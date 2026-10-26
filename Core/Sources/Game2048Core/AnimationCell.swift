import Foundation

public enum AnimationType: Int {
    case spawn = -1
    case move = 0
    case merge = 1
}

public final class AnimationCell {
    public let x: Int
    public let y: Int
    public let type: AnimationType
    public let duration: TimeInterval
    public let delay: TimeInterval
    public let extras: [Int]?
    private(set) var elapsed: TimeInterval = 0

    init(x: Int, y: Int, type: AnimationType, duration: TimeInterval, delay: TimeInterval, extras: [Int]?) {
        self.x = x
        self.y = y
        self.type = type
        self.duration = duration
        self.delay = delay
        self.extras = extras
    }

    func tick(_ delta: TimeInterval) {
        elapsed += delta
    }

    var isDone: Bool {
        duration + delay < elapsed
    }

    public var isActive: Bool {
        elapsed >= delay
    }

    public var percentageDone: Double {
        max(0, (elapsed - delay) / duration)
    }
}
