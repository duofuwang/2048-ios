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
    private let audioEngine = AVAudioEngine()
    private var mergeBuffer: AVAudioPCMBuffer?
    private var winBuffer: AVAudioPCMBuffer?
    private var playerNodes: [AVAudioPlayerNode] = []
    private var winNode: AVAudioPlayerNode?
    private var nextNode = 0
    private var mergeSoundIndex = 0
    private let audioQueue = DispatchQueue(label: "com.duofuwang.game2048.audio")
    private var swipe: SwipeInput!
    private var hapticPolicy: HapticPolicy!
    private let hapticFeedback = HapticFeedback()
    private var celebratedMilestones: Set<Int> = []
    private var pendingMilestone: Int?
    private var celebrationWorkItem: DispatchWorkItem?
    private var winDemoTimer: Timer?
    private var gameOverOverlay: GameOverOverlay?
    private var backgroundObserver: NSObjectProtocol?
    private var foregroundObserver: NSObjectProtocol?

    override var prefersStatusBarHidden: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = theme.backgroundColor

        engine = GameEngine(highScore: store.highScore)
        engine.delegate = self
        var restoringGame = false
        engine.restore(GameSnapshot(
            board: Self.demoBoard, score: 0, maxMerged: 2048,
            highScore: store.highScore, won: false, lose: false
        ))
        if ProcessInfo.processInfo.arguments.contains("-showGameOver") {
            engine.restore(GameSnapshot(
                board: Self.seededBoard, score: 676, maxMerged: 32,
                highScore: 676, won: false, lose: true
            ))
        } else if ProcessInfo.processInfo.arguments.contains("-showWin") {
            engine.restore(GameSnapshot(
                board: Self.winBoard, score: 20672, maxMerged: 2048,
                highScore: 20672, won: true, lose: false
            ))
        } else if ProcessInfo.processInfo.arguments.contains("-seedMerge") {
            engine.restore(GameSnapshot(
                board: Self.mergeBoard, score: 0, maxMerged: 0,
                highScore: 0, won: false, lose: false
            ))
        } else if ProcessInfo.processInfo.arguments.contains("-seedBoard") {
            engine.restore(GameSnapshot(
                board: Self.seededBoard, score: 300, maxMerged: 128,
                highScore: 500, won: false, lose: false
            ))
        } else if let snapshot = store.snapshot {
            engine.restore(snapshot)
            restoringGame = true
        }

        hapticPolicy = HapticPolicy(
            isEnabled: store.hapticsEnabled,
            intensity: store.hapticIntensity,
            trigger: store.hapticTrigger,
            seenValues: restoringGame ? store.hapticSeenValues : []
        )
        if !restoringGame {
            store.hapticSeenValues = []
        }
        markCelebratedMilestonesFromBoard()

        buildInterface()
        setupAudio()
        setupGestures()
        updateScore()
        boardView.startAnimating()
        if ProcessInfo.processInfo.arguments.contains("-showGameOver") {
            swipe.isLocked = true
            showGameOver()
        }
        if ProcessInfo.processInfo.arguments.contains("-showNewGame") {
            showNewGameConfirm()
        }
        if ProcessInfo.processInfo.arguments.contains("-showWin") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                self?.boardView.celebrate(value: 2048)
                self?.playWinSound()
            }
            winDemoTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
                self?.boardView.celebrate(value: 2048)
                self?.playWinSound()
            }
        }

        backgroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.saveGameState()
            self.audioEngine.pause()
            try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        }

        foregroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.resumeAudioEngine()
        }
    }

    deinit {
        if let observer = backgroundObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = foregroundObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        winDemoTimer?.invalidate()
        audioEngine.stop()
    }

    private func buildInterface() {
        let scoreTitle = UILabel()
        scoreTitle.text = NSLocalizedString("score", comment: "")
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
        scoreValue.accessibilityIdentifier = "scoreLabel"
        scoreValueLabel = scoreValue

        let board = BoardView(engine: engine, theme: theme)
        board.translatesAutoresizingMaskIntoConstraints = false
        boardView = board

        let newGame = imageButton(defaultName: "re_default", pressName: "re_press", action: #selector(newGameTapped))
        newGame.accessibilityIdentifier = "newGameButton"
        let pause = imageButton(defaultName: "pause_default", pressName: "pause_press", action: #selector(pauseTapped))
        pause.accessibilityIdentifier = "pauseButton"
        let themeSwitch = imageButton(defaultName: "theme_default", pressName: "theme_press", action: #selector(themeTapped))
        themeSwitch.isHidden = !store.themeQuickSwitch
        themeSwitch.accessibilityIdentifier = "themeButton"
        let sound = imageButton(defaultName: "vol_default", pressName: "vol_press", action: #selector(soundTapped))
        sound.accessibilityIdentifier = "soundButton"
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
            buttons.heightAnchor.constraint(equalToConstant: 60),
        ])

        for button in [newGame, pause, themeSwitch, sound] {
            button.widthAnchor.constraint(equalToConstant: 60).isActive = true
            button.heightAnchor.constraint(equalToConstant: 60).isActive = true
        }
    }

    private func setupAudio() {
        let session = AVAudioSession.sharedInstance()
        let category: AVAudioSession.Category = store.respectSilentMode ? .ambient : .playback
        try? session.setCategory(category, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)

        guard let url = Bundle.main.url(forResource: "merge_fast", withExtension: "mp3"),
              let file = try? AVAudioFile(forReading: url),
              let buffer = AVAudioPCMBuffer(
                  pcmFormat: file.processingFormat,
                  frameCapacity: AVAudioFrameCount(file.length)
              ) else {
            return
        }
        try? file.read(into: buffer)
        mergeBuffer = buffer

        for _ in 0..<8 {
            let node = AVAudioPlayerNode()
            audioEngine.attach(node)
            audioEngine.connect(node, to: audioEngine.mainMixerNode, format: buffer.format)
            playerNodes.append(node)
        }

        if let url = Bundle.main.url(forResource: "win", withExtension: "mp3"),
           let file = try? AVAudioFile(forReading: url),
           let buffer = AVAudioPCMBuffer(
               pcmFormat: file.processingFormat,
               frameCapacity: AVAudioFrameCount(file.length)
           ) {
            try? file.read(into: buffer)
            winBuffer = buffer
            let node = AVAudioPlayerNode()
            audioEngine.attach(node)
            audioEngine.connect(node, to: audioEngine.mainMixerNode, format: buffer.format)
            winNode = node
        }

        audioEngine.prepare()
        try? audioEngine.start()
        playerNodes.forEach { $0.play() }
        winNode?.play()
    }

    private func resumeAudioEngine() {
        try? AVAudioSession.sharedInstance().setActive(true)
        if !audioEngine.isRunning {
            try? audioEngine.start()
        }
        playerNodes.forEach { node in
            if !node.isPlaying {
                node.play()
            }
        }
        if let winNode, !winNode.isPlaying {
            winNode.play()
        }
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
        case .ended:
            swipe.ended(at: point)
        case .cancelled, .failed:
            swipe.cancelled()
        default:
            break
        }
    }

    private func performMove(_ direction: Direction) {
        guard !engine.lose else { return }
        pendingMilestone = nil
        hapticPolicy.beginMove()
        if hapticPolicy.isEnabled {
            hapticFeedback.prepare(intensity: hapticPolicy.intensity)
        }
        boardView.startAnimating()
        mergeSoundIndex = 0
        engine.move(direction)
        updateScore()
        hapticFeedback.perform(hapticPolicy.endMove())
        if let milestone = pendingMilestone {
            celebrate(milestone)
        }
    }

    private func saveGameState() {
        store.highScore = engine.highScore
        store.hapticSeenValues = hapticPolicy.seenValues
        store.snapshot = engine.snapshot()
        hapticFeedback.cancel()
        celebrationWorkItem?.cancel()
        celebrationWorkItem = nil
        boardView.clearCelebration()
    }

    private func updateScore() {
        scoreValueLabel?.text = String(engine.score)
    }

    private func updateSoundButton() {
        let on = store.soundVolume > 0
        soundButton.setImage(UIImage(named: on ? "vol_default" : "mute_default"), for: .normal)
        soundButton.setImage(UIImage(named: on ? "vol_press" : "mute_press"), for: .highlighted)
    }

    private func playMergeSound(after delay: TimeInterval) {
        guard store.soundVolume > 0, let buffer = mergeBuffer, !playerNodes.isEmpty else { return }
        let volume = Float(store.soundVolume)
        audioQueue.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self, !self.playerNodes.isEmpty else { return }
            let node = self.playerNodes[self.nextNode % self.playerNodes.count]
            self.nextNode += 1
            node.volume = volume
            node.scheduleBuffer(buffer, at: nil, options: [.interrupts], completionHandler: nil)
            if !node.isPlaying {
                node.play()
            }
        }
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
        celebratedMilestones.removeAll()
        pendingMilestone = nil
        celebrationWorkItem?.cancel()
        celebrationWorkItem = nil
        boardView.clearCelebration()
        hapticPolicy.resetGame()
        hapticPolicy.isEnabled = store.hapticsEnabled
        hapticPolicy.intensity = store.hapticIntensity
        hapticPolicy.trigger = store.hapticTrigger
        store.hapticSeenValues = []
        hapticFeedback.cancel()
        engine.newGame()
        store.snapshot = engine.snapshot()
        swipe.isLocked = false
        boardView.isUserInteractionEnabled = true
        updateScore()
        boardView.startAnimating()
    }

    private func playWinSound() {
        guard store.soundVolume > 0, let buffer = winBuffer else { return }
        let volume = Float(store.soundVolume)
        audioQueue.async { [weak self] in
            guard let self, let node = self.winNode else { return }
            node.volume = volume
            node.scheduleBuffer(buffer, at: nil, options: [.interrupts], completionHandler: nil)
            if !node.isPlaying {
                node.play()
            }
        }
    }

    private func celebrate(_ value: Int) {
        celebratedMilestones.insert(value)
        celebrationWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.boardView.celebrate(value: value)
            self.playWinSound()
        }
        celebrationWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: work)
    }

    private func markCelebratedMilestonesFromBoard() {
        var maxTile = 0
        for x in 0..<GameEngine.sizeX {
            for y in 0..<GameEngine.sizeY {
                maxTile = max(maxTile, engine.grid.field[x][y]?.value ?? 0)
            }
        }
        celebratedMilestones = Set(Self.milestones.filter { $0 <= maxTile })
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
        showNewGameConfirm()
    }

    private func showNewGameConfirm() {
        let overlay = NewGameOverlay()
        overlay.translatesAutoresizingMaskIntoConstraints = false
        overlay.onCancel = { [weak overlay] in
            overlay?.removeFromSuperview()
        }
        overlay.onConfirm = { [weak self, weak overlay] in
            overlay?.removeFromSuperview()
            self?.startNewGame()
        }
        view.addSubview(overlay)
        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: view.topAnchor),
            overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
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
        saveGameState()
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

    private static let demoBoard: [[Int]] = {
        let rows = [
            [2048, 2048, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
        ]
        return (0..<4).map { x in (0..<4).map { y in rows[y][x] } }
    }()

    private static let winBoard: [[Int]] = {
        let rows = [
            [2048, 64, 0, 0],
            [4, 8, 16, 2],
            [32, 2, 4, 0],
            [2, 8, 4, 0],
        ]
        return (0..<4).map { x in (0..<4).map { y in rows[y][x] } }
    }()

    private static let milestones: Set<Int> = [
        2048, 4096, 8192, 16384, 32768, 65536, 131072,
    ]

    private static let mergeBoard: [[Int]] = {
        let rows = [
            [2, 2, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
        ]
        return (0..<4).map { x in (0..<4).map { y in rows[y][x] } }
    }()
}

extension GameViewController: GameEngineDelegate {
    func gameEngine(_ engine: GameEngine, didMerge value: Int) {
        hapticPolicy.mergeDidOccur(value: value)
        if Self.milestones.contains(value), !celebratedMilestones.contains(value) {
            celebratedMilestones.insert(value)
            pendingMilestone = max(pendingMilestone ?? 0, value)
        }
        let delay = Double(mergeSoundIndex) * 0.012
        mergeSoundIndex += 1
        playMergeSound(after: delay)
    }

    func gameEngine(_ engine: GameEngine, didReach value: Int) {
    }

    func gameEngine(_ engine: GameEngine, didUpdateHighScore value: Int) {
    }

    func gameEngineDidEnd(_ engine: GameEngine) {
        saveGameState()
        swipe.isLocked = true
        boardView.isUserInteractionEnabled = false
        showGameOver()
    }
}
