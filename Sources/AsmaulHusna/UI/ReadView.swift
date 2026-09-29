import SwiftUI

struct ReadView: View {
    @EnvironmentObject var state: AppState
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var read: ReadStore

    @State private var pick = 0
    @State private var orbitX: Double = -5
    @State private var orbitY: Double = 7
    @State private var dragBusy = false

    private var theme: AppTheme { state.activeTheme }
    private var names: [Husna] { read.todayNames }
    private var husna: Husna { names[min(pick, names.count - 1)] }
    private var count: Int { read.reads(on: read.todayKey, name: husna.id) }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                header
                if names.count > 1 { namePicker }
                card
                if settings.showDua { duaCard }
                if settings.showHadith { hadithCard }
                controls
            }
            .padding(24)
            .frame(maxWidth: 900)
        }
        .background(Color.clear)
        .onAppear(perform: registerKeys)
        .onDisappear(perform: unregisterKeys)
    }

    // MARK: header

    private var header: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Day \(read.dayIndex + 1) of the 99-day cycle")
                    .font(.caption).foregroundStyle(.secondary)
                Text(husna.tr)
                    .font(.title2.weight(.bold))
                Text("Name #\(husna.id) of 99")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(spacing: 4) {
                RingView(progress: read.todayProgress, color: theme.accent, lineWidth: 11,
                         label: "\(read.todayTotal)/\(read.targetForToday)")
                    .frame(width: 68, height: 68)
                Text("today").font(.caption2).foregroundStyle(.secondary)
            }
            VStack(spacing: 4) {
                Image(systemName: "flame.fill").font(.title2).foregroundStyle(.orange)
                Text("\(read.streak)").font(.title3.weight(.bold).monospacedDigit())
                Text("streak").font(.caption2).foregroundStyle(.secondary)
            }
        }
    }

    private var namePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(names.enumerated()), id: \.element.id) { i, n in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { pick = i; resetOrbit() }
                    } label: {
                        Text("#\(n.id) \(n.tr)")
                            .font(.caption)
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(pick == i ? theme.accent : Color.primary.opacity(0.06),
                                        in: Capsule())
                            .foregroundStyle(pick == i ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: name card (3D tilt)

    private var card: some View {
        VStack(spacing: 16) {
            Text(husna.ar)
                .font(.system(size: 64, weight: .semibold))
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .environment(\.layoutDirection, .rightToLeft)
                .padding(.vertical, 8)

            Divider().opacity(0.4)

            Text(husna.tr)
                .font(.title3.weight(.medium))
                .kerning(1.5)

            if settings.showTelugu {
                Text(husna.te)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .transition(.opacity)
            }

            VStack(spacing: 6) {
                Text(husna.en).font(.headline)
                if settings.showMeaningTe {
                    Text(husna.ta).font(.subheadline).foregroundStyle(.secondary)
                }
            }
            .padding(.top, 4)

            HStack(spacing: 14) {
                Label("\(count) reads", systemImage: "checkmark.circle.fill")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(count >= settings.dailyTarget ? theme.accent : .secondary)
                Spacer()
                Label("target \(settings.dailyTarget)", systemImage: "target")
                    .font(.callout).foregroundStyle(.secondary)
            }
        }
        .padding(26)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(theme.card)
                .shadow(color: .black.opacity(0.12), radius: 18, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(theme.accent.opacity(0.25), lineWidth: 1.5)
        )
        .rotation3DEffect(.degrees(settings.threeDOn ? orbitY : 0), axis: (x: 0, y: 1, z: 0), perspective: 0.6)
        .rotation3DEffect(.degrees(settings.threeDOn ? orbitX : 0), axis: (x: 1, y: 0, z: 0), perspective: 0.6)
        .gesture(
            DragGesture()
                .onChanged { v in
                    guard settings.threeDOn else { return }
                    dragBusy = true
                    orbitY = max(-40, min(40, 7 + v.translation.width * 0.16))
                    orbitX = max(-35, min(35, -5 - v.translation.height * 0.12))
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) { resetOrbit() }
                    dragBusy = false
                }
        )
        .overlay(alignment: .topTrailing) {
            if settings.threeDOn {
                Label("drag to tilt", systemImage: "rotate.3d")
                    .font(.caption2).foregroundStyle(.tertiary)
                    .padding(10)
            }
        }
    }

    private func resetOrbit() { orbitX = -5; orbitY = 7 }

    // MARK: dua

    private var duaCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Short dua for this name", systemImage: "hands.and.sparkles")
                .font(.caption.weight(.semibold)).foregroundStyle(theme.accent)
            Text(husna.duaAr)
                .font(.system(size: 30, weight: .medium))
                .environment(\.layoutDirection, .rightToLeft)
                .frame(maxWidth: .infinity, alignment: .trailing)
            Text(husna.duaTr).font(.callout).foregroundStyle(.secondary)
            if settings.showTelugu {
                Text(husna.duaTe).font(.callout).foregroundStyle(.secondary)
            }
            Text(husna.duaEn).font(.callout.weight(.medium))
            if settings.showMeaningTe {
                Text(husna.duaTa).font(.callout).foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 18).fill(theme.card.opacity(0.75)))
    }

    // MARK: hadith

    private var hadithCard: some View {
        let h = husna.hadith
        return VStack(alignment: .leading, spacing: 10) {
            Label("Hadith / Ayah on this name", systemImage: "text.book.closed")
                .font(.caption.weight(.semibold)).foregroundStyle(theme.accent)
            Text(h.text)
                .font(.system(size: 21))
                .environment(\.layoutDirection, .rightToLeft)
                .frame(maxWidth: .infinity, alignment: .trailing)
            Text(h.meaning).font(.callout.italic())
            Text(h.source).font(.caption2).foregroundStyle(.secondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 18).fill(theme.card.opacity(0.55)))
    }

    // MARK: controls

    private var controls: some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                Button {
                    state.undoRead(husna.id)
                } label: {
                    Label("Undo", systemImage: "arrow.uturn.backward")
                        .frame(minWidth: 90)
                }
                .disabled(count == 0)

                Button {
                    state.recordRead(husna.id)
                } label: {
                    Label("Read once", systemImage: "checkmark")
                        .font(.title3.weight(.semibold))
                        .padding(.horizontal, 26).padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .tint(count >= settings.dailyTarget ? theme.accent : .green)

                Button {
                    for _ in 0..<(settings.dailyTarget - count) where count < settings.dailyTarget {
                        state.recordRead(husna.id)
                    }
                } label: {
                    Label("Fill target", systemImage: "forward.end.fill")
                        .frame(minWidth: 90)
                }
                .disabled(count >= settings.dailyTarget)
            }

            HStack(spacing: 16) {
                Label("Space = read · Esc = undo", systemImage: "keyboard")
                    .font(.caption).foregroundStyle(.secondary)
                Spacer()
                if pick < names.count - 1 {
                    Button("Next name →") { withAnimation { pick += 1; resetOrbit() } }
                }
                if read.todayPassed {
                    Label("Day passed ✓", systemImage: "checkmark.seal.fill")
                        .font(.caption.weight(.semibold)).foregroundStyle(theme.accent)
                } else {
                    Label("\(max(0, settings.minPass - read.todayTotal)) more to pass today",
                          systemImage: "hourglass")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .padding(.top, 4)
    }

    // MARK: keys

    private func registerKeys() {
        guard state.keyMonitor == nil else { return }
        state.keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if let fr = NSApp.keyWindow?.firstResponder, fr is NSText { return event }
            switch event.keyCode {
            case 49, 36:
                state.recordRead(husna.id); return nil
            case 27:
                state.undoRead(husna.id); return nil
            case 124:
                if pick < names.count - 1 { pick += 1; resetOrbit() }; return nil
            case 123:
                if pick > 0 { pick -= 1; resetOrbit() }; return nil
            default: return event
            }
        }
    }

    private func unregisterKeys() {
        if let m = state.keyMonitor {
            NSEvent.removeMonitor(m)
            state.keyMonitor = nil
        }
    }
}
