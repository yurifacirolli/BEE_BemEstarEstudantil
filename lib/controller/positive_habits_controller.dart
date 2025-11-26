import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

class Habit {
  final String title;
  final IconData icon;
  bool isCompleted;
  int streak;

  Habit({
    required this.title,
    required this.icon,
    this.isCompleted = false,
    this.streak = 0,
  });
}

class PositiveHabitsController extends ChangeNotifier {
  // Lista de hábitos de exemplo
  final List<Habit> habits = [
    Habit(title: 'Dormir 8 horas', icon: Icons.bedtime_outlined, streak: 3),
    Habit(title: 'Beber 2L de água', icon: Icons.local_drink_outlined, streak: 5, isCompleted: true),
    Habit(title: 'Fazer uma caminhada de 30 min', icon: Icons.directions_walk_outlined, streak: 1),
    Habit(title: 'Ler por 15 minutos', icon: Icons.book_outlined, streak: 12, isCompleted: true),
    Habit(title: 'Meditar por 5 minutos', icon: Icons.self_improvement_outlined, streak: 0),
  ];

  // Lista de sugestões locais para usar quando a API falhar.
  final List<String> _localSuggestions = const [
    'Organize uma playlist com suas músicas favoritas',
    'Escreva três coisas pelas quais você é grato(a) hoje',
    'Faça um alongamento de 10 minutos',
    'Desenhe ou rabisque algo sem compromisso',
    'Leia um capítulo de um livro',
    'Assista a um vídeo educativo sobre um novo tópico',
    'Arrume uma pequena parte do seu quarto',
  ];

  /// Retorna uma sugestão aleatória da lista local.
  String _getRandomLocalSuggestion() {
    final random = Random();
    return _localSuggestions[random.nextInt(_localSuggestions.length)];
  }

  /// Busca uma atividade aleatória. Tenta a API primeiro e usa uma sugestão local como fallback.
  Future<String> getNewActivitySuggestion() async {
    try {
      // Tenta buscar uma sugestão da API online.
      final response = await http.get(Uri.parse('https://bored-api.appbrewery.com/random'));

      if (response.statusCode != 200) throw Exception('API retornou status ${response.statusCode}');
      
      final data = json.decode(response.body);
      return data['activity'] ?? _getRandomLocalSuggestion();
    } catch (e) {
      debugPrint("API de atividades falhou (esperado se estiver offline/indisponível): $e. Usando sugestão local.");
      return _getRandomLocalSuggestion();
    }
  }

  /// Adiciona um novo hábito à lista com base em uma sugestão.
  void addSuggestedHabit(String suggestion) {
    // Evita adicionar sugestões vazias ou de erro.
    if (suggestion.contains('Tente novamente') || suggestion.contains('Verifique sua conexão')) return;

    final newHabit = Habit(title: suggestion, icon: Icons.lightbulb_outline);
    habits.add(newHabit);
    notifyListeners(); // Notifica a UI para reconstruir a lista com o novo hábito.
  }

  void toggleHabitCompletion(Habit habit) {
    habit.isCompleted = !habit.isCompleted;

    // Simula o aumento/diminuição da sequência
    if (habit.isCompleted) {
      habit.streak++;
    } else {
      // Evita que a sequência fique negativa
      if (habit.streak > 0) {
        habit.streak--;
      }
    }
    notifyListeners();
  }
}