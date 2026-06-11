import SwiftUI

struct LMManualEntryIcon: View {
    var size: CGFloat = 18
    var color: Color = LMColors.textBody

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let lineWidth = max(1.8, side * 0.1)
            let scale = side / 24

            ZStack {
                Path { path in
                    path.move(to: CGPoint(x: 16.5 * scale, y: 3.5 * scale))
                    path.addCurve(
                        to: CGPoint(x: 19.5 * scale, y: 6.5 * scale),
                        control1: CGPoint(x: 17.3 * scale, y: 2.7 * scale),
                        control2: CGPoint(x: 18.7 * scale, y: 2.7 * scale)
                    )
                    path.addLine(to: CGPoint(x: 7 * scale, y: 19 * scale))
                    path.addLine(to: CGPoint(x: 3 * scale, y: 20 * scale))
                    path.addLine(to: CGPoint(x: 4 * scale, y: 16 * scale))
                    path.closeSubpath()
                }
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))

                Path { path in
                    path.move(to: CGPoint(x: 14 * scale, y: 6 * scale))
                    path.addLine(to: CGPoint(x: 18 * scale, y: 10 * scale))
                }
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))

                Path { path in
                    path.move(to: CGPoint(x: 12 * scale, y: 20 * scale))
                    path.addLine(to: CGPoint(x: 21 * scale, y: 20 * scale))
                }
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            }
        }
        .frame(width: size, height: size)
    }
}

struct LMWeightScaleIcon: View {
    static let symbolName = "leanmate.weight.scale"

    var size: CGFloat = 18
    var color: Color = LMColors.textBody

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let lineWidth = max(1.6, side * 0.095)
            let scale = side / 24

            ZStack {
                RoundedRectangle(cornerRadius: 4 * scale, style: .continuous)
                    .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                    .frame(width: 16 * scale, height: 14 * scale)
                    .position(x: 12 * scale, y: 12.5 * scale)

                Path { path in
                    path.move(to: CGPoint(x: 8.2 * scale, y: 9 * scale))
                    path.addQuadCurve(
                        to: CGPoint(x: 15.8 * scale, y: 9 * scale),
                        control: CGPoint(x: 12 * scale, y: 6.7 * scale)
                    )
                }
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

                Path { path in
                    path.move(to: CGPoint(x: 12 * scale, y: 9 * scale))
                    path.addLine(to: CGPoint(x: 14.2 * scale, y: 7.3 * scale))
                }
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            }
        }
        .frame(width: size, height: size)
    }
}

struct LMManualEntryIcon_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(LMColors.warmMuted)
                    .frame(width: 42, height: 42)

                LMManualEntryIcon()
            }

            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(LMColors.primarySoft)
                    .frame(width: 42, height: 42)

                LMWeightScaleIcon(color: LMColors.primary)
            }
        }
        .padding()
        .background(LMColors.background)
    }
}
