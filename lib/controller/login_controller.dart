import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginController extends ChangeNotifier {
  final formKey = GlobalKey<FormState>();

  // Controladores para os campos
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Tenta fazer o login e navega para a home se for bem-sucedido.
  void login(BuildContext context) async {
    if (formKey.currentState!.validate()) {
      _setLoading(true);
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text,
          password: passwordController.text,
        );

        if (context.mounted) {
          // Navega para a home e remove todas as telas anteriores da pilha.
          Navigator.of(context).pushNamedAndRemoveUntil(
              '/home', (Route<dynamic> route) => false);
        }
      } on FirebaseAuthException catch (e) {
        String message;
        switch (e.code) {
          case 'user-not-found':
          case 'wrong-password':
          case 'invalid-credential': // Novo código de erro do Firebase
            message = 'Email e/ou senha incorretos.';
            break;
          case 'invalid-email':
            message = 'O formato do e-mail é inválido.';
            break;
          default:
            message = 'Ocorreu um erro. Tente novamente.';
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.red),
          );
        }
      } finally {
        _setLoading(false);
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}