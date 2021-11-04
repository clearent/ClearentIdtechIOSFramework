//
//  ClearentPublicVP3300Delegate.h
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 6/22/18.
//  Copyright © 2018 Clearent, L.L.C. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ClearentTransactionToken.h"
#import "ClearentFeedback.h"
#import "ClearentBluetoothDevice.h"

/** Protocol methods established for IDT_UniPayIII class  **/
@protocol Clearent_Public_IDTech_VP3300_Delegate <NSObject>

/**
* This will notify you when a Clearent Transaction Token has been successfully created based on the card data read from the ID Tech device. The object returned represents a Clearent Response.
* When you want to perform the payment transaction use the 'jwt' from this response as a header called 'mobilejwt'. See demo for an example (the payment transaction API is not supported in
* this SDK).
*/
-(void) successTransactionToken:(ClearentTransactionToken *) clearentTransactionToken;

/**
 *  When the framework wants to communicate back it will call this method.
 */
- (void) feedback:(ClearentFeedback*) clearentFeedback;


@optional

- (void) deviceMessage:(NSString*)message __deprecated_msg("Still required but will be removed in the future. Use feedback method in version 2 and greater.");//!<Receives messages from the framework
//!< @param message String message transmitted by framework

/**
 * This will notify you when a Clearent Transaction Token has been successfully created based on the card data read from the ID Tech device. The json returned represents a Clearent Response.
 * When you want to perform the payment transaction use the 'jwt' from this response as a header called 'mobilejwt'. See demo for an example (the payment transaction API is not supported in
 * this SDK).
 */
-(void) successfulTransactionToken:(NSString*)jsonString __deprecated_msg("use successTransactionToken method with ClearentTransactionToken instead.");


-(void) deviceConnected; //!<Fires when device connects.  If a connection is established before the delegate is established (no delegate to send initial connection notification to), this method will fire upon establishing the delegate.

-(void) deviceDisconnected; //!<Fires when device disconnects.

- (void) plugStatusChange:(BOOL)deviceInserted; //!<Monitors the headphone jack for device insertion/removal.
//!< @param deviceInserted TRUE = device inserted, FALSE = device removed

/**
 LCD Display Request
 During an EMV transaction, this delegate will receive data to clear virtual LCD display, display messages, display menu, or display language.  Applies to UniPay III
 @param mode LCD Display Mode:
 - 0x01: Menu Display.  A selection must be made to resume the transaction
 - 0x02: Normal Display get function key.  A function must be selected to resume the transaction
 - 0x03: Display without input.  Message is displayed without pausing the transaction
 - 0x04: List of languages are presented for selection. A selection must be made to resume the transaction
 - 0x10: Clear Screen. Command to clear the LCD screen
 */
//Deprecated - Use message method

- (void) lcdDisplay:(int)mode  lines:(NSArray*)lines __deprecated_msg("use feedback method instead.");

/**
 *  If you started a payment and asked the framework to connect to a bluetooth device, and the device is not found, or you were asking for a general scan, the framework will send back a list of
 *      bluetooth devices it found within the scan time you provided.
 */

- (void) bluetoothDevices:(NSArray<ClearentBluetoothDevice*>*) bluetoothDevices;

@end
