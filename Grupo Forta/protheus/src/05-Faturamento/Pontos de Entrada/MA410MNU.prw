#include 'protheus.ch'

/*/{Protheus.doc} MA410MNU
Ponto de entrada na tela de pedido de venda para adicionar outras acoes
no browser da tela

@author VM-TOTVS
@since 02/08/2019
@version undefined
@return return, return_description
@example
(examples)
@see (links_or_references)
/*/
User function MA410MNU()

	aAdd(aRotina,{"Alterar Pedido *"	,"VIEWDEF.CALA026"	, 0 , 4,0,NIL})//4-Alteracao
	aAdd(aRotina,{"Contrato Vendor *"	,"U_FORTR001"		, 0 , 4,0,NIL})
	aAdd(aRotina,{"Espelho Pedido"		,"U_MLFATR01"		, 0 , 2,0,NIL}) 
	aAdd(aRotina,{"Log do Pedido"		,"U_MLFATP02"		, 0 , 2,0,NIL}) 
	aAdd(aRotina,{"Status Pedido"		,"U_MLFATP01"		, 0 , 2,0,NIL}) 
	
	aAdd(aRotina,{"Ver Itens Pedido"	,"U_MLFATC07"		, 0 , 4,0,NIL})
	aAdd(aRotina,{"Remanejar Estoque"	,"U_MLFATA07"		, 0 , 3,0,NIL})
	
	aAdd(aRotina,{"WF Cotação"			,"U_MLFATW01"		, 0 , 4,0,NIL})
	
	// Permite desativar e controlar quais usuários terão integração com B2E 
	If RetCodUsr() $ GetNewPar("GF_IDINB2E", RetCodUsr()) 
		aAdd(aRotina,{"Integrar B2E"		,"U_MLFINM05"		, 0 , 4,0,NIL})
	Endif 
Return nil


/*/{Protheus.doc} MLFATP02
// Consulta Log do Pedido
@author Marcelo Alberto Lauschner
@since 21/08/2019
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function MLFATP02()

	Local 	aAreaOld	:= GetArea()
	
	dbSelectArea("SZ0")
	dbSetOrder(1)
	Set Filter To Z0_PEDIDO == SC5->C5_NUM  .And. Z0_FILIAL == SC5->C5_FILIAL 
	
	AxCadastro("SZ0","Historico e Logs de Pedido",".F.",".F.")
	
	dbSelectArea("SZ0")
	dbSetOrder(1)
	Set Filter to 
	
	RestArea(aAreaOld) 
	
Return 

User Function MLFATP01(cInCod,cInDescAux)

	Local	aAreaOld	:= GetArea()
	Local	nOpca		:= 0
	Default	cInCod		:= ""
	Default cInDescAux 	:= ""

	DbSelectArea("SX5")
	DbSetOrder(1)

	Private cCodTpOp	:= Padr(cInCod,TamSX3("C5_ZSTATS")[1])
	Private	cDescTpOp	:= Padr(cInDescAux,500)

	DEFINE MSDIALOG oDlgVlr FROM 069,070 TO 210,530  Of oMainWnd TITLE OemToAnsi("Inclusão - Cadastro de Tipos de Status de Pedidos") PIXEL  
	@ 001, 002 TO 052, 228 OF oDlgVlr  PIXEL
	@ 011, 009 SAY OemToAnsi("Código")  SIZE 54, 7  OF oDlgVlr PIXEL  
	@ 010, 068 MSGET cCodTpOp Picture "@!" SIZE 54, 10 Valid sfVldTpOp() F3 "XA"  OF oDlgVlr Hasbutton PIXEL 

	@ 025, 009 SAY OemToAnsi("Observação s/ Status")  SIZE 54, 7 OF oDlgVlr PIXEL  
	@ 024, 068 MSGET cDescTpOp Picture "@!" SIZE 154, 10  OF oDlgVlr Hasbutton PIXEL 

	DEFINE SBUTTON FROM 54, 71 TYPE 1 ENABLE ACTION (nOpca := 1,oDlgVlr:End()) OF oDlgVlr
	DEFINE SBUTTON FROM 54, 99 TYPE 2 ENABLE ACTION (oDlgVlr:End()) OF oDlgVlr

	Activate MsDialog oDlgVlr Centered

	If nOpca == 1
		sfGrava()
	Endif


	RestArea(aAreaOld)
Return



/*/{Protheus.doc} sfVldTpOp
// Validação do código de Tipo de Operação
@author Marcelo Alberto Lauschner
@since 15/07/2019
@version 1.0
@return lRet,Logical
@type Static Function
/*/
Static Function sfVldTpOp()

	Local	aAreaOld	:= GetArea() 
	Local	lRet		:= .F. 

	DbSelectArea("SX5")
	DbSetOrder(1)
	If DbSeek(xFilial("SX5")+ "XA" + cCodTpOp )	
		lRet	:= .T. 
	Else
		MsgInfo("Código de Tipo de Status não existe!")
	Endif
	RestArea(aAreaOld)

Return  lRet

Static Function sfGrava()
	
	DbSelectArea("SC5")
	RecLock("SC5",.F.)
	SC5->C5_ZSTATS 	:= cCodTpOp
	MsUnlock()
	// Grava Log		
	U_MLCFGM01("ST",SC5->C5_NUM,cDescTpOp,FunName())
	
Return 
	