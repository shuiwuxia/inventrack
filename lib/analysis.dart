// ignore_for_file: deprecated_member_use, unused_local_variable

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:collection/collection.dart'; // REQUIRED: For the groupBy function

// --- NEW: Analytics Period Page ---
// A reusable, stateful widget to display KPIs for a specific time period (Daily, Weekly, Monthly).
class AnalyticsPeriodPage extends StatefulWidget {
  final String title;
  final String periodKey; // e.g., 'kpis_daily', 'kpis_weekly'
  final String storeId;

  const AnalyticsPeriodPage({
    super.key,
    required this.title,
    required this.periodKey,
    required this.storeId,
  });

  @override
  State<AnalyticsPeriodPage> createState() => _AnalyticsPeriodPageState();
}

class _AnalyticsPeriodPageState extends State<AnalyticsPeriodPage> {
  Map<String, dynamic>? _kpiData;
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  // MODIFIED: This function now uses dummy data for daily, weekly, and monthly views
  // to demonstrate how the KPI cards will look.
  Future<void> _fetchAnalytics() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 400));

    // --- Dummy Data Generation ---
    Map<String, dynamic> getDummyData(String period) {
      double revenueMultiplier = 1.0;
      double countMultiplier = 1.0;
      if (period == 'kpis_weekly') {
        revenueMultiplier = 7.0;
        countMultiplier = 7.0;
      } else if (period == 'kpis_monthly') {
        revenueMultiplier = 30.0;
        countMultiplier = 30.0;
      }

      return {
        "total_revenue_inr": {"value": 15200.0 * revenueMultiplier, "unit": "INR"},
        "total_sales_count": {"value": 85.0 * countMultiplier, "unit": "Count"},
        "total_units_sold": {"value": 210.0 * countMultiplier, "unit": "Units"},
      };
    }

    // Use the dummy data based on the period key
    final dummyKpiData = getDummyData(widget.periodKey);

    setState(() {
      _kpiData = dummyKpiData;
      _isLoading = false;
    });

    // NOTE: The original API call is commented out below.
    // You can restore it when your backend provides live data for these periods.
    /* try { ... original API call logic ... } catch (e) { ... } */
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(_error, style: const TextStyle(color: Colors.red)))
              : _kpiData == null
                  ? const Center(child: Text("No data available for this period."))
                  : SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 56.0), // More padding for Samsung devices, extra 36px bottom padding to prevent overlap
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            // Get screen information for Samsung device optimization
                            final mediaQuery = MediaQuery.of(context);
                            final screenHeight = mediaQuery.size.height;
                            final isSamsungLike = screenHeight < 800;

                            // Responsive layout: 1 column on mobile, 2 on larger screens
                            final isMobile = constraints.maxWidth < 600;
                            final crossAxisCount = isMobile ? 1 : 2;
                            final childAspectRatio = isSamsungLike ? (isMobile ? 3.0 : 2.2) : (isMobile ? 2.5 : 1.8); // Even taller cards for Samsung
                            
                            // MODIFIED: Removed GridView and childAspectRatio to prevent overflow.
                            // Using a simple Column inside a SingleChildScrollView is more robust.
                            return ListView(
                              children: [
                                SizedBox(
                                  height: 200, // Give cards a fixed, sufficient height
                                  child: _buildKpiCard(
                                    'Total Revenue',
                                    _kpiData!['total_revenue_inr']['value'],
                                    _kpiData!['total_revenue_inr']['unit'],
                                    Icons.currency_rupee,
                                    Colors.green,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 200,
                                  child: _buildKpiCard(
                                    'Total Sales Count',
                                    _kpiData!['total_sales_count']['value'],
                                    _kpiData!['total_sales_count']['unit'],
                                    Icons.receipt_long,
                                    Colors.blue,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 200,
                                  child: _buildKpiCard(
                                    'Total Units Sold',
                                    _kpiData!['total_units_sold']['value'],
                                    _kpiData!['total_units_sold']['unit'],
                                    Icons.inventory_2,
                                    Colors.orange,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
    );
  }

  Widget _buildKpiCard(String title, double value, String unit, IconData icon, Color color) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Get screen information for Samsung device optimization
        final mediaQuery = MediaQuery.of(context);
        final screenHeight = mediaQuery.size.height;
        final isSamsungLike = screenHeight < 800;

        final isMobile = constraints.maxWidth < 400; // Detect very small screens
        final iconSize = isSamsungLike ? (isMobile ? 42.0 : 46.0) : (isMobile ? 36.0 : 40.0); // Larger icons for Samsung
        final titleFontSize = isSamsungLike ? (isMobile ? 20.0 : 22.0) : (isMobile ? 18.0 : 20.0); // Larger titles for Samsung
        final valueFontSize = isSamsungLike ? (isMobile ? 32.0 : 36.0) : (isMobile ? 28.0 : 32.0); // Larger values for Samsung

        return Card(
          elevation: isSamsungLike ? 8 : 6, // Higher elevation for Samsung
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isSamsungLike ? 20 : 16)), // More rounded for Samsung
          child: Padding(
            padding: EdgeInsets.all(isSamsungLike ? 24.0 : 20.0), // More padding for Samsung
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: iconSize, color: color),
                SizedBox(height: isSamsungLike ? 20 : 16), // More spacing for Samsung
                Text(
                  title,
                  style: TextStyle(fontSize: titleFontSize, color: Colors.black54, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: isSamsungLike ? 12 : 8), // More spacing for Samsung
                Text(
                  '${value.toStringAsFixed(0)} $unit',
                  style: TextStyle(fontSize: valueFontSize, fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AnalysisDashboard extends StatelessWidget {
  const AnalysisDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "MarketFlow AI",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
      ),
      home: const Analysispage(),
    );
  }
}

class Analysispage extends StatefulWidget {
  const Analysispage({super.key});

  @override
  State<Analysispage> createState() => _AnalysispageState();
}

class _AnalysispageState extends State<Analysispage> {
  // New structure for grouped forecast data: Map<ProductID, List<FlSpot>>
  Map<String, List<FlSpot>> _groupedForecastSpots = {};
  List<Map<String, dynamic>> _productData = [];
  List<Map<String, dynamic>> _recommendations = [];
  List<Map<String, dynamic>> _restockAlerts = [];
  // ignore: unused_field
  List<Map<String, dynamic>> _salesTrendData = [];
  List<String> _forecastDates = []; // To hold date labels for the X-axis
  Map<String, dynamic>? _overallKpis; // To hold overall KPI data
  bool _isLoading = false;

  // For mobile testing, replace with your computer's IP address (run 'ipconfig' on Windows or 'ifconfig' on Mac/Linux)
  // Example: "http://192.168.1.100:8000" - use your actual local IP, not 192.168.42.146
  // Or use ngrok/localtunnel to expose your local server: "https://your-ngrok-url.ngrok.io"
  final String baseUrl = "http://192.168.42.146:8000"; // Update this IP for mobile testing
  final String storeId = "S1001"; // Hardcoded store ID for the API calls

  // Define a set of distinct colors for the different lines
  final List<Color> chartColors = [
    Colors.deepPurple,
    Colors.orange,
    Colors.teal,
    Colors.red,
    Colors.green,
    Colors.blueGrey,
    Colors.pink,
    Colors.cyan,
  ];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  // Helper to map product ID to a consistent color
  Color _getProductColor(String productId) {
    // Uses hash code to consistently assign a color based on the product ID string
    final int hash = productId.hashCode;
    final int index = hash % chartColors.length;
    return chartColors[index.abs()];
  }

  // Fallback method to load dummy forecast data when API is unavailable
  void _loadFallbackForecastData() {
    if (kDebugMode) {
      print("🔄 Loading fallback forecast data for testing");
    }

    final now = DateTime.now();
    final productIds = ["P0001", "P0002", "P0003", "P0004", "P0005"];
    Map<String, List<FlSpot>> fallbackSpots = {};
    List<String> dates = [];

    // Generate 7 days of forecast data
    for (int i = 0; i < 7; i++) {
      final date = now.add(Duration(days: i));
      dates.add(date.toIso8601String().substring(0, 10));
    }

    // Generate wavy, random-looking forecast data for each product with higher values for better visibility
    for (final productId in productIds) {
      List<FlSpot> spots = [];
      for (int i = 0; i < 7; i++) {
        final baseValue = 60 + (productId.hashCode % 30); // Higher base values (60-90)
        // Use a combination of sine wave and random noise for a wavy effect
        final sineWave = sin((i / 6) * pi * 2) * 20; // Increased amplitude for more variation
        final noise = Random().nextInt(15) - 7; // Random noise between -7 and 8
        final value = (baseValue + sineWave + noise).clamp(40, 120).toDouble(); // Higher range (40-120)
        spots.add(FlSpot(i.toDouble(), value));
      }
      fallbackSpots[productId] = spots;
    }

    _groupedForecastSpots = fallbackSpots;
    _forecastDates = dates;

    if (kDebugMode) {
      print("✅ Fallback forecast data loaded with ${fallbackSpots.length} products");
    }
  }


  Future<void> fetchData() async {
    setState(() {
      _isLoading = true;
      _groupedForecastSpots = {};
      _forecastDates = [];
      _overallKpis = null;
    });
    try {
      // --- RESTRUCTURED: Use Future.wait for concurrent API calls ---
      await Future.wait([
        // 1. Fetch Recommendations (High/Low Selling)
        http.get(Uri.parse("$baseUrl/ml-data/recommendations")).then((response) {
          if (response.statusCode == 200 && response.body.isNotEmpty) {
            final data = json.decode(response.body);
            final high = List<Map<String, dynamic>>.from(data['high'] ?? []);
            final low = List<Map<String, dynamic>>.from(data['low'] ?? []);

            final highMapped = high.map((item) => {
                "product_name": item["product"] ?? "Unknown",
                "sales_units_30d": item["sales"] ?? "N/A",
                "rank": item["category"] ?? "-",
              }).toList();

            final lowMappedForRecs = low.map((item) => {
                "product_name": item["product"] ?? "Unknown",
                "reason": item["reason"] ?? "No reason provided",
              }).toList();

            _productData = highMapped.take(5).toList();
            _recommendations = lowMappedForRecs.take(5).toList();
            _restockAlerts = low.take(5).toList();
          }
        }),

        // 2. Fetch Forecast Data
        () async {
          try {
            final specificProductIds = ["P0001", "P0002", "P0003", "P0004", "P0005"];
            if (specificProductIds.isNotEmpty) {
              final forecastUrl = Uri.parse("$baseUrl/forecast/demand/");
              final forecastBody = jsonEncode({
                "store_id": storeId,
                "user_id": 1,
                "product_ids": specificProductIds,
                "forecast_start_date": DateTime.now().toIso8601String().substring(0, 10),
                "forecast_days": 7
              });

              if (kDebugMode) {
                print("🌐 Fetching forecast from: $forecastUrl");
                print("📦 Request body: $forecastBody");
              }

              final response = await http.post(
                forecastUrl,
                headers: {"Content-Type": "application/json"},
                body: forecastBody
              ).timeout(const Duration(seconds: 10));

              if (kDebugMode) {
                print("📊 Forecast response status: ${response.statusCode}");
                print("📄 Forecast response body: ${response.body}");
              }

              if (response.statusCode == 200) {
                final decodedData = json.decode(response.body);
                if (decodedData is List && decodedData.isNotEmpty) {
                  final allForecastPoints = List<Map<String, dynamic>>.from(decodedData);
                  final groupedByProduct = groupBy(allForecastPoints, (Map<String, dynamic> item) => item['product_id']);

                  Map<String, List<FlSpot>> newGroupedSpots = {};
                  List<String> dates = [];

                  groupedByProduct.forEach((productId, points) {
                    points.sort((a, b) => a['forecast_date'].compareTo(b['forecast_date']));
                    final spots = points.asMap().entries.map((entry) {
                      final index = entry.key;
                      final pointData = entry.value;
                      final value = (pointData["forecasted_units_sold"] ?? 0).toDouble();
                      if (productId == groupedByProduct.keys.first) {
                        dates.add(pointData['forecast_date']);
                      }
                      return FlSpot(index.toDouble(), value);
                    }).toList();
                    newGroupedSpots[productId] = spots;
                  });
                  _groupedForecastSpots = newGroupedSpots;
                  _forecastDates = dates;

                  if (kDebugMode) {
                    print("✅ Forecast data loaded successfully for ${newGroupedSpots.length} products");
                  }
                } else {
                  if (kDebugMode) {
                    print("⚠️ Forecast API returned empty or invalid data");
                  }
                  _loadFallbackForecastData();
                }
              } else {
                if (kDebugMode) {
                  print("❌ Forecast API error: ${response.statusCode} - ${response.body}");
                }
                _loadFallbackForecastData();
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print("❌ Error fetching forecast data: $e");
            }
            _loadFallbackForecastData();
          }
        }(),

        // 3. Fetch Overall Analytics KPIs
        http.get(Uri.parse("$baseUrl/analytics/$storeId")).then((response) {
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            _overallKpis = data['kpis_overall'];
            _salesTrendData = List<Map<String, dynamic>>.from(data["sales_trend_data"]);
          }
        }),
      ]);
    } catch (e) {
      if (kDebugMode) {
        print("❌ Final Error fetching data: $e");
      }
    } finally {
      // This will now only be called after all futures in Future.wait have completed.
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              color: Colors.white,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Sales Overview",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 16), // Add some space before buttons
                    Row(
                      children: [
                        _headerButton(context, "Daily", const AnalyticsPeriodPage(
                          title: "Daily Analytics",
                          periodKey: "kpis_daily",
                          storeId: "S1001", // Hardcoded for now
                        )),
                        const SizedBox(width: 8),
                        _headerButton(context, "Weekly", const AnalyticsPeriodPage(
                          title: "Weekly Analytics",
                          periodKey: "kpis_weekly",
                          storeId: "S1001",
                        )),
                        const SizedBox(width: 8),
                        _headerButton(
                          context,
                          "Monthly",
                          const AnalyticsPeriodPage(
                            title: "Monthly Analytics",
                            periodKey: "kpis_monthly",
                            storeId: "S1001",
                          )),
                        const SizedBox(width: 8),
                        _headerButton(context, "Overall", null, selected: true),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
                color: Colors.grey[100],
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // --- MODIFIED: Stat cards now use data from the API ---
                        _statCard(
                            "Total Revenue",
                            "₹${(_overallKpis?['total_revenue_inr']?['value'] ?? 0).toStringAsFixed(0)}",
                            Colors.green),
                        _statCard(
                            "Total Sales Count",
                            "${(_overallKpis?['total_sales_count']?['value'] ?? 0).toStringAsFixed(0)}",
                            Colors.blue),
                        _statCard(
                            "Total Units Sold",
                            "${(_overallKpis?['total_units_sold']?['value'] ?? 0).toStringAsFixed(0)}",
                            Colors.orange),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Use LayoutBuilder for a responsive grid
                    LayoutBuilder(
                      builder: (context, constraints) {
                        // Get screen information for Samsung device optimization
                        final mediaQuery = MediaQuery.of(context);
                        final screenHeight = mediaQuery.size.height;
                        final isSamsungLike = screenHeight > 800 && screenHeight < 1200;

                        // For mobile screens, use a single column.
                        bool isMobile = constraints.maxWidth < 600;
                        int crossAxisCount = isMobile ? 1 : 2;
                        // Adjust aspect ratio for single vs double column - more conservative for Samsung
                        double childAspectRatio = isSamsungLike
                            ? (isMobile ? 1.1 : 1.4)  // More height for Samsung
                            : (isMobile ? 0.9 : 1.2);
                        return GridView.count(
                          shrinkWrap: true, // Make GridView work inside SingleChildScrollView
                          physics: const NeverScrollableScrollPhysics(), // Disable GridView's own scrolling
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: isSamsungLike ? 20 : 16, // More spacing for Samsung
                          mainAxisSpacing: isSamsungLike ? 20 : 16, // More spacing for Samsung
                          childAspectRatio: childAspectRatio,
                          children: [
                            _chartCard("Forecast (Next 7 Days)",
                                "Generate Updated Forecast", _isLoading),
                            _recommendationsCard(_recommendations),
                            _tableCard(
                                "High-Selling Products (Performance)",
                                _productData),
                            _restockCard(_restockAlerts),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- REFACTORED _chartCard to be more robust and avoid layout errors ---
  Widget _chartCard(String title, String buttonText, bool loading) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      // Use a LayoutBuilder to get the available height and prevent overflow
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Get screen information for Samsung device optimization
          final mediaQuery = MediaQuery.of(context);
          final screenHeight = mediaQuery.size.height;
          final isSamsungLike = screenHeight > 800 && screenHeight < 1200; // Common Samsung screen heights

          // More conservative height calculation for Samsung devices
          // Account for padding (32 total), title height (~24), spacing (8), legend height (~40), button height (~48)
          final double paddingHeight = isSamsungLike ? 40 : 32; // More padding for Samsung
          final double titleHeight = 28; // Slightly more for Samsung
          final double spacingHeight = 12; // More spacing for Samsung
          final double legendHeight = 50; // More space for legend on Samsung
          final double buttonHeight = 56; // Larger button on Samsung
          final double otherElementsHeight = paddingHeight + titleHeight + spacingHeight + legendHeight + buttonHeight;

          // More conservative chart height allocation for Samsung devices - increased bottom margin to prevent overlap
          final double availableHeight = constraints.maxHeight - otherElementsHeight;
          final double minChartHeight = isSamsungLike ? 180 : 150; // Higher minimum for Samsung
          final double maxChartHeight = isSamsungLike ? availableHeight * 0.5 : availableHeight * 0.6; // More conservative for Samsung to prevent bottom overlap
          final double chartHeight = availableHeight > minChartHeight ? maxChartHeight.clamp(minChartHeight, availableHeight - 24) : minChartHeight; // Subtract 24px for bottom overlap fix

          return Padding(
            padding: EdgeInsets.all(isSamsungLike ? 20 : 16), // More padding for Samsung
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: isSamsungLike ? 18 : 16, fontWeight: FontWeight.bold)), // Larger title for Samsung
                  SizedBox(height: isSamsungLike ? 12 : 8), // More spacing for Samsung
                  // Chart Area with calculated height to prevent overflow
                  SizedBox(
                    height: chartHeight,
                    child: loading
                        ? const Center(child: CircularProgressIndicator())
                        : _groupedForecastSpots.isEmpty
                            ? const Center(child: Text("📊 No forecast data available"))
                            : LineChart(
                                LineChartData(
                                  gridData: FlGridData(show: true),
                                  borderData: FlBorderData(show: true),
                                  titlesData: FlTitlesData(
                                    show: true,
                                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    rightTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 40, // Increased reserved size
                                        getTitlesWidget: (double value, TitleMeta meta) {
                                          return SideTitleWidget(
                                            axisSide: meta.axisSide,
                                            space: 4.0,
                                            child: Text(value.toInt().toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                          );
                                        },
                                      ),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 35, // Increased reserved size
                                        interval: 1,
                                        getTitlesWidget: (double value, meta) {
                                          int index = value.toInt();
                                          if (index < 0 || index >= _forecastDates.length) return const SizedBox();
                                          final date = _forecastDates[index].substring(8, 10);
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 8.0),
                                            child: SideTitleWidget(
                                              axisSide: meta.axisSide,
                                              space: 4.0,
                                              child: Text(date, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  lineBarsData: _groupedForecastSpots.entries.map((entry) {
                                    return LineChartBarData(
                                      isCurved: true,
                                      color: _getProductColor(entry.key),
                                      barWidth: 3,
                                      spots: entry.value,
                                      // MODIFIED: Show a gradient fill below the line for a "wavy" look
                                      belowBarData: BarAreaData(
                                        show: true,
                                        gradient: LinearGradient(
                                          colors: [
                                            _getProductColor(entry.key).withOpacity(0.3),
                                            _getProductColor(entry.key).withOpacity(0.0),
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                      ),
                                      dotData: const FlDotData(show: false),
                                    );
                                  }).toList(),
                                ),
                              ),
                  ),
                  // MODIFIED: Replaced Spacer with a flexible SizedBox for more stable layout
                  const SizedBox(height: 8),
                  // Legend
                  Wrap(
                    spacing: isSamsungLike ? 12.0 : 8.0, // More spacing for Samsung
                    runSpacing: isSamsungLike ? 6.0 : 4.0, // More spacing for Samsung
                    children: _groupedForecastSpots.keys.take(5).map((productId) {
                      return Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(width: isSamsungLike ? 12 : 10, height: isSamsungLike ? 12 : 10, decoration: BoxDecoration(color: _getProductColor(productId), shape: BoxShape.circle)), // Larger legend dots for Samsung
                        SizedBox(width: isSamsungLike ? 6 : 4), // More spacing for Samsung
                        Text(productId, style: TextStyle(fontSize: isSamsungLike ? 11 : 10)), // Larger text for Samsung
                      ]);
                    }).toList(),
                  ),
                  SizedBox(height: isSamsungLike ? 12 : 8), // More spacing for Samsung
                  // Button
                  SizedBox(
                    width: double.infinity,
                    height: isSamsungLike ? 50 : 48, // Larger button for Samsung
                    child: ElevatedButton(
                      onPressed: fetchData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: isSamsungLike ? 12 : 8), // More padding for Samsung
                      ),
                      child: Text(buttonText, style: TextStyle(fontSize: isSamsungLike ? 16 : 14)), // Larger text for Samsung
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }


  // Omitted helper widgets (Unchanged from original request)

  Widget _headerButton(BuildContext context, String text, Widget? page,
      {bool selected = false}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: selected ? Colors.deepPurple : Colors.white,
        foregroundColor: selected ? Colors.white : Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      onPressed: page != null
          ? () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => page));
            }
          : () {},
      child: Text(text),
    );
  }

  Widget _statCard(String title, String value, Color valueColor) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 8),
              Text(value,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple)), // Kept deepPurple for consistency, but you could use valueColor
            ],
          ),
        ),
      ),
    );
  }

  Widget _recommendationsCard(List<Map<String, dynamic>> recs) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Next Week Recommendations",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            // Use Flexible instead of Expanded to prevent overflow
            Flexible(
              child: ListView.builder(
                itemCount: recs.length,
                itemBuilder: (context, index) {
                  final rec = recs[index];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.trending_up, color: Colors.deepPurple),
                    title: Text(rec["product_name"] ?? "Unnamed Product"),
                    subtitle: Text(rec["reason"] ?? "No reason available"),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tableCard(String title, List<Map<String, dynamic>> data) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(3),
                  1: FlexColumnWidth(2),
                  2: FlexColumnWidth(1.5)
                },
                border: TableBorder.symmetric(inside: BorderSide(color: Colors.grey.shade200)),
                children: data
                    .map((row) => TableRow(children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            // The text will wrap automatically within the column width
                            child: Text(row["product_name"] ?? "N/A"),
                          ),
                          Padding(padding: const EdgeInsets.all(8.0), child: Text("${row["sales_units_30d"] ?? "-"}")),
                          Padding(padding: const EdgeInsets.all(8.0), child: Text("${row["rank"] ?? "-"}")),
                        ]))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _restockCard(List<Map<String, dynamic>> recs) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Restock & Low Stock Recommendations",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // ✅ Use Flexible instead of Expanded to prevent overflow inside Card
            Flexible(
              child: recs.isEmpty
                  ? const Text(
                      "No low-stock or restock recommendations available.",
                      style: TextStyle(color: Colors.grey),
                    )
                  : ListView.builder(
                      itemCount: recs.length,
                      itemBuilder: (context, index) {
                        final rec = recs[index];
                        return ListTile(
                          leading: const Icon(Icons.warning_amber_rounded,
                              color: Colors.deepOrange),
                          title: Text(rec["product"] ?? rec["product_name"] ?? "Unnamed Product"), // Use 'product' or fallback
                          subtitle: Text(
                            rec["reason"] ?? "Low stock or zero sales.",
                            style: const TextStyle(color: Colors.black87),
                          ),
                        );
                      },
                    ),
            ),

            const Divider(),
            Text(
              "${recs.length} products flagged for restock or low stock this week.",
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}