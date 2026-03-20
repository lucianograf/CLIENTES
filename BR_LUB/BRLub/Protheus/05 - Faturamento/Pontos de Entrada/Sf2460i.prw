#include "topconn.ch"
/*/{Protheus.doc} SF2460I
(Ponto de entrada para gerar Workflow de Notas emitidas  )
@author MarceloLauschner
@since 10/07/2012
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function SF2460I()


	// Efetua verificação se esta validação deve ser executada para esta empresa/filial
	If !U_BFCFGM25("SF2460I")
		Return .T.
	Endif

	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()

	// Gravo log de geração de nota fiscal
	// Adicionado em 23/09/2014 por motivo de validar faturamentos por qualquer usuário
	U_GMCFGM01("NF",,"Geração de nota fiscal "+SF2->F2_DOC,FunName())

	// Chamado 23.947 - Atualizar percentual títulos Michelin
	sfAtuTit()

	// Se não
	If !(cEmpAnt+cFilAnt $ "0201" .And. Alltrim(SF2->F2_SERIE) == "3")
		Return
	Endif

	cProcess := "100000"
	cStatus  := "100000"
	oProcess := TWFProcess():New(cProcess,OemToAnsi("Geração de nota fiscal."))

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Abre o HTML criado                                                  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	If IsSrvUnix()
		If File("/workflow/nfiscal_sf2460i.htm") 
			oProcess:NewTask("Gerando HTML","/workflow/nfiscal_sf2460i.htm")
		Else
			FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "Não localizou arquivo  /workflow/nfiscal_sf2460i.htm"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			Return 
		Endif		
	Else
		oProcess:NewTask("Gerando HTML","\workflow\nfiscal_sf2460i.htm")
	Endif 

	oProcess:cSubject := "Nota Fiscal Série '3' Gerada -> "+SF2->F2_DOC
	oProcess:bReturn  := ""
	oHTML := oProcess:oHTML

	oHtml:ValByName("NOMECOM",AllTrim(SM0->M0_NOMECOM))
	oHtml:ValByName("ENDEMP",Capital(AllTrim(SM0->M0_ENDENT)) + " - " + Capital(SM0->M0_BAIRENT))
	oHtml:ValByName("COMEMP",Transform(SM0->M0_CEPENT,"@R 99999-999") + " - " + Capital(AllTrim(SM0->M0_CIDENT)) + " - " + SM0->M0_ESTENT)
	oHtml:ValByName("FONE","Fone/Fax: " + SM0->M0_TEL + " / " + SM0->M0_FAX)
	oHtml:ValByName("CGC","CNPJ: " +Transform(SM0->M0_CGC,"@R 99.999.999/9999-99"))
	oHtml:ValByName("INSC","Inscrição Estadual: " + SM0->M0_INSC)

	oHtml:ValByName("numero",SF2->F2_DOC+" - "+SF2->F2_SERIE)
	oHtml:ValByName("emissao",SF2->F2_EMISSAO)
	oHtml:ValByName("cliente",SF2->F2_CLIENTE+"/"+SF2->F2_LOJA+"  "+Posicione("SA1",1,xFilial("SA1")+SF2->F2_CLIENTE+SF2->F2_LOJA,"A1_NOME"))
	oHtml:ValByName("pedido",Posicione("SD2",3,xFilial("SD2")+SF2->F2_DOC+SF2->F2_SERIE,"D2_PEDIDO"))
	oHtml:ValByName("condicao",SF2->F2_COND+" -"+Posicione("SE4",1,xFilial("SE4")+SF2->F2_COND,"E4_DESCRI"))
	oHtml:ValByName("endereco",Posicione("SA1",1,xFilial("SA1")+SF2->F2_CLIENTE+SF2->F2_LOJA,"A1_END")+" - "+Posicione("SA1",1,xFilial("SA1")+SF2->F2_CLIENTE+SF2->F2_LOJA,"A1_BAIRRO"))
	oHtml:ValByName("municipio",Posicione("SA1",1,xFilial("SA1")+SF2->F2_CLIENTE+SF2->F2_LOJA,"A1_MUN")+" - "+Posicione("SA1",1,xFilial("SA1")+SF2->F2_CLIENTE+SF2->F2_LOJA,"A1_EST"))

	Dbselectarea("SD2")
	Dbsetorder(3)
	Dbseek(xFilial("SD2")+SF2->F2_DOC+SF2->F2_SERIE+SF2->F2_CLIENTE+SF2->F2_LOJA)
	While !Eof() .and. SD2->D2_FILIAL == xFilial("SD2") .and. SD2->D2_DOC == SF2->F2_DOC .and. SD2->D2_SERIE == SF2->F2_SERIE

		AAdd((oHtml:ValByName("P.IT")),SD2->D2_ITEM)
		AAdd((oHtml:ValByName("P.PRODUTO")),SD2->D2_COD)
		AAdd((oHtml:ValByName("P.DESCRICAO")),Posicione("SB1",1,xFilial("SB1")+SD2->D2_COD,"B1_DESC"))
		AAdd((oHtml:ValByName("P.QUANT")),Transform(SD2->D2_QUANT,"@E 9,999,999.99"))
		AAdd((oHtml:ValByName("P.PRCTAB")),Transform(SD2->D2_PRUNIT,"@E 9,999,999.99"))
		AAdd((oHtml:ValByName("P.PRCVEN")),Transform(SD2->D2_PRCVEN,"@E 9,999,999.99"))
		AAdd((oHtml:ValByName("P.PDESC")),Transform((SD2->D2_PRUNIT - SD2->D2_PRCVEN)/SD2->D2_PRUNIT,"@E 999.99"))
		AAdd((oHtml:ValByName("P.VALOR")),Transform(SD2->D2_TOTAL,"@E 9,999,999.99"))
		Dbselectarea("SD2")
		Dbskip()
	Enddo

	oHtml:ValByName("MERCADORIAS",Transform(SF2->F2_VALMERC,"@E 9,999,999.99"))
	oHtml:ValByName("TOTAL",Transform(SF2->F2_VALBRUT,"@E 9,999,999.99"))

	oHtml:ValByName("DATA",DTOC(dDataBase))
	oHtml:ValByName("HORA",Time())

	oHtml:ValByName("USUARIO",SubStr(cUsuario,7,15))
	oProcess:cTo := "fiscal1@atrialub.com.br"

	oProcess:Start()


Return


/*/{Protheus.doc} sfAtuTit
// Efetua ajuste do percentual de Produtos MIchelin da nota fiscal nos títulos gerados. 
@author Marcelo Alberto Lauschner
@since 18/10/2019
@version 1.0
@return ${return}, ${return_description}
@type function
/*/
Static Function sfAtuTit()

	Local	aAreaOld		:= GetArea()
	Local	cQry			:= ""
	Local	nPerMich		:= 0

	if SF2->F2_TIPO != 'D'		// diferente de devolução
		
		cQry := "SELECT ROUND(SUM(CASE WHEN B1_CABO IN ('MIC','MOT') THEN D2_VALBRUT ELSE 0 END) / SUM(D2_VALBRUT) * 100,2) PERC_MICHELIN "
		cQry += "  FROM " + RetSqlName("SD2") + " D2," + RetSqlName("SB1") + " B1," + RetSqlName("SF4") +" F4 "
		cQry += " WHERE B1.D_E_L_E_T_ =' ' "
		cQry += "   AND B1_COD = D2_COD "
		cQry += "   AND B1_FILIAL = '"+xFilial("SD1")+"' " 
		cQry += "   AND F4.D_E_L_E_T_ =' ' "
		cQry += "   AND F4_DUPLIC = 'S' "
		cQry += "   AND F4_CODIGO = D2_TES "
		cQry += "   AND F4_FILIAL = '"+xFilial("SD2")+"' "
		cQry += "   AND D2_LOJA = '" + SF2->F2_LOJA + "' "
		cQry += "   AND D2_CLIENTE = '"+SF2->F2_CLIENTE+"' "
		cQry += "   AND D2_SERIE = '"+SF2->F2_SERIE+"' "
		cQry += "   AND D2_DOC = '"+SF2->F2_DOC+"' "
		cQry += "   AND D2.D_E_L_E_T_ =' ' 
		cQry += "   AND D2_FILIAL = '"+xFilial("SD2")+"' "

		TcQuery cQry New Alias "QMIC"

		If !Eof()
			nPerMich	:= QMIC->PERC_MICHELIN
		Endif
		QMIC->(DbCloseArea())
		
		// 
		DbSelectArea("SE1")
		DbSetOrder(2) // E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
		DbSeek(xFilial("SE1")+SF2->F2_CLIENTE+SF2->F2_LOJA+SF2->F2_PREFIXO+SF2->F2_DUPL)
		While !Eof() .And. SE1->E1_CLIENTE == SF2->F2_CLIENTE .And. SE1->E1_LOJA == SF2->F2_LOJA .And. SE1->E1_PREFIXO == SF2->F2_PREFIXO .And. SE1->E1_NUM == SF2->F2_DUPL
			DbSelectArea("SE1")
			RecLock("SE1",.F.)
			SE1->E1_XPERMIC	:= nPerMich
			MsUnlock()
			SE1->(DbSkip())
		Enddo
	endif
	RestArea(aAreaOld)

Return 
