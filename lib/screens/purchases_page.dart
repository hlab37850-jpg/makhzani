import 'package:flutter/material.dart';

import '../database/product_repository.dart';
import '../database/purchase_repository.dart';
import '../database/supplier_repository.dart';
import '../models/product.dart';

class PurchasesPage extends StatefulWidget {
  const PurchasesPage({super.key});

  @override
  State<PurchasesPage> createState() => _PurchasesPageState();
}

class _PurchaseLine {
  final Product product;
  double quantity;
  double purchasePrice;

  _PurchaseLine({
    required this.product,
    required this.quantity,
    required this.purchasePrice,
  });

  double get total => quantity * purchasePrice;
}

class _PurchasesPageState extends State<PurchasesPage> {
  final ProductRepository _productsRepo = ProductRepository();
  final SupplierRepository _suppliersRepo = SupplierRepository();
  final PurchaseRepository _purchasesRepo = PurchaseRepository();

  List<Product> _products = [];
  List<Map<String, dynamic>> _suppliers = [];

  final List<_PurchaseLine> _cart = [];

  bool _loading = true;
  bool _saving = false;

  int? _supplierId;
  String? _supplierName;

  double _paid = 0;

  double get total =>
      _cart.fold<double>(0, (sum, item) => sum + item.total);

  double get debt {
    final value = total - _paid;
    return value > 0 ? value : 0;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    final products = await _productsRepo.getAll();
    final suppliers = await _suppliersRepo.getAll();

    if (!mounted) return;

    setState(() {
      _products = products;
      _suppliers = suppliers;
      _loading = false;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _selectSupplier() async {
    if (_suppliers.isEmpty) {
      _showMessage('لا يوجد موردون. أضف موردًا أولًا.');
      return;
    }

    final selected =
        await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'اختيار المورد',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              ..._suppliers.map(
                (supplier) => ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.local_shipping_rounded),
                  ),
                  title: Text(
                    supplier['name'].toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(
                    'المستحق الحالي: '
                    '${((supplier['balance'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)} ر.ي',
                  ),
                  onTap: () {
                    Navigator.pop(context, supplier);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selected == null) return;

    setState(() {
      _supplierId = selected['id'] as int;
      _supplierName = selected['name'].toString();
    });
  }

  Future<void> _showProductPicker() async {
    final searchController = TextEditingController();
    List<Product> filtered = List.of(_products);

    final selected = await showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void search(String value) {
              final query = value.trim().toLowerCase();

              setModalState(() {
                filtered = query.isEmpty
                    ? List.of(_products)
                    : _products.where((product) {
                        return product.name
                                .toLowerCase()
                                .contains(query) ||
                            product.barcode
                                .toLowerCase()
                                .contains(query);
                      }).toList();
              });
            }

            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * .75,
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'اختيار منتج',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                      ),
                      child: TextField(
                        controller: searchController,
                        onChanged: search,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'ابحث بالاسم أو الباركود',
                          prefixIcon:
                              const Icon(Icons.search_rounded),
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(
                              child:
                                  Text('لا توجد منتجات'),
                            )
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final product =
                                    filtered[index];

                                return ListTile(
                                  leading: const CircleAvatar(
                                    child: Icon(
                                      Icons.inventory_2_rounded,
                                    ),
                                  ),
                                  title: Text(
                                    product.name,
                                    style: const TextStyle(
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'سعر الشراء الحالي: '
                                    '${product.purchasePrice.toStringAsFixed(2)} ر.ي',
                                  ),
                                  trailing: const Icon(
                                    Icons.add_circle_rounded,
                                  ),
                                  onTap: () {
                                    Navigator.pop(
                                      context,
                                      product,
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    searchController.dispose();

    if (selected != null) {
      _addProduct(selected);
    }
  }

  void _addProduct(Product product) {
    final existingIndex = _cart.indexWhere(
      (line) => line.product.id == product.id,
    );

    if (existingIndex >= 0) {
      setState(() {
        _cart[existingIndex].quantity++;
      });
      return;
    }

    setState(() {
      _cart.add(
        _PurchaseLine(
          product: product,
          quantity: 1,
          purchasePrice: product.purchasePrice,
        ),
      );
    });
  }

    Future<void> _editLine(int index) async {
    final line = _cart[index];

    final quantityController = TextEditingController(
      text: line.quantity.toStringAsFixed(0),
    );

    final priceController = TextEditingController(
      text: line.purchasePrice.toStringAsFixed(2),
    );

    final result = await showDialog<List<double>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(line.product.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: quantityController,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'الكمية',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'سعر الشراء',
                  suffixText: 'ر.ي',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                final quantity = double.tryParse(
                  quantityController.text.trim(),
                );

                final price = double.tryParse(
                  priceController.text.trim(),
                );

                if (quantity == null ||
                    quantity <= 0 ||
                    price == null ||
                    price < 0) {
                  return;
                }

                Navigator.pop(
                  context,
                  [quantity, price],
                );
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );

    quantityController.dispose();
    priceController.dispose();

    if (result == null) return;

    setState(() {
      line.quantity = result[0];
      line.purchasePrice = result[1];
    });
  }

  Future<void> _editPaid() async {
    final controller = TextEditingController(
      text: _paid == 0 ? '' : _paid.toStringAsFixed(2),
    );

    final value = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('المبلغ المدفوع'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType:
                const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: const InputDecoration(
              labelText: 'المبلغ',
              suffixText: 'ر.ي',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  double.tryParse(
                        controller.text.trim(),
                      ) ??
                      0,
                );
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (value == null) return;

    if (value < 0 || value > total) {
      _showMessage(
        'المبلغ المدفوع يجب ألا يتجاوز إجمالي الفاتورة',
      );
      return;
    }

    setState(() => _paid = value);
  }

  Future<void> _completePurchase() async {
    if (_cart.isEmpty) {
      _showMessage('أضف منتجًا واحدًا على الأقل');
      return;
    }

    if (_supplierId == null) {
      _showMessage('اختر المورد أولًا');
      return;
    }

    if (_paid < 0 || _paid > total) {
      _showMessage('المبلغ المدفوع غير صحيح');
      return;
    }

    setState(() => _saving = true);

    try {
      await _purchasesRepo.createPurchase(
        supplierId: _supplierId,
        items: _cart.map((line) {
          return {
            'productId': line.product.id!,
            'quantity': line.quantity,
            'purchasePrice': line.purchasePrice,
          };
        }).toList(),
        paid: _paid,
      );

      if (!mounted) return;

      setState(() {
        _cart.clear();
        _paid = 0;
        _supplierId = null;
        _supplierName = null;
      });

      await _loadData();

      if (!mounted) return;

      _showMessage('تم تسجيل المشتريات بنجاح');
    } catch (e) {
      if (!mounted) return;
      _showMessage('تعذر تسجيل المشتريات: $e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'المشتريات',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                Expanded(
                  child: _cart.isEmpty
                      ? _EmptyPurchase(
                          supplierName: _supplierName,
                          onSupplier: _selectSupplier,
                          onAdd: _showProductPicker,
                        )
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            _PurchaseHeader(
                              supplierName: _supplierName,
                              onSupplier: _selectSupplier,
                              onAdd: _showProductPicker,
                            ),
                            const SizedBox(height: 12),
                            ...List.generate(
                              _cart.length,
                              (index) {
                                final line = _cart[index];

                                return Card(
                                  margin:
                                      const EdgeInsets.only(
                                    bottom: 10,
                                  ),
                                  child: ListTile(
                                    leading:
                                        const CircleAvatar(
                                      child: Icon(
                                        Icons.inventory_2_rounded,
                                      ),
                                    ),
                                    title: Text(
                                      line.product.name,
                                      style:
                                          const TextStyle(
                                        fontWeight:
                                            FontWeight.w800,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${line.purchasePrice.toStringAsFixed(2)} ر.ي × '
                                      '${line.quantity.toStringAsFixed(0)}'
                                      ' = '
                                      '${line.total.toStringAsFixed(2)} ر.ي',
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(
                                        Icons.edit_rounded,
                                      ),
                                      onPressed: () =>
                                          _editLine(index),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                ),
                _PurchaseSummary(
                  total: total,
                  paid: _paid,
                  debt: debt,
                  saving: _saving,
                  onPaid: _editPaid,
                  onComplete: _completePurchase,
                ),
              ],
            ),
      floatingActionButton: _cart.isNotEmpty
          ? FloatingActionButton(
              onPressed: _showProductPicker,
              child: const Icon(Icons.add_rounded),
            )
          : null,
    );
  }
}

class _EmptyPurchase extends StatelessWidget {
  final String? supplierName;
  final VoidCallback onSupplier;
  final VoidCallback onAdd;

  const _EmptyPurchase({
    required this.supplierName,
    required this.onSupplier,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.shopping_cart_rounded,
              size: 76,
            ),
            const SizedBox(height: 18),
            const Text(
              'فاتورة شراء جديدة',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onSupplier,
              icon: const Icon(
                Icons.local_shipping_rounded,
              ),
              label: Text(
                supplierName ?? 'اختيار المورد',
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('إضافة منتج'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PurchaseHeader extends StatelessWidget {
  final String? supplierName;
  final VoidCallback onSupplier;
  final VoidCallback onAdd;

  const _PurchaseHeader({
    required this.supplierName,
    required this.onSupplier,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onSupplier,
                icon: const Icon(
                  Icons.local_shipping_rounded,
                ),
                label: Text(
                  supplierName ?? 'اختيار المورد',
                ),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('إضافة'),
            ),
          ],
        ),
      ],
    );
  }
}

class _PurchaseSummary extends StatelessWidget {
  final double total;
  final double paid;
  final double debt;
  final bool saving;
  final VoidCallback onPaid;
  final VoidCallback onComplete;

  const _PurchaseSummary({
    required this.total,
    required this.paid,
    required this.debt,
    required this.saving,
    required this.onPaid,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 12,
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding:
              const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            children: [
              _row('الإجمالي', total),
              const SizedBox(height: 6),
              InkWell(
                borderRadius:
                    BorderRadius.circular(12),
                onTap: onPaid,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 8,
                  ),
                  child: _row(
                    'المدفوع',
                    paid,
                    trailing: const Icon(
                      Icons.edit_rounded,
                      size: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              _row(
                'المستحق للمورد',
                debt,
                bold: true,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed:
                      saving ? null : onComplete,
                  icon: saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.check_circle_rounded,
                        ),
                  label: Text(
                    saving
                        ? 'جارٍ الحفظ...'
                        : 'إتمام الشراء',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(
    String title,
    double value, {
    Widget? trailing,
    bool bold = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontWeight: bold
                  ? FontWeight.w900
                  : FontWeight.w600,
            ),
          ),
        ),
        Text(
          '${value.toStringAsFixed(2)} ر.ي',
          style: TextStyle(
            fontWeight: bold
                ? FontWeight.w900
                : FontWeight.w700,
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing,
        ],
      ],
    );
  }
}
