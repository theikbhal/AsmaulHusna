import SwiftUI

/// Offscreen render target for Instagram exports (post / story / carousel card).
struct ShareCard: View {
    let husna: Husna
    var style: Style = .post
    var index: Int = 0
    var total: Int = 0

    enum Style { case post, story }

    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var read: ReadStore

    private var theme: AppTheme {
        let base = AppTheme.byId(settings.themeId)
        let dark: Bool = {
            switch settings.nightMode {
            case .dark: return true
            case .light: return false
            case .system: return NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            }
        }()
        return dark ? base.night() : base
    }

    private var isStory: Bool { style == .story }

    var body: some View {
        ZStack {
            LinearGradient(colors: [theme.top, theme.bottom], startPoint: .top, endPoint: .bottom)

            // subtle geometric pattern
            GeometryReader { geo in
                ForEach(0..<6, id: \.self) { i in
                    Circle()
                        .stroke(theme.accent.opacity(0.14), lineWidth: 2)
                        .frame(width: CGFloat(160 + i * 90))
                        .position(x: geo.size.width * (i % 2 == 0 ? 0.15 : 0.85),
                                 y: geo.size.height * (0.12 + Double(i) * 0.15))
                }
            }

            VStack(spacing: isStory ? 34 : 26) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ASMAUL HUSNA")
                            .font(.system(size: isStory ? 34 : 30, weight: .heavy))
                            .kerning(6)
                            .foregroundStyle(theme.accent)
                        Text("The 99 Beautiful Names")
                            .font(.system(size: isStory ? 24 : 20))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("#\(husna.id)")
                        .font(.system(size: isStory ? 44 : 38, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.accent.opacity(0.85))
                }

                Spacer()

                Text(husna.ar)
                    .font(.system(size: isStory ? 130 : 108, weight: .semibold))
                    .minimumScaleFactor(0.35)
                    .lineLimit(1)
                    .environment(\.layoutDirection, .rightToLeft)

                Text(husna.tr)
                    .font(.system(size: isStory ? 48 : 42, weight: .semibold))
                    .kerning(3)
                if settings.showTelugu {
                    Text(husna.te)
                        .font(.system(size: isStory ? 44 : 36))
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 10) {
                    Text(husna.en)
                        .font(.system(size: isStory ? 42 : 36, weight: .bold))
                        .multilineTextAlignment(.center)
                    if settings.showMeaningTe {
                        Text(husna.ta)
                            .font(.system(size: isStory ? 34 : 28))
                            .foregroundStyle(.secondary)
                    }
                }

                if settings.showDua {
                    VStack(spacing: 8) {
                        Text(husna.duaAr)
                            .font(.system(size: isStory ? 52 : 44))
                            .environment(\.layoutDirection, .rightToLeft)
                        Text(husna.duaTr)
                            .font(.system(size: isStory ? 28 : 24))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)
                }

                Spacer()

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Streak \(read.streak) 🔥")
                            .font(.system(size: isStory ? 32 : 28, weight: .bold))
                        Text("Read it. Learn it. Live it.")
                            .font(.system(size: isStory ? 24 : 20))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if total > 0 {
                        Text("\(index)/\(total)")
                            .font(.system(size: isStory ? 40 : 34, weight: .bold, design: .rounded))
                            .foregroundStyle(theme.accent)
                    }
                }
            }
            .padding(isStory ? 90 : 76)
            .foregroundStyle(primaryOnTheme)
        }
        .frame(width: isStory ? ShareExport.Size.story.w : ShareExport.Size.post.w,
               height: isStory ? ShareExport.Size.story.h : ShareExport.Size.post.h)
        .clipShape(RoundedRectangle(cornerRadius: 0))
    }

    private var primaryOnTheme: Color {
        let l = (theme.top.nsColorComponent.0 * 0.299
            + theme.top.nsColorComponent.1 * 0.587
            + theme.top.nsColorComponent.2 * 0.114)
        return l < 0.5 ? .white : Color(red: 0.12, green: 0.13, blue: 0.16)
    }
}

private extension Color {
    var nsColorComponent: (CGFloat, CGFloat, CGFloat) {
        let c = NSColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        c.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r, g, b)
    }
}
