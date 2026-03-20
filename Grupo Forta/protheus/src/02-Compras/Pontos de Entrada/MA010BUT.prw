#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} MA010BUT
//Ponto de entrada no cadastro de Produtos para adicionar novos botões 
@author Marcelo Alberto Lauschner
@since 29/05/2018
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User function MA010BUT()

	Local	aButton	:= {}

	Aadd(aButton,{"VERDE"		,{|| sfCadServ()}  ,"Cadastro Serviços"})
	

Return aButton


/*/{Protheus.doc} sfCadServ
//Dialog para informar o código e descrição do serviço a ser cadastrado
@author Marcelo Alberto Lauschner
@since 29/05/2018
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
Static Function sfCadServ()
	Local	aAreaOld	:= GetArea()
	Local	nOpca		:= 0

	DbSelectArea("SX5")
	DbSetOrder(1)

	Private cCodServ	:= Padr(M->B1_CODISS,4)
	Private	cDescServ	:= Padr(" ",Len(SX5->X5_DESCRI))

	DEFINE MSDIALOG oDlgVlr FROM 069,070 TO 210,530  Of oMainWnd TITLE OemToAnsi("Cadastro de Serviços") PIXEL  
	@ 001, 002 TO 052, 228 OF oDlgVlr  PIXEL
	@ 011, 009 SAY OemToAnsi("Código do Serviço")  SIZE 54, 7 OF oDlgVlr PIXEL  
	@ 010, 068 MSGET cCodServ Picture "9999" SIZE 54, 10 Valid sfVldCdSrv() OF oDlgVlr Hasbutton PIXEL 

	@ 025, 009 SAY OemToAnsi("Descrição Serviço")  SIZE 54, 7 OF oDlgVlr PIXEL  
	@ 024, 068 MSGET cDescServ Picture "@!" SIZE 154, 10  OF oDlgVlr Hasbutton PIXEL 

	DEFINE SBUTTON FROM 54, 71 TYPE 1 ENABLE ACTION (nOpca := 1,oDlgVlr:End()) OF oDlgVlr
	DEFINE SBUTTON FROM 54, 99 TYPE 2 ENABLE ACTION (oDlgVlr:End()) OF oDlgVlr

	Activate MsDialog oDlgVlr Centered

	If nOpca == 1
		sfGrava()
		M->B1_CODISS	:= cCodServ
	Endif

	RestArea(aAreaOld)
Return


/*/{Protheus.doc} sfVldCdSrv
//Função que verifica se o código informado já existe ou não
@author Marcelo Alberto Lauschner
@since 29/05/2018
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
Static Function sfVldCdSrv()

	Local	aAreaOld	:= GetArea()
	Local	lRet		:= .T.
	DbSelectArea("SX5")
	DbSetOrder(1)
	If DbSeek(xFilial("SX5")+ "60" + cCodServ )	
		lRet	:= .F. 
		MsgInfo("Código de Serviço já cadastrado!")
	Endif
	RestArea(aAreaOld)
Return  lRet


/*/{Protheus.doc} sfGrava
//Função para gravação do novo Serviço
@author Marcelo Alberto Lauschner
@since 29/05/2018
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
Static Function sfGrava()

	// Garante que não gere duplicidade se eventualmente feito por outra estação. 
	DbSelectArea("SX5")
	DbSetOrder(1)
	If DbSeek(xFilial("SX5")+ "60" + cCodServ )
		
	Else	
		DbSelectArea("SX5")
		RecLock("SX5",.T.)
		SX5->X5_FILIAL		:= xFilial("SX5")
		SX5->X5_TABELA		:= "60"
		SX5->X5_CHAVE		:= cCodServ
		SX5->X5_DESCRI		:= cDescServ
		SX5->X5_DESCSPA		:= cDescServ
		SX5->X5_DESCENG		:= cDescServ
		MsUnlock()
	Endif
Return 


