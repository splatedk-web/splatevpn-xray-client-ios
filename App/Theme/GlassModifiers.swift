import SwiftUI

struct LiquidGlassModifier: ViewModifier {
    @Environment(\.splateColors) private var colors
    @Environment(\.glassTransparency) private var transparency
    @Environment(\.glassBlurEnabled) private var blurEnabled

    let cornerRadius: CGFloat
    let accentBorder: Color?
    let innerSheen: Bool

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        let fillAlpha = max(0.18, min(0.96, colors.glassAlpha * (1.0 - transparency * 0.65)))

        content
            .background {
                ZStack {
                    if blurEnabled {
                        shape.fill(.ultraThinMaterial)
                    }
                    shape.fill(colors.surface.opacity(fillAlpha))
                    if innerSheen {
                        shape.fill(
                            LinearGradient(
                                colors: [colors.glassSpecular.opacity(0.32), Color.clear],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                    }
                }
            }
            .overlay {
                if let accentBorder {
                    shape.strokeBorder(accentBorder.opacity(0.85), lineWidth: 1.2)
                } else {
                    shape.strokeBorder(
                        LinearGradient(
                            colors: [colors.glassBorderLight, colors.glassBorderDark],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.0
                    )
                }
            }
            .clipShape(shape)
    }
}

struct ElasticButtonStyle: ButtonStyle {
    var targetScale: CGFloat = 0.97

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? targetScale : 1.0)
            .animation(.spring(response: 0.24, dampingFraction: 0.72), value: configuration.isPressed)
    }
}

extension View {
    func liquidGlass(
        cornerRadius: CGFloat = 20,
        accentBorder: Color? = nil,
        innerSheen: Bool = true
    ) -> some View {
        modifier(LiquidGlassModifier(cornerRadius: cornerRadius, accentBorder: accentBorder, innerSheen: innerSheen))
    }
}
