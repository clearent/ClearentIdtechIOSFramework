![Screenshot](docs/clearent_logo.jpg)

# Development guide SDK UI/SDKWraper 

## Overview 

Clearent SDK UI and Clearent Wrapper were developed to ease in the integration of the ClearentIDTechSDK.

**ClearentWrapper** class integrates the original SDK and implements all delegates.

In order to pick and choose only the feedback that is important and it makes sense in the context of the UI SDK we created two important enums:
UserAction and UserInfo that will be initialise if any of the enum values will match the SDK feedback message.
In order to handle more messages from the SDK you can just add a new case to each of this enums.

We also implemented continous search for readers, so if you call the **startPairing** method we will restart the search process automaticly until you cancel it or call the **connectTo** method so if you implement the delegate be prepared to handle the **didFindReaders** method multiple times.

We wrapped the ClearentBluetoothDevice in ReadeInfo class and we added new fields like, connected, autoJoin, signalLevel, signalStrength.
Also we created a mechanism to inform the host app of changes that occured to the curent paired device :

```
public var readerInfoReceived: ((_ readerInfo: ReaderInfo?) -> Void)?
```
This clojure is defined in  ```ClearentWrapper``` and can be called each time there is new info on the reader giving the integrator the chance to update the UI.

The ```ClearentWrapperProtocol``` can be used by the integrators that want to integrate without the SDK UI. This protocol is similar to the original delegate of the SDK but we introduced new naming and new methods that notify the integrator about the every event but also fixes some issues.

We created the ```ClearentWrapperProtocol``` to be used by integrator that want to integrate without the SDK UI. This protocol is similar to the original delegate of the SDK but we introduced new naming and new methods that notify the integrator about the every event.

Another functionality that was added is the cache that will store all readers that  are paired with the app/sdk ClearentWrapperDefaults hold this values and
``` ClearentExtension``` file  will help with adding and removing items from the chache.

The ```ClearentHttpClient``` knows to do a sale request, void and refund transactions but also fetch merchant settings or send signature files to the backend. Have a look on the Entities folder where you can find some of the entities that are used together with the http client.







