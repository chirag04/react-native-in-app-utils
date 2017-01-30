# `react-native-in-app-utils`

A react-native wrapper for handling in-app purchases.

# Breaking Change

- Due to a major breaking change in RN 0.40+, Use v5.x of this lib when installing from npm.


# Notes

- You need an Apple Developer account to use in-app purchases.

- You have to set up your in-app purchases in iTunes Connect first. Follow this [tutorial](http://stackoverflow.com/questions/19556336/how-do-you-add-an-in-app-purchase-to-an-ios-application) for an easy explanation.

- You have to test your in-app purchases on a real device, in-app purchases will always fail on the Simulator.

### Add it to your project

1. Make sure you have `rnpm` installed: `npm install rnpm -g`

2. Install with rnpm: `rnpm install react-native-in-app-utils`

3. Whenever you want to use it within React code now you just have to do: `var InAppUtils = require('NativeModules').InAppUtils;`
   or for ES6:
   ```
   import { NativeModules } from 'react-native'
   import { InAppUtils } from 'NativeModules'
   ```


## API

### Loading products

You have to load the products first to get the correctly internationalized name and price in the correct currency.

```javascript
var products = [
   'com.xyz.abc',
];
InAppUtils.loadProducts(products, (error, products) => {
   //update store here.
});
```

**Response fields:**

| Field          | Type    | Description                                 |
| -------------- | ------- | ------------------------------------------- |
| identifier     | string  | The product identifier                      |
| price          | number  | The price as a number                       |
| currencySymbol | string  | The currency symbol, i.e. "$" or "SEK"      |
| currencyCode   | string  | The currency code, i.e. "USD" of "SEK"      |
| priceString    | string  | Localised string of price, i.e. "$1,234.00" |
| downloadable   | boolean | Whether the purchase is downloadable        |
| description    | string  | Description string                          |
| title          | string  | Title string                                |

**Troubleshooting:** If you do not get back your product(s) then there's a good chance that something in your iTunes Connect or Xcode is not properly configured. Take a look at this [StackOverflow Answer](http://stackoverflow.com/a/11707704/293280) to determine what might be the issue(s).

### Buy product

```javascript
var productIdentifier = 'com.xyz.abc';
InAppUtils.purchaseProduct(productIdentifier, (error, response) => {
   // NOTE for v3.0: User can cancel the payment which will be availble as error object here.
   if(response && response.productIdentifier) {
      AlertIOS.alert('Purchase Successful', 'Your Transaction ID is ' + response.transactionIdentifier);
      //unlock store here.
   }
});
```

**NOTE:** Call `loadProducts` prior to calling `purchaseProduct`, otherwise this will return `invalid_product`. If you're calling them right after each other, you will need to call `purchaseProduct` inside of the `loadProducts` callback to ensure it has had a chance to complete its call.

**Response fields:**

| Field                 | Type   | Description                                        |
| --------------------- | ------ | -------------------------------------------------- |
| transactionIdentifier | string | The transaction identifier                         |
| productIdentifier     | string | The product identifier                             |
| transactionReceipt    | string | The transaction receipt as a base64 encoded string |


### Restore payments

```javascript
InAppUtils.restorePurchases((error, response)=> {
   if(error) {
      AlertIOS.alert('itunes Error', 'Could not connect to itunes store.');
   } else {
      AlertIOS.alert('Restore Successful', 'Successfully restores all your purchases.');
      //unlock store here again.
   }
});
```

**Response:** An array of transactions with the following fields:

| Field                          | Type   | Description                                        |
| ------------------------------ | ------ | -------------------------------------------------- |
| originalTransactionIdentifier  | string | The original transaction identifier                |
| transactionIdentifier          | string | The transaction identifier                         |
| productIdentifier              | string | The product identifier                             |
| transactionReceipt             | string | The transaction receipt as a base64 encoded string |


### Receipts

iTunes receipts are associated to the users iTunes account and can be retrieved without any product reference.

```javascript
InAppUtils.receiptData((error, receiptData)=> {
  if(error) {
    AlertIOS.alert('itunes Error', 'Receipt not found.');
  } else {
    //send to validation server
  }
});
```

**Response:** The receipt as a base64 encoded string.

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
