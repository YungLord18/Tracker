import UIKit

//MARK: - Enum

enum WeekDay: String, CaseIterable {
    case monday = "Monday"
    case tuesday = "Tuesday"
    case wednesday = "Wednesday"
    case thursday = "Thursday"
    case friday = "Friday"
    case saturday = "Saturday"
    case sunday = "Sunday"
    
    func localizedString() -> String {
        switch self {
        case .monday:
            return ("Понедельник")
        case .tuesday:
            return ("Вторник")
        case .wednesday:
            return ("Среда")
        case .thursday:
            return ("Четверг")
        case .friday:
            return ("Пятница")
        case .saturday:
            return ("Суббота")
        case .sunday:
            return ("Воскресенье")
        }
    }
}

//MARK: - TrackerScheduleVC

final class TrackerScheduleVC: UIViewController {
    
    // MARK: - Identifier
    
    static let cellIdentifier = "TrackerScheduleCell"
    
    //MARK: - Public Properties
    
    var selectedDays: [WeekDay] = []
    var daySelectionHandler: (([WeekDay]) -> Void)?
    
    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.layer.cornerRadius = 16
        tableView.separatorColor = .ypGray
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .ypWhite
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: TrackerScheduleVC.cellIdentifier)
        return tableView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Расписание"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        return label
    }()
    
    private lazy var saveButton: UIButton = {
        let button = UIButton()
        button.setTitle("Готово", for: .normal)
        button.layer.cornerRadius = 16
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .ypBlack
        button.setTitleColor(.ypWhite, for: .normal)
        button.heightAnchor.constraint(equalToConstant: 60).isActive = true
        button.addTarget(
            self,
            action: #selector(saveButtonTapped),
            for: .touchUpInside)
        return button
    }()
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .ypWhite
        setupUI()
        setupConstraints()
    }
    
    //MARK: - Private Methods
    
    private func setupUI() {
        [tableView, titleLabel, saveButton].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 38),
            titleLabel.heightAnchor.constraint(equalToConstant: 22),
            
            saveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            saveButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
            
            tableView.heightAnchor.constraint(equalToConstant: 525),
            tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 50),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }
    
    //MARK: - @Objc
    
    @objc private func saveButtonTapped() {
        daySelectionHandler?(selectedDays)
        dismiss(animated: true, completion: nil)
    }
}
