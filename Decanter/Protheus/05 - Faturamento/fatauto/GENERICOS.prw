#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "RWMAKE.CH"
#INCLUDE "FONT.CH"
#INCLUDE "COLORS.CH"

//GENERICOS.prw


/*---------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+------------------+---------------------------------------------------------+
!Descricao         ! Funcoes Genericas utilizadas em todo sistema            !
!                  ! 1. Monta Grupo de Perguntas (SX1)                       !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 09/2018                                                 !
+------------------+--------------------------------------------------------*/

User Function FtCriaSX1(mvPerg,vList,lDel)
	Local aArea := GetArea()
	Local cSeq := "1"
	Local _Lin := 0
	Local nAdic := 0
	Local nTamOrd := Len(SX1->X1_ORDEM)
	Local cOrdPerg := ""
	Local cCpoTmp := ""
	Local _LisOpc

	// abre arquivo de perguntas
	DBSelectArea("SX1")
	SX1->( DBSetOrder(1) )

	// padroniza tamanho do cPerg
	mvPerg := PadR(mvPerg,Len(SX1->X1_GRUPO))

	//verifica se deve recriar as perguntas
	If lDel
		SX1->( DBSeek(mvPerg) )
		//Apaga todo o grupo de Perguntas
		While SX1->( !Eof() ) .and. SX1->X1_GRUPO == mvPerg
			RecLock("SX1",.F.)
			SX1->( DbDelete() )
			MsUnLock("SX1")
			SX1->(DbSkip())
		EndDo
	EndIf

	// verifica se todas os parametros existem
	For _Lin := 1 to Len(vList)
		// cria a variavel Ordem
		cOrdPerg := StrZero(_Lin,nTamOrd)

		// pesquisa pelo parametro
		SX1->( DBSeek(mvPerg+cOrdPerg) )

		// operacao (alteracao ou inclusao)
		RecLock("SX1",SX1->(Eof()))
		SX1->X1_GRUPO	:= mvPerg
		SX1->X1_ORDEM	:= cOrdPerg
		SX1->X1_PERGUNT	:= vList[_Lin,1]
		SX1->X1_PERSPA	:= vList[_Lin,1]
		SX1->X1_PERENG	:= vList[_Lin,1]
		SX1->X1_VARIAVL	:= "mv_ch" + cSeq
		SX1->X1_TIPO	:= vList[_Lin,2]
		SX1->X1_TAMANHO	:= vList[_Lin,3]
		SX1->X1_DECIMAL	:= vList[_Lin,4]
		SX1->X1_GSC		:= vList[_Lin,5]
		//Lista de Opções
		If vList[_Lin,5] = "C"
			For _LisOpc := 1 to Len(vList[_Lin,6])
				cCpoTmp := "X1_DEF" + StrZero(_LisOpc,2)
				SX1->&cCpoTmp := vList[_Lin,6,_LisOpc]
			Next _LisOpc
		Else
			SX1->X1_F3 := vList[_Lin,7]
		EndIf
		SX1->X1_PICTURE	:= vList[_Lin,8]
		SX1->X1_VAR01   := "mv_par" + StrZero(_Lin,2)

		// verifica se tem informacoes de campos adicionais
		If (Len(vList[_Lin])==8).and.(ValType(vList[_Lin,8])=="A")
			// grava informacoes adicionais
			For nAdic := 1 to Len(vList[_Lin,8])
				// grava campo
				SX1->&(vList[_Lin,8][nAdic,1]) := vList[_Lin,8][nAdic,2]
			Next nAdic
		EndIf

		SX1->(MsUnlock())

		//Atualiza Seq
		cSeq := Soma1(cSeq)
	Next _Lin

	// restaura area inicial
	RestArea(aArea)

Return()

//** Funcao que executa Query passada como parametro e retorna o conteudo do campo CAMPO
User Function FtQuery(mvQuery)

	Local cAliasX := Alias()
	Local aAreaAtu := GetArea()
	Local cCampo := ""

	If Select("QRYTMP") <> 0
		QRYTMP->(DbCloseArea())
	EndIf
	TcQuery mvQuery New Alias "QRYTMP"

	DbSelectArea("QRYTMP")
	QRYTMP->(DbGoTop())

	// define campo de retorno
	cCampo := QRYTMP->(FieldName(1))
	// conteudo do retorno
	xRetorno := QRYTMP->(&cCampo)

	// fecha query
	QRYTMP->(DbCloseArea())

	If !Empty(cAliasX)
		DbSelectArea(cAliasX)
		RestArea(aAreaAtu)
	EndIf

Return(xRetorno)

User Function SqlToVet(cQuery)

	Local aRet    := {}
	Local aRet1   := {}
	Local nRegAtu := 0
	Local x       := 0
	Local _cAlias := GetNextAlias()

	cQuery := ChangeQuery(cQuery)

	dbUseArea(.T.,"TOPCONN",TCGenQry(,,cQuery),_cAlias,.T.,.T.)

	(_cAlias)->(dbgotop())

	aRet1   := Array(Fcount())
	nRegAtu := 1

	While !(_cAlias)->(Eof())

		For x:=1 To Fcount()
			aRet1[x] := FieldGet(x)
		Next
		Aadd(aRet,aclone(aRet1))

		(_cAlias)->(dbSkip())
		nRegAtu += 1
	Enddo

	If Select(_cAlias) <> 0
		(_cAlias)->(dbCloseArea())
	EndIf

Return(aRet)

//Função para criar diretorio e subdiretorio
User Function CriaDir(cCaminho, lMsgAler)
	local cCamiTmp	:= lower(alltrim(cCaminho))

	Local lUnidade	:= AT(":", Alltrim(cCamiTmp)) > 0
	local nP_Unid	:= AT(":", Alltrim(cCamiTmp))
	Local cUnidade	:= iif(nP_Unid > 0,substr(cCamiTmp,1,nP_Unid),"") // ex: c:

	Local aArray	:= {}
	Local nCount	:= 0
	Local cDirAux	:= ""
	Local nRet		:= 0

	local lRet		:= .T.

	Default lMsgAler := .T.

	cCamiTmp :=  iif(lUnidade,substr(cCamiTmp,nP_Unid + 1,Len(cCamiTmp) - nP_Unid),cCamiTmp)

	// se unidade local,verifica se existe
	if lUnidade .and. !ExistDir(cUnidade+"\")
		IF lMsgAler
			Aviso("","Unidade informada: "+cUnidade+" invalida.",{"Aviso"})
		Else
			ConOut("Unidade informada: "+cUnidade+" invalida.")
		EndIF
		Return .F.
	endif

	aArray:= StrToArray(cCamiTmp,'\')

	if Len(aArray)==0 .or. Empty(StrTran(cCamiTmp,"\",""))
		IF lMsgAler
			Aviso("","Caminho informado invalido: "+cCamiTmp,{"Aviso"})
		Else
			ConOut("[Criadir] Caminho informado invalido: "+cCamiTmp)
		EndIF
		Return .F.
	endif

	For nCount:=1 to Len(aArray)
		if empty(aArray[nCount])
			loop
		endif

		IF Empty(cDirAux)
			cDirAux+=IIF(lUnidade,cUnidade,"")+"\"
		EndIF

		cDirAux+=aArray[nCount]+'\'

		If !ExistDir(cDirAux)
			conout("*** criando diretorio: "+cDirAux)

			nRet :=MakeDir(cDirAux)

			if nRet <> 0
				IF lMsgAler
					Aviso("","Não foi possivel criar o diretório: " + CRLF + cDirAux + CRLF +"Erro: " + cValToChar( FError()),{"Aviso"})
				Else
					ConOut("Não foi possivel criar o diretório: "+cDirAux+" Erro: " + cValToChar( FError()))
				EndIF
				lRet := .F.
				exit
			endif
		Endif
	Next nCount

Return(lRet)


//remover espacos em excesso da string 
User Function MiddleTrim(cText)
    Local cClean := ""
    Local cLast := " "
    Local nLen := Len(cText)
    Local i
    Local cChar
    For i := 1 To nLen
        cChar := Substr(cText, i, 1)
        If cChar != " "
            cClean += cChar
        ElseIf cLast != " "
            cClean += " "
        EndIf
        cLast := cChar
    Next
    If Substr(cClean, Len(cClean), 1) == " "
        cClean := Substr(cClean, 1, Len(cClean) - 1)
    EndIf
Return cClean


/*/{Protheus.doc} ExeQry
    (Executa query criando alias novo)
    @type  Static Function
    @author Heitor dos Santos
    @since 10/03/2022
    @version version
    @param param_name, param_type, param_descr
    @return return_var, return_type, return_description
    @example
    (examples)
    @see (links_or_references)
/*/
User Function ExeQry(_cQuery, _lRet, _lClose)
Local _cAlias
Default _lRet:= .F.
Default _lClose:= .F.

_cAlias:= GetNextAlias()

If select(_cAlias) > 0
	dbSelectArea(_cAlias)
	dbCloseArea()
EndIf

TcQuery _cQuery New Alias (_cAlias)

DbSelectArea(_cAlias)
DbGoTop()

_lRet:= !(_cAlias)->(Eof())

if _lClose
	If select(_cAlias) > 0
		dbSelectArea(_cAlias)
		dbCloseArea()
	EndIf
endif
    
Return _cAlias

/*/{Protheus.doc} gTimeSql
	(long_description)
	@type  Static Function
	@author user
	@since 30/03/2022
	@version version
	@param param_name, param_type, param_descr
	@return return_var, return_type, return_description
	@example
	(examples)
	@see (links_or_references)
/*/
User Function gTimeSql()
Local _cQuery, _cAlias
Local _cRet:=""

_cQuery:=" "

_cQuery+=" SELECT RTRIM(FORMAT(getdate(), 'yyyyMMdd HH:mm:ss')) as DATAA "
_cAlias:= U_ExeQry(_cQuery)

if (!(_cAlias)->(Eof()))
	_cRet:= (_cAlias)->DATAA
endif

If select(_cAlias) > 0
	dbSelectArea(_cAlias)
	dbCloseArea()
EndIf

Return _cRet

/*/{Protheus.doc} DtDb
	(long_description)
	@type  Static Function
	@author user
	@since 11/04/2022
	@version version
	@param param_name, param_type, param_descr
	@return return_var, return_type, return_description
	@example
	(examples)
	@see (links_or_references)
/*/
User Function DtDb(_dDate, _cTime)
Local _cRet:= DTOC(_dDate)
	
_cRet:= Subs(_cRet,4,3)+Subs(_cRet,1,3)+Subs(_cRet,7)

Return _cRet+" "+_cTime


/*/{Protheus.doc} User Function GHELP
	(long_description)
	@type  Function
	@author user
	@since 06/06/2022
	@version version
	@param param_name, param_type, param_descr
	@return return_var, return_type, return_description
	@example
	(examples)
	@see (links_or_references)
	/*/
User Function GHELP(_cHelp,_cProb,_cSoluc)
Default _cHelp := "Texto do Help"
Default _cProb := "Texto do Problema"
Default _cSoluc:= "Texto da Solução"
if Type("l410Auto") <> "U" .And. l410Auto
	_cProb:= _cProb+", "+_cSoluc
endif
Help(NIL, NIL, _cHelp, NIL, _cProb, 1, 0, NIL, NIL, NIL, NIL, NIL, {_cSoluc})
	
Return

/*/{Protheus.doc} User Function ZQVALID
	(long_description)
	@type  Function
	@author user
	@since 05/10/2022
	@version version
	@param param_name, param_type, param_descr
	@return return_var, return_type, return_description
	@example
	(examples)
	@see (links_or_references)
	/*/

User Function ZQVALID

SZQ->(DbSelectArea("SZQ"))
SZQ->(DbSetOrder(2))

If SZQ->(DbSeek(xFilial("SZQ")+ALLTRIM(M->ZQ_CRACHA)))
     MsgInfo("Registro já existe!!")
	 RETURN .F.
Endif
DbCloseArea()

Return .T.



/*/{Protheus.doc} bkppar
    (Faz backup dos parametros)
    @type  Static Function
    @author user
    @since 21/09/2022
    @version version
    @param param_name, param_type, param_descr
    @return return_var, return_type, return_description
    @example
    (examples)
    @see (links_or_references)
/*/
User Function bkppar(_nPars)
Local _ix
Local _aBkpPar:={}
Private _cTmp:=""

_aBkpPar:={}

for _ix:= 1 to _nPars
    _cTmp:=""
    _cTmp:="MV_PAR"+STRZERO(_ix,2)
    AADD(_aBkpPar,&(_cTmp))
next _ix

    
Return _aBkpPar

/*/{Protheus.doc} restpar
    (Restaura parametros)
    @type  Static Function
    @author user
    @since 21/09/2022
    @version version
    @param param_name, param_type, param_descr
    @return return_var, return_type, return_description
    @example
    (examples)
    @see (links_or_references)
/*/
User Function restpar(_aBkpPar)
Local _ix
Local  _nPars := Len(_aBkpPar)
Private _aBkpP := aClone(_aBkpPar)
Private _cTmp:=""

for _ix:= 1 to _nPars
    _cTmp:=""
    _cTmp:="MV_PAR"+STRZERO(_ix,2)+":= _aBkpP["+cValToChar(_ix)+"]"
    &(_cTmp)
next _ix
    
Return

/*/{Protheus.doc} User Function XPICT
	(Retorna uma mascara padrão pelo tamanho do campo)
	@type  Function
	@author Heitor dos Santos (GRUPPE)
	@since 15/02/2023
	@version version
	@param param_name, param_type, param_descr
	@return return_var, return_type, return_description
	@example
	(examples)
	@see (links_or_references)
	/*/
User Function XPICT(_nTam, _nDec, _lMilh)
Local _cInte :=""
Local _cDec  :=""
Local _nTamInt:= _nTam
Local _nx
Default _lMilh:= .T.

_nTamInt+= IIF(_nDec>0,-1,0)//Retira 1 posição do decimal
_nTamInt-= _nDec
//@E 999,999.99
_cDec:= IIF(_nDec>0,"."+REPLICATE("9",_nDec),"")
_cInte:= REPLICATE("9",_nTamInt)

if _lMilh
	For _nx:= 4 to _nTamInt
		if MOD(_nx-1,3)==0
			_cInte:= Subs(_cInte,1,_nx-1)+","+Subs(_cInte,_nx+1)
		endif
	Next _nx
endif


Return _cInte+_cDec

/*/{Protheus.doc} User Function TAB2JSON
	(Transforma o registro de uma tabela ou consulta em um JSON)
	@type  Function
	@author Heitor dos Santos (GRUPPE)
	@since 23/02/2023
	@version version
	@param param_name, param_type, param_descr
	@return return_var, return_type, return_description
	@example
	(examples)
	@see (links_or_references)
	/*/
User Function TAB2JSON(_cAlias)
Local _oObj:= JsonObject():New()
Local _nCampos := (_cAlias)->(FCount())
Local _nRec
Local nX
Local cName
Local _nVal
			
_nRec := cValToChar((_cAlias)->(Recno()))
_oObj['RECNO']	:= _nRec
For nX := 1 To _nCampos
	cName := (_cAlias)->(FieldName(nX))
	_nVal:=  (_cAlias)->&(cName)
	_oObj[cName]:= _nVal
next nX

Return _oObj

/*/{Protheus.doc} User Function TAB2JSON
	(Transforma um json em uma tabela)
	@type  Function
	@author Heitor dos Santos (GRUPPE)
	@since 23/02/2023
	@version version
	@param param_name, param_type, param_descr
	@return return_var, return_type, return_description
	@example
	(examples)
	@see (links_or_references)
	/*/
User Function JSON2TAB(_cAlias, _oObj, _lRLock, _lInc,_cCpmExc)
Local _nCampos := (_cAlias)->(FCount())
Local nX
Local cName
Default _lRLock:= .F.
Default _lInc:= .F.
Default _cCpmExc:= ""

if _lRLock
	RecLock(_cAlias,_lInc)
endif

For nX := 1 To _nCampos
	cName := (_cAlias)->(FieldName(nX))
	if !cName$_cCpmExc .and. _oObj:hasProperty(cName)
		FieldPut( nX,_oObj[cName])
	endif
next nX

if _lRLock
	MsUnlock()
endif

Return _oObj

/*/{Protheus.doc} User Function FPTOJSON
	(Funcao para retornar o nome do campo e sua posição no Alias (fieldpos) em formato JSON)
	@type  Function
	@author Heitor dos Santos (GRUPPE)
	@since 23/02/2023
	@version version
	@param param_name, param_type, param_descr
	@return return_var, return_type, return_description
	@example
	(examples)
	@see (links_or_references)
	/*/
User Function FPTOJSON(_cAlias)
Local _oObj:= JsonObject():New()
Local _nCampos := (_cAlias)->(FCount())
Local cName
Local nX

For nX := 1 To _nCampos
	cName := (_cAlias)->(FieldName(nX))
	_oObj[cName]:= nX
next nX
	
Return _oObj


/*/{Protheus.doc} User Function GCLOSEA
	(Fecha alias caso exista)
	@type  Function
	@author Heitor dos Santos (GRUPPE)
	@since 08/03/2023
	@version version
	@param param_name, param_type, param_descr
	@return return_var, return_type, return_description
	@example
	(examples)
	@see (links_or_references)
	/*/
User Function GCLOSEA(_cAlias)
Local _lRet := .F.

If select(_cAlias) > 0
	dbSelectArea(_cAlias)
	dbCloseArea()
	_lRet:= .T.
EndIf

Return _lRet


/*/{Protheus.doc} User Function GSEEK
	(Funcao que realiza DbSeek + DbSetOrder + DbSelectArea e retorna se registro foi localizado, criado para diminuir codigo fonte)
	@type  Function
	@author Heitor dos Santos (GRUPPE)
	@since 08/03/2023
	@version version
	@param param_name, param_type, param_descr
	@return return_var, return_type, return_description
	@example
	(examples)
	@see (links_or_references)
	/*/
User Function GSEEK(_cAlias, _nIndex, _cChave)
Local _lRet := .F.
	DbSelectArea(_cAlias)
	DbSetOrder(_nIndex)
	_lRet:= DbSeek(_cChave)
Return _lRet

/*/{Protheus.doc} User Function GSEEK
	(Funcao Clonar o Objeto, pois por padrao ao Objeto que recebe o valor do outro na verdade recebe a referencia do objeto o 
	que faz com que ao mudar o valor no objeto de destino altera no objeto original)
	@type  Function
	@author Heitor dos Santos (GRUPPE)
	@since 10/03/2023
	@version version
	@param param_name, param_type, param_descr
	@return return_var, return_type, return_description
	@example
	(examples)
	@see (links_or_references)
	/*/
User Function oClone(_oOrigem)
Local _oDestino := JsonObject():New()
_oDestino:FromJson(_oOrigem:ToJson())

_oDestino:= VerfD(_oOrigem, _oDestino)//Copia elementos do tipo data novamente

Return _oDestino

/*/{Protheus.doc} VerfD
	(Varre todo o objeto e Converte campos data)
	@type  Static Function
	@author Heitor dos Santos (GRUPPE)
	@since 08/03/2023
	@version version
	@param param_name, param_type, param_descr
	@return return_var, return_type, return_description
	@example
	(examples)
	@see (links_or_references)
/*/
Static Function VerfD(_oParams, _oObDest)
Local _nX
Local _aNames:={}
Local _cName
Private _oTmp := _oParams
Private _dTmp

If Type("_oTmp")=="J"
	_oTmp:= Nil
	_aNames:= _oParams:GetNames()
	For _nX:= 1 To Len(_aNames)
		_cName:= _aNames[_nX]
		_dTmp:= _oParams[_cName]
		if Type("_dTmp")=="J"
			VerfD(_oParams[_cName],_oObDest)
		elseif Type("_dTmp")=="D"
			_oObDest[_cName]:= _oParams[_cName]
		endif

	Next _nX
endif
	
Return _oObDest
