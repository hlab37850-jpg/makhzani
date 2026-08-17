import 'package:flutter/material.dart';

import '../database/product_repository.dart';
import '../models/product.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final ProductRepository _repository = ProductRepository();
  final TextEditingController _searchController = TextEditingController();

  List<Product> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchController.addListener(_searchProducts);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_searchProducts)
      ..dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _loading = true);

    final products = await _repository.getAll();

    if (!mounted) return;

    setState(() {
      _products = products;
      _loading = false;
    });
  }

  Future<void> _searchProducts() async {
    final query = _searchController.text.trim();

    final products = query.isEmpty
        ? await _repository.getAll()
        : await _repository.search(query);

    if (!mounted) return;

    setState(() => _products = products);
  }

  Future<void> _showProductForm([Product? product]) async {
    final nameController =
        TextEditingController(text: product?.name ?? '');
    final barcodeController =
        TextEditingController(text: product?.barcode ?? '');
    final purchaseController = TextEditingController(
      text: product?.purchasePrice.toString() ?? '',
    );
    final saleController = TextEditingController(
      text: product?.salePrice.toString() ?? '',
    );
    final quantityController = TextEditingController(
      text: product?.quantity.toString() ?? '0',
    );
    final minQuantityController = TextEditingController(
      text: product?.minQuantity.toString() ?? '5',
    );

    final result = await showDialog<Product>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(product == null ? 'إضافة منتج' : 'تعديل المنتج'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم المنتج',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: barcodeController,
                  decoration: const InputDecoration(
                    labelText: 'الباركود',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: purchaseController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'سعر الشراء',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: saleController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'سعر البيع',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'الكمية',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: minQuantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'حد التنبيه',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();

                if (name.isEmpty) return;

                Navigator.pop(
                  context,
                    Product(
                      id: product?.id,
                      name: name,
                      barcode: barcodeController.text.trim(),
                      purchasePrice:
                          double.tryParse(purchaseController.text) ?? 0.0,
                      salePrice:
                          double.tryParse(saleController.text) ?? 0.0,
                      quantity:
                          double.tryParse(quantityController.text) ?? 0.0,
                      minQuantity:
                          double.tryParse(minQuantityController.text) ?? 5.0,
                      createdAt:
                          product?.createdAt ??
                          DateTime.now().toIso8601String(),
                    ),
                );
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    barcodeController.dispose();
    purchaseController.dispose();
    saleController.dispose();
    quantityController.dispose();
    minQuantityController.dispose();

    if (result == null) return;

    if (result.id == null) {
      await _repository.insert(result);
    } else {
      await _repository.update(result);
    }

    await _loadProducts();
  }

  Future<void> _deleteProduct(Product product) async {
    if (product.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المنتج'),
        content: Text('هل تريد حذف «${product.name}»؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _repository.delete(product.id!);
    await _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'المنتجات',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ابحث عن منتج أو باركود...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: _searchController.clear,
                        icon: const Icon(Icons.clear),
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                    ? const Center(
                        child: Text('لا توجد منتجات حتى الآن'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          final lowStock =
                              product.quantity <= product.minQuantity;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Icon(
                                  lowStock
                                      ? Icons.warning_amber
                                      : Icons.inventory_2,
                                ),
                              ),
                              title: Text(
                                product.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'الكمية: ${product.quantity}  •  '
                                'البيع: ${product.salePrice}',
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showProductForm(product);
                                  } else if (value == 'delete') {
                                    _deleteProduct(product);
                                  }
                                },
                                itemBuilder: (context) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text('تعديل'),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('حذف'),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showProductForm,
        icon: const Icon(Icons.add),
        label: const Text('إضافة منتج'),
      ),
    );
  }
}
