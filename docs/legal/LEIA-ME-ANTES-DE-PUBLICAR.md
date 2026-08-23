# Antes de publicar a Política de Privacidade

## Ficheiros

- `privacy-policy.html` — página autónoma, pronta a servir em `ma-pa-zzz.tech/privacy-policy`
- `politica-privacidade.md` — mesmo conteúdo em Markdown, para colar num CMS

Os campos por preencher aparecem realçados a amarelo na página. São 5:
identidade legal do responsável, endereço, e-mail de contacto, data e idade mínima.
**Enquanto estiverem realçados, a página não está pronta.**

## Condição para publicar: a app em produção tem de vir desta branch

Duas afirmações do texto dependem de código que **não existe na `main`**:

| Afirmação | `main` | esta branch (`integracao/piloto`, base `dcaliqui`) |
|---|---|---|
| Secção 4 — pede confirmação antes de enviar a foto para IA | ❌ não existe | ✅ `_ensurePhotoAnalysisConsent` |
| Secção 8 — reportes aparecem como "Membro da comunidade" | ❌ mostra o nome real | ✅ implementado |

Nesta branch ambas são verdadeiras, pelo que a política pode ser publicada
assim que a app distribuída aos utilizadores for construída a partir daqui.

**Não publicar enquanto se distribuir a `main`** — seria afirmar publicamente
salvaguardas que essa versão não tem, exatamente o problema da "anonimização"
que o documento de conformidade identificou.

## Correções feitas ao rascunho, verificadas no código

1. **Dados de saúde acrescentados.** `epaludismo-api.vercel.app` recebe
   `symptomsDescription` — descrição de sintomas do utilizador. É dado sensível
   e não constava do rascunho nem do documento de conformidade. Acrescentada
   linha na tabela da secção 2, secção sobre não ser diagnóstico médico, e
   entrada na tabela de subprocessadores.

2. **Subprocessadores: 6 endpoints, não 4.** Além dos quatro conhecidos, o
   código chama `epaludismo-api.vercel.app` e `contagemapi-sable.vercel.app`.
   Todos confirmados por leitura do código, pelo que a nota "confirmar se são os
   serviços em produção" foi removida.

3. **Localização em segundo plano — removido.** O rascunho dizia que a
   localização é recolhida "opcionalmente, em segundo plano". Não é: a
   verificação de proximidade corre num temporizador enquanto a app está aberta,
   e o `UIBackgroundModes` do iOS não declara `location`. Afirmar o contrário
   seria declarar uma recolha mais intrusiva do que a real.

4. **"Excluir Conta" — removido.** O rascunho dizia que a conta pode ser apagada
   pela opção "Excluir Conta" no site/app. Essa opção **não existe na app**, em
   nenhuma das branches. O texto passa a encaminhar para o e-mail de contacto.
   ⚠️ Confirmem se existe mesmo no site; se não existir em lado nenhum, é uma
   promessa por cumprir — e a Apple exige eliminação de conta dentro da app
   (Guideline 5.1.1(v)) para aprovar a submissão.

5. **Retenção reescrita.** O rascunho tinha `[X meses]` por preencher e avisava
   para não publicar sem a política de retenção implementada. Como não está
   implementada, o texto passa a descrever a prática real (conservação enquanto
   necessária) em vez de prometer um prazo que ninguém aplica.

6. **Google Analytics acrescentado** à linha do Firebase — a app passou a
   registar eventos de utilização na branch `fix/preparacao-piloto`.

7. **Secção de menores acrescentada** — em falta no rascunho.

## Continua por resolver (fora do código)

- Rodar a chave Gemini exposta no histórico do git
- Notificação/autorização junto da APD — com dados de saúde pelo meio, é
  provável que passe de simples notificação a **autorização prévia**; vale a
  pena confirmar com quem vos apoia juridicamente
- Auditar as regras do Firestore
