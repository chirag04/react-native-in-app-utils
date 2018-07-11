# `react-native-in-app-utils`

A react-native wrapper for handling in-app purchases in iOS.

## Breaking Change

- Due to a major breaking change in RN 0.40+, use version 5 or higher of this lib when installing from npm.

## Notes

- You need an Apple Developer account to use in-app purchases.

- You have to set up your in-app purchases in iTunes Connect first. Follow steps 1-13 in this [tutorial](http://stackoverflow.com/questions/19556336/how-do-you-add-an-in-app-purchase-to-an-ios-application) for an easy explanation.

- You have to test your in-app purchases on a real device, in-app purchases will always fail on the Simulator.

## Installation

1. Install with react-native cli `react-native install react-native-in-app-utils`

2. Whenever you want to use it within React code now you just have to do: `var InAppUtils = require('NativeModules').InAppUtils;`
   or for ES6:

```
import { NativeModules } from 'react-native'
const { InAppUtils } = NativeModules
```


## API

### Loading products

You have to load the products first to get the correctly internationalized name and price in the correct currency.

```javascript
const identifiers = [
   'com.xyz.abc',
];
InAppUtils.loadProducts(identifiers, (error, products) => {
   console.log(products);
   //update store here.
});
```

**Response:** An array of product objects with the following fields:

| Field          | Type    | Description                                 |
| -------------- | ------- | ------------------------------------------- |
| identifier     | string  | The product identifier                      |
| price          | number  | The price as a number                       |
| currencySymbol | string  | The currency symbol, i.e. "$" or "SEK"      |
| currencyCode   | string  | The currency code, i.e. "USD" of "SEK"      |
| priceString    | string  | Localised string of price, i.e. "$1,234.00" |
| countryCode    | string  | Country code of the price, i.e. "GB" or "FR"|
| downloadable   | boolean | Whether the purchase is downloadable        |
| description    | string  | Description string                          |
| title          | string  | Title string                                |

**Troubleshooting:** If you do not get back your product(s) then there's a good chance that something in your iTunes Connect or Xcode is not properly configured. Take a look at this [StackOverflow Answer](http://stackoverflow.com/a/11707704/293280) to determine what might be the issue(s).

### Checking if payments are allowed

```javascript
InAppUtils.canMakePayments((canMakePayments) => {
   if(!canMakePayments) {
      Alert.alert('Not Allowed', 'This device is not allowed to make purchases. Please check restrictions on device');
   }
})
```

**NOTE:** canMakePayments may return false because of country limitation or parental contol/restriction setup on the device.

### Buy product

```javascript
var productIdentifier = 'com.xyz.abc';
InAppUtils.purchaseProduct(productIdentifier, (error, response) => {
   // NOTE for v3.0: User can cancel the payment which will be available as error object here.
   if(response && response.productIdentifier) {
      Alert.alert('Purchase Successful', 'Your Transaction ID is ' + response.transactionIdentifier);
      //unlock store here.
   }
});
```

**NOTE:** Call `loadProducts` prior to calling `purchaseProduct`, otherwise this will return `invalid_product`. If you're calling them right after each other, you will need to call `purchaseProduct` inside of the `loadProducts` callback to ensure it has had a chance to complete its call.

**NOTE:** Call `canMakePurchases` prior to calling `purchaseProduct` to ensure that the user is allowed to make a purchase. It is generally a good idea to inform the user that they are not allowed to make purchases from their account and what they can do about it instead of a cryptic error message from iTunes.

**NOTE:** `purchaseProductForUser(productIdentifier, username, callback)` is also available.
https://stackoverflow.com/questions/29255568/is-there-any-way-to-know-purchase-made-by-which-itunes-account-ios/29280858#29280858

**Response:** A transaction object with the following fields:

| Field                 | Type   | Description                                        |
| --------------------- | ------ | -------------------------------------------------- |
| originalTransactionDate        | number | The original transaction date (ms since epoch)     |
| originalTransactionIdentifier  | string | The original transaction identifier                |
| transactionDate       | number | The transaction date (ms since epoch)              |
| transactionIdentifier | string | The transaction identifier                         |
| productIdentifier     | string | The product identifier                             |
| transactionReceipt    | string | The transaction receipt as a base64 encoded string |

**NOTE:**  `originalTransactionDate` and `originalTransactionIdentifier` are only available for subscriptions that were previously cancelled or expired.

### Restore payments

```javascript
InAppUtils.restorePurchases((error, response) => {
   if(error) {
      Alert.alert('itunes Error', 'Could not connect to itunes store.');
   } else {
      Alert.alert('Restore Successful', 'Successfully restores all your purchases.');
      
      if (response.length === 0) {
        Alert.alert('No Purchases', "We didn't find any purchases to restore.");
        return;
      }

      response.forEach((purchase) => {
        if (purchase.productIdentifier === 'com.xyz.abc') {
          // Handle purchased product.
        }
      });
   }
});
```

**NOTE:** `restorePurchasesForUser(username, callback)` is also available.
https://stackoverflow.com/questions/29255568/is-there-any-way-to-know-purchase-made-by-which-itunes-account-ios/29280858#29280858

**Response:** An array of transaction objects with the following fields:

| Field                          | Type   | Description                                        |
| ------------------------------ | ------ | -------------------------------------------------- |
| originalTransactionDate        | number | The original transaction date (ms since epoch)     |
| originalTransactionIdentifier  | string | The original transaction identifier                |
| transactionDate                | number | The transaction date (ms since epoch)              |
| transactionIdentifier          | string | The transaction identifier                         |
| productIdentifier              | string | The product identifier                             |
| transactionReceipt             | string | The transaction receipt as a base64 encoded string |


### Receipts

iTunes receipts are associated to the users iTunes account and can be retrieved without any product reference.

```javascript
InAppUtils.receiptData((error, receiptData)=> {
  if(error) {
    Alert.alert('itunes Error', 'Receipt not found.');
  } else {
    //send to validation server
  }
});
```

**Response:** The receipt as a base64 encoded string.

### Can make payments

Check if in-app purchases are enabled/disabled.

```javascript
InAppUtils.canMakePayments((enabled) => {
  if(enabled) {
    Alert.alert('IAP enabled');
  } else {
    Alert.alert('IAP disabled');
  }
});
```

**Response:** The enabled boolean flag.


## Testing

To test your in-app purchases, you have to *run the app on an actual device*. Using the iOS Simulator, they will always fail as the simulator cannot connect to the iTunes Store. However, you can do certain tasks like using `loadProducts` without the need to run on a real device.

1. Set up a test account ("Sandbox Tester") in iTunes Connect. See the official documentation [here](https://developer.apple.com/library/ios/documentation/LanguagesUtilities/Conceptual/iTunesConnect_Guide/Chapters/SettingUpUserAccounts.html#//apple_ref/doc/uid/TP40011225-CH25-SW9).

2. Run your app on an actual iOS device. To do so, first [run the react-native server on the local network](https://facebook.github.io/react-native/docs/runningondevice.html) instead of localhost. Then connect your iDevice to your Mac via USB and [select it from the list of available devices and simulators](https://i.imgur.com/6ifsu8Q.jpg) in the very top bar. (Next to the build and stop buttons)

3. Open the app and buy something with your Sandbox Tester Apple Account!

## Monthly Subscriptions

You can check if the receipt is still valid using [iap-receipt-validator](https://github.com/sibelius/iap-receipt-validator) package

```jsx
import iapReceiptValidator from 'iap-receipt-validator';

const password = 'b212549818ff42ecb65aa45c'; // Shared Secret from iTunes connect
const production = false; // use sandbox or production url for validation
const validateReceipt = iapReceiptValidator(password, production);

async validate(receiptData) {
    try {
        const validationData = await validateReceipt(receiptData);

        // check if Auto-Renewable Subscription is still valid
        // validationData['latest_receipt_info'][0].expires_date > today
    } catch(err) {
        console.log(err.valid, err.error, err.message)
    }
}
```

This works on both react native and backend server, you should setup a cron job that run everyday to check if the receipt is still valid

## Free trial period for in-app-purchase
There is nothing to set up related to this library.
Instead, If you want to set up a free trial period for in-app-purchase, you have to set it up at
iTunes Connect > your app > your in-app-purchase > free trial period (say 3-days or any period you can find from the pulldown menu)

The flow we know at this point seems to be (auto-renewal case):
1. FIRST, user have to 'purchase' no matter the free trial period is set or not.
2. If the app is configured to have a free trial period, THEN user can use the app in that free trial period without being charged.
3. When the free trial period is over, Apple's system will start to auto-renew user's purchase, therefore user can continue to use the app, but user will be charged from that point on.
