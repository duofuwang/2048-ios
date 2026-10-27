import Foundation

public enum HapticIntensity: String, CaseIterable, Codable {
    case light
    case medium
    case strong
}

public enum HapticTrigger: String, CaseIterable, Codable {
    case perMove
    case perMerge
    case onNewValue
}

public struct HapticEvent: Equatable {
    public let intensity: HapticIntensity
    public let delay: TimeInterval

    public init(intensity: HapticIntensity, delay: TimeInterval) {
        self.intensity = intensity
        self.delay = delay
    }
}

public final class HapticPolicy {
    static let spacing: TimeInterval = 0.06
    static let window: TimeInterval = 0.2

    public var isEnabled: Bool
    public var intensity: HapticIntensity
    public var trigger: HapticTrigger
    public private(set) var seenValues: Set<Int>

    private struct Candidate {
        let value: Int
        let isNew: Bool
    }

    private var candidates: [Candidate] = []

    public init(
        isEnabled: Bool = true,
        intensity: HapticIntensity = .light,
        trigger: HapticTrigger = .perMove,
        seenValues: Set<Int> = []
    ) {
        self.isEnabled = isEnabled
        self.intensity = intensity
        self.trigger = trigger
        self.seenValues = seenValues
    }

    public func beginMove() {
        candidates.removeAll()
    }

    public func mergeDidOccur(value: Int) {
        let isNew = !seenValues.contains(value)
        candidates.append(Candidate(value: value, isNew: isNew))
        seenValues.insert(value)
    }

    public func endMove() -> [HapticEvent] {
        let result = makeEvents()
        candidates.removeAll()
        return result
    }

    public func resetGame() {
        seenValues.removeAll()
        candidates.removeAll()
    }

    public func restoreSeenValues(_ values: Set<Int>) {
        seenValues = values
        candidates.removeAll()
    }

    private func makeEvents() -> [HapticEvent] {
        guard isEnabled, !candidates.isEmpty else {
            return []
        }

        let qualifying: [Candidate]
        switch trigger {
        case .perMove:
            qualifying = [candidates[0]]
        case .perMerge:
            qualifying = candidates
        case .onNewValue:
            qualifying = candidates.filter(\.isNew)
        }

        var events: [HapticEvent] = []
        var delay: TimeInterval = 0
        for _ in qualifying {
            if delay >= Self.window {
                break
            }
            events.append(HapticEvent(intensity: intensity, delay: delay))
            delay += Self.spacing
        }
        return events
    }
}
