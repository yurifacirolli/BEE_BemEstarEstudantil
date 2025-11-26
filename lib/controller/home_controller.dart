import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeController extends ChangeNotifier {
  /// Retorna o UID do usuário atualmente logado.
  String? getUserId() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  /// Busca o nome do usuário logado no Firestore.
  Future<String> getLoggedUserName() async {
    final uid = getUserId();
    if (uid == null) return 'Visitante';

    try {
      final doc =
          await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();
      // Retorna o nome do usuário ou um texto padrão caso não encontre.
      return doc.data()?['name'] ?? 'Usuário';
    } catch (e) {
      // Em caso de erro, retorna um texto padrão.
      debugPrint("Erro ao buscar nome do usuário: $e");
      return 'Usuário';
    }
  }

  /// Realiza o logout do usuário e o redireciona para a tela de login.
  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    // Garante que o contexto ainda é válido antes de navegar.
    if (context.mounted) {
      // Navega para a tela de login e remove todas as rotas anteriores da pilha
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
    }
  }
}
