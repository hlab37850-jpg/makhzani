import 'package:flutter/material.dart';
import '../database/customer_repository.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  final CustomerRepository _repository = CustomerRepository();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _customers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _searchController.addListener(_search);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_search)
      ..dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() => _loading = true);

    final customers = await _repository.getAll();

    if (!mounted) return;

    setState(() {
      _customers = customers;
      _loading = false;
    });
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();

    final customers = query.isEmpty
        ? await _repository.getAll()
        : await _repository.search(query);

    if (!mounted) return;

    setState(() => _customers = customers);
  }

  Future<void> _showCustomerForm([
    Map<String, dynamic>? customer,
  ]) async {
    final nameController = TextEditingController(
      text: customer?['name']?.toString() ?? '',
    );
    final phoneController = TextEditingController(
      text: customer?['phone']?.toString() ?? '',
    );
    final addressController = TextEditingController(
      text: customer?['address']?.toString() ?? '',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            customer == null ? 'إضافة عميل' : 'تعديل العميل',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم العميل',
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

                if (name.isEmpty) {
                  return;
                }

                if (customer == null) {
                  await _repository.insert(
                    name: name,
                    phone: phoneController.text.trim(),
                    address: addressController.text.trim(),
                  );
                } else {
                  await _repository.update(
                    id: customer['id'] as int,
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
      await _loadCustomers();
    }
  }

  Future<void> _showPayment(
    Map<String, dynamic> customer,
  ) async {
    final balance =
        (customer['balance'] as num?)?.toDouble() ?? 0;

    if (balance <= 0) {
      _message('لا يوجد دين على هذا العميل');
      return;
    }

    final amountController = TextEditingController();
    final noteController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('سداد دين: ${customer['name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'الدين الحالي: ${balance.toStringAsFixed(2)} ر.ي',
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
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'ملاحظة',
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
                final amount =
                    double.tryParse(amountController.text.trim());

                if (amount == null || amount <= 0) {
                  return;
                }

                if (amount > balance) {
                  return;
                }

                try {
                  await _repository.addPayment(
                    customerId: customer['id'] as int,
                    amount: amount,
                    note: noteController.text.trim(),
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
    noteController.dispose();

    if (result == true) {
      await _loadCustomers();
      _message('تم تسجيل السداد بنجاح');
    }
  }

  Future<void> _deleteCustomer(
    Map<String, dynamic> customer,
  ) async {
    final balance =
        (customer['balance'] as num?)?.toDouble() ?? 0;

    if (balance > 0) {
      _message('لا يمكن حذف عميل عليه دين');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف العميل'),
        content: Text(
          'هل تريد حذف «${customer['name']}»؟',
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

    await _repository.delete(customer['id'] as int);
    await _loadCustomers();
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
    final totalDebt = _customers.fold<double>(
      0,
      (sum, customer) =>
          sum +
          ((customer['balance'] as num?)?.toDouble() ?? 0),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'العملاء والديون',
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
                    leading: CircleAvatar(
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                      ),
                    ),
                    title: const Text('إجمالي الديون'),
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
                    hintText: 'ابحث باسم العميل أو الهاتف...',
                    prefixIcon:
                        const Icon(Icons.search_rounded),
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
                : _customers.isEmpty
                    ? const Center(
                        child: Text('لا يوجد عملاء حتى الآن'),
                      )
                    : ListView.builder(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        itemCount: _customers.length,
                        itemBuilder: (context, index) {
                          final customer =
                              _customers[index];

                          final balance =
                              (customer['balance'] as num?)
                                      ?.toDouble() ??
                                  0;

                          return Card(
                            margin:
                                const EdgeInsets.only(
                              bottom: 10,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                child: const Icon(
                                  Icons.person_rounded,
                                ),
                              ),
                              title: Text(
                                customer['name']
                                    .toString(),
                                style: const TextStyle(
                                  fontWeight:
                                      FontWeight.w800,
                                ),
                              ),
                              subtitle: Text(
                                balance > 0
                                    ? 'الدين: ${balance.toStringAsFixed(2)} ر.ي'
                                    : 'لا يوجد دين',
                              ),
                              trailing:
                                  PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showCustomerForm(
                                      customer,
                                    );
                                  } else if (value ==
                                      'payment') {
                                    _showPayment(
                                      customer,
                                    );
                                  } else if (value ==
                                      'delete') {
                                    _deleteCustomer(
                                      customer,
                                    );
                                  }
                                },
                                itemBuilder:
                                    (context) => const [
                                  PopupMenuItem(
                                    value: 'payment',
                                    child: Text(
                                      'تسجيل سداد',
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
        onPressed: _showCustomerForm,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('عميل جديد'),
      ),
    );
  }
}
