import 'package:flutter/material.dart';

void main() {
  runApp(const MakhzaniApp());
}

class MakhzaniApp extends StatelessWidget {
  const MakhzaniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'مخزني',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'sans',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF176B5B),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F8F7),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF36B89A),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: DashboardPage(),
      ),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int selectedIndex = 0;

  final pages = const [
    _DashboardHome(),
    _PlaceholderPage(
      icon: Icons.inventory_2_rounded,
      title: 'المنتجات',
      subtitle: 'إدارة المنتجات والكميات والأسعار',
    ),
    _PlaceholderPage(
      icon: Icons.point_of_sale_rounded,
      title: 'المبيعات',
      subtitle: 'تسجيل ومتابعة عمليات البيع',
    ),
    _PlaceholderPage(
      icon: Icons.shopping_cart_rounded,
      title: 'المشتريات',
      subtitle: 'إدارة المشتريات والموردين',
    ),
    _PlaceholderPage(
      icon: Icons.people_alt_rounded,
      title: 'العملاء',
      subtitle: 'العملاء والديون والمستحقات',
    ),
    _PlaceholderPage(
      icon: Icons.bar_chart_rounded,
      title: 'التقارير',
      subtitle: 'تقارير المبيعات والأرباح والمخزون',
    ),
  ];

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.storefront_rounded,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مخزني',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                Text(
                  'إدارة متجرك بسهولة',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'بحث',
            onPressed: () {},
            icon: const Icon(Icons.search_rounded),
          ),
          IconButton(
            tooltip: 'التنبيهات',
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _buildDrawer(context),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: pages[selectedIndex],
      ),
      floatingActionButton: selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                setState(() => selectedIndex = 1);
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'إضافة منتج',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    child: Icon(Icons.store_rounded, size: 28),
                  ),
                  SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'متجري',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'نظام مخزني',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            _drawerItem(0, Icons.dashboard_rounded, 'الرئيسية'),
            _drawerItem(1, Icons.inventory_2_rounded, 'المنتجات'),
            _drawerItem(2, Icons.point_of_sale_rounded, 'المبيعات'),
            _drawerItem(3, Icons.shopping_cart_rounded, 'المشتريات'),
            _drawerItem(4, Icons.people_alt_rounded, 'العملاء والديون'),
            _drawerItem(5, Icons.bar_chart_rounded, 'التقارير'),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings_rounded),
              title: const Text('الإعدادات'),
              onTap: () {},
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(int index, IconData icon, String title) {
    final selected = selectedIndex == index;

    return ListTile(
      selected: selected,
      selectedTileColor:
          Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
      leading: Icon(icon),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      onTap: () {
        setState(() => selectedIndex = index);
        Navigator.pop(context);
      },
    );
  }
}

class _DashboardHome extends StatelessWidget {
  const _DashboardHome();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'مرحباً بك 👋',
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'إليك ملخص متجرك اليوم',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),

          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth > 700 ? 4 : 2;

              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.35,
                children: const [
                  _StatCard(
                    icon: Icons.payments_rounded,
                    title: 'مبيعات اليوم',
                    value: '0',
                    suffix: ' ر.س',
                  ),
                  _StatCard(
                    icon: Icons.trending_up_rounded,
                    title: 'أرباح اليوم',
                    value: '0',
                    suffix: ' ر.س',
                  ),
                  _StatCard(
                    icon: Icons.inventory_2_rounded,
                    title: 'المنتجات',
                    value: '0',
                    suffix: '',
                  ),
                  _StatCard(
                    icon: Icons.warning_amber_rounded,
                    title: 'مخزون منخفض',
                    value: '0',
                    suffix: '',
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 28),

          const Text(
            'اختصارات سريعة',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _QuickAction(
                icon: Icons.add_box_rounded,
                label: 'منتج جديد',
                onTap: () {},
              ),
              _QuickAction(
                icon: Icons.point_of_sale_rounded,
                label: 'بيع جديد',
                onTap: () {},
              ),
              _QuickAction(
                icon: Icons.shopping_cart_rounded,
                label: 'شراء جديد',
                onTap: () {},
              ),
              _QuickAction(
                icon: Icons.person_add_alt_1_rounded,
                label: 'عميل جديد',
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: 28),

          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    Icons.insights_rounded,
                    size: 42,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ابدأ بإضافة منتجاتك',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'بعد إضافة المنتجات ستظهر هنا إحصاءات المبيعات والأرباح والمخزون.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String suffix;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 28,
              color: Theme.of(context).colorScheme.primary,
            ),
            const Spacer(),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 3),
            Text(
              '$value$suffix',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _PlaceholderPage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
