This is an IOS Framework that works with the IDTech framework to handle credit card data from IDTECH readers (currently only UniPay III is supported).

Carthage was chosen to bring the Clearent framework into your project because of its flexibility.  Reference Carthage documentation too (https://github.com/Carthage/Carthage).

1 - Install Carthage if you have not done so. ex - brew install carthage.

2 - Add your github credentials to XCode.

3 - Add a Cartfile to your project (at root). Point to Clearent's private github repository for this framework by adding the following to your Cartfile

    github "clearent/ClearentIdtechIOSFramework" "release/1.0.0"
    
4 - Run this command from your project's root folder. This command will pull down a copy of the Clearent Framework and build it locally under Carthage/Build. 

    carthage update
    
5 - On your application targets’ General settings tab, in the Embedded Binaries section, drag and drop the Clearent Framework you want to use from the Carthage/Build folder.

6 - Additionally, you'll need to copy debug symbols for debugging and crash reporting on OS X.
    On your application target’s Build Phases settings tab, click the + icon and choose New Copy Files Phase.
    Click the Destination drop-down menu and select Products Directory.
    From the Clearent framework, drag and drop its corresponding dSYM file.
    
7 - Under the Build Settings Configure this: Apple LLVM 9.0 Languages - Modules, change CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES to Yes.

8 - Build your app. The Clearent Framework should be available for use.

Example of framework usage 

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
return @"307a301406072a8648ce3d020106092b240303020801010c0362000474ce100cfdf0f3e15782c96b41f20522d5660e8474a753722e2b9c0d3a768a068c377b524750dd89163866caad1aba885fd34250d3e122b789499f87f262a0204c6e649617604bcebaa730bf6c2a74cf54a69abf9f6bf7ecfed3e44e463e31fc";
}

5- Implement the successfulTransactionToken and errorTransactionToken delegate methods. A transaction token is the representation of the credit card and allows you to submit a payment transaction.
When a card is processed (swipe,contactless, or insert/dip of card with an emv chip), the framework will call one of these two methods.

-(void) successfulTransactionToken:(NSString*) jsonString {
    NSLog(@"A clearent transaction token (JWT) has been created. Let's show an example of how to use it.");
    NSLog(@"%@",jsonString);
    NSDictionary *successfulResponseDictionary = [self jsonAsDictionary:jsonString];
    NSDictionary *payload = [successfulResponseDictionary objectForKey:@"payload"];
    NSDictionary *emvJwt = [payload objectForKey:@"emv-jwt"];
    NSString *cvm = [emvJwt objectForKey:@"cvm"];
    NSString *lastFour = [emvJwt objectForKey:@"last-four"];
    NSString *trackDataHash = [emvJwt objectForKey:@"track-data-hash"];
    NSString *jwt = [emvJwt objectForKey:@"jwt"];
    NSLog(@"%@",jwt);
    NSLog(@"%@",cvm); 
    NSLog(@"%@",lastFour); 
    NSLog(@"%@",trackDataHash);
}

- (void) errorTransactionToken:(NSString*)message{
    NSLog(@"%@",message);
}

- (NSDictionary *)jsonAsDictionary:(NSString *)stringJson {
    NSData *data = [stringJson dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:data
    options:0
    error:&error];
    if (error) {
        NSLog(@"Error json: %@", [error description]);
    }
return jsonDictionary;
}

6 - When you are ready to process the payment, do a POST against endpoint /rest/v2/mobile/transactions. Here's an example:

- (void) exampleTransactionToClearentPayments:(NSString*)token {
    NSLog(@"%@Run the transaction...",token);
    //Construct the url
    NSString *targetUrl = [NSString stringWithFormat:@"%@/rest/v2/mobile/transactions", @"https://gateway-dev.clearent.net"];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    //Create a sample json request.
    NSData *postData = [self exampleClearentTransactionRequestAsJson];
    //Build a url request. It's a POST.
    [request setHTTPBody:postData];
    [request setHTTPMethod:@"POST"];
    //Use json
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];

    //add a test apikey as a header
    [request setValue:@"12fa1a5617464354a72b3c9eb92d4f3b" forHTTPHeaderField:@"api-key"];

    //add the JWT as a header.
    [request setValue:token forHTTPHeaderField:@"emvjwt"];
    [request setURL:[NSURL URLWithString:targetUrl]];
    //Do the Post. Report the result to your user (this example sends the message to the console on the demo app (lower left corner of ui)).
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:
    ^(NSData * _Nullable data,
    NSURLResponse * _Nullable response,
    NSError * _Nullable error) {
    //Clearent returns an object that is defined the same for both successful and unsuccessful calls with one exception. The 'payload' can be different.
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
    NSLog(@"Clearent Transaction Response status code: %ld", (long)[httpResponse statusCode]);
    if(error != nil) {
       NSLog(@"%@Result...",error.description);
    } else if(data != nil) {
        NSString *responseStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"Clearent Transaction : %s", responseStr);
    }
}] resume];
}

- (NSData*) exampleClearentTransactionRequestAsJson {
    NSDictionary* dict = @{@"amount":@"4.55",@"type":@"SALE",@"email-address":@"someone@somewhere.com",@"email-receipt":@"true"};
    return [NSJSONSerialization dataWithJSONObject:dict
    options:NSJSONWritingPrettyPrinted error:nil];
}
