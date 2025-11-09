
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'product_model.dart'; 

class InventoryService {
  // CRITICAL: Use the correct base URL for your device/emulator!
  // Android Emulator: 10.0.2.2 | iOS Simulator/Device: localhost or IP
  final String baseUrl = 'http://10.0.2.2:8000'; 
  final String productsEndpoint = '/inventory/products';

  Future<List<Product>> fetchAllProducts() async {
    final url = Uri.parse('$baseUrl$productsEndpoint');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      // Decode the entire JSON body, assuming FastAPI returns {"data": [...]}
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      final List productsJson = jsonResponse['data'] as List;

      return productsJson.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load products: Status ${response.statusCode}');
    }
  }

  // NOTE: You would add other methods here (e.g., login, inventory updates, etc.)
  
}