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
public struct SlateSidebarRow<Title: View, Accessory: View>: View {
    private let icon: String
    private let count: Int?
    private let tint: Color
    private let isActive: Bool
    private let help: String
    private let topPadding: CGFloat
    private let title: Title
    private let accessory: Accessory
    private let action: ((_ isCommandHeld: Bool) -> Void)?
    @FocusState private var isFocused: Bool

    /// - Parameters:
    ///   - tint: colour of the icon; the label colours use this.
    ///   - isActive: draws the accent wash behind the row.
    ///   - accessory: a trailing control (e.g. a delete button) after the
    ///     count; supplies its own accessibility label since a row's own
    ///     spoken value (title + count) says nothing about it.
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
        @ViewBuilder accessory: () -> Accessory = { EmptyView() },
        action: ((_ isCommandHeld: Bool) -> Void)? = nil
    ) {
        self.icon = icon
        self.count = count
        self.tint = tint
        self.isActive = isActive
        self.help = help
        self.topPadding = topPadding
        self.title = title()
        self.accessory = accessory()
        self.action = action
    }

    public var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(tint)
                    .frame(width: 14)
                    // Decorative: the title already says what this row is:
                    // VoiceOver reading the symbol's own name first ("flag,
                    // Picks, 3") would put the least useful word first.
                    .accessibilityHidden(true)
                title
                Spacer(minLength: 4)
                if let count {
                    Text("\(count)")
                        .monospacedDigit()
                        // textSecondary on the plain background clears WCAG AA, but
                        // dims to 3.2:1 against the active row's accent tint — the
                        // same isActive/isSelected switch SlateGridCell already
                        // uses for its own caption text.
                        .foregroundStyle(isActive ? Slate.textPrimary : Slate.textSecondary)
                }
            }
            // Combines the title and count text into one spoken value, e.g.
            // "Picks, 3" — scoped to exclude `accessory`, which must stay its
            // own reachable element (a delete button folded into this would
            // no longer be individually activatable by VoiceOver).
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(isActive ? .isSelected : [])
            accessory
        }
        .font(.callout)
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .padding(.top, topPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isActive ? Slate.accent.opacity(0.18) : Color.clear)
        .overlay {
            // A plain custom view draws no focus ring of its own, unlike a
            // real control – without this, a keyboard-only user could Tab
            // onto a row and never see where they landed.
            if isFocused {
                RoundedRectangle(cornerRadius: Slate.cornerRadius).stroke(Slate.accent, lineWidth: 2)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { action?(NSEvent.modifierFlags.contains(.command)) }
        .focusable(action != nil)
        .focused($isFocused)
        .onKeyPress(keys: [.return, .space]) { _ in
            guard let action else { return .ignored }
            action(NSEvent.modifierFlags.contains(.command))
            return .handled
        }
        .help(help)
        .accessibilityAddTraits(isActive ? .isSelected : [])
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
        @ViewBuilder accessory: () -> Accessory = { EmptyView() },
        action: ((_ isCommandHeld: Bool) -> Void)? = nil
    ) {
        self.init(
            icon: icon, count: count, tint: tint, isActive: isActive, help: help, topPadding: topPadding,
            title: { SlateSidebarTitle(title, color: titleColor) }, accessory: accessory, action: action)
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
