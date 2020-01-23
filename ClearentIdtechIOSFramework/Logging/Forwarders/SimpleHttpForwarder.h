#import <Foundation/Foundation.h>

@protocol Forwarder <NSObject>
@required
- (void)forwardLog:(NSData *)log forDeviceId:(NSString *)devId;
@end

@interface SimpleHttpForwarder : NSObject <Forwarder>

@property (nonatomic, strong) NSString *aggregatorUrl;
@property (nonatomic, strong) NSString *publicKey;

+ (SimpleHttpForwarder *)forwarderWithAggregatorUrl:(NSString *)url publicKey:(NSString *)publicKey;

@end
