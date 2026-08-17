import 'package:flutter/material.dart';
import '../database/report_repository.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final ReportRepository _repository = ReportRepository();

  bool _loading = true;
  Map<String, double> _summary = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    try {
      final summary = await _repository.summary();

      if (!mounted) return;

      setState(() {
        _summary = summary;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر تحميل التقارير: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  double value(String key) => _summary[key] ?? 0;

  String money(double amount) {
    return '${amount.toStringAsFixed(2)} ر.ي';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'التقارير',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'ملخص النظام',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 14),

                  _ReportCard(
                    icon: Icons.point_of_sale_rounded,
                    title: 'إجمالي المبيعات',
                    value: money(
                      value('sales'),
                    ),
                  ),

                  _ReportCard(
                    icon: Icons.trending_up_rounded,
                    title: 'إجمالي الأرباح',
                    value: money(
                      value('profit'),
                    ),
                  ),

                  _ReportCard(
                    icon: Icons.shopping_cart_rounded,
                    title: 'إجمالي المشتريات',
                    value: money(
                      value('purchases'),
                    ),
                  ),

                  _ReportCard(
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'ديون العملاء الحالية',
                    value: money(
                      value('customerDebt'),
                    ),
                  ),

                  _ReportCard(
                    icon: Icons.local_shipping_rounded,
                    title: 'مستحقات الموردين',
                    value: money(
                      value('supplierDebt'),
                    ),
                  ),

                  _ReportCard(
                    icon: Icons.inventory_2_rounded,
                    title: 'قيمة المخزون',
                    value: money(
                      value('stockValue'),
                    ),
                  ),

                  _ReportCard(
                    icon: Icons.warning_amber_rounded,
                    title: 'منتجات منخفضة المخزون',
                    value: value('lowStock')
                        .toInt()
                        .toString(),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _ReportCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(icon),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        trailing: Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
