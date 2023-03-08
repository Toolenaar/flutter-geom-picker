import 'package:flutter/material.dart';
import 'package:flutter_geom_picker/map_view.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(backgroundColor: Colors.white, body: GeomPickerMapView()),
    );
  }
}
