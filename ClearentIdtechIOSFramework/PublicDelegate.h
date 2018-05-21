//
//  PublicDelegate.h
//  ClearentPayments
//
//  Created by David Higginbotham on 1/5/18.
//  Copyright © 2018 Clearent, L.L.C. All rights reserved.
//

#import <Foundation/Foundation.h>

/** Protocol methods established for IDT_UniPayIII class  **/
@protocol Clearent_Public_IDTech_VP3300_Delegate <NSObject>

/**
 * Provide the url Clearent gives you to create a transaction token (JWT) representing the transaction request. When you are developing, point this url to the Clearent Sandbox. When you go live
 * switch it to the Clearent Live/Production url.
 */
- (NSString*) getTransactionTokenUrl;

/**
 * Provide the public key Clearent gives you. This will be presented as a header when calling the transaction token url. When you are developing, use the Clearent Sandbox public key.
 * When you go live switch to your Clearent Live/Production public key.
 */
- (NSString*) getPublicKey;

/**
 * This will notify you when a Clearent Transaction Token has been successfully created based on the card data read from the ID Tech device. The json returned represents a Clearent Response.
 * When you want to perform the payment transaction use the 'jwt' from this response as a header called 'emvjwt'. See demo for an example (the payment transaction API is not supported in
 * this SDK).
 */
-(void) successfulTransactionToken:(NSString*)jsonString;

/**
 * This will notify you when a Clearent Transaction Token failed to be created.
 */
-(void) errorTransactionToken:(NSString*)message;

@optional
-(void) deviceConnected; //!<Fires when device connects.  If a connection is established before the delegate is established (no delegate to send initial connection notification to), this method will fire upon establishing the delegate.
-(void) deviceDisconnected; //!<Fires when device disconnects.
- (void) plugStatusChange:(BOOL)deviceInserted; //!<Monitors the headphone jack for device insertion/removal.
//!< @param deviceInserted TRUE = device inserted, FALSE = device removed

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

//TODO Should this be exposed ? probably ok if there is no sensitive data.
- (void) dataInOutMonitor:(NSData*)data  incoming:(BOOL)isIncoming;

@end

