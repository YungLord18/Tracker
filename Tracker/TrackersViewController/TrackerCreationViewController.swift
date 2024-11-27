import UIKit

protocol TrackerCreationDelegate: AnyObject {
    func didCreateTracker(_ tracker: Tracker, inCategory category: String)
}

final class TrackerCreationViewController: UIViewController, UITextFieldDelegate {
    
    //MARK: - Public Properties
    
    weak var delegate: TrackerCreationDelegate?
    
    var trackerType: TrackerType?
    var trackerToEdit: Tracker?
    var selectedCategory: String?
    var selectedEmoji: String?
    var selectedColor: UIColor?
    
    let colors: [UIColor] = [
        .ypSelection1, .ypSelection2, .ypSelection3,
        .ypSelection4, .ypSelection5, .ypSelection6,
        .ypSelection7, .ypSelection8, .ypSelection9,
        .ypSelection10, .ypSelection11, .ypSelection12,
        .ypSelection13, .ypSelection14, .ypSelection15,
        .ypSelection16, .ypSelection17, .ypSelection18
    ]
    
    let emoji: [String] = [
        "🙂", "😻", "🌺", "🐶", "❤️", "😱",
        "😇", "😡", "🥶", "🤔", "🙌", "🍔",
        "🥦", "🏓", "🥇", "🎸", "🌴", "😪"
    ]
    
    lazy var emojiCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = .ypWhite
        
        return collectionView
    }()
    
    //MARK: - Private Properties
    
    private var selectedDays: [WeekDay] = []
    private var dataManager = TrackerDataManager.shared
    private let trackerStore = TrackerStore()
    private var recordDay = 0
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Новая привычка"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        return label
    }()
    
    private lazy var completedDaysLabel: UILabel = {
        let label = UILabel()
        let localizedDays = String(format: "%d", recordDay)
        label.text = localizedDays
        label.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        label.textColor = .ypBlack
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.heightAnchor.constraint(equalToConstant: 38).isActive = true
        return label
    }()
    
    private lazy var nameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Введите название трекера"
        textField.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        textField.backgroundColor = .ypBackgroundDay
        textField.layer.cornerRadius = 16
        textField.heightAnchor.constraint(equalToConstant: 75).isActive = true
        let leftPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: textField.frame.height))
        textField.leftView = leftPaddingView
        textField.leftViewMode = .always
        textField.delegate = self
        return textField
    }()
    
    private lazy var categoriesButton: UIButton = {
        let button = createRoundedButton(
            title: "Категория",
            action: #selector(categoriesButtonTapped),
            corners: [.topLeft, .topRight],
            radius: 16)
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.textAlignment = .left
        button.contentHorizontalAlignment = .left
        return button
    }()
    
    private lazy var scheduleButton: UIButton = {
        let button = createRoundedButton(
            title: "Расписание",
            action: #selector(scheduleButtonTapped),
            corners: [.topLeft, .topRight],
            radius: 16)
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.textAlignment = .left
        button.contentHorizontalAlignment = .left
        return button
    }()
    
    private lazy var separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .ypGray
        view.heightAnchor.constraint(equalToConstant: 0.2).isActive = true
        return view
    }()
    
    private lazy var emojiLabel: UILabel = {
        let label = UILabel()
        label.text = "Emoji"
        label.font = .systemFont(ofSize: 19, weight: .bold)
        label.backgroundColor = .ypWhite
        label.textColor = .ypBlack
        return label
    }()
    
    private lazy var colorLabel: UILabel = {
        let label = UILabel()
        label.text = "Цвет"
        label.font = .systemFont(ofSize: 19, weight: .bold)
        label.backgroundColor = .ypWhite
        label.textColor = .ypBlack
        return label
    }()
    
    private lazy var colorCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .ypWhite
        return collectionView
    }()
    
    private lazy var cancelButton: UIButton = {
        let button = UIButton()
        button.setTitle("Отменить", for: .normal)
        button.layer.cornerRadius = 16
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.ypRed.cgColor
        button.setTitleColor(.ypRed, for: .normal)
        button.backgroundColor = .clear
        button.heightAnchor.constraint(equalToConstant: 60).isActive = true
        button.addTarget(
            self,
            action: #selector(cancelButtonTapped),
            for: .touchUpInside)
        return button
    }()
    
    private lazy var saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Создать", for: .normal)
        button.layer.cornerRadius = 16
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .ypGray
        button.setTitleColor(.ypWhite, for: .normal)
        button.heightAnchor.constraint(equalToConstant: 60).isActive = true
        button.addTarget(
            self,
            action: #selector(saveButtonTapped),
            for: .touchUpInside)
        return button
    }()
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private lazy var stackViewButtom: UIStackView = {
        let stackViewButtom = UIStackView()
        stackViewButtom.axis = .horizontal
        stackViewButtom.translatesAutoresizingMaskIntoConstraints = false
        return stackViewButtom
    }()
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .ypWhite
        setupUI()
        setupConstraints()
        updateLayoutForTrackerType()
        updateButtonStates()
        
        emojiCollectionView.register(EmojiCell.self, forCellWithReuseIdentifier: EmojiCell.reuseIdentifier)
        colorCollectionView.register(ColorCell.self, forCellWithReuseIdentifier: ColorCell.reuseIdentifier)
        
        trackerStore.delegate = self
        trackerStore.loadCategories(for: Date(), dateFormatter: DateFormatter())

        if let tracker = trackerToEdit,
           let categoryTitle = TrackerCategoryStore().getCategoryForTracker(trackerId: tracker.id) {
            setupForEditing(tracker: tracker, category: categoryTitle)
        }
    }
    
    init() {
        self.dataManager = TrackerDataManager.shared
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Public Methods
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        updateSaveButtonState()
        return true
    }
    
    func updateSaveButtonState() {
        let isNameFilled = !(nameTextField.text?.isEmpty ?? true)
        let isCategorySelected = selectedCategory != nil
        let isEmojiSelected = selectedEmoji != nil
        let isColorSelected = selectedColor != nil
        if isNameFilled && isCategorySelected && isEmojiSelected && isColorSelected {
            saveButton.isEnabled = true
            saveButton.backgroundColor = .ypBlack
        } else {
            saveButton.isEnabled = false
            saveButton.backgroundColor = .ypGray
        }
    }
    
    //MARK: - Private Methods
    
    private func setupUI() {
        [scrollView].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        [stackView].forEach {
            scrollView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        [cancelButton, saveButton].forEach {
            stackViewButtom.addArrangedSubview($0)
        }
        
        let arrangedSubviews: [UIView] = [
            titleLabel,
            createSpacingView(height: 24),
            nameTextField,
            createSpacingView(height: 24),
            categoriesButton,
            separatorView,
            scheduleButton,
            createSpacingView(height: 32),
            emojiLabel,
            createSpacingView(height: 16),
            emojiCollectionView,
            createSpacingView(height: 16),
            colorLabel,
            createSpacingView(height: 16),
            colorCollectionView,
            stackViewButtom]
        arrangedSubviews.forEach { stackView.addArrangedSubview($0) }
        
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .fill
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
        ])
        
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: stackView.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: stackView.topAnchor, constant: 38),
            
            nameTextField.leadingAnchor.constraint(equalTo: stackView.leadingAnchor, constant: 16),
            nameTextField.trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: -16)
        ])
        
        NSLayoutConstraint.activate([
            categoriesButton.leadingAnchor.constraint(equalTo: stackView.leadingAnchor, constant: 16),
            categoriesButton.trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: -16),
            
            separatorView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor, constant: 32),
            separatorView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: -32),
            
            scheduleButton.leadingAnchor.constraint(equalTo: stackView.leadingAnchor, constant: 16),
            scheduleButton.trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: -16)
        ])
        
        NSLayoutConstraint.activate([
            emojiLabel.leadingAnchor.constraint(equalTo: stackView.leadingAnchor, constant: 28),
            
            emojiCollectionView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor, constant: 16),
            emojiCollectionView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: -16),
            emojiCollectionView.heightAnchor.constraint(equalToConstant: calculateCellSize())
        ])
        
        NSLayoutConstraint.activate([
            colorLabel.leadingAnchor.constraint(equalTo: stackView.leadingAnchor, constant: 28),
            
            colorCollectionView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor, constant: 16),
            colorCollectionView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: -16),
            colorCollectionView.heightAnchor.constraint(equalToConstant: calculateCellSize())
        ])
        
        NSLayoutConstraint.activate([
            stackViewButtom.leadingAnchor.constraint(equalTo: stackView.leadingAnchor, constant: 20),
            stackViewButtom.trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: -20),
            stackViewButtom.bottomAnchor.constraint(equalTo: stackView.bottomAnchor, constant: -20),
            stackViewButtom.heightAnchor.constraint(equalToConstant: 60),
            
            cancelButton.trailingAnchor.constraint(equalTo: saveButton.leadingAnchor, constant: -8),
            cancelButton.widthAnchor.constraint(equalTo: saveButton.widthAnchor),
            
            saveButton.trailingAnchor.constraint(equalTo: stackViewButtom.trailingAnchor),
            saveButton.bottomAnchor.constraint(equalTo: stackViewButtom.bottomAnchor)
        ])
    }
    
    private func setupForEditing(tracker: Tracker, category: String) {
        titleLabel.text = "Введите название трекера"
        let trackerRecordStore = TrackerRecordStore()
        trackerRecordStore.loadRecords(for: tracker)
        let completedTrackers = trackerRecordStore.completedTrackers
        let uniqueDates = Set(completedTrackers.map { $0.date })
        recordDay = uniqueDates.count
        nameTextField.text = tracker.name
        selectedEmoji = tracker.emoji
        selectedColor = tracker.color
        selectedDays = tracker.schedule.compactMap { WeekDay(rawValue: $0) }
        if selectedDays.isEmpty {
            trackerType = .irregularEvent
            scheduleButton.isHidden = true
            separatorView.isHidden = true
            updateCategoriesButtonCorners(.allCorners, radius: 16)
        } else {
            trackerType = .habit
            scheduleButton.isHidden = false
            separatorView.isHidden = false
            updateCategoriesButtonCorners([.topLeft, .topRight], radius: 16)
        }
        updatePlainCategoriesButtonTitle(categoryTitle: category)
        updateScheduleButtonTitle()
        updateSaveButtonState()
        stackView.insertArrangedSubview(completedDaysLabel, at: 2)
        completedDaysLabel.centerXAnchor.constraint(equalTo: stackView.centerXAnchor).isActive = true
        completedDaysLabel.bottomAnchor.constraint(equalTo: nameTextField.topAnchor, constant: -40).isActive = true
    }
    
    private func updateCategoriesButtonCorners(_ corners: UIRectCorner, radius: CGFloat) {
        let buttonWidth = UIScreen.main.bounds.width - 32
        let path = UIBezierPath(
            roundedRect: CGRect(x: 0, y: 0, width: buttonWidth, height: 75),
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        categoriesButton.layer.mask = mask
        categoriesButton.backgroundColor = .ypBackgroundDay
    }
    
    private func updateCategoriesButtonTitle() {
        let titleText = NSMutableAttributedString(string: "Категория\n", attributes: [
                .font: UIFont.systemFont(ofSize: 17, weight: .regular),
                .foregroundColor: UIColor.ypBlack])
        if let categoryText = selectedCategory {
            let categoryAttributedText = NSAttributedString(string: categoryText, attributes: [
                .font: UIFont.systemFont(ofSize: 17, weight: .regular),
                .foregroundColor: UIColor.ypGray
            ])
            titleText.append(categoryAttributedText)
        }
        categoriesButton.setAttributedTitle(titleText, for: .normal)
    }
    
    private func updatePlainCategoriesButtonTitle(categoryTitle: String) {
        categoriesButton.setTitle(categoryTitle, for: .normal)
    }
    
    private func updateScheduleButtonTitle() {
        let weekDayShortNames: [WeekDay: String] = [
            .monday: "Пн",
            .tuesday: "Вт",
            .wednesday: "Ср",
            .thursday: "Чт",
            .friday: "Пт",
            .saturday: "Сб",
            .sunday: "Вс"
        ]
        let titleText = NSMutableAttributedString(string: "Расписание\n", attributes: [
                .font: UIFont.systemFont(ofSize: 17, weight: .regular),
                .foregroundColor: UIColor.ypBlack])
        var daysText: String
        if selectedDays.count == WeekDay.allCases.count {
            daysText = "Каждый день"
        } else {
            let shortNames = selectedDays.compactMap { weekDayShortNames[$0] }
            daysText = shortNames.joined(separator: ", ")
        }
        let daysAttributedText = NSAttributedString(string: daysText, attributes: [
            .font: UIFont.systemFont(ofSize: 17, weight: .regular),
            .foregroundColor: UIColor.ypGray
        ])
        titleText.append(daysAttributedText)
        scheduleButton.setAttributedTitle(titleText, for: .normal)
    }
    
    private func updateButtonStates() {
        if trackerType == .irregularEvent {
            scheduleButton.isHidden = true
            separatorView.isHidden = true
            updateCategoriesButtonCorners(.allCorners, radius: 16)
        } else {
            updateCategoriesButtonCorners([.topLeft, .topRight], radius: 16)
        }
    }
    
    private func updateLayoutForTrackerType() {
        if trackerType == .habit {
            NSLayoutConstraint.activate([
                emojiLabel.topAnchor.constraint(equalTo: scheduleButton.bottomAnchor, constant: 32)
            ])
        } else if trackerType == .irregularEvent {
            NSLayoutConstraint.activate([
                emojiLabel.topAnchor.constraint(equalTo: categoriesButton.bottomAnchor, constant: 32)
            ])
        }
    }
    
    private func createSpacingView(height: CGFloat) -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.constraint(equalToConstant: height).isActive = true
        return view
    }
    
    private func calculateCellSize() -> CGFloat {
        let width = view.frame.width
        let height: CGFloat
        let heightCell = width / 6
        height = heightCell * 3
        return height
    }
    
    
    private func createRoundedButton(
        title: String,
        action: Selector,
        corners: UIRectCorner,
        radius: CGFloat) -> UIButton {
            let button = UIButton(type: .system)
            button.setTitle(title, for: .normal)
            button.heightAnchor.constraint(equalToConstant: 75).isActive = true
            button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
            button.backgroundColor = .ypBackgroundDay
            button.setTitleColor(.ypBlack, for: .normal)
            button.contentHorizontalAlignment = .left
            button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
            button.addTarget(self, action: action, for: .touchUpInside)
            let buttonWidth = UIScreen.main.bounds.width - 32
            let path = UIBezierPath(
                roundedRect: CGRect(x: 0, y: 0, width: buttonWidth, height: 75),
                byRoundingCorners: corners,
                cornerRadii: CGSize(width: radius, height: radius))
            let mask = CAShapeLayer()
            mask.path = path.cgPath
            button.layer.mask = mask
            button.backgroundColor = .ypBackgroundDay
            let arrowImageView = UIImageView(image: UIImage(systemName: "chevron.right"))
            arrowImageView.tintColor = .ypBlack
            button.addSubview(arrowImageView)
            arrowImageView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                arrowImageView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
                arrowImageView.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -16)
            ])
            return button
        }
    
    //MARK: - @OBJC
    
    @objc private func categoriesButtonTapped() {
        let categorySelectionVC = TrackerCategoryViewController()
        categorySelectionVC.categorySelectionHandler = { [weak self] selectedCategory in
            self?.selectedCategory = selectedCategory.title
            self?.updateCategoriesButtonTitle()
            self?.updateSaveButtonState()
        }
        present(categorySelectionVC, animated: true, completion: nil)
    }
    
    @objc private func scheduleButtonTapped() {
        let scheduleVC = TrackerScheduleVC()
        scheduleVC.selectedDays = selectedDays
        scheduleVC.daySelectionHandler = { [weak self] selectedDays in
            self?.selectedDays = selectedDays
            self?.updateScheduleButtonTitle()
            self?.updateSaveButtonState()
        }
        present(scheduleVC, animated: true, completion: nil)
    }
    
    @objc private func cancelButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func saveButtonTapped() {
        guard let name = nameTextField.text, !name.isEmpty else { return }
        guard let selectedCategory = selectedCategory else { return }
        guard let selectedEmoji = selectedEmoji else { return }
        guard let selectedColor = selectedColor else { return }
        var schedule = selectedDays.map { $0.rawValue }
        if trackerType == .irregularEvent {
            schedule.append("irregularEvent")
        } else {
            schedule.append("habit")
        }
        if let trackerToEdit = trackerToEdit {
            let updatedTracker = Tracker(
                id: trackerToEdit.id,
                name: name,
                color: selectedColor,
                emoji: selectedEmoji,
                schedule: schedule)
            trackerStore.updateTracker(updatedTracker, inCategory: selectedCategory)
            delegate?.didCreateTracker(updatedTracker, inCategory: selectedCategory)
        } else {
            let newTracker = Tracker(
                id: UUID(),
                name: name,
                color: selectedColor,
                emoji: selectedEmoji,
                schedule: schedule)
            trackerStore.addTracker(newTracker, category: TrackerCategory(title: selectedCategory, trackers: []))
            delegate?.didCreateTracker(newTracker, inCategory: selectedCategory)
        }
        dismiss(animated: true, completion: nil)
    }
}

//MARK: - Tracker Store Delegate

extension TrackerCreationViewController: TrackerStoreDelegate {
    
    func trackerStore(_ trackerStore: TrackerStore, didLoadCategories categories: [TrackerCategory]) {
        self.selectedCategory = categories.first?.title
        self.updateCategoriesButtonTitle()
    }
    
    func trackerStore(_ trackerStore: TrackerStore, didLoadTrackers trackers: [Tracker]) {}
    
    func trackerStore(_ trackerStore: TrackerStore, didLoadCompletedTrackers completedTrackers: [TrackerRecord]) {}
}
