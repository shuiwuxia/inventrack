

// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'login_screen.dart'; 

// --- MODEL & MOCK DATA ---

class Product {
  final String name;
  final String storeName;
  final double rating;
  final double mrp;
  final String imageUrl;
  final double distance;
  final int stockQuantity;
  final bool isLowStock;
  final bool isHighDemand;

  Product({
    required this.name,
    required this.storeName,
    required this.rating,
    required this.mrp,
    required this.imageUrl,
    required this.distance,
    required this.stockQuantity,
    required this.isLowStock,
    required this.isHighDemand,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final random = Random();
    final category = json['category'] as String?;
    
    // Set distance based on category as requested
    double distance = (category == 'Clothing') ? 0.5 : double.parse((random.nextDouble() * 10 + 1).toStringAsFixed(1));

    return Product(
      name: json['name'] ?? 'Unknown Product',
      storeName: json['category'] ?? 'Uncategorized', // Use category as store name for display
      rating: double.parse((random.nextDouble() * 2.0 + 3.0).toStringAsFixed(1)), // Generate random rating 3.0-5.0
      mrp: (json['mrp'] ?? 0.0).toDouble(),
      imageUrl: '', // API does not provide an image URL
      distance: distance,
      stockQuantity: random.nextInt(100) + 1, // Generate random stock 1-100
      isLowStock: random.nextBool(), // Generate random status
      isHighDemand: random.nextBool(), // Generate random status
    );
  }
}

class Shop {
  final String name;
  final String address;
  final double distance;

  Shop({required this.name, required this.address, required this.distance});

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      name: json['name'] ?? 'Unknown Shop',
      address: json['address'] ?? 'No address',
      distance: (json['distance'] ?? 0.0).toDouble(),
    );
  }
}

class NotificationItem {
  final String title;
  final String message;
  final String productName;

  NotificationItem({required this.title, required this.message, required this.productName});

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      productName: json['productName'] ?? '',
    );
  }
}

class CartItem {
  final Product product;
  final int quantity;

  CartItem({required this.product, required this.quantity});
}

class ConsumerSummary {
  final String fullName;
  final String phone;
  final String email;
  final String address;

  ConsumerSummary({
    required this.fullName,
    required this.phone,
    required this.email,
    required this.address,
  });
}

class MockProfileData {
  String fullName = 'Guest User';
  String phone = '+1 555-123-4567';
  String email = 'guest@inventrack.com';
  String address = '100 Inventory Lane';
}
final MockProfileData mockProfile = MockProfileData();

class CartModel extends ChangeNotifier {
  final List<CartItem> _items = [];
  List<CartItem> get items => _items;

  void addItem(Product product, int quantity) {
    final existingIndex = _items.indexWhere((item) => item.product.name == product.name);
    
    if (existingIndex != -1) {
      final existingItem = _items[existingIndex];
      _items[existingIndex] = CartItem(product: existingItem.product, quantity: existingItem.quantity + quantity);
    } else {
      _items.add(CartItem(product: product, quantity: quantity));
    }
    notifyListeners();
  }
  
  void removeItem(String productName) {
    _items.removeWhere((item) => item.product.name == productName);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
final CartModel cartModel = CartModel();

class ApiService {
  static const String mockAuthToken = 'mock-jwt-token-for-demo'; 

  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $mockAuthToken',
  };

  static Future<List<NotificationItem>> fetchNotifications() async {
    await Future.delayed(const Duration(milliseconds: 500)); 
    return []; 
  }

  // --- MODIFIED: Implemented to fetch live product data ---
  static Future<List<Product>> fetchProducts({String? searchQuery, bool? onlyLowStock, bool? onlyHighDemand}) async {
    final url = Uri.parse('http://192.168.42.146:8000/products/all');
   
    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        return data.map((item) => Product.fromJson(item)).toList();
      } else {
        debugPrint('Failed to load products: ${response.statusCode}');
        return []; // Return empty list on failure
      }
    } catch (e) {
      debugPrint('Error fetching products: $e');
      return [];
    }
  }

  // --- MODIFIED: Implemented to fetch live shop data ---
  static Future<List<Shop>> fetchShops() async {
    final url = Uri.parse('http://192.168.42.146:8000/shops/all');
   
    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        return data.map((item) => Shop.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  List<Product> _allProducts = []; // List to hold ALL fetched products
  List<Shop> _shops = [];
  final int _notificationCount = 3;
  List<String> _categories = []; // Will be populated from fetched products
  String? _selectedCategory; // To track the active category filter
  bool _isLoading = true;
  bool _locationAccessGranted = false; 

  @override
  void initState() {
    super.initState();
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndPromptLocation(context);
    });
  }

  Future<void> _checkAndPromptLocation(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final hasPrompted = prefs.getBool('location_prompted') ?? false;

    if (!hasPrompted) {
      await Future.delayed(const Duration(milliseconds: 300)); 
      
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Allow Location Access?'),
          content: const Text('To show the nearest stores and product stock, Inventrack requires access to your current location.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('DENY'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('ALLOW'),
            ),
          ],
        ),
      );

      await prefs.setBool('location_prompted', true);
      
      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permission mock-granted!')));
        setState(() => _locationAccessGranted = true);
        _loadData(); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location denied. Showing default results.'), backgroundColor: Colors.redAccent));
        setState(() => _locationAccessGranted = false);
      }
    } else {
        // Assuming permission is granted if prompted before
        setState(() => _locationAccessGranted = true);
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Fetch ALL products for the main consumer view
      final products = await ApiService.fetchProducts(); 
      final shops = await ApiService.fetchShops();

      setState(() {
        _allProducts = products.isEmpty ? _getMockAllProducts() : products;
        _shops = shops.isEmpty ? _getMockShops() : shops;

        // --- MODIFIED: Dynamically generate categories from products ---
        _categories = ['All', ..._allProducts.map((p) => p.storeName).toSet()];
        _selectedCategory = 'All'; // Default to show all products

        _isLoading = false;
        // Sort shops by nearest distance
        _shops.sort((a, b) => a.distance.compareTo(b.distance)); 
        // Sort products by nearest distance
        _allProducts.sort((a, b) => a.distance.compareTo(b.distance)); 
      });
    } catch (e) {
      setState(() {
        _allProducts = _getMockAllProducts(); // Fallback to mock data on error
        _shops = _getMockShops(); // Fallback to mock data on error

        // Also generate categories for mock data
        _categories = ['All', ..._allProducts.map((p) => p.storeName).toSet()];
        _selectedCategory = 'All';

        _isLoading = false;
        // Also sort mock data
        _shops.sort((a, b) => a.distance.compareTo(b.distance)); 
        _allProducts.sort((a, b) => a.distance.compareTo(b.distance));
      });
      debugPrint('Error loading data, using mock: $e');
    }
  }
  
  // New mock data function to simulate a larger product catalog
  List<Product> _getMockAllProducts() {
    return [
      Product(name: 'Wireless Mouse (Logitech)', storeName: 'Tech Hub', rating: 4.5, mrp: 29.99, imageUrl: 'https://placehold.co/60x60/87CEEB/FFFFFF?text=Mouse', distance: 1.2, stockQuantity: 5, isLowStock: true, isHighDemand: false),
      Product(name: 'Blue Denim Jeans', storeName: 'Fashion Co.', rating: 4.0, mrp: 59.99, imageUrl: 'https://placehold.co/60x60/F08080/FFFFFF?text=Jeans', distance: 3.5, stockQuantity: 200, isLowStock: false, isHighDemand: true),
      Product(name: 'Fantasy Adventure Book', storeName: 'Read World', rating: 4.9, mrp: 15.50, imageUrl: 'https://placehold.co/60x60/90EE90/FFFFFF?text=Book', distance: 0.8, stockQuantity: 12, isLowStock: false, isHighDemand: false),
      Product(name: 'Mechanical Keyboard', storeName: 'Tech Hub', rating: 4.8, mrp: 120.00, imageUrl: 'https://placehold.co/60x60/87CEEB/FFFFFF?text=Keyboard', distance: 5.0, stockQuantity: 3, isLowStock: true, isHighDemand: true),
      Product(name: 'A4 Notebook', storeName: 'Campus Supplies', rating: 4.1, mrp: 3.99, imageUrl: 'https://placehold.co/60x60/FFD700/000000?text=Note', distance: 0.3, stockQuantity: 50, isLowStock: false, isHighDemand: false),
      Product(name: 'White T-Shirt', storeName: 'Fashion Co.', rating: 3.9, mrp: 19.99, imageUrl: 'https://placehold.co/60x60/F08080/FFFFFF?text=Tshirt', distance: 2.1, stockQuantity: 10, isLowStock: true, isHighDemand: false),
      Product(name: 'Ergonomic Chair', storeName: 'Main Warehouse', rating: 4.6, mrp: 250.00, imageUrl: 'https://placehold.co/60x60/98FB98/000000?text=Chair', distance: 0.5, stockQuantity: 15, isLowStock: false, isHighDemand: true),
    ];
  }

  List<Shop> _getMockShops() {
    return [
      Shop(name: 'Main Warehouse', address: '101 Inventory Ave', distance: 0.5),
      Shop(name: 'City Store East', address: '25 Commerce Blvd', distance: 2.1),
      Shop(name: 'Campus Supplies', address: '12 University Road', distance: 0.3),
      Shop(name: 'Mega Mart', address: '99 Highway Lane', distance: 8.0),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildHomeContent(), // This now shows all products
      const SearchScreen(query: 'all'),
      const CartScreen(), 
      const ProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventrack'),
        actions: [
          Stack(
            children: [
              IconButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsScreen())),
                icon: const Icon(Icons.notifications_outlined),
              ),
              if (_notificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Text('$_notificationCount', style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ),
            ],
          ),
          IconButton(
            onPressed: () => setState(() => _currentIndex = 2), 
            icon: const Icon(Icons.shopping_cart),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: _currentIndex,
              children: screens,
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    // Separate the low stock products for the highlighted section
    final lowStockProducts = _allProducts.where((p) => p.isLowStock).toList();

    // --- MODIFIED: Filter products based on the selected category ---
    final filteredProducts = _selectedCategory == null || _selectedCategory == 'All'
        ? _allProducts
        // Note: We are using `storeName` as it holds the category from the API
        : _allProducts.where((p) => p.storeName == _selectedCategory).toList();
    
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Search Bar (Directly navigates to SearchScreen)
            Card(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search Products',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.all(16),
                  fillColor: Colors.grey[50],
                  filled: true,
                ),
                onSubmitted: (query) {
                  // Navigate to the search screen with the query, then switch tab
                  if (query.isNotEmpty) {
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => SearchScreen(query: query)));
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
            
            // 2. Categories
            const Text('Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      labelStyle: TextStyle(color: _selectedCategory == _categories[index] ? Colors.white : Colors.black),
                      backgroundColor: Colors.grey[200],
                      selectedColor: Theme.of(context).colorScheme.primary,
                      label: Text(_categories[index]),
                      selected: _selectedCategory == _categories[index],
                      onSelected: (isSelected) {
                        setState(() => _selectedCategory = isSelected ? _categories[index] : null);
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            
            // 3. Nearest Shops
            Text('Nearest Shops ${_locationAccessGranted ? '(Location Enabled)' : '(Location Disabled)'}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _shops.length > 3 ? 3 : _shops.length, // Show only top 3 shops
              itemBuilder: (context, index) => _buildShopCard(_shops[index]),
            ),
            const SizedBox(height: 16),
            
            // 4. Low Stock/Highlighted Products (Optional Section)
            if (lowStockProducts.isNotEmpty) ...[
              const Text('⚠️ Low Stock Alert', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: lowStockProducts.length > 3 ? 3 : lowStockProducts.length, // Show top 3 low stock
                itemBuilder: (context, index) => ProductCard(product: lowStockProducts[index]),
              ),
              const SizedBox(height: 16),
            ],
            
            // 5. ALL Products (The primary consumer catalogue)
            const Text('All Products', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            filteredProducts.isEmpty ? const Padding(padding: EdgeInsets.all(16.0), child: Center(child: Text("No products found in this category."))) : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) => ProductCard(product: filteredProducts[index]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopCard(Shop shop) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.store, color: Colors.deepPurple),
        title: Text(shop.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(shop.address),
        trailing: Text('${shop.distance}km', style: const TextStyle(fontWeight: FontWeight.bold)),
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Shop ${shop.name} details')),
        ),
      ),
    );
  }
}

// --- PRODUCT DETAIL SCREEN ---

class ProductDetailScreen extends StatelessWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  void _addToCart(BuildContext context) {
    cartModel.addItem(product, 1);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product.name} added to cart!'), backgroundColor: Colors.green),
    );
  }

  void _showGoogleMapsPlaceholder(BuildContext context, String storeName, double distance) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Simulating navigation to $storeName, located ${distance}km away (Google Maps API integration needed).')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 250,
              width: double.infinity,
              color: Colors.grey[200],
              child: product.imageUrl.isNotEmpty
                  ? Image.network(product.imageUrl, fit: BoxFit.cover, errorBuilder: (c, o, s) => const Center(child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey)))
                  : const Center(child: Icon(Icons.inventory, size: 50, color: Colors.grey)),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: 8),
                  Text('Store: ${product.storeName}', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[700])),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('\$${product.mrp.toStringAsFixed(2)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.deepPurple)),
                      Row(
                        children: [
                          ...List.generate(5, (i) => Icon(
                            i < product.rating.floor() ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 20,
                          )),
                          Text(' ${product.rating}', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 30),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Theme.of(context).colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text('Distance: ${product.distance}km', style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.inventory_2, color: Colors.green.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text('Stock Available: ${product.stockQuantity}', style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                  if (product.isLowStock) ...[
                    const SizedBox(height: 12),
                    const Text('Low Stock Alert!', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                  if (product.isHighDemand) ...[
                    const SizedBox(height: 12),
                    const Text('High Demand!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () => _addToCart(context),
                      icon: const Icon(Icons.shopping_cart),
                      label: const Text('Add to Cart', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () => _showGoogleMapsPlaceholder(context, product.storeName, product.distance),
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('Show on Map', style: TextStyle(fontSize: 18)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        side: BorderSide(color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- PRODUCT CARD ---

class ProductCard extends StatelessWidget {
  final Product product;
  const ProductCard({super.key, required this.product});

  void _addToCart(BuildContext context) {
    cartModel.addItem(product, 1);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product.name} added to cart!'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProductDetailScreen(product: product)),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  image: product.imageUrl.isNotEmpty
                      ? DecorationImage(image: NetworkImage(product.imageUrl), fit: BoxFit.cover)
                      : null,
                ),
                child: product.imageUrl.isEmpty ? const Icon(Icons.image, color: Colors.grey) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Store: ${product.storeName}', style: TextStyle(color: Colors.grey[600])),
                    Row(
                      children: [
                        ...List.generate(5, (i) => Icon(
                          i < product.rating.floor() ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 16,
                        )),
                        Text(' ${product.rating}'),
                      ],
                    ),
                    Text('MRP: \$${product.mrp.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.green)),
                    if (product.isLowStock) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.orange.shade400, borderRadius: BorderRadius.circular(4)),
                        child: Text('Low Stock (${product.stockQuantity})', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                    if (product.isHighDemand && !product.isLowStock) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.green.shade400, borderRadius: BorderRadius.circular(4)),
                        child: const Text('High Demand', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(
                width: 70,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: () => _addToCart(context),
                      icon: const Icon(Icons.add_shopping_cart, size: 20, color: Colors.blue),
                      tooltip: 'Add to Cart',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Icon(Icons.location_on, color: Colors.deepPurple, size: 16),
                        Text('${product.distance}km', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- SEARCH SCREEN ---

class SearchScreen extends StatefulWidget {
  final String query;
  const SearchScreen({super.key, required this.query});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<Product> _searchResults = [];
  bool _isLoading = true;
  String _currentSort = 'nearest';

  @override
  void initState() {
    super.initState();
    _searchProducts();
  }

  @override
  void didUpdateWidget(covariant SearchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      _searchProducts();
    }
  }

  Future<void> _searchProducts() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500)); 
    try {
      final results = await ApiService.fetchProducts(searchQuery: widget.query);
      _searchResults = results.isEmpty ? _getMockProducts(widget.query) : results;
    } catch (e) {
      _searchResults = _getMockProducts(widget.query);
      debugPrint('Search error, using mock: $e');
    }
    
    _applySort(_currentSort);
    setState(() => _isLoading = false);
  }

  List<Product> _getMockProducts(String query) {
    final allProducts = [
      Product(name: 'Wireless Mouse (Logitech)', storeName: 'Tech Hub', rating: 4.5, mrp: 29.99, imageUrl: 'https://placehold.co/60x60/87CEEB/FFFFFF?text=Mouse', distance: 1.2, stockQuantity: 5, isLowStock: true, isHighDemand: false),
      Product(name: 'Blue Denim Jeans', storeName: 'Fashion Co.', rating: 4.0, mrp: 59.99, imageUrl: 'https://placehold.co/60x60/F08080/FFFFFF?text=Jeans', distance: 3.5, stockQuantity: 200, isLowStock: false, isHighDemand: true),
      Product(name: 'Fantasy Adventure Book', storeName: 'Read World', rating: 4.9, mrp: 15.50, imageUrl: 'https://placehold.co/60x60/90EE90/FFFFFF?text=Book', distance: 0.8, stockQuantity: 12, isLowStock: false, isHighDemand: false),
      Product(name: 'Mechanical Keyboard', storeName: 'Tech Hub', rating: 4.8, mrp: 120.00, imageUrl: 'https://placehold.co/60x60/87CEEB/FFFFFF?text=Keyboard', distance: 5.0, stockQuantity: 3, isLowStock: true, isHighDemand: true),
      Product(name: 'A4 Notebook', storeName: 'Campus Supplies', rating: 4.1, mrp: 3.99, imageUrl: 'https://placehold.co/60x60/FFD700/000000?text=Note', distance: 0.3, stockQuantity: 50, isLowStock: false, isHighDemand: false),
    ];
    
    if (query == 'all' || query.isEmpty) return allProducts;
    return allProducts.where((p) => p.name.toLowerCase().contains(query.toLowerCase())).toList();
  }

  void _applySort(String sortType) {
    _currentSort = sortType;
    if (sortType == 'nearest') {
      _searchResults.sort((a, b) => a.distance.compareTo(b.distance));
    } else if (sortType == 'price') {
      _searchResults.sort((a, b) => a.mrp.compareTo(b.mrp));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Results for "${widget.query}"'),
        automaticallyImplyLeading: false, 
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _currentSort,
                    decoration: const InputDecoration(
                      labelText: 'Sort By',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'nearest', child: Text('Nearest Distance')),
                      DropdownMenuItem(value: 'price', child: Text('Lowest Price')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _applySort(value);
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Finding current GPS location and refreshing distances...')),
                    );
                  },
                  icon: const Icon(Icons.my_location, color: Colors.blue),
                  tooltip: 'Use current location',
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                    ? Center(child: Text('No results found for "${widget.query}"'))
                    : ListView.builder(
                        itemCount: _searchResults.length,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) => ProductCard(product: _searchResults[index]),
                      ),
          ),
        ],
      ),
    );
  }
}

// --- PROFILE SCREEN (CONSUMER) ---

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  ConsumerSummary _consumerSummary = ConsumerSummary(
    fullName: mockProfile.fullName,
    phone: mockProfile.phone,
    email: mockProfile.email,
    address: mockProfile.address,
  );
  bool _isLoading = true;
  bool _editing = false;
  
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _addrCtrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load data from SharedPreferences
    final fullName = prefs.getString('fullName') ?? mockProfile.fullName;
    final phone = prefs.getString('phone') ?? mockProfile.phone;
    final email = prefs.getString('email') ?? mockProfile.email;
    final address = prefs.getString('address') ?? mockProfile.address;

    setState(() {
      _consumerSummary = ConsumerSummary(
        fullName: fullName,
        phone: phone,
        email: email,
        address: address,
      );
      _nameCtrl = TextEditingController(text: _consumerSummary.fullName);
      _emailCtrl = TextEditingController(text: _consumerSummary.email);
      _phoneCtrl = TextEditingController(text: _consumerSummary.phone);
      _addrCtrl = TextEditingController(text: _consumerSummary.address);
      _isLoading = false;
    });
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString('fullName', _nameCtrl.text);
    await prefs.setString('email', _emailCtrl.text);
    await prefs.setString('phone', _phoneCtrl.text);
    await prefs.setString('address', _addrCtrl.text);

    setState(() {
      _consumerSummary = ConsumerSummary(
        fullName: _nameCtrl.text,
        phone: _phoneCtrl.text,
        email: _emailCtrl.text,
        address: _addrCtrl.text,
      );
      _editing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
  }

  void _changePassword() {
    showDialog(context: context, builder: (_) {
      final oldCtrl = TextEditingController();
      final newCtrl = TextEditingController();
      final confirmCtrl = TextEditingController();
      return AlertDialog(
        title: const Text('Change Password'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: oldCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Old password')),
          TextField(controller: newCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'New password')),
          TextField(controller: confirmCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm password')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () async {
            if (newCtrl.text != confirmCtrl.text) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New passwords do not match')));
              return;
            }
            final prefs = await SharedPreferences.getInstance();
            final saved = prefs.getString('password') ?? '';
            // NOTE: This uses SharedPreferences as a mock authentication store. Not secure in production.
            if (oldCtrl.text != saved) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wrong old password')));
              return;
            }
            await prefs.setString('password', newCtrl.text);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed')));
          }, child: const Text('Change')),
        ],
      );
    });
  }
  
  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addrCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile'), automaticallyImplyLeading: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _editing ? _editForm() : _viewProfile(),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: () => _changePassword(), child: const Text('Change Password')),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                onPressed: () {
                   Navigator.pushAndRemoveUntil(
                      context, 
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (Route<dynamic> route) => false,
                   );
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logged out!')));
                },
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              ),
            ),
          ]
        ),
      ),
    );
  }

  Widget _viewProfile() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Full Name: ${_consumerSummary.fullName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      const SizedBox(height: 10),
      _buildInfoRow(Icons.email_outlined, _consumerSummary.email),
      _buildInfoRow(Icons.phone_outlined, _consumerSummary.phone),
      _buildInfoRow(Icons.location_on_outlined, _consumerSummary.address),
      const SizedBox(height: 12),
      ElevatedButton.icon(
        onPressed: () => setState(() => _editing = true), 
        icon: const Icon(Icons.edit),
        label: const Text('Edit Profile'),
      ),
    ]);
  }
  
  Widget _buildInfoRow(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.deepPurple),
          const SizedBox(width: 8),
          Flexible(child: Text(value)),
        ],
      ),
    );
  }

  Widget _editForm() {
    return Column(children: [
      TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
      const SizedBox(height: 8),
      TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email', hintText: 'consumer@example.com')),
      const SizedBox(height: 8),
      TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Phone', hintText: '+1 555-123-4567')),
      const SizedBox(height: 8),
      TextField(controller: _addrCtrl, decoration: const InputDecoration(labelText: 'Address')),
      const SizedBox(height: 12),
      Row(children: [
        ElevatedButton(onPressed: _saveProfile, child: const Text('Save')),
        const SizedBox(width: 12),
        OutlinedButton(onPressed: () {
          _nameCtrl.text = _consumerSummary.fullName;
          _emailCtrl.text = _consumerSummary.email;
          _phoneCtrl.text = _consumerSummary.phone;
          _addrCtrl.text = _consumerSummary.address;
          setState(() => _editing = false);
        }, child: const Text('Cancel')),
      ])
    ]);
  }
}

// --- CART SCREEN ---

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {

  @override
  void initState() {
    super.initState();
    cartModel.addListener(_onCartChanged);
  }

  @override
  void dispose() {
    cartModel.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() {
    setState(() {}); 
  }

  double get _totalPrice => cartModel.items.fold(0.0, (sum, item) => sum + (item.product.mrp * item.quantity));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        automaticallyImplyLeading: false,
      ),
      body: cartModel.items.isEmpty
            ? Center(child: Text('Your cart is empty.', style: Theme.of(context).textTheme.headlineMedium))
            : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: cartModel.items.length,
                      itemBuilder: (context, index) {
                        final item = cartModel.items[index];
                        return CartItemCard(item: item);
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Subtotal:', style: Theme.of(context).textTheme.headlineMedium),
                            Text('\$${_totalPrice.toStringAsFixed(2)}', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.deepPurple)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              cartModel.clearCart();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Order Placed! Cart Cleared (Mock Action)'), backgroundColor: Colors.green),
                              );
                            },
                            icon: const Icon(Icons.payment),
                            label: const Text('Checkout', style: TextStyle(fontSize: 18)),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
    );
  }
}

class CartItemCard extends StatelessWidget {
  final CartItem item;

  const CartItemCard({super.key, required this.item});

  void _removeItem(BuildContext context) {
    cartModel.removeItem(item.product.name);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item.product.name} removed from cart.'), backgroundColor: Colors.redAccent),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: item.product.imageUrl.isNotEmpty
                ? DecorationImage(image: NetworkImage(item.product.imageUrl), fit: BoxFit.cover)
                : null,
            color: Colors.grey[200],
          ),
          child: item.product.imageUrl.isEmpty ? const Icon(Icons.image, size: 24, color: Colors.grey) : null,
        ),
        title: Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Store: ${item.product.storeName}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Qty: ${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('\$${(item.product.mrp * item.quantity).toStringAsFixed(2)}', style: const TextStyle(color: Colors.green)),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _removeItem(context),
            )
          ],
        ),
      ),
    );
  }
}

// --- NOTIFICATIONS SCREEN ---

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationItem> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }
  
  List<NotificationItem> _getMockNotifications() {
    return [
      NotificationItem(title: 'Low Stock Alert', message: 'Only 5 units left!', productName: 'Wireless Mouse'),
      NotificationItem(title: 'High Demand', message: 'Product is trending!', productName: 'Blue Denim Jeans'),
      NotificationItem(title: 'Price Drop', message: 'Price decreased by 10%', productName: 'Adventure Book'),
    ];
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500)); 

    try {
      final notifications = await ApiService.fetchNotifications();
      _notifications = notifications.isEmpty ? _getMockNotifications() : notifications;
    } catch (e) {
      _notifications = _getMockNotifications();
      debugPrint('Error loading notifications, using mock: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _notifications.length,
                padding: const EdgeInsets.all(8),
                itemBuilder: (context, index) {
                  final notif = _notifications[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: ListTile(
                      leading: Icon(
                        notif.title.contains('Low Stock') 
                            ? Icons.warning_amber 
                            : notif.title.contains('High Demand')
                                ? Icons.trending_up
                                : Icons.discount,
                        color: notif.title.contains('Low Stock') ? Colors.orange : Colors.green,
                      ),
                      title: Text(notif.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${notif.message} - ${notif.productName}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Viewing details for: ${notif.productName}')),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
    );
  }
}
