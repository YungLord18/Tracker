import UIKit

//MARK: - TrackerProtocol
protocol TrackerProtocol {
    var id: UUID { get }
    var name: String { get }
    var description: String? { get }
    var categoryID: UUID? { get }
    
    func delete()
}

//MARK: - TrackerCategoryProtocol
protocol TrackerCategoryProtocol {
    var id: UUID { get }
    var name: String { get }
    var description: String? { get }
    
    func delete()
}

//MARK: - TrackerRecordProtocol
protocol TrackerRecordProtocol {
    var id: UUID { get }
    var date: Date { get }
    var value: Double { get }
    var tracker: Tracker { get }
    
    func delete()
}
