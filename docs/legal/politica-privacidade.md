# Política de Privacidade — MapaZZZ

**Última atualização:** [DATA]

O MapaZZZ ("nós", "o app") é uma aplicação de prevenção e alerta de malária que permite reportar focos de mosquitos, consultar zonas de risco, avaliar a probabilidade de epaludismo a partir de sintomas e receber recomendações. Esta política explica que dados pessoais recolhemos, porquê, com quem partilhamos e quais são os seus direitos, nos termos da Lei n.º 22/11, de 17 de Junho (Proteção de Dados Pessoais, Angola).

## 1. Quem é o responsável pelo tratamento

[NOME LEGAL DA ENTIDADE RESPONSÁVEL PELO MAPAZZZ]
[ENDEREÇO]
Contacto para questões de privacidade: [EMAIL DE CONTACTO]

## 2. Que dados pessoais recolhemos

| Categoria | Dados | Quando |
|---|---|---|
| Conta | Nome, e-mail, palavra-passe (via Firebase Authentication) | No registo |
| Localização | Coordenadas GPS exatas | Ao criar um reporte e, enquanto a app está a ser utilizada, para o alertar da proximidade de zonas de risco |
| Imagem | Fotografia tirada pela câmara do telemóvel | Ao criar um reporte de foco de mosquitos |
| **Dados de saúde** | Descrição de sintomas que nos fornece | Ao usar a funcionalidade de avaliação de probabilidade de epaludismo |
| Identificador do dispositivo | Token de notificações push (Firebase Cloud Messaging) | Automaticamente, para envio de alertas |
| Dados de utilização/gamificação | Pontuação, nível/rank, histórico de reportes, resultados de quiz | Durante o uso do app |

Nos termos do Art. 5.º, alínea b) da Lei 22/11, **a imagem é, por si só, um dado pessoal**, mesmo sem outra informação associada.

A **descrição de sintomas** que fornece na avaliação de epaludismo constitui **dado pessoal sensível** (dado relativo à saúde). Só a tratamos com o seu consentimento expresso e exclusivamente para lhe devolver uma estimativa de probabilidade. **A estimativa apresentada não é um diagnóstico médico** e não substitui a observação por um profissional de saúde.

## 3. Para que finalidades usamos os seus dados

- Identificar e autenticar a sua conta;
- Registar e mostrar reportes de focos de malária no mapa;
- Analisar automaticamente, por inteligência artificial, se a fotografia mostra um foco real e qual o seu nível de risco;
- Gerar sugestões de solução para eliminar o foco reportado;
- Estimar a probabilidade de epaludismo a partir dos sintomas que descreve;
- Alertá-lo quando estiver perto de uma zona de risco conhecida;
- Melhorar o funcionamento do app.

Não usamos os seus dados para publicidade nem os vendemos a terceiros.

## 4. Consentimento

O tratamento dos seus dados depende do seu consentimento expresso, dado ao aceitar os Termos e Condições no registo. Adicionalmente, antes do primeiro envio de fotografia para análise automática por inteligência artificial, o app pede uma confirmação explícita, informando que a imagem será processada por serviços de terceiros.

Pode retirar o consentimento a qualquer momento, contactando-nos em [EMAIL DE CONTACTO]. A retirada do consentimento implica a cessação do tratamento e, se assim o pedir, a eliminação dos dados já recolhidos.

## 5. Com quem partilhamos os seus dados (subprocessadores)

Para funcionar, o MapaZZZ envia dados a estes prestadores de serviço, que atuam como subprocessadores:

| Serviço | Dados enviados | Finalidade | Localização |
|---|---|---|---|
| Firebase / Google Cloud (Authentication, Firestore, Cloud Messaging, Analytics) | Conta, localização, reportes, token de notificações, eventos de utilização | Infraestrutura principal do app | Servidores Google, fora de Angola |
| Google Gemini (Google AI) | Fotografia do reporte, título e descrição, descrição de sintomas | Análise da imagem, classificação de risco, geração de texto de solução, estimativa de epaludismo | EUA |
| Google Maps | Localização, para exibição e interação com o mapa | Exibição do mapa | Servidores Google |
| `image-validation-api.vercel.app` | Fotografia do reporte | Validar se a foto mostra um foco real | Infraestrutura Vercel (global/EUA) |
| `burger-image-api.vercel.app` | Fotografia do reporte | Armazenamento da imagem e devolução do URL | Infraestrutura Vercel (global/EUA) |
| `risk-level-api.vercel.app` | Fotografia e descrição do reporte | Classificação do nível de risco (1–3) | Infraestrutura Vercel (global/EUA) |
| `solution-by-ai.vercel.app` | Fotografia e descrição do reporte | Geração do texto de solução | Infraestrutura Vercel (global/EUA) |
| `epaludismo-api.vercel.app` | **Descrição de sintomas** | Estimativa da probabilidade de epaludismo | Infraestrutura Vercel (global/EUA) |
| `contagemapi-sable.vercel.app` | Data e idioma de conclusão de quiz | Contagem estatística de utilização | Infraestrutura Vercel (global/EUA) |

## 6. Transferência internacional de dados

Alguns dos subprocessadores listados na secção 5 processam dados fora de Angola, nomeadamente nos Estados Unidos. Nos termos dos Art. 33.º e 34.º da Lei 22/11, esta transferência internacional está sujeita a notificação e, quando aplicável, a autorização da Agência de Proteção de Dados (APD), e depende do seu consentimento para o tratamento dos dados nos termos desta política.

## 7. Por quanto tempo guardamos os seus dados

Conservamos os dados da sua conta enquanto esta se mantiver ativa.

Os dados dos seus reportes (incluindo fotografia e localização) são conservados enquanto forem necessários ao histórico de zonas de risco e às finalidades de saúde pública descritas na secção 3.

Pode pedir a eliminação dos seus dados a qualquer momento através de [EMAIL DE CONTACTO], e responderemos no prazo previsto na secção 9.

## 8. Segurança

Os dados são transmitidos por ligação cifrada (HTTPS). Os serviços de análise que recebem as suas fotografias e sintomas exigem autenticação por chave, não aceitando pedidos anónimos. O acesso aos sistemas internos é restrito a pessoal autorizado.

Os reportes que publica no mapa são visíveis por outros utilizadores da aplicação, mas **sem o seu nome**: aparecem identificados apenas como "Membro da comunidade".

## 9. Os seus direitos

Nos termos dos artigos 25.º a 29.º da Lei 22/11, tem direito a:

- **Informação** — saber que dados seus tratamos e porquê;
- **Acesso** — obter uma cópia dos seus dados;
- **Retificação** — corrigir dados incorretos ou incompletos;
- **Eliminação** — pedir o apagamento dos seus dados (respondemos em até 60 dias úteis);
- **Oposição** — opor-se ao tratamento por razões legítimas relacionadas com a sua situação particular;
- **Não ficar sujeito, sem intervenção humana, a decisões automatizadas que o afetem significativamente** — a classificação automática de risco de um reporte e a estimativa de probabilidade de epaludismo podem ser revistas mediante pedido.

Para exercer qualquer destes direitos, incluindo a eliminação da sua conta e dos dados associados, contacte-nos em [EMAIL DE CONTACTO].

## 10. Menores

O MapaZZZ não se destina a menores de [IDADE] anos. Se tomarmos conhecimento de que recolhemos dados de um menor sem o consentimento de quem exerce as responsabilidades parentais, eliminamo-los.

## 11. Alterações a esta política

Podemos atualizar esta política periodicamente. Notificaremos alterações relevantes através do app ou por e-mail.

## 12. Contacto

Dúvidas sobre privacidade: [EMAIL DE CONTACTO]
Autoridade de supervisão: Agência de Proteção de Dados (APD) de Angola — [apd.ao](https://apd.ao/ao/)
