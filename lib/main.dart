import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: WeatherPage(),
    );
  }
}

class WeatherPage extends StatefulWidget {
  @override
  _WeatherPageState createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final _formKey = GlobalKey<FormState>();
  final _cityController = TextEditingController();
  String _cityName = '';
  String _weatherInfo = '';

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>?> getCityCoordinates(String cityName) async {
    try {
      String url = 'https://api-ninjas.com/api/city?name=$cityName';
      Dio dio = Dio();
      dio.options.headers['X-Api-Key'] = dotenv.env['CITY_API_KEY'];
      Response response = await dio.get(url);
      return response.data;
    } catch (error) {
      print('Error: $error');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getWeatherData(
      double latitude, double longitude) async {
    try {
      String url =
          'https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&appid=${dotenv.env['METEO_API_KEY']}';
      Dio dio = Dio();
      Response response = await dio.get(url);
      return response.data;
    } catch (error) {
      print('Error: $error');
      return null;
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      Map<String, dynamic>? cityCoordinates =
          await getCityCoordinates(_cityName);
      if (cityCoordinates != null) {
        double latitude = cityCoordinates['latitude'];
        double longitude = cityCoordinates['longitude'];

        Map<String, dynamic>? weatherData =
            await getWeatherData(latitude, longitude);
        if (weatherData != null) {
          String cityName = weatherData['name'];
          String country = weatherData['sys']['country'];
          double temperature = weatherData['main']['temp'];

          setState(() {
            _weatherInfo =
                'City: $cityName, Country: $country, Temperature: $temperature°C';
          });
        } else {
          setState(() {
            _weatherInfo = 'Failed to fetch weather data';
          });
        }
      } else {
        setState(() {
          _weatherInfo = 'Failed to fetch city coordinates';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Weather App'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _cityController,
                decoration: InputDecoration(
                  labelText: 'City Name',
                ),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter a city name';
                  }
                  return null;
                },
                onSaved: (value) {
                  _cityName = value!;
                },
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Get Weather'),
              ),
              SizedBox(height: 16.0),
              Text(
                _weatherInfo,
                style: TextStyle(fontSize: 18.0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
