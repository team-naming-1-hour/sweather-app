import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sweater/components/card_container.dart';
import 'package:sweater/components/hourly_weather_section.dart';
import 'package:sweater/pages/gender_change_page.dart';
import 'package:sweater/pages/manage_location_page.dart';
import 'package:sweater/providers/location_info.dart';
import 'package:sweater/providers/coordi_provider.dart';
import 'package:provider/provider.dart';
import 'package:sweater/providers/weather.dart';
import 'package:sweater/theme/sweater_icons.dart';
import 'package:sweater/theme/global_theme.dart';
import '../components/coordi_section.dart';
import '../components/weather_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final String _title = "SWEATER";
  Color colorByWeather() {
    return Colors.white;
  }

  @override
  void iniState() {
    print(context.read<Location>().cur);
    print("hi");
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    context.read<CoordiProvider>().initCoordiList();
    var weather = context.watch<Weather>().forecastList[0];
    return Container(
        decoration: const BoxDecoration(
            image: DecorationImage(
                image: AssetImage("assets/background-sky.png"),
                fit: BoxFit.cover)),
        child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
                title: Text(
                  context.watch<Location>().cur.split(' ').last,
                  style: Theme.of(context)
                      .textTheme
                      .headline6!
                      .copyWith(color: colorByWeather()),
                ),
                leading: Builder(
                    builder: (context) => IconButton(
                        icon: Icon(SweaterIcons.bars, color: colorByWeather()),
                        onPressed: () {
                          Scaffold.of(context).openDrawer();
                        }))),
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    WeatherView(
                      temp: weather.getTemp,
                      sTemp: weather.getSTemp,
                      wind: weather.getWindSpeed,
                      weather: weather.getSky,
                    ),
                    HourlyWeatherSection(),
                    CardContainer(child: CoordiSection()),
                  ]),
            ),
            drawer: Drawer(
                child: ListView(
              children: <Widget>[
                DrawerHeader(
                    child: Text(_title,
                        style: Theme.of(context).textTheme.headline4),
                    decoration:
                        BoxDecoration(color: Theme.of(context).primaryColor)),
                ListTile(
                    leading: const Icon(Icons.location_on),
                    title: const Text("지역 관리"),
                    onTap: () => {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const ManageLocationPage()))
                        }),
                ListTile(
                    leading: const Icon(Icons.wc),
                    title: const Text("성별 설정"),
                    onTap: () => {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const GenderChangePage()))
                        })
              ],
            ))));
  }
}
