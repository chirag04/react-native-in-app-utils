# `react-native-in-app-utils`

A react-native wrapper for handling in-app purchases.

# Notes

- You need an Apple Developer account to use in-app purchases.

- You have to set up your in-app purchases in iTunes Connect first. Follow this [tutorial](http://stackoverflow.com/questions/19556336/how-do-you-add-an-in-app-purchase-to-an-ios-application) for an easy explanation.

- You have to test your in-app purchases on a real device, in-app purchases will always fail on the Simulator.

### Add it to your project

1. Run `npm install react-native-in-app-utils --save`.

2. Make sure you have `rnpm` installed: `npm install rnpm -g`

3. Run `rnpm link react-native-in-app-utils`

4. Whenever you want to use it within React code now you just have to do: `var InAppUtils = require('NativeModules').InAppUtils;` 
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

**Response fields:**

| Field                 | Type   | Description                |
| --------------------- | ------ | -------------------------- |
| transactionIdentifier | string | The transaction identifier |
| productIdentifier     | string | The product identifier |


### Restore payments

```javascript
InAppUtils.restorePurchases((error, products)=> {
   if(error) {
      AlertIOS.alert('itunes Error', 'Could not connect to itunes store.');
   } else {
      AlertIOS.alert('Restore Successful', 'Successfully restores all your purchases.');
      //unlock store here again.
   }
});
```

**Response:** An array of product identifiers (as strings).

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

To test your in-app purchases, you have to *run the app on an actual device*. Using the iOS Simulator, they will always fail.

1. Set up a test account ("Sandbox Tester") in iTunes Connect. See the official documentation [here](https://developer.apple.com/library/ios/documentation/LanguagesUtilities/Conceptual/iTunesConnect_Guide/Chapters/SettingUpUserAccounts.html#//apple_ref/doc/uid/TP40011225-CH25-SW9).

2. Run your app on an actual iOS device. To do so, first [run the react-native server on the local network](https://facebook.github.io/react-native/docs/runningondevice.html) instead of localhost. Then connect your iDevice to your Mac via USB and [select it from the list of available devices and simulators](https://i.imgur.com/6ifsu8Q.jpg) in the very top bar. (Next to the build and stop buttons)

3. Open the app and buy something with your Sandbox Tester Apple Account!
