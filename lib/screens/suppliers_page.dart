import 'package:flutter/material.dart';
import '../database/supplier_repository.dart';

class SuppliersPage extends StatefulWidget {
  const SuppliersPage({super.key});

  @override
  State<SuppliersPage> createState() => _SuppliersPageState();
}

class _SuppliersPageState extends State<SuppliersPage> {
  final SupplierRepository _repository = SupplierRepository();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _suppliers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
    _searchController.addListener(_search);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_search)
      ..dispose();
    super.dispose();
  }

  Future<void> _loadSuppliers() async {
    setState(() => _loading = true);

    final suppliers = await _repository.getAll();

    if (!mounted) return;

    setState(() {
      _suppliers = suppliers;
      _loading = false;
    });
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();

    final suppliers = query.isEmpty
        ? await _repository.getAll()
        : await _repository.search(query);

    if (!mounted) return;

    setState(() => _suppliers = suppliers);
  }

  Future<void> _showSupplierForm([
    Map<String, dynamic>? supplier,
  ]) async {
    final nameController = TextEditingController(
      text: supplier?['name']?.toString() ?? '',
    );

    final phoneController = TextEditingController(
      text: supplier?['phone']?.toString() ?? '',
    );

    final addressController = TextEditingController(
      text: supplier?['address']?.toString() ?? '',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            supplier == null ? 'إضافة مورد' : 'تعديل المورد',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم المورد',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'رقم الهاتف',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'العنوان',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();

                if (name.isEmpty) return;

                if (supplier == null) {
                  await _repository.insert(
                    name: name,
                    phone: phoneController.text.trim(),
                    address: addressController.text.trim(),
                  );
                } else {
                  await _repository.update(
                    id: supplier['id'] as int,
                    name: name,
                    phone: phoneController.text.trim(),
                    address: addressController.text.trim(),
                  );
                }

                if (context.mounted) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();

    if (result == true) {
      await _loadSuppliers();
    }
  }

  Future<void> _showPayment(
    Map<String, dynamic> supplier,
  ) async {
    final balance =
        (supplier['balance'] as num?)?.toDouble() ?? 0;

    if (balance <= 0) {
      _message('لا يوجد مستحقات على هذا المورد');
      return;
    }

    final amountController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'سداد للمورد: ${supplier['name']}',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'المستحق الحالي: '
                '${balance.toStringAsFixed(2)} ر.ي',
              ),
              const SizedBox(height: 15),
              TextField(
                controller: amountController,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'مبلغ السداد',
                  suffixText: 'ر.ي',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () async {
                final amount = double.tryParse(
                  amountController.text.trim(),
                );

                if (amount == null ||
                    amount <= 0 ||
                    amount > balance) {
                  return;
                }

                try {
                  await _repository.addPayment(
                    supplierId: supplier['id'] as int,
                    amount: amount,
                  );

                  if (context.mounted) {
                    Navigator.pop(context, true);
                  }
                } catch (_) {
                  if (context.mounted) {
                    _message('تعذر تسجيل السداد');
                  }
                }
              },
              child: const Text('تسجيل السداد'),
            ),
          ],
        );
      },
    );

    amountController.dispose();

    if (result == true) {
      await _loadSuppliers();
      _message('تم تسجيل السداد بنجاح');
    }
  }

  Future<void> _deleteSupplier(
    Map<String, dynamic> supplier,
  ) async {
    final balance =
        (supplier['balance'] as num?)?.toDouble() ?? 0;

    if (balance > 0) {
      _message('لا يمكن حذف مورد عليه مستحقات');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المورد'),
        content: Text(
          'هل تريد حذف «${supplier['name']}»؟',
        ),
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

    try {
      await _repository.delete(supplier['id'] as int);
      await _loadSuppliers();
    } catch (e) {
      _message(
        e.toString().contains('عمليات شراء')
            ? 'لا يمكن حذف مورد لديه عمليات شراء مسجلة'
            : 'تعذر حذف المورد',
      );
    }
  }

  void _message(String message) {
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
    final totalDebt = _suppliers.fold<double>(
      0,
      (sum, supplier) =>
          sum +
          ((supplier['balance'] as num?)?.toDouble() ?? 0),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'الموردون',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Card(
                  elevation: 0,
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(
                        Icons.local_shipping_rounded,
                      ),
                    ),
                    title: const Text('إجمالي المستحقات'),
                    subtitle: Text(
                      '${totalDebt.toStringAsFixed(2)} ر.ي',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'ابحث باسم المورد أو الهاتف...',
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                    ),
                    suffixIcon:
                        _searchController.text.isEmpty
                            ? null
                            : IconButton(
                                onPressed:
                                    _searchController.clear,
                                icon: const Icon(
                                  Icons.clear_rounded,
                                ),
                              ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _suppliers.isEmpty
                    ? const Center(
                        child: Text(
                          'لا يوجد موردون حتى الآن',
                        ),
                      )
                    : ListView.builder(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        itemCount: _suppliers.length,
                        itemBuilder: (context, index) {
                          final supplier =
                              _suppliers[index];

                          final balance =
                              (supplier['balance'] as num?)
                                      ?.toDouble() ??
                                  0;

                          return Card(
                            margin:
                                const EdgeInsets.only(
                              bottom: 10,
                            ),
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(
                                  Icons.local_shipping_rounded,
                                ),
                              ),
                              title: Text(
                                supplier['name'].toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              subtitle: Text(
                                balance > 0
                                    ? 'المستحق: '
                                      '${balance.toStringAsFixed(2)} ر.ي'
                                    : 'لا توجد مستحقات',
                              ),
                              trailing:
                                  PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'payment') {
                                    _showPayment(supplier);
                                  } else if (value == 'edit') {
                                    _showSupplierForm(
                                      supplier,
                                    );
                                  } else if (value == 'delete') {
                                    _deleteSupplier(
                                      supplier,
                                    );
                                  }
                                },
                                itemBuilder: (context) =>
                                    const [
                                  PopupMenuItem(
                                    value: 'payment',
                                    child: Text(
                                      'سداد',
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text(
                                      'تعديل',
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text(
                                      'حذف',
                                    ),
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
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: _showSupplierForm,
        icon: const Icon(
          Icons.person_add_rounded,
        ),
        label: const Text('مورد جديد'),
      ),
    );
  }
}
