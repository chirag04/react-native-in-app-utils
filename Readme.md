# `react-native-in-app-utils`

A react-native wrapper for handling in-app purchases.

# Notes

- You need an Apple Developer account to use in-app purchases.

- You have to set up your in-app purchases in iTunes Connect first. Follow this [tutorial](http://stackoverflow.com/questions/19556336/how-do-you-add-an-in-app-purchase-to-an-ios-application) for an easy explanation.

- You have to test your in-app purchases on a real device, in-app purchases will always fail on the Simulator.

### Add it to your project

1. Run `npm install react-native-in-app-utils --save`.

2. Open your project in XCode, right click on `Libraries`, click `Add Files to "Your Project Name"` and add `InAppUtils.xcodeproj`. (situated in `node_modules/react-native-in-app-utils`) [(This](http://url.brentvatne.ca/jQp8) then [this](http://url.brentvatne.ca/1gqUD), just with InAppUtils).

3. Link `libInAppUtils.a` with your Libararies. To do that, click on your project folder, select `Build Phases` in the top bar, scroll to `Link Binary with Libraries`, press the `+` at the very bottom and add `libInAppUtils.a` from the `node_modules/react-native-in-app-utils/InAppUtils` folder. [(Screenshot)](http://url.brentvatne.ca/17Xfe).

4. Whenever you want to use it within React code now you just have to do: `var InAppUtils = require('NativeModules').InAppUtils;`


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

### Buy product

```javascript
var productIdentifier = 'com.xyz.abc';
InAppUtils.purchaseProduct(productIdentifier, (error, response) => {
   if(response && response.productIdentifier) {
      AlertIOS.alert('Purchase Successful', 'Your Transaction ID is ' + response.transactionIdentifier);
      //unlock store here.
   }
});
```

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

### Check if user paid for the app

Check if app was bought or downloaded for free.  This is usefull when converting a paid app to a free app with in-app purchases but still want to give some or all of the features to the users that originally paid for the app.

```javascript
InAppUtils.paidForApp((error)=> {
  if(error) {
    // when the app was downloaded, the user didn't pay for it (free or promo code)
  } else {
    // the app was paid for when downloaded.
  }
});
```

## Testing

To test your in-app purchases, you have to *run the app on an actual device*. Using the iOS Simulator, they will always fail.

1. Set up a test account ("Sandbox Tester") in iTunes Connect. See the official documentation [here](https://developer.apple.com/library/ios/documentation/LanguagesUtilities/Conceptual/iTunesConnect_Guide/Chapters/SettingUpUserAccounts.html#//apple_ref/doc/uid/TP40011225-CH25-SW9).

2. Run your app on an actual iOS device. To do so, first [run the react-native server on the local network](https://facebook.github.io/react-native/docs/runningondevice.html) instead of localhost. Then connect your iDevice to your Mac via USB and [select it from the list of available devices and simulators](https://i.imgur.com/6ifsu8Q.jpg) in the very top bar. (Next to the build and stop buttons)

3. Open the app and buy something with your Sandbox Tester Apple Account!
