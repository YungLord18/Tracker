import UIKit

final class TrackersViewController: UIViewController, TrackerCategoryDelegate, TrackerStoreDelegate {

    // MARK: - Public Properties
    
    var trackerStore = TrackerStore()
    var trackerRecordStore = TrackerRecordStore()
    var trackerCategoryStore = TrackerCategoryStore()
    
//    var categories: [TrackerCategory] = []
//    var completedTrackers: [TrackerRecord] = []
//    var trackers: [Tracker] = []
    //var records: [TrackerRecord] = []
    
    var currentDate: Date = Date()
    let dataManager = TrackerDataManager.shared
    
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yy"
        return formatter
    }()
    
    // MARK: - Private Properties
    
    private(set) var visibleCategories: [TrackerCategory] = []
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Трекеры"
        label.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        return label
    }()
    
    private lazy var addButton: UIBarButtonItem = {
        let button = UIBarButtonItem(
            image: UIImage(named: "PlusButton"),
            style: .plain,
            target: self,
            action: #selector(addTracker))
        button.tintColor = .ypBlack
        return button
    }()
    
    private lazy var datePicker: UIBarButtonItem = {
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.locale = Locale.current
        datePicker.preferredDatePickerStyle = .compact
        datePicker.addTarget(
            self,
            action: #selector(datePickerValueChanged(_:)),
            for: .valueChanged)
        return UIBarButtonItem(customView: datePicker)
    }()
    
    private lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Поиск"
        searchBar.backgroundImage = UIImage()
        return searchBar
    }()
    
    private lazy var trackingLabel: UILabel = {
        let label = UILabel()
        label.text = "Что будем отслеживать?"
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textAlignment = .center
        return label
    }()
    
    private lazy var errorImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "ErrorStar"))
        return imageView
    }()
    
    private lazy var errorFilterImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "ErrorFillter"))
        return imageView
    }()
    
    private lazy var filterLabel: UILabel = {
        let label = UILabel()
        label.text = "Ничего не найдено"
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var filtersButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Фильтры", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .ypBlue
        button.layer.cornerRadius = 16
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        button.addTarget(
            self,
            action: #selector(didTapFiltersButton),
            for: .touchUpInside)
        return button
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .ypWhite
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(TrackerCell.self, forCellWithReuseIdentifier: "TrackerCell")
        collectionView.register(TrackerSectionHeader.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: "TrackerSectionHeader")
        return collectionView
    }()
    
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .ypWhite
        
        trackerStore.delegate = self
        trackerCategoryStore.delegate = self
        searchBar.delegate = self
        //trackerStore.loadCategories(for: Date(), dateFormatter: dateFormatter)
        trackerCategoryStore.loadCategories(for: Date(), dateFormatter: dateFormatter)
        trackerRecordStore.loadCompletedTrackers()
        
        setupUI()
        setupConstraints()
        setupNavigationBar()
        visibleCategories = trackerCategoryStore.categories
        updateTrackersView()

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    //MARK: - Public Methods
    
    func updateTrackersView() {
        if !trackerCategoryStore.categories.isEmpty {
            let trackers = trackerStore.trackers
            _ = trackers.filter {
                trackerStore.shouldDisplayTracker($0, forDate: currentDate, dateFormatter: dateFormatter)
            }
            if let searchText = searchBar.text,!searchText.isEmpty {
                visibleCategories = filterTrackersSearchBar(by: searchText, from: trackerCategoryStore.categories)
            } else {
                visibleCategories = trackerCategoryStore.categories
            }
            let hasTrackers = !visibleCategories.flatMap { $0.trackers }.isEmpty
            let isSearchActive = searchBar.text?.isEmpty == false
            errorImageView.isHidden = hasTrackers || isSearchActive
            trackingLabel.isHidden = hasTrackers || isSearchActive
            errorFilterImageView.isHidden = hasTrackers || !isSearchActive
            filterLabel.isHidden = hasTrackers || !isSearchActive
            filtersButton.isHidden = !hasTrackers
            collectionView.isHidden = !hasTrackers
            collectionView.reloadData()
        }
    }
    
    func trackerCategoryStore(_ trackerCategoryStore: TrackerCategoryStore,
                              didLoadCategories categories: [TrackerCategory]) {
        if !categories.isEmpty {
            //self.categories = categories
            updateTrackersView()
        }
    }
    
    func trackerStore(_ trackerStore: TrackerStore,
                      didLoadCategories categories: [TrackerCategory]) {
        if !categories.isEmpty {
            //self.categories = categories
            updateTrackersView()
        }
    }
    
    func trackerStore(_ trackerStore: TrackerStore,
                      didLoadTrackers trackers: [Tracker]) {
        //self.trackers = trackers
        updateTrackersView()
    }
    
    func trackerStore(_ trackerStore: TrackerStore,
                      didLoadCompletedTrackers completedTrackers: [TrackerRecord]) {
       // self.completedTrackers = completedTrackers
        updateTrackersView()
    }

    func filterTrackersSearchBar(by searchText: String, from categories: [TrackerCategory]) -> [TrackerCategory] {
        return categories.map { category in
            let filteredTrackers = category.trackers.filter { tracker in
                return tracker.name.lowercased().contains(searchText.lowercased())
            }
            return TrackerCategory(title: category.title, trackers: filteredTrackers)
        }.filter { !$0.trackers.isEmpty }
    }
    
    func filterTrackers(to categories: [TrackerCategory]) {
        visibleCategories = categories
        let allTrackers = trackerCategoryStore.categories.flatMap { $0.trackers }
        let hasCreatedTrackers = !allTrackers.isEmpty
        let hasTrackers = !visibleCategories.flatMap { $0.trackers }.isEmpty
        errorFilterImageView.isHidden = hasTrackers || !hasCreatedTrackers
        filterLabel.isHidden = hasTrackers || !hasCreatedTrackers
        collectionView.isHidden = !hasTrackers
        collectionView.reloadData()
    }
    
    func presentEditTrackerViewController(for tracker: Tracker) {
        let editTrackerViewController = TrackerCreationViewController()
        editTrackerViewController.trackerToEdit = tracker
        editTrackerViewController.delegate = self
        present(editTrackerViewController, animated: true, completion: nil)
    }
    
    func handleDeleteTracker(_ tracker: Tracker) {
        let alertController = UIAlertController(
            title: nil,
            message: "Уверенны что хотите удалить трекер?",
            preferredStyle: .actionSheet
        )
        let deleteAction = UIAlertAction(
            title: "Удалить",
            style: .destructive
        ) { [weak self] _ in
            guard let self = self else { return }
            let currentDate = self.currentDate
            let dateFormatter = self.dateFormatter
            self.trackerRecordStore.deleteTracker(withId: tracker.id, for: currentDate, dateFormatter: dateFormatter)
            self.updateTrackersView()
        }
        let cancelAction = UIAlertAction(
            title: "Отменить",
            style: .destructive,
            handler: nil
        )
        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - Private Methods
    
    private func setupUI() {
        [titleLabel, searchBar, errorImageView, trackingLabel,
         errorFilterImageView, filterLabel, collectionView, filtersButton].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            searchBar.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 7),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            searchBar.heightAnchor.constraint(equalToConstant: 36),
            
            errorImageView.widthAnchor.constraint(equalToConstant: 80),
            errorImageView.heightAnchor.constraint(equalToConstant: 80),
            errorImageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 402),
            errorImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            trackingLabel.topAnchor.constraint(equalTo: errorImageView.bottomAnchor, constant: 8),
            trackingLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            trackingLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            trackingLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            trackingLabel.heightAnchor.constraint(equalToConstant: 18),
            
            errorFilterImageView.widthAnchor.constraint(equalToConstant: 80),
            errorFilterImageView.heightAnchor.constraint(equalToConstant: 80),
            errorFilterImageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 402),
            errorFilterImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            filterLabel.topAnchor.constraint(equalTo: errorFilterImageView.bottomAnchor, constant: 8),
            filterLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            filterLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            filterLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            filterLabel.heightAnchor.constraint(equalToConstant: 40),
            
            collectionView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 24),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            collectionView.bottomAnchor.constraint(equalTo: filtersButton.topAnchor, constant: -16),
            
            filtersButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            filtersButton.widthAnchor.constraint(equalToConstant: 114),
            filtersButton.heightAnchor.constraint(equalToConstant: 50),
            filtersButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }
    
    private func setupNavigationBar() {
        navigationItem.leftBarButtonItems = [addButton]
        navigationItem.rightBarButtonItems = [datePicker]
    }
    
    // MARK: - Actions
    
    @objc private func addTracker() {
        let trackerTypeSelectionVC = TrackerTypeSelectionViewController()
        trackerTypeSelectionVC.delegate = self
        present(trackerTypeSelectionVC, animated: true, completion: nil)
    }
    
    @objc private func datePickerValueChanged(_ sender: UIDatePicker) {
        currentDate = sender.date
        updateTrackersView()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yy"
        let formattedDate = dateFormatter.string(from: currentDate)
        print("Выбранная дата: \(formattedDate)")
    }
    
    @objc private func didTapFiltersButton() {}
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
}
