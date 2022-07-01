//
//  ClearentApplicationOrientation.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 01.07.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

/// Handles the orientation of the application
public class ClearentApplicationOrientation {
    /// if custom orientation is needed on a specific screen (eg signature), call this closure with the needed mask and the orientation will be handled in AppDelegate
    public static var customOrientationMaskClosure: ((UIInterfaceOrientationMask) -> Void?)?
}

