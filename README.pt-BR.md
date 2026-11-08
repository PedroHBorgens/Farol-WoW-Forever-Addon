# WoW Forever Info

**Português** | [English](README.md)

Addon **gratuito e de código aberto** para WoW Forever: mostra um painel pequeno e arrastável com
**FPS · latência · coordenadas · ouro**.

## Instalação

1. Baixe este repositório (botão **Code → Download ZIP**).
2. Copie a pasta `WoWForeverInfo` para `World of Warcraft/_forever_/Interface/AddOns/`
   (a pasta final deve ser `_forever_/Interface/AddOns/WoWForeverInfo/Core.lua`).
   Outros clientes usam a própria pasta, como `_retail_` ou `_classic_era_`.
3. Na tela de personagens, clique em **AddOns** e ative **WoW Forever Info**.
   Se aparecer "desatualizado", marque **Carregar AddOns desatualizados**.

## Comandos

| Comando           | O que faz                                              |
|-------------------|--------------------------------------------------------|
| `/wfi`            | Mostra/oculta o painel |
| `/wfi lock`       | Trava/destrava o painel (arraste com o botão esquerdo) |
| `/wfi reset`      | Volta o painel para a posição padrão |
| `/wfi version`    | Mostra a versão do cliente e o número de **Interface** |
| `/wfi lang pt`    | Interface em português |
| `/wfi lang en`    | Interface em inglês |
| `/wfi lang auto`  | Segue o idioma do cliente (padrão) |

## Idioma

Por padrão o addon usa o idioma do seu cliente: **português** em clientes `ptBR`/`ptPT`
e **inglês** em todos os outros. Você pode trocar a qualquer momento com `/wfi lang pt` ou `/wfi lang en`;
a escolha fica salva.

## Descobrindo a versão do seu cliente

Rode `/wfi version` no jogo. O número de Interface que aparecer vai na primeira linha do `.toc`:

- `WoWForeverInfo_Mainline.toc` — **WoW Forever** (16001) e Retail. **É este o arquivo que o WoW Forever lê.**
- `WoWForeverInfo_Camelot.toc` — reserva específica do WoW Forever (16001)
- `WoWForeverInfo_Vanilla.toc` — Classic Era (11507)
- `WoWForeverInfo.toc` — padrão para qualquer outro cliente

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
- **Dados salvos são validados.** `WoWForeverInfoDB` guarda apenas a posição, o estado do painel e o idioma, e é
  verificado ao carregar — um arquivo corrompido ou adulterado volta para os valores padrão.
- **Baixe só da fonte oficial** (este repositório). Addons são texto Lua: você pode ler todo o código em `Core.lua`.

Encontrou um problema de segurança? Abra uma issue sem incluir dados pessoais, senhas ou informações da sua conta.

## Licença

MIT — use, modifique e distribua livremente. Veja `LICENSE`.
