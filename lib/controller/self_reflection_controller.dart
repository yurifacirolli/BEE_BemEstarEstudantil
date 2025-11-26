import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SelfReflectionController extends ChangeNotifier {
  // Lista de perguntas de exemplo (prompts que posteriormente serão feitos por IA)
  final List<String> prompts = [
    "O que te trouxe alegria hoje, por menor que seja?",
    "Qual foi o maior desafio que você enfrentou hoje e como lidou com ele?",
    "Pelo que você se sente grato(a) neste momento?",
    "Se você pudesse dar um conselho para si mesmo(a) no início do dia, qual seria?",
    "Qual pequena ação você pode tomar amanhã para se aproximar de um objetivo seu?",
  ];

  // Controllers para cada campo de texto
  late final List<TextEditingController> controllers;

  // Conjunto para armazenar os índices das reflexões marcadas como favoritas.
  final Set<int> _favoriteIndices = {};
  Set<int> get favoriteIndices => _favoriteIndices;

  // ID do documento que está sendo editado.
  String? _editingDocId;

  SelfReflectionController() {
    _initializeControllers();
  }

  void _initializeControllers() {
    controllers = List.generate(prompts.length, (_) => TextEditingController());
  }

  /// Alterna o estado de favorito para uma reflexão com base em seu índice.
  void toggleFavorite(int index) {
    if (_favoriteIndices.contains(index)) {
      _favoriteIndices.remove(index);
    } else {
      _favoriteIndices.add(index);
    }
    notifyListeners(); // Notifica a UI para reconstruir e mostrar a mudança no ícone.
  }

  /// Carrega os dados de uma reflexão existente para edição.
  Future<void> loadReflectionForEditing(String docId) async {
    _editingDocId = docId;
    try {
      final doc = await FirebaseFirestore.instance.collection('entradas_reflexao').doc(docId).get();
      if (doc.exists) {
        final data = doc.data()!;
        final promptToEdit = data['prompt'];
        final responseToEdit = data['response'];
        final isFavorite = data['isFavorite'] ?? false;

        // Encontra o índice da pergunta correspondente para preencher o campo certo.
        final index = prompts.indexOf(promptToEdit);
        if (index != -1) {
          controllers[index].text = responseToEdit;
          if (isFavorite) {
            _favoriteIndices.add(index);
          }
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Erro ao carregar reflexão para edição: $e");
    }
  }

  /// Salva as reflexões preenchidas no Firestore.
  Future<void> saveReflections(BuildContext context) async {
    // Se estiver em modo de edição, chama a lógica de atualização.
    if (_editingDocId != null) {
      // Encontra qual campo foi preenchido para salvar.
      for (int i = 0; i < controllers.length; i++) {
        if (controllers[i].text.isNotEmpty) {
          await _updateReflection(context, i, controllers[i].text);
          return; // Sai após salvar a edição.
        }
      }
      // Se nenhum campo estiver preenchido no modo de edição, apenas volta.
      Navigator.of(context).pop(true);
      return;
    }

    // Lógica original para criar novas reflexões.
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você precisa estar logado para salvar.'), backgroundColor: Colors.red),
      );
      return;
    }

    // Usado para escrever múltiplos documentos de uma vez (operação atômica)
    final batch = FirebaseFirestore.instance.batch();
    int reflectionsSaved = 0;

    for (int i = 0; i < prompts.length; i++) {
      final responseText = controllers[i].text.trim();
      if (responseText.isNotEmpty) {
        // Cria uma referência para um novo documento na coleção
        final docRef = FirebaseFirestore.instance.collection('entradas_reflexao').doc();

        batch.set(docRef, {
          'userId': user.uid,
          'prompt': prompts[i],
          'response': responseText,
          'entryDate': FieldValue.serverTimestamp(),
          'isFavorite': _favoriteIndices.contains(i), // Define como favorito se o índice estiver no conjunto.
        });
        reflectionsSaved++;
      }
    }

    if (reflectionsSaved == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhuma reflexão foi preenchida.'), backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      await batch.commit(); // Envia todas as operações para o Firestore
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$reflectionsSaved reflexão(ões) salva(s) com sucesso!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar reflexões: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Atualiza uma única reflexão existente.
  Future<void> _updateReflection(BuildContext context, int index, String response) async {
    if (_editingDocId == null) return;

    try {
      await FirebaseFirestore.instance.collection('entradas_reflexao').doc(_editingDocId).update({
        'response': response,
        'isFavorite': _favoriteIndices.contains(index),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reflexão atualizada com sucesso!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Reseta o estado do controlador para um novo registro.
  void resetState() {
    _editingDocId = null;
    _favoriteIndices.clear();
    for (final controller in controllers) {
      controller.clear();
    }
    // Notifica a UI para garantir que a tela seja reconstruída limpa.
    notifyListeners();
  }


  @override
  void dispose() {
    // Limpa todos os controllers quando o controller principal for descartado.
    for (final controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }
}