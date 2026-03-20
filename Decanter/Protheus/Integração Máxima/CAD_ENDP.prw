#INCLUDE 'FONT.CH'
#INCLUDE 'COLORS.CH'
#INCLUDE "PROTHEUS.CH"
#Include "TOPCONN.CH"
#INCLUDE "RWMAKE.CH"
#INCLUDE "PRTOPDEF.CH"

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÝÝÝÝÝÝÝÝÝÝÑÝÝÝÝÝÝÝÝÝÝËÝÝÝÝÝÝÝÑÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝËÝÝÝÝÝÝÑÝÝÝÝÝÝÝÝÝÝÝÝÝ»±±
±±ºPrograma  ³FORNECE   ºAutor  ³Infinit             º Data ³  08/21/18   º±±
±±ÌÝÝÝÝÝÝÝÝÝÝØÝÝÝÝÝÝÝÝÝÝÊÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÊÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝ¹±±
±±ºDesc.     ³ROTINA PARA CADASTRO DA TABELA DE PREÇO PARA OS CLIENTES    º±±
±±º          ³                                                            º±±
±±ÌÝÝÝÝÝÝÝÝÝÝØÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝ¹±±
±±ºUso       ³ AP                                                        º±±
±±ÈÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

USER FUNCTION CAD_ENDP()

PRIVATE CTAB1        := GETMV("XX_TAB1")
PRIVATE CTAB2		 := GETMV("XX_TAB2")

IF EMPTY(CTAB1) .OR. EMPTY(CTAB2)
	MSGINFO("Verifique os parametros XX_TAB1 e XX_TAB2.")
	RETURN
ENDIF

Private aRotina := { {"Pesquisar","AxPesqui",0,1,,.F.} ,;
             {"Visualizar","U_TAB_P",0,2},;
             {"Incluir","U_TAB_P",0,3},;             
             {"Alterar","U_TAB_P",0,4},;                          
			 {"Excluir","U_TAB_P",0,5},;
			 {"Comando Del","U_ROD_E",0,6},;			                           
			 {"Processa","U_RODA_ROT",0,7}}			 
			 
Private cCadastro := "Tabela de EndPoint"

Private cDelFunc := ".T." // Validacao para a exclusao. Pode-se utilizar ExecBlock

Private cString := CTAB1

dbSelectArea(cString)
dbSetOrder(1)

mBrowse( 6,1,22,75,cString)

RETURN

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÝÝÝÝÝÝÝÝÝÝÑÝÝÝÝÝÝÝÝÝÝËÝÝÝÝÝÝÝÑÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝËÝÝÝÝÝÝÑÝÝÝÝÝÝÝÝÝÝÝÝÝ»±±
±±ºPrograma  ³TAB_P     ºAutor  ³Infinit             º Data ³  01/11/18   º±±
±±ÌÝÝÝÝÝÝÝÝÝÝØÝÝÝÝÝÝÝÝÝÝÊÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÊÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝ¹±±
±±ºDesc.     ³ROTINA PARA PREENCHIMENTO DOS DADOS DA TABELA DE PREÇO      º±±
±±º          ³MODELO 3                                                    º±±
±±ÌÝÝÝÝÝÝÝÝÝÝØÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝ¹±±
±±ºUso       ³ AP                                                        º±±
±±ÈÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
                                           
User Function TAB_P(cAlias , nReg , nOpc)

Local cLinok 	:= "Allwaystrue"
Local cTudook 	:= "Allwaystrue"
Local nOpce 	:= nOpc 	//define modo de alteração para a enchoice
Local nOpcg 	:= nOpc 	//define modo de alteração para o grid
Local cFieldok 	:= "Allwaystrue"
Local lRet 		:= .T.

Local lVirtual  := .T. 	//Mostra campos virtuais se houver
Local nFreeze	:= 0
Local nAlturaEnc:= 150	//Altura da Enchoice
                                             
PRIVATE CTAB1        := GETMV("XX_TAB1")
PRIVATE CTAB2		 := GETMV("XX_TAB2")

Private cCadastro	:= "Tabela de EndPoint"
Private aCols 		:= {}
Private aHeader 	:= {}
Private aCpoEnchoice:= {}
Private aAltEnchoice:= {CTAB1+"_CODIGO",CTAB1+"_DESC",CTAB1+"_PATH",CTAB1+"_TIPO",CTAB1+"_TIPO2",CTAB1+"_FLAG",CTAB1+"_METODO",CTAB1+"_FUNCAO",CTAB1+"_DELETE"}
Private cTitulo

Private cAlias1 	:= CTAB1
Private cAlias2 	:= CTAB2

IF NOPC == 6//COPIA
	RegToMemory(CTAB1,.F.)
	RegToMemory(CTAB2,.F.)
	NOPCE := 3
	NOPCG := 4
ELSE
	RegToMemory(CTAB1,nOpc==3)
	RegToMemory(CTAB2,nOpc==3)
ENDIF
	
DefineCabec()
DefineaCols(nOpcg)

lRet:=Modelo3(cCadastro,cAlias1,cAlias2,aCpoEnchoice,cLinok,cTudook,nOpce,nOpcg,cFieldok,lVirtual,,aAltenchoice,nFreeze,,,nAlturaEnc)
        
        //retornará como true se clicar no botao confirmar
if lRet
	IF nOpc == 3 .OR. nOpc == 4 .OR. nOpc == 5 .OR. nOpc == 6
//		if MsgYesNo(cMensagem+"CONFIRMA ALTERAÇÃO DOS DADOS ?", cCadastro)
		Processa({||Gravar(nOpc)},cCadastro,"Alterando os dados, aguarde...")
//		endif
	ENDIF
else
	RollbackSx8()
endif
 
Return
 
Static Function DefineCabec()           
Local nX		:= 0
Local CTAB1     := GETMV("XX_TAB1")
Local CTAB2		:= GETMV("XX_TAB2")

Local aZM2		:= {CTAB2+"_ITEM",CTAB2+"_CAMPO1",CTAB2+"_CAMPO2",CTAB2+"_TIPO1",CTAB2+"_TIPO2"}
Local nUsado

aHeader		:= {}
aCpoEnchoice:= {}

nUsado:=0

//Monta a enchoice
DbSelectArea("SX3")
SX3->(DbSetOrder(1))
dbseek(cAlias1)
while SX3->(!eof()) .AND. X3_ARQUIVO == cAlias1
	IF X3USO(X3_USADO) .AND. CNIVEL == X3_NIVEL
		AADD(ACPOENCHOICE,X3_CAMPO)
	endif
	dbskip()
enddo

//Caso contrário, se quiser todos os campos é necessário trocar o "For" por While, para que este faça a leitura de toda a tabela
DbSelectArea("SX3")
SX3->(DbSetOrder(2))
aHeader:={}
For nX := 1 to Len(aZM2)
	If SX3->(DbSeek(aZM2[nX]))
		If X3USO(X3_USADO).And.cNivel>=X3_NIVEL
			nUsado:=nUsado+1
			Aadd(aHeader, {TRIM(X3_TITULO), X3_CAMPO , X3_PICTURE, X3_TAMANHO, X3_DECIMAL,X3_VALID, X3_USADO  , X3_TIPO   , X3_ARQUIVO, X3_CONTEXT})
		Endif
	Endif
Next nX

Return
 
//INSERE O CONTEUDO NO ACOLS DO GRID
STATIC FUNCTION DEFINEACOLS(NOPC)

Local CTAB1      := GETMV("XX_TAB1")
Local CTAB2		 := GETMV("XX_TAB2")

LOCAL NQTDCPO 	:= 0
LOCAL I			:= 0
LOCAL NCOLS 	:= 0
NQTDCPO 		:= LEN(AHEADER)
ACOLS			:= {}

DBSELECTAREA(CALIAS2)
(CALIAS2)->(DBSETORDER(1))
IF NOPC != 3 .AND. (CALIAS2)->(DBSEEK(XFILIAL(CALIAS2)+(CALIAS1)->&(CTAB1+"_CODIGO")))
	WHILE !EOF() .AND. (CALIAS2)->&(CTAB2+"_FILIAL") == XFILIAL(CALIAS2) .AND. (CALIAS2)->&(CTAB2+"_CODIGO")==(CALIAS1)->&(CTAB1+"_CODIGO")
		AADD(ACOLS,ARRAY(NQTDCPO+1))
		NCOLS++                         

		ACOLS[NCOLS,1] := &(CTAB2+"->"+CTAB2+"_ITEM")
		ACOLS[NCOLS,2] := &(CTAB2+"->"+CTAB2+"_CAMPO1")
		ACOLS[NCOLS,3] := &(CTAB2+"->"+CTAB2+"_CAMPO2")
		ACOLS[NCOLS,4] := &(CTAB2+"->"+CTAB2+"_TIPO1")
		ACOLS[NCOLS,5] := &(CTAB2+"->"+CTAB2+"_TIPO2")
				
		ACOLS[NCOLS,NQTDCPO+1] := .F.
		DBSELECTAREA(CALIAS2)
		DBSKIP()
	ENDDO
ELSE
	AADD(ACOLS,ARRAY(NQTDCPO+1))
	NCOLS++
	FOR I:= 1 TO NQTDCPO
		IF AHEADER[I,10] == "V"
			ACOLS[NCOLS,I] := FIELDGET(FIELDPOS(AHEADER[I,2]))
		ELSE
			ACOLS[NCOLS,I] := CRIAVAR(AHEADER[I,2],.T.)
		ENDIF
	NEXT I
	ACOLS[NCOLS,NQTDCPO+1] := .F.	
ENDIF

Return
 
//Gravar o conteudo dos campos
Static Function Gravar(nOpc)


Local CTAB1      := GETMV("XX_TAB1")
Local CTAB2		 := GETMV("XX_TAB2")

Local bcampo := { |nfield| field(nfield) }
Local i:= 0
Local y:= 0
Local nitem := 0
Local nItem	:= aScan(aHeader,{|x| AllTrim(Upper(x[2]))== CTAB2+"_ITEM"})
Local nPosCpo
Local nCpo
Local nI

Local cCamposTB1 	:= CTAB1+"_CODIGO|"+CTAB1+"_DESC|"+CTAB1+"_PATH|"+CTAB1+"_TIPO|"+CTAB1+"_TIPO2|"+CTAB1+"_FLAG|"+CTAB1+"_METODO|"+CTAB1+"_FUNCAO|"+CTAB1+"_DELETE"
Local cCamposTB2	:= CTAB2+"_ITEM|"+CTAB2+"_CAMPO1|"+CTAB2+"_CAMPO2|"+CTAB2+"_TIPO1|"+CTAB2+"_TIPO2"
 
Begin Transaction

//Gravando dados da enchoice
dbselectarea(cAlias1)

Reclock(cAlias1,nOpc==3)

IF NOPC == 5
	(CTAB1)->(DBDELETE())
ELSE

	for i:= 1 to fcount()
		incproc()
		if "FILIAL" $ FIELDNAME(i)
			Fieldput(i,xfilial(cAlias1))
		else
			//Grava apenas os campos contidos na variavel cCamposSC5
			If ( FieldName(i) $ cCamposTB1 )
				//Fieldput(i,M->(EVAL(bcampo,i)))
				CCAMPO := FieldName(i)
				&(CTAB1+"->"+CCAMPO + ":=" + "M->"+CCAMPO)
			Endif
		endif
	next i
ENDIF

(CTAB1)->(Msunlock())

//Gravando dados do grid
dbSelectArea(CTAB2)
(CTAB2)->(dbSetOrder(1))

IF NOPC == 5 
	//For nI := 1 To Len(aCols)
		//If !(aCols[nI, Len(aHeader)+1])
		
			WHILE &(CTAB2+'->(dbSeek(xFilial("'+CTAB2+'")+M->'+CTAB1+'_CODIGO))')//If CTAB2->(dbSeek( xFilial(CTAB2)+M->&(CTAB1+"_CODIGO")+aCols[nI,nItem] ))
				RecLock(CTAB2,.F.)
				(CTAB2)->(DBDELETE())
				(CTAB2)->(MSUNLOCK())	
				(CTAB2)->(DBGOTOP())
			ENDDO
		//sENDIF
	//NEXT NI
ELSE
	For nI := 1 To Len(aCols)
		If !(aCols[nI, Len(aHeader)+1])
			If &(CTAB2+'->(dbSeek(xFilial("'+CTAB2+'")+M->'+CTAB1+'_CODIGO+"'+aCols[nI,nItem]+'"))')
				RecLock(CTAB2,.F.)
			ELSE
				RECLOCK(CTAB2,.T.)
			ENDIF
			
			For nCpo := 1 to fCount()
				//Grava apenas os campos contidos na variavel $cCamposSC6
				If (FieldName(nCpo)$cCamposTB2)
					nPosCpo := aScan(aHeader,{|x| AllTrim(x[2]) == AllTrim(FieldName(nCpo))})
					If nPosCpo != 0
						FieldPut(nCpo,aCols[nI,nPosCpo])
					EndIf
				Endif
			Next nCpo
			CCODIGO := &("M->"+CTAB1+"_CODIGO")
			&(CTAB2+"->"+CTAB2+"_FILIAL" + " := '" + XFILIAL(CTAB2)+"'")           
			&(CTAB2+"->"+CTAB2+"_CODIGO" + " := '" + CCODIGO + "'")
			(CTAB2)->(MsUnLock())	
		ELSE
			If &(CTAB2+'->(dbSeek(xFilial("'+CTAB2+'")+M->'+CTAB1+'_CODIGO+"'+aCols[nI,nItem]+'"))')
				RECLOCK(CTAB2,.F.)
				(CTAB2)->(DBDELETE())
				(CTAB2)->(MSUNLOCK())
			ENDIF
		Endif
	Next nI
ENDIF	
CONFIRMSX8()

End Transaction

Return

USER FUNCTION ROD_E

LOCAL CTAB1        := GETMV("XX_TAB1")

CENDPOINT  := &(CTAB1+"->"+CTAB1+"_DESC")//ZM1->ZM1_DESC
CPATH      := &(CTAB1+"->"+CTAB1+"_PATH")//ZM1->ZM1_PATH
	
ADADOSDEL  := {1}	

FWMsgRun(, {|| U_BENVIA(ADADOSDEL   ,"DELETE" , CENDPOINT, ALLTRIM(CPATH)+"/Todos")  }, "Processando", "Processando a rotina...")

RETURN

USER FUNCTION RODA_ROT


FWMsgRun(, {|OSAY| U_ROTINA(OSAY)  }, "Processando", "Processando dados...")		          

RETURN