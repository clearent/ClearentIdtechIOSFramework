![Screenshot](docs/clearent_logo.jpg)

# Clearent SDK UI

## Overview 

Clearent SDK UI is a wrapper over ClearentFrameworkSDK that provides payments capabilities using the IDTech iOS framework to read credit card data using VP3300. Its goal is to ease integration by providing complete UI that handle all important flows end-to-end.


 **Clearent SDK UI** wraps all major features of the ClearentFrameworkSDK and adds UI for all major flows:

1. **Pairing Flow**, guides the user thru the pairing process steps, taking care of edge cases and possible errors.

2. **Transaction Flow**, guides the user thru the transaction flow, handling also device pairing if needed, takes care of edge cases and error handling.

3. **Readers List & Reader Details**, this flow provides reader management capabilities, it displays the status of the current paired reader but also a list of recently used readers from where you can navigate to a settings screen of the reader.

**Clearent SDK UI - Options**

1. **Tips**, when this feature is enabled the first step in the Transaction Flow will be the tips screen where the user/client is prompted with UI that will offer some options to choose a tip, This feature can be enabled or disabled from your merchant account.

2. **Signature**, when this feature is enabled as a last step in the Transaction Flow the SDK will display a screen  where the user/client can provide a signature. This signature will be uploaded to the Clearent backend.

3. **UI Customization**, Clearent SDK UI provides the integrator the chance to customize the fonts, colors and texts used in the UI, This is achieved by overwriting the public properties of each UI element that is exposed.


## Dependencies

 **Clearent SDK UI** does not use any other dependencies except the ones of the ClearentFrameworkSDK:
 
 - IDTech.xcframework 
 - DTech.bundle (responsible for translating error codes to messages)
 - CocoaLumberJack.xcframework


## Package Management - (Work In Progress)

You can use our [Clearent Cocoapod](https://github.com/clearent/CocoaPods) or [Carthage](https://github.com/Carthage/Carthage).

:new: CocoaPods latest version is 4.0.9.

### Carthage ###

:one: Install Carthage if you have not done so. ex - brew install carthage.

:two: Add your github credentials to XCode.

:three: Add a Cartfile to your project (at root). Point to Clearent's github repository for this framework by adding the following to your Cartfile

    github "clearent/ClearentIdtechIOSFramework" "4.0.9"

:four: Run this command from your project's root folder. This command will pull down a copy of the Clearent Framework and build it locally under Carthage/Build.

    carthage update

:five: On your application targets’ General settings tab, in the Embedded Binaries section, drag and drop the Clearent Framework from the Carthage/Build folder.

:six: Additionally, you'll need to copy debug symbols for debugging and crash reporting on OS X.
    On your application target’s Build Phases settings tab, click the + icon and choose New Copy Files Phase.
    Click the Destination drop-down menu and select Products Directory.
    From the Clearent framework, drag and drop its corresponding dSYM file.

:seven: Build your app. The Clearent Framework should be available for use.


## How to Integrate

In order to integrate the **SDK UI** you will need the **API URL**, **API KEY** and the **PUBLIC KEY**. 
Use ClearentUIManager class to update the SDK with this information like this. 

```
ClearentUIManager.shared.updateWith(baseURL: baseURL, apiKey: apiKey, publicKey: publicKey)
```

### Important!

**THe safe keeping of the **API URL**, **API KEY** and the **PUBLIC KEY** is the integrators reposability. The SDK does not store this informations only in memory!**


**Enabling the signature functionality**
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
