# Farol

**A free, lightweight and customizable info bar for WoW Forever — with clock alarms and a recent loot window.**
*Uma barra de informações leve, gratuita e personalizável para WoW Forever — com alarmes e janela de saques.*

> Unofficial add-on, not affiliated with Blizzard Entertainment. · Addon não oficial, não afiliado à Blizzard Entertainment.

---

## English

**Farol** (Portuguese for *lighthouse*) shows the information you care about in one small, movable bar.

> **You decide: almost everything starts off.** Only the basics are on the first time (7 of 31 bar items: FPS, latency, coordinates, zone, Hearthstone, durability, gold; the durability, bags, talents, spell rank and profession warnings; the session summary in your own chat; the minimap button). **Every new feature arrives turned off** — updating never turns anything on by itself. Right-click the bar (or `/farol menu`) to choose; after an update, Farol lists what is new once and says where to turn it on.

### Info bar — pick what you see
FPS · Latency · Memory · Coordinates · Zone · Speed · **Hearthstone: where it is bound & cooldown** · Durability · Bags · **Junk value (gray items)** · **Ammo & reagents (your limits)** · Gold (**+ total and rested XP of all your characters**) · Session gold · **Gold per hour** · XP & rested · **XP per hour & time to level** · **Reputation (standing, progress, rep/hour)** · **Professions (level / training limit)** · **Gold & level goals with a time estimate** · **Farm goals: items to gather, pace per hour & estimate** · **Quest log: how many fit, ready to turn in (and how much XP they give — enough to level up?), warning before it fills up** · **Completed quests of each character** · **Dungeon & raid run log (time, XP, gold, loot, deaths)** · Clock (local or server) · **Daily & weekly reset countdown + saved instances (raid lockouts)** · **Daily & weekly tasks** · **Notes (notepad)** · **Kept items (for later recipes, with reminders)** · Session time · Friends online · Guild online

- **Right-click** the bar (or `/farol menu`): a **tabbed menu** — Bar (items in groups), Warnings, Tools, General — to tick the items you want, and **choose their order** with [▲]/[▼] arrows. **Presets** (Basic, Leveling, Gold & farm, Dungeons) set up the bar in one click (with Undo); a **gear** next to an item opens its settings; a strip explains the item under the mouse. The General tab is split into sections, with the delete actions set apart; every window follows the same pattern (create at the top, list in the middle, Undo at the bottom).
- **Up to 3 bars**, each with its own items, position, appearance and order (menu → Bar 2 / Bar 3 → Show).
- **Profiles:** the same bars on every character, or **this character only** — and **Copy from...** another character.
- **Completed quests of each character:** a list of the quests each of your characters turned in, with their quest IDs, a search by name or ID and a click-to-copy Wowhead link; quest names are learned from the game as you see them (recording starts off) and the total the game reports; stays on your computer.
- **Daily & weekly tasks:** your own checklist (`/farol task`) that resets on its own at the daily/weekly reset (removed one by mistake? Undo).
- **Notepad:** up to 10 account-wide notes with a title, a text and a done checkbox (`/farol notes`); delete with confirmation and Undo.
- **Minimap button:** click for the menu, right-click to hide/show every bar at once (no other addon needed).
- **Hover** an item for its own short tooltip (gold, durability, resets…); hold **Shift** to see everything: home/world latency, subzone, every damaged item, exact XP, local *and* server time, and more.

### Appearance
- **Colorblind-friendly colors** (blue · yellow · orange) as an option; opaque windows, lighter hint text and gold amounts that never look like a warning.
- Scale 50–200%, **text size**, **icon size**, background opacity, border, **flexible layout** (drag the corner: one line, one column or aligned columns), **hide in combat** and **hide in instances**.

### Clock alarms
- Up to **10 alarms**, using **local** or **server** time, with an optional name.
- Plays a game sound and posts a message **only in your own chat**, every 30 seconds, until you click **Snooze** (1–60 min, configurable) or **Stop**.

### Durability and bag warnings
- One-time warning on screen and in your chat when gear durability drops below 20% or your bags are almost full / full (it also tells you how much junk you can sell — Farol never sells for you).
- Configurable limits and sound; never repeats while the number flickers.
- **Unspent talent points** and **lower-rank spells on your action bars** (never changes your bars for you).
- **Profession at its training limit**: "find a trainer to keep leveling" (once per limit).
- **Ammo and reagents running low**, with the warning/critical limits you choose (off by default; Farol never buys anything).
- Each warning lets you **Silence** it or get a **reminder in 2, 5, 10, 15 or 30 minutes** (your choice). Several warnings at once appear together in one window.
- Optional **break** and **drink water** reminders (off by default): you choose how often (15–240 min) and whether they can show during fights, raids and dungeons.
- Long warnings are never cut: they wrap onto up to 3 lines, hovering shows the whole text, and the warning window can be made wider with the ◢ grip.
- **History of the last 10 warnings**: button next to the bar (with unread counter), key binding or `/farol history`.
- **Kept items** (off by default): pick from a list of what you have (bags and bank) or click **Keep** in the loot window, and keep materials for a recipe you only learn later, with a reason and "when" (level or profession level); reminders at the merchant and when the time comes, left out of the junk count. Farol never sells anything.
- **Notes one click away** (off by default): a notes button next to the bar with the number of pending notes (Shift-click = new note) and a key binding of your choice.

### Session summary
- `/farol summary` shows what you did this session **in your own chat**: gold (and per hour), XP and levels, reputation (standing before → after), loot (rares, epics, legendaries) and warnings.
- The last session's summary is shown **the next time you log in** (option in the menu; not after `/reload`).
- **Farol messages in a chat tab of their own:** create a tab named "Farol" and pick it in Menu > General (or `/farol chat Farol`); by default they stay in the main chat. Farol only writes in your own chat — nothing is sent.
- **Optional:** where the session's XP and gold come from — quests, monsters, loot, merchant sales and purchases/repairs — in the XP and gold tooltips and in the summary (Menu > General, starts off).
- `/farol diag` shows in your own chat **how the game answered** (character, realm, gold, last logout, quest events) — read-only, handy to include in a bug report.

### Recent loot window
- Shows the last **5 / 10 / 15 / 20** items you looted (dropdown). Quick **bag button** next to the bar with a new-items counter.
- **Quality filter** dropdown (Poor → Legendary+), item tooltips, shift-click to link.
- Shows **when** you looted each item: Today / Yesterday / date, plus the full date in the tooltip.
- **Resizable** window with mouse-wheel scrolling. History saved per character.

### Languages
English and Brazilian Portuguese (follows your client, or `/farol lang en|pt`).

### Safe by design
- Only **reads and displays** information through the official add-on API — no automation, no protected actions.
- **Sends nothing**: no chat or add-on messages. Friends/guild items read counts only, never names.
- Saved settings are validated on load. Free, no ads, readable source code (MIT license).

### Commands
`/farol` show/hide · `/farol menu` options · `/farol alarm` alarms · `/farol loot` loot window · `/farol summary` session summary · `/farol help` all commands

---

## Português (Brasil)

**Farol** mostra as informações que importam numa barra pequena e móvel.

> **Você decide: quase tudo vem desligado.** Na primeira vez só o básico vem ligado (7 de 31 itens da barra: FPS, latência, coordenadas, zona, Pedra de Regresso, durabilidade, ouro; os avisos de durabilidade, bolsas, talentos, graus de magia e profissões; o resumo da sessão no seu próprio chat; o botão do minimapa). **Toda função nova chega desligada** — atualizar nunca liga nada sozinho. Clique com o botão direito na barra (ou `/farol menu`) para escolher; depois de uma atualização, o Farol lista as novidades uma vez e diz onde ligar.

### Barra de informações — você escolhe o que aparece
FPS · Latência · Memória · Coordenadas · Zona · Velocidade · **Pedra de Regresso: onde está vinculada e recarga** · Durabilidade · Bolsas · **Valor do lixo (itens cinzentos)** · **Munição e reagentes (seus limites)** · Ouro (**+ total e descanso de todos os seus personagens**) · Ouro da sessão · **Ouro por hora** · XP e descansado · **XP por hora e tempo até o próximo nível** · **Reputação (nível, progresso, rep/hora)** · **Profissões (nível / limite do treinamento)** · **Metas de ouro e de nível com estimativa de tempo** · **Metas de farm: itens para juntar, ritmo por hora e estimativa** · **Diário de missões: quantas cabem, prontas para entregar (e quanto XP elas dão — dá para subir de nível?), aviso antes de encher** · **Missões concluídas de cada personagem** · **Registro de masmorras e raides (tempo, XP, ouro, saques, mortes)** · Horário (local ou do servidor) · **Contagem até o reset diário e semanal + instâncias salvas (bloqueios de raide)** · **Tarefas diárias e semanais** · **Anotações (bloco de notas)** · **Itens guardados (para receitas de depois, com lembretes)** · Tempo de sessão · Amigos online · Guilda online

- **Clique direito** na barra (ou `/farol menu`): um **menu em abas** — Barra (itens em grupos), Avisos, Ferramentas, Geral — para marcar os itens que quiser e **escolher a ordem** com as setas [▲]/[▼]. **Pacotes prontos** (Básico, Upando, Ouro e farm, Masmorras) montam a barra com um clique (com Desfazer); a **engrenagem** ao lado de um item abre a configuração dele; uma faixa explica o item sob o mouse. A aba Geral é dividida em seções, com as ações de apagar separadas; todas as janelas seguem o mesmo padrão (criar no topo, lista no meio, Desfazer no rodapé).
- **Até 3 barras**, cada uma com itens, posição, aparência e ordem próprios (menu → Barra 2 / Barra 3 → Mostrar).
- **Perfis:** as mesmas barras em todos os personagens, ou **só deste personagem** — e **Copiar de...** outro personagem.
- **Missões concluídas de cada personagem:** lista das missões que cada personagem seu entregou, com o ID de cada uma, busca pelo nome ou ID e o link do Wowhead para copiar com um clique; os nomes das missões são aprendidos com o próprio jogo (o registro vem desligado) e o total que o jogo informa; fica só no seu computador.
- **Tarefas diárias e semanais:** sua lista (`/farol tarefa`) que zera sozinha no reset diário/semanal (apagou sem querer? Desfazer).
- **Bloco de notas:** até 10 anotações da conta com título, texto e caixinha de concluída (`/farol notas`); apagar com confirmação e Desfazer.
- **Botão no minimapa:** clique para o menu, clique direito para esconder/mostrar todas as barras (não precisa de outro addon).
- **Passe o mouse** num item para ver um tooltip curto só dele (ouro, durabilidade, resets…); segure **Shift** para ver tudo: latência local/mundo, subzona, cada peça danificada, XP exato, hora local *e* do servidor, e mais.

### Aparência
- **Cores para daltonismo** (azul · amarelo · laranja) como opção; janelas opacas, dicas mais legíveis e valores em ouro que não parecem alerta.
- Escala de 50 a 200%, **tamanho do texto**, **tamanho dos ícones**, opacidade do fundo, borda, **formato livre** (arraste o canto: uma linha, uma coluna ou colunas alinhadas), **esconder em combate** e **esconder em instâncias**.

### Alarmes do relógio
- Até **10 alarmes**, com hora **local** ou do **servidor** e um nome opcional.
- Toca um som do jogo e mostra uma mensagem **só no seu chat**, a cada 30 segundos, até você clicar em **Soneca** (1–60 min, configurável) ou **Parar**.

### Avisos de durabilidade e bolsas
- Aviso único na tela e no seu chat quando a durabilidade cai abaixo de 20% ou as bolsas estão quase cheias / cheias (e diz quanto lixo dá para vender — o Farol nunca vende por você).
- Limites e som configuráveis; não fica repetindo quando o número oscila.
- **Pontos de talento não gastos** e **magias de grau antigo na barra de ações** (nunca mexe nas suas barras).
- **Profissão no máximo do treinamento**: "procure um instrutor para continuar subindo" (uma vez por limite).
- **Munição e reagentes acabando**, com os limites de atenção/crítico que você escolhe (desligado por padrão; o Farol nunca compra nada).
- Cada aviso deixa você **Silenciar** ou ser **lembrado em 2, 5, 10, 15 ou 30 minutos** (você escolhe). Vários avisos ao mesmo tempo aparecem juntos numa janela só.
- Lembretes opcionais de **pausa** e de **beber água** (desligados por padrão): você escolhe de quanto em quanto tempo (15–240 min) e se podem aparecer em lutas, raides e masmorras.
- Avisos longos nunca ficam cortados: quebram em até 3 linhas, passar o mouse mostra o texto inteiro e a janela de avisos pode ficar mais larga com a alça ◢.
- **Histórico dos 10 últimos avisos**: botão ao lado da barra (com contador de novos), atalho de teclado ou `/farol historico`.
- **Itens guardados** (desligado por padrão): escolha numa lista do que você tem (bolsas e banco) ou clique em **Guardar** na janela de saques, e guarde materiais de uma receita que só aprende depois, com motivo e "quando" (nível ou nível de profissão); lembretes no comerciante e na hora certa, fora da conta do lixo. O Farol nunca vende nada.
- **Anotações a um clique** (desligado por padrão): botão das anotações ao lado da barra com o número de pendentes (Shift + clique = anotação nova) e tecla de atalho à sua escolha.

### Resumo da sessão
- `/farol resumo` mostra **no seu chat** o que você fez na sessão: ouro (e por hora), XP e níveis, reputação (nível antes → depois), saques (raros, épicos, lendários) e avisos.
- O resumo da última sessão aparece **na próxima vez que você entrar** (opção no menu; não aparece depois de `/reload`).
- **Mensagens do Farol numa aba de chat própria:** crie uma aba chamada "Farol" e escolha em Menu > Geral (ou `/farol chat Farol`); por padrão continuam no chat principal. O Farol só escreve no seu chat — nada é enviado.
- **Opcional:** de onde vem o XP e o ouro da sessão — missões, monstros, saque, vendas e compras/consertos no comerciante — nos tooltips do XP e do ouro e no resumo (Menu > Geral, vem desligado).
- `/farol diagnostico` mostra no seu chat **como o jogo respondeu** (personagem, reino, ouro, último logout, eventos de missão) — só leitura, útil para relatar um problema.

### Janela de últimos saques
- Mostra os últimos **5 / 10 / 15 / 20** itens que você saqueou (menu suspenso). **Botão de bolsa** ao lado da barra, com contador de itens novos.
- Menu de **filtro de qualidade** (Inferior → Lendário+), tooltip dos itens, Shift+clique para linkar.
- Mostra **quando** você saqueou cada item: Hoje / Ontem / data, e a data completa no tooltip.
- Janela **redimensionável**, com rolagem pela roda do mouse. Histórico salvo por personagem.

### Idiomas
Português do Brasil e inglês (segue o idioma do cliente, ou `/farol lang pt|en`).

### Seguro por natureza
- Só **lê e mostra** informações pela API oficial de addons — sem automação, sem ações protegidas.
- **Não envia nada**: nenhuma mensagem de chat ou de addon. Amigos/guilda leem só quantidades, nunca nomes.
- As configurações salvas são validadas ao carregar. Gratuito, sem anúncios, código legível (licença MIT).

### Comandos
`/farol` mostrar/ocultar · `/farol menu` opções · `/farol alarme` alarmes · `/farol saque` janela de saques · `/farol resumo` resumo da sessão · `/farol ajuda` todos os comandos
