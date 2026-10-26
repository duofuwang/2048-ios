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

        let menuButton = UIButton(type: .custom)
        menuButton.setImage(UIImage(named: "ic_action_overflow"), for: .normal)
        menuButton.imageView?.contentMode = .scaleAspectFit
        menuButton.showsMenuAsPrimaryAction = true
        menuButton.menu = UIMenu(children: [
            UIAction(title: "How to play") { [weak self] _ in
                self?.presentFullScreen(TutorialViewController())
            },
            UIAction(title: "More") { [weak self] _ in
                self?.presentAbout()
            },
            UIAction(title: "Settings") { [weak self] _ in
                self?.presentSettings()
            },
        ])
        menuButton.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(titleLabel)
        view.addSubview(playButton)
        view.addSubview(menuButton)

        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -180),

            playButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 90),
            playButton.widthAnchor.constraint(equalToConstant: 100),
            playButton.heightAnchor.constraint(equalToConstant: 100),

            menuButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            menuButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            menuButton.widthAnchor.constraint(equalToConstant: 48),
            menuButton.heightAnchor.constraint(equalToConstant: 48),
        ])
    }

    @objc private func playTapped() {
        let game = GameViewController()
        game.modalPresentationStyle = .fullScreen
        game.modalPresentationCapturesStatusBarAppearance = true
        present(game, animated: true)
    }

    private func presentFullScreen(_ viewController: UIViewController) {
        viewController.modalPresentationStyle = .fullScreen
        viewController.modalTransitionStyle = .crossDissolve
        viewController.modalPresentationCapturesStatusBarAppearance = true
        present(viewController, animated: true)
    }

    private func presentAbout() {
        let nav = UINavigationController(rootViewController: AboutViewController())
        nav.modalPresentationStyle = .fullScreen
        nav.modalPresentationCapturesStatusBarAppearance = true
        present(nav, animated: true)
    }

    private func presentSettings() {
        let nav = UINavigationController(rootViewController: SettingsViewController())
        nav.modalPresentationStyle = .fullScreen
        nav.modalPresentationCapturesStatusBarAppearance = true
        present(nav, animated: true)
    }
}
