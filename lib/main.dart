import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

void main() => runApp(const WeatherApp());

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      theme: ThemeData(useMaterial3: true, primarySwatch: Colors.blue),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  Map<String, dynamic>? currentWeather;
  List<dynamic>? forecast;

  @override
  void initState() {
    super.initState();
    _fetchWeatherData();
  }

  Future<void> _fetchWeatherData() async {
    try {
      Position position = await _determinePosition();
      double lat = position.latitude;
      double lon = position.longitude;
      String apiKey = '94cb2be73bc6d3e70ba1316fa1213d5b';
      String currentUrl =
          'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&units=metric&appid=$apiKey';
      String forecastUrl =
          'https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&units=metric&appid=$apiKey';

      final currentRes = await http.get(Uri.parse(currentUrl));
      final forecastRes = await http.get(Uri.parse(forecastUrl));

      if (currentRes.statusCode == 200 && forecastRes.statusCode == 200) {
        setState(() {
          currentWeather = json.decode(currentRes.body);
          forecast = json.decode(forecastRes.body)['list'];
        });
      } else {
        throw Exception('Failed to load weather');
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<Position> _determinePosition() async {
    LocationPermission permission;
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }
    return await Geolocator.getCurrentPosition();
  }

  void _onTabTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  Widget _buildToday() {
    if (currentWeather == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(currentWeather!['name'],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(
            '${currentWeather!['main']['temp']}°C',
            style: const TextStyle(fontSize: 40),
          ),
          const SizedBox(height: 10),
          Text(
            currentWeather!['weather'][0]['description'],
            style: const TextStyle(fontSize: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildForecast() {
    if (forecast == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        final item = forecast![index * 8]; // every 24 hrs (8 * 3hr intervals)
        final date = DateTime.parse(item['dt_txt']);
        return ListTile(
          leading: const Icon(Icons.calendar_today),
          title: Text(DateFormat('EEE, MMM d').format(date)),
          subtitle: Text(item['weather'][0]['description']),
          trailing: Text('${item['main']['temp']}°C'),
        );
      },
    );
  }

  Widget _buildSettings() {
    return const Center(child: Text("⚙️ Settings will be here", style: TextStyle(fontSize: 20)));
  }

  List<Widget> get _pages => [_buildToday(), _buildForecast(), _buildSettings()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🌤️ Weather App')),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.today), label: 'Today'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_view_day), label: 'Forecast'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
