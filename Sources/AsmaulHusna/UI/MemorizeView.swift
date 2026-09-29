import SwiftUI

struct MemorizeView: View {
    @EnvironmentObject var memo: MemoStore
    @EnvironmentObject var state: AppState
    @EnvironmentObject var settings: AppSettings

    @State private var revealed = false
    @State private var queue: [Husna] = []
    @State private var done = 0

    private var theme: AppTheme { state.activeTheme }
    private var card: Husna? { queue.first }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                statsRow
                session
                boxes
                techniques
            }
            .padding(24)
            .frame(maxWidth: 880)
        }
        .onAppear { if queue.isEmpty { queue = memo.dueToday } }
    }

    // MARK: stats

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatPill(title: "Due today", value: "\(memo.dueToday.count)", symbol: "clock.badge.exclamationmark")
            StatPill(title: "In the boxes", value: "\(memo.cards.count)", symbol: "square.stack.3d.up")
            StatPill(title: "Mastered (box 5)", value: "\(memo.masteredCount)", symbol: "graduationcap.fill",
                     tint: .green)
            StatPill(title: "Reviewed now", value: "\(done)", symbol: "checkmark.circle", tint: .blue)
        }
    }

    // MARK: session

    private var session: some View {
        VStack(spacing: 16) {
            if let h = card {
                VStack(spacing: 12) {
                    Text(revealed ? h.ar : "؟")
                        .font(.system(size: 58, weight: .semibold))
                        .environment(\.layoutDirection, .rightToLeft)
                        .opacity(revealed ? 1 : 0.45)
                        .animation(.easeInOut(duration: 0.25), value: revealed)

                    if revealed {
                        Text(h.tr).font(.title3.weight(.medium))
                        if settings.showTelugu { Text(h.te).font(.callout).foregroundStyle(.secondary) }
                        Text(h.en).font(.headline)
                        if settings.showMeaningTe { Text(h.ta).font(.callout).foregroundStyle(.secondary) }
                        Text("Box \(memo.card(h.id).box) · next review in \(daysUntil(memo.card(h.id).due))")
                            .font(.caption).foregroundStyle(.secondary)
                    } else {
                        Text("Recall the name, then reveal to grade yourself")
                            .font(.callout).foregroundStyle(.secondary)
                    }
                }
                .padding(22)
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 20).fill(theme.card.opacity(0.75)))

                HStack(spacing: 12) {
                    if !revealed {
                        Button {
                            withAnimation { revealed = true }
                        } label: { Label("Reveal", systemImage: "eye.fill").frame(minWidth: 120) }
                            .buttonStyle(.borderedProminent).tint(theme.accent)
                    } else {
                        gradeButton("Again", 0, .red)
                        gradeButton("Hard", 1, .orange)
                        gradeButton("Good", 2, .green)
                        gradeButton("Easy", 3, .blue)
                    }
                }

                HStack {
                    Button("Skip") { next() }
                    Spacer()
                    Text("\(queue.count) left in this session")
                        .font(.caption).foregroundStyle(.secondary)
                }
            } else if done > 0 {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill").font(.largeTitle).foregroundStyle(.green)
                    Text("Session complete — \(done) names reviewed").font(.headline)
                    Button("Start another round") { queue = memo.dueToday; done = 0; revealed = false }
                }
                .padding(28)
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 20).fill(theme.card.opacity(0.75)))
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "sparkles").font(.largeTitle).foregroundStyle(theme.accent)
                    Text("Nothing due right now").font(.headline)
                    Text("Every name you read joins the ladder: today → 1 → 3 → 7 → 21 days.")
                        .font(.callout).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    Button("Review anyway") { queue = Names.all.shuffled().prefix(10).map { $0 }; revealed = false }
                }
                .padding(28)
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 20).fill(theme.card.opacity(0.75)))
            }
        }
    }

    private func gradeButton(_ title: String, _ q: Int, _ color: Color) -> some View {
        Button {
            guard let h = card else { return }
            memo.grade(h.id, q)
            state.recordRead(h.id)
            next()
        } label: {
            VStack(spacing: 2) {
                Text(title).font(.callout.weight(.semibold))
                Text(q == 0 ? "restart" : (q == 1 ? "1 day" : (q == 2 ? boxHint(q) : boxHint(q))))
                    .font(.caption2).opacity(0.8)
            }
            .frame(minWidth: 76).padding(.vertical, 4)
        }
        .buttonStyle(.bordered)
        .tint(color)
    }

    private func boxHint(_ q: Int) -> String {
        let box = memo.lastGrade?.box ?? 1
        return "box \(box)"
    }

    private func next() {
        revealed = false
        done += 1
        if !queue.isEmpty { queue.removeFirst() }
        state.checkBadges()
    }

    private func daysUntil(_ d: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: ReadStore.shared.today, to: d).day ?? 0
        if days <= 0 { return "today" }
        return days == 1 ? "1 day" : "\(days) days"
    }

    // MARK: boxes

    private var boxes: some View {
        SectionCard(title: "Leitner boxes") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(1...5, id: \.self) { b in
                    let n = memo.cards.values.filter { $0.box == b }.count
                    HStack {
                        Text("Box \(b)").font(.callout.weight(.semibold)).frame(width: 66, alignment: .leading)
                        Text(label(forBox: b)).font(.caption).foregroundStyle(.secondary).frame(width: 150, alignment: .leading)
                        ProgressView(value: Double(n), total: Double(max(1, memo.cards.count)))
                            .tint(b == 5 ? .green : theme.accent)
                        Text("\(n)").font(.caption.monospacedDigit()).frame(width: 34, alignment: .trailing)
                    }
                }
                Text("Average box: \(String(format: "%.1f", memo.averageBox()))")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private func label(forBox b: Int) -> String {
        ["today", "every 1 day", "every 3 days", "every 7 days", "every 21 days"][b - 1]
    }

    // MARK: techniques

    private var techniques: some View {
        SectionCard(title: "Memorisation techniques") {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(MemoStore.techniques, id: \.0) { t in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(t.0).font(.subheadline.weight(.semibold))
                        Text(t.1).font(.callout)
                        Text(t.2).font(.caption).foregroundStyle(.secondary).italic()
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}
