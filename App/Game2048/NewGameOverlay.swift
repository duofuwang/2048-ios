import UIKit

final class NewGameOverlay: UIView {
    var onCancel: (() -> Void)?
    var onConfirm: (() -> Void)?

    init() {
        super.init(frame: .zero)
        backgroundColor = UIColor.black.withAlphaComponent(0.35)

        let card = UIView()
        card.backgroundColor = UIColor(hex: 0xF0F0F0)
        card.translatesAutoresizingMaskIntoConstraints = false
        addSubview(card)

        let title = UILabel()
        title.text = NSLocalizedString("start_new", comment: "")
        title.numberOfLines = 2
        title.textAlignment = .center
        title.textColor = UIColor(hex: 0x4D4D4D)
        title.font = UIFont(name: "HelveticaNeue-UltraLight", size: 70)
            ?? UIFont.systemFont(ofSize: 70, weight: .ultraLight)
        title.adjustsFontSizeToFitWidth = true
        title.minimumScaleFactor = 0.5

        let noButton = button(defaultName: "no_default", pressName: "no_press")
        noButton.accessibilityIdentifier = "cancelNewGame"
        noButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        let yesButton = button(defaultName: "yes_default", pressName: "yes_press")
        yesButton.accessibilityIdentifier = "confirmNewGame"
        yesButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)

        let row = UIStackView(arrangedSubviews: [noButton, yesButton])
        row.axis = .horizontal
        row.distribution = .fillEqually
        row.alignment = .center
        row.spacing = 20

        let warnView = UIImageView(image: UIImage(named: "warn"))
        warnView.contentMode = .scaleAspectFit

        let message = UILabel()
        message.text = NSLocalizedString("discard", comment: "")
        message.numberOfLines = 2
        message.textAlignment = .center
        message.textColor = UIColor(hex: 0x4D4D4D)
        message.font = UIFont(name: "HelveticaNeue-Light", size: 20)
            ?? UIFont.systemFont(ofSize: 20, weight: .light)

        let stack = UIStackView(arrangedSubviews: [title, row, warnView, message])
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)

        NSLayoutConstraint.activate([
            card.centerXAnchor.constraint(equalTo: centerXAnchor),
            card.centerYAnchor.constraint(equalTo: centerYAnchor),
            card.widthAnchor.constraint(equalToConstant: 320),
            card.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 20),
            card.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -20),

            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),

            noButton.heightAnchor.constraint(equalToConstant: 90),
            yesButton.heightAnchor.constraint(equalToConstant: 90),
            warnView.heightAnchor.constraint(equalToConstant: 50),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func cancelTapped() {
        onCancel?()
    }

    @objc private func confirmTapped() {
        onConfirm?()
    }

    private func button(defaultName: String, pressName: String) -> UIButton {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: defaultName), for: .normal)
        button.setImage(UIImage(named: pressName), for: .highlighted)
        button.imageView?.contentMode = .scaleAspectFit
        return button
    }
}
