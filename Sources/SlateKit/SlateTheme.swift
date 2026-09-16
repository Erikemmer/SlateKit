import SwiftUI

/// Colours and metrics modelled on Final Cut Pro's dark interface.
///
/// One place for the whole palette, so the look can be tuned without touching
/// a single view – and so two apps built on this package look like siblings
/// rather than cousins.
public enum Slate {
    // MARK: Surfaces

    /// Behind everything; the darkest thing that is still a panel.
    public static let windowBackground = Color(red: 0.118, green: 0.118, blue: 0.118)  // #1E1E1E
    /// Sidebars, inspectors, strips – the furniture around the content.
    public static let panelBackground = Color(red: 0.169, green: 0.169, blue: 0.169)  // #2B2B2B
    /// Where the content itself sits. Darker than the panels so a photo or a
    /// page has nothing competing with it.
    public static let contentBackground = Color(red: 0.086, green: 0.086, blue: 0.086)  // #161616
    public static let separator = Color.white.opacity(0.08)

    // MARK: Text

    public static let textPrimary = Color(white: 0.92)
    public static let textSecondary = Color(white: 0.60)

    /// Final Cut's yellow-orange. Selection, the active row, anything the eye
    /// should land on first – and nothing else, or it stops meaning anything.
    public static let accent = Color(red: 1.0, green: 0.78, blue: 0.20)

    // MARK: Verdict colours

    /// "Yes, keep it." Also the colour of a finished, successful thing.
    public static let affirm = Color(red: 0.30, green: 0.85, blue: 0.40)
    /// "No." Also failures and warnings that need an answer.
    public static let deny = Color(red: 0.95, green: 0.30, blue: 0.30)

    // MARK: Metrics

    /// Small on purpose. Final Cut rounds corners just enough to soften them.
    public static let cornerRadius: CGFloat = 4
    /// Panels that float above the content (overlays, popovers) are rounded a
    /// little more, so they read as lying on top rather than being cut into it.
    public static let floatingCornerRadius: CGFloat = 6
}

/// The five label colours, close enough to Lightroom's that a picture keeps its
/// meaning when it travels between tools. Generic on purpose: an app maps its
/// own vocabulary onto these, the package never learns what "red" means.
public enum SlateSwatch: String, CaseIterable, Sendable {
    case red, yellow, green, blue, purple

    public var color: Color {
        switch self {
        case .red: return Color(red: 0.93, green: 0.27, blue: 0.27)
        case .yellow: return Color(red: 0.98, green: 0.80, blue: 0.20)
        case .green: return Color(red: 0.36, green: 0.80, blue: 0.40)
        case .blue: return Color(red: 0.30, green: 0.58, blue: 0.98)
        case .purple: return Color(red: 0.70, green: 0.45, blue: 0.95)
        }
    }
}
