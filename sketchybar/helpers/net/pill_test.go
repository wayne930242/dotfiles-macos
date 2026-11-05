package main

import (
	"encoding/json"
	"reflect"
	"strings"
	"testing"
	"time"
)

const assertions = `Assertion status system-wide:
   PreventUserIdleSystemSleep     1
Listed by owning process:
   pid 566(coreaudiod): [0x00005cf000018927] 05:20:49 PreventUserIdleSystemSleep named: "com.apple.audio.context"
	Created for PID: 773.
   pid 415(WindowServer): [0x00005a4d0009976c] 00:01:04 UserIsActive named: "tickle"
	Timeout will fire in 536 secs Action=TimeoutActionRelease
   pid 74166(caffeinate): [0x0000a4f500018669] 00:13:32 PreventUserIdleSystemSleep named: "caffeinate command-line tool"
	Details: caffeinate asserting for 19400 secs
	Timeout will fire in 18588 secs Action=TimeoutActionRelease
   pid 74166(caffeinate): [0x0000a4f50005866a] 00:13:32 PreventUserIdleDisplaySleep named: "caffeinate command-line tool"
	Timeout will fire in 18588 secs Action=TimeoutActionRelease
   pid 74166(caffeinate): [0x0000a4f50009866c] 00:13:32 UserIsActive named: "caffeinate command-line tool"
	Timeout will fire in 18590 secs Action=TimeoutActionRelease
   pid 80001(caffeinate): [0x0000a4f500018670] 00:00:10 PreventUserIdleSystemSleep named: "caffeinate command-line tool"
	Timeout will fire in 600 secs Action=TimeoutActionRelease
`

func TestParseCaffeine(t *testing.T) {
	got := ParseCaffeine(assertions)
	want := Caffeine{On: true, Left: 18588 * time.Second, PIDs: []int{74166, 80001}}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("ParseCaffeine = %+v, want %+v", got, want)
	}
	unlimited := assertions + "   pid 9(caffeinate): [0x1] 00:00:01 PreventSystemSleep named: \"caffeinate command-line tool\"\n"
	if c := ParseCaffeine(unlimited); !c.Unlimited || c.Left != 0 || len(c.PIDs) != 3 {
		t.Fatalf("a caffeinate without a timeout: %+v", c)
	}
	if c := ParseCaffeine("Listed by owning process:\n   pid 566(coreaudiod): [0x1] 05:20:49 PreventUserIdleSystemSleep named: \"x\"\n"); c.On {
		t.Fatalf("no caffeinate read as on: %+v", c)
	}
}

func TestParsePower(t *testing.T) {
	settings := " disksleep            10\n sleep                0 (sleep prevented by coreaudiod, coreaudiod, caffeinate, powerd)\n displaysleep         10 (display sleep prevented by caffeinate)\n"
	got := ParsePower(settings, "Now drawing from 'AC Power'\n", 12)
	want := Power{SleepMin: 0, OnAC: true, Idle: 12, Holders: []string{"coreaudiod"}}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("ParsePower = %+v, want %+v", got, want)
	}
	if p := ParsePower(" sleep                1\n", "Now drawing from 'Battery Power'\n", 0); p.SleepMin != 1 || p.OnAC || p.Holders != nil {
		t.Fatalf("battery: %+v", p)
	}
}

func TestSpan(t *testing.T) {
	for d, want := range map[time.Duration]string{
		0: "now", 45 * time.Second: "45s", 58 * time.Minute: "58m",
		2*time.Hour + 5*time.Minute: "2h05m", 34 * time.Hour: "1d10h",
	} {
		if got := Span(d); got != want {
			t.Errorf("Span(%v) = %q, want %q", d, got, want)
		}
	}
}

func TestSleepLabel(t *testing.T) {
	battery := Power{SleepMin: 5, Idle: 60}
	tests := []struct {
		name string
		c    Caffeine
		p    Power
		want string
	}{
		{"idle on battery", Caffeine{}, battery, "Sleep: after 4m idle on battery"},
		{"never on AC", Caffeine{On: true, Left: time.Hour}, Power{OnAC: true}, "Sleep: never on idle on AC"},
		{"unlimited caffeine", Caffeine{On: true, Unlimited: true}, battery, "Sleep: not while caffeine is on"},
		{"timed caffeine", Caffeine{On: true, Left: 90 * time.Minute}, battery, "Sleep: in 1h35m at the earliest on battery"},
	}
	for _, tt := range tests {
		if got := SleepLabel(tt.c, tt.p); got != tt.want {
			t.Errorf("%s: SleepLabel = %q, want %q", tt.name, got, tt.want)
		}
	}
	if got := HoldersLabel(Power{Holders: []string{"coreaudiod", "Zoom"}}); got != "Also kept awake by coreaudiod, Zoom" {
		t.Errorf("HoldersLabel = %q", got)
	}
	if got := HoldersLabel(Power{}); got != "" {
		t.Errorf("HoldersLabel without holders = %q", got)
	}
	for c, want := range map[*Caffeine]string{
		{}: "Off", {On: true, Unlimited: true}: "On · until turned off", {On: true, Left: time.Hour}: "On · 1h00m left",
	} {
		if got := CaffeineLabel(*c); got != want {
			t.Errorf("CaffeineLabel(%+v) = %q, want %q", *c, got, want)
		}
	}
}

const ccswitchJSON = `[
 {"num":"1","email":"a@x.io","active":false,"token_state":"valid","error":null,
  "usage":{"five_hour":null,"seven_day":{"utilization":69.0,"resets_at":"2026-11-10T20:00:00.113348+00:00"}}},
 {"num":"2","email":"b@x.io","active":false,"token_state":"relogin","error":null,"usage":null},
 {"num":3,"email":"c@x.io","active":true,"token_state":"valid","error":null,
  "usage":{"seven_day":{"utilization":58.9,"resets_at":"2026-11-06T01:00:00Z"}}},
 {"num":"4","email":"d@x.io","active":false,"token_state":"valid","error":"usage: rate limited (429)","usage":null},
 {"num":"5","email":"e@x.io","active":false,"token_state":"valid","error":{"code":1},"usage":null}
]`

func accountsOf(t *testing.T, s string) []Account {
	t.Helper()
	var a []Account
	if err := json.Unmarshal([]byte(s), &a); err != nil {
		t.Fatal(err)
	}
	return a
}

func TestAccounts(t *testing.T) {
	a := accountsOf(t, ccswitchJSON)
	var statuses []string
	for _, x := range a {
		statuses = append(statuses, x.Status())
	}
	if want := []string{"ok", "login", "ok", "limited", "unavailable"}; !reflect.DeepEqual(statuses, want) {
		t.Fatalf("statuses %v, want %v", statuses, want)
	}
	if a[2].Num != "3" || a[2].Seven() != 58 {
		t.Fatalf("num %q seven %d", a[2].Num, a[2].Seven())
	}
	now := time.Date(2026, 11, 5, 22, 0, 0, 0, time.UTC)
	if got, want := AccountLabel(a[2], now), "c@x.io                  7d  58% ↻3h00m"; got != want {
		t.Fatalf("AccountLabel = %q, want %q", got, want)
	}
	if got := AccountLabel(a[1], now); !strings.HasSuffix(got, "login needs attention") {
		t.Fatalf("login label %q", got)
	}
}

func TestPillOf(t *testing.T) {
	c := map[string]string{"RED": "r", "YELLOW": "y", "ICON_COLOR": "i", "LABEL_COLOR": "l", "SPACE_INACTIVE": "s"}
	a := accountsOf(t, ccswitchJSON)
	tests := []struct {
		name     string
		accounts []Account
		caf      Caffeine
		want     Pill
	}{
		{"nothing", nil, Caffeine{}, Pill{glyphRobot, "s", "", "l"}},
		{"caffeine only", nil, Caffeine{On: true}, Pill{glyphRobot, "s", glyphCoffee, "l"}},
		{"claude", a, Caffeine{}, Pill{glyphClaude, "i", "3 · 7d 58%", "l"}},
		{"claude and caffeine", a, Caffeine{On: true, Unlimited: true}, Pill{glyphClaude, "i", glyphCoffee + "  3 · 7d 58%", "l"}},
		{"hot", accountsOf(t, `[{"num":"1","active":true,"usage":{"seven_day":{"utilization":90}}}]`), Caffeine{}, Pill{glyphClaude, "r", "1 · 7d 90%", "l"}},
		{"login", accountsOf(t, `[{"num":"2","active":true,"token_state":"relogin"}]`), Caffeine{}, Pill{glyphClaude, "r", "2 · !", "r"}},
		{"no active", a[:2], Caffeine{}, Pill{glyphClaude, "r", "- · !", "r"}},
	}
	for _, tt := range tests {
		if got := PillOf(c, tt.accounts, tt.caf); got != tt.want {
			t.Errorf("%s: PillOf = %+v, want %+v", tt.name, got, tt.want)
		}
	}
}

func TestListedAccounts(t *testing.T) {
	list := "Accounts:\n  1: a@x.io\n  3: c@x.io (active)\n"
	want := []string{"1 a@x.io false", "3 c@x.io true"}
	if got := ListedAccounts(list); !reflect.DeepEqual(got, want) {
		t.Fatalf("ListedAccounts = %v, want %v", got, want)
	}
	if got := cachedAccounts(accountsOf(t, `[{"num":"1","email":"a@x.io"},{"num":"3","email":"c@x.io","active":true}]`)); !reflect.DeepEqual(got, want) {
		t.Fatalf("cachedAccounts = %v", got)
	}
}
