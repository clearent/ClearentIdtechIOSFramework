//
//  ClearentDefaultFonts.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 07.07.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

class ClearentDefaultFonts: ClearentUIFonts {
    
    private let sfProDisplayBold = "SFProDisplay-Bold"
    private let sfProTextBold = "SFProText-Bold"
    private let sfProTextMedium = "SFProText-Medium"
    private let defaultFont = UIFont.systemFont(ofSize: 20)

    private var proDisplayBoldLarge: UIFont { UIFont(name: sfProDisplayBold, size: 20) ?? defaultFont }
    private var proTextBoldNormal: UIFont { UIFont(name: sfProTextBold, size: 14) ?? defaultFont }
    private var proTextLarge: UIFont { UIFont(name: sfProTextMedium, size: 16) ?? defaultFont }
    private var proTextNormal: UIFont { UIFont(name: sfProTextMedium, size: 14) ?? defaultFont }
    private var proTextSmall: UIFont { UIFont(name: sfProTextMedium, size: 12) ?? defaultFont }
    private var proTextExtraSmall: UIFont { UIFont(name: sfProTextMedium, size: 10) ?? defaultFont }
    
    var primaryButtonTextFont: UIFont { proTextNormal }
    
    var hintTextFont: UIFont { proTextNormal }
    
    var modalTitleFont: UIFont { proTextBoldNormal }
    
    var modalSubtitleFont: UIFont { proTextNormal }
    
    var listItemTextFont: UIFont { proTextNormal }
    
    var readerNameTextFont: UIFont { proTextNormal }
    
    var statusLabelFont: UIFont { proTextExtraSmall }
    
    var tipItemTextFont: UIFont { proTextNormal }
    
    var customNameInfoLabelFont: UIFont { proTextSmall }
    
    var customNameInputLabelFont: UIFont { proTextNormal }
    
    var signatureSubtitleFont: UIFont { proTextSmall}
    
    var detailScreenItemTitleFont: UIFont { proTextNormal }
    
    var detailScreenItemSubtitleFont: UIFont { proTextNormal }
     
    var detailScreenItemDescriptionFont: UIFont { proTextExtraSmall }
    
    var screenTitleFont: UIFont { proDisplayBoldLarge }
    
    var paymentViewTitleLabelFont: UIFont { proTextNormal }
    
    var paymentFieldTitleLabelFont: UIFont { proTextNormal }
    
    var errorMessageLabelFont: UIFont { proTextExtraSmall }
    
    var sectionTitleLabelFont: UIFont { proTextLarge }
    
    var textfieldPlaceholder: UIFont { proTextNormal }
}
