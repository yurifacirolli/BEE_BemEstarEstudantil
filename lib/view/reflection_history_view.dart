import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:app_project/controller/reflection_history_controller.dart';

class ReflectionHistoryView extends StatelessWidget {
  const ReflectionHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ReflectionHistoryController>(
      create: (_) => GetIt.I.get<ReflectionHistoryController>(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Histórico de Reflexões'),
        ),
        body: Consumer<ReflectionHistoryController>(
          builder: (context, controller, child) {
            // Inicia a busca na primeira construção
            if (controller.reflectionStream == null) controller.fetchReflections();
            return Column(
              children: [
                // Abas para filtrar
                SegmentedButton<ReflectionFilter>(
                  segments: const [
                    ButtonSegment(value: ReflectionFilter.all, label: Text('Todas')),
                    ButtonSegment(value: ReflectionFilter.favorites, label: Text('Favoritas'), icon: Icon(Icons.star)),
                  ],
                  selected: {controller.currentFilter},
                  onSelectionChanged: (newSelection) {
                    controller.setFilter(newSelection.first);
                  },
                  style: const ButtonStyle(visualDensity: VisualDensity.compact),
                ),
                const SizedBox(height: 8),
                // Conteúdo da lista
                Expanded(
                  child: _buildContent(context, controller),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ReflectionHistoryController controller) {
    return StreamBuilder<QuerySnapshot>(
      stream: controller.reflectionStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erro: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              controller.currentFilter == ReflectionFilter.all
                  ? 'Nenhuma reflexão encontrada.'
                  : 'Nenhuma reflexão favorita encontrada.',
              style: const TextStyle(fontSize: 16),
            ),
          );
        }

        final reflectionEntries = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: reflectionEntries.length,
          itemBuilder: (context, index) {
            final doc = reflectionEntries[index];
            final entry = doc.data() as Map<String, dynamic>;
            final timestamp = (entry['entryDate'] as Timestamp?)?.toDate();
            final formattedDate = timestamp != null ? DateFormat('dd/MM/yyyy').format(timestamp) : 'Data indisponível';
            final bool isFavorite = entry['isFavorite'] ?? false;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry['prompt'] ?? 'Pergunta não encontrada', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text('"${entry['response'] ?? ''}"', style: const TextStyle(fontStyle: FontStyle.italic)),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(formattedDate, style: const TextStyle(color: Colors.grey)),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(isFavorite ? Icons.star : Icons.star_border, color: Colors.amber),
                              tooltip: 'Favoritar',
                              onPressed: () => controller.toggleFavoriteStatus(doc.id, isFavorite),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.grey),
                              tooltip: 'Editar',
                              onPressed: () async {
                                await Navigator.of(context).pushNamed('/self_reflection', arguments: doc.id);
                                // A atualização é automática, não precisa mais do `if (result == true)`
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
