#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} MLFATA06
// Função para cadastrar os tipos de Status do pedido de venda. 
@author Marcelo Alberto Lauschner
@since 09/10/2019
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User function MLFATA06(cInAlias,nInRecno,nInOpcRot,nInXOpc)
	
	
	Default nInXOpc 		:= 1
	
	If nInXOpc == 2 
		sfCad()
		Return 
	ElseIf nInXOpc == 3 
		sfAlt()
		Return 
	Endif 
	Private	cFilAtu		:= xFilial("SX5")
	Private cCadastro 	:= "Cadastro de Status de Pedidos "
	Private aRotina 	

	
	aRotina 	:= {{"Pesquisar","AxPesqui",0,1} ,;
	{"Visualizar","AxVisual",0,2}}
	// determinados usuários poderão fazer os cadastros / dulci/marcelo/rafael/admin
	If __cUserId $ GetNewPar("ML_FATA06A","000008#000016#000002#000000")
		Aadd(aRotina,{"Incluir","U_MLFATA06(,,,2)",0,3})
		Aadd(aRotina,{"Alterar","U_MLFATA06(,,,3)",0,4})
		Aadd(aRotina,{ "Exlcuir", "AxDeleta", 0, 5})
	Endif
	
	dbSelectArea("SX5")
	Set Filter To  X5_FILIAL == cFilAtu .And. X5_TABELA == "XA"
	mBrowse(06, 01, 22, 75, "SX5")

	dbSelectArea("SX5")
	Set Filter To 

Return 


/*/{Protheus.doc} sfCadTpOp
// Inclusão de Código de Tipo de Operação.
@author Marcelo Alberto Lauschner
@since 15/07/2019
@version 1.0
@return 
@type Static Function
/*/
Static Function sfCad()

	Local	aAreaOld	:= GetArea()
	Local	nOpca		:= 0

	DbSelectArea("SX5")
	DbSetOrder(1)

	Private cCodTpOp	:= Padr(" ",TamSX3("C5_ZSTATS")[1])
	Private	cDescTpOp	:= Padr(" ",Len(SX5->X5_DESCRI))

	DEFINE MSDIALOG oDlgVlr FROM 069,070 TO 210,530  Of oMainWnd TITLE OemToAnsi("Inclusão - Cadastro de Tipos de Status de Pedidos") PIXEL  
	@ 001, 002 TO 052, 228 OF oDlgVlr  PIXEL
	@ 011, 009 SAY OemToAnsi("Código")  SIZE 54, 7 OF oDlgVlr PIXEL  
	@ 010, 068 MSGET cCodTpOp Picture "@!" SIZE 54, 10 Valid sfVldTpOp() OF oDlgVlr Hasbutton PIXEL 

	@ 025, 009 SAY OemToAnsi("Descrição Tipo Status")  SIZE 54, 7 OF oDlgVlr PIXEL  
	@ 024, 068 MSGET cDescTpOp Picture "@!" SIZE 154, 10  OF oDlgVlr Hasbutton PIXEL 

	DEFINE SBUTTON FROM 54, 71 TYPE 1 ENABLE ACTION (nOpca := 1,oDlgVlr:End()) OF oDlgVlr
	DEFINE SBUTTON FROM 54, 99 TYPE 2 ENABLE ACTION (oDlgVlr:End()) OF oDlgVlr

	Activate MsDialog oDlgVlr Centered

	If nOpca == 1
		sfGrava()
	Endif


	RestArea(aAreaOld)
Return



/*/{Protheus.doc} sfAltTpOp
// Alteração de Tipos de Operação 
@author Marcelo Alberto Lauschner
@since 15/07/2019
@version 1.0
@return 
@type Static Function
/*/
Static Function sfAlt()

	Local	aAreaOld	:= GetArea()
	Local	nOpca		:= 0

	DbSelectArea("SX5")
	DbSetOrder(1)

	Private cCodTpOp	:= Padr(SX5->X5_CHAVE,TamSX3("C5_ZSTATS")[1])
	Private	cDescTpOp	:= Padr(SX5->X5_DESCRI,Len(SX5->X5_DESCRI))

	DEFINE MSDIALOG oDlgVlr FROM 069,070 TO 210,530  Of oMainWnd TITLE OemToAnsi("Alteração - Cadastro de Tipos de Status de Pedido") PIXEL  
	@ 001, 002 TO 052, 228 OF oDlgVlr  PIXEL
	@ 011, 009 SAY OemToAnsi("Código")  SIZE 54, 7 OF oDlgVlr PIXEL  
	@ 010, 068 MSGET cCodTpOp Picture "@!" SIZE 54, 10  OF oDlgVlr Hasbutton PIXEL When .F.  

	@ 025, 009 SAY OemToAnsi("Descrição Tipo Status")  SIZE 54, 7 OF oDlgVlr PIXEL  
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
	Local	lRet		:= .T.

	DbSelectArea("SX5")
	DbSetOrder(1)
	If DbSeek(xFilial("SX5")+ "XA" + cCodTpOp )	
		lRet	:= .F. 
		MsgInfo("Código de Tipo de Status já cadastrado!")
	Endif
	RestArea(aAreaOld)

Return  lRet


/*/{Protheus.doc} sfGrava
//Função para gravação do novo Tipo de Operação
@author Marcelo Alberto Lauschner
@since 29/05/2018
@version 1.0
@return 
@type Static Function
/*/
Static Function sfGrava()

	// Garante que não gere duplicidade se eventualmente feito por outra estação. 
	DbSelectArea("SX5")
	DbSetOrder(1)
	If DbSeek(xFilial("SX5")+ "XA" + cCodTpOp )
		SX5->X5_DESCRI		:= cDescTpOp
		SX5->X5_DESCSPA		:= cDescTpOp
		SX5->X5_DESCENG		:= cDescTpOp
	Else	
		DbSelectArea("SX5")
		RecLock("SX5",.T.)
		SX5->X5_FILIAL		:= xFilial("SX5")
		SX5->X5_TABELA		:= "XA"
		SX5->X5_CHAVE		:= cCodTpOp
		SX5->X5_DESCRI		:= cDescTpOp
		SX5->X5_DESCSPA		:= cDescTpOp
		SX5->X5_DESCENG		:= cDescTpOp
		MsUnlock()
	Endif
Return 
