import SwiftUI

/// Eye-free, Islamically styled avatar: simple clothes, optional cap, pet silhouette and a tree.
struct AvatarView: View {
    var dress: Int = 0
    var cap: Int = 0
    var pet: Int = 1
    var tree: Int = 0
    var tint: Int = 0
    var size: CGFloat = 160

    private var skin: Color {
        [Color(red: 0.86, green: 0.72, blue: 0.56),
         Color(red: 0.75, green: 0.60, blue: 0.45),
         Color(red: 0.62, green: 0.47, blue: 0.34),
         Color(red: 0.48, green: 0.35, blue: 0.26)][tint % 4]
    }

    var body: some View {
        let s = size
        ZStack(alignment: .bottom) {
            // backdrop
            Circle()
                .fill(LinearGradient(colors: [.white.opacity(0.75), .white.opacity(0.35)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: s, height: s)

            // tree behind
            if tree != 0 { treeShape.frame(width: s * 0.42, height: s * 0.55)
                .offset(x: s * 0.26, y: -s * 0.10) }

            // pet behind the figure
            if pet != 0 { petShape.frame(width: s * 0.30, height: s * 0.26)
                .offset(x: -s * 0.27, y: -s * 0.12) }

            figure.frame(width: s * 0.52, height: s * 0.66)
                .offset(y: -s * 0.08)
        }
        .frame(width: s, height: s)
    }

    // MARK: figure

    private var figure: some View {
        ZStack(alignment: .top) {
            // body / dress
            DressShape()
                .fill(LinearGradient(colors: DressKind(rawValue: dress)?.colors
                    .map { $0 } ?? [Color.gray],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(DressShape().stroke(.black.opacity(0.12), lineWidth: 1))
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack(spacing: 0) {
                // neck + head
                Capsule().fill(skin).frame(width: 14, height: 14)
                Circle().fill(skin).frame(width: 44, height: 44)
                    .overlay(alignment: .top) { capShape.padding(.top, -4) }
            }
            .padding(.top, 2)
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    @ViewBuilder
    private var capShape: some View {
        switch CapKind(rawValue: cap) ?? .none {
        case .none:
            EmptyView()
        case .kufi:
            UnevenRoundedRectangle(topLeadingRadius: 16, topTrailingRadius: 16)
                .fill(Color(red: 0.92, green: 0.90, blue: 0.84))
                .frame(width: 42, height: 18)
                .overlay(UnevenRoundedRectangle(topLeadingRadius: 16, topTrailingRadius: 16)
                    .stroke(.black.opacity(0.15), lineWidth: 1))
        case .imamah:
            UnevenRoundedRectangle(topLeadingRadius: 20, bottomLeadingRadius: 8, bottomTrailingRadius: 8, topTrailingRadius: 20)
                .fill(Color.white)
                .frame(width: 50, height: 30)
                .overlay(
                    Path { p in
                        p.move(to: CGPoint(x: 4, y: 22)); p.addLine(to: CGPoint(x: 46, y: 22))
                        p.move(to: CGPoint(x: 6, y: 27)); p.addLine(to: CGPoint(x: 44, y: 27))
                    }.stroke(Color(red: 0.75, green: 0.70, blue: 0.60), lineWidth: 2)
                )
        case .scarf:
            UnevenRoundedRectangle(topLeadingRadius: 22, topTrailingRadius: 22)
                .fill(Color(red: 0.35, green: 0.30, blue: 0.55))
                .frame(width: 52, height: 34)
                .overlay(alignment: .bottomLeading) {
                    Rectangle().fill(Color(red: 0.35, green: 0.30, blue: 0.55))
                        .frame(width: 14, height: 26).offset(x: 2, y: 18)
                }
        }
    }

    // MARK: pet (silhouette, no eyes)

    private var petShape: some View {
        let c = Color(red: 0.36, green: 0.30, blue: 0.26).opacity(0.85)
        return ZStack {
            switch PetKind(rawValue: pet) ?? .none {
            case .none: EmptyView()
            case .cat:
                ZStack {
                    Ellipse().fill(c).frame(width: 46, height: 28).offset(y: 12)
                    Circle().fill(c).frame(width: 26, height: 26).offset(x: -18, y: -2)
                    Path { p in // ears
                        p.move(to: CGPoint(x: -26, y: -8)); p.addLine(to: CGPoint(x: -20, y: -20)); p.addLine(to: CGPoint(x: -13, y: -8))
                        p.move(to: CGPoint(x: -12, y: -8)); p.addLine(to: CGPoint(x: -7, y: -20)); p.addLine(to: CGPoint(x: 0, y: -8))
                    }.fill(c)
                    Path { p in // tail
                        p.move(to: CGPoint(x: 20, y: 14))
                        p.addQuadCurve(to: CGPoint(x: 34, y: -8), control: CGPoint(x: 36, y: 8))
                    }.stroke(c, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                }
            case .deer:
                ZStack {
                    Ellipse().fill(c).frame(width: 50, height: 26).offset(y: 12)
                    Circle().fill(c).frame(width: 20, height: 20).offset(x: -20, y: -4)
                    Path { p in
                        p.move(to: CGPoint(x: -24, y: -12)); p.addLine(to: CGPoint(x: -30, y: -26))
                        p.move(to: CGPoint(x: -18, y: -12)); p.addLine(to: CGPoint(x: -14, y: -26))
                    }.stroke(c, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                }
            case .lamb:
                ZStack {
                    ForEach(0..<7, id: \.self) { i in
                        Circle().fill(c.opacity(0.9))
                            .frame(width: 22, height: 22)
                            .offset(x: CGFloat((i % 4) * 12 - 18), y: CGFloat((i / 4) * 12))
                    }
                    Circle().fill(c).frame(width: 18, height: 18).offset(x: -24, y: 4)
                }
            case .bird:
                ZStack {
                    Ellipse().fill(c).frame(width: 34, height: 22)
                    Circle().fill(c).frame(width: 16, height: 16).offset(x: 14, y: -8)
                    Path { p in
                        p.move(to: CGPoint(x: -6, y: -6))
                        p.addQuadCurve(to: CGPoint(x: 12, y: -4), control: CGPoint(x: 4, y: -22))
                    }.fill(c.opacity(0.75))
                }
            case .camel:
                ZStack {
                    Ellipse().fill(c).frame(width: 54, height: 30).offset(y: 14)
                    Ellipse().fill(c).frame(width: 24, height: 26).offset(x: -6, y: -6)
                    Capsule().fill(c).frame(width: 12, height: 26).offset(x: -22, y: -14)
                    Circle().fill(c).frame(width: 16, height: 16).offset(x: -24, y: -28)
                }
            }
        }
    }

    // MARK: tree (silhouette)

    private var treeShape: some View {
        let trunk = Color(red: 0.45, green: 0.32, blue: 0.20)
        let leaf = Color(red: 0.25, green: 0.55, blue: 0.30)
        return ZStack(alignment: .bottom) {
            switch TreeKind(rawValue: tree) ?? .none {
            case .none: EmptyView()
            case .palm:
                ZStack(alignment: .bottom) {
                    Path { p in
                        p.move(to: CGPoint(x: 46, y: 120)); p.addQuadCurve(to: CGPoint(x: 54, y: 40),
                                                                           control: CGPoint(x: 40, y: 80))
                        p.addLine(to: CGPoint(x: 62, y: 40))
                        p.addQuadCurve(to: CGPoint(x: 56, y: 120), control: CGPoint(x: 70, y: 80))
                        p.closeSubpath()
                    }.fill(trunk)
                    ForEach(0..<6, id: \.self) { i in
                        Ellipse().fill(leaf)
                            .frame(width: 46, height: 16)
                            .rotationEffect(.degrees(Double(i) * 60 - 150))
                            .offset(y: -6)
                    }
                    .offset(x: 54, y: -30)
                }
            case .olive, .sidr, .garden:
                ZStack(alignment: .bottom) {
                    Rectangle().fill(trunk).frame(width: 12, height: 46).offset(y: -20)
                    ZStack {
                        ForEach(0..<6, id: \.self) { i in
                            Circle().fill(leaf.opacity(0.85 + Double(i % 3) * 0.05))
                                .frame(width: 44, height: 44)
                                .offset(x: CGFloat((i % 3) * 20 - 20), y: CGFloat((i / 3) * 16))
                        }
                    }
                    .offset(y: -56)
                }
            }
        }
    }
}

struct DressShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX - r.width * 0.20, y: r.minY))
        p.addLine(to: CGPoint(x: r.midX + r.width * 0.20, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - 2, y: r.maxY - 12))
        p.addQuadCurve(to: CGPoint(x: r.minX + 2, y: r.maxY - 12),
                       control: CGPoint(x: r.midX, y: r.maxY + 14))
        p.closeSubpath()
        return p
    }
}

/// The little companion card shown in the Garden tab.
struct AvatarCard: View {
    @EnvironmentObject var avatar: AvatarStore
    @EnvironmentObject var state: AppState

    var body: some View {
        VStack(spacing: 10) {
            AvatarView(dress: avatar.dress, cap: avatar.cap, pet: avatar.pet,
                       tree: avatar.tree, tint: avatar.tint, size: 170)
            Text("Level \(GameStore.shared.level) · \(GameStore.shared.coins) coins")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18).fill(state.activeTheme.card.opacity(0.7)))
    }
}
