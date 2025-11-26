import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Enum para definir as opções de ordenação disponíveis.
enum SortOption { dateDescending, dateAscending }

class MoodHistoryController extends ChangeNotifier {
  String _searchQuery = '';
  SortOption _sortOption = SortOption.dateDescending;

  String get searchQuery => _searchQuery;
  SortOption get sortOption => _sortOption;

  /// Retorna um Stream de dados do histórico de humor do usuário logado.
  Stream<QuerySnapshot> getMoodHistoryStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Retorna um stream vazio se o usuário não estiver logado.
      return const Stream.empty();
    }
    
    Query query = FirebaseFirestore.instance
      .collection('registros_humor')
      .where('userId', isEqualTo: user.uid);

    // A ordenação principal por data ainda é feita no Firestore para otimização.
    // A ordenação ascendente/descendente será tratada no cliente se necessário.
    return query.orderBy('timestamp', descending: true).snapshots();
  }

  /// Atualiza o termo de pesquisa e notifica os ouvintes.
  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Atualiza a opção de ordenação e notifica os ouvintes.
  void updateSortOption(SortOption? option) {
    if (option != null && _sortOption != option) {
      _sortOption = option;
      notifyListeners();
    }
  }

  /// Filtra e ordena a lista de documentos com base nos critérios atuais.
  List<QueryDocumentSnapshot> filterAndSortEntries(List<QueryDocumentSnapshot> entries) {
    // Mapa para traduzir emoji para o nome do humor para a pesquisa.
    const moodNameMap = {
      '😄': 'feliz',
      '🙂': 'bem',
      '😐': 'normal',
      '😟': 'triste',
      '😠': 'irritado',
    };

    List<QueryDocumentSnapshot> filteredEntries;

    // 1. Filtragem (case-insensitive)
    if (_searchQuery.isEmpty) {
      filteredEntries = entries;
    } else {
      final lowerCaseQuery = _searchQuery.toLowerCase();
      filteredEntries = entries.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final moodEmoji = (data['mood'] as String? ?? '');
        final moodName = moodNameMap[moodEmoji] ?? '';
        final notes = (data['notes'] as String? ?? '').toLowerCase();
        final activities = (data['activities'] as List<dynamic>).join(', ').toLowerCase();

        return moodEmoji.contains(lowerCaseQuery) ||
               notes.contains(lowerCaseQuery) ||
               moodName.contains(lowerCaseQuery) ||
               activities.contains(lowerCaseQuery);
      }).toList();
    }

    // 2. Ordenação
    filteredEntries.sort((a, b) {
      final aTimestamp = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
      final bTimestamp = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;

      if (aTimestamp == null || bTimestamp == null) return 0;

      switch (_sortOption) {
        case SortOption.dateAscending:
          return aTimestamp.compareTo(bTimestamp); // Mais antigo primeiro
        case SortOption.dateDescending:
        default:
          return bTimestamp.compareTo(aTimestamp); // Mais recente primeiro
      }
    });

    return filteredEntries;
  }
}