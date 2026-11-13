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
    @StateObject private var model = Model()

    init() {
        // Menu bar only, no Dock icon.
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        MenuBarExtra("ZoneGrid", systemImage: "clock") {
            ContentView().environmentObject(model)
        }
        .menuBarExtraStyle(.window)
    }
}

final class Model: ObservableObject {
    @Published var zoneIDs: [String] {
        didSet { UserDefaults.standard.set(zoneIDs, forKey: "zoneIDs") }
    }
    @Published var minutes: Double = 14 * 60   // chosen LOCAL time, minutes since midnight

    private let utc: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(secondsFromGMT: 0)!
        return c
    }()

    init() {
        zoneIDs = UserDefaults.standard.stringArray(forKey: "zoneIDs")
            ?? ["America/New_York", "Europe/London"]
    }

    var startOfDay: Date { Calendar.current.startOfDay(for: Date()) }
    var selected: Date { startOfDay.addingTimeInterval(minutes * 60) }

    func setNow() {
        let c = Calendar.current.dateComponents([.hour, .minute], from: Date())
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
        let a = Calendar.current.dateComponents([.year, .month, .day], from: d)
        let b = cal(tz).dateComponents([.year, .month, .day], from: d)
        guard let da = utc.date(from: a), let db = utc.date(from: b) else { return 0 }
        return Int((db.timeIntervalSince(da) / 86400).rounded())
    }

    func offsetLabel(_ tz: TimeZone) -> String {
        let diff = (tz.secondsFromGMT(for: selected) - TimeZone.current.secondsFromGMT(for: selected)) / 3600
        return diff == 0 ? "" : String(format: "%+d", diff)
    }
}

struct ContentView: View {
    @EnvironmentObject var m: Model
    @State private var query = ""

    var matches: [String] {
        let q = query.lowercased().trimmingCharacters(in: .whitespaces)
        guard q.count >= 2 else { return [] }
        return TimeZone.knownTimeZoneIdentifiers
            .filter { $0.lowercased().replacingOccurrences(of: "_", with: " ").contains(q) }
            .filter { !m.zoneIDs.contains($0) }
            .prefix(6).map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("When it's").font(.headline)
                Text(m.timeString(m.selected, .current)).font(.headline.monospacedDigit())
                Text("in \(m.name(.current))").foregroundStyle(.secondary)
                Spacer()
                Button("Now") { m.setNow() }
                Button { NSApplication.shared.terminate(nil) } label: {
                    Image(systemName: "power")
                }.buttonStyle(.borderless)
            }

            Slider(value: $m.minutes, in: 0...1425, step: 15)

            CityRow(tz: .current, isLocal: true)
            ForEach(m.zoneIDs, id: \.self) { id in
                if let tz = TimeZone(identifier: id) {
                    CityRow(tz: tz, isLocal: false)
                }
            }

            Divider()
            TextField("Add city (e.g. Tokyo, Madrid, New York)", text: $query)
                .textFieldStyle(.roundedBorder)
            ForEach(matches, id: \.self) { id in
                Button(id.replacingOccurrences(of: "_", with: " ")) {
                    m.zoneIDs.append(id)
                    query = ""
                }.buttonStyle(.link)
            }
        }
        .padding(14)
        .frame(width: 700)
    }
}

struct CityRow: View {
    @EnvironmentObject var m: Model
    let tz: TimeZone
    let isLocal: Bool

    var body: some View {
        let off = m.dayOffset(m.selected, tz)
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 0) {
                Text(m.name(tz)).font(.system(size: 13, weight: .semibold))
                Text(isLocal ? "here" : m.offsetLabel(tz))
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

            if !isLocal {
                Button {
                    m.zoneIDs.removeAll { $0 == tz.identifier }
                } label: { Image(systemName: "xmark.circle") }
                    .buttonStyle(.borderless)
            } else {
                Color.clear.frame(width: 16, height: 1)
            }
        }
    }

    @ViewBuilder
    func strip(_ h: Int) -> some View {
        let d = m.startOfDay.addingTimeInterval(Double(h) * 3600)
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
