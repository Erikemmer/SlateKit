import SwiftUI

/// A quiet line at the foot of a panel saying what the machine is busy with.
///
/// It appears while there is work and disappears when there is none – nothing
/// here ever says "done", because a finished job has nothing left to report.
public struct SlateStatusBar: View {
    private let text: String
    private let showsSpinner: Bool

    public init(_ text: String, showsSpinner: Bool = true) {
        self.text = text
        self.showsSpinner = showsSpinner
    }

    public var body: some View {
        HStack(spacing: 8) {
            if showsSpinner {
                ProgressView().controlSize(.small).scaleEffect(0.7)
            }
            Text(text)
                .font(.caption2)
                .foregroundStyle(Slate.textSecondary)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .transition(.opacity)
    }
}

/// A one-line banner over the content, for something that went wrong and the
/// user can do nothing about right now.
public struct SlateBanner: View {
    private let message: String
    private let tint: Color

    public init(_ message: String, tint: Color = Slate.deny) {
        self.message = message
        self.tint = tint
    }

    public var body: some View {
        Text(message)
            .font(.callout)
            .padding(10)
            .background(tint.opacity(0.9), in: RoundedRectangle(cornerRadius: Slate.cornerRadius))
            .padding(.top, 8)
            .transition(.opacity)
    }
}
