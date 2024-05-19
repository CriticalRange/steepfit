import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:health/health.dart';
import 'package:steepfit/page/settings.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:developer';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  // Fictitious brand color.
  static const _brandBlue = Color(0xFF1E88E5);

  CustomColors lightCustomColors =
      const CustomColors(danger: Color(0xFFE53935));
  CustomColors darkCustomColors = const CustomColors(danger: Color(0xFFEF9A9A));

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
        builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
      ColorScheme lightColorScheme;
      ColorScheme darkColorScheme;

      if (lightDynamic != null && darkDynamic != null) {
        // On Android S+ devices, use the provided dynamic color scheme.
        // (Recommended) Harmonize the dynamic color scheme' built-in semantic colors.
        lightColorScheme = lightDynamic.harmonized();
        // (Optional) Customize the scheme as desired. For example, one might
        // want to use a brand color to override the dynamic [ColorScheme.secondary].
        lightColorScheme = lightColorScheme.copyWith(secondary: _brandBlue);
        // (Optional) If applicable, harmonize custom colors.

        // Repeat for the dark color scheme.
        darkColorScheme = darkDynamic.harmonized();
        darkColorScheme = darkColorScheme.copyWith(secondary: _brandBlue);
      } else {
        // Otherwise, use fallback schemes.
        lightColorScheme = ColorScheme.fromSeed(
          seedColor: _brandBlue,
        );
        darkColorScheme = ColorScheme.fromSeed(
          seedColor: _brandBlue,
          brightness: Brightness.dark,
        );
      }

      return MaterialApp(
        theme: ThemeData(
          colorScheme: lightColorScheme,
          extensions: [lightCustomColors],
        ),
        darkTheme: ThemeData(
          colorScheme: darkColorScheme,
          extensions: [darkCustomColors],
        ),
        themeMode: ThemeMode.dark,
        debugShowCheckedModeBanner: false,
        title: 'SteepFit',
        home: MyHomePage(
          title: 'SteepFit',
          subTitle: "Keep up the Good work!",
          value: 200,
          maxValue: 2000,
        ),
      );
    });
  }
}

@immutable
class CustomColors extends ThemeExtension<CustomColors> {
  const CustomColors({
    required this.danger,
  });

  final Color? danger;

  @override
  CustomColors copyWith({Color? danger}) {
    return CustomColors(
      danger: danger ?? this.danger,
    );
  }

  @override
  CustomColors lerp(ThemeExtension<CustomColors>? other, double t) {
    if (other is! CustomColors) {
      return this;
    }
    return CustomColors(
      danger: Color.lerp(danger, other.danger, t),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage(
      {super.key,
      required this.title,
      this.subTitle,
      this.value = 0,
      required this.maxValue});
  final String title;
  final String? subTitle;
  late double value;
  final double maxValue;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  void _gotoSettings() {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Settings(),
        ));
  }

  @override
  void initState() {
    super.initState();
    _initializeHealthConnect();
  }

  void _initializeHealthConnect() async {
    Health().configure(useHealthConnectIfAvailable: true);

    var types = [
      HealthDataType.STEPS,
    ];

    // requesting access to the data types before reading them
    bool requested = await Health().requestAuthorization(types);

    var now = DateTime.now();

    // fetch health data from the last 24 hours
    List<HealthDataPoint> healthData = await Health().getHealthDataFromTypes(
        types: types, startTime: now.subtract(Duration(days: 1)), endTime: now);

    int stepsCount = 0;

    for (var data in healthData) {
      if (data.type == HealthDataType.STEPS) {
        List<String> stepsParts = data.value.toString().split(':');
        if (stepsParts.length == 2) {
          stepsCount += int.parse(stepsParts[1]);
        }
      }
    }

    setState(() {
      widget.value = stepsCount.toDouble();
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(onPressed: (_gotoSettings), icon: Icon(Icons.settings))
        ],
        titleTextStyle: TextStyle(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            fontSize: 32),
        backgroundColor: Theme.of(context).colorScheme.onSecondary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 8.0),
            Text(
              widget.subTitle!,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8.0), // Adjust height as needed
            SfCircularChart(
              borderWidth: 0,
              legend: Legend(
                isVisible: true,
                backgroundColor: Colors.transparent,
                isResponsive: true,
                overflowMode: LegendItemOverflowMode.wrap,
              ),
              tooltipBehavior: TooltipBehavior(),
              backgroundColor: Colors.transparent,
              series: <CircularSeries>[
                RadialBarSeries<ChartData, String>(
                  maximumValue: widget.maxValue,
                  trackColor: Theme.of(context).colorScheme.primaryContainer,
                  trackBorderColor: Colors.transparent,
                  trackBorderWidth: 0,
                  dataSource: <ChartData>[
                    ChartData('Steps', widget.value,
                        Theme.of(context).colorScheme.tertiaryFixed),
                    ChartData('Calories', widget.maxValue,
                        Theme.of(context).colorScheme.primaryFixed),
                  ],
                  enableTooltip: true,
                  legendIconType: LegendIconType.circle,
                  xValueMapper: (ChartData data, _) => data.x,
                  yValueMapper: (ChartData data, _) => data.y,
                  dataLabelSettings: DataLabelSettings(
                      isVisible: false,
                      borderColor: Colors.transparent,
                      borderRadius: 0,
                      borderWidth: 0),
                  pointColorMapper: (ChartData data, _) => data.color,
                  radius: '80%',
                  innerRadius: '70%',
                  cornerStyle: CornerStyle.bothCurve,
                  dataLabelMapper: (ChartData data, _) => data.x,
                ),
              ],
            ),
            const SizedBox(height: 8.0), // Adjust height as needed
            Text(
              '${widget.value.toStringAsFixed(0)}/${widget.maxValue.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _initializeHealthConnect();
              },
              child: const Text('Health Connect'),
            ),
          ],
        ),
      ),
    );
  }
}

class ChartData {
  ChartData(this.x, this.y, this.color);
  final String x;
  final double y;
  final Color color;
}
