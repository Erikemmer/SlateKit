import SwiftUI

/// One keyboard shortcut as the user reads it. The app owns the table; this is
/// only the shape the views need.
public struct SlateShortcut: Identifiable, Hashable, Sendable {
    public var id: String { "\(group).\(keys)" }
    /// How the keys are written, e.g. "1–5" or "⌘⇧E".
    public let keys: String
    public let action: String
    public let group: String

    public init(keys: String, action: String, group: String = "") {
        self.keys = keys
        self.action = action
        self.group = group
    }
}

/// The key itself, set in a monospaced face so ⌘⇧E and 1–5 line up.
public struct SlateKeyBadge: View {
    private let keys: String

    public init(_ keys: String) {
        self.keys = keys
    }

    public var body: some View {
        Text(keys)
            .font(.caption.monospaced())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 3))
            .foregroundStyle(Slate.textPrimary)
    }
}

/// The handful of keys worth knowing, on one line: "P Pick · X Reject · …".
/// For a welcome screen, where a full table would be too much to read.
public struct SlateShortcutLine: View {
    private let shortcuts: [SlateShortcut]

    public init(_ shortcuts: [SlateShortcut]) {
        self.shortcuts = shortcuts
    }

    /// Wrapping, with each hint a unit that does not break inside itself.
    ///
    /// It was one `HStack`, and with five hints in a 590-point column SwiftUI
    /// did what an `HStack` does when it runs out of room: it squeezed the
    /// *labels*. "Open Library…" became two lines, "Move through the grid"
    /// three, and a row meant to be read at a glance came out ragged. Found on
    /// the first screenshot ever taken of Shelf's welcome screen.
    ///
    /// A flow layout wraps between hints instead of inside them. The separator
    /// travels with its own hint rather than sitting between two, so a line
    /// break never leaves a dot hanging at the start of a row.
    public var body: some View {
        SlateFlowLayout(spacing: 10) {
            ForEach(Array(shortcuts.enumerated()), id: \.element.id) { index, shortcut in
                HStack(spacing: 5) {
                    if index > 0 {
                        Text("·").foregroundStyle(Slate.separator)
                    }
                    Text(shortcut.keys).monospaced().foregroundStyle(Slate.textPrimary)
                    Text(shortcut.action).foregroundStyle(Slate.textSecondary)
                }
                .lineLimit(1)
                .fixedSize()
            }
        }
        .font(.caption)
    }
}

/// Every shortcut at once, grouped, in two columns – the window you open when
/// you know there is a key for this but not which one.
///
/// Two columns rather than one long list: the whole point is to find a line
/// without scrolling, and scrolling is what a single column would force.
public struct SlateShortcutSheet: View {
    private let title: String
    private let groups: [(name: String, shortcuts: [SlateShortcut])]
    private let onClose: () -> Void

    public init(
        title: String,
        groups: [(name: String, shortcuts: [SlateShortcut])],
        onClose: @escaping () -> Void
    ) {
        self.title = title
        self.groups = groups
        self.onClose = onClose
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.title2.weight(.semibold))
                .foregroundStyle(Slate.textPrimary)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 14)
            ScrollView {
                HStack(alignment: .top, spacing: 28) {
                    column(of: leftGroups)
                    column(of: rightGroups)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            Divider()
            HStack {
                Spacer()
                Button(String(localized: "Close", bundle: .module), action: onClose).keyboardShortcut(.cancelAction)
            }
            .padding(14)
        }
        // Sized to what the table actually holds, not a number picked once and
        // left behind: the window used to be a fixed 560×480 regardless of how
        // many shortcuts the two columns held. `maxHeight` is a safety net, not
        // a target — the inner ScrollView still scrolls if a future shortcut
        // list ever grows past it; today's table fits well inside it.
        .frame(minWidth: 480, idealWidth: 620, maxWidth: 760, maxHeight: 700)
        .fixedSize(horizontal: false, vertical: true)
        .background(Slate.windowBackground)
    }

    /// Split so the two columns hold roughly the same number of lines, not the
    /// same number of groups – one group of nine beside one of three looks broken.
    /// Each group costs its shortcuts plus one line for its heading.
    nonisolated static func splitPoint(groupSizes: [Int]) -> Int {
        guard !groupSizes.isEmpty else { return 0 }
        let half = groupSizes.reduce(0) { $0 + $1 + 1 } / 2
        var lines = 0
        for (index, size) in groupSizes.enumerated() {
            lines += size + 1
            if lines >= half { return index + 1 }
        }
        return groupSizes.count
    }

    private var splitPoint: Int { Self.splitPoint(groupSizes: groups.map(\.shortcuts.count)) }

    private var leftGroups: ArraySlice<(name: String, shortcuts: [SlateShortcut])> {
        groups[..<splitPoint]
    }
    private var rightGroups: ArraySlice<(name: String, shortcuts: [SlateShortcut])> {
        groups[splitPoint...]
    }

    private func column(
        of groups: ArraySlice<(name: String, shortcuts: [SlateShortcut])>
    )
        -> some View
    {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(Array(groups), id: \.name) { group in
                VStack(alignment: .leading, spacing: 6) {
                    Text(group.name.uppercased())
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Slate.textSecondary)
                    Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 5) {
                        ForEach(group.shortcuts) { shortcut in
                            GridRow {
                                SlateKeyBadge(shortcut.keys).gridColumnAlignment(.trailing)
                                Text(shortcut.action)
                                    .font(.callout)
                                    .foregroundStyle(Slate.textPrimary)
                                    .gridColumnAlignment(.leading)
                            }
                        }
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
