#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

@interface InAppUtils : RCTEventEmitter <RCTBridgeModule, SKProductsRequestDelegate, SKPaymentTransactionObserver>

@end
