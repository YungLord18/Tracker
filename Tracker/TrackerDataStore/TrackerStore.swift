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

final class TrackerStore: NSObject, NSFetchedResultsControllerDelegate {
    
    //MARK: - Private Properties
    
    private var context = TrackerDataManager.shared.context
    private var fetchedResultsController: NSFetchedResultsController<TrackerCoreData>?
    private let coreData: TrackerDataManager
    
    // MARK: - Initialization
    
    init(coreData: TrackerDataManager = TrackerDataManager.shared,
         managedObjectContext: NSManagedObjectContext = TrackerDataManager.shared.persistentContainer.viewContext) {
        self.coreData = coreData
        self.context = managedObjectContext
        super.init()
        setupFetchedResultsController()
    }
    
    //MARK: - Public Methods
    
    func addTracker(_ tracker: Tracker, category: TrackerCategory
                    //        id: UUID,
                    //        name: String,
                    //        color: UIColor,
                    //        emoji: String,
                    //        schedule: [String],
                    //        category: TrackerCategoryCoreData
    ) {
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
                        schedule: tracker.schedule?.data(using:.utf8).flatMap { try? JSONDecoder().decode([String].self, from: $0) } ?? []
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
}
