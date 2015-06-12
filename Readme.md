# react-native-in-app-utils

A react-native wrapper for handling in-app payments.

### Add it to your project

1. Run `npm install react-native-in-app-utils --save`
2. Open your project in XCode, right click on `Libraries` and click `Add
   Files to "Your Project Name"` [(Screenshot)](http://url.brentvatne.ca/jQp8) then [(Screenshot)](http://url.brentvatne.ca/1gqUD).
3. Add `libInAppUtils.a` to `Build Phases -> Link Binary With Libraries`
   [(Screenshot)](http://url.brentvatne.ca/17Xfe).
4. Whenever you want to use it within React code now you can: `var InAppUtils = require('NativeModules').InAppUtils;`


## Example
```javascript
var InAppUtils = require('NativeModules').InAppUtils;

//todo add more info here.
```