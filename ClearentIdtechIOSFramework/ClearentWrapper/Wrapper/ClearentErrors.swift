//
//  ClearentErrors.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 16.08.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//


/// Used to determine whether a flow succeeded or failed. The assosiated value is of type String? and represents the custom name of the reader
public typealias CompletionResult = Result<String?, ClearentResultError>

@objc public class ClearentResultError: NSObject, Error {
    let type: ClearentErrorType
    let code: String?
    let message: String?
    
    init(code: String? = nil, message: String? = nil, type: ClearentErrorType) {
        self.code = code
        self.message = message
        self.type = type
    }
}

@objc public enum ClearentErrorType: Int {
     /// The user aborted the current flow
    case cancelledByUser = 0

    /// No apiKey was passed to SDK
    case apiKeyNotProvided

    /// No baseURL was passed to SDK
    case baseURLNotProvided
    
    /// No publicKey was passed to SDK
    case publicKeyNotProvided

    case networkError
    
    case missingToken
    
    case missingData
    
    var isMissingKeyError: Bool {
        return [.apiKeyNotProvided, .baseURLNotProvided, .publicKeyNotProvided].contains(self)
    }
}
