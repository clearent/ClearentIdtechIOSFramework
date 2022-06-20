//
//  ClearentRoundedCornersStackView.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 10.05.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

class ClearentRoundedCornersStackView: ClearentAdaptiveStackView {

    private enum Layout {
        static let cornerRadius = 15.0
        static let margin = 16.0
        static let emptySpaceHeight = 104.0
        static let backgroundColor = ClearentConstants.Color.backgroundSecondary01
    }

    // MARK: - Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func showLoadingView() {
        removeAllArrangedSubviews()
        let loadingView = ClearentLoadingView()
        let emptySpace = ClearentEmptySpace(height: Layout.emptySpaceHeight)
        addArrangedSubview(emptySpace)
        addArrangedSubview(loadingView)
    }
    
    func findButtonInStack(with type: FlowButtonType) -> ClearentPrimaryButton? {
        return subviews.first { ($0 as? ClearentPrimaryButton)?.type == type } as? ClearentPrimaryButton
    }
    
    // MARK: - Private

    private func setup() {
        addRoundedCorners(backgroundColor: Layout.backgroundColor, radius: Layout.cornerRadius, margin: Layout.margin)
        backgroundColor = .white
        showLoadingView()
    }
}
