--[[
  Farol — Avisos de durabilidade e bolsas / Durability and bag warnings

  * Durabilidade: avisa quando a peça mais gasta fica abaixo do limite (padrão 20%).
  * Bolsas: avisa quando sobram poucos espaços livres (padrão 2 ou menos) e quando enchem.
  * Avisa UMA vez: só avisa de novo depois que a situação melhora (reparou / liberou espaço)
    e com intervalo mínimo de 5 minutos, para não repetir quando o número oscila.
  * Talentos: avisa quando há pontos de talento não gastos (e a cada ponto novo).
  * Graus de magia: avisa quando uma magia na barra de ações não é o grau mais alto que você conhece.
    O addon NÃO troca a magia por você (isso seria automação): só avisa.
  * Talentos e graus nunca avisam no meio do combate: esperam a luta acabar.
  * Cada aviso abre uma janelinha: "Silenciar" (só volta se a situação mudar) ou
    "Lembrar em N min" (2, 5, 10, 15 ou 30; avisa de novo se o problema continuar).
    Vários avisos ao mesmo tempo aparecem juntos, numa janela só, com "Silenciar todos" / "Lembrar todos".
    Um lembrete por tipo de aviso; lembretes acabam no /reload ou ao sair do jogo.
  * Lembretes de pausa e de beber água (desligados por padrão): o jogador escolhe o intervalo (15 a 240 min)
    e se podem aparecer em lutas, raides e masmorras (por padrão esperam). "Silenciar" vale até o fim da sessão.
  * Mensagem no centro da tela e no SEU chat (nada é enviado a ninguém) + som opcional.
  * Histórico dos 10 últimos avisos (salvo por personagem): botão ao lado da barra com contador
    de avisos novos, atalho de teclado (Esc > Teclas de atalho > AddOns > Farol) e /farol historico.
]]

local _, ns = ...

local COOLDOWN = 5 * 60
local REMIND_CHOICES = { 2, 5, 10, 15, 30 } -- minutos do "Lembrar em"
local BREAK_MIN, BREAK_MAX = 15, 240        -- intervalo dos lembretes de pausa e de água (minutos)
local BREAK_KEYS = { "pause", "water" }
local HISTORY_MAX = 10
local HISTORY_ICON = "Interface\\Icons\\INV_Misc_Note_01"
local DURAB_MIN, DURAB_MAX = 5, 50
local BAGS_MIN, BAGS_MAX = 0, 10
local DEFAULTS = {
    durab = true, durabPct = 20, bags = true, bagSlots = 2, sound = true, talents = true, ranks = true,
    prof = true,                                             -- profissão no máximo do treinamento
    restFull = false,                                        -- outro personagem com descanso cheio (ao entrar)
    ammo = false, ammoYellow = 400, ammoRed = 200,           -- munição: aviso (desligado) e limites das cores
    reag = false, reagYellow = 10, reagRed = 5,              -- reagentes: aviso (desligado) e limites das cores
    remindMin = 30,                                          -- tempo padrão do "Lembrar em"
    pause = false, pauseMin = 120, pauseAnywhere = false,    -- lembrete de pausa (desligado por padrão)
    water = false, waterMin = 45, waterAnywhere = false,     -- lembrete de beber água (desligado por padrão)
    tasks = false,                                           -- tarefas diárias pendentes 1 h antes do reset
    goals = false,                                           -- meta de ouro/nível alcançada
    questFull = false, questMin = 19,                        -- diário de missões quase cheio (a partir de N)
    questReady = false,                                      -- missões prontas ao entrar numa cidade/estalagem
    hearthReady = false,                                     -- Pedra de Regresso pronta (fim da recarga)
    questValue = false,                                      -- XP e ouro das missões prontas (barra e tooltip)
    questLevel = false,                                      -- avisar quando entregar as prontas sobe de nível
    popupW = 0,                                              -- largura da janela de avisos (0 = padrão; alça ◢)
}
local QUEST_MIN, QUEST_MAX = 1, 100
local MAX_ACTION_SLOT = 180 -- barras de ação (clientes modernos têm até 180 espaços)
local RANK_SCAN_INTERVAL = 5 -- segundos entre varreduras quando algo mudou

local Warnings = {}
ns.Warnings = Warnings

---------------------------------------------------------------------------
-- Textos / Strings
---------------------------------------------------------------------------

local STRINGS = {
    pt = {
        warn_title      = "Avisos",
        warn_durab      = "Durabilidade baixa: %d%% — hora de reparar!",
        warn_bags       = "Bolsas quase cheias: %d espaços livres.",
        warn_bags_1     = "Bolsas quase cheias: %d espaço livre.",
        warn_bags_full  = "Bolsas cheias!",
        warn_opt_durab  = "Durabilidade abaixo de",
        warn_opt_bags   = "Bolsas com até",
        warn_unit_pct   = "%",
        warn_unit_slots = "espaços livres",
        warn_opt_sound  = "Tocar som",
        warn_opt_talents = "Pontos de talento não gastos",
        warn_opt_ranks  = "Magias de grau antigo nas barras",
        warn_talents    = "Você tem %d pontos de talento para gastar.",
        warn_talents_1  = "Você tem %d ponto de talento para gastar.",
        warn_ranks      = "Magia de grau antigo na barra: %s.",
        warn_rank_item  = "%s (Grau %d) — você já tem o Grau %d",
        warn_more       = " e mais %d",
        warn_name_talents = "talentos",
        warn_name_ranks = "graus de magia",
        warn_status_talents = "talentos: %d ponto(s) não gasto(s) (função: %s).",
        warn_status_notal = "talentos: não foi possível ler os pontos neste cliente.",
        warn_status_ranks = "magias de grau antigo na barra: %d.",
        warn_popup_title = "Aviso",
        warn_silence_btn = "Silenciar",
        warn_remind_btn = "Lembrar em %d min",
        warn_minutes    = "%d min",
        warn_group_title = "Avisos (%d)",
        warn_silence_all = "Silenciar todos",
        warn_tip_title  = "Aviso do Farol",
        warn_tip_where  = "Desligar ou ajustar: Menu > Avisos.",
        warn_grip_tip   = "Arraste para mudar a largura da janela (fica salva).",
        warn_grip_reset = "Clique direito: largura padrão.",
        warn_remind_all = "Lembrar todos em %d min",
        warn_silenced   = "aviso silenciado: só volta se a situação mudar.",
        warn_silenced_session = "lembrete silenciado até o fim da sessão.",
        warn_silenced_n = "%d avisos silenciados.",
        warn_silenced_n_1 = "%d aviso silenciado.",
        warn_reminded   = "Ok — volto a avisar às %s se continuar.",
        warn_reminded_n = "Ok — volto a avisar %d avisos às %s, se ainda for preciso.",
        warn_reminded_n_1 = "Ok — volto a avisar %d aviso às %s, se ainda for preciso.",
        warn_chat_hint  = " — /farol aviso silenciar ou /farol aviso lembrar [minutos]",
        warn_pause      = "Você está jogando há %s — que tal uma pausa?",
        warn_prof       = "%s no máximo do treinamento — procure um instrutor para continuar subindo.",
        warn_bags_junk  = " Há %d espaços com lixo (%s) para vender.",
        warn_bags_junk_1 = " Há %d espaço com lixo (%s) para vender.",
        warn_restFull   = "Descanso cheio (150%%): %s — bom momento para jogar com eles.",
        warn_supply     = "%s acabando — reabasteça antes de sair da cidade.",
        supply_status   = "munição/reagentes: %s.",
        supply_status_none = "munição/reagentes: nada para a sua classe (ou ainda não encontrado nas bolsas).",
        warn_opt_ammo   = "Munição acabando",
        warn_opt_reag   = "Reagentes acabando",
        warn_yellow     = "atenção:",
        warn_red        = "crítico:",
        warn_name_ammo  = "munição",
        warn_name_reag  = "reagentes",
        warn_set_supply = "%s: atenção abaixo de %d, crítico abaixo de %d.",
        warn_bad_supply = "valores inválidos: use atenção e crítico de 0 a %d, com o crítico menor que o de atenção.",
        warn_opt_restFull = "Outro personagem com descanso cheio",
        warn_name_restFull = "descanso cheio",
        warn_opt_prof   = "Profissão no limite do treinamento",
        warn_name_prof  = "profissões",
        warn_water      = "Hora de beber água!",
        warn_opt_pause  = "Pausa a cada",
        warn_opt_water  = "Água a cada",
        warn_unit_min   = "min",
        warn_opt_anywhere = "Também em lutas e masmorras",
        warn_opt_remind = "\"Lembrar em\" padrão:",
        warn_name_pause = "pausa",
        warn_name_water = "beber água",
        warn_name_tasks = "tarefas diárias pendentes",
        warn_opt_tasks = "Tarefas diárias pendentes (1 h antes)",
        warn_opt_goals = "Meta alcançada (ouro, nível ou farm)",
        warn_opt_questFull = "Diário a partir de",
        warn_unit_quests = "missões",
        warn_name_questFull = "diário de missões quase cheio",
        warn_questFull = "Diário de missões quase cheio: %d/%d.",
        warn_questFull_full = "Diário de missões cheio: %d/%d!",
        warn_opt_questReady = "Missões prontas (cidade/estalagem)",
        warn_opt_hearthReady = "Pedra de Regresso pronta",
        warn_opt_questValue = "XP e ouro das prontas",
        warn_name_questValue = "XP e ouro das missões prontas",
        warn_opt_questLevel = "Prontas que sobem de nível",
        warn_name_questLevel = "entregar as prontas sobe de nível",
        warn_questLevel = "Entregue as %d missões prontas: você sobe para o nível %d.",
        warn_questLevel_1 = "Entregue a %d missão pronta: você sobe para o nível %d.",
        warn_desc_questValue = "mostra na barra e no tooltip do item Missões quanto XP e ouro as prontas vão dar e se entregar todas sobe você de nível.",
        warn_desc_questLevel = "avisa uma vez por nível quando entregar as missões prontas já faz você subir de nível.",
        warn_name_hearthReady = "Pedra de Regresso pronta",
        warn_hearthReady = "Pedra de Regresso pronta (%s).",
        warn_hearthReady_noplace = "Pedra de Regresso pronta.",
        warn_name_questReady = "missões prontas para entregar",
        warn_questReady = "Você tem %d missões prontas para entregar.",
        warn_questReady_one = "Você tem 1 missão pronta para entregar.",
        warn_set_questMin = "aviso do diário de missões: a partir de %d missões.",
        warn_bad_questMin = "valor inválido: use de 1 a 100 missões.",
        warn_name_goals = "meta alcançada",
        warn_goals     = "meta alcançada: %s!",
        warn_sec_gear  = "Equipamento e bolsas",
        warn_sec_char  = "Personagem",
        warn_sec_breaks = "Pausas",
        warn_sec_quests = "Missões e viagem",
        warn_recommended = "Só os recomendados",
        warn_all_off   = "Desligar todos",
        warn_top_hint  = "Só avisa o que estiver marcado.",
        warn_set_recommended = "avisos: só os recomendados ligados (durabilidade, bolsas, talentos, graus e profissões).",
        warn_set_all_off = "avisos: todos desligados (ligue de novo na aba Avisos ou com \"Só os recomendados\").",
        warn_desc_durab = "avisa quando a peça mais gasta do equipamento fica abaixo da porcentagem escolhida.",
        warn_desc_bags  = "avisa quando sobram poucos espaços livres nas bolsas (e quanto lixo dá para vender).",
        warn_desc_ammo  = "avisa quando a munição fica abaixo do limite crítico; os limites de atenção e crítico também colorem a barra.",
        warn_desc_reag  = "avisa quando os reagentes da sua classe ficam abaixo do limite crítico.",
        warn_desc_talents = "avisa quando você tem pontos de talento para gastar.",
        warn_desc_ranks = "avisa quando uma magia de grau antigo está nas suas barras de ação e você já tem um grau melhor.",
        warn_desc_prof  = "avisa quando uma profissão chega ao limite do treinamento: hora de procurar um instrutor.",
        warn_desc_restFull = "ao entrar, avisa se outro personagem seu já está com o descanso cheio (estimativa).",
        warn_desc_goals = "avisa uma vez quando uma meta de ouro, de nível ou de farm é alcançada.",
        warn_desc_questFull = "avisa quando o diário de missões chega ao número escolhido (e de novo quando enche).",
        warn_desc_questReady = "ao entrar numa cidade ou estalagem, avisa se há missões prontas para entregar (no máx. a cada 5 min).",
        warn_desc_hearthReady = "avisa uma vez quando a recarga da Pedra de Regresso termina; espera o combate e a masmorra acabarem.",
        warn_desc_tasks = "1 hora antes do reset diário, avisa se ainda falta alguma tarefa diária.",
        warn_desc_pause = "lembra de fazer uma pausa a cada intervalo escolhido.",
        warn_desc_water = "lembra de beber água a cada intervalo escolhido.",
        warn_desc_anywhere = "sem esta opção, o lembrete espera a luta acabar e você sair da masmorra ou raide.",
        warn_desc_sound = "toca um som curto junto com cada aviso.",
        warn_sec_how   = "Como avisar",
        warn_tasks    = "faltam %d tarefas diárias e o reset diário é em %s.",
        warn_task_one = "falta 1 tarefa diária e o reset diário é em %s.",
        warn_set_break  = "lembrete de %s: a cada %d min.",
        warn_set_anywhere = "lembrete de %s: aparece também em lutas, raides e masmorras.",
        warn_set_wait   = "lembrete de %s: espera a luta acabar e você sair da masmorra/raide.",
        warn_set_remind = "\"Lembrar em\" agora vem com %d min.",
        warn_bad_break  = "valor inválido: use de 15 a 240 minutos.",
        warn_bad_remind = "valor inválido: use 2, 5, 10, 15 ou 30 minutos.",
        warn_none       = "nenhum aviso aberto.",
        hist_title      = "Últimos avisos",
        hist_sum        = "Resumo", hist_sum_sub = "deste personagem · os 10 mais recentes",
        hist_stat_saved = "Guardados", hist_stat_today = "Hoje", hist_stat_last = "Último",
        hist_ago        = "há %s", hist_list_sub = "mais novos primeiro", hist_today = "HOJE", hist_yesterday = "ONTEM",
        hist_empty      = "Nenhum aviso ainda.",
        hist_clear      = "Limpar",
        hist_cleared    = "histórico de avisos apagado.",
        hist_button_tip = "Últimos avisos",
        hist_button_new = "%d novos — clique para ver",
        hist_button_new_1 = "%d novo — clique para ver",
        hist_clear_ask  = "Apagar %d avisos?",
        hist_clear_ask_1 = "Apagar %d aviso?",
        hist_button_none = "Clique para ver",
        opt_history     = "Histórico...",
        help_history    = "  /farol historico     - ver os 10 últimos avisos (também pelo botão ao lado da barra ou por atalho de teclado)",
        warn_opt_test   = "Testar aviso",
        warn_hint       = "Tudo é opcional: só avisa o que você deixar marcado. Cada aviso aparece uma vez e só volta se a situação melhorar e piorar de novo (no mínimo 5 min depois).",
        warn_hint_break = "Pausa e água vêm desligadas; sem a opção acima, esperam a luta e a masmorra acabarem.",
        warn_set_durab  = "aviso de durabilidade: abaixo de %d%%.",
        warn_set_bags   = "aviso de bolsas: até %d espaços livres.",
        warn_set_bags_1 = "aviso de bolsas: até %d espaço livre.",
        warn_on         = "aviso ligado: %s",
        warn_off        = "aviso desligado: %s",
        warn_name_durab = "durabilidade",
        warn_name_bags  = "bolsas",
        warn_name_sound = "som",
        warn_bad_durab  = "valor inválido: use de 5 a 50 (%).",
        warn_bad_bags   = "valor inválido: use de 0 a 10 espaços.",
        warn_usage      = "uso: /farol aviso durab N || bolsas N || pausa N || agua N || missoes N || durab/bolsas/talentos/graus/profissoes/descansado/municao/reagentes/pausa/agua/missoes/prontas/regresso/som on||off || municao A V || reagentes A V || pausa/agua lutas on||off || recomendados || nenhum || lembrar N || status || silenciar",
        opt_warnings    = "Avisos...",
        help_warn       = "  /farol aviso         - abrir o menu na aba Avisos (durabilidade, bolsas, talentos, profissões, pausa, água...)",
    },
    en = {
        warn_title      = "Warnings",
        warn_durab      = "Low durability: %d%% — time to repair!",
        warn_bags       = "Bags almost full: %d free slots.",
        warn_bags_1     = "Bags almost full: %d free slot.",
        warn_bags_full  = "Bags full!",
        warn_opt_durab  = "Durability below",
        warn_opt_bags   = "Bags with only",
        warn_unit_pct   = "%",
        warn_unit_slots = "free slots",
        warn_opt_sound  = "Play a sound",
        warn_opt_talents = "Unspent talent points",
        warn_opt_ranks  = "Lower-rank spells on your bars",
        warn_talents    = "You have %d unspent talent points.",
        warn_talents_1  = "You have %d unspent talent point.",
        warn_ranks      = "Lower-rank spell on your bars: %s.",
        warn_rank_item  = "%s (Rank %d) — you already know Rank %d",
        warn_more       = " and %d more",
        warn_name_talents = "talents",
        warn_name_ranks = "spell ranks",
        warn_status_talents = "talents: %d unspent point(s) (function: %s).",
        warn_status_notal = "talents: unable to read talent points on this client.",
        warn_status_ranks = "lower-rank spells on your bars: %d.",
        warn_popup_title = "Warning",
        warn_silence_btn = "Silence",
        warn_remind_btn = "Remind in %d min",
        warn_minutes    = "%d min",
        warn_group_title = "Warnings (%d)",
        warn_silence_all = "Silence all",
        warn_tip_title  = "Farol warning",
        warn_tip_where  = "Turn off or adjust: Menu > Warnings.",
        warn_grip_tip   = "Drag to change the window width (saved).",
        warn_grip_reset = "Right-click: default width.",
        warn_remind_all = "Remind all in %d min",
        warn_silenced   = "warning silenced: it only comes back if the situation changes.",
        warn_silenced_session = "reminder silenced until the end of the session.",
        warn_silenced_n = "%d warnings silenced.",
        warn_silenced_n_1 = "%d warning silenced.",
        warn_reminded   = "Ok — you'll be warned again at %s if it's still a problem.",
        warn_reminded_n = "Ok — %d warnings will come back at %s, if still needed.",
        warn_reminded_n_1 = "Ok — %d warning will come back at %s, if still needed.",
        warn_chat_hint  = " — /farol warn silence or /farol warn remind [minutes]",
        warn_pause      = "You've been playing for %s — time for a break?",
        warn_prof       = "%s at the training limit — find a trainer to keep leveling.",
        warn_bags_junk  = " %d slots hold junk (%s) you can sell.",
        warn_bags_junk_1 = " %d slot holds junk (%s) you can sell.",
        warn_restFull   = "Rested XP full (150%%): %s — a good time to play them.",
        warn_supply     = "%s running low — restock before leaving town.",
        supply_status   = "ammo/reagents: %s.",
        supply_status_none = "ammo/reagents: nothing for your class (or not found in your bags yet).",
        warn_opt_ammo   = "Ammo running low",
        warn_opt_reag   = "Reagents running low",
        warn_yellow     = "warning:",
        warn_red        = "critical:",
        warn_name_ammo  = "ammo",
        warn_name_reag  = "reagents",
        warn_set_supply = "%s: warning below %d, critical below %d.",
        warn_bad_supply = "invalid values: use warning and critical from 0 to %d, with critical lower than warning.",
        warn_opt_restFull = "Another character fully rested",
        warn_name_restFull = "full rested XP",
        warn_opt_prof   = "Profession at its training limit",
        warn_name_prof  = "professions",
        warn_water      = "Time to drink some water!",
        warn_opt_pause  = "Break every",
        warn_opt_water  = "Drink water every",
        warn_unit_min   = "min",
        warn_opt_anywhere = "Also in fights and dungeons",
        warn_opt_remind = "\"Remind in\" default:",
        warn_name_pause = "break",
        warn_name_water = "drink water",
        warn_name_tasks = "daily tasks left",
        warn_opt_tasks = "Daily tasks left (1 h before)",
        warn_opt_goals = "Goal reached (gold, level or farm)",
        warn_opt_questFull = "Quest log from",
        warn_unit_quests = "quests",
        warn_name_questFull = "quest log almost full",
        warn_questFull = "Quest log almost full: %d/%d.",
        warn_questFull_full = "Quest log full: %d/%d!",
        warn_opt_questReady = "Quests ready in a city or inn",
        warn_opt_hearthReady = "Hearthstone ready",
        warn_opt_questValue = "XP and gold of ready ones",
        warn_name_questValue = "XP and gold of ready quests",
        warn_opt_questLevel = "Ready ones level you up",
        warn_name_questLevel = "turning in the ready quests levels you up",
        warn_questLevel = "Turn in the %d ready quests: you reach level %d.",
        warn_questLevel_1 = "Turn in the %d ready quest: you reach level %d.",
        warn_desc_questValue = "shows on the bar and in the Quests tooltip how much XP and gold the ready quests give and whether turning them all in levels you up.",
        warn_desc_questLevel = "warns once per level when turning in your ready quests is already enough to level up.",
        warn_name_hearthReady = "Hearthstone ready",
        warn_hearthReady = "Hearthstone ready (%s).",
        warn_hearthReady_noplace = "Hearthstone ready.",
        warn_name_questReady = "quests ready to turn in",
        warn_questReady = "You have %d quests ready to turn in.",
        warn_questReady_one = "You have 1 quest ready to turn in.",
        warn_set_questMin = "quest log warning: at %d quests or more.",
        warn_bad_questMin = "invalid value: use 1 to 100 quests.",
        warn_name_goals = "goal reached",
        warn_goals     = "goal reached: %s!",
        warn_sec_gear  = "Gear and bags",
        warn_sec_char  = "Character",
        warn_sec_breaks = "Breaks",
        warn_sec_quests = "Quests and travel",
        warn_recommended = "Recommended only",
        warn_all_off   = "Turn all off",
        warn_top_hint  = "Only ticked warnings are active.",
        warn_set_recommended = "warnings: only the recommended ones are on (durability, bags, talents, ranks and professions).",
        warn_set_all_off = "warnings: all off (turn them on again in the Warnings tab or with \"Recommended only\").",
        warn_desc_durab = "warns when your most worn piece of gear drops below the chosen percentage.",
        warn_desc_bags  = "warns when only a few free bag slots are left (and how much junk you can sell).",
        warn_desc_ammo  = "warns when ammo drops below the critical limit; the warning and critical limits also color the bar.",
        warn_desc_reag  = "warns when your class reagents drop below the critical limit.",
        warn_desc_talents = "warns when you have talent points to spend.",
        warn_desc_ranks = "warns when a lower-rank spell is on your action bars and you already know a better rank.",
        warn_desc_prof  = "warns when a profession reaches its training limit: time to find a trainer.",
        warn_desc_restFull = "at login, warns if another of your characters already has full rested XP (estimate).",
        warn_desc_goals = "warns once when a gold, level or farm goal is reached.",
        warn_desc_questFull = "warns when your quest log reaches the chosen number (and again when it is full).",
        warn_desc_questReady = "when you enter a city or inn, warns if there are quests ready to turn in (at most every 5 min).",
        warn_desc_hearthReady = "warns once when your Hearthstone cooldown ends; waits for combat and dungeons to end.",
        warn_desc_tasks = "1 hour before the daily reset, warns if a daily task is still left.",
        warn_desc_pause = "reminds you to take a break at the chosen interval.",
        warn_desc_water = "reminds you to drink some water at the chosen interval.",
        warn_desc_anywhere = "without this option, the reminder waits for the fight to end and for you to leave the dungeon or raid.",
        warn_desc_sound = "plays a short sound with each warning.",
        warn_sec_how   = "How to warn",
        warn_tasks    = "%d daily tasks left and the daily reset is in %s.",
        warn_task_one = "1 daily task left and the daily reset is in %s.",
        warn_set_break  = "%s reminder: every %d min.",
        warn_set_anywhere = "%s reminder: also shown during fights, raids and dungeons.",
        warn_set_wait   = "%s reminder: waits until the fight ends and you leave the dungeon/raid.",
        warn_set_remind = "\"Remind in\" now starts at %d min.",
        warn_bad_break  = "invalid value: use 15 to 240 minutes.",
        warn_bad_remind = "invalid value: use 2, 5, 10, 15 or 30 minutes.",
        warn_none       = "no open warning.",
        hist_title      = "Recent warnings",
        hist_sum        = "Summary", hist_sum_sub = "this character · the 10 most recent",
        hist_stat_saved = "Saved", hist_stat_today = "Today", hist_stat_last = "Latest",
        hist_ago        = "%s ago", hist_list_sub = "newest first", hist_today = "TODAY", hist_yesterday = "YESTERDAY",
        hist_empty      = "No warnings yet.",
        hist_clear      = "Clear",
        hist_cleared    = "warning history cleared.",
        hist_button_tip = "Recent warnings",
        hist_button_new = "%d new — click to view",
        hist_button_new_1 = "%d new — click to view",
        hist_clear_ask  = "Delete %d warnings?",
        hist_clear_ask_1 = "Delete %d warning?",
        hist_button_none = "Click to view",
        opt_history     = "History...",
        help_history    = "  /farol history       - view the last 10 warnings (also via the button next to the bar or a key binding)",
        warn_opt_test   = "Test warning",
        warn_hint       = "Everything is optional: you only get the warnings you leave ticked. Each warning shows once and only comes back if things improve and get worse again (at least 5 min later).",
        warn_hint_break = "Break and water start off; without the option above they wait for fights and dungeons to end.",
        warn_set_durab  = "durability warning: below %d%%.",
        warn_set_bags   = "bag warning: %d free slots or fewer.",
        warn_set_bags_1 = "bag warning: %d free slot or fewer.",
        warn_on         = "warning on: %s",
        warn_off        = "warning off: %s",
        warn_name_durab = "durability",
        warn_name_bags  = "bags",
        warn_name_sound = "sound",
        warn_bad_durab  = "invalid value: use 5 to 50 (%).",
        warn_bad_bags   = "invalid value: use 0 to 10 slots.",
        warn_usage      = "usage: /farol warn durab N || bags N || break N || water N || quests N || durab/bags/talents/ranks/professions/rested/ammo/reagents/break/water/quests/ready/hearth/sound on||off || ammo Y R || reagents Y R || break/water fights on||off || recommended || none || remind N || status || silence",
        opt_warnings    = "Warnings...",
        help_warn       = "  /farol warn          - open the menu on the Warnings tab (durability, bags, talents, professions, break, water...)",
    },
}
for lang, entries in pairs(STRINGS) do
    for key, value in pairs(entries) do
        ns.STRINGS[lang][key] = value
    end
end

local function T(key) return ns.T(key) end
local function Print(msg) ns.Print(msg) end
local function Settings() return ns.GetDB().warnings end

---------------------------------------------------------------------------
-- Validação
---------------------------------------------------------------------------

local function InRange(value, low, high)
    value = tonumber(value)
    if value and value == math.floor(value) and value >= low and value <= high then return value end
    return nil
end

function Warnings.Sanitize(saved)
    local clean = {}
    if type(saved) ~= "table" then saved = {} end
    for _, key in ipairs({ "durab", "bags", "sound", "talents", "ranks", "prof", "restFull", "ammo", "reag", "pause", "pauseAnywhere",
                           "water", "waterAnywhere", "tasks", "goals", "questFull", "questReady", "hearthReady", "questValue", "questLevel" }) do
        if type(saved[key]) == "boolean" then clean[key] = saved[key] else clean[key] = DEFAULTS[key] end
    end
    clean.durabPct = InRange(saved.durabPct, DURAB_MIN, DURAB_MAX) or DEFAULTS.durabPct
    clean.bagSlots = InRange(saved.bagSlots, BAGS_MIN, BAGS_MAX) or DEFAULTS.bagSlots
    clean.pauseMin = InRange(saved.pauseMin, BREAK_MIN, BREAK_MAX) or DEFAULTS.pauseMin
    clean.waterMin = InRange(saved.waterMin, BREAK_MIN, BREAK_MAX) or DEFAULTS.waterMin
    clean.questMin = InRange(saved.questMin, QUEST_MIN, QUEST_MAX) or DEFAULTS.questMin
    -- Limites de munição (0 a 5000) e reagentes (0 a 200): vermelho menor que amarelo (0 no amarelo = sem amarelo).
    for _, pair in ipairs({ { "ammo", 5000 }, { "reag", 200 } }) do
        local y = InRange(saved[pair[1] .. "Yellow"], 0, pair[2])
        local r = InRange(saved[pair[1] .. "Red"], 0, pair[2])
        if not y or not r or (y > 0 and r >= y) then
            y, r = DEFAULTS[pair[1] .. "Yellow"], DEFAULTS[pair[1] .. "Red"]
        end
        clean[pair[1] .. "Yellow"], clean[pair[1] .. "Red"] = y, r
    end
    -- Largura escolhida com a alça da janela de avisos: 0 (padrão) ou de POPUP_MIN a POPUP_MAX pixels.
    clean.popupW = type(saved.popupW) == "number" and InRange(saved.popupW, 0, 1400) or 0
    if clean.popupW > 0 and clean.popupW < 520 then clean.popupW = 0 end
    clean.remindMin = DEFAULTS.remindMin
    for _, minutes in ipairs(REMIND_CHOICES) do
        if saved.remindMin == minutes then clean.remindMin = minutes end
    end
    return clean
end

---------------------------------------------------------------------------
-- Disparo
---------------------------------------------------------------------------

-- Estado de cada aviso: armed = pode avisar; lastAt = quando avisou (GetTime).
local state = {
    durab = { armed = true, lastAt = nil },
    bags = { armed = true, lastAt = nil, full = false },
    talents = { warnedCount = 0 },      -- quantos pontos já foram avisados
    ranks = { warned = {}, dirty = true, lastScan = nil }, -- magias já avisadas; "dirty" = algo mudou
    prof = { warned = {} },                             -- limites já avisados ("Mineração@150")
    restFull = { checked = false },                     -- descanso cheio: confere uma vez por sessão
    supply = { warned = {} },                           -- munição/reagentes já avisados (por grupo)
    pause = { nextAt = nil, silenced = false },         -- lembretes por tempo: próxima vez (GetTime)
    water = { nextAt = nil, silenced = false },
    tasks = { cycle = nil },                            -- reset diário já avisado (tarefas pendentes)
    goals = {},                                         -- metas: o "já avisada" fica salvo (FarolCharDB.goals)
    questFull = { armed = true, lastAt = nil, full = false }, -- diário quase cheio (como as bolsas)
    questReady = { wasResting = nil, lastAt = nil },    -- prontas: ao passar a descansar (cidade/estalagem)
    questLevel = { warned = nil },                      -- nível já avisado (entregar as prontas sobe de nível)
    hearthReady = { cooling = false },                  -- viu a pedra em recarga: avisa quando ficar pronta
}

local function PlayWarningSound()
    -- Som da "checagem de prontidão": diferente do som do alarme.
    if SOUNDKIT and SOUNDKIT.READY_CHECK then
        PlaySound(SOUNDKIT.READY_CHECK, "Master")
    elseif PlaySound then
        PlaySound("ReadyCheck", "Master")
    end
end

---------------------------------------------------------------------------
-- Janelinha de aviso: "Silenciar" ou "Lembrar em N min"
-- Um aviso: texto + botões. Vários: uma janela só, com uma linha por aviso e "Silenciar todos" /
-- "Lembrar todos". Cada linha tem o seu próprio tempo de "Lembrar" (menu suspenso).
---------------------------------------------------------------------------

-- Avisos esperando resposta: { key = "durab"|"bags"|"talents"|"ranks"|"pause"|"water"|"test", text, minutes }
local queue = {}
local popup
local groupMinutes          -- tempo escolhido no "Lembrar todos" (nil = padrão das configurações)
local Render                -- definida abaixo

local function DefaultMinutes()
    local settings = ns.GetDB() and Settings()
    return settings and settings.remindMin or DEFAULTS.remindMin
end

-- Itens do menu de tempo: 2, 5, 10, 15, 30 min. get/set leem e gravam o tempo escolhido.
local function MinuteItems(get, set)
    return function()
        local items = {}
        for _, minutes in ipairs(REMIND_CHOICES) do
            items[#items + 1] = {
                text = string.format(T("warn_minutes"), minutes),
                checked = get() == minutes,
                onClick = function() set(minutes); Render() end,
            }
        end
        return items
    end
end

local function NewButton(parent, name, width, onClick)
    local button = CreateFrame("Button", name, parent, "UIPanelButtonTemplate")
    button:SetSize(width, 22)
    button:SetScript("OnClick", onClick)
    return button
end

local ROW_HEIGHT = 28
local GROUP_WIDTH, SINGLE_WIDTH = 640, 400   -- larguras padrão (a alça ◢ muda; Settings().popupW)
local POPUP_MIN, POPUP_MAX = 520, 1400        -- faixa da largura escolhida (modo "vários avisos")
local BUTTONS_WIDTH = 296                     -- Silenciar + Lembrar + ▾ à direita de cada aviso
local MAX_LINES, LINE_HEIGHT = 3, 13          -- cada aviso usa até 3 linhas (nada de "…")

-- Larguras atuais: a escolhida pelo jogador (ou a padrão); a de um aviso só acompanha.
local function GroupWidth()
    local w = Settings().popupW
    if type(w) ~= "number" or w < POPUP_MIN then return GROUP_WIDTH end
    return math.min(w, POPUP_MAX)
end
local function SingleWidth() return math.max(SINGLE_WIDTH, math.min(GroupWidth() - 240, POPUP_MAX - 240)) end

-- Altura do texto já quebrado em linhas (no máx. MAX_LINES). Cliente sem GetStringHeight: estimativa.
local function TextHeight(fs, text, width)
    local ok, h = pcall(function() return fs.GetStringHeight and fs:GetStringHeight() end)
    if not ok or type(h) ~= "number" or h ~= h or h <= 0 then
        local lines = math.ceil(#(text or "") * 6.2 / math.max(width, 50))
        h = math.max(1, lines) * LINE_HEIGHT
    end
    return math.max(LINE_HEIGHT, math.min(h, MAX_LINES * LINE_HEIGHT + 2))
end

local function WrapText(fs, width)
    fs:SetWidth(width)
    if fs.SetWordWrap then fs:SetWordWrap(true) end
    if fs.SetMaxLines then pcall(fs.SetMaxLines, fs, MAX_LINES) end
    fs:SetJustifyV("TOP")
end

-- Tooltip com o aviso inteiro, a explicação daquele aviso e onde ajustar.
local function ShowTip(owner, entry)
    if not entry or not GameTooltip then return end
    GameTooltip:SetOwner(owner, "ANCHOR_TOP")
    GameTooltip:AddLine(T("warn_tip_title"), 1, 0.82, 0)
    GameTooltip:AddLine(entry.text, 1, 1, 1, true)
    local descKey = "warn_desc_" .. tostring(entry.key)
    local desc = T(descKey)
    if desc ~= descKey then GameTooltip:AddLine(desc, 0.8, 0.8, 0.8, true) end
    GameTooltip:AddLine(T("warn_tip_where"), 0.6, 0.6, 0.6, true)
    GameTooltip:Show()
end
Warnings.ShowTip = ShowTip

local function CreateRow(frame, index)
    local row = CreateFrame("Frame", "FarolWarnRow" .. index .. "Line", frame)
    row:SetSize(GROUP_WIDTH - 40, ROW_HEIGHT - 4)
    row:EnableMouse(true)
    row:SetScript("OnEnter", function(self) ShowTip(self, self.entry) end)
    row:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.text:SetPoint("TOPLEFT", 0, -4)
    row.text:SetJustifyH("LEFT")
    WrapText(row.text, GROUP_WIDTH - 40 - BUTTONS_WIDTH - 10)
    local prefix = "FarolWarnRow" .. index
    row.time = ns.CreateDropdown(row, prefix .. "Time", 34, MinuteItems(
        function() return row.entry and row.entry.minutes end,
        function(minutes) if row.entry then row.entry.minutes = minutes end end))
    row.time:SetPoint("TOPRIGHT", 0, 0)
    row.remind = NewButton(row, prefix .. "Remind", 144, function()
        if row.entry then Warnings.Respond(true, row.entry.key, row.entry.minutes) end
    end)
    row.remind:SetPoint("RIGHT", row.time, "LEFT", -2, 0)
    row.silence = NewButton(row, prefix .. "Silence", 100, function()
        if row.entry then Warnings.Respond(false, row.entry.key) end
    end)
    row.silence:SetPoint("RIGHT", row.remind, "LEFT", -6, 0)
    row:Hide()
    return row
end

-- Alça ◢: arrastar muda a largura (salva em Settings().popupW); clique direito volta ao padrão.
local function CreateGrip(frame)
    pcall(frame.SetResizable, frame, true)
    if frame.SetResizeBounds then pcall(frame.SetResizeBounds, frame, SINGLE_WIDTH, 100, POPUP_MAX, 900)
    elseif frame.SetMinResize then pcall(frame.SetMinResize, frame, SINGLE_WIDTH, 100) end
    local grip = CreateFrame("Button", "FarolWarnPopupGrip", frame)
    grip:SetSize(16, 16)
    grip:SetPoint("BOTTOMRIGHT", -8, 8)
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    grip:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" then frame.farolSizing = true; pcall(frame.StartSizing, frame, "RIGHT") end
    end)
    grip:SetScript("OnMouseUp", function(_, button)
        if button == "RightButton" then Warnings.SetPopupWidth(0) return end
        if not frame.farolSizing then return end
        frame.farolSizing = nil
        pcall(frame.StopMovingOrSizing, frame)
        local ok, w = pcall(frame.GetWidth, frame)
        if ok and type(w) == "number" and w == w then
            if not frame.farolGroup then w = w + 240 end -- um aviso só: a largura salva é a do modo "vários"
            Warnings.SetPopupWidth(w)
        end
    end)
    grip:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(T("warn_grip_tip"))
        GameTooltip:AddLine(T("warn_grip_reset"), 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    grip:SetScript("OnLeave", function() GameTooltip:Hide() end)
    frame.grip = grip
end

local function CreatePopup()
    local frame = CreateFrame("Frame", "FarolWarnPopup", UIParent, ns.backdropTemplate)
    frame:SetSize(SINGLE_WIDTH, 118)
    frame:SetPoint("TOP", 0, -240)
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    -- Um aviso só: passar o mouse mostra o texto inteiro (vários: cada linha tem o seu).
    frame:SetScript("OnEnter", function(self) if #queue == 1 then ShowTip(self, queue[1]) end end)
    frame:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    if frame.SetBackdrop then
        frame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 },
        })
    end
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("TOP", 0, -16)
    frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.text:SetPoint("TOP", frame.title, "BOTTOM", 0, -6)
    frame.text:SetJustifyH("CENTER")
    WrapText(frame.text, SINGLE_WIDTH - 40)
    -- Botões de baixo: um aviso = Silenciar / Lembrar; vários = Silenciar todos / Lembrar todos.
    frame.silence = NewButton(frame, "FarolWarnSilence", 124, function()
        if #queue == 1 then Warnings.Respond(false, queue[1].key) else Warnings.Respond(false) end
    end)
    frame.silence:SetPoint("BOTTOMLEFT", 22, 16)
    frame.time = ns.CreateDropdown(frame, "FarolWarnRemindTime", 34, MinuteItems(
        function()
            if #queue == 1 then return queue[1].minutes end
            return groupMinutes or DefaultMinutes()
        end,
        function(minutes)
            if #queue == 1 then queue[1].minutes = minutes else groupMinutes = minutes end
        end))
    frame.time:SetPoint("BOTTOMRIGHT", -26, 16)
    frame.remind = NewButton(frame, "FarolWarnRemind", 190, function() -- cabe "Lembrar todos em 30 min"
        if #queue == 1 then
            Warnings.Respond(true, queue[1].key, queue[1].minutes)
        else
            Warnings.Respond(true, nil, groupMinutes or DefaultMinutes())
        end
    end)
    frame.remind:SetPoint("RIGHT", frame.time, "LEFT", -2, 0)
    frame.rows = {}
    CreateGrip(frame)
    ns.MakeToplevel(frame) -- abre na frente e vem para a frente ao clicar
    frame:Hide()
    return frame
end

Render = function()
    if #queue == 0 then
        groupMinutes = nil
        if popup then popup:Hide() end
        return
    end
    popup = popup or CreatePopup()
    local group = #queue > 1
    popup.farolGroup = group
    for i, row in ipairs(popup.rows) do
        if not (group and queue[i]) then row.entry = nil; row:Hide() end
    end
    if group then
        local width = GroupWidth()
        local textWidth = width - 40 - BUTTONS_WIDTH - 10
        popup.title:SetText(string.format(T("warn_group_title"), #queue))
        popup.text:SetText("")
        popup.text:Hide()
        local y = 44
        for i, entry in ipairs(queue) do
            local row = popup.rows[i] or CreateRow(popup, i)
            popup.rows[i] = row
            row.entry = entry
            row.text:SetWidth(textWidth)
            row.text:SetText(entry.text)
            local height = math.max(ROW_HEIGHT - 4, TextHeight(row.text, entry.text, textWidth) + 8)
            row:SetSize(width - 40, height)
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", 20, -y)
            y = y + height + 4
            row.silence:SetText(T("warn_silence_btn"))
            row.remind:SetText(string.format(T("warn_remind_btn"), entry.minutes))
            row:Show()
        end
        popup:SetSize(width, y + 56)
        popup.silence:SetText(T("warn_silence_all"))
        popup.remind:SetText(string.format(T("warn_remind_all"), groupMinutes or DefaultMinutes()))
    else
        local width = SingleWidth()
        popup.title:SetText(T("warn_popup_title"))
        popup.text:SetWidth(width - 40)
        popup.text:SetText(queue[1].text)
        popup.text:Show()
        popup:SetSize(width, math.max(118, 104 + TextHeight(popup.text, queue[1].text, width - 40)))
        popup.silence:SetText(T("warn_silence_btn"))
        popup.remind:SetText(string.format(T("warn_remind_btn"), queue[1].minutes))
    end
    popup:Show()
end

-- Largura escolhida com a alça (0 = padrão). Salva só valores válidos e redesenha a janela.
function Warnings.SetPopupWidth(w)
    w = tonumber(w)
    if not w or w ~= w or w < POPUP_MIN then w = 0 end
    Settings().popupW = math.floor(math.min(w, POPUP_MAX))
    Render()
end
local ShowNext = Render -- nome antigo, usado abaixo

---------------------------------------------------------------------------
-- Histórico dos últimos avisos (FarolCharDB.warnHistory, por personagem)
---------------------------------------------------------------------------

local unread = 0          -- avisos novos desde a última vez que o histórico foi aberto
local historyButton       -- botão ao lado da barra (criado sob demanda)
local historyWindow
local RefreshHistory      -- definida abaixo
local HistoryDetail       -- Central do Farol (3.31), definida abaixo

local function History()
    if type(FarolCharDB) ~= "table" then return {} end
    FarolCharDB.warnHistory = FarolCharDB.warnHistory or {}
    return FarolCharDB.warnHistory
end

-- Valida o histórico salvo: só texto simples (sem códigos "|"), com no máximo 200 caracteres.
-- Data salva válida: número finito entre 1970 e 2100 (um arquivo adulterado com "infinito"
-- ou NaN quebraria a formatação da data).
local function ValidTime(t)
    t = tonumber(t)
    if t and t == t and t >= 0 and t <= 4102444800 then return math.floor(t) end
    return nil
end

function Warnings.SanitizeHistory(saved)
    local clean = {}
    if type(saved) ~= "table" then return clean end
    -- Só os HISTORY_MAX mais recentes válidos (linear, mesmo com uma lista adulterada enorme).
    clean = ns.KeepLast(saved, HISTORY_MAX, function(entry)
        if type(entry) ~= "table" or type(entry.text) ~= "string" or not ValidTime(entry.t) then return nil end
        local text = string.gsub(string.sub(entry.text, 1, 1000), "[|%c]", "")
        return { t = ValidTime(entry.t), text = string.sub(text, 1, 200) }
    end)
    return clean
end

local function UpdateButton()
    local db = ns.GetDB()
    if not db or not ns.frame then return end
    if not db.warnButton then
        if historyButton then historyButton:Hide() end
        ns.LayoutQuickButtons()
        return
    end
    if not historyButton then
        historyButton = CreateFrame("Button", "FarolWarnHistoryButton", ns.frame)
        historyButton:SetSize(18, 18)
        table.insert(ns.quickButtons, historyButton)
        historyButton.icon = historyButton:CreateTexture(nil, "ARTWORK")
        historyButton.icon:SetAllPoints()
        historyButton.icon:SetTexture(HISTORY_ICON)
        historyButton.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        historyButton.badge = historyButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        historyButton.badge:SetPoint("BOTTOMRIGHT", 4, -2)
        historyButton:RegisterForClicks("LeftButtonUp")
        historyButton:SetScript("OnClick", function() Warnings.ToggleHistory() end)
        historyButton:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(T("hist_button_tip"))
            GameTooltip:AddLine(unread > 0 and string.format(ns.TN("hist_button_new", unread), unread) or T("hist_button_none"),
                0.8, 0.8, 0.8)
            GameTooltip:Show()
        end)
        historyButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    -- Cor da paleta (ns.C): segue a opção de cores para daltonismo.
    historyButton.badge:SetText(unread > 0 and (ns.C.bad .. tostring(unread) .. "|r") or "")
    historyButton:Show()
    ns.LayoutQuickButtons()
end
Warnings.UpdateButton = UpdateButton

local function Record(text)
    local history = History()
    history[#history + 1] = { t = time(), text = string.gsub(text, "[|%c]", "") }
    while #history > HISTORY_MAX do table.remove(history, 1) end
    if historyWindow and historyWindow:IsShown() then
        RefreshHistory()
    else
        unread = unread + 1
    end
    UpdateButton()
end

local function Announce(text, key)
    -- Só no SEU cliente: centro da tela + sua janela de chat. Nada é enviado.
    if UIErrorsFrame and UIErrorsFrame.AddMessage then
        pcall(UIErrorsFrame.AddMessage, UIErrorsFrame, text, 1, 0.6, 0)
    end
    Print("|cffff9900" .. text .. "|r" .. T("warn_chat_hint"))
    if key ~= "test" then Record(text) end
    if Settings().sound then pcall(PlayWarningSound) end
    -- Um aviso de cada tipo na fila: um aviso novo do mesmo tipo atualiza o texto.
    for _, entry in ipairs(queue) do
        if entry.key == key then
            entry.text = text
            ShowNext()
            return
        end
    end
    queue[#queue + 1] = { key = key, text = text, minutes = DefaultMinutes() }
    ShowNext()
end

local function ValidRemind(minutes)
    minutes = tonumber(minutes)
    for _, choice in ipairs(REMIND_CHOICES) do
        if minutes == choice then return choice end
    end
    return nil
end

local function IsBreak(key) return key == "pause" or key == "water" end

-- Aplica a resposta a um aviso. Um lembrete por tipo: lembrar de novo troca o horário anterior.
local function Apply(current, remind, minutes, now)
    local entry = state[current.key]
    if not entry then return end
    if IsBreak(current.key) then
        if remind then entry.nextAt = now + minutes * 60 else entry.silenced = true end
    elseif remind then
        entry.remindAt = now + minutes * 60
    else
        entry.remindAt = nil
    end
end

-- Resposta do jogador: remind = true (lembrar em "minutes") ou false (silenciar).
-- key = um aviso; sem key = todos os avisos abertos (botões "todos" e comandos do chat).
function Warnings.Respond(remind, key, minutes)
    if #queue == 0 then Print(T("warn_none")) return end
    minutes = ValidRemind(minutes) or DefaultMinutes()
    local now = GetTime()
    local answered, onlyBreaks = {}, true
    for i = #queue, 1, -1 do
        if key == nil or queue[i].key == key then
            local current = table.remove(queue, i)
            Apply(current, remind, minutes, now)
            table.insert(answered, 1, current)
            if not IsBreak(current.key) then onlyBreaks = false end
        end
    end
    if #answered == 0 then Print(T("warn_none")) return end
    local at = date("%H:%M", time() + minutes * 60)
    if #answered > 1 then
        Print(remind and string.format(ns.TN("warn_reminded_n", #answered), #answered, at) or string.format(ns.TN("warn_silenced_n", #answered), #answered))
    elseif remind then
        Print(string.format(T("warn_reminded"), at))
    else
        Print(onlyBreaks and T("warn_silenced_session") or T("warn_silenced"))
    end
    ShowNext()
end

-- Em combate? Leitura protegida: se o jogo der erro, conta como "em combate" (os avisos só esperam).
local function InCombat()
    if not InCombatLockdown then return false end
    local ok, value = pcall(InCombatLockdown)
    if not ok then return true end
    return value and true or false
end

local function CanFire(entry, now)
    return entry.armed and (entry.lastAt == nil or now - entry.lastAt >= COOLDOWN)
end

local function Fire(entry, now, text, key)
    entry.armed = false
    entry.lastAt = now
    entry.remindAt = nil
    Announce(text, key)
end

-- "Lembrar em 30 min" venceu e o problema continua?
local function ReminderDue(entry, now)
    return entry.remindAt ~= nil and now >= entry.remindAt
end

local function CheckDurability(now)
    local settings = Settings()
    local lowest = ns.GetLowestDurability()
    if not settings.durab or type(lowest) ~= "number" or ns.IsSecret(lowest) then return end
    local entry = state.durab
    if lowest < settings.durabPct then
        local text = string.format(T("warn_durab"), math.floor(lowest))
        if CanFire(entry, now) then
            Fire(entry, now, text, "durab")
        elseif ReminderDue(entry, now) then
            entry.remindAt = nil
            Announce(text, "durab")
        end
    else
        entry.armed = true -- reparou: pode avisar de novo
        entry.remindAt = nil
    end
end

-- Valor em texto simples ("3g 24s"), sem códigos de cor: vai para o chat e para o histórico.
local function PlainMoney(copper)
    local gold, silver, cop = math.floor(copper / 10000), math.floor(copper % 10000 / 100), copper % 100
    if gold > 0 then return gold .. "g " .. silver .. "s" end
    if silver > 0 then return silver .. "s " .. cop .. "c" end
    return cop .. "c"
end

-- Dica para o aviso de bolsas: quanto lixo dá para vender (o Farol nunca vende sozinho).
local function JunkHint()
    if not ns.GetJunk then return "" end
    local ok, junk = pcall(ns.GetJunk)
    if not ok or not junk or junk.slots == 0 then return "" end
    return string.format(ns.TN("warn_bags_junk", junk.slots), junk.slots, PlainMoney(junk.total))
end

local function CheckBags(now)
    local settings = Settings()
    if not settings.bags then return end
    local free = ns.GetBagSpace()
    if type(free) ~= "number" or ns.IsSecret(free) then return end
    local entry = state.bags
    if free > settings.bagSlots then
        entry.armed = true -- liberou espaço: pode avisar de novo
        entry.full = false
        entry.remindAt = nil
        return
    end
    if free > 0 then entry.full = false end
    -- Texto montado só na hora de avisar (a dica do lixo lê as bolsas).
    local function Text() return (free == 0 and T("warn_bags_full") or string.format(ns.TN("warn_bags", free), free)) .. JunkHint() end
    if free == 0 and not entry.full then
        -- Encheu de vez: avisa mesmo que já tenha avisado "quase cheias" há pouco.
        entry.full = true
        Fire(entry, now, Text(), "bags")
    elseif CanFire(entry, now) then
        Fire(entry, now, Text(), "bags")
    elseif ReminderDue(entry, now) then
        entry.remindAt = nil
        Announce(Text(), "bags")
    end
end

---------------------------------------------------------------------------
-- Talentos não gastos
-- A função mudou de nome entre versões do jogo; tentamos cada uma, em ordem.
---------------------------------------------------------------------------

local function TraitsUnspent()
    -- Clientes modernos: soma a "moeda" de pontos de cada árvore de talentos.
    local configID = C_ClassTalents.GetActiveConfigID()
    if not configID then return nil end
    local config = C_Traits.GetConfigInfo(configID)
    if not config or type(config.treeIDs) ~= "table" then return nil end
    local total = 0
    for _, treeID in ipairs(config.treeIDs) do
        for _, currency in ipairs(C_Traits.GetTreeCurrencyInfo(configID, treeID, false) or {}) do
            total = total + (tonumber(currency.quantity) or 0)
        end
    end
    return total
end

-- Pontos gastos em uma árvore. A ordem dos valores de GetTalentTabInfo muda entre versões:
--   clássico: nome, ícone, pontosGastos, ...       (1º valor é texto)
--   Wrath+:   id, nome, descrição, ícone, pontosGastos, ...   (1º valor é número)
local function TabPointsSpent(tab)
    local r1, _, r3, _, r5 = GetTalentTabInfo(tab)
    local spent
    if type(r1) == "string" then spent = r3 else spent = r5 end
    return type(spent) == "number" and spent or nil
end

-- Estimativa de reserva: no sistema clássico ganha-se 1 ponto por nível a partir do 10
-- (51 no nível 60). Pontos esperados − pontos gastos. Bônus do Forever que dão pontos extras
-- só fazem esta conta avisar A MENOS, nunca a mais.
local function TabsEstimate()
    if not (GetNumTalentTabs and GetTalentTabInfo and UnitLevel) then return nil end
    local tabs = GetNumTalentTabs()
    if type(tabs) ~= "number" or tabs < 1 then return nil end
    local spent = 0
    for tab = 1, tabs do
        local points = TabPointsSpent(tab)
        if not points then return nil end
        spent = spent + points
    end
    local expected = math.max(0, UnitLevel("player") - 9)
    return math.max(0, expected - spent)
end

local TALENT_SOURCES = {
    { "UnitCharacterPoints", function() return UnitCharacterPoints and UnitCharacterPoints("player") end },
    { "GetUnspentTalentPoints", function() return GetUnspentTalentPoints and GetUnspentTalentPoints() end },
    { "GetNumUnspentTalents", function() return GetNumUnspentTalents and GetNumUnspentTalents() end },
    { "C_Traits", function() return C_ClassTalents and C_Traits and TraitsUnspent() end },
    { "estimativa/estimate", TabsEstimate },
}

-- Lê uma fonte: devolve número, "não existe" (nil) ou erro.
local function ReadSource(source)
    local ok, points = pcall(source[2])
    if ok and type(points) == "number" and not ns.IsSecret(points) and points >= 0 and points <= 100 then
        return points
    end
    return nil, ok and "nil" or "erro"
end

-- Consulta TODAS as fontes e usa o maior valor: uma função que existe mas sempre devolve 0
-- (de outro sistema de talentos) não esconde mais os pontos encontrados por outra fonte.
-- Devolve (pontos, nome da fonte) ou nil se nenhuma funcionar neste cliente.
local function UnspentTalents()
    local best, bestSource
    for _, source in ipairs(TALENT_SOURCES) do
        local points = ReadSource(source)
        if points and (not best or points > best) then
            best, bestSource = points, source[1]
        end
    end
    return best, bestSource
end

local function CheckTalents(now)
    if not Settings().talents then return end
    local points = UnspentTalents()
    if not points then return end
    local entry = state.talents
    if points == 0 then
        entry.warnedCount = 0
        entry.remindAt = nil
    elseif points > entry.warnedCount then
        entry.warnedCount = points
        entry.remindAt = nil
        Announce(string.format(ns.TN("warn_talents", points), points), "talents")
    elseif ReminderDue(entry, now) then
        entry.remindAt = nil
        Announce(string.format(ns.TN("warn_talents", points), points), "talents")
    end
end

---------------------------------------------------------------------------
-- Graus de magia na barra de ações
---------------------------------------------------------------------------

-- Número do grau a partir do texto do jogo ("Grau 3" / "Rank 3"); nil se não for grau.
local function RankNumber(subtext)
    if type(subtext) ~= "string" or ns.IsSecret(subtext) then return nil end
    return tonumber(string.match(subtext, "(%d+)"))
end

local function SpellNameAndRank(spellID)
    local name, sub
    if C_Spell and C_Spell.GetSpellName then
        name = C_Spell.GetSpellName(spellID)
        sub = C_Spell.GetSpellSubtext and C_Spell.GetSpellSubtext(spellID)
    elseif GetSpellInfo then
        name, sub = GetSpellInfo(spellID) -- clientes antigos: GetSpellInfo devolve nome e grau
        if GetSpellSubtext then sub = GetSpellSubtext(spellID) or sub end
    end
    if type(name) ~= "string" or ns.IsSecret(name) then return nil end
    return name, RankNumber(sub)
end

-- Maior grau conhecido de cada magia, lendo o grimório (API moderna ou clássica).
local function HighestRanks()
    local best = {}
    local function Consider(name, rank)
        if type(name) == "string" and rank and (not best[name] or rank > best[name]) then
            best[name] = rank
        end
    end
    if C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines and C_SpellBook.GetSpellBookItemInfo then
        local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player or 0
        for line = 1, C_SpellBook.GetNumSpellBookSkillLines() do
            local info = C_SpellBook.GetSpellBookSkillLineInfo(line)
            if info then
                for index = info.itemIndexOffset + 1, info.itemIndexOffset + info.numSpellBookItems do
                    local item = C_SpellBook.GetSpellBookItemInfo(index, bank)
                    if item then Consider(item.name, RankNumber(item.subName)) end
                end
            end
        end
    elseif GetNumSpellTabs and GetSpellTabInfo then
        local getName = GetSpellBookItemName or GetSpellName
        for tab = 1, GetNumSpellTabs() do
            local _, _, offset, count = GetSpellTabInfo(tab)
            for index = (offset or 0) + 1, (offset or 0) + (count or 0) do
                local name, sub = getName(index, BOOKTYPE_SPELL or "spell")
                Consider(name, RankNumber(sub))
            end
        end
    end
    return best
end

-- Lista as magias da barra cujo grau é menor que o maior conhecido.
local function FindOutdatedSpells()
    local best = HighestRanks()
    local outdated, seen = {}, {}
    for slot = 1, MAX_ACTION_SLOT do
        if HasAction(slot) then
            local kind, id = GetActionInfo(slot)
            if kind == "spell" and type(id) == "number" and not ns.IsSecret(id) then
                local name, rank = SpellNameAndRank(id)
                local key = name and rank and (name .. "#" .. rank)
                if key and best[name] and best[name] > rank and not seen[key] then
                    seen[key] = true
                    outdated[#outdated + 1] = { key = key, name = name, rank = rank, best = best[name] }
                end
            end
        end
    end
    return outdated
end

local function CheckRanks(now)
    if not Settings().ranks then return end
    local entry = state.ranks
    local reminding = ReminderDue(entry, now)
    if reminding then entry.dirty = true end
    if not entry.dirty and entry.lastScan and now - entry.lastScan < 60 then return end
    if entry.lastScan and now - entry.lastScan < RANK_SCAN_INTERVAL then return end
    entry.dirty, entry.lastScan = false, now

    local outdated = FindOutdatedSpells()
    local current, fresh = {}, {}
    for _, spell in ipairs(outdated) do
        current[spell.key] = true
        if not entry.warned[spell.key] then fresh[#fresh + 1] = spell end
    end
    entry.warned = current -- magias trocadas saem da lista e podem avisar de novo no futuro
    if #outdated == 0 then entry.remindAt = nil return end
    if reminding then
        entry.remindAt = nil
        fresh = outdated -- lembrete: mostra todas as que continuam desatualizadas
    end
    if #fresh == 0 then return end

    local parts = {}
    for i = 1, math.min(3, #fresh) do
        parts[i] = string.format(T("warn_rank_item"), fresh[i].name, fresh[i].rank, fresh[i].best)
    end
    local text = table.concat(parts, "; ")
    if #fresh > 3 then text = text .. string.format(T("warn_more"), #fresh - 3) end
    Announce(string.format(T("warn_ranks"), text), "ranks")
end

---------------------------------------------------------------------------
-- Profissão no máximo do treinamento: "procure um instrutor"
---------------------------------------------------------------------------

-- Avisa uma vez por limite (ex.: Mineração em 150/150). Treinou e subiu o limite: o próximo limite avisa de novo.
-- O último limite (300) não avisa: não há mais o que treinar.
local function CheckProfessions(now)
    if not Settings().prof or not ns.ReadProfessions then return end
    local list = ns.ReadProfessions()
    if not list then return end
    local entry = state.prof
    local capped, fresh = {}, {}
    for _, p in ipairs(list) do
        if ns.ProfState(p) == "cap" then
            local id = p.name .. "@" .. p.max
            capped[#capped + 1] = p
            if not entry.warned[id] then fresh[#fresh + 1] = p end
        end
    end
    local warned = {}
    for _, p in ipairs(capped) do warned[p.name .. "@" .. p.max] = true end
    entry.warned = warned -- treinou: sai da lista
    if #capped == 0 then entry.remindAt = nil return end
    local reminding = ReminderDue(entry, now)
    if reminding then entry.remindAt = nil; fresh = capped end
    if #fresh == 0 then return end
    local parts = {}
    for i, p in ipairs(fresh) do
        parts[i] = string.gsub(p.name, "[|%c]", "") .. " " .. p.level .. "/" .. p.max
    end
    Announce(string.format(T("warn_prof"), table.concat(parts, ", ")), "prof")
end

---------------------------------------------------------------------------
-- Munição e reagentes abaixo do vermelho (contagem feita pelo Core; o Farol nunca compra nada).
-- Avisa uma vez por grupo; avisa de novo depois que você reabastecer e o número cair outra vez.
---------------------------------------------------------------------------

local function CheckSupplies(now)
    local settings = Settings()
    if not (settings.ammo or settings.reag) or not ns.GetSupplies then return end
    local list = ns.GetSupplies()
    if not list then return end
    local entry = state.supply
    local out, fresh, warned = {}, {}, {}
    for _, s in ipairs(list) do
        local enabled = (s.kind == "ammo" and settings.ammo) or (s.kind ~= "ammo" and settings.reag)
        if enabled and s.state == "out" then
            out[#out + 1] = s
            warned[s.key] = true
            if not entry.warned[s.key] then fresh[#fresh + 1] = s end
        end
    end
    entry.warned = warned -- reabasteceu: sai da lista e pode avisar de novo no futuro
    if #out == 0 then entry.remindAt = nil return end
    if ReminderDue(entry, now) then entry.remindAt = nil; fresh = out end
    if #fresh == 0 then return end
    local parts = {}
    for i, s in ipairs(fresh) do parts[i] = T("sup_" .. s.key) .. ": " .. s.count end
    Announce(string.format(T("warn_supply"), table.concat(parts, ", ")), "supply")
end

---------------------------------------------------------------------------
-- Outro personagem com o descanso cheio (estimativa feita pelo Core). Confere uma vez por sessão.
---------------------------------------------------------------------------

local function CheckRestFull(now)
    if not Settings().restFull or not ns.RestedAlts then return end
    local entry = state.restFull
    local reminding = ReminderDue(entry, now)
    if entry.checked and not reminding then return end
    local list = ns.RestedAlts()
    if not list then return end -- nome/reino ainda não carregados: tenta de novo
    entry.checked = true
    if reminding then entry.remindAt = nil end
    local names = {}
    for _, r in ipairs(list) do
        if r.full then names[#names + 1] = string.gsub(r.name, "[|%c]", "") .. " (" .. r.level .. ")" end
    end
    if #names == 0 then return end
    if #names > 4 then names = { names[1], names[2], names[3], names[4] .. string.format(T("warn_more"), #names - 4) } end
    Announce(string.format(T("warn_restFull"), table.concat(names, ", ")), "restFull")
end

-- Tarefas diárias que faltam, 1 h antes do reset diário: uma vez por reset (e de novo no "Lembrar em").
local TASKS_BEFORE = 3600
local function CheckTasks(now)
    if not Settings().tasks or not ns.Tasks then return end
    local entry = state.tasks
    local left, resetIn = ns.Tasks.PendingDaily()
    if not left or left == 0 or not resetIn or resetIn > TASKS_BEFORE then return end
    local cycle = math.floor((time() + resetIn) / 600) -- este reset (arredondado em 10 min)
    local text = left == 1 and string.format(T("warn_task_one"), ns.FormatDuration(resetIn))
        or string.format(T("warn_tasks"), left, ns.FormatDuration(resetIn))
    if entry.cycle ~= cycle then
        entry.cycle, entry.remindAt = cycle, nil
        Announce(text, "tasks")
    elseif ReminderDue(entry, now) then
        entry.remindAt = nil
        Announce(text, "tasks")
    end
end

-- Meta de ouro ou de nível alcançada: uma vez por meta (fica marcado em FarolCharDB.goals).
local function CheckGoals()
    if not Settings().goals or not ns.Goals then return end
    local list = ns.Goals.NewlyReached()
    if #list > 0 then Announce(string.format(T("warn_goals"), table.concat(list, ", ")), "goals") end
end

function Warnings.TasksChanged() state.tasks.cycle, state.tasks.remindAt = nil, nil end

---------------------------------------------------------------------------
-- Diário de missões (Quests.lua): quase cheio (a partir de N) e prontas ao entrar numa cidade ou estalagem
---------------------------------------------------------------------------

local function CheckQuestFull(now)
    local settings = Settings()
    local entry = state.questFull
    if not settings.questFull or not ns.Quests then return end
    local data = ns.Quests.Read()
    if not data then return end
    if data.count < settings.questMin then -- liberou espaço: pode avisar de novo
        entry.armed, entry.full, entry.remindAt = true, false, nil
        return
    end
    local full = data.count >= data.max
    if not full then entry.full = false end
    local text = string.format(full and T("warn_questFull_full") or T("warn_questFull"), data.count, data.max)
    if full and not entry.full then
        entry.full = true -- encheu de vez: avisa mesmo que tenha avisado "quase cheio" há pouco
        Fire(entry, now, text, "questFull")
    elseif CanFire(entry, now) then
        Fire(entry, now, text, "questFull")
    elseif ReminderDue(entry, now) then
        entry.remindAt = nil
        Announce(text, "questFull")
    end
end

-- Ao passar a descansar (entrou numa cidade ou estalagem, ou entrou no jogo numa delas): avisa se há missões
-- prontas. No máximo uma vez a cada 5 min; o "Lembrar em" avisa de novo se ainda houver.
local function CheckQuestReady(now)
    local entry = state.questReady
    if not Settings().questReady or not ns.Quests or not IsResting then entry.wasResting = nil return end
    local ok, value = pcall(IsResting)
    if not ok or ns.IsSecret(value) then return end
    local resting = value and true or false
    local arrived = resting and not entry.wasResting
    entry.wasResting = resting
    local reminding = ReminderDue(entry, now)
    if not reminding and not (arrived and (entry.lastAt == nil or now - entry.lastAt >= COOLDOWN)) then return end
    local data = ns.Quests.Read()
    local ready = data and #data.ready or 0
    if reminding then entry.remindAt = nil end
    if ready == 0 then return end
    entry.lastAt = now
    Announce(ready == 1 and T("warn_questReady_one") or string.format(T("warn_questReady"), ready), "questReady")
end

-- Entregar as prontas sobe de nível: avisa uma vez por nível (o "Lembrar em" avisa de novo se ainda valer).
local function CheckQuestLevel(now)
    local entry = state.questLevel
    if not Settings().questLevel or not ns.Quests or not ns.Quests.Value then return end
    local data = ns.Quests.Read()
    local v = data and ns.Quests.Value(data)
    if not v or not v.next then return end
    local reminding = ReminderDue(entry, now)
    if entry.warned == v.level and not reminding then return end
    if reminding then entry.remindAt = nil end
    entry.warned = v.level
    Announce(string.format(ns.TN("warn_questLevel", #data.ready), #data.ready, v.next), "questLevel")
end

-- Pedra de Regresso: avisa uma vez quando a recarga termina (só se a viu em recarga nesta sessão; ao entrar com
-- ela já pronta, não avisa). Espera a luta e a masmorra acabarem, como os lembretes.
local Busy -- definida abaixo
local function CheckHearth(now)
    local entry = state.hearthReady
    if not Settings().hearthReady or not ns.Hearth then entry.cooling = false return end
    local ready, status = ns.Hearth.Ready()
    if ready == nil then return end
    if not ready then entry.cooling = true return end
    local reminding = ReminderDue(entry, now)
    if not entry.cooling and not reminding then return end
    if Busy() then return end -- espera
    entry.cooling = false
    if reminding then entry.remindAt = nil end
    Announce(status.place and string.format(T("warn_hearthReady"), status.place) or T("warn_hearthReady_noplace"), "hearthReady")
end

---------------------------------------------------------------------------
-- Lembretes de pausa e de beber água (por tempo)
---------------------------------------------------------------------------

-- Em luta, ou dentro de masmorra, raide, arena ou campo de batalha?
Busy = function()
    if InCombat() then return true end
    if IsInInstance then
        local ok, inside, kind = pcall(IsInInstance)
        if ok and inside and kind ~= "none" then return true end
    end
    return false
end

-- Conta a partir do login (ou de quando a opção foi ligada / o intervalo mudou). Quando vence:
-- aparece, ou espera a luta/masmorra acabar se o jogador não marcou "também em lutas...".
local function CheckBreaks(now)
    local settings = Settings()
    for _, key in ipairs(BREAK_KEYS) do
        local entry = state[key]
        if not settings[key] then
            entry.nextAt, entry.silenced = nil, false
        elseif not entry.silenced then
            local interval = settings[key .. "Min"] * 60
            if not entry.nextAt then
                entry.nextAt = now + interval
            elseif now >= entry.nextAt and (settings[key .. "Anywhere"] or not Busy()) then
                entry.nextAt = now + interval
                local text = T("warn_water")
                if key == "pause" then
                    local played = ns.GetSessionSeconds and ns.GetSessionSeconds() or nil
                    text = string.format(T("warn_pause"), ns.FormatDuration(played or interval))
                end
                Announce(text, key)
            end
        end
    end
end

-- Mudanças nas barras, no grimório ou no nível pedem uma nova varredura dos graus.
local watcher = CreateFrame("Frame")
for _, event in ipairs({ "ACTIONBAR_SLOT_CHANGED", "SPELLS_CHANGED", "LEARNED_SPELL_IN_TAB",
                         "PLAYER_LEVEL_UP", "PLAYER_ENTERING_WORLD", "UPDATE_BONUS_ACTIONBAR" }) do
    pcall(watcher.RegisterEvent, watcher, event)
end
watcher:SetScript("OnEvent", function() state.ranks.dirty = true end)

-- Verifica uma vez por segundo, num frame próprio (funciona com o painel escondido).
local driver = CreateFrame("Frame")
local sinceCheck = 0
driver:SetScript("OnUpdate", function(_, elapsed)
    sinceCheck = sinceCheck + elapsed
    if sinceCheck < 1 then return end
    sinceCheck = 0
    if not ns.GetDB() or not Settings() then return end
    local now = GetTime()
    pcall(CheckDurability, now)
    pcall(CheckBags, now)
    pcall(CheckBreaks, now)
    if not InCombat() then -- talentos e graus esperam o combate acabar
        pcall(CheckTalents, now)
        pcall(CheckRanks, now)
        pcall(CheckProfessions, now)
        pcall(CheckRestFull, now)
        pcall(CheckSupplies, now)
        pcall(CheckTasks, now)
        pcall(CheckGoals)
        pcall(CheckQuestFull, now)
        pcall(CheckQuestReady, now)
        pcall(CheckQuestLevel, now)
        pcall(CheckHearth, now)
    end
end)

---------------------------------------------------------------------------
-- Ajustes (usados pela janela e pelos comandos)
---------------------------------------------------------------------------

local RefreshWindow -- definida abaixo

local function SetEnabled(key, value, quiet)
    Settings()[key] = value
    if key == "talents" then state.talents.warnedCount = 0
    elseif key == "ranks" then state.ranks.warned = {}; state.ranks.dirty = true
    elseif key == "prof" then state.prof.warned = {}; state.prof.remindAt = nil
    elseif key == "restFull" then state.restFull.checked = false; state.restFull.remindAt = nil
    elseif key == "ammo" or key == "reag" then state.supply.warned = {}; state.supply.remindAt = nil
    elseif IsBreak(key) then -- recomeça a contagem agora
        state[key].nextAt = value and GetTime() + Settings()[key .. "Min"] * 60 or nil
        state[key].silenced = false
        if not value then -- desligou: o aviso aberto desse lembrete some da janela
            for i = #queue, 1, -1 do
                if queue[i].key == key then table.remove(queue, i) end
            end
            ShowNext()
        end
    elseif key == "questReady" then state.questReady.wasResting, state.questReady.lastAt = nil, nil
    elseif key == "questFull" then state.questFull.armed, state.questFull.full = true, false
    elseif key == "hearthReady" then state.hearthReady.cooling, state.hearthReady.remindAt = false, nil
    elseif key == "questLevel" then state.questLevel.warned, state.questLevel.remindAt = nil, nil
    elseif key == "questValue" then if ns.UpdateText then ns.UpdateText() end
    elseif state[key] then state[key].armed = true end
    if not quiet then Print(string.format(value and T("warn_on") or T("warn_off"), T("warn_name_" .. key))) end
    if RefreshWindow then RefreshWindow() end
end

-- Botões do topo da aba Avisos: "Só os recomendados" (os padrões aprovados) e "Desligar todos". O som e as opções
-- "também em lutas" ficam como estão.
local TOGGLE_KEYS = { "durab", "bags", "ammo", "reag", "talents", "ranks", "prof", "restFull", "goals",
                      "questFull", "questReady", "questLevel", "hearthReady", "tasks", "pause", "water" }
function Warnings.SetAll(recommended)
    for _, key in ipairs(TOGGLE_KEYS) do
        local value = recommended and DEFAULTS[key] or false
        if Settings()[key] ~= value then SetEnabled(key, value, true) end
    end
    Print(recommended and T("warn_set_recommended") or T("warn_set_all_off"))
    if RefreshWindow then RefreshWindow() end
end

local function SetDurabPct(value)
    local pct = InRange(value, DURAB_MIN, DURAB_MAX)
    if not pct then Print(T("warn_bad_durab")) return false end
    Settings().durabPct = pct
    state.durab.armed = true
    Print(string.format(T("warn_set_durab"), pct))
    if RefreshWindow then RefreshWindow() end
    return true
end

-- Intervalo do lembrete de pausa/água (15 a 240 min); a contagem recomeça agora.
local function SetBreakMinutes(key, value)
    local minutes = InRange(value, BREAK_MIN, BREAK_MAX)
    if not minutes then Print(T("warn_bad_break")) return false end
    Settings()[key .. "Min"] = minutes
    state[key].nextAt = GetTime() + minutes * 60 -- a contagem recomeça agora
    Print(string.format(T("warn_set_break"), T("warn_name_" .. key), minutes))
    if RefreshWindow then RefreshWindow() end
    return true
end

-- Limites de munição/reagentes: amarelo e vermelho (vermelho menor que o amarelo; 0 no amarelo = sem amarelo).
local function SetSupplyLimits(kind, yellow, red)
    local max = kind == "ammo" and 5000 or 200
    local y, r = InRange(yellow, 0, max), InRange(red, 0, max)
    if not y or not r or (y > 0 and r >= y) then Print(string.format(T("warn_bad_supply"), max)) return false end
    Settings()[kind .. "Yellow"], Settings()[kind .. "Red"] = y, r
    state.supply.warned = {}
    Print(string.format(T("warn_set_supply"), T("warn_name_" .. kind), y, r))
    if ns.UpdateText then ns.UpdateText() end
    if RefreshWindow then RefreshWindow() end
    return true
end

-- Pode aparecer em lutas, raides e masmorras? (false = espera)
local function SetAnywhere(key, value)
    Settings()[key .. "Anywhere"] = value
    Print(string.format(value and T("warn_set_anywhere") or T("warn_set_wait"), T("warn_name_" .. key)))
    if RefreshWindow then RefreshWindow() end
end

-- Tempo que já vem escolhido no "Lembrar em".
local function SetRemindDefault(value)
    local minutes = ValidRemind(value)
    if not minutes then Print(T("warn_bad_remind")) return false end
    Settings().remindMin = minutes
    Print(string.format(T("warn_set_remind"), minutes))
    if RefreshWindow then RefreshWindow() end
    return true
end

local function SetQuestMin(value)
    local count = InRange(value, QUEST_MIN, QUEST_MAX)
    if not count then Print(T("warn_bad_questMin")) return false end
    Settings().questMin = count
    state.questFull.armed, state.questFull.full = true, false
    Print(string.format(T("warn_set_questMin"), count))
    if RefreshWindow then RefreshWindow() end
    return true
end

local function SetBagSlots(value)
    local slots = InRange(value, BAGS_MIN, BAGS_MAX)
    if not slots then Print(T("warn_bad_bags")) return false end
    Settings().bagSlots = slots
    state.bags.armed = true
    Print(string.format(ns.TN("warn_set_bags", slots), slots))
    if RefreshWindow then RefreshWindow() end
    return true
end

---------------------------------------------------------------------------
-- Controles dos avisos (aba "Avisos" do menu)
---------------------------------------------------------------------------

local function NumberBox(frame, name, anchor, onSave, digits)
    local box = CreateFrame("EditBox", name, frame, "InputBoxTemplate")
    box:SetSize(digits == 3 and 36 or 28, 20)
    box:SetPoint("LEFT", anchor, "RIGHT", 10, 0)
    box:SetAutoFocus(false)
    box:SetNumeric(true)
    box:SetMaxLetters(digits or 2)
    box:SetScript("OnEnterPressed", function(self)
        if not onSave(self:GetText()) then RefreshWindow() end -- inválido: volta ao valor salvo
        self:ClearFocus()
    end)
    box:SetScript("OnEscapePressed", function(self) RefreshWindow(); self:ClearFocus() end)
    box.farolApply = function(self) if not onSave(self:GetText()) then RefreshWindow() end end
    frame.farolBoxes = frame.farolBoxes or {}
    table.insert(frame.farolBoxes, box)
    ns.TabChain(frame.farolBoxes) -- Tab: próximo campo de número da aba
    return box
end

-- Controles dos avisos, em seções (aba "Avisos" do menu e do painel de configurações do jogo).
-- prefix = começo dos nomes ("FarolWarn" no menu do Farol). Posições relativas ao canto do "parent".
local sets = {}

function Warnings.BuildControls(parent, prefix)
    local set = {}
    local function Check(name, x, y, key, onClick)
        local check = CreateFrame("CheckButton", prefix .. name, parent, "UICheckButtonTemplate")
        check:SetSize(24, 24)
        check:SetPoint("TOPLEFT", x, y)
        check.label = check:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        check.label:SetPoint("LEFT", check, "RIGHT", 4, 0)
        check:SetScript("OnClick", function(self)
            local value = self:GetChecked() and true or false
            if onClick then onClick(value) else SetEnabled(key, value) end
        end)
        return check
    end
    local function Header(x, y)
        local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        header:SetPoint("TOPLEFT", x, y)
        return header
    end
    local function Unit(anchor)
        local unit = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        unit:SetPoint("LEFT", anchor, "RIGHT", 6, 0)
        return unit
    end

    -- Topo: "Só os recomendados" e "Desligar todos". Embaixo: a faixa com a explicação do aviso sob o mouse.
    set.recommended = CreateFrame("Button", prefix .. "Recommended", parent, "UIPanelButtonTemplate")
    set.recommended:SetSize(160, 22)
    set.recommended:SetPoint("TOPLEFT", 16, 0)
    set.recommended:SetScript("OnClick", function() Warnings.SetAll(true) end)
    set.allOff = CreateFrame("Button", prefix .. "AllOff", parent, "UIPanelButtonTemplate")
    set.allOff:SetSize(130, 22)
    set.allOff:SetPoint("LEFT", set.recommended, "RIGHT", 8, 0)
    set.allOff:SetScript("OnClick", function() Warnings.SetAll(false) end)
    set.topHint = ns.Dim(parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"))
    set.topHint:SetPoint("LEFT", set.allOff, "RIGHT", 10, 0)
    set.info = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    set.info:SetPoint("TOPLEFT", 16, -444) -- abaixo da coluna 2 (3.23: + XP e ouro das prontas)
    set.info:SetWidth(620)
    set.info:SetJustifyH("LEFT")
    local function Explain(check, key)
        check:SetScript("OnEnter", function() Warnings.ShowInfo(set, key) end)
        check:SetScript("OnLeave", function() Warnings.ShowInfo(set, nil) end)
        return check
    end

    -- Coluna 1: equipamento; personagem.
    local x, y = 16, -30
    set.gearHeader = Header(x, y)
    set.durab = Explain(Check("Durab", x, y - 18, "durab"), "durab")
    set.durabBox = NumberBox(parent, prefix .. "DurabPct", set.durab.label, SetDurabPct)
    set.durabUnit = Unit(set.durabBox)
    set.bags = Explain(Check("Bags", x, y - 43, "bags"), "bags")
    set.bagsBox = NumberBox(parent, prefix .. "BagSlots", set.bags.label, SetBagSlots)
    set.bagsUnit = Unit(set.bagsBox)
    -- Munição e reagentes: liga/desliga e, na linha de baixo, os limites amarelo e vermelho.
    y = y - 68
    for _, kind in ipairs({ "ammo", "reag" }) do
        local cap = kind == "ammo" and "Ammo" or "Reag"
        set[kind] = Explain(Check(cap, x, y, kind), kind)
        local yl = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        yl:SetPoint("TOPLEFT", x + 30, y - 28)
        set[kind .. "YellowLabel"] = yl
        local function save() -- lê as duas caixas e grava juntas
            return SetSupplyLimits(kind, set[kind .. "YellowBox"]:GetText(), set[kind .. "RedBox"]:GetText())
        end
        set[kind .. "YellowBox"] = NumberBox(parent, prefix .. cap .. "Yellow", yl, save, 4)
        local rl = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        rl:SetPoint("LEFT", set[kind .. "YellowBox"], "RIGHT", 14, 0)
        set[kind .. "RedLabel"] = rl
        set[kind .. "RedBox"] = NumberBox(parent, prefix .. cap .. "Red", rl, save, 4)
        y = y - 50
    end
    y = y - 6
    set.charHeader = Header(x, y)
    set.talents = Explain(Check("Talents", x, y - 18, "talents"), "talents")
    set.ranks = Explain(Check("Ranks", x, y - 43, "ranks"), "ranks")
    set.prof = Explain(Check("Prof", x, y - 68, "prof"), "prof")
    set.restFull = Explain(Check("RestFull", x, y - 93, "restFull"), "restFull")
    set.goals = Explain(Check("Goals", x, y - 118, "goals"), "goals")
    local bottom = y - 146

    -- Coluna 2: missões e viagem; pausas; como avisar.
    x, y = 330, -30
    set.questHeader = Header(x, y)
    set.questFull = Explain(Check("QuestFull", x, y - 18, "questFull"), "questFull")
    set.questBox = NumberBox(parent, prefix .. "QuestMin", set.questFull.label, SetQuestMin, 3)
    set.questUnit = Unit(set.questBox)
    set.questReady = Explain(Check("QuestReady", x, y - 43, "questReady"), "questReady")
    set.hearthReady = Explain(Check("HearthReady", x, y - 68, "hearthReady"), "hearthReady")
    set.tasks = Explain(Check("Tasks", x, y - 93, "tasks"), "tasks")
    set.questValue = Explain(Check("QuestValue", x, y - 118, "questValue"), "questValue")
    set.questLevel = Explain(Check("QuestLevel", x, y - 143, "questLevel"), "questLevel")
    y = y - 173
    set.breaksHeader = Header(x, y)
    y = y - 18
    for _, key in ipairs(BREAK_KEYS) do
        local cap = key == "pause" and "Pause" or "Water"
        local check = Explain(Check(cap, x, y, key), key)
        set[key] = check
        set[key .. "Box"] = NumberBox(parent, prefix .. cap .. "Min", check.label,
            function(text) return SetBreakMinutes(key, text) end, 3)
        set[key .. "Unit"] = Unit(set[key .. "Box"])
        set[key .. "Anywhere"] = Explain(Check(cap .. "Anywhere", x + 22, y - 24, nil,
            function(value) SetAnywhere(key, value) end), "anywhere")
        y = y - 54
    end
    y = y - 4
    set.howHeader = Header(x, y)
    set.sound = Explain(Check("Sound", x, y - 18, "sound"), "sound")
    y = y - 50
    set.remindLabel = parent:CreateFontString(prefix .. "RemindLabel", "OVERLAY", "GameFontHighlight")
    set.remindLabel:SetPoint("TOPLEFT", x + 4, y - 4)
    set.remindDefault = ns.CreateDropdown(parent, prefix .. "RemindDefault", 80, MinuteItems(
        function() return Settings().remindMin end,
        function(minutes) SetRemindDefault(minutes) end))
    set.remindDefault:SetPoint("LEFT", set.remindLabel, "RIGHT", 10, 0)
    y = y - 30
    set.test = CreateFrame("Button", prefix .. "Test", parent, "UIPanelButtonTemplate")
    set.test:SetSize(130, 22)
    set.test:SetPoint("TOPLEFT", x, y)
    set.test:SetScript("OnClick", function()
        Announce(string.format(T("warn_durab"), Settings().durabPct - 1), "test")
    end)
    set.history = CreateFrame("Button", prefix .. "OpenHistory", parent, "UIPanelButtonTemplate")
    set.history:SetSize(130, 22)
    set.history:SetPoint("LEFT", set.test, "RIGHT", 8, 0)
    set.history:SetScript("OnClick", function() Warnings.ToggleHistory() end)
    y = y - 40

    sets[#sets + 1] = set
    return set, math.min(bottom, y)
end

-- Faixa de explicação: o aviso sob o mouse; sem nada, como os avisos funcionam.
function Warnings.ShowInfo(set, key)
    set.infoKey = key
    if key then
        local name = key == "anywhere" and T("warn_opt_anywhere") or T("warn_name_" .. key)
        set.info:SetText("|cffffd100" .. name .. ":|r " .. T("warn_desc_" .. key))
    else
        set.info:SetText(ns.C.dim .. T("warn_hint") .. " " .. T("warn_hint_break") .. "|r")
    end
end

local function RefreshSet(set)
    local settings = Settings()
    set.gearHeader:SetText(T("warn_sec_gear"))
    set.charHeader:SetText(T("warn_sec_char"))
    set.breaksHeader:SetText(T("warn_sec_breaks"))
    set.questHeader:SetText(T("warn_sec_quests"))
    set.recommended:SetText(T("warn_recommended"))
    set.allOff:SetText(T("warn_all_off"))
    set.topHint:SetText(T("warn_top_hint"))
    Warnings.ShowInfo(set, set.infoKey)
    set.howHeader:SetText(T("warn_sec_how"))
    for _, key in ipairs({ "durab", "bags", "talents", "ranks", "prof", "restFull", "tasks", "goals", "questFull", "questReady", "hearthReady", "questValue", "questLevel", "sound" }) do
        set[key].label:SetText(T("warn_opt_" .. key))
        set[key]:SetChecked(settings[key])
    end
    set.durabUnit:SetText(T("warn_unit_pct"))
    set.bagsUnit:SetText(T("warn_unit_slots"))
    for _, kind in ipairs({ "ammo", "reag" }) do
        set[kind].label:SetText(T("warn_opt_" .. kind))
        set[kind]:SetChecked(settings[kind])
        set[kind .. "YellowLabel"]:SetText(T("warn_yellow"))
        set[kind .. "RedLabel"]:SetText(T("warn_red"))
        if not set[kind .. "YellowBox"]:HasFocus() then set[kind .. "YellowBox"]:SetText(tostring(settings[kind .. "Yellow"])) end
        if not set[kind .. "RedBox"]:HasFocus() then set[kind .. "RedBox"]:SetText(tostring(settings[kind .. "Red"])) end
    end
    for _, key in ipairs(BREAK_KEYS) do
        set[key].label:SetText(T("warn_opt_" .. key))
        set[key]:SetChecked(settings[key])
        set[key .. "Unit"]:SetText(T("warn_unit_min"))
        set[key .. "Anywhere"].label:SetText(T("warn_opt_anywhere"))
        set[key .. "Anywhere"]:SetChecked(settings[key .. "Anywhere"])
        if not set[key .. "Box"]:HasFocus() then set[key .. "Box"]:SetText(tostring(settings[key .. "Min"])) end
    end
    set.remindLabel:SetText(T("warn_opt_remind"))
    set.remindDefault:SetText(string.format(T("warn_minutes"), settings.remindMin))
    set.test:SetText(T("warn_opt_test"))
    set.history:SetText(T("opt_history"))
    if not set.durabBox:HasFocus() then set.durabBox:SetText(tostring(settings.durabPct)) end
    if not set.bagsBox:HasFocus() then set.bagsBox:SetText(tostring(settings.bagSlots)) end
    set.questUnit:SetText(T("warn_unit_quests"))
    if not set.questBox:HasFocus() then set.questBox:SetText(tostring(settings.questMin)) end
end

RefreshWindow = function()
    if not ns.GetDB() or not Settings() then return end
    for _, set in ipairs(sets) do RefreshSet(set) end
end
Warnings.RefreshControls = function() RefreshWindow() end

-- /farol aviso: abre o menu do Farol na aba "Avisos" (ou fecha, se já estiver nela).
function Warnings.ToggleWindow()
    if ns.OpenOptions then ns.OpenOptions("warnings") end
end

local function CreateHistoryWindow()
    local frame = CreateFrame("Frame", "FarolWarnHistory", UIParent, ns.backdropTemplate)
    frame:SetSize(520, 92 + HISTORY_MAX * 20)
    frame:SetPoint("CENTER", 0, 20)
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    if frame.SetBackdrop then
        frame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 },
        })
    end
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("TOP", 0, -18)
    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    frame.farolClose = close -- na Central fica escondido: o X da Central fecha tudo (3.31.2)
    close:SetPoint("TOPRIGHT", -6, -6)
    frame.empty = ns.Dim(frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight"))
    frame.empty:SetPoint("TOPLEFT", 24, -52)
    frame.rows = {}
    for i = 1, HISTORY_MAX do
        local row = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row:SetPoint("TOPLEFT", 22, -48 - (i - 1) * 20)
        row:SetWidth(476)
        row:SetJustifyH("LEFT")
        if row.SetWordWrap then row:SetWordWrap(false) end
        frame.rows[i] = row
    end
    frame.clear = CreateFrame("Button", "FarolWarnHistoryClear", frame, "UIPanelButtonTemplate")
    frame.clear:SetSize(150, 22) -- cabe "Apagar 10 avisos?"
    frame.clear:SetPoint("BOTTOMRIGHT", -24, 16)
    -- "Limpar": o 1º clique pergunta ("Apagar 10 avisos?"), o 2º apaga.
    frame.clear:SetScript("OnClick", function(self)
        local history = History()
        ns.ConfirmClick(self, #history, "hist_clear_ask", function()
            for i = #history, 1, -1 do history[i] = nil end
            Print(T("hist_cleared"))
            RefreshHistory()
        end)
    end)
    frame:SetScript("OnShow", function()
        unread = 0
        UpdateButton()
        RefreshHistory()
    end)
    -- Central do Farol (estilo detalhado, 3.31): resumo e linha do tempo por dia.
    frame.farolDetailSize = { 770, 486 }
    frame.farolDetail = function(on)
        local Kit = ns.Hub and ns.Hub.Kit
        if Kit then Kit.ShowPanels(frame, on) end
        if not on then
            frame.empty:ClearAllPoints(); frame.empty:SetPoint("TOPLEFT", 24, -52)
            frame.clear:ClearAllPoints(); frame.clear:SetPoint("BOTTOMRIGHT", -24, 16)
            for i, row in ipairs(frame.rows) do
                row:ClearAllPoints(); row:SetPoint("TOPLEFT", 22, -48 - (i - 1) * 20); row:SetWidth(476)
            end
        end
        RefreshHistory()
    end
    tinsert(UISpecialFrames, "FarolWarnHistory") -- ESC fecha
    ns.MakeToplevel(frame) -- abre na frente e vem para a frente ao clicar
    frame:Hide()
    return frame
end

RefreshHistory = function()
    if not historyWindow or not historyWindow:IsShown() then return end
    historyWindow.title:SetText(T("hist_title"))
    historyWindow.clear:SetText(T("hist_clear")); historyWindow.clear.farolAsk = nil
    local history = History()
    historyWindow.empty:SetText(T("hist_empty"))
    if #history == 0 then historyWindow.empty:Show() else historyWindow.empty:Hide() end
    for i, row in ipairs(historyWindow.rows) do
        local entry = history[#history - i + 1] -- mais novo primeiro
        if entry then
            local okd, when = pcall(date, "%d/%m %H:%M", entry.t)
            row:SetText("|cffaaaaaa" .. (okd and type(when) == "string" and when or "--") .. "|r  " .. entry.text)
            row:Show()
        else
            row:Hide()
        end
    end
    if historyWindow.farolDocked then HistoryDetail(historyWindow, history) end
end

-- Dia de uma data ("20261127"); nil se inválida.
local function DayKey(t)
    if type(t) ~= "number" or t ~= t then return nil end
    local ok, text = pcall(date, "%Y%m%d", t)
    return ok and text or nil
end

HistoryDetail = function(frame, history)
    local Kit = ns.Hub and ns.Hub.Kit
    if not Kit then return end
    local ok, now = pcall(time)
    if not ok or type(now) ~= "number" then now = nil end
    local today, yesterday = now and DayKey(now), now and DayKey(now - 86400)
    local sum = Kit.Panel(frame, "sum", 8, -6, 754, 70)
    sum.title:SetText(T("hist_sum")); sum.sub:SetText(T("hist_sum_sub"))
    local todayCount = 0
    for _, entry in ipairs(history) do if today and DayKey(entry.t) == today then todayCount = todayCount + 1 end end
    local newest = history[#history]
    local last = "--"
    if newest and now and type(newest.t) == "number" and now >= newest.t then
        local secs = math.max(60, now - newest.t)
        last = string.format(T("hist_ago"), ns.FormatDuration and ns.FormatDuration(secs) or tostring(secs))
    end
    Kit.Stat(frame, "sum1", 20, -30, 110, T("hist_stat_saved"), tostring(#history))
    Kit.Stat(frame, "sum2", 140, -30, 80, T("hist_stat_today"), tostring(todayCount))
    Kit.Stat(frame, "sum3", 230, -30, 200, T("hist_stat_last"), last)
    frame.clear:ClearAllPoints(); frame.clear:SetPoint("TOPRIGHT", -20, -36)
    local list = Kit.Panel(frame, "list", 8, -84, 754, 394)
    list.title:SetText(T("hist_title")); list.sub:SetText(T("hist_list_sub"))
    frame.empty:ClearAllPoints(); frame.empty:SetPoint("TOPLEFT", 22, -114)
    local y, lastDay = -112, nil
    for i, row in ipairs(frame.rows) do
        local entry = history[#history - i + 1]
        local head = Kit.Text(frame, "day" .. i, "GameFontNormalSmall", 22, y, 200)
        local at = ns.Dim(Kit.Text(frame, "at" .. i, "GameFontHighlightSmall", 30, y, 50))
        head:SetText(""); at:SetText("")
        if entry then
            local day = DayKey(entry.t)
            if day ~= lastDay then
                lastDay = day
                local label = (day and day == today and T("hist_today")) or (day and day == yesterday and T("hist_yesterday"))
                if not label then
                    local okd, text = pcall(date, "%d/%m", entry.t)
                    label = okd and text or "--"
                end
                head:SetText(label)
                y = y - 16
            end
            at:ClearAllPoints(); at:SetPoint("TOPLEFT", 30, y)
            local okt, hm = pcall(date, "%H:%M", entry.t)
            at:SetText(okt and hm or "--")
            row:ClearAllPoints(); row:SetPoint("TOPLEFT", 84, y); row:SetWidth(664)
            row:SetText(entry.text)
            y = y - 20
        end
    end
end

function Warnings.ToggleHistory()
    historyWindow = historyWindow or CreateHistoryWindow()
    if historyWindow:IsShown() then historyWindow:Hide() else historyWindow:Show() end
end

-- Usada pelo atalho de teclado definido em Bindings.xml.
function Farol_ToggleWarnHistory()
    if ns.GetDB() then Warnings.ToggleHistory() end
end
BINDING_HEADER_FAROL = "Farol"
BINDING_NAME_FAROL_WARN_HISTORY = "Últimos avisos / Recent warnings"

function Warnings.Refresh()
    RefreshHistory()
    UpdateButton()
    RefreshWindow()
end

---------------------------------------------------------------------------
-- Comandos: /farol aviso ...
---------------------------------------------------------------------------

local KEYS = {
    durab = "durab", dur = "durab", durabilidade = "durab", durability = "durab",
    bolsas = "bags", bolsa = "bags", bags = "bags", bag = "bags",
    som = "sound", sound = "sound",
    talentos = "talents", talento = "talents", talents = "talents", talent = "talents",
    graus = "ranks", grau = "ranks", ranks = "ranks", rank = "ranks",
    profissoes = "prof", profissao = "prof", prof = "prof", professions = "prof", profession = "prof",
    descansado = "restFull", xpdescansado = "restFull", rested = "restFull", restedxp = "restFull", -- "descanso" = pausa
    municao = "ammo", ammo = "ammo", flechas = "ammo", balas = "ammo",
    reagentes = "reag", reagente = "reag", reagents = "reag", reagent = "reag",
    pausa = "pause", pause = "pause", ["break"] = "pause", descanso = "pause",
    agua = "water", water = "water", hidratacao = "water", hydrate = "water",
    tarefas = "tasks", tarefa = "tasks", tasks = "tasks", task = "tasks",
    metas = "goals", meta = "goals", goals = "goals", goal = "goals",
    missoes = "questFull", diario = "questFull", quests = "questFull", questlog = "questFull",
    prontas = "questReady", entregar = "questReady", ready = "questReady", turnin = "questReady",
    regresso = "hearthReady", pedra = "hearthReady", hearth = "hearthReady", hearthstone = "hearthReady",
}
local FIGHTS = { lutas = true, luta = true, fights = true, fight = true, combate = true, combat = true }

-- Diagnóstico: mostra o que o addon consegue ler neste cliente.
local function PrintStatus()
    local points, source = UnspentTalents()
    if points then
        Print(string.format(T("warn_status_talents"), points, source))
    else
        Print(T("warn_status_notal"))
    end
    -- Detalhe de cada fonte (para diagnosticar clientes diferentes, como o WoW Forever).
    for _, entry in ipairs(TALENT_SOURCES) do
        local value, why = ReadSource(entry)
        Print(string.format("    %s: %s", entry[1], value and tostring(value) or (why or "-")))
    end
    if GetNumTalentTabs and GetTalentTabInfo then
        local ok, tabs = pcall(GetNumTalentTabs)
        local spent = {}
        for tab = 1, (ok and type(tabs) == "number" and tabs or 0) do
            local okTab, points = pcall(TabPointsSpent, tab)
            spent[#spent + 1] = okTab and tostring(points) or "erro"
        end
        Print(string.format("    GetTalentTabInfo: %s", table.concat(spent, " / ")))
    end
    local okLevel, level = pcall(UnitLevel, "player") -- leitura protegida (diagnóstico)
    Print(string.format("    UnitLevel: %s", okLevel and tostring(level) or "--"))
    local okRep, faction, repSource = pcall(ns.GetWatchedFaction)
    if okRep and faction then
        Print(string.format(T("rep_status"), (string.gsub(tostring(faction.name), "|", "||")), tostring(repSource)))
    else
        Print(T("rep_status_none"))
    end
    local okJunk, junk, junkSource = pcall(ns.GetJunk)
    if okJunk and junk then
        Print(string.format(T("junk_status"), PlainMoney(junk.total), junk.slots, tostring(junkSource or "--")))
    end
    if ns.GetSupplies then
        local okSup, list = pcall(ns.GetSupplies)
        if okSup and list and #list > 0 then
            local parts = {}
            for i, sup in ipairs(list) do parts[i] = T("sup_" .. sup.key) .. " " .. sup.count end
            Print(string.format(T("supply_status"), table.concat(parts, ", ")))
        else
            Print(T("supply_status_none"))
        end
    end
    if ns.ReadLockouts then
        local okLocks, locks = pcall(ns.ReadLockouts)
        Print(string.format(T("locks_status"), (okLocks and locks) and #locks or 0,
            (okLocks and locks) and "GetSavedInstanceInfo" or "--"))
    end
    local okProf, profs, profSource = pcall(ns.ReadProfessions)
    if okProf and profs and #profs > 0 then
        local parts = {}
        for i, p in ipairs(profs) do parts[i] = string.gsub(p.name, "|", "||") .. " " .. p.level .. "/" .. p.max end
        Print(string.format(T("prof_status"), table.concat(parts, ", "), tostring(profSource)))
    else
        Print(string.format(T("prof_status_none"), tostring(okProf and profSource or "--")))
    end
    local okReset, daily, weekly, dailySource, weeklySource = pcall(ns.GetResetTimes)
    if okReset then
        local function show(v) return v and string.format("%dh %02dm", math.floor(v / 3600), math.floor(v % 3600 / 60)) or "--" end
        Print(string.format(T("reset_status"), show(daily), tostring(dailySource or "--"),
            show(weekly), tostring(weeklySource or "--")))
    end
    if ns.Quests then
        local okQ, data = pcall(ns.Quests.Read)
        Print(string.format(T("quests_status"), (okQ and data) and (data.count .. "/" .. data.max) or "--",
            (okQ and data) and #data.ready or 0, ns.Quests.Source()))
    end
    do -- como o Farol identificou o personagem (nome e reino; o WoW Forever não informa o reino)
        local name, realm = ns.CurrentCharacter()
        Print(string.format(T("char_status"), name or "--",
            realm == ns.REALM_FALLBACK and T("realm_none") or (realm and ns.RealmLabel(realm) or "--")))
    end
    if ns.Completed then
        local okC, line = pcall(ns.Completed.StatusLine)
        if okC then Print(line) end
    end
    local ok, outdated = pcall(FindOutdatedSpells)
    outdated = ok and outdated or {}
    Print(string.format(T("warn_status_ranks"), #outdated))
    for i = 1, math.min(5, #outdated) do
        Print("  " .. string.format(T("warn_rank_item"), outdated[i].name, outdated[i].rank, outdated[i].best))
    end
end
local ON = { on = true, ligar = true, ativar = true, sim = true }
local OFF = { off = true, desligar = true, desativar = true, nao = true }

function Warnings.HandleCommand(rest)
    local word, value, extra = string.match(rest or "", "^%s*(%a*)%s*(%w*)%s*(%w*)")
    word, value, extra = string.lower(word or ""), string.lower(value or ""), string.lower(extra or "")
    local key = KEYS[word]
    if word == "" then
        Warnings.ToggleWindow()
    elseif word == "status" or word == "diagnostico" then
        PrintStatus()
    elseif word == "historico" or word == "history" then
        Warnings.ToggleHistory()
    elseif word == "silenciar" or word == "silence" then
        Warnings.Respond(false)
    elseif word == "lembrar" or word == "remind" then
        if value ~= "" and not ValidRemind(value) then Print(T("warn_bad_remind")) return end
        Warnings.Respond(true, nil, value)
    elseif word == "recomendados" or word == "recommended" then
        Warnings.SetAll(true)                         -- /farol aviso recomendados
    elseif word == "nenhum" or word == "none" then
        Warnings.SetAll(false)                        -- /farol aviso nenhum
    elseif word == "padrao" or word == "default" then
        SetRemindDefault(value)                       -- /farol aviso padrao 10
    elseif not key then
        Print(T("warn_usage"))
    elseif ON[value] then
        SetEnabled(key, true)
    elseif OFF[value] then
        SetEnabled(key, false)
    elseif key == "durab" and value ~= "" then
        SetDurabPct(value)
    elseif key == "bags" and value ~= "" then
        SetBagSlots(value)
    elseif key == "questFull" and value ~= "" then
        SetQuestMin(value)                             -- /farol aviso missoes 18
    elseif (key == "ammo" or key == "reag") and value ~= "" then
        SetSupplyLimits(key, value, extra)              -- /farol aviso municao 400 200
    elseif IsBreak(key) and FIGHTS[value] and (ON[extra] or OFF[extra]) then
        SetAnywhere(key, ON[extra] and true or false)  -- /farol aviso pausa lutas on
    elseif IsBreak(key) and value ~= "" then
        SetBreakMinutes(key, value)                    -- /farol aviso agua 30
    else
        Print(T("warn_usage"))
    end
end
