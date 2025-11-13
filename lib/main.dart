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
      databaseURL: 'https://treemitator-default-rtdb.asia-southeast1.firebasedatabase.app',
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
  final int vocIndex;
  final String timestamp;

  SensorData({
    this.temperature = 0.0,
    this.humidity = 0.0,
    this.airPressure = 0.0,
    this.vocIndex = 0,
    this.timestamp = '',
  });

  factory SensorData.fromMap(Map<dynamic, dynamic> map) {
    return SensorData(
      temperature: (map['Temperature'] ?? 0).toDouble(),
      humidity: (map['Humidity'] ?? 0).toDouble(),
      airPressure: (map['Pressure'] ?? 0).toDouble(),
      vocIndex: (map['VOC_Index'] ?? 0).toInt(),
      timestamp: DateFormat('hh:mm:ss a').format(DateTime.now()),
    );
  }
}

// Sensor View Model
class SensorViewModel extends ChangeNotifier {
  SensorData _latestSensorData = SensorData();
  final List<SensorData> _sensorHistory = [];
  int _lastUpdateTimeMillis = 0;

  SensorData get latestSensorData => _latestSensorData;
  List<SensorData> get sensorHistory => _sensorHistory;
  int get lastUpdateTimeMillis => _lastUpdateTimeMillis;

  final DatabaseReference _database = FirebaseDatabase.instance.ref('Sensors');

  SensorViewModel() {
    _listenToSensorData();
  }

  void _listenToSensorData() {
    _database.onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        _lastUpdateTimeMillis = DateTime.now().millisecondsSinceEpoch;
        
        final newData = SensorData.fromMap(data);
        _latestSensorData = newData;
        
        _sensorHistory.insert(0, newData);
        if (_sensorHistory.length > 100) {
          _sensorHistory.removeLast();
        }
        
        notifyListeners();
      }
    });
  }
}

// Splash Screen (Cover Page)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  String _displayText = '';
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();
    
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
    _controller.dispose();
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
          child: FadeTransition(
            opacity: _animation,
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFCCCCCC), Colors.white, Color(0xFFB8B8B8)],
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
      HomeScreen(onNavigateToDashboard: () => setState(() => _selectedIndex = 1)),
      DashboardScreen(viewModel: _viewModel),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF323232),
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// Home Screen
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
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    // replaced deprecated withOpacity -> withAlpha
                    Colors.white.withAlpha((0.1 * 255).round()),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Center(
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                    boxShadow: [
                      BoxShadow(
                        color: Color.fromRGBO(255, 255, 255, 0.30),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/product.png',
                        fit: BoxFit.contain,
                        width: 140,
                        height: 140,
                      ),
                    ),
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
                    style: const TextStyle(color: Color(0xFFADADAD), fontSize: 14),
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

// Dashboard Screen
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
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (widget.viewModel.lastUpdateTimeMillis > 0) {
        setState(() {
          _timeSinceUpdate = 
              (DateTime.now().millisecondsSinceEpoch - widget.viewModel.lastUpdateTimeMillis) ~/ 1000;
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
    final isConnected = _timeSinceUpdate < 5;
    final data = widget.viewModel.latestSensorData;
    final history = widget.viewModel.sensorHistory;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Sensor Dashboard',
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
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
                'Air Pressure',
                '${data.airPressure.toStringAsFixed(0)} hPa',
                'Normal',
                Icons.speed,
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
        const SizedBox(height: 32),
        const Text(
          'Data Analytics',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildAnalyticsCard(history),
        const SizedBox(height: 32),
        const Text(
          'Data Log',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildDataLogHeader(),
        const Divider(color: Colors.grey),
        ...history.map((log) => _buildDataLogRow(log, log == data)),
        const SizedBox(height: 16),
        const Text(
          'System Status',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildSystemStatusCard(isConnected),
      ],
    );
  }

  Widget _buildSensorCard(String title, String value, String status, IconData icon, Color iconColor) {
    return Card(
      color: const Color(0xFF323232),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.black.withAlpha((0.5 * 255).round())),
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
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
              ],
            ),
            Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
            ),
            Text(status, style: const TextStyle(color: Color(0xFFADADAD), fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard(List<SensorData> history) {
    return Card(
      color: const Color(0xFF323232),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                _buildLegendItem(const Color(0xFF8BC34A), 'Temperature'),
                const SizedBox(width: 16),
                _buildLegendItem(const Color(0xFF61D4FF), 'Humidity'),
                const SizedBox(width: 16),
                _buildLegendItem(Colors.grey, 'VOC Index'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: history.isEmpty
                  ? const Center(child: Text('No data available', style: TextStyle(color: Colors.grey)))
                  : LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          _buildLineChartBarData(
                            history.reversed.take(20).toList(),
                            (data) => data.temperature,
                            const Color(0xFF8BC34A),
                          ),
                          _buildLineChartBarData(
                            history.reversed.take(20).toList(),
                            (data) => data.humidity,
                            const Color(0xFF61D4FF),
                          ),
                          _buildLineChartBarData(
                            history.reversed.take(20).toList(),
                            (data) => data.vocIndex.toDouble(),
                            Colors.grey,
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
      barWidth: 2,
      dotData: const FlDotData(show: false),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
      ],
    );
  }

  Widget _buildDataLogHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text('Time', style: TextStyle(color: Color(0xFFADADAD), fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 2,
            child: Text('Temp', textAlign: TextAlign.end, style: TextStyle(color: Color(0xFFADADAD), fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 2,
            child: Text('Humid', textAlign: TextAlign.end, style: TextStyle(color: Color(0xFFADADAD), fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 2,
            child: Text('VOC', textAlign: TextAlign.end, style: TextStyle(color: Color(0xFFADADAD), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDataLogRow(SensorData log, bool isLatest) {
    return Container(
      decoration: BoxDecoration(
        color: isLatest ? Color(0xFF4CAF50).withAlpha((0.1 * 255).round()) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(log.timestamp, style: const TextStyle(color: Colors.white, fontSize: 14)),
          ),
          Expanded(
            flex: 2,
            child: Text('${log.temperature.toStringAsFixed(1)}°C', textAlign: TextAlign.end, style: const TextStyle(color: Colors.white, fontSize: 14)),
          ),
          Expanded(
            flex: 2,
            child: Text('${log.humidity.toStringAsFixed(1)}%', textAlign: TextAlign.end, style: const TextStyle(color: Colors.white, fontSize: 14)),
          ),
          Expanded(
            flex: 2,
            child: Text('${log.vocIndex}', textAlign: TextAlign.end, style: const TextStyle(color: Colors.white, fontSize: 14)),
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
                const Text('Connection', style: TextStyle(color: Color(0xFFADADAD), fontSize: 16)),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: connectionColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isConnected ? 'Connected' : 'Disconnected',
                      style: TextStyle(color: connectionColor, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            Divider(color: Colors.grey.withAlpha((0.3 * 255).round())),
            _buildStatusRow('Last Update', lastUpdate),
            Divider(color: Colors.grey.withAlpha((0.3 * 255).round())),
            _buildStatusRow('Active Sensors', '4/4'),
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
          Text(label, style: const TextStyle(color: Color(0xFFADADAD), fontSize: 16)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
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
              child: Text('3 seconds', style: TextStyle(color: Colors.white)),
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
                      const Text('Alert on sensor warnings', style: TextStyle(color: Colors.white)),
                      Switch(
                        value: _alertOnWarnings,
                        onChanged: (value) => setState(() => _alertOnWarnings = value),
                        activeThumbColor: const Color(0xFF4CAF50),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Connection status alerts', style: TextStyle(color: Colors.white)),
                      Switch(
                        value: _connectionAlerts,
                        onChanged: (value) => setState(() => _connectionAlerts = value),
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
          child: Text(title, style: const TextStyle(color: Color(0xFFADADAD), fontSize: 12)),
        ),
        const SizedBox(height: 8),
        Card(
          color: const Color(0xFF323232),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: content,
        ),
      ],
    );
  }
}