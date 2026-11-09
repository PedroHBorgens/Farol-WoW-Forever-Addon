# Farol

**Português** | [English](README.md)

**Farol** é um addon **gratuito, de código aberto e não oficial** para WoW Forever: mostra um painel pequeno e arrastável com
**FPS · latência · memória · coordenadas · zona · velocidade · durabilidade · bolsas · ouro · ouro da sessão · XP · horário · tempo de sessão · amigos · guilda** — você escolhe o que aparece.
Passe o mouse no painel para ver um tooltip com detalhes, e escolha quais itens aparecem na barra.

## Instalação

> **Vindo do "WoW Forever Info"?** O addon mudou de nome. Apague a pasta antiga
> `Interface/AddOns/WoWForeverInfo` antes de instalar o `Farol`. As configurações antigas não são
> levadas junto (é só marcar seus itens de novo no menu), e o comando agora é `/farol`.

1. Baixe este repositório (botão **Code → Download ZIP**).
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
| `/farol sessao zerar`| Recomeça ouro da sessão, ouro/h, XP/h e tempo |
| `/farol aviso`      | Abre a janela de avisos (durabilidade e bolsas) |
| `/farol historico`  | Últimos 10 avisos (também pelo botão ao lado da barra ou por atalho de teclado) |
| `/farol aparencia`  | Abre a janela de aparência (escala, fundo, formato, esconder em combate) |
| `/farol ordem`      | Escolhe a ordem das informações na barra |
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

- **Clique direito** no painel
- Digite `/farol menu`
- **Esc → Opções → AddOns → Farol**

No menu você escolhe os itens da barra, mostra/trava o painel, troca o relógio para a hora do servidor, escolhe o idioma (Auto / Português /
English) e reseta a posição. Aperte **Esc** para fechar. Se esconder o painel, use `/farol menu` para trazê-lo de volta.

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
- **Mostrar borda**, **mostrar ícones na barra** (um por item) e **mostrar o botão do histórico de avisos** e **mostrar o botão de saques**.
- **Esconder em combate** (volta quando a luta acaba) e **esconder em masmorras, raides, arenas e campos de batalha**.
  Os alarmes e os avisos continuam funcionando com a barra escondida.
- **Restaurar padrão** volta tudo ao normal.

Comandos: `/farol aparencia escala 120`, `/farol aparencia fundo 40`, `/farol aparencia texto 14`, `/farol aparencia icones 20`, `/farol aparencia linha`, `/farol aparencia coluna`, `/farol aparencia largura 400`,
`/farol aparencia borda`, `/farol aparencia combate`, `/farol aparencia instancia`, `/farol aparencia padrao`.

## Avisos de durabilidade e bolsas

O Farol avisa **uma vez** quando a sua peça mais gasta fica abaixo de **20%** de durabilidade, e quando sobram
**2 ou menos** espaços nas bolsas (com um aviso separado de "Bolsas cheias!"). O aviso aparece **no centro da
tela e no seu chat** (nada é enviado a ninguém), com o som de checagem de prontidão do jogo.

- Só avisa de novo depois que a situação melhora (você reparou / liberou espaço), e no máximo uma vez a cada
  5 minutos, para não ficar repetindo enquanto você saqueia ou vende.
- Abra **Avisos...** no menu de opções (ou `/farol aviso`) para ligar/desligar cada aviso, mudar os limites
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

### Silenciar ou lembrar em 30 minutos

Cada aviso abre uma janelinha com duas opções:

- **Silenciar**: o aviso fica quieto e só volta se a situação mudar (ex.: você reparou e a durabilidade caiu de
  novo, ou ganhou um ponto de talento novo).
- **Lembrar em 30 min**: se o problema continuar daqui a 30 minutos, o aviso aparece de novo.

Vários avisos ao mesmo tempo aparecem um de cada vez. No chat: `/farol aviso silenciar`, `/farol aviso lembrar`.

### Histórico de avisos

Os **10 últimos avisos** (com data e hora) ficam guardados por personagem. Para abrir:

- clique no **botão de bilhete ao lado da barra**: um número vermelho mostra quantos avisos novos você ainda não viu;
- um **atalho de teclado** à sua escolha: Esc → Opções → Teclas de atalho → AddOns → Farol (usa o `Bindings.xml`
  oficial do jogo; só abre a janela);
- `/farol historico`, ou **Histórico...** na janela de Avisos.

## Janela de últimos saques

Uma janela separada que lista os itens que **você** saqueou ou recebeu, do mais novo para o mais antigo.

- Abra pelo **botão de bolsa ao lado da barra** (um número verde mostra os itens saqueados desde a última vez
  que você abriu), pelo botão **Saques...** no menu de opções, ou com `/farol saque`.
- Menu **Mostrar** — 5, 10, 15 ou 20 itens recentes.
- Menu **Qualidade** — marque Inferior, Comum, Incomum, Raro, Épico e Lendário+ (nomes e cores vêm do próprio jogo), ou use *Marcar todas* / *Desmarcar todas*.
- **Redimensionável** — arraste a alça do canto; a lista acompanha a largura e rola com a roda do mouse quando não cabe tudo. O tamanho fica salvo.
- Cada linha mostra o ícone, o link do item colorido, a quantidade e a hora. Passe o mouse para ver o tooltip
  do item; **Shift+clique** coloca o link na sua caixa de chat (você decide se envia).
- O histórico é salvo **por personagem** (últimos 100 itens). **Limpar** apaga tudo.

Ele lê só as mensagens de saque do próprio jogo sobre **você** ("Você recebe saque: …"), usando os textos do
cliente, então funciona em qualquer idioma. O saque de outros jogadores é ignorado. Em algumas situações de
instância/combate o cliente moderno pode esconder o conteúdo do chat dos addons; esses itens simplesmente não são registrados.

## Itens da barra

Os seis primeiros vêm ligados; os outros começam desligados — marque no menu.

Os itens de sessão (ouro da sessão, ouro/h, XP/h, tempo de sessão) contam desde que você entrou ou deu `/reload`.
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
| Ouro             | Dinheiro do personagem                                    | `ouro`          | ligado     |
| Ouro da sessão   | Quanto ganhou ou gastou desde que entrou / `/reload`      | `sessao`        | desligado  |
| Ouro por hora    | Ouro da sessão por hora (vermelho quando negativo)        | `ouroh`         | desligado  |
| Experiência (XP) | % de XP e bônus descansado (some no nível máximo)         | `xp`            | desligado  |
| XP por hora      | XP/h e tempo até o próximo nível (após 1 min de sessão)   | `xph`           | desligado  |
| Horário          | Hora local, ou do servidor (opção no menu)                | `hora`          | desligado  |
| Tempo de sessão  | Quanto tempo está jogando desde que entrou / `/reload`    | `tempo`         | desligado  |
| Amigos online    | Quantidade de amigos online (WoW + Battle.net)            | `amigos`        | desligado  |
| Guilda online    | Quantidade de membros da guilda online (some sem guilda)  | `guilda`        | desligado  |

**Ordem:** abra **Ordem...** no menu de opções (ou `/farol ordem`) e use as setas [▲]/[▼] para mover cada item;
a barra muda na hora (em qualquer formato). Os itens escondidos aparecem em cinza, para você já deixar a posição
pronta. **Restaurar ordem padrão** (ou `/farol ordem padrao`) desfaz tudo.

Exemplo: `/farol hide ouro` esconde o ouro; `/farol show ouro` mostra de volta. Também funcionam
`mostrar`/`esconder` e os nomes em inglês (`zone`, `gold`, `bags`…). Suas escolhas ficam salvas.

**Tooltip:** passe o mouse no painel para ver todos os detalhes de uma vez — latência local/mundo,
subzona, cada peça danificada, XP exato e descansado, hora local *e* do servidor, amigos separados por
WoW / Battle.net, e mais.

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
Este addon só lê FPS, latência, coordenadas e ouro; se o jogo esconder algum valor, o painel mostra `--`
em vez de dar erro.

## Segurança

Segurança da informação é a primeira regra deste projeto:

- **Nada sai do seu computador.** O addon não usa `SendAddonMessage`, chat ou qualquer canal para enviar dados.
- **Nenhum código externo é executado.** Sem `loadstring`/`RunScript`; comandos aceitam só palavras fixas.
- **Sem automação.** Ele só lê e exibe informações; não joga por você (o que violaria as regras do servidor).
- **Dados salvos são validados.** `FarolDB` guarda apenas a posição, o estado do painel, o idioma, os itens visíveis seus alarmes (hora, tipo de relógio, ligado/desligado, um nome já limpo e o tempo da soneca) e os ajustes dos avisos. `FarolCharDB` (por personagem) guarda só links de item validados do seu histórico de saques, e é
  verificado ao carregar — um arquivo corrompido ou adulterado volta para os valores padrão.
- **Baixe só da fonte oficial** (este repositório). Addons são texto Lua: você pode ler todo o código em `Core.lua`.

Encontrou um problema de segurança? Relate de forma **privada** (Security → Report a vulnerability), como explicado
no [`SECURITY.md`](SECURITY.md). Nunca inclua dados pessoais, senhas ou informações da sua conta.

## Testes

O addon tem testes automáticos que rodam **fora do jogo**, em Lua 5.1 (a mesma versão do cliente do WoW),
usando um simulador simples da API do WoW (`tests/wow_mock.lua`). Eles cobrem a barra nos clientes WoW Forever
e 3.3.5a, os valores bloqueados (secret values), o menu de opções, os alarmes e a soneca, a janela de saques,
os arquivos `.toc`, e uma varredura que falha se o código algum dia usar APIs de automação, de mensagens ou de
execução de código, e um fuzzing com comandos, mensagens de chat e dados salvos aleatórios e maliciosos.

```
lua5.1 tests/run.lua
```

O GitHub Actions roda os testes a cada push e pull request (`.github/workflows/tests.yml`) e anexa a cada
execução um pacote `Farol-<versão>` pronto para instalar (aba Actions → a execução → *Artifacts*).

## Publicando no CurseForge

O texto da página está em [`assets/curseforge-description.md`](assets/curseforge-description.md) e o avatar do
projeto em [`assets/farol-icon-400.png`](assets/farol-icon-400.png). Envie um ZIP que tenha na raiz só a pasta
`Farol`, e selecione a versão do jogo do WoW Forever (1.60.1).

O ícone do jogo (`Farol/Media/Farol.tga`, que aparece na lista de AddOns) é uma arte original feita para este projeto.

## Conformidade com a política de addons da Blizzard

Este addon segue a [Política de Desenvolvimento de AddOns da Blizzard](https://us.forums.blizzard.com/en/wow/t/ui-add-on-development-policy/24534):

| Regra da política | Este addon |
|---|---|
| Deve ser gratuito | ✅ Gratuito, licença MIT — sem versão paga nem funções pagas |
| Código visível (sem ofuscação) | ✅ Lua simples e comentado em `Core.lua` |
| Sem propaganda ou pedidos de doação | ✅ Nenhum, nem no jogo nem neste repositório |
| Não pode prejudicar o desempenho do servidor | ✅ O único pedido ao servidor é a lista da guilda, no máximo 1 vez por minuto e só com o item Guilda ligado (o mesmo que a janela de Guilda do jogo faz) |
| Não pode automatizar o jogo | ✅ Usa só a API oficial de addons para **ler e mostrar** informações; nunca lança magias, move, seleciona alvos, compra, vende ou manda mensagens |
| Deve seguir os Termos de Uso / EULA | ✅ Sem programas externos, sem leitura de memória, sem injeção — não é um `.exe` |

**Não é afiliado à Blizzard Entertainment.** World of Warcraft e WoW Forever são marcas da Blizzard Entertainment, Inc.

### Como evitar banimento

- O que dá ban são **bots, programas de automação, "unlockers", ferramentas de memória/injeção e exploits** — não addons Lua comuns como este.
- Evite programas que apertam teclas por você (ex.: macros de AutoHotkey); eles podem gerar ban por "automação de terceiros".
- Nunca rode um `.exe` que diga ser addon. Addon de verdade é só arquivo de texto `.lua`/`.toc`/`.xml`.
- Baixe só deste repositório (ou das releases oficiais dele) e nunca digite sua senha fora do launcher oficial da Battle.net.

## Licença

MIT — use, modifique e distribua livremente. Veja `LICENSE`.
