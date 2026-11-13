import SwiftUI

// The "oo" in Loop: one long oval. It's built from evenly spaced points
// so the opening animation draws it at a steady speed all the way around.
struct LoopShape: Shape {
    func path(in rect: CGRect) -> Path {
        let radius = rect.height / 2
        let straight = max(rect.width - 2 * radius, 0)
        let total = 2 * straight + 2 * .pi * radius

        // Spot that's a given distance around the oval, starting top left and going clockwise
        func point(at distance: Double) -> CGPoint {
            var d = distance
            if d < straight {
                return CGPoint(x: rect.minX + radius + d, y: rect.minY)
            }
            d -= straight
            if d < .pi * radius {
                let angle = -Double.pi / 2 + d / radius
                return CGPoint(x: rect.maxX - radius + radius * cos(angle), y: rect.midY + radius * sin(angle))
            }
            d -= .pi * radius
            if d < straight {
                return CGPoint(x: rect.maxX - radius - d, y: rect.maxY)
            }
            d -= straight
            let angle = Double.pi / 2 + d / radius
            return CGPoint(x: rect.minX + radius + radius * cos(angle), y: rect.midY + radius * sin(angle))
        }

        var path = Path()
        let steps = 160
        path.move(to: point(at: 0))
        for step in 1...steps {
            path.addLine(to: point(at: total * Double(step) / Double(steps)))
        }
        path.closeSubpath()
        return path
    }
}

// "Lunch" over "Loop", with the oo drawn as one long orange loop.
// progress is how much of the loop is drawn, from 0 to 1, for the opening animation.
struct LogoView: View {
    var size: CGFloat = 56
    var progress: CGFloat = 1

    var body: some View {
        VStack(alignment: .leading, spacing: -size * 0.12) {
            Text("Lunch")
            HStack(alignment: .lastTextBaseline, spacing: size * 0.04) {
                Text("L")
                LoopShape()
                    .trim(from: 0, to: progress)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: size * 0.12, lineCap: .round, lineJoin: .round))
                    .frame(width: size * 1.05, height: size * 0.44)
                    // Lift it so the loop sits on the line like lowercase letters
                    .padding(.bottom, size * 0.06)
                Text("p")
            }
        }
        .font(.system(size: size, weight: .bold, design: .rounded))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Lunch Loop")
    }
}

// Shown when the app opens, and after Reset App. The loop draws itself.
// Before onboarding it waits for a swipe up (or a tap) with a hint at the bottom.
// Every other time it slides away on its own once the loop is drawn.
struct SplashView: View {
    let waitsForSwipe: Bool
    // Called once the loop is drawn, so the app can get built underneath
    let onDrawn: () -> Void
    let onFinish: () -> Void

    @State private var progress: CGFloat = 0
    @State private var showingHint = false
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            LogoView(size: 64, progress: progress)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if showingHint {
                VStack(spacing: 6) {
                    Image(systemName: "chevron.up")
                        .font(.title2.weight(.semibold))
                        .symbolEffect(.bounce.up, options: .repeating)
                    Text("Swipe up to continue")
                        .font(.subheadline.weight(.medium))
                }
                .foregroundStyle(.tint)
                .padding(.bottom, 48)
                .transition(.opacity)
            }
        }
        .background(Color(.systemBackground))
        .contentShape(Rectangle())
        .offset(y: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    // Follow the finger upward only
                    dragOffset = min(0, value.translation.height)
                }
                .onEnded { value in
                    if value.translation.height < -80 {
                        slideAway()
                    } else {
                        withAnimation(.spring) { dragOffset = 0 }
                    }
                }
        )
        .onTapGesture {
            if showingHint { slideAway() }
        }
        .task {
            // Starts slow, speeds through the middle, then eases into the end
            withAnimation(.timingCurve(0.7, 0, 0.3, 1, duration: 0.9)) {
                progress = 1
            }
            try? await Task.sleep(for: .seconds(1.0))
            onDrawn()
            if waitsForSwipe {
                withAnimation { showingHint = true }
            } else {
                // A short beat, then slide up on its own
                try? await Task.sleep(for: .seconds(0.25))
                slideAway()
            }
        }
    }

    // Moves the whole screen up and out of sight, then tells the app it's gone
    private func slideAway() {
        withAnimation(.easeInOut(duration: 0.45)) {
            dragOffset = -1200
        } completion: {
            onFinish()
        }
    }
}

#Preview {
    SplashView(waitsForSwipe: true, onDrawn: {}, onFinish: {})
}
