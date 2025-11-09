// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
// ignore: unused_import
import 'package:csv/csv.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const MarketFlowInventoryApp());

class MarketFlowInventoryApp extends StatelessWidget {
  const MarketFlowInventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MarketFlow AI - Inventory',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const InventoryPage(storeId: ""), // storeId will be passed dynamically
    );
  }
}

class InventoryPage extends StatefulWidget {
  final String storeId; // dynamic store id
  const InventoryPage({super.key, required this.storeId});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  int? expandedIndex;
  int? editingIndex;
  bool addingNew = false;
  String searchQuery = "";
  String selectedFilterCategory = "All";
  bool loading = false;

  final List<String> categories = [
    "Clothing",
    "Stationary",
    "Retail",
    "Books",
    "Electronics"
  ];

  List<Map<String, dynamic>> products = [];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    if (widget.storeId.isEmpty) return;
    setState(() => loading = true);
    final String apiUrl = "http://localhost:8000/inventory/${widget.storeId}/products";
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          setState(() {
            products = List<Map<String, dynamic>>.from(data);
          });
        }
      } else {
        if (kDebugMode) print("Fetch Error: ${response.statusCode}");
      }
    } catch (e) {
      if (kDebugMode) print("Network Error: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  List<Map<String, dynamic>> get filteredProducts {
    final q = searchQuery.trim().toLowerCase();
    return products.where((p) {
      final matchesSearch = q.isEmpty || p["name"].toString().toLowerCase().contains(q);
      final matchesCategory = selectedFilterCategory == "All" || p["category"] == selectedFilterCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = screenWidth > 1100
        ? 4
        : screenWidth > 800
            ? 3
            : screenWidth > 500
                ? 2
                : 1;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Inventory Management"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: "Upload CSV",
            icon: const Icon(Icons.upload_file),
            onPressed: _uploadCSV,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.deepPurple))
          : GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
                setState(() {
                  addingNew = false;
                  editingIndex = null;
                  expandedIndex = null;
                });
              },
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.deepPurple.shade50),
                            ),
                            child: DropdownButton<String>(
                              value: selectedFilterCategory,
                              underline: const SizedBox(),
                              items: [
                                const DropdownMenuItem(value: "All", child: Text("All")),
                                ...categories.map((c) => DropdownMenuItem(value: c, child: Text(c)))
                              ],
                              onChanged: (val) {
                                setState(() {
                                  selectedFilterCategory = val ?? "All";
                                  expandedIndex = null;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              onChanged: (value) {
                                setState(() => searchQuery = value);
                              },
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.search, color: Colors.deepPurple),
                                hintText: "Search products by name...",
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            tooltip: "Refresh",
                            icon: const Icon(Icons.refresh, color: Colors.deepPurple),
                            onPressed: _fetchProducts,
                          )
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: filteredProducts.isEmpty
                            ? const Center(child: Text("No products found.", style: TextStyle(color: Colors.grey)))
                            : GridView.builder(
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 16,
                                  childAspectRatio: 1.05,
                                ),
                                itemCount: filteredProducts.length,
                                itemBuilder: (context, index) {
                                  final product = filteredProducts[index];
                                  final isExpanded = expandedIndex == index;
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        expandedIndex = isExpanded ? null : index;
                                        editingIndex = null;
                                        addingNew = false;
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      decoration: BoxDecoration(
                                        color: Colors.deepPurple[50],
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(2, 3))
                                        ],
                                      ),
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Icon(Icons.inventory_2, size: 44, color: Colors.deepPurple),
                                                const SizedBox(height: 8),
                                                Text(product["name"] ?? "",
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                                const SizedBox(height: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(color: Colors.deepPurple.shade100),
                                                  ),
                                                  child: Text(
                                                    product["category"] ?? "Uncategorized",
                                                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          AnimatedCrossFade(
                                            duration: const Duration(milliseconds: 300),
                                            firstChild: const SizedBox.shrink(),
                                            secondChild: _hoverDetails(product),
                                            crossFadeState: isExpanded
                                                ? CrossFadeState.showSecond
                                                : CrossFadeState.showFirst,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.deepPurple,
        onPressed: () {
          setState(() {
            addingNew = true;
            editingIndex = null;
            expandedIndex = null;
          });
        },
        icon: const Icon(Icons.add),
        label: const Text("Add Product"),
      ),
      bottomSheet: (editingIndex != null)
          ? _editPanel(products[editingIndex!], false)
          : (addingNew ? _editPanel({}, true) : null),
    );
  }

  Widget _hoverDetails(Map<String, dynamic> product) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.deepPurple.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("MRP: ₹${product["mrp"]} | MSP: ₹${product["msp"]}", style: const TextStyle(fontSize: 12)),
          Text("Qty: ${product["qty"]} units", style: const TextStyle(fontSize: 12)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                onPressed: () {
                  setState(() {
                    editingIndex = products.indexOf(product);
                    addingNew = false;
                    expandedIndex = null;
                  });
                },
                child: const Text("Edit"),
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _editPanel(Map<String, dynamic> product, bool isAdding) {
    final nameController = TextEditingController(text: product["name"] ?? "");
    final mrpController = TextEditingController(text: product["mrp"]?.toString() ?? "");
    final mspController = TextEditingController(text: product["msp"]?.toString() ?? "");
    final qtyController = TextEditingController(text: product["qty"]?.toString() ?? "");
    final String productCategory = product["category"] ?? categories.first;
    String selectedCategory = _mapToBroadCategory(productCategory);
    if (!categories.contains(selectedCategory)) {
      selectedCategory = categories.first;
    }

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade300))),
        padding: const EdgeInsets.all(16),
        height: 360,
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isAdding ? "Add New Product" : "Editing: ${product["name"] ?? ""}",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Expanded(
              child: ListView(
                children: [
                  _buildTextField("Name", nameController),
                  _buildTextField("MRP", mrpController),
                  _buildTextField("MSP", mspController),
                  _buildTextField("Quantity", qtyController),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory, 
                    items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) {
                      selectedCategory = val!; 
                    },
                    decoration: const InputDecoration(labelText: "Category", border: OutlineInputBorder()),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton(
                onPressed: () async {
                  final newProduct = {
                    "name": nameController.text.trim(),
                    "status": "In Stock",
                    "demand": "Moderate",
                    "mrp": double.tryParse(mrpController.text) ?? 0,
                    "msp": double.tryParse(mspController.text) ?? 0,
                    "qty": int.tryParse(qtyController.text) ?? 0,
                    "category": selectedCategory,
                  };

                  if (isAdding) {
                    await _addProductToAPI(newProduct);
                  } else {
                    await _updateProductToAPI(product["id"].toString(), newProduct);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                child: Text(isAdding ? "Add Product" : "Save Changes"),
              ),
            ),
          ],
        ),
      ),
    );
  }
  String _mapToBroadCategory(String productCategory) {
    final broadCategories = ["Clothing", "Stationary", "Home & Grocery", "Books", "Electronics", "Others"];
    final cat = productCategory.toLowerCase().trim();
    if (["kurthi", "lehengas", "suits", "sweaters", "socks", "jeans", "shrugs", "mens tee", "tops", "trousers", "nightpants", "sports wear", "nightwear", "patyala"].contains(cat)) {
      return "Clothing";
    }
    if (["files", "a4 papers", "tapes", "calculators", "pens", "stapler", "double punch", "gum bottle", "plastic scale", "notebooks", "registers", "stamps", "envelops", "highlighters", "pencils", "notepads", "diaries", "scissors", "rulers", "arts"].contains(cat)) {
      return "Stationary";
    }
    if (["novels", "history books", "law books", "mythology", "story books", "upsc", "gate", "barc", "jee", "neet", "ntse", "olympiad", "government text books", "reasoning", "engeneering mathematics", "computer architecture", "python", "c", "java", "dbms"].contains(cat)) {
      return "Books";
    }
    if (["washing machine", "ac", "camera", "audio supplies", "video supplies", "fridge", "routers", "setup boxes", "inverters", "generators", "hair supplies", "electric kettle", "sewing machine", "gaming supplies", "cables", "mobile appliances", "geysers", "heaters", "sensors"].contains(cat)) {
      return "Electronics";
    }
    if (["spice and condiments", "beverages", "dishwashers", "soaps", "ditergents", "decerative accessories", "skincare", "haircare", "toys", "groceries", "staple foods", "snacks", "diary products", "hygine products", "accessories", "petcare products", "kitchen ware", "households", "umbrella", "gardening supplies"].contains(cat)) {
      return "Home & Grocery";
    }
    if (broadCategories.contains(productCategory)) {
      return productCategory;
    }
    return "Others";
  }
  Future<void> _addProductToAPI(Map<String, dynamic> product) async {
    final String apiUrl = "http://localhost:8000/inventory/${widget.storeId}/products";
    try {
      final response = await http.post(Uri.parse(apiUrl),
          headers: {"Content-Type": "application/json"}, body: jsonEncode(product));
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Product added successfully")));
        _fetchProducts();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Failed: ${response.statusCode}")));
      }
    } catch (e) {
      if (kDebugMode) print("Error: $e");
    }
  }

  Future<void> _updateProductToAPI(String productId, Map<String, dynamic> updated) async {
    final String apiUrl = "http://localhost:8000/inventory/${widget.storeId}/$productId";
    try {
      // FIX: Changed http.put to http.patch to match the FastAPI route
      final response = await http.patch(Uri.parse(apiUrl),
          headers: {"Content-Type": "application/json"}, body: jsonEncode(updated));
          
      if (response.statusCode == 200) {
        // Assuming a 200 status code means success (FastAPI @router.patch returns 200)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Updated successfully")));
        _fetchProducts();
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("❌ Failed: ${response.statusCode}")));
        // Log the full error response for debugging if needed
        if (kDebugMode) print("Update failed response body: ${response.body}"); 
      }
    } catch (e) {
      if (kDebugMode) print("Error updating: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ Network Error during update")));
    }
  }

  Future<void> _uploadCSV() async {
    if (widget.storeId.isEmpty) return;
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv']);
    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      final uri = Uri.parse("http://localhost:8000/inventory/${widget.storeId}/upload_csv");
      var request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      var response = await request.send();
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ CSV Uploaded")));
        _fetchProducts();
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("❌ Upload failed: ${response.statusCode}")));
      }
    }
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(controller: controller, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder())),
    );
  }
}