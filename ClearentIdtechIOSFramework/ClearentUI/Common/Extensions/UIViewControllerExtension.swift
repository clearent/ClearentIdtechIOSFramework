//
//  UIViewControllerExtension.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 17.11.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

extension UIViewController {
    func addNavigationBarWithBackItem(barTitle: String) {
        let navigationBar = createNavigationBar()
        view.addSubview(navigationBar)

        let navigationItem = UINavigationItem(title: barTitle)
        let image = UIImage(named: ClearentConstants.IconName.navigationArrow, in: ClearentConstants.bundle, compatibleWith: nil)
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(didPressBackButton))

        navigationBar.setItems([navigationItem], animated: false)
    }
    
    private func createNavigationBar() -> UINavigationBar {
        let window = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.flatMap { $0.windows }.first { $0.isKeyWindow }
        let topPadding = window?.safeAreaInsets.top ?? 0
        let barWidth = window?.frame.size.width ?? view.frame.size.width
        let navigationBar = UINavigationBar(frame: CGRect(x: 0, y: topPadding, width: barWidth, height: 44))
        navigationBar.barTintColor = view.backgroundColor
        navigationBar.shadowImage = UIImage()
        navigationBar.isTranslucent = true
        navigationBar.tintColor = ClearentUIBrandConfigurator.shared.colorPalette.navigationBarTintColor
        navigationBar.titleTextAttributes = [.font: ClearentUIBrandConfigurator.shared.fonts.screenTitleFont,
                                          .foregroundColor: ClearentUIBrandConfigurator.shared.colorPalette.screenTitleColor]
        return navigationBar
    }
    
    @objc func didPressBackButton() {
        navigationController?.popViewController(animated: true)
    }
}