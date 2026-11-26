import SwiftUI

struct GlassBackdropView: View {
    @Environment(\.splateColors) private var colors
    let accentGlow: Color
    let isConnected: Bool

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [colors.background, colors.backgroundDeep],
                startPoint: .top,
                endPoint: .bottom
            )

            ambientOrbs
            illustratedLayers
        }
        .ignoresSafeArea()
    }

    private var ambientOrbs: some View {
        let intensity = colors.ambientIntensity * (isConnected ? 1.15 : 0.85)
        return ZStack {
            Circle()
                .fill(accentGlow.opacity(0.28 * intensity))
                .frame(width: 320, height: 320)
                .blur(radius: 85)
                .offset(x: -110, y: -230)

            Circle()
                .fill(colors.ambientB.opacity(0.24 * intensity))
                .frame(width: 280, height: 280)
                .blur(radius: 90)
                .offset(x: 130, y: -40)

            Circle()
                .fill(colors.ambientC.opacity(0.22 * intensity))
                .frame(width: 300, height: 300)
                .blur(radius: 95)
                .offset(x: -40, y: 240)
        }
    }

    @ViewBuilder
    private var illustratedLayers: some View {
        switch colors.backdrop {
        case .winter:
            if colors.isDark {
                layerImage("theme_winter_night_environment", opacity: 0.72)
                layerImage("theme_winter_night_forest", opacity: 0.85, alignment: .bottom)
            } else {
                layerImage("theme_winter_day_environment", opacity: 0.78)
                layerImage("theme_winter_day_forest", opacity: 0.85, alignment: .bottom)
            }
        case .grid:
            layerImage("theme_cyberpunk_layers_v2", opacity: 0.65)
        case .ocean:
            layerImage("theme_ocean_layers_v2", opacity: 0.65)
            layerImage("theme_ocean_object", opacity: 0.55, alignment: .bottom)
        case .aurora:
            layerImage("theme_aurora_object", opacity: 0.68, alignment: .top)
        case .sunset:
            layerImage("theme_sunset_object", opacity: 0.70, alignment: .bottom)
        case .rings:
            layerImage("theme_red_object", opacity: 0.58)
        case .sakura:
            layerImage("theme_sakura_object", opacity: 0.68, alignment: .topTrailing)
        case .pony:
            layerImage("theme_pony_characters", opacity: 0.45, alignment: .bottom)
        case .bloom:
            layerImage("theme_bloom_character", opacity: 0.45, alignment: .bottom)
        case .stars:
            starsOverlay
        case .soft, .pastel:
            EmptyView()
        }
    }

    private func layerImage(_ name: String, opacity: Double, alignment: Alignment = .center) -> some View {
        GeometryReader { geo in
            Image(name)
                .resizable()
                .scaledToFill()
                .frame(width: geo.size.width, height: geo.size.height, alignment: alignment)
                .clipped()
                .opacity(opacity)
        }
    }

    private var starsOverlay: some View {
        Canvas { ctx, size in
            let seeds: [(CGFloat, CGFloat, CGFloat)] = [
                (0.12, 0.14, 1.8), (0.28, 0.08, 1.3), (0.44, 0.19, 2.0), (0.67, 0.11, 1.5),
                (0.84, 0.16, 1.9), (0.19, 0.34, 1.4), (0.53, 0.31, 1.6), (0.76, 0.38, 1.3),
                (0.91, 0.29, 1.7), (0.09, 0.58, 1.5), (0.37, 0.64, 1.8), (0.64, 0.54, 1.2),
                (0.82, 0.69, 1.6), (0.22, 0.81, 1.4), (0.58, 0.84, 1.9), (0.88, 0.86, 1.5)
            ]
            for (rx, ry, r) in seeds {
                let rect = CGRect(x: size.width * rx, y: size.height * ry, width: r, height: r)
                ctx.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.55)))
            }
        }
    }
}
