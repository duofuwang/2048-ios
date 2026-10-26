import UIKit

final class SettingsViewController: UIViewController {
    private let store = GameStore()
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let themes: [Theme] = [.holo, .dark, .classic]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
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

    private func chooseTheme() {
        let alert = UIAlertController(title: "Theme", message: nil, preferredStyle: .actionSheet)
        for theme in themes {
            alert.addAction(UIAlertAction(title: name(of: theme), style: .default) { [weak self] _ in
                self?.store.theme = theme
                self?.tableView.reloadData()
            })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func name(of theme: Theme) -> String {
        switch theme {
        case .holo: return "Holo (Default)"
        case .dark: return "Dark"
        case .classic: return "Classic"
        }
    }
}

extension SettingsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        3
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
            cell.textLabel?.text = "Theme"
            cell.detailTextLabel?.text = name(of: store.theme)
            cell.accessoryType = .disclosureIndicator
            return cell
        case 1:
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = "Theme Quick Switch"
            cell.selectionStyle = .none
            let toggle = UISwitch()
            toggle.isOn = store.themeQuickSwitch
            toggle.addTarget(self, action: #selector(themeSwitchChanged(_:)), for: .valueChanged)
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

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == 0 {
            chooseTheme()
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
        title.text = "Swipe Sensitivity"
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
            valueLabel.text = "Low"
        } else if value < 0.5 {
            valueLabel.text = "Medium"
        } else if value < 0.75 {
            valueLabel.text = "High"
        } else {
            valueLabel.text = "Very High"
        }
    }
}
