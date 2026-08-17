import 'package:flutter/material.dart';
import '../database/product_repository.dart';
import '../database/sales_repository.dart';
import '../models/product.dart';

class SalesPage extends StatefulWidget {
  const SalesPage({super.key});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SaleLine {
  final Product product;
  double quantity;

  _SaleLine({
    required this.product,
    required this.quantity,
  });

  double get total => quantity * product.salePrice;
  double get profit =>
      quantity * (product.salePrice - product.purchasePrice);
}

class _SalesPageState extends State<SalesPage> {
  final ProductRepository _productsRepo = ProductRepository();
  final SalesRepository _salesRepo = SalesRepository();

  List<Product> _products = [];
  final List<_SaleLine> _cart = [];

  bool _loading = true;
  bool _saving = false;
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
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _loading = true);

    final products = await _productsRepo.getAll();

    if (!mounted) return;

    setState(() {
      _products = products.where((p) => p.quantity > 0).toList();
      _loading = false;
    });
  }

  void _addProduct(Product product) {
    final existingIndex =
        _cart.indexWhere((line) => line.product.id == product.id);

    if (existingIndex >= 0) {
      final line = _cart[existingIndex];

      if (line.quantity + 1 > product.quantity) {
        _showMessage('الكمية المطلوبة أكبر من المخزون');
        return;
      }

      setState(() => line.quantity++);
      return;
    }

    setState(() {
      _cart.add(_SaleLine(product: product, quantity: 1));
    });
  }

  void _changeQuantity(int index, double delta) {
    final line = _cart[index];
    final next = line.quantity + delta;

    if (next <= 0) {
      setState(() => _cart.removeAt(index));
      return;
    }

    if (next > line.product.quantity) {
      _showMessage('لا يمكن تجاوز المخزون المتاح');
      return;
    }

    setState(() => line.quantity = next);
  }

  Future<void> _completeSale() async {
    if (_cart.isEmpty) {
      _showMessage('أضف منتجًا واحدًا على الأقل');
      return;
    }

    if (_paid < 0) {
      _showMessage('المبلغ المدفوع غير صحيح');
      return;
    }

    if (_paid > total) {
      _showMessage('المبلغ المدفوع أكبر من إجمالي الفاتورة');
      return;
    }

    setState(() => _saving = true);

    try {
      await _salesRepo.createSale(
        items: _cart.map((line) {
          return {
            'productId': line.product.id!,
            'quantity': line.quantity,
            'salePrice': line.product.salePrice,
            'purchasePrice': line.product.purchasePrice,
          };
        }).toList(),
        paid: _paid,
      );

      if (!mounted) return;

      setState(() {
        _cart.clear();
        _paid = 0;
      });

      await _loadProducts();

      if (!mounted) return;

      _showMessage('تم تسجيل البيع بنجاح');
    } catch (e) {
      if (!mounted) return;
      _showMessage('تعذر تسجيل البيع: $e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
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
                        return product.name.toLowerCase().contains(query) ||
                            product.barcode.toLowerCase().contains(query);
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
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
                        controller: searchController,
                        onChanged: search,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'ابحث بالاسم أو الباركود',
                          prefixIcon: const Icon(Icons.search_rounded),
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(
                              child: Text('لا توجد منتجات متاحة'),
                            )
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final product = filtered[index];

                                return ListTile(
                                  leading: CircleAvatar(
                                    child: const Icon(
                                      Icons.inventory_2_rounded,
                                    ),
                                  ),
                                  title: Text(
                                    product.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'المخزون: ${product.quantity} • '
                                    'السعر: ${product.salePrice.toStringAsFixed(2)}',
                                  ),
                                  trailing:
                                      const Icon(Icons.add_circle_rounded),
                                  onTap: () {
                                    Navigator.pop(context, product);
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
            keyboardType: const TextInputType.numberWithOptions(
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
                  double.tryParse(controller.text.trim()) ?? 0,
                );
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (value != null) {
      setState(() => _paid = value);
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'المبيعات',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _cart.isEmpty
                      ? _EmptySale(onAdd: _showProductPicker)
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            _SaleHeader(
                              count: _cart.length,
                              onAdd: _showProductPicker,
                            ),
                            const SizedBox(height: 12),
                            ...List.generate(
                              _cart.length,
                              (index) {
                                final line = _cart[index];

                                return Card(
                                  margin:
                                      const EdgeInsets.only(bottom: 10),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          child: const Icon(
                                            Icons.inventory_2_rounded,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                line.product.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${line.product.salePrice.toStringAsFixed(2)} ر.ي',
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () =>
                                              _changeQuantity(index, -1),
                                          icon: const Icon(
                                            Icons.remove_circle_outline,
                                          ),
                                        ),
                                        Text(
                                          line.quantity
                                              .toStringAsFixed(0),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () =>
                                              _changeQuantity(index, 1),
                                          icon: const Icon(
                                            Icons.add_circle_outline,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                ),
                _SaleSummary(
                  total: total,
                  paid: _paid,
                  debt: debt,
                  saving: _saving,
                  onPaid: _editPaid,
                  onComplete: _completeSale,
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

class _EmptySale extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptySale({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.point_of_sale_rounded,
              size: 76,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 18),
            const Text(
              'فاتورة جديدة',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'أضف المنتجات التي تريد بيعها ثم أكمل العملية.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
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

class _SaleHeader extends StatelessWidget {
  final int count;
  final VoidCallback onAdd;

  const _SaleHeader({
    required this.count,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'المنتجات في الفاتورة: $count',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add_rounded),
          label: const Text('إضافة'),
        ),
      ],
    );
  }
}

class _SaleSummary extends StatelessWidget {
  final double total;
  final double paid;
  final double debt;
  final bool saving;
  final VoidCallback onPaid;
  final VoidCallback onComplete;

  const _SaleSummary({
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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            children: [
              _row('الإجمالي', total),
              const SizedBox(height: 6),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onPaid,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: _row(
                    'المدفوع',
                    paid,
                    trailing: const Icon(Icons.edit_rounded, size: 18),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              _row(
                'المتبقي / الدين',
                debt,
                bold: true,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: saving ? null : onComplete,
                  icon: saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.check_circle_rounded),
                  label: Text(
                    saving ? 'جارٍ الحفظ...' : 'إتمام البيع',
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
              fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
        ),
        Text(
          '${value.toStringAsFixed(2)} ر.ي',
          style: TextStyle(
            fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
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
