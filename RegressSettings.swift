import UIKit

@objc public class RegressSettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private var tableView: UITableView!
    private let settings = UserDefaults.standard
    
    private let sections = [
        "Невидимка (Ghost Mode)",
        "История сообщений (Anti-Recall)",
        "Внешний вид (Material 3 & UI)",
        "Панель вкладок (Navigation)",
        "Персонализация и Профиль",
        "Безопасность и Очистка"
    ]
    
    private var activeFontName: String {
        return settings.string(forKey: "regress_active_font") ?? "Системный"
    }
    
    private var selectedThemeName: String {
        let hsl = settings.string(forKey: "regress_theme_hsl") ?? "system"
        for preset in AyuThemeManager.themePresets {
            if preset["hsl"] == hsl {
                return preset["name"] ?? "Dynamic System"
            }
        }
        return "Custom Color"
    }

    private var selectedIconName: String {
        return settings.string(forKey: "regress_app_icon") ?? "Regress Default"
    }
    
    private var selectedBadgeName: String {
        return settings.string(forKey: "regress_profile_badge") ?? "Без значка"
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Настройки Regress"
        self.view.backgroundColor = .systemGroupedBackground
        
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationItem.largeTitleDisplayMode = .always
        
        tableView = UITableView(frame: self.view.bounds, style: .grouped)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "StandardCell")
        
        self.view.addSubview(tableView)
        setupHeaderView()
    }
    
    private func setupHeaderView() {
        let header = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 140))
        header.backgroundColor = .clear
        
        let logoLabel = UILabel()
        logoLabel.text = "REGRESS"
        logoLabel.font = UIFont.systemFont(ofSize: 34, weight: .black)
        logoLabel.textColor = self.view.tintColor
        logoLabel.textAlignment = .center
        logoLabel.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(logoLabel)
        
        let subLabel = UILabel()
        subLabel.text = "Material 3 Client Optimization"
        subLabel.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        subLabel.textColor = .secondaryLabel
        subLabel.textAlignment = .center
        subLabel.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(subLabel)
        
        NSLayoutConstraint.activate([
            logoLabel.centerXAnchor.constraint(equalTo: header.centerXAnchor),
            logoLabel.topAnchor.constraint(equalTo: header.topAnchor, constant: 30),
            subLabel.centerXAnchor.constraint(equalTo: header.centerXAnchor),
            subLabel.topAnchor.constraint(equalTo: logoLabel.bottomAnchor, constant: 5)
        ])
        
        tableView.tableHeaderView = header
    }
    
    // MARK: - Table View Data Source
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 5 // Ghost Mode (+ Ghost Stories)
        case 1: return 4 // Anti-Recall (+ Save Self-destruct)
        case 2: return 3 // Appearance
        case 3: return 2 // Tab Bar Navigation
        case 4: return 5 // Personalization (+ Screenshot Unblocker, Local Premium, Streamer, Speed, Badge)
        case 5: return 2 // Security
        default: return 0
        }
    }
    
    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section]
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "StandardCell", for: indexPath)
        cell.textLabel?.font = UIFont.systemFont(ofSize: 16)
        cell.accessoryView = nil
        cell.accessoryType = .none
        cell.imageView?.image = nil
        
        switch indexPath.section {
        case 0: // Ghost Mode
            if indexPath.row == 0 {
                cell.textLabel?.text = "Включить Режим Невидимки"
                let sw = UISwitch()
                sw.isOn = settings.bool(forKey: "regress_ghost_master")
                sw.addTarget(self, action: #selector(toggleGhostMaster(_:)), for: .valueChanged)
                cell.accessoryView = sw
            } else if indexPath.row == 1 {
                cell.textLabel?.text = "Не читать сообщения (Без отчетов)"
                let sw = UISwitch()
                sw.isOn = settings.bool(forKey: "regress_ghost_noread")
                sw.addTarget(self, action: #selector(toggleNoRead(_:)), for: .valueChanged)
                cell.accessoryView = sw
            } else if indexPath.row == 2 {
                cell.textLabel?.text = "Скрывать статус набора текста"
                let sw = UISwitch()
                sw.isOn = settings.bool(forKey: "regress_ghost_notyping")
                sw.addTarget(self, action: #selector(toggleNoTyping(_:)), for: .valueChanged)
                cell.accessoryView = sw
            } else if indexPath.row == 3 {
                cell.textLabel?.text = "Скрывать статус Онлайн"
                let sw = UISwitch()
                sw.isOn = settings.bool(forKey: "regress_ghost_noonline")
                sw.addTarget(self, action: #selector(toggleNoOnline(_:)), for: .valueChanged)
                cell.accessoryView = sw
            } else if indexPath.row == 4 {
                cell.textLabel?.text = "Скрытный просмотр Историй"
                let sw = UISwitch()
                sw.isOn = settings.bool(forKey: "regress_ghost_stories")
                sw.addTarget(self, action: #selector(toggleGhostStories(_:)), for: .valueChanged)
                cell.accessoryView = sw
            }
            
        case 1: // Anti-Recall
            if indexPath.row == 0 {
                cell.textLabel?.text = "Сохранять удаленные сообщения"
                let sw = UISwitch()
                sw.isOn = settings.bool(forKey: "regress_antirecall_active")
                sw.addTarget(self, action: #selector(toggleAntiRecall(_:)), for: .valueChanged)
                cell.accessoryView = sw
            } else if indexPath.row == 1 {
                cell.textLabel?.text = "Показывать значок удаления (🗑️)"
                let sw = UISwitch()
                sw.isOn = settings.bool(forKey: "regress_antirecall_badge")
                sw.addTarget(self, action: #selector(toggleAntiRecallBadge(_:)), for: .valueChanged)
                cell.accessoryView = sw
            } else if indexPath.row == 2 {
                cell.textLabel?.text = "Сохранять историю изменений"
                let sw = UISwitch()
                sw.isOn = settings.bool(forKey: "regress_edit_history")
                sw.addTarget(self, action: #selector(toggleEditHistory(_:)), for: .valueChanged)
                cell.accessoryView = sw
            } else if indexPath.row == 3 {
                cell.textLabel?.text = "Сохранять исчезающие медиа"
                let sw = UISwitch()
                sw.isOn = settings.bool(forKey: "regress_save_selfdestruct")
                sw.addTarget(self, action: #selector(toggleSaveSelfDestruct(_:)), for: .valueChanged)
                cell.accessoryView = sw
            }
            
        case 2: // Appearance
            if indexPath.row == 0 {
                cell.textLabel?.text = "Палитра Material You (HSL)"
                cell.accessoryType = .disclosureIndicator
                let detailLabel = UILabel()
                detailLabel.text = selectedThemeName
                detailLabel.font = UIFont.systemFont(ofSize: 14)
                detailLabel.textColor = .secondaryLabel
                detailLabel.sizeToFit()
                cell.accessoryView = detailLabel
            } else if indexPath.row == 1 {
                cell.textLabel?.text = "Кастомный шрифт"
                cell.accessoryType = .disclosureIndicator
                let detailLabel = UILabel()
                detailLabel.text = activeFontName
                detailLabel.font = UIFont.systemFont(ofSize: 14)
                detailLabel.textColor = .secondaryLabel
                detailLabel.sizeToFit()
                cell.accessoryView = detailLabel
            } else if indexPath.row == 2 {
                cell.textLabel?.text = "Кастомные иконки"
                cell.accessoryType = .disclosureIndicator
                let detailLabel = UILabel()
                detailLabel.text = selectedIconName
                detailLabel.font = UIFont.systemFont(ofSize: 14)
                detailLabel.textColor = .secondaryLabel
                detailLabel.sizeToFit()
                cell.accessoryView = detailLabel
            }
            
        case 3: // Tab Bar Navigation
            if indexPath.row == 0 {
                cell.textLabel?.text = "Скрыть вкладку Истории"
                let sw = UISwitch()
                sw.isOn = settings.bool(forKey: "regress_hide_stories_tab")
                sw.addTarget(self, action: #selector(toggleHideStoriesTab(_:)), for: .valueChanged)
                cell.accessoryView = sw
            } else if indexPath.row == 1 {
                cell.textLabel?.text = "Скрыть вкладку Контакты"
                let sw = UISwitch()
                sw.isOn = settings.bool(forKey: "regress_hide_contacts_tab")
                sw.addTarget(self, action: #selector(toggleHideContactsTab(_:)), for: .valueChanged)
                cell.accessoryView = sw
            }
            
        case 4: // Personalization
            if indexPath.row == 0 {
                cell.textLabel?.text = "Локальный Premium (Все фичи)"
                let sw = UISwitch()
                sw.isOn = settings.bool(forKey: "regress_local_premium")
                sw.addTarget(self, action: #selector(toggleLocalPremium(_:)), for: .valueChanged)
                cell.accessoryView = sw
            } else if indexPath.row == 1 {
                cell.textLabel?.text = "Режим стримера (Скрытие данных)"
                let sw = UISwitch()
                sw.isOn = settings.bool(forKey: "regress_streamer_mode")
                sw.addTarget(self, action: #selector(toggleStreamerMode(_:)), for: .valueChanged)
                cell.accessoryView = sw
            } else if indexPath.row == 2 {
                cell.textLabel?.text = "Ускорение загрузки (Буфер)"
                let sw = UISwitch()
                sw.isOn = settings.bool(forKey: "regress_speed_booster")
                sw.addTarget(self, action: #selector(toggleSpeedBooster(_:)), for: .valueChanged)
                cell.accessoryView = sw
            } else if indexPath.row == 3 {
                cell.textLabel?.text = "Разрешить скриншоты везде"
                let sw = UISwitch()
                sw.isOn = settings.bool(forKey: "regress_unblock_screenshots")
                sw.addTarget(self, action: #selector(toggleUnblockScreenshots(_:)), for: .valueChanged)
                cell.accessoryView = sw
            } else if indexPath.row == 4 {
                cell.textLabel?.text = "Кастомный значок профиля"
                cell.accessoryType = .disclosureIndicator
                let detailLabel = UILabel()
                detailLabel.text = selectedBadgeName
                detailLabel.font = UIFont.systemFont(ofSize: 14)
                detailLabel.textColor = .secondaryLabel
                detailLabel.sizeToFit()
                cell.accessoryView = detailLabel
            }
            
        case 5: // Security
            if indexPath.row == 0 {
                cell.textLabel?.text = "Очистить кэш удаленных сообщений"
                cell.textLabel?.textColor = .systemRed
            } else if indexPath.row == 1 {
                cell.textLabel?.text = "Сбросить все настройки Regress"
                cell.textLabel?.textColor = .systemRed
            }
            
        default:
            break
        }
        
        return cell
    }
    
    // MARK: - Table View Delegate & Spring Animation
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let cell = tableView.cellForRow(at: indexPath) {
            UIView.animate(withDuration: 0.1, delay: 0, options: [.curveEaseInOut], animations: {
                cell.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
            }) { _ in
                UIView.animate(withDuration: 0.1, animations: {
                    cell.transform = .identity
                })
            }
        }
        
        switch indexPath.section {
        case 2: // Appearance
            if indexPath.row == 0 {
                presentThemePicker()
            } else if indexPath.row == 1 {
                presentFontPicker()
            } else if indexPath.row == 2 {
                presentIconPicker()
            }
        case 4: // Personalization
            if indexPath.row == 4 {
                presentBadgePicker()
            }
        case 5: // Security
            if indexPath.row == 0 {
                confirmClearCache()
            } else if indexPath.row == 1 {
                confirmResetSettings()
            }
        default:
            break
        }
    }
    
    // MARK: - Switches actions
    
    @objc private func toggleGhostMaster(_ sender: UISwitch) {
        settings.set(sender.isOn, forKey: "regress_ghost_master")
        tableView.reloadData()
    }
    @objc private func toggleNoRead(_ sender: UISwitch) { settings.set(sender.isOn, forKey: "regress_ghost_noread") }
    @objc private func toggleNoTyping(_ sender: UISwitch) { settings.set(sender.isOn, forKey: "regress_ghost_notyping") }
    @objc private func toggleNoOnline(_ sender: UISwitch) { settings.set(sender.isOn, forKey: "regress_ghost_noonline") }
    @objc private func toggleGhostStories(_ sender: UISwitch) { settings.set(sender.isOn, forKey: "regress_ghost_stories") }
    @objc private func toggleAntiRecall(_ sender: UISwitch) { settings.set(sender.isOn, forKey: "regress_antirecall_active") }
    @objc private func toggleAntiRecallBadge(_ sender: UISwitch) { settings.set(sender.isOn, forKey: "regress_antirecall_badge") }
    @objc private func toggleEditHistory(_ sender: UISwitch) { settings.set(sender.isOn, forKey: "regress_edit_history") }
    @objc private func toggleSaveSelfDestruct(_ sender: UISwitch) { settings.set(sender.isOn, forKey: "regress_save_selfdestruct") }
    @objc private func toggleHideStoriesTab(_ sender: UISwitch) { settings.set(sender.isOn, forKey: "regress_hide_stories_tab") }
    @objc private func toggleHideContactsTab(_ sender: UISwitch) { settings.set(sender.isOn, forKey: "regress_hide_contacts_tab") }
    @objc private func toggleStreamerMode(_ sender: UISwitch) { settings.set(sender.isOn, forKey: "regress_streamer_mode") }
    @objc private func toggleSpeedBooster(_ sender: UISwitch) { settings.set(sender.isOn, forKey: "regress_speed_booster") }
    @objc private func toggleUnblockScreenshots(_ sender: UISwitch) { settings.set(sender.isOn, forKey: "regress_unblock_screenshots") }
    
    @objc private func toggleLocalPremium(_ sender: UISwitch) {
        settings.set(sender.isOn, forKey: "regress_local_premium")
        let alert = UIAlertController(title: "Локальный Premium", message: "Пожалуйста, полностью перезапустите приложение для применения изменений.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "ОК", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Pickers
    
    private func presentThemePicker() {
        let alert = UIAlertController(title: "Выберите цветовую палитру", message: "Вы можете выбрать один из готовых пресетов или создать свой цвет с помощью HSL слайдеров.", preferredStyle: .actionSheet)
        
        for theme in AyuThemeManager.themePresets {
            alert.addAction(UIAlertAction(title: theme["name"], style: .default, handler: { _ in
                self.settings.set(theme["hsl"], forKey: "regress_theme_hsl")
                self.tableView.reloadData()
            }))
        }
        
        alert.addAction(UIAlertAction(title: "🎨 Свой цвет (HSL Слайдер)", style: .destructive, handler: { _ in
            let picker = RegressColorPickerViewController()
            self.navigationController?.pushViewController(picker, animated: true)
        }))
        
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
    }
    
    private func presentFontPicker() {
        let alert = UIAlertController(title: "Выберите шрифт интерфейса", message: "Шрифт будет применен ко всем надписям в клиенте.", preferredStyle: .actionSheet)
        let fonts = ["Системный", "Outfit", "Inter", "Outfit SemiBold", "Courier New"]
        for font in fonts {
            alert.addAction(UIAlertAction(title: font, style: .default, handler: { _ in
                self.settings.set(font, forKey: "regress_active_font")
                self.tableView.reloadData()
            }))
        }
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
    }
    
    private func presentIconPicker() {
        let alert = UIAlertController(title: "Выберите иконку приложения", message: "Эти премиальные простые иконки заменят стандартную.", preferredStyle: .actionSheet)
        let icons = ["Regress Default", "Dark Premium", "Gold Gradient", "Neon Regress"]
        for icon in icons {
            alert.addAction(UIAlertAction(title: icon, style: .default, handler: { _ in
                self.settings.set(icon, forKey: "regress_app_icon")
                self.changeAppIcon(named: icon)
                self.tableView.reloadData()
            }))
        }
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
    }
    
    private func changeAppIcon(named iconName: String) {
        let supportsKey = "supportsAlternateAppIcons"
        guard let supports = UIApplication.shared.value(forKey: supportsKey) as? Bool, supports else { return }
        let apiName = (iconName == "Regress Default") ? nil : iconName.replacingOccurrences(of: " ", with: "_").lowercased()
        UIApplication.shared.perform(Selector(("setAlternateIconName:")), with: apiName)
    }
    
    private func presentBadgePicker() {
        let alert = UIAlertController(title: "Кастомный значок профиля", message: "Этот значок будет отображаться рядом с вашим именем в чатах.", preferredStyle: .actionSheet)
        let badges = ["Без значка", "Корона 👑", "Щит разработчика 🛡️", "Призрак 👻", "Молния ⚡", "Синяя звезда ⭐"]
        for badge in badges {
            alert.addAction(UIAlertAction(title: badge, style: .default, handler: { _ in
                self.settings.set(badge, forKey: "regress_profile_badge")
                self.tableView.reloadData()
            }))
        }
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
    }
    
    private func confirmClearCache() {
        let alert = UIAlertController(title: "Очистить кэш?", message: "Это удалит всю локальную историю удаленных сообщений без возможности восстановления.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Удалить", style: .destructive, handler: { _ in
            AyuMessageTracker.shared.clearAllCache()
        }))
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
    }
    
    private func confirmResetSettings() {
        let alert = UIAlertController(title: "Сбросить все настройки?", message: "Все настройки Regress будут сброшены к значениям по умолчанию.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Сбросить", style: .destructive, handler: { _ in
            let keys = [
                "regress_ghost_master", "regress_ghost_noread", "regress_ghost_notyping", "regress_ghost_noonline", "regress_ghost_stories",
                "regress_antirecall_active", "regress_antirecall_badge", "regress_edit_history", "regress_save_selfdestruct",
                "regress_theme_hsl", "regress_active_font", "regress_app_icon", "regress_profile_badge",
                "regress_local_premium", "regress_streamer_mode", "regress_speed_booster", "regress_unblock_screenshots",
                "regress_hide_stories_tab", "regress_hide_contacts_tab"
            ]
            for key in keys {
                self.settings.removeObject(forKey: key)
            }
            self.tableView.reloadData()
        }))
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
    }
}

// MARK: - RegressDeletedHistoryViewController (Displays Local Chat Deleted History)

@objc public class RegressDeletedHistoryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private var tableView: UITableView!
    private var deletedMessages: [[String: Any]] = []
    @objc public var chatId: Int64 = 0
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Удаленные сообщения"
        self.view.backgroundColor = .systemGroupedBackground
        
        tableView = UITableView(frame: self.view.bounds, style: .insetGrouped)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        self.view.addSubview(tableView)
        
        // Add "Clear" option in header
        let clearBtn = UIBarButtonItem(title: "Очистить", style: .plain, target: self, action: #selector(clearHistory))
        self.navigationItem.rightBarButtonItem = clearBtn
        
        loadDeletedMessages()
    }
    
    private func loadDeletedMessages() {
        deletedMessages = AyuMessageTracker.shared.getDeletedMessages(forChatId: chatId)
        tableView.reloadData()
        
        if deletedMessages.isEmpty {
            let label = UILabel()
            label.text = "Удаленных сообщений пока нет 🤷‍♂️"
            label.font = UIFont.systemFont(ofSize: 15, weight: .medium)
            label.textColor = .secondaryLabel
            label.textAlignment = .center
            label.frame = self.view.bounds
            tableView.backgroundView = label
        } else {
            tableView.backgroundView = nil
        }
    }
    
    @objc private func clearHistory() {
        let alert = UIAlertController(title: "Очистить историю?", message: "Это удалит удаленные сообщения для этого чата локально.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Очистить", style: .destructive, handler: { _ in
            AyuMessageTracker.shared.clearAllCache() // Simple complete clear
            self.loadDeletedMessages()
        }))
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
    }
    
    // MARK: - Table View Data Source
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return deletedMessages.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "HistoryCell")
        cell.backgroundColor = .secondarySystemGroupedBackground
        
        let item = deletedMessages[indexPath.row]
        let sender = item["senderName"] as? String ?? "Пользователь"
        let text = item["text"] as? String ?? ""
        let dateVal = item["date"] as? Int32 ?? 0
        
        // Format Date
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .short
        let dateString = formatter.string(from: Date(timeIntervalSince1970: TimeInterval(dateVal)))
        
        cell.textLabel?.text = "\(sender)   [\(dateString)]"
        cell.textLabel?.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        cell.textLabel?.textColor = .secondaryLabel
        
        cell.detailTextLabel?.text = text
        cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        cell.detailTextLabel?.textColor = .label
        cell.detailTextLabel?.numberOfLines = 0
        
        // Add subtle deleted trash bin
        let trashView = UILabel()
        trashView.text = "🗑️"
        trashView.sizeToFit()
        cell.accessoryView = trashView
        
        return cell
    }
}

// MARK: - RegressColorPickerViewController (Interactive HSL Color Sliders)

public class RegressColorPickerViewController: UIViewController {
    
    private let settings = UserDefaults.standard
    private let colorPreview = UIView()
    
    private let hueSlider = UISlider()
    private let satSlider = UISlider()
    private let lightSlider = UISlider()
    
    private let hueValLabel = UILabel()
    private let satValLabel = UILabel()
    private let lightValLabel = UILabel()
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Создать свой цвет"
        self.view.backgroundColor = .systemGroupedBackground
        
        var h: Float = 200, s: Float = 80, l: Float = 50
        let currentHSL = settings.string(forKey: "regress_theme_hsl") ?? "200,80%,50%"
        let comps = currentHSL.components(separatedBy: ",")
        if comps.count == 3 {
            h = Float(comps[0]) ?? 200
            s = Float(comps[1].replacingOccurrences(of: "%", with: "")) ?? 80
            l = Float(comps[2].replacingOccurrences(of: "%", with: "")) ?? 50
        }
        
        setupUI()
        
        hueSlider.value = h
        satSlider.value = s
        lightSlider.value = l
        
        updateColorPreview()
    }
    
    private func setupUI() {
        colorPreview.translatesAutoresizingMaskIntoConstraints = false
        colorPreview.layer.cornerRadius = 60
        colorPreview.layer.shadowColor = UIColor.black.cgColor
        colorPreview.layer.shadowOpacity = 0.25
        colorPreview.layer.shadowRadius = 8
        colorPreview.layer.shadowOffset = CGSize(width: 0, height: 4)
        self.view.addSubview(colorPreview)
        
        setupSliderRow(slider: hueSlider, label: hueValLabel, name: "Оттенок (Hue)", minVal: 0, maxVal: 360, yOffset: 250)
        setupSliderRow(slider: satSlider, label: satValLabel, name: "Насыщенность (Sat)", minVal: 0, maxVal: 100, yOffset: 340)
        setupSliderRow(slider: lightSlider, label: lightValLabel, name: "Яркость (Light)", minVal: 10, maxVal: 90, yOffset: 430)
        
        hueSlider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
        satSlider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
        lightSlider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
        
        let saveBtn = UIButton(type: .system)
        saveBtn.setTitle("Применить цвет", for: .normal)
        saveBtn.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        saveBtn.backgroundColor = self.view.tintColor
        saveBtn.setTitleColor(.white, for: .normal)
        saveBtn.layer.cornerRadius = 14
        saveBtn.translatesAutoresizingMaskIntoConstraints = false
        saveBtn.addTarget(self, action: #selector(saveColor), for: .touchUpInside)
        self.view.addSubview(saveBtn)
        
        NSLayoutConstraint.activate([
            colorPreview.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            colorPreview.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 40),
            colorPreview.widthAnchor.constraint(equalToConstant: 120),
            colorPreview.heightAnchor.constraint(equalToConstant: 120),
            
            saveBtn.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            saveBtn.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            saveBtn.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.8),
            saveBtn.heightAnchor.constraint(equalToConstant: 54)
        ])
    }
    
    private func setupSliderRow(slider: UISlider, label: UILabel, name: String, minVal: Float, maxVal: Float, yOffset: CGFloat) {
        let titleLabel = UILabel()
        titleLabel.text = name
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        titleLabel.textColor = .secondaryLabel
        titleLabel.frame = CGRect(x: 30, y: yOffset, width: 200, height: 20)
        self.view.addSubview(titleLabel)
        
        slider.minimumValue = minVal
        slider.maximumValue = maxVal
        slider.frame = CGRect(x: 30, y: yOffset + 25, width: self.view.frame.width - 120, height: 30)
        self.view.addSubview(slider)
        
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .label
        label.textAlignment = .right
        label.frame = CGRect(x: self.view.frame.width - 80, y: yOffset + 28, width: 50, height: 20)
        self.view.addSubview(label)
    }
    
    @objc private func sliderChanged() {
        updateColorPreview()
    }
    
    private func updateColorPreview() {
        let h = CGFloat(hueSlider.value)
        let s = CGFloat(satSlider.value)
        let l = CGFloat(lightSlider.value)
        
        hueValLabel.text = "\(Int(hueSlider.value))°"
        satValLabel.text = "\(Int(satSlider.value))%"
        lightValLabel.text = "\(Int(lightSlider.value))%"
        
        colorPreview.backgroundColor = UIColor(hue: h / 360.0, saturation: s / 100.0, brightness: l / 100.0, alpha: 1.0)
    }
    
    @objc private func saveColor() {
        let hslString = "\(Int(hueSlider.value)),\(Int(satSlider.value))%,\(Int(lightSlider.value))%"
        settings.set(hslString, forKey: "regress_theme_hsl")
        self.navigationController?.popViewController(animated: true)
    }
}
