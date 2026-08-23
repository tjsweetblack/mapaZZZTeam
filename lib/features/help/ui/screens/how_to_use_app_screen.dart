import 'package:flutter/material.dart';

class HowToUseAppScreen extends StatelessWidget {
  const HowToUseAppScreen({super.key});

  static const Color _primaryColor = Color(0xFFE53935);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          tooltip: 'Voltar',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Como usar o app',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: const [
            _WelcomeCard(),
            SizedBox(height: 24),
            Text(
              'Comece por aqui',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12),
            _InstructionStep(
              number: '1',
              icon: Icons.map_outlined,
              title: 'Consulte o mapa',
              description:
                  'Veja as denúncias próximas e as áreas com diferentes níveis de risco. Use o gesto de pinça para aproximar ou afastar o mapa.',
            ),
            _InstructionStep(
              number: '2',
              icon: Icons.add_a_photo_outlined,
              title: 'Faça uma denúncia',
              description:
                  'Toque no botão vermelho com a câmara, tire ou escolha uma foto e informe os detalhes do possível foco de mosquitos.',
            ),
            _InstructionStep(
              number: '3',
              icon: Icons.location_on_outlined,
              title: 'Ative a localização',
              description:
                  'Permita o acesso à localização para identificar o risco perto de si e posicionar a denúncia com mais precisão.',
            ),
            _InstructionStep(
              number: '4',
              icon: Icons.article_outlined,
              title: 'Acompanhe as informações',
              description:
                  'Deslize a lista na parte inferior do mapa para ver as reportagens ativas e toque numa delas para ler os detalhes.',
            ),
            _InstructionStep(
              number: '5',
              icon: Icons.menu_book_outlined,
              title: 'Explore o menu',
              description:
                  'No menu lateral encontrará o seu perfil, quiz, notícias, É-Paludismo, prémios e outras informações úteis.',
            ),
            SizedBox(height: 8),
            _TipCard(),
          ],
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HowToUseAppScreen._primaryColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 27,
            backgroundColor: Colors.white24,
            child: Icon(Icons.health_and_safety_outlined,
                color: Colors.white, size: 31),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bem-vindo ao MapaZZZ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Ajude a sua comunidade a identificar e prevenir focos de mosquitos.',
                  style: TextStyle(color: Colors.white, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InstructionStep extends StatelessWidget {
  final String number;
  final IconData icon;
  final String title;
  final String description;

  const _InstructionStep({
    required this.number,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFFFFE7E5),
                shape: BoxShape.circle,
              ),
              child: Text(
                number,
                style: const TextStyle(
                  color: HowToUseAppScreen._primaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon,
                          color: HowToUseAppScreen._primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Color(0xFF5E5E5E),
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5D9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, color: Color(0xFFB77900)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Dica: mantenha as notificações ativas para receber alertas quando estiver perto de uma área de risco.',
              style: TextStyle(color: Color(0xFF725400), height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
