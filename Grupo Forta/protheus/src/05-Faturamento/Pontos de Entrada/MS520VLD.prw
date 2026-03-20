#include 'protheus.ch'
#include 'parmtype.ch'


/*/{Protheus.doc} MS520VLD
//  Ponto de Entrada para validar a exclusão de Nota Fiscal 
@author Marcelo Alberto Lauschner
@since 14/08/2019
@version 1.0
@return lRet , Logical , Define se a nota pode ser excluída ou não
@type function
/*/
User function MS520VLD()
	
	Local	lRet		:= .T. 
	Local	aAreaOld	:= GetArea()
	Local	aRetVld		:= {}
	Local	cObs		:= ""
	
	If !sfVldFin()
		lRet	:= .F. 
	Endif
	
	If lRet	
		aRetVld		:= U_MLCFGM01("CN",SF2->F2_DOC,,FunName(),.T.)
		cObs		:= aRetVld[1]
	Endif
	
	RestArea(aAreaOld)
	
	
Return lRet



/*/{Protheus.doc} sfVldFin
(Função que verifica o status dos títulos do contas a receber evitando tentativa invalida de cancelamento da NFe)
@author Marcelo Lauschner
@since 29/05/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/

Static Function sfVldFin()
	
	
	Local	lRetorno	:= .T.
	Local	cPrefixo 	:= IIf(Empty(SF2->F2_PREFIXO),&(GetMv("MV_1DUPREF")),SF2->F2_PREFIXO)
	Local	cClieFor	:= SF2->F2_CLIENTE
	Local 	cLoja		:= SF2->F2_LOJA
	Local	cAliasSE1	:= GetNextAlias()
	Local	cQuery
		
	
	If lRetorno .And. !Empty(SF2->F2_DUPL)
		
			
		cQuery := "SELECT SE1.*,SE1.R_E_C_N_O_ SE1RECNO "
		cQuery += "  FROM "+RetSqlName("SE1")+" SE1 "
		cQuery += " WHERE SE1.E1_FILIAL='"+xFilial("SE1")+"' "
		cQuery += "   AND SE1.E1_PREFIXO='"+cPrefixo+"' "
		cQuery += "   AND SE1.E1_NUM='"+SF2->F2_DUPL+"' "
		cQuery += "   AND SE1.E1_CLIENTE='"+cClieFor+"' "
		cQuery += "   AND SE1.E1_LOJA='"+cLoja+"' "
		cQuery += "   AND SE1.D_E_L_E_T_=' ' "
				
				
		dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasSE1,.T.,.T.)
		
		While ( !Eof() .And. xFilial("SE1") == (cAliasSE1)->E1_FILIAL .And.;
				cClieFor == (cAliasSE1)->E1_CLIENTE .And.;
				cLoja == (cAliasSE1)->E1_LOJA .And.;
				cPrefixo == (cAliasSE1)->E1_PREFIXO .And.;
				SF2->F2_DUPL == (cAliasSE1)->E1_NUM .And.;
				lRetorno )
		
				If !Empty((cAliasSE1)->E1_BAIXA) .And.(cAliasSE1)->E1_SALDO = 0  
					lRetorno := .F.
					Help(" ",1,"FA040BAIXA")
				Elseif !Empty((cAliasSE1)->E1_BAIXA) .And.(cAliasSE1)->E1_VALOR <> (cAliasSE1)->E1_SALDO 
					lRetorno := .F.
					Help(" ",1,"BAIXAPARC")
				ElseIf (cAliasSE1)->E1_SITUACA != "0"
					lRetorno := .F.
					Help(" ",1,"A520NCART")					
				ElseIf !Empty((cAliasSE1)->E1_NUMBOR)
					lRetorno := .F.
					Help(" ",1,"A520NUMBOR")					
				Endif
			
			dbSelectArea(cAliasSE1)
			dbSkip()
		EndDo
		dbSelectArea(cAliasSE1)
		dbCloseArea()
		
	EndIf
	
	
Return lRetorno