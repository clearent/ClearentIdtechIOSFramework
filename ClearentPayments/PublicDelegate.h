//
//  PublicDelegate.h
//  ClearentPayments
//
//  Created by David Higginbotham on 1/5/18.
//  Copyright © 2018 Clearent, L.L.C. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ClearentTransactionToken.h"

/** Protocol methods established for IDT_UniPayIII class  **/
@protocol Clearent_Public_IDT_UniPayIII_Delegate <NSObject>
@optional
-(void) deviceConnected; //!<Fires when device connects.  If a connection is established before the delegate is established (no delegate to send initial connection notification to), this method will fire upon establishing the delegate.
-(void) deviceDisconnected; //!<Fires when device disconnects.
- (void) plugStatusChange:(BOOL)deviceInserted; //!<Monitors the headphone jack for device insertion/removal.
//!< @param deviceInserted TRUE = device inserted, FALSE = device removed

//TODO Talk about this one. Sounds like we should not allow them to access this method.
- (void) dataInOutMonitor:(NSData*)data  incoming:(BOOL)isIncoming; //!<All incoming/outgoing data going to the device can be monitored through this delegate.
//!< @param data The serial data represented as a NSData object
//!< @param isIncoming The direction of the data
//!<- <c>TRUE</c> specifies data being received from the device,
//!<- <c>FALSE</c> indicates data being sent to the device.

- (void) deviceMessage:(NSString*)message;//!<Receives messages from the framework
//!< @param message String message transmitted by framework

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

- (void) lcdDisplay:(int)mode  lines:(NSArray*)lines;

/**
 * This will notify you when a Clearent Transaction Token has been successfully created based on the card data read from the ID Tech device.
 */
-(void) successClearentTransactionToken:(ClearentTransactionToken*)clearentTransactionToken;

/**
 * This will notify you when a Clearent Transaction Token failed to be created.
 */
//TODO Should be a response object
-(NSString*) errorClearentTransactionToken;

@end
