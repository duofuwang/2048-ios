import UIKit

final class StartViewController: UIViewController {
    private let backgroundBlue = UIColor(red: 0x20 / 255, green: 0x81 / 255, blue: 0xE4 / 255, alpha: 1)
    private let buttonGreen = UIColor(red: 0x8B / 255, green: 0xC3 / 255, blue: 0x4A / 255, alpha: 1)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = backgroundBlue

        let titleLabel = UILabel()
        titleLabel.text = "2048"
        titleLabel.textColor = .white
        titleLabel.font = UIFont(name: "HelveticaNeue-UltraLight", size: 96)
            ?? UIFont.systemFont(ofSize: 96, weight: .ultraLight)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let playButton = UIButton(type: .system)
        playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playButton.tintColor = .white
        playButton.backgroundColor = buttonGreen
        playButton.layer.cornerRadius = 50
        playButton.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(titleLabel)
        view.addSubview(playButton)

        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -100),
            playButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 100),
            playButton.widthAnchor.constraint(equalToConstant: 100),
            playButton.heightAnchor.constraint(equalToConstant: 100),
        ])
    }
}
