//
//  ClearentVP3300Configuration.h
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 10/2/19.
//  Copyright © 2019 Clearent, L.L.C. All rights reserved.
//

#import <Foundation/Foundation.h>

/** When you start a transaction you can pass this object in to describe the payment request.
 amount,amtOther,type,timeout,tags,forceOnline,fallback - are all passthrough values for the IDTech framework. Clearent will use the amount and email address with its system but the rest help IDTech's framework work.
 
 clearentBaseUrl -  required either point to prod - gateway.clearent.net or sandbox gateway-sb.clearent.net
 publicKey - required pass in the public key Clearent gave you (use the PROD public key for production and the sandbox public key for sandbox)
 
 contactAutoConfiguration - enable the clearent feature to apply an emv contact configuration to the reader. This is bypassed if the configuration cache has recorded the reader is already configured (use clearConfigurationCache to reset)
 contactlessAutoConfiguration - enable the clearent feature to configure contactless. This is bypassed if the configuration cache has recorded the reader is already configured (use clearConfigurationCache to reset)
 contactless - enable the ability to run contactless transactions. This is defaulted to false and is independent of contactless configuration.
 
 disableRemoteLogging - disable clearent's remote logging feature. Remote logging is enabled by default.

 **/
@protocol ClearentVP3300Configuration <NSObject>

- (NSString*) clearentBaseUrl;
- (NSString*) publicKey;

@optional
- (BOOL) contactAutoConfiguration;
- (BOOL) contactlessAutoConfiguration;
- (BOOL) contactless;
- (BOOL) disableRemoteLogging;
- (BOOL) enableEnhancedFeedback;

@end
