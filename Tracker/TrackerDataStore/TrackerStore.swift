import UIKit
import CoreData

//MARK: - Protocol

protocol TrackerStoreDelegate {
    func trackerStore(_ trackerStore: TrackerStore, didLoadCategories categories: [TrackerCategory])
    func trackerStore(_ trackerStore: TrackerStore, didLoadTrackers trackers: [Tracker])
    func trackerStore(_ trackerStore: TrackerStore, didLoadCompletedTrackers completedTrackers: [TrackerRecord])
}

//MARK: - Tracker Models

struct Tracker {
    let id: UUID
    let name: String
    let color: UIColor
    let emoji: String
    let schedule: [String]
}

//MARK: - Final Class Tracker Store

final class TrackerStore: NSObject, NSFetchedResultsControllerDelegate {
    
    //MARK: - Public Properties
    
    var completedTrackers: [TrackerRecord] = []
    var trackers: [Tracker] = []
    var categories: [TrackerCategory] = []
    var delegate: TrackerStoreDelegate?
    
    //MARK: - Private Properties
    
    private var context = TrackerDataManager.shared.context
    private var fetchedResultsController: NSFetchedResultsController<TrackerCoreData>?
    private let coreData: TrackerDataManager
    
    private(set) var previousCategories: [UUID: TrackerCategoryCoreData] = [:]
    private(set) var pinnedTrackers: [TrackerCoreData] = []
    
    // MARK: - Initialization
    
    init(coreData: TrackerDataManager = TrackerDataManager.shared,
         managedObjectContext: NSManagedObjectContext = TrackerDataManager.shared.persistentContainer.viewContext) {
        self.coreData = coreData
        self.context = managedObjectContext
        super.init()
        setupFetchedResultsController()
    }
    
    //MARK: - Public Methods
    func loadTrackers(for category: TrackerCategory) {
        let fetchRequest: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "category.title == %@", category.title)
        do {
            let trackers = try context.fetch(fetchRequest)
            let trackersArray = trackers.map { Tracker(id: $0.id ?? UUID(),
                                                       name: $0.name ?? "",
                                                       color: $0.color as? UIColor ?? UIColor.black,
                                                       emoji: $0.emoji ?? "",
                                                       schedule: decodeSchedule($0.schedule)) }
            delegate?.trackerStore(self, didLoadTrackers: trackersArray)
        } catch {
            print("Ошибка при запросе данных: \(error)")
        }
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
    
    func addTracker(_ tracker: Tracker, category: TrackerCategory) {
        let trackerObject = TrackerCoreData(context: context)
        trackerObject.id = tracker.id
        trackerObject.name = tracker.name
        trackerObject.color = tracker.color
        trackerObject.emoji = tracker.emoji
        if let jsonData = try? JSONEncoder().encode(tracker.schedule) {
            trackerObject.schedule = String(data: jsonData, encoding: .utf8)
        } else {
            print("Failed to encode schedule to JSON.")
        }
        let categoryObject = TrackerCategoryCoreData(context: context)
        categoryObject.title = category.title
        trackerObject.category = categoryObject
        saveContext()
    }
    
    func fetchAllTrackers() -> [Tracker] {
        let request: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        do {
            let trackers = try context.fetch(request)
            return trackers.compactMap { tracker in
                if let id = tracker.id,
                   let name = tracker.name,
                   let color = tracker.color as? UIColor,
                   let emoji = tracker.emoji {
                    return Tracker(
                        id: id,
                        name: name,
                        color: color,
                        emoji: emoji,
                        schedule: tracker.schedule?.data(using:.utf8).flatMap { try? JSONDecoder().decode([String].self,
                                                                                                          from: $0) } ?? []
                    )
                } else {
                    return nil
                }
            }
        } catch {
            print("Failed to fetch trackers: \(error)")
            return []
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
    //MARK: - Делаем перенос файлов из extension
    
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
    
    //MARK: - делаем перенос файлов из TrackerDataManager
    
    func isIrregularEvent(tracker: TrackerCoreData) -> Bool {
        return tracker.schedule?.contains("irregularEvent") ?? false
    }
    
    func isHabit(tracker: TrackerCoreData) -> Bool {
        return tracker.schedule?.contains("habit") ?? false
    }
    
    func pinTracker(_ tracker: Tracker) {
        let fetchRequest: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", tracker.id as CVarArg)
        do {
            if let trackerToPin = try context.fetch(fetchRequest).first {
                trackerToPin.isPinned = true
                pinnedTrackers.append(trackerToPin)
                previousCategories[tracker.id] = trackerToPin.category
                saveContext()
            }
        } catch {
            print("Failed to pin tracker: \(error)")
        }
    }
    
    func unpinTracker(_ tracker: Tracker) {
        let fetchRequest: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", tracker.id as CVarArg)
        do {
            if let trackerToUnpin = try context.fetch(fetchRequest).first {
                trackerToUnpin.isPinned = false
                if let previousCategory = previousCategories[tracker.id] {
                    trackerToUnpin.category = previousCategory
                }
                pinnedTrackers.removeAll { $0.id == trackerToUnpin.id }
                previousCategories[tracker.id] = nil
                saveContext()
            }
        } catch {
            print("Failed to unpin tracker: \(error)")
        }
    }
    
    func isTrackerPinned(_ tracker: Tracker) -> Bool {
        let fetchRequest: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", tracker.id as CVarArg)
        do {
            if let fetchedTracker = try context.fetch(fetchRequest).first {
                return fetchedTracker.isPinned
            }
        } catch {
            print("Failed to check if tracker is pinned: \(error)")
        }
        return false
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
    
    // MARK: - Private Methods
    
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
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
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
    
    private func deleteTracker(_ tracker: TrackerCoreData) {
        context.delete(tracker)
        saveContext()
    }
    
    
    //MARK: - делаем перенос
    
    private func decodeSchedule(_ scheduleString: String?) -> [String] {
        guard let data = scheduleString?.data(using: .utf8) else { return [] }
        do {
            let schedule = try JSONDecoder().decode([String].self, from: data)
            return schedule
        } catch {
            print("Failed to decode schedule: \(error)")
            return []
        }
    }
}
