//
//  InfoWithIconExtension.swift
//  XplorPayMobile
//
//  Created by Carmen Jurcovan on 17.12.2022.
//

import Foundation
import ClearentIdtechIOSFramework

class ItemSelectionField: ClearentInfoWithIcon {
    var navigationController: UINavigationController?
    var onPresenter: ((MerchantTerminalSearchViewProtocol) -> MerchantTerminalSearchPresenter)?
    
    override var nibName: String? { String(describing: ClearentInfoWithIcon.self) }
    override var bundle: Bundle? { Bundle(for: ClearentInfoWithIcon.self) }
    
    override func configure() {
        super.configure()
        setypStyle()
        containerWasPressed = { [weak self] in
            let merchantTerminalSearchVC = MerchantTerminalSearchViewController()
            merchantTerminalSearchVC.presenter = self?.onPresenter?(merchantTerminalSearchVC)
            self?.navigationController?.pushViewController(merchantTerminalSearchVC, animated: false)
        }
    }
    
    // MARK: Private
    
    private func setypStyle() {
        titleText = ""
        iconName = ClearentConstants.IconName.rightArrowLarge
        descriptionTextColor = Constants.Color.base02
        warningFont = Constants.Font.proTextSmall
    }
}
