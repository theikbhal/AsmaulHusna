import SwiftUI

struct GardenView: View {
    @EnvironmentObject var avatar: AvatarStore
    @EnvironmentObject var state: AppState
    @EnvironmentObject var read: ReadStore

    @State private var section = 0

    private var theme: AppTheme { state.activeTheme }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                HStack(spacing: 18) {
                    AvatarCard()
                    gardenCard
                }
                Picker("", selection: $section) {
                    Text("Clothes").tag(0)
                    Text("Headwear").tag(1)
                    Text("Pet").tag(2)
                    Text("Tree").tag(3)
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                wardrobe
            }
            .padding(24)
            .frame(maxWidth: 880)
        }
    }

    // MARK: garden

    private var gardenCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Your garden", systemImage: "leaf.fill").font(.headline)
                Spacer()
                Text(avatar.stage.emoji).font(.title)
            }
            Text(avatar.stage.name).font(.title3.weight(.semibold))

            // stage strip
            HStack(spacing: 6) {
                ForEach(GardenStage.allCases) { s in
                    VStack(spacing: 3) {
                        Text(s.emoji).font(.title3)
                            .opacity(s.rawValue <= avatar.stage.rawValue ? 1 : 0.28)
                        Circle()
                            .fill(s.rawValue <= avatar.stage.rawValue ? theme.accent : Color.secondary.opacity(0.3))
                            .frame(width: 7, height: 7)
                    }
                }
            }

            if let next = avatar.nextStageDays {
                let done = read.daysPassed
                ProgressView(value: Double(done), total: Double(next))
                    .tint(theme.accent)
                Text("\(done)/\(next) days passed → next stage")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                Text("Maximum stage reached — masha'Allah!").font(.caption).foregroundStyle(.secondary)
            }

            Text("Every day you pass grows the garden. Streak keeps it alive; a missed day stops it.")
                .font(.caption2).foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 18).fill(theme.card.opacity(0.7)))
    }

    // MARK: wardrobe

    private var wardrobe: some View {
        SectionCard(title: sectionTitle) {
            let cols = Array(repeating: GridItem(.flexible(), spacing: 10), count: 5)
            LazyVGrid(columns: cols, spacing: 10) {
                switch section {
                case 0: partGrid(DressKind.allCases.map { ($0.rawValue, $0.label, $0.unlockAt) }, kind: "dress", current: avatar.dress)
                case 1: partGrid(CapKind.allCases.map { ($0.rawValue, $0.label, $0.unlockAt) }, kind: "cap", current: avatar.cap)
                case 2: partGrid(PetKind.allCases.map { ($0.rawValue, $0.label, $0.unlockAt) }, kind: "pet", current: avatar.pet)
                default: partGrid(TreeKind.allCases.map { ($0.rawValue, $0.label, $0.unlockAt) }, kind: "tree", current: avatar.tree)
                }
            }

            Divider().padding(.top, 6)
            Text("Skin tone").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            HStack(spacing: 10) {
                ForEach(0..<4, id: \.self) { i in
                    Circle()
                        .fill(AvatarStore.tints[i])
                        .frame(width: 30, height: 30)
                        .overlay(Circle().stroke(i == avatar.tint ? theme.accent : .clear, lineWidth: 3))
                        .onTapGesture { avatar.select(i, kind: "tint") }
                }
                Spacer()
                Text("Level \(state.gameLevel) unlocks more")
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
    }

    private var sectionTitle: String {
        ["Clothes", "Headwear", "Companion", "Tree"][section]
    }

    @ViewBuilder
    private func partGrid(_ items: [(Int, String, Int)], kind: String, current: Int) -> some View {
        ForEach(items, id: \.0) { item in
            let unlocked = item.2 <= state.gameLevel
            VStack(spacing: 6) {
                AvatarView(dress: kind == "dress" ? item.0 : avatar.dress,
                           cap: kind == "cap" ? item.0 : avatar.cap,
                           pet: kind == "pet" ? item.0 : avatar.pet,
                           tree: kind == "tree" ? item.0 : avatar.tree,
                           tint: avatar.tint, size: 74)
                Text(item.1).font(.caption2)
                Text(unlocked ? "Lv \(item.2)" : "🔒 Lv \(item.2)")
                    .font(.caption2)
                    .foregroundStyle(unlocked ? .green : .secondary)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(current == item.0 ? theme.accent.opacity(0.18) : theme.card.opacity(0.6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(current == item.0 ? theme.accent : .clear, lineWidth: 2)
            )
            .opacity(unlocked ? 1 : 0.55)
            .onTapGesture { avatar.select(item.0, kind: kind) }
        }
    }
}

extension AppState {
    var gameLevel: Int { GameStore.shared.level }
}
