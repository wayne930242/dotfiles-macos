package main

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"image"
	"image/color"
	"image/png"
	"io"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"time"
)

const (
	qrItem   = "net.qr"
	qrModule = 8 // pixels per QR module; shown at half size, so a Retina display draws it sharp
	qrQuiet  = 4 // the light border a scanner needs, in modules
)

var qrFile = filepath.Join(cacheDir, "net-qr.png")

type pairing struct {
	URL  string   `json:"url"`
	Rows []string `json:"rows"`
}

// remotePair asks the GUI server for a one-time pairing URL and its QR, turning remote access
// on first when it is off, as the GUI's own button does. The server takes writes only with the
// local page's origin and the CSRF secret it wrote into gui.json.
func remotePair() (pairing, error) {
	base, err := guiURL()
	if err != nil {
		return pairing{}, err
	}
	csrf, err := guiCSRF()
	if err != nil {
		return pairing{}, err
	}
	u, err := url.Parse(base)
	if err != nil {
		return pairing{}, fmt.Errorf("gui url: %w", err)
	}
	origin := u.Scheme + "://" + u.Host
	post := func(action string) (int, []byte, error) {
		req, err := http.NewRequest(http.MethodPost, base+"api/remote/"+action, bytes.NewReader([]byte("{}")))
		if err != nil {
			return 0, nil, err
		}
		req.Header.Set("Origin", origin)
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("X-SB-CSRF", csrf)
		resp, err := (&http.Client{Timeout: 30 * time.Second}).Do(req)
		if err != nil {
			return 0, nil, err
		}
		defer resp.Body.Close()
		body, err := io.ReadAll(io.LimitReader(resp.Body, 1<<20))
		return resp.StatusCode, body, err
	}
	status, body, err := post("pair")
	if err == nil && status == http.StatusConflict { // remote access is off
		status, body, err = post("on")
	}
	if err != nil {
		return pairing{}, fmt.Errorf("pair: %w", err)
	}
	if status != http.StatusOK {
		var e struct {
			Reason string `json:"reason"`
		}
		_ = json.Unmarshal(body, &e)
		if e.Reason == "" {
			e.Reason = fmt.Sprintf("HTTP %d", status)
		}
		return pairing{}, errors.New(e.Reason)
	}
	var p pairing
	if err := json.Unmarshal(body, &p); err != nil || len(p.Rows) == 0 {
		return pairing{}, fmt.Errorf("pair: unexpected reply")
	}
	return p, nil
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

// showQR puts a fresh pairing QR at the top of the open popup, or the reason it failed.
func showQR() error {
	c := readState().Colors
	if c == nil {
		var err error
		if c, err = theme(); err != nil {
			return err
		}
	}
	p, err := remotePair()
	if err != nil {
		sketchybar("--remove", qrItem, "--add", "item", qrItem, "popup.net", "--set", qrItem,
			"background.drawing=off", "padding_left=6", "padding_right=6", "icon.drawing=off", fontLabel,
			"label=Remote QR failed: "+err.Error(), "label.color="+c["RED"])
		return err
	}
	var buf bytes.Buffer
	img := QRImage(p.Rows)
	if err := png.Encode(&buf, img); err != nil {
		return fmt.Errorf("encode qr: %w", err)
	}
	if err := os.MkdirAll(cacheDir, 0o700); err != nil {
		return fmt.Errorf("cache dir: %w", err)
	}
	if err := os.WriteFile(qrFile, buf.Bytes(), 0o600); err != nil {
		return fmt.Errorf("write qr: %w", err)
	}
	side := img.Bounds().Dx() / 2
	sketchybar("--remove", qrItem, "--add", "item", qrItem, "popup.net", "--set", qrItem,
		"icon.drawing=off", "label.drawing=off", "padding_left=6", "padding_right=6",
		fmt.Sprintf("width=%d", side), "y_offset=0",
		"background.drawing=on", "background.color=0x00000000",
		"background.image="+qrFile, "background.image.scale=0.5",
		fmt.Sprintf("background.height=%d", side))
	return nil
}
