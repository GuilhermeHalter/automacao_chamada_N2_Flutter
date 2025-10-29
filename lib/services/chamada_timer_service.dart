import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class ChamadaTimerService with ChangeNotifier {
  static const int totalRodadas = 4;
  static const Duration intervaloEntreRodadas = Duration(minutes: 50);
  static const Duration duracaoJanelaRegistro = Duration(minutes: 5); 

  Timer? _timerRodadas; 
  Timer? _timerJanela; 

  int _rodadaAtual = 0;
  bool _chamadaAtiva = false;
  bool _janelaRegistroAberta = false;
  DateTime? _inicioProximaRodada; 
  DateTime? _fimJanelaRegistroAtual;

  final List<Map<String, String>> _alunosPresentesRodada = [];

  int get rodadaAtual => _rodadaAtual;
  bool get chamadaAtiva => _chamadaAtiva;
  bool get janelaRegistroAberta => _janelaRegistroAberta;

  List<Map<String, String>> get alunosPresentesNaRodadaAtual => List.unmodifiable(_alunosPresentesRodada);

  Duration get tempoAteProximaRodada {
    if (!_chamadaAtiva || _inicioProximaRodada == null || _rodadaAtual >= totalRodadas) {
      return Duration.zero;
    }
    final agora = DateTime.now();
    final diff = _inicioProximaRodada!.difference(agora);
    return diff.isNegative ? Duration.zero : diff;
  }

  Duration get tempoRestanteJanela {
    if (!_janelaRegistroAberta || _fimJanelaRegistroAtual == null) {
      return Duration.zero;
    }
    final agora = DateTime.now();
    final diff = _fimJanelaRegistroAtual!.difference(agora);
    return diff.isNegative ? Duration.zero : diff;
  }

  void iniciarChamada() {
    if (_chamadaAtiva) return;

    print("SERVIÇO TIMER: Iniciando chamada...");
    _rodadaAtual = 0;
    _chamadaAtiva = true;
    _janelaRegistroAberta = false;
    _alunosPresentesRodada.clear();
    _inicioProximaRodada = DateTime.now();
    _fimJanelaRegistroAtual = null;
    notifyListeners();

    _iniciarProximaRodada();
  }

  void _iniciarProximaRodada() {
    if (_rodadaAtual >= totalRodadas) {
      print("SERVIÇO TIMER: Todas as $totalRodadas rodadas concluídas.");
      _encerrarChamadaCompleta();
      return;
    }

    _rodadaAtual++;
    _janelaRegistroAberta = true;
    _alunosPresentesRodada.clear();
    _fimJanelaRegistroAtual = DateTime.now().add(duracaoJanelaRegistro);
    print("SERVIÇO TIMER: Rodada $_rodadaAtual iniciada. Janela aberta até $_fimJanelaRegistroAtual.");
    notifyListeners();

    _timerJanela?.cancel();
    _timerJanela = Timer(duracaoJanelaRegistro, _fecharJanelaRegistro);

    if (_rodadaAtual < totalRodadas) {
      _inicioProximaRodada = DateTime.now().add(intervaloEntreRodadas);
      print("SERVIÇO TIMER: Próxima rodada (${_rodadaAtual + 1}) agendada para $_inicioProximaRodada.");

      _timerRodadas?.cancel();
      _timerRodadas = Timer(intervaloEntreRodadas, _iniciarProximaRodada);
    } else {
      _inicioProximaRodada = null;
      print("SERVIÇO TIMER: Esta é a última rodada.");
    }
     notifyListeners();
  }

  void _fecharJanelaRegistro() {
    if (!_janelaRegistroAberta) return;

    print("SERVIÇO TIMER: Rodada $_rodadaAtual - Janela de registro fechada.");
    _janelaRegistroAberta = false;
    _fimJanelaRegistroAtual = null;
    notifyListeners();

    if (_rodadaAtual >= totalRodadas) {
      print("SERVIÇO TIMER: Janela da última rodada fechada.");
      _encerrarChamadaCompleta();
    }
  }

  void encerrarChamadaManualmente() {
     if (!_chamadaAtiva) return;
     print("SERVIÇO TIMER: Chamada encerrada manualmente pelo professor.");
     _cancelarTimers();
     _resetarEstado();
     notifyListeners();
  }

  void _encerrarChamadaCompleta() {
    print("SERVIÇO TIMER: Chamada encerrada automaticamente após ${totalRodadas} rodadas.");
    _cancelarTimers();
    _chamadaAtiva = false;
    _janelaRegistroAberta = false;
    _inicioProximaRodada = null;
    _fimJanelaRegistroAtual = null;
    _alunosPresentesRodada.clear();
    notifyListeners();
  }

  void _cancelarTimers() {
    _timerRodadas?.cancel();
    _timerJanela?.cancel();
    _timerRodadas = null;
    _timerJanela = null;
    print("SERVIÇO TIMER: Timers cancelados.");
  }

  void _resetarEstado() {
     _rodadaAtual = 0;
     _chamadaAtiva = false;
     _janelaRegistroAberta = false;
     _inicioProximaRodada = null;
     _fimJanelaRegistroAtual = null;
  }

  void registrarPresencaAluno(String nomeAluno, String raAluno) {
    if (janelaRegistroAberta && _chamadaAtiva) {
      if (!_alunosPresentesRodada.any((aluno) => aluno['ra'] == raAluno)) {
          final timestamp = DateFormat('HH:mm:ss').format(DateTime.now());
          _alunosPresentesRodada.add({
              'nome': nomeAluno,
              'ra': raAluno,
              'timestamp': 'Registrado às $timestamp'
          });
          print("SERVIÇO TIMER: Aluno $nomeAluno ($raAluno) registrado na rodada $_rodadaAtual.");
          notifyListeners();
      } else {
         print("SERVIÇO TIMER: Aluno $nomeAluno ($raAluno) já registrado na rodada $_rodadaAtual.");
      }
    } else {
       print("SERVIÇO TIMER: Tentativa de registro do aluno $nomeAluno fora da janela ou chamada inativa.");
    }
  }

  @override
  void dispose() {
    print("SERVIÇO TIMER: Dispose chamado, cancelando timers.");
    _cancelarTimers();
    super.dispose();
  }
}