# Política de Privacidade — MapaZZZ (rascunho para publicação)

> **Nota antes de publicar — leia isto primeiro:**
> 1. Este texto foi escrito com base no que o código do app efetivamente faz (auditoria em [`protecao-dados-imagem-video.md`](./protecao-dados-imagem-video.md)), não em suposições genéricas. Não copie sem rever.
> 2. Há campos entre `[colchetes]` que precisam de ser preenchidos por vocês (identidade legal do responsável, contacto) — não inventei esses dados.
> 3. Onde o texto promete algo (ex.: prazo de conservação) que o sistema **ainda não implementa de facto**, isso está marcado com ⚠️ — publicar a promessa sem implementar o comportamento reabre exatamente o mesmo problema que acabámos de corrigir com a questão da "anonimização". Ajuste o texto para refletir a realidade atual, ou implemente o comportamento antes de publicar.
> 4. O site `ma-pa-zzz.tech/privacy-policy` está atualmente **sem conteúdo nenhum** (só menu e rodapé) — isto é mais urgente do que uma desatualização.

---

## Política de Privacidade

**Última atualização:** [DATA]

O MapaZZZ ("nós", "o app") é uma aplicação de prevenção e alerta de malária que permite reportar focos de mosquitos, consultar zonas de risco e receber recomendações. Esta política explica que dados pessoais recolhemos, porquê, com quem partilhamos e quais são os seus direitos, nos termos da Lei n.º 22/11, de 17 de Junho (Proteção de Dados Pessoais, Angola).

### 1. Quem é o responsável pelo tratamento

[NOME LEGAL DA ENTIDADE/EMPRESA RESPONSÁVEL PELO MAPAZZZ]
[ENDEREÇO]
Contacto para questões de privacidade: [EMAIL DE CONTACTO]

### 2. Que dados pessoais recolhemos

| Categoria | Dados | Quando |
|---|---|---|
| Conta | Nome, e-mail, palavra-passe (via Firebase Authentication) | No registo |
| Localização | Coordenadas GPS exatas | Ao criar um reporte e, opcionalmente, em segundo plano para alertas de proximidade a zonas de risco |
| Imagem | Fotografia tirada pela câmara do telemóvel | Ao criar um reporte de foco de mosquitos |
| Identificador do dispositivo | Token de notificações push (Firebase Cloud Messaging) | Automaticamente, para envio de alertas |
| Dados de utilização/gamificação | Pontuação, nível/rank, histórico de reportes | Durante o uso do app |

Nos termos do Art. 5.º, alínea b) da Lei 22/11, **a imagem é, por si só, um dado pessoal**, mesmo sem outra informação associada.

### 3. Para que finalidades usamos os seus dados

- Identificar e autenticar a sua conta;
- Registar e mostrar reportes de focos de malária no mapa;
- Analisar automaticamente, por inteligência artificial, se a fotografia mostra um foco real e qual o seu nível de risco;
- Gerar sugestões de solução para eliminar o foco reportado;
- Alertá-lo quando estiver perto de uma zona de risco conhecida;
- Melhorar o funcionamento do app.

Não usamos os seus dados para publicidade nem os vendemos a terceiros.

### 4. Consentimento

O tratamento dos seus dados depende do seu consentimento expresso, dado ao aceitar os Termos e Condições no registo. Adicionalmente, antes de cada envio de fotografia para análise automática por inteligência artificial, o app pede uma confirmação explícita, informando que a imagem será processada por serviços de terceiros.

### 5. Com quem partilhamos os seus dados (subprocessadores)

Para funcionar, o MapaZZZ envia dados a estes prestadores de serviço, que atuam como subprocessadores:

| Serviço | Dados enviados | Finalidade | Localização |
|---|---|---|---|
| Firebase / Google Cloud (Authentication, Firestore, Cloud Messaging) | Conta, localização, reportes, token de notificações | Infraestrutura principal do app | Servidores Google, fora de Angola |
| Google Gemini (Google AI) | Fotografia do reporte, título e descrição | Análise automática da imagem, classificação de risco, geração de texto de solução | EUA |
| [`image-validation-api.vercel.app`, `burger-image-api.vercel.app`, `risk-level-api.vercel.app`, `solution-by-ai.vercel.app` — **confirmar se são os serviços em produção**] | Fotografia do reporte | Validação, armazenamento e análise da imagem | Infraestrutura Vercel (global/EUA) |
| Google Maps | Localização aproximada, quando aplicável | Exibição do mapa | Servidores Google |

⚠️ **Antes de publicar**: confirmem se os quatro domínios `*.vercel.app` acima são mesmo os usados em produção (ver ação pendente #4 do documento de conformidade) e substituam pelos nomes reais/atualizados se forem outros.

### 6. Transferência internacional de dados

Alguns dos subprocessadores listados na secção 5 processam dados fora de Angola (nomeadamente nos Estados Unidos, no caso da Google Gemini). Nos termos dos Art. 33.º e 34.º da Lei 22/11, esta transferência internacional está sujeita a notificação e, quando aplicável, a autorização da Agência de Proteção de Dados (APD), e depende do seu consentimento para o tratamento dos dados nos termos desta política.

### 7. Por quanto tempo guardamos os seus dados

⚠️ **Preencher apenas depois de a política de retenção ser efetivamente implementada** (ver ação pendente #6 do documento de conformidade). Sugestão de texto, a ajustar à prática real:

> Conservamos os dados do seu reporte (incluindo a fotografia e a localização) enquanto a sua conta estiver ativa e pelo período adicional de [X meses] necessário para fins de segurança pública e histórico de zonas de risco, findo o qual são eliminados ou anonimizados. Pode pedir a eliminação antecipada dos seus dados a qualquer momento, através de [MEIO DE CONTACTO / opção "Excluir Conta" no site].

### 8. Segurança

Os dados são transmitidos por ligação cifrada (HTTPS). O acesso aos sistemas internos é restrito a pessoal autorizado. [Acrescentar aqui outras medidas reais aplicadas, ex.: autenticação nos serviços backend, regras de acesso à base de dados.]

### 9. Os seus direitos

Nos termos dos artigos 25.º a 29.º da Lei 22/11, tem direito a:

- **Informação** — saber que dados seus tratamos e porquê;
- **Acesso** — obter uma cópia dos seus dados;
- **Retificação** — corrigir dados incorretos ou incompletos;
- **Eliminação** — pedir o apagamento dos seus dados (respondemos em até 60 dias úteis);
- **Oposição** — opor-se ao tratamento por razões legítimas relacionadas com a sua situação particular;
- **Não ficar sujeito, sem intervenção humana, a decisões automatizadas que o afetem significativamente** — por exemplo, a classificação automática de risco de um reporte por IA pode ser revista mediante pedido.

Para exercer estes direitos, contacte-nos em [EMAIL DE CONTACTO]. Também pode apagar a sua conta diretamente através da opção "Excluir Conta" disponível no site/app.

### 10. Alterações a esta política

Podemos atualizar esta política periodicamente. Notificaremos alterações relevantes através do app ou por e-mail.

### 11. Contacto

Dúvidas sobre privacidade: [EMAIL DE CONTACTO]
Autoridade de supervisão: Agência de Proteção de Dados (APD) de Angola — [apd.ao](https://apd.ao/ao/)
