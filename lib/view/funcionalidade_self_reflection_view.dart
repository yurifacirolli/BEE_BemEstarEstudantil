import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:app_project/controller/self_reflection_controller.dart';
import 'package:provider/provider.dart';

class FuncionalidadeSelfReflectionView extends StatefulWidget {
  const FuncionalidadeSelfReflectionView({super.key});

  @override
  State<FuncionalidadeSelfReflectionView> createState() => _FuncionalidadeSelfReflectionViewState();
}

class _FuncionalidadeSelfReflectionViewState extends State<FuncionalidadeSelfReflectionView> {
  final _controller = GetIt.I.get<SelfReflectionController>();
  String? _docIdToEdit;

  @override
  void initState() {
    super.initState();
    _controller.resetState();
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String) {
      _docIdToEdit = args;
      _controller.loadReflectionForEditing(_docIdToEdit!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_docIdToEdit == null ? 'Perguntas de Reflexão' : 'Editar Reflexão'),
          actions: [
            if (_docIdToEdit == null) // mostra o botão de histórico apenas no modo criação
              IconButton(
                icon: const Icon(Icons.history),
                tooltip: 'Ver Histórico',
                onPressed: () => Navigator.of(context).pushNamed('/reflection_history'),
              ),
          ],
        ),
        body: Consumer<SelfReflectionController>(
          builder: (context, controller, child) {
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              // Adiciona um item extra na lista para o botão
              itemCount: controller.prompts.length + 1,
              itemBuilder: (context, index) {
                // se for o último item da lista, exibe o botão de salvar.
                if (index == controller.prompts.length && _docIdToEdit == null) {
                  return _buildSaveButton(context, controller);
                }

                if (index >= controller.prompts.length) {
                  return const SizedBox.shrink();
                }

                // Caso contrário, mostra o card com a pergunta
                return Card(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildReflectionCardContent(context, controller, index),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

Widget _buildReflectionCardContent(BuildContext context, SelfReflectionController controller, int index) {
  // no modo de edição, mostra apenas o campo que está sendo editado.
  final isEditing = controller.controllers.any((c) => c.text.isNotEmpty);
  if (isEditing && controller.controllers[index].text.isEmpty) {
    return const SizedBox.shrink(); // Oculta os outros campos
  }

  return Column(
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              controller.prompts[index],
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(controller.favoriteIndices.contains(index) ? Icons.star : Icons.star_border),
            color: controller.favoriteIndices.contains(index) ? Colors.amber : Colors.grey,
            onPressed: () => controller.toggleFavorite(index),
          ),
        ],
      ),
      const SizedBox(height: 12),
      TextField(
        controller: controller.controllers[index],
        decoration: const InputDecoration(
          hintText: 'Sua resposta aqui...',
          border: OutlineInputBorder(),
        ),
        maxLines: 3,
      ),
      // Mostra o botão de salvar dentro do card no modo de edição
      if (isEditing)
        Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: ElevatedButton(onPressed: () => controller.saveReflections(context), child: const Text('Salvar Alterações')),
        ),
    ],
  );
}

Widget _buildSaveButton(BuildContext context, SelfReflectionController controller) {
  return Padding(
    padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      onPressed: () => controller.saveReflections(context),
      child: const Text('Salvar Reflexões'),
    ),
  );
}