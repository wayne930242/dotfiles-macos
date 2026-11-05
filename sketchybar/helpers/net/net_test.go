package main

import (
	"errors"
	"io"
	"net/http"
	"reflect"
	"strings"
	"testing"
)

func TestFlatten(t *testing.T) {
	n := Net{Bases: []Base{{
		ID: "w1", Label: "Root",
		Tower: &Unit{Key: "t", Name: "tower · Root", Role: "main", Mark: "idle"},
		Tabs: []Tab{{Units: []Unit{{
			Key: "m", Name: "main one", Role: "main", Mark: "commanding",
			Subs: []Unit{
				{Key: "s1", Name: "sub one", Role: "subagent", Mark: "working"},
				{Key: "s2", Name: "gone", Role: "subagent", Mark: "done", Ended: true},
				{Key: "s3", Name: "sub three", Role: "subagent", Mark: "waiting",
					Subs: []Unit{{Key: "s3a", Name: "nested", Role: "subagent", Mark: "done"}}},
			},
		}}}},
		Outside: []Unit{{Key: "o", Name: "outsider", Role: "outside", Mark: "error"}},
	}}}
	want := []Row{
		{Kind: "base", Base: "w1", Name: "Root"},
		{Kind: "unit", Base: "w1", Key: "t", Name: "tower · Root", Role: "tower", Mark: "idle"},
		{Kind: "unit", Base: "w1", Key: "m", Name: "main one", Role: "main", Mark: "commanding"},
		{Kind: "unit", Base: "w1", Key: "s1", Name: "sub one", Role: "subagent", Mark: "working", Depth: 1},
		{Kind: "unit", Base: "w1", Key: "s3", Name: "sub three", Role: "subagent", Mark: "waiting", Depth: 1, Last: true},
		{Kind: "unit", Base: "w1", Key: "s3a", Name: "nested", Role: "subagent", Mark: "done", Depth: 2, Last: true},
		{Kind: "unit", Base: "w1", Key: "o", Name: "outsider", Role: "outside", Mark: "error"},
	}
	got := Flatten(n)
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("Flatten:\n got %+v\nwant %+v", got, want)
	}
	if c := Count(got); c != (Counts{Waiting: 1, Working: 2, Done: 1, Error: 1}) {
		t.Fatalf("Count = %+v", c)
	}
}

func TestNextKey(t *testing.T) {
	tests := []struct {
		name string
		keys []string
		last string
		want string
	}{
		{"first press", []string{"a", "b"}, "", "a"},
		{"advances", []string{"a", "b", "c"}, "a", "b"},
		{"wraps", []string{"a", "b"}, "b", "a"},
		{"last no longer waits", []string{"a", "b"}, "z", "a"},
	}
	for _, tt := range tests {
		if got := NextKey(tt.keys, tt.last); got != tt.want {
			t.Errorf("%s: NextKey = %q, want %q", tt.name, got, tt.want)
		}
	}
}

func TestPaneFor(t *testing.T) {
	list := []byte(`{"result":{"agents":[
		{"pane_id":"w:p1","agent_session":{"value":"/s/--proj--/2026-10-25T05-20-33-317Z_01a1-main.jsonl"}},
		{"pane_id":"w:p2","agent_session":{"value":"/s/--wt--/2026-10-25T07-17-12-420Z_9d6d-sub-4bde-72f4.jsonl"}},
		{"pane_id":"w:p3"}
	]}}`)
	tests := []struct {
		key, want string
	}{
		{"01a1-main", "w:p1"},
		{"9d6d-sub", "w:p2"},
		{"absent", ""},
	}
	for _, tt := range tests {
		got, err := paneFor(list, tt.key)
		if err != nil || got != tt.want {
			t.Errorf("paneFor(%q) = %q, %v; want %q", tt.key, got, err, tt.want)
		}
	}
}

func TestReadEvents(t *testing.T) {
	stream := "event: hello\ndata: {\"stream\":\"x\"}\n\ndata: {\"bases\":[]}\n\nevent: ping\ndata: \n\n"
	var got []Event
	err := readEvents(strings.NewReader(stream), func(e Event) error {
		got = append(got, e)
		return nil
	})
	want := []Event{{"hello", `{"stream":"x"}`}, {"message", `{"bases":[]}`}, {"ping", ""}}
	if !errors.Is(err, io.EOF) || !reflect.DeepEqual(got, want) {
		t.Fatalf("readEvents = %+v, %v; want %+v, EOF", got, err, want)
	}
}

func TestQRImage(t *testing.T) {
	img := QRImage([]string{"10", "01"})
	side := (2 + 2*qrQuiet) * qrModule
	if b := img.Bounds(); b.Dx() != side || b.Dy() != side {
		t.Fatalf("size %v, want %d", b, side)
	}
	at := func(mx, my int) uint8 { return img.GrayAt((mx+qrQuiet)*qrModule+1, (my+qrQuiet)*qrModule+1).Y }
	if at(0, 0) != 0 || at(1, 1) != 0 || at(1, 0) != 0xff || at(0, 1) != 0xff {
		t.Fatal("modules drawn in the wrong place")
	}
	if img.GrayAt(0, 0).Y != 0xff {
		t.Fatal("quiet border is not light")
	}
}

func TestWithoutURLDropsToken(t *testing.T) {
	_, err := http.Get("http://127.0.0.1:1/SECRETTOKEN/events")
	if err == nil {
		t.Skip("port 1 answered")
	}
	if msg := withoutURL(err).Error(); strings.Contains(msg, "SECRETTOKEN") {
		t.Fatalf("token kept: %s", msg)
	}
}

func TestFlattenHead(t *testing.T) {
	n := Net{Head: &Unit{Key: "h", Name: "主塔台", Mark: "working", State: "live"}, Bases: []Base{{ID: "w1", Label: "Root"}}}
	want := []Row{
		{Kind: "unit", Key: "h", Name: "主塔台", Role: "head", Mark: "working"},
		{Kind: "base", Base: "w1", Name: "Root"},
	}
	if got := Flatten(n); !reflect.DeepEqual(got, want) {
		t.Fatalf("Flatten head:\n got %+v\nwant %+v", got, want)
	}
	if got := Flatten(Net{Head: &Unit{Key: "h", Name: "head", State: "absent"}}); len(got) != 0 {
		t.Fatalf("absent head drawn: %+v", got)
	}
}
