

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // add intl to pubspec.yaml
// lib/main.dart
// ADD THESE TWO IMPORTS:
// ignore: unused_import
import 'product_model.dart'; 
// ignore: unused_import
import 'inventory_service.dart'; 

void main() => runApp(const RetailApp());

class RetailApp extends StatelessWidget {
  const RetailApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Retail App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LandingPage(),
      debugShowCheckedModeBanner: false,
      routes: {
        SalesPage.routeName: (_) => SalesPage(),
        LowStockPage.routeName: (_) => LowStockPage(),
        RestockPage.routeName: (_) => RestockPage(),
        NotificationsPage.routeName: (_) => NotificationsPage(),
      },
    );
  }
}

/////////////////////////////
// LANDING PAGE
/////////////////////////////
class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Retail App Landing')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: const Text('Shopkeeper Sign Up / Login'),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ShopkeeperSignUp()));
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text('Customer Sign Up / Login'),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerSignUp()));
              },
            ),
          ],
        ),
      ),
    );
  }
}

/////////////////////////////
// SHOPKEEPER SIGN UP / LOGIN
/////////////////////////////
class ShopkeeperSignUp extends StatefulWidget {
  const ShopkeeperSignUp({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ShopkeeperSignUpState createState() => _ShopkeeperSignUpState();
}

class _ShopkeeperSignUpState extends State<ShopkeeperSignUp> {
  final _shopNameController = TextEditingController();
  final _shopkeeperNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _shopNameController.dispose();
    _shopkeeperNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _signUp() {
    // Simple validation for example
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ShopkeeperDashboard(
          shopName: _shopNameController.text,
          shopkeeperName: _shopkeeperNameController.text,
          email: _emailController.text,
          phone: _phoneController.text,
          address: _addressController.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shopkeeper Sign Up / Login')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _shopNameController, decoration: const InputDecoration(labelText: 'Shop Name')),
          TextField(controller: _shopkeeperNameController, decoration: const InputDecoration(labelText: 'Shopkeeper Name')),
          TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
          TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone'), keyboardType: TextInputType.phone),
          TextField(controller: _addressController, decoration: const InputDecoration(labelText: 'Address')),
          TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
          TextField(controller: _confirmPasswordController, decoration: const InputDecoration(labelText: 'Confirm Password'), obscureText: true),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _signUp, child: const Text('Sign Up / Login')),
        ],
      ),
    );
  }
}

/////////////////////////////
// SHOPKEEPER DASHBOARD
/////////////////////////////
class ShopkeeperDashboard extends StatefulWidget {
  final String shopName;
  final String shopkeeperName;
  final String email;
  final String phone;
  final String address;

  const ShopkeeperDashboard({super.key, 
    required this.shopName,
    required this.shopkeeperName,
    required this.email,
    required this.phone,
    required this.address,
  });

  @override
  State<ShopkeeperDashboard> createState() => _ShopkeeperDashboardState();
}

class _ShopkeeperDashboardState extends State<ShopkeeperDashboard> {
  // Top Selling (primary dashboard) - 5 editable
  final List<TextEditingController> topSellingControllers = List.generate(5, (i) => TextEditingController());
  // Low stock preview (primary)
  final List<TextEditingController> lowStockPreview = List.generate(3, (i) => TextEditingController());

  // Profile controllers
  late final TextEditingController _shopNameController;
  late final TextEditingController _shopkeeperNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  final TextEditingController _changePasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Notifications sample
  @override
  void initState() {
    super.initState();
    _shopNameController = TextEditingController(text: widget.shopName);
    _shopkeeperNameController = TextEditingController(text: widget.shopkeeperName);
    _emailController = TextEditingController(text: widget.email);
    _phoneController = TextEditingController(text: widget.phone);
    _addressController = TextEditingController(text: widget.address);

    // Fill sample defaults for top selling (optional)
    for (int i = 0; i < topSellingControllers.length; i++) {
      topSellingControllers[i].text = 'Product ${i + 1}';
    }

    // sample low stock preview
    for (int i = 0; i < lowStockPreview.length; i++) {
      lowStockPreview[i].text = 'LowStock ${i + 1}';
    }
  }

  @override
  void dispose() {
    for (final c in topSellingControllers) {
      c.dispose();
    }
    for (final c in lowStockPreview) {
      c.dispose();
    }
    _shopNameController.dispose();
    _shopkeeperNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _changePasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _openSales(String type) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => SalesPage(initialType: type)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopkeeper Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => Navigator.pushNamed(context, NotificationsPage.routeName),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          /////////////////////////////
          // Primary Dashboard
          /////////////////////////////
          ExpansionTile(
            initiallyExpanded: true,
            title: const Text('Primary Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
            children: [
              ListTile(
                title: const Text('Revenue %'),
                subtitle: const TextField(decoration: InputDecoration(hintText: 'Enter Revenue %')),
              ),
              ListTile(
                title: const Text('Profit/Loss %'),
                subtitle: const TextField(decoration: InputDecoration(hintText: 'Enter Profit/Loss %')),
              ),
              ListTile(
                title: const Text('Total Products'),
                subtitle: const TextField(decoration: InputDecoration(hintText: 'Enter total products')),
              ),
              ListTile(
                title: const Text('Low Stock (preview)'),
                subtitle: Column(
                  children: lowStockPreview.map((c) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: TextField(controller: c, decoration: const InputDecoration(hintText: 'Low stock product')),
                  )).toList(),
                ),
                trailing: ElevatedButton(
                  child: const Text('Open'),
                  onPressed: () => Navigator.pushNamed(context, LowStockPage.routeName),
                ),
              ),
              ListTile(
                title: const Text('Top Selling Products'),
                subtitle: Column(
                  children: topSellingControllers.map((c) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: TextField(controller: c, decoration: const InputDecoration(hintText: 'Top selling product (editable)')),
                  )).toList(),
                ),
              ),
            ],
          ),

          /////////////////////////////
          // POS
          /////////////////////////////
          ExpansionTile(
            title: const Text('POS', style: TextStyle(fontWeight: FontWeight.bold)),
            children: [
              ListTile(title: const Text('Product Search / Selection'), subtitle: const TextField(decoration: InputDecoration(hintText: 'Enter Product Name'))),
              ListTile(title: const Text('Quantity'), subtitle: const TextField(decoration: InputDecoration(hintText: 'Enter Quantity'), keyboardType: TextInputType.number)),
              ListTile(title: const Text('Discount / Tax'), subtitle: const TextField(decoration: InputDecoration(hintText: 'Enter Discount / Tax'))),
              ListTile(title: const Text('Total Bill'), subtitle: const TextField(decoration: InputDecoration(hintText: 'Enter Total'))),
            ],
          ),

          /////////////////////////////
          // Inventory
          /////////////////////////////
          ExpansionTile(
            title: const Text('Inventory', style: TextStyle(fontWeight: FontWeight.bold)),
            children: [
              ListTile(title: const Text('SKU (mandatory)'), subtitle: const TextField()),
              ListTile(title: const Text('Product Name'), subtitle: const TextField()),
              ListTile(title: const Text('Category'), subtitle: const TextField()),
              ListTile(title: const Text('MRP'), subtitle: const TextField()),
              ListTile(title: const Text('MSP'), subtitle: const TextField()),
              ListTile(title: const Text('Price'), subtitle: const TextField()),
              ListTile(title: const Text('Quantity'), subtitle: const TextField()),
              ListTile(title: const Text('Last Restock'), subtitle: const TextField()),
            ],
          ),

          /////////////////////////////
          // Notifications
          /////////////////////////////
          ExpansionTile(
            title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
            children: [
              ListTile(
                title: const Text('Open Notifications Center'),
                trailing: ElevatedButton(child: const Text('Open'), onPressed: () => Navigator.pushNamed(context, NotificationsPage.routeName)),
                subtitle: const Text('Tap to view all notifications with date/time and read/unread status'),
              ),
            ],
          ),

          /////////////////////////////
          // Profile
          /////////////////////////////
          ExpansionTile(
            title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
            children: [
              ListTile(title: const Text('Shop Name'), subtitle: TextField(controller: _shopNameController)),
              ListTile(title: const Text('Shopkeeper Name'), subtitle: TextField(controller: _shopkeeperNameController)),
              ListTile(title: const Text('Email'), subtitle: TextField(controller: _emailController)),
              ListTile(title: const Text('Phone'), subtitle: TextField(controller: _phoneController)),
              ListTile(title: const Text('Address'), subtitle: TextField(controller: _addressController)),
              ListTile(
                title: const Text('Change Password'),
                subtitle: Column(
                  children: [
                    TextField(controller: _changePasswordController, obscureText: true, decoration: const InputDecoration(hintText: 'New Password')),
                    const SizedBox(height: 8),
                    TextField(controller: _confirmPasswordController, obscureText: true, decoration: const InputDecoration(hintText: 'Confirm Password')),
                    const SizedBox(height: 8),
                    ElevatedButton(onPressed: () {
                      if (_changePasswordController.text != _confirmPasswordController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed (local only)')));
                      }
                    }, child: const Text('Update Password')),
                  ],
                ),
              ),
              ListTile(title: ElevatedButton(child: const Text('Delete Account'), onPressed: () {})),
              ListTile(title: ElevatedButton(child: const Text('Logout'), onPressed: () => Navigator.pop(context))),
            ],
          ),

          /////////////////////////////
          // Analysis
          /////////////////////////////
          ExpansionTile(
            title: const Text('Analysis', style: TextStyle(fontWeight: FontWeight.bold)),
            children: [
              // Top Selling Products - 5 fields
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Top Selling Products (5)'),
                    const SizedBox(height: 8),
                    ...List.generate(5, (i) {
                      // separate controllers for this analysis area
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: TextField(
                          decoration: InputDecoration(labelText: 'Top Product ${i + 1} (editable)'),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              // Demand Forecast - 5 rows
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Demand Forecast (5 products)'),
                    const SizedBox(height: 8),
                    ...List.generate(5, (i) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: TextField(decoration: InputDecoration(labelText: 'Forecast Product ${i + 1}')),
                    )),
                  ],
                ),
              ),

              // Total Sales clickable options
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Sales'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ElevatedButton(onPressed: () => _openSales('Daily'), child: const Text('Daily')),
                        ElevatedButton(onPressed: () => _openSales('Weekly'), child: const Text('Weekly')),
                        ElevatedButton(onPressed: () => _openSales('Monthly'), child: const Text('Monthly')),
                        ElevatedButton(onPressed: () => _openSales('Yearly'), child: const Text('Yearly')),
                      ],
                    ),
                  ],
                ),
              ),

              // Low Stock products open dynamic page
              ListTile(
                title: const Text('Low Stock Products (editable)'),
                subtitle: const Text('Open the Low Stock manager to add/edit boxes'),
                trailing: ElevatedButton(child: const Text('Open'), onPressed: () => Navigator.pushNamed(context, LowStockPage.routeName)),
              ),

              // Restock Recommendations open dynamic page
              ListTile(
                title: const Text('Restock Recommendations'),
                subtitle: const Text('Open to view or add recommendations'),
                trailing: ElevatedButton(child: const Text('Open'), onPressed: () => Navigator.pushNamed(context, RestockPage.routeName)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/////////////////////////////
// SALES PAGE (Daily / Weekly / Monthly / Yearly)
/////////////////////////////
class SalesPage extends StatefulWidget {
  static const routeName = '/sales';
  final String? initialType;
  const SalesPage({super.key, this.initialType});
  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  String _selected = 'Daily';
  final Map<String, List<String>> demoData = {
    'Daily': ['Order A - 100', 'Order B - 200'],
    'Weekly': ['Week 1 - 1000', 'Week 2 - 1200'],
    'Monthly': ['Jan - 4000', 'Feb - 4500'],
    'Yearly': ['2023 - 50000', '2024 - 60000'],
  };

  @override
  void initState() {
    super.initState();
    if (widget.initialType != null) _selected = widget.initialType!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sales - $_selected'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Wrap(
              spacing: 8,
              children: ['Daily', 'Weekly', 'Monthly', 'Yearly'].map((t) => ChoiceChip(
                label: Text(t),
                selected: _selected == t,
                onSelected: (_) => setState(() => _selected = t),
              )).toList(),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: (demoData[_selected] ?? []).map((s) => Card(child: ListTile(title: Text(s)))).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/////////////////////////////
// LOW STOCK PAGE (dynamic boxes)
/////////////////////////////
class LowStockPage extends StatefulWidget {
  static const routeName = '/lowstock';

  const LowStockPage({super.key});
  @override
  State<LowStockPage> createState() => _LowStockPageState();
}

class _LowStockPageState extends State<LowStockPage> {
  List<TextEditingController> items = [];

  @override
  void initState() {
    super.initState();
    // start with two boxes
    items.add(TextEditingController(text: 'Low item 1'));
    items.add(TextEditingController(text: 'Low item 2'));
  }

  @override
  void dispose() {
    for (final c in items) {
      c.dispose();
    }
    super.dispose();
  }

  void addItem() {
    setState(() {
      items.add(TextEditingController());
    });
  }

  void removeItem(int index) {
    setState(() {
      items[index].dispose();
      items.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Low Stock Manager'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addItem,
        tooltip: 'Add Item Box',
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        itemBuilder: (context, i) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              title: TextField(controller: items[i], decoration: InputDecoration(labelText: 'Low Stock Item ${i + 1}')),
              trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () => removeItem(i)),
            ),
          );
        },
      ),
    );
  }
}

/////////////////////////////
// RESTOCK RECOMMENDATIONS (dynamic boxes)
/////////////////////////////
class RestockPage extends StatefulWidget {
  static const routeName = '/restock';

  const RestockPage({super.key});
  @override
  State<RestockPage> createState() => _RestockPageState();
}

class _RestockPageState extends State<RestockPage> {
  List<TextEditingController> items = [];

  @override
  void initState() {
    super.initState();
    items.add(TextEditingController(text: 'Recommend A'));
  }

  @override
  void dispose() {
    for (final c in items) {
      c.dispose();
    }
    super.dispose();
  }

  void addItem() {
    setState(() {
      items.add(TextEditingController());
    });
  }

  void removeItem(int idx) {
    setState(() {
      items[idx].dispose();
      items.removeAt(idx);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restock Recommendations'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addItem,
        tooltip: 'Add Recommendation',
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        itemBuilder: (context, i) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              title: TextField(controller: items[i], decoration: InputDecoration(labelText: 'Recommendation ${i + 1}')),
              trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () => removeItem(i)),
            ),
          );
        },
      ),
    );
  }
}

/////////////////////////////
// NOTIFICATIONS PAGE
/////////////////////////////
class NotificationItem {
  String title;
  String type;
  DateTime dateTime;
  bool read;

  NotificationItem({
    required this.title,
    required this.type,
    required this.dateTime,
    this.read = false,
  });
}

class NotificationsPage extends StatefulWidget {
  static const routeName = '/notifications';

  const NotificationsPage({super.key});
  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<NotificationItem> notifications = [];

  @override
  void initState() {
    super.initState();
    // sample notifications
    notifications = [
      NotificationItem(title: 'Stock low: Product 12', type: 'Stock', dateTime: DateTime.now().subtract(const Duration(hours: 2))),
      NotificationItem(title: 'New message from supplier', type: 'Message', dateTime: DateTime.now().subtract(const Duration(days: 1)), read: true),
      NotificationItem(title: 'Sale milestone reached', type: 'Info', dateTime: DateTime.now().subtract(const Duration(days: 3))),
    ];
  }

  void toggleRead(int i) {
    setState(() {
      notifications[i].read = !notifications[i].read;
    });
  }

  String formatDT(DateTime dt) {
    return DateFormat('yyyy-MM-dd HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                for (final n in notifications) {
                  n.read = true;
                }
              });
            },
            child: const Text('Mark all read', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: notifications.length,
        itemBuilder: (context, i) {
          final n = notifications[i];
          return Card(
            child: ListTile(
              leading: Icon(n.read ? Icons.mark_email_read : Icons.mark_email_unread, color: n.read ? Colors.grey : Colors.blue),
              title: Text(n.title),
              subtitle: Text('${n.type} • ${formatDT(n.dateTime)}'),
              trailing: IconButton(
                icon: Icon(n.read ? Icons.check_circle : Icons.circle_outlined),
                onPressed: () => toggleRead(i),
              ),
              onTap: () => toggleRead(i),
            ),
          );
        },
      ),
    );
  }
}

/////////////////////////////
// CUSTOMER SIGN UP / LOGIN + DASHBOARD (unchanged but included)
/////////////////////////////
class CustomerSignUp extends StatefulWidget {
  const CustomerSignUp({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CustomerSignUpState createState() => _CustomerSignUpState();
}

class _CustomerSignUpState extends State<CustomerSignUp> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  void _signup() {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerDashboard(
          name: _nameController.text,
          email: _emailController.text,
          phone: _phoneController.text,
          address: _addressController.text,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customer Sign Up / Login')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full Name')),
          TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
          TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone'), keyboardType: TextInputType.phone),
          TextField(controller: _addressController, decoration: const InputDecoration(labelText: 'Address')),
          TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
          TextField(controller: _confirmPasswordController, decoration: const InputDecoration(labelText: 'Confirm Password'), obscureText: true),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _signup, child: const Text('Sign Up / Login')),
        ],
      ),
    );
  }
}

class CustomerDashboard extends StatelessWidget {
  final String name;
  final String email;
  final String phone;
  final String address;

  const CustomerDashboard({super.key, 
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController(text: name);
    final emailController = TextEditingController(text: email);
    final phoneController = TextEditingController(text: phone);
    final addressController = TextEditingController(text: address);

    return Scaffold(
      appBar: AppBar(title: const Text('Customer Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ExpansionTile(
            title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
            children: [
              ListTile(title: TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full Name'))),
              ListTile(title: TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email'))),
              ListTile(title: TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone'))),
              ListTile(title: TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Address'))),
              ListTile(
                title: ElevatedButton(
                  child: const Text('Logout'),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
          ExpansionTile(title: const Text('Home / Quick Access'), children: const [
            ListTile(title: Text('Categories, Products, Cart/Favorites')),
          ]),
        ],
      ),
    );
  }
}