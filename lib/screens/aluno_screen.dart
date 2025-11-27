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
  erroConexao,
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

  void _iniciarSimuladorScan() {
    setState(() {
      _status = AlunoStatus.procurando;
    });

    _pararSimuladorScan();

    _scanSimulatorTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final timerService = context.read<ChamadaTimerService>();

      if (!timerService.chamadaAtiva) {
        _pararSimuladorScan();
        setState(() => _status = AlunoStatus.falhaForaDaChamada);
        return;
      }

      if (timerService.janelaRegistroAberta) {
        print("ALUNO SCREEN: Professor detectado. Tentando registrar...");
        
        _pararSimuladorScan();

        try {
          await timerService.registrarPresencaAluno(
            widget.usuario.nome,
            widget.usuario.ra,
          );

          if (mounted) {
            setState(() {
              _status = AlunoStatus.registrado;
              _rodadaRegistrada = timerService.rodadaAtual;
            });
          }
        } catch (e) {
          print("Erro no registro: $e");
          if (mounted) {
            setState(() => _status = AlunoStatus.erroConexao);
          }
        }
      } else {
        print("ALUNO SCREEN: Procurando... janela fechada.");
      }
    });
  }

  void _pararSimuladorScan() {
    _scanSimulatorTimer?.cancel();
    _scanSimulatorTimer = null;
  }

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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _iniciarSimuladorScan,
              child: const Column(
                children: [
                  Icon(Icons.wifi_tethering, color: Colors.white, size: 40),
                  SizedBox(height: 8),
                  Text("Participar da Chamada", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        );

      case AlunoStatus.procurando:
        return Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            const Text("Conectando ao professor...", style: TextStyle(fontSize: 18, color: Colors.deepPurple)),
            const SizedBox(height: 8),
            Text(
              timerService.janelaRegistroAberta
                  ? "Sinal detectado! Registrando..."
                  : "Aguardando abertura da janela...",
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        );

      case AlunoStatus.registrado:
        return Column(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 16),
            Text(
              "Presença salva na nuvem!\nRodada $_rodadaRegistrada",
              style: const TextStyle(fontSize: 18, color: Colors.green, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => setState(() => _status = AlunoStatus.ocioso),
              child: const Text('Ok'),
            ),
          ],
        );

      case AlunoStatus.erroConexao:
        return Column(
          children: [
            const Icon(Icons.wifi_off, color: Colors.orange, size: 60),
            const SizedBox(height: 16),
            const Text(
              "Erro de Conexão.\nNão foi possível salvar sua presença.",
              style: TextStyle(fontSize: 16, color: Colors.orange, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => setState(() => _status = AlunoStatus.ocioso),
              child: const Text('Tentar Novamente'),
            ),
          ],
        );

      default: 
        return Column(
          children: [
            const Icon(Icons.error, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            const Text(
              "Não foi possível registrar.\nVerifique se a chamada está ativa.",
              style: TextStyle(fontSize: 16, color: Colors.red, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => setState(() => _status = AlunoStatus.ocioso),
              child: const Text('Voltar'),
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Aluno")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(child: _buildStatusContent()),
      ),
    );
  }
}