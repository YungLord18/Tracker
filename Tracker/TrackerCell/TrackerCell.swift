import UIKit

//MARK: - Tracke Cell Delegate

protocol TrackerCellDelegate: AnyObject {
    func trackerCellDidToggleCompletion(_ cell: TrackerCell, for tracker: Tracker)
    func trackerCellDidRequestEdit(_ cell: TrackerCell, for tracker: Tracker)
    func trackerCellDidRequestDelete(_ cell: TrackerCell, for tracker: Tracker)
}

//MARK: - TrackerCell

final class TrackerCell: UICollectionViewCell {
    
    //MARK: - Identifier
    
    static let trackerCellIdentifier: String = "TrackerCell"
    
    //MARK: - Public Properties
    
    weak var delegate: TrackerCellDelegate?
    
    //MARK: - Private Properties
    
    private var tracker: Tracker?
    private var completedTrackers: [TrackerRecord] = []
    private var date: String = ""
    private var dataManager: TrackerDataManager?
    
    //MARK: - Public Methods
    
    func configure(
        with tracker: Tracker,
        completedTrackers: [TrackerRecord],
        dataManager: TrackerDataManager,
        date: String
    ) {
        
    }
}
