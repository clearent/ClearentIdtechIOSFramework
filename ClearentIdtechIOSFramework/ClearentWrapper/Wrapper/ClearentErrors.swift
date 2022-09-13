//
//  ClearentErrors.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 16.08.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//


/// Used to determine whether a flow succeeded or failed. The assosiated value is of type String? and represents the custom name of the reader
public typealias CompletionResult = Result<String?, ClearentResult>

@objc public enum ClearentResult:Int, Error {
     /// The user aborted the current flow
    case cancelledByUser = 0

    /// No apiKey was passed to SDK
    case apiKeyNotProvided

    /// No baseURL was passed to SDK
    case baseURLNotProvided
    
    /// No publicKey was passed to SDK
    case publicKeyNotProvided
    
    /// Process finished
    case processFinishedWithoutError
}


enum ResponseErrorCode: String {
    case saleReponseParseErrorCode = "sale_response_parsing_error"
    case signatureUploadReponseParseError = "signature_response_parsing_error"
}

enum ResponseErrorMessage: String {
    case saleReponseParseErrorMessage = "Sale request http response could not be parsed."
    case signatureUploadReponseParseErrorMessage = "Signature upload request http response could not be parsed."
}
