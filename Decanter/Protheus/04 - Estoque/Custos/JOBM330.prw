#include 'protheus.ch'
#include 'parmtype.ch'
#include "tbiconn.ch"
/*/{Protheus.doc} JOBM330

JOB de processamento do custo custo 

@author TSC679 - CHARLES REITZ
@since 20/09/2019
@version undefined

@return return, return_description
@example
(examples)
@see (links_or_references)
/*/
User Function JOBM330(aParamSchd)
	//{'01','01','01','01','000000','000009000001'}
	Local lCPParte := .F. //-- Define que não será processado o custo em partes
	Local lBat := .T. //-- Define que a rotina será executada em Batch
	Local aListaFil := {} //-- Carrega Lista com as Filiais a serem processadas
	Local cCodFil := ' ' //-- Código da Filial a ser processada
	Local cNomFil := ' ' //-- Nome da Filial a ser processada
	Local cCGC := '' //-- CGC da filial a ser processada
	Local aParAuto := {} //-- Carrega a lista com os 21 parâmetros
	Local cLogServer	:=	""
	Local cTimeIni		:= Time()
	Local nTimeIni		:= Seconds()



	nTimeFim		:= Seconds()
	cLogServer += "============================================================================"+ chr(13)+chr(10)
	cLogServer += "INICIANDO JOB DE PROCESSAMENTO DO CUSTO MÉDIO  MATA330  - JOBM330 - "+Time() + chr(13)+chr(10)


	PREPARE ENVIRONMENT EMPRESA aParamSchd[1] FILIAL aParamSchd[2] MODULO "EST"
	cLogServer += "Tempo Execucao: " + SecsToTime(nTimeFim - nTimeIni) + chr(13)+chr(10)

	cLogServer += SM0->M0_CODIGO +"/"+SM0->M0_CODFIL+" - DataBase:"+dtoc(date())+ chr(13)+chr(10)
	cLogServer += "============================================================================"+ chr(13)+chr(10)

	FwLogMsg('INFO',; 	// cSeverity
	,;					//cTransactionId
	'',;				//cGroup
	FunName(),;			//cCategory
	'',;				//cStep
	"",;				//cMsgId
	cLogServer,;		//cMessage
	0,;					//nMensure
	0,;					//nElapseTime
	{})					//aMessage


	If (cValToChar(day(date())) $ GetMv("AV_CUSDIAS",,"1/2/3/5"))
		cLogServer	:="Não executada, conforme definido no paramêtro de dias - AV_CUSDIAS"
		FwLogMsg('INFO',; 	// cSeverity
		,;					//cTransactionId
		'',;				//cGroup
		FunName(),;			//cCategory
		'',;				//cStep
		"",;				//cMsgId
		cLogServer,;		//cMessage
		0,;					//nMensure
		0,;					//nElapseTime
		{})					//aMessage
	Else

		//-- Adiciona filial a ser processada

		aParAuto	:= {date(),; //mv_par01 - data final
		2, ; //mv_par02 - mostra lançamentos - não
		1, ;//mv_par03 - aglutina sim
		1,;//mv_par04 - atualiza mov sim
		0,;//mv_par05 - aumento mod
		2,;//mv_par06 - centro de custo - extracontabil
		"",;//mv_par07 - conta a inibir inicial
		"",;//mv_par08 - conta a inibir final
		1,;//mv_par09 - apaga estorno sim
		3,;//mv_par10 - gera lancto mantém lançamento
		1,;//mv_par11 - gera estrutura mvto sim
		3,;//mv_par12 - contabiliza por - ambas
		2,;//mv_par13 - cacula mod não
		2,;//mv_par14 - metodo de apropriacao - mensal
		1,;//mv_par15 - recalcula niveis - sim
		1,;//mv_par16 - mostra sequencia - não mostrar
		2,;//mv_par17 - sequencia fifo - custo medio
		1,;//mv_par18 - mvto valorizado - antes
		2,;//mv_par19 - recalcula custo transporte -não
		1,;//mv_par20 - calculo por - todas filiais
		2}//mv_par21 - calcula custo em partes - não

		dbSelectArea("SM0")
		dbSeek(cEmpAnt)
		Do While ! Eof() .And. SM0->M0_CODIGO == cEmpAnt
			cCodFil := SM0->M0_CODFIL
			cNomFil := SM0->M0_FILIAL
			cCGC := SM0->M0_CGC
			//-- Adiciona a filial na lista de filiais a serem processadas
			Aadd(aListaFil,{.T.,cCodFil,cNomFil,cCGC,.F.,})
			dbSkip()
		EndDo


		//-- Executa a rotina de recálculo do custo médio
		MSExecAuto({|x,y,z,w| mata330(x,y,z,w)},lBat,aListaFil,lCPParte,aParAuto)
		
	EndIf
	nTimeFim		:= Seconds()
	cLogServer := "*Tempo Total Processamento: " + SecsToTime(nTimeFim - nTimeIni) + chr(13)+chr(10)
	FwLogMsg('INFO',; 	// cSeverity
		,;					//cTransactionId
		'',;				//cGroup
		FunName(),;			//cCategory
		'',;				//cStep
		"",;				//cMsgId
		cLogServer,;		//cMessage
		0,;					//nMensure
		0,;					//nElapseTime
		{})					//aMessage
	RESET ENVIRONMENT


Return
/*
Static Function Scheddef()

	Local aParam
	Local aOrd     := {}
	aParam := { "P",;                      //Tipo R para relatorio P para processo
	"",;// Pergunte do relatorio, caso nao use passar ParamDef
	"",;  // Alias
	aOrd,;   //Array de ordens
	""}

Return aParam*/
