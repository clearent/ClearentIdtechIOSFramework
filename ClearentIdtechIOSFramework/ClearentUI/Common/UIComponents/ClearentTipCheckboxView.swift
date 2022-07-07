//
//  ClearentTipCheckboxView.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 14.06.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

class ClearentTipCheckboxView: ClearentMarginableView {

    // MARK: - Properties
    
    @IBOutlet weak var checkView: UIImageView!
    @IBOutlet weak var percentageLabel: UILabel!
    @IBOutlet weak var tipValueLabel: UILabel!
    @IBOutlet weak var decreaseTipButton: UIButton!
    @IBOutlet weak var increaseTipButton: UIButton!
    
    var tipSelectedAction: ((_ tipValue: Double) -> Void)?
    
    private var tipValue: Double = 0
    
    override var margins: [BottomMargin] {
        [
            RelativeBottomMargin(constant: 16, relatedViewType: ClearentTipCheckboxView.self),
            BottomMargin(constant: 0)
        ]
    }
    
    var isSelected: Bool = false {
        didSet {
            checkView.layer.borderWidth = isSelected ? checkView.bounds.height / 3.0 : ClearentConstants.Size.defaultButtonBorderWidth
            checkView.layer.borderColor = isSelected ? ClearentUIBrandConfigurator.shared.colorPalette.checkboxSelectedBorderColor.cgColor : ClearentUIBrandConfigurator.shared.colorPalette.checkboxUnselectedBorderColor.cgColor
        }
    }
    
    convenience init(percentageText: String, tipValue: Double, isCustomTip: Bool = false) {
        self.init()
        percentageLabel.text = percentageText
        updateValue(tipValue: tipValue)
        setIsCustomTip(isCustomTip: isCustomTip)
    }
    
    override func configure() {
        setCheckView()
        setLabels()
        setAdjustTipButton(button: decreaseTipButton, iconName: ClearentConstants.IconName.decreaseTip)
        setAdjustTipButton(button: increaseTipButton, iconName: ClearentConstants.IconName.increaseTip)
    }
    
    @IBAction func tipWasPressed() {
        guard let superview = superview else { return }

        // deselect the last selected option
        superview.subviews.forEach {
            if let tipOption = $0 as? ClearentTipCheckboxView, !tipOption.isEqual(self) {
                tipOption.isSelected = false
            }
        }

        isSelected = !isSelected
        let value = isSelected ? tipValue : 0
        tipSelectedAction?(value)
    }

    @IBAction func decreaseTipValue() {
        adjustCustomTip(with: -ClearentConstants.Tips.customTipAdjustFactor)
    }
    
    @IBAction func increaseTipValue() {
        adjustCustomTip(with: ClearentConstants.Tips.customTipAdjustFactor)
    }
    
    // MARK: - Private
    
    private func updateValue(tipValue: Double) {
        self.tipValue = max(tipValue, 0)
        tipValueLabel.text = ClearentMoneyFormatter.formattedText(from: self.tipValue)
    }
    
    private func setIsCustomTip(isCustomTip: Bool) {
        decreaseTipButton.isHidden = !isCustomTip
        increaseTipButton.isHidden = !isCustomTip
    }
    
    private func setLabels() {
        percentageLabel.font = ClearentConstants.Font.proTextNormal
        percentageLabel.textColor = ClearentUIBrandConfigurator.shared.colorPalette.percentageLabelColor
        tipValueLabel.font = ClearentConstants.Font.proTextNormal
        tipValueLabel.textColor = ClearentUIBrandConfigurator.shared.colorPalette.tipLabelColor
    }
    
    private func setCheckView() {
        isSelected = false
        checkView.layer.cornerRadius = checkView.bounds.height / 2.0
        checkView.backgroundColor = ClearentConstants.Color.backgroundSecondary01
    }
    
    private func setAdjustTipButton(button: UIButton, iconName: String) {
        let icon = UIImage(named: iconName, in: ClearentConstants.bundle, with: nil)
        button.setImage(icon, for: .normal)
        button.setTitle("", for: .normal)
        button.backgroundColor = ClearentConstants.Color.backgroundSecondary01
        button.tintColor = ClearentUIBrandConfigurator.shared.colorPalette.tipAdjustmentTintColor
    }
    
    private func adjustCustomTip(with factor: Double) {
        updateValue(tipValue: tipValue + factor)
        if isSelected {
            tipSelectedAction?(tipValue)
        }
    }
}
