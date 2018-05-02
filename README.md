This is an IOS Framework that works with the IDTech framework to handle credit card data from IDTECH readers (currently only UniPay III is supported).

Carthage was chosen to bring the Clearent framework into your project because of its flexibility.  

1 - Install Carthage if you have not done so. ex - brew install carthage.
2 - Add a Cartfile to your project (at root). Point to Clearent's private github repository for this framework by adding the following to your Cartfile

github "clearent/ClearentIdtechIOSFramework-" ~>= 1.0.0

3 - run this command from your project's root folder. carthage update --platform iOS


