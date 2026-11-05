package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"net/url"
	"os/exec"
	"strings"
)

// The prompt, the title, and the reply go to osascript as arguments, never inside its script.
const askScript = `on run argv
	activate
	set r to display dialog (item 1 of argv) default answer "" with title (item 2 of argv) buttons {"Cancel", "Send"} default button "Send" cancel button "Cancel"
	return text returned of r
end run`

const notifyScript = `on run argv
	display notification (item 2 of argv) with title (item 1 of argv)
end run`

func notify(title, body string) {
	_ = exec.Command("osascript", "-e", notifyScript, title, body).Run()
}

// tellHead asks for a message in a dialog and sends it to the head tower, as its composer in the GUI does.
func tellHead() error {
	closePopup()
	s := readState()
	if !s.Online || s.Head == "" {
		notify("Head tower", "No Straw Boss GUI server runs")
		return errors.New("no GUI server")
	}
	out, err := exec.Command("osascript", "-e", askScript, "Message to the head tower:", "Straw Net").Output()
	if err != nil { // Cancel, or the dialog could not show
		return nil
	}
	msg := strings.TrimRight(string(out), "\n")
	if strings.TrimSpace(msg) == "" {
		return nil
	}
	status, body, err := guiPost("api/sessions/"+url.PathEscape(s.Head)+"/input", map[string]string{"text": msg, "as": "send"})
	if err == nil && status != http.StatusOK {
		err = fmt.Errorf("%s", replyReason(status, body))
	}
	if err != nil {
		notify("Head tower did not take it", err.Error())
		return err
	}
	notify("Head tower", "Sent")
	return nil
}

// replyReason is the reason a GUI server's refusal gives, or its HTTP status.
func replyReason(status int, body []byte) string {
	var e struct {
		Reason string `json:"reason"`
	}
	_ = json.Unmarshal(body, &e)
	if e.Reason == "" {
		return fmt.Sprintf("HTTP %d", status)
	}
	return e.Reason
}
