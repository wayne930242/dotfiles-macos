#!/usr/bin/env bash

set -euo pipefail

# Measures the built-in display's notch and prints, in points:
#   <notch_width> <limit> <screen_min_x> <screen_max_x>
# notch_width includes a gap on each side, for the bar's notch_width; limit is the x where
# the left side must end (the notch's left edge less the gap); the screen range tells the
# built-in display's bar apart from an external one. Prints nothing when no screen has a
# notch (lid closed, an older Mac). The notch's size in points follows the display scaling:
# the 14" MacBook Pro's is 185 pt at the default 1512 pt and 220 pt at 1800 pt.
GAP=8

osascript -l JavaScript - "$GAP" <<'EOF' 2>/dev/null || true
function run(argv) {
    ObjC.import("AppKit");
    const gap = Number(argv[0]);
    const screens = $.NSScreen.screens;
    for (let i = 0; i < screens.count; i++) {
        const s = screens.objectAtIndex(i);
        const left = s.auxiliaryTopLeftArea, right = s.auxiliaryTopRightArea;
        if (left.size.width > 0 && right.size.width > 0) {
            const f = s.frame;
            const notch = f.size.width - left.size.width - right.size.width;
            return [Math.round(notch + 2 * gap), Math.floor(left.origin.x + left.size.width - gap),
                    Math.round(f.origin.x), Math.round(f.origin.x + f.size.width)].join(" ");
        }
    }
    return "";
}
EOF
