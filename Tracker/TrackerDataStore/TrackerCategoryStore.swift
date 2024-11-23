import UIKit
import CoreData

//MARK: - Protocol

protocol TrackerCategoryDelegate {
    func trackerCategoryStore(_ trackerCategoryStore: TrackerCategoryStore,
                              didLoadCategories categories: [TrackerCategory])
}

//MARK: - Tracker Category Models

struct TrackerCategory {
    let title: String
    let trackers: [Tracker]
}
 
//MARK: - Final Class TrackerCategoryStore

final class TrackerCategoryStore: NSObject, NSFetchedResultsControllerDelegate {
    
    //MARK: - Public Properties
    
    var categories: [TrackerCategory] = []
    var delegate: TrackerCategoryDelegate?
    
    @NSManaged public var isPinned: Bool
    
    //MARK: - Private Properties
    
    private var context = TrackerDataManager.shared.context
    private var fetchedResultsController: NSFetchedResultsController<TrackerCoreData>?
    private let coreData: TrackerDataManager
    private var completedTrackers: [TrackerRecord] = []
    
    private(set) var pinnedTrackers: [TrackerCoreData] = []
    
    //MARK: - Initialization
    
    init(managedObjectContext: NSManagedObjectContext = TrackerDataManager.shared.context) {
        self.context = managedObjectContext
        self.coreData = TrackerDataManager.shared
        super.init()
        setupFetchedResultsController()
        pinnedTrackers = []
    }
    
    //MARK: - Public Methods
    
    func addCategory(_ category: TrackerCategory) {
        let categoryObject = TrackerCategoryCoreData(context: context)
        categoryObject.title = category.title
        saveContext()
    }
    
    func getCategory() throws -> [TrackerCategory] {
        var categories: [TrackerCategory] = []
        let request = NSFetchRequest<TrackerCategoryCoreData>(entityName: "TrackerCategoryCoreData")
        do {
            let authors = try context.fetch(request)
            authors.forEach {
                if let title = $0.title {
                    let trackers = $0.trackers?.allObjects as? [TrackerCoreData] ?? []
                    let trackerModels = trackers.map {
                        Tracker(
                            id: $0.id ?? UUID(),
                            name: $0.name ?? "",
                            color: $0.color as? UIColor ?? UIColor.black,
                            emoji: $0.emoji ?? "",
                            schedule: []
                        )
                    }
                    categories.append(TrackerCategory(title: title, trackers: trackerModels))
                } else {
                    print("Warning: TrackerCategoryCoreData object with nil title found.")
                }
            }
        } catch {
            throw error
        }
        return categories
    }
    
    func loadCategories(for date: Date, dateFormatter: DateFormatter) {
        let fetchRequest: NSFetchRequest<TrackerCategoryCoreData> = TrackerCategoryCoreData.fetchRequest()
        do {
            let fetchedCategories = try context.fetch(fetchRequest)
            let pinnedTrackerIds = Set(pinnedTrackers.compactMap { $0.id })
            self.categories = fetchedCategories.compactMap { categoryCoreData in
                let trackers = (categoryCoreData.trackers?.allObjects as? [TrackerCoreData])?.compactMap {
                    trackerCoreData in
                    let tracker = Tracker(
                        id: trackerCoreData.id ?? UUID(),
                        name: trackerCoreData.name ?? "",
                        color: trackerCoreData.color as? UIColor ?? UIColor.black,
                        emoji: trackerCoreData.emoji ?? "",
                        schedule: decodeSchedule(trackerCoreData.schedule))
                    if pinnedTrackerIds.contains(tracker.id) {
                        return nil
                    }
                    return shouldDisplayTracker(
                        tracker, forDate: date,
                        dateFormatter: dateFormatter) ? tracker : nil
                } ?? [] as [Tracker]
                return trackers.isEmpty ? nil : TrackerCategory(
                    title: categoryCoreData.title ?? "",
                    trackers: trackers)
            }
            self.categories.sort { category1, category2 in
                if category1.title == "Закрепленные" {
                    return true
                } else if category2.title == "Закрепленные" {
                    return false
                } else {
                    return category1.title < category2.title
                }
            }
            if !pinnedTrackers.isEmpty {
                let pinnedCategory = TrackerCategory(
                    title: "Закрепленные",
                    trackers: pinnedTrackers.map { trackerCoreData in
                        Tracker(
                            id: trackerCoreData.id ?? UUID(),
                            name: trackerCoreData.name ?? "",
                            color: trackerCoreData.color as? UIColor ?? UIColor.black,
                            emoji: trackerCoreData.emoji ?? "",
                            schedule: decodeSchedule(trackerCoreData.schedule))
                    })
                self.categories.insert(pinnedCategory, at: 0)
            }
        } catch {
            print("Failed to fetch categories: \(error)")
        }
    }
    
    func shouldDisplayTracker(_ tracker: Tracker, forDate date: Date, dateFormatter: DateFormatter) -> Bool {
        let calendar = Calendar.current
        if tracker.schedule.contains("irregularEvent") {
            let fetchRequest: NSFetchRequest<TrackerRecordCoreData> = TrackerRecordCoreData.fetchRequest()
            fetchRequest.predicate = NSPredicate(
                format: "tracker.id == %@ AND date == %@",
                tracker.id as CVarArg, dateFormatter.string(from: date))
            do {
                let records = try context.fetch(fetchRequest)
                if records.isEmpty {
                    let trackerCreatedRecently = !completedTrackers.contains { $0.trackerID == tracker.id }
                    return trackerCreatedRecently
                }
                return !records.isEmpty
            } catch {
                print("Ошибка при запросе данных: \(error)")
                return false
            }
        }
        let weekdayIndex = calendar.component(.weekday, from: date) - 1
        let weekdaySymbols = calendar.weekdaySymbols
        _ = weekdaySymbols[weekdayIndex]
        let fetchRequest: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", tracker.id as NSUUID)
        do {
            let trackers = try context.fetch(fetchRequest)
            if let fetchedTracker = trackers.first {
                if isHabit(tracker: fetchedTracker) {
                    let weekDay = calendar.component(.weekday, from: date)
                    let selectDayWeek: WeekDay
                    switch weekDay {
                    case 1: selectDayWeek = .sunday
                    case 2: selectDayWeek = .monday
                    case 3: selectDayWeek = .tuesday
                    case 4: selectDayWeek = .wednesday
                    case 5: selectDayWeek = .thursday
                    case 6: selectDayWeek = .friday
                    case 7: selectDayWeek = .saturday
                    default:
                        fatalError("Неизвестный день недели")
                    }
                    let isScheduledToday = fetchedTracker.schedule?.contains(selectDayWeek.rawValue) ?? false
                    return isScheduledToday
                }
            }
        } catch {
            print("Ошибка при запросе данных: \(error)")
        }
        return false
    }
    
    func isHabit(tracker: TrackerCoreData) -> Bool {
        return tracker.schedule?.contains("habit") ?? false
    }
    
    func getCategoryForTracker(trackerId: UUID) -> String? {
        if let tracker = fetchTracker(by: trackerId) {
            return tracker.category?.title
        }
        return nil
    }
    
    func fetchTracker(by id: UUID) -> TrackerCoreData? {
        let fetchRequest: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        do {
            return try context.fetch(fetchRequest).first
        } catch {
            print("Failed to fetch tracker: \(error)")
            return nil
        }
    }
        
    func addNewTracker(to categoryTitle: String, tracker: Tracker) {
        let fetchRequest: NSFetchRequest<TrackerCategoryCoreData> = TrackerCategoryCoreData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "title == %@", categoryTitle)
        do {
            let categories = try context.fetch(fetchRequest)
            if let category = categories.first {
                let existingTrackers = category.trackers?.allObjects as? [TrackerCoreData]
                if existingTrackers?.contains(where: { $0.id == tracker.id }) == true {
                    print("Tracker with id \(tracker.id) already exists in category \(categoryTitle)")
                    return
                }
            }
            let newTracker = TrackerCoreData(context: context)
            newTracker.id = tracker.id
            newTracker.name = tracker.name
            newTracker.color = tracker.color
            newTracker.emoji = tracker.emoji
            if let jsonData = try? JSONEncoder().encode(tracker.schedule) {
                newTracker.schedule = String(data: jsonData, encoding: .utf8)
            } else {
                print("Failed to encode schedule to JSON.")
            }
            if let category = categories.first {
                category.addToTrackers(newTracker)
            } else {
                let newCategory = TrackerCategoryCoreData(context: context)
                newCategory.title = categoryTitle
                newCategory.addToTrackers(newTracker)
            }
            saveContext()
        } catch {
            print("Failed to fetch or add category: \(error)")
        }
    }
    
    func updateTracker(_ updatedTracker: Tracker, inCategory categoryTitle: String) {
        let fetchRequest: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", updatedTracker.id as CVarArg)
        do {
            if let trackerToUpdate = try context.fetch(fetchRequest).first {
                trackerToUpdate.name = updatedTracker.name
                trackerToUpdate.color = updatedTracker.color
                trackerToUpdate.emoji = updatedTracker.emoji
                if let jsonData = try? JSONEncoder().encode(updatedTracker.schedule) {
                    trackerToUpdate.schedule = String(data: jsonData, encoding: .utf8)
                } else {
                    print("Failed to encode schedule to JSON.")
                }
                let categoryFetchRequest:
                NSFetchRequest<TrackerCategoryCoreData> = TrackerCategoryCoreData.fetchRequest()
                categoryFetchRequest.predicate = NSPredicate(format: "title == %@", categoryTitle)
                if let category = try context.fetch(categoryFetchRequest).first {
                    trackerToUpdate.category = category
                }
                saveContext()
            }
        } catch {
            print("Failed to update tracker: \(error)")
        }
    }
    
    //MARK: - Private Methods
    
    private func saveContext() {
        do {
            if context.hasChanges {
                try context.save()
                print("Context successfully saved.")
            }
        } catch {
            print("Failed to save context: \(error.localizedDescription)")
        }
    }
    
    private func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        
        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil)
        fetchedResultsController?.delegate = self
        
        do {
            try fetchedResultsController?.performFetch()
        } catch {
            print("Ошибка performFetch: \(error)")
        }
    }
    
    private func deleteCategory(_ category: TrackerCategoryCoreData) {
        context.delete(category)
        saveContext()
    }
    
    private func decodeSchedule(_ scheduleString: String?) -> [String] {
        guard let data = scheduleString?.data(using:.utf8) else { return [] }
        do {
            let schedule = try JSONDecoder().decode([String].self, from: data)
            return schedule
        } catch {
            print("Failed to decode schedule: \(error)")
            return []
        }
    }
}
