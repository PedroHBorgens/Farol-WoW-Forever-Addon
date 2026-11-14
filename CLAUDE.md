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
- Profissões: clientes modernos usam `GetProfessions` + `GetProfessionInfo`; os antigos, `GetSkillLineInfo` (o grupo
  com profissões "abandonáveis" e o grupo seguinte, das secundárias; armas e defesa ficam de fora). Não expandimos
  grupos fechados (isso mexeria na interface do jogador). Limite final do estilo clássico: 300 (`PROF_FINAL`).
- Lixo nas bolsas: clientes modernos usam `C_Container.GetContainerItemInfo` (tabela) e `C_Item.GetItemInfo`; os
  antigos, `GetContainerItemInfo`/`GetContainerItemLink` e `GetItemInfo`. Preço de venda = 11º valor de `GetItemInfo`.
  Item ainda não carregado volta `nil`: fica "pendente" e entra na próxima atualização. **Nunca vender** (o
  `test_toc.lua` proíbe as funções de vender/mover/destruir/equipar itens). `NUM_BAG_SLOTS` é validado (`LastBag`).
- Descanso de personagens deslogados: o jogo não informa; o Core **estima** (`EstimateRest`) pelas regras do estilo
  clássico — estalagem/cidade (`IsResting` ao sair) 5% do XP do nível a cada 8 h, fora 1/4 disso, máximo 150%.
  Se o WoW Forever usar outras taxas, ajuste `REST_INN_RATE`/`REST_OUT_RATE`.
- Munição e reagentes: tabela `SUPPLIES` por classe (`UnitClass` → arquivo da classe), IDs do jogo clássico; contagem
  com `C_Item.GetItemCount`/`GetItemCount` e, para munição, `GetInventoryItemCount("player", 0)`. Grupo só é
  acompanhado depois de visto (`FarolCharDB.supplySeen`). Limites em `warnings.ammoYellow/ammoRed/reagYellow/reagRed`
  (vermelho < amarelo; 0 no amarelo = sem amarelo). Se o WoW Forever usar outros IDs, ajuste `SUPPLIES`.
- Instâncias salvas: `GetNumSavedInstances`/`GetSavedInstanceInfo` (12º/11º valores = chefes mortos/total nos clientes
  modernos; o 3.3.5a não tem). A lista só existe depois de `RequestRaidInfo` → evento `UPDATE_INSTANCE_INFO`
  (`locksLoaded`). Pedido ao servidor: 1 vez no login (`isInitialLogin`) e no máximo 1 vez por minuto
  (`RequestLockouts`). Guardado em `chars[...].locks = { {n, k, b, r = data do fim} }` (máx. 20), validado ao carregar.
  São os **dois únicos** pedidos ao servidor do addon (este e a lista da guilda): nunca adicionar outro sem limite.
- Apelidos de comando (`ITEM_ALIASES`, `KEYS`, `WORDS`) não podem repetir nome: em Lua o segundo sobrescreve o
  primeiro em silêncio. Um teste do `test_toc.lua` confere. Ex.: "descanso" = pausa; XP descansado = "descansado".
- `PLAYER_ENTERING_WORLD` traz `(isInitialLogin, isReloadingUi)` nos clientes modernos; nos antigos vem sem
  argumentos e também dispara ao trocar de zona/instância. O resumo da sessão usa isso para aparecer só no login.
- No chat do WoW, `|` inicia códigos (`|c` cor, `|H` link, `|T` textura). **Barra literal = `||`.** Um teste confere
  todos os textos.
- `GetChecked()` devolve `1/nil` em clientes antigos: sempre converter com `and true or false`.

## Estrutura

```
Farol/
  Farol*.toc        4 arquivos (.toc); mesma versão em todos; ordem de carga: Core, Alarm, Loot, Warnings,
                    Appearance, Order
  Core.lua          barra (grade de células), 22 itens, tooltip, menu de opções, comandos /farol, dados salvos
  Alarm.lua         alarmes do relógio, soneca, janela e janelinha
  Loot.lua          janela de últimos saques, menus suspensos próprios, botão 👜
  Warnings.lua      avisos (durabilidade, bolsas, talentos, graus, profissões, munição, reagentes, pausa, água), "Silenciar / Lembrar em N min"
                    (2–30), janela agrupada para vários avisos, histórico 📝
  Appearance.lua    escala, fundo, tamanhos de texto/ícone, formato (uma linha / uma coluna), esconder em combate,
                    mostrar/esconder os botões rápidos 📝 👜
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
  `ns.MakeToplevel`, `ns.LayoutQuickButtons`, `ns.SetBarWidth`, `ns.ITEM_ORDER`, `ns.ITEM_ICONS`,
  `ns.GetWatchedFaction`, `ns.GetJunk`, `ns.ReadProfessions`, `ns.GetResetTimes`, `ns.GetServerClock` (hora do servidor validada: relógio, alarmes e
  resets usam só ela, nunca `GetGameTime` direto) e `ns.FormatWhen(t, longo)` (datas de histórico: "Hoje 21:42" /
  "Ontem" / "08/11"; longo = "domingo, 08/11/2026 às 21:12"; inválido = "--").
- Cada módulo adiciona seus textos em `ns.STRINGS.pt` / `ns.STRINGS.en` e usa `T("chave")`.
- **Globais:** só nomes começando com `Farol` (janelas/botões), `FarolDB`, `FarolCharDB`, `SLASH_FAROL1`,
  `Farol_ToggleWarnHistory`, `BINDING_*`. Nada de globais genéricos.
- **Dados salvos:** `FarolDB` (conta: configurações, `items`, `order`, `alarms`, `loot`, `warnings`, `chars` = ouro
  e nível dos **próprios** personagens por reino — `chars[reino][nome] = { gold, level, t, rest?, max?, inn?, locks? }`
  (descanso: XP descansado, XP do nível e se estava em estalagem/cidade, gravados ao sair), nomes sem `|`/controle
  e até 48 bytes, no máximo 20 reinos × 60 personagens; nunca nomes de outros jogadores) e
  `FarolCharDB` (personagem: `items` = histórico de saques, `warnHistory`, `lastSession` = resumo da última sessão,
  só números, salvo em `PLAYER_LOGOUT` — que também acontece no `/reload`). O Core monta o `db` limpo em
  `ADDON_LOADED` chamando o `Sanitize` de cada módulo; chaves desconhecidas são descartadas.
- **Tooltip:** dividido em seções (`TIP.perf`, `TIP.gold`, `TIP.reset`…). Cada célula tem uma área invisível de
  mouse (`AttachHover`) que mostra só as seções do item (`TIP_SECTIONS`) e repassa arrastar/clique para a barra.
  Shift, a opção `tooltipFull` ou o fundo da barra mostram tudo (`TIP_ORDER`). Listas: no máximo `LIST_MAX` (5).
- **Barra:** cada informação é uma **célula** (FontString) numa grade de **colunas alinhadas à esquerda**. O número
  de colunas é o máximo que cabe em `db.barWidth` (0 = uma linha, 1 = uma coluna, N = pixels escolhidos pela alça).
  A altura segue as linhas. Botões rápidos (📝 👜) via `ns.quickButtons` + `ns.LayoutQuickButtons()`.
- **Janelas:** todas chamam `ns.MakeToplevel(frame)` (abrem na frente; clique traz para a frente) e entram em
  `UISpecialFrames` (Esc fecha).
- **Menus suspensos:** implementação própria em `Loot.lua` (o `UIDropDownMenu` da Blizzard é obsoleto e causa taint).
- **Sliders:** usamos botões [-]/[+] (o template de slider mudou entre versões).

## Testes

```
lua5.1 tests/run.lua        # ~150 testes; deve terminar com "0 failed"
```

- `tests/wow_mock.lua`: simulador da API (modos `forever`, `wotlk` e `secret`). `H:login()`, `H:slash()`,
  `H:update(seg)`, `H:event()`, `H:bar()` (texto da barra), `H:cells()`, `H:click()`.
- Cuidados com o simulador: campos inexistentes devolvem `nil`; métodos desconhecidos (MaiúsculaInicial) viram
  no-op. Quando um teste falhar, confira primeiro se o erro é do simulador ou do addon.
- `test_fuzz.lua` bombardeia comandos, mensagens de saque e dados salvos adulterados. Novos campos salvos devem
  aparecer nele.
- `test_globals.lua` usa todas as funções e falha se aparecer qualquer global fora de `Farol…`/`BINDING_*`/
  `SLASH_FAROL1`, ou um `function Nome()` sem `local`. Esquecer o `local` é o erro mais fácil de cometer.
- Leituras do jogo que decidem quando avisar (`InCombatLockdown`, `IsInInstance`) passam por `pcall`; se falharem,
  o aviso **espera** (conta como "em combate"), nunca quebra a verificação.
- Rode também em Lua 5.4 (`lupa.lua54`): ele recusa frações em `date()` e `%d`, e pega erros que o 5.1 deixa passar.
  O 5.4 **embaralha a ordem do `pairs`** a cada execução: nunca dependa dela (use `KeepRecent`/`table.sort`). Rode o
  5.4 algumas vezes seguidas para pegar testes que só falham às vezes.
- Sem Lua instalado, dá para rodar com a biblioteca Python `lupa` (`lupa.lua51`).

## Fluxo de trabalho

1. Branch a partir do `main` atualizado.
2. Mudança + testes + README.md **e** README.pt-BR.md + `assets/curseforge-description.md` se for algo visível.
3. Subir a versão em **todos os 4 `.toc`** (`## Version:`) e registrar no `CHANGELOG.md`. Função nova e visível:
   acrescentar uma chave **no fim** de `NEWS` (Core.lua) com o texto `news_*` em PT/EN — quem atualizar vê só o que
   ainda não viu. Item novo na barra: também `desc_<item>` em PT/EN (explicação ao passar o mouse; um teste confere) e uma
   entrada em `TIP_SECTIONS` (quais seções `TIP.*` o tooltip daquele item mostra; um teste confere).
4. Pull request. O `main` é protegido: o merge exige **`test`** aprovado. Esperar também o
   **`github-advanced-security`** (AI Scan / "Code scanning AI findings": análise de segurança por IA do GitHub,
   a única automática que cobre Lua, já que o CodeQL não analisa Lua).
   - Ele é **consultivo**: não bloqueia o merge pela regra do repositório, e pode **não rodar** (depende de estar
     ligado em Settings → Advanced Security e, na versão de teste, de licença/créditos de IA do Copilot). Rodou nos
     PRs #17–#25 e parou de ser disparado a partir do #26.
   - Se ele **não rodar** (esperar alguns minutos depois do `test`), o merge só acontece com: (1) a **análise de
     segurança local completa** passando — testes em Lua 5.1 e 5.4, fuzzing, `test_globals`, varredura de APIs
     proibidas e de escrita em `_G`, procura de segredos/dados pessoais, workflow sem mudanças e um teste
     adversarial do código novo (APIs do jogo com erro, valores NaN/infinito/bloqueados, cliques fora de ordem);
     e (2) a **autorização explícita do dono** do repositório para aquele merge.
   - Nunca fechar/reabrir PR nem enviar commit vazio só para tentar disparar a verificação.
5. Pacote para o CurseForge: ZIP com **uma única pasta `Farol` na raiz e mais nada** — `LICENSE.txt` fica
   **dentro** de `Farol/` (`Farol/LICENSE.txt`). Qualquer arquivo solto na raiz do ZIP faz o CurseForge rejeitar
   ("This ZIP contains files at the top level"). O workflow gera esse pacote como *artifact* em cada execução;
   ao montar à mão: `cp LICENSE Farol/LICENSE.txt` e zipar só a pasta `Farol`. Conferir com `unzip -Z1`.
6. Sessões automatizadas não conseguem apagar branches no GitHub; isso é feito pela interface do GitHub.

## Imagens do CurseForge

`assets/curseforge/`: ilustrações 1280×720 com legenda EN/PT e selo "Illustration · Ilustração" (não são prints do
jogo). Nome dos arquivos: `farol-NN-o-que-mostra.png` (número = ordem no CurseForge; o gerador já salva com o nome
final, definido em `page("...")` no `make_pages.py`). Para regenerar: `python3 assets/curseforge/make_pages.py` e `node assets/curseforge/shoot.js` (Playwright).
Ao mudar uma janela do addon, atualize a ilustração correspondente:

| Mudança | Imagens |
|---|---|
| Item novo na barra / no tooltip | 02 (contagem de itens, grade, tooltip), 03 (caixinhas e ordem); 08 se for de progresso; 01 se for destaque |
| Opção nova no menu (Geral, idioma, botões) | 03 |
| Alarmes | 04 · Janela de saques: 05 · Avisos / histórico: 06 |
| Aparência (escala, fundo, formato, botões rápidos) | 07 (e 02 se mudar o formato da barra) |
| Resumo da sessão (textos no chat) | 09 |

As imagens saem idênticas quando não mudam (o gerador é determinístico): suba no CurseForge só as que mudaram
e apague lá as versões antigas.
