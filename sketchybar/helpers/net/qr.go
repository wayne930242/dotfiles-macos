package main

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"image"
	"image/color"
	"image/png"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"time"
)

const (
	qrItem   = "net.row.qr"
	qrModule = 8 // pixels per QR module; shown at half size, so a Retina display draws it sharp
	qrQuiet  = 4 // the light border a scanner needs, in modules
)

// The popup's QR is drawn from these, so a redraw keeps it: the image once made, else the reason
// it failed, else a placeholder while qrWant says one is being made. All go when the popup closes,
// since a pairing code stays valid for ten minutes.
var (
	qrFile = filepath.Join(cacheDir, "net-qr.png")
	qrErr  = filepath.Join(cacheDir, "net-qr.err")
	qrWant = filepath.Join(cacheDir, "net-qr.want")
)

type pairing struct {
	URL  string   `json:"url"`
	Rows []string `json:"rows"`
}

// remotePair asks the GUI server for a one-time pairing URL and its QR, turning remote access
// on first when it is off, as the GUI's own button does.
func remotePair() (pairing, error) {
	status, body, err := guiPost("api/remote/pair", map[string]any{})
	if err == nil && status == http.StatusConflict { // remote access is off
		status, body, err = guiPost("api/remote/on", map[string]any{})
	}
	if err != nil {
		return pairing{}, fmt.Errorf("pair: %w", err)
	}
	if status != http.StatusOK {
		return pairing{}, errors.New(replyReason(status, body))
	}
	var p pairing
	if err := json.Unmarshal(body, &p); err != nil || len(p.Rows) == 0 {
		return pairing{}, fmt.Errorf("pair: unexpected reply")
	}
	return p, nil
}

// tailnetUp reports whether Tailscale is connected here; remote access works over the tailnet only.
func tailnetUp() bool {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	out, err := exec.CommandContext(ctx, "tailscale", "status", "--json").Output()
	if err != nil {
		return false
	}
	var s struct {
		BackendState string `json:"BackendState"`
	}
	return json.Unmarshal(out, &s) == nil && s.BackendState == "Running"
}

func clearQR() {
	for _, f := range []string{qrFile, qrErr, qrWant} {
		_ = os.Remove(f)
	}
}

// QRImage draws the server's QR rows ("1" dark, "0" light) with the quiet border.
func QRImage(rows []string) *image.Gray {
	n := len(rows) + 2*qrQuiet
	img := image.NewGray(image.Rect(0, 0, n*qrModule, n*qrModule))
	for i := range img.Pix {
		img.Pix[i] = 0xff
	}
	for y, row := range rows {
		for x, c := range row {
			if c != '1' {
				continue
			}
			for dy := 0; dy < qrModule; dy++ {
				for dx := 0; dx < qrModule; dx++ {
					img.SetGray((x+qrQuiet)*qrModule+dx, (y+qrQuiet)*qrModule+dy, color.Gray{Y: 0})
				}
			}
		}
	}
	return img
}

// qrProps draws the QR row from its files; nil when no QR is wanted.
func qrProps(c map[string]string) []string {
	if _, err := os.Stat(qrFile); err == nil {
		side := QRSide()
		return []string{"icon.drawing=off", "label.drawing=off", fmt.Sprintf("width=%d", side),
			"background.drawing=on", "background.color=0x00000000",
			"background.image=" + qrFile, "background.image.scale=0.5", fmt.Sprintf("background.height=%d", side)}
	}
	if b, err := os.ReadFile(qrErr); err == nil {
		return []string{"icon=" + glyphQR, "icon.color=" + c["RED"], "label=Remote QR failed: " + string(b), "label.color=" + c["RED"]}
	}
	if _, err := os.Stat(qrWant); err == nil {
		return []string{"icon=" + glyphQR, "icon.color=" + c["SPACE_INACTIVE"], "label=Remote QR…", "label.color=" + c["SPACE_INACTIVE"]}
	}
	return nil
}

var qrSide int

// QRSide is the drawn QR's side in points: half its pixels.
func QRSide() int {
	if qrSide == 0 {
		if f, err := os.Open(qrFile); err == nil {
			if cfg, err := png.DecodeConfig(f); err == nil {
				qrSide = cfg.Width / 2
			}
			f.Close()
		}
	}
	return qrSide
}

// makeQR fetches a fresh pairing QR into the open popup's QR row, or the reason it failed.
func makeQR() error {
	p, err := remotePair()
	// The request can take seconds: a popup closed meanwhile gets no QR, and no pairing code
	// stays on disk
	if !popupOpen() {
		return err
	}
	if err != nil {
		_ = os.WriteFile(qrErr, []byte(err.Error()), 0o600)
	} else {
		var buf bytes.Buffer
		if err := png.Encode(&buf, QRImage(p.Rows)); err != nil {
			return fmt.Errorf("encode qr: %w", err)
		}
		if err := os.WriteFile(qrFile, buf.Bytes(), 0o600); err != nil {
			return fmt.Errorf("write qr: %w", err)
		}
	}
	if !popupOpen() {
		clearQR()
		return err
	}
	c, cerr := colors()
	if cerr != nil {
		return cerr
	}
	sketchybar(append([]string{"--set", qrItem}, qrProps(c)...)...)
	return err
}
