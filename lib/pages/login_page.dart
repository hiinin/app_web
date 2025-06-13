import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../pages/home_page.dart'; // ajuste o caminho e nome conforme seu projeto

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _passwordController = TextEditingController();
  final _loginController = TextEditingController();
  bool _obscurePassword = true;

  Future<void> _tryLogin() async {
    final loginInput = _loginController.text.trim();
    final passwordInput = _passwordController.text.trim();

    if (loginInput.isEmpty || passwordInput.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Preencha login e senha')));
      return;
    }

    try {
      final response =
          await Supabase.instance.client
              .from('admin')
              .select()
              .eq('login', loginInput)
              .maybeSingle();

      if (response == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Usuário não encontrado')));
        return;
      }

      if (response['password'] == passwordInput) {
        // Quando o login for bem-sucedido, use este código:
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder:
                (context, animation, secondaryAnimation) => const HomePage(),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Senha incorreta')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao fazer login: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Row(
        children: [
          // Imagem à esquerda (70%)
          Expanded(
            flex: 7,
            child: Container(
              decoration: BoxDecoration(
                image: const DecorationImage(
                  image: AssetImage('assets/images/imagemfundologin.jpg'),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 10,
                    offset: const Offset(15, 0), // Shadow para a direita
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.2),
                    blurRadius: 50,
                    spreadRadius: 20,
                    offset: const Offset(25, 0), // Shadow mais suave
                  ),
                ],
              ),
            ),
          ), // Formulário à direita (30%)
          Expanded(
            flex: 3,
            child: Container(
              height: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 40),
              decoration: const BoxDecoration(color: Colors.white),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 30),

                  Center(
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/logocampusmap.png', // ajuste o caminho se necessário
                          width: 350,
                          height: 350,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 1), // Espaço entre cabeçalho e campos
                  // Campo Login
                  TextField(
                    controller: _loginController,
                    style: const TextStyle(color: Color(0xFF222B45)),
                    decoration: InputDecoration(
                      labelText: 'Login',
                      labelStyle: const TextStyle(color: Color(0xFF8F9BB3)),
                      filled: true,
                      fillColor: const Color(0xFFF7F9FC),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 24,
                        horizontal: 20,
                      ), // AUMENTA ALTURA
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE4E9F2)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE4E9F2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFF1976D2),
                          width: 2,
                        ),
                      ),
                      prefixIcon: const Icon(
                        Icons.person_outline,
                        color: Color(0xFF8F9BB3),
                      ),
                    ),
                  ),

                  const SizedBox(height: 60), // Espaço grande entre campos
                  // Campo Senha
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: Color(0xFF222B45)),
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      labelStyle: const TextStyle(color: Color(0xFF8F9BB3)),
                      filled: true,
                      fillColor: const Color(0xFFF7F9FC),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 24,
                        horizontal: 20,
                      ), // AUMENTA ALTURA
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE4E9F2)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE4E9F2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFF1976D2),
                          width: 2,
                        ),
                      ),
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: Color(0xFF8F9BB3),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: const Color(0xFF8F9BB3),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    onSubmitted: (_) => _tryLogin(),
                  ),

                  const Spacer(flex: 1), // Espaço entre campos e botão
                  // Botão
                  SizedBox(
                    width: double.infinity,
                    height: 64, // AUMENTA ALTURA DO BOTÃO
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 22,
                        ), // AUMENTA ALTURA DO BOTÃO
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                        backgroundColor: const Color(0xFF1976D2),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _tryLogin,
                      child: const Text(
                        "Entrar",
                        style: TextStyle(
                          fontSize: 20, // Se quiser aumentar o texto também
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  ),

                  const Spacer(flex: 2), // Espaço no final
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
