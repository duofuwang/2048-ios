import UIKit

final class ConfettiView: UIView {
    private struct Particle {
        var position: CGPoint
        var velocity: CGVector
        var angle: CGFloat
        var angularVelocity: CGFloat
        var flip: CGFloat
        var flipSpeed: CGFloat
        var size: CGSize
        var color: UIColor
        var age: TimeInterval = 0
        let lifetime: TimeInterval
    }

    private var particles: [Particle] = []
    private var displayLink: CADisplayLink?
    private var lastTick: CFTimeInterval = 0

    private static let colors: [UIColor] = [
        UIColor(hex: 0xEDC22E),
        UIColor(hex: 0xF67C5F),
        UIColor(hex: 0x8FBF3F),
        .white,
        UIColor(hex: 0xF2B179),
    ]

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
        isUserInteractionEnabled = false
        contentMode = .redraw
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        displayLink?.invalidate()
    }

    func start(at point: CGPoint) {
        particles = (0..<55).map { _ in
            let angle = CGFloat.random(in: 0..<(2 * .pi))
            let speed = CGFloat.random(in: 120...300)
            return Particle(
                position: point,
                velocity: CGVector(
                    dx: cos(angle) * speed,
                    dy: sin(angle) * speed - CGFloat.random(in: 60...180)
                ),
                angle: CGFloat.random(in: 0..<(2 * .pi)),
                angularVelocity: CGFloat.random(in: -10...10),
                flip: CGFloat.random(in: 0..<(2 * .pi)),
                flipSpeed: CGFloat.random(in: -12...12),
                size: CGSize(
                    width: CGFloat.random(in: 7...12),
                    height: CGFloat.random(in: 4...7)
                ),
                color: Self.colors.randomElement() ?? .white,
                lifetime: TimeInterval.random(in: 1.2...1.6)
            )
        }
        let link = CADisplayLink(target: self, selector: #selector(step))
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 120, preferred: 120)
        link.add(to: .main, forMode: .common)
        lastTick = CACurrentMediaTime()
        displayLink = link
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
        particles.removeAll()
    }

    @objc private func step(_ link: CADisplayLink) {
        let now = CACurrentMediaTime()
        let dt = min(now - lastTick, 1.0 / 30)
        lastTick = now
        let drag = pow(0.99, dt * 60)
        for index in particles.indices {
            particles[index].age += dt
            particles[index].velocity.dx *= drag
            particles[index].velocity.dy *= drag
            particles[index].velocity.dy += 520 * dt
            particles[index].position.x += particles[index].velocity.dx * dt
            particles[index].position.y += particles[index].velocity.dy * dt
            particles[index].angle += particles[index].angularVelocity * dt
            particles[index].flip += particles[index].flipSpeed * dt
        }
        particles.removeAll { $0.age >= $0.lifetime }
        setNeedsDisplay()
        if particles.isEmpty {
            stop()
        }
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        for particle in particles {
            let remaining = particle.lifetime - particle.age
            let alpha = min(1, remaining / 0.25)
            let width = max(1, particle.size.width * abs(cos(particle.flip)))
            let height = particle.size.height
            context.saveGState()
            context.translateBy(x: particle.position.x, y: particle.position.y)
            context.rotate(by: particle.angle)
            context.setAlpha(alpha)
            particle.color.setFill()
            context.fill(CGRect(x: -width / 2, y: -height / 2, width: width, height: height))
            context.restoreGState()
        }
    }
}
