# Documento de Conformidade — Transmissão, Armazenamento e Processamento de Imagem/Vídeo de Utilizadores

| | |
|---|---|
| **Âmbito** | Funcionalidade de reporte de focos de malária (captura de foto → validação/análise por IA → registo no mapa), app MapaZZZ |
| **Data** | 2026-08-05 |
| **Base legal analisada** | Lei n.º 22/11, de 17 de Junho (Proteção de Dados Pessoais, Angola) + boas práticas internacionais equivalentes ao RGPD/GDPR, usadas como referência onde a lei angolana é omissa |

---

## Índice

1. [Como os dados fluem hoje](#1-como-os-dados-fluem-hoje)
2. [O que já cumpríamos](#2-o-que-já-cumpríamos)
3. [O que estava em falta](#3-o-que-estava-em-falta)
4. [O que foi retificado](#4-o-que-foi-retificado)
5. [O que falta agora](#5-o-que-falta-agora)
6. [Conclusão e risco residual](#6-conclusão-e-risco-residual)

---

## 1. Como os dados fluem hoje

1. **Captura** — `lib/features/report/ui/screens/create_report.dart`: foto tirada com o plugin `camera` (sem opção de galeria). A permissão de câmara é apenas o diálogo nativo do sistema operativo.
2. **Transmissão** — a mesma foto é enviada a **quatro serviços externos diferentes**, todos em HTTPS:
   - `image-validation-api.vercel.app` (valida se a foto mostra um foco real);
   - `burger-image-api.vercel.app` (guarda a foto e devolve o URL público);
   - `risk-level-api.vercel.app` (classifica o nível de risco 1–3);
   - `solution-by-ai.vercel.app` (gera texto de solução via IA).

   Estes quatro domínios **não fazem parte deste repositório** — não é possível auditar o código deles. Em paralelo existe, dentro do repositório, uma implementação Node.js equivalente (`imageAnalysis-api/`, `malaria-api/`) que usa a **Google Gemini** para o mesmo efeito; não ficou confirmado se é essa a que está de facto em produção nos quatro domínios acima.
3. **Armazenamento** — o URL da foto, as coordenadas GPS exatas e o `userId` do autor ficam gravados **permanentemente no mesmo documento** da coleção `reports` no Firestore, sem prazo de expiração.
4. **Processamento** — feito por Google Gemini (serviço de terceiro, fora de Angola).

---

## 2. O que já cumpríamos

| Requisito legal/boas práticas | Situação |
|---|---|
| Transmissão em canal cifrado (Art. 30.º da Lei 22/11) | ✅ Todos os endpoints usam HTTPS |
| Consentimento geral para tratamento de dados (Art. 12.º) | ✅ Ecrã de Termos e Condições com aceitação obrigatória antes do registo (`lib/screens/signup/ui/terms_of_service.dart`), incluindo secção "Privacidade e Proteção de Dados" |
| Existência de política de privacidade | ⚠️ Parcial — há um link (`ma-pa-zzz.tech/privacy-policy`), mas é externo, não auditável a partir deste repositório e o app não controla o conteúdo publicado lá |
| Finalidade determinada e explícita (Art. 9.º) | ✅ A foto só é usada para validar/classificar risco de malária — sem reaproveitamento visível para outros fins |

---

## 3. O que estava em falta

Levantamento do estado **antes** desta intervenção:

| # | Não conformidade encontrada | Norma/princípio violado |
|---|---|---|
| 1 | Chave de API da Google Gemini em texto simples, **comitada no repositório git** (`imageAnalysis-api/.env`, `malaria-api/.env`) | Art. 30.º/31.º — medidas técnicas de segurança |
| 2 | Os 4 endpoints backend (Node.js) não tinham **nenhuma autenticação** — qualquer pedido anónimo era processado e faturado contra a chave da Google | Art. 30.º/31.º — medidas técnicas de segurança |
| 3 | Ficheiro temporário da imagem no disco do servidor (`generateSolution-api.js`) não era necessariamente apagado se a chamada à IA falhasse | Art. 11.º — duração/eliminação dos dados |
| 4 | Nome real do autor do reporte era **exposto publicamente** a qualquer utilizador que abrisse o reporte, contradizendo diretamente a promessa de "anonimização" no ecrã de Termos (`terms_of_service.dart:216`) | Art. 6.º — transparência/veracidade da informação prestada; princípio da minimização (Art. 9.º/11.º) |
| 5 | Nenhum aviso/consentimento específico dentro do fluxo de reporte, informando que a foto é enviada a serviços de IA de terceiros, antes de a câmara ser ativada | Art. 12.º/13.º — consentimento inequívoco e informado |

---

## 4. O que foi retificado

Correções aplicadas diretamente no código nesta intervenção, mapeadas 1:1 aos pontos da secção 3:

| # | Correção aplicada | Ficheiro(s) alterado(s) |
|---|---|---|
| 1 | `.env` removidos do índice do git, adicionados ao `.gitignore`; criados `.env.example` como modelo sem segredos reais | `.gitignore`, `imageAnalysis-api/.env.example`, `malaria-api/.env.example` |
| 2 | Middleware de autenticação por chave partilhada (`x-api-key` + `REPORT_API_SHARED_SECRET`) adicionado aos 4 endpoints | `imageAnalysis-api/index.js`, `malaria-api/index.js`, `malaria-api/riskAnalysis-api.js`, `malaria-api/generateSolution-api.js` |
| 3 | `fs.unlinkSync` movido para bloco `finally`, garantindo remoção do ficheiro temporário mesmo quando a chamada à IA falha | `malaria-api/generateSolution-api.js` |
| 4 | Deixou de se pedir o campo `name` ao Firestore; o ecrã passa a mostrar sempre um rótulo anonimizado ("Membro da comunidade"), mantendo apenas o distintivo de rank (não identificável) | `lib/features/report/ui/screens/report_details.dart` |
| 5 | Diálogo de consentimento explícito (`_ensurePhotoAnalysisConsent`) mostrado antes de a câmara iniciar, na primeira utilização, exigindo toque em "Concordo e continuar"; a escolha fica guardada localmente | `lib/features/report/ui/screens/create_report.dart` |

`flutter analyze` e `node --check` foram executados após as alterações — nenhum erro novo introduzido.

---

## 5. O que falta agora

Ações que **exigem acesso a sistemas externos ou uma decisão de produto/negócio** e não puderam ser executadas nesta sessão, por ordem de urgência:

1. 🔴 **Rodar/revogar a chave Gemini exposta** (`AIzaSyDAymo...`) na consola do Google Cloud e gerar uma nova. A chave antiga continua acessível no **histórico** do git mesmo depois da remoção feita agora — apagá-la do histórico exigiria reescrever o repositório (`git filter-repo`/BFG + force-push), uma operação destrutiva que só deve ser feita com autorização explícita e coordenação com todos os colaboradores. Tratar a chave como definitivamente comprometida, independentemente de se reescrever o histórico.
2. 🟠 **Notificação/autorização prévia junto da Agência de Proteção de Dados (APD)** para o tratamento de imagem + geolocalização associadas a identidade de utilizador (Art. 35.º–38.º) — passo administrativo em [apd.ao](https://apd.ao/ao/), não uma alteração de código.
3. 🔴 **Publicar conteúdo na Política de Privacidade** — verificação direta em 2026-08-05 confirmou que `ma-pa-zzz.tech/privacy-policy` está **sem qualquer conteúdo real** (só menu e rodapé), apesar de ser o link para o qual o app remete os utilizadores em 4 pontos do código. Isto é mais grave do que uma desatualização: não existe hoje nenhuma política de privacidade publicada, o que por si só é uma não-conformidade com o Art. 25.º (dever de informação). Redigi um rascunho completo, pronto a rever e publicar, em [`politica-privacidade-draft.md`](./politica-privacidade-draft.md) — cobre os subprocessadores (Google Gemini/EUA, os quatro serviços `*.vercel.app`, Firebase/Google Cloud) e a transferência internacional (Art. 33.º/34.º). **Não consigo publicar isto diretamente**: o site (aparenta ser Next.js/Vercel) não está neste repositório nem em nenhum projeto acessível nesta máquina — falta o acesso ao código-fonte ou ao CMS desse site.
4. 🟡 **Confirmar a identidade real dos quatro serviços `*.vercel.app`** usados em produção pelo cliente Flutter — não pertencem a este repositório, pelo que não foi possível auditar retenção/segurança nem confirmar se têm as mesmas proteções agora aplicadas aos equivalentes locais.
5. 🟡 **Auditar as regras do Firestore** (`firestore.rules` não existe neste repositório) diretamente na consola Firebase, para confirmar quem pode ler a coleção `reports` (foto + GPS + `userId`).
6. 🟡 **Definir e implementar uma política de retenção** dos reportes antigos (Art. 11.º exige conservação só pelo tempo necessário à finalidade) — ex.: apagar ou anonimizar reportes com mais de X meses, tipicamente via Cloud Function agendada.
7. 🟢 **Gerar e configurar `REPORT_API_SHARED_SECRET`** nos ambientes onde `imageAnalysis-api/`/`malaria-api/` estão implantados, e decidir se o cliente Flutter passa a chamar estes endpoints em vez dos quatro domínios `*.vercel.app` de origem desconhecida — decisão de arquitetura ainda em aberto.

---

## 6. Conclusão e risco residual

- **5 problemas corrigidos diretamente no código** nesta sessão.
- **7 ações pendentes**, duas delas 🔴 urgentes: rotação da chave Gemini já exposta, e publicação de conteúdo real na Política de Privacidade (a página está atualmente vazia — rascunho já preparado em [`politica-privacidade-draft.md`](./politica-privacidade-draft.md)).
- O maior **risco legal residual**: os Termos de Serviço prometem "anonimização", mas o `userId` continua ligado à foto e ao GPS na base de dados — a correção de hoje resolve a exposição *visível na app* (o nome deixa de ser mostrado a outros utilizadores), mas não implementa uma desassociação real de identidade no armazenamento. Enquanto isso não existir, a palavra "anonimizado" nos Termos é juridicamente arriscada — decisão de produto/jurídica a tomar, não uma correção técnica isolada.
