import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:app_project/controller/mood_history_controller.dart';

class MoodHistoryView extends StatefulWidget {
  const MoodHistoryView({super.key});

  @override
  State<MoodHistoryView> createState() => _MoodHistoryViewState();
}

class _MoodHistoryViewState extends State<MoodHistoryView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GetIt.I.get<MoodHistoryController>(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Histórico de Humor'),
        ),
        // Usamos um Consumer para acessar o controller
        body: Consumer<MoodHistoryController>(
          builder: (context, controller, child) {
            return Column(
              children: [
                _buildSearchAndSortBar(context, controller),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: controller.getMoodHistoryStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Erro: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text(
                            'Nenhum registro de humor encontrado.',
                            style: TextStyle(fontSize: 16),
                          ),
                        );
                      }

                      // Aplica o filtro e a ordenação do controller
                      final filteredEntries = controller.filterAndSortEntries(snapshot.data!.docs);

                      if (filteredEntries.isEmpty) {
                        return const Center(
                          child: Text(
                            'Nenhum resultado para sua busca.',
                            style: TextStyle(fontSize: 16),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: filteredEntries.length,
                        itemBuilder: (context, index) {
                          final doc = filteredEntries[index];
                          return _buildMoodEntryCard(context, doc);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchAndSortBar(BuildContext context, MoodHistoryController controller) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar registro...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onChanged: controller.updateSearchQuery,
            ),
          ),
          const SizedBox(width: 12),
          DropdownButton<SortOption>(
            value: controller.sortOption,
            icon: const Icon(Icons.sort),
            underline: const SizedBox.shrink(),
            items: const [
              DropdownMenuItem(
                value: SortOption.dateDescending,
                child: Text('Mais Recentes'),
              ),
              DropdownMenuItem(
                value: SortOption.dateAscending,
                child: Text('Mais Antigos'),
              ),
            ],
            onChanged: controller.updateSortOption,
          ),
        ],
      ),
    );
  }

  Widget _buildMoodEntryCard(BuildContext context, QueryDocumentSnapshot doc) {
    final docId = doc.id;
    final entry = doc.data() as Map<String, dynamic>;
    final timestamp = (entry['timestamp'] as Timestamp?)?.toDate();
    final formattedDate = timestamp != null
        ? DateFormat('dd/MM/yyyy \'às\' HH:mm').format(timestamp)
        : 'Data indisponível';
    final activities = (entry['activities'] as List<dynamic>).join(', ');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      elevation: 3,
      child: ListTile(
        leading: Text(
          entry['mood'] ?? '?',
          style: const TextStyle(fontSize: 32),
        ),
        title: Text(
          formattedDate,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (entry['notes'] != null && entry['notes'].isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
                child: Text('Anotação: "${entry['notes']}"'),
              ),
            if (activities.isNotEmpty) Text('Atividades: $activities'),
          ],
        ),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.edit, color: Colors.grey),
          tooltip: 'Editar Registro',
          onPressed: () async {
            await Navigator.of(context).pushNamed('/mood_tracker', arguments: docId);
          },
        ),
      ),
    );
  }
}