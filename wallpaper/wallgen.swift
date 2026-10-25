// wallgen draws the desktop wallpaper from local facts: a system profile, a commit heatmap
// over ~/projects, and today's Straw Boss sessions. It renders a still image; a launch agent
// runs `wallgen apply` hourly, so the wallpaper costs nothing between runs.
//
//	wallgen apply  [--style S] [--image FILE|none]   render for every screen and set it
//	wallgen render [--style S] [--image FILE|none] --out FILE [--size WxH] [--scale N]
//
// The backdrop is wallpaper/background.png unless --image names another; none draws a plain one.
//
// Styles: terminal (default), panels, minimal. Built by install.sh with swiftc.
import AppKit
import Foundation
import SystemConfiguration

// MARK: - Palette (Catppuccin Mocha, as in sketchybar/themes/catppuccin-mocha.sh)

func hex(_ v: UInt32, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((v >> 16) & 0xff) / 255, green: CGFloat((v >> 8) & 0xff) / 255,
            blue: CGFloat(v & 0xff) / 255, alpha: alpha)
}

let crust = hex(0x11111b), mantle = hex(0x181825), base = hex(0x1e1e2e)
let surface0 = hex(0x313244), surface1 = hex(0x45475a), overlay0 = hex(0x6c7086)
let subtext0 = hex(0xa6adc8), textColor = hex(0xcdd6f4)
let green = hex(0xa6e3a1), mauve = hex(0xcba6f7), blue = hex(0x89b4fa)
let peach = hex(0xfab387), teal = hex(0x94e2d5), yellow = hex(0xf9e2af), red = hex(0xf38ba8)

// SketchyBar floats its pills over the top of the wallpaper: this band stays quiet
let barBand: CGFloat = 50
// AeroSpace's outer gap, which the bar's pills also line up with
let edge: CGFloat = 10

// MARK: - Facts

let fm = FileManager.default
let home = fm.homeDirectoryForCurrentUser

func run(_ tool: String, _ args: [String]) -> String? {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: tool)
    p.arguments = args
    let out = Pipe()
    p.standardOutput = out
    p.standardError = FileHandle.nullDevice
    do { try p.run() } catch { return nil }
    let data = out.fileHandleForReading.readDataToEndOfFile()
    p.waitUntilExit()
    return p.terminationStatus == 0 ? String(decoding: data, as: UTF8.self) : nil
}

func sysctlString(_ name: String) -> String {
    var size = 0
    guard sysctlbyname(name, nil, &size, nil, 0) == 0, size > 0 else { return "" }
    var buf = [UInt8](repeating: 0, count: size)
    guard sysctlbyname(name, &buf, &size, nil, 0) == 0 else { return "" }
    return String(decoding: buf.prefix { $0 != 0 }, as: UTF8.self)
}

func bootTime() -> Date? {
    var tv = timeval()
    var size = MemoryLayout<timeval>.size
    guard sysctlbyname("kern.boottime", &tv, &size, nil, 0) == 0 else { return nil }
    return Date(timeIntervalSince1970: TimeInterval(tv.tv_sec))
}

func duration(_ seconds: TimeInterval) -> String {
    let m = Int(seconds) / 60, d = m / 1440, h = m % 1440 / 60
    return d > 0 ? "\(d)d \(h)h" : "\(h)h \(m % 60)m"
}

func gib(_ bytes: Int64) -> String { String(format: "%.0f GB", Double(bytes) / 1e9) }

struct Facts {
    var user = NSUserName()
    // The Bonjour name; ProcessInfo's hostName can be a reverse-DNS name from the network
    var host = (SCDynamicStoreCopyLocalHostName(nil) as String?) ?? "mac"
    var rows: [(String, String)] = []

    init() {
        let v = ProcessInfo.processInfo.operatingSystemVersion
        rows.append(("os", "macOS \(v.majorVersion).\(v.minorVersion)"))
        rows.append(("chip", sysctlString("machdep.cpu.brand_string")))
        rows.append(("memory", gib(Int64(ProcessInfo.processInfo.physicalMemory))))
        if let boot = bootTime() { rows.append(("uptime", duration(Date().timeIntervalSince(boot)))) }
        let keys: Set<URLResourceKey> = [.volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey]
        if let r = try? URL(fileURLWithPath: "/").resourceValues(forKeys: keys),
           let total = r.volumeTotalCapacity, let free = r.volumeAvailableCapacityForImportantUsage {
            rows.append(("disk", "\(gib(Int64(total) - free)) / \(gib(Int64(total)))"))
        }
        if let pw = getpwuid(getuid()), let shell = pw.pointee.pw_shell {
            rows.append(("shell", URL(fileURLWithPath: String(cString: shell)).lastPathComponent))
        }
        rows.append(("wm", "AeroSpace · SketchyBar"))
        rows.append(("term", "Ghostty · herdr"))
        rows.append(("theme", "Catppuccin Mocha"))
    }
}

let git = fm.isExecutableFile(atPath: "/opt/homebrew/bin/git") ? "/opt/homebrew/bin/git" : "/usr/bin/git"
let day: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.dateFormat = "yyyy-MM-dd"
    return f
}()
var calendar: Calendar = {
    var c = Calendar(identifier: .gregorian)
    c.firstWeekday = 2  // weeks start on Monday
    return c
}()

// The repositories under ~/projects plus this checkout; a worktree (a .git file) shares its
// main repository's history, so only full clones count.
func repositories() -> [URL] {
    var out: [URL] = []
    let projects = home.appendingPathComponent("projects")
    for name in ((try? fm.contentsOfDirectory(atPath: projects.path)) ?? []).sorted() {
        let dir = projects.appendingPathComponent(name)
        var isDir: ObjCBool = false
        if fm.fileExists(atPath: dir.appendingPathComponent(".git").path, isDirectory: &isDir), isDir.boolValue {
            out.append(dir)
        }
    }
    let dotfiles = URL(fileURLWithPath: CommandLine.arguments[0]).resolvingSymlinksInPath()
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    if fm.fileExists(atPath: dotfiles.appendingPathComponent(".git").path), !out.contains(dotfiles) {
        out.append(dotfiles)
    }
    return out
}

struct Commits {
    var perDay: [String: Int] = [:]
    var week: [(String, Int)] = []  // the last seven days, per repository
    var total = 0
    var repos = 0

    init(weeks: Int) {
        let repos = repositories()
        self.repos = repos.count
        let email = run(git, ["config", "--global", "user.email"])?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let weekAgo = day.string(from: calendar.date(byAdding: .day, value: -6, to: Date())!)
        let lock = NSLock()
        var perDay: [String: Int] = [:], week: [String: Int] = [:]
        DispatchQueue.concurrentPerform(iterations: repos.count) { i in
            var args = ["-C", repos[i].path, "log", "--all", "--since=\(weeks * 7).days",
                        "--format=%ad", "--date=short"]
            if !email.isEmpty { args.append("--author=\(email)") }
            guard let out = run(git, args) else { return }
            let days = out.split(separator: "\n").map(String.init)
            lock.lock()
            for d in days { perDay[d, default: 0] += 1 }
            let recent = days.filter { $0 >= weekAgo }.count
            if recent > 0 { week[repos[i].lastPathComponent] = recent }
            lock.unlock()
        }
        self.perDay = perDay
        self.total = perDay.values.reduce(0, +)
        self.week = week.sorted { $0.value != $1.value ? $0.value > $1.value : $0.key < $1.key }
            .map { ($0.key, $0.value) }
    }
}

struct Boss {
    var active = 0   // session files written today
    var started = 0  // session files created today
    var projects: [(String, Int)] = []
    var now: [String: Int]? = nil  // the live net's marks, while the feed sees a GUI server

    init(repoNames: [String]) {
        let sessions = home.appendingPathComponent(".pi/agent/sessions")
        let start = calendar.startOfDay(for: Date())
        var per: [String: Int] = [:]
        for dir in (try? fm.contentsOfDirectory(atPath: sessions.path)) ?? [] {
            let path = sessions.appendingPathComponent(dir)
            for file in (try? fm.contentsOfDirectory(atPath: path.path)) ?? [] where file.hasSuffix(".jsonl") {
                guard let a = try? fm.attributesOfItem(atPath: path.appendingPathComponent(file).path),
                      let modified = a[.modificationDate] as? Date, modified >= start else { continue }
                active += 1
                per[Boss.project(dir, repoNames), default: 0] += 1
                if let created = a[.creationDate] as? Date, created >= start { started += 1 }
            }
        }
        projects = per.sorted { $0.value != $1.value ? $0.value > $1.value : $0.key < $1.key }
            .map { ($0.key, $0.value) }
        let cache = home.appendingPathComponent(".cache/sketchybar/net.json")
        if let data = try? Data(contentsOf: cache),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           json["online"] as? Bool == true, let rows = json["rows"] as? [[String: Any]] {
            var marks: [String: Int] = [:]
            for r in rows where r["kind"] as? String == "unit" {
                marks[r["mark"] as? String ?? "idle", default: 0] += 1
            }
            now = marks
        }
    }

    // A session directory names its cwd with "/" turned into "-" (--Users-me-projects-x--), so
    // the longest repository name it starts with is the project
    static func project(_ dir: String, _ repoNames: [String]) -> String {
        var s = dir.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        if s.contains("private-tmp") { return "tmp" }
        if let r = s.range(of: "-projects-") { s = String(s[r.upperBound...]) }
        else if s.hasPrefix("Users-\(NSUserName())-") { s = String(s.dropFirst("Users-\(NSUserName())-".count)) }
        else if s == "Users-\(NSUserName())" { return "~" }
        if let repo = repoNames.filter({ s == $0 || s.hasPrefix($0 + "-") }).max(by: { $0.count < $1.count }) {
            return repo
        }
        return s
    }
}

// MARK: - Drawing

func font(_ size: CGFloat, bold: Bool = false) -> NSFont {
    NSFont(name: bold ? "HackNFM-Bold" : "HackNFM-Regular", size: size)
        ?? NSFont.monospacedSystemFont(ofSize: size, weight: bold ? .bold : .regular)
}

final class Canvas {
    let size: CGSize
    let cg: CGContext
    var dry = false  // measure only

    init(size: CGSize, cg: CGContext) { self.size = size; self.cg = cg }

    @discardableResult
    func text(_ s: String, _ p: CGPoint, _ f: NSFont, _ c: NSColor) -> CGFloat {
        let a = NSAttributedString(string: s, attributes: [.font: f, .foregroundColor: c])
        if !dry { a.draw(at: p) }
        return a.size().width
    }

    @discardableResult
    func spans(_ parts: [(String, NSColor)], _ p: CGPoint, _ f: NSFont) -> CGFloat {
        var x = p.x
        for (s, c) in parts { x += text(s, CGPoint(x: x, y: p.y), f, c) }
        return x - p.x
    }

    func rect(_ r: CGRect, _ c: NSColor, radius: CGFloat = 0) {
        if dry { return }
        c.setFill()
        NSBezierPath(roundedRect: r, xRadius: radius, yRadius: radius).fill()
    }

    func card(_ r: CGRect) {
        if dry { return }
        let path = NSBezierPath(roundedRect: r, xRadius: 12, yRadius: 12)
        surface0.withAlphaComponent(0.55).setFill()
        path.fill()
        surface1.setStroke()
        path.lineWidth = 1
        path.stroke()
    }

    // A painted backdrop, filled to the screen; the bar's band and the left side, where the
    // facts go, are darkened so both read over it
    func backdrop(_ image: NSImage) {
        let s = image.size
        let k = max(size.width / s.width, size.height / s.height)
        let r = CGRect(x: (size.width - s.width * k) / 2, y: (size.height - s.height * k) / 2, width: s.width * k, height: s.height * k)
        image.draw(in: r, from: .zero, operation: .copy, fraction: 1, respectFlipped: true, hints: [.interpolation: NSImageInterpolation.high.rawValue])
        let space = CGColorSpace(name: CGColorSpace.sRGB)!
        // Solid under the bar, then a long fade that also hides a painted top edge
        let top = CGGradient(colorsSpace: space, colors: [crust.cgColor, crust.cgColor, crust.withAlphaComponent(0).cgColor] as CFArray,
                             locations: [0, 0.45, 1])!
        cg.drawLinearGradient(top, start: .zero, end: CGPoint(x: 0, y: barBand + 90), options: [])
        let left = CGGradient(colorsSpace: space, colors: [crust.withAlphaComponent(0.6).cgColor, crust.withAlphaComponent(0).cgColor] as CFArray, locations: [0, 1])!
        cg.drawLinearGradient(left, start: .zero, end: CGPoint(x: size.width * 0.5, y: 0), options: [])
        NSColor.black.withAlphaComponent(0.04).setFill()
        var y: CGFloat = 0
        while y < size.height { NSBezierPath(rect: CGRect(x: 0, y: y, width: size.width, height: 1)).fill(); y += 3 }
    }

    // Crust at the top fading to base, a dot grid, faint scanlines, and darker corners
    func background() {
        let space = CGColorSpace(name: CGColorSpace.sRGB)!
        let fade = CGGradient(colorsSpace: space, colors: [crust.cgColor, mantle.cgColor, base.cgColor] as CFArray,
                              locations: [0, 0.12, 1])!
        cg.drawLinearGradient(fade, start: .zero, end: CGPoint(x: 0, y: size.height), options: [])
        let dot = surface0.withAlphaComponent(0.7)
        dot.setFill()
        let step: CGFloat = 24
        var y = barBand + step
        while y < size.height {
            var x = edge + step / 2
            while x < size.width {
                NSBezierPath(ovalIn: CGRect(x: x - 0.9, y: y - 0.9, width: 1.8, height: 1.8)).fill()
                x += step
            }
            y += step
        }
        NSColor.black.withAlphaComponent(0.05).setFill()
        y = 0
        while y < size.height { NSBezierPath(rect: CGRect(x: 0, y: y, width: size.width, height: 1)).fill(); y += 3 }
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let vignette = CGGradient(colorsSpace: space, colors: [NSColor.clear.cgColor, crust.withAlphaComponent(0.55).cgColor] as CFArray,
                                  locations: [0.55, 1])!
        cg.drawRadialGradient(vignette, startCenter: center, startRadius: 0, endCenter: center,
                              endRadius: hypot(size.width, size.height) / 2, options: [.drawsAfterEndLocation])
    }

    var painted = false

    // The hostname, large and faint, in the lower right; a painted backdrop has its own subject
    func watermark(_ s: String) {
        if painted { return }
        let f = font(min(140, size.width / 9), bold: true)
        let a = NSAttributedString(string: s.lowercased(), attributes: [.font: f, .foregroundColor: surface0.withAlphaComponent(0.45)])
        let w = a.size()
        if !dry { a.draw(at: CGPoint(x: size.width - w.width - edge - 20, y: size.height - w.height - 4)) }
    }
}

struct Look {
    let f: NSFont, b: NSFont, small: NSFont
    let line: CGFloat, cell: CGFloat, gap: CGFloat

    init(scale: CGFloat) {
        f = font(14 * scale)
        b = font(14 * scale, bold: true)
        small = font(11 * scale)
        line = 21 * scale
        cell = 13 * scale
        gap = 3 * scale
    }
}

// Each block draws at its top-left corner and returns its size; with canvas.dry it only measures.

func drawFacts(_ c: Canvas, _ facts: Facts, _ at: CGPoint, _ k: Look) -> CGSize {
    var w: CGFloat = 0, y = at.y
    for (key, value) in facts.rows {
        let kw = c.text(key.padding(toLength: 8, withPad: " ", startingAt: 0), CGPoint(x: at.x, y: y), k.b, mauve)
        w = max(w, kw + c.text(value, CGPoint(x: at.x + kw, y: y), k.f, textColor))
        y += k.line
    }
    return CGSize(width: w, height: y - at.y)
}

// Quartiles of the active days, so a few huge days do not flatten the rest into one shade
func thresholds(_ counts: [Int]) -> [Int] {
    let active = counts.filter { $0 > 0 }.sorted()
    guard !active.isEmpty else { return [1, 1, 1] }
    return [0.25, 0.5, 0.75].map { active[min(active.count - 1, Int(Double(active.count) * $0))] }
}

func level(_ n: Int, _ t: [Int]) -> Int {
    n == 0 ? 0 : n >= t[2] ? 4 : n >= t[1] ? 3 : n >= t[0] ? 2 : 1
}

func drawHeat(_ c: Canvas, _ commits: Commits, weeks: Int, _ at: CGPoint, _ k: Look) -> CGSize {
    let today = calendar.startOfDay(for: Date())
    let weekday = (calendar.component(.weekday, from: today) + 5) % 7  // Monday 0
    let thisWeek = calendar.date(byAdding: .day, value: -weekday, to: today)!
    let labelW = c.text("Mon ", .zero, k.small, .clear)
    let monthH = k.line
    let peak = thresholds(Array(commits.perDay.values))
    let shades = [surface0, green.withAlphaComponent(0.3), green.withAlphaComponent(0.5),
                  green.withAlphaComponent(0.75), green]
    for (r, name) in ["Mon", "", "Wed", "", "Fri", "", ""].enumerated() where !name.isEmpty {
        c.text(name, CGPoint(x: at.x, y: at.y + monthH + CGFloat(r) * (k.cell + k.gap) - k.gap / 2), k.small, overlay0)
    }
    var lastMonth = -1
    let months = DateFormatter().shortMonthSymbols!
    for w in 0..<weeks {
        let start = calendar.date(byAdding: .day, value: (w - weeks + 1) * 7, to: thisWeek)!
        let x = at.x + labelW + CGFloat(w) * (k.cell + k.gap)
        let month = calendar.component(.month, from: start)
        if month != lastMonth {
            // A month that starts in the first two columns would crowd the next label
            let next = calendar.date(byAdding: .day, value: 14, to: start)!
            if w > 0 || calendar.component(.month, from: next) == month {
                c.text(months[month - 1], CGPoint(x: x, y: at.y), k.small, overlay0)
            }
            lastMonth = month
        }
        for d in 0..<7 {
            let date = calendar.date(byAdding: .day, value: d, to: start)!
            if date > today { continue }
            let cell = CGRect(x: x, y: at.y + monthH + CGFloat(d) * (k.cell + k.gap), width: k.cell, height: k.cell)
            c.rect(cell, shades[level(commits.perDay[day.string(from: date)] ?? 0, peak)], radius: k.cell * 0.22)
            if date == today, !c.dry {
                peach.setStroke()
                let ring = NSBezierPath(roundedRect: cell.insetBy(dx: -1.5, dy: -1.5), xRadius: k.cell * 0.3, yRadius: k.cell * 0.3)
                ring.lineWidth = 1.5
                ring.stroke()
            }
        }
    }
    return CGSize(width: labelW + CGFloat(weeks) * (k.cell + k.gap) - k.gap, height: monthH + 7 * (k.cell + k.gap) - k.gap)
}

func drawBars(_ c: Canvas, _ rows: [(String, Int)], color: NSColor, limit: Int, _ at: CGPoint, _ k: Look) -> CGSize {
    let shown = Array(rows.prefix(limit))
    guard let peak = shown.first?.1, peak > 0 else {
        let w = c.text("—", at, k.f, overlay0)
        return CGSize(width: w, height: k.line)
    }
    let nameW = c.text(String(repeating: "m", count: 18), .zero, k.f, .clear)
    let barMax = k.cell * 14
    var y = at.y, w: CGFloat = 0
    for (name, n) in shown {
        let label = name.count > 17 ? String(name.prefix(16)) + "…" : name
        c.text(label, CGPoint(x: at.x, y: y), k.f, subtext0)
        let len = max(k.gap, barMax * CGFloat(n) / CGFloat(peak))
        c.rect(CGRect(x: at.x + nameW, y: y + k.line * 0.22, width: len, height: k.line * 0.5), color.withAlphaComponent(0.85), radius: 2)
        let nw = c.text("\(n)", CGPoint(x: at.x + nameW + len + k.gap * 2, y: y), k.b, textColor)
        w = max(w, nameW + len + k.gap * 2 + nw)
        y += k.line
    }
    return CGSize(width: w, height: y - at.y)
}

func nowSpans(_ boss: Boss) -> [(String, NSColor)] {
    guard let now = boss.now else { return [("net offline", overlay0)] }
    var out: [(String, NSColor)] = [("now ", overlay0)]
    for (mark, color) in [("waiting", peach), ("working", blue), ("commanding", mauve), ("error", red), ("done", green)] {
        if let n = now[mark], n > 0 { out += [("\(n) \(mark)", color), ("  ", overlay0)] }
    }
    return out.count == 1 ? [("now all idle", overlay0)] : Array(out.dropLast())
}

func numbered(_ n: Int) -> String {
    let f = NumberFormatter()
    f.numberStyle = .decimal
    return f.string(from: NSNumber(value: n)) ?? "\(n)"
}

// MARK: - Styles

let heatWeeks = 26

func updated() -> String {
    let f = DateFormatter()
    f.dateFormat = "EEE d MMM HH:mm"
    f.locale = Locale(identifier: "en_US_POSIX")
    return f.string(from: Date())
}

// A terminal session typed out on the desktop
func styleTerminal(_ c: Canvas, _ facts: Facts, _ commits: Commits, _ boss: Boss) {
    let k = Look(scale: c.size.width >= 1400 ? 1 : 0.85)
    let x = edge + 46
    var y = barBand + max(40, (c.size.height - barBand) * 0.08)
    let prompt: (String) -> Void = { cmd in
        c.spans([("\(facts.user)@\(facts.host)", mauve), (" ~ ", blue), ("❯ ", green), (cmd, textColor)], CGPoint(x: x, y: y), k.b)
        y += k.line * 1.4
    }
    let indent = x + k.cell * 1.5
    prompt("fastfetch")
    y += drawFacts(c, facts, CGPoint(x: indent, y: y), k).height + k.line
    prompt("git heat --weeks \(heatWeeks)")
    y += drawHeat(c, commits, weeks: heatWeeks, CGPoint(x: indent, y: y), k).height + k.line * 0.6
    c.spans([(numbered(commits.total), green), (" commits · \(commits.repos) repos · last 7 days", overlay0)], CGPoint(x: indent, y: y), k.f)
    y += k.line * 1.3
    y += drawBars(c, commits.week, color: green, limit: 5, CGPoint(x: indent, y: y), k).height + k.line
    prompt("boss today")
    c.spans([("\(boss.active)", peach), (" sessions · ", overlay0), ("\(boss.started)", peach), (" started   ", overlay0)] + nowSpans(boss),
            CGPoint(x: indent, y: y), k.f)
    y += k.line * 1.3
    y += drawBars(c, boss.projects, color: peach, limit: 5, CGPoint(x: indent, y: y), k).height + k.line
    let w = c.spans([("\(facts.user)@\(facts.host)", mauve), (" ~ ", blue), ("❯ ", green)], CGPoint(x: x, y: y), k.b)
    c.rect(CGRect(x: x + w, y: y + k.line * 0.1, width: k.cell * 0.65, height: k.line * 0.8), textColor.withAlphaComponent(0.85))
    c.text("updated \(updated())", CGPoint(x: x + w + k.cell * 2, y: y), k.small, overlay0)
    c.watermark(facts.host)
}

// Three cards in a row, styled like the bar's pills
func stylePanels(_ c: Canvas, _ facts: Facts, _ commits: Commits, _ boss: Boss) {
    let k = Look(scale: c.size.width >= 1400 ? 1 : 0.85)
    let pad = k.cell * 1.5, head = k.line * 1.6
    func measure(_ draw: (CGPoint) -> CGSize) -> CGSize {
        c.dry = true
        defer { c.dry = false }
        return draw(.zero)
    }
    let blocks: [(String, String, NSColor, (CGPoint) -> CGSize)] = [
        ("\u{f179}", "\(facts.user)@\(facts.host)", mauve, { drawFacts(c, facts, $0, k) }),
        ("\u{e702}", "commits · \(numbered(commits.total)) in \(heatWeeks) weeks", green, { p in
            let h = drawHeat(c, commits, weeks: heatWeeks, p, k)
            let b = drawBars(c, commits.week, color: green, limit: 3, CGPoint(x: p.x, y: p.y + h.height + k.line * 0.8), k)
            return CGSize(width: max(h.width, b.width), height: h.height + k.line * 0.8 + b.height)
        }),
        ("\u{f06a9}", "straw boss · \(boss.active) sessions today", peach, { p in
            let w = c.spans(nowSpans(boss), p, k.f)
            let b = drawBars(c, boss.projects, color: peach, limit: 6, CGPoint(x: p.x, y: p.y + k.line * 1.5), k)
            return CGSize(width: max(w, b.width), height: k.line * 1.5 + b.height)
        }),
    ]
    let sizes = blocks.map { measure($0.3) }
    let gap = k.cell * 2
    let height = (sizes.map(\.height).max() ?? 0) + head + pad * 2
    let total = sizes.reduce(0) { $0 + $1.width + pad * 2 } + gap * CGFloat(blocks.count - 1)
    var x = (c.size.width - total) / 2
    let y = barBand + (c.size.height - barBand - height) * 0.42
    c.text(updated().uppercased(), CGPoint(x: x, y: y - k.line * 1.6), k.b, overlay0)
    for (i, (icon, title, color, draw)) in blocks.enumerated() {
        let w = sizes[i].width + pad * 2
        c.card(CGRect(x: x, y: y, width: w, height: height))
        c.spans([(icon + "  ", color), (title, textColor)], CGPoint(x: x + pad, y: y + pad), k.b)
        _ = draw(CGPoint(x: x + pad, y: y + pad + head))
        x += w + gap
    }
    c.watermark(facts.host)
}

// One large heatmap and a line under it
func styleMinimal(_ c: Canvas, _ facts: Facts, _ commits: Commits, _ boss: Boss) {
    let base = Look(scale: c.size.width >= 1400 ? 1 : 0.85)
    let k = Look(scale: base.line / 21 * 1.9)
    c.dry = true
    let size = drawHeat(c, commits, weeks: heatWeeks, .zero, k)
    c.dry = false
    let at = CGPoint(x: (c.size.width - size.width) / 2, y: barBand + (c.size.height - barBand - size.height) * 0.42)
    _ = drawHeat(c, commits, weeks: heatWeeks, at, k)
    let parts: [(String, NSColor)] = [("\(facts.user)@\(facts.host)", mauve), ("  ·  ", overlay0),
                                      (numbered(commits.total), green), (" commits in \(heatWeeks) weeks", overlay0), ("  ·  ", overlay0),
                                      ("\(boss.active)", peach), (" sessions today  ", overlay0)] + nowSpans(boss)
    c.dry = true
    let w = c.spans(parts, .zero, base.b)
    c.dry = false
    c.spans(parts, CGPoint(x: (c.size.width - w) / 2, y: at.y + size.height + base.line * 1.5), base.b)
    let u = "updated \(updated())"
    c.dry = true
    let uw = c.text(u, .zero, base.small, overlay0)
    c.dry = false
    c.text(u, CGPoint(x: (c.size.width - uw) / 2, y: at.y + size.height + base.line * 3), base.small, overlay0)
}

let styles: [String: (Canvas, Facts, Commits, Boss) -> Void] = [
    "terminal": styleTerminal, "panels": stylePanels, "minimal": styleMinimal,
]

func render(style: String, size: CGSize, scale: CGFloat, image: NSImage?, facts: Facts, commits: Commits, boss: Boss) -> Data? {
    guard let draw = styles[style],
          let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size.width * scale), pixelsHigh: Int(size.height * scale),
                                     bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                     colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0),
          let ctx = NSGraphicsContext(bitmapImageRep: rep) else { return nil }
    // Draw in points: flip to a top-left origin and scale to the pixel grid
    let cg = ctx.cgContext
    cg.translateBy(x: 0, y: size.height * scale)
    cg.scaleBy(x: scale, y: -scale)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: cg, flipped: true)
    let canvas = Canvas(size: size, cg: cg)
    if let image {
        canvas.backdrop(image)
        canvas.painted = true
    } else {
        canvas.background()
    }
    draw(canvas, facts, commits, boss)
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])
}

// MARK: - Main

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("wallgen: \(message)\n".utf8))
    exit(1)
}

var args = Array(CommandLine.arguments.dropFirst())
let command = args.isEmpty ? "apply" : args.removeFirst()
var options: [String: String] = [:]
while args.count >= 2, args[0].hasPrefix("--") { options[String(args.removeFirst().dropFirst(2))] = args.removeFirst() }
if !args.isEmpty { fail("usage: wallgen apply [--style S] [--image FILE|none] | render [--style S] [--image FILE|none] --out FILE [--size WxH] [--scale N]") }
let style = options["style"] ?? "terminal"
// wallpaper/background.png beside the source, unless --image names another or "none"
let imagePath = options["image"] ?? URL(fileURLWithPath: CommandLine.arguments[0]).resolvingSymlinksInPath()
    .deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("background.png").path
let image = imagePath == "none" ? nil : NSImage(contentsOfFile: imagePath)
if imagePath != "none", options["image"] != nil, image == nil { fail("cannot read \(imagePath)") }
if styles[style] == nil { fail("unknown style \(style); styles: \(styles.keys.sorted().joined(separator: ", "))") }

_ = NSApplication.shared
let facts = Facts()
let commits = Commits(weeks: heatWeeks)
let boss = Boss(repoNames: repositories().map(\.lastPathComponent))

switch command {
case "render":
    guard let out = options["out"] else { fail("render needs --out") }
    var size = NSScreen.main?.frame.size ?? CGSize(width: 1512, height: 982)
    if let s = options["size"] {
        let p = s.split(separator: "x").compactMap { Double($0) }
        guard p.count == 2 else { fail("--size is WxH in points") }
        size = CGSize(width: p[0], height: p[1])
    }
    let scale = CGFloat(Double(options["scale"] ?? "") ?? Double(NSScreen.main?.backingScaleFactor ?? 2))
    guard let png = render(style: style, size: size, scale: scale, image: image, facts: facts, commits: commits, boss: boss) else { fail("render failed") }
    do { try png.write(to: URL(fileURLWithPath: out)) } catch { fail("write \(out): \(error.localizedDescription)") }
case "apply":
    // A new file name each run: macOS keeps showing a cached image for a path it already set
    let dir = home.appendingPathComponent("Library/Application Support/wallgen")
    do { try fm.createDirectory(at: dir, withIntermediateDirectories: true) } catch { fail("create \(dir.path): \(error.localizedDescription)") }
    let stamp = Int(Date().timeIntervalSince1970)
    var keep: Set<String> = []
    for (i, screen) in NSScreen.screens.enumerated() {
        guard let png = render(style: style, size: screen.frame.size, scale: screen.backingScaleFactor, image: image,
                               facts: facts, commits: commits, boss: boss) else { fail("render failed") }
        let file = dir.appendingPathComponent("screen\(i)-\(stamp).png")
        do {
            try png.write(to: file)
            try NSWorkspace.shared.setDesktopImageURL(file, for: screen, options: [
                .imageScaling: NSImageScaling.scaleProportionallyUpOrDown.rawValue, .allowClipping: true,
            ])
        } catch { fail("set wallpaper: \(error.localizedDescription)") }
        keep.insert(file.lastPathComponent)
    }
    for old in (try? fm.contentsOfDirectory(atPath: dir.path)) ?? [] where old.hasSuffix(".png") && !keep.contains(old) {
        try? fm.removeItem(at: dir.appendingPathComponent(old))
    }
default:
    fail("unknown command \(command)")
}
