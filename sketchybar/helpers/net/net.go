package main

// The net as the Straw Boss GUI server streams it; only the fields the bar shows.
type Net struct {
	Bases []Base `json:"bases"`
	// The head tower, first in the list; "absent" until the boss first talks to it.
	Head *Unit `json:"head"`
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
	State string `json:"state"`
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

// Flatten lists the head tower first (once it exists), then each base, then its tower, then each tab's units and the units outside a tab,
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
	if n.Head != nil && n.Head.State != "absent" {
		unit(*n.Head, "", "head", 0, false)
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

// Counts tally the units by mark; Waiting turns the focus border orange and feeds alt-w.
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
	glyphRobot     = "\U000f06a9"
	glyphClaude    = "\U000f09d1"
	glyphCoffee    = "\U000f0176"
	glyphTimer     = "\U000f0150"
	glyphSleep     = "\U000f04b2"
	glyphMessage   = "\U000f0369"
	glyphOpen      = "\U000f03cc"
	glyphQR        = "\U000f0432"
	glyphDashboard = "\U000f056e"
)
