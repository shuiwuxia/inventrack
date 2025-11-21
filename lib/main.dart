
// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'inventory.dart';
import 'pos.dart';
import 'analysis.dart';

void main() {
  runApp(const RetailApp());
}

class RetailApp extends StatelessWidget {
  const RetailApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RetailApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          headlineSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(fontSize: 16),
          bodyMedium: TextStyle(fontSize: 14),
        ),
      ),
      home: const RoleSelectionPage(),
    );
  }
}

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Choose Role")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.storefront),
                label: const Text("Shopkeeper"),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24)),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage()));
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.person),
                label: const Text("Customer"),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24)),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------ LOGIN PAGE (API-ENABLED) ------------------------------

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    const String apiUrl = "https://inventrack-backend-1.onrender.com/auth/login"; // FastAPI endpoint 
   

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "identifier": _emailController.text.trim(), // *** FIX APPLIED: Changed "email" to "identifier" ***
          "password": _passwordController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final prefs = await SharedPreferences.getInstance();
        
        // This line saves the user data returned from your API (email, full_name, etc.)
        // This ensures the Dashboard has data to display, matching your current signup flow.
        await prefs.setString('email', data['email'] ?? _emailController.text.trim());
        await prefs.setString('shopkeeperName', data['full_name'] ?? 'Shopkeeper');
        await prefs.setString('token', data['token'] ?? ''); // Assuming a token will be available later

        if (!mounted) return;
        
        // *** FIX APPLIED: Navigate to DashboardPage upon success ***
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardPage()),
        );
      } 
      // Handle invalid credentials
      else if (response.statusCode == 401 ||
               response.body.toLowerCase().contains("invalid")) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid credentials! Please try again.")),
        );
      } 
      // Handle all other server errors
      else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Server error: ${response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error connecting to server: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Shopkeeper Login")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Email / Mobile")),
            const SizedBox(height: 12),
            TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: "Password")),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: () {}, child: const Text("Forgot Password?")),
            ),
            const SizedBox(height: 12),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _login, 
                    child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12), 
                        child: Text("Login")
                      )
                  ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupPage())),
              child: const Text("Sign up for new user"),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------ SIGNUP PAGE ------------------------------
// adjust the import path if needed

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _shopName = TextEditingController();
  final _shopkeeperName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _address = TextEditingController();

  bool _isLoading = false;

  Future<void> _registerShopkeeper() async {
    if (!_formKey.currentState!.validate()) return;

    if (_password.text != _confirmPassword.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    setState(() => _isLoading = true);

    final url = Uri.parse("https://inventrack-backend-1.onrender.com/auth/register/shopkeeper"); // FastAPI endpoint
    

    final body = {
      "shop_name": _shopName.text.trim(),
      "full_name": _shopkeeperName.text.trim(),
      "email": _email.text.trim(),
      "phone": _phone.text.trim(),
      "password": _password.text.trim(),
      "address": _address.text.trim(),
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // ✅ Registration successful
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('email', _email.text);
        await prefs.setString('shopkeeperName', _shopkeeperName.text);
        await prefs.setString('shopName', _shopName.text);
        await prefs.setString('address', _address.text);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account created successfully!")),
        );

        // ✅ Navigate to dashboard
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DashboardPage()),
          );
        });
      } else if (response.statusCode == 400 || response.statusCode == 409) {
        // ⚠️ Handle duplicate or invalid email errors
        String message = "Registration failed";
        try {
          final jsonData = jsonDecode(response.body);
          if (jsonData['detail'] != null) {
            message = jsonData['detail'];
          } else if (jsonData['error'] != null) {
            message = jsonData['error'];
          }
        } catch (_) {}
        if (message.toLowerCase().contains('email')) {
          message = "This email is already registered!";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      } else {

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Server error: ${response.statusCode}")),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error connecting to server: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Shopkeeper Sign Up")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(children: [
            TextFormField(
              controller: _shopName,
              decoration: const InputDecoration(labelText: "Shop Name"),
              validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _shopkeeperName,
              decoration: const InputDecoration(labelText: "Shopkeeper Name"),
              validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(labelText: "Email"),
              validator: (v) {
                if (v == null || v.isEmpty) return "Required";
                final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
                if (!emailRegex.hasMatch(v)) return "Invalid email format";
                return null;
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _phone,
              decoration: const InputDecoration(labelText: "Phone"),
              keyboardType: TextInputType.phone,
              validator: (v) =>
                  (v == null || v.isEmpty) ? "Required" : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _address,
              decoration: const InputDecoration(labelText: "Address"),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _password,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
              validator: (v) => (v == null || v.length < 6)
                  ? "Password must be at least 6 characters"
                  : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _confirmPassword,
              decoration: const InputDecoration(labelText: "Confirm Password"),
              obscureText: true,
              validator: (v) =>
                  v != _password.text ? "Passwords do not match" : null,
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _registerShopkeeper,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 14),
                    ),
                    child: const Text(
                      "Sign Up",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
          ]),
        ),
      ),
    );
  }
}


// ------------------------------ DASHBOARD PAGE ------------------------------
// ✅ Ensure this import path is correct

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  ShopkeeperSummary _summary = ShopkeeperSummary.empty();

  final List<String> _pages = [
    "Primary Dashboard",
    "POS",
    "Inventory",
    "Notifications",
    "Profile",
    "Analysis"
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _summary = ShopkeeperSummary(
        shopName: prefs.getString('shopName') ?? 'My Shop',
        shopkeeperName: prefs.getString('shopkeeperName') ?? 'Shopkeeper',
        email: prefs.getString('email') ?? '',
        phone: prefs.getString('phone') ?? '',
        address: prefs.getString('address') ?? '',
      );
    });
  }

  // ✅ Logout function (redirects to RoleSelectionPage)
  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Logout Confirmation"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // ✅ Clear stored data

      if (!context.mounted) return;

      // ✅ Navigate back to RoleSelectionPage and remove all previous routes
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const RoleSelectionPage()),
        (route) => false,
      );
    }
  }

  Widget _buildDrawerHeader() {
    return UserAccountsDrawerHeader(
      accountName: Text(_summary.shopName),
      accountEmail: Text(_summary.shopkeeperName),
      currentAccountPicture: CircleAvatar(
        child: Text(
          _summary.shopName.isNotEmpty ? _summary.shopName[0] : 'S',
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(children: [
        _buildDrawerHeader(),
        Expanded(
          child: ListView.separated(
            itemCount: _pages.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final icon = [
                Icons.dashboard,
                Icons.point_of_sale,
                Icons.inventory_2,
                Icons.notifications,
                Icons.person,
                Icons.analytics
              ][index];
              return ListTile(
                leading: Icon(icon),
                title: Text(_pages[index]),
                selected: _selectedIndex == index,
                onTap: () {
                  setState(() => _selectedIndex = index);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text("Logout"),
          onTap: _logout, // ✅ Calls the logout function
        ),
      ]),
    );
  }

  Widget _content() {
    switch (_selectedIndex) {
      case 0:
        return PrimaryDashboardWidget(summary: _summary);
      case 1:
        return const POSWidget();
      case 2:
        return const InventoryWidget();
      case 3:
        return const NotificationsWidget();
      case 4:
        return ProfileWidget(summary: _summary, onUpdated: _loadProfile);
      case 5:
        return const AnalysisWidget();
      default:
        return const Center(child: Text('Unknown page'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pages[_selectedIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'refresh',
            onPressed: () => showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('refresh'),
                content: const Text(
                    'refresh'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  )
                ],
              ),
            ),
          )
        ],
      ),
      drawer: _buildDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _content(),
      ),
    );
  }
}


// ------------------------------ MODELS ------------------------------

class ShopkeeperSummary {
  final String shopName;
  final String shopkeeperName;
  final String email;
  final String phone;
  final String address;

  ShopkeeperSummary({required this.shopName, required this.shopkeeperName, required this.email, required this.phone, required this.address});

  ShopkeeperSummary.empty()
      : shopName = 'My Shop',
        shopkeeperName = 'Shopkeeper',
        email = '',
        phone = '',
        address = '';
}

// ------------------------------ PRIMARY DASHBOARD ------------------------------

class PrimaryDashboardWidget extends StatelessWidget {
  final ShopkeeperSummary summary;
  const PrimaryDashboardWidget({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Primary Dashboard', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          // Use LayoutBuilder to create a responsive layout
          LayoutBuilder(
            builder: (context, constraints) {
              // Use a Column for narrow screens (mobile)
              if (constraints.maxWidth < 600) {
                return Column(
                  children: [
                    _revenueCard(context),
                    const SizedBox(height: 12),
                    _productOverviewCard(context),
                    const SizedBox(height: 12),
                    _alertsCard(context),
                    const SizedBox(height: 12),
                    _forecastCard(context),
                  ],
                );
              }
              // Use a Row for wider screens (tablet/desktop)
              return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 3, child: Column(children: [
                  _revenueCard(context),
                  const SizedBox(height: 12),
                  _productOverviewCard(context),
                ])),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: Column(children: [
                  _alertsCard(context),
                  const SizedBox(height: 12),
                  _forecastCard(context),
                ])),
              ]);
            },
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Products list sample', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(columns: const [
                    DataColumn(label: Text('Product')),
                    DataColumn(label: Text('Category')),
                    DataColumn(label: Text('Qty')),
                    DataColumn(label: Text('Price')),
                    DataColumn(label: Text('Status')),
                  ], rows: const [
                    DataRow(cells: [DataCell(Text('Organic Milk')), DataCell(Text('Dairy')), DataCell(Text('24')), DataCell(Text('\$3.99')), DataCell(Text('In Stock'))]),
                    DataRow(cells: [DataCell(Text('Whole Wheat Bread')), DataCell(Text('Bakery')), DataCell(Text('5')), DataCell(Text('\$2.49')), DataCell(Text('Low Stock'))]),
                    DataRow(cells: [DataCell(Text('Red Apples')), DataCell(Text('Fruits')), DataCell(Text('0')), DataCell(Text('\$1.29')), DataCell(Text('Out of Stock'))]),
                    DataRow(cells: [DataCell(Text('Free Range Eggs')), DataCell(Text('Dairy')), DataCell(Text('42')), DataCell(Text('\$4.29')), DataCell(Text('In Stock'))]),
                  ]),
                ),
              ]),
            ),
          )
        ],
      ),
    );
  }

  Widget _revenueCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Revenue', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text('Monthly Sales (%) compared to previous month'),
          const SizedBox(height: 8),
          const LinearProgressIndicator(value: 0.6),
          const SizedBox(height: 12),
          const Text('Profit / Loss (%) (+ for profit, - for loss)'),
          const SizedBox(height: 8),
          const LinearProgressIndicator(value: 0.35),
          const SizedBox(height: 12),
          Row(children: const [
            Icon(Icons.attach_money),
            SizedBox(width: 6),
            Text('Total Sales: \$12,340'),
          ]),
        ]),
      ),
    );
  }

  Widget _productOverviewCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Product Overview', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const ListTile(title: Text('Total Number of Products'), trailing: Text('24')),
          const ListTile(title: Text('Number of Low Stock Products'), trailing: Text('5')),
          const ListTile(title: Text('Top Selling Products (top 5)'), subtitle: Text('1. Bread\n2. Milk\n3. Eggs\n4. Apples\n5. Butter')),
        ]),
      ),
    );
  }

  Widget _alertsCard(BuildContext context) {
    final alerts = [
      {'title': 'Low Stock Alert', 'subtitle': 'Whole Wheat Bread is running low (5 remaining)'},
      {'title': 'Seasonal Forecast', 'subtitle': 'Ice cream demand expected to increase by 30% next week.'},
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Recent Alerts', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          ...alerts.map((a) => ListTile(leading: const Icon(Icons.notification_important), title: Text(a['title']!), subtitle: Text(a['subtitle']!))),
          Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () {}, child: const Text('View All Alerts'))),
        ]),
      ),
    );
  }

  Widget _forecastCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Forecast', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text('Whole Wheat Bread'),
          const LinearProgressIndicator(value: 0.4),
          const SizedBox(height: 8),
          const Text('Free Range Eggs'),
          const LinearProgressIndicator(value: 0.8),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: () {}, child: const Text('Generate Full Forecast')),
        ]),
      ),
    );
  }
}

// ------------------------------ POS PAGE ------------------------------

class POSWidget extends StatelessWidget {
  const POSWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: () { 
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => POS()),
          );
        },
        child: Text(
          'Go to pos',
          style: Theme.of(context)
              .textTheme
              .bodyMedium!
              .copyWith(color: const Color.fromARGB(255, 78, 78, 78)),
        ),
      ),
    );
  }
}

// ------------------------------ INVENTORY PAGE ------------------------------

class InventoryWidget extends StatelessWidget {
  const InventoryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        // inside InventoryWidget build method
        onPressed: () {
          // Use a String for the store ID
          const String storeIdForNavigation = 'S1001'; 
        
          Navigator.push(
            context,
            // FIX: Pass the required 'storeId' as a String
            MaterialPageRoute(builder: (_) => InventoryPage(storeId: storeIdForNavigation)),
            // Note: The 'const' keyword before InventoryPage is removed because 
            // we're passing a non-constant context variable.
          );
        },
        child: Text(
          'Go to Inventory',
          style: Theme.of(context)
              .textTheme
              .bodyMedium!
              .copyWith(color: Colors.grey[600]),
        ),
      ),
    );
  }
}

class NotificationsWidget extends StatefulWidget {
  const NotificationsWidget({super.key});

  @override
  State<NotificationsWidget> createState() => _NotificationsWidgetState();
}

class _NotificationsWidgetState extends State<NotificationsWidget> {
  // Low stock notifications
  List<Map<String, dynamic>> alerts = [
    {
      'title': 'Low Stock Alert',
      'subtitle': 'Product P0011 is running low (5 remaining)',
      'time': 'Just now',
      'read': false
    },
    {
      'title': 'Low Stock Alert',
      'subtitle': 'Product P0016 is running low (74 remaining)',
      'time': 'Just now',
      'read': false
    },
    {
      'title': 'Low Stock Alert',
      'subtitle': 'Product P0003 is running low (69 remaining)',
      'time': 'Just now',
      'read': false
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Notifications', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                for (int i = 0; i < alerts.length; i++)
                  ListTile(
                    leading: const Icon(Icons.notifications),
                    title: Text(alerts[i]['title']!),
                    subtitle: Row(
                      children: [
                        Expanded(child: Text('${alerts[i]['subtitle']} • ${alerts[i]['time']}')),
                        if (alerts[i]['read'] == true)
                          const Icon(Icons.done_all, color: Colors.blue, size: 16),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              alerts[i]['read'] = true; // mark as read
                            });
                          },
                          child: const Text('Mark as read'),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              alerts.removeAt(i); // delete notification
                            });
                          },
                          child: const Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
// ------------------------------ PROFILE PAGE ------------------------------

class ProfileWidget extends StatefulWidget {
  final ShopkeeperSummary summary;
  final VoidCallback onUpdated;
  const ProfileWidget({super.key, required this.summary, required this.onUpdated});

  @override
  State<ProfileWidget> createState() => _ProfileWidgetState();
}

class _ProfileWidgetState extends State<ProfileWidget> {
  bool _editing = false;
  late final TextEditingController _shopCtrl;
  late final TextEditingController _keeperCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addrCtrl;

  @override
  void initState() {
    super.initState();
    _shopCtrl = TextEditingController(text: widget.summary.shopName);
    _keeperCtrl = TextEditingController(text: widget.summary.shopkeeperName);
    _emailCtrl = TextEditingController(text: widget.summary.email);
    _phoneCtrl = TextEditingController(text: widget.summary.phone);
    _addrCtrl = TextEditingController(text: widget.summary.address);
  }

  @override
  void dispose() {
    _shopCtrl.dispose();
    _keeperCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addrCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('shopName', _shopCtrl.text);
    await prefs.setString('shopkeeperName', _keeperCtrl.text);
    await prefs.setString('email', _emailCtrl.text);
    await prefs.setString('phone', _phoneCtrl.text);
    await prefs.setString('address', _addrCtrl.text);
    widget.onUpdated();
    setState(() => _editing = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Profile', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: _editing ? _editForm() : _viewProfile(),
          ),
        )
      ]),
    );
  }

  Widget _viewProfile() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Shop name: ${widget.summary.shopName}'),
      const SizedBox(height: 6),
      Text('Shopkeeper: ${widget.summary.shopkeeperName}'),
      const SizedBox(height: 6),
      Text('Email: ${widget.summary.email}'),
      const SizedBox(height: 6),
      Text('Phone: ${widget.summary.phone}'),
      const SizedBox(height: 6),
      Text('Address: ${widget.summary.address}'),
      const SizedBox(height: 12),
      Row(children: [
        ElevatedButton(onPressed: () => setState(() => _editing = true), child: const Text('Edit Profile')),
        const SizedBox(width: 12),
        OutlinedButton(onPressed: () => _changePassword(), child: const Text('Change Password')),
      ])
    ]);
  }

  Widget _editForm() {
    return Column(children: [
      TextField(controller: _shopCtrl, decoration: const InputDecoration(labelText: 'Shop name')),
      const SizedBox(height: 8),
      TextField(controller: _keeperCtrl, decoration: const InputDecoration(labelText: 'Shopkeeper name')),
      const SizedBox(height: 8),
      TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
      const SizedBox(height: 8),
      TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Phone')),
      const SizedBox(height: 8),
      TextField(controller: _addrCtrl, decoration: const InputDecoration(labelText: 'Address')),
      const SizedBox(height: 12),
      Row(children: [
        ElevatedButton(onPressed: _saveProfile, child: const Text('Save')),
        const SizedBox(width: 12),
        OutlinedButton(onPressed: () => setState(() => _editing = false), child: const Text('Cancel')),
      ])
    ]);
  }

  void _changePassword() {
    showDialog(context: context, builder: (_) {
      final oldCtrl = TextEditingController();
      final newCtrl = TextEditingController();
      final confirmCtrl = TextEditingController();
      return AlertDialog(
        title: const Text('Change Password'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: oldCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Old password')),
          TextField(controller: newCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'New password')),
          TextField(controller: confirmCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm password')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () async {
            if (newCtrl.text != confirmCtrl.text) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New passwords do not match')));
              return;
            }
            final prefs = await SharedPreferences.getInstance();
            final saved = prefs.getString('password') ?? '';
            if (oldCtrl.text != saved) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wrong old password')));
              return;
            }
            await prefs.setString('password', newCtrl.text);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed')));
          }, child: const Text('Change')),
        ],
      );
    });
  }
}
class AnalysisWidget extends StatelessWidget {
  const AnalysisWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Analysis"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => Analysispage()), // ✅ navigate to analysis page
            );
          },
          child: Text(
            'Go to Analysis',
            style: Theme.of(context)
                .textTheme
                .bodyMedium!
                .copyWith(color: Colors.grey[600]),
          ),
        ),
      ),
    );
  }
}
