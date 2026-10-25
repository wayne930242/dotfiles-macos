package main

import "fmt"

// The net as the Straw Boss GUI server streams it; only the fields the bar shows.
type Net struct {
	Bases []Base `json:"bases"`
}

type Base struct {
	ID      string `json:"id"`
	Label   string `json:"label"`
	Tower   *Unit  `json:"tower"`
	Tabs    []Tab  `json:"tabs"`
	Outside []Unit `json:"outside"`
}

type Tab struct {
	Units []Unit `json:"units"`
}

type Unit struct {
	Key   string `json:"key"`
	Name  string `json:"name"`
	Role  string `json:"role"`
	Mark  string `json:"mark"`
	Ended bool   `json:"ended"`
	Subs  []Unit `json:"subs"`
}

// Row is one line of the popup: a base heading, or a unit at its depth in the subagent tree.
type Row struct {
	Kind  string `json:"kind"` // "base" or "unit"
	Base  string `json:"base"`
	Key   string `json:"key,omitempty"`
	Name  string `json:"name"`
	Role  string `json:"role,omitempty"`
	Mark  string `json:"mark,omitempty"`
	Depth int    `json:"depth"`
	Last  bool   `json:"last"`
}

// Flatten lists each base, then its tower, then each tab's units and the units outside a tab,
// every unit followed by its live subagents. Ended units are left out.
func Flatten(n Net) []Row {
	var rows []Row
	var unit func(u Unit, base, role string, depth int, last bool)
	unit = func(u Unit, base, role string, depth int, last bool) {
		if u.Ended {
			return
		}
		if role == "" {
			role = u.Role
		}
		rows = append(rows, Row{Kind: "unit", Base: base, Key: u.Key, Name: u.Name, Role: role, Mark: u.Mark, Depth: depth, Last: last})
		var subs []Unit
		for _, s := range u.Subs {
			if !s.Ended {
				subs = append(subs, s)
			}
		}
		for i, s := range subs {
			unit(s, base, "", depth+1, i == len(subs)-1)
		}
	}
	for _, b := range n.Bases {
		rows = append(rows, Row{Kind: "base", Base: b.ID, Name: b.Label})
		if b.Tower != nil {
			unit(*b.Tower, b.ID, "tower", 0, false)
		}
		for _, t := range b.Tabs {
			for _, u := range t.Units {
				unit(u, b.ID, "", 0, false)
			}
		}
		for _, u := range b.Outside {
			unit(u, b.ID, "", 0, false)
		}
	}
	return rows
}

// Counts are what the pill shows; a unit commanding its subagents counts as working.
type Counts struct {
	Waiting, Working, Done, Error int
}

func Count(rows []Row) Counts {
	var c Counts
	for _, r := range rows {
		if r.Kind != "unit" {
			continue
		}
		switch r.Mark {
		case "waiting":
			c.Waiting++
		case "working", "commanding":
			c.Working++
		case "done":
			c.Done++
		case "error":
			c.Error++
		}
	}
	return c
}

// Nerd Font glyphs (Hack Nerd Font Mono).
const (
	glyphRobot = "\U000f06a9"
	glyphTower = "\U000f043b"
	glyphStar  = "\uf005"
	glyphOpen  = "\U000f03cc"
)

var markGlyph = map[string]string{
	"waiting":    "\U000f009e",
	"working":    "\U000f051f",
	"commanding": "\U000f051f",
	"done":       "\U000f012c",
	"error":      "\U000f0159",
	"idle":       "\U000f04b2",
	"unknown":    "\U000f0625",
}

func glyphOf(mark string) string {
	if g, ok := markGlyph[mark]; ok {
		return g
	}
	return markGlyph["unknown"]
}

// PillLabel lists the non-zero counts, most urgent first; empty when nothing is active.
func PillLabel(c Counts) string {
	label := ""
	for _, p := range []struct {
		mark string
		n    int
	}{{"waiting", c.Waiting}, {"error", c.Error}, {"working", c.Working}, {"done", c.Done}} {
		if p.n == 0 {
			continue
		}
		if label != "" {
			label += "  "
		}
		label += fmt.Sprintf("%s %d", markGlyph[p.mark], p.n)
	}
	return label
}

const nameWidth = 28

// RowIndent is a unit row's label.padding_left in points. Indentation is padding, not
// leading spaces, because SketchyBar leaves leading spaces out of a label's width and then
// cuts the label's end by as much.
func RowIndent(r Row) int {
	if r.Depth < 2 {
		return 16
	}
	return 16 + (r.Depth-1)*16
}

// RowLabel draws a unit with its tree branch and role mark, its name cut to nameWidth.
func RowLabel(r Row) string {
	if r.Kind == "base" {
		return r.Name
	}
	lead := ""
	switch r.Role {
	case "tower":
		lead = glyphTower + " "
	case "main":
		lead = glyphStar + " "
	}
	branch := ""
	if r.Depth > 0 {
		branch = "├ "
		if r.Last {
			branch = "└ "
		}
	}
	name := []rune(r.Name)
	if len(name) > nameWidth {
		name = append(name[:nameWidth-1], '…')
	}
	return branch + lead + string(name)
}
