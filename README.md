# Clearent IDTech IOS Framework

This IOS Framework works with the IDTech framework allowing you to handle credit card data form an IDTECH VIVOpay reader (VP3300).

## Dependency Management.

You can use our [Clearent Cocoapod](https://github.com/clearent/CocoaPods) or [Carthage](https://github.com/Carthage/Carthage).

### Carthage ###

:one: Install Carthage if you have not done so. ex - brew install carthage.

:two: Add your github credentials to XCode.

:three: Add a Cartfile to your project (at root). Point to Clearent's github repository for this framework by adding the following to your Cartfile

    github "clearent/ClearentIdtechIOSFramework" == 1.0.26.4

:four: Run this command from your project's root folder. This command will pull down a copy of the Clearent Framework and build it locally under Carthage/Build.

    carthage update

:five: On your application targets’ General settings tab, in the Embedded Binaries section, drag and drop the Clearent Framework from the Carthage/Build folder.

:six: Additionally, you'll need to copy debug symbols for debugging and crash reporting on OS X.
    On your application target’s Build Phases settings tab, click the + icon and choose New Copy Files Phase.
    Click the Destination drop-down menu and select Products Directory.
    From the Clearent framework, drag and drop its corresponding dSYM file.

:seven: Build your app. The Clearent Framework should be available for use.

## Use the Clearent Framework with an IDTech device - Objective C

:one: Add this to your ViewController.h  
#import <ClearentIdtechIOSFramework/ClearentIdtechIOSFramework.h>

:two: Change your interface to adhere to the Clearent public delegate (Clearent_Public_IDTech_VP3300_Delegate)
Ex -@interface ViewController : UIViewController<UIAlertViewDelegate,Clearent_Public_IDTech_VP3300_Delegate, UIActionSheetDelegate,MFMailComposeViewControllerDelegate>

:three: Define the framework object you will interact with in ViewController.m.

Clearent_VP3300 *clearentVP3300;

:four: Initialize the object

clearentVP3300 = [[Clearent_VP3300 alloc]  init];

[clearentVP3300 init:self clearentBaseUrl:@"http://gateway-sb.clearent.net", @"the public key Clearent gave you"];

:five: Monitor for device readiness thru the isReady method of the delegate. You can also use the isConnected method of the Clearent_VP3300 object to verify the framework is still connected to the reader.

:six: Implement the successfulTransactionToken method. This method returns a token which represents the credit card and the current transaction request. It allows you to submit a payment transaction.
When a card is processed (swipe or insert/dip of card with an emv chip), the framework will call successfulTransactionToken method when tokenization is successful.

-(void) successfulTransactionToken:(NSString*) jsonString {
  //This json contains the transaction token. See demo app for more details
}

:seven: Monitor for errors by implementing the deviceMessage and lcdDisplay methods. When you see the message INSERT/SWIPE it means
you should interact with the reader.

:eight: When you are ready to process the payment, do a POST against endpoint /rest/v2/mobile/transactions/sale (for a sale). See demo app for an example [Clearent IDTech VP3300 iOS Demo](https://github.com/clearent/IDTech_VP3300_Demo)

## Basic User Flow

:one: Start a transaction. The framework exposes 3 methods for starting a transaction - emv_startTransaction (dip and swipe), ctls_startTransaction (contactless only), and device_startTransaction. If you will never support contactless use emv_startTransaction. If you plan on supporting contactless we recommend the device_startTransaction method since it supports contactless, dip, and swipe.

-(RETURN_CODE) device_startTransaction:(double)amount amtOther:(double)amtOther type:(int)type timeout:(int)timeout tags:(NSData*)tags forceOnline:(BOOL)forceOnline  fallback:(BOOL)fallback;

:two: Interact with reader - If you are using bluetooth make sure you've pressed the button on the reader. The bluetooth reader should have a blue led flashing quickly. This means it's connected and can communicate with the reader. The framework will callback in the deviceMessage with messages that indicate what is happening between the framework and the reader. If you see a message similar to 'Insert, swipe or, tap', that means the reader is ready for card interaction.

:three: Success - If you get a callback to the successfulTransactionToken it means the card was read successfully and translated to a transaction token. The transaction token is short lived (24 hr) and is meant to facilitate a payment, not to save the card for future use. If you want to store the card send in 'create-token' as true on the /rest/v2/mobile/transactions/sale endpoint and you will receive a Clearent Vault token id (token-id) that you can save and send in the 'card' field of future transactions.

:four: Failure - The framework will send messages back that indicate failure. ex - TERMINATE, 'Card read error'. When this happens, you can call the device_cancelTransaction method to cancel the current transaction and attempt again. If the problem persists it is recommended you key in the card and use the manual entry process.

## Use the Clearent Framework to create a transaction token (JWT) for a manually entered card

:one: Change your interface to adhere to the delegate ClearentManualEntryDelegate
Ex -@interface ViewController : UIViewController<UIAlertViewDelegate,Clearent_Public_IDTech_VP3300_Delegate, UIActionSheetDelegate,MFMailComposeViewControllerDelegate>,ClearentManualEntryDelegate

:two: Define the framework object you will interact with in ViewController.m.

ClearentManualEntry *clearentManualEntry;

:three: Initialize the object

clearentManualEntry = [[ClearentManualEntry alloc]  init];

[clearentManualEntry init:self clearentBaseUrl:@"http://gateway-sb.clearent.net", @"the public key Clearent gave you"];

:four: Implement the successfulTransactionToken method. If you have already implemented this for the IDTech Device solution you don't have to do anything extra.

-(void) successfulTransactionToken:(NSString*) jsonString {
  //This json contains the transaction token. See demo app for more details
}

:five: Monitor for errors by implementing the handleManualEntryError method.

:six: When you are ready to process the payment, do a POST against endpoint /rest/v2/mobile/transactions/sale (for a sale). See demo app for an example [Clearent IDTech iOS Demo](https://github.com/clearent/IDTech_VP3300_Demo)

## Disabling emv configuration when using a preconfigured reader

By default Clearent will apply an emv configuration to your device. This configuration was determined by going through a certification process. The configuration can also be applied before the device is shipped to you. When this happens, you should disable the configuration feature. To do this, call this method on the Clearent_VP3300 object.

- (void) setAutoConfiguration:(BOOL)enable;

## User experience when emv configuration is being applied.

When the Clearent framework applies the emv configuration to the reader it is using IDTech's framework for communication. This process can take up to a couple of minutes and also has its own unique failures that need to be managed (with possible retry logic). The Clearent framework has some retry capability to account for these failures (example bluetooth connectivity) but only attempts a limited number of times. It's up to the client app to account for this initial user experience. Once the reader has been configured the device serial number is cached so the framework knows not to configure again. If you want to avoid hitting this one time delay during a transaction flow you can advise the merchant to perform an initial connection with the reader, maybe at the time they pull the reader out of the box or some time prior to running transactions.


# Go Live Checklist

- [ ] Finish Clearent Integration Certification
- [ ] Change base url from https://gateway-sb.clearent.net to https://gateway.clearent.net
- [ ] Change public key from sandbox to production
- [ ] Switch Clearent api keys from sandbox to production
- [ ] Confirm Clearent api keys are used server side only and not embedded in your app.
   
# Release Notes

1.0.26 - Added remote logging. Any errors, and some informational messages, are sent to Clearent server to aid in support. No sensitive data is transmitted (ex-card data). Fixed an issue with the manual entry request. The software-type was not being sent. The logging solution uses the file system. It cleans up after itself, rotating logs every couple of minutes and transmitting data to server every minute (but only if there is something to transmit).

1.0.26.1 - New static methods to call before instantiating the Clearent_VP3300 object to avoid the microphone permission prompt. Use only if you exclusively use bluetooth readers.

[IDT_VP3300 disableAudioDetection];

[IDT_Device disableAudioDetection];

1.0.26.2 - ios13 fixes. (NSData description usage)

1.0.26.3 - discovered another ios13 fix. It's recommended that both audio jack users and bluetooth users upgrade.

Idtech introduced a new message that comes back in the callback. They modified the device_startTransaction to return a swipe/tap/insert display message, and modified ctls_startTransaction to return a tap/swipe message. This might impact your solution if you are coding off of these messages.

:new: 1.0.26.4 - Fixed an issue where the framework was not handling the card data correctly when the user has been presented with the 'USE MAGSTRIPE' message after an invalid insert. The result was an NSInvalidArgumentException being thrown.
