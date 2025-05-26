import 'dart:async';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/supabase_service.dart';
import 'package:intl/intl.dart';
import 'notifications_screen.dart';
import '../models/environment_reading.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'sign_in_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  List<Product> products = [];
  String? error;
  bool loading = false;
  bool backgroundLoading = false;
  int unreadNotificationCount = 0;
  Product? editingProduct;
  late final SupabaseService supabaseService;
  late final TextEditingController nameController;
  late final TextEditingController quantityController;
  late final TextEditingController thresholdController;
  late final TextEditingController expiredDateController;
  String section = 'A';
  bool dialogLoading = false;
  Timer? _refreshTimer;
  EnvironmentReading? latestReading;

  @override
  void initState() {
    super.initState();
    supabaseService = SupabaseService();
    nameController = TextEditingController();
    quantityController = TextEditingController();
    thresholdController = TextEditingController();
    expiredDateController = TextEditingController();
    fetchProducts();
    fetchUnreadNotificationCount();
    fetchLatestEnvironmentReading();
    // Set up periodic refresh every 5 seconds (background)
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && !backgroundLoading) {
        fetchProducts(background: true);
        fetchUnreadNotificationCount();
        fetchLatestEnvironmentReading();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    nameController.dispose();
    quantityController.dispose();
    thresholdController.dispose();
    expiredDateController.dispose();
    super.dispose();
  }

  Future<void> fetchProducts({bool background = false}) async {
    if (loading || backgroundLoading) return;
    if (background) {
      setState(() => backgroundLoading = true);
    } else {
      setState(() => loading = true);
    }
    try {
      final data = await supabaseService.fetchProducts();
      if (mounted) {
        setState(() {
          products = data;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => error = e.toString());
      }
    } finally {
      if (mounted) {
        if (background) {
          setState(() => backgroundLoading = false);
        } else {
          setState(() => loading = false);
        }
      }
    }
  }

  Future<void> fetchUnreadNotificationCount() async {
    final count = await supabaseService.getUnreadNotificationCount();
    if (mounted) {
      setState(() {
        unreadNotificationCount = count;
      });
    }
  }

  Future<void> fetchLatestEnvironmentReading() async {
    final reading = await supabaseService.fetchLatestEnvironmentReading();
    if (mounted) {
      setState(() {
        latestReading = reading;
      });
    }
  }

  void openDialog([Product? product]) {
    editingProduct = product;
    nameController.text = product?.name ?? '';
    quantityController.text = product?.quantity.toString() ?? '';
    thresholdController.text = product?.threshold.toString() ?? '';
    expiredDateController.text = product?.expiredDate ?? '';
    section = product?.section ?? 'A';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product == null ? 'Add Product' : 'Edit Product'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: thresholdController,
                decoration: const InputDecoration(labelText: 'Threshold'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: expiredDateController,
                decoration: const InputDecoration(
                    labelText: 'Expired Date (YYYY-MM-DD)'),
                onTap: () async {
                  FocusScope.of(context).requestFocus(FocusNode());
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    expiredDateController.text =
                        picked.toIso8601String().split('T').first;
                  }
                },
              ),
              DropdownButtonFormField<String>(
                value: section,
                items: const [
                  DropdownMenuItem(value: 'A', child: Text('A')),
                  DropdownMenuItem(value: 'B', child: Text('B')),
                  DropdownMenuItem(value: 'C', child: Text('C')),
                ],
                onChanged: (val) => setState(() => section = val ?? 'A'),
                decoration: const InputDecoration(labelText: 'Section'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: dialogLoading
                ? null
                : () async {
                    setState(() => dialogLoading = true);
                    try {
                      if (product == null) {
                        await supabaseService.addProduct(
                          Product(
                            id: '',
                            name: nameController.text,
                            quantity:
                                int.tryParse(quantityController.text) ?? 0,
                            threshold:
                                int.tryParse(thresholdController.text) ?? 0,
                            expiredDate: expiredDateController.text.isEmpty
                                ? null
                                : expiredDateController.text,
                            section: section,
                            createdAt: '',
                            lastNotifiedQuantity: null,
                          ),
                        );
                      } else {
                        await supabaseService.updateProduct(
                          product,
                          Product(
                            id: product.id,
                            name: nameController.text,
                            quantity:
                                int.tryParse(quantityController.text) ?? 0,
                            threshold:
                                int.tryParse(thresholdController.text) ?? 0,
                            expiredDate: expiredDateController.text.isEmpty
                                ? null
                                : expiredDateController.text,
                            section: section,
                            createdAt: product.createdAt,
                            lastNotifiedQuantity: product.lastNotifiedQuantity,
                          ),
                        );
                      }
                      Navigator.of(context).pop();
                      fetchProducts();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    } finally {
                      setState(() => dialogLoading = false);
                    }
                  },
            child: Text(product == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  void confirmDelete(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await supabaseService.deleteProduct(product.id);
                Navigator.of(context).pop();
                fetchProducts();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Delete'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('yyyy-MM-dd').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loading ? null : () => fetchProducts(),
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () async {
                  setState(() {
                    unreadNotificationCount = 0;
                  });
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const NotificationsScreen()),
                  );
                  if (result == 'refresh_badge') {
                    fetchUnreadNotificationCount();
                  }
                },
              ),
              if (unreadNotificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Center(
                      child: Text(
                        unreadNotificationCount > 99
                            ? '99+'
                            : unreadNotificationCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const SignInScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => openDialog(),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await fetchProducts();
          await fetchLatestEnvironmentReading();
        },
        child: loading && products.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : error != null
                ? Center(child: Text('Error: $error'))
                : products.isEmpty
                    ? const Center(child: Text('No products found.'))
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (loading && products.isNotEmpty)
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              ),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: DataTable(
                                  columnSpacing: 20,
                                  horizontalMargin: 12,
                                  columns: const [
                                    DataColumn(
                                      label: Text(
                                        'Name',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Qty',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      numeric: true,
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Threshold',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      numeric: true,
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Expired Date',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Section',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Created',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Actions',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                  rows: products.map((product) {
                                    final isLowStock =
                                        product.quantity < product.threshold;
                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          Container(
                                            constraints: const BoxConstraints(
                                                maxWidth: 150),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  product.name,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                if (isLowStock)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 4.0),
                                                    child: Text(
                                                      'Low Stock',
                                                      style: TextStyle(
                                                        color:
                                                            Colors.orange[800],
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            product.quantity.toString(),
                                            style: TextStyle(
                                              color: isLowStock
                                                  ? Colors.red
                                                  : null,
                                              fontWeight: isLowStock
                                                  ? FontWeight.bold
                                                  : null,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                            Text(product.threshold.toString())),
                                        DataCell(Text(
                                            formatDate(product.expiredDate))),
                                        DataCell(Text(product.section)),
                                        DataCell(
                                          Text(
                                            formatDate(product.createdAt),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit),
                                                onPressed: () =>
                                                    openDialog(product),
                                                constraints:
                                                    const BoxConstraints(),
                                                padding:
                                                    const EdgeInsets.all(8),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete),
                                                color: Colors.red,
                                                onPressed: () =>
                                                    confirmDelete(product),
                                                constraints:
                                                    const BoxConstraints(),
                                                padding:
                                                    const EdgeInsets.all(8),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                            // Gauges below the table
                            Padding(
                              padding: const EdgeInsets.only(top: 2.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Expanded(
                                    child: _buildGauge(
                                      label: 'Temperature',
                                      value: latestReading?.temperature,
                                      min: 0,
                                      max: 50,
                                      unit: '°C',
                                      color: Colors.orange,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildGauge(
                                      label: 'Humidity',
                                      value: latestReading?.humidity,
                                      min: 0,
                                      max: 100,
                                      unit: '%',
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
      ),
    );
  }

  Widget _buildGauge({
    required String label,
    double? value,
    required double min,
    required double max,
    required String unit,
    required Color color,
  }) {
    // Color segments for temperature and humidity
    List<Color> tempColors = [
      Colors.cyan,
      Colors.blue,
      Colors.purple,
      Colors.pink,
      Colors.red
    ];
    List<Color> humColors = [
      Colors.blue,
      Colors.cyan,
      Colors.green,
      Colors.yellow
    ];
    final isTemp = label.toLowerCase().contains('temp');
    final List<Color> arcColors = isTemp ? tempColors : humColors;
    final int segments = 20;
    final double segmentSize = (max - min) / segments;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final double gaugeWidth =
                constraints.maxWidth > 180 ? 180 : constraints.maxWidth;
            return SizedBox(
              width: gaugeWidth,
              height: 140,
              child: SfRadialGauge(
                axes: <RadialAxis>[
                  RadialAxis(
                    minimum: min,
                    maximum: max,
                    showLabels: false,
                    showTicks: false,
                    startAngle: 180,
                    endAngle: 0,
                    canScaleToFit: true,
                    axisLineStyle: const AxisLineStyle(
                      thickness: 0.18,
                      thicknessUnit: GaugeSizeUnit.factor,
                      cornerStyle: CornerStyle.bothCurve,
                    ),
                    pointers: <GaugePointer>[
                      RangePointer(
                        value: value ?? min,
                        width: 0.18,
                        sizeUnit: GaugeSizeUnit.factor,
                        gradient: SweepGradient(
                          colors: arcColors,
                          stops: [
                            for (int i = 0; i < arcColors.length; i++)
                              i / (arcColors.length - 1)
                          ],
                        ),
                        cornerStyle: CornerStyle.bothCurve,
                      ),
                    ],
                    annotations: <GaugeAnnotation>[
                      GaugeAnnotation(
                        widget: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              value != null
                                  ? '${value.toStringAsFixed(1)} $unit'
                                  : '--',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              label,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        angle: 90,
                        positionFactor: 0.1,
                      ),
                    ],
                    ranges: [
                      for (int i = 0; i < segments; i++)
                        GaugeRange(
                          startValue: min + i * segmentSize,
                          endValue: min + (i + 1) * segmentSize,
                          color: arcColors[(arcColors.length * i ~/ segments)
                              .clamp(0, arcColors.length - 1)],
                          startWidth: 0.18,
                          endWidth: 0.18,
                          sizeUnit: GaugeSizeUnit.factor,
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
