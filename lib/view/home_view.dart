import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_project/controller/home_controller.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

    // Lista de funcionalidades para exibir na tela
  final List<Feature> features = const [
    Feature(
      title: 'Rastreador de Humor',
      image: 'assets/mood_tracker.png', // Caminho de imagem de exemplo
    ),
    Feature(
      title: 'Exercício Diário de Atenção',
      image: 'assets/mindfulness.png',
    ),
    Feature(
      title: 'Dashboard de Bem-Estar',
      image: 'assets/dashboard.png',
    ),
    Feature(
      title: 'Perguntas de Autorreflexão',
      image: 'assets/reflection.png',
    ),
    Feature(
      title: 'Desafio de Hábitos Positivos',
      image: 'assets/habits.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Página Inicial'),
        actions: [
          // Botão "Sobre"
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Sobre',
            onPressed: () {
              Navigator.of(context).pushNamed('/about');
            },
          ),
          // Botão "Logout"
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () => context.read<HomeController>().logout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Saudação ao usuário (adicionada da outra versão)
            FutureBuilder<String>(
              future: context.read<HomeController>().getLoggedUserName(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text('Bem-vindo(a)!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold));
                }
                return Text('Olá, ${snapshot.data ?? 'Usuário'}!', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold));
              },
            ),
            const SizedBox(height: 24),
            // USO DE LISTVIEW
            ListView.builder(
              // Ajustes para funcionar dentro de um SingleChildScrollView
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              itemCount: features.length,
              itemBuilder: (context, index) {
                final feature = features[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  elevation: 4,
                  child: InkWell(
                    onTap: () {
                      // Navega para a funcionalidade correta com base no índice
                      if (index == 0) {
                        Navigator.of(context).pushNamed('/mood_tracker');
                      } else if (index == 1) {
                        Navigator.of(context).pushNamed('/daily_mindfulness');
                      } else if (index == 2) {
                        Navigator.of(context).pushNamed('/wellness_dashboard');
                      } else if (index == 3) {
                        Navigator.of(context).pushNamed('/self_reflection');
                      } else if (index == 4) {
                        Navigator.of(context).pushNamed('/positive_habits');
                      }
                    },
                    child: Stack(
                      alignment: Alignment.bottomLeft,
                      children: [
                        // Imagem de fundo do card
                        Ink.image(
                          height: 150,
                          fit: BoxFit.cover,
                          image: AssetImage(feature.image),
                          //Em caso de erro ao carregar a imagem, mostra um ícone
                          onImageError: (exception, stackTrace) => const Center(
                            child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                          ),
                        ),
                        Container(
                          height: 150,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.black54, Colors.transparent],
                              begin: Alignment.bottomCenter,
                              end: Alignment.center,
                            ),
                          ),
                        ),
                        // Título da funcionalidade
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            feature.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              shadows: [Shadow(blurRadius: 2.0, color: Colors.black87)],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class Feature {
  final String title;
  final String image;

  const Feature({required this.title, required this.image});
}