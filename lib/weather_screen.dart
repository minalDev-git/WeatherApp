import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import './hourly_forecast_item.dart';
import './additional_info_item.dart';

//converted this to a stateful widget b/c we need to call getCurrentweather();
//this func shold not be called in build func b/c build func should always be least expensive
class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  String cityName = '';
  final TextEditingController _textEditingController = TextEditingController();

//this var is used to store the value of _getCurrentweather() on refresh
  late Future<Map<String, dynamic>> weather;
  //late double temp;              //temp = data['list'][0]['main']['temp']
  // double temp = 0;

  //if we make a 'global' var or a 'late' var,
  //the build func gets executed first while the data is being fetched from api, and sets the old value of the var
  //b/c we marked this function as async
  //to display the correct value, wrap the assignment operation in setState func
  //Map of String:keys and dynamic: values
  Future<Map<String, dynamic>> _getCurrentWeather(
      {String cityName = 'London'}) async {
    try {
      String apiKey = dotenv.env['API_KEY'] ?? '';
      String baseUrl = dotenv.env['BASE_URL'] ?? '';
      //q=London&APPID=
      String url = '$baseUrl$cityName&APPID=$apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        //convert the string to (json object)/Map
        final data = jsonDecode(response.body);
        //print(data['list'][0]['main']['temp']);
        // setState(() {
        //   temp = data['list'][0]['main']['temp'];
        // });
        return data;
      } else if (response.statusCode == 404) {
        // City not found
        throw 'Wrong city name entered';
      } else {
        // Other errors from API
        throw 'An unexpected error occurred';
      }
    } on SocketException {
      // No internet
      throw 'Internet Connection Required';
    } catch (e) {
      throw e.toString();
    }
  }

//It is very tedious to handle the possible errors so we use the convinient flutter's widget, to deal with "Futures"
//we will remove the initState and setState methods and in the build function we'll use "FutureBuilder"
//It has 2 properties: future and builder: arrow func
  // @override
  // void initState() {
  //   super.initState();
  //   _getCurrentweather();
  // }

//when we press refresh button, we call setState which builds the build func again but
//setState doesn't call the initState, therefore weather variable has the old value that was set by initState
  @override
  void initState() {
    super.initState();
    weather = _getCurrentWeather();
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Weather App',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                // re-initializing
                _textEditingController.clear();
                weather = _getCurrentWeather();
              });
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      //while api data is being fetched, 0k shows on the screen,=> not a great UX
      //therefore, we'll show a loading indicator
      body: FutureBuilder(
          //already has a value assigned to it, thus getCurrentWeather() is not called again,therefore not restarting
          //to fix that, we re-initialize weather var in setState func or call=> future: getCurrentWeather() & keep
          //setState empty.
          future: weather,
          builder: (context, asyncSnapshot) {
            //asyncSnapshot allows to handle state in your app e.g data state, error state or loading state
            //print(asyncSnapshot); //return type AsyncSnapshot<dynamic> means its a class
            if (asyncSnapshot.connectionState == ConnectionState.waiting) {
              //means data is being fetched from api, show the loading indicator
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 5.0,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Fetching Forecast...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (asyncSnapshot.hasError) {
              return Center(
                child: Text(
                  asyncSnapshot.error.toString(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              );
            }

            //we have handled the error case so we are sure that asyncSnapshot.data will be non-NULL
            final data = asyncSnapshot.data!;
            final currentWeatherData = data['list'][0];
            final currentTemp = currentWeatherData['main']['temp'];
            final currentSky = currentWeatherData['weather'][0]['main'];
            final currentIconCode = currentWeatherData['weather'][0]['icon'];
            //URL + $iconCode@2x.png
            String iconUrl = dotenv.env['ICON_URL'] ?? '';
            final pressure = currentWeatherData['main']['pressure'];
            final humidity = currentWeatherData['main']['humidity'];
            final windSpeed = currentWeatherData['wind']['speed'];

            final border = OutlineInputBorder(
              borderSide: const BorderSide(
                //color format: 0xAARRGGBB
                color: Colors.black, //by default the color is 0xFF000000
                width: 2.0,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(5),
            );
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: _textEditingController,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 20),
                        decoration: InputDecoration(
                          hintText: "City Name",
                          hintStyle: const TextStyle(color: Colors.grey),
                          prefixIcon: const Icon(Icons.location_city),
                          prefixIconColor: Colors.white,
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                cityName = _textEditingController.text;
                                weather =
                                    _getCurrentWeather(cityName: cityName);
                              });
                            },
                            icon: const Icon(Icons.search),
                          ),
                          suffixIconColor: Colors.white,
                          filled: true,
                          focusedBorder: border,
                          enabledBorder: border,
                        ),
                      ),
                    ),
                    // main card
                    SizedBox(
                      width: double.infinity,
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                              sigmaX: 10,
                              sigmaY: 10,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Text(
                                    '$currentTemp °K',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Image.network(
                                    '$iconUrl$currentIconCode@2x.png',
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(Icons.error),
                                  ),
                                  Text(
                                    currentSky,
                                    style: const TextStyle(fontSize: 20),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    const Text(
                      ' Hourly Forecast',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    // weather forecast cards
                    // SingleChildScrollView(
                    //   //whatever child widget is placed inside SingleChildScrollView widget, becomes scrollable
                    //   //we did this b/c multiple card widgets were exceeding the limit of the screen
                    //   scrollDirection: Axis.horizontal,
                    //   child: Row(
                    //     children: [
                    //     //we want multiple HourlyForecastItems to show over here so we could use a for-loop for that
                    //     //however,the drawback of this approach is that the widget is not building on demand,but together
                    //     //This affects the performance of the app.
                    //     //approach 2: build widgets as soon as we scroll,so it lazily create our widgets. only the
                    //     //part that gets scrolled, gets created otherwise not.
                    //     //to achieve this, we use "ListView.builder" widget
                    //       for (int i = 0; i < 5; i++)
                    //         HourlyForecastItem(
                    //           time: data['list'][i + 1]['dt'].toString(),
                    //           icon: Icons.cloud,
                    //           temperature:
                    //               data['list'][i + 1]['main']['temp'].toString(),
                    //         ),
                    //     ],
                    //   ),
                    // ),
                    //lazily builds a list. It takes the entire screen size so we need to restrict its height to avoid
                    //errors.
                    SizedBox(
                      height: 130,
                      child: ListView.builder(
                        itemCount: 5, //number of items to be built
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (contex, index) {
                          final hourlyForecast = data['list'][index + 1];
                          final hourlyIconCode =
                              hourlyForecast['weather'][0]['icon'];
                          final hourlyTemp =
                              hourlyForecast['main']['temp'].toString();
                          //to extract the time out of this string, we can use string manupilation or "intl" package
                          final hourlyTime =
                              DateTime.parse(hourlyForecast['dt_txt']);
                          return HourlyForecastItem(
                            //Hm => hour-min 00:00 format
                            time: DateFormat.jm().format(hourlyTime),
                            icon: '$iconUrl$hourlyIconCode@2x.png',
                            temperature: hourlyTemp,
                          );
                        }, //what do you want to build
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    //additional Information
                    const Text(
                      ' Additional Information',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        AdditionalInfoItem(
                          icon: Icons.water_drop_rounded,
                          label: 'Humidity',
                          value: humidity.toString(),
                        ),
                        AdditionalInfoItem(
                          icon: Icons.air,
                          label: 'Wind Speed',
                          value: windSpeed.toString(),
                        ),
                        AdditionalInfoItem(
                          icon: Icons.speed_outlined,
                          label: 'Pressure',
                          value: pressure.toString(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
    );
  }
}
