import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/cart_item_model.dart';

final billingProvider = StateNotifierProvider<BillingNotifier, BillingState>((
  ref,
) {
  return BillingNotifier();
});

class BillingState {
  final List<CartItem> cart;
  final double discount;
  final double taxPercent;

  const BillingState({
    this.cart = const [],
    this.discount = 0,
    this.taxPercent = 18,
  });

  BillingState copyWith({
    List<CartItem>? cart,
    double? discount,
    double? taxPercent,
  }) {
    return BillingState(
      cart: cart ?? this.cart,
      discount: discount ?? this.discount,
      taxPercent: taxPercent ?? this.taxPercent,
    );
  }

  double get subtotal => cart.fold(0, (sum, item) => sum + item.total);

  double get tax => cart.fold(0, (sum, item) => sum + item.tax);

  double get total => subtotal - discount + tax;
}

class BillingNotifier extends StateNotifier<BillingState> {
  BillingNotifier() : super(const BillingState());

  void addToCart(Map<String, dynamic> product, int qty) {
    final availableStock =
        (product["quantity"] ?? product["stock"] ?? 0) as int;
    if (availableStock <= 0) {
      return;
    }

    final cart = [...state.cart];
    final index = cart.indexWhere((c) => c.productId == product["id"]);

    if (index != -1) {
      // ── FIX: Cap the addition at available stock count ──
      if (cart[index].qty + qty > availableStock) {
        cart[index].qty = availableStock;
      } else {
        cart[index].qty += qty;
      }
    } else {
      final finalQty = qty > availableStock ? availableStock : qty;

      cart.add(
        CartItem(
          productId: product["id"],
          name: product["name"],
          price: (product["selling_price"] as num).toDouble(),
          sgst: (product["sgst"] ?? 0).toDouble(),
          cgst: (product["cgst"] ?? 0).toDouble(),
          discount: (product["discount"] ?? 0).toDouble(),
          imagePath: product["image_path"],
          qty: finalQty,
        ),
      );
    }

    state = state.copyWith(cart: cart);
  }

  // ── FIX: Enforce real availableStock bounds to prevent over-adding items ──
  void increaseQty(int index, [int? availableStock]) {
    final cart = [...state.cart];
    final maxStock = availableStock ?? 99999;

    if (cart[index].qty < maxStock) {
      cart[index].qty++;
      state = state.copyWith(cart: cart);
    }
  }

  void decreaseQty(int index) {
    final cart = [...state.cart];

    if (cart[index].qty > 1) {
      cart[index].qty--;
    }

    state = state.copyWith(cart: cart);
  }

  void removeItem(int index) {
    final cart = [...state.cart];
    cart.removeAt(index);
    state = state.copyWith(cart: cart);
  }

  void clearCart() {
    state = state.copyWith(cart: []);
  }

  void setDiscount(double value) {
    state = state.copyWith(discount: value);
  }
}
