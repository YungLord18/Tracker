import UIKit
import CoreData

//MARK: - Tracker Models

struct Tracker {
    let id: UUID
    let name: String
    let color: UIColor
    let emoji: String
    let schedule: [String]
}

//MARK: - Final Class Tracker Store

final class TrackerStore {
    
    //MARK: - Private Properties
    
    private let context = TrackerDataManager.shared.context
    
    //MARK: - Public Methods
    
    func addTracker(
        id: UUID,
        name: String,
        color: UIColor,
        emoji: String,
        schedule: [String],
        category: TrackerCategoryCoreData) {
            let trackerObject = TrackerCoreData(context: context)
            trackerObject.id = id
            trackerObject.name = name
            trackerObject.color = color
            trackerObject.emoji = emoji
            if let jsonData = try? JSONEncoder().encode(schedule) {
                trackerObject.schedule = String(data: jsonData, encoding: .utf8)
            } else {
                print("Failed to encode schedule to JSON.")
            }
            trackerObject.category = category
            saveContext()
        }
    
    func fetchAllTrackers() -> [TrackerCoreData] {
        let request: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        do {
            let trackers = try context.fetch(request)
            trackers.forEach { tracker in
                if let scheduleData = tracker.schedule?.data(using: .utf8),
                   let scheduleArray = try? JSONDecoder().decode([String].self, from: scheduleData) {
                    print("Schedule for \(String(describing: tracker.name)): \(scheduleArray)")
                }
            }
            return trackers
        } catch {
            print("Failed to fetch trackers: \(error)")
            return []
        }
    }
    
    func deleteTracker(_ tracker: TrackerCoreData) {
        context.delete(tracker)
        saveContext()
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
}
