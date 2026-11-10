# Farol — guia do projeto

Guia técnico para quem trabalha no código (pessoas ou assistentes de IA). Para usar o addon, veja o
[README](README.md) / [README.pt-BR](README.pt-BR.md). Mudanças por versão: [CHANGELOG](CHANGELOG.md).

**Farol** é um addon gratuito, de código aberto e **não oficial** para **WoW Forever**: barra de informações
personalizável, alarmes, janela de saques e avisos. Publicado no CurseForge. Licença MIT.

## Regras do projeto (não negociáveis)

1. **Segurança da informação em primeiro lugar.**
2. **Só ler e mostrar.** Nada de automação: o addon nunca lança magias, move, seleciona alvos, saqueia, rola dados,
   negocia, compra, vende, conserta ou mexe nas barras de ação. O teste `test_toc.lua` falha se o código usar APIs
   proibidas (`SendChatMessage`, `SendAddonMessage`, `CastSpell`, `PickupSpell`, `PlaceAction`, `RepairAllItems`,
   `loadstring`, `RunScript`, `C_Timer`, `hooksecurefunc`, `SetCVar`, `SetBinding`…). Não remova itens dessa lista.
3. **Não enviar nada.** Nenhuma mensagem de chat ou de addon. Amigos/guilda: só **quantidades**, nunca nomes.
4. **Português e inglês em tudo** que o jogador vê (textos do jogo, README.md e README.pt-BR.md, descrição do
   CurseForge).
5. **Todo dado salvo é validado ao carregar** (tipo, faixa, NaN/infinito); valores ruins voltam ao padrão.
6. **Toda mudança vem com teste.** Nada entra no `main` sem os testes passando.
7. **Nome e aparência não oficiais:** nunca usar marcas/arte da Blizzard como se fossem do addon.

## WoW Forever: fatos técnicos que custaram descobrir

- Cliente **1.60.1**, **Interface 16001**, família *Mainline* (API moderna, a mesma do Midnight).
- O cliente lê **`Farol_Mainline.toc`** (não o `Farol.toc`). `Farol_Camelot.toc` é reserva. Ao mudar a versão do
  cliente, atualize a linha `## Interface:` (versão `1.60.1` → `16001`).
- Pasta de addons: `World of Warcraft/_forever_/Interface/AddOns/`.
- **"Secret values"** (restrições do Midnight): em combate alguns valores ficam bloqueados. Toda leitura passa por
  `pcall` / `Safe()` e `ns.IsSecret()`; se bloqueado, a barra mostra `--` em vez de dar erro.
- **Talentos no estilo clássico** (3 árvores, 1 ponto por nível a partir do 10, 51 no 60) e **magias com graus**.
- Pontos de talento não gastos: o nome da função mudou entre versões do WoW. `Warnings.lua` consulta **todas**
  (`UnitCharacterPoints`, `GetUnspentTalentPoints`, `GetNumUnspentTalents`, `C_Traits`) e uma **estimativa**
  (nível − 9 − pontos gastos via `GetTalentTabInfo`) e usa o **maior** valor. `/farol aviso status` mostra cada fonte.
- Reputação acompanhada: clientes modernos usam `C_Reputation.GetWatchedFactionData`, os antigos
  `GetWatchedFactionInfo`; o Core tenta os dois (`GetWatchedFaction`) e `/farol aviso status` mostra qual funcionou.
- Resets: `C_DateAndTime.GetSecondsUntilDailyReset` / `GetSecondsUntilWeeklyReset`; clientes antigos só têm
  `GetQuestResetTime` (diário). Valores fora da faixa (negativo, NaN, infinito, diário > 2 dias, semanal > 8 dias)
  são recusados (`ns.GetResetTimes`).
- No chat do WoW, `|` inicia códigos (`|c` cor, `|H` link, `|T` textura). **Barra literal = `||`.** Um teste confere
  todos os textos.
- `GetChecked()` devolve `1/nil` em clientes antigos: sempre converter com `and true or false`.

## Estrutura

```
Farol/
  Farol*.toc        4 arquivos (.toc); mesma versão em todos; ordem de carga: Core, Alarm, Loot, Warnings,
                    Appearance, Order
  Core.lua          barra (grade de células), itens, tooltip, menu de opções, comandos /farol, dados salvos
  Alarm.lua         alarmes do relógio, soneca, janela e janelinha
  Loot.lua          janela de últimos saques, menus suspensos próprios, botão 👜
  Warnings.lua      avisos (durabilidade, bolsas, talentos, graus), "Silenciar / Lembrar em 30 min", histórico 📝
  Appearance.lua    escala, fundo, tamanhos de texto/ícone, formato (uma linha / uma coluna), esconder em combate
  Order.lua         ordem dos itens na barra
  Bindings.xml      atalho de teclado oficial (só abre o histórico de avisos)
  Media/Farol.tga   ícone original (64×64)
tests/              suíte de testes em Lua 5.1 com simulador da API do WoW
assets/             ícones, texto do CurseForge, imagens de divulgação (assets/curseforge/ + gerador)
.github/            workflow de testes (ações fixadas por SHA) e Dependabot
```

### Arquitetura

- Arquivos compartilham a tabela `ns` (`local _, ns = ...`). O Core exporta `ns.T` (tradução), `ns.Print`,
  `ns.GetDB`, `ns.IsSecret`, `ns.frame`, `ns.UpdateText`, `ns.ApplyAppearance`, `ns.ApplyVisibility`,
  `ns.MakeToplevel`, `ns.LayoutQuickButtons`, `ns.SetBarWidth`, `ns.ITEM_ORDER`, `ns.ITEM_ICONS`.
- Cada módulo adiciona seus textos em `ns.STRINGS.pt` / `ns.STRINGS.en` e usa `T("chave")`.
- **Globais:** só nomes começando com `Farol` (janelas/botões), `FarolDB`, `FarolCharDB`, `SLASH_FAROL1`,
  `Farol_ToggleWarnHistory`, `BINDING_*`. Nada de globais genéricos.
- **Dados salvos:** `FarolDB` (conta: configurações, `items`, `order`, `alarms`, `loot`, `warnings`) e
  `FarolCharDB` (personagem: `items` = histórico de saques, `warnHistory`). O Core monta o `db` limpo em
  `ADDON_LOADED` chamando o `Sanitize` de cada módulo; chaves desconhecidas são descartadas.
- **Barra:** cada informação é uma **célula** (FontString) numa grade de **colunas alinhadas à esquerda**. O número
  de colunas é o máximo que cabe em `db.barWidth` (0 = uma linha, 1 = uma coluna, N = pixels escolhidos pela alça).
  A altura segue as linhas. Botões rápidos (📝 👜) via `ns.quickButtons` + `ns.LayoutQuickButtons()`.
- **Janelas:** todas chamam `ns.MakeToplevel(frame)` (abrem na frente; clique traz para a frente) e entram em
  `UISpecialFrames` (Esc fecha).
- **Menus suspensos:** implementação própria em `Loot.lua` (o `UIDropDownMenu` da Blizzard é obsoleto e causa taint).
- **Sliders:** usamos botões [-]/[+] (o template de slider mudou entre versões).

## Testes

```
lua5.1 tests/run.lua        # ~100 testes; deve terminar com "0 failed"
```

- `tests/wow_mock.lua`: simulador da API (modos `forever`, `wotlk` e `secret`). `H:login()`, `H:slash()`,
  `H:update(seg)`, `H:event()`, `H:bar()` (texto da barra), `H:cells()`, `H:click()`.
- Cuidados com o simulador: campos inexistentes devolvem `nil`; métodos desconhecidos (MaiúsculaInicial) viram
  no-op. Quando um teste falhar, confira primeiro se o erro é do simulador ou do addon.
- `test_fuzz.lua` bombardeia comandos, mensagens de saque e dados salvos adulterados. Novos campos salvos devem
  aparecer nele.
- Sem Lua instalado, dá para rodar com a biblioteca Python `lupa` (`lupa.lua51`).

## Fluxo de trabalho

1. Branch a partir do `main` atualizado.
2. Mudança + testes + README.md **e** README.pt-BR.md + `assets/curseforge-description.md` se for algo visível.
3. Subir a versão em **todos os 4 `.toc`** (`## Version:`) e registrar no `CHANGELOG.md`.
4. Pull request. O `main` é protegido: o merge exige **`test`** e **`github-advanced-security`** aprovados.
   Esperar as duas verificações antes do merge.
5. Pacote para o CurseForge: ZIP com **uma única pasta `Farol` na raiz e mais nada** — `LICENSE.txt` fica
   **dentro** de `Farol/` (`Farol/LICENSE.txt`). Qualquer arquivo solto na raiz do ZIP faz o CurseForge rejeitar
   ("This ZIP contains files at the top level"). O workflow gera esse pacote como *artifact* em cada execução;
   ao montar à mão: `cp LICENSE Farol/LICENSE.txt` e zipar só a pasta `Farol`. Conferir com `unzip -Z1`.
6. Sessões automatizadas não conseguem apagar branches no GitHub; isso é feito pela interface do GitHub.

## Imagens do CurseForge

`assets/curseforge/`: ilustrações 1280×720 com legenda EN/PT e selo "Illustration · Ilustração" (não são prints do
jogo). Para regenerar: `python3 assets/curseforge/make_pages.py` e `node assets/curseforge/shoot.js` (Playwright).
Ao mudar uma janela do addon, atualize a ilustração correspondente.
