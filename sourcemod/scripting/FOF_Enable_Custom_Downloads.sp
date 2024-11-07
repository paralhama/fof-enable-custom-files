#include <sourcemod>
#include <sdktools>
#include <morecolors>
#include <adminmenu> 

public Plugin:myinfo =
{
	name = "Enable Custom Downloads",
	author = "Paralhama",
	description = "Enable custom files and detects error terms in chat, sending correction tips to players.",
	version = "1.0",
	url = ""
}

bool Checked[MAXPLAYERS+1] = {false, ...};
bool ModifiedCommands[MAXPLAYERS+1] = {false, ...};
bool QuitExecuted[MAXPLAYERS+1] = {false, ...};
int TimerPlayer[MAXPLAYERS+1];
Handle ClientTimers[MAXPLAYERS+1];  // Armazena o handle do timer de cada cliente
bool fof_skins_is_load = false;

public void OnAllPluginsLoaded()
{
    // Verifica se o plugin de zombies está carregado
    if (FindPluginByFile("fof_skins.smx") != null)
    {
        fof_skins_is_load = true;
    }
}

// Array para armazenar os termos a serem detectados no chat
new const String:g_TermsError[][] = 
{
	"skins",
	"preto e roxo",
	"roxo e preto",
	"erro",
	"modelo",
	"model",
	"textura",
	"material",
	"bug",
	"bugado",
	"quebrado",
	"glitched",
	"con fallos",
	"con errores",
	"черный и фиолетовый",    // preto e roxo (russo)
	"фиолетовый и черный",      // roxo e preto (russo)
	"ошибка",                   // erro (russo)
	"модель",                   // modelo (russo)
	"текстура",                 // textura (russo)
	"материал",                 // material (russo)
	"баг",                      // bug (russo)
	"сбой",                     // bugado (russo)
	"сломанный",                // quebrado (russo)
	"глюк",                     // glitched (russo)
	"schwarz und lila",         // preto e roxo (alemão)
	"lila und schwarz",         // roxo e preto (alemão)
	"fehler",                   // erro (alemão)
	"modell",                   // modelo (alemão)
	"texture",                  // textura (alemão)
	"buggy",                    // bugado (alemão)
	"kaputt",                   // quebrado (alemão)
	"glitschig",                // glitched (alemão)
	"nero e viola",             // preto e roxo (italiano)
	"viola e nero",             // roxo e preto (italiano)
	"errore",                   // erro (italiano)
	"modello",                  // modelo (italiano)
	"materiale",                // material (italiano)
	"difettoso",                // bugado (italiano)
	"rotto",                    // quebrado (italiano)
	"glitchato",                // glitched (italiano)
	"noir et violet",           // preto e roxo (francês)
	"violet et noir",           // roxo e preto (francês)
	"erreur",                   // erro (francês)
	"modèle",                   // modelo (francês)
	"matériau",                 // material (francês)
	"bugué",                    // bugado (francês)
	"cassé",                    // quebrado (francês)
	"negro y púrpura",         // preto e roxo (espanhol)
	"púrpura y negro",         // roxo e preto (espanhol)
	"roto",                     // quebrado (espanhol)
	"glitcheado"                // glitched (espanhol)
};

public void OnPluginStart()
{
	// Registrar comandos de chat
	RegConsoleCmd("say", OnSay);
	RegConsoleCmd("say_team", OnSay);

	LoadTranslations("FOF_Enable_Custom_Downloads.phrases");

	AddCommandListener(Command_Jointeam, "jointeam");
	AddCommandListener(Command_Jointeam, "autojoin");
	AddCommandListener(Command_Jointeam, "chooseteam");

}

public Action Command_Jointeam(int client, const char[] command, int args)
{
	if (ModifiedCommands[client] && !QuitExecuted[client])
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}


public OnClientPutInServer(client)
{
	ClientCommand(client, "cl_allowdownload 1;fof_hide_vote_menu 0");
	QueryClientConVar(client, "cl_downloadfilter", DownloadsConvarResponse);
	
	if (ModifiedCommands[client])
	{
		CreateTimer(0.5, ShowHiddenMOTD, client, TIMER_FLAG_NO_MAPCHANGE);
		ClientCommand(client, "spectator");
		ClientCommand(client, "cl_downloadfilter all;cl_allowdownload 1;fof_hide_vote_menu 0");
		TimerPlayer[client] = 20;
		Client_ScreenFade(client);
		ClientTimers[client] = CreateTimer(1.0, ForceQuit, client, TIMER_REPEAT);
	}
}

public Action ShowHiddenMOTD(Handle timer, int client)
{
	if(IsClientInGame(client) && IsClientConnected(client))
	{
		Handle kv = CreateKeyValues("data");
		KvSetString(kv, "msg", "about:blank");
		KvSetString(kv, "title", "adverts");
		KvSetNum(kv, "type", MOTDPANEL_TYPE_URL);
		ShowVGUIPanel(client, "info", kv, false); // last arugment of false, hides the panel
		CloseHandle(kv);
	}

	return Plugin_Stop;
}

public DownloadsConvarResponse(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[])
{   
	if(StrEqual(cvarName, "cl_downloadfilter", false))
	{
		if(!StrEqual(cvarValue, "all", false))
		{
			//ClientTimers[client] = CreateTimer(1.0, ForceQuit, client, TIMER_REPEAT);
			CreateTimer(0.01, ChangeCommands, client, TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			Checked[client] = true;
		}
	}
} 

Action ChangeCommands(Handle timer, any client)
{
	if (IsClientInGame(client) && IsClientConnected(client) && !IsFakeClient(client))
	{
		ModifiedCommands[client] = true;
		ClientCommand(client, "cl_downloadfilter all;cl_allowdownload 1;fof_hide_vote_menu 0;retry");
	}
	return Plugin_Continue;
}

Action ForceQuit(Handle timer, int client)
{
	// Apenas contar o timer se o cliente estiver no jogo e conectado
	if (IsClientInGame(client) && IsClientConnected(client) && TimerPlayer[client] > 0)
	{
		// Mostrar a contagem no HUD
		TimerPlayer[client] -= 1;
		if (TimerPlayer[client] % 2 == 0)
		{
			SetHudTextParams(0.02, 0.4, 99999.0, 0, 255, 17, 0, 0, 0.0, 0.0, 0.0);
		}
		else
		{
			SetHudTextParams(0.02, 0.4, 99999.0, 255, 255, 255, 0, 0, 0.0, 0.0, 0.0);
		}
		// Criar uma string com dois dígitos para o timer
		char timerString[3];
		Format(timerString, sizeof(timerString), "%02d", TimerPlayer[client]);

		// Mostrar a string do Timer no HUD
		ShowHudText(client, 6, "%t", "GAME_WILL_CLOSE", timerString);

		if (TimerPlayer[client] == 0)
		{
			ShowHudText(client, 0, "");
			// Reinicia o jogador quando o Timer chega a 0
			ClientCommand(client, "quit");
			ModifiedCommands[client] = false;
			QuitExecuted[client] = true;
			// Mata o timer quando a contagem chega a 0
			KillTimer(ClientTimers[client]);
			ClientTimers[client] = INVALID_HANDLE;
			return Plugin_Handled;
		}
	}
	// Se o cliente sair do jogo, a contagem para
	else if (!IsClientConnected(client) || !IsClientInGame(client))
	{
		KillTimer(ClientTimers[client]);
		ClientTimers[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

stock bool Client_ScreenFade(int client, bool reliable=true)
{
    int duration = 0xFFFF; // Duração máxima (indeterminado)
    int holdtime = -1;     // Tempo de espera indefinido (pode ser ignorado dependendo do engine)
    int mode = 0;          // Modo (pode ajustar flags conforme necessário)
    int r = 0, g = 0, b = 0; // Preto (RGB = 0, 0, 0)
    int a = 255;           // Totalmente opaco (Alpha = 255)

    Handle userMessage = StartMessageOne("Fade", client, (reliable ? USERMSG_RELIABLE : 0));

    if (userMessage == INVALID_HANDLE) {
        return false;
    }

    if (GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available &&
        GetUserMessageType() == UM_Protobuf) {

        int color[4];
        color[0] = r;
        color[1] = g;
        color[2] = b;
        color[3] = a;

        PbSetInt(userMessage,   "duration",   duration);
        PbSetInt(userMessage,   "hold_time",  holdtime);
        PbSetInt(userMessage,   "flags",      mode);
        PbSetColor(userMessage, "clr",        color);
    }
    else {
        BfWriteShort(userMessage,    duration);   // Fade duration (indeterminado)
        BfWriteShort(userMessage,    holdtime);   // Fade hold time (indeterminado)
        BfWriteShort(userMessage,    mode);       // What to do
        BfWriteByte(userMessage,     r);          // Color R (0 = preto)
        BfWriteByte(userMessage,     g);          // Color G (0 = preto)
        BfWriteByte(userMessage,     b);          // Color B (0 = preto)
        BfWriteByte(userMessage,     a);          // Color Alpha (255 = opaco)
    }
    EndMessage();

    return true;
}


// ####### Detecta palavras no chat relacionadas a erros gráficos e envia uma mensagem #############################

public Action:OnSay(client, args)
{
    // Declaração da variável para armazenar a mensagem do chat
    decl String:mensagem[512];
    GetCmdArgString(mensagem, sizeof(mensagem));

    // Primeiro verifica se a mensagem contém "!skins" - se contiver, ignora
    if (StrContains(mensagem, "!skins", false) != -1)
    {
        return Plugin_Continue;
    }

    // Verifica se o cliente é admin
    if (CheckCommandAccess(client, "generic_admin", ADMFLAG_GENERIC, false))
        return Plugin_Continue;

    // Verificar cada termo da lista g_TermsError
    for (new i = 0; i < sizeof(g_TermsError); i++)
    {
        if (StrContains(mensagem, g_TermsError[i], false) != -1)
        {
            // Criar um temporizador para exibir a mensagem 1 segundo depois
            CreateTimer(0.1, Timer_EnviarMensagem, GetClientUserId(client));
            break;
        }
    }
    
    return Plugin_Continue;
}

// Função chamada pelo temporizador após 1 segundo
public Action:Timer_EnviarMensagem(Handle:timer, any:userId)
{
    // Verifica se o cliente ainda está conectado
    new client = GetClientOfUserId(userId);
    if (client > 0 && IsClientInGame(client))
    {
        // Buffer para armazenar o nome do jogador
        new String:PlayerName[256];  // Corrigido para String

        // Obtém o nome do jogador
        GetClientName(client, PlayerName, sizeof(PlayerName));

        // Envia a mensagem ao jogador
        CPrintToChatAll("{black}████{yellow}████{black}████{yellow}████{black}████{yellow}████{black}████{yellow}████{black}████");
        if (fof_skins_is_load)
		{
			CPrintToChatAll("%t", "chat_msg_error_with_skins", PlayerName);
        }
		else
		{
			CPrintToChatAll("%t", "chat_msg_error_without_skins", PlayerName);
		}
        CPrintToChatAll("{black}████{yellow}████{black}████{yellow}████{black}████{yellow}████{black}████{yellow}████{black}████");
    }

    return Plugin_Stop;
}
