#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@interface SKProductDiscount (StringPrice)

@property (nonatomic, readonly) NSString *priceString;

@end
