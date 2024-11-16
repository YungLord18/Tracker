import UIKit
import CoreData

//MARK: - Tracker Record Models

struct TrackerRecord {
    let trackerID: UUID
    let date: String
}

//MARK: - Final Class TrackerRecordStore

final class TrackerRecordStore {
    
    //MARK: - Private Properties
    
    private let context = TrackerDataManager.shared.context
    private var completedTrackers: [TrackerRecord] = []
    
    //MARK: - Public Methods
    
//    func addRecord(date: String, tracker: TrackerCoreData) {
//        let recordObject = TrackerRecordCoreData(context: context)
//        recordObject.date = date
//        recordObject.tracker = tracker
//        saveContext()
//        
//        let newTrackerRecord = TrackerRecord(coreData: recordObject)
//        completedTrackers.append(newTrackerRecord)
//    }
    
    func addRecord(_ record: TrackerRecord) {
        let recordObject = TrackerRecordCoreData(context: context)
        recordObject.date = record.date
        recordObject.tracker = TrackerCoreData(context: context)
        recordObject.tracker?.id = record.trackerID
        saveContext()
    }
    
    func fetchRecords(for tracker: TrackerCoreData) -> [TrackerRecord] {
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
    
//    func fetchRecords(for tracker: TrackerCoreData) -> [TrackerRecordCoreData] {
//        let request: NSFetchRequest<TrackerRecordCoreData> = TrackerRecordCoreData.fetchRequest()
//        request.predicate = NSPredicate(format: "tracker == %@", tracker)
//        do {
//            return try context.fetch(request)
//        } catch {
//            print("Failed to fetch records: \(error)")
//            return []
//        }
//    }
    
//    func deleteRecord(_ record: TrackerRecordCoreData) {
//        context.delete(record)
//        saveContext()
//        
//        if let index = completedTrackers.firstIndex(where: { $0.trackerID == record.tracker?.id }) {
//            completedTrackers.remove(at: index)
//        }
//    }
    
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
}

//MARK: - Tracker Record

extension TrackerRecord {
    init(coreData: TrackerRecordCoreData) {
        self.trackerID = coreData.tracker?.id ?? UUID()
        self.date = coreData.date ?? ""
    }
}
