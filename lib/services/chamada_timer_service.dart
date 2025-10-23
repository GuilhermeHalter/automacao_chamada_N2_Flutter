import 'dart:async';
import 'package:flutter/foundation.dart';

class ChamadaTimerService with ChangeNotifier {
  static const int totalRodadas = 4;
  static const Duration intervaloEntreRodadas = Duration(seconds: 60); // TODO: Alterar para Duration(minutes: 50) em produção
  static const Duration duracaoJanelaRegistro = Duration(seconds: 15); // TODO: Alterar para Duration(minutes: 5) em produção

  Timer? _timerRodadas; 
  Timer? _timerJanela; 

  int _rodadaAtual = 0;
  bool _chamadaAtiva = false;
  bool _janelaRegistroAberta = false;
  DateTime? _inicioProximaRodada; 
  DateTime? _fimJanelaRegistroAtual;

  int get rodadaAtual => _rodadaAtual;
  bool get chamadaAtiva => _chamadaAtiva;
  bool get janelaRegistroAberta => _janelaRegistroAberta;

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

  @override
  void dispose() {
    print("SERVIÇO TIMER: Dispose chamado, cancelando timers.");
    _cancelarTimers();
    super.dispose();
  }
}