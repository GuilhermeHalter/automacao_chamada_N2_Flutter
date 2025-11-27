import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/home_screen.dart';
import 'services/chamada_timer_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('pt_BR', null); 

  await Supabase.initialize(
    url: 'https://zwcwaagwqdkxlsdkwiji.supabase.co', 
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp3Y3dhYWd3cWRreGxzZGt3aWppIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQxODg2MzgsImV4cCI6MjA3OTc2NDYzOH0.Vv71zpyf3ia4f3_oUbEJsTOjfTu18XCIxI3AaXQoblI',
  );

  runApp(
    ChangeNotifierProvider(
      create: (context) => ChamadaTimerService(),
      child: const ChamadaApp()
    )
  );
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