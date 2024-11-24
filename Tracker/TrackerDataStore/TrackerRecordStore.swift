import UIKit
import CoreData

//MARK: - Protocol

protocol TrackerRecordDelegate {
    func trackerRecordStore(_ trackerRecordStore: TrackerRecordStore,
                            didLoadCompletedTrackers completedTrackers: [TrackerRecord])
    
    func trackerRecordStore(_ trackerRecordStore: TrackerRecordStore,
                            didLoadRecords records: [TrackerRecord])
}

//MARK: - Tracker Record Models

struct TrackerRecord {
    let trackerID: UUID
    let date: String
}

//MARK: - Final Class TrackerRecordStore

final class TrackerRecordStore: NSObject, NSFetchedResultsControllerDelegate {
    
    //MARK: - Public Properties
    
    var categories: [TrackerCategory] = []
    var completedTrackers: [TrackerRecord] = []
    var delegate: TrackerRecordDelegate?
    
    @NSManaged public var isPinned: Bool
    
    //MARK: - Private Properties
    
    private let coreData: TrackerDataManager
    private var context = TrackerDataManager.shared.context
    private var fetchedResultsController: NSFetchedResultsController<TrackerCoreData>?
    
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
    
    func loadRecords(for tracker: Tracker) {
        let fetchRequest: NSFetchRequest<TrackerRecordCoreData> = TrackerRecordCoreData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "tracker.id == %@", tracker.id as CVarArg)
        do {
            let records = try context.fetch(fetchRequest)
            let recordsArray = records.map { TrackerRecord(coreData: $0) }
            delegate?.trackerRecordStore(self, didLoadRecords: recordsArray)
        } catch {
            print("Ошибка при запросе данных: \(error)")
        }
    }
    
    func loadCompletedTrackers() {
        let fetchRequest: NSFetchRequest<TrackerRecordCoreData> = TrackerRecordCoreData.fetchRequest()
        do {
            let records = try context.fetch(fetchRequest)
            self.completedTrackers = records.map { TrackerRecord(coreData: $0) }
        } catch {
            print("Failed to fetch completed trackers: \(error)")
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

    func markTrackerAsCompleted(trackerId: UUID, date: String) {
        let fetchRequest: NSFetchRequest<TrackerRecordCoreData> = TrackerRecordCoreData.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "tracker.id == %@ AND date == %@",
            trackerId as CVarArg, date)
        do {
            let records = try context.fetch(fetchRequest)
            if records.isEmpty {
                guard let tracker = fetchTracker(by: trackerId) else {
                    return
                }
                let newRecord = TrackerRecordCoreData(context: context)
                newRecord.tracker = tracker
                newRecord.trackerId = tracker.id
                newRecord.date = date
                saveContext()
                let trackerRecord = TrackerRecord(coreData: newRecord)
                completedTrackers.append(trackerRecord)
            }
        } catch {
            print("Failed to fetch records: \(error)")
        }
    }
    
    func unmarkTrackerAsCompleted(trackerId: UUID, date: String) {
        let fetchRequest: NSFetchRequest<TrackerRecordCoreData> = TrackerRecordCoreData.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "tracker.id == %@ AND date == %@",
            trackerId as CVarArg, date)
        do {
            let records = try context.fetch(fetchRequest)
            for record in records {
                context.delete(record)
            }
            saveContext()
            completedTrackers.removeAll { $0.trackerID == trackerId && $0.date == date }
        } catch {
            print("Failed to fetch records: \(error)")
        }
    }
    
    func deleteTracker(withId id: UUID, for date: Date, dateFormatter: DateFormatter) {
        let fetchRequest: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        do {
            let trackers = try context.fetch(fetchRequest)
            if let trackerToDelete = trackers.first {
                let recordFetchRequest:
                NSFetchRequest<TrackerRecordCoreData> = TrackerRecordCoreData.fetchRequest()
                recordFetchRequest.predicate = NSPredicate(format: "tracker.id == %@", id as CVarArg)
                let records = try context.fetch(recordFetchRequest)
                for record in records {
                    context.delete(record)
                }
                context.delete(trackerToDelete)
                saveContext()
                loadCategories(for: date, dateFormatter: dateFormatter)
            }
        } catch {
            print("Failed to fetch or delete tracker: \(error)")
        }
    }
    
    //MARK: - Private Methods
    
    private func addRecord(_ record: TrackerRecord) {
        let recordObject = TrackerRecordCoreData(context: context)
        recordObject.date = record.date
        recordObject.tracker = TrackerCoreData(context: context)
        recordObject.tracker?.id = record.trackerID
        saveContext()
    }
    
    private func deleteRecord(_ record: TrackerRecord) {
        let request: NSFetchRequest<TrackerRecordCoreData> = TrackerRecordCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "tracker.id == %@ AND date == %@", record.trackerID as CVarArg, record.date)
        do {
            if let recordObject = try context.fetch(request).first {
                context.delete(recordObject)
                saveContext()
            }
        } catch {
            print("Failed to delete record: \(error)")
        }
    }
    
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
    
    private func fetchRecords(for tracker: TrackerCoreData) -> [TrackerRecord] {
        let request: NSFetchRequest<TrackerRecordCoreData> = TrackerRecordCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "tracker == %@", tracker)
        do {
            let records = try context.fetch(request)
            return records.map { TrackerRecord(coreData: $0) }
        } catch {
            print("Failed to fetch records: \(error)")
            return []
        }
    }
    
    private func getCompletedTrackersCount() -> Int {
        loadCompletedTrackers()
        return completedTrackers.count
    }
    
    private func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        
        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        
        fetchedResultsController?.delegate = self
        
        do {
            try fetchedResultsController?.performFetch()
        } catch {
            print("Ошибка performFetch: \(error)")
        }
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

//MARK: - Tracker Record

extension TrackerRecord {
    init(coreData: TrackerRecordCoreData) {
        self.trackerID = coreData.tracker?.id ?? UUID()
        self.date = coreData.date ?? ""
    }
}
