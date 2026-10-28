import UIKit
import Game2048Core

final class BoardView: UIView {
    private let engine: GameEngine
    private var theme: Theme
    private var displayLink: CADisplayLink?
    private var lastTick: CFTimeInterval = 0
    private var tileImages: [Int: UIImage] = [:]
    private var boardBackground: UIImage?
    private var cellSize: CGFloat = 0
    private let gridWidth: CGFloat = 2
    private var boardOrigin = CGPoint.zero
    private var lastLayoutSize: CGSize = .zero
    private var celebrationViews: [ConfettiView] = []

    init(engine: GameEngine, theme: Theme) {
        self.engine = engine
        self.theme = theme
        super.init(frame: .zero)
        backgroundColor = theme.backgroundColor
        isOpaque = true
        isAccessibilityElement = true
        accessibilityIdentifier = "board"
        accessibilityLabel = "board"
    }

    override var accessibilityValue: String? {
        get {
            (0..<engine.grid.sizeY).map { y in
                (0..<engine.grid.sizeX)
                    .map { x in String(engine.grid.field[x][y]?.value ?? 0) }
                    .joined(separator: ",")
            }.joined(separator: ";")
        }
        set {}
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        displayLink?.invalidate()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.size != lastLayoutSize else { return }
        lastLayoutSize = bounds.size
        recomputeLayout()
    }

    private func recomputeLayout() {
        guard bounds.width > 0, bounds.height > 0 else { return }
        let cells = CGFloat(GameEngine.sizeX)
        cellSize = min(bounds.width / cells - gridWidth * 2, bounds.height / cells - gridWidth * 2)
        let total = cellSize * cells + gridWidth * (cells + 1)
        boardOrigin = CGPoint(
            x: (bounds.width - total) / 2 + gridWidth,
            y: (bounds.height - total) / 2 + gridWidth
        )
        prepareImages()
        setNeedsDisplay()
    }

    private func prepareImages() {
        tileImages.removeAll()
        for power in 1...12 {
            _ = image(for: 1 << power)
        }
        boardBackground = renderBackground()
    }

    private func renderBackground() -> UIImage? {
        guard bounds.width > 0, bounds.height > 0, cellSize > 0 else { return nil }
        return UIGraphicsImageRenderer(bounds: bounds).image { context in
            theme.backgroundColor.setFill()
            context.fill(bounds)
            for x in 0..<GameEngine.sizeX {
                for y in 0..<GameEngine.sizeY {
                    theme.cellColor(for: 0).setFill()
                    context.fill(cellRect(x, y))
                }
            }
        }
    }

    func startAnimating() {
        guard displayLink == nil else {
            setNeedsDisplay()
            return
        }
        lastTick = CACurrentMediaTime()
        let link = CADisplayLink(target: self, selector: #selector(step))
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 60, preferred: 60)
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    func applyTheme(_ theme: Theme) {
        self.theme = theme
        backgroundColor = theme.backgroundColor
        prepareImages()
        setNeedsDisplay()
    }

    func celebrate(value: Int) {
        guard !UIAccessibility.isReduceMotionEnabled, cellSize > 0 else { return }
        guard let center = cellCenter(for: value), let host = superview else { return }

        let confetti = ConfettiView(frame: host.bounds)
        host.addSubview(confetti)
        confetti.start(at: convert(center, to: host))
        celebrationViews.append(confetti)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self, weak confetti] in
            confetti?.stop()
            confetti?.removeFromSuperview()
            self?.celebrationViews.removeAll { $0 === confetti }
        }
    }

    func clearCelebration() {
        celebrationViews.forEach { $0.stop(); $0.removeFromSuperview() }
        celebrationViews.removeAll()
    }

    private func cellCenter(for value: Int) -> CGPoint? {
        var fallback: CGPoint?
        for x in 0..<GameEngine.sizeX {
            for y in 0..<GameEngine.sizeY {
                guard engine.grid.field[x][y]?.value == value else { continue }
                let rect = cellRect(x, y)
                let center = CGPoint(x: rect.midX, y: rect.midY)
                if fallback == nil {
                    fallback = center
                }
                if engine.animationGrid.animations(at: x, y).contains(where: { $0.type == .merge }) {
                    return center
                }
            }
        }
        return fallback
    }

    @objc private func step(_ link: CADisplayLink) {
        let now = CACurrentMediaTime()
        engine.animationGrid.tickAll(now - lastTick)
        lastTick = now
        setNeedsDisplay()
        if !engine.animationGrid.isAnimationActive {
            link.invalidate()
            displayLink = nil
        }
    }

    private func cellRect(_ x: Int, _ y: Int) -> CGRect {
        CGRect(
            x: boardOrigin.x + CGFloat(x) * (cellSize + gridWidth),
            y: boardOrigin.y + CGFloat(y) * (cellSize + gridWidth),
            width: cellSize,
            height: cellSize
        )
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext(), cellSize > 0 else { return }
        if let boardBackground {
            boardBackground.draw(in: bounds)
        } else {
            theme.backgroundColor.setFill()
            context.fill(bounds)
        }

        for x in 0..<GameEngine.sizeX {
            for y in 0..<GameEngine.sizeY {
                let cell = cellRect(x, y)
                guard let tile = engine.grid.field[x][y] else { continue }

                var animated = false
                let animations = engine.animationGrid.animations(at: x, y)
                for animation in animations.reversed() {
                    if animation.type == .spawn {
                        animated = true
                    }
                    guard animation.isActive else { continue }
                    let progress = animation.percentageDone

                    switch animation.type {
                    case .spawn:
                        let scale = CGFloat(progress)
                        let inset = cellSize / 2 * (1 - scale)
                        drawTile(value: tile.value, in: cell.insetBy(dx: inset, dy: inset))
                    case .merge:
                        let scale = CGFloat(1 + 0.375 * progress - 0.25 * progress * progress)
                        let inset = cellSize / 2 * (1 - scale)
                        drawTile(value: tile.value, in: cell.insetBy(dx: inset, dy: inset))
                    case .move:
                        let value = animations.count >= 2 ? tile.value / 2 : tile.value
                        let previousX = animation.extras?[0] ?? x
                        let previousY = animation.extras?[1] ?? y
                        let offsetX = CGFloat(tile.x - previousX) * (cellSize + gridWidth) * CGFloat(progress - 1)
                        let offsetY = CGFloat(tile.y - previousY) * (cellSize + gridWidth) * CGFloat(progress - 1)
                        drawTile(value: value, in: cell.offsetBy(dx: offsetX, dy: offsetY))
                    }
                    animated = true
                }

                if !animated {
                    drawTile(value: tile.value, in: cell)
                }
            }
        }
    }

    private func drawTile(value: Int, in rect: CGRect) {
        image(for: value).draw(in: rect)
    }

    private func image(for value: Int) -> UIImage {
        if let cached = tileImages[value] {
            return cached
        }
        let size = CGSize(width: cellSize, height: cellSize)
        let image = UIGraphicsImageRenderer(size: size).image { _ in
            theme.cellColor(for: value).setFill()
            UIRectFill(CGRect(origin: .zero, size: size))

            let text = String(value)
            let measureText = value < 2048 ? "0000" : text
            let cellTextSize = cellSize * 0.9
            let measureFont = font(size: cellTextSize)
            let measuredWidth = (measureText as NSString).size(withAttributes: [.font: measureFont]).width
            let textSize = cellTextSize * cellTextSize / max(cellTextSize, measuredWidth)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font(size: textSize),
                .foregroundColor: theme.tileTextColor(for: value),
            ]
            let drawn = (text as NSString).size(withAttributes: attributes)
            let origin = CGPoint(x: (cellSize - drawn.width) / 2, y: (cellSize - drawn.height) / 2)
            (text as NSString).draw(at: origin, withAttributes: attributes)
        }
        tileImages[value] = image
        return image
    }

    private func font(size: CGFloat) -> UIFont {
        UIFont(name: "HelveticaNeue-UltraLight", size: size)
            ?? UIFont.systemFont(ofSize: size, weight: .ultraLight)
    }
}
