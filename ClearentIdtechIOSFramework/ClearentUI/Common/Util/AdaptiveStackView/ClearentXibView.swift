//
//  ClearentXibView.swift
//  XplorPayMobile
//
//  Created by Carmen Jurcovan on 07.04.2022.
//

import UIKit

/// A custom UIView  that contains all the necessary methods for loading a view from nib. Could be used as a base class for UI components in order to avoid boilerplate code.
open class ClearentXibView: UIView {
    // MARK: - Lifecycle

    public var nibName: String? {
        String(describing: type(of: self))
    }

    public override func awakeFromNib() {
        super.awakeFromNib()
        configure()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadViewFromNib()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        loadViewFromNib()
    }

    public convenience init() {
        self.init(frame: CGRect.zero)
        configure()
    }

    open func configure() {
        // Add additional configuration for child view here
    }

    // MARK: - Private

    private func loadViewFromNib() {
        guard let nibName = nibName else { return }
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: nibName, bundle: bundle)
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else { return }
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(view)
    }
}
