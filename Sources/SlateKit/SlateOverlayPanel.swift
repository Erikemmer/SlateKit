import SwiftUI

/// A floating plate that lies over the content: a measurement, a readout, a
/// hint. Opaque enough to be read over anything, rounded and shadowed so it
/// reads as lying on top rather than being part of the picture.
///
/// The transparency is a decision that was made twice. At 55 % black the grey
/// secondary text disappeared over a bright sky; 88 % of the panel colour keeps
/// every word legible and still lets the content show through at the edges.
///
/// It never takes clicks – whatever is underneath stays reachable.
public struct SlateOverlayPanel<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(10)
            .background(
                Slate.panelBackground.opacity(0.88),
                in: RoundedRectangle(cornerRadius: Slate.floatingCornerRadius)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Slate.floatingCornerRadius)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.45), radius: 8, y: 2)
            .padding(12)
            .allowsHitTesting(false)
    }
}

/// The dark well a graph or a small preview is drawn into, inside an overlay
/// panel. Darker than the panel so the drawing has something to stand on.
public struct SlateGraphWell<Content: View>: View {
    private let size: CGSize
    private let content: Content

    public init(size: CGSize, @ViewBuilder content: () -> Content) {
        self.size = size
        self.content = content()
    }

    public var body: some View {
        content
            .frame(width: size.width, height: size.height)
            .background(Color.black.opacity(0.35), in: RoundedRectangle(cornerRadius: Slate.cornerRadius))
    }
}
