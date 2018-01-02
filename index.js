import {
  NativeEventEmitter,
  NativeModules,
  Platform,
} from 'react-native';

const { InAppUtils } = NativeModules;

const InAppUtilsEmitter = new NativeEventEmitter(InAppUtils);

const promisify = fn => (...args) => new Promise((resolve, reject) => {
  fn(...args, (err, res) => {
    if (err !== undefined && err instanceof Error) reject(err);
    // If only one argument is given and it's not an error
    if (err !== undefined && res === undefined) resolve(err);
    resolve(res);
  });
});

const IAU = Platform.select({
  ios: {
    loadProducts: (products, cb) => cb
      ? InAppUtils.loadProducts(products, cb)
      : promisify(InAppUtils.loadProducts)(products),

    canMakePayments: cb => cb
      ? InAppUtils.canMakePayments(cb)
      : promisify(InAppUtils.canMakePayments)(),

    purchaseProduct: (productIdentifier, cb) => cb
      ? InAppUtils.purchaseProduct(productIdentifier, cb)
      : promisify(InAppUtils.purchaseProduct)(productIdentifier),

    restorePurchases: cb => cb
      ? InAppUtils.restorePurchases(cb)
      : promisify(InAppUtils.restorePurchases)(),

    receiptData: cb => cb
    ? InAppUtils.receiptData(cb)
    : promisify(InAppUtils.receiptData)(),

    addListener: (event, cb) => InAppUtilsEmitter.addListener(event, cb),
  },

  android: {},
});

export default IAU;
