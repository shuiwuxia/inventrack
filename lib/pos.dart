// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const MarketFlowInventoryApp());

class MarketFlowInventoryApp extends StatelessWidget {
  const MarketFlowInventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MarketFlow AI - POS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const POS(),
    );
  }
}

class POS extends StatefulWidget {
  const POS({super.key});

  @override
  State<POS> createState() => _POSState();
}

class _POSState extends State<POS> {
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> billItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  /// ✅ Fetch products from backend API
  Future<void> fetchProducts() async {
    const storeId = 'S1001';
    final url = Uri.parse('https://inventrack-backend-1.onrender.com/inventory/$storeId/products');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          // --- FIX: Correctly map API response keys to the product map ---
          products = data.map((p) => {
                "name": p["name"] ?? "Unnamed", // API sends 'name'
                "id": p["id"] ?? "N/A",         // API sends 'id', not 'sku'
                "mrp": (p["mrp"] ?? 0.0).toDouble(), // API sends 'mrp' as the price
                // Derive status from quantity ('qty')
                "status": (p["qty"] ?? 0) > 0 ? "In Stock" : "Out of Stock",
                "highDemand": false, // This field is not in the API response, default to false
              }).toList();
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load products");
      }
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("❌ Error fetching products: $e");
    }
  }

  /// ✅ Add product to bill
  void addToBill(Map<String, dynamic> product, int quantity) {
    setState(() {
      final existing =
          billItems.indexWhere((item) => item['id'] == product['id']);
      if (existing != -1) {
        billItems[existing]['quantity'] += quantity;
        billItems[existing]['total'] =
            (billItems[existing]['mrp'] as double) *
                billItems[existing]['quantity'];
      } else {
        // --- FIX: Use correct keys ('name', 'id', 'mrp') when adding to bill ---
        billItems.add({
          "product_name": product['name'],
          "id": product['id'],
          "mrp": product['mrp'],
          "quantity": quantity,
          "total": (product['mrp'] as double) * quantity,
        });
      }
    });
  }

  /// ✅ Show a dialog to add a product to the bill (for mobile)
  void _showAddProductDialog(Map<String, dynamic> product) {
    int quantity = 1;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(product['name']),
          content: Text("Price: ₹${product['mrp']}"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                addToBill(product, quantity);
                Navigator.pop(context);
              },
              child: const Text("Add to Bill"),
            ),
          ],
        );
      },
    );
  }

  /// ✅ Simulate payment and inventory update
  void proceedToPay() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Processing Payment...",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "✅ Inventory Updated Successfully!",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(bottom: 20, left: 20, right: 20),
        duration: Duration(seconds: 2),
      ),
    );

    setState(() {
      billItems.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount =
        billItems.fold(0.0, (sum, item) => sum + (item['total'] as double));

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("POS"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : products.isEmpty
              ? const Center(child: Text("No products found")) // Product Grid
              : Padding(
                  padding: const EdgeInsets.all(8.0), // Reduced padding for mobile
                  child: GridView.builder(
                    itemCount: products.length,
                    // Use SliverGridDelegateWithMaxCrossAxisExtent for responsiveness
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 200.0, // Max width for each item
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.9, // Adjust aspect ratio for better fit
                    ),
                    itemBuilder: (context, index) {
                      final p = products[index];
                      return InventoryItem(
                        name: p['name'],
                        sku: p['id'], // Use 'id' as SKU
                        price: p['mrp'].toString(), // Pass 'mrp' as price
                        status: p['status'],
                        highDemand: p['highDemand'],
                        // Use the dialog for adding to bill on mobile
                        onAddToBill: (quantity) => _showAddProductDialog(p),
                      );
                    },
                  ),
                ),
      // ✅ Bill Summary as a Bottom Sheet for mobile
      bottomSheet: billItems.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Bill Summary",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  // Scrollable list of bill items
                  SizedBox(
                    height: 150, // Constrain height
                    child: ListView.builder(
                      itemCount: billItems.length,
                      itemBuilder: (context, index) {
                        final item = billItems[index];
                        return ListTile(
                          title: Text(item['product_name']),
                          subtitle: Text("Qty: ${item['quantity']}"),
                          trailing: Text("₹${item['total']}"),
                        );
                      },
                    ),
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Total Amount:",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("₹${totalAmount.toStringAsFixed(2)}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // ✅ Proceed to Pay Button
                  ElevatedButton.icon(
                    icon: const Icon(Icons.payment),
                    label: const Text("Proceed to Pay"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: proceedToPay,
                  ),
                ],
              ),
            ),
    );
  }
}

/// ===============================
/// INVENTORY ITEM WIDGET
/// ===============================
class InventoryItem extends StatefulWidget {
  final String name;
  final String sku;
  final String price;
  final String status;
  final bool highDemand;
  final Function(int quantity) onAddToBill;

  const InventoryItem({
    super.key,
    required this.name,
    required this.sku,
    required this.price,
    required this.status,
    this.highDemand = false,
    required this.onAddToBill,
  });

  @override
  State<InventoryItem> createState() => _InventoryItemState();
}

class _InventoryItemState extends State<InventoryItem> {
  @override
  Widget build(BuildContext context) {
    // Use GestureDetector for taps on mobile instead of MouseRegion for hover
    return GestureDetector(
      onTap: () => widget.onAddToBill(1), // Pass a default quantity of 1
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shopping_bag, size: 40, color: Colors.deepPurple),
                const SizedBox(height: 8),
                Text(widget.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text("SKU: ${widget.sku}",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                // Use Wrap for chips to handle different numbers of chips gracefully
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  alignment: WrapAlignment.center,
                  children: [
                    Chip(
                      label: Text(widget.status,
                          style: const TextStyle(
                              fontSize: 10, color: Colors.white)),
                      backgroundColor: widget.status == "In Stock"
                          ? Colors.green
                          : Colors.orange,
                      visualDensity: VisualDensity.compact,
                    ),
                    if (widget.highDemand)
                      Chip(
                        label: const Text("High Demand",
                            style:
                                TextStyle(fontSize: 10, color: Colors.white)),
                        backgroundColor: Colors.orange,
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ],
            )),
      ),
    );
  }
}