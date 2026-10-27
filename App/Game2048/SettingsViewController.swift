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
        var configuration = UIButton.Configuration.plain()
        var attributedTitle = AttributedString(title)
        attributedTitle.font = .systemFont(ofSize: 17)
        configuration.attributedTitle = attributedTitle
        configuration.image = Self.chevronImage
        configuration.imagePlacement = .trailing
        configuration.imagePadding = 6
        configuration.imageColorTransformer = UIConfigurationColorTransformer { _ in .tertiaryLabel }
        configuration.contentInsets = .zero
        configuration.baseForegroundColor = .secondaryLabel

        let button = UIButton(configuration: configuration)
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

    private static let chevronImage = UIImage(
        systemName: "chevron.up.chevron.down",
        withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .medium)
    )
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
        case .sound: return 1
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

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard let section = Section(rawValue: section) else { return nil }
        return section == .haptics ? NSLocalizedString("pref_haptics_footer", comment: "") : nil
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
            return silentModeCell()
        case .haptics:
            return hapticsCell(row: indexPath.row)
        }
    }
}

private final class SensitivityCell: UITableViewCell {
    private let slider = UISlider()
    private let valueLabel = UILabel()
    var onChange: ((Double) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none

        let title = UILabel()
        title.text = NSLocalizedString("slider_title", comment: "")
        title.font = .systemFont(ofSize: 17)

        valueLabel.font = .systemFont(ofSize: 17)
        valueLabel.textColor = .secondaryLabel

        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)

        let stack = UIStackView(arrangedSubviews: [title, slider, valueLabel])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(value: Double) {
        slider.value = Float(value)
        updateLabel()
    }

    @objc private func sliderChanged() {
        updateLabel()
        onChange?(Double(slider.value))
    }

    private func updateLabel() {
        let value = slider.value
        if value < 0.25 {
            valueLabel.text = NSLocalizedString("sens_low", comment: "")
        } else if value < 0.5 {
            valueLabel.text = NSLocalizedString("sens_medium", comment: "")
        } else if value < 0.75 {
            valueLabel.text = NSLocalizedString("sens_high", comment: "")
        } else {
            valueLabel.text = NSLocalizedString("sens_very_high", comment: "")
        }
    }
}
