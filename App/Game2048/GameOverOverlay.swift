import UIKit

final class GameOverOverlay: UIView {
    var onRestart: (() -> Void)?
    var onShare: (() -> Void)?

    init(score: Int, highScore: Int) {
        super.init(frame: .zero)
        backgroundColor = UIColor.black.withAlphaComponent(0.35)

        let card = UIView()
        card.backgroundColor = UIColor(hex: 0xF0F0F0)
        card.translatesAutoresizingMaskIntoConstraints = false
        addSubview(card)

        let title = UILabel()
        title.text = NSLocalizedString("gameover", comment: "")
        title.textColor = UIColor(hex: 0x4D4D4D)
        title.font = UIFont(name: "HelveticaNeue-UltraLight", size: 75)
            ?? UIFont.systemFont(ofSize: 75, weight: .ultraLight)
        title.textAlignment = .center
        title.adjustsFontSizeToFitWidth = true
        title.minimumScaleFactor = 0.4

        let highScoreLabel = UILabel()
        highScoreLabel.text = "High Score: \(highScore)"
        highScoreLabel.textColor = UIColor(hex: 0x4D4D4D)
        highScoreLabel.font = UIFont(name: "HelveticaNeue-UltraLight", size: 30)
            ?? UIFont.systemFont(ofSize: 30, weight: .ultraLight)
        highScoreLabel.textAlignment = .center

        let scoreLabel = UILabel()
        scoreLabel.text = "Score: \(score)"
        scoreLabel.textColor = UIColor(hex: 0x4D4D4D)
        scoreLabel.font = UIFont(name: "HelveticaNeue-UltraLight", size: 30)
            ?? UIFont.systemFont(ofSize: 30, weight: .ultraLight)
        scoreLabel.textAlignment = .center

        let restart = button(defaultName: "re_default", pressName: "re_press")
        restart.addTarget(self, action: #selector(restartTapped), for: .touchUpInside)
        let share = button(defaultName: "share_default", pressName: "share_press")
        share.addTarget(self, action: #selector(shareTapped), for: .touchUpInside)

        let row = UIStackView(arrangedSubviews: [restart, share])
        row.axis = .horizontal
        row.distribution = .fillEqually
        row.alignment = .center
        row.spacing = 20

        let stack = UIStackView(arrangedSubviews: [title, highScoreLabel, scoreLabel, row])
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)

        NSLayoutConstraint.activate([
            card.centerXAnchor.constraint(equalTo: centerXAnchor),
            card.centerYAnchor.constraint(equalTo: centerYAnchor),
            card.widthAnchor.constraint(equalToConstant: 300),
            card.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 20),
            card.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -20),

            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),

            restart.heightAnchor.constraint(equalToConstant: 70),
            share.heightAnchor.constraint(equalToConstant: 70),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func restartTapped() {
        onRestart?()
    }

    @objc private func shareTapped() {
        onShare?()
    }

    private func button(defaultName: String, pressName: String) -> UIButton {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: defaultName), for: .normal)
        button.setImage(UIImage(named: pressName), for: .highlighted)
        button.imageView?.contentMode = .scaleAspectFit
        return button
    }
}
