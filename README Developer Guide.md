![Screenshot](docs/clearent_logo.jpg)

# Development guide SDK UI/SDKWraper

## Overview

The enhanced sdk was developed to ease in the integration of the **ClearentIDTechSDK**.

## Wrapper

### Wrapper Initialization

**ClearentWrapper** class integrates the original SDK and implements all delegates.

`ClearentWrapper` has a method that sets the configuration needed by the SDK to work properly. 

```
public func initialize(with config: ClearentWrapperConfiguration)
```

Because it's a static parameter, the configuration can be accessed like this:

```
ClearentWrapper.configuration
```

**ClearentWrapperConfiguration** can be initialized with the following parameters: `baseURL`, `apiKey`, `publicKey`, `offlineModeEncryptionKeyData`, `enableEnhancedMessaging`.

Enabling the enhanced messages will use the `enhancedmessages-v1.txt` file from the ClearentIdtechMessages bundle to provide friendly messages to the user.

`readerInfoReceived` is a closure that can be called each time there is new info on the reader. This gives the integrator the chance to update the UI. This way, the host app is informed of changes that occurred to the current paired device:


```
public var readerInfoReceived: ((_ readerInfo: ReaderInfo?) -> Void)?
```

`provideAuthAndMerchantTerminalDetails` is a closure called when the SDK needs to inform the user about the current merchant & terminal selected. Only used when the webAuth is used instead of API KEY for the API authentication.

In order to pick and choose only the feedback that is important and it makes sense in the context of the SDK UI, one important enum was created:
**UserAction**, this will be initialised if any of the enum values will match the SDK feedback message. If a case is not there the string of the feedback message will be used.
In order to handle more messages from the SDK you can just add a new case to each of these enums.

Another available feature is continuous search for readers. When calling `startPairing` method, search process will be restarted automatically until it is cancelled or `connectTo` method is called. Therefore, if you implement the delegate, be prepared to handle the `didFindReaders` method multiple times.

**ClearentBluetoothDevice** was wrapped in **ReaderInfo** class and new fields were added: `connected`, `autoJoin`, `signalLevel`, `signalStrength`, `encrypted`. 

The `ClearentWrapperProtocol` can be used by the integrators that want to integrate without the SDK UI. This protocol is similar to the original delegate of the SDK but we introduced new naming and new methods that notify the integrator about every event but also fixes some issues.

Another functionality that was added is the cache that will store all readers that were paired with the app/sdk.
 `ClearentWrapperDefaults` hold these values and `ClearentExtension` file will help with adding and removing items from the cache.
 
The `ClearentHttpClient` knows to do a sale request, void and refund transactions but also fetch merchant settings, send signature files to the backend or email receipt. Have a look on the Entities folder where you can find some of the entities that are used together with the http client.


## UI

The UI part simplifies the integration of the SDK by reducing the amount of code needed to only a few lines. It has it's own folder, named **ClearentUI**. 

### UI Initialization

**ClearentUIManager** is a singleton class that will provide access to the main UI flows of the SDK. Similar to `ClearentWrapper`, `ClearentUIManager` has a method that sets the configuration needed by the SDK and SDK UI to work properly:

```
public func initialize(with configuration: ClearentUIManagerConfiguration)
```

The configuration can be accessed like this:

```
ClearentUIManager.configuration
```

**ClearentUIManagerConfiguration** can be initialized with the following parameters: `baseURL`, `apiKey`, `publicKey`, `offlineModeEncryptionKeyData`, `enableEnhancedMessaging`, `tipAmounts`, `signatureEnabled`. When creating an instance of this, `ClearentWrapperConfiguration` will automatically be created and passed to the SDK.

### UI flows

View controllers were created for all the main features/flows of the SDK. So, if pairing, payment or settings has to be started, the integrator just needs to fetch the proper controller using ClearentUIManager and display it modally on the screen.
    
Here is one from the interface methods:

```
/**
* Method that returns a UINavigationController that can handle the pairing process of a card reader.
* @param completion, a closure to be executed once the clearent SDK UI is dimissed
*/
@objc public func pairingViewController(completion: ((ClearentError?) -> Void)?) -> UINavigationController {
    navigationController(processType: .pairing(), dismissCompletion: { [weak self] result in
        let completionResult = self?.resultFor(completionResult: result)
        completion?(completionResult)
    })
}
```
The completion parameter gives the developer a chance to know if a process has finished successfully or the controller was dismissed because of an issue.

If you have a look at the implementation behind this, you will observe another two important UI components that are used for the following UI flows: pairing, payment and readers list.

**ClearentProcessingModalViewController** and **ClearentProcessingModalPresenter** will be initialized and presented to the user. In order to initialize you need to provide some parameters like
processType, paymentInfo, a reader if you use this to display the screen where the reader can be edited and also a dismiss completion.

For the settings screen, **ClearentSettingsModalViewController** was created. This contains info about recently paired readers, offline mode feature (if this is available) and the option to enable/disable email receipt functionality.

 **OfflinePromptViewController** is used to notify the user about offline mode.


### FlowDataProvider

This class integrates the **ClearentWrapper** and it is a middle layer between the SDK and UI part. It will handle all delegates of the **ClearentWrapper** and it will send further feedback to the UI using a protocol: **FlowDataProtocol**.

```
protocol FlowDataProtocol : AnyObject {
    func didFinishSignature()
    func didFinishHandlingReceipt()
    func didFinishTransaction(response: Transaction?)
    func deviceDidDisconnect()
    func didFinishedPairing()
    func didReceiveFlowFeedback(feedback: FlowFeedback)
    func didBeginContinuousSearching()
}
```

```didReceiveFlowFeedback(feedback: FlowFeedback)``` is the most called protocol method. FlowFeedback is a type that contains instructions and data for the UI part on how to handle this feedback.

**FlowFeedback** will provide a list of items that contain data and the meaning of that data. It is used by the Presenter to create the UI.
Each modal you see is basically a vertical stack and using the items array UI elements are added to the stack in the same order they are added in the array.


## Readers history

All readers paired using the UI part will be stored in **UserDefaults**. **ClearentWrapperDefaults** and the **ClearentWrapper**'s extension are used in order to achieve this. Beside the list of used readers, the current paired reader is also kept in a separate property and is used to know that a reader was paired between apps and to automatically reconnect to it if available and if `autojoin` property is true for it.
