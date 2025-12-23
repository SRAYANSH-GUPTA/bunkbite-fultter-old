import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:dio/dio.dart';
import '../core/api_service.dart';
import '../models/order_model.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/orders_provider.dart';
import '../screens/order_details_screen.dart';
import '../widgets/error_dialog.dart';

// Helper function to get user-friendly error messages
String _getUserFriendlyError(dynamic error) {
  if (error is DioException) {
    if (error.response?.statusCode == 404) {
      return 'Service not available. Please try again later.';
    } else if (error.response?.statusCode == 400) {
      final message =
          error.response?.data['message'] ?? error.response?.data['error'];
      if (message != null &&
          message.toString().toLowerCase().contains('closed')) {
        return 'Canteen is currently closed. Please try again during operating hours.';
      }
      return message?.toString() ??
          'Invalid request. Please check your order and try again.';
    } else if (error.response?.statusCode == 401) {
      return 'Please login again to continue.';
    } else if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Connection timeout. Please check your internet and try again.';
    } else if (error.type == DioExceptionType.connectionError) {
      return 'No internet connection. Please check your network.';
    }
    return error.response?.data['message']?.toString() ??
        error.response?.data['error']?.toString() ??
        'Something went wrong. Please try again.';
  }
  return 'An unexpected error occurred. Please try again.';
}

class PaymentState {
  final bool isLoading;
  final String? error;

  PaymentState({this.isLoading = false, this.error});
}

class PaymentController extends StateNotifier<PaymentState> {
  final ApiService _apiService;
  late Razorpay _razorpay;
  String? _currentOrderId; // Internal app order ID
  BuildContext? _context; // Store context for navigation

  // Need reference to Ref to clear cart? Or just callback.
  final Ref ref;

  PaymentController(this._apiService, this.ref) : super(PaymentState()) {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void initiateCheckout(
    BuildContext context,
    String canteenId,
    List<OrderLineItem> items,
  ) async {
    _context = context; // Store context for later use
    state = PaymentState(isLoading: true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Wait... Starting Payment...')),
    );
    try {
      // 1. Create Order
      final orderData = {
        'canteenId': canteenId,
        'items': items
            .map((i) => {'menuItemId': i.menuItemId, 'quantity': i.quantity})
            .toList(),
      };

      final createRes = await _apiService.client.post(
        '/orders',
        data: orderData,
      );
      // Create Order Response: { success: true, data: { orderId: ... } } ?
      // Prompt says POST /orders returns orderId?
      // Wait, prompt for POST /orders is vague on response structure, but likely { success, data }
      // Let's assume standard format: createRes.data['data']['_id'] or similar?
      // Prompt sample for GET /orders shows _id.
      // Usually POST returns the created object.
      // Let's safe parse.
      final responseData = createRes.data['data'] ?? createRes.data;
      final String orderId =
          responseData['orderId'] ??
          responseData['_id'] ??
          responseData['id']; // Defensive
      _currentOrderId = orderId;

      // 2. Initiate Payment (Razorpay Order)
      final payRes = await _apiService.client.post(
        '/payments/initiate',
        data: {'orderId': orderId},
      );
      // Response: { success: true, data: { razorpayOrderId: ..., amount: ..., razorpayKeyId: ... } }

      final payData = payRes.data['data'];
      final String razorpayOrderId = payData['razorpayOrderId'];
      final int amount = payData['amount'];
      // STRICT FIX: User says key comes as 'razorpayKeyId' or use 'keyId' as fallback
      final String razorpayKey =
          payData['razorpayKeyId'] ??
          payData['keyId'] ??
          "rzp_test_1DP5mmOlF5G5ag";

      // Get User Details
      final user = ref.read(authProvider).user;
      final userEmail = user?.email ?? 'student@example.com';
      final phone = '9000090000'; // Placeholder

      // Temporary Debug Toast
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Debug: Key=$razorpayKey, Ord=${razorpayOrderId.substring(0, 10)}...',
          ),
          duration: const Duration(seconds: 4),
        ),
      );

      // STRICT iOS Standard Options
      var options = {
        'key': razorpayKey,
        'amount': amount,
        'name': 'BunkBite',
        'description': 'Payment for Order $orderId',
        'order_id': razorpayOrderId,
        'prefill': {'contact': phone, 'email': userEmail},
        'theme': {
          'color': '#667eea', // STRICT requirement
        },
        'external': {
          'wallets': ['paytm'],
        },
        'retry': {'enabled': true, 'max_count': 1},
        'send_sms_hash': true,
      };

      _razorpay.open(options);
    } catch (e) {
      final friendlyError = _getUserFriendlyError(e);
      state = PaymentState(isLoading: false, error: friendlyError);
      if (context.mounted) {
        ErrorDialog.show(context, friendlyError, title: 'Checkout Failed');
      }
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // Verify payment
    final orderId = _currentOrderId;
    if (orderId == null) {
      return;
    }

    try {
      await _apiService.client.post(
        '/payments/verify',
        data: {
          'orderId': orderId,
          'razorpayPaymentId': response.paymentId,
          'razorpayOrderId': response.orderId,
          'razorpaySignature': response.signature,
        },
      );

      // Fetch the complete order details
      final orderRes = await _apiService.client.get('/orders/$orderId');
      final orderData = orderRes.data['data'] ?? orderRes.data;
      final order = OrderModel.fromJson(orderData);

      // Clear cart
      ref.read(cartProvider.notifier).clearCart();

      // Refresh orders list
      ref.read(ordersProvider.notifier).fetchOrders();

      // Navigate to order details screen
      if (_context != null && _context!.mounted) {
        Navigator.of(_context!).pushReplacement(
          MaterialPageRoute(builder: (_) => OrderDetailsScreen(order: order)),
        );

        ScaffoldMessenger.of(_context!).showSnackBar(
          const SnackBar(
            content: Text('Payment successful! Order placed.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      final friendlyError = _getUserFriendlyError(e);
      if (_context != null && _context!.mounted) {
        ErrorDialog.show(
          _context!,
          friendlyError,
          title: 'Payment Verification Failed',
        );
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    state = PaymentState(
      isLoading: false,
      error: 'Payment Failed: ${response.message ?? "Payment was cancelled"}',
    );
    if (_context != null && _context!.mounted) {
      final errorMessage = response.message?.isNotEmpty == true
          ? response.message!
          : 'Payment was cancelled or failed. Please try again.';

      ErrorDialog.show(_context!, errorMessage, title: 'Payment Failed');
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // Handle external wallet
  }
}

final paymentProvider = StateNotifierProvider<PaymentController, PaymentState>((
  ref,
) {
  return PaymentController(ApiService(), ref);
});
