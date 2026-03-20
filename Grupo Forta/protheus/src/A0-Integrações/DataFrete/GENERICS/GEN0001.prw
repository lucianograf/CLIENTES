#INCLUDE "totvs.ch"

/*
+-------------+----------------------+-------+------------------------------------------+------+-------------+
| Programa    | Consulta de dados    | Autor | William Souza - TOTVS S/A                | Data | ABR./2023   |
+-------------+----------------------+-------+------------------------------------------+------+-------------+
| Descricao   | Processamento para extração de dados         			            		 			     |
+-------------+----------------------------------------------------------------------------------------------+
| Uso         |                                                                                              |
+-------------+----------------------------------------------------------------------------------------------+
*/

User Function GEN0001(_cColunas,_cTabela,_cApelido,_cRecno,_cWhere,_cInner,_cOrder,_cTop,_cTipo,_nI,_cOper,_aTabelas)
	
	Local _cValores  := ""
	Local _cString   := ""
	Local _cQry      := ""
	Local _aCampos   := iif(len(_cColunas) == 3,FWsx3util():getallfields(_cColunas,.f.),StrTokArr( _cColunas, "," ))
	Local _cAlias    := GetNextAlias()
	Local i := y     := 0
	Local x          := 1
	Local _lTrava    := .f.
	Local _cNum      := ""
	Local _cjson     := ""
	Local _FUUID     := FWUUID(_cRecno)
	Local _cTabela2  := iif(empty(_aTabelas),_cColunas,_aTabelas[1])

	Default _nI      := 1
	Default aTabelas := {}

	if len(_cColunas) == 3 
		_cColunas := "" 
		for i := 1  to len (_aCampos)
			_cColunas += _aCampos[i]+ ","
		next
		_cColunas := left(_cColunas,len(_cColunas)-1)
	EndIf

	//Montagem da query
	_cQry := "SELECT " + iif(!empty(_cTop),"TOP "+ _cTop, "") +chr(10)+chr(13)
	_cQry += _cColunas + " " +chr(10)+chr(13)
			
	/*If !Empty(_cRecno)
		_cQry += ", "+_cRecno+".R_E_C_N_O_ AS '' "
	EndIF*/
			
	_cQry += "FROM "+ _cTabela + " " + _cApelido + " " +chr(10)+chr(13)
			
	if !Empty(_cInner)
		_cQry += _cInner + " " +chr(10)+chr(13)
	ENDIF
		
	If !Empty(_cWhere)
		_cQry += "WHERE " + _cWhere + " " +chr(10)+chr(13)
	EndIf
	
	If !Empty(_cOrder)
		_cQry += "ORDER BY " + _cOrder +chr(10)+chr(13)
	EndIF	
			
	If Select(_cAlias ) > 0
		(_cAlias)->(DbCloseArea())
	Endif
			
	conout("-----------------")
	conout(_cQry)
	conout("-----------------")
		
	DbUseArea(.T.,"TOPCONN",TcGenQry(,,_cQry),_cAlias ,.T.,.T.)
			
	IF !(_cAlias)->(Eof())
		While !(_cAlias)->(Eof())

     		if !Empty(_cTipo)       
				if !_ltrava
					_cString += '{"'+_aTabelas[1]+'":{'       +chr(10)+chr(13)

					_cString += "'OPERACAO':'"+_cOper+"'," +chr(10)+chr(13)
					_cString += "'CHAVE':'"+_FUUID+"'," +chr(10)+chr(13)
					_cString += "'IDINTEGRACAO':'"+_cRecno+"'," +chr(10)+chr(13)

					for y := 1 to _nI
						if FWSX3Util():GetFieldType(_aCampos[y]) <> "M"
							_cValores := (_cAlias)->&(_aCampos[y])
							_cString += "'"+alltrim(_aCampos[y])+"':"+alltrim(iif(VALTYPE( _cValores ) == "N",cvaltochar(_cValores),"'"+_cValores+"'"))+ iif(y <> Len(_aCampos),",","") +chr(10)+chr(13)
						EndIf
					Next

					_cString += '}, "'+_aTabelas[2]+'":['       +chr(10)+chr(13)
					_ltrava := .t.
					_cNum := (_cAlias)->&(_aCampos[1])
					x += _nI		
				Endif
			EndIF

			_cString += "{"

			for i := x to len(_aCampos)

				if FWSX3Util():GetFieldType(_aCampos[i] ) <> "M"
					_cValores := (_cAlias)->&(_aCampos[i])
					_cString += "'"+alltrim(_aCampos[i])+"':"+alltrim(iif(VALTYPE( _cValores ) == "N",cvaltochar(_cValores),"'"+_cValores+"'"))+ iif(i <> Len(_aCampos),",",iif(!Empty(_cRecno),",","")) +chr(13)
				
				
				EndIF					
			Next

			_cString += "},"  +chr(10)+chr(13)
			
			(_cAlias)->(dbSkip())
			conout(_cString)
		End

		if !Empty(_cTipo)		
			_cString := left(_cString,len(_cString)-3)
		else
			_cString := left(_cString,len(_cString)-6)
        endif 
		
		if !Empty(_cTipo)
			_cString +=	"  ] " +chr(10)+chr(13)
			_cString +=	"}"
        EndIF 

		if Empty(_cTipo)
			_cJson := "{'"+_cTabela2+"':{" +chr(10)+chr(13)
			_cJson += "'OPERACAO':'"+_cOper+"'," +chr(10)+chr(13)
			_cJson += "'CHAVE':'"+_FUUID+"'," +chr(10)+chr(13)
			_cJson += "'IDINTEGRACAO':'"+_cRecno+"'," +chr(10)+chr(13)
			_cJson += _cString 	+chr(10)+chr(13)	
			_cJson += "}}" +chr(10)+chr(13)
		else
			_cJson := _cString
		endif
		
    EndIF 

(_cAlias)->(dbclosearea())

Return {_FUUID,strtran(_cJson,"'",'"')}
