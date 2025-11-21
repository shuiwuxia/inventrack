// File: inventory.dart

// ignore_for_file: unused_import, use_build_context_synchronously

import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
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
    final String apiUrl = "https://inventrack-backend-1.onrender.com/inventory/${widget.storeId}/products";

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
      // FIX: Check for "name" (the key we fixed in the backend)
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
                      // ... (existing filter/search Row)
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
                                                
                                                // 🌟 ADDED: Sub-Category Badge
                                                if (product["subcategory"] != null && product["subcategory"].isNotEmpty)
                                                  Padding(
                                                    padding: const EdgeInsets.only(top: 4.0),
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: Colors.deepPurple.shade100,
                                                        borderRadius: BorderRadius.circular(8),
                                                        border: Border.all(color: Colors.deepPurple.shade200),
                                                      ),
                                                      child: Text(
                                                        product["subcategory"],
                                                        style: const TextStyle(fontSize: 12, color: Colors.deepPurple),
                                                      ),
                                                    ),
                                                  ),
                                                // 🌟 END ADDED
                                                
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
          // FIX: Use "qty" key as fixed in the backend
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
    // FIX: Using base keys like 'name' and 'qty' from the frontend view, but the payload will be mapped later
    final nameController = TextEditingController(text: product["name"] ?? ""); 
    final mrpController = TextEditingController(text: product["mrp"]?.toString() ?? "");
    final mspController = TextEditingController(text: product["msp"]?.toString() ?? "");
    final qtyController = TextEditingController(text: product["qty"]?.toString() ?? ""); 
    final subcategoryController = TextEditingController(text: product["subcategory"] ?? "");
    String selectedCategory = product["category"] ?? categories.first;

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade300))),
        padding: const EdgeInsets.all(16),
        height: 420, 
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
                  _buildTextField("Sub-Category", subcategoryController),
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
                  // --- START FIX: Adjust payload keys to match FastAPI schemas ---
                  
                  // Base payload using keys expected by ProductUpdate schema (used by PATCH)
                  final basePayload = {
                    "product_name": nameController.text.trim(),   // Fix for all
                    "mrp": double.tryParse(mrpController.text) ?? 0,
                    "msp": double.tryParse(mspController.text) ?? 0,
                    "stock_quantity": int.tryParse(qtyController.text) ?? 0, // Fix for all
                    "category": selectedCategory,
                    "subcategory": subcategoryController.text.trim(), // Key used by ProductUpdate
                  };

                  if (kDebugMode) {
                    print("Sending payload: ${jsonEncode(basePayload)}");
                  }
                  
                  if (isAdding) {
                    // FIX for POST: ProductCreate schema expects 'subcategory' (snake_case)
                    final createPayload = Map<String, dynamic>.from(basePayload);
                    final subcategoryValue = createPayload.remove('subcategory');
                    createPayload['subcategory'] = subcategoryValue; // Map to snake_case
                    
                    await _addProductToAPI(createPayload);
                    
                  } else {
                    // FIX for PATCH: The basePayload is already correct for ProductUpdate
                    await _updateProductToAPI(product["id"].toString(), basePayload);
                  }
                  // --- END FIX ---

                  setState(() {
                    addingNew = false;
                    editingIndex = null;
                  });
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

  // FIX: This function now receives the corrected payload from _editPanel
  Future<void> _addProductToAPI(Map<String, dynamic> product) async {
    final String apiUrl = "https://inventrack-backend-1.onrender.com/products/${widget.storeId}/"; // NOTE: Should use /products/{store_id}/
    
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

  // FIX: This function now uses the correct method and URL
  Future<void> _updateProductToAPI(String productId, Map<String, dynamic> updated) async {
    // FIX 1: Correct the API URL to include productId
    final String apiUrl = "https://inventrack-backend-1.onrender.com/inventory/${widget.storeId}/$productId"; 
    
    try {
      // FIX 2: Change from http.put to http.patch to match the FastAPI router
      final response = await http.patch(Uri.parse(apiUrl), // CHANGED: put -> patch
          headers: {"Content-Type": "application/json"}, body: jsonEncode(updated));
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Updated successfully")));
        _fetchProducts();
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("❌ Failed: ${response.statusCode}")));
      }
    } catch (e) {
      if (kDebugMode) print("Error updating: $e");
    }
  }

  Future<void> _uploadCSV() async {
    if (widget.storeId.isEmpty) return;
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv']);
    
    // Check if a file was picked
    if (result != null) {
      final PlatformFile platformFile = result.files.single;
      
      final uri = Uri.parse("https://inventrack-backend-1.onrender.com/inventory/${widget.storeId}/upload_csv");
      
      var request = http.MultipartRequest('POST', uri);
      
      try {
        http.MultipartFile multipartFile;
        
        // FIX: Use conditional logic to handle web (kIsWeb) vs mobile/desktop
        if (kIsWeb) {
          // WEB: Use fromBytes and the bytes property
          if (platformFile.bytes == null) {
            throw Exception("File data is null, cannot upload.");
          }
          multipartFile = http.MultipartFile.fromBytes(
            'file', 
            platformFile.bytes!, 
            filename: platformFile.name,
          );
        } else {
          // MOBILE/DESKTOP: Use fromPath and the path property
          if (platformFile.path == null) {
             throw Exception("File path is null, cannot upload.");
          }
          // The original code was: File file = File(result.files.single.path!);
          multipartFile = await http.MultipartFile.fromPath(
            'file', 
            // We still need the dart:io.File path for fromPath, though path is available on platformFile
            File(platformFile.path!).path, 
            filename: platformFile.name,
          );
        }
        
        request.files.add(multipartFile);
        var response = await request.send();
        
        // Ensure response is fully read to avoid issues, especially on upload
        final responseBody = await response.stream.bytesToString();
        if (kDebugMode) print("Upload Response: ${response.statusCode} - $responseBody");

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ CSV Uploaded")));
          _fetchProducts();
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("❌ Upload failed: ${response.statusCode}")));
        }
      } catch (e) {
        if (kDebugMode) print("Upload Error: $e");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Upload error: ${e.toString()}")));
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