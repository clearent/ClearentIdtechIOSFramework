![Screenshot](docs/clearent_logo.jpg)

# Development guide SDK UI/SDKWraper

## Overview

The enhanced sdk was developed to ease in the integration of the ClearentIDTechSDK.

## Wrapper


**ClearentWrapper** class integrates the original SDK and implements all delegates.

In order to pick and choose only the feedback that is important and it makes sense in the context of the SDK UI, two important enums were created:
UserAction and UserInfo that will be initialised if any of the enum values will match the SDK feedback message.
In order to handle more messages from the SDK you can just add a new case to each of these enums.

Another available feature is continuous search for readers. When calling **startPairing** method, search process will be restarted automatically until it is cancelled or **connectTo** method is called. Therefore, if you implement the delegate, be prepared to handle the **didFindReaders** method multiple times.

**ClearentBluetoothDevice** was wrapped in **ReaderInfo** class and new fields were added: connected, autoJoin, signalLevel, signalStrength.
Also, a mechanism was created to inform the host app of changes that occurred to the curent paired device :

```
public var readerInfoReceived: ((_ readerInfo: ReaderInfo?) -> Void)?
```
This closure is defined in ```ClearentWrapper``` and can be called each time there is new info on the reader. This  gives the integrator the chance to update the UI.

The ```ClearentWrapperProtocol``` can be used by the integrators that want to integrate without the SDK UI. This protocol is similar to the original delegate of the SDK but we introduced new naming and new methods that notify the integrator about every event but also fixes some issues.

Another functionality that was added is the cache that will store all readers that are paired with the app/sdk.
 ``` ClearentWrapperDefaults``` hold these values and ``` ClearentExtension``` file will help with adding and removing items from the cache.
 
The ```ClearentHttpClient``` knows to do a sale request, void and refund transactions but also fetch merchant settings or send signature files to the backend. Have a look on the Entities folder where you can find some of the entities that are used together with the http client.


## UI

The UI part simplifies the integration of the SDK by reducing the amount of code needed to only a few lines. View controllers were created for all the main features/flows of the SDK. So, if pairing, payment or readers list flow has to be started, the integrator just needs to fetch the proper controller from the SDK UI and display it modally on the screen. It has it's own folder, named ```ClearentUI```.

ClearentUIManager is a singleton class that will provide all these view controllers.

Here is one from the interface methods:

```
/**
* Method returns a UIController that can handle the pairing process of a card reader
* @param completion, a closure to be executed once the clearent SDK UI is dismissed
*/
@objc public func pairingViewController(completion: ((ClearentResult) -> Void)?) -> UINavigationController {
viewController(processType: .pairing(), dismissCompletion: { [weak self] result in
guard let completionResult = self?.resultFor(completionResult: result) else { return }
completion?(completionResult)
})
}
```

The integrator's job is to get the controller using this method and display it on the screen and also provide the completion parameter. The completion parameter gives the developer a chance to know if a process has finished successfully or the controller was dismissed because of an issue.

If you have a look at the implementation behind this, you will observe another two important UI components that are used in all cases where the SDK needs to display controllers.

**ClearentProcessingModalViewController** and **ClearentProcessingModalPresenter** will be initialized and presented to the user. In order to initialize you need to provide some parameters like
processType , showOnTop, a reader if you use this to display the screen where the reader can be edited and also a dismiss completion.

**FlowDataProvider**

This class integrates the **ClearentWrapper** and it is a middle layer between the SDK and UI part. It will handle all delegates of the **ClearentWrapper** and it will send further feedback to the UI using a protocol : **FlowDataProtocol**.

```
protocol FlowDataProtocol : AnyObject {
func didFinishSignature()
func didFinishTransaction(error: ResponseError?)
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

All readers paired using the UI part will be stored in **UserDefaults**. **ClearentWrapperDefaults** and the **ClearentWrapper**'s extension are used in order to achieve this. Beside the list of used readers, the current paired reader is also kept in a separate property and is used to know that a reader was paired between apps and to automatically reconnect to it if available and if **autojoin** property is true for it.