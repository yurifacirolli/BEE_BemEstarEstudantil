import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MoodTrackerController extends ChangeNotifier {
  final _noteController = TextEditingController();
  TextEditingController get noteController => _noteController;

  String? _selectedMood;
  String? get selectedMood => _selectedMood;

  // Lista de humores disponíveis
  final List<Map<String, String>> moods = const [
    {'emoji': '😄', 'label': 'Feliz'},
    {'emoji': '🙂', 'label': 'Bem'},
    {'emoji': '😐', 'label': 'Normal'},
    {'emoji': '😟', 'label': 'Triste'},
    {'emoji': '😠', 'label': 'Irritado'},
  ];

  // Lista de atividades disponíveis e selecionadas
  final List<String> allActivities = ['Trabalho', 'Estudo', 'Exercício', 'Família', 'Amigos', 'Lazer'];
  final Set<String> _selectedActivities = {};
  Set<String> get selectedActivities => _selectedActivities;

  // ID do documento que está sendo editado. Se for nulo, estamos criando um novo.
  String? _editingDocId;

  /// Atualiza o humor selecionado e notifica os ouvintes para reconstruir a UI.
  void selectMood(String emoji) {
    _selectedMood = emoji;
    notifyListeners(); // para notificar a UI sobre a mudança.
  }

  /// Adiciona ou remove uma atividade da lista de selecionadas.
  void toggleActivity(String activity) {
    if (_selectedActivities.contains(activity)) {
      _selectedActivities.remove(activity);
    } else {
      _selectedActivities.add(activity);
    }
    notifyListeners();
  }

  /// Carrega os dados de um registro existente para edição.
  Future<void> loadMoodForEditing(String docId) async {
    _editingDocId = docId;
    try {
      final doc = await FirebaseFirestore.instance.collection('registros_humor').doc(docId).get();
      if (doc.exists) {
        final data = doc.data()!;
        _selectedMood = data['mood'];
        _noteController.text = data['notes'] ?? '';
        _selectedActivities.clear();
        _selectedActivities.addAll(List<String>.from(data['activities'] ?? []));
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Erro ao carregar humor para edição: $e");
    }
  }

  /// Salva o registro de humor no Firestore.
  Future<void> saveMood(BuildContext context) async {
    // Se estiver em modo de edição, chama o método de atualização.
    if (_editingDocId != null) {
      _updateMood(context);
      return;
    }

    if (_selectedMood == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione um humor.'), backgroundColor: Colors.red),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você precisa estar logado para salvar.'), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('registros_humor').add({
        'userId': user.uid,
        'mood': _selectedMood,
        'notes': _noteController.text,
        'activities': _selectedActivities.toList(),
        'timestamp': FieldValue.serverTimestamp(), // Usa o tempo do servidor
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Humor registrado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Volta para a tela anterior e indica sucesso
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Atualiza um registro de humor existente no Firestore.
  Future<void> _updateMood(BuildContext context) async {
    if (_editingDocId == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('registros_humor').doc(_editingDocId).update({
        'mood': _selectedMood,
        'notes': _noteController.text,
        'activities': _selectedActivities.toList(),
        'timestamp': FieldValue.serverTimestamp(), // Atualiza o timestamp da edição
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registro atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Volta e indica sucesso
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Reseta o estado do controlador para um novo registro.
  void resetState() {
    _noteController.clear();
    _selectedMood = null;
    _selectedActivities.clear();
    _editingDocId = null;
    // Notifica a UI caso a tela seja reutilizada.
    notifyListeners();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }
}