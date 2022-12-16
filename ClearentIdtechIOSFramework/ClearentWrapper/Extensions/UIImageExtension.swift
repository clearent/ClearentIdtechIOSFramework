//
//  UIImageExtension.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 28.11.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

extension UIImage {
    func resize(to targetWidth: CGFloat = 400.0) -> UIImage? {
        let scaleRatio  = targetWidth / size.width
        
        let newSize = CGSize(width: size.width * scaleRatio, height: size.height * scaleRatio)
        let newRect = CGRect(origin: .zero, size: newSize)
        
        // Do the resizing to the rect using the ImageContext
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        draw(in: newRect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}
