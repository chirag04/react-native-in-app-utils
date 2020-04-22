#import "InAppUtils.h"
#import <StoreKit/StoreKit.h>
#import <React/RCTLog.h>
#import <React/RCTUtils.h>
#import <StoreKit/StoreKit.h>
#import "SKProduct+StringPrice.h"

@implementation InAppUtils
{
    bool hasListeners;
    
    NSArray *products;
    NSMutableDictionary *_callbacks;
    
    //Promoted in-app purchase
    SKProduct *promotedProduct;
    SKPayment *promotedProductPayment;
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

- (NSArray<NSString *> *)supportedEvents
{
    return @[@"OnPromotedProduct"];
}

-(void)startObserving {
    hasListeners = YES;
}

-(void)stopObserving {
    hasListeners = NO;
}

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
                    NSDictionary *purchase = [self getPurchaseData:transaction];
                    callback(@[[NSNull null], purchase]);
                    [_callbacks removeObjectForKey:key];
                } else {
                    RCTLogWarn(@"No callback registered for transaction with state purchased.");
                }
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
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

                NSDictionary *purchase = [self getPurchaseData:transaction];

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
    SKProductsRequest *productsRequest = [[SKProductsRequest alloc]
                                          initWithProductIdentifiers:[NSSet setWithArray:productIdentifiers]];
    productsRequest.delegate = self;
    _callbacks[RCTKeyForInstance(productsRequest)] = callback;
    [productsRequest start];
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
        NSMutableArray *productsArrayForJS = [[NSMutableArray alloc] init];
        
        for(SKProduct *item in response.products) {
                        
            NSArray *discounts;
            
            if (@available(iOS 12.2, *)) {
                discounts = [self getDiscountData:[item.discounts copy]];
            }
            
            NSString* currencyCode = @"";
            
            if (@available(iOS 10.0, *)) {
                currencyCode = item.priceLocale.currencyCode;
            }

            NSString *subscriptionPeriodNumberOfUnits = @"";
            NSString *subscriptionPeriodUnit= @"";
            NSString *countryCode= @"";
            NSDictionary *introductoryPrice = nil;
            
            if (@available(iOS 13.0, *)) {
                countryCode = [[SKPaymentQueue defaultQueue] storefront].countryCode;
            }else{
                countryCode = [item.priceLocale objectForKey: NSLocaleCountryCode];
            }
            
            
            if (@available(iOS 11.2, *)) {
                switch (item.subscriptionPeriod.unit) {
                    case SKProductPeriodUnitDay:
                        subscriptionPeriodUnit = @"DAY";
                    break;
                    case SKProductPeriodUnitWeek:
                        subscriptionPeriodUnit = @"WEEK";
                    break;
                    case SKProductPeriodUnitMonth:
                        subscriptionPeriodUnit = @"MONTH";
                    break;
                    case SKProductPeriodUnitYear:
                        subscriptionPeriodUnit = @"YEAR";
                    break;
                    default:
                        subscriptionPeriodUnit = @"";
                    }
                
                subscriptionPeriodNumberOfUnits = [NSString stringWithFormat:@"%lu",  (unsigned long)item.subscriptionPeriod.numberOfUnits];
                
                if(item.introductoryPrice != nil){
                    NSDecimalNumber* introductoryPricePrice = [NSDecimalNumber zero];
                    NSString* introductoryPriceIdentifier = @"";
                    NSString* introductoryPricePaymentMode = @"";
                    NSString* introductoryPriceNumberOfPeriods = @"";
                    NSString* introductoryPriceSubscriptionUnit = @"";
                    NSString* introductoryPriceType= @"";
                    NSString* introductoryPriceSubscriptionNumberOfUnits = @"";
                    
                    introductoryPricePrice = item.introductoryPrice.price;
                    introductoryPriceSubscriptionNumberOfUnits = [NSString stringWithFormat:@"%lu",  (unsigned long) item.introductoryPrice.subscriptionPeriod.numberOfUnits];
                    introductoryPriceNumberOfPeriods = [@(item.introductoryPrice.numberOfPeriods) stringValue];
                    
                    switch (item.introductoryPrice.paymentMode) {
                        case SKProductDiscountPaymentModeFreeTrial:
                            introductoryPricePaymentMode = @"FREETRIAL";
                            break;
                        case SKProductDiscountPaymentModePayAsYouGo:
                            introductoryPricePaymentMode = @"PAYASYOUGO";
                            break;
                        case SKProductDiscountPaymentModePayUpFront:
                            introductoryPricePaymentMode = @"PAYUPFRONT";
                            break;
                        default:
                            introductoryPricePaymentMode = @"";                            
                            break;
                    }
                    
                    if (item.introductoryPrice.subscriptionPeriod.unit == SKProductPeriodUnitDay) {
                        introductoryPriceSubscriptionUnit = @"DAY";
                    } else if (item.introductoryPrice.subscriptionPeriod.unit == SKProductPeriodUnitWeek) {
                        introductoryPriceSubscriptionUnit = @"WEEK";
                    } else if (item.introductoryPrice.subscriptionPeriod.unit == SKProductPeriodUnitMonth) {
                        introductoryPriceSubscriptionUnit = @"MONTH";
                    } else if (item.introductoryPrice.subscriptionPeriod.unit == SKProductPeriodUnitYear) {
                        introductoryPriceSubscriptionUnit = @"YEAR";
                    } else {
                        introductoryPriceSubscriptionUnit = @"";
                    }
                    
                    
                    if (@available(iOS 12.2, *)) {
                        introductoryPriceIdentifier = item.introductoryPrice.identifier ? item.introductoryPrice.identifier : @"";
                        
                        switch (item.introductoryPrice.type) {
                        case SKProductDiscountTypeIntroductory:
                            introductoryPriceType = @"INTRODUCTORY";
                            break;
                        case SKProductDiscountTypeSubscription:
                            introductoryPriceType = @"SUBSCRIPTION";
                            break;
                        default:
                            introductoryPriceType = @"";
                            break;
                        }
                    }
                    
                    NSDictionary *introductoryPriceSubscriptionPeriod = @{
                            @"unit": introductoryPriceSubscriptionUnit,
                            @"numberOfUnits":introductoryPriceSubscriptionNumberOfUnits,
                    };
                    
                    introductoryPrice = @{
                        @"identifier": introductoryPriceIdentifier,
                        @"type": introductoryPriceType,
                        @"price": introductoryPricePrice,
                        @"paymentMode": introductoryPricePaymentMode,
                        @"numberOfPeriods": introductoryPriceNumberOfPeriods,
                        @"subscriptionPeriod": introductoryPriceSubscriptionPeriod,
                    };
                }else{
                    introductoryPrice = @{};
                }
            }
                        
            NSDictionary *subscriptionPeriod = @{
                @"unit": subscriptionPeriodUnit,
                @"numberOfUnits":subscriptionPeriodNumberOfUnits,
            };
          
            NSDictionary *product = @{
                @"identifier": item.productIdentifier,
                @"price": item.price,
                @"currencySymbol": [item.priceLocale objectForKey:NSLocaleCurrencySymbol],
                @"currencyCode": currencyCode,
                @"priceString": item.priceString,
                @"countryCode": countryCode,
                @"downloadable": item.isDownloadable ? @"true" : @"false" ,
                @"description": item.localizedDescription ? item.localizedDescription : @"",
                @"title": item.localizedTitle ? item.localizedTitle : @"",
                @"discounts": discounts ? discounts: @"",
                @"introductoryPrice":  introductoryPrice,
                @"subscriptionPeriod": subscriptionPeriod,
            };
            
            [productsArrayForJS addObject:product];
          
        }
        callback(@[[NSNull null], productsArrayForJS]);
        [_callbacks removeObjectForKey:key];
    } else {
        RCTLogWarn(@"No callback registered for load product request.");
    }
}

- (NSMutableArray *)getDiscountData:(NSArray *)discounts {
    NSMutableArray *mappedDiscounts = [NSMutableArray arrayWithCapacity:[discounts count]];
    NSString *localizedPrice;
    NSString *paymendMode;
    NSString *subscriptionPeriods;
    NSString *discountType;

    if (@available(iOS 11.2, *)) {
        for(SKProductDiscount *discount in discounts) {
            NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
            formatter.numberStyle = NSNumberFormatterCurrencyStyle;
            formatter.locale = discount.priceLocale;
            localizedPrice = [formatter stringFromNumber:discount.price];
            NSString *numberOfPeriods;
            
            numberOfPeriods = [@(discount.numberOfPeriods) stringValue];
            
            switch (discount.paymentMode) {
                case SKProductDiscountPaymentModeFreeTrial:
                    paymendMode = @"FREETRIAL";
                    break;
                case SKProductDiscountPaymentModePayAsYouGo:
                    paymendMode = @"PAYASYOUGO";
                    break;
                case SKProductDiscountPaymentModePayUpFront:
                    paymendMode = @"PAYUPFRONT";
                    break;
                default:
                    paymendMode = @"";
                    break;
            }

            switch (discount.subscriptionPeriod.unit) {
                case SKProductPeriodUnitDay:
                    subscriptionPeriods = @"DAY";
                    break;
                case SKProductPeriodUnitWeek:
                    subscriptionPeriods = @"WEEK";
                    break;
                case SKProductPeriodUnitMonth:
                    subscriptionPeriods = @"MONTH";
                    break;
                case SKProductPeriodUnitYear:
                    subscriptionPeriods = @"YEAR";
                    break;
                default:
                    subscriptionPeriods = @"";
            }


            NSString* discountIdentifier = @"";
            
            if (@available(iOS 12.2, *)) {
                discountIdentifier = discount.identifier;
                switch (discount.type) {
                    case SKProductDiscountTypeIntroductory:
                        discountType = @"INTRODUCTORY";
                        break;
                    case SKProductDiscountTypeSubscription:
                        discountType = @"SUBSCRIPTION";
                        break;
                    default:
                        discountType = @"";
                        break;
                }

            }
        

            [mappedDiscounts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                        discountIdentifier, @"identifier",
                                        discountType, @"type",
                                        numberOfPeriods, @"numberOfPeriods",
                                        discount.price, @"price",
                                        localizedPrice, @"localizedPrice",
                                        paymendMode, @"paymentMode",
                                        subscriptionPeriods, @"subscriptionPeriod",
                                        nil
                                        ]];
        }
    }

    return mappedDiscounts;
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
    NSData *dataReceipt = [NSData dataWithContentsOfURL:[[NSBundle mainBundle] appStoreReceiptURL]];
    NSString *receipt = [dataReceipt base64EncodedStringWithOptions:0];

    NSMutableDictionary *purchase = [NSMutableDictionary dictionaryWithDictionary: @{
                                                                                     @"transactionDate": @(transaction.transactionDate.timeIntervalSince1970 * 1000),
                                                                                     @"transactionIdentifier": transaction.transactionIdentifier,
                                                                                     @"productIdentifier": transaction.payment.productIdentifier,
                                                                                     @"transactionReceipt": receipt
                                                                                     }];
    // originalTransaction is available for restore purchase and purchase of cancelled/expired subscriptions
    SKPaymentTransaction *originalTransaction = transaction.originalTransaction;
    if (originalTransaction) {
        purchase[@"originalTransactionDate"] = @(originalTransaction.transactionDate.timeIntervalSince1970 * 1000);
        purchase[@"originalTransactionIdentifier"] = originalTransaction.transactionIdentifier;
    }
    
    return purchase;
}

#pragma mark In-app purchases promotion

- (BOOL)paymentQueue:(SKPaymentQueue *)queue shouldAddStorePayment:(SKPayment *)payment forProduct:(SKProduct *)product {
    promotedProduct = product;
    promotedProductPayment = payment;
    if(hasListeners) {
        [self sendEventWithName:@"OnPromotedProduct" body:payment.productIdentifier];
    }
    return false;
}

RCT_EXPORT_METHOD(getPromotedProduct: (RCTResponseSenderBlock)callback)
{
    callback(@[promotedProduct ? promotedProduct.productIdentifier : [NSNull null]]);
}

RCT_EXPORT_METHOD(buyPromotedProduct:(RCTResponseSenderBlock)callback)
{
    if(promotedProductPayment) {
        [[SKPaymentQueue defaultQueue] addPayment:promotedProductPayment];
        _callbacks[RCTKeyForInstance(promotedProductPayment.productIdentifier)] = callback;
    }
    else {
        callback(@[@"no_initial_product"]);
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

@end
