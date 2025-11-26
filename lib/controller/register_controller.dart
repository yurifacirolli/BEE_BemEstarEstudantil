import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterController extends ChangeNotifier {
  final formKey = GlobalKey<FormState>();

  // Controladores para acessar os valores dos campos
  final nameController = TextEditingController();
  final dobController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Valida o e-mail usando uma API externa.
  Future<bool> _validateEmailWithApi(String email) async {
    const apiKey = '5df1k06jr2jo6kb1na6p8r2qphmud7eg83i4c35pe1ohf0g89p15m8';
    final url = Uri.parse('https://anyapi.io/api/v1/email?apiKey=$apiKey&email=$email');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // A API retorna um booleano no campo 'valid'.
        // Se for true, o e-mail é válido.
        return data['valid'] ?? false;
      } else {
        // Se a API falhar, considera o e-mail inválido por segurança.
        debugPrint('API de validação de e-mail falhou com status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      // Em caso de erro de rede, etc.
      debugPrint('Erro ao chamar a API de validação de e-mail: $e');
      // Se a API falhar 
      // retorna'true' para não bloquear o cadastro. O Firebase fará a validação principal.
      return true;
    }
  }

  /// Valida o formulário e simula o cadastro do usuário.
  void register(BuildContext context) async {
    if (formKey.currentState!.validate()) {
      _setLoading(true);

      // Validação de e-mail com a API externa
      final isEmailValid = await _validateEmailWithApi(emailController.text);
      if (!isEmailValid) {
        // A API retornou 'false', o que significa que o e-mail é realmente inválido.
        if (context.mounted) {
          _showError(context, 'O e-mail fornecido é inválido ou descartável.');
        }
        _setLoading(false);
        return;
      }

      try {
        // 1. Criar usuário no Firebase Authentication
        final userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
                email: emailController.text, password: passwordController.text);

        // 2. Armazenar informações adicionais no Firestore
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(userCredential.user!.uid)
            .set({
          'name': nameController.text,
          'dob': dobController.text,
          'email': emailController.text,
          'phone': phoneController.text,
        });

        // Feedback de sucesso e navegação
        if (context.mounted) {
          _showSuccess(context, 'Usuário criado com sucesso!');
          Navigator.of(context).pop();
        }
      } on FirebaseAuthException catch (e) {
        // Tratamento de erros específicos do Firebase Auth
        String message;
        switch (e.code) {
          case 'email-already-in-use':
            message = 'Este e-mail já está em uso.';
            break;
          case 'invalid-email':
            message = 'O formato do e-mail é inválido.';
            break;
          case 'weak-password':
            message = 'A senha é muito fraca.';
            break;
          default:
            message = 'Ocorreu um erro. Tente novamente.';
        }
        if (context.mounted) {
          _showError(context, message);
        }
      } finally {
        _setLoading(false);
      }
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  String? validateConfirmPassword(String? value) {
    if (value != passwordController.text) {
      return 'As senhas não coincidem.';
    }
    return null;
  }

  /// Valida a complexidade da senha.
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'A senha é obrigatória.';
    }
    if (value.length < 8) {
      return 'A senha deve ter no mínimo 8 caracteres.';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Deve conter ao menos uma letra maiúscula.';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Deve conter ao menos uma letra minúscula.';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Deve conter ao menos um número.';
    }
    // Regex para verificar caracteres especiais.
    if (!value.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) {
      return 'Deve conter ao menos um caractere especial.';
    }
    // Se todas as validações passarem
    return null;
  }

  @override
  void dispose() {
    // Limpa todos os controladores
    [nameController, dobController, emailController, phoneController, passwordController, confirmPasswordController]
        .forEach((controller) => controller.dispose());
    super.dispose();
  }
}