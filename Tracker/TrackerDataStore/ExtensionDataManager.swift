import CoreData
import UIKit

// MARK: - ExtensionTrackerDataManagerStore

extension TrackerDataManager {
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
    
    func loadCompletedTrackers() {
        let fetchRequest: NSFetchRequest<TrackerRecordCoreData> = TrackerRecordCoreData.fetchRequest()
        do {
            let records = try context.fetch(fetchRequest)
            self.completedTrackers = records.map { TrackerRecord(coreData: $0) }
        } catch {
            print("Failed to fetch completed trackers: \(error)")
        }
    }
    
    func getCategoryForTracker(trackerId: UUID) -> String? {
        if let tracker = fetchTracker(by: trackerId) {
            return tracker.category?.title
        }
        return nil
    }
    
    func getCompletedTrackersCount() -> Int {
        loadCompletedTrackers()
        return completedTrackers.count
    }
    
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
