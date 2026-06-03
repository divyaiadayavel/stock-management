import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/db_helper.dart';
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

  double get tax => subtotal * taxPercent / 100;

  double get total => subtotal - discount + tax;
}

class BillingNotifier extends StateNotifier<BillingState> {
  BillingNotifier() : super(const BillingState());

  void addToCart(Map<String, dynamic> product, int qty) {
    final cart = [...state.cart];

    final index = cart.indexWhere((c) => c.productId == product["id"]);

    if (index != -1) {
      cart[index].qty += qty;
    } else {
      cart.add(
        CartItem(
          productId: product["id"],
          name: product["name"],
          price: (product["selling_price"] as num).toDouble(),
          qty: qty,
        ),
      );
    }

    state = state.copyWith(cart: cart);
  }

  void increaseQty(int index) {
    final cart = [...state.cart];
    cart[index].qty++;
    state = state.copyWith(cart: cart);
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
}
