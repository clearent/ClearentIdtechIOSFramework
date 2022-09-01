//
//  SVGView.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 26.08.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import WebKit

class SVGView: UIView {

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func setupAnimation(name: String) {
        guard let loader = SVGLoader(animationName: name, bundle: ClearentConstants.bundle) else {
            fatalError("Resource not found.")
        }
        setupWebView(with: loader)
        
        isUserInteractionEnabled = false
        isOpaque = false
        backgroundColor = .clear
    }

    // MARK: - Private
    
    private func setupWebView(with loader: SVGLoader) {
        let webView = WKWebView(frame: bounds)
        addSubview(webView)
        webView.pinToEdges(of: self)
        webView.scrollView.isScrollEnabled = false
        webView.loadHTMLString(loader.html, baseURL: nil)
    }
}
