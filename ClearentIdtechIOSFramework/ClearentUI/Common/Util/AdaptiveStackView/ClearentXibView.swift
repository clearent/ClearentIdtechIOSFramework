//
//  ClearentXibView.swift
//  XplorPayMobile
//
//  Created by Carmen Jurcovan on 07.04.2022.
//

import UIKit

/// A custom UIView  that contains all the necessary methods for loading a view from nib. Could be used as a base class for UI components in order to avoid boilerplate code.
public class ClearentXibView: UIView {
    // MARK: - Lifecycle

    public override func awakeFromNib() {
        super.awakeFromNib()
        configure()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadViewFromNib()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        loadViewFromNib()
    }

    convenience init() {
        self.init(frame: CGRect.zero)
        configure()
    }

    func configure() {
        // Add additional configuration for child view here
    }

    // MARK: - Private

    private func loadViewFromNib() {
        let bundle = Bundle(for: type(of: self))
        let nibName = String(describing: type(of: self))
        let nib = UINib(nibName: nibName, bundle: bundle)
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else { return }
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(view)
    }
}
