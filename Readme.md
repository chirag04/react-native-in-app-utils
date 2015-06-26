# react-native-in-app-utils

A react-native wrapper for handling in-app payments.

# Notes

- You need Apple Developer account for using in-app payments.

- You have to set up your in-app payments in iTunes Connect first. Follow this [tutorial](http://stackoverflow.com/questions/19556336/how-do-you-add-an-in-app-purchase-to-an-ios-application) for an easy explanation.

- You have to test your app on a real device, In App Payments will always fail on the Simulator.

### Add it to your project

1. Run `npm install react-native-in-app-utils --save`.

2. Open your project in XCode, right click on `Libraries`, click `Add Files to "Your Project Name"` and add `InAppUtils.xcodeproj`. (situated in `node_modules/react-native-in-app-utils`) [(This](http://url.brentvatne.ca/jQp8) then [this](http://url.brentvatne.ca/1gqUD), just with InAppUtils).

3. Link `libInAppUtils.a` with your Libararies. To do that, click on your project folder, select `Build Phases` in the top bar, scroll to `Link Binary with Libraries`, press the `+` at the very bottom and add `libInAppUtils.a` from the `node_modules/react-native-in-app-utils/InAppUtils` folder. [(Screenshot)](http://url.brentvatne.ca/17Xfe).

4. Whenever you want to use it within React code now you just have to do: `var InAppUtils = require('NativeModules').InAppUtils;`


## Api

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
InAppUtils.purchaseProduct(productIdentifier, (error, identifier) => {
   if(identifier) {
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
