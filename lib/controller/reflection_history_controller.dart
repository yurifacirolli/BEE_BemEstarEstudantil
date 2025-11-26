import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

enum ReflectionFilter { all, favorites }

class ReflectionHistoryController extends ChangeNotifier {
  ReflectionFilter _currentFilter = ReflectionFilter.all;
  ReflectionFilter get currentFilter => _currentFilter;

  // Stream que será reconstruído quando o filtro mudar.
  Stream<QuerySnapshot>? _reflectionStream;
  Stream<QuerySnapshot>? get reflectionStream => _reflectionStream;

  /// Altera o filtro e busca os dados novamente.
  void setFilter(ReflectionFilter filter) {
    if (_currentFilter != filter) {
      _currentFilter = filter;
      fetchReflections();
    }
  }

  /// Busca as reflexões no Firestore com base no filtro atual.
  void fetchReflections() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _reflectionStream = const Stream.empty();
      notifyListeners();
      return;
    }

    Query query = FirebaseFirestore.instance
        .collection('entradas_reflexao')
        .where('userId', isEqualTo: user.uid);

    if (_currentFilter == ReflectionFilter.favorites) {
      query = query.where('isFavorite', isEqualTo: true);
    }

    _reflectionStream = query.orderBy('entryDate', descending: true).snapshots();
    notifyListeners();
  }

  /// Alterna o status de favorito de um registro diretamente no Firestore.
  Future<void> toggleFavoriteStatus(String docId, bool currentStatus) async {
    try {
      // Atualiza o documento no Firestore
      await FirebaseFirestore.instance
          .collection('entradas_reflexao')
          .doc(docId)
          .update({'isFavorite': !currentStatus});

      // A UI será atualizada automaticamente pelo StreamBuilder,
      // não precisamos mais de lógica de atualização local.
    } catch (e) {
      debugPrint("Erro ao atualizar favorito: $e");
    }
  }
}