//
//  UIFontExtension.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 06.05.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

extension UIFont {
    public class func loadFonts() {
        let fonts = ["SF-Pro-Text-Medium.otf", "SF-Pro-Text-Bold.otf", "SF-Pro-Text-Regular.otf"]
        fonts.forEach {
            registerFont(with: $0, moduleBundle: ClearentConstants.bundle)
        }
    }

    private static func registerFont(with filenameString: String, moduleBundle: Bundle) {
        guard let url = moduleBundle.url(forResource: filenameString, withExtension: nil) else { return }
        var errorRef: Unmanaged<CFError>?
        if CTFontManagerRegisterFontsForURL(url as CFURL, .none, &errorRef) {
            print("Did load font \(filenameString)")
        } else {
            print("Failed to register font \(filenameString). This font may have already been registered in the main bundle.")
        }
    }
}
