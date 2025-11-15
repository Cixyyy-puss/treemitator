import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyC31lX9YyAF6DrYuBm3GvMEM0lYrQ5dBH4',
      appId: '1:970810672437:android:e61cf34240f952b79d387c',
      messagingSenderId: '970810672437',
      projectId: 'treemitator',
      databaseURL:
          'https://treemitator-default-rtdb.asia-southeast1.firebasedatabase.app',
      storageBucket: 'treemitator.firebasestorage.app',
    ),
  );
  runApp(const TreemitatorBloomApp());
}

class TreemitatorBloomApp extends StatelessWidget {
  const TreemitatorBloomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Treemitator BLOOM',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: const Color(0xFF4CAF50),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF4CAF50),
          secondary: Color(0xFF8BC34A),
        ),
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Sensor Data Model
class SensorData {
  final double temperature;
  final double humidity;
  final double airPressure;
  final double oxygen;
  final double co2;
  final int vocIndex;
  final String timestamp;
  final DateTime dateTime;

  SensorData({
    this.temperature = 0.0,
    this.humidity = 0.0,
    this.airPressure = 0.0,
    this.oxygen = 0.0,
    this.co2 = 0.0,
    this.vocIndex = 0,
    String? timestamp,
    DateTime? dateTime,
  }) : timestamp = timestamp ?? DateFormat('hh:mm:ss a').format(DateTime.now()),
       dateTime = dateTime ?? DateTime.now();

  factory SensorData.fromMap(Map<dynamic, dynamic> map) {
    return SensorData(
      temperature: (map['Temperature'] ?? 0).toDouble(),
      humidity: (map['Humidity'] ?? 0).toDouble(),
      airPressure: (map['Pressure'] ?? 0).toDouble(),
      oxygen: ((map['Oxygen'] ?? map['O2'] ?? 0) as num).toDouble(),
      co2: ((map['CO2'] ?? 0) as num).toDouble(),
      vocIndex: (map['VOC_Index'] ?? 0).toInt(),
      timestamp: DateFormat('hh:mm:ss a').format(DateTime.now()),
      dateTime: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'airPressure': airPressure,
      'oxygen': oxygen,
      'co2': co2,
      'vocIndex': vocIndex,
      'timestamp': timestamp,
      'dateTime': dateTime.toIso8601String(),
    };
  }

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      temperature: json['temperature'],
      humidity: json['humidity'],
      airPressure: json['airPressure'],
      oxygen: json['oxygen'],
      co2: json['co2'],
      vocIndex: json['vocIndex'],
      timestamp: json['timestamp'],
      dateTime: DateTime.parse(json['dateTime']),
    );
  }
}

// Sensor View Model
class SensorViewModel extends ChangeNotifier {
  SensorData _latestSensorData = SensorData();
  final List<SensorData> _sensorHistory = [];
  int _lastUpdateTimeMillis = 0;
  bool _isConnected = false;

  SensorData get latestSensorData => _latestSensorData;
  List<SensorData> get sensorHistory => _sensorHistory;
  int get lastUpdateTimeMillis => _lastUpdateTimeMillis;
  bool get isConnected => _isConnected;

  final DatabaseReference _database = FirebaseDatabase.instance.ref('Sensors');

  SensorViewModel() {
    _loadHistoricalData();
    _listenToSensorData();
    _startConnectionMonitor();
  }

  Future<void> _loadHistoricalData() async {
    // Data will persist in memory during app session
    // To add permanent storage, use shared_preferences or a local database
    notifyListeners();
  }

  Future<void> _saveHistoricalData() async {
    // Data will persist in memory during app session
    // To add permanent storage, use shared_preferences or a local database
  }

  void _startConnectionMonitor() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now().millisecondsSinceEpoch;
      _isConnected =
          _lastUpdateTimeMillis > 0 && (now - _lastUpdateTimeMillis) < 5000;
      notifyListeners();
    });
  }

  void _listenToSensorData() {
    _database.onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        _lastUpdateTimeMillis = DateTime.now().millisecondsSinceEpoch;
        _isConnected = true;

        final newData = SensorData.fromMap(data);
        _latestSensorData = newData;

        _sensorHistory.insert(0, newData);

        // Save data (currently in memory only)
        _saveHistoricalData();

        notifyListeners();
      }
    });
  }
}

// Splash Screen with Glowing Logo
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  String _displayText = '';
  late AnimationController _textController;
  late AnimationController _glowController;
  late Animation<double> _textAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _textAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_textController);
    _textController.forward();

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _animateText();

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    });
  }

  Future<void> _animateText() async {
    const fullText = 'Welcome to Treemitator';
    for (int i = 0; i <= fullText.length; i++) {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 100));
      setState(() {
        _displayText = fullText.substring(0, i);
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF121212), Color(0xFF388E3C)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Glowing Logo
              AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, child) {
                  return Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF4CAF50,
                          ).withValues(alpha: _glowAnimation.value * 0.8),
                          blurRadius: 40 * _glowAnimation.value,
                          spreadRadius: 10 * _glowAnimation.value,
                        ),
                        BoxShadow(
                          color: const Color(
                            0xFF8BC34A,
                          ).withValues(alpha: _glowAnimation.value * 0.6),
                          blurRadius: 60 * _glowAnimation.value,
                          spreadRadius: 20 * _glowAnimation.value,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset('assets/logo.png', fit: BoxFit.cover),
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
              FadeTransition(
                opacity: _textAnimation,
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Color(0xFFCCCCCC),
                      Colors.white,
                      Color(0xFFB8B8B8),
                    ],
                  ).createShader(bounds),
                  child: Text(
                    _displayText,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Main Screen with Bottom Navigation
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late final SensorViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = SensorViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        onNavigateToDashboard: () => setState(() => _selectedIndex = 1),
      ),
      DashboardScreen(viewModel: _viewModel),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF323232),
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

// Bubble Animation Widget
class BubbleAnimation extends StatefulWidget {
  const BubbleAnimation({super.key});

  @override
  State<BubbleAnimation> createState() => _BubbleAnimationState();
}

class _BubbleAnimationState extends State<BubbleAnimation>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  late List<double> _leftPositions;

  @override
  void initState() {
    super.initState();
    _controllers = [];
    _animations = [];
    _leftPositions = [];

    for (int i = 0; i < 5; i++) {
      final controller = AnimationController(
        duration: Duration(milliseconds: 2000 + (i * 500)),
        vsync: this,
      )..repeat();

      final animation = Tween<double>(
        begin: 1.0,
        end: 0.0,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));

      _controllers.add(controller);
      _animations.add(animation);
      _leftPositions.add((i * 40.0) + 20.0);

      Future.delayed(Duration(milliseconds: i * 400), () {
        if (mounted) controller.forward();
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(_animations.length, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Positioned(
              left: _leftPositions[index],
              bottom: _animations[index].value * 180,
              child: Opacity(
                opacity: _animations[index].value * 0.6,
                child: Container(
                  width: 8 + (index * 2.0),
                  height: 8 + (index * 2.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.5),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

// Home Screen with Larger Product Image and Bubble Animation
class HomeScreen extends StatelessWidget {
  final VoidCallback onNavigateToDashboard;

  const HomeScreen({super.key, required this.onNavigateToDashboard});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        color: const Color(0xFF121212),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Text(
              'IoT Monitor',
              style: TextStyle(color: Color(0xFFADADAD), fontSize: 18),
            ),
            const SizedBox(height: 32),
            Container(
              width: 230,
              height: 230,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Bubble animation
                    const SizedBox(
                      width: 200,
                      height: 200,
                      child: BubbleAnimation(),
                    ),
                    // Product image
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.transparent,
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromRGBO(255, 255, 255, 0.30),
                            blurRadius: 20,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/product.png',
                          fit: BoxFit.contain,
                          width: 200,
                          height: 200,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Treemitator BLOOM',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Monitors Treemitator BLOOM in real-time. Track sensor readings with precision and a dynamic system.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFFADADAD), fontSize: 16),
              ),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8BC34A), Color(0xFF388E3C)],
                  ),
                ),
                child: ElevatedButton(
                  onPressed: onNavigateToDashboard,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'View Dashboard',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, color: Colors.black),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            _buildFeatureCard(
              'Real-Time Data',
              'Live sensor readings updated instantly from your Arduino devices',
              Icons.timeline,
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              'Analytics',
              'Shows data its readings over time in graphs',
              Icons.bar_chart,
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              'Secure',
              'Your sensor data is protected with enterprise-grade security',
              Icons.lock,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(String title, String description, IconData icon) {
    return Card(
      color: const Color(0xFF323232),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF4CAF50), size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Color(0xFFADADAD),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Dashboard Screen with Improved Analytics and Scrollable Data Log
class DashboardScreen extends StatefulWidget {
  final SensorViewModel viewModel;

  const DashboardScreen({super.key, required this.viewModel});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Timer _timer;
  int _timeSinceUpdate = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (widget.viewModel.lastUpdateTimeMillis > 0) {
        setState(() {
          _timeSinceUpdate =
              (DateTime.now().millisecondsSinceEpoch -
                  widget.viewModel.lastUpdateTimeMillis) ~/
              1000;
        });
      }
    });
    widget.viewModel.addListener(_onViewModelUpdate);
  }

  void _onViewModelUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _timer.cancel();
    widget.viewModel.removeListener(_onViewModelUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = widget.viewModel.isConnected;
    final data = widget.viewModel.latestSensorData;
    final history = widget.viewModel.sensorHistory;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Sensor Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Text(
          'Real-time monitoring of your Arduino IoT devices',
          style: TextStyle(color: Color(0xFFADADAD), fontSize: 14),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _buildSensorCard(
                'Temperature',
                '${data.temperature.toStringAsFixed(1)}°C',
                'Normal',
                Icons.device_thermostat,
                const Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSensorCard(
                'Humidity',
                '${data.humidity.toStringAsFixed(1)}%',
                'Normal',
                Icons.opacity,
                const Color(0xFF4CAF50),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSensorCard(
                'Oxygen (O2)',
                '${data.oxygen.toStringAsFixed(1)}% O2',
                'Normal',
                Icons.bubble_chart,
                const Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSensorCard(
                'VOC Index',
                '${data.vocIndex} IAQ',
                'Normal',
                Icons.air,
                const Color(0xFF4CAF50),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSensorCard(
                'Carbon Dioxide(CO2)',
                '${data.co2.toStringAsFixed(0)} ppm',
                'Normal',
                Icons.cloud,
                const Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(child: SizedBox()),
          ],
        ),
        const SizedBox(height: 32),
        const Text(
          'Data Analytics',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildAnalyticsCard(history),
        const SizedBox(height: 32),
        const Text(
          'Data Log (Latest 10 Readings)',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildScrollableDataLog(history, data),
        const SizedBox(height: 32),
        const Text(
          'System Status',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildSystemStatusCard(isConnected),
      ],
    );
  }

  Widget _buildSensorCard(
    String title,
    String value,
    String status,
    IconData icon,
    Color iconColor,
  ) {
    return Card(
      color: const Color(0xFF323232),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.5)),
      ),
      elevation: 12,
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              status,
              style: const TextStyle(color: Color(0xFFADADAD), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard(List<SensorData> history) {
    final displayData = history.length > 50 ? history.sublist(0, 50) : history;

    return Card(
      color: const Color(0xFF323232),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildLegendItem(const Color(0xFF8BC34A), 'Temperature'),
                  const SizedBox(width: 12),
                  _buildLegendItem(const Color(0xFF61D4FF), 'Humidity'),
                  const SizedBox(width: 12),
                  _buildLegendItem(Colors.grey, 'VOC Index'),
                  const SizedBox(width: 12),
                  _buildLegendItem(const Color(0xFFFFC107), 'Oxygen (O2)'),
                  const SizedBox(width: 12),
                  _buildLegendItem(const Color(0xFFFF7043), 'CO2'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: displayData.isEmpty
                  ? const Center(
                      child: Text(
                        'No data available',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 20,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.white.withValues(alpha: 0.1),
                              strokeWidth: 1,
                            );
                          },
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                );
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              interval: 10,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() >= displayData.length) {
                                  return const SizedBox();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    (displayData.length - value.toInt())
                                        .toString(),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        minX: 0,
                        maxX: (displayData.length - 1).toDouble(),
                        minY: 0,
                        maxY: 100,
                        lineTouchData: LineTouchData(
                          enabled: true,
                          touchTooltipData: LineTouchTooltipData(
                            tooltipBgColor: Colors.black87,
                            tooltipRoundedRadius: 8,
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((spot) {
                                String label = '';
                                if (spot.barIndex == 0) label = 'Temp';
                                if (spot.barIndex == 1) label = 'Humid';
                                if (spot.barIndex == 2) label = 'VOC';
                                if (spot.barIndex == 3) label = 'O2';
                                if (spot.barIndex == 4) label = 'CO2';

                                return LineTooltipItem(
                                  '$label: ${spot.y.toStringAsFixed(1)}',
                                  const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              }).toList();
                            },
                          ),
                        ),
                        lineBarsData: [
                          _buildLineChartBarData(
                            displayData.reversed.toList(),
                            (data) => data.temperature,
                            const Color(0xFF8BC34A),
                          ),
                          _buildLineChartBarData(
                            displayData.reversed.toList(),
                            (data) => data.humidity,
                            const Color(0xFF61D4FF),
                          ),
                          _buildLineChartBarData(
                            displayData.reversed.toList(),
                            (data) => data.vocIndex.toDouble(),
                            Colors.grey,
                          ),
                          _buildLineChartBarData(
                            displayData.reversed.toList(),
                            (data) => data.oxygen,
                            const Color(0xFFFFC107),
                          ),
                          _buildLineChartBarData(
                            displayData.reversed.toList(),
                            (data) => data.co2 / 10,
                            const Color(0xFFFF7043),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  LineChartBarData _buildLineChartBarData(
    List<SensorData> data,
    double Function(SensorData) getValue,
    Color color,
  ) {
    return LineChartBarData(
      spots: data
          .asMap()
          .entries
          .map((e) => FlSpot(e.key.toDouble(), getValue(e.value)))
          .toList(),
      isCurved: true,
      color: color,
      barWidth: 3,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          return FlDotCirclePainter(radius: 2, color: color, strokeWidth: 0);
        },
      ),
      belowBarData: BarAreaData(
        show: true,
        color: color.withValues(alpha: 0.1),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
      ],
    );
  }

  Widget _buildScrollableDataLog(
    List<SensorData> history,
    SensorData currentData,
  ) {
    final displayLogs = history.take(10).toList();

    return Card(
      color: const Color(0xFF323232),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 400),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildDataLogHeader(),
            ),
            const Divider(color: Colors.grey, height: 1),
            Expanded(
              child: displayLogs.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'No data available',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: displayLogs.length,
                      separatorBuilder: (context, index) => Divider(
                        color: Colors.grey.withValues(alpha: 0.2),
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final log = displayLogs[index];
                        final isLatest = log == currentData;
                        return _buildDataLogRow(log, isLatest);
                      },
                    ),
            ),
            if (history.length > 10)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.arrow_downward,
                      color: Color(0xFFADADAD),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${history.length - 10} more readings available',
                      style: const TextStyle(
                        color: Color(0xFFADADAD),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataLogHeader() {
    return Row(
      children: const [
        Expanded(
          flex: 3,
          child: Text(
            'Time',
            style: TextStyle(
              color: Color(0xFFADADAD),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            'Temp',
            textAlign: TextAlign.end,
            style: TextStyle(
              color: Color(0xFFADADAD),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            'Humid',
            textAlign: TextAlign.end,
            style: TextStyle(
              color: Color(0xFFADADAD),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            'VOC',
            textAlign: TextAlign.end,
            style: TextStyle(
              color: Color(0xFFADADAD),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            'O2',
            textAlign: TextAlign.end,
            style: TextStyle(
              color: Color(0xFFADADAD),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            'CO2',
            textAlign: TextAlign.end,
            style: TextStyle(
              color: Color(0xFFADADAD),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDataLogRow(SensorData log, bool isLatest) {
    return Container(
      decoration: BoxDecoration(
        color: isLatest
            ? const Color(0xFF4CAF50).withValues(alpha: 0.15)
            : Colors.transparent,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.timestamp,
                  style: TextStyle(
                    color: isLatest ? const Color(0xFF4CAF50) : Colors.white,
                    fontSize: 13,
                    fontWeight: isLatest ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (isLatest)
                  const Text(
                    'Latest',
                    style: TextStyle(color: Color(0xFF4CAF50), fontSize: 10),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${log.temperature.toStringAsFixed(1)}°',
              textAlign: TextAlign.end,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${log.humidity.toStringAsFixed(1)}%',
              textAlign: TextAlign.end,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              log.vocIndex.toString(),
              textAlign: TextAlign.end,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              log.oxygen.toStringAsFixed(1),
              textAlign: TextAlign.end,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              log.co2.toStringAsFixed(0),
              textAlign: TextAlign.end,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemStatusCard(bool isConnected) {
    final connectionColor = isConnected ? const Color(0xFF4CAF50) : Colors.red;
    final lastUpdate = widget.viewModel.lastUpdateTimeMillis == 0
        ? 'Never'
        : _timeSinceUpdate < 60
        ? '${_timeSinceUpdate}s ago'
        : '${_timeSinceUpdate ~/ 60}m ago';

    final activeSensors = isConnected ? '5/5' : '0/5';

    return Card(
      color: const Color(0xFF323232),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Connection',
                  style: TextStyle(color: Color(0xFFADADAD), fontSize: 16),
                ),
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: connectionColor,
                        shape: BoxShape.circle,
                        boxShadow: isConnected
                            ? [
                                BoxShadow(
                                  color: connectionColor.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isConnected ? 'Connected' : 'Disconnected',
                      style: TextStyle(
                        color: connectionColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Divider(color: Colors.grey.withValues(alpha: 0.3)),
            _buildStatusRow('Last Update', lastUpdate),
            Divider(color: Colors.grey.withValues(alpha: 0.3)),
            _buildStatusRow('Active Sensors', activeSensors),
            Divider(color: Colors.grey.withValues(alpha: 0.3)),
            _buildStatusRow(
              'Total Readings',
              widget.viewModel.sensorHistory.length.toString(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFFADADAD), fontSize: 16),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// Settings Screen
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _alertOnWarnings = true;
  bool _connectionAlerts = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF121212),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          const Text(
            'Settings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Customize your dashboard experience',
            style: TextStyle(color: Color(0xFFADADAD), fontSize: 14),
          ),
          const SizedBox(height: 32),
          _buildSettingsGroup(
            'Data Refresh Rate',
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Real-time', style: TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingsGroup(
            'Notifications',
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Alert on sensor warnings',
                        style: TextStyle(color: Colors.white),
                      ),
                      Switch(
                        value: _alertOnWarnings,
                        onChanged: (value) =>
                            setState(() => _alertOnWarnings = value),
                        activeThumbColor: const Color(0xFF4CAF50),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Connection status alerts',
                        style: TextStyle(color: Colors.white),
                      ),
                      Switch(
                        value: _connectionAlerts,
                        onChanged: (value) =>
                            setState(() => _connectionAlerts = value),
                        activeThumbColor: const Color(0xFF4CAF50),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text(
            title,
            style: const TextStyle(color: Color(0xFFADADAD), fontSize: 12),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          color: const Color(0xFF323232),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: content,
        ),
      ],
    );
  }
}
