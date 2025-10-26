class Usuario {
  final String nome;
  final String ra;
  final String senha;

  Usuario({required this.nome, required this.ra, required this.senha});
}

class UsuarioService {
  static final List<Usuario> _usuarios = [];

  static void cadastrarAluno(String nome, String ra, String senha) {
    if (_usuarios.any((u) => u.ra == ra)) {
      throw Exception("RA já cadastrado.");
    }
    _usuarios.add(Usuario(nome: nome, ra: ra, senha: senha));
  }

  static Usuario? autenticar(String ra, String senha) {
    try {
      return _usuarios.firstWhere((u) => u.ra == ra && u.senha == senha);
    } catch (_) {
      return null;
    }
  }
}
