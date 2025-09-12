import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TermsAndServiceScreen extends StatelessWidget {
  final VoidCallback onAccept;
  final VoidCallback onDeny;

  const TermsAndServiceScreen(
      {super.key, required this.onAccept, required this.onDeny});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set background color
      appBar: AppBar(
        title: const Text(
          'Termos e Condições',
          style: TextStyle(color: Colors.black), // Set title color
        ),
        backgroundColor: Colors.transparent, // Make the AppBar transparent
        elevation: 0, // Remove shadow from AppBar
        iconTheme: const IconThemeData(
            color: Colors.black), // Ensure back button is visible
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: Scrollbar(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(
                        right: 8.0), // Add padding for scrollbar
                    child:
                        _buildTermsText(), // Build the terms and conditions text
                  ),
                ),
              ),
            ),
            _buildButtons(context), // Build the Accept/Deny buttons
          ],
        ),
      ),
    );
  }

  // Method to build the terms and conditions text
  Widget _buildTermsText() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Termos e Condições do Aplicativo MapaZZZ',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          'Última atualização: 27 de abril de 2025',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        SizedBox(height: 16),
        Text(
          'Bem-vindo ao MapaZZZ, um aplicativo móvel desenvolvido para monitoramento e prevenção da malária por meio de dados em tempo real e engajamento comunitário. Ao utilizar o MapaZZZ, você concorda em cumprir e estar vinculado aos seguintes Termos e Condições. Leia atentamente antes de usar o aplicativo. Se não concordar com estes termos, por favor, não utilize o aplicativo.',
          style: TextStyle(fontSize: 14),
        ),
        SizedBox(height: 16),
        Text(
          '1. Aceitação dos Termos',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          'Ao baixar, instalar ou usar o aplicativo MapaZZZ, você declara que leu, compreendeu e concorda com estes Termos e Condições, bem como com nossa Política de Privacidade. Estes termos aplicam-se a todos os usuários, incluindo indivíduos, organizações ou instituições de saúde.',
          style: TextStyle(fontSize: 14),
        ),
        SizedBox(height: 16),
        Text(
          '2. Objetivo do Aplicativo',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          'O MapaZZZ tem como objetivo promover a prevenção e o controle da malária por meio de:',
          style: TextStyle(fontSize: 14),
        ),
        SizedBox(height: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                '•  Relatórios voluntários de riscos ambientais (como poças de água estagnada) para criar mapas de calor interativos.',
                style: TextStyle(fontSize: 14)),
            Text(
                '•  Alertas e notificações sobre surtos de malária e recomendações preventivas.',
                style: TextStyle(fontSize: 14)),
            Text(
                '•  Conteúdo educacional gamificado sobre prevenção da malária.',
                style: TextStyle(fontSize: 14)),
            Text(
                '•  Integração com instituições de saúde para consulta de dados de risco em tempo real.',
                style: TextStyle(fontSize: 14)),
          ],
        ),
        SizedBox(height: 8),
        Text(
          'O aplicativo não substitui aconselhamento médico profissional. Em caso de emergência, procure imediatamente um profissional de saúde.',
          style: TextStyle(fontSize: 14),
        ),
        SizedBox(height: 16),
        Text(
          '3. Elegibilidade',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          'Para usar o MapaZZZ, você deve:',
          style: TextStyle(fontSize: 14),
        ),
        SizedBox(height: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                '•  Ter pelo menos 13 anos de idade. Usuários menores de 18 anos devem ter permissão de um responsável legal.',
                style: TextStyle(fontSize: 14)),
            Text(
                '•  Residir em uma região onde o aplicativo esteja disponível.',
                style: TextStyle(fontSize: 14)),
            Text(
                '•  Concordar em fornecer informações precisas ao reportar riscos ou criar uma conta.',
                style: TextStyle(fontSize: 14)),
          ],
        ),
        SizedBox(height: 16),
        Text(
          '4. Uso do Aplicativo',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          '4.1. Funcionalidades',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text('Você pode:', style: TextStyle(fontSize: 14)),
        SizedBox(height: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                '•  Reportar riscos ambientais, incluindo localização e fotografias, de forma voluntária.',
                style: TextStyle(fontSize: 14)),
            Text(
                '•  Confirmar relatórios de outros usuários para aumentar a precisão dos dados.',
                style: TextStyle(fontSize: 14)),
            Text(
                '•  Receber alertas sobre surtos de malária e recomendações preventivas.',
                style: TextStyle(fontSize: 14)),
            Text('•  Acessar conteúdo educacional gamificado.',
                style: TextStyle(fontSize: 14)),
            Text(
                '•  Usar funcionalidades offline, com sincronização posterior quando conectado à internet.',
                style: TextStyle(fontSize: 14)),
          ],
        ),
        SizedBox(height: 16),
        Text(
          '4.2. Regras de Conduta',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text('Você concorda em:', style: TextStyle(fontSize: 14)),
        SizedBox(height: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('•  Não enviar conteúdo falso, enganoso ou ofensivo.',
                style: TextStyle(fontSize: 14)),
            Text(
                '•  Não usar o aplicativo para fins ilegais ou não autorizados.',
                style: TextStyle(fontSize: 14)),
            Text(
                '•  Respeitar a privacidade de outros usuários e não compartilhar informações pessoais sem consentimento.',
                style: TextStyle(fontSize: 14)),
            Text(
                '•  Não tentar acessar, modificar ou interferir no funcionamento do aplicativo ou de seus servidores.',
                style: TextStyle(fontSize: 14)),
          ],
        ),
        SizedBox(height: 16),
        Text(
          '4.3. Funcionalidade Offline',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          'Algumas funcionalidades, como relatórios de risco e acesso a conteúdo educacional, estão disponíveis offline. Os dados serão sincronizados automaticamente quando uma conexão à internet estiver disponível.',
          style: TextStyle(fontSize: 14),
        ),
        SizedBox(height: 16),
        Text(
          '5. Privacidade e Proteção de Dados',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          'A privacidade dos usuários é uma prioridade. O MapaZZZ segue normas rigorosas de proteção de dados, incluindo:',
          style: TextStyle(fontSize: 14),
        ),
        SizedBox(height: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                '•  Anonimização: Relatórios de localização são voluntários e anonimizados para proteger sua identidade.',
                style: TextStyle(fontSize: 14)),
            Text(
                '•  Consentimento: Você controla quais dados (como localização ou fotos) deseja compartilhar.',
                style: TextStyle(fontSize: 14)),
            Text(
                '•  Segurança: Utilizamos medidas de segurança para proteger seus dados contra acesso não autorizado.',
                style: TextStyle(fontSize: 14)),
            Text(
                '•  Acesso por Instituições de Saúde: Dados de risco podem ser compartilhados com instituições de saúde de forma agregada e anonimizada, conforme permitido por lei.',
                style: TextStyle(fontSize: 14)),
          ],
        ),
        SizedBox(height: 8),
        Text(
          'Para mais detalhes, consulte nossa Política de Privacidade.',
          style: TextStyle(fontSize: 14),
        ),
        SizedBox(height: 16),
        Text(
          '6. Propriedade Intelectual',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          'Todo o conteúdo do aplicativo, incluindo design, código, logotipos, textos e elementos gamificados, é propriedade do MapaZZZ ou de seus licenciadores. Você não pode copiar, modificar, distribuir ou criar trabalhos derivados sem autorização expressa.',
          style: TextStyle(fontSize: 14),
        ),
        SizedBox(height: 16),
        Text(
          '7. Integração com Terceiros',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          'O MapaZZZ utiliza APIs de terceiros, como Google Maps, para fornecer funcionalidades como localização de centros de saúde. O uso dessas APIs está sujeito aos termos de serviço dos respectivos provedores. Não nos responsabilizamos por interrupções ou alterações nesses serviços de terceiros.',
          style: TextStyle(fontSize: 14),
        ),
        SizedBox(height: 16),
        Text(
          '8. Limitação de Responsabilidade',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          'O MapaZZZ é fornecido "no estado em que se encontra". Não garantimos que o aplicativo estará livre de erros, interrupções ou falhas. Não nos responsabilizamos por:',
          style: TextStyle(fontSize: 14),
        ),
        SizedBox(height: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                '•  Decisões tomadas com base nas informações fornecidas pelo aplicativo.',
                style: TextStyle(fontSize: 14)),
            Text(
                '•  Danos diretos, indiretos ou consequentes decorrentes do uso do aplicativo.',
                style: TextStyle(fontSize: 14)),
            Text(
                '•  Inacessibilidade temporária devido a manutenção ou falhas de conectividade.',
                style: TextStyle(fontSize: 14)),
          ],
        ),
        SizedBox(height: 16),
        Text(
          '9. Modificações nos Termos',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          'Podemos atualizar estes Termos e Condições periodicamente para refletir mudanças no aplicativo ou em requisitos legais. Notificaremos os usuários sobre alterações significativas por meio do aplicativo ou por outros canais. O uso continuado do MapaZZZ após as alterações implica aceitação dos novos termos.',
          style: TextStyle(fontSize: 14),
        ),
        SizedBox(height: 16),
        Text(
          '10. Rescisão',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          'Podemos suspender ou encerrar seu acesso ao MapaZZZ se você violar estes Termos e Condições ou se determinarmos que seu uso prejudica o aplicativo ou outros usuários. Você pode encerrar sua conta a qualquer momento, excluindo o aplicativo ou entrando em contato conosco.',
          style: TextStyle(fontSize: 14),
        ),
        SizedBox(height: 16),
        Text(
          '11. Lei Aplicável',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          'Estes Termos e Condições são regidos pelas leis do país onde o MapaZZZ está registrado. Qualquer disputa será resolvida nos tribunais competentes dessa jurisdição.',
          style: TextStyle(fontSize: 14),
        ),
        SizedBox(height: 16),
        Text(
          '12. Contato',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          'Se tiver dúvidas sobre estes Termos e Condições, entre em contato conosco pelo e-mail: suporte@mapazzz.org.',
          style: TextStyle(fontSize: 14),
        ),
        SizedBox(height: 16),
        Text(
          'Ao usar o MapaZZZ, você contribui para a prevenção da malária e para a proteção de comunidades vulneráveis. Obrigado por fazer parte desta missão!',
          style: TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  // Method to build the Accept/Deny buttons
  Widget _buildButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: () {
            onDeny(); // Call the provided deny function

            // Keep the dialog logic if you want it shown from here
            showCupertinoDialog(
              context: context,
              builder: (context) => CupertinoAlertDialog(
                title: const Text('Atenção'),
                content: const Text(
                    'Para continuar, você precisa aceitar os Termos e Condições.'),
                actions: [
                  CupertinoDialogAction(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the dialog
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: const Text(
            'Deny',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
        ElevatedButton(
          onPressed:
              onAccept, // Call the onAccept callback passed from SignUpScreen
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20), // Rounded corners
            ),
          ),
          child: const Text(
            'Accept',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
