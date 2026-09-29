import SwiftUI

struct RootView: View {
    @EnvironmentObject var state: AppState
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var read: ReadStore

    private var theme: AppTheme { state.activeTheme }

    var body: some View {
        ZStack {
            LinearGradient(colors: [theme.top, theme.bottom], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            NavigationSplitView {
                List(selection: $state.tab) {
                    ForEach(visibleTabs) { tab in
                        Label(tab.title, systemImage: tab.symbol).tag(tab)
                    }
                    Section("Today") {
                        HStack {
                            Image(systemName: "flame.fill").foregroundStyle(.orange)
                            Text("\(read.streak) day streak").font(.caption)
                        }
                        ProgressView(value: read.todayProgress)
                            .tint(theme.accent)
                        Text("\(read.todayTotal)/\(read.targetForToday) reads · day \(read.dayIndex + 1)/99")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                }
                .listStyle(.sidebar)
                .navigationSplitViewColumnWidth(min: 180, ideal: 210)
                .frame(minWidth: 180)
            } detail: {
                detail
            }
            .navigationSplitViewStyle(.balanced)

            overlay
        }
        .animation(.easeInOut(duration: 0.25), value: state.tab)
    }

    private var visibleTabs: [AppState.Tab] {
        var t = AppState.Tab.allCases
        if !settings.namesListOn { t.removeAll { $0 == .names } }
        if !settings.challengesOn { t.removeAll { $0 == .challenges } }
        if !settings.gardenOn { t.removeAll { $0 == .garden } }
        if !settings.memorizeOn { t.removeAll { $0 == .memorize } }
        if !settings.shareOn { t.removeAll { $0 == .share } }
        return t
    }

    @ViewBuilder
    private var detail: some View {
        switch state.tab {
        case .read: ReadView()
        case .names: NamesListView()
        case .memorize: MemorizeView()
        case .challenges: ChallengesView()
        case .garden: GardenView()
        case .stats: StatsView()
        case .share: ShareView()
        case .settings: SettingsPane()
        case .help: HelpView()
        }
    }

    @ViewBuilder
    private var overlay: some View {
        VStack {
            Spacer()
            if let toast = state.toast {
                Text(toast)
                    .font(.callout.weight(.semibold))
                    .padding(.horizontal, 18).padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 26)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: state.toast)

        if state.celebrate {
            ConfettiView()
                .transition(.opacity)
                .task {
                    try? await Task.sleep(nanoseconds: 2_400_000_000)
                    withAnimation { state.celebrate = false }
                }
        }
    }
}

struct ConfettiView: View {
    @State private var fall = false
    private let colors: [Color] = [.green, .mint, .yellow, .orange, .pink, .blue, .purple]

    var body: some View {
        GeometryReader { geo in
            ForEach(0..<54, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(colors[i % colors.count])
                    .frame(width: 9, height: 13)
                    .rotationEffect(.degrees(fall ? Double(i * 37 % 360) + 220 : Double(i * 11 % 360)))
                    .position(x: CGFloat((i * 71) % Int(max(1, geo.size.width))),
                              y: fall ? geo.size.height + 40 : -40)
                    .opacity(fall ? 0.15 : 1)
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            guard AppSettings.shared.animationsOn else { return }
            withAnimation(.easeIn(duration: 2.2)) { fall = true }
        }
    }
}

struct SectionCard<Content: View>: View {
    let title: String
    var accent: Color = .accentColor
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline).foregroundStyle(.secondary)
            content
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.opacity(0.55), in: RoundedRectangle(cornerRadius: 14))
    }
}

struct StatPill: View {
    let title: String
    let value: String
    let symbol: String
    var tint: Color = .accentColor

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: symbol).font(.title3).foregroundStyle(tint)
            Text(value).font(.title3.weight(.bold).monospacedDigit())
            Text(title).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.background.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct RingView: View {
    let progress: Double
    var color: Color = .green
    var lineWidth: CGFloat = 12
    var label: String = ""

    var body: some View {
        ZStack {
            Circle().stroke(color.opacity(0.18), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, progress))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
            if !label.isEmpty {
                Text(label).font(.system(size: lineWidth * 1.5, weight: .bold, design: .rounded))
            }
        }
    }
}
