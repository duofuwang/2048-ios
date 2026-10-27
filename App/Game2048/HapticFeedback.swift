import UIKit
import Game2048Core

final class HapticFeedback {
    private var generation = 0
    private var generator: UIImpactFeedbackGenerator?

    func prepare(intensity: HapticIntensity) {
        generation += 1
        let generator = UIImpactFeedbackGenerator(style: Self.style(for: intensity))
        generator.prepare()
        self.generator = generator
    }

    func perform(_ events: [HapticEvent]) {
        guard let first = events.first else { return }
        if generator == nil {
            prepare(intensity: first.intensity)
        }
        generation += 1
        let token = generation
        let generator = self.generator ?? UIImpactFeedbackGenerator(style: Self.style(for: first.intensity))
        for event in events {
            DispatchQueue.main.asyncAfter(deadline: .now() + event.delay) { [weak self] in
                guard let self, self.generation == token else { return }
                generator.impactOccurred()
            }
        }
    }

    func cancel() {
        generation += 1
        generator = nil
    }

    private static func style(for intensity: HapticIntensity) -> UIImpactFeedbackGenerator.FeedbackStyle {
        switch intensity {
        case .light: return .light
        case .medium: return .medium
        case .strong: return .heavy
        }
    }
}
