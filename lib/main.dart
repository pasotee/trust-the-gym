import 'package:flutter/material.dart';
import 'package:trust_the_gym/appdefines.dart';
import 'package:trust_the_gym/weeklytrainings.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppDefines.appTitle,
      theme: ThemeData(
        primarySwatch: AppDefines.mainColor,
      ),
      home: WeeklyTrainingsPage(
          title: AppDefines.mainTitle, itemsPerRow: AppDefines.itemsPerRow),
    );
  }
}
