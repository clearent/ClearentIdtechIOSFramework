//
//  ClearentErrorDetailsView.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Pop on 25.08.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import Foundation

public class ClearentErrorDetailsView: UIView, ClearentMarginable {
    
    enum Layout {
        static let topSpaceToContainerView: CGFloat = 10
    }
    
    // MARK: - Properties
    
    public var viewType: UIView.Type { type(of: self) }
    
    public var margins: [BottomMargin] {
        [RelativeBottomMargin(constant: 10, relatedViewType: ClearentPrimaryButton.self)]
    }
    
    public func setBottomMargin(margin: BottomMargin) {
        bottomLayoutConstraint = NSLayoutConstraint(item: textView, attribute: .bottomMargin, relatedBy: .equal, toItem: self, attribute: .bottomMargin, multiplier: 1.0, constant: -margin.constant)
        configure()
    }
    
    private var bottomLayoutConstraint: NSLayoutConstraint?
    private var textView = UITextView()
    
    // MARK: - Internal
    
    func setup(with detailedErrorMessage: String) {
        textView.text = detailedErrorMessage
    }
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    convenience init() {
        self.init(frame: .zero)
        
        textView.isEditable = false
    }
    
    // MARK: - Private
    
    private func configure() {
        addSubview(textView)

        textView.translatesAutoresizingMaskIntoConstraints = false
        guard let bottomLayoutConstraint = bottomLayoutConstraint else { return }
        
        let topAnchor = textView.topAnchor.constraint(equalTo: self.topAnchor, constant: Layout.topSpaceToContainerView)
        let leftAnchor = textView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 0)
        let rightAnchor = textView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: 0)
        let heightConstraint = textView.heightAnchor.constraint(equalToConstant: textView.contentSize.height)
        NSLayoutConstraint.activate([topAnchor, leftAnchor, rightAnchor, heightConstraint, bottomLayoutConstraint])
    }
}
