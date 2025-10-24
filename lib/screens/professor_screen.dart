import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/chamada_timer_service.dart';
import 'chamada_ativa_screen.dart';
import 'relatorio_chamada_screen.dart';

class TelaProfessor extends StatelessWidget {
  const TelaProfessor({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Professor'),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.settings, color: Colors.black54),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF8F8F8),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                gradient: LinearGradient(
                  colors: [Color(0xFF7B3EFF), Color(0xFF9E7BFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Olá, Professor!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Pronto para iniciar uma nova chamada?',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Card 1 - Iniciar nova chamada
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.deepPurple,
                  child: Icon(Icons.play_arrow, color: Colors.white),
                ),
                title: const Text(
                  'Iniciar Nova Chamada',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Começar uma sessão de presença automática',
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                onTap: () {
                  final timerService = context.read<ChamadaTimerService>();
                  timerService.iniciarChamada();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChamadaAtivaScreen(), 
                    ),
                  );
                },
              ),
            ),

            // Card 2 - Ver resultados anteriores
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.deepPurple,
                  child: Icon(Icons.history, color: Colors.white),
                ),
                title: const Text(
                  'Ver Resultados Anteriores',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Consultar relatórios de chamadas passadas',
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                onTap: () {
                  // <-- Corrigido aqui
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RelatorioChamadaScreen(),
                    ),
                  );
                },
              ),
            ),

            const Spacer(),

            // Rodapé informativo
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.amber),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'O sistema registra automaticamente a presença dos alunos próximos via Bluetooth.',
                      style: TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
