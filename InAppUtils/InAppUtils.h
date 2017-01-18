#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

#import <React/RCTBridgeModule.h>

@interface InAppUtils : NSObject <RCTBridgeModule, SKProductsRequestDelegate, SKPaymentTransactionObserver>

@end
