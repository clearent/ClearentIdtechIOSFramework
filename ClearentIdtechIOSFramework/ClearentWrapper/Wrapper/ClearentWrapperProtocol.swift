//
//  ClearentWrapperProtocol.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Rotaru on 12.09.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import Foundation

/**
 * This protocol is used to comunicate information and results regarding the interaction with the SDK
 */
public protocol ClearentWrapperProtocol : AnyObject {
    /**
     * Method called right after a pairing process and a bluetooth search is started
     */
    func didStartPairing()
    
    /**
     * Method called right after a successful connection to a card reader was completed
     */
    func didFinishPairing()
    
    /**
     * Method called as a response to 'startDeviceInfoUpdate' method and indicates that new reader information is available
     */
    func didReceiveSignalStrength()
    
    /**
     * Method called after a pairing process is started and card readers were found nearby
     * @param readers, the list of readers available for pairing
     */
    func didFindReaders(readers:[ReaderInfo])
    
    /**
     * Method called when the currently paired device disconnects
     */
    func deviceDidDisconnect()
    
    /**
     * Method called after the 'connectTo' method was called by protocol implementing class, indicating that a connection to the selected reader is being established
     */
    func startedReaderConnection(with reader:ReaderInfo)
    
    /**
     * Method called in response to method 'searchRecentlyUsedReaders' and indicates that recently readers were found
     * @param readers. list of recently paired readers
     */
    func didFindRecentlyUsedReaders(readers:[ReaderInfo])
    
    /**
     * Method called to indicate that continuous search of nearby readers has started
     */
    func didBeginContinuousSearching()
    
    /**
     * Method called when a general error is encountered in a payment/transaction process
     */
    func didEncounteredGeneralError()
    
    /**
     * Method called when a transaction is finished
     * @param response, transaction response as received from the API
     * @param error, if not null it will contain the error received from the API
     */
    func didFinishTransaction(response: TransactionResponse?, error: ClearentResultError?)
    
    /**
     * Method called when a offline transaction is finished
     * @param error TransactionStoreStatus, the status off offline transaction proccesing
     */
    func didAcceptOfflineTransaction(err:TransactionStoreStatus)
    
    /**
     * Method called  when the process of uploading the signature image has completed
     * @param response, upload response as received from the API
     * @param error, if not null it will contain the error received from the API
     */
     func didFinishedSignatureUploadWith(response: SignatureResponse?, error: ClearentResultError?)
    
    /**
     * Method called when an offline signature was saved succesfully
     * @param error TransactionStoreStatus, the status off offline signature proccesing
     */
    func didAcceptOfflineSignature(err:TransactionStoreStatus, transactionID: String)
    
    /**
     * Method called each time the reader needs an action from the user
     * @UserAction, please check the enum for more cases
     * @action, User Action needed to be performed by the user
     */
    func userActionNeeded(action: UserAction)
    
    /**
     * Method called during a transaction process in case the reader's data is not encrypted. In order to perform transactions in offline mode, the reader should have both EMV & MSR encryption enabled. A warning message is displayed otherwise
     */
    func showEncryptionWarning()
}
