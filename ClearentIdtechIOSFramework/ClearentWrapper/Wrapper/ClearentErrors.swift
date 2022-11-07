//
//  ClearentErrors.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 16.08.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

/// Used to determine whether a flow succeeded or failed. The success case stores an optional string that represents the custom name of the reader
public typealias CompletionResult = Result<String?, ClearentError>

@objc public class ClearentError: NSObject, Error, Codable {
    let type: ClearentErrorType
    let code: String?
    let message: String?
    
    init(type: ClearentErrorType, code: String? = nil, message: String? = nil) {
        self.type = type
        self.code = code
        self.message = message
    }
}

@objc public enum ClearentErrorType: Int, Codable {
     /// The user aborted the current flow
    case cancelledByUser = 0

    /// No apiKey was passed to SDK
    case apiKeyNotProvided

    /// No baseURL was passed to SDK
    case baseURLNotProvided
    
    /// No publicKey was passed to SDK
    case publicKeyNotProvided

    /// Error related to http response
    case httpError
    
    /// Error related to transaction response
    case gatewayDeclined
    
    /// No internet connection or bluetooth availabe
    case connectivityError

    /// No transaction token was received from backend
    case missingToken
    
    /// Signature image not found on user defaults for offline transaction
    case missingSignatureImage
    
    var isMissingKeyError: Bool {
        return [.apiKeyNotProvided, .baseURLNotProvided, .publicKeyNotProvided].contains(self)
    }
    
    case none
}
