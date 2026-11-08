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

## Itens da barra

Os seis primeiros vêm ligados; os outros começam desligados — marque no menu.

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
| Experiência (XP) | % de XP e bônus descansado (some no nível máximo)         | `xp`            | desligado  |
| Horário          | Hora local, ou do servidor (opção no menu)                | `hora`          | desligado  |
| Tempo de sessão  | Quanto tempo está jogando desde que entrou / `/reload`    | `tempo`         | desligado  |
| Amigos online    | Quantidade de amigos online (WoW + Battle.net)            | `amigos`        | desligado  |
| Guilda online    | Quantidade de membros da guilda online (some sem guilda)  | `guilda`        | desligado  |

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
- **Dados salvos são validados.** `FarolDB` guarda apenas a posição, o estado do painel, o idioma e os itens visíveis, e é
  verificado ao carregar — um arquivo corrompido ou adulterado volta para os valores padrão.
- **Baixe só da fonte oficial** (este repositório). Addons são texto Lua: você pode ler todo o código em `Core.lua`.

Encontrou um problema de segurança? Abra uma issue sem incluir dados pessoais, senhas ou informações da sua conta.

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
