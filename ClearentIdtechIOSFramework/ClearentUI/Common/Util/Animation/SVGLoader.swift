//
//  SVGLoader.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 26.08.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

class SVGLoader {
    let html: String

    private let rawCSS = """
                            svg {
                                width: 100vw;
                                height: 100vh;
                            }
                           """
    
    private let resetCSS = """
                                a,abbr,acronym,address,applet,article,aside,audio,b,big,blockquote,body,canvas,caption,center,cite,code,dd,del,details,dfn,div,dl,dt,em,embed,fieldset,figcaption,figure,footer,form,h1,h2,h3,h4,h5,h6,header,hgroup,html,i,iframe,img,ins,kbd,label,legend,li,mark,menu,nav,object,ol,output,p,pre,q,ruby,s,samp,section,small,span,strike,strong,sub,summary,sup,table,tbody,td,tfoot,th,thead,time,tr,tt,u,ul,var,video{margin:0;padding:0;border:0;font-size:100%;font:inherit;vertical-align:baseline}article,aside,details,figcaption,figure,footer,header,hgroup,menu,nav,section{display:block}body{line-height:1}ol,ul{list-style:none}blockquote,q{quotes:none}blockquote:after,blockquote:before,q:after,q:before{content:'';content:none}table{border-collapse:collapse;border-spacing:0}
                            """

    init?(animationName: String, bundle: Bundle) {
        guard let url = bundle.url(forResource: animationName, withExtension: "svg"),
              let data = try? Data(contentsOf: url),
              let svg = String(data: data, encoding: .utf8) else { return nil }

        self.html = """
        <!doctype html>
        <html>

        <head>
            <meta charset="utf-8"/>
            <style>
                \(self.rawCSS)
                \(self.resetCSS)
            </style>
        </head>

        <body>
            \(svg)
        </body>

        </html>
        """
    }
}
