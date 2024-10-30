import UIKit

final class MainTabBarController: UITabBarController {
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAppearance()
        setupViewControllers()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setupAppearance()
    }
    
    // MARK: - Private Methods
    
    private func setupViewControllers() {
        let trackersViewController = UINavigationController(rootViewController: TrackerViewController())
        trackersViewController.tabBarItem = UITabBarItem(title: "Трекеры",
                                                         image: UIImage(named: "Tracker"),
                                                         selectedImage: nil)
        
        let statisticsViewController = StatisticsViewController()
        statisticsViewController.tabBarItem = UITabBarItem(title: "Статистика",
                                                           image: UIImage(named: "Statistic"),
                                                           selectedImage: nil)
        
        viewControllers = [trackersViewController, statisticsViewController]
    }
    
    private func setupAppearance() {
        let activeTabColor: UIColor = .ypBlue
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        tabBar.tintColor = activeTabColor
        tabBar.barTintColor = isDarkMode ? .ypWhite : .ypBlack
        let topBorder = UIView(frame: CGRect(x: 0, y: 0, width: tabBar.frame.width, height: 1))
        topBorder.backgroundColor = .ypBackgroundDay
        tabBar.addSubview(topBorder)
    }
    
}
