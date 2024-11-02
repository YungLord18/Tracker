import UIKit

final class TrackerNewCategoryVC: UIViewController {
    
    //MARK: - Public Properties
    
    var onCategorySave: ((TrackerCategory) -> Void)?
    
    //MARK: - Private Properties
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Новая категория"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        return label
    }()
    
    private lazy var categoryNameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Введите название категории"
        textField.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        textField.backgroundColor = .ypBackgroundDay
        textField.layer.cornerRadius = 16
        let leftPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: textField.frame.height))
        textField.leftView = leftPaddingView
        textField.leftViewMode = .always
        textField.heightAnchor.constraint(equalToConstant: 75).isActive = true
        textField.addTarget(
            self,
            action: #selector(textFieldDidChange(_:)),
            for: .editingChanged)
        textField.delegate = self
        return textField
    }()
    
    private lazy var saveCategoryButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Готово", for: .normal)
        button.layer.cornerRadius = 16
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .ypGray
        button.isEnabled = false
        button.heightAnchor.constraint(equalToConstant: 60).isActive = true
        button.addTarget(
            self,
            action: #selector(saveCategoryButtonTapped),
            for: .touchUpInside)
        return button
    }()
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .ypWhite
        setupUI()
        setupConstraints()
    }
    
    //MARK: - SetupUI
    
    private func setupUI() {
        [titleLabel, categoryNameTextField, saveCategoryButton].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 38),
            
            categoryNameTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 38),
            categoryNameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            categoryNameTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            saveCategoryButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            saveCategoryButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            saveCategoryButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50)
        ])
    }
    
    //MARK: - Actions
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        if let text = textField.text, !text.isEmpty {
            saveCategoryButton.isEnabled = true
            saveCategoryButton.backgroundColor = .ypBlack
        } else {
            saveCategoryButton.isEnabled = false
            saveCategoryButton.backgroundColor = .ypGray
        }
    }
    
    @objc private func saveCategoryButtonTapped() {
        guard let categoryName = categoryNameTextField.text, !categoryName.isEmpty else { return }
        let newCategory = TrackerCategory(title: categoryName, trackers: [])
        onCategorySave?(newCategory)
        dismiss(animated: true, completion: nil)
    }
}

//MARK: - UITextFieldDelegate

extension TrackerNewCategoryVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
