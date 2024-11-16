import CoreData
import UIKit

// MARK: - TrackerDataManager

final class TrackerDataManager {
    
    // MARK: - Public Properties
    
    @NSManaged public var isPinned: Bool
    
    static let shared = TrackerDataManager()
    
    let context: NSManagedObjectContext
    
    var categories: [TrackerCategory] = []
    var completedTrackers: [TrackerRecord] = []
    
    // MARK: - Private Properties
    
    private(set) var previousCategories: [UUID: TrackerCategoryCoreData] = [:]
    private(set) var pinnedTrackers: [TrackerCoreData] = []
    
    // MARK: - Initialization
    
    private init() {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            self.context = appDelegate.persistentContainer.viewContext
            loadCompletedTrackers()
        } else {
            fatalError("Failed to get app delegate")
        }
    }
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // MARK: - Public Methods
    
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
    
    func isIrregularEvent(tracker: TrackerCoreData) -> Bool {
        return tracker.schedule?.contains("irregularEvent") ?? false
    }
    
    func isHabit(tracker: TrackerCoreData) -> Bool {
        return tracker.schedule?.contains("habit") ?? false
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
            }
        } catch {
            print("Failed to save context: \(error.localizedDescription)")
        }
    }
}
