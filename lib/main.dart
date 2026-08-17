import 'package:flutter/material.dart';

void main() {
  runApp(const MakhzaniApp());
}

class MakhzaniApp extends StatefulWidget {
  const MakhzaniApp({super.key});

  @override
  State<MakhzaniApp> createState() => _MakhzaniAppState();
}

class _MakhzaniAppState extends State<MakhzaniApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF1565C0);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'مخزني',
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        ),
        fontFamily: 'sans',
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
        fontFamily: 'sans',
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: DashboardPage(
        isDarkMode: _themeMode == ThemeMode.dark,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const DashboardPage({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'مخزني',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: onToggleTheme,
            tooltip: isDarkMode ? 'الوضع الفاتح' : 'الوضع الداكن',
            icon: Icon(
              isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'لوحة التحكم',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'إدارة مخزونك ومبيعاتك بسهولة',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          const Row(
            children: [
              Expanded(
                child: _DashboardCard(
                  title: 'المبيعات',
                  value: '0',
                  icon: Icons.point_of_sale,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _DashboardCard(
                  title: 'الأرباح',
                  value: '0',
                  icon: Icons.trending_up,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(
                child: _DashboardCard(
                  title: 'المنتجات',
                  value: '0',
                  icon: Icons.inventory_2,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _DashboardCard(
                  title: 'الديون',
                  value: '0',
                  icon: Icons.credit_card,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.storefront,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'مرحبًا بك في مخزني',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'سيتم تجهيز إدارة المنتجات والمبيعات والمشتريات والعملاء هنا.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
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

class _DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _DashboardCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(title),
          ],
        ),
      ),
    );
  }
}
