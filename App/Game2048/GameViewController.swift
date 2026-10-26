import UIKit
import AVFoundation
import Game2048Core

final class GameViewController: UIViewController {
    private let store = GameStore()
    private var theme = Theme.current
    private var engine: GameEngine!
    private var boardView: BoardView!
    private var scoreTitleLabel: UILabel!
    private var scoreValueLabel: UILabel!
    private var soundButton: UIButton!
    private var audioPlayer: AVAudioPlayer?
    private var swipe: SwipeInput!
    private var toastLabel: UILabel?
    private var gameOverOverlay: GameOverOverlay?
    private var backgroundObserver: NSObjectProtocol?

    override var prefersStatusBarHidden: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = theme.backgroundColor

        engine = GameEngine(highScore: store.highScore)
        engine.delegate = self
        if ProcessInfo.processInfo.arguments.contains("-showGameOver") {
            engine.restore(GameSnapshot(
                board: Self.seededBoard, score: 676, maxMerged: 32,
                highScore: 676, won: false, lose: true
            ))
        } else if ProcessInfo.processInfo.arguments.contains("-seedBoard") {
            engine.restore(GameSnapshot(
                board: Self.seededBoard, score: 300, maxMerged: 128,
                highScore: 500, won: false, lose: false
            ))
        } else if let snapshot = store.snapshot {
            engine.restore(snapshot)
        }

        buildInterface()
        setupAudio()
        setupGestures()
        updateScore()
        boardView.startAnimating()
        if ProcessInfo.processInfo.arguments.contains("-showGameOver") {
            swipe.isLocked = true
            showGameOver()
        }

        backgroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.store.snapshot = self.engine.snapshot()
        }
    }

    deinit {
        if let observer = backgroundObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    private func buildInterface() {
        let scoreTitle = UILabel()
        scoreTitle.text = "Score"
        scoreTitle.textColor = theme.scoreColor
        scoreTitle.font = thinFont(25)
        scoreTitle.textAlignment = .center
        scoreTitle.translatesAutoresizingMaskIntoConstraints = false
        scoreTitleLabel = scoreTitle

        let scoreValue = UILabel()
        scoreValue.textColor = theme.scoreColor
        scoreValue.font = thinFont(75)
        scoreValue.textAlignment = .center
        scoreValue.adjustsFontSizeToFitWidth = true
        scoreValue.minimumScaleFactor = 0.4
        scoreValue.translatesAutoresizingMaskIntoConstraints = false
        scoreValueLabel = scoreValue

        let board = BoardView(engine: engine, theme: theme)
        board.translatesAutoresizingMaskIntoConstraints = false
        boardView = board

        let newGame = imageButton(defaultName: "re_default", pressName: "re_press", action: #selector(newGameTapped))
        let pause = imageButton(defaultName: "pause_default", pressName: "pause_press", action: #selector(pauseTapped))
        let themeSwitch = imageButton(defaultName: "theme_default", pressName: "theme_press", action: #selector(themeTapped))
        themeSwitch.isHidden = !store.themeQuickSwitch
        let sound = imageButton(defaultName: "vol_default", pressName: "vol_press", action: #selector(soundTapped))
        soundButton = sound
        updateSoundButton()

        let buttons = UIStackView(arrangedSubviews: [newGame, pause, themeSwitch, sound])
        buttons.axis = .horizontal
        buttons.distribution = .equalSpacing
        buttons.alignment = .center
        buttons.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scoreTitle)
        view.addSubview(scoreValue)
        view.addSubview(board)
        view.addSubview(buttons)

        let safe = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            scoreTitle.topAnchor.constraint(equalTo: safe.topAnchor, constant: 8),
            scoreTitle.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            scoreValue.topAnchor.constraint(equalTo: scoreTitle.bottomAnchor),
            scoreValue.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scoreValue.leadingAnchor.constraint(greaterThanOrEqualTo: safe.leadingAnchor, constant: 16),

            board.topAnchor.constraint(equalTo: scoreValue.bottomAnchor, constant: 8),
            board.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            board.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            board.bottomAnchor.constraint(equalTo: buttons.topAnchor, constant: -8),

            buttons.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            buttons.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            buttons.bottomAnchor.constraint(equalTo: safe.bottomAnchor, constant: -8),
            buttons.heightAnchor.constraint(equalToConstant: 70),
        ])

        for button in [newGame, pause, themeSwitch, sound] {
            button.widthAnchor.constraint(equalToConstant: 70).isActive = true
            button.heightAnchor.constraint(equalToConstant: 70).isActive = true
        }
    }

    private func setupAudio() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default)
        try? session.setActive(true)
        guard let url = Bundle.main.url(forResource: "merge", withExtension: "mp3") else { return }
        audioPlayer = try? AVAudioPlayer(contentsOf: url)
        audioPlayer?.enableRate = true
        audioPlayer?.rate = 1.8
        audioPlayer?.prepareToPlay()
    }

    private func setupGestures() {
        swipe = SwipeInput(sensitivity: store.sensitivity, referenceWidth: UIScreen.main.bounds.width)
        swipe.onMove = { [weak self] direction in
            self?.performMove(direction)
        }
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        view.addGestureRecognizer(pan)
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let point = gesture.location(in: view)
        switch gesture.state {
        case .began:
            swipe.began(at: point)
        case .changed:
            swipe.changed(to: point)
        case .ended, .cancelled, .failed:
            swipe.ended()
        default:
            break
        }
    }

    private func performMove(_ direction: Direction) {
        guard !engine.lose else { return }
        let moved = engine.move(direction)
        if moved {
            store.snapshot = engine.snapshot()
            boardView.startAnimating()
        }
    }

    private func updateScore() {
        scoreValueLabel?.text = String(engine.score)
    }

    private func updateSoundButton() {
        let on = store.soundVolume > 0
        soundButton.setImage(UIImage(named: on ? "vol_default" : "mute_default"), for: .normal)
        soundButton.setImage(UIImage(named: on ? "vol_press" : "mute_press"), for: .highlighted)
    }

    private func playMergeSound() {
        guard store.soundVolume > 0, let audioPlayer else { return }
        audioPlayer.volume = Float(store.soundVolume)
        audioPlayer.currentTime = 0
        audioPlayer.play()
    }

    private func applyTheme(_ theme: Theme) {
        self.theme = theme
        store.theme = theme
        view.backgroundColor = theme.backgroundColor
        scoreTitleLabel.textColor = theme.scoreColor
        scoreValueLabel.textColor = theme.scoreColor
        boardView.applyTheme(theme)
    }

    private func startNewGame() {
        engine.newGame()
        store.snapshot = engine.snapshot()
        swipe.isLocked = false
        boardView.isUserInteractionEnabled = true
        updateScore()
        boardView.startAnimating()
    }

    private func showToast(_ text: String) {
        toastLabel?.removeFromSuperview()
        let label = InsetLabel()
        label.text = text
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = .white
        label.font = .systemFont(ofSize: 15)
        label.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        label.alpha = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            label.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, constant: -32),
        ])
        toastLabel = label
        UIView.animate(withDuration: 0.2) { label.alpha = 1 }
        UIView.animate(withDuration: 0.3, delay: 2.5) {
            label.alpha = 0
        } completion: { [weak self] _ in
            label.removeFromSuperview()
            if self?.toastLabel === label {
                self?.toastLabel = nil
            }
        }
    }

    private func showGameOver() {
        gameOverOverlay?.removeFromSuperview()
        let overlay = GameOverOverlay(score: engine.score, highScore: engine.highScore)
        overlay.translatesAutoresizingMaskIntoConstraints = false
        overlay.onRestart = { [weak self] in
            self?.gameOverOverlay?.removeFromSuperview()
            self?.gameOverOverlay = nil
            self?.startNewGame()
        }
        overlay.onShare = { [weak self] in
            self?.shareScore()
        }
        view.addSubview(overlay)
        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: view.topAnchor),
            overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        gameOverOverlay = overlay
    }

    private func shareScore() {
        let text = "I just scored \(engine.score) points in 2048."
        let controller = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        present(controller, animated: true)
    }

    @objc private func newGameTapped() {
        let alert = UIAlertController(
            title: "Start\na new Game?",
            message: "This will discard your\ncurrent game!",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "No", style: .cancel))
        alert.addAction(UIAlertAction(title: "Yes", style: .default) { [weak self] _ in
            self?.startNewGame()
        })
        present(alert, animated: true)
    }

    @objc private func themeTapped() {
        let next: Theme
        switch theme {
        case .holo: next = .dark
        case .dark: next = .classic
        case .classic: next = .holo
        }
        applyTheme(next)
    }

    @objc private func pauseTapped() {
        store.snapshot = engine.snapshot()
        dismiss(animated: true)
    }

    @objc private func soundTapped() {
        store.soundVolume = store.soundVolume > 0 ? 0 : 1
        updateSoundButton()
    }

    private func imageButton(defaultName: String, pressName: String, action: Selector) -> UIButton {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: defaultName), for: .normal)
        button.setImage(UIImage(named: pressName), for: .highlighted)
        button.imageView?.contentMode = .scaleAspectFit
        button.addTarget(self, action: action, for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }

    private func thinFont(_ size: CGFloat) -> UIFont {
        UIFont(name: "HelveticaNeue-UltraLight", size: size)
            ?? UIFont.systemFont(ofSize: size, weight: .ultraLight)
    }

    private static let seededBoard: [[Int]] = {
        let rows = [
            [2, 4, 8, 16],
            [32, 64, 128, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
        ]
        return (0..<4).map { x in (0..<4).map { y in rows[y][x] } }
    }()
}

extension GameViewController: GameEngineDelegate {
    func gameEngine(_ engine: GameEngine, didMerge value: Int) {
        updateScore()
        playMergeSound()
    }

    func gameEngine(_ engine: GameEngine, didReach value: Int) {
        if value == 2048 {
            showToast("You won, Congratulations! Now let's see how far you can go.")
        }
    }

    func gameEngine(_ engine: GameEngine, didUpdateHighScore value: Int) {
        store.highScore = value
    }

    func gameEngineDidEnd(_ engine: GameEngine) {
        store.snapshot = engine.snapshot()
        swipe.isLocked = true
        boardView.isUserInteractionEnabled = false
        showGameOver()
    }
}

private final class InsetLabel: UILabel {
    private let insets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + insets.left + insets.right,
            height: size.height + insets.top + insets.bottom
        )
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let inner = super.sizeThatFits(
            CGSize(width: size.width - insets.left - insets.right, height: size.height)
        )
        return CGSize(
            width: inner.width + insets.left + insets.right,
            height: inner.height + insets.top + insets.bottom
        )
    }
}
