#import "InAppUtils.h"
#import <StoreKit/StoreKit.h>
#import <React/RCTLog.h>
#import <React/RCTUtils.h>
#import "SKProduct+StringPrice.h"

@implementation InAppUtils
{
    NSArray *products;
    NSMutableDictionary *_callbacks;
}

- (instancetype)init
{
    if ((self = [super init])) {
        _callbacks = [[NSMutableDictionary alloc] init];
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    }
    return self;
}

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

RCT_EXPORT_MODULE()

- (void)paymentQueue:(SKPaymentQueue *)queue
 updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStateFailed: {
                NSString *key = RCTKeyForInstance(transaction.payment.productIdentifier);
                RCTResponseSenderBlock callback = _callbacks[key];
                if (callback) {
                    callback(@[RCTJSErrorFromNSError(transaction.error)]);
                    [_callbacks removeObjectForKey:key];
                } else {
                    RCTLogWarn(@"No callback registered for transaction with state failed.");
                }
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
            }
            case SKPaymentTransactionStatePurchased: {
                NSString *key = RCTKeyForInstance(transaction.payment.productIdentifier);
                RCTResponseSenderBlock callback = _callbacks[key];
                if (callback) {
                    NSDictionary *purchase = @{
                                              @"transactionDate": @(transaction.transactionDate.timeIntervalSince1970 * 1000),
                                              @"transactionIdentifier": transaction.transactionIdentifier,
                                              @"productIdentifier": transaction.payment.productIdentifier,
                                              @"transactionReceipt": [[transaction transactionReceipt] base64EncodedStringWithOptions:0]
                                              };
                    callback(@[[NSNull null], purchase]);
                    [_callbacks removeObjectForKey:key];
                } else {
                    RCTLogWarn(@"No callback registered for transaction with state purchased.");
                }
                break;
            }
            case SKPaymentTransactionStateRestored:
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
            case SKPaymentTransactionStatePurchasing:
                NSLog(@"purchasing");
                break;
            case SKPaymentTransactionStateDeferred:
                NSLog(@"deferred");
                break;
            default:
                break;
        }
    }
}

RCT_EXPORT_METHOD(getPendingPurchases:(RCTResponseSenderBlock)callback)
{
    NSMutableArray *transactionsArrayForJS = [NSMutableArray array];
    for (SKPaymentTransaction *transaction in [SKPaymentQueue defaultQueue].transactions) {
        
        NSMutableDictionary *purchase = [NSMutableDictionary new];
        purchase[@"transactionDate"] = @(transaction.transactionDate.timeIntervalSince1970 * 1000);
        purchase[@"productIdentifier"] = transaction.payment.productIdentifier;
        purchase[@"transactionState"] = StringForTransactionState(transaction.transactionState);
        
        if (transaction.transactionIdentifier != nil) {
                purchase[@"transactionIdentifier"] = transaction.transactionIdentifier;
        }
        
        NSString *receipt = [[transaction transactionReceipt] base64EncodedStringWithOptions:0];

        if (receipt != nil) {
            purchase[@"transactionReceipt"] = receipt;
        }

        SKPaymentTransaction *originalTransaction = transaction.originalTransaction;
        if (originalTransaction) {
            purchase[@"originalTransactionDate"] = @(originalTransaction.transactionDate.timeIntervalSince1970 * 1000);
            purchase[@"originalTransactionIdentifier"] = originalTransaction.transactionIdentifier;
        }

        [transactionsArrayForJS addObject:purchase];
    }
    callback(@[[NSNull null], transactionsArrayForJS]);
}

RCT_EXPORT_METHOD(purchaseProductForUser:(NSString *)productIdentifier
                  username:(NSString *)username
                  callback:(RCTResponseSenderBlock)callback)
{
    [self doPurchaseProduct:productIdentifier username:username callback:callback];
}

RCT_EXPORT_METHOD(purchaseProduct:(NSString *)productIdentifier
                  callback:(RCTResponseSenderBlock)callback)
{
    [self doPurchaseProduct:productIdentifier username:nil callback:callback];
}

- (void) doPurchaseProduct:(NSString *)productIdentifier
                  username:(NSString *)username
                  callback:(RCTResponseSenderBlock)callback
{
    SKProduct *product;
    for(SKProduct *p in products)
    {
        if([productIdentifier isEqualToString:p.productIdentifier]) {
            product = p;
            break;
        }
    }

    if(product) {
        SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];
        if(username) {
            payment.applicationUsername = username;
        }
        [[SKPaymentQueue defaultQueue] addPayment:payment];
        _callbacks[RCTKeyForInstance(payment.productIdentifier)] = callback;
    } else {
        callback(@[@"invalid_product"]);
    }
}

RCT_EXPORT_METHOD(finishPurchase:(NSString *)transactionIdentifier
                  callback:(RCTResponseSenderBlock)callback)
{
    for (SKPaymentTransaction *transaction in [SKPaymentQueue defaultQueue].transactions) {
        if ([transaction.transactionIdentifier isEqualToString:transactionIdentifier]) {
            if (transaction.transactionState == SKPaymentTransactionStatePurchased) {
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                callback(@[[NSNull null]]);
            } else {
                callback(@[@"invalid_purchase"]);
            }
            return;
        }
    }
    callback(@[@"invalid_purchase"]);
}


- (void)paymentQueue:(SKPaymentQueue *)queue
restoreCompletedTransactionsFailedWithError:(NSError *)error
{
    NSString *key = RCTKeyForInstance(@"restoreRequest");
    RCTResponseSenderBlock callback = _callbacks[key];
    if (callback) {
        switch (error.code)
        {
            case SKErrorPaymentCancelled:
                callback(@[@"user_cancelled"]);
                break;
            default:
                callback(@[@"restore_failed"]);
                break;
        }
        
        [_callbacks removeObjectForKey:key];
    } else {
        RCTLogWarn(@"No callback registered for restore product request.");
    }
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    NSString *key = RCTKeyForInstance(@"restoreRequest");
    RCTResponseSenderBlock callback = _callbacks[key];
    if (callback) {
        NSMutableArray *productsArrayForJS = [NSMutableArray array];
        for(SKPaymentTransaction *transaction in queue.transactions){
            if(transaction.transactionState == SKPaymentTransactionStateRestored) {

                NSMutableDictionary *purchase = [NSMutableDictionary dictionaryWithDictionary: @{
                    @"transactionDate": @(transaction.transactionDate.timeIntervalSince1970 * 1000),
                    @"transactionIdentifier": transaction.transactionIdentifier,
                    @"productIdentifier": transaction.payment.productIdentifier,
                    @"transactionReceipt": [[transaction transactionReceipt] base64EncodedStringWithOptions:0]
                }];

                SKPaymentTransaction *originalTransaction = transaction.originalTransaction;
                if (originalTransaction) {
                    purchase[@"originalTransactionDate"] = @(originalTransaction.transactionDate.timeIntervalSince1970 * 1000);
                    purchase[@"originalTransactionIdentifier"] = originalTransaction.transactionIdentifier;
                }

                [productsArrayForJS addObject:purchase];
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            }
        }
        callback(@[[NSNull null], productsArrayForJS]);
        [_callbacks removeObjectForKey:key];
    } else {
        RCTLogWarn(@"No callback registered for restore product request.");
    }
}

RCT_EXPORT_METHOD(restorePurchases:(RCTResponseSenderBlock)callback)
{
    NSString *restoreRequest = @"restoreRequest";
    _callbacks[RCTKeyForInstance(restoreRequest)] = callback;
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

RCT_EXPORT_METHOD(restorePurchasesForUser:(NSString *)username
                    callback:(RCTResponseSenderBlock)callback)
{
    NSString *restoreRequest = @"restoreRequest";
    _callbacks[RCTKeyForInstance(restoreRequest)] = callback;
    if(!username) {
        callback(@[@"username_required"]);
        return;
    }
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactionsWithApplicationUsername:username];
}

RCT_EXPORT_METHOD(loadProducts:(NSArray *)productIdentifiers
                  callback:(RCTResponseSenderBlock)callback)
{
    if([SKPaymentQueue canMakePayments]){
        SKProductsRequest *productsRequest = [[SKProductsRequest alloc]
                                              initWithProductIdentifiers:[NSSet setWithArray:productIdentifiers]];
        productsRequest.delegate = self;
        _callbacks[RCTKeyForInstance(productsRequest)] = callback;
        [productsRequest start];
    } else {
        callback(@[@"not_available"]);
    }
}

RCT_EXPORT_METHOD(canMakePayments: (RCTResponseSenderBlock)callback)
{
    BOOL canMakePayments = [SKPaymentQueue canMakePayments];
    callback(@[@(canMakePayments)]);
}

RCT_EXPORT_METHOD(receiptData:(RCTResponseSenderBlock)callback)
{
    NSURL *receiptUrl = [[NSBundle mainBundle] appStoreReceiptURL];
    NSData *receiptData = [NSData dataWithContentsOfURL:receiptUrl];
    if (!receiptData) {
      callback(@[@"not_available"]);
    } else {
      callback(@[[NSNull null], [receiptData base64EncodedStringWithOptions:0]]);
    }
}

// SKProductsRequestDelegate protocol method
- (void)productsRequest:(SKProductsRequest *)request
     didReceiveResponse:(SKProductsResponse *)response
{
    NSString *key = RCTKeyForInstance(request);
    RCTResponseSenderBlock callback = _callbacks[key];
    if (callback) {
        products = [NSMutableArray arrayWithArray:response.products];
        NSMutableArray *productsArrayForJS = [NSMutableArray array];
        for(SKProduct *item in response.products) {
            NSDictionary *product = @{
                                      @"identifier": item.productIdentifier,
                                      @"price": item.price,
                                      @"currencySymbol": [item.priceLocale objectForKey:NSLocaleCurrencySymbol],
                                      @"currencyCode": [item.priceLocale objectForKey:NSLocaleCurrencyCode],
                                      @"priceString": item.priceString,
                                      @"countryCode": [item.priceLocale objectForKey: NSLocaleCountryCode],
                                      @"downloadable": item.downloadable ? @"true" : @"false" ,
                                      @"description": item.localizedDescription ? item.localizedDescription : @"",
                                      @"title": item.localizedTitle ? item.localizedTitle : @"",
                                      };
            [productsArrayForJS addObject:product];
        }
        callback(@[[NSNull null], productsArrayForJS]);
        [_callbacks removeObjectForKey:key];
    } else {
        RCTLogWarn(@"No callback registered for load product request.");
    }
}

// SKProductsRequestDelegate network error
- (void)request:(SKRequest *)request didFailWithError:(NSError *)error{
    NSString *key = RCTKeyForInstance(request);
    RCTResponseSenderBlock callback = _callbacks[key];
    if(callback) {
        callback(@[RCTJSErrorFromNSError(error)]);
        [_callbacks removeObjectForKey:key];
    }
}

- (void)dealloc
{
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

#pragma mark Private

static NSString *RCTKeyForInstance(id instance)
{
    return [NSString stringWithFormat:@"%p", instance];
}
    
static NSString *StringForTransactionState(SKPaymentTransactionState state)
{
    switch(state) {
        case SKPaymentTransactionStatePurchasing: return @"purchasing";
        case SKPaymentTransactionStatePurchased: return @"purchased";
        case SKPaymentTransactionStateFailed: return @"failed";
        case SKPaymentTransactionStateRestored: return @"restored";
        case SKPaymentTransactionStateDeferred: return @"deferred";
    }
    
    [NSException raise:NSGenericException format:@"Unexpected SKPaymentTransactionState."];
}

@end
