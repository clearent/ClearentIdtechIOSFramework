# Clearent IDTech IOS Framework

This is an IOS Framework that works with the IDTech framework to handle credit card data from IDTECH readers (currently only UniPay III is supported).

Carthage was chosen to bring the Clearent framework into your project because of its flexibility.  Reference Carthage documentation too (https://github.com/Carthage/Carthage).

## Build the framework, build your app.

1 - Install Carthage if you have not done so. ex - brew install carthage.

2 - Add your github credentials to XCode.

3 - Add a Cartfile to your project (at root). Point to Clearent's private github repository for this framework by adding the following to your Cartfile

    github "clearent/ClearentIdtechIOSFramework" "release/1.0.0"
    
4 - Run this command from your project's root folder. This command will pull down a copy of the Clearent Framework and build it locally under Carthage/Build. 

    carthage update
    
5 - On your application targets’ General settings tab, in the Embedded Binaries section, drag and drop the Clearent Framework from the Carthage/Build folder.

6 - Additionally, you'll need to copy debug symbols for debugging and crash reporting on OS X.
    On your application target’s Build Phases settings tab, click the + icon and choose New Copy Files Phase.
    Click the Destination drop-down menu and select Products Directory.
    From the Clearent framework, drag and drop its corresponding dSYM file.
    
7 - Under the Build Settings Configure this: Apple LLVM 9.0 Languages - Modules, change CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES to Yes.

8 - Build your app. The Clearent Framework should be available for use.

## Use the Clearent Framework 

1 - Add this to your ViewController.h
#import <ClearentIdtechIOSFramework/ClearentIdtechIOSFramework.h>

2 - Define the framework object you will interact with in ViewController.m.
Clearent_UniPayIII *clearentPayments;

3 - Intialize the object
clearentPayments = [[Clearent_UniPayIII alloc]  init];
[clearentPayments init:self];

4 - Implement these methods, providing the necessary configuration. We recommend not hard coding the public key. 

-(NSString*) getTransactionTokenUrl {
    return @"http://gateway-sb.clearent.net/rest/v2/emvjwt";
}

-(NSString*) getPublicKey {
    return @"fdsafkjsf384r73fnsdkguhag93488hegsr";
}

5- Implement the successfulTransactionToken and errorTransactionToken delegate methods. A transaction token is the representation of the credit card and allows you to submit a payment transaction.
When a card is processed (swipe,contactless, or insert/dip of card with an emv chip), the framework will call one of these two methods.

-(void) successfulTransactionToken:(NSString*) jsonString {
  //This json contains the transaction token. See demo app for more details
}

- (void) errorTransactionToken:(NSString*)message{
     //See demo app for more details
}

6 - When you are ready to process the payment, do a POST against endpoint /rest/v2/mobile/transactions. See demo app for an example

