import UIKit

// MARK: - EmojiCell

final class ColorCell: UICollectionViewCell {
    
    // MARK: - Identifier
    
    static let reuseIdentifier = "colorCell"
    
    // MARK: - Private Properties
    
    private lazy var contentContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 8
        view.clipsToBounds = true
        return view
    }()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(contentContainer)
        setupConstraints()
        contentView.layer.cornerRadius = 8
        contentView.layer.borderWidth = 0
        contentView.clipsToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public Methods
    
    func configure(with color: UIColor, isSelected: Bool) {
        contentContainer.backgroundColor = color
        contentView.layer.borderWidth = isSelected ? 2 : 0
        contentView.layer.borderColor = isSelected ? color.withSaturation(0.3)?.cgColor : UIColor.clear.cgColor
    }
    
    // MARK: - Private Methods
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            contentContainer.widthAnchor.constraint(equalToConstant: 40),
            contentContainer.heightAnchor.constraint(equalToConstant: 40),
            contentContainer.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            contentContainer.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
}

// MARK: - UIColor

private extension UIColor {
    func withSaturation(_ saturation: CGFloat) -> UIColor? {
        var hue: CGFloat = 0
        var saturationValue: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        guard self.getHue(&hue, saturation: &saturationValue, brightness: &brightness, alpha: &alpha) else {
            return nil
        }
        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
    }
}
