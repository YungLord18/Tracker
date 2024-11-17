import UIKit
import CoreData

//MARK: - Tracker Record Models

struct TrackerRecord {
    let trackerID: UUID
    let date: String
}

//MARK: - Final Class TrackerRecordStore

final class TrackerRecordStore: NSObject, NSFetchedResultsControllerDelegate {
    
    //MARK: - Private Properties
    
    private var context = TrackerDataManager.shared.context
    private var completedTrackers: [TrackerRecord] = []
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
    
    func addRecord(_ record: TrackerRecord) {
        let recordObject = TrackerRecordCoreData(context: context)
        recordObject.date = record.date
        recordObject.tracker = TrackerCoreData(context: context)
        recordObject.tracker?.id = record.trackerID
        saveContext()
    }
    
    func deleteRecord(_ record: TrackerRecord) {
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
}

//MARK: - Tracker Record

extension TrackerRecord {
    init(coreData: TrackerRecordCoreData) {
        self.trackerID = coreData.tracker?.id ?? UUID()
        self.date = coreData.date ?? ""
    }
}
