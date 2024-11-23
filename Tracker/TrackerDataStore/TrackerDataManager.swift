import CoreData
import UIKit

// MARK: - TrackerDataManager

final class TrackerDataManager {
    
    // MARK: - Public Properties
    
    static let shared = TrackerDataManager()
    
    let context: NSManagedObjectContext
    
    public var persistentContainer: NSPersistentContainer {
            return (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer ?? NSPersistentContainer(name: "Tracker")
        }
    
    // MARK: - Initialization
    
    private init() {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            self.context = appDelegate.persistentContainer.viewContext
            
        } else {
            fatalError("Failed to get app delegate")
        }
    }
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }

}
