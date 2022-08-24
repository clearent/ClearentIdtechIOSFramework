![Screenshot](docs/clearent_logo.jpg)
# This is work in progress...

# IDTech iOS Framework :iphone: :credit_card:

Hi ! If you've stumbled across our GitHub and want to know what Clearent can do for you (spoiler alert, we do payments) go [here](https://developer.clearent.com/) to learn more. Or skip all that, get a sandbox key [here](https://developer.clearent.com/get-started/), and get online with us today. #wesupportdevs :bowtie:.

[Documentation](https://clearent.github.io/iosidtechframework.github.io/index.html)

## Overview (See [Demo](https://github.com/clearent/IDTech_VP3300_Objc_Demo) for more details)

Our iOS Framework works with the IDTech framework allowing you to handle credit card data from an IDTech VIVOpay reader (VP3300). The audio jack and bluetooth versions are supported.

The design is similar to the IDTech design so you can reference IDTech's documentation. The big difference is the methods exposed by the IDTech framework's delegate that would return credit card data to you is now handled by the Clearent framework. The Clearent solution implements the emvTransactionData and swipeMSRData IDTech methods on your behalf. Instead of working directly with the card data, the card data is sent to Clearent. Clearent will issue a 'Transaction Token' (aka, JWT) for each card read. The Transaction Token is sent back thru the delegate, allowing you to present it when you want to run a sale.

Visit the [Clearent Mobile API Docs](http://api.clearent.com/swagger.html#!/Quest_API_Integration/Mobile_Transactions_using_SDKs) to see how to run a mobile sale using our Rest endpoints.

Code references are in objective-c since the framework was built in that language. We are working on a [Swift](https://github.com/clearent/IDTechSwiftDemo) demo. Currently it shows you can connect with a bluetooth reader and get the transaction token back.

## Release Notes

[Release Notes](docs/RELEASE_NOTES.md) :eyes:

## Dependency Management.

You can use our [Clearent Cocoapod](https://github.com/clearent/CocoaPods) or [Carthage](https://github.com/Carthage/Carthage).

:new: CocoaPods latest version is 2.0.15.

### Carthage ###

:one: Install Carthage if you have not done so. ex - brew install carthage.

:two: Add your github credentials to XCode.

:three: Add a Cartfile to your project (at root). Point to Clearent's github repository for this framework by adding the following to your Cartfile

    github "clearent/ClearentIdtechIOSFramework" "2.0.5"

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

```smalltalk
#import <ClearentIdtechIOSFramework/ClearentIdtechIOSFramework.h>
```

:two: Change your interface to adhere to the Clearent public delegate (Clearent_Public_IDTech_VP3300_Delegate)

```smalltalk
@interface ViewController : UIViewController<UIAlertViewDelegate,Clearent_Public_IDTech_VP3300_Delegate, UIActionSheetDelegate,MFMailComposeViewControllerDelegate>
```

:three: Define the framework object you will interact with in ViewController.m.

```smalltalk
Clearent_VP3300 *clearentVP3300;
```

:four: Initialize the object

```smalltalk
clearentVP3300 = [[Clearent_VP3300 alloc]  init];

[clearentVP3300 init:self clearentBaseUrl:@"https://gateway-sb.clearent.net", @"the public key Clearent gave you"];
```

:five: Monitor for device readiness thru the isReady method of the delegate. You can also use the isConnected method of the Clearent_VP3300 object to verify the framework is still connected to the reader.

:six: Implement the successfulTransactionToken method. This method returns a token which represents the credit card and the current transaction request. It allows you to submit a payment transaction.
When a card is processed (swipe or insert/dip of card with an emv chip), the framework will call successfulTransactionToken method when tokenization is successful.

```smalltalk
-(void) successfulTransactionToken:(NSString*) jsonString {
  //This json contains the transaction token. See demo app for more details
}
```

:seven: Monitor for errors by implementing the deviceMessage and lcdDisplay methods. When you see the message INSERT/SWIPE it means
you should interact with the reader.

:eight: When you are ready to process the payment, do a POST against endpoint /rest/v2/mobile/transactions/sale (for a sale).

## Audio Jack Connectivity

* If an audio jack reader is connected to the iPad/iPhone you can monitor for the connection using a method you implement for the public delegate.

```smalltalk
- (void) plugStatusChange:(BOOL)deviceInserted;
```
* When you see the device is connected you call this method to finish setting the connection.

```objective-c
[clearentVP3300 device_connectToAudioReader];
```

## Bluetooth Connectivity

* If a bluetooth reader is used, you can monitor for a connection using this method.

```objective-c
[clearentVP3300 isConnected];
```

* You can use the framework to start scanning for a specific device or to do a general scan for any device that has the prefix of 'IDTECH-VP3300-'.

```smalltalk
[clearentVP3300 device_enableBLEDeviceSearch:val];
```

* Messages will be returned from this method you implemented for the public delegate. The returned message will contain 'BLE DEVICE FOUND' followed by the name.

```smalltalk
- (void) deviceMessage:(NSString*)message
```
* A quick flashing blue LED means the bluetooth reader is connected. A transaction can now be started.

* Slow blinking blue LED means the reader is on and listening for anyone to connect to.

* Am amber colored LED during a connection attempt means the reader is low on power. Charge the reader for at least 30 minutes.

* If you plug the reader in to a power source you can still use it over bluetooth but the connection, once established, will remain connected (and generally will be more reliable).

## Basic User Flow

:one: Start a transaction. The framework exposes 3 methods for starting a transaction - emv_startTransaction (dip and swipe), ctls_startTransaction (contactless only), and device_startTransaction. If you will never support contactless use emv_startTransaction. If you plan on supporting contactless we recommend the device_startTransaction method since it supports contactless, dip, and swipe.

```smalltalk
-(RETURN_CODE) device_startTransaction:(double)amount amtOther:(double)amtOther type:(int)type timeout:(int)timeout tags:(NSData*)tags forceOnline:(BOOL)forceOnline  fallback:(BOOL)fallback;
```

:two: Interact with reader - If you are using bluetooth make sure you've pressed the button on the reader. The bluetooth reader should have a blue led flashing quickly. This means it's connected and can communicate with the reader. The framework will callback in the deviceMessage with messages that indicate what is happening between the framework and the reader. If you see a message similar to 'Insert, swipe or, tap', that means the reader is ready for card interaction.

:three: Success - If you get a callback to the successfulTransactionToken it means the card was read successfully and translated to a transaction token. The transaction token is short lived (24 hr) and is meant to facilitate a payment, not to save the card for future use. If you want to store the card send in 'create-token' as true on the /rest/v2/mobile/transactions/sale endpoint and you will receive a Clearent Vault token id (token-id) that you can save and send in the 'card' field of future transactions.

:four: Failure - The framework will send messages back that indicate failure. ex - TERMINATE, 'Card read error'. When this happens, you can call the device_cancelTransaction method to cancel the current transaction and attempt again. If the problem persists it is recommended you key in the card and use the manual entry process.

## Use the Clearent Framework to create a transaction token (JWT) for a manually entered card - Objective C

:one: Change your interface to adhere to the delegate ClearentManualEntryDelegate

```smalltalk
@interface ViewController : UIViewController<UIAlertViewDelegate,Clearent_Public_IDTech_VP3300_Delegate, UIActionSheetDelegate,MFMailComposeViewControllerDelegate>,ClearentManualEntryDelegate
```

:two: Define the framework object you will interact with in ViewController.m.

```smalltalk
ClearentManualEntry *clearentManualEntry;
```

:three: Initialize the object

```smalltalk
clearentManualEntry = [[ClearentManualEntry alloc]  init];

[clearentManualEntry init:self clearentBaseUrl:@"https://gateway-sb.clearent.net", @"the public key Clearent gave you"];
```

:four: Implement the successfulTransactionToken method. If you have already implemented this for the IDTech Device solution you don't have to do anything extra.

```smalltalk
-(void) successfulTransactionToken:(NSString*) jsonString {
  //This json contains the transaction token. See demo app for more details
}
```

:five: Monitor for errors by implementing the handleManualEntryError method.

:six: When you are ready to process the payment, do a POST against endpoint /rest/v2/mobile/transactions/sale (for a sale). See demo app for an example [Clearent IDTech iOS Demo](https://github.com/clearent/IDTech_VP3300_Demo)

## Disabling emv configuration when using a preconfigured reader

By default Clearent will not apply (as of 1.1.8-beta) an emv configuration to your device. This configuration was determined by going through a certification process. The configuration can also be applied before the device is shipped to you. When this happens, you should disable the configuration feature. To do this, call this method on the Clearent_VP3300 object.

```smalltalk
- (void) setAutoConfiguration:(BOOL)enable;
```

If you want to check to see if the reader has already had configuration applied to it use this method (added 1.1.8-beta). When we configure a reader we alter the 9F4E tag to include 50 as a hex value (P for preconfigured).

```objective-c
[clearentVP3300 isPreconfigured];
```

## Enabling contactless

By default the framework will not apply the contactless emv configuration to your device. So no action needs to be taken for pre configured readers. If you are not using a pre configured reader you can pass true to enable configuration. When the reader is successfully configured a flag is set in the application's memory so it remembers not to apply the configuration on subsequent connections.

```smalltalk
- (void) setContactlessConfiguration:(BOOL)enable;
```

Independent of the contactless configuration is a flag to enable the use of contactless. By default the framework will throw the same error it did in the previous version until contactless is enabled.

```objective-c
[clearentVP3300 setContactless:true];
```

If you need the ability to apply contactless configuration after you have initialized the Clearent_VP3300 object you can use this method after you have enabled contactless configuration with the setContactlessConfiguration method.

```objective-c
[clearentVP3300 applyClearentConfiguration];
```

If you want to check to see if the reader has already had contactless configuration applied to it use this method.

```objective-c
[clearentVP3300 isContactlessConfigured];
```

## Contactless

* The amount field is required in order to fully support all scenarios we discovered during our certification process. If an amount is not provided, then large
amounts risk being declined.

* If an email address is available, provide it. In an event of an offline decline the customer will receive an offline decline receipt (email only).

* A new method has been created which allows you to pass in the email address when starting a transaction.

```smalltalk
ClearentPayment *clearentPayment = [[ClearentPayment alloc] init];
   [clearentPayment setAmount:amount];
   clearentPayment.amtOther = 0;
   clearentPayment.type = 0;
   clearentPayment.timeout = 30;
   clearentPayment.tags = nil;
   clearentPayment.emailAddress = txtReceiptEmailAddress.text;
   clearentPayment.fallback = true;
   clearentPayment.forceOnline = false;

   RETURN_CODE rt = [clearentVP3300 device_startTransaction:clearentPayment];
```   

* EMV Contactless cards , which have the wifi/network symbol on them, are supported. Cards put into an Apple Wallet are also supported. Cards that use the MSD Contactless standard are not supported.

:exclamation: The virtualized Apple Card is not supported.

* If a tap is attempted and the reader has trouble reading the card because it was not in the NFC field long enough, the framework will handle this error and start up a new transaction. This retry loop will send back a message of 'RETRY TAP' until either it's successful or the transaction is cancelled or timed out.

* Some times when the card and the reader interact an error will happen that does not allow contactless. When this happens the framework will cancel the transaction and start a new contact/swipe transaction. Contactless will be disabled allowing you to interact with the reader without fear of triggering the contactless read. You will be prompted with a message to "INSERT/SWIPE".

* There are times where the contactless interaction does not work (see [Known Issues](https://github.com/clearent/ClearentIdtechIOSFramework/blob/master/docs/RELEASE_NOTES.md#known-issues--different-behavior)). When this happens you can insert the contactless card *first*, then start the transaction.

* If you have already configured contactless and need to clear the cache that stops the framework from performing configuration every time the reader connects.
```objective-c
   [clearentVP3300 clearContactlessConfigurationCache];
```

* New helper method to configure everything at once. This method also gives you the ability to disable our remote logging (recommended for debug only).

```smalltalk
   ClearentVP3300Config *clearentVP3300Config = [[ClearentVP3300Config alloc] init];
   clearentVP3300Config.clearentBaseUrl = baseUrl;
   clearentVP3300Config.publicKey = publicKey;
   clearentVP3300Config.contactAutoConfiguration = false;
   clearentVP3300Config.contactlessAutoConfiguration = false;
   clearentVP3300Config.contactless = true;
   clearentVP3300Config.disableRemoteLogging = true;

   clearentVP3300 = [[Clearent_VP3300 alloc] initWithConfig:self  clearentVP3300Configuration:clearentVP3300Config];
```

## The Transaction Token (JWT)

 The successfulTransactionToken callback will get a message in JSON. It contains safe data about the card as well as the transaction token/JWT.

  * cvm - the card holder verification method

  * last-four - last four of the credit card number

  * track-data-hash - a hash representing the track data. This can be used as a unique id of the transaction.

  * jwt - This is the transaction token/JWT you will pass to us as a header when you perform a payment transaction.

## User experience when emv configuration is being applied.

When the Clearent framework applies the emv configuration to the reader it is using IDTech's framework for communication. This process can take up to a couple of minutes and also has its own unique failures that need to be managed (with possible retry logic). The Clearent framework has some retry capability to account for these failures (example bluetooth connectivity) but only attempts a limited number of times. It's up to the client app to account for this initial user experience. Once the reader has been configured the device serial number is cached so the framework knows not to configure again. If you want to avoid hitting this one time delay during a transaction flow you can advise the merchant to perform an initial connection with the reader, maybe at the time they pull the reader out of the box or some time prior to running transactions.

## Other tidbits

[Card Orientation in Reader](docs/card_orientation.gif)

# Go Live Checklist

- [ ] Finish Clearent Integration Certification
- [ ] Change base url from https://gateway-sb.clearent.net to https://gateway.clearent.net
- [ ] Change public key from sandbox to production
- [ ] Switch Clearent api keys from sandbox to production
- [ ] Confirm Clearent api keys are used server side only and not embedded in your app.
- [ ] :shipit: :city_sunset: :saxophone: :notes:

[From an ipad, download latest objc demo](https://github.com/clearent/ClearentIdtechIOSFramework/blob/2.0/apps/VP3300%202020-04-29%2006-18-09/index.html){:target="_blank"}.
