import SwiftUI

// MARK: - Panel Theme (layout/size presets)

enum PanelTheme: String, CaseIterable, Identifiable, Codable {
    case compact
    case comfortable
    case spacious

    var id: String { rawValue }

    var title: String {
        switch self {
        case .compact: "Compact"
        case .comfortable: "Comfortable"
        case .spacious: "Spacious"
        }
    }

    var description: String {
        switch self {
        case .compact: "Smaller text, tighter layout"
        case .comfortable: "Default balanced layout"
        case .spacious: "Larger text, more breathing room"
        }
    }
}

// MARK: - Color Scheme

enum PanelColorScheme: String, CaseIterable, Identifiable, Codable {
    case standard
    case highContrast
    case muted
    case monochrome

    var id: String { rawValue }

    var title: String {
        switch self {
        case .standard: "Standard"
        case .highContrast: "High Contrast"
        case .muted: "Muted"
        case .monochrome: "Monochrome"
        }
    }

    var description: String {
        switch self {
        case .standard: "Default blue and orange tones"
        case .highContrast: "Bold colors, stronger borders"
        case .muted: "Soft pastel tones"
        case .monochrome: "Grayscale only"
        }
    }
}

// MARK: - Panel Appearance

struct PanelAppearance {
    let theme: PanelTheme
    let colorScheme: PanelColorScheme

    init(theme: PanelTheme = .comfortable, colorScheme: PanelColorScheme = .standard) {
        self.theme = theme
        self.colorScheme = colorScheme
    }

    // MARK: - Layout (from theme)

    var panelWidth: CGFloat {
        switch theme {
        case .compact: 360
        case .comfortable: 420
        case .spacious: 500
        }
    }

    var panelHeight: CGFloat {
        switch theme {
        case .compact: 340
        case .comfortable: 380
        case .spacious: 440
        }
    }

    var contentFont: Font {
        switch theme {
        case .compact: .caption
        case .comfortable: .callout
        case .spacious: .body
        }
    }

    var pillFontSize: CGFloat {
        switch theme {
        case .compact: 10
        case .comfortable: 12
        case .spacious: 14
        }
    }

    var contentPadding: CGFloat {
        switch theme {
        case .compact: 12
        case .comfortable: 16
        case .spacious: 20
        }
    }

    var sectionSpacing: CGFloat {
        switch theme {
        case .compact: 8
        case .comfortable: 12
        case .spacious: 16
        }
    }

    var sectionPadding: CGFloat {
        switch theme {
        case .compact: 6
        case .comfortable: 8
        case .spacious: 10
        }
    }

    var cornerRadius: CGFloat {
        switch theme {
        case .compact: 8
        case .comfortable: 12
        case .spacious: 16
        }
    }

    // MARK: - Colors (from colorScheme)

    var tldrBackground: Color {
        switch colorScheme {
        case .standard: Color.orange.opacity(0.08)
        case .highContrast: Color.orange.opacity(0.18)
        case .muted: Color.orange.opacity(0.05)
        case .monochrome: Color.gray.opacity(0.08)
        }
    }

    var tldrAccent: Color {
        switch colorScheme {
        case .standard: .orange
        case .highContrast: .orange
        case .muted: Color.orange.opacity(0.6)
        case .monochrome: .gray
        }
    }

    var explanationBackground: Color {
        switch colorScheme {
        case .standard: Color.blue.opacity(0.05)
        case .highContrast: Color.blue.opacity(0.12)
        case .muted: Color.blue.opacity(0.03)
        case .monochrome: Color.gray.opacity(0.05)
        }
    }

    var resourcesBackground: Color {
        switch colorScheme {
        case .standard: Color.gray.opacity(0.06)
        case .highContrast: Color.gray.opacity(0.12)
        case .muted: Color.gray.opacity(0.04)
        case .monochrome: Color.gray.opacity(0.06)
        }
    }

    var codeBlockOpacity: Double {
        switch colorScheme {
        case .standard: 0.2
        case .highContrast: 0.3
        case .muted: 0.12
        case .monochrome: 0.15
        }
    }

    var addedColor: Color {
        switch colorScheme {
        case .standard: .green
        case .highContrast: Color.green
        case .muted: Color.green.opacity(0.7)
        case .monochrome: Color.primary
        }
    }

    var removedColor: Color {
        switch colorScheme {
        case .standard: .red
        case .highContrast: Color.red
        case .muted: Color.red.opacity(0.6)
        case .monochrome: Color.secondary
        }
    }

    var pillSelectedBackground: Color {
        switch colorScheme {
        case .standard: Color.accentColor.opacity(0.2)
        case .highContrast: Color.accentColor.opacity(0.35)
        case .muted: Color.accentColor.opacity(0.12)
        case .monochrome: Color.gray.opacity(0.2)
        }
    }

    var pillSelectedBorder: Color {
        switch colorScheme {
        case .standard: Color.accentColor.opacity(0.5)
        case .highContrast: Color.accentColor.opacity(0.8)
        case .muted: Color.accentColor.opacity(0.3)
        case .monochrome: Color.gray.opacity(0.5)
        }
    }

    var pillUnselectedBorder: Color {
        switch colorScheme {
        case .standard: Color.secondary.opacity(0.3)
        case .highContrast: Color.secondary.opacity(0.5)
        case .muted: Color.secondary.opacity(0.2)
        case .monochrome: Color.gray.opacity(0.3)
        }
    }

    var linkColor: Color {
        switch colorScheme {
        case .standard: .blue
        case .highContrast: .blue
        case .muted: Color.blue.opacity(0.7)
        case .monochrome: .primary
        }
    }
}
