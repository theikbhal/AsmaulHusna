import SwiftUI

struct StatsView: View {
    @EnvironmentObject var read: ReadStore
    @EnvironmentObject var game: GameStore
    @EnvironmentObject var memo: MemoStore
    @EnvironmentObject var state: AppState

    private var theme: AppTheme { state.activeTheme }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                totals
                heatmapCard
                weeklyCard
                masteryCard
                badgesCard
            }
            .padding(24)
            .frame(maxWidth: 900)
        }
        .onAppear { state.checkBadges() }
    }

    private var totals: some View {
        HStack(spacing: 12) {
            StatPill(title: "Current streak", value: "\(read.streak)", symbol: "flame.fill", tint: .orange)
            StatPill(title: "Best streak", value: "\(read.best)", symbol: "trophy.fill", tint: .yellow)
            StatPill(title: "Days passed", value: "\(read.daysPassed)", symbol: "checkmark.seal.fill", tint: .green)
            StatPill(title: "Total reads", value: "\(read.totalReads)", symbol: "book.fill", tint: theme.accent)
            StatPill(title: "Level", value: "\(game.level)", symbol: "bolt.fill", tint: .purple)
        }
    }

    // MARK: heatmap

    private var heatmapCard: some View {
        SectionCard(title: "Last 84 days") {
            let cells = read.heatmap(84)
            let cols = Array(repeating: GridItem(.flexible(), spacing: 5), count: 12)
            LazyVGrid(columns: cols, spacing: 5) {
                ForEach(cells, id: \.key) { cell in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color(level: cell.level))
                        .frame(height: 20)
                        .overlay {
                            if Calendar.current.isDate(cell.date, inSameDayAs: read.today) {
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(theme.accent, lineWidth: 2)
                            }
                        }
                        .help("\(cell.key): level \(cell.level)")
                }
            }
            HStack {
                Text("less").font(.caption2).foregroundStyle(.secondary)
                ForEach(0...3, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 3).fill(color(level: i)).frame(width: 14, height: 14)
                }
                Text("more").font(.caption2).foregroundStyle(.secondary)
                Spacer()
                Text("Visualisation of consistency — every square is one day.")
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
    }

    private func color(level: Int) -> Color {
        switch level {
        case 0: return Color.primary.opacity(0.07)
        case 1: return theme.accent.opacity(0.30)
        case 2: return theme.accent.opacity(0.60)
        default: return theme.accent
        }
    }

    // MARK: weekly bars

    private var weeklyCard: some View {
        SectionCard(title: "Reads per day (last 14 days)") {
            let data = read.readsLast(14)
            let maxV = max(1, data.map(\.value).max() ?? 1)
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(data.enumerated()), id: \.offset) { _, item in
                    VStack(spacing: 4) {
                        Text("\(item.value)").font(.caption22).foregroundStyle(.secondary)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(item.value >= settingsMin ? theme.accent : theme.accent.opacity(0.35))
                            .frame(height: max(4, CGFloat(item.value) / CGFloat(maxV) * 110))
                        Text(item.label).font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
            Text("Green bar = day passed the minimum of \(settingsMin) reads.")
                .font(.caption2).foregroundStyle(.secondary)
        }
    }

    private var settingsMin: Int { AppSettings.shared.minPass }

    // MARK: mastery

    private var masteryCard: some View {
        SectionCard(title: "Mastery of the names (reads / 30)") {
            let top = Names.all.map { ($0, read.perName[$0.id] ?? 0) }
                .sorted { $0.1 > $1.1 }.prefix(8)
            if top.allSatisfy({ $0.1 == 0 }) {
                Text("Start reading — your strongest names will show up here.")
                    .font(.callout).foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 7) {
                    ForEach(top, id: \.0.id) { item in
                        HStack {
                            Text(item.0.ar).font(.callout).frame(width: 130, alignment: .trailing)
                                .environment(\.layoutDirection, .rightToLeft)
                            Text(item.0.tr).font(.caption).frame(width: 130, alignment: .leading)
                            ProgressView(value: read.mastery(item.0.id)).tint(theme.accent)
                            Text("\(item.1)").font(.caption.monospacedDigit()).frame(width: 34, alignment: .trailing)
                        }
                    }
                }
            }
        }
    }

    // MARK: badges

    private var badgesCard: some View {
        SectionCard(title: "Badges (\(game.unlocked.count)/\(GameStore.catalogue.count))") {
            let cols = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)
            LazyVGrid(columns: cols, spacing: 10) {
                ForEach(GameStore.catalogue) { b in
                    let on = game.unlocked.contains(b.id)
                    VStack(spacing: 5) {
                        Image(systemName: b.icon)
                            .font(.title2)
                            .foregroundStyle(on ? badgeColor(b.rarity) : .secondary)
                        Text(b.name).font(.caption.weight(.semibold)).multilineTextAlignment(.center)
                        Text(b.desc).font(.caption2).foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Text(on ? b.rarity : "locked").font(.caption22).foregroundStyle(.tertiary)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 12)
                        .fill(on ? theme.card.opacity(0.8) : Color.primary.opacity(0.04)))
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .stroke(on ? badgeColor(b.rarity).opacity(0.5) : .clear, lineWidth: 1))
                    .opacity(on ? 1 : 0.55)
                }
            }
        }
    }

    private func badgeColor(_ rarity: String) -> Color {
        switch rarity {
        case "Common": return .blue
        case "Rare": return .green
        case "Epic": return .purple
        default: return .orange
        }
    }
}

private extension Font {
    static var caption22: Font { .system(size: 10) }
}
