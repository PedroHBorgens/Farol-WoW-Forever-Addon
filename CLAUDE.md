# Farol — guia do projeto

Guia técnico para quem trabalha no código (pessoas ou assistentes de IA). Para usar o addon, veja o
[README](README.md) / [README.pt-BR](README.pt-BR.md). Mudanças por versão: [CHANGELOG](CHANGELOG.md).

**Farol** é um addon gratuito, de código aberto e **não oficial** para **WoW Forever**: barra de informações
personalizável, alarmes, janela de saques e avisos. Publicado no CurseForge: <https://www.curseforge.com/wow/addons/farol>. Licença MIT.

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
8. **Função nova vem desligada.** O jogador decide o que liga; atualizar o addon nunca liga nada sozinho. Só vem
   ligado por padrão o que está nas listas aprovadas pelo dono em `tests/test_defaults.lua` (itens da barra, avisos,
   opções gerais e padrões `x ~= false`); o teste falha se aparecer outro. Novidade ligada a item/aviso entra em
   `Profiles.NEWS_ITEM`/`NEWS_WARN` (Core) para a mensagem de novidades dizer "desligado (ligue em Menu > ...)".

## WoW Forever: fatos técnicos que custaram descobrir

- Cliente **1.60.1**, **Interface 16001**, família *Mainline* (API moderna, a mesma do Midnight).
- **O jogo nem sempre responde como a documentação diz (3.18).** Antes de usar uma API, pergunte: (1) e se vier `""`
  em vez de `nil` (reino vazio)? (2) o que o 2º/3º retorno significa *aqui* (no Forever o 2º de `UnitName` é o
  sobrenome, não o reino)? (3) funciona na hora em que vou ler — antes do `PLAYER_LOGIN`, em combate, no
  `PLAYER_LOGOUT` (ouro 0)? Ao sair, leitura que falhou **nunca apaga** o que já estava salvo (`RecordCharacter`
  mantém descanso e instâncias). Em dúvida, peça ao dono um `/run print(...)` no jogo **antes** do merge, e acrescente
  a resposta real ao simulador (modo `Mock.REAL`). Ouro só por `Profiles.Money()`; nome/reino só por
  `Profiles.ReadIdentity()`/`CurrentCharacter` (o `test_forever_real.lua` falha se outro arquivo chamar `GetMoney`,
  `GetRealmName`, `GetNormalizedRealmName`, `UnitName("player")` ou `UnitFullName`).
- **`/farol diagnostico` (Diag.lua, 3.18):** mostra no chat do jogador as leituras cruas (nome, sobrenome, reino,
  ouro), o último logout (`FarolCharDB.diag = { lz = o jogo deu 0 de ouro, t }`, validado) e contagens de eventos só
  na memória (`QUEST_TURNED_IN`, `QUEST_COMPLETE`, `QUEST_ACCEPTED`, mensagem `ERR_QUEST_COMPLETE_S`, `PLAYER_MONEY`).
  Ao descobrir outro comportamento estranho do jogo, acrescente uma linha ao diagnóstico.
- **De onde vem o XP e o ouro (Sources.lua, 3.19):** XP de missão = `xpReward` do `QUEST_TURNED_IN(id, xp, ouro)`;
  monstros = XP em luta ou até 3 s depois (`PLAYER_REGEN_*`); ouro de saque = com `LOOT_OPENED` aberto (+1 s);
  comerciante = entre `MERCHANT_SHOW`/`MERCHANT_CLOSED` (+ vendas, − compras/consertos). Sem valor na entrega, conta a
  mudança até 2 s antes/depois. "Outros" = total da sessão − as outras (a soma sempre bate). O XP chega pelo
  `SampleXP` do Core (`Sources.OnXP`); `ResetSession` chama `Sources.Reset`. Sem "por hora" por origem (o jogo não
  diz o tempo de cada atividade). Resumo salvo: `lastSession.src = { qx, mx, ox, qn, qg, lg, sg, bg, og }` (validado).
  Confirmado no jogo (3.19): o WoW Forever informa o XP e o ouro da recompensa no `QUEST_TURNED_IN` (ex.: XP 3131,
  18s); missão sem moedas vem com ouro 0.
- **Janela de chat (3.20):** todo texto do Farol passa por `Print` (Core), que escreve com `AddMessage` na janela
  escolhida (`FarolDB.chatWindow` = nome de uma aba do jogador; "" = chat principal; `Profiles.ChatWindows` lê
  `GetChatWindowInfo(i)` + `ChatFrame<i>`, só abas mostradas/encaixadas). Aba que sumiu ou deu erro = chat principal.
  O Farol **nunca** cria/renomeia/configura abas (`FCF_*`, `SetChatWindow*`, grupos de mensagens: proibidos no
  `test_toc.lua`). Módulo novo: use `ns.Print`, nunca `DEFAULT_CHAT_FRAME:AddMessage` direto.
- O cliente lê **`Farol_Mainline.toc`** (não o `Farol.toc`). `Farol_Camelot.toc` é reserva. Ao mudar a versão do
  cliente, atualize a linha `## Interface:` (versão `1.60.1` → `16001`).
- Pasta de addons: `World of Warcraft/_forever_/Interface/AddOns/`.
- **Personagem (3.15.1):** o WoW Forever devolve `GetRealmName() == ""` e tem sobrenome: `UnitName("player")` =
  ("Oxis", "Raknash"). `CurrentCharacter` usa nome + sobrenome ("Oxis Raknash") e o reino de reserva
  `Profiles.REALM_FALLBACK` ("-", mostrado como "este reino" por `Profiles.RealmLabel`). Nunca mostre o "-" cru: use
  `ns.RealmLabel`. `/farol aviso status` mostra como o personagem foi identificado.
- **Ouro ao sair (3.17.1):** no `PLAYER_LOGOUT` o WoW Forever devolve `GetMoney() == 0` — confirmado com o
  `/farol diagnostico` (3.18): acontece na **saída de verdade** (voltar à seleção de personagens/sair do jogo); no
  `/reload` o ouro vem certo. O simulador dá 0 nos dois casos (mais rígido, de propósito). Leia o ouro só por
  `Profiles.Money()` (guarda `Profiles.lastMoney` durante o jogo e no `PLAYER_MONEY`; com `Profiles.loggingOut` devolve
  a última leitura). Nunca chame `GetMoney` direto no que roda ao sair (ouro dos personagens, resumo da sessão).
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
- **Nunca valide vários retornos com `ipairs({ a, b, c })`**: o `ipairs` para no primeiro `nil` e deixa passar um valor
  ausente (já causou erro no arrasto do botão do minimapa). Use índice fixo (`for i = 1, n`) ou trate `nil` antes.
- Metas de farm: contagem com `C_Item.GetItemCount(id, true)`/`GetItemCount(id, true)` (o `true` inclui o banco quando
  o cliente informa). Do link (Shift + clique) só se lê o número e o nome do item; nada é guardado do link. Busca pelo
  nome: `GetItemInfo(nome)`, depois bolsas, depois o histórico de saques. A contagem do início da sessão fica só na
  memória (recomeça se a quantidade cair, ex.: vendeu/usou).
- Diário de missões: modernos `C_QuestLog` (`GetNumQuestLogEntries`, `GetInfo`, `IsComplete`, `IsFailed`,
  `GetQuestObjectives`, `GetMaxNumQuestsCanAccept`); antigos `GetQuestLogTitle` — a ordem muda: quando o 4º valor é
  número (grupo sugerido do 3.3.5a), categoria/fechada/completa andam uma posição; completa = 1 (pronta) ou -1 (falhou).
  Limite: `GetMaxNumQuestsCanAccept` → `MAX_QUESTLOGQUESTS` → 20. Nunca abrir categorias fechadas (só avisar no tooltip).
- Pedra de Regresso: item 6948; lugar com `GetBindLocation`; recarga com `C_Container.GetItemCooldown` (modernos) ou
  `GetItemCooldown` (antigos) — duração ≤ 1,5 s é a recarga global e não conta. Sem lugar informado, o item some da barra.
- Item da barra **ausente** nos dados salvos (item novo para quem já usa) vem **desligado**; o padrão de `ITEM_DEFAULTS`
  só vale em instalação nova (sem lista de itens salva). Valor inválido volta ao padrão.
- **Cores de estado só pela paleta `ns.C`** (`good`/`warn`/`bad`/`dim`, Core): nunca escreva `|cff40ff40` etc. nos
  módulos (um teste do `test_a11y.lua` confere). `Profiles.ApplyPalette()` troca a paleta pela opção `colorblind`
  (azul `66b3ff` / amarelo / laranja `ff8a33`; padrão verde / amarelo / vermelho `ff6666`). Texto de apoio: `ns.Dim(fs)`
  (cinza 0,75), não `GameFontDisable`. Campos de número: `box.farolApply` + `ns.TabChain(lista)` (Tab grava só se mudou).
  `ns.MakeToplevel` também põe o fundo opaco (`frame.farolBacking`). Selos dos botões 📝 👜 também via `ns.C` (nada de
  `badge:SetTextColor`); `Profiles.SetColorblind` repinta na hora. Ouro: número na cor do texto, cor só em g/s/c
  (`FormatMoney`): amarelo é só "atenção". **Textos descrevem o estado, não a cor** ("bom/atenção/alerta",
  limites "atenção/crítico"): com a opção de daltonismo, verde/vermelho viram azul/laranja (`test_copy.lua` confere).
- **Plurais e "Limpar" (3.13.1):** nada de "(s)"/"(ns)" (só em textos de diagnóstico `*_status`/`*_usage`): chave
  normal = plural e `<chave>_1` = singular, com os mesmos `%d/%s`; use `ns.TN(chave, n)`. Botão que apaga uma lista
  usa `ns.ConfirmClick(botão, n, "chave_ask", ação)`: 1º clique pergunta "Apagar N itens?", 2º em até 5 s faz;
  lista vazia faz direto; quem atualiza a janela zera `botão.farolAsk`.
- **Dados salvos enormes (3.13.2):** um arquivo adulterado pode ter centenas de milhares de itens ou nomes com
  megabytes de espaços. No `Sanitize`, listas usam `ns.KeepLast(lista, máx., limpar)` (pega os mais recentes do fim
  para o começo, linear) — nunca `while #l > máx. do table.remove(l, 1) end` — e textos usam `ns.Trim(texto)` (corta em
  1024 bytes e apara em tempo linear) — nunca `string.match(texto, "^%s*(.-)%s*$")` em texto salvo (quadrático). Só
  comandos do chat (≤ 255 letras) podem usar esse padrão. `tests/test_hardening.lua` confere.
- **Desfazer (3.13):** ação que apaga ou muda várias coisas de uma vez tem "Desfazer" visível, só na sessão:
  `Profiles.packBackup` (pacotes; `name` some ao mexer num item), `Tasks.lastRemoved` / `Farm.lastRemoved` (cópias,
  nunca a tabela salva; posição inválida → fim da lista; respeita o limite de 10). Botão escondido quando não há o
  que desfazer.
- Missões concluídas (3.14): entrega por `QUEST_TURNED_IN(id)`; nome/nível capturados no `QUEST_COMPLETE` (janela de
  recompensa: `GetQuestID`/`GetTitleText` + diário) ou `C_QuestLog.GetTitleForQuestID`; clientes antigos (sem
  `C_QuestLog`) pela mensagem do sistema `ERR_QUEST_COMPLETE_S`. Total: `C_QuestLog.GetAllCompletedQuestIDs` (moderno) ou
  `GetQuestsCompleted` (antigo; 0 = não informado, porque no 3.3.5a precisa de `QueryQuestsCompleted`, um pedido ao
  servidor que **não** fazemos). Nomes de missões antigas exigiriam pedir ao servidor: não pedimos. Nada é gravado com
  `questRecord` desligado (regra 8); o total ao vivo aparece na barra mesmo assim (só leitura). 3.15: com o registro
  ligado, `Completed.ReadIDs` guarda os IDs concluídos em `completed[...].a` (crescente, sem repetir, máx. 15000, os
  maiores) a cada login; a opção `questShowOld` (desligada) mostra na janela os que não estão no registro, só pelo ID.
  3.16: clicar numa linha mostra o link do Wowhead (`Completed.WowheadURL`: `wowhead.com/forever/pt/quest=ID/` ou
  `/forever/quest=ID` em inglês, sem barra no fim; só de ID inteiro válido) numa caixa só de leitura para Ctrl+C; o addon não acessa a internet.
  3.17: dicionário `FarolDB.questNames[id] = { n ≤ 60, l?, t }` (conta, máx. 5000 os mais recentes; `SanitizeNames`
  escolhe os mais recentes pelos números antes de limpar o texto) aprendido de `QUEST_DETAIL`, `QUEST_ACCEPTED`,
  `QUEST_LOG_UPDATE` (no máx. a cada 5 s), `QUEST_COMPLETE` e entregas; só com `questRecord` ligado. Nunca buscar nomes
  no Wowhead (termos de uso proíbem coleta) nem com pedido ao servidor sem autorização do dono.
- **Nomes genéricos** em tudo que o jogador vê (addon, READMEs, CurseForge, imagens, vídeos): nada de personagens,
  lugares ou itens da Blizzard. Um teste do `test_toc.lua` procura uma lista desses nomes; ao achar outro, acrescente.

## Estrutura

```
Farol/
  Farol*.toc        4 arquivos (.toc); mesma versão em todos; ordem de carga: Core, Alarm, Loot, Warnings,
                    Appearance, Order, Tasks, Notes, Goals, Farm, Quests, Hearth, Runs, Completed, Sources, Diag, MinimapButton
  Core.lua          barras (até 3, grade de células), 30 itens, tooltip, menu de opções, comandos /farol, dados salvos
  Alarm.lua         alarmes do relógio, soneca, janela e janelinha
  Loot.lua          janela de últimos saques, menus suspensos próprios, botão 👜
  Warnings.lua      avisos (durabilidade, bolsas, talentos, graus, profissões, munição, reagentes, pausa, água, tarefas),
                    "Silenciar / Lembrar em N min" (2–30), janela agrupada para vários avisos (texto quebra em até 3 linhas,
                    tooltip com o aviso inteiro, alça ◢ de largura em `warnings.popupW`), histórico 📝, controles da aba Avisos
  Appearance.lua    escala, fundo, tamanhos de texto/ícone, formato (uma linha / uma coluna), esconder em combate,
                    mostrar/esconder os botões rápidos 📝 👜
  Order.lua         ordem dos itens na barra
  Tasks.lua         lista de tarefas diárias/semanais (janela, item "tasks" da barra, tooltip, /farol tarefa)
  Notes.lua         bloco de notas da conta (até 10 anotações: título + texto + concluída; janela, item "notes",
                    tooltip, /farol notas; apagar com confirmação e Desfazer)
  Goals.lua         metas de ouro e de nível (janela, item "goals" da barra, tooltip, estimativa pelo ritmo, /farol meta)
  Farm.lua          metas de farm/itens (item "farm", tooltip com ritmo, linhas na janela de Metas, "+ Meta" nos saques,
                    /farol meta item, /farol farm)
  Quests.lua        diário de missões (item "quests", tooltip; avisos questFull/questReady ficam em Warnings.lua)
  Hearth.lua        Pedra de Regresso (item "hearth": lugar + recarga; aviso hearthReady em Warnings.lua; lugar dos
                    personagens em chars[...].bind, gravado pelo Core)
  Runs.lua          registro de masmorras/raides (corrida atual no item "run", resumo ao sair, 10 últimas, /farol masmorra)
  Completed.lua     missões concluídas por personagem (janela com busca, item "qdone", registro desligado até o
                    jogador ligar, total do jogo; /farol concluidas)
  Sources.lua       de onde vem o XP e o ouro (opção "sources", desligada; tooltips XP/ouro, resumo, /farol origem)
  Diag.lua          /farol diagnostico: leituras cruas do jogo, último logout e contagem de eventos (só leitura)
  MinimapButton.lua botão próprio no minimapa (sem bibliotecas) + entrada AddonCompartment do .toc (/farol minimapa)
  Bindings.xml      atalho de teclado oficial (só abre o histórico de avisos)
  Media/Farol.tga   ícone original (64×64)
tests/              suíte de testes em Lua 5.1 com simulador da API do WoW
assets/             ícones, texto do CurseForge, imagens de divulgação (assets/curseforge/ + gerador), vídeo (assets/video/)
.github/            workflow de testes (ações fixadas por SHA) e Dependabot
```

### Arquitetura

- Arquivos compartilham a tabela `ns` (`local _, ns = ...`). O Core exporta `ns.T` (tradução), `ns.Print`,
  `ns.GetDB`, `ns.IsSecret`, `ns.frame`, `ns.UpdateText`, `ns.ApplyAppearance`, `ns.ApplyVisibility`,
  `ns.MakeToplevel`, `ns.LayoutQuickButtons`, `ns.SetBarWidth`, `ns.ITEM_ORDER`, `ns.ITEM_ICONS`,
  `ns.GetWatchedFaction`, `ns.GetJunk`, `ns.ReadBagSlot`/`ns.LastBag` (leitura de bolsas, usada pelo Farm), `ns.GetGoldRate`, `ns.GetXPRate`, `ns.GetSessionXP`, `ns.ReadProfessions`, `ns.GetResetTimes`, `ns.GetServerClock` (hora do servidor validada: relógio, alarmes e
  resets usam só ela, nunca `GetGameTime` direto) e `ns.FormatWhen(t, longo)` (datas de histórico: "Hoje 21:42" /
  "Ontem" / "08/11"; longo = "domingo, 08/11/2026 às 21:12"; inválido = "--").
- Cada módulo adiciona seus textos em `ns.STRINGS.pt` / `ns.STRINGS.en` e usa `T("chave")`.
- **Globais:** só nomes começando com `Farol` (janelas/botões), `FarolDB`, `FarolCharDB`, `SLASH_FAROL1`,
  `Farol_ToggleWarnHistory`, `Farol_OnAddonCompartmentClick/Enter/Leave` (citadas no `.toc`), `BINDING_*`. Nada de
  globais genéricos. O `test_globals` lê **todos** os `.lua` (lista `FILES`): arquivo novo entra nela.
- **Perfis (3.x):** no disco, os campos de cada barra (`ns.BAR_KEYS`: posição, aparência, `items`, `order`…) ficam
  em `FarolDB.profiles.account.bars[N]`; `activeBar` e `dataVersion = 3` ao lado. No código, `db.items`, `db.scale`
  etc. continuam valendo: um metatable (`Profiles.PROXY` no Core) leva essas chaves para a barra ativa. Por isso
  **nunca percorra o `db` com `pairs`/`next`** (não vê os campos da barra) e use `rawget` só de propósito. Ao carregar,
  `Profiles.Flatten` monta a visão "solta" (2.x e 3.x iguais), passa pela validação de sempre e `Profiles.Build`
  remonta o formato novo; perfis desconhecidos e chaves estranhas são descartados. Campo novo de barra: entra em
  `BAR_KEYS`. O Core está perto do limite de 200 variáveis locais do Lua: agrupe funções novas numa tabela
  (`Profiles.*`), nunca em `local` novos no topo do arquivo.
- **Várias barras (3.1):** até `Profiles.MAX_BARS` (3). Barra 1 = `FarolFrame` (sempre existe, recebe os eventos, tem
  os botões rápidos); barras 2/3 = `FarolBar2`/`FarolBar3`, criadas só quando usadas (`Profiles.Ensure`). As funções
  da barra (`Profiles.Layout`, `Appearance`, `Visibility`, `Grip`, `SavePosition`...) trabalham na **barra atual**
  (`frame`, `cells`, `grip`... + `db.*`). `Profiles.With(n, fn)` troca a atual por um momento e volta (mesmo com erro);
  `Profiles.Each(fn)` roda em todas; `UpdateText`/`ApplyAppearance`/`ApplyVisibility` já fazem isso. Todo script de
  quadro de barra passa por `Profiles.With(n, ...)` (`Profiles.Wire`). Fora disso, a atual é a escolhida no menu
  (`activeBar`, volta para 1 ao carregar). A atualização periódica roda só pela primeira barra visível
  (`Profiles.Leader`); pedidos ao servidor só se uma barra visível mostra o item (`Profiles.AnyItem`).
- **Perfis por personagem (3.2):** `FarolDB.profiles.chars[reino][nome] = { bars = {1..3} }` (só os próprios
  personagens, `ValidName`, 20 reinos × 60 nomes em ordem alfabética, `Profiles.SanitizeChars`); a escolha de cada um em
  `FarolCharDB.profile` ("account"/"char"). `Profiles.active` = as barras em uso (o metatable lê/escreve nelas);
  `Profiles.Activate()` escolhe (o nome do personagem pode só chegar no `PLAYER_ENTERING_WORLD`, que reaplica).
  Toda cópia passa por `Profiles.CleanBar`/`CopyBars` (validação + tabelas novas, nunca compartilhadas). "Copiar de..."
  guarda `Profiles.backup` (só na sessão) para `/farol perfil desfazer`. Esquecer um personagem apaga o perfil dele.
- **Botão do minimapa (3.7):** `FarolDB.minimap = { show, locked, angle 0–360 }` (validado). Clique direito chama
  `ns.SetAllBarsHidden` ("esconder todas", só na sessão: `Profiles.allHidden`, respeitado por `Profiles.Visibility`;
  `/farol` sozinho desfaz). Sem `Minimap` (outra interface) o botão simplesmente não é criado.
- **Dados salvos:** `FarolDB` (conta: configurações, `items`, `order`, `alarms`, `loot`, `warnings`, `chars` = ouro
  e nível dos **próprios** personagens por reino — `chars[reino][nome] = { gold, level, t, rest?, max?, inn?, locks?, bind? }`
  (bind = onde a Pedra de Regresso estava vinculada, texto limpo até 40 letras)
  (descanso: XP descansado, XP do nível e se estava em estalagem/cidade, gravados ao sair), nomes sem `|`/controle
  e até 48 bytes, no máximo 20 reinos × 60 personagens; nunca nomes de outros jogadores), `questRecord` (registro de
  missões, desligado), `questShowOld` (mostrar as de antes do registro, desligado), `questNames` (dicionário ID → nome
  aprendido com o jogo, máx. 5000), `notes` (bloco de notas da conta: `{ {t ≤ 40, x ≤ 500 com quebras de linha, d, m} }`,
  máx. 10, sem `|`/controle), `completed[reino][nome] = { t = total
  do jogo, tt = quando, a = { IDs concluídos, máx. 15000 }, list = { {i, n ≤ 60, l, z ≤ 40, t} } }`
  (máx. 2000 por personagem, 20 reinos × 60 nomes; só os próprios personagens; `ns.KeepLast`/`ns.KeepRecent`) e
  `FarolCharDB` (personagem: `items` = histórico de saques, `warnHistory`, `runs` = `{ list (máx. 10), cur }` corridas
  em masmorras/raides `{ n, k = "party"/"raid", t, s ≥ 60, x, g, l, r, e, d, u (só cur) }` — o `/reload` continua a
  corrida, mais de 15 min fora fecha no último momento visto; saques contados via `Runs.OnLoot` chamado pelo
  `Record` do Loot; XP pela diferença de `ns.GetSessionXP`, `goals` = metas `{ gold = cobre alvo
  (≤ 1 milhão de ouro), level = nível alvo, ls = nível ao criar, gw/lw = "alcançada" já avisada }`, `tasks` = lista de tarefas
  `{ n = nome limpo (≤ 40 letras), w = semanal?, d = time() da marca }` (máx. 10; feita = `d` depois do último reset do
  tipo, calculado com `ns.GetResetTimes`), `farm` = metas de itens `{ id, n = nome limpo (≤ 40 letras), c = alvo
  1–100000, w = "alcançada" já avisada }` (máx. 10, sem id repetido), `diag = { lz, t }` = o jogo deu 0 de ouro no último logout? (para o `/farol diagnostico`), `lastSession` = resumo da última sessão, só números, salvo em `PLAYER_LOGOUT` — que também acontece no `/reload`). O Core monta o `db` limpo em
  `ADDON_LOADED` chamando o `Sanitize` de cada módulo; chaves desconhecidas são descartadas.
- **Tooltip:** dividido em seções (`TIP.perf`, `TIP.gold`, `TIP.reset`…). Cada célula tem uma área invisível de
  mouse (`AttachHover`) que mostra só as seções do item (`TIP_SECTIONS`) e repassa arrastar/clique para a barra.
  Shift, a opção `tooltipFull` ou o fundo da barra mostram tudo (`TIP_ORDER`). Listas: no máximo `LIST_MAX` (5).
- **Barra:** cada informação é uma **célula** (FontString) numa grade de **colunas alinhadas à esquerda**. O número
  de colunas é o máximo que cabe em `db.barWidth` (0 = uma linha, 1 = uma coluna, N = pixels escolhidos pela alça).
  A altura segue as linhas. Botões rápidos (📝 👜) via `ns.quickButtons` + `ns.LayoutQuickButtons()`.
- **Janelas:** todas chamam `ns.MakeToplevel(frame)` (abrem na frente; clique traz para a frente) e entram em
  `UISpecialFrames` (Esc fecha).
- **Menu de opções (3.4):** abas `Profiles.TABS` = Barra / Avisos / Ferramentas / Geral (`BuildControls` no Core, um
  conjunto de controles para a janela `FarolOptions` e outro para o painel Esc → Opções → AddOns; `RefreshOptions`
  sincroniza os dois). Itens em grupos `Profiles.GROUPS` (`ns.ITEM_GROUPS`) **na mesma ordem de `ITEM_ORDER`** (um
  teste confere; os testes de menu contam as caixinhas por posição). A aba Avisos usa `Warnings.BuildControls(página,
  prefixo)` (`FarolWarn…` no menu, `FarolPanelWarn…` no painel); não existe mais a janela `FarolWarnings`.
  `ns.OpenOptions(aba)` abre/fecha numa aba (`/farol aviso` → "warnings"; clique direito → "bar"). Item novo na barra:
  também entra num grupo. Opção que existe em duas janelas: chame `ns.RefreshOptions()` depois de mudar.
  **Menu 3.11:** aba Barra = "Editando:" barra 1/2/3 (só escolhe; a ativa em texto branco) + Mostrar/Travar,
  quadro "Aplicar pacote:" (`set.packBox`), `Profiles.PACKS` (pacotes: só ligam o que o jogador clica;
  "basic" substitui, os outros somam; `Profiles.packBackup` guarda a barra antes para "Desfazer"; `/farol pacote`),
  `Profiles.GEARS` (⚙ ao lado do item: aba "warnings" ou função que abre a janela) e a faixa `set.info`
  (`Profiles.ShowInfo`: `desc_<item>`). Perfil e "Copiar de..." ficam na aba Geral. Aba Avisos: grupos, botões
  `Warnings.SetAll(true/false)` ("Só os recomendados" = padrões de `DEFAULTS`; o som e "também em lutas" não mudam) e a
  faixa `Warnings.ShowInfo` (`warn_desc_<chave>`, um teste confere PT/EN). A ordem de criação das caixinhas não mudou
  (os testes contam por posição): itens, Mostrar, Travar, aba Geral, avisos. Coluna 2 da aba Avisos: rótulos curtos.
- **Menus suspensos:** implementação própria em `Loot.lua` (o `UIDropDownMenu` da Blizzard é obsoleto e causa taint).
- **Sliders:** usamos botões [-]/[+] (o template de slider mudou entre versões).

## Testes

```
lua5.1 tests/run.lua        # ~730 testes (2 passadas); deve terminar com "0 failed"
```

- **Duas passadas (3.18):** a 1ª com o simulador "de livro"; a 2ª, **forever-real** (`Mock.REAL`), com reino `""` e
  sobrenome ("Montes"). O ouro 0 no `PLAYER_LOGOUT` vale sempre no modo `forever` (`H.loggingOut`; dispare
  `PLAYER_MONEY` ao mudar `H.money` no meio do teste, como o jogo faz). Suítes com dados salvos num reino/nome fixos
  declaram `fixedIdentity = true` e mantêm essa identidade na 2ª passada. `FAROL_PASS=1`/`2` roda só uma.

- Barras 2/3 nos testes: `H.env.FarolBar2._fontStrings` (`H:cells()`/`H:bar()` leem só a barra 1); `tests/test_bars.lua`.
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
   ainda não viu — e, se for item ou aviso, em `Profiles.NEWS_ITEM`/`NEWS_WARN` (regra 8: vem desligado). Item novo na barra: também `desc_<item>` em PT/EN (explicação ao passar o mouse; um teste confere) e uma
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
| Opção nova no menu (abas Barra / Geral / Ferramentas) | 03 |
| Alarmes | 04 · Janela de saques: 05 · Avisos (aba Avisos do menu) / histórico: 06 |
| Aparência (escala, fundo, formato, botões rápidos) | 07 (e 02 se mudar o formato da barra) |
| Resumo da sessão (textos no chat) | 09 |
| Tarefas (janela, item, aviso) | 10 |
| Metas, metas de farm e diário de missões (item e tooltip de progresso) | 08 (e 02/03 pela contagem de itens) |
| Masmorras e raides (item, resumo, janela) | 11 (e 02/03 pela contagem de itens) |
| Missões concluídas (janela, item, tooltip) | 12 (e 02/03 pela contagem de itens) |
| Várias barras e perfis por personagem | 13 |
| Ouro/descanso dos personagens, Pedra de Regresso, instâncias salvas | 14 |
| De onde vem o XP e o ouro (tooltips) | 15 (e 09 pelo resumo) |
| Janela de chat do Farol e `/farol diagnostico` | 16 |
| Botão do minimapa e cores para daltonismo | 17 |
| Bloco de notas (janela, item, tooltip) | 18 (e 02/03 pela contagem de itens) |

As imagens saem idênticas quando não mudam (o gerador é determinístico): suba no CurseForge só as que mudaram
e apague lá as versões antigas.

**Vídeo de divulgação** (`assets/video/`, 60 s, 1920×1080, sem áudio): `python3 assets/video/make_video.py` e
`node assets/video/record.js video` (precisa de `ffmpeg`). Cenas e legendas em `make_video.py` (`CAPS`), o que acontece
a cada segundo em `timeline.js` (`render(t)`, `PATH`, `CLICKS`). Mesmo estilo e mesmas regras das imagens (selo
"Illustration · Ilustração", nomes genéricos, nada da Blizzard). Ao mudar uma janela mostrada no vídeo, atualize a cena.
`.html`/`.mp4`/prévias não são versionados.
