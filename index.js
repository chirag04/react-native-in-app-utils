import {
  NativeEventEmitter,
  NativeModules,
  Platform,
} from 'react-native';

const { InAppUtils } = NativeModules;

const InAppUtilsEmitter = new NativeEventEmitter(InAppUtils);

const promisify = fn => (...args) => new Promise((resolve, reject) => {
  fn(...args, (err, res) => err ? reject(err) : resolve(res));
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

    purchaseProductForUser: (productIdentifier, username, cb) => cb
      ? InAppUtils.purchaseProductForUser(productIdentifier, username, cb)
      : promisify(InAppUtils.purchaseProductForUser)(productIdentifier, username),

    restorePurchases: cb => cb
      ? InAppUtils.restorePurchases(cb)
      : promisify(InAppUtils.restorePurchases)(),

    restorePurchasesForUser: (username, cb) => cb
      ? InAppUtils.restorePurchasesForUser(username, cb)
      : promisify(InAppUtils.restorePurchasesForUser)(username),

    receiptData: cb => cb
      ? InAppUtils.receiptData(cb)
      : promisify(InAppUtils.receiptData)(),

    shouldFinishTransactions: (finishTransactions, cb) => cb
      ? InAppUtils.shouldFinishTransactions(finishTransactions, cb)
      : promisify(InAppUtils.shouldFinishTransactions)(finishTransactions),

    finishCurrentTransaction: cb => cb
      ? InAppUtils.finishCurrentTransaction(cb)
      : promisify(InAppUtils.finishCurrentTransaction)(),

    clearCompletedTransactions: cb => cb
      ? InAppUtils.clearCompletedTransactions(cb)
      : promisify(InAppUtils.clearCompletedTransactions)(),

    addListener: (...args) => InAppUtilsEmitter.addListener(...args),
  },

  android: {},
});

export default IAU;
