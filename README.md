![Screenshot](docs/clearent_logo.jpg)

# Clearent SDK UI

## Overview 

Clearent SDK UI is a wrapper over ClearentFrameworkSDK that provides payment capabilities using the IDTech iOS framework to read credit card data using VP3300. Its goal is to ease integration by providing complete UI that handle all important flows end-to-end.


 **Clearent SDK UI** wraps all major features of the ClearentFrameworkSDK and adds UI for all major flows:

1. **Pairing Flow**, guides the user through the pairing process steps, taking care of edge cases and possible errors.

2. **Transaction Flow**, guides the user through the transaction flow, handling also device pairing if needed, takes care of edge cases and error handling.

3. **Readers List & Reader Details**, this flow provides reader management capabilities, it displays the status of the current paired reader, but also a list of recently used readers from where you can navigate to a settings screen of the reader.

**Clearent SDK UI - Options**

1. **Tips**, when this feature is enabled the first step in the Transaction Flow will be the tips screen where the user/client is prompted with UI that will offer some options to choose a tip. This feature can be enabled or disabled from your merchant account.

2. **Signature**, when this feature is enabled as a last step in the Transaction Flow the SDK will display a screen  where the user/client can provide a signature. This signature will be uploaded to the Clearent backend.

3. **UI Customization**, Clearent SDK UI provides the integrator the chance to customize the fonts, colors and texts used in the UI, This is achieved by overwriting the public properties of each UI element that is exposed.


## Dependencies

 **Clearent SDK UI** does not use any other dependencies except the ones of the ClearentFrameworkSDK:
 
 - IDTech.xcframework 
 - DTech.bundle (responsible for translating error codes to messages)
 - CocoaLumberJack.xcframework


## Package Management - (To be updated with correct information)

// podfile & cartfile example 

## Supported iOS versions

The SDK supports current version of iOS and two previous versions. Curently 13, 14 and 15.

## How to Integrate

In order to integrate the **SDK UI** you will need the **API URL**, **API KEY** and the **PUBLIC KEY**. 
Use ClearentUIManager class to update the SDK with this information like this. 

```
ClearentUIManager.shared.updateWith(baseURL: baseURL, apiKey: apiKey, publicKey: publicKey)
```

### Important!

**The safe keeping of the **API URL**, **API KEY** and the **PUBLIC KEY** is the integrators reposability. The SDK stores this information only in memory!**


**Tips** 

This feature can be enabled from your merchant account and when it's enabled the first step in the transaction flow will be a prompt where the user/client is prompted with UI that will offer some options to choose a tip. The options the user/client has are three fixed options in percents and a custom tip input field. The three options are customizable by settting the **tipAmounts** that is an array of Int values property of the **ClearentUIManager** as below.

```
ClearentUIManager.tipAmounts = [5, 15, 20]
```


**Disabling the signature functionality**
The signature feature is enabled by default, if you want to disable it:
```
ClearentUIManager.shared.signatureEnabled = false
```

Now you are ready to use the SDK UI. 
In order to display the UI from the SDK you need to have an instance of **UINavigationController** that you will use to present specific UIControllers from the SDK.

**Starting the pairing process**

```
let pairingVC = ClearentUIManager.shared.pairingViewController()
self.navigationController?.present(pairingVC, animated: true, completion: {})
```

**Starting a transaction**

Every time you start a transaction you need to pass the amount as Double to the payment controller.
The SDK UI provides the option to enter the card details manualy or by using the card reader, use the **useCardReaderPaymentMethod** to choose the desired method.

```
 ClearentUIManager.shared.useCardReaderPaymentMethod = true
```

```
let transactionVC = ClearentUIManager.shared.paymentViewController(amount: 20.0)
self.navigationController?.present(transactionVC, animated: true, completion: {})
```


**Showing readers list & reader details**

```
let readerDetailsVC = ClearentUIManager.shared.readersViewController()
self.navigationController?.present(readerDetailsVC, animated: true, completion: { })
```
The reader details will display the status of the current reader and a list of recently paired readers. From this list the user can navigate to the readers details.


**Reader Status**

If you want to display the reader's status in your app you cand use the  **readerInfoReceived** clojure of the **ClearentUIManager**.


Here is the defintion of the clojure. You will receive a **ReaderInfo** object that contains reader related information.
```
public var readerInfoReceived: ((_ readerInfo: ReaderInfo?) -> Void)?

```

How to use it.

```
ClearentUIManager.shared.readerInfoReceived = { [weak self] reader in
    // update your UI
}
```


## Customizing the SDK experience

The SDK provides the option to customize the fonts, colors and texts used in the SDK. This can be achieved by overriding properties of the **ClearentUIBrandConfigurator** class that is a singleton. Check our [Swift Example](https://) for full customization example.

**Colors**
```
ClearentUIBrandConfigurator.shared.colorPalette = ClientColorPalette()
```

**ClientColorPalette** is a class that you will need to write and implement **ClearentUIColors** protocol. 


**Fonts**

You will need to implement a class that will implement **ClearentUIFonts** protocol and load your custom fonts.


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

Swift example of the ClearenSDKUI  integration [Swift Example](https://).

```
import UIKit
import ClearentSDKUI

class ViewController: UIViewController {
    
    @IBOutlet weak var showReadersDetailsButton: UIButton!
    @IBOutlet weak var startTransactionButton: UIButton!
    @IBOutlet weak var startPairingButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initSDK()
    }
    
    func initSDK() {
        
        // Update the SDk with needed info to work properly
        ClearentUIManager.shared.updateWith(baseURL: Api.baseURL, apiKey: Api.apiKey, publicKey: Api.publicKey)
        
        // Load the default fonts from our SDK
        UIFont.loadFonts()
        
        // The signature step from transaction is enabled by default
        ClearentUIManager.shared.signatureEnabled = false
    }
    
    
    // MARK: Actions
    
    @IBAction func showRederDetailsAction(_ sender: Any) {
        
        let readerDetailsVC = ClearentUIManager.shared.readersViewController()
        self.navigationController?.present(readerDetailsVC, animated: true, completion: { })
    }
    
    @IBAction func startTransactionAction(_ sender: Any) {
        let transactionVC = ClearentUIManager.shared.paymentViewController(amount: 20.0)
        self.navigationController?.present(transactionVC, animated: true, completion: { })
    }
    
    @IBAction func startPairingProcess(_ sender: Any) {
        let pairingVC = ClearentUIManager.shared.pairingViewController()
        self.navigationController?.present(pairingVC, animated: true, completion: { })
    }
}

```

## Objective-C Code Example

Objective-C example of the ClearenSDKUI  integration [Obj-C Example](https://).

```
#import "ViewController.h"
#import <ClearentIdtechIOSFramework/ClearentIdtechIOSFramework.h>

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *startTransactionButton;
@property (weak, nonatomic) IBOutlet UIButton *showReaderDetailsButton;
@property (weak, nonatomic) IBOutlet UIButton *pairNewReaderButton;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [[ClearentUIManager shared] updateWithBaseURL:@"https...."
                                           apiKey:@"api key..."
                                        publicKey:@"publick key"];
    
    [[ClearentUIManager shared] setSignatureEnabled:NO];
    
    [UIFont loadFontsWithFonts:[NSArray arrayWithObjects: @"SF-Pro-Display-Bold.otf", @"SF-Pro-Text-Bold.otf", @"SF-Pro-Text-Medium.otf", nil] bundle:ClearentConstants.bundle];
}

- (IBAction)showReaderDetails:(id)sender {
    UIViewController *vc = [[ClearentUIManager shared] readersViewControllerWithCompletion:^(enum ClearentResult result) {
        //do something that you want on dismiss
    }];
    [self presentViewController:vc animated:YES completion:nil];
}

- (IBAction)startPairing:(id)sender {
    UIViewController *vc = [[ClearentUIManager shared] pairingViewControllerWithCompletion:^(enum ClearentResult result) {
        //do something that you want on dismiss
    }];
    [self presentViewController:vc animated:YES completion:nil];
}

- (IBAction)startTransaction:(id)sender {
    UIViewController *vc = [[ClearentUIManager shared] paymentViewControllerWithAmount:20.0 completion:^(enum ClearentResult result) {
        //do something that you want on dismiss
    }];
    [self presentViewController:vc animated:YES completion:nil];
}

@end

```


# Integrating the ClearentWrapper (Swift Only)


## Overview

**ClearentWrapper** is a wrapper over **ClearentFrameworkSDK** that provides payments capabilities using the IDTech iOS framework to read credit card data using VP3300. Its goal is to ease integration and fix some of the most common issues.

**ClearentWrapper** is a singleton class and the main interaction point with the SDK.  

You will use this class to update the SDK with the needed information to work properly : **API URL**, **API KEY** and the **PUBLIC KEY**. 

**Important Note:**

The safe keeping of the **API URL**, **API KEY** and the **PUBLIC KEY** is the integrators reposability. The SDK stores this information only in memory!

**ClearentWrapperProtocol** is the protocol you will need to implement in order to receive updates , error and notifications from the SDK. Each method from the protocol is documented in code.

**ClearentWrapperDefaults** is a user default storage that holds information like currently paired reader and a list of previously paired readers. You should not save anything here the SDK handles this for you.

## Supported iOS versions

The SDK supports current version of iOS and two previous versions. Curently 13, 14 and 15.

## Pairing a reader.

In order to perform transaction using the VP3300 card reader you will need to pair (connect) the device using Bluetooth, the Bluetooth connectivity is handled by the SDK .

In this step the SDK performs a Bluetooth search in order to discover the card readers around. In order for the device to be discoverable, it needs to be turned on and in range of the mobile device. The result of the Bluetooth search is a list of devices of type ReaderInfo and you will get the list from the delegate method **didFindReaders(readers: [ReaderInfo])**.  

Once you have the list of available readers the next step is to select the reader you want to connect to using the **connectTo(reader: ReaderInfo)** method that will try to connect the reader. Once the SDK manages to connect to the reader the delegate method didFinishPairing will get called indicating the connection was successful. 


## Performing a transaction

You can perform a transaction in two modes : using a card reader or by using the card details directly.

**1.Performing a transaction using the card reader.**

A transaction is performed in two steps :

1.  Reading the card, the IDTech framework reads the card info and provides a jwt (token).
2. Performing an API call that will send the transaction information together with the JWT token to a payment gateway.

You can start a transaction using startTransaction(saleEntity: SaleEntity) method. You need to provide a SaleEntity that will contain the amount, you can also specify a tip and client related information. 

When you call the startTransaction method the SDK will start guide you to the process by calling two important methods from the ClearentWrapperProtocol  : 

1. **userActionNeeded(action: UserAction)** , indicates that the user need to do an action like swiping the card, removing the card etc.
2. **didReceiveInfo(info: UserInfo)**, this method presents different information related to the transaction.

After the transaction is completed the delegate method didFinishTransaction(response: TransactionResponse, error: ResponseError?) will get called. You can check the error parameter to know if the transaction was successful or not.

**2. Performing a transaction using manual card entry.**

You can start a transaction using startTransaction(with saleEntity: SaleEntity, manualEntryCardInfo: ManualEntryCardInfo?) method where the manualEntryCardInfo parameter will contain the card informations.


**Cancelling , voiding and refunding a transaction**

If you started a card reader transaction and want to cancel it you can use cancelTransaction() method and after this call the card reader will be ready to take another transaction. You can use this method only before the card is read by the card reader. Once the card has been read the transaction will be performed and the transaction will be also registered by the payment gateway. In this case you can use the **voidTransaction(transactionID:String)** to void the transaction you want (this will work only if the transaction was not yet processed by the gateway). Another option is to perform a refund using the **refundTransaction(jwt: String, amount: String)**.


## Getting information related to the card reader status

You can obtain a ReaderInfo  object from **ClearentWrapperDefaults.pairedReader**.  
Sometimes you will need to request and display new information related to the reader like battery status or signal strength. You can achieve this by using the **startDeviceInfoUpdate()** method, calling this method will start fetching new information from the connected reader and when this information will be available it will call **readerInfoReceived: ((_ readerInfo: ReaderInfo?) -> Void)?** closure that you will need to implement in your code.


## Getting information related to previously paired readers

Each time you pair a new reader the SDK will save its information in a User Defaults cache. You can get the list using recentlyPairedReaders  property of the **ClearentWrapperDefaults**. The result will be an array of **ReaderInfo** objects.

You can check if a reader is connected by using the **isReaderConnected()** method or by checking the **isConnected** property of the **ClearentWrapperDefaults.pairedReader**.



## Uploading a signature

If you want to upload a signature image after a transaction, you can use 
**sendSignatureWithImage(image: UIImage)**. After this method is called, the **didFinishedSignatureUploadWith(response: SignatureResponse, error: ResponseError?)** delegate method will be called.  Note that the sendSignature method will use the latest transaction ID as the ID for the signature in the API call.
In case of error you can use the **resendSignature()** method to retry the signature upload


## Relevant code snippets


**Initialisation**  

```
    ClearentWrapper.shared.updateWithInfo(baseURL: Api.baseURL, publicKey: Api.publicKey, apiKey: Api.apiKey)
    
    // You will need to implement the delegate methods
    ClearentWrapper.shared.delegate = self
```


**Pairing a device**  

Calling this method will start the process of pairing a card reader with an iOS device.

```
    ClearentWrapper.shared.startPairing(reconnectIfPossible: true)
```

After the search for readers is completed the SDK will trigger a delegate method. 

```
    func didFindReaders(readers: [ReaderInfo])  {
        // you can display the list of readers on the UI
    }
```

If no available readers around are found the SDK will trigger this method :

```
    func didNotFindReaders() {
        // you can inform the user to check if the card reader is turned on in range and it's not paired with another device
    }
```

After the user selects one of the readers from the list you need to tell the SDK to connect to it.

```
   // reader is a ReaderInfo item
   ClearentWrapper.shared.connectTo(reader: reader)
```

The SDK will try to connect to the selected device and it will call the ```didFinishedPairing()``` method when finished.
Now you have a paired reader and you can start using it for performing transactions.


**Performing a transaction**  

Using a card reader

```
   // Define a SaleEntity, you can also add client information on the SaleEntity
   let saleEntity = SaleEntity(amount: 22.0, tipAmount: 5)
   ClearentWrapper.shared.startTransaction(with: saleEntity)
```

Using manual card entry

```
   // Define a SaleEntity, you can also add client information on the SaleEntity
   let saleEntity = SaleEntity(amount: 22.0, tipAmount: 5)
   
   // Create a manual card entry instance
   let ManualEntryCardInfo(card: "4111111111111111", expirationDateMMYY: "0728", csc: "999")
   ClearentWrapper.shared.startTransaction(with: saleEntity, manualEntryCardInfo: manualEntryCardInfo)
```

After starting a transaction feedback messages will be triggered on the delegate.


User action needed indicates that the user/client needs to perform an action in order for the transaction to continue e.g. Insert the card.
```
    func userActionNeeded(action: UserAction) {
        // here you should check the user action type and display the informtion to the users
    }
```


User info contains informations related to the transaction status e.g. Processing

```
    func didReceiveInfo(info: UserInfo) {
        // you should display the information to the users
    }
```


After the transaction is proccesed a delegate method will inform you about the status.

```
    func didFinishTransaction(error: ResponseError?) {
        if error == nil {
           // no error
        } else {
           // you should inform about the error
        }
    }
```


Full Swift example of the ClearenWrapper integration  integration [Swift Example](https://).
