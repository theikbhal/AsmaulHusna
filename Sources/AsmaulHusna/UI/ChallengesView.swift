import SwiftUI

struct ChallengesView: View {
    @EnvironmentObject var store: ChallengeStore
    @EnvironmentObject var state: AppState
    @EnvironmentObject var settings: AppSettings

    @State private var expanded: ChallengeKind? = .daily

    private var theme: AppTheme { state.activeTheme }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(ChallengeKind.allCases) { kind in
                    challengeCard(kind)
                }
            }
            .padding(24)
            .frame(maxWidth: 880)
        }
    }

    private func challengeCard(_ kind: ChallengeKind) -> some View {
        let p = store.progress(kind)
        let cfg = store.config(kind)
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: kind.symbol).font(.title3).foregroundStyle(p.passed ? .green : theme.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text(kind.title).font(.headline)
                    Text(store.periodLabel(kind)).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if p.passed {
                    Label("Passed", systemImage: "checkmark.seal.fill")
                        .font(.caption.weight(.semibold)).foregroundStyle(.green)
                } else {
                    Text("\(p.value)/\(p.target)")
                        .font(.callout.weight(.bold).monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        expanded = expanded == kind ? nil : kind
                    }
                } label: {
                    Image(systemName: expanded == kind ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            ProgressView(value: p.fraction)
                .tint(p.passed ? .green : theme.accent)

            HStack(spacing: 14) {
                Label("\(p.daysPassed)/\(p.daysTotal) days passed", systemImage: "calendar")
                Label("min pass \(cfg.minPass > 0 ? cfg.minPass : settings.minPass)/day", systemImage: "checkmark.circle")
                Label("when: \(cfg.whenText.isEmpty ? kind.defaultWhen : cfg.whenText)", systemImage: "clock")
            }
            .font(.caption).foregroundStyle(.secondary)

            if expanded == kind {
                detail(kind, cfg: cfg, p: p)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(theme.card.opacity(0.7)))
    }

    @ViewBuilder
    private func detail(_ kind: ChallengeKind, cfg: ChallengeConfig, p: ChallengeProgress) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()

            labeledField("Why", text: binding(kind, \.why),
                         placeholder: kind.defaultWhy)
            labeledField("When", text: binding(kind, \.whenText),
                         placeholder: kind.defaultWhen)

            HStack(spacing: 16) {
                stepper("How much (target)", value: binding(kind, \.howMuch),
                        range: 0...100000, zeroNote: "auto: \(store.autoTarget(kind))")
                stepper("Minimum pass / day", value: binding(kind, \.minPass),
                        range: 0...99, zeroNote: "auto: \(settings.minPass)")
            }

            if kind == .family { familyEditor(cfg) }

            Text("Why it works: a written intention, a fixed time, a measurable target and a clear pass mark "
                 + "are the four things that turn an idea into a habit.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private func labeledField(_ label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            TextField(placeholder, text: text)
                .textFieldStyle(.roundedBorder)
        }
    }

    private func stepper(_ label: String, value: Binding<Int>, range: ClosedRange<Int>, zeroNote: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            HStack {
                Stepper(value: value, in: range) {
                    Text(value.wrappedValue == 0 ? zeroNote : "\(value.wrappedValue)")
                        .font(.callout.monospacedDigit())
                }
                .fixedSize()
            }
        }
    }

    private func binding(_ kind: ChallengeKind, _ keyPath: WritableKeyPath<ChallengeConfig, String>) -> Binding<String> {
        Binding(
            get: { store.config(kind)[keyPath: keyPath] },
            set: { v in
                var c = store.config(kind)
                c[keyPath: keyPath] = v
                store.update(kind, c)
            })
    }

    private func binding(_ kind: ChallengeKind, _ keyPath: WritableKeyPath<ChallengeConfig, Int>) -> Binding<Int> {
        Binding(
            get: { store.config(kind)[keyPath: keyPath] },
            set: { v in
                var c = store.config(kind)
                c[keyPath: keyPath] = v
                store.update(kind, c)
            })
    }

    // MARK: family

    private func familyEditor(_ cfg: ChallengeConfig) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Family members").font(.caption.weight(.semibold)).foregroundStyle(.secondary)

            ForEach(cfg.family) { m in
                HStack {
                    AvatarView(dress: m.dress % DressKind.allCases.count, cap: 0, pet: 0, tree: 0,
                               tint: m.dress % 4, size: 44)
                    Text(m.name).font(.callout.weight(.medium))
                    Spacer()
                    Text("\(m.reads[ReadStore.shared.todayKey] ?? 0) reads")
                        .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                    Button { store.bumpMember(m.id, by: 1) } label: { Image(systemName: "plus.circle.fill") }
                        .buttonStyle(.plain).foregroundStyle(.green)
                    Button { store.bumpMember(m.id, by: -1) } label: { Image(systemName: "minus.circle.fill") }
                        .buttonStyle(.plain).foregroundStyle(.red)
                    Button { store.removeFamilyMember(m.id) } label: { Image(systemName: "trash") }
                        .buttonStyle(.plain).foregroundStyle(.tertiary)
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 10).fill(theme.top.opacity(0.6)))
            }

            HStack {
                TextField("Add a family member…", text: Binding(
                    get: { newMemberName },
                    set: { newMemberName = $0 }
                ))
                .textFieldStyle(.roundedBorder)
                Button("Add") {
                    let n = newMemberName.trimmingCharacters(in: .whitespaces)
                    guard !n.isEmpty else { return }
                    store.addFamilyMember(n)
                    newMemberName = ""
                }
                .disabled(newMemberName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            Text("Everyone reads on the same device — each member's count is added to the shared target. "
                 + "Readings you log in the Read tab count too.")
                .font(.caption2).foregroundStyle(.secondary)
        }
    }

    @State private var newMemberName = ""
}
