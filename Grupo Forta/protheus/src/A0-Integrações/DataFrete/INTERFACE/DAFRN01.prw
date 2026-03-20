#INCLUDE 'TOTVS.ch'
#INCLUDE 'FWMVCDef.ch'
#Include 'TbiConn.ch'
#include "TOPCONN.ch"


/*/{Protheus.doc} BVIN01
    (Rotina de Monitoramento de Logs da Integração)
    @type  User Function
    @author William.Souza
    @since 03/04/2023
    @version 1.0
/*/
User function DAFRN01()

	Local aArea   := FWGetArea()
	Local oBrowse
	Private aRotina := {}
	Private cCadastro := "Monitor de Log de Integração"

	DbSelectArea('P01')
	P01->(DbSetOrder(1))

	//Definicao do menu
	aRotina := MenuDef()

	//Instanciando o browse
	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias("P01")
	oBrowse:SetDescription(cCadastro)
	oBrowse:AddLegend( "P01->P01_STATUS=='0'", "WHITE" , "Aguardando processamento"   )
	oBrowse:AddLegend( "P01->P01_STATUS=='1'", "GREEN" , "Processada com Sucesso"   )
	oBrowse:AddLegend( "P01->P01_STATUS=='2'", "RED"   , "Falha no processamento" )
	oBrowse:DisableDetails()

	//Ativa a Browse
	oBrowse:Activate()

	FWRestArea(aArea)


Return NIL

//-------------------------------------------------------------------
Static Function MenuDef()
	Local aRotina := {}

	//Adicionando opcoes do menu
	aAdd(aRotina, {"Pesquisar"         , "AXPESQUI", 0, 1})
	aAdd(aRotina, {"Visualizar"        , "AXVISUAL", 0, 2})
	aAdd(aRotina, {"Reprocessa"        , "U_DTProc", 0, 3})
	aAdd(aRotina, {"Gera  NF/Datafrete", "U_DTProcP1", 0, 3})
	aAdd(aRotina, {"Envia NF/Datafrete", "U_DTProcNF", 0, 3})
	aAdd(aRotina, {"Excluir Registro"  , "U_BVProcDel", 0, 3})
	aAdd(aRotina, {"Legenda", "U_BVleg", 0, 2})

Return aRotina


//-------------------------------------------------------------------



User Function BVleg()
	Local aLegenda := {}

	//Monta as legendas (Cor, Legenda)
	aAdd(aLegenda,{"BR_VERDE"   ,     "Processada com Sucesso"})
	aAdd(aLegenda,{"BR_VERMELHO",     "Falha no processamento"})
	aAdd(aLegenda,{"BR_BRANCO"  ,     "Aguardando processamento"})


	//Chama a função que monta a tela de legenda
	BrwLegenda("Status de Processamento", "Status", aLegenda)
Return

/*/{Protheus.doc} Reprocessar
    (Reprocessamento de integração de WS)
    @type  Static Function
    @author William.Souza
    @since 03/04/2023
    @version 1.0
/*/

User Function DTProc()
	FWMsgRun(,{|| U_BVPROC() },,"Reprocessando Integração..." )
Return

User Function DTProcNF()
	FWMsgRun(,{|| U_DTJOB02A("WSDTNF") },,"Enviando Notas ao Datafrete..." )
Return

User Function DTProcP1()
	tcsqlexec("UPDATE "+RETSQLNAME("SF2")+" SET F2_XDFRETE = ' '")
	FWMsgRun(,{|| u_DTJOB001() },,"Gerando Notas Fiscais - Tabela P01" )
Return

User function BVproc()

	tcsqlexec("UPDATE "+RETSQLNAME("P01")+" SET P01_STATUS = '0', P01_DATPRO = ' ', P01_HORPRO = ' ' WHERE P01_STATUS = '2'")

	MsgAlert("Registro liberados para reprocessar", "Reprocessamento")
Return

User Function BVProcDel()
	IF P01->P01_STATUS $ '0|2'
		If MsgYesNo("Deseja remover o registro atual da tabela P01", "Confirma?")
			tcsqlexec("UPDATE "+RETSQLNAME("P01")+" SET D_E_L_E_T_ = '*', R_E_C_D_E_L_ = R_E_C_N_O_ WHERE P01_ID = '"+P01->P01_ID+"'")

			If MsgYesNo("Deseja remover a flag de geração da NF->DataFrete?", "Confirma?")
				tcsqlexec("UPDATE "+RETSQLNAME("SF2")+" SET F2_XDFID = ' ', F2_XDFRETE WHERE F2_XDFID  = '"+P01->P01_ID+"'")
			EndIF
		EndIF
	ELSE
		MsgInfo("Ação não permitida", "Exclusão de Registro")
	Endif

Return

