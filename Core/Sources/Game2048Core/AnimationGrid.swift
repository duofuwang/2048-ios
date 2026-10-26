import Foundation

public final class AnimationGrid {
    public let sizeX: Int
    public let sizeY: Int
    private var field: [[[AnimationCell]]]
    private(set) var activeAnimations = 0
    private var oneMoreFrame = false

    public init(sizeX: Int = 4, sizeY: Int = 4) {
        self.sizeX = sizeX
        self.sizeY = sizeY
        field = Array(repeating: Array(repeating: [AnimationCell](), count: sizeY), count: sizeX)
    }

    func startAnimation(
        x: Int,
        y: Int,
        type: AnimationType,
        duration: TimeInterval,
        delay: TimeInterval,
        extras: [Int]? = nil
    ) {
        field[x][y].append(AnimationCell(x: x, y: y, type: type, duration: duration, delay: delay, extras: extras))
        activeAnimations += 1
    }

    public func tickAll(_ delta: TimeInterval) {
        var finished: [AnimationCell] = []
        for x in 0..<sizeX {
            for y in 0..<sizeY {
                for animation in field[x][y] {
                    animation.tick(delta)
                    if animation.isDone {
                        finished.append(animation)
                        activeAnimations -= 1
                    }
                }
            }
        }
        for animation in finished {
            field[animation.x][animation.y].removeAll { $0 === animation }
        }
    }

    public var isAnimationActive: Bool {
        if activeAnimations != 0 {
            oneMoreFrame = true
            return true
        }
        if oneMoreFrame {
            oneMoreFrame = false
            return true
        }
        return false
    }

    public func animations(at x: Int, _ y: Int) -> [AnimationCell] {
        field[x][y]
    }

    public func cancelAnimations() {
        for x in 0..<sizeX {
            for y in 0..<sizeY {
                field[x][y].removeAll()
            }
        }
        activeAnimations = 0
    }
}
