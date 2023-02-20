//
//  ClearentIcon.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 05.05.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

class ClearentIcon: UIView, ClearentMarginable {
    
    // MARK: - Properties
    
    public var viewType: UIView.Type { type(of: self) }
    
    private var bottomConstraint: NSLayoutConstraint?
    private let imageView = UIImageView()
    
    var margins: [BottomMargin] {
        [
            RelativeBottomMargin(constant: 24, relatedViewType: ClearentIcon.self),
            RelativeBottomMargin(constant: 26, relatedViewType: ClearentTitleLabel.self),
            RelativeBottomMargin(constant: 48, relatedViewType: ClearentSubtitleLabel.self),
            RelativeBottomMargin(constant: 40, relatedViewType: ClearentPrimaryButton.self),
            BottomMargin(constant: 40)
        ]
    }
    
    var iconName: String? {
        didSet {
            guard let iconName = iconName else { return }
            imageView.image = UIImage(named: iconName, in: ClearentConstants.bundle, compatibleWith: nil)
        }
    }
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    convenience init(iconName: String) {
        self.init()
        configure()
        imageView.image = UIImage(named: iconName, in: ClearentConstants.bundle, compatibleWith: nil)
    }
    
    // MARK: - Lifecycle
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        configure()
    }
    
    // MARK: - Internal
    
    func setBottomMargin(margin: BottomMargin) {
        bottomConstraint?.constant = -margin.constant
    }

    // MARK: - Private
    
    private func configure() {
        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        
        let bottomConstraint = imageView.bottomAnchor.constraint(equalTo: bottomAnchor)
        imageView.pinToEdges(edges: [.top, .left, .right], of: self)
        bottomConstraint.isActive = true
        self.bottomConstraint = bottomConstraint
    }
}
