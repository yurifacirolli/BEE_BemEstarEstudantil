import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordController extends ChangeNotifier {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void sendPasswordResetEmail(BuildContext context) async {
    if (formKey.currentState!.validate()) {
      _setLoading(true);
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(
          email: emailController.text,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Link de recuperação enviado para o seu e-mail.'),
              backgroundColor: Colors.green,
            ),
          );
          // Volta para a tela de login
          Navigator.of(context).pop();
        }
      } on FirebaseAuthException catch (e) {
        String message = 'Ocorreu um erro. Tente novamente.';
        if (e.code == 'user-not-found') {
          message = 'Nenhum usuário encontrado para este e-mail.';
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
}