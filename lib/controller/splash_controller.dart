import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SplashController {
  /// Navega para a próxima tela após um tempo de espera.
  void initialize(BuildContext context) {
    // Aguarda 2 segundos para exibir a splash screen
    Future.delayed(const Duration(seconds: 2)).then((_) {
      // Verifica o estado de autenticação do usuário
      FirebaseAuth.instance.authStateChanges().listen((User? user) {
        if (user == null) {
          // Se não houver usuário logado, vai para a tela de login
          Navigator.of(context).pushReplacementNamed('/login');
        } else {
          // Se houver um usuário logado, vai direto para a home
          Navigator.of(context).pushReplacementNamed('/home');
        }
      });
    });
  }
}
