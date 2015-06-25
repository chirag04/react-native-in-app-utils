# react-native-in-app-utils

A react-native wrapper for handling in-app payments.

# Note
You need apple developer account for using in-app payments. Flow the answer here(http://stackoverflow.com/questions/19556336/how-do-you-add-an-in-app-purchase-to-an-ios-application) to get started on setting up in-app payments in iTunes connect first.

### Add it to your project

1. Run `npm install react-native-in-app-utils --save`
2. Open your project in XCode, right click on `Libraries` and click `Add
   Files to "Your Project Name"` [(Screenshot)](http://url.brentvatne.ca/jQp8) then [(Screenshot)](http://url.brentvatne.ca/1gqUD).
3. Add `libInAppUtils.a` to `Build Phases -> Link Binary With Libraries`
   [(Screenshot)](http://url.brentvatne.ca/17Xfe).
4. Whenever you want to use it within React code now you can: `var InAppUtils = require('NativeModules').InAppUtils;`


## Api

### Loading products
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
