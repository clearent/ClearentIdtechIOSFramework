![Screenshot](clearent_logo.jpg)

# Release Notes (Current Release is 3.1, Pod 3.2.9)

Support IDTech framework version 1.1.166.019

IDTech fixed an issue with a subset of return codes that had been mapped for their Windows solution instead of iOS. We removed some extra logic that was trying to fix this issue.

Add setPublicKey so the Clearent_VP3300 object can be treated as a singleton. This allows you to update the public key if you are supporting multiple Merchants.

The framework used to check a cache first when deciding what reader to connect to when the IDTech framework sends back readers found during a scan. This has changed
to favoring the reader described in the ClearentConnection object first.

We've continued to follow IDTech's 'Less is more' approach to reducing the interaction with the bluetooth reader by limiting the requests to get device serial number and firmware version  
information after every connection. Utilizing the ClearentConnection object has simplified our approach. The firmare version was only required to support a workaround
put in place to address a contactless bug with firmware version .151. This issue has since been resolved.

Our remote logging solution would sometiems crash so we swapped it out with a CocoaLumberjack solution.

We removed some logic that was attempting a retry of the bluetooth scan when no readers were found. You have the ability to send in the maximum amount of time you want to scan
and this logic was working against that. So, instead of doubling the time we'll just tell you the reader was not found.
This logic was put in place because of a scenario where the IDTech framework will sometimes not find the reader during a scan even though we see the bluelight flashing slowly on the reader.
Our logic would call the IDTech method to force a bluetooth disconnect which would help the next scan.    


# Release Notes (Current Release is 2.0.5)

2.0.4 - There was an unrecoverable file exception that produced a crash in our remote logging solution.

2.0.4 - added logic to handle an incomplete card object that comes back from the idtech framework during a bad swipe.
When this happens we will cancel the current transaction and restart a transaction in '2 in 1' mode.

2.0.3 - RELEASE

2.0.3-beta - disabled a retry of a swipe when it wasn't necessary.

2.0.2-beta - logging. added a TIMEOUT that will occur 1 second after the transaction times out if idtech has not returned the TIMEOUT. When there are 3 short beeps it when using a phone for tap a message "SEE PHONE" should show to indicate the user needs to answer a password or biometric prompt.

2.0.1-beta - perform selector checks before calling deprecated delegate callbacks to ensure they have been implemented

2.0.0-beta - We've added a new method (startTransaction) allowing you to pass in connection properties at transaction time so the framework can take control of bluetooth and audio jack connectivity. We've also simplified the integration by deprecating methods that are not used and consolidating methods that did the same thing (lcdDisplay and deviceMessage).

[Upgrade guide](Clearent_iOS_IDTech_Framework_Version2.doc)

1.1.12-beta

* added defensive checks to make sure a part of remote logging does not crash.

### Known Issues & different behavior ###

* Some times when you attempt contactless the reader sends back a generic response. When this happens the framework doesn't know whether to keep retrying the tap or fallback to a contact/swipe.
A 'Card read error' is returned. A new transaction will need to be tried.

* The idtech framework will sometimes not send back a message we can display to you instructing you there was an error during contactless/tap. Instead it relies on audio beeps. Usually if you here 3 beeps or two beeps instead of the long beep it indicates an issue. See docs for more details.
