import UIKit

final class StartViewController: UIViewController {
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hex: 0x2081E4)

        let titleLabel = UILabel()
        titleLabel.text = "2048"
        titleLabel.textColor = .white
        titleLabel.font = UIFont(name: "HelveticaNeue-UltraLight", size: 96)
            ?? UIFont.systemFont(ofSize: 96, weight: .ultraLight)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let playButton = UIButton(type: .custom)
        playButton.setImage(UIImage(named: "play_default"), for: .normal)
        playButton.setImage(UIImage(named: "play_press"), for: .highlighted)
        playButton.imageView?.contentMode = .scaleAspectFit
        playButton.addTarget(self, action: #selector(playTapped), for: .touchUpInside)
        playButton.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(titleLabel)
        view.addSubview(playButton)

        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -180),
            playButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 90),
            playButton.widthAnchor.constraint(equalToConstant: 100),
            playButton.heightAnchor.constraint(equalToConstant: 100),
        ])
    }

    @objc private func playTapped() {
        let game = GameViewController()
        game.modalPresentationStyle = .fullScreen
        game.modalPresentationCapturesStatusBarAppearance = true
        present(game, animated: true)
    }
}
