import 'package:flutter/material.dart';
import 'aluno_screen.dart';
import 'cadastro_screen.dart';
import '../services/usuario_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _raController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _carregando = false;
  String? _erro;

  void _fazerLogin() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    final ra = _raController.text.trim();
    final senha = _senhaController.text.trim();

    await Future.delayed(const Duration(milliseconds: 500));

    final usuario = UsuarioService.autenticar(ra, senha);

    if (usuario != null) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => AlunoScreen(usuario: usuario),
          ),
        );
      }
    } else {
      setState(() => _erro = "RA ou senha inválidos.");
    }

    setState(() => _carregando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login do Aluno"), centerTitle: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Entre para realizar a chamada",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
              const SizedBox(height: 40),

              TextField(
                controller: _raController,
                decoration: const InputDecoration(
                  labelText: "RA do aluno",
                  prefixIcon: Icon(Icons.badge),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _senhaController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Senha",
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              if (_erro != null)
                Text(_erro!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 10),

              _carregando
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      onPressed: _fazerLogin,
                      child: const Text("Entrar",
                          style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),

              const SizedBox(height: 12),

              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CadastroScreen()),
                  );
                },
                child: const Text("Não tem conta? Cadastre-se"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
