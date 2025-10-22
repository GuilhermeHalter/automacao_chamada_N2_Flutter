import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const ChamadaApp());
}

class ChamadaApp extends StatelessWidget {
  const ChamadaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sistema de Chamada Automática',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
        fontFamily: 'Poppins',
      ),
      home: const TelaInicial(),
    );
  }
}
