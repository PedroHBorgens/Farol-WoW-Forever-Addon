# WoW Forever Info

Addon **gratuito e de código aberto** para WoW Forever: mostra um painel pequeno e arrastável com
**FPS · latência · coordenadas · ouro**.

## Instalação

1. Baixe este repositório (botão **Code → Download ZIP**).
2. Copie a pasta `WoWForeverInfo` para `World of Warcraft/Interface/AddOns/`
   (a pasta final deve ser `Interface/AddOns/WoWForeverInfo/Core.lua`).
3. Na tela de personagens, clique em **AddOns** e ative **WoW Forever Info**.
   Se aparecer "desatualizado", marque **Carregar AddOns desatualizados**.

## Comandos

| Comando       | O que faz                                              |
|---------------|--------------------------------------------------------|
| `/wf`         | Mostra/oculta o painel                                 |
| `/wf lock`    | Trava/destrava o painel (arraste com o botão esquerdo) |
| `/wf reset`   | Volta o painel para a posição padrão                   |
| `/wf version` | Mostra a versão do cliente e o número de **Interface** |

## Descobrindo a versão do seu cliente

Rode `/wf version` no jogo. O número de Interface que aparecer vai na primeira linha do `.toc`:

- `WoWForeverInfo.toc` — usado por clientes antigos (padrão **30300**, WotLK 3.3.5a)
- `WoWForeverInfo_Vanilla.toc` — Classic Era (11507)
- `WoWForeverInfo_Mainline.toc` — Retail (110205)

Clientes modernos escolhem o `.toc` com sufixo correspondente; clientes antigos leem só o primeiro.

## Segurança

Segurança da informação é a primeira regra deste projeto:

- **Nada sai do seu computador.** O addon não usa `SendAddonMessage`, chat ou qualquer canal para enviar dados.
- **Nenhum código externo é executado.** Sem `loadstring`/`RunScript`; comandos aceitam só palavras fixas.
- **Sem automação.** Ele só lê e exibe informações; não joga por você (o que violaria as regras do servidor).
- **Dados salvos são validados.** `WoWForeverInfoDB` guarda apenas a posição e o estado do painel, e é
  verificado ao carregar — um arquivo corrompido ou adulterado volta para os valores padrão.
- **Baixe só da fonte oficial** (este repositório). Addons são texto Lua: você pode ler todo o código em `Core.lua`.

Encontrou um problema de segurança? Abra uma issue sem incluir dados pessoais, senhas ou informações da sua conta.

## Licença

MIT — use, modifique e distribua livremente. Veja `LICENSE`.
