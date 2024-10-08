import 'package:flutter/material.dart';
import 'package:objectbox/objectbox.dart';
import 'Product.dart'; // Import your Product entity
import 'objectbox.g.dart'; // Import the generated code
import 'dart:io';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Delete the database files (useful in development)
  await deleteDatabase();

  // Initialize the ObjectBox store
  final store = await openStore();
  runApp(MyApp(store: store));
}

// Function to delete the database files
Future<void> deleteDatabase() async {
  final dir = await getApplicationDocumentsDirectory();
  final objectBoxDir = Directory('${dir.path}/objectbox');
  if (await objectBoxDir.exists()) {
    await objectBoxDir.delete(recursive: true);
    print("Database deleted successfully");
  } else {
    print("Database directory not found");
  }
}

class MyApp extends StatelessWidget {
  final Store store;

  const MyApp({Key? key, required this.store}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ObjectBox Product Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ProductListScreen(store: store),
    );
  }
}

class ProductListScreen extends StatefulWidget {
  final Store store;

  const ProductListScreen({Key? key, required this.store}) : super(key: key);

  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  late final Box<Product> productBox;
  late List<Product> products;

  @override
  void initState() {
    super.initState();
    productBox = widget.store.box<Product>();
    _refreshProducts();
  }

  void _refreshProducts() {
    setState(() {
      products = productBox.getAll();
    });
  }

  void _addProduct(String name, double price) {
    final product = Product(name: name, price: price);
    productBox.put(product);
    _refreshProducts();
  }

  void _updateProduct(Product product, String newName, double newPrice) {
    product.name = newName;
    product.price = newPrice;
    productBox.put(product);
    _refreshProducts();
  }

  void _deleteProduct(int id) {
    productBox.remove(id);
    _refreshProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product List'),
      ),
      body: ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return ListTile(
            title: Text('${product.name} - \$${product.price}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showUpdateProductDialog(product),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteProduct(product.id),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProductDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddProductDialog() {
    final TextEditingController _nameController = TextEditingController();
    final TextEditingController _priceController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Product'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: 'Enter product name'),
            ),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(hintText: 'Enter product price'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              final String name = _nameController.text;
              final String priceText = _priceController.text;

              if (name.isNotEmpty && priceText.isNotEmpty) {
                try {
                  final double price = double.parse(priceText);
                  _addProduct(name, price); // Only add product if parsing succeeds
                  Navigator.of(context).pop();
                } catch (e) {
                  // Show an error if parsing fails
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid price')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill in all fields')),
                );
              }
            },
            child: const Text('Add'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }


  void _showUpdateProductDialog(Product product) {
    final TextEditingController _nameController = TextEditingController(text: product.name);
    final TextEditingController _priceController = TextEditingController(text: product.price.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Product'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: 'Enter new product name'),
            ),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(hintText: 'Enter new product price'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (_nameController.text.isNotEmpty && _priceController.text.isNotEmpty) {
                _updateProduct(product, _nameController.text, double.parse(_priceController.text));
              }
              Navigator.of(context).pop();
            },
            child: const Text('Update'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
