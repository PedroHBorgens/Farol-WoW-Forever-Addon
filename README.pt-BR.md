# Farol

**Português** | [English](README.md)

**Farol** é um addon **gratuito, de código aberto e não oficial** para WoW Forever: mostra um painel pequeno e arrastável com
**FPS · latência · memória · coordenadas · zona · velocidade · Pedra de Regresso · durabilidade · bolsas · valor do lixo · munição e reagentes · ouro · ouro da sessão · ouro/hora · XP ·
XP/hora · reputação · profissões · metas de ouro/nível · metas de farm (itens) · diário de missões · missões concluídas · horário · resets diário/semanal · tarefas · anotações · itens guardados · tempo de sessão · masmorra atual · amigos · guilda** — você escolhe o que aparece (31 itens).
Passe o mouse no painel para ver um tooltip com detalhes. Também tem **alarmes do relógio**, **janela de últimos
saques** e **avisos** (durabilidade, bolsas, talentos não gastos, magias de grau antigo).

## Você decide: quase tudo vem desligado

O Farol respeita a sua escolha: **só funciona o que você ligar**, e **toda função nova chega desligada** — atualizar
o addon nunca liga nada sozinho (um teste automático garante isso).

| Vem ligado na primeira vez | Todo o resto vem desligado |
|---|---|
| Barra com o básico: FPS, latência, coordenadas, zona, Pedra de Regresso, durabilidade e ouro (7 de 31 itens) | Os outros 24 itens da barra e a 2ª e 3ª barras |
| Avisos de durabilidade, bolsas, talentos não gastos, magias de grau antigo e profissões (com som) | Munição, reagentes, pausa, água, tarefas, metas, missões, descanso dos personagens |
| Resumo da sessão ao entrar e ao sair de masmorra — só no **seu** chat | Tooltip completo, horário do servidor, ouro de todos os personagens, esconder em combate |
| Botão no minimapa | Perfis por personagem, alarmes, tarefas, metas |

- **Para ligar ou desligar:** clique com o botão direito na barra (ou `/farol menu`) — passe o mouse em cada item para
  ver o que ele mostra. Tudo o que vem ligado também pode ser desligado.
- **Depois de uma atualização**, o Farol lista as novidades uma vez no seu chat e diz quais estão desligadas e onde
  ligar (`/farol novidades` mostra de novo). Quem já usa o addon mantém exatamente o que escolheu.

## Instalação

> **Vindo do "WoW Forever Info"?** O addon mudou de nome. Apague a pasta antiga
> `Interface/AddOns/WoWForeverInfo` antes de instalar o `Farol`. As configurações antigas não são
> levadas junto (é só marcar seus itens de novo no menu), e o comando agora é `/farol`.

1. Instale pelo **[CurseForge](https://www.curseforge.com/wow/addons/farol)**, ou baixe este repositório (botão **Code → Download ZIP**).
2. Copie a pasta `Farol` para `World of Warcraft/_forever_/Interface/AddOns/`
   (a pasta final deve ser `_forever_/Interface/AddOns/Farol/Core.lua`).
   Outros clientes usam a própria pasta, como `_retail_` ou `_classic_era_`.
3. Na tela de personagens, clique em **AddOns** e ative **Farol**.
   Se aparecer "desatualizado", marque **Carregar AddOns desatualizados**.

## Comandos

| Comando             | O que faz |
|---------------------|--------------------------------------------------------|
| `/farol`            | Mostra/oculta o painel |
| `/farol menu`       | Abre o menu de opções (ou clique direito no painel) |
| `/farol saque`      | Abre a janela de últimos saques |
| `/farol saque limpar`| Apaga o histórico de saques deste personagem |
| `/farol sessao zerar`| Recomeça ouro da sessão, ouro/h, XP/h, rep/h e tempo |
| `/farol novidades`  | Mostra de novo as novidades das últimas versões |
| `/farol instancias` | Instâncias salvas (bloqueios de raide) deste e dos outros personagens |
| `/farol resumo`     | Resumo da sessão atual (ouro, XP, reputação, saques, avisos) |
| `/farol ouro`       | Ouro de todos os seus personagens deste reino |
| `/farol ouro total on` / `off` | Mostra / esconde o total do reino ao lado do ouro na barra |
| `/farol ouro esquecer Nome` | Esquece um personagem que você apagou ou não usa mais |
| `/farol resumo on` / `off` | Mostra / não mostra o resumo da última sessão ao entrar |
| `/farol aviso`      | Abre o menu na aba Avisos (durabilidade, bolsas, talentos, graus de magia, pausa, água) |
| `/farol aviso status`| Mostra o que o Farol consegue ler no seu cliente (talentos, reputação, resets) |
| `/farol historico`  | Últimos 10 avisos (também pelo botão ao lado da barra ou por atalho de teclado) |
| `/farol aparencia`  | Abre a janela de aparência (escala, fundo, formato, esconder em combate) |
| `/farol ordem`      | Escolhe a ordem das informações na barra |
| `/farol meta`       | Metas de ouro e de nível com estimativa de tempo (`/farol meta ouro 500`, `/farol meta nivel 40`) |
| `/farol pacote`     | Liga um pacote de itens: `basico` (volta ao básico), `upando`, `farm`, `masmorras`; `desfazer` |
| `/farol meta item`  | Metas de farm: `/farol meta item [link] 40` (Shift + clique no item) ou pelo nome; `remover`, `limpar` |
| `/farol minimapa`   | Mostra/esconde ou trava o botão do minimapa (`on`, `off`, `travar`, `destravar`) |
| `/farol masmorra`   | Suas 10 últimas masmorras e raides: tempo, XP, ouro, saques, mortes |
| `/farol concluidas` | Missões concluídas de cada personagem (lista com busca e total); `registrar on\|off` |
| `/farol chat Nome`  | Em qual janela de chat o Farol escreve (ex.: uma aba "Farol"); `/farol chat principal` volta ao padrão |
| `/farol origem on\|off` | Mostra de onde vem o XP e o ouro da sessão (missões, monstros, saque, comerciante) |
| `/farol diagnostico` | Mostra no seu próprio chat como o jogo respondeu (personagem, reino, ouro, último logout, eventos); só leitura |
| `/farol central`    | Central do Farol (estilo detalhado): todas as janelas num painel com barra lateral; `off` = estilo simples; `tamanho 70-130` = tamanho da Central |
| `/farol guardar`    | Itens guardados para depois: motivo, quando ficam úteis, lembretes (`[item]: motivo`, `lista`, `tirar N`, `desfazer`) |
| `/farol notas`      | Bloco de notas da conta: até 10 anotações com caixinha de concluída (`nova Título`, `lista`, `desfazer`) |
| `/farol tarefa`     | Lista de tarefas diárias e semanais (zera sozinha; `/farol tarefa add Nome`) |
| `/farol perfil`     | Perfil da conta ou só deste personagem; copiar de outro (`/farol perfil copiar Nome`) |
| `/farol barra 2 mostrar` | Liga a barra 2 (ou 3) e escolhe ela para o menu, a Aparência e a Ordem (`/farol barra` lista as barras) |
| `/farol alarme`     | Abre a janela de alarmes |
| `/farol alarme add 07:30`| Cria um alarme (veja abaixo) |
| `/farol soneca`     | Adia o alarme que está tocando (tempo configurado, padrão 5 min) |
| `/farol parar`      | Para o alarme que está tocando |
| `/farol lock`       | Trava/destrava o painel (arraste com o botão esquerdo) |
| `/farol reset`      | Volta o painel para a posição padrão |
| `/farol show <item>`| Mostra um item na barra |
| `/farol hide <item>`| Esconde um item da barra |
| `/farol itens`      | Lista os itens e o que está visível |
| `/farol ajuda`      | Lista todos os comandos |
| `/farol version`    | Mostra a versão do cliente e o número de **Interface** |
| `/farol lang pt`    | Interface em português |
| `/farol lang en`    | Interface em inglês |
| `/farol lang auto`  | Segue o idioma do cliente (padrão) |

## Menu de opções

Marque ou desmarque cada item, sem precisar de comandos. Abra de qualquer um destes jeitos:

- **Clique no botão do Farol no minimapa** (ou na lista de addons do jogo ao lado do minimapa, nos clientes modernos)
- **Clique direito** no painel
- Digite `/farol menu`
- **Esc → Opções → AddOns → Farol**

O menu tem **quatro abas**:

- **Barra** — o que é da barra escolhida: **Editando: Barra 1 / 2 / 3** (só escolhe qual barra você está editando,
  não muda nada), **Mostrar** e **Travar**; num quadro à parte, **Aplicar pacote:** com os **pacotes prontos**
  (**Básico** volta ao básico; **Upando**, **Ouro e farm** e **Masmorras** ligam um conjunto de itens que combinam;
  depois de aplicar, o menu diz o que mudou e aparece **Desfazer** para voltar como estava — também
  `/farol pacote upando` / `/farol pacote desfazer`); os itens em grupos
  (Desempenho, Lugar, Equipamento e bolsas, Ouro, Progresso, Tempo e social), com uma **engrenagem** ao lado dos que
  têm configuração (ela abre a janela ou o aviso daquele item); uma **faixa embaixo explica o item sob o mouse**; e os
  botões **Aparência...** e **Ordem...** desta barra.
- **Avisos** — todos os avisos em grupos: Equipamento e bolsas, Personagem, Missões e viagem, Pausas, Como avisar
  (som, "Lembrar em", testar, histórico). No topo, **Só os recomendados** e **Desligar todos**
  (`/farol aviso recomendados` / `/farol aviso nenhum`); embaixo, a explicação do aviso sob o mouse. `/farol aviso`
  abre o menu nesta aba.
- **Ferramentas** — um botão para cada janela, com o que ela faz: Alarmes, Tarefas, Metas, Masmorras, **Missões concluídas**, Saques, Histórico e **Resumo agora**.
- **Geral** — o que vale para todos os seus personagens, em seções: **Idioma** (Auto / Português / English);
  **Chat e mensagens** (qual aba do chat, resumo da sessão ao entrar, de onde vem o XP e o ouro); **Barra e relógio**
  (hora do servidor, ouro de todos os personagens e o botão **Aparência...** para tooltip completo, botões rápidos,
  tamanho e fundo); **Minimapa e acessibilidade** (botão do minimapa mostrar / travar, cores para daltonismo);
  **Perfis (avançado)**: as mesmas barras em todos os personagens ou só neste, e **Copiar de...**; e, separado em
  vermelho, **Restaurar e apagar**: posição da barra, zerar sessão e **esquecer personagens** (pede um segundo clique).

**Botão no minimapa:** clique = menu, **clique direito = esconde/mostra todas as barras de uma vez** (só nesta sessão —
bom para prints; `/farol` também traz de volta), Shift + clique = aba Avisos. Arraste em volta do minimapa (se não
estiver travado). `/farol minimapa on|off|travar|destravar`. É um botão do próprio Farol — não precisa de outro addon
nem de biblioteca.

Aperte **Esc** para fechar. Se esconder a barra, use `/farol menu` para trazê-la de volta.

### Até 3 barras

No alto do menu, **Editando: [Barra 1] [Barra 2] [Barra 3]** escolhe qual barra o menu, a **Aparência...** e a
**Ordem...** mudam. Escolha **Barra 2**, marque **Mostrar** e os itens que quiser: cada barra tem **itens,
posição, aparência (escala, fundo, texto, formato, esconder em combate) e ordem próprios**. O clique direito numa barra
abre o menu já com ela escolhida. As barras 2 e 3 começam desligadas (e abaixo da barra 1); também dá para usar
`/farol barra 2 mostrar` / `/farol barra 2 esconder`. Alarmes, saques, avisos, idioma e os botões rápidos (📝 👜, ao lado
da barra 1) são compartilhados.

### Perfis: da conta ou só deste personagem

**Perfil: [Conta ▾]** no menu: por padrão todos os personagens usam o perfil da **conta** (as mesmas barras).
Escolha **Só este personagem** para dar ao personagem atual barras só dele (começa como cópia do perfil da conta; o
da conta continua guardado). **Copiar de... ▾** copia as 3 barras da conta ou de outro personagem seu para o perfil em
uso — `/farol perfil desfazer` volta como estava (até você sair do jogo). Comandos: `/farol perfil`,
`/farol perfil conta`, `/farol perfil personagem`, `/farol perfil copiar Nome` (ou `conta`). Só perfis dos seus
próprios personagens; esquecer um personagem (`/farol ouro esquecer Nome`) também esquece o perfil dele.

## Alarmes do relógio

Crie até **10 alarmes**, cada um com **hora local** ou **hora do servidor (do jogo)**, e um nome opcional.

- Abra a janela pelo botão **Alarmes...** no menu de opções, ou digite `/farol alarme`.
- Digite hora e minutos, clique em **Local/Servidor** para escolher o relógio, dê um nome se quiser e clique em **Adicionar**.
- Marque ou desmarque um alarme para ativar/desativar; **X** apaga. **Testar som** toca o som do alarme.
- **Tempo da soneca:** digite de 1 a 60 minutos e aperte **Enter** (padrão 5). O botão Soneca mostra o tempo atual.

Quando o alarme dispara, ele toca um som e mostra uma mensagem **só na sua janela de chat** — nada é
enviado ao servidor ou a outros jogadores — e aparece uma janelinha com **Soneca** e **Parar**.
Ele **repete a cada 30 segundos** até você apertar soneca ou parar. Um alarme ativado volta a tocar no dia seguinte.
Os alarmes funcionam mesmo com o painel escondido, e o item Horário mostra um ícone de relógio quando há alarme ativo.

Comandos no chat:

| Comando                                              | O que faz                                      |
|------------------------------------------------------|------------------------------------------------|
| `/farol alarme add 07:30`                            | Alarme às 07:30 (hora local)                   |
| `/farol alarme add 22:15 servidor Raide`             | Alarme às 22:15 do servidor com o nome "Raide" |
| `/farol alarme lista`                                | Lista os alarmes com seus números              |
| `/farol alarme ativar 2` / `/farol alarme desativar 2` | Ativa / desativa o alarme número 2           |
| `/farol alarme remover 2`                            | Apaga o alarme número 2                        |
| `/farol alarme soneca 10`                            | Define a soneca para 10 minutos (1 a 60)       |
| `/farol soneca`                                      | Adia pelo tempo configurado                    |
| `/farol soneca 15`                                   | Adia só desta vez por 15 minutos               |
| `/farol parar`                                       | Para o alarme tocando                          |

Os alarmes só tocam com o jogo aberto. Um alarme não dispara no mesmo minuto em que foi criado, nem
depois de um `/reload` dentro desse minuto (isso evita alarmes falsos).

## Aparência

Abra **Aparência...** no menu de opções (ou `/farol aparencia`):

- **Escala** de 50% a 200% e **opacidade do fundo** de 0% a 100% (0% = só o texto flutuando na tela), com botões [-]/[+].
- **Tamanho do texto** de 8 a 24 e **tamanho dos ícones** de 10 a 32, separados (a escala aumenta tudo junto). A barra
  e os botões ao lado se ajustam sozinhos.
- **Formato livre**: arraste a **alça no canto inferior direito da barra** (com a barra destravada) para escolher a
  largura. As informações se reorganizam em **colunas alinhadas à esquerda** que caibam: larga = uma linha, estreita =
  uma informação por linha, e no meio = 2, 3, 4… colunas. A altura se ajusta sozinha. Atalhos: **Uma linha** / **Uma
  coluna**. Travar a barra (`/farol lock`) esconde a alça.
- **Mostrar borda**, **mostrar ícones na barra** (um por item) e **mostrar o botão do histórico de avisos**, **mostrar o botão de saques**, **mostrar o botão das anotações** (desligado) e **tooltip completo** (todas as informações em qualquer item).
- **Esconder em combate** (volta quando a luta acaba) e **esconder em masmorras, raides, arenas e campos de batalha**.
  Os alarmes e os avisos continuam funcionando com a barra escondida.
- **Restaurar padrão** volta tudo ao normal.

Comandos: `/farol aparencia escala 120`, `/farol aparencia fundo 40`, `/farol aparencia texto 14`, `/farol aparencia icones 20`, `/farol aparencia linha`, `/farol aparencia coluna`, `/farol aparencia largura 400`,
`/farol aparencia borda`, `/farol aparencia combate`, `/farol aparencia instancia`, `/farol aparencia icones` (liga/desliga),
`/farol aparencia botao` (botão do histórico de avisos), `/farol aparencia botaosaques`, `/farol aparencia tooltip`,
`/farol aparencia padrao`.

## Avisos de durabilidade e bolsas

O Farol avisa **uma vez** quando a sua peça mais gasta fica abaixo de **20%** de durabilidade, e quando sobram
**2 ou menos** espaços nas bolsas (com um aviso separado de "Bolsas cheias!"). O aviso aparece **no centro da
tela e no seu chat** (nada é enviado a ninguém), com o som de checagem de prontidão do jogo.
Quando há lixo para vender, o aviso de bolsas diz: "… Há 3 espaço(s) com lixo (3g 26s) para vender."

- Só avisa de novo depois que a situação melhora (você reparou / liberou espaço), e no máximo uma vez a cada
  5 minutos, para não ficar repetindo enquanto você saqueia ou vende.
- Abra a aba **Avisos** do menu (ou `/farol aviso`) para ligar/desligar cada aviso, mudar os limites
  (durabilidade 5–50%, bolsas 0–10 espaços), desligar o som ou testar.
- Comandos: `/farol aviso durab 25`, `/farol aviso bolsas 4`, `/farol aviso durab off`, `/farol aviso som off`.

### Talentos e graus de magia

- **Pontos de talento não gastos:** "Você tem 2 ponto(s) de talento para gastar." Avisa ao entrar e a cada ponto novo.
- **Magias de grau antigo nas barras de ação:** "Bola de Fogo (Grau 3) — você já tem o Grau 5". O Farol lê seu
  grimório e suas barras e avisa uma vez por magia até você trocar. Ele **nunca** mexe nas suas barras (isso seria
  automação): quem arrasta o grau novo é você.
- Esses dois avisos nunca aparecem no meio da luta; esperam o combate acabar.
- `/farol aviso status` mostra o que o Farol consegue ler no seu cliente: os pontos não gastos, o resultado de **cada**
  fonte de talentos (o nome da função do jogo mudou entre versões do WoW, então o Farol consulta todas e usa o maior
  valor, além de uma estimativa pelo nível: nível − 9 menos os pontos gastos) e as magias de grau antigo encontradas. Para desligar: `/farol aviso talentos off` / `/farol aviso graus off`.

### Munição e reagentes

O item **Munição e reagentes** (desligado por padrão) conta o que a sua classe usa: munição do caçador, Fragmentos
de Alma do bruxo, Pó Arcano e runas do mago, velas do sacerdote, símbolos do paladino, sementes e reagentes de Dádiva
do druida, Ankhs do xamã, pós do ladino. **Você escolhe os limites de atenção e crítico** na aba Avisos
(padrão: munição 400 / 200, reagentes 10 / 5; o crítico precisa ser menor que o de atenção, 0 em atenção = sem
atenção; na barra, atenção = amarelo e crítico = vermelho, ou laranja com as cores para daltonismo), ou com `/farol aviso municao 400 200` e `/farol aviso reagentes 10 5`. Os avisos opcionais (desligados por
padrão) aparecem uma vez abaixo do vermelho, esperam a luta acabar e voltam depois que você reabastecer:
"Munição: 150 acabando — reabasteça antes de sair da cidade." Um reagente só passa a ser acompanhado depois que o
personagem já teve pelo menos um (um mago de nível 10 não é avisado sobre Pó Arcano). O Farol só **conta** — nunca
compra, usa ou move itens. `/farol aviso status` mostra o que foi encontrado.

### Profissões: procure um instrutor

No estilo clássico, as profissões param de subir em cada limite de treinamento (75, 150, 225, 300). Quando uma
chega ao limite, o Farol avisa uma vez: "Mineração 150/150 no máximo do treinamento — procure um instrutor para
continuar subindo." Avisa de novo no próximo limite depois que você treinar, nunca no último (300/300). Várias ao
mesmo tempo aparecem num aviso só. Espera a luta acabar, tem Silenciar / Lembrar como os outros e desliga com
`/farol aviso profissoes off` ou na janela de Avisos. `/farol aviso status` mostra as profissões lidas e qual
função do jogo respondeu.

### Lembretes de pausa e de beber água

Dois lembretes opcionais, **os dois desligados por padrão**, que você liga na janela de Avisos:

- **Lembrete de pausa**: "Você está jogando há 2h 00m — que tal uma pausa?"
- **Lembrete de beber água**: "Hora de beber água!"
- Você escolhe o intervalo de cada um (**15 a 240 minutos**; padrão 120 e 45). A contagem começa no login (ou
  quando você liga / muda o intervalo) e se repete.
- **Também em lutas, raides e masmorras** (desmarcado por padrão): desmarcado, um lembrete que vence durante uma
  luta ou dentro de masmorra, raide, arena ou campo de batalha **espera** e aparece assim que você sair.
- **Silenciar** desliga aquele lembrete até o fim da sessão (ele volta no próximo login).
- Comandos: `/farol aviso pausa 90`, `/farol aviso agua 30`, `/farol aviso pausa on` / `off`,
  `/farol aviso agua lutas on` / `off`.

### Silenciar ou lembrar depois

Cada aviso abre uma janelinha com duas opções:

- **Silenciar**: o aviso fica quieto e só volta se a situação mudar (ex.: você reparou e a durabilidade caiu de
  novo, ou ganhou um ponto de talento novo).
- **Lembrar em [30 min ▾]**: escolha **2, 5, 10, 15 ou 30 minutos** no menu; se o problema continuar, o aviso
  aparece de novo. O tempo que já vem escolhido é definido na janela de Avisos (padrão 30).

- **Vários avisos ao mesmo tempo aparecem juntos** numa janela só, uma linha para cada (com o próprio
  Silenciar / Lembrar), e mais **Silenciar todos** e **Lembrar todos em [N min ▾]**.
- Um lembrete por tipo de aviso: lembrar de novo troca o horário anterior. Lembrete de um problema que já foi
  resolvido (você reparou, gastou os pontos…) é descartado. Os lembretes acabam no `/reload` ou ao sair do jogo.
- No chat: `/farol aviso silenciar` e `/farol aviso lembrar [minutos]` (todos os avisos abertos), `/farol aviso padrao 10`.
- **Nada fica cortado (desde a 3.21):** um aviso longo quebra em até 3 linhas e a janela cresce na altura; passe o
  mouse num aviso para ver o texto inteiro, do que ele trata e onde ajustar. Arraste a **alça ◢** no canto para deixar
  a janela mais larga ou mais estreita (fica salvo; clique direito na alça ou **Posição padrão** volta à largura padrão).

### Histórico de avisos

Os **10 últimos avisos** (com data e hora) ficam guardados por personagem. Para abrir:

- clique no **botão de bilhete ao lado da barra**: um número vermelho mostra quantos avisos novos você ainda não viu;
- um **atalho de teclado** à sua escolha: Esc → Opções → Teclas de atalho → AddOns → Farol (usa o `Bindings.xml`
  oficial do jogo; só abre a janela);
- `/farol historico`, ou **Histórico...** na janela de Avisos.

## Metas de ouro e de nível

Escolha uma meta — **ouro** (por exemplo 500 de ouro) e/ou um **nível** (por exemplo 40) — com `/farol meta`, **Metas...**
na aba Ferramentas do menu, ou `/farol meta ouro 500` / `/farol meta nivel 40`. O item **Metas** da barra (desligado por
padrão) mostra quanto de cada meta você já tem e uma **estimativa** do tempo que falta pelo ritmo da sessão (ouro por
hora, XP por hora): `Meta 500g 44% ~27m · Nv 40 36% ~6h 10m` (amarelo enquanto falta, verde "alcançada"). O tooltip
mostra quanto você tem, a estimativa ("por volta das 22:41") e o ritmo. A estimativa de nível supõe que cada nível que
falta custa o XP do nível atual — use como referência. Aviso opcional (desligado): **"Meta alcançada: 500g!"**, uma vez
por meta. As metas são de cada personagem. `/farol meta limpar [ouro|nivel]` apaga.

### Metas de farm (itens)

Para juntar material de profissão, de missão ou de reputação: `/farol meta item [link] 40` (digite o comando e dê
**Shift + clique** no item para colocar o link) ou pelo nome, `/farol meta item Tecido de Seda 40` (o item precisa estar
nas bolsas ou no histórico de saques). Também dá para clicar em **+ Meta** numa linha da janela de saques 👜 (meta de 20,
que você muda depois). O item **Farm** da barra (desligado por padrão) mostra o item e o progresso
(`Tecido de Seda 27/40`: vermelho no começo, amarelo, verde ao completar) ou, com várias metas, quantas já foram
concluídas (`Farm 2/5`). O tooltip lista cada item com quantos você pegou nesta sessão, o ritmo por hora e a
estimativa ("+18 nesta sessão (~24/h) · faltam ~32m"). A contagem inclui o banco quando o jogo informa. A janela
**Metas...** lista os itens para mudar a quantidade ou apagar (X — apagou sem querer? **Desfazer**, ao lado do título
"Farm", ou `/farol meta item desfazer`). Até 10 itens por personagem; o aviso de meta
alcançada vale também para eles, uma vez por item. `/farol meta item remover <nome ou número>`, `/farol meta item limpar`.
O Farol só **conta** os itens: nunca move, vende, usa ou saqueia nada, e nada é enviado.

## Acessibilidade

- **Cores para daltonismo** (aba Geral, desligada por padrão; `/farol cores daltonismo` / `/farol cores padrao`):
  troca o verde (bom) por **azul** e o vermelho (ruim) por **laranja**, mantendo o amarelo (atenção). As três cores
  continuam diferentes para quem tem protanopia, deuteranopia ou tritanopia. Vale para a barra, os tooltips e os
  números dos botões 📝 👜.
- Valores em ouro mostram o número na cor normal do texto e só as letras **g / s / c** em dourado, prateado e cobre:
  assim o amarelo sempre quer dizer "atenção".
- Apagar uma tarefa ou uma meta de farm, ou aplicar um pacote, pode ser **desfeito** com um clique (nesta sessão).
- As cores de estado sempre vêm com um número ou uma palavra (`60 fps`, `Dur 54%`, `pronta`): a cor nunca é a única
  informação.
- O vermelho da barra é mais claro, para ler melhor sobre cenários claros; as janelas têm fundo opaco e as dicas usam
  um cinza mais claro.
- **Tab** passa para o próximo campo de número (aba Avisos e janela Metas); Enter confirma e Esc fecha.

## Pedra de Regresso

O item **Pedra de Regresso** mostra onde ela está vinculada e quanto falta da recarga: `Vila do Farol · 23m` (amarelo),
`Vila do Farol · pronta` (verde) ou `Vila do Farol · sem pedra` (cinza, quando ela não está nas bolsas — o lugar
continua aparecendo). O tooltip mostra a que horas ela fica pronta. Vem ligado **só em instalação nova** (aprovado
como exceção à regra "função nova vem desligada"); quem já usa o Farol recebe desligado e liga em Menu > Barra
(`/farol mostrar regresso`). Aviso opcional (desligado) na aba **Avisos**: **"Pedra de Regresso pronta"**, uma vez por
recarga, esperando o combate e a masmorra acabarem (`/farol aviso regresso on`). O tooltip do **ouro** também mostra
onde cada um dos seus personagens estava vinculado ao sair. O Farol só **lê**: nunca usa a pedra nem vincula em outro
lugar.

## Diário de missões

O item **Missões** da barra (desligado por padrão) mostra quantas missões há no diário e quantas cabem, e quantas já
estão **prontas para entregar**: `Missões 17/20 · 3 prontas` (verde com folga, amarelo a partir de 3 do limite, vermelho
cheio). O tooltip lista primeiro as **prontas para entregar** e depois as **em andamento**, com o objetivo que falta
(`3/8`), o nível colorido pela dificuldade (como no jogo) e quantas estão bem acima do seu nível (no máximo 5 por lista,
"… e mais N"). Dois avisos opcionais (desligados) na aba **Avisos**: **diário quase cheio** a partir de N missões
(`/farol aviso missoes 19`, `/farol aviso missoes on`) e **missões prontas** ao entrar numa cidade ou estalagem
(`/farol aviso prontas on`; no máximo a cada 5 minutos). O Farol só **lê** o diário: nunca aceita, entrega, abandona ou
compartilha missões, e não abre categorias fechadas do diário. `/farol aviso status` mostra o que foi lido.

**Quanto valem as missões prontas (desde a 3.23, desligado):** marque **XP e ouro das prontas** na aba Avisos e a barra
mostra `Missões 8/40 · 5 prontas (+7.4k XP)`; o tooltip ganha o total de XP e ouro das prontas, cada pronta com a sua
recompensa (as que mais dão XP primeiro), **"Entregando todas: nível 23 → 24 (sobram 6.5k XP)"** (ou quanto XP ainda
falta) e o XP das missões em andamento. As recompensas vêm do próprio jogo, para cada missão do diário (clientes
modernos). Aviso opcional **Prontas que sobem de nível** (desligado): uma vez por nível, quando entregar as prontas já
basta para subir de nível.

## Missões concluídas

A janela **Missões concluídas** (Menu > Ferramentas, ou `/farol concluidas`) mostra as missões que cada um dos **seus**
personagens entregou: `[32] Entrega na Baía do Farol — #4127 — Vale Norte — Hoje 21:40`, da mais nova para a mais
antiga, com **busca pelo nome ou pelo ID** e rolagem com a roda do mouse. O **ID** (`#4127`) é o número único que o jogo
dá a cada missão. **Clique numa missão** para ver o link dela no Wowhead, na seção do WoW Forever
(`https://www.wowhead.com/forever/pt/quest=ID/`), já selecionado para copiar com Ctrl+C e colar no navegador. Vale
também para as missões de antes do registro, que só têm o ID. O Farol não acessa a internet: só monta o endereço. No alto, escolha o personagem (só os seus, do mesmo reino).

- **O registro vem desligado.** Marque **"Registrar missões entregues"** na janela (ou `/farol concluidas registrar on`)
  e, a partir daí, cada missão entregue é guardada com nome, nível, zona e data (até 2.000 por personagem, as mais
  recentes).
- **Missões de antes do registro, só pelo ID:** marque **"Mostrar missões de antes do registro (só o ID)"** na janela
  (vem desligado) para ver, depois das registradas, as missões que o jogo informa como concluídas: `#3210 (antes do
  registro)`, das maiores para as menores, e buscáveis pelo ID. O Farol guarda esses IDs (até 15.000 por personagem) cada
  vez que você entra com o registro ligado; outros personagens aparecem depois que entrarem uma vez com ele ligado. A
  lista inclui marcadores internos do jogo (IDs que não são missões de verdade).
- **Nomes aprendidos com o jogo:** com o registro ligado, o Farol guarda o nome de cada missão que você **vê** — ao ler
  no NPC, ao aceitar, enquanto está no diário e ao entregar — num dicionário da conta (até 5.000 nomes, para todos os
  seus personagens). As missões de antes do registro mostram o nome quando ele já é conhecido; as outras aparecem como
  "(nome ainda não visto)". A janela mostra "Nomes conhecidos: X de Y". Tudo é leitura local: nenhum pedido ao servidor.
- **Total no jogo:** o número de missões que o jogo diz que o personagem já concluiu, **incluindo as de antes do
  registro**. Os nomes dessas missões antigas não aparecem: o jogo só os informa se o addon pedir ao servidor, e o Farol
  não faz esse pedido. O total inclui alguns marcadores internos do jogo, então pode ser um pouco maior que o real. Se o
  cliente não informar, aparece `--` (a lista do registro continua funcionando).
- Item opcional na barra (desligado): `Concluídas 412`, com o total de cada personagem, quantas foram entregues hoje e as
  últimas no tooltip.
- Fica tudo no seu computador (`FarolDB`); nada é enviado. **Esquecer personagens** também apaga a lista deles.
  `/farol aviso status` mostra qual função do jogo informou o total. O Farol só **lê**: nunca aceita, entrega ou
  abandona missões.

## Masmorras e raides

Ao entrar numa **masmorra ou raide**, o Farol começa uma "corrida" sozinho: tempo dentro, **XP**, **ouro** (o saldo,
então consertos entram na conta), **saques** (com raros e épicos) e **mortes** — só os seus números. O item **Masmorra /
raide** da barra (desligado por padrão) mostra isso enquanto você está dentro (`Ember Depths 18m · +4.2k XP · +12g`);
passe o mouse para ver detalhes e a última vez que esteve ali. Ao sair, um **resumo no seu chat** (pode desligar):
"saiu de Ember Depths (masmorra): 32m · XP +6.8k · Ouro +18g 40s · Saques 14 (2 raros, 1 épico) · Mortes 1". A janela
**Masmorras e raides** (`/farol masmorra`, ou **Masmorras...** na aba Ferramentas) mostra as **10 últimas corridas** do
personagem.

Um `/reload` lá dentro continua a corrida; se você ficar mais de 15 minutos fora do jogo, ela termina no último momento
visto. Visitas de menos de 1 minuto não ficam salvas. `/farol masmorra resumo on|off`, `/farol masmorra limpar`.
(`/farol instancias` continua listando suas instâncias salvas.)

## Tarefas diárias e semanais

Sua lista de coisas para fazer, por personagem (até 10): abra com `/farol tarefa` ou **Tarefas...** no menu, escreva a
tarefa, escolha **Diária** ou **Semanal** e clique em **Adicionar**. Marque o que já fez. **As diárias voltam a "falta"
no reset diário, e as semanais no reset semanal** — sozinhas. O item **Tarefas** da barra (desligado por padrão) mostra
quantas já fez (`Tarefas 3/5`, amarelo enquanto falta alguma, verde quando todas foram feitas); passe o mouse para ver
a lista. Aviso opcional (desligado): **1 hora antes do reset diário, se faltar alguma diária**.

O Farol não confere nada no jogo — quem marca as tarefas é você. Comandos: `/farol tarefa add [diaria|semanal] Nome`,
`/farol tarefa feita N`, `/farol tarefa apagar N`, `/farol tarefa desfazer`, `/farol tarefa lista`, `/farol tarefa aviso on|off`.
Na janela, **Tipo: Diária / Semanal** escolhe o tipo da nova tarefa; apagou uma sem querer (X)? Aparece
**Tarefa apagada: ... [Desfazer]**, que a devolve ao mesmo lugar (só nesta sessão).

## Anotações (bloco de notas)

Desde a 3.22, o Farol tem um bloco de notas da **conta inteira** (as mesmas anotações em todos os personagens): até
**10 anotações**, cada uma com um título curto (até 40 letras) e um texto de várias linhas (até 500 letras), salvos ao
digitar. Abra com `/farol notas` ou **Anotações...** em Menu > Ferramentas.

- À esquerda, a lista com uma caixinha para cada anotação: marque quando concluir. As concluídas vão para baixo, em
  cinza, e ficam até você apagar (nada zera sozinho).
- À direita, o título e o texto da anotação escolhida; **✓ Concluída / Reabrir** e **Apagar**.
- **Apagar** e **Limpar concluídas** perguntam antes (clique de novo para confirmar) e mostram **Desfazer** (só nesta
  sessão).
- Item opcional na barra **Anotações** (desligado): `Notas 2/5` = 2 pendentes de 5; passe o mouse para ver as pendentes.
- **Botão das anotações** ao lado da barra (desde a 3.25, desligado; Menu > Geral > **Aparência...** > "Mostrar botão
  das anotações", ou `/farol notas botao on`): o número mostra as pendentes; clique abre/fecha a janela,
  **Shift + clique** abre com uma anotação nova e passar o mouse lista as pendentes.
- **Tecla de atalho** à sua escolha: Esc → Opções → Teclas de atalho → AddOns → Farol → "Anotações" (o Farol não define
  nenhuma tecla).
- Comandos: `/farol notas nova Título`, `/farol notas lista`, `/farol notas desfazer`, `/farol notas botao on|off`.
- As anotações ficam só no seu computador; nada é enviado. O texto salvo é conferido ao carregar (tamanhos máximos,
  sem códigos do chat).

## Central do Farol (estilo detalhado)

Desde a 3.27 o Farol tem dois estilos. O **simples** funciona como sempre: cada janela abre sozinha. O **detalhado**
junta tudo num painel só, a **Central do Farol**. Desde a 3.28 uma **instalação nova** já começa no estilo detalhado;
quem já usava o Farol continua como estava até escolher. Ligue com `/farol central` (ou Menu > Geral > "Estilo
detalhado (Central do Farol)"); `/farol central off` ou o botão **Estilo simples** volta.

- Barra lateral com todas as seções: Início · Personagens · Metas · Missões · Profissões · Tarefas · Anotações ·
  Guardados · Masmorras · Saques · Alarmes · Avisos · Configurações, e o nome e o nível do personagem embaixo.
- **Início** mostra cartões: esta sessão (ouro, ouro por hora, XP, XP por hora e a barra de XP com o descansado),
  missões, tarefas e resets, equipamento e bolsas, anotações, itens guardados, o último aviso e personagens e
  profissões. Clique num cartão para abrir a seção.
- **Profissões** (3.28): um cartão por profissão com o grau, uma trilha com as marcas 75 · 150 · 225 · 300 (verde = o
  que você tinha, dourado = o que subiu nesta sessão, laranja = o limite do seu treinamento), os pontos ganhos na sessão
  (e por hora) e o próximo passo ("procure um instrutor para treinar Perito") ao chegar no limite.
- **Personagens** (3.28): tabela dos seus personagens deste reino (nível, ouro, descanso com barra, onde está a Pedra de
  Regresso, quando foram vistos), as instâncias salvas (chefes, tempo para resetar) e quem está com o descanso cheio ou
  quando vai estar.
- **Tarefas, Anotações e Guardados** (3.29) em cartões: tarefas em duas colunas (diárias e semanais, cada uma com
  "N de M", barra de progresso e o tempo até o reset); anotações com a lista à esquerda e o editor à direita
  ("editada ..."); guardados em cartões com o ícone do item, a quantidade (com o banco), o motivo e quando dá para
  usar. O estilo simples continua com as janelas de sempre.
- **Metas, Missões concluídas e Masmorras** (3.30) em cartões: ouro e nível lado a lado ("Você tem", "Falta", o
  tempo no ritmo atual e uma barra) e as metas de farm em cartões (ícone, barra, ganho da sessão, estimativa); missões
  concluídas com um resumo (registradas, hoje, total no jogo) e a lista com o link do Wowhead; masmorras com a corrida
  atual ao vivo, as médias das últimas corridas e o histórico.
- **Saques, Alarmes e Avisos** (3.31) em cartões: saques com filtros, um resumo e um cartão por item (botões Guardar
  e + Meta); alarmes com o próximo em destaque ("toca em ...", ao vivo), o formulário e um cartão por alarme; o
  histórico de avisos numa linha do tempo por dia (HOJE, ONTEM) com um resumo.
- **Configurações** (3.32) em cartões dentro da Central: aba Barra com os cartões da barra e dos pacotes e um cartão
  por grupo de itens ("3 de 8" ligados), Avisos em cartões por grupo com os números na própria linha, um cartão por
  ferramenta e Geral em cartões (Idioma, Perfis, Chat, Barra e relógio, Minimapa e acessibilidade; "Restaurar e
  apagar" à parte, em vermelho). As mesmas opções do menu de sempre, sincronizadas; fora da Central o menu fica igual.
- **Janelinhas de aviso e de alarme** (3.33) no visual da Central quando o estilo detalhado está ligado: moldura do
  Farol, faixa colorida do nível (alerta, atenção, informação), ícone do tipo de aviso e o texto em título + detalhe; o
  alarme mostra a hora em destaque, o nome e Local/Servidor, com a borda mais clara enquanto toca.
- **Tamanho da Central** (3.31): arraste a alça ◢ no canto inferior direito para aumentar ou diminuir a Central
  inteira (70% a 130%); duplo clique volta a 100%, ou use `/farol central tamanho 85`. Fica salvo na conta.
- As outras seções são as janelas de sempre, encaixadas na Central; arrastá-las move a Central. Com o estilo
  detalhado ligado, qualquer janela do Farol (por comando, pelo menu ou pelo botão do minimapa) abre dentro dela.
- No topo: idioma e **Estilo simples**; no rodapé: Resumo agora, Barra... e Aparência....
- A barra em si não muda nos dois estilos. Só leitura; nada é enviado.

## Itens guardados (para depois)

Desde a 3.26, dá para ter uma lista de itens que você quer guardar — por exemplo um material de uma receita que só
aprende num nível mais alto. Abra com `/farol guardar` ou **Guardados...** em Menu > Ferramentas. A lista é da
**conta inteira** (até 50 itens).

- No topo: o item — **clique na caixa para escolher numa lista do que você tem** (bolsas, mais o banco como estava na
  última vez que você o abriu; digitar filtra, a rodinha rola, clique ou Enter escolhe), ou use `/farol guardar` e
  Shift + clique no item —, um **motivo** opcional e
  **quando** ele fica útil: sem prazo, num **nível do personagem** ou num **nível de profissão** (das suas profissões).
  Clique numa linha para trazê-la de volta ao formulário e mudar.
- Cada linha mostra quantos você tem (e quantos estão no banco, quando o jogo informa), o motivo e o estado:
  "nível 35 — faltam 7", "já pode" ou "sem prazo". **X** tira da lista, com **Desfazer** no rodapé.
- Itens guardados não entram no **Lixo nas bolsas**. A janela de **Saques** tem um botão **Guardar** em cada item
  (um ✓ quando já está guardado).
- O jogo só mostra o banco enquanto ele está aberto: ao abrir, o Farol anota quais itens estão lá (número e nome do
  item, até 1000, por personagem) só para essa lista. Ele nunca abre o banco nem mexe em itens.
- Lembretes opcionais (desligados, na janela ou por comando):
  - **no comerciante** (`/farol guardar comerciante on`): quais guardados estão nas bolsas, com o motivo;
  - **na hora certa** (`/farol guardar hora on`): uma vez por personagem, ao chegar no nível ou na profissão;
  - **no tooltip do item** (`/farol guardar tooltip on`): uma linha "Farol: guardado — motivo".
- Item opcional na barra **Itens guardados** (desligado): `Guardados 4 · 1` = 4 guardados, 1 já pode.
- O Farol nunca vende, move nem trava itens: só lembra. Nada é enviado; a lista é conferida ao carregar.

## Resumo da sessão

`/farol resumo` mostra, **só no seu chat**, o que você fez nesta sessão:

```
Farol: resumo da sessão (2h 14m):
Farol:   Ouro: +38g 12s (+17g 6s/h) · XP: +84.2k (1 nível, 37.6k/h)
Farol:   Reputação: +1.3k Harbor Guild (Honrado → Reverenciado)
Farol:   Saques: 46 (3 raros, 1 épico) · Avisos: 2
```

- Quando você sai do jogo, o Farol guarda esse resumo para o personagem e, **na próxima vez que você entrar**, mostra
  "última sessão (data, duração)" no seu chat. Ele não aparece depois de um `/reload`, e sessões com menos de
  5 minutos não são guardadas.
- Para desligar: **Resumo da sessão ao entrar** no menu de opções, ou `/farol resumo off`.
- Usa os mesmos números da barra (ouro da sessão, XP/h, reputação por hora) e os históricos de saques e de avisos.
  Nada é enviado a ninguém.

### Mensagens do Farol numa aba de chat própria (desde a 3.20)

O Farol só escreve no **seu** chat (nada é enviado). Por padrão, no chat principal; para separar:

1. Clique direito numa aba do chat → **Nova janela** e dê o nome **Farol** (uma vez; o Farol nunca cria nem renomeia
   abas).
2. Escolha em Menu > Geral > **"Mensagens do Farol em"**, ou digite `/farol chat Farol`.

Tudo o que o Farol escreve vai para lá: resumo da sessão, avisos no chat, diagnóstico, respostas dos comandos,
novidades. As janelinhas de alarme e de aviso continuam na tela, como antes. Se a aba for fechada ou renomeada, as
mensagens voltam ao chat principal, para nada se perder. `/farol chat` lista as suas janelas de chat;
`/farol chat principal` volta ao padrão.

### De onde vem o XP e o ouro (opcional, desde a 3.19)

Ligue **"Mostrar de onde vem o XP e o ouro"** (Menu > Geral, ou `/farol origem on`) e os tooltips do XP e do ouro,
além do resumo da sessão, dividem a sessão por origem:

- **XP:** missões (com quantas você entregou), monstros (XP ganho em luta ou até 3 s depois) e outros (descobrir
  lugares, profissões).
- **Ouro:** recompensas de missão, saque de monstros (com a janela de saque aberta), vendas ao comerciante, compras
  e consertos no comerciante, e outros (correio, leilão, troca, treinadores, voos...).
- Missões usam o XP e o ouro que o jogo informa na entrega; se o jogo não informar, conta a mudança que chega junto
  da entrega (até 2 s). "Outros" é sempre o total da sessão menos as outras origens, então a soma bate com o ouro e o
  XP da sessão. O `/farol diagnostico` mostra se o jogo informou a recompensa.
- As porcentagens são da sessão inteira (o jogo não informa quanto tempo você passou em cada atividade, então não há
  "por hora" de cada origem). Vem desligado; só lê eventos que o jogo já manda; nada é enviado.

## Janela de últimos saques

Uma janela separada que lista os itens que **você** saqueou ou recebeu, do mais novo para o mais antigo.

- Abra pelo **botão de bolsa ao lado da barra** (um número verde mostra os itens saqueados desde a última vez
  que você abriu), pelo botão **Saques...** no menu de opções, ou com `/farol saque`.
- Menu **Mostrar** — 5, 10, 15 ou 20 itens recentes.
- Menu **Qualidade** — marque Inferior, Comum, Incomum, Raro, Épico e Lendário+ (nomes e cores vêm do próprio jogo), ou use *Marcar todas* / *Desmarcar todas*.
- **Redimensionável** — arraste a alça do canto; a lista acompanha a largura e rola com a roda do mouse quando não cabe tudo. O tamanho fica salvo.
- Cada linha mostra o ícone, o link do item colorido, a quantidade e **quando** você saqueou: **Hoje 21:42**,
  **Ontem 21:27**, ou a data para os mais antigos (**08/11 21:12**). Passe o mouse para ver o tooltip do item, que
  também mostra a data completa ("Saqueado: domingo, 08/11/2026 às 21:12"); **Shift+clique** coloca o link na sua
  caixa de chat (você decide se envia).
- O histórico é salvo **por personagem** (últimos 100 itens). **Limpar** pergunta antes ("Apagar 23 itens?") e o
  segundo clique, em até 5 segundos, apaga tudo. O mesmo vale para o Histórico de avisos e para as masmorras.

Ele lê só as mensagens de saque do próprio jogo sobre **você** ("Você recebe saque: …"), usando os textos do
cliente, então funciona em qualquer idioma. O saque de outros jogadores é ignorado. Em algumas situações de
instância/combate o cliente moderno pode esconder o conteúdo do chat dos addons; esses itens simplesmente não são registrados.

## Itens da barra

Seis itens vêm ligados (FPS, latência, coordenadas, zona, durabilidade e ouro); os outros começam desligados —
marque no menu.

Os itens de sessão (ouro da sessão, ouro/h, XP/h, reputação por hora, tempo de sessão) contam desde que você entrou ou deu `/reload`.
Use **Zerar sessão** no menu, ou `/farol sessao zerar`, para recomeçar (por exemplo, ao trocar de lugar de farm).

| Item             | Mostra                                                    | Nome no comando | Padrão     |
|------------------|-----------------------------------------------------------|-----------------|------------|
| FPS              | Quadros por segundo (verde ≥ 50, amarelo ≥ 25)            | `fps`           | ligado     |
| Latência         | A maior entre latência local/mundo (verde ≤ 100 ms)       | `ms`            | ligado     |
| Memória          | Memória Lua total (interface + addons)                    | `mem`           | desligado  |
| Coordenadas      | Sua posição no mapa (`--` dentro de instâncias)           | `coords`        | ligado     |
| Zona             | Nome da zona atual                                        | `zona`          | ligado     |
| Velocidade       | Velocidade de movimento (100% = correndo normal)          | `vel`           | desligado  |
| Durabilidade     | Sua peça **mais danificada** (vermelho abaixo de 20%)     | `durab`         | ligado     |
| Bolsas           | Espaços livres / total (vermelho com 2 ou menos)          | `bolsas`        | desligado  |
| Lixo nas bolsas  | Valor de venda dos itens cinzentos e espaços que ocupam   | `lixo`          | desligado  |
| Munição e reagentes | Munição/reagentes da sua classe, com cores pelos seus limites | `municao` | desligado  |
| Ouro             | Dinheiro do personagem (total opcional de todos os seus personagens) | `ouro` | ligado     |
| Ouro da sessão   | Quanto ganhou ou gastou desde que entrou / `/reload`      | `sessao`        | desligado  |
| Ouro por hora    | Ouro da sessão por hora (vermelho quando negativo)        | `ouroh`         | desligado  |
| Experiência (XP) | % de XP e bônus descansado (some no nível máximo)         | `xp`            | desligado  |
| XP por hora      | XP/h e tempo até o próximo nível (após 1 min de sessão)   | `xph`           | desligado  |
| Reputação        | Facção acompanhada: nível (cores do jogo), progresso %, rep/hora | `rep`           | desligado  |
| Profissões       | Profissões principais com nível/limite do treinamento (amarelo perto, vermelho no limite) | `prof` | desligado |
| Missões concluídas | Total de missões concluídas deste personagem (lista de cada personagem na janela) | `concluidas` | desligado |
| Horário          | Hora local, ou do servidor (opção no menu)                | `hora`          | desligado  |
| Resets           | Tempo até o reset diário e o semanal                      | `reset`         | desligado  |
| Anotações        | Anotações pendentes do bloco de notas (`Notas 2/5`)        | `notas`         | desligado  |
| Itens guardados  | Itens guardados para depois e quantos já podem ser usados (`Guardados 4 · 1`) | `guardados` | desligado |
| Tempo de sessão  | Quanto tempo está jogando desde que entrou / `/reload`    | `tempo`         | desligado  |
| Amigos online    | Quantidade de amigos online (WoW + Battle.net)            | `amigos`        | desligado  |
| Guilda online    | Quantidade de membros da guilda online (some sem guilda)  | `guilda`        | desligado  |

**Ordem:** abra **Ordem...** no menu de opções (ou `/farol ordem`) e use as setas [▲]/[▼] para mover cada item;
a barra muda na hora (em qualquer formato). Os itens escondidos aparecem em cinza, para você já deixar a posição
pronta. **Restaurar ordem padrão** (ou `/farol ordem padrao`) desfaz tudo.

Exemplo: `/farol hide ouro` esconde o ouro; `/farol show ouro` mostra de volta. Também funcionam
`mostrar`/`esconder` e os nomes em inglês (`zone`, `gold`, `bags`…). Suas escolhas ficam salvas.

**Reputação:** mostra a facção que você marcar como **"Mostrar como barra de experiência"** no painel de reputação
do jogo. O tooltip mostra também o progresso, a reputação por hora e uma estimativa do tempo até o próximo nível.

**Ouro de todos os seus personagens:** o Farol lembra do ouro e do nível de cada personagem **seu** quando você
joga com ele, e o tooltip do ouro lista todos por reino (do mais rico ao mais pobre, com a última vez que você jogou
com cada um) e o total. Marque **Ouro de todos os personagens na barra** (ou `/farol ouro total on`) para ver
`123g 45s 67c (Total 1482g 10s)`. Ele só conhece um personagem depois que você entra com ele uma vez com o Farol
ligado. Use **Esquecer personagens** nas opções (dois cliques para confirmar) ou `/farol ouro esquecer Nome` para
personagens que você apagou. Tudo fica só no seu computador.

**Descanso dos seus personagens:** ao sair, o Farol também guarda o seu XP descansado e se você estava numa estalagem
ou cidade. O tooltip do ouro mostra então uma **estimativa** para os outros personagens — por exemplo
`Mira (34) 150% cheio` ou `Tomas (22) 5% cheio em ~9d 16h` — pelas regras do estilo clássico: em estalagem/cidade,
5% de um nível a cada 8 horas; fora, um quarto disso; até 150%. O valor real substitui a estimativa quando você entra
com o personagem. Aviso opcional (desligado por padrão) na janela de Avisos ou com `/farol aviso descansado on`:
"Descanso cheio (150%): Mira (34)…", uma vez por sessão.

**Lixo nas bolsas:** soma o preço de venda dos itens cinzentos (Inferior), por exemplo `Lixo 3g 26s (3)`; o
tooltip mostra os que valem mais. **O Farol nunca vende nada** (isso seria automação): quem vende é você, no
comerciante. Itens que o jogo ainda não carregou entram na conta assim que as informações chegam.

**Profissões:** a barra mostra as profissões principais (ou as secundárias, se você não tiver principal); o tooltip
lista todas, incluindo culinária, pesca e primeiros socorros, com os pontos ganhos nesta sessão.

**Resets:** contagem regressiva até o reset **diário** e o **semanal**, com o tempo que o próprio jogo informa. O
tooltip mostra quando cada um acontece, na hora local e na do servidor. Clientes antigos só informam o diário.
O tooltip também lista as suas **instâncias salvas** (bloqueios de raide/masmorra) — por exemplo
`Núcleo Derretido 7/10 chefes, reset em 2d 4h` — e o tooltip do ouro mostra onde os seus **outros personagens** estão
salvos (guardado ao sair; bloqueios vencidos somem sozinhos). `/farol instancias` lista tudo no seu chat. Para ter a
lista, o Farol pede ao servidor uma vez ao entrar e, depois, no máximo uma vez por minuto (o mesmo pedido da janela de
Raide do próprio jogo).

**Tooltip:** passe o mouse num item para ver **só os detalhes dele** — por exemplo, o ouro mostra seu ouro, ouro por
hora, seus personagens e o descanso/instâncias deles; a durabilidade mostra cada peça danificada; os Resets mostram os
horários e as instâncias salvas. Segure **Shift** (ou passe o mouse na borda da barra) para ver **tudo** de uma vez:
latência local/mundo, subzona, XP exato, hora local *e* do servidor, amigos separados por WoW / Battle.net, e mais.
Listas longas mostram 5 linhas e "e mais N". Prefere o jeito antigo? Marque **Tooltip completo** na janela de
Aparência (`/farol aparencia tooltip`).

**Privacidade:** os itens de amigos e guilda leem só **quantidades**; nenhum nome é lido ou guardado.

## Idioma

Por padrão o addon usa o idioma do seu cliente: **português** em clientes `ptBR`/`ptPT`
e **inglês** em todos os outros. Você pode trocar a qualquer momento com `/farol lang pt` ou `/farol lang en`;
a escolha fica salva.

## Descobrindo a versão do seu cliente

Rode `/farol version` no jogo. O número de Interface que aparecer vai na primeira linha do `.toc`:

- `Farol_Mainline.toc` — **WoW Forever** (16001) e Retail. **É este o arquivo que o WoW Forever lê.**
- `Farol_Camelot.toc` — reserva específica do WoW Forever (16001)
- `Farol_Vanilla.toc` — Classic Era (11507)
- `Farol.toc` — padrão para qualquer outro cliente

O cliente escolhe o `.toc` com o sufixo correspondente e, se não houver, usa o padrão. Se um patch futuro do
WoW Forever marcar o addon como incompatível, atualize o número no `_Mainline.toc` a partir da versão da tela
de login (ex.: 1.60.1 → 16001), ou confira no jogo com `/run print(select(4, GetBuildInfo()))`.

### Observações sobre o WoW Forever

O WoW Forever roda no cliente moderno (Midnight) e herda as restrições de combate chamadas "secret values".
Toda leitura do Farol é protegida: se o jogo esconder ou bloquear um valor (por exemplo, em combate), o painel
mostra `--` em vez de dar erro.

O WoW Forever **não informa o reino** e os personagens têm **nome e sobrenome**. O Farol identifica cada personagem
pelo nome + sobrenome (ex.: "Oxis Raknash") e agrupa todos num reino de reserva, mostrado como "este reino". Isso vale
para o ouro e o descanso dos seus personagens, as instâncias salvas, os perfis por personagem e as missões concluídas.
`/farol aviso status` mostra como o personagem foi identificado. No momento de sair do jogo, o WoW Forever informa
0 de ouro; por isso o Farol grava o ouro da última leitura feita durante o jogo, e outras leituras que falharem nessa
hora (XP descansado, instâncias salvas, lugar da Pedra de Regresso) nunca apagam o que já estava salvo.

`/farol diagnostico` (desde a 3.18) mostra **no seu próprio chat** como o jogo respondeu: nome e sobrenome do
personagem, o reino como o jogo informou, o ouro atual, se o jogo informou 0 de ouro no seu último logout (e o Farol
manteve o valor certo), hora do servidor e resets, missões concluídas e quantas vezes alguns eventos do jogo aconteceram
nesta sessão (entrega de missão, janela de recompensa, missão aceita, ouro mudou). Só lê: nada é enviado nem pedido ao
servidor, e as contagens ficam só na memória. Um print dele ajuda muito ao relatar um problema.

## Segurança

Segurança da informação é a primeira regra deste projeto:

- **Nada sai do seu computador.** O addon não usa `SendAddonMessage`, chat ou qualquer canal para enviar dados.
- **Nenhum código externo é executado.** Sem `loadstring`/`RunScript`; comandos aceitam só palavras fixas.
- **Sem automação.** Ele só lê e exibe informações; não joga por você (o que violaria as regras do servidor).
- **Dados salvos são validados.** `FarolDB` guarda só as suas configurações: posição e estado do painel, idioma,
  itens visíveis e a ordem deles, aparência, alarmes (hora, tipo de relógio, ligado/desligado, um nome já limpo e o
  tempo da soneca), ajustes da janela de saques e dos avisos (desde a 3.0 os ajustes da barra ficam agrupados num perfil), as suas anotações (bloco de notas, títulos e textos conferidos ao carregar) e o ouro e o nível dos **seus próprios** personagens
  por reino (para o total da conta). `FarolCharDB` (por personagem) guarda só o histórico
  de saques (links de item validados), os 10 últimos avisos, o resumo da última sessão (só números, inclusive o XP/ouro por origem quando essa opção está ligada) e se o jogo informou 0 de ouro no último logout (sim/não e quando, para o `/farol diagnostico`). Tudo é verificado ao carregar — um arquivo corrompido
  ou adulterado volta para os valores padrão.
- **Baixe só das fontes oficiais** (este repositório ou a página do CurseForge). Addons são texto Lua: você pode ler
  todo o código na pasta `Farol`.

Encontrou um problema de segurança? Relate de forma **privada** (Security → Report a vulnerability), como explicado
no [`SECURITY.md`](SECURITY.md). Nunca inclua dados pessoais, senhas ou informações da sua conta.

## Testes

O addon tem testes automáticos que rodam **fora do jogo**, em Lua 5.1 (a mesma versão do cliente do WoW),
usando um simulador simples da API do WoW (`tests/wow_mock.lua`). Eles cobrem a barra nos clientes WoW Forever
e 3.3.5a, os valores bloqueados (secret values), o menu de opções, os alarmes e a soneca, a janela de saques,
os avisos (inclusive os lembretes de pausa e água e a janela agrupada), a aparência, a reputação, os resets, o resumo
da sessão, os arquivos `.toc`, uma varredura que falha se o código algum dia usar APIs de automação, de mensagens ou
de execução de código, uma checagem de que o addon não cria nomes globais genéricos (só `Farol…`), e um fuzzing com
comandos, mensagens de chat e dados salvos aleatórios e maliciosos. A suíte roda em Lua 5.1 e também é conferida em
Lua 5.4. Ela roda **duas vezes**: uma com um simulador "de livro" e outra ("forever-real") do jeito que o WoW Forever
responde de verdade — reino vazio, sobrenome no nome do personagem e ouro 0 ao sair —, além de um teste em que todas
as leituras do jogo voltam 0 ou vazio no logout e nada salvo pode se perder.

```
lua5.1 tests/run.lua
```

O GitHub Actions roda os testes a cada push e pull request (`.github/workflows/tests.yml`) e anexa a cada
execução um pacote `Farol-<versão>` pronto para instalar (aba Actions → a execução → *Artifacts*).

## Publicando no CurseForge

O texto da página está em [`assets/curseforge-description.md`](assets/curseforge-description.md) e o avatar do
projeto em [`assets/farol-icon-400.png`](assets/farol-icon-400.png); as imagens (ilustrações) estão em
[`assets/curseforge/`](assets/curseforge/). Envie um ZIP que tenha na raiz **só** a pasta `Farol` (com o
`LICENSE.txt` dentro dela — qualquer arquivo solto na raiz é recusado), e selecione a versão do jogo do WoW Forever
(1.60.1). Cada execução do GitHub Actions monta esse pacote para você (*Artifacts*).

O ícone do jogo (`Farol/Media/Farol.tga`, que aparece na lista de AddOns) é uma arte original feita para este projeto.

## Conformidade com a política de addons da Blizzard

Este addon segue a [Política de Desenvolvimento de AddOns da Blizzard](https://us.forums.blizzard.com/en/wow/t/ui-add-on-development-policy/24534):

| Regra da política | Este addon |
|---|---|
| Deve ser gratuito | ✅ Gratuito, licença MIT — sem versão paga nem funções pagas |
| Código visível (sem ofuscação) | ✅ Lua simples e comentado na pasta `Farol` |
| Sem propaganda ou pedidos de doação | ✅ Nenhum, nem no jogo nem neste repositório |
| Não pode prejudicar o desempenho do servidor | ✅ Só dois pedidos ao servidor, ambos de leitura e com limite: a lista da guilda (no máximo 1 vez por minuto, só com o item Guilda ligado) e a lista de instâncias salvas (1 vez ao entrar e depois no máximo 1 vez por minuto) — os mesmos pedidos que as janelas de Guilda e de Raide do jogo fazem |
| Não pode automatizar o jogo | ✅ Usa só a API oficial de addons para **ler e mostrar** informações; nunca lança magias, move, seleciona alvos, compra, vende ou manda mensagens |
| Deve seguir os Termos de Uso / EULA | ✅ Sem programas externos, sem leitura de memória, sem injeção — não é um `.exe` |

**Não é afiliado à Blizzard Entertainment.** World of Warcraft e WoW Forever são marcas da Blizzard Entertainment, Inc.

### Como evitar banimento

- O que dá ban são **bots, programas de automação, "unlockers", ferramentas de memória/injeção e exploits** — não addons Lua comuns como este.
- Evite programas que apertam teclas por você (ex.: macros de AutoHotkey); eles podem gerar ban por "automação de terceiros".
- Nunca rode um `.exe` que diga ser addon. Addon de verdade é só arquivo de texto `.lua`/`.toc`/`.xml`.
- Baixe só deste repositório (ou das releases oficiais dele) e nunca digite sua senha fora do launcher oficial da Battle.net.

## Histórico de versões

Veja o [`CHANGELOG.md`](CHANGELOG.md) para as mudanças de cada versão (em inglês).

## Licença

MIT — use, modifique e distribua livremente. Veja `LICENSE`.
