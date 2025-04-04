import UIKit

final class OnboardingPageViewController: UIPageViewController {
    
    // MARK: - Identifier
    
    static let onboardingCompleted = "isOnboardingCompleted"
    
    //MARK: - Public Properties
    
    let onboardingPages: [UIViewController] = {
        let firstPage = OnboardingViewController(
            imageName: "OnboardingBlue",
            text: "Отслеживайте только\n то, что хотите",
            buttonTitle: "Вот это технологии!"
        )
        
        let secondPage = OnboardingViewController(
            imageName: "OnboardingRed",
            text: "Даже если это\n не литры воды и йога",
            buttonTitle: "Вот это технологии!"
        )
        
        return [firstPage, secondPage]
    }()
    
    var currentIndex: Int {
        guard let currentViewController = viewControllers?.first else { return 0 }
        return onboardingPages.firstIndex(of: currentViewController) ?? 0
    }
    
    //MARK: - Private Properties
    
    private lazy var pageControl: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.currentPageIndicatorTintColor = .black
        pageControl.pageIndicatorTintColor = .ypGray
        pageControl.numberOfPages = 2
        pageControl.addTarget(
            self,
            action: #selector(pageControlValueChanged(_:)),
            for: .valueChanged)
        return pageControl
    }()
    
    //MARK: - Initialization
    
    init() {
        super.init(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: nil
        )
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        delegate = self
        setupUI()
        setupConstraints()
        
        if let firstPage = onboardingPages.first {
            setViewControllers(
                [firstPage],
                direction: .forward,
                animated: true,
                completion: nil)
        }
    }
    
    //MARK: - Public Method
    
    func updatePageControl() {
        pageControl.currentPage = currentIndex
    }
    
    //MARK: - Private Method
    
    private func setupUI() {
        view.addSubview(pageControl)
        pageControl.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            pageControl.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -168),
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    //MARK: - Action
    
    @objc private func pageControlValueChanged(_ sender: UIPageControl) {
        let selectedIndex = sender.currentPage
        let direction: UIPageViewController.NavigationDirection = selectedIndex > currentIndex ?
            .forward : .reverse
        setViewControllers(
            [onboardingPages[selectedIndex]],
            direction: direction,
            animated: true,
            completion: nil)
    }
    
}

//MARK: - Extension Delegate & DataSource

extension OnboardingPageViewController: UIPageViewControllerDataSource {
    
    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController) -> UIViewController? {
            let index = currentIndex
            return index == 0 ? nil : onboardingPages[index - 1]
        }
    
    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController) -> UIViewController? {
            let index = currentIndex
            return index == onboardingPages.count - 1 ? nil : onboardingPages[index + 1]
        }
}

extension OnboardingPageViewController: UIPageViewControllerDelegate {
    func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        if completed {
            updatePageControl()
        }
    }
}
