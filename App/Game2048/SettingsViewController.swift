import UIKit
import Game2048Core

final class SettingsViewController: UIViewController {
    private enum Section: Int, CaseIterable {
        case appearance
        case controls
        case sound
        case haptics
    }

    private struct MenuOption {
        let title: String
        let isSelected: Bool
        let action: () -> Void
    }

    private let store = GameStore()
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let themes: [Theme] = [.holo, .dark, .classic]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("set", comment: "")
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done, target: self, action: #selector(done)
        )
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
        tableView.register(SensitivityCell.self, forCellReuseIdentifier: "sensitivity")
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    @objc private func done() {
        dismiss(animated: true)
    }

    @objc private func themeSwitchChanged(_ sender: UISwitch) {
        store.themeQuickSwitch = sender.isOn
    }

    @objc private func respectSilentChanged(_ sender: UISwitch) {
        store.respectSilentMode = sender.isOn
    }

    @objc private func gameSoundChanged(_ sender: UISwitch) {
        store.soundVolume = sender.isOn ? 1 : 0
    }

    @objc private func hapticsSwitchChanged(_ sender: UISwitch) {
        store.hapticsEnabled = sender.isOn
        tableView.reloadSections(IndexSet(integer: Section.haptics.rawValue), with: .none)
    }

    private func name(of theme: Theme) -> String {
        switch theme {
        case .holo: return NSLocalizedString("theme_holo", comment: "")
        case .dark: return NSLocalizedString("theme_dark", comment: "")
        case .classic: return NSLocalizedString("theme_classic", comment: "")
        }
    }

    private func name(of intensity: HapticIntensity) -> String {
        switch intensity {
        case .light: return NSLocalizedString("pref_haptic_intensity_light", comment: "")
        case .medium: return NSLocalizedString("pref_haptic_intensity_medium", comment: "")
        case .strong: return NSLocalizedString("pref_haptic_intensity_strong", comment: "")
        }
    }

    private func name(of trigger: HapticTrigger) -> String {
        switch trigger {
        case .perMove: return NSLocalizedString("pref_haptic_trigger_per_move", comment: "")
        case .perMerge: return NSLocalizedString("pref_haptic_trigger_per_merge", comment: "")
        case .onNewValue: return NSLocalizedString("pref_haptic_trigger_on_new_value", comment: "")
        }
    }

    private func hapticsCell(row: Int) -> UITableViewCell {
        switch row {
        case 0:
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = NSLocalizedString("pref_haptics_enabled", comment: "")
            cell.selectionStyle = .none
            let toggle = UISwitch()
            toggle.isOn = store.hapticsEnabled
            toggle.addTarget(self, action: #selector(hapticsSwitchChanged(_:)), for: .valueChanged)
            cell.accessoryView = toggle
            return cell

        case 1:
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = NSLocalizedString("pref_haptic_intensity", comment: "")
            cell.textLabel?.textColor = store.hapticsEnabled ? .label : .secondaryLabel
            cell.selectionStyle = .none
            let button = menuButton(
                title: name(of: store.hapticIntensity),
                isEnabled: store.hapticsEnabled,
                options: HapticIntensity.allCases.map { intensity in
                    MenuOption(
                        title: name(of: intensity),
                        isSelected: store.hapticIntensity == intensity
                    ) { [weak self] in
                        self?.store.hapticIntensity = intensity
                        self?.tableView.reloadSections(
                            IndexSet(integer: Section.haptics.rawValue), with: .none
                        )
                    }
                }
            )
            cell.accessoryView = button
            return cell

        default:
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = NSLocalizedString("pref_haptic_trigger", comment: "")
            cell.textLabel?.textColor = store.hapticsEnabled ? .label : .secondaryLabel
            cell.selectionStyle = .none
            let button = menuButton(
                title: name(of: store.hapticTrigger),
                isEnabled: store.hapticsEnabled,
                options: HapticTrigger.allCases.map { trigger in
                    MenuOption(
                        title: name(of: trigger),
                        isSelected: store.hapticTrigger == trigger
                    ) { [weak self] in
                        self?.store.hapticTrigger = trigger
                        self?.tableView.reloadSections(
                            IndexSet(integer: Section.haptics.rawValue), with: .none
                        )
                    }
                }
            )
            cell.accessoryView = button
            return cell
        }
    }

    private func themeCell() -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.textLabel?.text = NSLocalizedString("pref_theme", comment: "")
        cell.selectionStyle = .none
        cell.accessoryView = menuButton(
            title: name(of: store.theme),
            options: themes.map { theme in
                MenuOption(
                    title: name(of: theme),
                    isSelected: store.theme == theme
                ) { [weak self] in
                    self?.store.theme = theme
                    self?.tableView.reloadData()
                }
            }
        )
        return cell
    }

    private func quickSwitchCell() -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.textLabel?.text = NSLocalizedString("pref_themebutton", comment: "")
        cell.selectionStyle = .none
        let toggle = UISwitch()
        toggle.isOn = store.themeQuickSwitch
        toggle.addTarget(self, action: #selector(themeSwitchChanged(_:)), for: .valueChanged)
        cell.accessoryView = toggle
        return cell
    }

    private func gameSoundCell() -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.textLabel?.text = NSLocalizedString("pref_game_sound", comment: "")
        cell.selectionStyle = .none
        let toggle = UISwitch()
        toggle.isOn = store.soundVolume > 0
        toggle.addTarget(self, action: #selector(gameSoundChanged(_:)), for: .valueChanged)
        cell.accessoryView = toggle
        return cell
    }

    private func silentModeCell() -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.textLabel?.text = NSLocalizedString("pref_respect_silent", comment: "")
        cell.selectionStyle = .none
        let toggle = UISwitch()
        toggle.isOn = store.respectSilentMode
        toggle.addTarget(self, action: #selector(respectSilentChanged(_:)), for: .valueChanged)
        cell.accessoryView = toggle
        return cell
    }

    private func menuButton(title: String, isEnabled: Bool = true, options: [MenuOption]) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17)
        button.setTitleColor(.secondaryLabel, for: .normal)
        button.setImage(Self.chevronImage, for: .normal)
        button.tintColor = .tertiaryLabel
        button.semanticContentAttribute = .forceRightToLeft
        button.showsMenuAsPrimaryAction = true
        button.menu = UIMenu(children: options.map { option in
            UIAction(title: option.title, state: option.isSelected ? .on : .off) { _ in
                option.action()
            }
        })
        button.isEnabled = isEnabled
        button.alpha = isEnabled ? 1 : 0.5
        button.sizeToFit()
        return button
    }

    private static let chevronImage: UIImage? = {
        let configuration = UIImage.SymbolConfiguration(pointSize: 13, weight: .medium)
        guard let symbol = UIImage(systemName: "chevron.up.chevron.down", withConfiguration: configuration) else {
            return nil
        }
        let padding: CGFloat = 6
        let size = CGSize(width: symbol.size.width + padding, height: symbol.size.height)
        return UIGraphicsImageRenderer(size: size).image { _ in
            symbol.draw(at: CGPoint(x: padding, y: 0))
        }.withRenderingMode(.alwaysTemplate)
    }()
}

extension SettingsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = Section(rawValue: section) else { return 0 }
        switch section {
        case .appearance: return 2
        case .controls: return 1
        case .sound: return 2
        case .haptics: return 3
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let section = Section(rawValue: section) else { return nil }
        switch section {
        case .appearance: return NSLocalizedString("pref_appearance", comment: "")
        case .controls: return NSLocalizedString("pref_controls", comment: "")
        case .sound: return NSLocalizedString("pref_sound", comment: "")
        case .haptics: return NSLocalizedString("pref_haptics", comment: "")
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = Section(rawValue: indexPath.section) else { return UITableViewCell() }
        switch section {
        case .appearance:
            return indexPath.row == 0 ? themeCell() : quickSwitchCell()
        case .controls:
            let cell = tableView.dequeueReusableCell(withIdentifier: "sensitivity", for: indexPath) as! SensitivityCell
            cell.configure(value: store.sensitivity)
            cell.onChange = { [weak self] value in
                self?.store.sensitivity = value
            }
            return cell
        case .sound:
            return indexPath.row == 0 ? gameSoundCell() : silentModeCell()
        case .haptics:
            return hapticsCell(row: indexPath.row)
        }
    }
}

private final class SensitivityCell: UITableViewCell {
    private let slider = TickSlider()
    var onChange: ((Double) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none

        let title = UILabel()
        title.text = NSLocalizedString("slider_title", comment: "")
        title.font = .systemFont(ofSize: 17)

        let slow = UIImageView(image: UIImage(
            systemName: "tortoise",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .regular)
        ))
        slow.tintColor = .secondaryLabel
        slow.setContentHuggingPriority(.required, for: .horizontal)

        let fast = UIImageView(image: UIImage(
            systemName: "hare",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .regular)
        ))
        fast.tintColor = .secondaryLabel
        fast.setContentHuggingPriority(.required, for: .horizontal)

        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.accessibilityLabel = NSLocalizedString("slider_title", comment: "")
        slider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)

        let row = UIStackView(arrangedSubviews: [slow, slider, fast])
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .center

        let stack = UIStackView(arrangedSubviews: [title, row])
        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(value: Double) {
        slider.value = Float(value)
        slider.snapToTick()
        updateAccessibilityValue()
    }

    @objc private func sliderChanged() {
        slider.snapToTick()
        updateAccessibilityValue()
        onChange?(Double(slider.value))
    }

    private func updateAccessibilityValue() {
        let key: String
        switch Int((slider.value * 3).rounded()) {
        case 0: key = "sens_low"
        case 1: key = "sens_medium"
        case 2: key = "sens_high"
        default: key = "sens_very_high"
        }
        slider.accessibilityValue = NSLocalizedString(key, comment: "")
    }
}

private final class TickSlider: UISlider {
    private let tickCount = 4
    private var step: Float { Float(1) / Float(tickCount - 1) }

    override func layoutSubviews() {
        super.layoutSubviews()
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        let track = trackRect(forBounds: bounds)
        let radius: CGFloat = 2
        UIColor.tertiaryLabel.setFill()
        for index in 0..<tickCount {
            let x = track.minX + track.width * CGFloat(index) / CGFloat(tickCount - 1)
            UIBezierPath(ovalIn: CGRect(
                x: x - radius,
                y: track.maxY + 4,
                width: radius * 2,
                height: radius * 2
            )).fill()
        }
        super.draw(rect)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            setNeedsDisplay()
        }
    }

    func snapToTick() {
        value = (value / step).rounded() * step
    }

    override func accessibilityIncrement() {
        setValue(min(maximumValue, value + step), animated: false)
        sendActions(for: .valueChanged)
    }

    override func accessibilityDecrement() {
        setValue(max(minimumValue, value - step), animated: false)
        sendActions(for: .valueChanged)
    }
}
