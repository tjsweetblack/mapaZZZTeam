import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          // Added leading back button
          icon: const Icon(Icons.arrow_back,
              color: Colors.black), //Set arrow color
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text('Sobre o MapaZZZ',
            style: TextStyle(color: Colors.red)), // Title of the page, now red
        centerTitle: true,
        backgroundColor: Colors.white, //Set to white
        elevation: 0, //removes shadow
      ),
      backgroundColor: Colors.white, // Set background color of the entire page
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Sobre o Aplicativo MapaZZZ', // App Name
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.red, // Made title red
                ),
              ),
              const SizedBox(height: 10.0),
              const Text(
                'O MapaZZZ é um aplicativo móvel inovador desenvolvido com a missão de combater a malária por meio de monitoramento comunitário, prevenção ativa e educação acessível. Criado no âmbito do Hackathon “MapaZZZ”, o aplicativo utiliza dados em tempo real e tecnologias modernas, incluindo inteligência artificial (quando aplicável), para empoderar comunidades nas regiões mais afetadas pela malária.',
                style: TextStyle(fontSize: 16.0),
              ),
              const SizedBox(height: 20.0),
              const Text(
                'Nossa Missão',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.red, // Made title red
                ),
              ),
              const SizedBox(height: 10.0),
              const Text(
                'A malária continua sendo um desafio global, especialmente em áreas com acesso limitado a recursos de saúde. O MapaZZZ busca:',
                style: TextStyle(fontSize: 16.0),
              ),
              const SizedBox(height: 10.0),
              const Text(
                'Prevenir surtos ao identificar e mapear riscos ambientais, como poças de água estagnada, que favorecem a proliferação de mosquitos.',
                style: TextStyle(fontSize: 16.0),
              ),
              const SizedBox(height: 10.0),
              const Text(
                'Informar e educar os usuários sobre medidas preventivas de forma interativa e envolvente.',
                style: TextStyle(fontSize: 16.0),
              ),
              const SizedBox(height: 10.0),
              const Text(
                'Conectar comunidades com instituições de saúde, promovendo respostas rápidas e eficazes.',
                style: TextStyle(fontSize: 16.0),
              ),
              const SizedBox(height: 20.0),
              const Text(
                'Principais Funcionalidades',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.red, // Made title red
                ),
              ),
              const SizedBox(height: 10.0),
              const Text(
                'O MapaZZZ oferece ferramentas práticas e acessíveis para todos os usuários:',
                style: TextStyle(fontSize: 16.0),
              ),
              const SizedBox(height: 10.0),
              const Text(
                'Mapa de Risco Interativo: Permite que os usuários relatem riscos ambientais, como focos de mosquitos, com localização e fotos. Esses dados geram mapas de calor dinâmicos, com cores que indicam níveis de risco, validados pela comunidade.',
                style: TextStyle(fontSize: 16.0),
              ),
              const SizedBox(height: 10.0),
              const Text(
                'Alertas e Notificações: Envia avisos sobre surtos de malária na região do usuário, com recomendações preventivas personalizadas e, opcionalmente, suporte para pedidos de emergência ou localização de centros de saúde próximos.',
                style: TextStyle(fontSize: 16.0),
              ),
              const SizedBox(height: 10.0),
              const Text(
                'Educação Gamificada: Oferece conteúdo interativo e envolvente para ensinar sobre a malária, sua prevenção e tratamento, tornando o aprendizado acessível e divertido.',
                style: TextStyle(fontSize: 16.0),
              ),
              const SizedBox(height: 20.0),
              const Text(
                'Compromisso com a Acessibilidade',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.red, // Made title red
                ),
              ),
              const SizedBox(height: 10.0),
              const Text(
                'Sabemos que muitas regiões afetadas pela malária enfrentam desafios de conectividade. Por isso, o MapaZZZ inclui:',
                style: TextStyle(fontSize: 16.0),
              ),
              const SizedBox(height: 10.0),
              const Text(
                'Funcionalidade Offline: Permite o uso de recursos essenciais sem internet, com sincronização posterior.',
                style: TextStyle(fontSize: 16.0),
              ),
              const SizedBox(height: 10.0),
              const Text(
                'Design Inclusivo: Interface simples e intuitiva, projetada para usuários de diferentes idades e níveis de alfabetização.',
                style: TextStyle(fontSize: 16.0),
              ),
              const SizedBox(height: 20.0),
              const Text(
                'Privacidade e Segurança',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.red, // Made title red
                ),
              ),
              const SizedBox(height: 10.0),
              const Text(
                'A privacidade dos usuários é fundamental. O MapaZZZ segue rigorosas normas de proteção de dados:',
                style: TextStyle(fontSize: 16.0),
              ),
              const SizedBox(height: 10.0),
              const Text(
                'Relatórios de localização são voluntários e anonimizados.',
                style: TextStyle(fontSize: 16.0),
              ),
              const SizedBox(height: 10.0),
              const Text(
                'Dados sensíveis são protegidos com tecnologias seguras.',
                style: TextStyle(fontSize: 16.0),
              ),
              const SizedBox(height: 10.0),
              const Text(
                'Instituições de saúde acessam apenas informações agregadas e anonimizadas, respeitando sua privacidade.',
                style: TextStyle(fontSize: 16.0),
              ),
              const SizedBox(height: 20.0),
              const Text(
                'Integração com Instituições de Saúde',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.red, // Made title red
                ),
              ),
              const SizedBox(height: 10.0),
              const Text(
                'O MapaZZZ disponibiliza uma API segura para que organizações de saúde monitorem dados de risco em tempo real, permitindo respostas rápidas a potenciais surtos e alocação eficiente de recursos.',
                style: TextStyle(fontSize: 16.0),
              ),
              const SizedBox(height: 20.0),
              const Text(
                'Por que o MapaZZZ?',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.red, // Made title red
                ),
              ),
              const SizedBox(height: 10.0),
              const Text(
                'O MapaZZZ é mais do que um aplicativo — é uma ferramenta de impacto social que une tecnologia, colaboração comunitária e educação para salvar vidas. Ao usar o MapaZZZ, você se torna parte de uma rede global dedicada a reduzir o impacto da malária e proteger comunidades vulneráveis.',
                style: TextStyle(fontSize: 16.0),
              ),
              const SizedBox(height: 20.0),
              const Text(
                'Entre em Contato',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.red, // Made title red
                ),
              ),
              const SizedBox(height: 10.0),
              const Text(
                'Quer saber mais ou contribuir com nossa missão? Entre em contato pelo e-mail:',
                style: TextStyle(fontSize: 16.0),
              ),
              const SizedBox(height: 5.0),
              const Text(
                'info@ma-pa-zzz.com', // Contact Email
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue, // Keeping the email address blue
                ),
              ),
              const SizedBox(height: 20.0),
              const Text(
                'Juntos, podemos construir um futuro sem malária!',
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
