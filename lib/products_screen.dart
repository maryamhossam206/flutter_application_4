import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'theme_cubit.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<dynamic> _products = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    final url = Uri.parse('https://accessories-eshop.runasp.net/api/products');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);

        setState(() {
          // التحقق مما إذا كان الـ JSON القادم List أم Map
          if (decodedData is List) {
            _products = decodedData;
          } else if (decodedData is Map<String, dynamic>) {
            // البحث عن القائمة داخل مفاتيح JSON الشهيرة
            _products = decodedData['products'] ??
                decodedData['data'] ??
                decodedData['items'] ??
                [];
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load products (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, bool>(
      builder: (context, isDark) {
        final textColor = isDark ? Colors.white : Colors.black;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Products'),
            backgroundColor: isDark ? Colors.black : Colors.white,
            foregroundColor: textColor,
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: textColor),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _products.length,
                      itemBuilder: (context, index) {
                        final product = _products[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: product['pictureUrl'] != null || product['imageUrl'] != null
                                ? Image.network(
                                    product['pictureUrl'] ?? product['imageUrl'],
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.shopping_bag),
                                  )
                                : const Icon(Icons.shopping_bag),
                            title: Text(
                              product['name'] ?? product['title'] ?? 'Product ${index + 1}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              product['description'] ?? 'No description',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Text(
                              '\$${product['price'] ?? 0}',
                              style: const TextStyle(
                                color: Color(0xFF4FA0FF),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        );
      },
    );
  }
}