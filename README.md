![Screenshot](docs/clearent_logo.jpg)

# Clearent SDK UI

## Overview 

**Clearent SDK UI** is a wrapper over **ClearentFrameworkSDK** that provides payment capabilities using the **IDTech** iOS framework to read credit card data using **VP3300**. Its goal is to ease integration by providing complete UI that handle all important flows end-to-end.


 **Clearent SDK UI** wraps all major features of the ClearentFrameworkSDK and adds UI for all major flows:

1. **Pairing Flow**, guides the user through the pairing process steps, taking care of edge cases and possible errors.

2. **Transaction Flow**, guides the user through the transaction flow, handling also device pairing if needed, takes care of edge cases and error handling.

3. **Settings**, this provides access to readers list & reader details screens, offline mode options and email receipt toggle.

**Clearent SDK UI - Options**

1. **Tips**, when this feature is enabled, a tips screen will be displayed during the transaction flow, where the user/client is prompted with UI that will offer some options to choose a tip. This feature can be enabled or disabled from your merchant account.

2. **Signature**, when this feature is enabled, the SDK will display a screen where the user/client can provide a signature. This signature will be uploaded to the Clearent backend. This feature can be enabled when initializating the SDK UI.

3. **Email receipt**, if this is enabled in settings screen, as a last step in the transaction flow, the user will be prompted to enter an email address to which the transation receipt will be sent.

4. **Store and Forward**, if this is available, settings screen will display a section related to it. The feature can be activated by passing `offlineModeEncryptionKeyData` to SDK UI. Depending on the options the user enables in settings screen, transactions will be stored locally or they will be uploaded to the Clearent backend. If transactions are saved locally, a "Process" button will appear on settings, under the "Offline mode options" section. Tapping on the button will trigger the upload of the local transactions. An upload report will then be available in settings screen.

5. **UI Customization**, Clearent SDK UI provides the integrator the chance to customize the fonts, colors and texts used in the UI. This is achieved by overwriting the public properties of each UI element that is exposed.

6. **Enhanced Messages**, when this feature is enabled, the feedback that the SDK is providing uses friendlier messages, this messages are stored in the enhancedmessages-v1.txt file from the ClearentIdtechMessages bundle.
    The host app will need to include the bundle in build phases copy resources section.


## Dependencies

 **Clearent SDK UI** does not use any other dependencies except the ones of the ClearentFrameworkSDK:
 
 - IDTech.xcframework 
 - DTech.bundle (responsible for translating error codes to messages)
 - CocoaLumberJack.xcframework


## Package Management 

**Example Podfile**
```
source 'https://github.com/clearent/CocoaPods.git'
source 'https://github.com/CocoaPods/Specs.git'

# Uncomment the next line to define a global platform for your project
# platform :ios, '13.0'

target 'ExampleSwift' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  pod 'ClearentIdtechIOSFrameworkPod', '4.0.63' 
  # Pods for ExampleSwift
end
```



## Supported iOS versions

The SDK supports current version of iOS and two previous versions. Curently 14, 15 and 16.

## How to Integrate

In order to integrate the **SDK UI** you will need to create a configuration object and pass it to `ClearentUIManager`, like in the following example: 

```
let uiManagerConfig =
        ClearentUIManagerConfiguration(baseURL: baseURL, apiKey: apiKey, publicKey: publickKey,  tipAmounts: [1, 2, 3], offlineModeEncryptionKeyData: encryptionKeyData, enableEnhancedMessaging: true, signatureEnabled: true)
ClearentUIManager.shared.initialize(with: uiManagerConfig)
```

### Important!

**The safe keeping of the `BASE URL`, `API KEY` and the `PUBLIC KEY` is the integrators reposability. The SDK stores this information only in memory!  
API KEY can be nil as long as web authentication is used: ClearenwtWrapper.shared.updateWebAuth(...). This implies having a vt-token from the web side.  
If no PUBLIC KEY is passed to the SDK, the value will be fetched each time a transaction is being made.**


**Tips** 

This feature can be enabled from your merchant account and when it's enabled, the user/client is prompted during the transaction flow with UI that will offer some options to choose a tip. The options the user/client has are three fixed options in percents and a custom tip input field. The three options are customizable by setting the `tipAmounts` that is an array of Int values property of the `ClearentUIManagerConfiguration`.


Now you are ready to use the SDK UI. 
In order to display the UI from the SDK you need to have an instance of `UINavigationController` that you will use to present specific UIControllers from the SDK.

**Starting the pairing process**

```
let pairingVC = ClearentUIManager.shared.pairingViewController(completion: {})
navigationController?.present(pairingVC, animated: true, completion: { })
```

**Starting a transaction**

Every time you start a transaction you need to pass an instance of `PaymentInfo` to the payment controller. This object should contain the amount and some optional parameters like customerID, invoice, orderID, etc.
The SDK UI provides the option to enter the card details manually or by using the card reader, use the `cardReaderPaymentIsPreffered` to choose the desired method. If this method fails, the option to use manual payment can be displayed in UI as a fallback method.

```
ClearentUIManager.shared.cardReaderPaymentIsPreffered = true
```

```
let transactionVC = ClearentUIManager.shared.paymentViewController(paymentInfo: PaymentInfo(amount: 20.0), completion: {})
navigationController?.present(transactionVC, animated: true, completion: {})
```


**Showing settings screen**

```
let settingsVC = ClearentUIManager.shared.settingsViewController(completion: {}) 
navigationController?.present(settingsVC, animated: true)
```

The settings screen will display the following sections:
 - a link that shows the current reader. When tapping on it, a new page will display the status of the current reader and a list of recently paired readers. From this list the user can navigate to the readers details.
 - offline mode related elements, option to process offline transaction and to see an upload report. These are displayed only if offline mode feature is available. Otherwise, the section is hidden.
 - a toggle used to enable/disable email receipt

Another way for accesing the reader info is to use `ClearentWrapperDefaults` class that has two important public properties: 

- recentlyPairedReaders, a list of ReaderInfo objects, containing previously paired devices
- pairedReaderInfo, a ReaderInfo? object representing the current paired reader


**Reader Status**

If you want to display the reader's status in your app you cand use the `readerInfoReceived` closure of the `ClearentUIManagerConfiguration`.


Here is the defintion of the closure. You will receive a `ReaderInfo` object that contains reader related information:

```
public var readerInfoReceived: ((_ readerInfo: ReaderInfo?) -> Void)?

```

How to use it.

```
ClearentUIManager.configuration.readerInfoReceived = { [weak self] reader in
    // update your UI
}
```


## Customizing the SDK experience

The SDK provides the option to customize the fonts, colors and texts used in the SDK. This can be achieved by overriding properties of the **ClearentUIBrandConfigurator** class that is a singleton. Check our [Swift Example](https://github.com/clearent/idtech-ios-sdk/tree/main/ExampleSwift) for full customization example.

**Colors**

```
ClearentUIBrandConfigurator.shared.colorPalette = ClientColorPalette()
```

`ClientColorPalette` is a class that you will need to write and implement `ClearentUIColors` protocol. 


**Fonts**

You will need to implement a class that will adopt `ClearentUIFonts` protocol and load your custom fonts.


```
UIFont.loadFonts(fonts: ["Arial Bold.ttf", "Arial.ttf"], bundle: Constants.bundle)
ClearentUIBrandConfigurator.shared.fonts = ClientFonts()
```

**Texts**

In order to customize texts used in the SDK you will need to provide a dictionary containing the new messages you want to show.

```
ClearentUIBrandConfigurator.shared.overriddenLocalizedStrings = [
    "xsdk_tips_custom_amount": "🍎Custom amount",
    "xsdk_tips_user_transaction_tip_title": "🍎Would you like to add a tip?",
    "xsdk_tips_user_action_transaction_with_tip": "🍎Charge %@",
    "xsdk_tips_user_action_transaction_without_tip":"🍎Maybe next time"
]
```


## Swift Code Example

Swift example of the **ClearenSDKUI** integration [Swift Example](https://github.com/clearent/idtech-ios-sdk/tree/main/ExampleSwift).

```
import UIKit
import ClearentSDKUI

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        initSDK()
    }
    
    func initSDK() {
        
        // Setup the SDK with needed config to work properly
        let encryptionKeyData = Crypto.SHA256hash(data: "some_secret_here".data(using: .utf8)!)
        let uiManagerConfig =
        ClearentUIManagerConfiguration(baseURL: "https....", apiKey: "api key...", publicKey: nil, offlineModeEncryptionKeyData: encryptionKeyData, enableEnhancedMessaging: true, signatureEnabled: true)
        
        ClearentUIManager.shared.initialize(with: uiManagerConfig)
        
        // Load the default fonts from our SDK
        UIFont.loadFonts()
    }
    
    
    // MARK: Actions
    
    @IBAction func startPairingProcess(_ sender: Any) {
        let pairingVC = ClearentUIManager.shared.pairingViewController() { [weak self] error in
            // do something here after dismiss
        }
        navigationController?.present(pairingVC, animated: true, completion: { })
    }
    
    @IBAction func startCardReaderTransaction(_ sender: Any) {
        let paymentInfo = PaymentInfo(amount: randomCGFloat())
        ClearentUIManager.shared.cardReaderPaymentIsPreferred = true
        
        let paymentVC = ClearentUIManager.shared.paymentViewController(paymentInfo: paymentInfo) { [weak self] error in
            // do something here after dismiss
        }
        navigationController?.present(paymentVC, animated: true)
    }
    
    @IBAction func startManualEntryTransaction(_ sender: Any) {
        let paymentInfo = PaymentInfo(amount: randomCGFloat())
        ClearentUIManager.shared.cardReaderPaymentIsPreferred = false
        
        let paymentVC = ClearentUIManager.shared.paymentViewController(paymentInfo: paymentInfo) { [weak self] error in
            // do something here after dismiss
        }
        navigationController?.present(paymentVC, animated: true)
    }
    
    @IBAction func showSettingsScreen(_ sender: Any) {
        let settingsVC = ClearentUIManager.shared.settingsViewController() { [weak self] error in
            // do something here after dismiss
        }
        navigationController?.present(settingsVC, animated: true)
    }
}

```

## Objective-C Code Example

Objective-C example of the **ClearenSDKUI** integration [Obj-C Example](https://github.com/clearent/idtech-ios-sdk/tree/main/ObjC-Example).

```
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Initalize the SDK UI with needed info to work properly
    // ! Make sure you update the apiKey with the correct value in order to test the SDK !
    
    NSData* encryptedKey = [Crypto SHA256hashWithData:[@"some_secret_here" dataUsingEncoding: NSUTF8StringEncoding]];
    ClearentUIManagerConfiguration* uiManagerConfig = [[ClearentUIManagerConfiguration alloc]
                                                       initWithBaseURL:@"https:..."
                                                       apiKey:@"api key..."
                                                       publicKey:nil
                                                       offlineModeEncryptionKeyData:encryptedKey
                                                       enableEnhancedMessaging:false
                                                       tipAmounts:@[@15, @18, @20]
                                                       signatureEnabled:true];
    [[ClearentUIManager shared] initializeWith:uiManagerConfig];

    [UIFont loadFontsWithFonts:[NSArray arrayWithObjects: @"SF-Pro-Display-Bold.otf", @"SF-Pro-Text-Bold.otf", @"SF-Pro-Text-Medium.otf", nil] bundle:ClearentConstants.bundle];
}

- (IBAction)showSettings:(id)sender {
    UIViewController *vc = [[ClearentUIManager shared] settingsViewControllerWithCompletion:^(ClearentError* error) {
        //do something that you want on dismiss
    }];
    [self presentViewController:vc animated:YES completion:nil];
}

- (IBAction)startPairing:(id)sender {
    UIViewController *vc = [[ClearentUIManager shared] pairingViewControllerWithCompletion:^(ClearentError* error) {
        //do something that you want on dismiss
    }];
    [self presentViewController:vc animated:YES completion:nil];
}

- (IBAction)startCardReaderTransaction:(id)sender {
    [ClearentUIManager shared].cardReaderPaymentIsPreferred = true;
    PaymentInfo *paymentInfo = [[PaymentInfo alloc] initWithAmount:20.00 customerID:nil invoice:nil orderID:nil billing:nil shipping:nil softwareType:nil webAuth:nil];
    UIViewController *vc = [[ClearentUIManager shared] paymentViewControllerWithPaymentInfo:paymentInfo completion:^(ClearentError* error) {
        //do something that you want on dismiss
    }];
    [self presentViewController:vc animated:YES completion:nil];
}

- (IBAction)startManualTransaction:(id)sender {
    [ClearentUIManager shared].cardReaderPaymentIsPreferred = false;
    PaymentInfo *paymentInfo = [[PaymentInfo alloc] initWithAmount:30.00 customerID:nil invoice:nil orderID:nil billing:nil shipping:nil softwareType:nil webAuth:nil];
    UIViewController *vc = [[ClearentUIManager shared] paymentViewControllerWithPaymentInfo:paymentInfo completion:^(ClearentError* error) {
        //do something that you want on dismiss
    }];
    [self presentViewController:vc animated:YES completion:nil];
}

@end

```


# Integrating the ClearentWrapper (Swift Only)


## Overview

**ClearentWrapper** is a wrapper over **ClearentFrameworkSDK** that provides payments capabilities using the IDTech iOS framework to read credit card data using VP3300. Its goal is to ease integration and fix some of the most common issues.

`ClearentWrapper` is a singleton class and the main interaction point with the SDK.  

You will use this class to update the SDK with the needed information to work properly : **API URL**, **API KEY** and the **PUBLIC KEY**. 

**Important Note:**

The safe keeping of the `API URL`, `API KEY` and the `PUBLIC KEY` is the integrators reposability. The SDK stores this information only in memory!
If no public key is passed, this will be fetched from the web.

`ClearentWrapperProtocol` is the protocol you will need to implement in order to receive updates, error and notifications from the SDK. Each method from the protocol is documented in code.

`ClearentWrapperDefaults` is a user default storage that holds information like currently paired reader and a list of previously paired readers. You should not save anything here the SDK handles this for you.

`Enhanced Messages`, when this feature is enabled, the feedback that the SDK is providing uses friendlier messages, this messages are stored in the `enhancedmessages-v1.txt` file from the ClearentIdtechMessages bundle.
    The host app will need to include the bundle in build phases copy resources section.

## Supported iOS versions

The SDK supports current version of iOS and two previous versions. Curently 14, 15 and 16.

## Pairing a reader.

In order to perform transaction using the VP3300 card reader you will need to pair (connect) the device using Bluetooth, the Bluetooth connectivity is handled by the SDK .

In this step the SDK performs a Bluetooth search in order to discover the card readers around. In order for the device to be discoverable, it needs to be turned on and in range of the mobile device. The result of the Bluetooth search is a list of devices of type ReaderInfo and you will get the list from the delegate method `didFindReaders(readers: [ReaderInfo])`.  
Once you have the list of available readers the next step is to select the reader you want to connect to using the `connectTo(reader: ReaderInfo)` method that will try to connect the reader. Once the SDK manages to connect to the reader the delegate method didFinishPairing will get called indicating the connection was successful. 


## Performing a transaction

You can perform a transaction in two modes: using a card reader or by using the card details directly.

**1.Performing a transaction using the card reader.**

A transaction is performed in two steps :

1. Reading the card, the IDTech framework reads the card info and provides a jwt (token).
2. Performing an API call that will send the transaction information together with the JWT token to a payment gateway.

You can start a transaction using `func startTransaction(with saleEntity: SaleEntity, isManualTransaction: false, completion: @escaping((ClearentError?) -> Void))`. You need to provide a `SaleEntity` that will contain the amount, you can also specify a tip and client related information. 

When you call the startTransaction method the SDK will start guide you to the process by calling two important methods from the ClearentWrapperProtocol  : 

1. **userActionNeeded(action: UserAction)** , indicates that the user need to do an action like swiping the card, removing the card etc.
2. **didReceiveInfo(info: UserInfo)**, this method presents different information related to the transaction.

After the transaction is completed the delegate method didFinishTransaction(response: TransactionResponse?, error: ClearentError?) will get called. You can check the error parameter to know if the transaction was successful or not.

**2. Performing a transaction using manual card entry.**

You can start a transaction using `startTransaction(with saleEntity: SaleEntity, isManualTransaction: true, completion: @escaping((ClearentError?) -> Void))` method.


**Cancelling, voiding and refunding a transaction**

If you started a card reader transaction and want to cancel it you can use cancelTransaction() method and after this call the card reader will be ready to take another transaction. You can use this method only before the card is read by the card reader. Once the card has been read the transaction will be performed and the transaction will be also registered by the payment gateway. In this case you can use the `func voidTransaction(transactionID: String, completion: @escaping (TransactionResponse?, ClearentError?) -> Void)` to void the transaction you want (this will work only if the transaction was not yet processed by the gateway). Another option is to perform a refund using the `func func refundTransaction(jwt: String, saleEntity: SaleEntity, completion: @escaping (TransactionResponse?, ClearentError?) -> Void)`.


## Getting information related to the card reader status

You can obtain a `ReaderInfo`  object from `ClearentWrapperDefaults.pairedReader`.  
Sometimes you will need to request and display new information related to the reader like battery status or signal strength. You can achieve this by using the startDeviceInfoUpdate()` method, calling this method will start fetching new information from the connected reader and when this information will be available it will call `readerInfoReceived: ((_ readerInfo: ReaderInfo?) -> Void)?` closure that you will need to implement in your code.


## Getting information related to previously paired readers

Each time you pair a new reader the SDK will save its information in a User Defaults cache. You can get the list using `recentlyPairedReaders` property of the `ClearentWrapperDefaults`. The result will be an array of `ReaderInfo` objects.

You can check if a reader is connected by using the `isReaderConnected()` method or by checking the `isConnected` property of the `ClearentWrapperDefaults.pairedReader`.


## Uploading a signature

If you want to upload a signature image after a transaction, you can use 
`func sendSignatureWithImage(image: UIImage, completion: @escaping (SignatureResponse?, ClearentError?) -> Void)`. After this method is called, the `didFinishedSignatureUploadWith(response: SignatureResponse?, error: ClearentError?)` delegate method will be called.  Note that the sendSignature method will use the latest transaction ID as the ID for the signature in the API call.
If an error occurs you can use the `resendSignature(completion: @escaping (SignatureResponse?, ClearentError?) -> Void)` method to retry the upload of the signature.

## Email receipt
If you want to email the receipt after a transaction, you can use 
`func sendReceipt(emailAddress: String, completion: @escaping (ReceiptResponse?, ClearentError?) -> Void)`. After this method is called, the `func didFinishedSendingReceipt(response: ReceiptResponse?, error: ClearentError?)` delegate method will be called. Note that the sendReceipt method will use the latest transaction ID in the API call.

## Process offline transactions

Store and forward feature is available if `offlineModeEncryptionKeyData` is passed to the SDK initialization. This means that while offline mode is enabled, all transaction will be stored locally. To upload offline transaction when internet is on, the following method needs to be called.
`func processOfflineTransactions(completion: @escaping ((ClearentError?) -> Void))`

## Relevant code snippets


**Initialisation**  

```
let encryptionKeyData = Crypto.SHA256hash(data: "some_secret_here".data(using: .utf8)!)
let clearentWrapperConfiguration = ClearentWrapperConfiguration(baseURL: baseURL, apiKey: apiKey, publicKey: nil, offlineModeEncryptionKeyData: encryptionKeyData)
ClearentWrapper.shared.initialize(with: clearentWrapperConfiguration)

// You will need to implement the delegate methods
ClearentWrapper.shared.delegate = self
```


**Pairing a device**  

Calling this method will start the process of pairing a card reader with an iOS device.

```
ClearentWrapper.shared.startPairing(reconnectIfPossible: true)
```

After the search for readers is completed, the SDK will trigger a delegate method. 

```
func didFindReaders(readers: [ReaderInfo])  {
    // you can display the list of readers on the UI
}
```

After the user selects one of the readers from the list you need to tell the SDK to connect to it.

```
// reader is a ReaderInfo item
ClearentWrapper.shared.connectTo(reader: reader)
```

The SDK will try to connect to the selected device and it will call the `didFinishedPairing()` method when finished.
Now you have a paired reader and you can start using it for performing transactions.


**Performing a transaction**  

Using a card reader

```
// Define a SaleEntity, you can also add client information on the SaleEntity
let saleEntity = SaleEntity(amount: 22.0, tipAmount: 5)
ClearentWrapper.shared.startTransaction(with: SaleEntity, isManualTransaction: false) { error in
    // handle completion
}
```

Using manual card entry

```
// Create a SaleEntity object and, besides amount, add card info
let saleEntity = SaleEntity(amount: 22.0, tipAmount: 5, card: "4111111111111111", csc: "999", expirationDateMMYY: "11/28")
ClearentWrapper.shared.startTransaction(with: saleEntity, manualEntryCardInfo: true) { error in
    // handle completion
}
```

After starting a transaction, feedback messages will be triggered on the delegate.


`userActionNeeded` indicates that the user/client needs to perform an action in order for the transaction to continue e.g. Insert the card.
```
func userActionNeeded(action: UserAction) {
    // here you should check the user action type and display the informtion to the users
}
```


User info contains information related to the transaction status e.g. Processing

```
func didReceiveInfo(info: UserInfo) {
    // you should display the information to the users
}
```


After the transaction is proccesed, a delegate method will inform you about the status.

```
func didFinishTransaction(response: TransactionResponse?, error: ClearentError?) {
    if error == nil {
        // no error
    } else {
        // you should inform about the error
    }
}
```


Full Swift example of the **ClearentWrapper** integration: [Swift Wrapper Example](https://github.com/clearent/idtech-ios-sdk/tree/main/ExampleSwiftWrapper).
