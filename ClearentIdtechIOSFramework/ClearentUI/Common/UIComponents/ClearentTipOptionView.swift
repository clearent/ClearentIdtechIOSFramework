//
//  ClearentTipCheckboxView.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 14.06.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

class ClearentTipOptionView: ClearentMarginableView {

    // MARK: - Properties
    
    @IBOutlet weak var checkView: UIImageView!
    @IBOutlet weak var percentageLabel: UILabel!
    @IBOutlet weak var customAmountTextField: UITextField!
    
    var tipSelectedAction: ((_ tipValue: Double) -> Void)?
    
    private var tipValue: Double = 0
    
    override var margins: [BottomMargin] {
        [
            RelativeBottomMargin(constant: 16, relatedViewType: ClearentTipOptionView.self),
            BottomMargin(constant: 0)
        ]
    }
    
    var isSelected: Bool = false {
        didSet {
            checkView.layer.borderWidth = isSelected ? checkView.bounds.height / 3.0 : ClearentConstants.Size.defaultButtonBorderWidth
            checkView.layer.borderColor = isSelected ? ClearentUIBrandConfigurator.shared.colorPalette.checkboxSelectedBorderColor.cgColor : ClearentUIBrandConfigurator.shared.colorPalette.checkboxUnselectedBorderColor.cgColor
        }
    }
    
    convenience init(percentageTextAndValue: String, tipValue: Double, isCustomTip: Bool = false) {
        self.init()
        self.tipValue = tipValue
        percentageLabel.text = percentageTextAndValue
        setTextField(isCustomTip: isCustomTip)
    }
    
    override func configure() {
        setCheckView()
        setLabels()
    }
    
    @IBAction func tipWasPressed() {
        guard let superview = superview else { return }

        // deselect the last selected option
        superview.subviews.forEach {
            if let tipOption = $0 as? ClearentTipOptionView, !tipOption.isEqual(self) {
                tipOption.isSelected = false
            }
        }

        isSelected = true
        tipSelectedAction?(tipValue)
    }
    
    // MARK: - Private
    
    
    private func setTextField(isCustomTip: Bool) {
        customAmountTextField.isHidden = !isCustomTip
        customAmountTextField.keyboardType = .numberPad
        customAmountTextField.addDoneToKeyboard(barButtonTitle: "xsdk_keyboard_done".localized)
        customAmountTextField.addTarget(self, action: #selector(textFieldDidChange(textField:)), for: .editingChanged)
    }
    
    private func setLabels() {
        percentageLabel.font = ClearentUIBrandConfigurator.shared.fonts.tipItemTextFont
        percentageLabel.textColor = ClearentUIBrandConfigurator.shared.colorPalette.tipLabelColor
    }
    
    private func setCheckView() {
        isSelected = false
        checkView.layer.cornerRadius = checkView.bounds.height / 2.0
        checkView.backgroundColor = ClearentConstants.Color.backgroundSecondary01
    }
    
    @objc final private func textFieldDidChange(textField: UITextField) {
        guard let text = textField.text else { return }
        let tipWithDigitsOnly = text.filter("0123456789".contains)
        // limit the tip amount to certain minimum and maximum values declared in Constants
        let tipPrefix = String(tipWithDigitsOnly.prefix(ClearentConstants.Amount.maxNoOfCharacters))
        tipValue = tipPrefix.isEmpty ? 0 : max(tipPrefix.double, ClearentConstants.Tips.minCustomTipValue)
        customAmountTextField.text = tipPrefix.isEmpty ? "" : ClearentMoneyFormatter.formattedWithoutSymbol(from: tipValue)
        tipWasPressed()
    }
}
