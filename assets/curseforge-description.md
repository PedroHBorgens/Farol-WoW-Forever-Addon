# Farol

**A free, lightweight and customizable info bar for WoW Forever — with clock alarms and a recent loot window.**
*Uma barra de informações leve, gratuita e personalizável para WoW Forever — com alarmes e janela de saques.*

> Unofficial add-on, not affiliated with Blizzard Entertainment. · Addon não oficial, não afiliado à Blizzard Entertainment.

---

## English

**Farol** (Portuguese for *lighthouse*) shows the information you care about in one small, movable bar.

### Info bar — pick what you see
FPS · Latency · Memory · Coordinates · Zone · Speed · Durability · Bags · Gold · Session gold · **Gold per hour** · XP & rested · **XP per hour & time to level** · **Reputation (standing, progress, rep/hour)** · Clock (local or server) · **Daily & weekly reset countdown** · Session time · Friends online · Guild online

- **Right-click** the bar (or `/farol menu`) to tick the items you want, and **choose their order** with [▲]/[▼] arrows.
- **Hover** the bar for a detailed tooltip: home/world latency, subzone, every damaged item, exact XP, local *and* server time, and more.

### Appearance
- Scale 50–200%, **text size**, **icon size**, background opacity, border, **flexible layout** (drag the corner: one line, one column or aligned columns), **hide in combat** and **hide in instances**.

### Clock alarms
- Up to **10 alarms**, using **local** or **server** time, with an optional name.
- Plays a game sound and posts a message **only in your own chat**, every 30 seconds, until you click **Snooze** (1–60 min, configurable) or **Stop**.

### Durability and bag warnings
- One-time warning on screen and in your chat when gear durability drops below 20% or your bags are almost full / full.
- Configurable limits and sound; never repeats while the number flickers.
- **Unspent talent points** and **lower-rank spells on your action bars** (never changes your bars for you).
- Each warning lets you **Silence** it or get a **reminder in 30 minutes**.
- **History of the last 10 warnings**: button next to the bar (with unread counter), key binding or `/farol history`.

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
`/farol` show/hide · `/farol menu` options · `/farol alarm` alarms · `/farol loot` loot window · `/farol help` all commands

---

## Português (Brasil)

**Farol** mostra as informações que importam numa barra pequena e móvel.

### Barra de informações — você escolhe o que aparece
FPS · Latência · Memória · Coordenadas · Zona · Velocidade · Durabilidade · Bolsas · Ouro · Ouro da sessão · **Ouro por hora** · XP e descansado · **XP por hora e tempo até o próximo nível** · **Reputação (nível, progresso, rep/hora)** · Horário (local ou do servidor) · **Contagem até o reset diário e semanal** · Tempo de sessão · Amigos online · Guilda online

- **Clique direito** na barra (ou `/farol menu`), marque os itens que quiser e **escolha a ordem** com as setas [▲]/[▼].
- **Passe o mouse** na barra para ver um tooltip detalhado: latência local/mundo, subzona, cada peça danificada, XP exato, hora local *e* do servidor, e mais.

### Aparência
- Escala de 50 a 200%, **tamanho do texto**, **tamanho dos ícones**, opacidade do fundo, borda, **formato livre** (arraste o canto: uma linha, uma coluna ou colunas alinhadas), **esconder em combate** e **esconder em instâncias**.

### Alarmes do relógio
- Até **10 alarmes**, com hora **local** ou do **servidor** e um nome opcional.
- Toca um som do jogo e mostra uma mensagem **só no seu chat**, a cada 30 segundos, até você clicar em **Soneca** (1–60 min, configurável) ou **Parar**.

### Avisos de durabilidade e bolsas
- Aviso único na tela e no seu chat quando a durabilidade cai abaixo de 20% ou as bolsas estão quase cheias / cheias.
- Limites e som configuráveis; não fica repetindo quando o número oscila.
- **Pontos de talento não gastos** e **magias de grau antigo na barra de ações** (nunca mexe nas suas barras).
- Cada aviso deixa você **Silenciar** ou ser **lembrado em 30 minutos**.
- **Histórico dos 10 últimos avisos**: botão ao lado da barra (com contador de novos), atalho de teclado ou `/farol historico`.

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
`/farol` mostrar/ocultar · `/farol menu` opções · `/farol alarme` alarmes · `/farol saque` janela de saques · `/farol ajuda` todos os comandos
