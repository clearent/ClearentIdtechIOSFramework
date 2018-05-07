#import <Foundation/Foundation.h>
#import <MessageUI/MessageUI.h>
#import <AVFoundation/AVFoundation.h>
#import "ClearentDevice.h"
#import "PublicDelegate.h"

@interface Clearent_UniPayIII : NSObject<Clearent_Device>

@property(nonatomic) SEL callBackSelector;
- (void) init : (id <Clearent_Public_IDT_UniPayIII_Delegate>) publicDelegate;
- (NSString*) SDK_version;
@end
