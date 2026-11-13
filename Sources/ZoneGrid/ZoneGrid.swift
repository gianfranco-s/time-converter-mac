import SwiftUI
import AppKit

// ZoneGrid: menu bar timezone planner.
// Pick a local time with the slider; see the matching time in every saved city,
// plus a 24-hour strip per city (green = work hours, yellow = awake, gray = night).
//
// Build:  swiftc -parse-as-library -O ZoneGrid.swift -o ZoneGrid
// Run:    ./ZoneGrid &        (needs macOS 13+ and the Xcode command line tools)

@main
struct ZoneGridApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        Settings { EmptyView() }   // no windows; the UI lives in the status item's popover
    }
}

/// Menu bar icon: left click toggles the planner, right click (or ctrl-click) shows a Quit menu.
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let model = Model()
    private var statusItem: NSStatusItem!
    private let popover = NSPopover()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Menu bar only, no Dock icon.
        NSApplication.shared.setActivationPolicy(.accessory)

        let host = NSHostingController(rootView: ContentView().environmentObject(model))
        host.sizingOptions = [.preferredContentSize]
        popover.contentViewController = host
        popover.behavior = .transient

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "clock", accessibilityDescription: "ZoneGrid")
            button.target = self
            button.action = #selector(clicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    @objc private func clicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp || event.modifierFlags.contains(.control) {
            popover.performClose(nil)
            let menu = NSMenu()
            menu.addItem(withTitle: "Quit ZoneGrid", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
            statusItem.menu = menu
            sender.performClick(nil)   // show the menu under the icon
            statusItem.menu = nil      // restore custom click handling
        } else if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

final class Model: ObservableObject {
    @Published var zoneIDs: [String] {
        didSet { UserDefaults.standard.set(zoneIDs, forKey: "zoneIDs") }
    }
    @Published var homeID: String {
        didSet { UserDefaults.standard.set(homeID, forKey: "homeID") }
    }
    var rowStep: CGFloat = 44   // measured row height + spacing, used for drag reordering
    @Published var minutes: Double = 14 * 60   // chosen HOME time, minutes since midnight

    private let utc: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(secondsFromGMT: 0)!
        return c
    }()

    init() {
        zoneIDs = UserDefaults.standard.stringArray(forKey: "zoneIDs")
            ?? ["America/New_York", "Europe/London"]
        homeID = UserDefaults.standard.string(forKey: "homeID") ?? TimeZone.current.identifier
        zoneIDs.removeAll { $0 == homeID }
    }

    var home: TimeZone { TimeZone(identifier: homeID) ?? .current }

    /// Make `id` the home city; the previous home becomes a regular, removable city.
    func setHome(_ id: String) {
        guard id != homeID else { return }
        let old = homeID
        zoneIDs.removeAll { $0 == id }
        if !zoneIDs.contains(old) { zoneIDs.insert(old, at: 0) }
        homeID = id
    }

    var startOfDay: Date { cal(home).startOfDay(for: Date()) }
    var selected: Date { homeDate(minutes: minutes) }

    /// Wall-clock time `minutes` after midnight in the home zone, today. Built from calendar
    /// components (not seconds) so it stays correct on 23/25-hour DST transition days.
    func homeDate(minutes: Double) -> Date {
        let m = Int(minutes)
        return cal(home).date(bySettingHour: m / 60, minute: m % 60, second: 0, of: Date())
            ?? startOfDay.addingTimeInterval(minutes * 60)
    }

    func setNow() {
        let c = cal(home).dateComponents([.hour, .minute], from: Date())
        let m = Double((c.hour ?? 0) * 60 + (c.minute ?? 0))
        minutes = min(1425, (m / 15).rounded() * 15)
    }

    func cal(_ tz: TimeZone) -> Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = tz
        return c
    }

    func timeString(_ d: Date, _ tz: TimeZone) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = tz
        f.dateFormat = "HH:mm"
        return f.string(from: d)
    }

    func name(_ tz: TimeZone) -> String {
        let id = tz.identifier
        return (id.split(separator: "/").last.map(String.init) ?? id)
            .replacingOccurrences(of: "_", with: " ")
    }

    /// Whole days the city's calendar date differs from the local date at `d`.
    func dayOffset(_ d: Date, _ tz: TimeZone) -> Int {
        let a = cal(home).dateComponents([.year, .month, .day], from: d)
        let b = cal(tz).dateComponents([.year, .month, .day], from: d)
        guard let da = utc.date(from: a), let db = utc.date(from: b) else { return 0 }
        return Int((db.timeIntervalSince(da) / 86400).rounded())
    }

    func offsetLabel(_ tz: TimeZone) -> String {
        let secs = tz.secondsFromGMT(for: selected) - home.secondsFromGMT(for: selected)
        guard secs != 0 else { return "" }
        let a = abs(secs) / 60
        let sign = secs < 0 ? "-" : "+"
        return a % 60 == 0 ? "\(sign)\(a / 60)" : String(format: "%@%d:%02d", sign, a / 60, a % 60)
    }
}

struct ContentView: View {
    @EnvironmentObject var m: Model
    @State private var query = ""
    @State private var adding = false
    @FocusState private var searchFocused: Bool

    var matches: [String] {
        let q = query.lowercased().trimmingCharacters(in: .whitespaces)
        guard q.count >= 2 else { return [] }
        return TimeZone.knownTimeZoneIdentifiers
            .filter { $0.lowercased().replacingOccurrences(of: "_", with: " ").contains(q) }
            .filter { !m.zoneIDs.contains($0) && $0 != m.homeID }
            .prefix(6).map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("When it's").font(.headline)
                Text(m.timeString(m.selected, m.home)).font(.headline.monospacedDigit())
                Text("in \(m.name(m.home))").foregroundStyle(.secondary)
                Spacer()
                Button("Now") { m.setNow() }
                Button {
                    adding.toggle()
                    query = ""
                    if adding { searchFocused = true }
                } label: {
                    Image(systemName: adding ? "minus" : "plus")
                }
                .buttonStyle(.borderless)
                .help(adding ? "Hide add city" : "Add city")
            }

            Slider(value: $m.minutes, in: 0...1425, step: 15)

            CityRow(tz: m.home, isHome: true)
            ForEach(m.zoneIDs, id: \.self) { id in
                if let tz = TimeZone(identifier: id) {
                    CityRow(tz: tz, isHome: false)
                }
            }

            if adding {
                Divider()
                TextField("Add city (e.g. Tokyo, Madrid, New York)", text: $query)
                    .textFieldStyle(.roundedBorder)
                    .focused($searchFocused)
                ForEach(matches, id: \.self) { id in
                    Button(id.replacingOccurrences(of: "_", with: " ")) {
                        m.zoneIDs.append(id)
                        query = ""
                        adding = false
                    }.buttonStyle(.link)
                }
            }
        }
        .padding(14)
        .frame(width: 820)
    }
}

struct CityRow: View {
    @EnvironmentObject var m: Model
    let tz: TimeZone
    let isHome: Bool
    @State private var dragStart: Int?
    @State private var dragY: CGFloat = 0

    var body: some View {
        let off = m.dayOffset(m.selected, tz)
        HStack(spacing: 8) {
            Image(systemName: "line.3.horizontal")
                .foregroundStyle(.secondary)
                .opacity(isHome ? 0 : 1)
                .frame(width: 24, height: 30)
                .contentShape(Rectangle())
                .gesture(isHome ? nil : reorderGesture)
            VStack(alignment: .leading, spacing: 0) {
                Text(m.name(tz)).font(.system(size: 13, weight: .semibold))
                Text(isHome ? "home" : m.offsetLabel(tz))
                    .font(.caption).foregroundStyle(.secondary)
            }
            .frame(width: 90, alignment: .leading)

            VStack(alignment: .trailing, spacing: 0) {
                Text(m.timeString(m.selected, tz)).font(.system(size: 15, weight: .bold).monospacedDigit())
                Text(off == 0 ? " " : (off > 0 ? "+\(off) day" : "\(off) day"))
                    .font(.caption2).foregroundStyle(.orange)
            }
            .frame(width: 60, alignment: .trailing)

            HStack(spacing: 1) {
                ForEach(0..<24, id: \.self) { h in strip(h) }
            }

            if !isHome {
                Button { m.setHome(tz.identifier) } label: { Image(systemName: "house") }
                    .buttonStyle(.borderless)
                    .help("Set as home")
                Button {
                    m.zoneIDs.removeAll { $0 == tz.identifier }
                } label: { Image(systemName: "xmark.circle") }
                    .buttonStyle(.borderless)
                    .help("Remove")
            } else {
                Image(systemName: "house.fill").foregroundStyle(.secondary)
                Color.clear.frame(width: 16, height: 1)
            }
        }
        .background(GeometryReader { g in
            Color.clear.onAppear { m.rowStep = g.size.height + 10 }
        })
        .offset(y: dragY)
        .zIndex(dragStart == nil ? 0 : 1)
    }

    /// Live drag-to-reorder: the row follows the cursor, neighbours shift as it passes them.
    /// Only indices within `zoneIDs` are reachable, so the home row always stays first.
    var reorderGesture: some Gesture {
        DragGesture(minimumDistance: 2, coordinateSpace: .global)
            .onChanged { v in
                guard let cur = m.zoneIDs.firstIndex(of: tz.identifier) else { return }
                let start = dragStart ?? cur
                dragStart = start
                let t = v.translation.height
                let target = min(max(start + Int((t / m.rowStep).rounded()), 0), m.zoneIDs.count - 1)
                var idx = cur
                if target != cur {
                    m.zoneIDs.move(fromOffsets: [cur], toOffset: target > cur ? target + 1 : target)
                    idx = target
                }
                dragY = t - CGFloat(idx - start) * m.rowStep
            }
            .onEnded { _ in
                withAnimation(.easeOut(duration: 0.15)) { dragY = 0 }
                dragStart = nil
            }
    }

    @ViewBuilder
    func strip(_ h: Int) -> some View {
        let d = m.homeDate(minutes: Double(h) * 60)
        let c = m.cal(tz)
        let hr = c.component(.hour, from: d)
        let label = hr == 0 ? "\(c.component(.day, from: d))" : "\(hr)"
        let color: Color = (9..<18).contains(hr) ? .green.opacity(0.35)
            : ((7..<9).contains(hr) || (18..<22).contains(hr)) ? .yellow.opacity(0.25)
            : .gray.opacity(0.25)
        let selected = h == Int(m.minutes / 60)
        Text(label)
            .font(.system(size: 10, weight: hr == 0 ? .bold : .regular).monospacedDigit())
            .frame(width: 20, height: 26)
            .background(color)
            .overlay(RoundedRectangle(cornerRadius: 3)
                .stroke(selected ? Color.primary : .clear, lineWidth: 2))
    }
}
