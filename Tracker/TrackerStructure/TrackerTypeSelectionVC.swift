import UIKit

// MARK: - TrackerTypeSelectionDelegate

protocol TrackerTypeSelectionDelegate: AnyObject {
    func didSelectTrackerType(_ type: TrackerType)
}

// MARK: - Enums

enum TrackerType {
    case habit
    case irregularEvent
}

// MARK: - TrackerTypeSelection

final class TrackerTypeSelectionViewController: UIViewController {
    
    // MARK: - Public Properties
    
    weak var delegate: TrackerTypeSelectionDelegate?
    
    // MARK: - Private Properties
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Создание трекера"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        return label
    }()
    
    private lazy var habitButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle ("Привычка", for: .normal)
        button.setTitleColor(.ypWhite, for: .normal)
        button.backgroundColor = .ypBlack
        button.layer.cornerRadius = 16
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.heightAnchor.constraint(equalToConstant: 60).isActive = true
        button.addTarget(
            self,
            action: #selector(habitButtonTapped),
            for: .touchUpInside)
        return button
    }()
    
    private lazy var irregularEventButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Нерегулярные событие", for: .normal)
        button.setTitleColor(.ypWhite, for: .normal)
        button.backgroundColor = .ypBlack
        button.layer.cornerRadius = 16
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.heightAnchor.constraint(equalToConstant: 60).isActive = true
        button.addTarget(
            self,
            action: #selector(irregularEventButtonTapped),
            for: .touchUpInside)
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .ypWhite
        setupUI()
        setupConstraints()
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        [titleLabel, habitButton, irregularEventButton].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 38),
            
            habitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            habitButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            habitButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            habitButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            irregularEventButton.topAnchor.constraint(equalTo: habitButton.bottomAnchor, constant: 16),
            irregularEventButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            irregularEventButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            irregularEventButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    private func setupAppearance() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        view.backgroundColor = isDarkMode ? .ypBlack : .ypWhite
        titleLabel.textColor = isDarkMode ? .ypWhite : .ypBlack
        habitButton.backgroundColor = isDarkMode ? .ypWhite : .ypBlack
        habitButton.setTitleColor(isDarkMode ? .ypBlack : .ypWhite, for: .normal)
        irregularEventButton.backgroundColor = isDarkMode ? .ypWhite : .ypBlack
        irregularEventButton.setTitleColor(isDarkMode ? .ypBlack : .ypWhite, for: .normal)
    }
    
    // MARK: - Private Methods
    
    private func showCreateTrackerScreen(with type: TrackerType) {
//        let createTrackerVC = TrackerCreationViewController()
//        createTrackerVC.trackerType = type
//        createTrackerVC.modalPresentationStyle = .fullScreen
//        present(createTrackerVC, animated: true, completion: nil)
    }
    
    // MARK: - Actions
    
    @objc private func habitButtonTapped() {
        delegate?.didSelectTrackerType(.habit)
        showCreateTrackerScreen(with: .habit)
    }
    
    @objc private func irregularEventButtonTapped() {
        delegate?.didSelectTrackerType(.irregularEvent)
        showCreateTrackerScreen(with: .irregularEvent)
    }
}
