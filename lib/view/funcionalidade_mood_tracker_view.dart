import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:app_project/controller/mood_tracker_controller.dart';
import 'package:provider/provider.dart';

class FuncionalidadeMoodTrackerView extends StatefulWidget {
  const FuncionalidadeMoodTrackerView({super.key});

  @override
  State<FuncionalidadeMoodTrackerView> createState() => _FuncionalidadeMoodTrackerViewState();
}

class _FuncionalidadeMoodTrackerViewState extends State<FuncionalidadeMoodTrackerView> {
  final _controller = GetIt.I.get<MoodTrackerController>();
  String? _docIdToEdit;

  @override
  void initState() {
    super.initState();
    _controller.resetState(); 
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pega o ID do documento passado como argumento, se houver.
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String) {
      _docIdToEdit = args;
      // Carrega os dados para edição.
      _controller.loadMoodForEditing(_docIdToEdit!);
    }
  }

  @override
  void dispose() {
    // O controlador é gerenciado pelo GetIt, não precisa ser descartado aqui.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Fornece a instância do controlador para a árvore de widgets.
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_docIdToEdit == null ? 'Novo Registro de Humor' : 'Editar Registro'),
          actions: [
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: 'Ver Histórico',
              onPressed: () {
                Navigator.of(context).pushNamed('/mood_history');
              },
            ),
          ],
        ),
      
        body: Consumer<MoodTrackerController>(
          builder: (context, controller, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '1. Selecione seu humor:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  // Seletor de humor
                  _buildMoodSelector(controller),
                  const SizedBox(height: 32),
                  const Text(
                    '2. O que você fez hoje?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  // Seletor de atividades
                  _buildActivitySelector(controller),
                  const SizedBox(height: 32),
                  const Text(
                    '3. Alguma anotação?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  // Campo de texto para anotações
                  TextField(
                    controller: controller.noteController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Escreva um pouco sobre o seu dia...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Botão de salvar
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => controller.saveMood(context),
                    child: const Text('Salvar Registro'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

Widget _buildMoodSelector(MoodTrackerController controller) {
  return Wrap(
    spacing: 16.0,
    runSpacing: 16.0,
    alignment: WrapAlignment.center,
    children: controller.moods.map((mood) {
      final isSelected = controller.selectedMood == mood['emoji'];
      return GestureDetector(
        onTap: () => controller.selectMood(mood['emoji']!),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue.shade100 : Colors.grey.shade200,
                shape: BoxShape.circle,
                border: isSelected ? Border.all(color: Colors.blue, width: 2) : null,
              ),
              child: Text(
                mood['emoji']!,
                style: const TextStyle(fontSize: 32),
              ),
            ),
            const SizedBox(height: 8),
            Text(mood['label']!),
          ],
        ),
      );
    }).toList(),
  );
}

Widget _buildActivitySelector(MoodTrackerController controller) {
  return Wrap(
    spacing: 8.0,
    runSpacing: 4.0,
    children: controller.allActivities.map((activity) {
      final isSelected = controller.selectedActivities.contains(activity);
      return FilterChip(
        label: Text(activity),
        selected: isSelected,
        onSelected: (_) => controller.toggleActivity(activity),
        selectedColor: Colors.blue.shade200,
        checkmarkColor: Colors.black,
      );
    }).toList(),
  );
}