import UIKit

// MARK: - TrackerTypeSelectionDelegate

extension TrackersViewController: TrackerTypeSelectionDelegate {
    func didSelectTrackerType(_ type: TrackerType) {
        dismiss(animated: true) {
            let createTrackerVC = TrackerCreationViewController()
            createTrackerVC.trackerType = type
            createTrackerVC.delegate = self
            self.present(createTrackerVC, animated: true, completion: nil)
        }
    }
}

//MARK: - UICollectionViewDataSource, UICollectionViewDelegate

extension TrackerCreationViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int) -> Int {
            return collectionView == emojiCollectionView ? emoji.count : colors.count
        }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            if collectionView == emojiCollectionView {
                if let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: EmojiCell.reuseIdentifier,
                    for: indexPath) as? EmojiCell {
                    let emoji = emoji[indexPath.item]
                    let isSelected = emoji == selectedEmoji
                    cell.configure(with: emoji, isSelected: isSelected)
                    return cell
                } else {
                    return UICollectionViewCell()
                }
            } else {
                if let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: ColorCell.reuseIdentifier,
                    for: indexPath) as? ColorCell {
                    let color = colors[indexPath.item]
                    let isSelected = color == selectedColor
                    cell.configure(with: color, isSelected: isSelected)
                    return cell
                } else {
                    return UICollectionViewCell()
                }
            }
        }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
            return 0
        }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
            return 0
        }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath) -> CGSize {
            let width = (collectionView.bounds.width) / 6
            return CGSize(width: width, height: width)
        }
    
    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath) {
            if collectionView == emojiCollectionView {
                selectedEmoji = emoji[indexPath.item]
            } else {
                selectedColor = colors[indexPath.item]
            }
            collectionView.reloadData()
            updateSaveButtonState()
        }
}


// MARK: - TrackerCreationDelegate

extension TrackersViewController: TrackerCreationDelegate {
    func didCreateTracker(
        _ tracker: Tracker,
        inCategory category: String
    ) {
        dataManager.addNewTracker(to: category, tracker: tracker)
        updateTrackersView()
    }
}

// MARK: - UICollectionViewDataSource

extension TrackersViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return visibleCategories.count
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int) -> Int {
            let category = visibleCategories[section]
            let trackers = category.trackers.filter {
                dataManager.shouldDisplayTracker($0, forDate: currentDate, dateFormatter: dateFormatter)
            }
            return trackers.count
        }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: TrackerCell.trackerCellIdentifier,
                for: indexPath) as? TrackerCell else {
                return UICollectionViewCell()
            }
            let category = visibleCategories[indexPath.section]
            let trackers = category.trackers.filter {
                dataManager.shouldDisplayTracker($0, forDate: currentDate, dateFormatter: dateFormatter)
            }
            let tracker = trackers[indexPath.item]
            let completedTrackers = dataManager.completedTrackers.filter { $0.trackerID == tracker.id }
            cell.configure(
                with: tracker,
                completedTrackers: completedTrackers,
                dataManager: dataManager,
                date: dateFormatter.string(from: currentDate))
            cell.delegate = self
            return cell
        }
}

// MARK: - UICollectionViewDelegate

extension TrackersViewController: UICollectionViewDelegate {
    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath) -> UICollectionReusableView {
            if kind == UICollectionView.elementKindSectionHeader {
                guard let headerView = collectionView.dequeueReusableSupplementaryView(
                    ofKind: kind,
                    withReuseIdentifier: TrackerSectionHeader.trackerSectionHeaderIdentifier,
                    for: indexPath
                ) as? TrackerSectionHeader else {
                    return UICollectionReusableView()
                }
                let category = visibleCategories[indexPath.section]
                headerView.titleLabel.text = category.title
                return headerView
            }
            return UICollectionReusableView()
        }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension TrackersViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int) -> CGSize {
            return CGSize(width: collectionView.frame.width, height: 30)
        }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath) -> CGSize {
            let cellWidth = collectionView.bounds.width / 2 - 20
            return CGSize(width: cellWidth, height: 148)
        }
}

// MARK: - UISearchBarDelegate

extension TrackersViewController: UISearchBarDelegate {
    func searchBar(
        _ searchBar: UISearchBar,
        textDidChange searchText: String
    ) {
        updateTrackersView()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        updateTrackersView()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        searchBar.resignFirstResponder()
        updateTrackersView()
    }
}

// MARK: - TrackerCellDelegate

extension TrackersViewController: TrackerCellDelegate {
    func trackerCellDidToggleCompletion(_ cell: TrackerCell, for tracker: Tracker) {
        updateTrackersView()
    }
    
    func trackerCellDidRequestEdit(_ cell: TrackerCell, for tracker: Tracker) {
        presentEditTrackerViewController(for: tracker)
    }
    
    func trackerCellDidRequestDelete(_ cell: TrackerCell, for tracker: Tracker) {
        handleDeleteTracker(tracker)
    }
}

extension TrackersViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

//MARK: - TrackerScheduleVC Delegate

extension TrackerScheduleVC: UITableViewDelegate {
    func tableView(
        _ tableView: UITableView,
        heightForRowAt indexPath: IndexPath) -> CGFloat {
            return 75
        }
}

//MARK: - TrackerScheduleVC Data Source

extension TrackerScheduleVC: UITableViewDataSource {
    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        return WeekDay.allCases.count
    }
    
    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: TrackerScheduleVC.cellIdentifier,
                for: indexPath)
            let day = WeekDay.allCases[indexPath.row]
            cell.textLabel?.text = day.localizedString()
            let switchView = UISwitch()
            switchView.isOn = selectedDays.contains(day)
            switchView.addTarget(self, action: #selector(switchChanged(sender:)), for: .valueChanged)
            switchView.onTintColor = UIColor.ypBlue
            cell.backgroundColor = UIColor.ypBackgroundDay
            cell.accessoryView = switchView
            if indexPath.row == WeekDay.allCases.count - 1 {
                cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
            } else {
                cell.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
            }
            return cell
        }
}

extension TrackerScheduleVC {
    @objc func switchChanged(sender: UISwitch) {
        guard let cell = sender.superview as? UITableViewCell,
              let indexPath = tableView.indexPath(for: cell) else {
            return
        }
        let day = WeekDay.allCases[indexPath.row]
        if sender.isOn {
            selectedDays.append(day)
        } else {
            if let index = selectedDays.firstIndex(of: day) {
                selectedDays.remove(at: index)
            }
        }
    }
}

//MARK: - TrackerCategoryVC: DataSource

extension TrackerCategoryViewController: UITableViewDataSource {
    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int) -> Int {
            return viewModel.categories.count
        }
    
    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: TrackerCategoryCell.identifier,
                for: indexPath) as? TrackerCategoryCell else {
                return UITableViewCell()
            }
            let category = viewModel.categories[indexPath.row].title
            let isSelected = category == viewModel.selectedCategory?.title
            cell.configure(with: category, isSelected: isSelected)
            cell.contentView.backgroundColor = .ypBackgroundDay
            return cell
        }
}

//MARK: - TrackerCategory: TableViewDelegate

extension TrackerCategoryViewController: UITableViewDelegate {
    func tableView(
        _ tableView: UITableView,
        willDisplay cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {
        if indexPath.row == 0 && viewModel.categories.count == 1 {
            cell.contentView.layer.cornerRadius = 16
            cell.contentView.layer.maskedCorners = [
                .layerMinXMinYCorner,
                .layerMaxXMinYCorner,
                .layerMinXMaxYCorner,
                .layerMaxXMaxYCorner]
        } else if indexPath.row == 0 {
            cell.contentView.layer.cornerRadius = 16
            cell.contentView.layer.maskedCorners = [
                .layerMinXMinYCorner,
                .layerMaxXMinYCorner]
        } else if indexPath.row == viewModel.categories.count - 1 {
            cell.contentView.layer.cornerRadius = 16
            cell.contentView.layer.maskedCorners = [
                .layerMinXMaxYCorner,
                .layerMaxXMaxYCorner]
        } else {
            cell.contentView.layer.cornerRadius = 0
        }
        cell.contentView.layer.masksToBounds = true
    }
    
    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        viewModel.selectCategory(at: indexPath.row)
    }
}
