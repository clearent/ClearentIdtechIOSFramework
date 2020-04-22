![Screenshot](clearent_logo.jpg)

# Release Notes (Current Release is 1.1.12)

2.0.0-beta - We've added a new method (startTransaction) allowing you to pass in connection properties at transaction time so the framework can take control of bluetooth and audio jack connectivity. We've also simplified the integration by deprecating methods that are not used and consolidating methods that did the same thing (lcdDisplay and deviceMessage).

[Upgrade guide](docs/Clearent_iOS_IDTech_Framework_Version2.doc)

1.1.12-beta

* added defensive checks to make sure a part of remote logging does not crash.

### Known Issues & different behavior ###

* The idtech framework is calling back with a new message when you start a transaction using the device_startTransaction method. "PLEASE SWIPE, TAP,OR INSERT"

* Some times when you attempt contactless the reader sends back a generic response. When this happens the framework doesn't know whether to keep retrying the tap or fallback to a contact/swipe.
A 'Card read error' is returned. A new transaction will need to be tried.

* The idtech framework will sometimes not send back a message we can display to you instructing you there was an error during contactless/tap. Instead it relies on audio beeps. Usually if you here 3 beeps or two beeps instead of the long beep it indicates an issue. See docs for more details.

* There was an issue related to how the reader was behaving when you pressed the button after it was disconnected for a while. The firmware was incorrectly determining that a card was inserted or not. This made logic in the idtech framework think a card was inserted and as a result would not enable contactless mode. A firmware fix was made (bluetooth version 151). To avoid forcing everyone to upgrade their firmware we put a workaround in that starts up the transaction and immediately cancels it, then starts up the transaction again. This somehow resets the firmware switch that is having a problem so when the new transaction is started contactless mode is also enabled. The fallout from this is you might get a second callback message sent instructing you to PLEASE SWIPE, TAP, OR INSERT, or the INSERT/SWIPE message.
