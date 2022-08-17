//
//  ClearentErrors.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 16.08.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

/**
  Used to determine whether a flow succeeded or failed. The assosiated value is of type String? and represents the custom name of the reader
 */
public typealias CompletionResult = Result<String?, ClearentError>

public enum ClearentError: Error {
    /**
     The user aborted the current flow
    */
    case cancelledByUser
    
    /**
     No apiKey was passed to SDK
    */
    case apiKeyNotProvided
    
    /**
     No baseURL was passed to SDK
    */
    case baseURLNotProvided
}
