import 'package:supabase_flutter/supabase_flutter.dart';

class Usuario {
  final String id;
  final String nome;
  final String ra;
  final String? email;

  Usuario({
    required this.id,
    required this.nome,
    required this.ra,
    this.email,
  });

  factory Usuario.fromSupabase(User user) {
    final metadata = user.userMetadata ?? {};
    return Usuario(
      id: user.id,
      nome: metadata['nome'] ?? 'Aluno',
      ra: metadata['ra'] ?? '',
      email: user.email,
    );
  }
}

class UsuarioService {
  static final _supabase = Supabase.instance.client;

  static Usuario? get usuarioAtual {
    final user = _supabase.auth.currentUser;
    return user != null ? Usuario.fromSupabase(user) : null;
  }

  static String _gerarEmailDoRa(String ra) {
    return '${ra.trim()}@aluno.app'; 
  }

  static Future<void> cadastrarAluno(String nome, String ra, String senha) async {
    final email = _gerarEmailDoRa(ra);

    try {
      await _supabase.auth.signUp(
        email: email,
        password: senha,
        data: {
          'nome': nome,
          'ra': ra,
        },
      );
    } on AuthException catch (e) {
      if (e.message.contains('already registered') || e.code == 'user_already_exists') {
        throw Exception('Este RA já possui cadastro.');
      }
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Erro inesperado ao cadastrar: $e');
    }
  }

  static Future<Usuario?> autenticar(String ra, String senha) async {
    final email = _gerarEmailDoRa(ra);

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: senha,
      );

      if (response.user != null) {
        return Usuario.fromSupabase(response.user!);
      }
      return null;
    } on AuthException catch (e) {
      if (e.message.contains('Invalid login credentials')) {
        throw Exception('RA ou senha incorretos.');
      }
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Erro ao fazer login: $e');
    }
  }

  static Future<void> logout() async {
    await _supabase.auth.signOut();
  }
}