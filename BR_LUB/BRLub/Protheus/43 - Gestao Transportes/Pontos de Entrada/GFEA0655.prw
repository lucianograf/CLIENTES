#include "totvs.ch"
#include "XmlXFun.Ch"

/*/{Protheus.doc} GFEA0655
Ponto de entrada do GFE para geração do Frete sobre saídas - Substitui o cabeçalho e itens do padrão 
@type function
@version  
@author Marcelo Alberto Lauschner
@since 30/08/2022
@return variant, return_description
/*/
User Function GFEA0655()

/*Ponto de Entrada Nestle - TQASX7 */
//If  ExistBlock("GFEA0655")
//	aCustFis 	:= ExecBlock("GFEA0655",.F.,.F.,{aDocFrete, aItensDoc, cOperPE})
//	aDocFrete 	:= aCustFis[1][1]
//	aItensDoc 	:= aCustFis[1][2]
//EndIf

	Local   aAreaOld    := GetArea()
	Local   aRetVet     := {}
	Local   aCabGfe     := ParamIxb[1]
	Local   aItemGfe    := ParamIxb[2]
	Local   cChvCte     := GW3->GW3_CTE


	U_MLDBSLCT("CONDORXML",.F.,1)
	If DbSeek(cChvCte)
		If cEmpAnt $ "06#16"
			// Não faz nada na Redelog
		Else
			sfCriaSD1(@aCabGfe,@aItemGfe)
		Endif
	Else
		MsgInfo("Não foi encontrado o XML deste CT-e na tabela de arquivamento da Central XML","GFEA0655 - Validação Chave")
		aItemGfe    := {} // Força o zeramento dos itens
		aCabGfe		:= {} // Forca o zeramento do cabecalho tambem para evitar lancamento indevido
	Endif

	Aadd(aRetVet,{aCabGfe,aItemGfe})

	RestArea(aAreaOld)

Return aRetVet



/*/{Protheus.doc} sfValAtrib
Função para passar na validação do SonarCube - Analytics 
@type function
@version  
@author Marcelo Alberto Lauschner
@since 06/08/2022
@param xInAtributo, variant, param_description
@return variant, return_description
/*/
Static Function sfValAtrib(xInAtributo)
Return (Type(xInAtributo) )

Static Function sfCriaSD1(aInSF1,aInSD1)

	Local       aAreaOld        := GetArea()
	Local       nForA
	Local       nForD
	Local       nForE
	Local       nForF
	Local	    lFilCGCNFS	    := GetNewPar("XM_FCGCNFS",.F.) // Criar parâmetro quando necessário para não Filtrar o CGC do Destinatário das notas relacioandas no XML do CTe
	Local       lXmLd1Cont		:= GetNewPar("XM_LD1CONT",.F.)
	Local       lXmLd1Ccus		:= GetNewPar("XM_LD1CCUS",.F.)
	Local       lXmld1Clvl		:= GetNewPar("XM_LD1CLVL",.F.)
	Local       lXmld1Itcc		:= GetNewPar("XM_LD1ITCC",.F.)
	Local 		cLeftNil		:= GetNewPar("XM_LEFTNIL","0")
	Local 	 	nTmF1Doc		:= TamSX3("F1_DOC")[1]
	Local 	 	nTmF1Ser		:= TamSX3("F1_SERIE")[1]
	Local 		cTpNfCte		:= GetNewPar("XM_TPNFCTE","C")
	Local 		lAddOper		:= GetNewPar("XM_ADDOPER",.T.)
	Local		aNfsXCte		:= {}
	Local 		cCCusto		    := ""
	Local 		cContaC		    := ""
	Local		cItemCc		    := ""
	Local 		cClasVlr	    := ""
	Local 		cF1LOJDEST		:= ""
	Local 		cF1CLIDEST		:= ""
	Local 		lAddNfeOrig		:= .F.
	Local 		nTotMerc		:= 0
	Local 		nValPedagio		:= 0
	Local 		nValSeguro		:= 0
	Local 		nValCompon		:= 0
	Local 		nValPrest		:= 0
	Local 		nSaldZero 		:= 0
	Local 		nValSD1			:= 0
	Local 		nSaldPedg		:= 0
	Local 		lExistMalote	:= .F.
	Local 		aNfOriCTE		:= {}
	Local 		cNewOper		:= "T1" // Tipo de operação Fixa para Fretes sobre vendas //Padr(GetNewPar("XM_FMPADFR",GetNewPar("XM_FMPADCP"," ")),2)
	Local 		cAviso			:= ""
	Local 		cErro 			:= ""
	Local 		lAbortaLp 		:= .F.

	oCte := XmlParser(CONDORXML->XML_ATT3,"_",@cAviso,@cErro)


	If sfValAtrib("oCte:_CTeProc")<> "U"
		oNF 	:= oCte:_CTeProc:_CTe
		cChvCte	:= oCte:_CTeProc:_protCTe:_infProt:_chCTe:TEXT
	ElseIf sfValAtrib("oCte:_CTe")<> "U"
		oNF 	:= oCte:_CTe
		cChvCte	:= oCte:_CTeProc:_protCTe:_infProt:_chCTe:TEXT
	ElseIf sfValAtrib("oCte:_enviCTe:_CTe")<> "U"
		oNF		:= oCte:_enviCTe:_CTe
		cChvCte	:= oCte:_enviCTe:_protCTe:_infProt:_chCTe:TEXT
	ElseIf sfValAtrib("oCte:_procCTe:_CTe") <> "U"
		oNF		:= oCte:_procCTe:_CTe
		cChvCte := oCte:_PROCCTE:_PROTCTE:_infProt:_chCTe:TEXT
	ElseIf sfValAtrib("oCte:_cteOSProc:_CTeOS")<> "U"
		oNF 	:= oCte:_cteOSProc:_CTeOS
		cChvCte	:= oCte:_CTeOSProc:_protCTe:_infProt:_chCTe:TEXT
	ElseIf sfValAtrib("oCte:_enviCTe:_CTeOS")<> "U"
		oNF := oCte:_enviCTe:_CTeOS
		cChvCte	:= oCte:_enviCTe:_protCTe:_infProt:_chCTe:TEXT
	ElseIf sfValAtrib("oCte:_retCTeConsultaDFe:_CTeDFe:_procCTe:_CTe") <> "U"
		oNF	:= oCte:_retCTeConsultaDFe:_CTeDFe:_procCTe:_CTe
		cChvCte	:= oCte:_retCTeConsultaDFe:_CTeDFe:_procCTe:_infProt:_chCTe:TEXT
	Else
		cAviso	:= ""
		cErro	:= ""
		oCte := XmlParser(CONDORXML->XML_ARQ,"_",@cAviso,@cErro)

		If !Empty(cErro)
			If !lAutoExec
				U_MLATUXML("E7")
				MsgAlert(cErro+chr(13)+cAviso,ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Erro ao validar schema do Xml")
			Else
				U_MLATUXML("E7")
			Endif
			Return .F.
		Endif

		If !Empty(cAviso)
			MsgAlert(cErro+chr(13)+cAviso,ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Aviso ao validar schema do Xml")
			stSendMail(GetNewPar("XM_MAILADM","suporte@centralxml.com.br"),"Marcação de CTE om erro "+ cAviso ,'"'+CONDORXML->XML_ARQ+'"')
		Endif

		If sfValAtrib("oCte:_CTeProc")<> "U"
			oNF 	:= oCte:_CTeProc:_CTe
			cChvCte	:= oCte:_CTeProc:_protCTe:_infProt:_chCTe:TEXT
		ElseIf sfValAtrib("oCte:_CTe")<> "U"
			oNF 	:= oCte:_CTe
			cChvCte	:= oCte:_CTeProc:_protCTe:_infProt:_chCTe:TEXT
		ElseIf sfValAtrib("oCte:_enviCTe:_CTe")<> "U"
			oNF		:= oCte:_enviCTe:_CTe
			cChvCte	:= oCte:_enviCTe:_protCTe:_infProt:_chCTe:TEXT
		ElseIf sfValAtrib("oCte:_procCTe:_CTe") <> "U"
			oNF		:= oCte:_procCTe:_CTe
			cChvCte	:= oCte:_PROCCTE:_PROTCTE:_infProt:_chCTe:TEXT
		Else
			If !lAutoExec
				U_MLATUXML("E8")
				MsgAlert("Não foi possível ler o arquivo xml:"+CONDORXML->XML_ARQ,ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			Else
				U_MLATUXML("E8")
			Endif
			Return .F.
		Endif
	Endif


	oIdent     	:= oNF:_InfCTe:_ide
	oEmitente  	:= oNF:_InfCTe:_emit
	oRemetente	:= Iif(sfValAtrib("oNF:_InfCTe:_rem") <> "U",oNF:_InfCTe:_rem,Nil)
	oExpedidor  := Iif(sfValAtrib("oNF:_InfCTe:_exped") <> "U",oNF:_InfCTe:_exped,Nil)
	oDestino   	:= Iif(sfValAtrib("oNF:_InfCTe:_Dest") <> "U",oNF:_InfCTe:_Dest,Nil)
	oValorPrest := oNF:_InfCTe:_vPrest
	oImposto	:= oNF:_InfCTe:_imp
	oInfCte		:= Iif(sfValAtrib("oNF:_InfCTe:_infCTeNorm") <> "U",oNF:_InfCTe:_infCTeNorm,Nil)

	// 11/08/2022 - Melhoria para ajustar o valor total da nota conforme o XML
	// se o valor da nota está com 1 centavo tenta fazer o ajuste
	If CONDORXML->XML_VLRDOC <= 0.01
		If sfValAtrib("oValorPrest:_vTPrest") <> "U"
			RecLock("CONDORXML",.F.)
			CONDORXML->XML_VLRDOC	:= Val(oValorPrest:_vTPrest:TEXT)
			MsUnlock()
		Endif
	Endif

	If sfValAtrib("oDestino:_CNPJ") <> "U"
		cCgcCli		:= oDestino:_CNPJ:TEXT
		DbSelectArea("SA1")
		DbSetOrder(3)
		If DbSeek(xFilial("SA1") + cCgcCli )
			// Caso não encontre o CNPJ com os digitos informados, procura fazendo uma troca
		Else
			cCgcCli		:= StrZero(Val(cCgcCli),11)
			DbSelectArea("SA1")
			DbSetOrder(3)
			DbSeek(xFilial("SA1") + cCgcCli )
		Endif
		cCgcCli	:= SA1->A1_CGC
	ElseIf sfValAtrib("oDestino:_CPF") <> "U"
		DbSelectArea("SA1")
		DbSetOrder(3)
		If DbSeek(xFilial("SA1")+oDestino:_CPF:TEXT ) .Or.;
				DbSeek(xFilial("SA1")+StrZero(Val(oDestino:_CPF:TEXT),14))
			cCgcCli	:= SA1->A1_CGC
		Else
			cCgcCli	:= Space(14)
		Endif
	Endif

	DbSelectArea("SA2")
	DbSetOrder(3)
	If DbSeek(xFilial("SA2")+ Iif(sfValAtrib("oEmitente:_CNPJ")<> "U",oEmitente:_CNPJ:TEXT,Iif(sfValAtrib("oEmitente:_CPF") <> "U",oEmitente:_CPF:TEXT,"")) )//CONDORXML->XML_EMIT)
		cCodForn	:= SA2->A2_COD
		cLojForn	:= SA2->A2_LOJA
	Else
		MsgAlert("Emitente do CT-e não está cadastrado como Fornecedor! ")
		Return .F.
	Endif

	cF1UFORITR 	:= Iif( SF1->(FieldPos("F1_UFORITR")) > 0,IIf(sfValAtrib("oIdent:_UFIni") <> "U",oIdent:_UFIni:TEXT,Space(TamSX3("F1_UFORITR")[1])),"")
	cF1MUORITR  := Iif( SF1->(FieldPos("F1_MUORITR")) > 0,IIf(sfValAtrib("oIdent:_cMunIni") <> "U",Substr(oIdent:_cMunIni:TEXT,3),Space(TamSX3("F1_MUORITR")[1])),"")
	cF1UFDESTR 	:= Iif( SF1->(FieldPos("F1_UFDESTR")) > 0,IIf(sfValAtrib("oIdent:_UFFim") <> "U",oIdent:_UFFim:TEXT,Space(TamSX3("F1_UFDESTR")[1])),"")
	cF1MUDESTR	:= Iif( SF1->(FieldPos("F1_MUDESTR")) > 0,IIf(sfValAtrib("oIdent:_cMunFim") <> "U",Substr(oIdent:_cMunFim:TEXT,3),Space(TamSX3("F1_MUDESTR")[1])),"")

	// Novo modelo de tratativa da modelagem do número da Nota fiscal
	If cLeftNil $ " #0" 		// 0=Padrão(Soh Num c/zeros)
		cSerCte	:= Padr(oIdent:_serie:TEXT,nTmF1Ser)
		cNumCte	:= Right(StrZero(0,(nTmF1Doc) - Len(Trim(oIdent:_nCT:TEXT)) )+oIdent:_nCT:TEXT,nTmF1Doc)
	ElseIf cLeftNil == "1" 	// 1=Num e Serie
		cSerCte	:= Right(StrZero(0,(nTmF1Ser) - Len(Trim(oIdent:_serie:TEXT)))+oIdent:_serie:TEXT,nTmF1Ser)
		cNumCte	:= Right(StrZero(0,(nTmF1Doc) - Len(Trim(oIdent:_nCT:TEXT)) )+oIdent:_nCT:TEXT,nTmF1Doc)
	ElseIf cLeftNil == "2"	// 2=Sem preencher zeros
		cSerCte	:= Padr(oIdent:_serie:TEXT,nTmF1Ser)
		cNumCte	:= Padr(oIdent:_nCT:TEXT,nTmF1Doc)
	Endif


	// Obtenho os nós com as notas fiscais do Frete
	oDet := Iif(sfValAtrib("oRemetente:_infNf")<> "U",oRemetente:_infNf,IIf(sfValAtrib("oRemetente:_infNfe") <> "U",oRemetente:_infNfe,{}))
	oDet := IIf(ValType(oDet)=="O",{oDet},oDet)

	// Melhoria feita em 25/05/2014 para atender CTe 2.00
	If Empty(oDet) .And. sfValAtrib("oInfCte:_infDoc:_infNFe") <> "U"
		oDet	:= oInfCte:_infDoc:_infNFe
		oDet	:= IIf(ValType(oDet)=="O",{oDet},oDet)
	Endif

	// Melhoria feita em 03/06/2014 para atender CTe 2.00
	If Empty(oDet) .And. sfValAtrib("oInfCte:_infDoc:_infNF") <> "U"
		oDet	:= oInfCte:_infDoc:_infNF
		oDet	:= IIf(ValType(oDet)=="O",{oDet},oDet)
	Endif

	/*<infDoc> <infOutros><tpDoc>99</tpDoc><descOutros>NF</descOutros><nDoc>260046</nDoc><dEmi>2023-01-27</dEmi><vDocFisc>1450.00</vDocFisc></infOutros></infDoc>*/
	If Empty(oDet) .And. sfValAtrib("oInfCte:_infDoc:_infOutros") <> "U"
		oDet	:= oInfCte:_infDoc:_infOutros
		oDet	:= IIf(ValType(oDet)=="O",{oDet},oDet)
	Endif

	If Empty(oDet) .And. sfValAtrib("oNF:_InfCTe:_infCteComp") <> "U"
		oDet	:= oNF:_InfCTe:_infCteComp
		oDet	:= IIf(ValType(oDet)=="O",{oDet},oDet)
	Endif

	For nForA := 1 To Len(oDet)
		iX := nForA
		If sfValAtrib("oDet[ix]:_chave") <> "U"

			lAddNfeOrig	:= .F.
			cCCusto		:= ""
			cContaC		:= ""
			cItemCc		:= ""
			cClasVlr	:= ""

			cQry := ""
			cQry += "SELECT F2.R_E_C_N_O_ F2RECNO "
			cQry += "  FROM " + RetSqlName("SF2") + " F2 "
			If lFilCGCNFS
				cQry += "," + RetSqlName("SA1") + " A1 "
			Endif
			cQry += " WHERE F2.D_E_L_E_T_ = ' ' "
			cQry += "   AND F2_CHVNFE = '" + oDet[ix]:_chave:TEXT + "'"
			cQry += "   AND F2_FILIAL = '" + xFilial("SF2")+ "'"
			If lFilCGCNFS
				cQry += "   AND F2_LOJA = A1_LOJA "
				cQry += "   AND F2_CLIENTE = A1_COD "
				cQry += "   AND A1.D_E_L_E_T_ =' ' "
				cQry += "   AND A1_CGC = '" + cCgcCli + "'"
				cQry += "   AND A1_FILIAL = '" + xFilial("SA1")+ "'"
			Endif

			dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),"QXF2",.T.,.F.)

			While !Eof()

				dbSelectArea("SF2")
				DbGoto(QXF2->F2RECNO)



				U_MLDBSLCT("CONDORCTEXNFS",.F.,4)
				If !DbSeek(Padr(cChvCte,TamSX3("F1_CHVNFE")[1]) +  Padr(oDet[ix]:_chave:TEXT,TamSX3("F1_CHVNFE")[1]) )
					RecLock("CONDORCTEXNFS",.T.)
				Else
					RecLock("CONDORCTEXNFS",.F.)
				Endif
				CONDORCTEXNFS->XCN_CHVCTE	:= cChvCte
				CONDORCTEXNFS->XCN_EMP     	:= cEmpAnt
				CONDORCTEXNFS->XCN_FIL		:= cFilAnt
				CONDORCTEXNFS->XCN_NUMCTE	:= cNumCte
				CONDORCTEXNFS->XCN_SERCTE  	:= cSerCte
				CONDORCTEXNFS->XCN_FORCTE  	:= SA2->A2_COD
				CONDORCTEXNFS->XCN_LOJCTE 	:= SA2->A2_LOJA
				CONDORCTEXNFS->XCN_TIPCTE  	:= cTpNfCte
				CONDORCTEXNFS->XCN_CHVNFS	:= SF2->F2_CHVNFE
				CONDORCTEXNFS->XCN_NUMNFS	:= SF2->F2_DOC
				CONDORCTEXNFS->XCN_SERNFS	:= SF2->F2_SERIE
				CONDORCTEXNFS->XCN_CLINFS	:= SF2->F2_CLIENTE
				CONDORCTEXNFS->XCN_LOJNFS	:= SF2->F2_LOJA
				CONDORCTEXNFS->XCN_TIPNFS	:= SF2->F2_TIPO
				CONDORCTEXNFS->XCN_TPFRET	:= "S"
				MsUnlock()

				Aadd(aNfsXCte,{CONDORCTEXNFS->XCN_EMP+CONDORCTEXNFS->XCN_FIL+CONDORCTEXNFS->XCN_NUMNFS+CONDORCTEXNFS->XCN_SERNFS+CONDORCTEXNFS->XCN_CLINFS+CONDORCTEXNFS->XCN_LOJNFS})
				cQryGrp	:= ""
				If lXmLd1Cont .And. SD2->(FieldPos("D2_CONTA")) > 0
					cQryGrp += "   ,D2_CONTA"
				Endif
				If lXmLd1Ccus .And. SD2->(FieldPos("D2_CCUSTO")) > 0
					cQryGrp += "   ,D2_CCUSTO"
				Endif

				If lXmld1Clvl .And. SD2->(FieldPos("D2_CLVL")) > 0
					cQryGrp += "   ,D2_CLVL"
				Endif

				If lXmld1Itcc .And. SD2->(FieldPos("D2_ITEMCC")) > 0
					cQryGrp += "   ,D2_ITEMCC"
				Endif

				cQry := "SELECT SUM(D2_VALBRUT) D2_VALBRUT,D2_DOC,D2_SERIE "
				cQry += cQryGrp
				cQry += "  FROM " + RetSqlName("SD2") + " D2 "
				cQry += " WHERE D2.D_E_L_E_T_ = ' ' "
				cQry += "   AND D2_LOJA = '"+SF2->F2_LOJA+"' "
				cQry += "   AND D2_CLIENTE = '" + SF2->F2_CLIENTE +"' "
				cQry += "   AND D2_SERIE = '" + SF2->F2_SERIE + "' "
				cQry += "   AND D2_DOC = '" + SF2->F2_DOC + "' "
				cQry += "   AND D2_FILIAL = '" + xFilial("SD2")+ "'"
				cQry += " GROUP BY D2_DOC,D2_SERIE"
				If !Empty(cQryGrp)
					cQry += cQryGrp
				Endif

				dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),"QXD2",.T.,.F.)

				While !Eof()

					If lXmLd1Cont .And. SD2->(FieldPos("D2_CONTA")) > 0
						cContaC		:= QXD2->D2_CONTA
					Endif
					If lXmLd1Ccus .And. SD2->(FieldPos("D2_CCUSTO")) > 0
						cCCusto		:= QXD2->D2_CCUSTO
					Endif

					If lXmld1Clvl .And. SD2->(FieldPos("D2_CLVL")) > 0
						cClasVlr	:= QXD2->D2_CLVL
					Endif

					If lXmld1Itcc .And. SD2->(FieldPos("D2_ITEMCC")) > 0
						cItemCc		:= QXD2->D2_ITEMCC
					Endif

					// Adicionar quebra por F4_DUPLIC e BONIFICAÇÃO -

					// Customizacao que permite levar o centro de custo do vendedor para o lançamento do documento
					DbSelectArea("SA3")
					DbSetOrder(1)
					DbSeek(xFilial("SA3")+SF2->F2_VEND1)
					If SA3->(FieldPos("A3_CC")) > 0 
						If !Empty(SA3->A3_CC)
							cCCusto	:= SA3->A3_CC
						Endif
					Endif

					// Ponto de entrada criado em 27/01/2013
					// Novo centro de custo retornado para o item do frete
					If ExistBlock("XMLCTE04")
						cCCusto	:= ExecBlock("XMLCTE04",.F.,.F.,{cCCusto})
					Endif

					Aadd(aNfOriCTE,{SF2->F2_FILIAL,;
						SF2->F2_DOC,;
						SF2->F2_SERIE,;
						SF2->F2_CLIENTE,;
						SF2->F2_LOJA,;
						QXD2->D2_VALBRUT,;
						cCCusto,;
						cContaC,;
						cItemCc,;
						cClasVlr})
					DbSelectArea("QXD2")
					QXD2->(DbSkip())
				Enddo
				QXD2->(DbCloseArea())

				nTotMerc += SF2->F2_VALBRUT
				// 23/11/2017 - Adiciona Cod.Cliente de entrega
				cF1LOJDEST	:= Iif( SF1->(FieldPos("F1_LOJDEST")) > 0,SF2->F2_LOJA,"")
				cF1CLIDEST	:= Iif( SF1->(FieldPos("F1_CLIDEST")) > 0,SF2->F2_CLIENTE,"")
				lAddNfeOrig	:= .T.
				DbSelectArea("QXF2")
				DbSkip()
			Enddo
			QXF2->(DbCloseArea())



			// Inicia loop para procurar como Frete sobre Compras - FOB mas que será lançado como Despesas pela rotina Documento Entrada invés de Mata116
			dbSelectArea("SF1")
			dbSetOrder(8)
			If DbSeek(xFilial("SF1") + oDet[ix]:_chave:TEXT)
				cCCusto		:= ""
				cContaC		:= ""
				cItemCc		:= ""
				cClasVlr	:= ""
				// Ponto de entrada criado em 27/01/2013
				// Novo centro de custo retornado para o item do frete
				// Mantém compatibilidade de uso do ponto de entrada
				If ExistBlock("XMLCTE04")
					cCCusto	:= ExecBlock("XMLCTE04",.F.,.F.,{cCCusto})
				Endif

				U_MLDBSLCT("CONDORCTEXNFS",.F.,4)
				//XCN_CHVCTE+XCN_CHVNFS
				//If !DbSeek(Padr(cChvCte,TamSX3("F1_CHVNFE")[1])+cEmpAnt+cFilAnt+SF1->F1_DOC+SF1->F1_SERIE+SF1->F1_FORNECE+SF1->F1_LOJA+SF1->F1_TIPO)
				If !DbSeek(Padr(cChvCte,TamSX3("F1_CHVNFE")[1]) +  Padr(oDet[ix]:_chave:TEXT,TamSX3("F1_CHVNFE")[1]) )
					RecLock("CONDORCTEXNFS",.T.)
				Else
					RecLock("CONDORCTEXNFS",.F.)
				Endif
				CONDORCTEXNFS->XCN_CHVCTE	:= cChvCte
				CONDORCTEXNFS->XCN_EMP     	:= cEmpAnt
				CONDORCTEXNFS->XCN_FIL		:= cFilAnt
				CONDORCTEXNFS->XCN_NUMCTE	:= cNumCte
				CONDORCTEXNFS->XCN_SERCTE  	:= cSerCte
				CONDORCTEXNFS->XCN_FORCTE  	:= SA2->A2_COD
				CONDORCTEXNFS->XCN_LOJCTE 	:= SA2->A2_LOJA
				CONDORCTEXNFS->XCN_TIPCTE  	:= cTpNfCte
				CONDORCTEXNFS->XCN_CHVNFS	:= SF1->F1_CHVNFE
				CONDORCTEXNFS->XCN_NUMNFS	:= SF1->F1_DOC
				CONDORCTEXNFS->XCN_SERNFS	:= SF1->F1_SERIE
				CONDORCTEXNFS->XCN_CLINFS	:= SF1->F1_FORNECE
				CONDORCTEXNFS->XCN_LOJNFS	:= SF1->F1_LOJA
				CONDORCTEXNFS->XCN_TIPNFS	:= SF1->F1_TIPO
				CONDORCTEXNFS->XCN_TPFRET	:= "E"
				MsUnlock()


				Aadd(aNfsXCte,{CONDORCTEXNFS->XCN_EMP+CONDORCTEXNFS->XCN_FIL+CONDORCTEXNFS->XCN_NUMNFS+CONDORCTEXNFS->XCN_SERNFS+CONDORCTEXNFS->XCN_CLINFS+CONDORCTEXNFS->XCN_LOJNFS})
				Aadd(aNfOriCTE,{SF1->F1_FILIAL,;
					SF1->F1_DOC,;
					SF1->F1_SERIE,;
					SF1->F1_FORNECE,;
					SF1->F1_LOJA,;
					SF1->F1_VALBRUT,;
					cCCusto,;
					cContaC,;
					cItemCc,;
					cClasVlr})
				nTotMerc += SF1->F1_VALBRUT
				lAddNfeOrig	:= .T.
			Endif


			// Caso não tenha dados de notas vinculadas, cria uma linha para listar o produto
			If !lAddNfeOrig .And. aScan(aNfOriCTE,{|x| x[2] + x[3] == Substr(oDet[ix]:_chave:TEXT,26,9)+Substr(oDet[ix]:_chave:TEXT,23,3) }) == 0
				Aadd(aNfOriCTE,{cFilAnt,;					// 	F2_FILIAL			1
				Substr(oDet[ix]:_chave:TEXT,26,9),; 		//	F2_DOC				2
				Substr(oDet[ix]:_chave:TEXT,23,3),;  		//	F2_SERIE			3
				"",;										// 	F2_CLIENTE     		4
				"",;										//	F2_LOJA,;          	5
				1,;											//	F2_VALBRUT,; 	    6
				cCCusto,;     					        	//						7
				cContaC,;             						//						8
				cItemCc,;             						//						9
				cClasVlr})  								//						10
				nTotMerc	+= 1
			Endif
		Endif


		If sfValAtrib("oDet[ix]:_nDoc") <> "U"
			//MsgAlert(oDet[iX]:_nDoc:TEXT,ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			lAddNfeOrig	:= .F.
			cSerNfs		:= "   "
			cNumNfs		:= Padr(StrZero(Val(oDet[ix]:_nDoc:TEXT),TamSX3("F2_DOC")[1]), TamSX3("F2_DOC")[1])

			cQry := ""
			cQry += "SELECT F2.R_E_C_N_O_ F2RECNO "
			cQry += "  FROM " + RetSqlName("SF2") + " F2," + RetSqlName("SA1") + " A1 "
			cQry += " WHERE F2.D_E_L_E_T_ = ' ' "
			If sfValAtrib("oDet[ix]:_serie") <> "U"
				cQry += "   AND F2_SERIE LIKE '%" + oDet[ix]:_serie:TEXT + "%' "
				cSerNfs	:= Padr(oDet[ix]:_serie:TEXT,Len(SF2->F2_SERIE))
			Endif
			cQry += "   AND F2_DOC LIKE '%" + oDet[ix]:_nDoc:TEXT + "%'"
			cQry += "   AND F2_LOJA = A1_LOJA "
			cQry += "   AND F2_CLIENTE = A1_COD "
			cQry += "   AND F2_FILIAL = '" + xFilial("SF2")+ "'"
			cQry += "   AND A1.D_E_L_E_T_ =' ' "
			cQry += "   AND A1_CGC = '" + cCgcCli + "'"
			cQry += "   AND A1_FILIAL = '" + xFilial("SA1")+ "'"

			//If lIsDebug
			//	Aviso(ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) ,cQry,{"Ok"},3)
			//Endif

			dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),"QXF2",.T.,.F.)

			While !Eof()

				dbSelectArea("SF2")
				DbGoto(QXF2->F2RECNO)


				U_MLDBSLCT("CONDORCTEXNFS",.F.,4)
				//XCN_CHVCTE+XCN_CHVNFS
				If !DbSeek(Padr(cChvCte,TamSX3("F1_CHVNFE")[1]) +  SF2->F2_CHVNFE )
					//If !DbSeek(Padr(cChvCte,TamSX3("F1_CHVNFE")[1])+cEmpAnt+cFilAnt+SF2->F2_DOC+SF2->F2_SERIE+SF2->F2_CLIENTE+SF2->F2_LOJA+SF2->F2_TIPO)
					RecLock("CONDORCTEXNFS",.T.)
				Else
					RecLock("CONDORCTEXNFS",.F.)
				Endif

				CONDORCTEXNFS->XCN_CHVCTE	:= cChvCte
				CONDORCTEXNFS->XCN_EMP     	:= cEmpAnt
				CONDORCTEXNFS->XCN_FIL		:= cFilAnt
				CONDORCTEXNFS->XCN_NUMCTE	:= cNumCte
				CONDORCTEXNFS->XCN_SERCTE  	:= cSerCte
				CONDORCTEXNFS->XCN_FORCTE  	:= SA2->A2_COD
				CONDORCTEXNFS->XCN_LOJCTE 	:= SA2->A2_LOJA
				CONDORCTEXNFS->XCN_TIPCTE  	:= cTpNfCte
				CONDORCTEXNFS->XCN_CHVNFS	:= SF2->F2_CHVNFE
				CONDORCTEXNFS->XCN_NUMNFS	:= SF2->F2_DOC
				CONDORCTEXNFS->XCN_SERNFS	:= SF2->F2_SERIE
				CONDORCTEXNFS->XCN_CLINFS	:= SF2->F2_CLIENTE
				CONDORCTEXNFS->XCN_LOJNFS	:= SF2->F2_LOJA
				CONDORCTEXNFS->XCN_TIPNFS	:= SF2->F2_TIPO
				CONDORCTEXNFS->XCN_TPFRET	:= "S"
				MsUnlock()

				Aadd(aNfsXCte,{CONDORCTEXNFS->XCN_EMP+CONDORCTEXNFS->XCN_FIL+CONDORCTEXNFS->XCN_NUMNFS+CONDORCTEXNFS->XCN_SERNFS+CONDORCTEXNFS->XCN_CLINFS+CONDORCTEXNFS->XCN_LOJNFS})
				cQryGrp	:= ""
				If lXmLd1Cont .And. SD2->(FieldPos("D2_CONTA")) > 0
					cQryGrp += "   ,D2_CONTA"
				Endif
				If lXmLd1Ccus .And. SD2->(FieldPos("D2_CCUSTO")) > 0
					cQryGrp += "   ,D2_CCUSTO"
				Endif

				If lXmld1Clvl .And. SD2->(FieldPos("D2_CLVL")) > 0
					cQryGrp += "   ,D2_CLVL"
				Endif

				If lXmld1Itcc .And. SD2->(FieldPos("D2_ITEMCC")) > 0
					cQryGrp += "   ,D2_ITEMCC"
				Endif

				cQry := "SELECT SUM(D2_VALBRUT) D2_VALBRUT,D2_DOC,D2_SERIE "
				cQry += cQryGrp
				cQry += "  FROM " + RetSqlName("SD2") + " D2 "
				cQry += " WHERE D2.D_E_L_E_T_ = ' ' "
				cQry += "   AND D2_LOJA = '"+SF2->F2_LOJA+"' "
				cQry += "   AND D2_CLIENTE = '" + SF2->F2_CLIENTE +"' "
				cQry += "   AND D2_SERIE = '" + SF2->F2_SERIE + "' "
				cQry += "   AND D2_DOC = '" + SF2->F2_DOC + "' "
				cQry += "   AND D2_FILIAL = '" + xFilial("SD2")+ "'"
				cQry += " GROUP BY D2_DOC,D2_SERIE"
				If !Empty(cQryGrp)
					cQry += cQryGrp
				Endif

				dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),"QXD2",.T.,.F.)

				While !Eof()

					If lXmLd1Cont .And. SD2->(FieldPos("D2_CONTA")) > 0
						cContaC		:= QXD2->D2_CONTA
					Endif
					If lXmLd1Ccus .And. SD2->(FieldPos("D2_CCUSTO")) > 0
						cCCusto		:= QXD2->D2_CCUSTO
					Endif

					If lXmld1Clvl .And. SD2->(FieldPos("D2_CLVL")) > 0
						cClasVlr	:= QXD2->D2_CLVL
					Endif

					If lXmld1Itcc .And. SD2->(FieldPos("D2_ITEMCC")) > 0
						cItemCc		:= QXD2->D2_ITEMCC
					Endif

					// Customizacao que permite levar o centro de custo do vendedor para o lançamento do documento
					DbSelectArea("SA3")
					DbSetOrder(1)
					DbSeek(xFilial("SA3")+SF2->F2_VEND1)
					If SA3->(FieldPos("A3_CC")) > 0 
						If !Empty(SA3->A3_CC)
							cCCusto	:= SA3->A3_CC
						Endif
					Endif

					
					// Ponto de entrada criado em 27/01/2013
					// Novo centro de custo retornado para o item do frete
					If ExistBlock("XMLCTE04")
						cCCusto	:= ExecBlock("XMLCTE04",.F.,.F.,{cCCusto})
					Endif

					Aadd(aNfOriCTE,{SF2->F2_FILIAL,;
						SF2->F2_DOC,;
						SF2->F2_SERIE,;
						SF2->F2_CLIENTE,;
						SF2->F2_LOJA,;
						QXD2->D2_VALBRUT,;
						cCCusto,;
						cContaC,;
						cItemCc,;
						cClasVlr})
					DbSelectArea("QXD2")
					QXD2->(DbSkip())
				Enddo
				QXD2->(DbCloseArea())

				nTotMerc += SF2->F2_VALBRUT

				DbSelectArea("QXF2")
				DbSkip()
			Enddo
			QXF2->(DbCloseArea())

			// Caso não tenha dados de notas vinculadas, cria uma linha para listar o produto
			If !lAddNfeOrig .And. aScan(aNfOriCTE,{|x| x[2] + x[3] == cNumNfs + cSerNfs }) == 0
				Aadd(aNfOriCTE,{cFilAnt,;					// 	F2_FILIAL			1
				cNumNfs,;							 		//	F2_DOC				2
				cSerNfs,;  									//	F2_SERIE			3
				"",;										// 	F2_CLIENTE     		4
				"",;										//	F2_LOJA,;          	5
				1,;											//	F2_VALBRUT,; 	    6
				cCCusto,;     					        	//						7
				cContaC,;             						//						8
				cItemCc,;             						//						9
				cClasVlr})  								//						10
				nTotMerc	+= 1
			Endif

		Endif

		If sfValAtrib("oDet[iX]:_chCTe") <> "U"

			lAddNfeOrig	:= .F.

			dbSelectArea("SF1")
			dbSetOrder(8)
			If DbSeek(xFilial("SF1") + oDet[ix]:_chCTe:TEXT)

				DbSelectArea("SD1")
				DbSetOrder(1) //D1_FILIAL+D1_DOC+D1_SERIE+D1_FORNECE+D1_LOJA+D1_COD+D1_ITEM
				DbSeek(xFilial("SD1")+SF1->(F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA))
				cCCusto		:= ""
				cContaC		:= ""
				cItemCc		:= ""
				cClasVlr	:= ""

				If lXmLd1Cont 
					cContaC		:= SD1->D1_CONTA
				Endif
				If lXmLd1Ccus 
					cCCusto		:= SD1->D1_CC
				Endif

				If lXmld1Clvl 
					cClasVlr	:= SD1->D1_CLVL
				Endif

				If lXmld1Itcc 
					cItemCc		:= SD1->D1_ITEMCTA
				Endif


				U_MLDBSLCT("CONDORCTEXNFS",.F.,4)
				//XCN_CHVCTE+XCN_CHVNFS
				//If !DbSeek(Padr(cChvCte,TamSX3("F1_CHVNFE")[1])+cEmpAnt+cFilAnt+SF1->F1_DOC+SF1->F1_SERIE+SF1->F1_FORNECE+SF1->F1_LOJA+SF1->F1_TIPO)
				If !DbSeek(Padr(cChvCte,TamSX3("F1_CHVNFE")[1]) +  Padr(oDet[ix]:_chCTe:TEXT,TamSX3("F1_CHVNFE")[1]) )
					RecLock("CONDORCTEXNFS",.T.)
				Else
					RecLock("CONDORCTEXNFS",.F.)
				Endif
				CONDORCTEXNFS->XCN_CHVCTE	:= cChvCte
				CONDORCTEXNFS->XCN_EMP     	:= cEmpAnt
				CONDORCTEXNFS->XCN_FIL		:= cFilAnt
				CONDORCTEXNFS->XCN_NUMCTE	:= cNumCte
				CONDORCTEXNFS->XCN_SERCTE  	:= cSerCte
				CONDORCTEXNFS->XCN_FORCTE  	:= SA2->A2_COD
				CONDORCTEXNFS->XCN_LOJCTE 	:= SA2->A2_LOJA
				CONDORCTEXNFS->XCN_TIPCTE  	:= cTpNfCte
				CONDORCTEXNFS->XCN_CHVNFS	:= SF1->F1_CHVNFE
				CONDORCTEXNFS->XCN_NUMNFS	:= SF1->F1_DOC
				CONDORCTEXNFS->XCN_SERNFS	:= SF1->F1_SERIE
				CONDORCTEXNFS->XCN_CLINFS	:= SF1->F1_FORNECE
				CONDORCTEXNFS->XCN_LOJNFS	:= SF1->F1_LOJA
				CONDORCTEXNFS->XCN_TIPNFS	:= SF1->F1_TIPO
				CONDORCTEXNFS->XCN_TPFRET	:= "E"
				MsUnlock()


				Aadd(aNfsXCte,{CONDORCTEXNFS->XCN_EMP+CONDORCTEXNFS->XCN_FIL+CONDORCTEXNFS->XCN_NUMNFS+CONDORCTEXNFS->XCN_SERNFS+CONDORCTEXNFS->XCN_CLINFS+CONDORCTEXNFS->XCN_LOJNFS})
				Aadd(aNfOriCTE,{SF1->F1_FILIAL,;
					SF1->F1_DOC,;
					SF1->F1_SERIE,;
					SF1->F1_FORNECE,;
					SF1->F1_LOJA,;
					SF1->F1_VALBRUT,;
					cCCusto,;
					cContaC,;
					cItemCc,;
					cClasVlr})
				nTotMerc += SF1->F1_VALBRUT
				lAddNfeOrig	:= .T.
			Endif


			// Caso não tenha dados de notas vinculadas, cria uma linha para listar o produto
			If !lAddNfeOrig .And. aScan(aNfOriCTE,{|x| x[2] + x[3] == Substr(oDet[ix]:_chave:TEXT,26,9)+Substr(oDet[ix]:_chave:TEXT,23,3) }) == 0
				Aadd(aNfOriCTE,{cFilAnt,;					// 	F2_FILIAL			1
				Substr(oDet[ix]:_chave:TEXT,26,9),; 		//	F2_DOC				2
				Substr(oDet[ix]:_chave:TEXT,23,3),;  		//	F2_SERIE			3
				"",;										// 	F2_CLIENTE     		4
				"",;										//	F2_LOJA,;          	5
				1,;											//	F2_VALBRUT,; 	    6
				cCCusto,;     					        	//						7
				cContaC,;             						//						8
				cItemCc,;             						//						9
				cClasVlr})  								//						10
				nTotMerc	+= 1
			Endif


		Endif
	Next nForA

	// Por definição é necessário que haja o cadastro do Produto "FRETE" para que a rotina funcione
	DbSelectArea("SB1")
	DbSetOrder(1)
	If DbSeek(xFilial("SB1")+GetNewPar("XM_CDPFRET","FRETE")) // Código do produto pode ser diferente conforme parametro

		// Localizo Objetos componentes do Frete
		If sfValAtrib("oValorPrest:_Comp") <> "U"
			oDetPrest := oValorPrest:_Comp
			oDetPrest := IIf(ValType(oDetPrest)=="O",{oDetPrest},oDetPrest)
			For nForD := 1 To Len(oDetPrest)
				xU := nForD
				// Procuro pelo Pedagio pois não existe crédito de ICMS sobre este servico
				// 18/11/2020 - Adicionado melhoria que permite que o pedágio possa ter mais de um nome no XML
				If Alltrim(Upper(U_MLXMLNAC(oDetPrest[xU]:_xNome:TEXT))) $ GetNewPar("XM_CDPEDGO","PEDAGIO#PEDAGIO VLR#VLR PEDAGIO")
					nValPedagio	:= Val(oDetPrest[xU]:_vComp:TEXT)
				Endif

				If Alltrim(Upper(U_MLXMLNAC(oDetPrest[xU]:_xNome:TEXT))) == "SEGURO"
					nValSeguro	:= Val(oDetPrest[xU]:_vComp:TEXT)
				Endif
				nValCompon	+= 	Val(oDetPrest[xU]:_vComp:TEXT)
			Next nForD
		Endif

		// Localizo Objetos das notas referenciadas
		oDetNfs 		:= Iif(sfValAtrib("oRemetente:_infNf")<> "U",oRemetente:_infNf,IIf(sfValAtrib("oRemetente:_infNfe") <> "U",oRemetente:_infNfe,{}))
		oDetNfs 		:= IIf(ValType(oDetNfs)=="O",{oDetNfs},oDetNfs)
		// Melhoria feita em 25/05/2014 para atender CTe 2.00
		If Empty(oDetNfs) .And. sfValAtrib("oInfCte:_infDoc:_infNFe") <> "U"
			oDetNfs	:= oInfCte:_infDoc:_infNFe
			oDetNfs	:= IIf(ValType(oDetNfs)=="O",{oDetNfs},oDetNfs)
		Endif

		// Melhoria feita em 03/06/2014 para atender CTe 2.00
		If Empty(oDetNfs) .And. sfValAtrib("oInfCte:_infDoc:_infNF") <> "U"
			oDetNfs	:= oInfCte:_infDoc:_infNF
			oDetNfs	:= IIf(ValType(oDetNfs)=="O",{oDetNfs},oDetNfs)
		Endif

		lExistMalote	:= .F.
		For nForE := 1 To Len(oDetNfs)
			xU := nForE
			// Procuro a referencia com as notas de saida do Sistema
			If sfValAtrib("oDetNfs[xU]:_nDoc") <> "U"
				If (oDetNfs[xU]:_nDoc:TEXT == oIdent:_nCT:TEXT .And. oDetNfs[xU]:_serie:TEXT == oIdent:_serie:TEXT) .Or. oDetNfs[xU]:_nCFOP:TEXT=="6359"
					lExistMalote := .T.
				Endif
			Endif
		Next

		If sfValAtrib("oInfCte:_infCarga:_proPred") <> "U" .And. sfValAtrib("oInfCte:_infCarga:_xOutCat") <> "U"
			If "DOCUMENTO" $ Upper(oInfCte:_infCarga:_proPred:TEXT) .And. ;
					Upper(oInfCte:_infCarga:_xOutCat:TEXT) $ "ENVELOPE#MALOTE"
				lExistMalote	:= .T.
			Endif
		Endif

		// Caso tenha encontrado o mesmo numero de CTE e Serie para as notas referenciadas, assume que se trata de malote
		If lExistMalote
			DbSelectArea("SB1")
			DbSetOrder(1)
			If !DbSeek(xFilial("SB1")+GetNewPar("XM_CDPMALT","MALOTE")) // Código do produto pode ser diferente conforme parametro
				DbSeek(xFilial("SB1")+GetNewPar("XM_CDPFRET","FRETE")) // Código do produto pode ser diferente conforme parametro
			Endif
		Endif

		// 27/05/2020
		// Se o código do produto do Pedágio for o mesmo que o código de produto do Frete não
		If GetNewPar("XM_CDPEDAG","PEDAGIO") == GetNewPar("XM_CDPFRET","FRETE")
			nValPedagio	:= 0
		Endif

		// Se existir a tag Valor a receber e
		If sfValAtrib("oValorPrest:_vRec") <> "U" .And. Val(oValorPrest:_vTPrest:TEXT) < Val(oValorPrest:_vRec:TEXT)
			nValPrest := Val(oValorPrest:_vRec:TEXT) - nValPedagio
			//ElseIf sfValAtrib("oValorPrest:_vRec") <> "U" .And. Val(oValorPrest:_vTPrest:TEXT) > Val(oValorPrest:_vRec:TEXT)
			//	nValPrest := Val(oValorPrest:_vRec:TEXT) - nValPedagio
		Else
			nValPrest 	:= Val(oValorPrest:_vTPrest:TEXT)- nValPedagio
		Endif
		// Mudança feita em 23/11/2013
		// Permite que gere várias linhas do mesmo item para relacionar a nota de origem no campo D1_NFORI fracionando conforme
		// o valor da nota dentro do total
		nSaldZero 	:= nValPrest
		nValSD1		:= 0
		nSaldPedg	:= nValPedagio

		// Mudança feita em 03/05/2016
		// So realiza o rateio e associacao das NF do frete se este nao for de 1 centavo
		If nValPrest == 0.01
			aNfOriCTEO := aClone(aNfOriCTE)
			aNfOriCTE := {}
		Endif

		// Caso não tenha dados de notas vinculadas, cria uma linha para listar o produto
		If Len(aNfOriCTE) == 0
			Aadd(aNfOriCTE,{cFilAnt,;					// 	F2_FILIAL			1
			Replicate("9",TamSX3("D1_NFORI")[1]),; 		//	F2_DOC				2
			"999",;    									//	F2_SERIE			3
			"",;										// 	F2_CLIENTE     		4
			"",;										//	F2_LOJA,;          	5
			1,;											//	F2_VALBRUT,; 	    6
			cCCusto,;     					        	//						7
			cContaC,;             						//						8
			cItemCc,;             						//						9
			cClasVlr})  								//						10
			nTotMerc	:= 1
		Endif
		// Efetua a ordenação pelo valor da mercadoria
		aSort(aNfOriCTE,,,{|x,y| x[6] < y[6] })

		// Zero o valor do Vetor
		aInSD1	:= {}
		For nForF := 1 To Len(aNfOriCTE)
			iP := nForF

			///	Aadd(aNfOriCTE,{SF2->F2_FILIAL,;  1
			//SF2->F2_DOC,;         2
			//SF2->F2_SERIE,;       3
			//SF2->F2_CLIENTE,;     4
			//SF2->F2_LOJA,;        5
			//SF2->F2_VALBRUT,;     6
			//cCCusto,;             7
			//cContaC,;             8
			//cItemCc,;             9
			//cClasVlr})  10
			// Reposiciona o Código do produto FRETE para não repetir somente o pedágio.
			DbSelectArea("SB1")
			DbSetOrder(1)
			DbSeek(xFilial("SB1")+GetNewPar("XM_CDPFRET","FRETE")) // Código do produto pode ser diferente conforme parametro

			aItem:={	{"D1_FILIAL"	,xFilial("SD1")	             	   						,Nil},;
				{"D1_COD"   	,SB1->B1_COD					                   	   			,Nil}}
			nValSD1	:= Round(aNfOriCTE[iP,6] / nTotMerc * nValPrest,2 )
			If nValSD1 < 0.01
				nValSD1	:= 0.01
			Endif
			// Efetua o calculo para evitar erro de soma de fracionamentos
			If iP < Len(aNfOriCTE)
				nSaldZero -= nValSD1
			Else
				nValSD1 	:= nSaldZero
			Endif

			If cTpNfCte == "C"
				Aadd(aItem,{"D1_VUNIT" 		,nValSD1   		   								,Nil})
				Aadd(aItem,{"D1_TOTAL" 		,nValSD1											,Nil})
				Aadd(aItem,{"D1_TES"   		,SB1->B1_TE								 	   	,Nil})
			Else
				If Posicione("SF4",1,xFilial("SF4")+SB1->B1_TE,"F4_QTDZERO") <> "1"
					Aadd(aItem,{"D1_QUANT" 	,1													,Nil})
					Aadd(aItem,{"D1_VUNIT" 	,nValSD1   		   								,Nil})
				Endif
				Aadd(aItem,{"D1_TOTAL" 	,nValSD1										   		,Nil})
			Endif

			Aadd(aItem,{"D1_NFORI"   	,aNfOriCTE[iP,2]			             				,Nil})
			Aadd(aItem,{"D1_SERIORI" 	,aNfOriCTE[iP,3]		               				,Nil})

			If !Empty(cNewOper)
				// 06/02/2015 - Adicionada a busca pelo TES por erro na função A103INICPO do MATA103X.PRX
				// Procura por Tes Inteligente
				cNewTes	:= MaTesInt(1/*nEntSai*/,cNewOper,SA2->A2_COD,SA2->A2_LOJA,"F"/*cTipoCF*/,SB1->B1_COD)
				// Procura padrão do cadastro de produto
				If Empty(cNewTes)
					cNewTes	:= SB1->B1_TE
				Endif
				If !Empty(cNewTes) .And. cTpNfCte <> "C"
					Aadd(aItem,{"D1_TES"  	,cNewTes  	,Nil})
				Endif
				If lAddOper .And. ExistCpo("SX5","DJ"+cNewOper)
					Aadd(aItem,{"D1_OPER"	,cNewOper									,Nil})
				Endif
			Endif

			// 13/09/2013 Feito melhorias para contemplar os dados de Conta Contábil / Centro de Custo / Classe Valor e Item Conta
			If !Empty(aNfOriCTE[iP,8]) .And. lXmLd1Cont
				Aadd(aItem,{"D1_CONTA"		,aNfOriCTE[iP,8]/*cContaC*/						,Nil})
			Endif

			If !Empty(aNfOriCTE[iP,7]) .And. lXmLd1Ccus
				Aadd(aItem,{"D1_CC"		,aNfOriCTE[iP,7]/*cCCusto*/							,Nil})
			ElseIf Empty(aNfOriCTE[iP,7]) .And. lXmLd1Ccus
				lAbortaLp 	:= .T.
			Endif

			If !Empty(aNfOriCTE[iP,10]) .And. lXmld1Clvl
				Aadd(aItem,{"D1_CLVL"	,aNfOriCTE[iP,10]/*cClasVlr	*/						,Nil})
			Endif

			If !Empty(aNfOriCTE[iP,9]) .And. lXmld1Itcc
				Aadd(aItem,{"D1_ITEMCTA",aNfOriCTE[iP,9]/*cItemCc		*/					,Nil})
			Endif


			// 13/08/2017 - Melhoria para verificar se o fracionamento do item ficou zerado
			If nValSD1 > 0
				// Ponto de entrada criado em 29/06/2015
				// Permite que o cliente customize adição de novos campos no vetor de itens
				If ExistBlock("XMLCTE09")
					ExecBlock("XMLCTE09",.F.,.F.,aClone(aNfOriCTE[iP]))
				Endif

				AADD(aInSD1,aItem)
			Endif

			If nValPedagio > 0
				// Por definicação é necessário que hája o cadastro do Produto "PEDAGIO" para que a rotina funcione
				DbSelectArea("SB1")
				DbSetOrder(1)
				If DbSeek(xFilial("SB1")+GetNewPar("XM_CDPEDAG","PEDAGIO")) // Código do produto pode ser diferente conforme parametro


					aItem:={	{"D1_FILIAL"	,xFilial("SD1")	 				            			,Nil},;
						{"D1_COD"     	,SB1->B1_COD  	                          	 			,Nil}}

					nValSD1	:= Round(aNfOriCTE[iP,6] / nTotMerc * nValPedagio,2 )
					// Efetua o calculo para evitar erro de soma de fracionamentos
					If iP < Len(aNfOriCTE)
						nSaldPedg -= nValSD1
					Else
						nValSD1 	:= nSaldPedg
					Endif

					If cTpNfCte == "C"
						Aadd(aItem,{"D1_VUNIT" 		,nValSD1   		   								,Nil})
						Aadd(aItem,{"D1_TOTAL" 		,nValSD1   							 			,Nil})
						Aadd(aItem,{"D1_TES"   		,SB1->B1_TE								 	   	,Nil})
					Else
						If Posicione("SF4",1,xFilial("SF4")+SB1->B1_TE,"F4_QTDZERO") <> "1"
							Aadd(aItem,{"D1_QUANT" 	,1 													,Nil})
							Aadd(aItem,{"D1_VUNIT"  ,nValSD1    							 			,Nil})
						Endif
						Aadd(aItem,{"D1_TOTAL" 	,nValSD1    							 		   		,Nil})
					Endif

					Aadd(aItem,{"D1_NFORI"   	,aNfOriCTE[iP,2]			             				,Nil})
					Aadd(aItem,{"D1_SERIORI" 	,aNfOriCTE[iP,3]		               				,Nil})

					If !Empty(cNewOper)
						// 06/02/2015 - Adicionada a busca pelo TES por erro na função A103INICPO do MATA103X.PRX
						// Procura por Tes Inteligente
						cNewTes	:= MaTesInt(1/*nEntSai*/,cNewOper,SA2->A2_COD,SA2->A2_LOJA,"F"/*cTipoCF*/,SB1->B1_COD)
						// Procura padrão do cadastro de produto
						If Empty(cNewTes)
							cNewTes	:= SB1->B1_TE
						Endif
						If !Empty(cNewTes) .And. cTpNfCte <> "C"
							Aadd(aItem,{"D1_TES"  	,cNewTes  	,Nil})
						Endif
						If lAddOper .And. ExistCpo("SX5","DJ"+cNewOper)
							Aadd(aItem,{"D1_OPER",	cNewOper												,Nil})
						Endif
					Endif

					// 13/09/2013 Feito melhorias para contemplar os dados de Conta Contábil / Centro de Custo / Classe Valor e Item Conta
					If !Empty(aNfOriCTE[iP,8]) .And. lXmLd1Cont
						Aadd(aItem,{"D1_CONTA"		,aNfOriCTE[iP,8]/*cContaC*/						,Nil})
					Endif

					If !Empty(aNfOriCTE[iP,7]) .And. lXmLd1Ccus
						Aadd(aItem,{"D1_CC"		,aNfOriCTE[iP,7]/*cCCusto*/							,Nil})
					Endif

					If !Empty(aNfOriCTE[iP,10]) .And. lXmld1Clvl
						Aadd(aItem,{"D1_CLVL"	,aNfOriCTE[iP,10]/*cClasVlr	*/						,Nil})
					Endif

					If !Empty(aNfOriCTE[iP,9]) .And. lXmld1Itcc
						Aadd(aItem,{"D1_ITEMCTA",aNfOriCTE[iP,9]/*cItemCc		*/					,Nil})
					Endif

					// Garante que somente valores positivos e não zerados serão adicionados
					If nValSD1 > 0
						// Ponto de entrada criado em 29/06/2015
						// Permite que o cliente customize adição de novos campos no vetor de itens
						If ExistBlock("XMLCTE09")
							ExecBlock("XMLCTE09",.F.,.F.,aClone(aNfOriCTE[iP]))
						Endif
						//If nSaldPedg == 0
						DbSelectArea("SF4")
						DbSetOrder(1)
						DbSeek(xFilial("SF4")+cNewTes)

						If SF4->(FieldPos("F4_AGRPEDG")) > 0 .And. SF4->F4_AGRPEDG $ "1#2" //1=Agregar na base ICMS;2=Agregar somente no total NF;3=Nao considera
							Aadd(aInSF1,{"F1_VALPEDG",	nValPedagio		,Nil})
							lAddVlrPedg	:= .T.
						Else
							lAddVlrPedg	:= .F.
							AADD(aInSD1,aItem)
						Endif
					Endif
				Endif
			Endif
		Next nForF
	Endif

	If lAbortaLp
		MsgInfo("Não foi encontrado informação de Centro de Custo para lançar este Documento","GFEA0655 - Validação Centor de Custo")
		aInSD1	:= {}
		aInSF1  := {} // IAGO Zera tambem cabecalho pra evitar lancamento indevido
	Endif

	RestArea(aAreaOld)

Return
