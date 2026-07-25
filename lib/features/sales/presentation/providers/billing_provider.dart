import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../products/data/models/product_model.dart';
import '../../data/models/cart_item_model.dart';

final billingProvider = StateNotifierProvider<BillingNotifier, BillingState>((
  ref,
) {
  return BillingNotifier();
});

class BillingState {
  final List<CartItem> cart;
  final double discount;

  const BillingState({this.cart = const [], this.discount = 0});

  BillingState copyWith({List<CartItem>? cart, double? discount}) {
    return BillingState(
      cart: cart ?? this.cart,
      discount: discount ?? this.discount,
    );
  }

  double get subtotal => cart.fold(0.0, (sum, item) => sum + item.subtotal);

  double get tax => cart.fold(0.0, (sum, item) => sum + item.tax);

  double get itemDiscount =>
      cart.fold(0.0, (sum, item) => sum + item.discountAmount);

  double get grandTotal => subtotal - itemDiscount - discount + tax;

  int get totalItems => cart.fold(0, (sum, item) => sum + item.qty);

  bool get isEmpty => cart.isEmpty;

  bool get isNotEmpty => cart.isNotEmpty;
}

class BillingNotifier extends StateNotifier<BillingState> {
  BillingNotifier() : super(const BillingState());

  /// Add Product
  void addProduct(Product product, {int qty = 1}) {
    final cart = [...state.cart];

    final index = cart.indexWhere((item) => item.productId == product.id);

    if (index >= 0) {
      cart[index].qty += qty;
    } else {
      final finalQty = qty > availableStock ? availableStock : qty;

      cart.add(
        CartItem(
          productId: product.id!,
          name: product.name,
          category: product.category,
          price: product.sellingPrice,
          sgst: product.sgst,
          cgst: product.cgst,
          discount: product.discount,
          imagePath: product.imagePath,
          qty: 1,
        ),
      );
    }

    state = state.copyWith(cart: cart);
  }

  /// Remove Product
  void removeProduct(int productId) {
    final cart = [...state.cart];
    cart.removeWhere((item) => item.productId == productId);

    state = state.copyWith(cart: cart);
  }

  /// Increase Qty
  void increaseQty(int productId) {
    final cart = [...state.cart];

    final index = cart.indexWhere((item) => item.productId == productId);

    if (index == -1) return;

    cart[index].qty++;

    state = state.copyWith(cart: cart);
  }

  /// Decrease Qty
  void decreaseQty(int productId) {
    final cart = [...state.cart];

    final index = cart.indexWhere((item) => item.productId == productId);

    if (index == -1) return;

    if (cart[index].qty > 1) {
      cart[index].qty--;
    } else {
      cart.removeAt(index);
    }

    state = state.copyWith(cart: cart);
  }

  /// Update Qty
  void updateQty(int productId, int qty) {
    if (qty <= 0) {
      removeProduct(productId);
      return;
    }

    final cart = [...state.cart];

    final index = cart.indexWhere((item) => item.productId == productId);

    if (index == -1) return;

    cart[index].qty = qty;

    state = state.copyWith(cart: cart);
  }

  /// Clear Cart
  void clearCart() {
    state = const BillingState();
  }

  /// Bill Discount
  void setDiscount(double value) {
    state = state.copyWith(discount: value < 0 ? 0 : value);
  }
}
