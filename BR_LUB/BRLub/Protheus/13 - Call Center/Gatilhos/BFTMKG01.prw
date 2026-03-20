#Include 'Protheus.ch'
#Include 'TopConn.ch'


/*/{Protheus.doc} BFTMKG01
(Gatilho utilizado para não carregar contato bloqueado automaticamente)
@author Iago Luiz Raimondi
@since 31/08/2015
@version 1.0
@param cCliente, character, (Codigo cliente)
@param cLoja, character, (Codigo Loja)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFTMKG01(cCliente,cLoja)

	Local cAlias 	:= GetNextAlias()
	Local cRet 		:= ""
		
	Default cCliente := M->UA_CLIENTE
	Default cLoja 	 := M->UA_LOJA

	cQry := "SELECT U5_CODCONT"
	cQry += "  FROM "+RetSqlName("SU5")+" A"
	cQry += " INNER JOIN "+RetSqlName("AC8")+" B ON B.AC8_ENTIDA = 'SA1'"
	cQry += "                    AND B.AC8_CODCON = A.U5_CODCONT"
	cQry += " WHERE A.D_E_L_E_T_ = ' '"
	cQry += "   AND A.U5_MSBLQL != '1'"
	cQry += "   AND A.U5_FILIAL = '"+ xFilial("SU5") +"'"
	cQry += "   AND B.D_E_L_E_T_ = ' '"
	cQry += "   AND B.AC8_CODENT = '"+ cCliente + cLoja +"'"
	cQry += "   AND B.AC8_FILIAL = '"+ xFilial("AC8") +"'"
	
	TCQUERY cQry NEW ALIAS cAlias
	
	If cAlias->(!EOF())
		cRet 	:= cAlias->U5_CODCONT
	EndIf
	
	cAlias->(dbCloseArea())
	
Return (cRet)

