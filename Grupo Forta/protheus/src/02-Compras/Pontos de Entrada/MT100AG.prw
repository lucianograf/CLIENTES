#include 'protheus.ch'
#include 'parmtype.ch'


/*/{Protheus.doc} MT100AG
//TODO Ponto de entrada antes da Gravação do Documento de Entrada. 
@author Marcelo Alberto Lauschner
@since 22/01/2020
@version 1.0
@return Nil 
@type User Function
/*/
User function MT100AG()
	
	Local	oDlgEsp
	Local	aAreaOld		:= GetArea()
	Local 	lMotObrig 		:= X3Obrigat("F1_MOTRET")
	Local 	aSize			:= MsAdvSize(.F.)
	Private cDescRet		:= CriaVar("DHI_DESCRI",.F.)
	Private cMotRet			:= CriaVar("DHI_CODIGO",.F.)
	Private cHistRet		:= CriaVar("F1_HISTRET",.F.)
	Private oMemoRet		:= Nil
	
	// Se for uma nota tipo devolução de Venda e Inclusão/Classificação 
	If cTipo $ "D" .And. (INCLUI .Or. ALTERA)

		DEFINE MSDIALOG oDlgEsp From 0,0 To 200,400 OF oMainWnd PIXEL TITLE "Informar Motivo de Devolução/Retorno"
		
		@ 010,005 TO 80,195 LABEL "Motivo do Retorno/Devolução" OF oDlgEsp PIXEL // 'Motivo do retorno'

		@ 019,010 SAY RetTitle("F1_MOTRET") PIXEL
		@ 018,040 MSGET cMotRet SIZE 30, 10 OF oDlgEsp F3 "DHI" PIXEL VALID;
		(cDescRet:=Posicione("DHI",1,xFilial("DHI")+cMotRet,"DHI_DESCRI"), Vazio() .Or. ExistCpo('DHI',cMotRet,1)) HASBUTTON

		@ 018,075 MSGET cDescRet SIZE 115, 10 OF oDlgEsp PIXEL VALID Vazio() WHEN .F. HASBUTTON

		@ 034,010 SAY RetTitle("F1_HISTRET") PIXEL
		@ 033,040 GET oMemoRet VAR cHistRet Of oDlgEsp MEMO size 115,45 pixel 


		DEFINE SBUTTON FROM 085,020 TYPE 1 OF oDlgEsp ENABLE PIXEL ACTION Eval({|| Iif(!Empty(cMotRet),.T.,Iif(lMotObrig,(MsgAlert("Informe um código de motivo valido.","MATA103"),.F.),.T.)),(MT103SetRet(cMotRet,cHistRet),nOpcao := 1,oDlgEsp:End())})

		DEFINE SBUTTON FROM 085,055 TYPE 2 OF oDlgEsp ENABLE PIXEL ACTION (nOpcao := 0,oDlgEsp:End())

		ACTIVATE MSDIALOG oDlgEsp CENTERED
		
		

	Endif

	RestArea(aAreaOld)

Return Nil 