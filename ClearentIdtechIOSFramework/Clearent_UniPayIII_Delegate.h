#import <IDTech/IDTech.h>
#import <MessageUI/MessageUI.h>
#import <AVFoundation/AVFoundation.h>

@protocol Clearent_UniPayIII_Delegate <IDT_UniPayIII_Delegate>

@end

@interface Clearent_UniPayIII : NSObject<IDT_Device_Delegate>{
    id<Clearent_UniPayIII_Delegate> delegate;
}
@property(strong) id<Clearent_UniPayIII_Delegate> delegate;

+(Clearent_UniPayIII*) sharedController;
@end
