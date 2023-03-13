import 'package:flutter/material.dart';
import 'package:flutter_paypal/flutter_paypal.dart';
import 'shared_state.dart';

/// Demotransactiondata
const transactions = [
  {
    "amount": {
      "total": '15.99',
      "currency": "EUR",
      "details": {"subtotal": '15.99', "shipping": '0', "shipping_discount": 0}
    },
    "description": "The payment transaction description.",
    // "payment_options": {
    //   "allowed_payment_method":
    //       "INSTANT_FUNDING_SOURCE"
    // },
    "item_list": {
      "items": [
        {
          "name": "A demo product",
          "quantity": 1,
          "price": '15.99',
          "currency": "EUR"
        }
      ],
    },
  }
];

/// Demo PaypalInterface
UsePaypal paypalInterface = UsePaypal(
    sandboxMode: true,
    onSuccess: (Map params) {print("Success: $params");},
    onError: (Map params) {print("Error: $params");},
    onCancel: (Map params) {print("Cancel: $params");},
    returnURL: "${WEB_URL}/returntransaction",
    cancelURL: "${WEB_URL}/canceledtransaction",
    note: "Contact us for any questions on your order.",
    transactions: transactions,
    clientId: PAYPAL_SANDBOX_CLIENTID,
    secretKey: PAYPAL_SANDBOX_SECRET);
