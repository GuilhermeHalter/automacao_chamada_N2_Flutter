import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChamadaTimerService with ChangeNotifier {
  static const int totalRodadas = 4;
  static const Duration intervaloEntreRodadas = Duration(minutes: 50);
  static const Duration duracaoJanelaRegistro = Duration(minutes: 5); 

  final _supabase = Supabase.instance.client;

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

  Stream<List<Map<String, dynamic>>> get presencasEmTempoReal {
    if (!_chamadaAtiva || _rodadaAtual == 0) {
      return const Stream.empty();
    }
    return _supabase
        .from('presencas')
        .stream(primaryKey: ['id'])
        .eq('rodada', _rodadaAtual)
        .order('created_at', ascending: false);
  }

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
    print("SERVIÇO TIMER: Rodada $_rodadaAtual iniciada no Supabase.");
    
    notifyListeners();

    _timerJanela?.cancel();
    _timerJanela = Timer(duracaoJanelaRegistro, _fecharJanelaRegistro);

    if (_rodadaAtual < totalRodadas) {
      _inicioProximaRodada = DateTime.now().add(intervaloEntreRodadas);
      
      _timerRodadas?.cancel();
      _timerRodadas = Timer(intervaloEntreRodadas, _iniciarProximaRodada);
    } else {
      _inicioProximaRodada = null;
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
      _encerrarChamadaCompleta();
    }
  }

  void encerrarChamadaManualmente() {
     if (!_chamadaAtiva) return;
     print("SERVIÇO TIMER: Chamada encerrada manualmente.");
     _cancelarTimers();
     _resetarEstado();
     notifyListeners();
  }

  void _encerrarChamadaCompleta() {
    print("SERVIÇO TIMER: Fim da aula.");
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
  }

  void _resetarEstado() {
     _rodadaAtual = 0;
     _chamadaAtiva = false;
     _janelaRegistroAberta = false;
     _inicioProximaRodada = null;
     _fimJanelaRegistroAtual = null;
  }

  Future<void> registrarPresencaAluno(String nomeAluno, String raAluno) async {
    if (janelaRegistroAberta && _chamadaAtiva) {
      try {
        await _supabase.from('presencas').insert({
          'ra_aluno': raAluno,
          'nome_aluno': nomeAluno,
          'rodada': _rodadaAtual,
          // 'created_at' é gerado automaticamente pelo banco
        });
        
        print("SERVIÇO TIMER: Aluno $nomeAluno ($raAluno) salvo no Supabase.");        
      } catch (e) {
         print("SERVIÇO TIMER: Erro ao registrar presença (possível duplicata): $e");
      }
    } else {
       print("SERVIÇO TIMER: Tentativa de registro fora da janela.");
    }
  }

  @override
  void dispose() {
    _cancelarTimers();
    super.dispose();
  }
}