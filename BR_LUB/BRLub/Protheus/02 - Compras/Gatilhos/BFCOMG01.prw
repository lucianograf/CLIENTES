#Include 'Protheus.ch'

/*/{Protheus.doc} BFCOMG01
(Gatilho para retornar código de produto)
@author MarceloLauschner
@since 16/08/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFCOMG01()

Local		cQry 		:= ""
Local		cRet		:= ""
Local		aAreaOld	:= GetArea()

cQry := "SELECT A5_PRODUTO,A5_CODPRF "
cQry += "  FROM " + RetSqlName("SA5") 
cQry += " WHERE D_E_L_E_T_ = ' ' "
cQry += "   AND A5_CODPRF LIKE '%" + Alltrim(M->AIB_CODPRF) + "%' "                                           
cQry += "   AND A5_LOJA = '" + M->AIA_LOJFOR + "' "
cQry += "   AND A5_FORNECE = '" + M->AIA_CODFOR + "' "
cQry += "   AND A5_FILIAL = '" + xFilial("SA5") + "' "

dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),"QSA5",.T.,.T.)

If !Eof()
	cRet			:= QSA5->A5_PRODUTO
Endif
QSA5->(DbCloseArea())

RestArea(aAreaOld)

Return cRet


