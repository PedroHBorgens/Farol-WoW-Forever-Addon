# Security policy / Política de segurança

## Reporting a vulnerability / Como relatar uma falha

**Please do not open a public issue for security problems.** Use GitHub's private reporting instead:
**Security → Report a vulnerability** on this repository. Only the maintainer will see it.

**Não abra uma issue pública para problemas de segurança.** Use o relato privado do GitHub:
**Security → Report a vulnerability** neste repositório. Só o mantenedor vê o relato.

Never include passwords, account details or personal data in a report. / Nunca inclua senhas, dados da conta ou
dados pessoais no relato.

## Supported versions / Versões atendidas

Only the latest release on CurseForge and the `main` branch receive fixes. / Só a versão mais recente no CurseForge
e o branch `main` recebem correções.

## What Farol does and does not do / O que o Farol faz e não faz

- Only **reads and displays** information through the official add-on API. No automation: it never casts, moves,
  targets, loots, trades, buys, sells or changes your action bars. / Só **lê e mostra** informações pela API oficial;
  nenhuma automação.
- **Sends nothing**: no chat or add-on messages, no network access (add-ons cannot reach the internet). / **Não envia
  nada**: nenhuma mensagem de chat ou de addon.
- Friends and guild items read **counts only**, never names. / Amigos e guilda: só **quantidades**, nunca nomes.
- Saved data (`FarolDB`, `FarolCharDB`) holds only settings, alarms, your own loot links and warning texts, and is
  **validated on load**. / Os dados salvos guardam só configurações, alarmes, seus links de saque e textos de avisos, e
  são **validados ao carregar**.

## How this is enforced / Como isso é garantido

- Automated tests (`tests/`) run on every push and pull request, including:
  - a scan that fails if the code uses automation, messaging or dynamic-code APIs;
  - fuzzing with random and malicious commands, chat messages and tampered saved data.
- The `main` branch is protected: changes only by pull request with passing tests and code scanning.
- GitHub Actions run with read-only permissions, no secrets, `persist-credentials: false`, and actions pinned by
  commit SHA (kept up to date by Dependabot).
