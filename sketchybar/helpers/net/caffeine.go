package main

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"
	"regexp"
	"slices"
	"strconv"
	"strings"
	"syscall"
	"time"
)

// Caffeine is every caffeinate holding the Mac awake, the pill's own or an agent's.
type Caffeine struct {
	On        bool
	Unlimited bool          // some caffeinate has no timeout
	Left      time.Duration // the longest timeout left, when none is unlimited
	PIDs      []int
}

// Power is what decides idle sleep once no caffeinate holds it.
type Power struct {
	SleepMin int      // idle minutes before system sleep on the current power source; 0 is never
	OnAC     bool     // drawing from AC power
	Idle     int      // seconds since the last keyboard or mouse input
	Holders  []string // other processes that prevent idle sleep, such as coreaudiod while audio plays
}

var (
	assertionHead = regexp.MustCompile(`^\s*pid (\d+)\(([^)]*)\): \[[^]]*\] \S+ (\w+)`)
	timeoutLine   = regexp.MustCompile(`Timeout will fire in (\d+) secs`)
	sleepLine     = regexp.MustCompile(`^\s*sleep\s+(\d+)(?:\s+\(sleep prevented by ([^)]*)\))?`)
)

// ParseCaffeine reads `pmset -g assertions`: each caffeinate's sleep assertions and their timeouts.
func ParseCaffeine(out string) Caffeine {
	timeouts := map[int]int{} // pid → longest timeout in seconds; -1 for none
	pid, isCaf := 0, false
	sc := bufio.NewScanner(strings.NewReader(out))
	for sc.Scan() {
		line := sc.Text()
		if m := assertionHead.FindStringSubmatch(line); m != nil {
			pid, _ = strconv.Atoi(m[1])
			isCaf = m[2] == "caffeinate" && strings.HasPrefix(m[3], "Prevent")
			if isCaf {
				if _, ok := timeouts[pid]; !ok {
					timeouts[pid] = -1
				}
			}
			continue
		}
		if m := timeoutLine.FindStringSubmatch(line); m != nil && isCaf {
			secs, _ := strconv.Atoi(m[1])
			if timeouts[pid] == -1 || secs > timeouts[pid] {
				timeouts[pid] = secs
			}
		}
	}
	var c Caffeine
	longest := 0
	for p, secs := range timeouts {
		c.PIDs = append(c.PIDs, p)
		if secs < 0 {
			c.Unlimited = true
		} else if secs > longest {
			longest = secs
		}
	}
	slices.Sort(c.PIDs)
	c.On = len(c.PIDs) > 0
	if c.On && !c.Unlimited {
		c.Left = time.Duration(longest) * time.Second
	}
	return c
}

// ParsePower reads `pmset -g` and `pmset -g batt`.
func ParsePower(settings, batt string, idle int) Power {
	p := Power{OnAC: strings.Contains(batt, "'AC Power'"), Idle: idle}
	for _, line := range strings.Split(settings, "\n") {
		m := sleepLine.FindStringSubmatch(line)
		if m == nil {
			continue
		}
		p.SleepMin, _ = strconv.Atoi(m[1])
		for _, h := range strings.Split(m[2], ",") {
			h = strings.TrimSpace(h)
			// caffeinate is told apart; powerd holds sleep for the system itself
			if h != "" && h != "caffeinate" && h != "powerd" && !slices.Contains(p.Holders, h) {
				p.Holders = append(p.Holders, h)
			}
		}
		break
	}
	return p
}

// Span is a short duration: "45s", "58m", "2h05m", "1d10h".
func Span(d time.Duration) string {
	s := int(d / time.Second)
	switch {
	case s <= 0:
		return "now"
	case s >= 86400:
		return fmt.Sprintf("%dd%dh", s/86400, s%86400/3600)
	case s >= 3600:
		return fmt.Sprintf("%dh%02dm", s/3600, s%3600/60)
	case s >= 60:
		return fmt.Sprintf("%dm", s/60)
	}
	return fmt.Sprintf("%ds", s)
}

// CaffeineLabel is the popup's caffeine row.
func CaffeineLabel(c Caffeine) string {
	switch {
	case !c.On:
		return "Off"
	case c.Unlimited:
		return "On · until turned off"
	}
	return "On · " + Span(c.Left) + " left"
}

// SleepLabel says how long until the Mac sleeps on idle: caffeine first, then the power source's idle timer.
func SleepLabel(c Caffeine, p Power) string {
	source := "on AC"
	if !p.OnAC {
		source = "on battery"
	}
	switch {
	case p.SleepMin == 0:
		return "Sleep: never on idle " + source
	case c.On && c.Unlimited:
		return "Sleep: not while caffeine is on"
	case c.On:
		return "Sleep: in " + Span(c.Left+time.Duration(p.SleepMin)*time.Minute) + " at the earliest " + source
	}
	return "Sleep: after " + Span(max(time.Duration(p.SleepMin*60-p.Idle)*time.Second, time.Second)) + " idle " + source
}

// HoldersLabel names what else keeps the Mac awake, such as coreaudiod while audio plays; "" for nothing.
func HoldersLabel(p Power) string {
	if len(p.Holders) == 0 {
		return ""
	}
	return "Also kept awake by " + strings.Join(p.Holders, ", ")
}

func readCaffeine() Caffeine {
	out, err := exec.Command("pmset", "-g", "assertions").Output()
	if err != nil {
		return Caffeine{}
	}
	return ParseCaffeine(string(out))
}

func readPower() Power {
	settings, _ := exec.Command("pmset", "-g").Output()
	batt, _ := exec.Command("pmset", "-g", "batt").Output()
	idle := 0
	if out, err := exec.Command("ioreg", "-c", "IOHIDSystem", "-d", "4").Output(); err == nil {
		if m := regexp.MustCompile(`"HIDIdleTime" = (\d+)`).FindSubmatch(out); m != nil {
			ns, _ := strconv.ParseInt(string(m[1]), 10, 64)
			idle = int(ns / 1e9)
		}
	}
	return ParsePower(string(settings), string(batt), idle)
}

// stopCaffeine ends every caffeinate of this user, an agent's too: off means the Mac may sleep.
func stopCaffeine() {
	pids := readCaffeine().PIDs
	if out, err := exec.Command("pgrep", "-x", "-U", strconv.Itoa(os.Getuid()), "caffeinate").Output(); err == nil {
		for _, f := range strings.Fields(string(out)) {
			if p, err := strconv.Atoi(f); err == nil && !slices.Contains(pids, p) {
				pids = append(pids, p)
			}
		}
	}
	for _, p := range pids {
		_ = syscall.Kill(p, syscall.SIGTERM)
	}
	// pmset drops a released assertion a moment after its process ends
	for range 20 {
		if !readCaffeine().On {
			return
		}
		time.Sleep(100 * time.Millisecond)
	}
}

// startCaffeine replaces whatever caffeinate runs with one for secs seconds, or until turned off when secs is 0.
// It keeps the display, the disks, and the system awake, in its own session so it outlives this click.
func startCaffeine(secs int) error {
	stopCaffeine()
	args := []string{"-dims"}
	if secs > 0 {
		args = append(args, "-t", strconv.Itoa(secs))
	}
	cmd := exec.Command("caffeinate", args...)
	cmd.SysProcAttr = &syscall.SysProcAttr{Setsid: true}
	if err := cmd.Start(); err != nil {
		return fmt.Errorf("caffeinate: %w", err)
	}
	_ = cmd.Process.Release()
	for range 20 {
		if readCaffeine().On {
			return nil
		}
		time.Sleep(100 * time.Millisecond)
	}
	return nil
}

// caffeine runs the popup's caffeine rows: toggle, off, or on SECONDS (0 for until turned off).
func caffeine(what, arg string) error {
	var err error
	switch what {
	case "toggle":
		if readCaffeine().On {
			stopCaffeine()
		} else {
			err = startCaffeine(0)
		}
	case "off":
		stopCaffeine()
	case "on":
		secs, convErr := strconv.Atoi(arg)
		if convErr != nil || secs < 0 {
			return fmt.Errorf("caffeine on: seconds, got %q", arg)
		}
		err = startCaffeine(secs)
	default:
		return fmt.Errorf("usage: caffeine toggle | off | on SECONDS")
	}
	redraw()
	return err
}
