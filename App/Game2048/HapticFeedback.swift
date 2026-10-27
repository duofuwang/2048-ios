import UIKit
import Game2048Core

final class HapticFeedback {
    private var generation = 0

    func perform(_ events: [HapticEvent]) {
        generation += 1
        let token = generation
        for event in events {
            DispatchQueue.main.asyncAfter(deadline: .now() + event.delay) { [weak self] in
                guard let self, self.generation == token else { return }
                let generator = UIImpactFeedbackGenerator(style: Self.style(for: event.intensity))
                generator.prepare()
                generator.impactOccurred()
            }
        }
    }

    func cancel() {
        generation += 1
    }

    private static func style(for intensity: HapticIntensity) -> UIImpactFeedbackGenerator.FeedbackStyle {
        switch intensity {
        case .light: return .light
        case .medium: return .medium
        case .strong: return .heavy
        }
    }
}
