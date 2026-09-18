import SwiftUI

/// Forty little rectangles falling once. Cheap, no dependencies, enough to feel like a win.
struct ConfettiView: View {
    private struct Piece: Identifiable {
        let id = UUID()
        let x: CGFloat
        let delay: Double
        let size: CGFloat
        let rotation: Double
        let colorIndex: Int
    }

    private let pieces: [Piece] = (0..<40).map { _ in
        Piece(x: .random(in: 0.02...0.98), delay: .random(in: 0...0.5), size: .random(in: 6...12),
              rotation: .random(in: 0...360), colorIndex: Int.random(in: 0..<4))
    }
    private let colors: [Color] = [Theme.accent, Theme.warning, Theme.success, Theme.accent.opacity(0.6)]

    @State private var animate = false

    var body: some View {
        GeometryReader { geo in
            ForEach(pieces) { piece in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(colors[piece.colorIndex])
                    .frame(width: piece.size, height: piece.size * 0.6)
                    .rotationEffect(.degrees(animate ? piece.rotation + 540 : piece.rotation))
                    .position(x: piece.x * geo.size.width, y: animate ? geo.size.height + 30 : -30)
                    .opacity(animate ? 0.1 : 1)
                    .animation(.easeIn(duration: 1.8).delay(piece.delay), value: animate)
            }
        }
        .allowsHitTesting(false)
        .onAppear { animate = true }
    }
}
