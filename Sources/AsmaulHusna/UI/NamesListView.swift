import SwiftUI

/// Read-only list of all 99 names with check marks, read counts, today's marker
/// and an optional auto-scroll paced slow / medium / fast.
struct NamesListView: View {
    @EnvironmentObject var state: AppState
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var read: ReadStore
    @EnvironmentObject var memo: MemoStore

    @State private var cursor = 1
    @State private var wheelMonitor: Any?

    private enum Speed: String, CaseIterable, Identifiable {
        case slow, medium, fast
        var id: String { rawValue }
        var label: String { rawValue.capitalized }
        /// seconds the list rests on each name
        var interval: Double { self == .slow ? 1.6 : (self == .medium ? 0.9 : 0.45) }
        /// length of the glide to the next name
        var glide: Double { self == .slow ? 0.7 : (self == .medium ? 0.45 : 0.25) }
    }

    private var theme: AppTheme { state.activeTheme }
    private var speed: Speed { Speed(rawValue: settings.namesSpeed) ?? .medium }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            roster
        }
        .task(id: settings.namesAutoScroll ? "on-\(settings.namesSpeed)" : "off") {
            await autoScroll()
        }
        .onAppear { installWheelMonitor() }
        .onDisappear { removeWheelMonitor() }
    }

    // MARK: header

    private var header: some View {
        VStack(spacing: 9) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("The 99 Names").font(.title3.weight(.bold))
                    Text(summary).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Toggle(isOn: $settings.namesAutoScroll) {
                    Label(settings.namesAutoScroll ? "Auto-scrolling" : "Auto-scroll",
                          systemImage: settings.namesAutoScroll ? "pause.circle.fill" : "play.circle.fill")
                }
                .toggleStyle(.button)
                .controlSize(.large)
                .help("Glide down the list; scrolling with the mouse stops it.")
                Picker("", selection: $settings.namesSpeed) {
                    ForEach(Speed.allCases) { s in Text(s.label).tag(s.rawValue) }
                }
                .pickerStyle(.segmented)
                .frame(width: 210)
                .help("Slow / medium / fast reading pace for the auto-scroll.")
            }
            legend
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }

    private var summary: String {
        let seen = Names.all.filter { (read.perName[$0.id] ?? 0) > 0 }.count
        let mastered = Names.all.filter { (memo.cards[$0.id]?.box ?? 0) >= 5 }.count
        return "\(seen)/99 read · \(mastered) mastered · \(read.totalReads) total recitations"
    }

    private var legend: some View {
        HStack(spacing: 16) {
            Label("read", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
            Label("mastered", systemImage: "checkmark.seal.fill").foregroundStyle(.purple)
            Label("today", systemImage: "sun.max.fill").foregroundStyle(.orange)
            Label("not read yet", systemImage: "circle").foregroundStyle(.secondary)
            Spacer()
        }
        .font(.caption2)
    }

    // MARK: list

    private var roster: some View {
        ScrollViewReader { proxy in
            List(Names.all) { n in
                row(n)
                    .id(n.id)
                    .listRowBackground(rowBackground(n))
            }
            .listStyle(.inset)
            .onChange(of: cursor) { _, v in
                guard settings.namesAutoScroll else { return }
                withAnimation(.easeInOut(duration: speed.glide)) { proxy.scrollTo(v, anchor: .center) }
            }
        }
    }

    private func rowBackground(_ n: Husna) -> some View {
        let isToday = read.todayNames.contains { $0.id == n.id }
        let isCursor = settings.namesAutoScroll && cursor == n.id
        return RoundedRectangle(cornerRadius: 8)
            .fill(isToday ? theme.accent.opacity(0.16)
                          : (isCursor ? theme.accent.opacity(0.09) : Color.clear))
    }

    private func row(_ n: Husna) -> some View {
        let count = read.perName[n.id] ?? 0
        let box = memo.cards[n.id]?.box ?? 0
        let mastered = box >= 5
        let isToday = read.todayNames.contains { $0.id == n.id }

        return HStack(alignment: .top, spacing: 12) {
            Text("\(n.id)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 24, alignment: .trailing)
                .padding(.top, 4)

            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(n.ar)
                        .font(.title3.weight(.semibold))
                        .environment(\.layoutDirection, .rightToLeft)
                    Spacer(minLength: 10)
                    Text(n.tr)
                        .font(.callout.weight(.medium))
                        .foregroundStyle(.secondary)
                    if isToday {
                        Image(systemName: "sun.max.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                            .help("Today's name")
                    }
                }
                if settings.showTelugu {
                    Text(n.te).font(.callout).foregroundStyle(.tertiary)
                }
                HStack(spacing: 10) {
                    Text(n.en).font(.caption)
                    if settings.showMeaningTe {
                        Text(n.ta).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }

            VStack(spacing: 3) {
                Image(systemName: mastered ? "checkmark.seal.fill"
                                            : (count > 0 ? "checkmark.circle.fill" : "circle"))
                    .font(.title3)
                    .foregroundStyle(mastered ? Color.purple
                                              : (count > 0 ? Color.green : Color.secondary.opacity(0.35)))
                    .help(mastered ? "Mastered — top memorisation box"
                                   : (count > 0 ? "Read \(count) times" : "Not read yet"))
                if count > 0 {
                    Text("\(count)")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 48)
            .padding(.top, 2)
        }
        .padding(.vertical, 5)
    }

    // MARK: auto-scroll

    private func autoScroll() async {
        guard settings.namesAutoScroll else { return }
        let pause = UInt64(speed.interval * 1_000_000_000)
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: pause)
            if Task.isCancelled || !settings.namesAutoScroll { return }
            cursor = cursor % Names.all.count + 1
        }
    }

    private func installWheelMonitor() {
        guard wheelMonitor == nil else { return }
        wheelMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
            if settings.namesAutoScroll { settings.namesAutoScroll = false }
            return event
        }
    }

    private func removeWheelMonitor() {
        if let m = wheelMonitor {
            NSEvent.removeMonitor(m)
            wheelMonitor = nil
        }
    }
}
