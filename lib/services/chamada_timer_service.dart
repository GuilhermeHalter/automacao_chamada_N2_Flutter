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

  String? _chamadaId;

  int _rodadaAtual = 0;
  bool _chamadaAtiva = false;
  bool _janelaRegistroAberta = false;
  DateTime? _inicioProximaRodada; 
  DateTime? _fimJanelaRegistroAtual;

  int get rodadaAtual => _rodadaAtual;
  bool get chamadaAtiva => _chamadaAtiva;
  bool get janelaRegistroAberta => _janelaRegistroAberta;
  String? get chamadaId => _chamadaId;

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

  Stream<List<Map<String, dynamic>>> get presencasEmTempoReal {
    if (!_chamadaAtiva || _chamadaId == null) {
      return const Stream.empty();
    }
    return _supabase
        .from('presencas')
        .stream(primaryKey: ['id'])
        .eq('chamada_id', _chamadaId!)
        .order('created_at', ascending: false)
        .map((listaPresencas) {
          return listaPresencas.where((p) => p['rodada'] == _rodadaAtual).toList();
        });
  }

  Future<void> iniciarChamada() async {
    if (_chamadaAtiva) return;

    try {
      print("SERVIÇO TIMER: Criando nova chamada no banco...");
      
      final data = await _supabase.from('chamadas').insert({
        'ativo': true,
        'descricao': 'Aula Iniciada em ${DateTime.now().toString()}'
      }).select().single();

      _chamadaId = data['id'];
      print("SERVIÇO TIMER: Chamada criada com ID: $_chamadaId");
      
      _rodadaAtual = 0;
      _chamadaAtiva = true;
      _janelaRegistroAberta = false;
      _inicioProximaRodada = DateTime.now();
      _fimJanelaRegistroAtual = null;
      
      notifyListeners();
      _iniciarProximaRodada();

    } catch (e) {
      print("Erro crítico ao iniciar chamada: $e");
      _resetarEstado();
    }
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
    print("SERVIÇO TIMER: Rodada $_rodadaAtual iniciada.");
    
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

    print("SERVIÇO TIMER: Rodada $_rodadaAtual - Janela fechada.");
    _janelaRegistroAberta = false;
    _fimJanelaRegistroAtual = null;
    notifyListeners();

    if (_rodadaAtual >= totalRodadas) {
      _encerrarChamadaCompleta();
    }
  }

  Future<void> encerrarChamadaManualmente() async {
     if (!_chamadaAtiva) return;
     print("SERVIÇO TIMER: Chamada encerrada manualmente.");
     
     await _finalizarChamadaNoBanco();
     _cancelarTimers();
     _resetarEstado();
     notifyListeners();
  }

  Future<void> _encerrarChamadaCompleta() async {
    print("SERVIÇO TIMER: Fim do ciclo de chamadas.");
    await _finalizarChamadaNoBanco();
    _cancelarTimers();
    _resetarEstado();
    notifyListeners();
  }

  Future<void> _finalizarChamadaNoBanco() async {
    if (_chamadaId != null) {
      try {
        await _supabase.from('chamadas').update({
          'ativo': false,
          'data_fim': DateTime.now().toIso8601String()
        }).eq('id', _chamadaId!);
      } catch (e) {
        print("Erro ao finalizar chamada no banco: $e");
      }
    }
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
     _chamadaId = null; 
  }

  Future<void> registrarPresencaAluno(String nomeAluno, String raAluno) async {
    if (janelaRegistroAberta && _chamadaAtiva && _chamadaId != null) {
      try {
        await _supabase.from('presencas').insert({
          'chamada_id': _chamadaId,
          'ra_aluno': raAluno,
          'nome_aluno': nomeAluno,
          'rodada': _rodadaAtual,
        });
        
        print("SERVIÇO TIMER: Presença registrada ($nomeAluno) na Chamada $_chamadaId.");        
      } catch (e) {
         print("SERVIÇO TIMER: Erro/Duplicidade ao registrar: $e");
         rethrow;
      }
    } else {
       print("SERVIÇO TIMER: Registro rejeitado (Fora da janela ou sem chamada ativa).");
       throw Exception("A janela de chamada está fechada.");
    }
  }

  @override
  void dispose() {
    _cancelarTimers();
    super.dispose();
  }
}