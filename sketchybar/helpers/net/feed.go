package main

import (
	"bufio"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"os"
	"reflect"
	"strings"
	"time"
)

const (
	// The server pings every 15 s; a stream silent for longer than this is dead.
	silentLimit = 45 * time.Second
	retryDelay  = 3 * time.Second
)

// Event is one server-sent event.
type Event struct {
	Name string
	Data string
}

// readEvents parses an SSE stream, calling fn per event until the stream ends or fn returns an error.
func readEvents(r io.Reader, fn func(Event) error) error {
	sc := bufio.NewScanner(r)
	sc.Buffer(make([]byte, 64*1024), 16*1024*1024)
	ev, data := Event{Name: "message"}, []string(nil)
	for sc.Scan() {
		line := sc.Text()
		switch {
		case line == "":
			ev.Data = strings.Join(data, "\n")
			if err := fn(ev); err != nil {
				return err
			}
			ev, data = Event{Name: "message"}, nil
		case strings.HasPrefix(line, "event:"):
			ev.Name = strings.TrimSpace(line[len("event:"):])
		case strings.HasPrefix(line, "data:"):
			data = append(data, strings.TrimPrefix(line[len("data:"):], " "))
		}
	}
	if err := sc.Err(); err != nil {
		return fmt.Errorf("read stream: %w", err)
	}
	return io.EOF
}

var errMoved = errors.New("gui.json changed")

type feeder struct {
	colors map[string]string
	shown  *Counts // what the pill shows; nil while offline
	drawn  bool
	border string
	rows   []Row
}

// publish writes the cache and redraws only what changed.
func (f *feeder) publish(online bool, rows []Row) {
	s := State{Online: online, Rows: rows, Colors: f.colors}
	if err := writeState(s); err != nil {
		fmt.Fprintln(os.Stderr, "net:", err)
	}
	var view *Counts
	if online {
		n := Count(rows)
		view = &n
	}
	if !f.drawn || !reflect.DeepEqual(view, f.shown) {
		drawPill(s)
		f.shown, f.drawn = view, true
	}
	if popupOpen() {
		if !online {
			closePopup() // the pill is hidden, so its popup goes too
		} else if self, err := os.Executable(); err == nil {
			drawPopup(s, self)
		}
	}
	f.border = setBorder(f.colors, view != nil && view.Waiting > 0, f.border)
}

// follow streams one connection to the GUI server until it fails, goes silent, or gui.json changes.
func (f *feeder) follow() error {
	before, err := os.Stat(guiState)
	if err != nil {
		return fmt.Errorf("stat gui.json: %w", err)
	}
	url, err := guiURL()
	if err != nil {
		return err
	}
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	watchdog := time.AfterFunc(silentLimit, cancel)
	defer watchdog.Stop()
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url+"events", nil)
	if err != nil {
		return fmt.Errorf("build request: %w", err)
	}
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return fmt.Errorf("connect: %w", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("connect: %s", resp.Status)
	}
	return readEvents(resp.Body, func(ev Event) error {
		watchdog.Reset(silentLimit)
		if now, err := os.Stat(guiState); err != nil || !now.ModTime().Equal(before.ModTime()) {
			return errMoved
		}
		if ev.Name != "message" || ev.Data == "" {
			return nil
		}
		var n Net
		if err := json.Unmarshal([]byte(ev.Data), &n); err != nil {
			return fmt.Errorf("parse net: %w", err)
		}
		rows := Flatten(n)
		if rows == nil {
			rows = []Row{}
		}
		if reflect.DeepEqual(rows, f.rows) {
			return nil
		}
		f.publish(true, rows)
		f.rows = rows
		return nil
	})
}

func feed() error {
	colors, err := theme()
	if err != nil {
		return err
	}
	f := &feeder{colors: colors, border: colors["BORDER_ACTIVE_COLOR"]}
	f.publish(false, nil)
	logged := ""
	for {
		err := f.follow()
		// A server that stays down fails every retry the same way: log each new reason once.
		if !errors.Is(err, errMoved) && err.Error() != logged {
			fmt.Fprintln(os.Stderr, time.Now().Format(time.DateTime), "net: stream ended:", err)
			logged = err.Error()
		}
		if f.rows != nil { // it was online: show it offline once, and the next failure is news
			f.rows, logged = nil, ""
			f.publish(false, nil)
		}
		time.Sleep(retryDelay)
	}
}
