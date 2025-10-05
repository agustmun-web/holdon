// lib/main.dart

import 'package:flutter/material.dart';

void main() {
  // SOLO debe haber una llamada a runApp
  runApp(const MyApp()); 
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HoldOn! Anti-Theft App',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const PlaceholderScreen(), // Usa tu pantalla principal aquí
    );
  }
}

// Widget temporal en blanco
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('¡HoldOn! Listo para empezar a construir'),
      ),
    );
  }
}