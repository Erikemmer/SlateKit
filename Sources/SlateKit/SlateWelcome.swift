import AppKit
import SwiftUI

/// What a window shows before anything is open: how to start, what was open
/// last, and the handful of keys worth knowing.
///
/// Quiet on purpose – it is a workspace waiting for work, not a landing page.
/// The column is capped at 420 pt because a centred stack that grows with the
/// window stops being a focus and becomes a wall.
public struct SlateWelcomeLayout<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        ZStack {
            Slate.contentBackground
            VStack(spacing: 20) {
                content
            }
            .frame(maxWidth: 420)
            .padding(20)
        }
    }
}

/// App icon, name, and one line saying what the app is for.
public struct SlateWelcomeHeader: View {
    private let title: String
    private let subtitle: String
    private let iconSize: CGFloat

    public init(title: String, subtitle: String, iconSize: CGFloat = 96) {
        self.title = title
        self.subtitle = subtitle
        self.iconSize = iconSize
    }

    public var body: some View {
        VStack(spacing: 8) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: iconSize, height: iconSize)
                .accessibilityHidden(true)
            Text(title)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(Slate.textPrimary)
            Text(subtitle)
                .font(.callout)
                .foregroundStyle(Slate.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
}

/// The way in that most days start with. Yellow, large, unmissable.
public struct SlatePrimaryButton: View {
    private let title: String
    private let action: () -> Void

    public init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .padding(.horizontal, 12)
                .padding(.vertical, 2)
        }
        .controlSize(.large)
        .buttonStyle(.borderedProminent)
        .tint(Slate.accent)
        .foregroundStyle(.black)
    }
}

/// The other way in. Same size, no colour – it is offered, not urged.
public struct SlateSecondaryButton: View {
    private let title: String
    private let action: () -> Void

    public init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .padding(.horizontal, 12)
                .padding(.vertical, 2)
        }
        .controlSize(.large)
    }
}

/// A dashed rectangle that says things can be dropped here, and lights up when
/// something is held over it.
public struct SlateDropZone: View {
    private let title: String
    private let symbol: String
    private let isTargeted: Bool

    public init(title: String, symbol: String = "arrow.down.doc", isTargeted: Bool) {
        self.title = title
        self.symbol = symbol
        self.isTargeted = isTargeted
    }

    public var body: some View {
        VStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(isTargeted ? Slate.accent : Slate.textSecondary)
                // Decorative: the title beside it says the same thing in words,
                // and the symbol's own name ("arrow.down.doc") says it in none.
                .accessibilityHidden(true)
            Text(title)
                .font(.callout)
                .foregroundStyle(isTargeted ? Slate.textPrimary : Slate.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: Slate.cornerRadius)
                .fill(isTargeted ? Slate.accent.opacity(0.08) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Slate.cornerRadius)
                .strokeBorder(
                    isTargeted ? Slate.accent : Slate.separator,
                    style: StrokeStyle(lineWidth: 1, dash: [4, 4])
                )
        )
    }
}

/// The "Recent" list under the buttons.
public struct SlateRecentList<Content: View>: View {
    private let title: String
    private let content: Content

    public init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Slate.textSecondary)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// One entry in the recent list: name, a short summary, and the path underneath.
///
/// An entry whose folder is not there right now is dimmed rather than hidden.
/// A disconnected drive is a normal Tuesday, and a list that silently loses
/// rows teaches people not to trust it.
public struct SlateRecentRow: View {
    private let name: String
    private let detail: String?
    private let path: String
    private let isReachable: Bool
    private let help: String
    private let action: () -> Void

    public init(
        name: String,
        detail: String? = nil,
        path: String,
        isReachable: Bool = true,
        help: String = "",
        action: @escaping () -> Void
    ) {
        self.name = name
        self.detail = detail
        self.path = path
        self.isReachable = isReachable
        self.help = help
        self.action = action
    }

    @FocusState private var isFocused: Bool

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: isReachable ? "folder" : "questionmark.folder")
                    .accessibilityHidden(true)
                    .foregroundStyle(Slate.textSecondary)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(name).foregroundStyle(Slate.textPrimary)
                        if let detail { Text(detail).font(.caption).foregroundStyle(Slate.textSecondary) }
                    }
                    Text(path)
                        .font(.caption)
                        .foregroundStyle(Slate.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.head)
                }
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .focusable()
        .focused($isFocused)
        .slateFocusRing(isFocused)
        .opacity(isReachable ? 1 : 0.4)
        .help(help)
    }
}
