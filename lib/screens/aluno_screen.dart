import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/chamada_timer_service.dart';
import '../services/usuario_service.dart';

enum AlunoStatus {
  ocioso,
  procurando,
  registrado,
  falhaJanelaFechada,
  falhaForaDaChamada,
}

class AlunoScreen extends StatefulWidget {
  final Usuario usuario;

  const AlunoScreen({super.key, required this.usuario});

  @override
  State<AlunoScreen> createState() => _AlunoScreenState();
}

class _AlunoScreenState extends State<AlunoScreen> {
  AlunoStatus _status = AlunoStatus.ocioso;
  Timer? _scanSimulatorTimer;
  int _rodadaRegistrada = 0;

  @override
  void dispose() {
    _pararSimuladorScan();
    super.dispose();
  }

  /// Inicia o simulador que "detecta" o professor.
  void _iniciarSimuladorScan() {
    setState(() {
      _status = AlunoStatus.procurando;
    });

    _pararSimuladorScan();

    _scanSimulatorTimer =
        Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final timerService = context.read<ChamadaTimerService>();

      if (!timerService.chamadaAtiva) {
        setState(() {
          _status = AlunoStatus.falhaForaDaChamada;
        });
        _pararSimuladorScan();
        return;
      }

      if (timerService.janelaRegistroAberta) {
        print(
            "ALUNO SCREEN: Professor detectado na rodada ${timerService.rodadaAtual}");

        // Registra presença do aluno logado
        timerService.registrarPresencaAluno(
          widget.usuario.nome,
          widget.usuario.ra,
        );

        setState(() {
          _status = AlunoStatus.registrado;
          _rodadaRegistrada = timerService.rodadaAtual;
        });
        _pararSimuladorScan();
      } else {
        print("ALUNO SCREEN: Procurando... janela fechada ou ainda não abriu.");
        if (_status != AlunoStatus.procurando) {
          setState(() => _status = AlunoStatus.procurando);
        }
      }
    });
  }

  /// Para o simulador de varredura
  void _pararSimuladorScan() {
    _scanSimulatorTimer?.cancel();
    _scanSimulatorTimer = null;
    print("ALUNO SCREEN: Simulador de Scan parado.");
  }

  /// Mostra o conteúdo de acordo com o status do aluno
  Widget _buildStatusContent() {
    final timerService = context.watch<ChamadaTimerService>();

    switch (_status) {
      case AlunoStatus.ocioso:
        return Column(
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C853),
                padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _iniciarSimuladorScan,
              child: const Column(
                children: [
                  Icon(Icons.wifi_tethering, color: Colors.white, size: 40),
                  SizedBox(height: 8),
                  Text(
                    "Participar da Chamada",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Ativar detecção de proximidade",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 28),
          ],
        );

      case AlunoStatus.procurando:
        return Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            const Text(
              "Procurando professor na sala...",
              style: TextStyle(fontSize: 18, color: Colors.deepPurple),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              timerService.chamadaAtiva
                  ? (timerService.janelaRegistroAberta
                      ? "Janela da Rodada ${timerService.rodadaAtual} aberta!"
                      : "Aguardando janela da Rodada ${timerService.rodadaAtual + 1}...")
                  : "Aguardando início da chamada...",
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        );

      case AlunoStatus.registrado:
        return Column(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 16),
            Text(
              "Professor encontrado! Presença registrada na Rodada $_rodadaRegistrada!",
              style: const TextStyle(
                fontSize: 18,
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Sua presença está sendo registrada automaticamente.\nMantenha-se próximo ao professor.",
                style: TextStyle(
                  color: Colors.green.shade800,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => setState(() => _status = AlunoStatus.ocioso),
              child: const Text('Ok'),
            ),
          ],
        );

      case AlunoStatus.falhaJanelaFechada:
      case AlunoStatus.falhaForaDaChamada:
        return Column(
          children: [
            const Icon(Icons.error, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            Text(
              _status == AlunoStatus.falhaJanelaFechada
                  ? "Não foi possível registrar.\nA janela de registro da rodada está fechada."
                  : "Não foi possível registrar.\nA chamada não está ativa no momento.",
              style: const TextStyle(
                fontSize: 16,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => setState(() => _status = AlunoStatus.ocioso),
              child: const Text('Tentar Novamente'),
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text("Aluno", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _pararSimuladorScan();
            Navigator.pop(context);
          },
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.settings),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 Cabeçalho com nome do aluno logado
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF00C853), Color(0xFF00E676)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Olá, ${widget.usuario.nome}!",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Pronto para participar da chamada?",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // 🔹 Corpo com status dinâmico
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Center(child: _buildStatusContent()),
              ),

              const SizedBox(height: 24),

              // 🔹 Dicas visuais
              _buildInfoCard(
                icon: Icons.bluetooth,
                text:
                    "Mantenha o Bluetooth ativado para registrar sua presença",
                color: Colors.lightBlue.shade50,
              ),
              const SizedBox(height: 8),
              _buildInfoCard(
                icon: Icons.warning_amber_rounded,
                text: "Permaneça próximo ao professor durante toda a aula",
                color: Colors.orange.shade50,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Cartão informativo simples
  Widget _buildInfoCard({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(icon, color: Colors.black54),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
