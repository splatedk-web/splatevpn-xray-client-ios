import SwiftUI

public extension AppThemeColors {
    static let dark = build(
        isDark: true,
        background: 0xFF050914, backgroundDeep: 0xFF020408,
        surface: 0xFF0C1424, surfaceElevated: 0xFF141F38,
        borderSubtle: 0xFF1D2E4E, borderMedium: 0xFF2C436D,
        textPrimary: 0xFFF5F9FC, textSecondary: 0xFF96ACC8, textTertiary: 0xFF94A4BC,
        accent: 0xFF7BDDEC, accentSecondary: 0xFF829FFF,
        accentEmerald: 0xFF53DBAB, accentAmber: 0xFFF4C474,
        accentCrimson: 0xFFFF728A, accentViolet: 0xFFA488FA, accentBlue: 0xFF829FFF,
        onAccent: 0xFF001218, ambientB: 0xFF847CC7, ambientC: 0xFF2860EB,
        ambientIntensity: 0.88, backdrop: .soft, glassAlpha: 0.86,
        glassBorderLight: 0x6EA0C5FF, glassBorderDark: 0x385580FF, glassSpecular: 0x44FFFFFF
    )

    static let amoled = build(
        isDark: true,
        background: 0xFF000000, backgroundDeep: 0xFF000000,
        surface: 0xFF060809, surfaceElevated: 0xFF0E1114,
        borderSubtle: 0xFF18202A, borderMedium: 0xFF253040,
        textPrimary: 0xFFF8FCFF, textSecondary: 0xFF8EA4BC, textTertiary: 0xFF879BA8,
        accent: 0xFF8EF0CF, accentSecondary: 0xFF67C9E0,
        accentEmerald: 0xFF00F5B0, accentAmber: 0xFFFFC942,
        accentCrimson: 0xFFFF3366, accentViolet: 0xFF8B9AFF, accentBlue: 0xFF00C8FF,
        onAccent: 0xFF001A16, ambientB: 0xFF0077B6, ambientC: 0xFF8EF0CF,
        ambientIntensity: 0.50, backdrop: .stars, glassAlpha: 0.90,
        glassBorderLight: 0x406CCFB8, glassBorderDark: 0x1AFFFFFF, glassSpecular: 0x28FFFFFF
    )

    static let light = build(
        isDark: false,
        background: 0xFFF2F5FA, backgroundDeep: 0xFFE5ECF5,
        surface: 0xFFFFFFFF, surfaceElevated: 0xFFFFFFFF,
        borderSubtle: 0xFFD4DFEC, borderMedium: 0xFFA4B6CC,
        textPrimary: 0xFF0F172A, textSecondary: 0xFF475569, textTertiary: 0xFF64748B,
        accent: 0xFF1D63DC, accentSecondary: 0xFF635BFF,
        accentEmerald: 0xFF047857, accentAmber: 0xFFB45309,
        accentCrimson: 0xFFDC2646, accentViolet: 0xFF6D42C7, accentBlue: 0xFF1D63DC,
        onAccent: 0xFFFFFFFF, ambientB: 0xFFB6D3FA, ambientC: 0xFFD5C9FA,
        ambientIntensity: 0.34, backdrop: .pastel, glassAlpha: 0.94,
        glassBorderLight: 0xEEFFFFFF, glassBorderDark: 0x3864748B, glassSpecular: 0xAAFFFFFF
    )

    static let cyberpunk = build(
        isDark: true,
        background: 0xFF120C22, backgroundDeep: 0xFF070510,
        surface: 0xFF21172F, surfaceElevated: 0xFF30233F,
        borderSubtle: 0xFF4D3B61, borderMedium: 0xFF80669B,
        textPrimary: 0xFFF7F1FF, textSecondary: 0xFFD5C5E8, textTertiary: 0xFFC5B5D8,
        accent: 0xFFD1ADFF, accentSecondary: 0xFF80E6DD,
        accentEmerald: 0xFF91DBBB, accentAmber: 0xFFF4D59B,
        accentCrimson: 0xFFFFA9CC, accentViolet: 0xFFCEB8FF, accentBlue: 0xFFACCEFF,
        onAccent: 0xFF21112F, ambientB: 0xFF7954A9, ambientC: 0xFF528E98,
        ambientIntensity: 0.42, backdrop: .grid, glassAlpha: 0.88,
        glassBorderLight: 0x708E74AC, glassBorderDark: 0x382B1C41, glassSpecular: 0x70EEE0FF
    )

    static let winter = build(
        isDark: true,
        background: 0xFF0B1829, backgroundDeep: 0xFF050E1B,
        surface: 0xFF14263B, surfaceElevated: 0xFF1C334B,
        borderSubtle: 0xFF30475F, borderMedium: 0xFF506B87,
        textPrimary: 0xFFF2F7FF, textSecondary: 0xFFBDD0E5, textTertiary: 0xFFADC2DA,
        accent: 0xFFADDFFF, accentSecondary: 0xFFD9D7FF,
        accentEmerald: 0xFF8DDCC5, accentAmber: 0xFFF4D29A,
        accentCrimson: 0xFFFFA6B4, accentViolet: 0xFFC8BDF5, accentBlue: 0xFFADDFFF,
        onAccent: 0xFF10263C, ambientB: 0xFF749CC8, ambientC: 0xFFBCCBEC,
        ambientIntensity: 0.55, backdrop: .winter, glassAlpha: 0.88,
        glassBorderLight: 0x709BC7E8, glassBorderDark: 0x383D7195, glassSpecular: 0x70E5F4FF
    )

    static let winterLight = build(
        isDark: false,
        background: 0xFFEFF5FC, backgroundDeep: 0xFFDFEAF6,
        surface: 0xFFFFFFFF, surfaceElevated: 0xFFF7FAFE,
        borderSubtle: 0xFFBFD0E3, borderMedium: 0xFF8AA6C2,
        textPrimary: 0xFF132A40, textSecondary: 0xFF334E68, textTertiary: 0xFF546E85,
        accent: 0xFF1D62A8, accentSecondary: 0xFF5A58A6,
        accentEmerald: 0xFF0A7560, accentAmber: 0xFF9A5B0B,
        accentCrimson: 0xFFBE2E56, accentViolet: 0xFF68519F, accentBlue: 0xFF1D62A8,
        onAccent: 0xFFFFFFFF, ambientB: 0xFF9BC2E2, ambientC: 0xFFC4BFE4,
        ambientIntensity: 0.38, backdrop: .winter, glassAlpha: 0.94,
        glassBorderLight: 0xEFFFFFFF, glassBorderDark: 0x487B9BBA, glassSpecular: 0xCFFFFFFF
    )

    static let red = build(
        isDark: true,
        background: 0xFF080A0C, backgroundDeep: 0xFF030304,
        surface: 0xFF131518, surfaceElevated: 0xFF1B1E24,
        borderSubtle: 0xFF282E38, borderMedium: 0xFF3A424F,
        textPrimary: 0xFFF8F9FA, textSecondary: 0xFF9EA5B2, textTertiary: 0xFF9BA3AF,
        accent: 0xFFFF8C93, accentSecondary: 0xFFF1B1A0,
        accentEmerald: 0xFF67D8AA, accentAmber: 0xFFF0BF69,
        accentCrimson: 0xFFFF7890, accentViolet: 0xFFB0B5C2, accentBlue: 0xFFFF8C93,
        onAccent: 0xFF21070B, ambientB: 0xFFD5796E, ambientC: 0xFF920018,
        ambientIntensity: 0.82, backdrop: .rings, glassAlpha: 0.86,
        glassBorderLight: 0x60F19CA3, glassBorderDark: 0x28FFFFFF, glassSpecular: 0x32FFFFFF
    )

    static let aurora = build(
        isDark: true,
        background: 0xFF020E16, backgroundDeep: 0xFF01080E,
        surface: 0xFF06202C, surfaceElevated: 0xFF0B3040,
        borderSubtle: 0xFF135060, borderMedium: 0xFF1E7890,
        textPrimary: 0xFFE8FFF5, textSecondary: 0xFFA7C9C4, textTertiary: 0xFF87BAB3,
        accent: 0xFF83E4C2, accentSecondary: 0xFF85C9ED,
        accentEmerald: 0xFF00E676, accentAmber: 0xFFFFD04F,
        accentCrimson: 0xFFFF8198, accentViolet: 0xFFA78BFA, accentBlue: 0xFF85C9ED,
        onAccent: 0xFF001A10, ambientB: 0xFFA78BFA, ambientC: 0xFF85C9ED,
        ambientIntensity: 0.85, backdrop: .aurora, glassAlpha: 0.84,
        glassBorderLight: 0x6092DCC4, glassBorderDark: 0x3800C0FF, glassSpecular: 0x4420FFB0
    )

    static let sunset = build(
        isDark: true,
        background: 0xFF120414, backgroundDeep: 0xFF06010A,
        surface: 0xFF220E28, surfaceElevated: 0xFF301438,
        borderSubtle: 0xFF413044, borderMedium: 0xFF69506B,
        textPrimary: 0xFFFFF5ED, textSecondary: 0xFFDFC0B8, textTertiary: 0xFFB99BAA,
        accent: 0xFFFFAA87, accentSecondary: 0xFFF4CC89,
        accentEmerald: 0xFF25E8A0, accentAmber: 0xFFF4C474,
        accentCrimson: 0xFFFF7890, accentViolet: 0xFFC8A0ED, accentBlue: 0xFFFF8545,
        onAccent: 0xFF1C0804, ambientB: 0xFFF4CC89, ambientC: 0xFFA681B2,
        ambientIntensity: 0.85, backdrop: .sunset, glassAlpha: 0.88,
        glassBorderLight: 0x68EAB2A2, glassBorderDark: 0x38BB6EFF, glassSpecular: 0x44FFDCC0
    )

    static let ocean = build(
        isDark: true,
        background: 0xFF041721, backgroundDeep: 0xFF020C16,
        surface: 0xFF0B2230, surfaceElevated: 0xFF13303F,
        borderSubtle: 0xFF2D5361, borderMedium: 0xFF46717E,
        textPrimary: 0xFFEAF8FF, textSecondary: 0xFFB7D2D7, textTertiary: 0xFFA4C2CC,
        accent: 0xFF88DDC7, accentSecondary: 0xFF9ACCE8,
        accentEmerald: 0xFF62DEB4, accentAmber: 0xFFF4CB83,
        accentCrimson: 0xFFFF839C, accentViolet: 0xFFC1ABEE, accentBlue: 0xFF9BBFF9,
        onAccent: 0xFF031820, ambientB: 0xFF4E8DA0, ambientC: 0xFF64BBA7,
        ambientIntensity: 0.65, backdrop: .ocean, glassAlpha: 0.84,
        glassBorderLight: 0x6082DCEC, glassBorderDark: 0x38376787, glassSpecular: 0x44D7F4FF
    )

    static let sakura = build(
        isDark: true,
        background: 0xFF140D1D, backgroundDeep: 0xFF090610,
        surface: 0xFF251A30, surfaceElevated: 0xFF30233D,
        borderSubtle: 0xFF493650, borderMedium: 0xFF6E536F,
        textPrimary: 0xFFFFF2F6, textSecondary: 0xFFE2CADB, textTertiary: 0xFFC4ADC8,
        accent: 0xFFF4B5CD, accentSecondary: 0xFFCCB8EF,
        accentEmerald: 0xFF83DDB5, accentAmber: 0xFFF0D19A,
        accentCrimson: 0xFFFF8FA9, accentViolet: 0xFFCCB8EF, accentBlue: 0xFFA8C5F2,
        onAccent: 0xFF250E1C, ambientB: 0xFFB18AC8, ambientC: 0xFFEC9BB9,
        ambientIntensity: 0.90, backdrop: .sakura, glassAlpha: 0.84,
        glassBorderLight: 0x68F4B5CD, glassBorderDark: 0x386E536F, glassSpecular: 0x44FFF0F7
    )

    static let pony = build(
        isDark: false,
        background: 0xFFFAF6FE, backgroundDeep: 0xFFEFE7FA,
        surface: 0xFFFFFFFF, surfaceElevated: 0xFFFCF8FF,
        borderSubtle: 0xFFD9C7E9, borderMedium: 0xFFB296CA,
        textPrimary: 0xFF2B1C3A, textSecondary: 0xFF524063, textTertiary: 0xFF6E5C80,
        accent: 0xFF7842AC, accentSecondary: 0xFFA82F75,
        accentEmerald: 0xFF047857, accentAmber: 0xFFB45309,
        accentCrimson: 0xFFDC2646, accentViolet: 0xFF7842AC, accentBlue: 0xFF2865B0,
        onAccent: 0xFFFFFFFF, ambientB: 0xFFE6A8D4, ambientC: 0xFFA2DCF2,
        ambientIntensity: 0.42, backdrop: .pony, glassAlpha: 0.96,
        glassBorderLight: 0xEEFFFFFF, glassBorderDark: 0x45B296CA, glassSpecular: 0xAAFFFFFF,
        accentConnected: 0xFF7842AC
    )

    static let winx = build(
        isDark: false,
        background: 0xFFFCF5F9, backgroundDeep: 0xFFF6E7F1,
        surface: 0xFFFFFFFF, surfaceElevated: 0xFFFFF8FC,
        borderSubtle: 0xFFE5C4D8, borderMedium: 0xFFC896B4,
        textPrimary: 0xFF381C2F, textSecondary: 0xFF624255, textTertiary: 0xFF7D5D70,
        accent: 0xFFAA296F, accentSecondary: 0xFF276A99,
        accentEmerald: 0xFF047857, accentAmber: 0xFFB45309,
        accentCrimson: 0xFFDC2646, accentViolet: 0xFF8142AE, accentBlue: 0xFF276A99,
        onAccent: 0xFFFFFFFF, ambientB: 0xFFEFB6D1, ambientC: 0xFFA3DDF0,
        ambientIntensity: 0.42, backdrop: .bloom, glassAlpha: 0.96,
        glassBorderLight: 0xEEFFFFFF, glassBorderDark: 0x45C896B4, glassSpecular: 0xAAFFFFFF,
        accentConnected: 0xFFAA296F
    )
}
