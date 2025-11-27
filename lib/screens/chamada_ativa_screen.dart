import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/chamada_timer_service.dart';

class ChamadaAtivaScreen extends StatefulWidget {
  const ChamadaAtivaScreen({super.key});

  @override
  State<ChamadaAtivaScreen> createState() => _ChamadaAtivaScreenState();
}

class _ChamadaAtivaScreenState extends State<ChamadaAtivaScreen> {
  Timer? _uiUpdateTimer;

  @override
  void initState() {
    super.initState();
    _uiUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _uiUpdateTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  String _formatTimestamp(String? isoString) {
    if (isoString == null) return '--:--:--';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return DateFormat('HH:mm:ss').format(dt);
    } catch (e) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final timerService = context.watch<ChamadaTimerService>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!timerService.chamadaAtiva && mounted) {
        Navigator.maybePop(context);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chamada Ativa'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple.shade100,
        actions: [
          TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Encerrar Chamada'),
                  content: const Text('Tem certeza que deseja encerrar a chamada manualmente?'),
                  actions: [
                    TextButton(
                      child: const Text('Cancelar'),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                    TextButton(
                      child: const Text('Encerrar', style: TextStyle(color: Colors.red)),
                      onPressed: () {
                        timerService.encerrarChamadaManualmente();
                        Navigator.of(ctx).pop();
                      },
                    ),
                  ],
                ),
              );
            },
            child: const Text(
              'Finalizar',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('Rodada Atual', style: TextStyle(color: Colors.black54)),
                        const SizedBox(height: 4),
                        Text(
                          '${timerService.rodadaAtual}/${ChamadaTimerService.totalRodadas}',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          timerService.janelaRegistroAberta
                              ? 'Janela fecha em'
                              : (timerService.rodadaAtual < ChamadaTimerService.totalRodadas
                                  ? 'Próxima rodada em'
                                  : 'Chamada Concluída'),
                          style: TextStyle(
                            color: timerService.janelaRegistroAberta ? Colors.green.shade700 : Colors.orange.shade700,
                            fontWeight: timerService.janelaRegistroAberta ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          timerService.janelaRegistroAberta
                              ? _formatDuration(timerService.tempoRestanteJanela)
                              : (timerService.rodadaAtual < ChamadaTimerService.totalRodadas
                                  ? _formatDuration(timerService.tempoAteProximaRodada)
                                  : '--:--'),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: timerService.janelaRegistroAberta ? Colors.green.shade700 : Colors.orange.shade900,
                           ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Divider(),
             const Text(
              'Alunos Presentes na Rodada Atual',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: timerService.presencasEmTempoReal,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Erro ao carregar lista: ${snapshot.error}'),
                      );
                    }

                    final alunos = snapshot.data ?? [];

                    if (alunos.isEmpty) {
                      return Center(
                        child: Text(
                          timerService.janelaRegistroAberta
                              ? 'Aguardando registros...'
                              : 'Nenhum registro nesta rodada.',
                          style: TextStyle(color: Colors.grey.shade600),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: alunos.length,
                      itemBuilder: (context, index) {
                        final aluno = alunos[index];
                        return ListTile(
                          leading: const Icon(Icons.check_circle, color: Colors.green),
                          title: Text(aluno['nome_aluno'] ?? 'Desconhecido'),
                          subtitle: Text(
                            'RA: ${aluno['ra_aluno']} • ${_formatTimestamp(aluno['created_at'])}',
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.cloud_sync, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sincronizado em tempo real com a nuvem.',
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