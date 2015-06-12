#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@interface SKProduct (StringPrice)

@property (nonatomic, readonly) NSString *priceString;

@end