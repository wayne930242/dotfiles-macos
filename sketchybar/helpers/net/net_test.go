package main

import (
	"errors"
	"io"
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

func TestPillLabel(t *testing.T) {
	tests := []struct {
		name string
		in   Counts
		want string
	}{
		{"nothing active", Counts{}, ""},
		{"working only", Counts{Working: 5}, markGlyph["working"] + " 5"},
		{"urgent first", Counts{Waiting: 1, Working: 3, Done: 2, Error: 1},
			markGlyph["waiting"] + " 1  " + markGlyph["error"] + " 1  " + markGlyph["working"] + " 3  " + markGlyph["done"] + " 2"},
	}
	for _, tt := range tests {
		if got := PillLabel(tt.in); got != tt.want {
			t.Errorf("%s: PillLabel = %q, want %q", tt.name, got, tt.want)
		}
	}
}

func TestRowLabel(t *testing.T) {
	tests := []struct {
		name string
		in   Row
		want string
	}{
		{"base", Row{Kind: "base", Name: "Root"}, "Root"},
		{"tower", Row{Kind: "unit", Role: "tower", Name: "tower"}, glyphTower + " tower"},
		{"main", Row{Kind: "unit", Role: "main", Name: "六月調校"}, glyphStar + " 六月調校"},
		{"middle sub", Row{Kind: "unit", Role: "subagent", Name: "a", Depth: 1}, "├ a"},
		{"last nested sub", Row{Kind: "unit", Role: "subagent", Name: "b", Depth: 2, Last: true}, "└ b"},
		{"long name cut by runes", Row{Kind: "unit", Role: "subagent", Name: strings.Repeat("字", 30)},
			strings.Repeat("字", nameWidth-1) + "…"},
	}
	for _, tt := range tests {
		if got := RowLabel(tt.in); got != tt.want {
			t.Errorf("%s: RowLabel = %q, want %q", tt.name, got, tt.want)
		}
	}
}

func TestRowIndent(t *testing.T) {
	tests := []struct {
		name string
		in   Row
		want int
	}{
		{"top unit", Row{Kind: "unit"}, 16},
		{"sub", Row{Kind: "unit", Depth: 1}, 16},
		{"nested sub", Row{Kind: "unit", Depth: 3}, 48},
	}
	for _, tt := range tests {
		if got := RowIndent(tt.in); got != tt.want {
			t.Errorf("%s: RowIndent = %d, want %d", tt.name, got, tt.want)
		}
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
