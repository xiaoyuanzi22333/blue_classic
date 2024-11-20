import 'package:flutter/material.dart';
import './models/homePage.dart';
import 'package:provider/provider.dart';
import './models/bluetooth_model.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => BluetoothModel(),
      child: const MyApp(),
    )
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Flutter Navigation Demo',
      home: HomePage(),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import './models/bluetooth_model.dart';

// void main() {
//   runApp(
//     ChangeNotifierProvider(
//       create: (_) => BluetoothModel(),
//       child: MyApp(),
//     ),
//   );
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Bluetooth App',
//       home: BluetoothScreen(),
//     );
//   }
// }