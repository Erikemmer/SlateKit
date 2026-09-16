import AppKit
import SwiftUI

/// The small capitalised heading above a group of sidebar rows.
public struct SlateSidebarSection: View {
    private let title: String

    public init(_ title: String) {
        self.title = title
    }

    public var body: some View {
        Text(title.uppercased())
            .font(.caption2.weight(.semibold))
            .foregroundStyle(Slate.textSecondary)
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 4)
            // Every row spans the column. Without this the widest row decides
            // how wide the content is, and anything wider than the sidebar gets
            // clipped on both sides.
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// One row of a sidebar list: icon, name, a count on the right, highlighted
/// while it is part of what is being shown.
///
/// No width of its own – the column decides how wide it is, so the same row
/// works in a 200 pt sidebar and a 320 pt one.
public struct SlateSidebarRow<Title: View>: View {
    private let icon: String
    private let count: Int?
    private let tint: Color
    private let isActive: Bool
    private let help: String
    private let topPadding: CGFloat
    private let title: Title
    private let action: ((_ isCommandHeld: Bool) -> Void)?

    /// - Parameters:
    ///   - tint: colour of the icon; the label colours use this.
    ///   - isActive: draws the accent wash behind the row.
    ///   - action: told whether ⌘ was held, so a list can offer "narrow down"
    ///     as well as "show this".
    public init(
        icon: String,
        count: Int? = nil,
        tint: Color = Slate.textSecondary,
        isActive: Bool = false,
        help: String = "",
        topPadding: CGFloat = 0,
        @ViewBuilder title: () -> Title,
        action: ((_ isCommandHeld: Bool) -> Void)? = nil
    ) {
        self.icon = icon
        self.count = count
        self.tint = tint
        self.isActive = isActive
        self.help = help
        self.topPadding = topPadding
        self.title = title()
        self.action = action
    }

    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(tint)
                .frame(width: 14)
            title
            Spacer(minLength: 4)
            if let count {
                Text("\(count)")
                    .monospacedDigit()
                    .foregroundStyle(Slate.textSecondary)
            }
        }
        .font(.callout)
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .padding(.top, topPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isActive ? Slate.accent.opacity(0.18) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture { action?(NSEvent.modifierFlags.contains(.command)) }
        .help(help)
    }
}

/// A sidebar row's name, styled the one way sidebar names are styled.
public struct SlateSidebarTitle: View {
    private let text: String
    private let color: Color

    public init(_ text: String, color: Color = Slate.textPrimary) {
        self.text = text
        self.color = color
    }

    public var body: some View {
        Text(text).foregroundStyle(color).lineLimit(1)
    }
}

extension SlateSidebarRow where Title == SlateSidebarTitle {
    /// The common case: a plain name.
    public init(
        _ title: String,
        icon: String,
        count: Int? = nil,
        tint: Color = Slate.textSecondary,
        isActive: Bool = false,
        help: String = "",
        topPadding: CGFloat = 0,
        titleColor: Color = Slate.textPrimary,
        action: ((_ isCommandHeld: Bool) -> Void)? = nil
    ) {
        self.init(
            icon: icon, count: count, tint: tint, isActive: isActive, help: help, topPadding: topPadding,
            title: { SlateSidebarTitle(title, color: titleColor) }, action: action)
    }
}

/// The row that names what is open, at the very top of the sidebar.
public struct SlateSidebarHeaderRow: View {
    private let title: String
    private let icon: String
    private let help: String

    public init(_ title: String, icon: String = "folder.fill", help: String = "") {
        self.title = title
        self.icon = icon
        self.help = help
    }

    public var body: some View {
        Label(title, systemImage: icon)
            .font(.body)
            .foregroundStyle(Slate.textPrimary)
            .lineLimit(1)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Slate.accent.opacity(0.18), in: RoundedRectangle(cornerRadius: Slate.cornerRadius)
            )
            .padding(.horizontal, 6)
            .padding(.top, 8)
            .help(help)
    }
}
