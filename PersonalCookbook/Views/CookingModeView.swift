import SwiftUI

/// Focused, glanceable, one-step-at-a-time cooking workflow.
struct CookingModeView: View {
    let recipe: Recipe
    @Environment(\.dismiss) private var dismiss
    @State private var index = 0

    private var total: Int { recipe.steps.count }
    private var isComplete: Bool { index >= total }

    var body: some View {
        ZStack {
            CookbookBackground()

            VStack(spacing: 0) {
                topBar
                segmentedProgress
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                if isComplete {
                    CompletionCard(recipe: recipe) { dismiss() }
                        .padding(20)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                } else {
                    TabView(selection: $index) {
                        ForEach(Array(recipe.steps.enumerated()), id: \.offset) { i, step in
                            StepCard(step: step, number: i + 1)
                                .padding(.horizontal, 20)
                                .padding(.top, 16)
                                .padding(.bottom, 6)
                                .tag(i)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    controls
                }
            }
        }
        .preferredColorScheme(.dark)
        .animation(.snappy(duration: 0.3), value: index)
    }

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 40, height: 40)
                    .glassControl(Circle())
            }
            .buttonStyle(.plain)
            Spacer()
            Text(isComplete ? "Done" : "Step \(index + 1) of \(total)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }

    // One segment per step (Stories-style). Completed and current steps are lit.
    private var segmentedProgress: some View {
        HStack(spacing: 5) {
            ForEach(0..<total, id: \.self) { i in
                Capsule()
                    .fill(i <= index ? AnyShapeStyle(Theme.accent) : AnyShapeStyle(.white.opacity(0.14)))
                    .frame(height: 4)
            }
        }
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.snappy) { if index > 0 { index -= 1 } }
            } label: {
                Label("Previous", systemImage: "chevron.left")
                    .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 6)
            }
            .buttonStyle(.glass)
            .controlSize(.large)
            .disabled(index == 0)
            .opacity(index == 0 ? 0.4 : 1)

            Button {
                withAnimation(.snappy) { index += 1 }
            } label: {
                Label(index == total - 1 ? "Finish" : "Next",
                      systemImage: index == total - 1 ? "checkmark" : "chevron.right")
                    .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 6)
            }
            .buttonStyle(.glassProminent)
            .tint(Theme.accent)
            .controlSize(.large)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 18)
    }
}

// MARK: - Step card

private struct StepCard: View {
    let step: CookingStep
    let number: Int

    var body: some View {
        // The card hugs its content and centres vertically in the available
        // space; long steps scroll instead of stretching into dead space.
        GeometryReader { geo in
            ScrollView {
                card
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: geo.size.height, alignment: .center)
            }
            .scrollIndicators(.hidden)
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("STEP \(number)")
                .font(.caption.weight(.bold)).tracking(1.6)
                .foregroundStyle(Theme.accent)

            Text(step.title)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .fixedSize(horizontal: false, vertical: true)

            Text(step.instruction)
                .font(.title3)
                .foregroundStyle(.primary.opacity(0.88))
                .fixedSize(horizontal: false, vertical: true)

            if let mins = step.durationMinutes, mins > 0 {
                StepTimer(minutes: mins)
            }

            if !step.ingredients.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Label("For this step", systemImage: "list.bullet")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    FlowLayout(spacing: 8) {
                        ForEach(step.ingredients, id: \.self) { ing in
                            Pill(text: ing, systemImage: "circle.fill", tint: Theme.green)
                        }
                    }
                }
            }

            if !step.tips.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(step.tips, id: \.self) { tip in
                        HStack(alignment: .top, spacing: 9) {
                            Image(systemName: "lightbulb.fill").foregroundStyle(Theme.amber)
                            Text(tip).font(.callout).foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Theme.amber.opacity(0.10), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Theme.amber.opacity(0.22), lineWidth: 0.8))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .glassCard(padding: 0)
    }
}

// MARK: - Inline step timer

private struct StepTimer: View {
    let minutes: Int
    @State private var remaining: Int
    @State private var running = false
    @State private var didStart = false
    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(minutes: Int) {
        self.minutes = minutes
        _remaining = State(initialValue: minutes * 60)
    }

    private var finished: Bool { didStart && remaining == 0 }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: finished ? "checkmark.circle.fill" : "timer")
                .font(.title2)
                .foregroundStyle(Theme.accent)
            Text(timeString)
                .font(.system(size: 32, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(finished ? Theme.accent : .primary)
                .contentTransition(.numericText())
            Spacer()
            Button(action: toggle) {
                Image(systemName: running ? "pause.fill" : "play.fill")
                    .font(.headline).foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(Circle().fill(Theme.accent))
            }
            .buttonStyle(.plain)
            .disabled(finished)

            if didStart {
                Button(action: reset) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.headline).foregroundStyle(.secondary)
                        .frame(width: 46, height: 46)
                        .glassControl(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .glassCard(cornerRadius: 18, padding: 0)
        .onReceive(tick) { _ in
            guard running, remaining > 0 else { return }
            withAnimation { remaining -= 1 }
            if remaining == 0 { running = false }
        }
    }

    private func toggle() {
        if running { running = false }
        else { didStart = true; running = true }
    }
    private func reset() {
        running = false; didStart = false; remaining = minutes * 60
    }
    private var timeString: String {
        String(format: "%d:%02d", remaining / 60, remaining % 60)
    }
}

// MARK: - Completion

private struct CompletionCard: View {
    let recipe: Recipe
    var onDone: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle().fill(Theme.accent.opacity(0.15)).frame(width: 124, height: 124)
                Image(systemName: "checkmark")
                    .font(.system(size: 54, weight: .bold))
                    .foregroundStyle(Theme.accent)
            }
            Text("All done!")
                .font(.system(size: 36, weight: .bold, design: .rounded))
            Text("You finished \(recipe.name). Enjoy your meal.")
                .font(.title3).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if !recipe.tasteFixes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("If it tastes off", systemImage: "slider.horizontal.3")
                        .font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
                    ForEach(recipe.tasteFixes.prefix(2)) { fix in
                        Text("\(fix.problem) → \(fix.fix)")
                            .font(.callout).foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassCard()
            }

            Spacer()
            Button(action: onDone) {
                Text("Done").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 6)
            }
            .buttonStyle(.glassProminent)
            .tint(Theme.accent)
            .controlSize(.large)
        }
    }
}
