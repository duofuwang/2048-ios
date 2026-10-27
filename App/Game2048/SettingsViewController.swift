import UIKit
import Game2048Core

final class SettingsViewController: UIViewController {
    private let store = GameStore()
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let themes: [Theme] = [.holo, .dark, .classic]
    private let hapticIntensities: [HapticIntensity] = [.light, .medium, .strong]
    private let hapticTriggers: [HapticTrigger] = [.perMove, .perMerge, .onNewValue]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("set", comment: "")
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done, target: self, action: #selector(done)
        )
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
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
        tableView.reloadSections(IndexSet(integer: 1), with: .none)
    }

    @objc private func hapticsIntensityChanged(_ sender: UISegmentedControl) {
        let index = sender.selectedSegmentIndex
        guard hapticIntensities.indices.contains(index) else { return }
        store.hapticIntensity = hapticIntensities[index]
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
            let control = UISegmentedControl(items: hapticIntensities.map { name(of: $0) })
            control.selectedSegmentIndex = hapticIntensities.firstIndex(of: store.hapticIntensity) ?? 0
            control.isEnabled = store.hapticsEnabled
            control.alpha = store.hapticsEnabled ? 1 : 0.5
            control.addTarget(self, action: #selector(hapticsIntensityChanged(_:)), for: .valueChanged)
            cell.accessoryView = control
            return cell

        default:
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = NSLocalizedString("pref_haptic_trigger", comment: "")
            cell.textLabel?.textColor = store.hapticsEnabled ? .label : .secondaryLabel
            cell.selectionStyle = .none
            let button = UIButton(type: .system)
            button.setTitle(name(of: store.hapticTrigger), for: .normal)
            button.setImage(UIImage(systemName: "chevron.down"), for: .normal)
            button.semanticContentAttribute = .forceRightToLeft
            button.showsMenuAsPrimaryAction = true
            button.menu = UIMenu(children: hapticTriggers.map { trigger in
                UIAction(
                    title: name(of: trigger),
                    state: store.hapticTrigger == trigger ? .on : .off
                ) { [weak self] _ in
                    self?.store.hapticTrigger = trigger
                    self?.tableView.reloadSections(IndexSet(integer: 1), with: .none)
                }
            })
            button.isEnabled = store.hapticsEnabled
            button.alpha = store.hapticsEnabled ? 1 : 0.5
            button.sizeToFit()
            cell.accessoryView = button
            return cell
        }
    }
}

extension SettingsViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? 4 : 3
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 1 ? NSLocalizedString("pref_haptics", comment: "") : nil
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        section == 1 ? NSLocalizedString("pref_haptics_footer", comment: "") : nil
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 1 {
            return hapticsCell(row: indexPath.row)
        }

        switch indexPath.row {
        case 0:
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = NSLocalizedString("pref_theme", comment: "")
            cell.selectionStyle = .none
            let button = UIButton(type: .system)
            button.setTitle(name(of: store.theme), for: .normal)
            button.setImage(UIImage(systemName: "chevron.down"), for: .normal)
            button.semanticContentAttribute = .forceRightToLeft
            button.showsMenuAsPrimaryAction = true
            button.menu = UIMenu(children: themes.map { theme in
                UIAction(
                    title: name(of: theme),
                    state: store.theme == theme ? .on : .off
                ) { [weak self] _ in
                    self?.store.theme = theme
                    self?.tableView.reloadData()
                }
            })
            button.sizeToFit()
            cell.accessoryView = button
            return cell
        case 1:
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = NSLocalizedString("pref_themebutton", comment: "")
            cell.selectionStyle = .none
            let toggle = UISwitch()
            toggle.isOn = store.themeQuickSwitch
            toggle.addTarget(self, action: #selector(themeSwitchChanged(_:)), for: .valueChanged)
            cell.accessoryView = toggle
            return cell
        case 3:
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = NSLocalizedString("pref_respect_silent", comment: "")
            cell.selectionStyle = .none
            let toggle = UISwitch()
            toggle.isOn = store.respectSilentMode
            toggle.addTarget(self, action: #selector(respectSilentChanged(_:)), for: .valueChanged)
            cell.accessoryView = toggle
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "sensitivity", for: indexPath) as! SensitivityCell
            cell.configure(value: store.sensitivity)
            cell.onChange = { [weak self] value in
                self?.store.sensitivity = value
            }
            return cell
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

        valueLabel.font = .systemFont(ofSize: 15)
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
