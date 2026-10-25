// wallanim: a few slow animations over the wallpaper wallgen draws, run by a launch agent.
//
// A borderless, click-through window per screen sits just above the desktop picture and below
// the desktop icons. Its layers follow ~/Library/Application Support/wallgen/layout.json, which
// `wallgen apply` writes: the eyes glow, light runs down the painted streams, a scanline sweeps
// the text column, the cursor blinks, and the live counts from the SketchyBar net feed replace
// the hour-old ones, with "working" breathing while agents run.
//
// Core Animation runs these in the window server, so this process stays idle between changes.
// Animations pause while a screen's window is covered, the displays sleep, or the Mac runs on
// battery.
//
//	swiftc -O -swift-version 5 -o wallpaper/bin/wallanim wallpaper/wallanim.swift
import AppKit
import IOKit.ps

// MARK: - Layout (wallgen.swift encodes the same shape)

struct Patch: Codable {
    var rect: [Double]
    var file: String
}

struct NowMark: Codable {
    var patch: Patch
    var font: Double
}

struct ScreenLayout: Codable {
    var display: UInt32
    var width: Double, height: Double
    var eyes: [[Double]] = []
    var streams: [[Double]] = []
    var cursor: Patch?
    var now: NowMark?
    var column: [Double]?
}

struct Layout: Codable {
    var stamp: Int
    var screens: [ScreenLayout]
}

// MARK: - Look

func hex(_ v: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat((v >> 16) & 0xff) / 255, green: CGFloat((v >> 8) & 0xff) / 255, blue: CGFloat(v & 0xff) / 255, alpha: a)
}

let overlay0 = 0x6c7086 as UInt32, peach = 0xfab387 as UInt32, blue = 0x89b4fa as UInt32
let mauve = 0xcba6f7 as UInt32, red = 0xf38ba8 as UInt32, green = 0xa6e3a1 as UInt32, teal = 0x94e2d5 as UInt32

let home = FileManager.default.homeDirectoryForCurrentUser
let wallDir = home.appendingPathComponent("Library/Application Support/wallgen")
let layoutURL = wallDir.appendingPathComponent("layout.json")
let netDir = home.appendingPathComponent(".cache/sketchybar")
let netURL = netDir.appendingPathComponent("net.json")

func rect(_ a: [Double]) -> CGRect? { a.count == 4 ? CGRect(x: a[0], y: a[1], width: a[2], height: a[3]) : nil }

// The animations are slow; a low frame rate keeps the window server's work small
func paced(_ a: CAAnimation) -> CAAnimation {
    if #available(macOS 12.0, *) { a.preferredFrameRateRange = CAFrameRateRange(minimum: 8, maximum: 30, preferred: 20) }
    a.isRemovedOnCompletion = false
    return a
}

func image(_ file: String) -> CGImage? {
    guard let src = CGImageSourceCreateWithURL(wallDir.appendingPathComponent(file) as CFURL, nil) else { return nil }
    return CGImageSourceCreateImageAtIndex(src, 0, nil)
}

// The live counts, as wallgen's nowSpans draws them: (text, color) parts
func nowParts() -> [(String, UInt32)] {
    guard let data = try? Data(contentsOf: netURL),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          json["online"] as? Bool == true, let rows = json["rows"] as? [[String: Any]] else { return [("net offline", overlay0)] }
    var marks: [String: Int] = [:]
    for r in rows where r["kind"] as? String == "unit" { marks[r["mark"] as? String ?? "idle", default: 0] += 1 }
    var out: [(String, UInt32)] = [("now ", overlay0)]
    for (mark, color) in [("waiting", peach), ("working", blue), ("commanding", mauve), ("error", red), ("done", green)] {
        if let n = marks[mark], n > 0 { out += [("\(n) \(mark)", color), ("  ", overlay0)] }
    }
    return out.count == 1 ? [("now all idle", overlay0)] : Array(out.dropLast())
}

// MARK: - One screen

final class Stage {
    let screen: NSScreen
    let window: NSWindow
    let root = CALayer()  // origin top-left, like wallgen's points
    var nowLayer: CALayer?
    var nowMark: NowMark?
    var paused = false

    init(screen: NSScreen, layout: ScreenLayout?) {
        self.screen = screen
        window = NSWindow(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false, screen: screen)
        window.setFrame(screen.frame, display: false)
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)) + 1)
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.isReleasedWhenClosed = false
        let view = NSView(frame: CGRect(origin: .zero, size: screen.frame.size))
        view.wantsLayer = true
        window.contentView = view
        root.frame = view.bounds
        root.isGeometryFlipped = true
        root.contentsScale = screen.backingScaleFactor
        view.layer?.addSublayer(root)
        // A layout drawn for another resolution would sit in the wrong places
        if let layout, abs(layout.width - screen.frame.width) < 1, abs(layout.height - screen.frame.height) < 1 { build(layout) }
        window.orderFrontRegardless()
    }

    var scale: CGFloat { screen.backingScaleFactor }

    func build(_ l: ScreenLayout) {
        for e in l.eyes where e.count == 3 { eye(CGPoint(x: e[0], y: e[1]), radius: e[2]) }
        for (i, s) in l.streams.enumerated() where s.count == 3 { stream(x: s[0], top: s[1], bottom: s[2], seed: i) }
        if let c = l.column.flatMap(rect) { scanline(c) }
        if let c = l.cursor { cursor(c) }
        if let n = l.now { nowMark = n; drawNow() }
    }

    // The eyes glow and fade together, about once every seven seconds
    func eye(_ p: CGPoint, radius: Double) {
        let size = radius * 9
        let glow = CAGradientLayer()
        glow.type = .radial
        glow.colors = [hex(peach, 0.55), hex(peach, 0.16), hex(peach, 0)]
        glow.locations = [0, 0.3, 1]
        glow.startPoint = CGPoint(x: 0.5, y: 0.5)
        glow.endPoint = CGPoint(x: 1, y: 1)
        glow.frame = CGRect(x: p.x - size / 2, y: p.y - size / 2, width: size, height: size)
        glow.opacity = 0.2
        let breathe = CABasicAnimation(keyPath: "opacity")
        breathe.fromValue = 0.15
        breathe.toValue = 0.9
        breathe.duration = 3.4
        breathe.autoreverses = true
        breathe.repeatCount = .infinity
        breathe.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        glow.add(paced(breathe), forKey: "breathe")
        root.addSublayer(glow)
    }

    // A short streak of light runs down a painted line, then rests
    func stream(x: Double, top: Double, bottom: Double, seed: Int) {
        let length = 54.0
        let drop = CAGradientLayer()
        drop.colors = [hex(teal, 0), hex(teal, 0.45), hex(0xe6fffa, 0.9)]
        drop.locations = [0, 0.75, 1]
        drop.frame = CGRect(x: x - 1, y: top - length, width: 2, height: length)
        drop.opacity = 0
        // Spread the streams out so they don't fall in step
        let duration = 7.0 + Double((seed * 37) % 50) / 10
        let fall = CAKeyframeAnimation(keyPath: "position.y")
        fall.values = [top - length / 2, bottom - length / 2, bottom - length / 2]
        fall.keyTimes = [0, 0.6, 1]
        let fade = CAKeyframeAnimation(keyPath: "opacity")
        fade.values = [0, 1, 1, 0, 0]
        fade.keyTimes = [0, 0.08, 0.5, 0.6, 1]
        let group = CAAnimationGroup()
        group.animations = [fall, fade]
        group.duration = duration
        group.repeatCount = .infinity
        group.timeOffset = duration * Double((seed * 53) % 100) / 100
        drop.add(paced(group), forKey: "fall")
        root.addSublayer(drop)
    }

    // A faint band sweeps down the text column every fourteen seconds
    func scanline(_ c: CGRect) {
        let clip = CALayer()
        clip.frame = c
        clip.masksToBounds = true
        let band = CAGradientLayer()
        let h = 90.0
        band.colors = [hex(teal, 0), hex(teal, 0.07), hex(teal, 0)]
        band.frame = CGRect(x: 0, y: -h, width: c.width, height: h)
        let sweep = CAKeyframeAnimation(keyPath: "position.y")
        sweep.values = [-h / 2, c.height + h / 2, c.height + h / 2]
        sweep.keyTimes = [0, 0.45, 1]
        sweep.duration = 14
        sweep.repeatCount = .infinity
        band.add(paced(sweep), forKey: "sweep")
        clip.addSublayer(band)
        root.addSublayer(clip)
    }

    // The bare backdrop under the cursor, shown half the time, hides it: a blink
    func cursor(_ p: Patch) {
        guard let r = rect(p.rect), let img = image(p.file) else { return }
        let cover = patchLayer(img, r)
        let blink = CAKeyframeAnimation(keyPath: "opacity")
        blink.values = [0, 1]
        blink.keyTimes = [0, 0.5, 1]
        blink.calculationMode = .discrete
        blink.duration = 1.1
        blink.repeatCount = .infinity
        cover.add(paced(blink), forKey: "blink")
        root.addSublayer(cover)
    }

    func patchLayer(_ img: CGImage, _ r: CGRect) -> CALayer {
        let l = CALayer()
        l.contents = img
        l.contentsScale = scale
        l.contentsGravity = .resize
        l.frame = r
        return l
    }

    // The bare backdrop covers the drawn counts; the live ones go on top
    func drawNow() {
        nowLayer?.removeFromSuperlayer()
        nowLayer = nil
        guard let n = nowMark, let r = rect(n.patch.rect), let img = image(n.patch.file) else { return }
        let group = patchLayer(img, r)
        let font = NSFont(name: "HackNFM-Regular", size: n.font) ?? .monospacedSystemFont(ofSize: n.font, weight: .regular)
        var x = 2.0
        for (s, color) in nowParts() {
            let a = NSAttributedString(string: s, attributes: [.font: font, .foregroundColor: NSColor(cgColor: hex(color)) ?? .white])
            let size = a.size()
            let frame = CGRect(x: x, y: 1, width: ceil(size.width) + 1, height: ceil(size.height))
            if s.hasSuffix(" working") {
                let halo = CALayer()
                halo.frame = frame.insetBy(dx: -4, dy: -1)
                halo.cornerRadius = 4
                halo.backgroundColor = hex(blue, 0.16)
                halo.add(paced(pulse(from: 0, to: 1)), forKey: "pulse")
                group.addSublayer(halo)
            }
            let text = CATextLayer()
            text.string = a
            text.contentsScale = scale
            text.frame = frame
            if s.hasSuffix(" working") { text.add(paced(pulse(from: 0.55, to: 1)), forKey: "pulse") }
            group.addSublayer(text)
            x += size.width
        }
        root.addSublayer(group)
        nowLayer = group
    }

    func pulse(from: Float, to: Float) -> CABasicAnimation {
        let a = CABasicAnimation(keyPath: "opacity")
        a.fromValue = from
        a.toValue = to
        a.duration = 1.6
        a.autoreverses = true
        a.repeatCount = .infinity
        a.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        return a
    }

    func setPaused(_ p: Bool) {
        guard p != paused else { return }
        paused = p
        if p {
            root.timeOffset = root.convertTime(CACurrentMediaTime(), from: nil)
            root.speed = 0
        } else {
            let stopped = root.timeOffset
            root.speed = 1
            root.timeOffset = 0
            root.beginTime = 0
            root.beginTime = root.convertTime(CACurrentMediaTime(), from: nil) - stopped
        }
    }

    func close() {
        window.orderOut(nil)
        window.close()
    }
}

// MARK: - All screens

final class Animator {
    var stages: [Stage] = []
    var watchers: [DispatchSourceFileSystemObject] = []
    var pending: [String: DispatchWorkItem] = [:]
    var onBattery = false
    var displaysAsleep = false

    func start() {
        let nc = NotificationCenter.default, ws = NSWorkspace.shared.notificationCenter
        nc.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { [weak self] _ in self?.rebuild() }
        ws.addObserver(forName: NSWorkspace.screensDidSleepNotification, object: nil, queue: .main) { [weak self] _ in self?.displaysAsleep = true; self?.applyPause() }
        ws.addObserver(forName: NSWorkspace.screensDidWakeNotification, object: nil, queue: .main) { [weak self] _ in self?.displaysAsleep = false; self?.applyPause() }
        nc.addObserver(forName: NSWindow.didChangeOcclusionStateNotification, object: nil, queue: .main) { [weak self] _ in self?.applyPause() }
        if let source = IOPSNotificationCreateRunLoopSource({ _ in animator.powerChanged() }, nil)?.takeRetainedValue() {
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .defaultMode)
        }
        powerChanged()
        // wallgen replaces layout.json by rename and the feed replaces net.json the same way,
        // so watch their directories
        try? FileManager.default.createDirectory(at: wallDir, withIntermediateDirectories: true)
        watch(wallDir, key: "layout") { [weak self] in self?.rebuild() }
        try? FileManager.default.createDirectory(at: netDir, withIntermediateDirectories: true)
        watch(netDir, key: "net") { [weak self] in self?.stages.forEach { $0.drawNow() } }
        rebuild()
    }

    func watch(_ dir: URL, key: String, _ fire: @escaping () -> Void) {
        let fd = open(dir.path, O_EVTONLY)
        guard fd >= 0 else { return }
        let source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fd, eventMask: .write, queue: .main)
        source.setEventHandler { [weak self] in
            // A write comes as several events; act once they settle
            self?.pending[key]?.cancel()
            let work = DispatchWorkItem(block: fire)
            self?.pending[key] = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: work)
        }
        source.setCancelHandler { close(fd) }
        source.resume()
        watchers.append(source)
    }

    func rebuild() {
        stages.forEach { $0.close() }
        let layout = (try? Data(contentsOf: layoutURL)).flatMap { try? JSONDecoder().decode(Layout.self, from: $0) }
        stages = NSScreen.screens.map { screen in
            let id = (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value
            return Stage(screen: screen, layout: layout?.screens.first { $0.display == id })
        }
        applyPause()
    }

    func powerChanged() {
        let info = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let source = IOPSGetProvidingPowerSourceType(info)?.takeUnretainedValue() as String?
        onBattery = source == kIOPMBatteryPowerKey
        applyPause()
    }

    func applyPause() {
        for s in stages {
            s.setPaused(onBattery || displaysAsleep || !s.window.occlusionState.contains(.visible))
        }
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let animator = Animator()
animator.start()
app.run()
