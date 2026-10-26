import UIKit
import Game2048Core

final class SwipeInput {
    var isLocked = false
    var onMove: ((Direction) -> Void)?

    private let swipeThreshold: CGFloat
    private let moveThreshold: CGFloat
    private let resetStarting: CGFloat = 10

    private var x: CGFloat = 0
    private var y: CGFloat = 0
    private var lastdx: CGFloat = 0
    private var lastdy: CGFloat = 0
    private var previousX: CGFloat = 0
    private var previousY: CGFloat = 0
    private var startingX: CGFloat = 0
    private var startingY: CGFloat = 0
    private var previousDirection = 1
    private var veryLastDirection = 1

    // Thresholds come from the Android source in pixels on a 1080-wide screen.
    init(sensitivity: Double, referenceWidth: CGFloat) {
        let pixelScale = referenceWidth / 1080
        let sens = CGFloat(10 + sensitivity * 50)
        swipeThreshold = (70 - sens) * pixelScale
        moveThreshold = 300 * pixelScale
    }

    func began(at point: CGPoint) {
        x = point.x
        y = point.y
        startingX = x
        startingY = y
        previousX = x
        previousY = y
        lastdx = 0
        lastdy = 0
    }

    func changed(to point: CGPoint) {
        guard !isLocked else { return }
        x = point.x
        y = point.y

        let dx = x - previousX
        if abs(lastdx + dx) < abs(lastdx) + abs(dx), abs(dx) > resetStarting, abs(x - startingX) > 0 {
            startingX = x
            startingY = y
            lastdx = dx
            previousDirection = veryLastDirection
        }
        if lastdx == 0 { lastdx = dx }

        let dy = y - previousY
        if abs(lastdy + dy) < abs(lastdy) + abs(dy), abs(dy) > resetStarting, abs(y - startingY) > 0 {
            startingX = x
            startingY = y
            lastdy = dy
            previousDirection = veryLastDirection
        }
        if lastdy == 0 { lastdy = dy }

        if pathMoved() > 0 {
            var moved = false
            if ((dy >= swipeThreshold && abs(dy) >= abs(dx)) || y - startingY >= moveThreshold),
               previousDirection % 2 != 0 {
                moved = true
                previousDirection *= 2
                veryLastDirection = 2
                onMove?(.down)
            } else if ((dy <= -swipeThreshold && abs(dy) >= abs(dx)) || y - startingY <= -moveThreshold),
                      previousDirection % 3 != 0 {
                moved = true
                previousDirection *= 3
                veryLastDirection = 3
                onMove?(.up)
            }

            if ((dx >= swipeThreshold && abs(dx) >= abs(dy)) || x - startingX >= moveThreshold),
               previousDirection % 5 != 0 {
                moved = true
                previousDirection *= 5
                veryLastDirection = 5
                onMove?(.right)
            } else if ((dx <= -swipeThreshold && abs(dx) >= abs(dy)) || x - startingX <= -moveThreshold),
                      previousDirection % 7 != 0 {
                moved = true
                previousDirection *= 7
                veryLastDirection = 7
                onMove?(.left)
            }

            if moved {
                startingX = x
                startingY = y
            }
        }

        previousX = x
        previousY = y
    }

    func ended() {
        previousDirection = 1
        veryLastDirection = 1
    }

    private func pathMoved() -> CGFloat {
        (x - startingX) * (x - startingX) + (y - startingY) * (y - startingY)
    }
}
