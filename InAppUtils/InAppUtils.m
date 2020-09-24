#import "InAppUtils.h"
#import <StoreKit/StoreKit.h>
#import <React/RCTLog.h>
#import <React/RCTUtils.h>
#import "SKProduct+StringPrice.h"

@implementation InAppUtils
{
    NSArray *products;
    NSMutableDictionary *_callbacks;
    BOOL hasPurchaseCompletedListeners;
    SKPaymentTransaction *currentTransaction;
    BOOL shouldFinishTransactions;
}

- (instancetype)init
{
    if ((self = [super init])) {
        hasPurchaseCompletedListeners = NO;
        shouldFinishTransactions = YES;
        _callbacks = [[NSMutableDictionary alloc] init];
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    }
    return self;
}


- (void)startObserving {
    hasPurchaseCompletedListeners = YES;
}

- (void)stopObserving {
    hasPurchaseCompletedListeners = NO;
}

+ (BOOL)requiresMainQueueSetup {
    return NO;
}

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

RCT_EXPORT_MODULE()

- (NSArray<NSString *> *)supportedEvents
{
    return @[@"purchaseCompleted"];
}

// Transactions initiated from App Store
- (BOOL)paymentQueue:(SKPaymentQueue *)queue
shouldAddStorePayment:(SKPayment *)payment
          forProduct:(SKProduct *)product {
    return hasPurchaseCompletedListeners;
}

- (void)paymentQueue:(SKPaymentQueue *)queue
 updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStateFailed: {
                NSLog(@"purchase failed");
                NSString *key = transaction.payment.productIdentifier;
                RCTResponseSenderBlock callback = _callbacks[key];
                if (callback) {
                    callback(@[RCTJSErrorFromNSError(transaction.error)]);
                    [_callbacks removeObjectForKey:key];
                } else {
                    RCTLogWarn(@"No callback registered for transaction with state failed.");
                }
                [self finishTransaction:transaction];
                break;
            }
            case SKPaymentTransactionStatePurchased: {
                NSLog(@"purchased");
                currentTransaction = transaction;
                NSString *key = transaction.payment.productIdentifier;
                RCTResponseSenderBlock callback = _callbacks[key];
                NSDictionary *purchase = [self getPurchaseData:transaction];
                if (callback) {
                    callback(@[[NSNull null], purchase]);
                    [_callbacks removeObjectForKey:key];
                }
                if (hasPurchaseCompletedListeners) {
                    [self sendEventWithName:@"purchaseCompleted" body:purchase];
                }
                if (!callback && !hasPurchaseCompletedListeners) {
                    RCTLogWarn(@"No callback or listener registered for transaction with state purchased.");
                }
               [self finishTransaction:transaction];
                break;
            }
            case SKPaymentTransactionStateRestored:
                NSLog(@"purchase restored");
                [self finishTransaction:transaction];
                break;
            case SKPaymentTransactionStatePurchasing:
                NSLog(@"purchasing");
                break;
            case SKPaymentTransactionStateDeferred:
                NSLog(@"purchase deferred");
                break;
            default:
                break;
        }
    }
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
        _callbacks[payment.productIdentifier] = callback;
    } else {
        callback(@[RCTMakeError(@"invalid_product", nil, nil)]);
    }
}

- (void) finishTransaction:(SKPaymentTransaction *)transaction
{
    if (shouldFinishTransactions) {
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
        NSLog(@"transaction finished");
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue
restoreCompletedTransactionsFailedWithError:(NSError *)error
{
    NSString *key = @"restoreRequest";
    RCTResponseSenderBlock callback = _callbacks[key];
    if (callback) {
        switch (error.code)
        {
            case SKErrorPaymentCancelled:
                callback(@[RCTMakeError(@"user_cancelled", nil, nil)]);
                break;
            default:
                callback(@[RCTJSErrorFromNSError(error)]);
                break;
        }

        [_callbacks removeObjectForKey:key];
    } else {
        RCTLogWarn(@"No callback registered for restore product request.");
    }
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    NSString *key = @"restoreRequest";
    RCTResponseSenderBlock callback = _callbacks[key];
    if (callback) {
        NSMutableArray *productsArrayForJS = [NSMutableArray array];
        for(SKPaymentTransaction *transaction in queue.transactions){
            if(transaction.transactionState == SKPaymentTransactionStateRestored) {

                NSDictionary *purchase = [self getPurchaseData:transaction];

                [productsArrayForJS addObject:purchase];
                [self finishTransaction:transaction];
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
    _callbacks[restoreRequest] = callback;
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

RCT_EXPORT_METHOD(restorePurchasesForUser:(NSString *)username
                  callback:(RCTResponseSenderBlock)callback)
{
    NSString *restoreRequest = @"restoreRequest";
    _callbacks[restoreRequest] = callback;
    if(!username) {
        callback(@[RCTMakeError(@"username_required", nil, nil)]);
        return;
    }
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactionsWithApplicationUsername:username];
}

RCT_EXPORT_METHOD(loadProducts:(NSArray *)productIdentifiers
                  callback:(RCTResponseSenderBlock)callback)
{
    SKProductsRequest *productsRequest = [[SKProductsRequest alloc]
                                          initWithProductIdentifiers:[NSSet setWithArray:productIdentifiers]];
    productsRequest.delegate = self;
    _callbacks[RCTKeyForInstance(productsRequest)] = callback;
    [productsRequest start];
}

RCT_EXPORT_METHOD(canMakePayments: (RCTResponseSenderBlock)callback)
{
    BOOL canMakePayments = [SKPaymentQueue canMakePayments];
    callback(@[[NSNull null], @(canMakePayments)]);
}

RCT_EXPORT_METHOD(receiptData:(RCTResponseSenderBlock)callback)
{
    NSString *receipt = [self grandUnifiedReceipt];
    if (receipt == nil) {
        callback(@[RCTMakeError(@"receipt_not_available", nil, nil)]);
    } else {
        callback(@[[NSNull null], receipt]);
    }
}

// Fetch Grand Unified Receipt
- (NSString *)grandUnifiedReceipt
{
    NSURL *receiptUrl = [[NSBundle mainBundle] appStoreReceiptURL];
    NSData *receiptData = [NSData dataWithContentsOfURL:receiptUrl];
    if (!receiptData) {
        return nil;
    } else {
        return [receiptData base64EncodedStringWithOptions:0];
    }
}

RCT_EXPORT_METHOD(shouldFinishTransactions:(BOOL)finishTransactions
                  callback:(RCTResponseSenderBlock)callback) {
    shouldFinishTransactions = finishTransactions;
    callback(@[[NSNull null]]);
}

RCT_EXPORT_METHOD(getPurchaseTransactions:(RCTResponseSenderBlock)callback) {
    NSArray *transactions = [[SKPaymentQueue defaultQueue] transactions];
    NSMutableArray *purchasedTransactions = [NSMutableArray array];
    for (int k = 0; k < transactions.count; k++) {
        SKPaymentTransaction *transaction = transactions[k];
        if (transaction.transactionState == SKPaymentTransactionStatePurchased) {
            NSDictionary *purchase = [self getPurchaseData:transaction];
            [purchasedTransactions addObject:purchase];
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
        }
    }
    callback(@[[NSNull null], purchasedTransactions]);
}

RCT_EXPORT_METHOD(finishCurrentTransaction:(RCTResponseSenderBlock)callback) {
    if (currentTransaction) {
        [[SKPaymentQueue defaultQueue] finishTransaction:currentTransaction];
        currentTransaction = nil;
        NSLog(@"current transaction cleared");
    }
    callback(@[[NSNull null]]);
}

// Clears all transactions that are not in purchasing state
RCT_EXPORT_METHOD(clearCompletedTransactions:(RCTResponseSenderBlock)callback) {
    NSArray *pendingTrans = [[SKPaymentQueue defaultQueue] transactions];
    int transactionsCleared = 0;
    for (int k = 0; k < pendingTrans.count; k++) {
        SKPaymentTransaction *transaction = pendingTrans[k];
        // Transactions in purchasing state cannot be cleared
        if (transaction.transactionState != SKPaymentTransactionStatePurchasing) {
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            transactionsCleared++;
        }
    }
    NSLog(@"cleared %i transactions", transactionsCleared);
    callback(@[[NSNull null]]);
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
            NSMutableDictionary *product = [NSMutableDictionary dictionaryWithDictionary:@{
                                      @"identifier": item.productIdentifier,
                                      @"price": item.price,
                                      @"currencySymbol": [item.priceLocale objectForKey:NSLocaleCurrencySymbol],
                                      @"currencyCode": [item.priceLocale objectForKey:NSLocaleCurrencyCode],
                                      @"priceString": item.priceString,
                                      @"countryCode": [item.priceLocale objectForKey: NSLocaleCountryCode],
                                      @"downloadable": item.isDownloadable ? @"true" : @"false" ,
                                      @"description": item.localizedDescription ? item.localizedDescription : @"",
                                      @"title": item.localizedTitle ? item.localizedTitle : @"",
                                      }];
            if (@available(iOS 11.2, *)) {
                if (item.introductoryPrice) {
                    product[@"introPrice"] = @(item.introductoryPrice.price.floatValue) ?: @"";
                }
            }
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

- (NSDictionary *)getPurchaseData:(SKPaymentTransaction *)transaction {
    NSMutableDictionary *purchase = [NSMutableDictionary dictionaryWithDictionary: @{
                                                                                     @"transactionDate": @(transaction.transactionDate.timeIntervalSince1970 * 1000),
                                                                                     @"transactionIdentifier": transaction.transactionIdentifier,
                                                                                     @"productIdentifier": transaction.payment.productIdentifier,
                                                                                     @"transactionReceipt": [self grandUnifiedReceipt]
                                                                                     }];
    // originalTransaction is available for restore purchase and purchase of cancelled/expired subscriptions
    SKPaymentTransaction *originalTransaction = transaction.originalTransaction;
    if (originalTransaction) {
        purchase[@"originalTransactionDate"] = @(originalTransaction.transactionDate.timeIntervalSince1970 * 1000);
        purchase[@"originalTransactionIdentifier"] = originalTransaction.transactionIdentifier;
    }

    return purchase;
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

@end
