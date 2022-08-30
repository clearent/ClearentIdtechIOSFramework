//
//  ClearentAnimationWithSubtitle.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 26.08.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import Foundation

class ClearentAnimationWithSubtitle: ClearentMarginableView {

    @IBOutlet weak var animatedView: SVGView!
    @IBOutlet weak var subtitle: ClearentSubtitleLabel!

    var bottomConstraint: NSLayoutConstraint?
    private var timer: Timer?
    var subtitles: [String]?
    
    override var margins: [BottomMargin] {
        [ RelativeBottomMargin(constant: 24, relatedViewType: ClearentPrimaryButton.self) ]
    }

    convenience init(animationName: String, subtitles: [String]?) {
        self.init()
        self.subtitles = subtitles
        subtitle.title = subtitles?[0]
        animatedView.setupAnimation(name: animationName)
        timer = Timer.scheduledTimer(withTimeInterval: 3.3, repeats: true) { [weak self] _ in
            self?.subtitle.fadeOut(completion: {
                self?.subtitle.title = subtitles?.nextItem(after: self?.subtitle.title ?? "")
                self?.subtitle.fadeIn()
            })
        }
    }

    deinit {
        timer?.invalidate()
        timer = nil
    }
}
