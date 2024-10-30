import UIKit

//MARK: - Tracke Cell Delegate

protocol TrackerCellDelegate: AnyObject {
    func trackerCellDidToggleCompletion(_ cell: TrackerCell, for tracker: Tracker)
    func trackerCellDidRequestEdit(_ cell: TrackerCell, for tracker: Tracker)
    func trackerCellDidRequestDelete(_ cell: TrackerCell, for tracker: Tracker)
}

//MARK: - TrackerCell

final class TrackerCell: UICollectionViewCell {
    
    //MARK: - Identifier
    
    static let trackerCellIdentifier: String = "TrackerCell"
    
    //MARK: - Public Properties
    
    weak var delegate: TrackerCellDelegate?
    
    //MARK: - Private Properties
    
    private var tracker: Tracker?
    private var completedTrackers: [TrackerRecord] = []
    private var date: String = ""
    private var dataManager: TrackerDataManager?
    
    private lazy var cardView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 16
        return view
    }()
    
    private lazy var emojiLabel: UILabel = {
        let label = UILabel()
        return label
    }()
    
    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .white
        return label
    }()
    
    private lazy var quantityView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    private lazy var completionButton: UIButton = {
        let button = UIButton(type: .system)
        let plusButton = UIImage(systemName: "PlusButton")
        button.setImage(plusButton, for: .normal)
        button.tintColor = .ypWhite
        button.backgroundColor = cardView.backgroundColor
        button.layer.cornerRadius = 17
        button.addTarget(
            self,
            action: #selector(completionButtonTapped),
            for: .touchUpInside)
        return button
    }()
    
    private lazy var countLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .ypBlack
        return label
    }()
    
    private lazy var pinView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "pin.fill")
        imageView.tintColor = .white
        imageView.isHidden = true
        return imageView
    }()
    
    //MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
        
        let interaction = UIContextMenuInteraction(delegate: self)
        cardView.addInteraction(interaction)
        
        let longPressGestureRecognizer = UILongPressGestureRecognizer(
            target: self,
            action: #selector(presentContextMenu))
        cardView.addGestureRecognizer(longPressGestureRecognizer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Public Methods
    
    func configure(with tracker: Tracker,
                   completedTrackers: [TrackerRecord],
                   dataManager: TrackerDataManager,
                   date: String) {
        self.tracker = tracker
        self.completedTrackers = completedTrackers
        self.dataManager = dataManager
        self.date = date
        cardView.backgroundColor = tracker.color
        emojiLabel.text = tracker.emoji
        nameLabel.text = tracker.name
        updateCompletionButtonSaturation(forCompletedState: isCompletedForToday())
        updatePinVisibility()
        let uniqueDates = Set(completedTrackers.map { $0.date })
        let countDays = uniqueDates.count
        let localizedDays = String.localizedStringWithFormat(
            NSLocalizedString("days_count", comment: ""),
            countDays)
        countLabel.text = localizedDays
        let configuration = UIImage.SymbolConfiguration(pointSize: 10, weight: .bold)
        let iconName = isCompletedForToday() ? "checkmark" : "plus"
        let iconImage = UIImage(systemName: iconName, withConfiguration: configuration)
        completionButton.setImage(iconImage, for: .normal)
    }
    
    func isCompletedForToday() -> Bool {
        return completedTrackers.contains { $0.trackerID == tracker?.id && $0.date == date }
    }
    
    // MARK: - Private Methods
    
    private func setupUI() {
        [cardView, quantityView, pinView].forEach {
            contentView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        [emojiLabel, nameLabel, pinView].forEach {
            cardView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        [completionButton, countLabel].forEach {
            quantityView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            cardView.heightAnchor.constraint(equalToConstant: 90),
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            emojiLabel.widthAnchor.constraint(equalToConstant: 24),
            emojiLabel.heightAnchor.constraint(equalToConstant: 24),
            emojiLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            emojiLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            
            nameLabel.heightAnchor.constraint(equalToConstant: 34),
            nameLabel.topAnchor.constraint(equalTo: emojiLabel.bottomAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            
            quantityView.heightAnchor.constraint(equalToConstant: 58),
            quantityView.topAnchor.constraint(equalTo: cardView.bottomAnchor),
            quantityView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            quantityView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            completionButton.widthAnchor.constraint(equalToConstant: 34),
            completionButton.heightAnchor.constraint(equalToConstant: 34),
            completionButton.topAnchor.constraint(equalTo: quantityView.topAnchor, constant: 8),
            completionButton.trailingAnchor.constraint(equalTo: quantityView.trailingAnchor, constant: -12),
            
            countLabel.heightAnchor.constraint(equalToConstant: 18),
            countLabel.topAnchor.constraint(equalTo: quantityView.topAnchor, constant: 16),
            countLabel.leadingAnchor.constraint(equalTo: quantityView.leadingAnchor, constant: 12),
            
            pinView.widthAnchor.constraint(equalToConstant: 12),
            pinView.heightAnchor.constraint(equalToConstant: 12),
            pinView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 18),
            pinView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
        ])
    }
    
    private func updateCompletionButtonSaturation(forCompletedState isCompleted: Bool) {
        if isCompleted {
            completionButton.backgroundColor = tracker?.color.withAlphaComponent(0.3)
        } else {
            completionButton.backgroundColor = tracker?.color
        }
    }
    
    private func updatePinVisibility() {
        pinView.isHidden = !isTrackerPinned()
    }
    
    private func isTrackerPinned() -> Bool {
        guard let tracker = tracker else { return false }
        return dataManager?.isTrackerPinned(tracker) ?? false
    }
    
    //MARK: - Actions
    
    @objc func completionButtonTapped() {
        guard let tracker = tracker else { return }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yy"
        guard let selectedDate = dateFormatter.date(from: date), selectedDate <= Date() else {
            return
        }
        if isCompletedForToday() {
            dataManager?.unmarkTrackerAsCompleted(trackerId: tracker.id, date: date)
        } else {
            dataManager?.markTrackerAsCompleted(trackerId: tracker.id, date: date)
        }
        updateCompletionButtonSaturation(forCompletedState: !isCompletedForToday())
        delegate?.trackerCellDidToggleCompletion(self, for: tracker)
    }
    
    @objc private func presentContextMenu() {
        cardView.becomeFirstResponder()
    }
}

//MARK: - UIContextMenuDelegate

extension TrackerCell: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
            guard let tracker = tracker else { return nil }
            let isPinned = dataManager?.isTrackerPinned(tracker) ?? false
            let pinActionTitle = isPinned ?
            NSLocalizedString("Unpin", comment: "Открепить") :
            NSLocalizedString("Pin", comment: "Закрепить")
            let pinAction = UIAction(title: pinActionTitle, image: UIImage(systemName: "pin")) { [weak self] _ in
                guard let self = self else { return }
                if isPinned {
                    self.dataManager?.unpinTracker(tracker)
                } else {
                    self.dataManager?.pinTracker(tracker)
                }
                self.delegate?.trackerCellDidToggleCompletion(self, for: tracker)
            }
            let editAction = UIAction(
                title: NSLocalizedString("Edit", comment: "Редактировать")) { [weak self] _ in
                    guard let self = self else { return }
                    self.delegate?.trackerCellDidRequestEdit(self, for: tracker)
                }
            let deleteAction = UIAction(
                title: NSLocalizedString("Delete", comment: "Удалить"),
                attributes: .destructive
            ) { [weak self] _ in
                guard let self = self else { return }
                self.delegate?.trackerCellDidRequestDelete(self, for: tracker)
            }
            return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
                UIMenu(title: "", children: [pinAction, editAction, deleteAction])
            }
        }
}
