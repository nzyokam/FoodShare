import 'food.dart'; 

class CartManager {
  final List<Food> _cartItems = [];

  // Getter to return the list of cart items
  List<Food> get cartItems => List.unmodifiable(_cartItems);

  // Getter for total number of items in cart
  int get totalItems => _cartItems.length;

  // Adds a food item to the cart
  void addToCart(Food food) {
    _cartItems.add(food);
  }

  // Removes a food item from the cart
  void removeFromCart(Food food) {
    _cartItems.remove(food);
  }

  // Clears all items from the cart
  void clearCart() {
    _cartItems.clear();
  }

  // Checks if a food item is already in the cart
  bool isInCart(Food food) {
    return _cartItems.contains(food);
  }
}
