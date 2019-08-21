#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

#import "RCTBridgeModule.h"

@interface InAppUtils : NSObject <RCTBridgeModule, SKProductsRequestDelegate, SKPaymentTransactionObserver>

@end
