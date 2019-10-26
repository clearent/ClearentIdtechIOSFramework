![Screenshot](clearent_logo.jpg)

# Release Notes

1.0.26 - Added remote logging. Any errors, and some informational messages, are sent to Clearent server to aid in support. No sensitive data is transmitted (ex-card data). Fixed an issue with the manual entry request. The software-type was not being sent. The logging solution uses the file system. It cleans up after itself, rotating logs every couple of minutes and transmitting data to server every minute (but only if there is something to transmit).

1.0.26.1 - New static methods to call before instantiating the Clearent_VP3300 object to avoid the microphone permission prompt. Use only if you exclusively use bluetooth readers.

```smalltalk
[IDT_VP3300 disableAudioDetection];

[IDT_Device disableAudioDetection];
```

1.0.26.2 - ios13 fixes. (NSData description usage)

1.0.26.3 - discovered another ios13 fix. It's recommended that both audio jack users and bluetooth users upgrade.

Idtech introduced a new message that comes back in the callback. They modified the device_startTransaction to return a swipe/tap/insert display message, and modified ctls_startTransaction to return a tap/swipe message. This might impact your solution if you are coding off of these messages.

1.0.26.4 - Fixed an issue where the framework was not handling the card data correctly when the user has been presented with the 'USE MAGSTRIPE' message after an invalid insert. The result was an NSInvalidArgumentException being thrown.

:new: 1.1.0-beta - Contactless support, various fixes. :eyes: Uses IDTech framework version v1.01.157

### Contactless ###

* Added emv contactless reader support. MSD contactless was not a part of certification and is not supported. EMV Contactless Cards (with the network symbol) and cards in an Apple Wallet should work.

* If a tap is attempted and the reader has trouble reading the card because it was not in the NFC field long enough, the framework will handle this error and start up a new transaction. This retry loop will send back a message of 'RETRY TAP' until either it's successful or the transaction is cancelled or times out.

* Some times when the card and the reader interact an error will happen that does not allow contactless. When this happens the framework will cancel the transaction and start a new contact/swipe transaction. Contactless will be disabled and a message will be retuned to "INSERT/SWIPE".

* Added contactless configuration.

* Added methods allowing you to control the contactless configuration.

```smalltalk
   Clearent_VP3300 clearentVP3300 = [[Clearent_VP3300 alloc] init:self  clearentBaseUrl:baseUrl publicKey:publicKey];

   //If you have already configured contactless and need to clear the cache that stops the framework from performing configuration every time the reader connects.
   [clearentVP3300 clearContactlessConfigurationCache];

   //By default the framework will not auto configure contactless. This is different from contact configuration, which, by default, will auto configure.
   [clearentVP3300 setContactlessAutoConfiguration:true];

   //Independent of the contactless configuration is a flag to enable the use of contactless. By default the framework will throw the same error it did previously.
   [clearentVP3300 setContactless:true];

   //New helper method to configure everything at once. This method also gives you the ability to disable our remote logging (recommended for to quiet down debugging only).
   ClearentVP3300Config *clearentVP3300Config = [[ClearentVP3300Config alloc] init];
   clearentVP3300Config.clearentBaseUrl = baseUrl;
   clearentVP3300Config.publicKey = publicKey;
   clearentVP3300Config.contactAutoConfiguration = false;
   clearentVP3300Config.contactlessAutoConfiguration = false;
   clearentVP3300Config.contactless = true;
   clearentVP3300Config.disableRemoteLogging = true;

   clearentVP3300 = [[Clearent_VP3300 alloc] initWithConfig:self  clearentVP3300Configuration:clearentVP3300Config];
```

### Auto Configuration ###

* Added some small delays and retry logic to the auto configuration process.

* Added some healing logic related to early communication issues with the reader during auto configuration that resulted in duplicate jwt requests being sent to Clearent. If the framework sees you have set auto configuration on it will
check the terminal major configuration (tmc) to make sure it is set to 5C, not 2C (default from manufacturer). It will also check a custom idtech tag that tells the reader what emv entry mode to use as default for inserts.
idtech defaults to 07, which is contactless. If this has not been set to 05 and the tmc is not 5 the framework will invalidate the cache prior to determining whether or not it should auto configuration (which forces auto configuration to happen). Because of this issue we have changed auto configuration from being lenient to strict, meaning if any part of the configuration fails the reader will be considered not configured and the framework will not allow transactions to run.

* Auto configuration has been tested using the audio jack and bluetooth versions of the VP3300 reader. If you find the configuration failing it's recommended you try plugging in the reader to a power source.


If you are receiving pre configured readers you should disable contact auto configuration so it never runs.

```smalltalk
[clearentVP3300 setAutoConfiguration:false];

or using the new initWithConfig

ClearentVP3300Config *clearentVP3300Config = [[ClearentVP3300Config alloc] init];
clearentVP3300Config.contactAutoConfiguration = false;
```

### Various fixes ###

* Fixed Clearent_VP3300 initializer Swift issue

* Fixed an issue where the framework did not callback with a time out message.

* Added some retry logic to retrieve the firmware version, kernel version, and device serial number prior to running a transaction in case the framework had communication issues when it first tried to retrieve this info.

* Removed references to the idtech headers, bundle, and framework. The project still has references for compile purposes but the build will not have any IdTech.

### Known Issues & different behavior ###

* The idtech framework is calling back with a new message when you start a transaction using the device_startTransaction method. "PLEASE SWIPE, TAP,OR INSERT"

* Some times when you attempt contactless the reader sends back a generic response. When this happens the framework doesn't know whether to keep retrying the tap or fallback to a contact/swipe.
A 'Card read error' is returned. A new transaction will need to be tried.
