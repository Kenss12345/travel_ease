import 'package:flutter/material.dart';

class SecondScreen extends StatelessWidget {
  const SecondScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pantalla 2'),
      ),
      body: const Center(
        child: Text('¡Bienvenido a la Pantalla 2!'),
      ),
    );
  }
}