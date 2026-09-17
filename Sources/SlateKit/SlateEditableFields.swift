import SwiftUI

/// Editable fields for an inspector: one line, several lines, and a field that
/// collects small named pieces.
///
/// They exist because an inspector that *shows* values and an inspector that
/// *edits* them should be the same column with the same spacing, not two
/// designs. `SlateValueRow` draws a name on the left and a value on the right;
/// `SlateEditableRow` draws a name on the left and a field on the right, at the
/// same size, so a column of facts becomes a column of fields without moving.
///
/// ## What they all do the same way
///
/// - **A field is finished by ⏎ or by losing focus**, and only then is the new
///   value handed over. Not per keystroke: the host writes a file when a field
///   is finished, and a file per keystroke is a file per keystroke.
/// - **Escape puts the old value back** and gives up focus.
/// - **A value changed from outside** — an undo, another window — replaces what
///   the field shows, unless the field is being typed in. Typing is never
///   interrupted; a field nobody is touching always tells the truth.
///
/// The host keeps no draft state and no focus bookkeeping: it passes the value
/// in and gets a finished string back.
/// A name on the left and an editable value on the right, sized like
/// `SlateValueRow` so the two can sit in one column.
public struct SlateEditableRow: View {
    private let name: String
    private let value: String
    private let placeholder: String
    private let onCommit: (String) -> Void
    private let help: String?

    public init(
        name: String, value: String, placeholder: String = "", help: String? = nil,
        onCommit: @escaping (String) -> Void
    ) {
        self.name = name
        self.value = value
        self.placeholder = placeholder
        self.help = help
        self.onCommit = onCommit
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(name)
                .foregroundStyle(Slate.textSecondary)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer(minLength: 4)
            SlateEditableText(
                value: value, placeholder: placeholder, alignment: .trailing, onCommit: onCommit)
        }
        .font(.callout)
        .help(help ?? name)
    }
}

/// A field on its own, without a name beside it – for a title, a description,
/// anything that has a section heading above it instead.
public struct SlateEditableBlock: View {
    private let value: String
    private let placeholder: String
    private let isMultiline: Bool
    private let lineLimit: Int
    private let font: Font
    private let onCommit: (String) -> Void

    /// - Parameters:
    ///   - isMultiline: ⏎ then inserts a line break instead of finishing the
    ///     field, and losing focus is what finishes it. A description is typed
    ///     in paragraphs; a field that ends on the first ⏎ cannot hold one.
    ///   - lineLimit: how tall a multiline field grows before it scrolls.
    public init(
        value: String, placeholder: String = "", isMultiline: Bool = false, lineLimit: Int = 6,
        font: Font = .callout, onCommit: @escaping (String) -> Void
    ) {
        self.value = value
        self.placeholder = placeholder
        self.isMultiline = isMultiline
        self.lineLimit = lineLimit
        self.font = font
        self.onCommit = onCommit
    }

    public var body: some View {
        SlateEditableText(
            value: value, placeholder: placeholder, alignment: .leading, isMultiline: isMultiline,
            lineLimit: lineLimit, font: font, onCommit: onCommit)
    }
}

/// The field itself: the draft, the focus, ⏎, Escape, and the sync with a value
/// that changed elsewhere. Every editable control in this file is one of these
/// with something drawn next to it.
struct SlateEditableText: View {
    let value: String
    let placeholder: String
    let alignment: TextAlignment
    var isMultiline: Bool = false
    var lineLimit: Int = 6
    var font: Font = .callout
    let onCommit: (String) -> Void

    @State private var draft: String = ""
    @State private var hasAppeared = false
    @State private var isHovered = false
    @FocusState private var isFocused: Bool

    var body: some View {
        field
            .font(font)
            .foregroundStyle(Slate.textPrimary)
            .textFieldStyle(.plain)
            .multilineTextAlignment(alignment)
            .focused($isFocused)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(background)
            .onHover { isHovered = $0 }
            .onAppear {
                // Not in `init`: a `@State` set there is discarded on the next
                // body pass, which is the classic way a field comes up empty.
                guard !hasAppeared else { return }
                hasAppeared = true
                draft = value
            }
            // An undo, or another field's edit that changed this one – the sort
            // title follows a title. Never while the field is being typed in.
            .onChange(of: value) { _, new in
                guard !isFocused else { return }
                draft = new
            }
            .onChange(of: isFocused) { wasFocused, nowFocused in
                // Losing focus finishes the field. This is the only completion
                // a multiline field has.
                if wasFocused, !nowFocused { commit() }
            }
            .onExitCommand { revert() }
    }

    @ViewBuilder
    private var field: some View {
        if isMultiline {
            TextField(placeholder, text: $draft, prompt: SlatePrompt.text(placeholder), axis: .vertical)
                .lineLimit(1...lineLimit)
        } else {
            TextField(placeholder, text: $draft, prompt: SlatePrompt.text(placeholder))
                .onSubmit { commit() }
        }
    }

    /// Visible as a field only while it matters: focused, or under the pointer.
    ///
    /// The first version filled every field faintly at all times, and the first
    /// screenshot of the result showed why that is wrong: nine filled boxes in a
    /// 280-point column read as a form to be completed, where Selector's
    /// inspector reads as a column of values that happen to be editable. The
    /// comment on this very function said so before the code did.
    ///
    /// Nothing at rest, a hint under the pointer, the accent when focused —
    /// so a field is discoverable without the column announcing itself.
    private var background: some View {
        RoundedRectangle(cornerRadius: Slate.cornerRadius)
            .fill(fill)
            .overlay {
                RoundedRectangle(cornerRadius: Slate.cornerRadius)
                    .strokeBorder(isFocused ? Slate.accent.opacity(0.8) : Color.clear, lineWidth: 1)
            }
    }

    private var fill: Color {
        if isFocused { return Color.white.opacity(0.10) }
        if isHovered { return Color.white.opacity(0.05) }
        return .clear
    }

    private func commit() {
        guard draft != value else { return }
        onCommit(draft)
    }

    private func revert() {
        draft = value
        isFocused = false
    }
}

/// A field that collects small named pieces – keywords, and anything else that
/// comes as a handful of words: a line to type in, what the text might mean
/// under it, and the pieces themselves as chips below that.
///
/// The shape is Selector's tag control, down to a placeholder that names the key
/// that focuses the field ("Add tag… (T)"), because a control whose key is
/// written on it is a control people find.
public struct SlateTokenField: View {
    private let tokens: [String]
    private let placeholder: String
    private let completions: [String]
    private let help: String
    private let onAdd: (String) -> Void
    private let onRemove: (String) -> Void
    private let onDraftChange: (String) -> Void
    private let focusRequest: Int
    let chipStyle: SlateChipStyle
    let chipRemoveButton: SlateChipRemoveButton

    /// - Parameters:
    ///   - completions: what the *host* thinks the current draft could mean. It
    ///     is handed in rather than computed here: which tags exist, and how a
    ///     partial word is matched against them, is the host's knowledge.
    ///   - onDraftChange: called as the text changes, so the host can work out
    ///     the completions. It is the one thing here that fires per keystroke,
    ///     and it must stay cheap – nothing is written.
    ///   - focusRequest: a counter. Raising it puts the keyboard in this field,
    ///     which is how a key such as T reaches it. A counter and not a `Bool`
    ///     so pressing the key twice focuses twice.
    ///   - help: shown for the *entry field only*. It is a parameter rather
    ///     than something the host puts on the whole control with `.help()`,
    ///     because that is what the host did and SwiftUI passed it down to every
    ///     chip: each one claimed "⏎ adds, ⌫ removes the last one" in place of
    ///     its own "Remove science fiction". Found in the accessibility tree.
    ///   - chipStyle, chipRemoveButton: handed straight to the chips below the
    ///     field, and defaulting the way `SlateChip` itself does, so this
    ///     control cannot quietly hold a different opinion about what a chip
    ///     looks like from the one the host draws beside it.
    public init(
        tokens: [String],
        placeholder: String,
        completions: [String] = [],
        focusRequest: Int = 0,
        help: String = "",
        chipStyle: SlateChipStyle = .accent,
        chipRemoveButton: SlateChipRemoveButton = .always,
        onDraftChange: @escaping (String) -> Void = { _ in },
        onAdd: @escaping (String) -> Void,
        onRemove: @escaping (String) -> Void
    ) {
        self.tokens = tokens
        self.placeholder = placeholder
        self.completions = completions
        self.focusRequest = focusRequest
        self.help = help
        self.chipStyle = chipStyle
        self.chipRemoveButton = chipRemoveButton
        self.onDraftChange = onDraftChange
        self.onAdd = onAdd
        self.onRemove = onRemove
    }

    @State private var draft = ""
    @FocusState private var isFocused: Bool

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            entry
            if isFocused, !completions.isEmpty {
                SlateFlowLayout(spacing: 6) {
                    ForEach(completions, id: \.self) { completion in
                        SlateSuggestionChip(completion) { add(completion) }
                    }
                }
            }
            if !tokens.isEmpty {
                SlateFlowLayout(spacing: 6) {
                    ForEach(tokens, id: \.self) { token in
                        SlateChip(token, style: chipStyle, removeButton: chipRemoveButton) {
                            onRemove(token)
                        }
                    }
                }
            }
        }
    }

    private var entry: some View {
        TextField(placeholder, text: $draft, prompt: SlatePrompt.text(placeholder))
            .textFieldStyle(.plain)
            .font(.caption)
            .foregroundStyle(Slate.textPrimary)
            .focused($isFocused)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background {
                RoundedRectangle(cornerRadius: Slate.cornerRadius)
                    .fill(isFocused ? Color.white.opacity(0.10) : Color.white.opacity(0.04))
                    .overlay {
                        RoundedRectangle(cornerRadius: Slate.cornerRadius)
                            .strokeBorder(isFocused ? Slate.accent.opacity(0.8) : Color.clear, lineWidth: 1)
                    }
            }
            .onSubmit { add(draft) }
            .onChange(of: draft) { _, new in onDraftChange(new) }
            .onChange(of: focusRequest) { _, _ in isFocused = true }
            .help(help)
            // Backspace in an empty field takes the last chip off, the way every
            // token field since Mail's address row has behaved.
            .onKeyPress(.delete) {
                guard draft.isEmpty, let last = tokens.last else { return .ignored }
                onRemove(last)
                return .handled
            }
            .onExitCommand {
                draft = ""
                onDraftChange("")
                isFocused = false
            }
    }

    private func add(_ token: String) {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onAdd(trimmed)
        draft = ""
        onDraftChange("")
    }
}

/// A line of text under a field, for what went wrong with what was typed.
///
/// Its own view so the message cannot be drawn three different ways in one
/// inspector. `deny` rather than plain red: at 4.5:1 on a panel it is readable,
/// which the obvious red was not (see `Slate.deny`).
public struct SlateFieldNote: View {
    private let text: String

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        Text(text)
            .font(.caption2)
            .foregroundStyle(Slate.deny)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isStaticText)
    }
}

/// What an empty field says about itself.
///
/// Its own type because a placeholder is not a value and must never be drawn
/// like one. A field carries `Slate.textPrimary`, and SwiftUI hands that colour
/// to the placeholder too unless it is told otherwise – so an empty inspector
/// read as a column of books whose publisher was "Add publisher…". The prompt
/// is therefore built here, once, in the colour a label wears.
///
/// The title still goes to `TextField` as its first argument even though the
/// prompt is what gets drawn: that argument is what the accessibility tree uses
/// as the field's name, and a field whose name is "" is a field VoiceOver
/// cannot announce.
enum SlatePrompt {
    static func text(_ placeholder: String) -> Text? {
        guard !placeholder.isEmpty else { return nil }
        return Text(placeholder).foregroundStyle(Slate.textSecondary)
    }
}
