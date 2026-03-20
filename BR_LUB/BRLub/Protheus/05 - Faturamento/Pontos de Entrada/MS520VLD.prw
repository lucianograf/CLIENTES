#INCLUDE "topconn.ch"
#include "protheus.ch"

/*/{Protheus.doc} MS520VLD
(Ponto de entrada que valida exclusão de documento de saida)
@author MarceloLauschner
@since 04/10/2005
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function MS520VLD()
	
	Local 		aAreaOld		:= GetArea()
	Local		lContOnLine		:= Iif(cEmpAnt$"02#03#04",GetNewPar("GM_CTBONLN",.T.),.F.)	// Se for empresa LLust ou Atria Verifico parametro se Contabiliza on-line ou não
	Local		cProcess
	Local		oProcess
	Local		oHtml
	Local		cStatus
	Local		aRestPerg		:= sfRestPerg(.T./*lSalvaPerg*/,/*aPerguntas*/,9/*nTamSx1*/)
	Private 	cObs 	 		:= Space(100)
	Private 	lRetorno 		:= .T.
	Private		aRecSD2			:= {}
	
	// Efetua verificação se esta validação deve ser executada para esta empresa/filial
	If !U_BFCFGM25("MS520VLD")
		Return .T.
	Endif
	
	// Executa gravação do Log de Uso da rotina
	//U_BFCFGM01()
	
	
	// Grava Log
	aRetVld		:= U_GMCFGM01("CN",SF2->F2_DOC,,FunName(),.T.)
	cObs		:= aRetVld[1]
	//If !aRetVld[2]
	//	RestArea(aAreaOld)
	//	Return .F.
	//Endif
	
	// Adicionada verificação de possibilidade cancelar Contas Receber antes do restante das validações
	If !sfVldFin()
		Return .F. 
	Endif
	
	// Consisto a contabilização Online forçada
	If lContOnLine
		//³ mv_par01 Mostra Lan‡.Contab ?  Sim/Nao                        ³
		//³ mv_par02 Aglut. Lan‡amentos ?  Sim/Nao                        ³
		//³ mv_par03 Lan‡.Contab.On-Line?  Sim/Nao                        ³
		//³ mv_par04 Retornar PV        ?  Carteira/Apto a faturar        ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If MV_PAR02<>1 .And. MV_PAR03<> 1
			u_gravasx1("MT521A","02",1)
			u_gravasx1("MT521A","03",1)
		Endif
	Endif
	
	
	cProcess := "100000"
	cStatus  := "100000"
	oProcess := TWFProcess():New(cProcess,OemToAnsi("Exclusão de nota fiscal."))
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Abre o HTML criado                                                  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If IsSrvUnix()
		If File("/workflow/nfiscal_ms520vld.htm")
			oProcess:NewTask("Gerando HTML","/workflow/nfiscal_ms520vld.htm")
		Else
			FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "Não localizou arquivo  /workflow/nfiscal_ms520vld.htm"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			Return .F.
		Endif
	Else
		oProcess:NewTask("Gerando HTML","\workflow\nfiscal_ms520vld.htm")
	Endif
	
	
	oProcess:cSubject := "Cancelamento de Nota fiscal Nº:'" +SF2->F2_DOC + "/"+SF2->F2_SERIE +" da Empresa'" + SM0->M0_NOME + "'"
	
	oProcess:bReturn  := ""
	oHTML := oProcess:oHTML
	
	oHtml:ValByName("numero",SF2->F2_DOC+" - "+SF2->F2_SERIE)
	oHtml:ValByName("emissao",SF2->F2_EMISSAO)
	If SF2->F2_TIPO $ "D#B"
		oHtml:ValByName("cliente",SF2->F2_CLIENTE+"/"+SF2->F2_LOJA+"  " + Posicione("SA2",1,xFilial("SA2")+SF2->F2_CLIENTE+SF2->F2_LOJA,"A2_NOME"))
		oHtml:ValByName("endereco",SA2->A2_END+" - "+SA2->A2_BAIRRO)
		oHtml:ValByName("municipio",SA2->A2_MUN+" - "+SA2->A2_EST)
	Else
		oHtml:ValByName("cliente",SF2->F2_CLIENTE+"/"+SF2->F2_LOJA+"  "+Posicione("SA1",1,xFilial("SA1")+SF2->F2_CLIENTE+SF2->F2_LOJA,"A1_NOME"))
		oHtml:ValByName("endereco",Posicione("SA1",1,xFilial("SA1")+SF2->F2_CLIENTE+SF2->F2_LOJA,"A1_END")+" - "+Posicione("SA1",1,xFilial("SA1")+SF2->F2_CLIENTE+SF2->F2_LOJA,"A1_BAIRRO"))
		oHtml:ValByName("municipio",Posicione("SA1",1,xFilial("SA1")+SF2->F2_CLIENTE+SF2->F2_LOJA,"A1_MUN")+" - "+Posicione("SA1",1,xFilial("SA1")+SF2->F2_CLIENTE+SF2->F2_LOJA,"A1_EST"))
	Endif	
	oHtml:ValByName("pedido",Posicione("SD2",3,xFilial("SD2")+SF2->F2_DOC+SF2->F2_SERIE,"D2_PEDIDO"))
	oHtml:ValByName("condicao",SF2->F2_COND+" -"+Posicione("SE4",1,xFilial("SE4")+SF2->F2_COND,"E4_DESCRI"))
	oHtml:ValByName("motivo",cObs)
	
	Dbselectarea("SD2")
	Dbsetorder(3)
	Dbseek(xFilial("SD2")+SF2->F2_DOC+SF2->F2_SERIE+SF2->F2_CLIENTE+SF2->F2_LOJA)
	While !Eof() .and. SD2->D2_FILIAL == xFilial("SD2") .and. SD2->D2_DOC == SF2->F2_DOC .and. SD2->D2_SERIE == SF2->F2_SERIE .And.;
			SD2->D2_CLIENTE == SF2->F2_CLIENTE .And. SD2->D2_LOJA == SF2->F2_LOJA
		
		AAdd((oHtml:ValByName("P.IT")),SD2->D2_ITEM)
		AAdd((oHtml:ValByName("P.PRODUTO")),SD2->D2_COD)
		AAdd((oHtml:ValByName("P.DESCRICAO")),Posicione("SB1",1,xFilial("SB1")+SD2->D2_COD,"B1_DESC"))
		AAdd((oHtml:ValByName("P.QUANT")),Transform(SD2->D2_QUANT,"@E 9,999,999.99"))
		AAdd((oHtml:ValByName("P.PRCTAB")),Transform(SD2->D2_PRUNIT,"@E 9,999,999.99"))
		AAdd((oHtml:ValByName("P.PRCVEN")),Transform(SD2->D2_PRCVEN,"@E 9,999,999.99"))
		AAdd((oHtml:ValByName("P.PDESC")),Transform((SD2->D2_PRUNIT - SD2->D2_PRCVEN)/SD2->D2_PRUNIT,"@E 999.99"))
		AAdd((oHtml:ValByName("P.VALOR")),Transform(SD2->D2_TOTAL,"@E 9,999,999.99"))
		// Alimenta vetor para localizar CTK de lançamentos contábeis
		Aadd(aRecSD2,SD2->(Recno()))
		
		Dbselectarea("SD2")
		Dbskip()
	Enddo
	
	oHtml:ValByName("MERCADORIAS",Transform(SF2->F2_VALMERC,"@E 9,999,999.99"))
	oHtml:ValByName("TOTAL",Transform(SF2->F2_VALBRUT,"@E 9,999,999.99"))
	
	oHtml:ValByName("DATA",DTOC(dDataBase))
	oHtml:ValByName("HORA",Time())
	
	oHtml:ValByName("USUARIO",SubStr(cUsuario,7,15))
	oProcess:cTo :=	AllTrim(GetMv("GM_CANCNF")) //Alterado para trabalhar com parametros por empresa.
	
	oProcess:Start()
	oProcess:Finish()

	// Força disparo dos e-mails pendentes do workflow
	WFSENDMAIL()
	
	If cEmpAnt $ "02"
		sfDelTamp()
	Endif
	
	
	// Restaura as perguntas para evitar erros 
	sfRestPerg(/*lSalvaPerg*/,aRestPerg/*aPerguntas*/,/*nTamSx1*/)
	
	RestArea(aAreaOld)
	
Return(lRetorno)


/*/{Protheus.doc} sfDelTamp
(long_description)
@author MarceloLauschner
@since 14/05/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfDelTamp()
	Local	aAreaOld	:= GetArea()
	
	dbSelectArea("SZA")
	dbSetOrder(3)
	dbSeek(xFilial("SZA")+SF2->F2_DOC+SF2->F2_CLIENTE+SF2->F2_LOJA)
	While !Eof() .and. SZA->ZA_DOC == SF2->F2_DOC .And. SZA->ZA_CLIENTE == SF2->F2_CLIENTE .And. SZA->ZA_LOJA == SF2->F2_LOJA .And.;
			SZA->ZA_TIPOMOV == "C"		// Posiciona Nota/Cliente/Loja e Tipo Movimento evitando exclusão de outros registros
		RecLock("SZA",.F.)
		dbDelete()
		MsUnLock("SZA")
		DbSelectArea("SZA")
		DbSkip()
	Enddo
	RestArea(aAreaOld)
	
Return




/*/{Protheus.doc} sfVldFin
(Função que verifica o status dos títulos do contas a receber evitando tentativa invalida de cancelamento da NFe)
@author MarceloLauschner
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




/*/{Protheus.doc} sfRestPerg
(Salva e restaura perguntas para controle da Rotina)
@author MarceloLauschner
@since 22/04/2014
@version 1.0
@param lSalvaPerg, ${param_type}, (Descrição do parâmetro)
@param aPerguntas, array, (Descrição do parâmetro)
@param nTamSx1, numérico, (Descrição do parâmetro)
@return array, Perguntas num vetor
@example
(examples)
@see (links_or_references)
/*/
Static Function sfRestPerg(lSalvaPerg,aPerguntas,nTamSx1)
	
	Local	ni
	
	DEFAULT lSalvaPerg	:=.F.
	Default nTamSX1		:= 40
	DEFAULT aPerguntas	:=Array(nTamSX1)
	
	For ni := 1 to Len(aPerguntas)
		If lSalvaPerg
			aPerguntas[ni] := &("mv_par"+StrZero(ni,2))
		Else
			&("mv_par"+StrZero(ni,2)) :=	aPerguntas[ni]
		EndIf
	Next ni
	
Return(aPerguntas)
