#INCLUDE "rwmake.ch"
#INCLUDE "topconn.ch"
#INCLUDE "tbiconn.ch"

/*/{Protheus.doc} BIG038
Ação Tmk dentro da tela de atendimento
@type function
@version 1.0
@author Marcelo Lauschner
@since 5/30/2005
/*/
User Function BIG038()
Return U_BFTMKC01()

/*/{Protheus.doc} BFTMKC01
Ação TMK dentro da Tela de Atendimento Callcenter
@type function
@version 1.0 
@author MarceloLauschner
@since 5/4/2015
/*/
User Function BFTMKC01()

	Private	cVend1i 		:= "      "
	Private 	cVend1f 	:= "999999"
	Private 	cVend2i 	:= "      "
	Private 	cVend2f 	:= "999999"
	Private		cTpcon  	:= "Acao"
	Private 	cCliente 	:= "000001"
	Private 	cLj      	:= "01"
	Private 	cRazao
	Private 	lAltCli 	:= .F.
	Private		lUsaLits	:= cEmpAnt $ "02#11"

	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()

	If Type("lProspect") <> "U" .And. lProspect
		MsgAlert("Está selecionada a opção Prospect! Rotina só funciona com cadastro de clientes!","Selecionado Prospect")
		Return
	Endif

	@ 200,1 TO 380,395 DIALOG oLeTxt TITLE OemToAnsi("Paramêtros ")
	@ 02,10 TO 070,190
	@ 10,018 Say "Vendedor inicial"
	@ 10,070 Get cVend1i   SIZE 40,10
	@ 20,018 Say "Vendedor Final"
	@ 20,070 Get cVend1f   SIZE 40,10
	@ 30,018 Say "Madrinha inicial"
	@ 30,070 Get cVend2i   SIZE 40,10
	@ 40,018 Say "Madrinha final"
	@ 40,070 Get cVend2f   SIZE 40,10
	@ 72,070 BUTTON "&Continua"  SIZE 40,15 ACTION (Processa({|| sfClientes() },"Localizando clientes"),oLeTxt:End() )
	@ 72,018 BUTTON "&Fechar"  SIZE 40,15 ACTION (oLeTxt:End() )

	Activate Dialog oLeTxt Centered


Return

/*/{Protheus.doc} sfClientes
Tela de consulta de clientes na tela do call center
@type function
@version 1.0 
@author Marcelo Lauschner
@since 5/4/2015
/*/
Static Function sfClientes()

	Local 	aCampos 	:= {}
	Local 	aStru   	:= {}
	Local	nReg    	:= 0
	Local	cQuc		:= ""
	Local	cQrd		:= ""
	Local	cArq		:= ""
	Private	cLj			:= ""
	Private	cCliente	:= ""
	Private	cRazao		:= ""

	lAltCli := .T.
	aStru:={}


	If Select("CLI") > 0
		CLI->(DbCloseArea())
	Endif

	Aadd(aStru,{ "COD"     ,"C",06,0})
	Aadd(aStru,{ "LOJA"    ,"C",02,0})
	Aadd(aStru,{ "NOME"    ,"C",40,0})
	Aadd(aStru,{ "NREDUZ"  ,"C",20,0})
	Aadd(aStru,{ "CIDADE"  ,"C",30,0})
	Aadd(aStru,{ "CONTATO" ,"C",15,0})
	Aadd(aStru,{ "DDD"     ,"C",03,0})
	Aadd(aStru,{ "FONE"    ,"C",15,0})
	Aadd(aStru,{ "ULT"     ,"D",08,0})
	Aadd(aStru,{ "ATED"    ,"D",08,0})
	Aadd(aStru,{ "TVEND"   ,"D",08,0})
	Aadd(aStru,{ "COBR"    ,"D",08,0})
	Aadd(aStru,{ "VEND"    ,"C",15,0})
	Aadd(aStru,{ "VZ"     , "C", 01, 0 })

	cArq := CriaTrab(aStru,.t.)
	dbUseArea ( .T.,__localdriver, cArq, "CLI",NIL,.F. )

	If cTpcon  <> "Campanha"
		cQrd := ""
		cQrd += "SELECT * "
		cQrd += "  FROM " + RetSqlName("SA1")
		cQrd += " WHERE A1_FILIAL = '" + xFilial("SA1") + "' "
		cQrd += "   AND A1_VEND BETWEEN '" +cVend1i + "' AND '" + cVend1f + "' "
		cQrd += "   AND A1_VEND2 BETWEEN  '" + cVend2i + "' AND '" +cVend2f+ "' "
		cQrd += " ORDER BY A1_VEND ASC,A1_ULTCOM DESC,A1_COD ASC,A1_LOJA ASC "
	Else
		If cCampanha == ""
			cCampanha := "999999"
		Endif
		cQrd := ""
		cQrd += "SELECT * "
		cQrd += "  FROM "+ RetSqlName("SA1")
		cQrd += " WHERE A1_FILIAL = '" + xFilial("SA1") + "' "
		cQrd += "   AND A1_VEND BETWEEN '" +cVend1i + "' AND '" + cVend1f + "' "
		cQrd += "   AND A1_VEND2 BETWEEN  '" + cVend2i + "' AND '" +cVend2f+ "' "
		If cEmpAnt == "02"
			cQrd += "   AND A1_CAMPANH = '" + Alltrim(substr(cCampanha,1,6)) + "' "
		Endif
		cQrd += " ORDER BY A1_VEND ASC,A1_ULTCOM DESC,A1_COD ASC,A1_LOJA ASC "
	Endif

	TCQUERY cQrd NEW ALIAS "QRD"

	Count to nReg


	Dbselectarea("QRD")
	dbgotop()
	ProcRegua(nReg)
	While !Eof()
		IncProc(QRD->A1_COD+"/"+QRD->A1_LOJA+" - "+QRD->A1_NREDUZ)

		dbSelectArea("CLI")
		RecLock("CLI",.T.)
		CLI->COD     := QRD->A1_COD
		CLI->LOJA    := QRD->A1_LOJA
		CLI->NOME    := QRD->A1_NOME
		CLI->NREDUZ  := QRD->A1_NREDUZ
		CLI->CIDADE  := QRD->A1_MUN
		CLI->CONTATO := QRD->A1_CONTATO
		CLI->DDD     := QRD->A1_DDD
		CLI->FONE    := QRD->A1_TEL
		Dbselectarea("SA3")
		dbsetorder(1)
		If Dbseek(xFilial("SA3")+QRD->A1_VEND)
			CLI->VEND    := SA3->A3_NREDUZ
		Else
			CLI->VEND    := " "
		Endif
		CLI->ULT     := STOD(QRD->A1_ULTCOM)

		cQuc := ""
		cQuc += "SELECT MAX(UC_DATA)AS ULTATEN "
		cQuc += "  FROM " + RetSqlName("SUC")
		cQuc += " WHERE D_E_L_E_T_ = ' '  "
		cQuc += "   AND UC_FILIAL = '" + xFilial("SUC") + "'  "
		cQuc += "   AND UC_ENTIDAD = 'SA1' "
		cQuc += "   AND UC_CHAVE = '" + (QRD->A1_COD+QRD->A1_LOJA) + "' "

		TCQUERY cQuc NEW ALIAS "QCU"

		Dbselectarea("QCU")
		dbgotop()
		CLI->ATED    :=  STOD(QCU->ULTATEN)

		QCU->(DbCloseArea())

		cQuc := ""
		cQuc += "SELECT MAX(UA_EMISSAO)AS ULTVEND "
		cQuc += "  FROM " + RetSqlName("SUA")
		cQuc += " WHERE D_E_L_E_T_ = ' '  "
		cQuc += "   AND UA_FILIAL = '" + xFilial("SUA") + "'  "
		cQuc += "   AND UA_CLIENTE = '" + QRD->A1_COD+ "' "
		cQuc += "   AND UA_LOJA = '" +QRD->A1_LOJA+ "' "

		TCQUERY cQuc NEW ALIAS "QCA"

		Dbselectarea("QCA")
		dbgotop()
		CLI->TVEND   :=  STOD(QCA->ULTVEND)

		QCA->(DbCloseArea())

		cQuc := ""
		cQuc += "SELECT MAX(ACF_DATA)AS ULTCOB "
		cQuc += "  FROM "+ RetSqlName("ACF")
		cQuc += " WHERE D_E_L_E_T_ = ' '  "
		cQuc += "   AND ACF_FILIAL = '" + xFilial("ACF") + "'  "
		cQuc += "   AND ACF_CLIENT = '" + QRD->A1_COD+ "' "
		cQuc += "   AND ACF_LOJA = '" +QRD->A1_LOJA+ "' "

		TCQUERY cQuc NEW ALIAS "QACF"

		Dbselectarea("QACF")
		dbgotop()

		CLI->COBR    :=   STOD(QACF->ULTCOB)
		QACF->(DbCloseArea())

		CLI->VZ      := " "
		MsUnLock("CLI")

		Dbselectarea("QRD")
		dbskip()
	Enddo
	QRD->(DbCloseArea())


	dbSelectArea("CLI")
	dbGotop()
	@ 200,1 TO 860,1014 DIALOG oDlg1 TITLE OemToAnsi("Consulta clientes")

	aCampos := {}
	Aadd(aCampos,{ "COD"     ,"Cód"})
	Aadd(aCampos,{ "LOJA"    ,"Lj",})
	Aadd(aCampos,{ "NOME"    ,"Razão"})
	Aadd(aCampos,{ "NREDUZ"  ,"Fantasia"})
	Aadd(aCampos,{ "CIDADE"  ,"Cidade"})
	Aadd(aCampos,{ "CONTATO" ,"Contato"})
	Aadd(aCampos,{ "DDD"     ,"DDD","@ 999"})
	Aadd(aCampos,{ "FONE"    ,"Fone"})
	Aadd(aCampos,{ "ULT"     ,"Últ.Comp"})
	Aadd(aCampos,{ "ATED"    ,"Últ.Atend"})
	Aadd(aCampos,{ "TVEND"   ,"Últ.Vend"})
	Aadd(aCampos,{ "COBR"    ,"Últ.Cobr"})
	Aadd(aCampos,{ "VEND"    ,"Vendedor"})
	Aadd(aCampos,{ "VZ"       ," " })

	@ 005,005 TO 300,500 BROWSE "CLI" OBJECT oBrw1 FIELDS aCampos
	@ 310,010 Button "&Notas Fiscais"  size 40,13 Action (Processa({|| sfViewNFs() },"Consultando"))
	@ 310,055 Button "Pr&odutos faturados" size 65,13 Action ( Processa({|| sfProdutos()},"Consultando"))
	@ 310,125 Button "&Cotações" size 50,13 Action ( Processa({|| sfCotacao()},"Consultando"))
	@ 310,180 Button "&Títulos em aberto" size 65,13 action( Processa ({|| sfTitView()},"Consultando"))
	@ 310,250 Button "&Pendência" size 50,13 action ( Processa ({|| sfPendencia()},"Consultando"))
	@ 310,305 Button "&Resíduos" size 50,13 action ( Processa ({|| sfResiduos()},"Consultando"))
	@ 310,360 button "&Fechar "     size 35,13 Action oDlg1:End()
	@ 310,400 Button "Pesquisar" size 40,13 Action sfSearch()
	@ 310,445 Button "Imprimir"  size 40,13 Action (Imprime(),Ord())

	ACTIVATE DIALOG oDlg1 CENTERED

	CLI->(DbCloseArea())

	FErase(cArq + GetDbExtension()) // Deleting file
	FErase(cArq + OrdBagExt()) // Deleting index

Return

Static Function Ord()

	Dbselectarea("CLI")
	dbgotop()

	oBrw1:oBrowse:Refresh()

Return


Static Function sfSearch()

	Private cPesq 		:= Space(40)
	Private aOrdpesq 		:= {"1-Código+Loja","2-Razão Social","3-Nome Reduzido","4-Contato","5-Telefone"}
	Private cComboord 	:= ""

	@ 200,001 TO 300,300 DIALOG oDlgpesq TITLE OemToAnsi("Pesquisa")
	@ 007,010 Combobox cComboord Items aOrdpesq SIZE 70,12
	@ 018,010 Get cPesq size 70,12 picture "@!"
	@ 030,035 button "Pesquisar "  size 37,13 Action (Close(oDlgpesq),sfLoopPesq())
	@ 030,070 Button "Fechar" size 40,13 Action Close(oDlgpesq)

	ACTIVATE DIALOG oDlgpesq CENTERED

Return


Static Function sfLoopPesq()

	Dbselectarea("CLI")
	dbgotop()
	While !Eof()
		If Substr(cComboord,1,1) == "1"
			If cPesq <> CLI->COD+CLI->LOJA
			Else
				oBrw1:oBrowse:Refresh()
				Exit
			Endif
		Elseif Substr(cComboord,1,1) == "2"
			If cPesq <> CLI->NOME
			Else
				oBrw1:oBrowse:Refresh()
				Exit
			Endif
		Elseif Substr(cComboord,1,1) == "3"
			If cPesq <> CLI->NREDUZ
			Else
				oBrw1:oBrowse:Refresh()
				Exit
			Endif
		Elseif Substr(cComboord,1,1) == "4"
			If cPesq <> CLI->CONTATO
			Else
				oBrw1:oBrowse:Refresh()
				Exit
			Endif
		Elseif Substr(cComboord,1,1) == "5"
			If cPesq <> CLI->FONE
			Else
				oBrw1:oBrowse:Refresh()
				Exit
			Endif
		Endif
		Dbselectarea("CLI")
		dbskip()
	Enddo

Return


Static Function sfAtuCodLj()


	If Type("M->UA_CLIENTE") <> "U"
		If !Empty(M->UA_CLIENTE)
			cCliente	:= M->UA_CLIENTE
			cLj 		:= M->UA_LOJA
			cRazao 		:= M->UA_DESCCLI
		Endif
	ElseIf Type("M->C5_CLIENTE") <> "U"
		If !Empty(M->C5_CLIENTE)
			cCliente	:= M->C5_CLIENTE
			cLj 		:= M->C5_LOJACLI
			cRazao 		:= SA1->A1_NOME
		Endif
	Endif

	If !lAltCli
		Dbselectarea("SA1")
		dbsetorder(1)
		If Dbseek(xFilial("SA1")+cCliente+cLj)
			cRazao := SA1->A1_NOME
		Else
			cRazao := ""
		Endif
	Else
		cCliente := CLI->COD
		cLj    := CLI->LOJA
		cRazao := CLI->NOME
	Endif

Return

// Consulta de notas fiscais
Static Function sfViewNFs()

	Local aCampos 	:= {}
	Local aStru   	:= {}
	Local nFat    	:= 0.00
	Local aNomeFil	:= {}
	Local lCliInGrp	:= .F.
	local cAliHist  := AllTrim( SuperGetMv( 'MV_X_ALIH',,'' ) )

	sfAtuCodLj()

	If !Empty(SA1->A1_GRPVEN)
		lCliInGrp	:= .T.
	Endif

	DbSelectArea("SM0")
	DbSetOrder(1)
	nRecSm0 	:=  SM0->(Recno())
	DbGotop()
	While !Eof()
		Aadd(aNomeFil,{SM0->M0_CODIGO + SM0->M0_CODFIL, Alltrim(SM0->M0_CODFIL)+"-"+Capital(SM0->M0_FILIAL)})
		DbSelectArea("SM0")
		DbSkip()
	Enddo
	DbSelectArea("SM0")
	DbGoto(nRecSm0)

	aStru:={}

	Aadd(aStru,{ "FILIAL" , "C", 020, 0 } )
	Aadd(aStru,{ "SERIE"  , "C", 03, 0 } )
	Aadd(aStru,{ "NOTA"   , "C", 09, 0 } )
	Aadd(aStru,{ "PEDIDO" , "C", 06, 0 } )
	Aadd(aStru,{ "EMISSAO", "D", 08, 0 } )
	Aadd(aStru,{ "VALOR"  , "N", 10, 2 } )
	Aadd(aStru,{ "TRANSP" , "C", 15, 0 } )
	Aadd(aStru,{ "CONDPAG", "C", 25, 0 })
	Aadd(aStru,{ "VENBON" , "C", 35, 0 } )
	If lCliInGrp
		Aadd(aStru,{ "CLIENTE" , "C", 080, 0 } )
	Endif
	Aadd(aStru,{ "VZ"     , "C", 01, 0 })

	cArq := CriaTrab(aStru,.t.)
	dbUseArea ( .T.,__localdriver, cArq, "NOTA", NIL, .F. )

	cQri := "SELECT * FROM ( "
	cQri += "SELECT '"+cEmpAnt+"' EMPRESA,F2_FILIAL,F2_SERIE,F2_DOC,D2_PEDIDO,F2_EMISSAO,F2_VALBRUT,F2_DUPL,F2_COND, E4_DESCRI "
	cQri += "       ,CONCAT(F2_TRANSP,'-', COALESCE((SELECT A4_NREDUZ "
	cQri += "                                   FROM "+RetSqlName("SA4")
	cQri += "                                  WHERE D_E_L_E_T_ = ' ' "
	cQri += "                                    AND A4_COD = F2_TRANSP "
	cQri += "                                    AND A4_FILIAL = '  ' ),' ' )) F2_TRANSP "
	If lCliInGrp
		cQri += "       ,CONCAT(F2_CLIENTE, '/', F2_LOJA, '-', (SELECT A1_NOME "
		cQri += "                                               FROM " + RetSqlName("SA1") + " A1 "
		cQri += "                                              WHERE A1.D_E_L_E_T_ =' ' "
		cQri += "                                                AND A1_COD = F2_CLIENTE "
		cQri += "                                                AND A1_LOJA = F2_LOJA "
		cQri += "                                                AND A1_FILIAL = '" + xFilial("SA1") + "') ) CLIENTE "
	Endif
	cQri += "  FROM "+ RetSqlName("SD2") + " SD2, " + RetSqlName("SF2") + " SF2, " + RetSqlName("SE4") + " SE4 "
	cQri += " WHERE SE4.D_E_L_E_T_ = ' ' "
	cQri += "   AND SE4.E4_CODIGO = SF2.F2_COND "
	cQri += "   AND SE4.E4_FILIAL = '"+xFilial("SE4")+"' "
	cQri += "   AND SF2.D_E_L_E_T_ = ' ' "
	cQri += "   AND SF2.F2_TIPO = 'N' "
	cQri += "   AND SF2.F2_DOC = SD2.D2_DOC "
	cQri += "   AND SF2.F2_SERIE = SD2.D2_SERIE "
	cQri += "   AND SF2.F2_LOJA = SD2.D2_LOJA "
	cQri += "   AND SF2.F2_CLIENTE = SD2.D2_CLIENTE "
	cQri += "   AND SF2.F2_FILIAL = SD2.D2_FILIAL "
	cQri += "   AND SD2.D_E_L_E_T_ = ' ' "
	If lCliInGrp
		cQri += "   AND CONCAT(SD2.D2_CLIENTE,SD2.D2_LOJA) IN(SELECT CONCAT(A1_COD,A1_LOJA) "
		cQri += "                                         FROM " + RetSqlName("SA1") + " A1 "
		cQri += "                                        WHERE A1.D_E_L_E_T_ =' ' "
		cQri += "                                          AND A1_GRPVEN = '" + SA1->A1_GRPVEN +"'"
		cQri += "                                          AND A1_FILIAL = '" + xFilial("SA1") + "')"
	Else
		cQri += "   AND SD2.D2_LOJA = '" + cLj + "' "
		cQri += "   AND SD2.D2_CLIENTE = '" + cCliente + "' "
	Endif
	cQri += "   AND SD2.D2_FILIAL IN "+FormatIN(GetMv("BF_FILIAIS"),"/")
	cQri += " GROUP BY F2_FILIAL,SF2.F2_SERIE, SF2.F2_DOC,SD2.D2_PEDIDO,SF2.F2_EMISSAO,SF2.F2_VALBRUT,SF2.F2_TRANSP,SF2.F2_DUPL,SF2.F2_COND, E4_DESCRI "
	If lCliInGrp
		cQri += " ,F2_CLIENTE,F2_LOJA "
	Endif

	// JEAN - 16/Ago/2022 - Identifica histórico do cliente importado da Onix Lub
	if !Empty( cAliHist )
		
		DBSelectArea( cAliHist )
		cQri += "UNION ALL "
		cQri += "SELECT '"+cEmpAnt+"' EMPRESA, "+ cAliHist +"_F2FILI F2_FILIAL, "+ cAliHist +"_F2SERI F2_SERIE, "+ cAliHist +"_F2DOC F2_DOC, "
		cQri += "       "+cAliHist +"_D2PEDI D2_PEDIDO, "+ cAliHist +"_F2EMIS F2_EMISSAO, "+ cAliHist +"_F2VALB F2_VALBRUT, "+ cAliHist +"_F2DUPL F2_DUPL, "
		cQri += "       "+cAliHist +"_F2COND F2_COND, "+ cAliHist +"_E4DESC E4_DESCRI, "
		cQri += "       CONCAT( "+ cAliHist +"_F2TRAN,'-', "+ cAliHist +"_A4NRED ) F2_TRANSP "
		If lCliInGrp
			cQri += "       ,CONCAT( "+ cAliHist +"_F2CLIE, '/', "+ cAliHist +"_F2LOJA, '-', "+ cAliHist +"_A1NOME ) CLIENTE "
		Endif
		cQri += "  FROM "+ RetSqlName( cAliHist ) + " "+ cAliHist +" "
		cQri += " WHERE "+ cAliHist +"."+ cAliHist +"_FILIAL IN "+ FormatIN(GetMv("BF_FILIAIS"),"/")
		cQri += "   AND "+ cAliHist +".D_E_L_E_T_ = ' ' "
		If lCliInGrp
			cQri += "   AND CONCAT("+ cAliHist +"_D2CLIE,"+ cAliHist +"_D2LOJA ) IN (SELECT CONCAT(A1_COD,A1_LOJA) "
			cQri += "                                         FROM " + RetSqlName("SA1") + " A1 "
			cQri += "                                        WHERE A1.D_E_L_E_T_ =' ' "
			cQri += "                                          AND A1_GRPVEN = '" + SA1->A1_GRPVEN +"'"
			cQri += "                                          AND A1_FILIAL = '" + xFilial("SA1") + "')"
		Else
			cQri += "   AND "+ cAliHist +"_D2LOJA = '" + cLj + "' "
			cQri += "   AND "+ cAliHist +"_D2CLIE = '" + cCliente + "' "
		Endif
		cQri += " GROUP BY "+ cAliHist +"_F2FILI, "+ cAliHist +"_F2SERI, "+ cAliHist +"_F2DOC, "+ cAliHist +"_D2PEDI, "+ cAliHist +"_F2EMIS, "
		cQri += "       "+ cAliHist +"_F2VALB, "+ cAliHist +"_F2TRAN, "+ cAliHist +"_A4NRED, "+ cAliHist +"_F2DUPL, "+ cAliHist +"_F2COND, "+ cAliHist +"_E4DESC "
		If lCliInGrp
			cQri += ", "+ cAliHist +"_F2CLIE, "+ cAliHist +"_F2LOJA, "+ cAliHist +"_A1NOME "
		Endif
	endif

	cQri += ") TEMP "
	cQri += " ORDER BY TEMP.F2_EMISSAO DESC, TEMP.F2_DOC "

	TCQUERY cQri NEW ALIAS "QF2"

	While !Eof()
		If !Empty(QF2->F2_DOC)

			cDescFilial	:= QF2->F2_FILIAL
			DbSelectArea("SM0")
			DbSetOrder(1)
			nRecSm0 	:=  SM0->(Recno())
			DbGotop()
			While !Eof()
				If SM0->M0_CODIGO == Alltrim(QF2->EMPRESA) .And. SM0->M0_CODFIL  == Alltrim(QF2->F2_FILIAL)
					cDescFilial	:= Alltrim(QF2->F2_FILIAL) +"-"+Capital(SM0->M0_FILIAL)
					Exit
				Endif
				DbSelectArea("SM0")
				DbSkip()
			Enddo
			DbSelectArea("SM0")
			DbGoto(nRecSm0)

			dbSelectArea("NOTA")
			RecLock("NOTA",.T.)
			NOTA->FILIAL   := cDescFilial
			NOTA->SERIE    := QF2->F2_SERIE
			NOTA->NOTA     := QF2->F2_DOC
			NOTA->PEDIDO   := QF2->D2_PEDIDO
			NOTA->EMISSAO  := STOD(QF2->F2_EMISSAO)
			NOTA->VALOR    := QF2->F2_VALBRUT
			NOTA->CONDPAG  :=  QF2->F2_COND+" - " +  QF2->E4_DESCRI
			NOTA->TRANSP   := QF2->F2_TRANSP

			IF QF2->F2_DUPL <> ' '
				NOTA->VENBON := "Venda com título cobrança"
			Else
				NOTA->VENBON := "Bonificação ou expositor"
			Endif
			If lCliInGrp
				NOTA->CLIENTE	:= QF2->CLIENTE
			Endif
			NOTA->VZ     := ""


			MsUnLock()
			nFat += QF2->F2_VALBRUT
		Endif
		dbSelectArea("QF2")
		dbSkip()
	End
	QF2->(DbCloseArea())

	dbSelectArea("NOTA")
	dbGotop()

	aCampos := {}
	Aadd(aCampos,{ "FILIAL"  ,"Filial NF" })
	Aadd(aCampos,{ "SERIE"    ,"Serie NF" })
	Aadd(aCampos,{ "NOTA"    ,"Nº Nota" })
	Aadd(aCampos,{ "PEDIDO"  ,"Nº Ped"  })
	Aadd(aCampos,{ "EMISSAO" ,"Emissão" })
	Aadd(aCampos,{ "VALOR"   ,"Valor","@E 999,999.99"})
	Aadd(aCampos,{ "TRANSP"  ,"Transportadora" })
	Aadd(aCampos,{ "CONDPAG" ,"Condição Pagamento" })
	Aadd(aCampos,{ "VENBON"  ,"Nota fiscal Venda ou Bonif/Expositor" })
	If lCliInGrp
		Aadd(aCampos,{"CLIENTE" , "Cliente/Loja "})
	Endif
	Aadd(aCampos,{ "VZ"      ," "})

	aSize 		:= MsAdvSize( .T., .F., 400 )		// Size da Dialog

	@ aSize[7],001  TO aSize[6] , aSize[5] DIALOG oDlg2 TITLE OemToAnsi("Consulta Notas fiscais faturadas do cliente->"+cCliente+"/"+cLj+cRazao)
	@ 005,005 TO aSize[6]/2-50,aSize[5]/2 - 05 BROWSE "NOTA" OBJECT oBrw2 FIELDS aCampos
	@ aSize[6]/2-35,015 Say "Soma de Faturamento"
	@ aSize[6]/2-35,080 Get nFat size 60,13 picture "@E 999,999,999.99" When .f.
	@ aSize[6]/2-35,160 Button "&Visualiza" size 45,13 Action (Processa({|| sfNfView(lCliInGrp) },"Consultando"))
	@ aSize[6]/2-35,225 button "&Fechar "     size 37,13 Action Close(oDlg2)

	ACTIVATE DIALOG oDlg2 CENTERED

	NOTA->(DbCloseArea())

	FErase(cArq + GetDbExtension()) // Deleting file
	FErase(cArq + OrdBagExt()) // Deleting index

Return

// Visualiza produtos
Static Function sfProdutos()

	Local aCampos 	:= {}
	Local aStru   	:= {}
	Local nFat    	:= 0.00
	Local cCodProd	:= ""
	Local lCliInGrp	:= .F.
	Local lPedCli	:= .F.
	local cAliHist  := AllTrim( SuperGetMv( 'MV_X_ALIH',,'' ) )

	sfAtuCodLj()

	If !Empty(SA1->A1_GRPVEN)
		lCliInGrp	:= .T.
	Endif

	cTpcon  := "Acao"

	If Type("M->UA_CLIENTE") <> "U"
		If Type("aCols") == "A" .And. n > 0
			cCodProd	:= aCols[n,aScan(aHeader,{|x| AllTrim(x[2]) == "UB_PRODUTO"})]
			DbSelectArea("SB1")
			DbSetOrder(1)
			If !DbSeek(xFilial("SB1")+cCodProd)
				cCodProd	:= Space(TamSX3("UB_PRODUTO")[1])
			Endif
		Endif
	Endif
	If Type("M->C5_CLIENTE") <> "U"
		If Type("aCols") == "A" .And. n > 0
			cCodProd	:= aCols[n,aScan(aHeader,{|x| AllTrim(x[2]) == "C6_PRODUTO"})]
			DbSelectArea("SB1")
			DbSetOrder(1)
			If !DbSeek(xFilial("SB1")+cCodProd)
				cCodProd	:= Space(TamSX3("C6_PRODUTO")[1])
			Endif
		Endif
	Endif

	aStru:={}

	Aadd(aStru,{ "FILIAL" , "C", 20, 0 } )
	Aadd(aStru,{ "SERIE"  , "C", 01, 0 } )
	Aadd(aStru,{ "NOTA"   , "C", 09, 0 } )
	Aadd(aStru,{ "PEDIDO" , "C", 06, 0 } )
	Aadd(aStru,{ "PEDCLI" , "C", 25, 0 } )
	If lCliInGrp
		Aadd(aStru,{ "CLIENTE" , "C" , 80,0 })
	Endif
	Aadd(aStru,{ "ORIGEM" , "C", 15, 0 } )
	Aadd(aStru,{ "EMISSAO", "D", 08, 0 } )
	Aadd(aStru,{ "PRODUTO", "C", 15, 0 } )
	Aadd(aStru,{ "DESCRI" , "C", 45, 0 } )
	Aadd(aStru,{ "QTE"    , "N", 7, 0 } )
	Aadd(aStru,{ "PRCVEN" , "N", 10, 2 } )
	Aadd(aStru,{ "PRCBRUT", "N", 10, 2 } )
	If lUsaLits
		Aadd(aStru,{ "PRCTAMP", "N", 10, 2 } )
		Aadd(aStru,{ "VLRTAMP", "N", 10, 2 } )
	Endif
	Aadd(aStru,{ "VENBON" , "C", 30, 0 } )
	Aadd(aStru,{ "CONDPAG", "C", 25, 0 })
	Aadd(aStru,{ "VZ"     , "C", 01, 0 })

	cArq := CriaTrab(aStru,.t.)
	dbUseArea ( .T.,__localdriver, cArq, "PROD", NIL, .F. )


	cQri := "SELECT * FROM ( "
	cQri += "SELECT '"+cEmpAnt+"' EMPRESA,"
	cQri += "       D2_FILIAL,D2_TOTAL,D2_SERIE,D2_DOC,D2_PEDIDO,D2_EMISSAO,D2_COD,D2_QUANT,D2_PRCVEN,D2_VALBRUT,D2_CF,D2_TES,"
	If lUsaLits
		cQri += "       B1_DESC, F4_TEXTO ,D2_VALPROM,B1_QTELITS,F2_COND,E4_DESCRI "
	Else
		cQri += "       B1_DESC, F4_TEXTO ,0 D2_VALPROM,0 B1_QTELITS,F2_COND,E4_DESCRI "
	Endif
	If lCliInGrp
		cQri += "       ,CONCAT(F2_CLIENTE,'/',F2_LOJA,'-',(SELECT A1_NOME "
		cQri += "                                               FROM " + RetSqlName("SA1") + " A1 "
		cQri += "                                              WHERE A1.D_E_L_E_T_ =' ' "
		cQri += "                                                AND A1_COD = F2_CLIENTE "
		cQri += "                                                AND A1_LOJA = F2_LOJA "
		cQri += "                                                AND A1_FILIAL = '" + xFilial("SA1") + "')) CLIENTE "
	Endif

	If SC5->(FieldPos("C5_PROPRI")) > 0
		cQri += "       ,CASE WHEN C5_PROPRI = '1' THEN '1=Receptivo' WHEN C5_PROPRI = '2' THEN '2=Ativo' WHEN C5_PROPRI = '3' THEN '3=Fax' WHEN C5_PROPRI = '4' THEN '4=Representante' ELSE '5=Msn/Email' END C5_PROPRI "
	Else
		cQri += "       ,'0' C5_PROPRI "
	Endif
	cQri += "       ,C5_XPEDCLI "
	cQri += "  FROM "+RetSqlName("SD2") + " SD2, " + RetSqlName("SB1") + " SB1, " + RetSqlName("SA1") + " SA1, "+RetSqlName("SF4") + " SF4, "
	cQri += "       " + RetSqlName("SF2") + " SF2, " + RetSqlName("SE4") + " SE4," + RetSqlName("SC5") + " C5 "
	cQri += " WHERE SF4.D_E_L_E_T_ = ' ' "
	cQri += "   AND SF4.F4_CODIGO = SD2.D2_TES "
	cQri += "   AND SF4.F4_FILIAL = SD2.D2_FILIAL "
	cQri += "   AND SE4.D_E_L_E_T_ = ' ' "
	cQri += "   AND SE4.E4_CODIGO  = F2_COND "
	cQri += "   AND SE4.E4_FILIAL = '" + xFilial("SE4")+ "'"
	cQri += "   AND SF2.D_E_L_E_T_ = ' ' "
	cQri += "   AND SF2.F2_LOJA = SD2.D2_LOJA "
	cQri += "   AND SF2.F2_CLIENTE = SD2.D2_CLIENTE "
	cQri += "   AND SF2.F2_SERIE = SD2.D2_SERIE "
	cQri += "   AND SF2.F2_DOC = SD2.D2_DOC "
	cQri += "   AND SF2.F2_FILIAL = SD2.D2_FILIAL "
	cQri += "   AND C5.D_E_L_E_T_ =' ' "
	cQri += "   AND C5_NUM = D2_PEDIDO "
	cQri += "   AND C5_FILIAL = D2_FILIAL "
	cQri += "   AND SA1.D_E_L_E_T_ = ' ' "
	cQri += "   AND SA1.A1_LOJA = SD2.D2_LOJA "
	cQri += "   AND SA1.A1_COD = SD2.D2_CLIENTE "
	cQri += "   AND SA1.A1_FILIAL = '" + xFilial("SA1") + "' "
	cQri += "   AND SB1.D_E_L_E_T_ = ' ' "
	cQri += "   AND SB1.B1_COD = SD2.D2_COD "
	If !Empty(xFilial("SB1"))
		cQri += "   AND SB1.B1_FILIAL = SD2.D2_FILIAL "
	Else
		cQri += "   AND SB1.B1_FILIAL = '" + xFilial("SB1") + "' "
	Endif
	cQri += "   AND SD2.D2_TIPO = 'N' "
	If !Empty(cCodProd)
		cQri += "  AND SD2.D2_COD = '"+cCodProd+"' "
	Endif
	cQri += "   AND SD2.D_E_L_E_T_ = ' ' "
	If lCliInGrp
		cQri += "   AND CONCAT(SD2.D2_CLIENTE,SD2.D2_LOJA) IN(SELECT CONCAT(A1_COD,A1_LOJA) "
		cQri += "                                         FROM " + RetSqlName("SA1") + " A1 "
		cQri += "                                        WHERE A1.D_E_L_E_T_ =' ' "
		cQri += "                                          AND A1_GRPVEN = '" + SA1->A1_GRPVEN +"'"
		cQri += "                                          AND A1_FILIAL = '" + xFilial("SA1") + "')"
	Else
		cQri += "   AND SD2.D2_LOJA = '" + cLj + "' "
		cQri += "   AND SD2.D2_CLIENTE = '" + cCliente + "' "
	Endif
	cQri += "   AND SD2.D2_FILIAL IN "+FormatIN(GetMv("BF_FILIAIS"),"/")

	// JEAN - 16/Ago/2022 - Adiciona histórico de vendas da Onix
	if !Empty( cAliHist )
		
		DBSelectArea( cAliHist )
		cQri += " UNION ALL "
		cQri += " SELECT '"+cEmpAnt+"' EMPRESA,"
		cQri += "       "+ cAliHist +"_D2FILI D2_FILIAL, "+ cAliHist +"_D2TOTA D2_TOTAL, "+ cAliHist +"_D2SERI D2_SERIE, "
		cQri += "       "+ cAliHist +"_D2DOC D2_DOC, "+ cAliHist +"_D2PEDI D2_PEDIDO, "+ cAliHist +"_D2EMIS D2_EMISSAO,"
		cQri += "       "+ cAliHist +"_D2COD D2_COD, "+ cAliHist +"_D2QUAN D2_QUANT, "+ cAliHist +"_D2PRCV D2_PRCVEN, "
		cQri += "       "+ cAliHist +"_D2VALB D2_VALBRUT, "+ cAliHist +"_D2CF D2_CF, "+ cAliHist +"_D2TES D2_TES, "
		If lUsaLits
			cQri += "       "+ cAliHist +"_B1DESC B1_DESC, "+ cAliHist +"_F4TEXT F4_TEXTO, "+ cAliHist +"_D2VALP D2_VALPROM, "
			cQri += "       "+ cAliHist +"_B1QTEL B1_QTELITS, "+ cAliHist +"_F2COND F2_COND, "+ cAliHist +"_E4DESC E4_DESCRI "
		Else
			cQri += "       "+ cAliHist +"_B1DESC B1_DESC, "+ cAliHist +"_F4TEXT F4_TEXTO, 0 D2_VALPROM, 0 B1_QTELITS, "
			cQri += "       "+ cAliHist +"_F2COND F2_COND, "+ cAliHist +"_E4DESC E4_DESCRI "
		Endif
		If lCliInGrp
			cQri += "       ,CONCAT( "+ cAliHist +"_F2CLIE,'/',"+ cAliHist +"_F2LOJA,'-',"+ cAliHist +"_A1NOME ) CLIENTE "
		Endif

		If ( cAliHist )->(FieldPos( cAliHist +"_C5PROP" ) ) > 0		// Se o campo existir na base
			cQri += "       ,CASE WHEN "+ cAliHist +"_C5PROP = '1' THEN '1=Receptivo' "
			cQri += "             WHEN "+ cAliHist +"_C5PROP = '2' THEN '2=Ativo' "
			cQri += "             WHEN "+ cAliHist +"_C5PROP = '3' THEN '3=Fax' "
			cQri += "             WHEN "+ cAliHist +"_C5PROP = '4' THEN '4=Representante' "
			cQri += "        ELSE '5=Msn/Email' "
			cQri += "        END C5_PROPRI "
		Else
			cQri += "       ,'0' C5_PROPRI "
		Endif
		cQri += "       ,"+ cAliHist +"_C5XPED C5_XPEDCLI "
		cQri += "  FROM "+RetSqlName( cAliHist ) + " "+ cAliHist +" "
		cQri += " WHERE "+ cAliHist +"."+ cAliHist +"_FILIAL IN "+FormatIN(GetMv("BF_FILIAIS"),"/")
		
		// Quando a digitação do pedido estiver na linha dos produtos
		If !Empty(cCodProd)
			cQri += "  AND "+ cAliHist +"_D2COD = '"+ cCodProd +"' "
		Endif

		// Quando o cliente tiver um grupo econômico cadastrado
		If lCliInGrp
			cQri += "   AND CONCAT( "+ cAliHist +"_D2CLIE, "+ cAliHist +"_D2LOJA) IN( SELECT CONCAT(A1_COD,A1_LOJA) "
			cQri += "                                         FROM " + RetSqlName("SA1") + " A1 "
			cQri += "                                        WHERE A1.D_E_L_E_T_ =' ' "
			cQri += "                                          AND A1_GRPVEN = '" + SA1->A1_GRPVEN +"'"
			cQri += "                                          AND A1_FILIAL = '" + xFilial("SA1") + "')"
		Else
			cQri += "   AND "+ cAliHist +"_D2LOJA = '" + cLj + "' "
			cQri += "   AND "+ cAliHist +"_D2CLIE = '" + cCliente + "' "
		Endif
		cQri += "   AND "+ cAliHist +".D_E_L_E_T_ = ' ' "
	endif

	cQri += ") TEMP "
	cQri += " ORDER BY TEMP.D2_EMISSAO DESC, TEMP.D2_DOC DESC , TEMP.D2_SERIE DESC, TEMP.D2_COD, TEMP.F4_TEXTO ASC "
	
	TCQUERY cQri NEW ALIAS "QD2"

	Dbselectarea("QD2")
	dbgotop()
	While !Eof()

		If !Empty(QD2->D2_DOC)
			cDescFilial	:= QD2->D2_FILIAL
			DbSelectArea("SM0")
			DbSetOrder(1)
			nRecSm0 	:=  SM0->(Recno())
			DbGotop()
			While !Eof()
				If SM0->M0_CODIGO == Alltrim(QD2->EMPRESA) .And. SM0->M0_CODFIL  == Alltrim(QD2->D2_FILIAL)
					cDescFilial	:= Alltrim(QD2->D2_FILIAL)+"-"+Capital(SM0->M0_FILIAL)
					Exit
				Endif
				DbSelectArea("SM0")
				DbSkip()
			Enddo
			DbSelectArea("SM0")
			DbGoto(nRecSm0)

			dbSelectArea("PROD")
			RecLock("PROD",.T.)
			PROD->FILIAL	:= cDescFilial
			PROD->SERIE 	:= QD2->D2_SERIE
			PROD->NOTA    	:= QD2->D2_DOC
			PROD->PEDIDO  	:= QD2->D2_PEDIDO
			PROD->PEDCLI	:= QD2->C5_XPEDCLI
			If !Empty(QD2->C5_XPEDCLI)
				lPedCli	:= .T.
			Endif
			PROD->ORIGEM	:= QD2->C5_PROPRI
			PROD->EMISSAO	:= STOD(QD2->D2_EMISSAO)
			PROD->PRODUTO 	:= QD2->D2_COD
			PROD->DESCRI  	:= QD2->B1_DESC
			PROD->QTE    	:= QD2->D2_QUANT
			PROD->PRCBRUT	:= QD2->D2_VALBRUT/QD2->D2_QUANT
			PROD->PRCVEN  	:= QD2->D2_PRCVEN
			If lUsaLits
				PROD->PRCTAMP	:= IIf( QD2->D2_VALPROM > 0 ,QD2->D2_VALPROM/QD2->D2_QUANT , 0 )
				PROD->VLRTAMP	:= IIf(  QD2->D2_VALPROM > 0 , (QD2->D2_VALPROM/QD2->D2_QUANT)/(Iif(QD2->B1_QTELITS <= 0,1,QD2->B1_QTELITS)) , 0 )
			Endif
			PROD->CONDPAG 	:=  QD2->F2_COND+" - " +  QD2->E4_DESCRI
			PROD->VENBON 	:=  QD2->D2_TES+" - " + QD2->D2_CF + " - " + QD2->F4_TEXTO
			PROD->VZ     	:= ""
			If lCliInGrp
				PROD->CLIENTE	:= QD2->CLIENTE
			Endif

			MsUnLock()
			nFat += QD2->D2_VALBRUT
		Endif
		dbSelectArea("QD2")
		dbSkip()
	Enddo
	QD2->(DbCloseArea())

	dbSelectArea("PROD")
	dbGotop()

	aCampos := {}
	Aadd(aCampos,{ "FILIAL"   ,"Filial" })
	Aadd(aCampos,{ "SERIE"    ,"Serie NF" })
	Aadd(aCampos,{ "NOTA"    ,"Nº Nota" })
	Aadd(aCampos,{ "PEDIDO"  ,"Nº Ped"  })
	If lPedCli
		Aadd(aCampos,{ "PEDCLI"  ,"Ordem Compra"  })
	Endif
	If lCliInGrp
		Aadd(aCampos,{"CLIENTE" , "Cliente/Loja "})
	Endif
	Aadd(aCampos,{ "ORIGEM"  ,"Origem Ped."  })
	Aadd(aCampos,{ "EMISSAO" ,"Emissão" })
	Aadd(aCampos,{ "PRODUTO" ,"Produto" })
	Aadd(aCampos,{ "DESCRI"  ,"Descrição" })
	Aadd(aCampos,{ "QTE"     ,"Quantidade","@E 999,999"})
	Aadd(aCampos,{ "PRCBRUT" ,"Preço Final","@E 999,999.99"})
	If lUsaLits
		Aadd(aCampos,{ "PRCTAMP" ,"R$ Tampa","@E 999,999.99"})
		Aadd(aCampos,{ "VLRTAMP" ,"R$ Tampa p/Litro","@E 999,999.99"})
	Endif
	Aadd(aCampos,{ "VENBON"  ,"TES - CFOP - Descrição do código fiscal" })
	Aadd(aCampos,{ "PRCVEN"  ,"Preço Venda","@E 999,999.99"})
	Aadd(aCampos,{ "CONDPAG" ,"Condição Pagamento" })
	Aadd(aCampos,{ "VZ"      ," "})

	aSize 		:= MsAdvSize( .T., .F., 400 )		// Size da Dialog

	@ aSize[7],001  TO aSize[6] , aSize[5] DIALOG oDlg3 TITLE OemToAnsi("Consulta produtos faturados do cliente-> "+cCliente+"/"+cLj+" "+cRazao)
	@ 005,005 TO aSize[6]/2-50,aSize[5]/2 - 05 BROWSE "PROD" OBJECT oBrw3 FIELDS aCampos
	@ aSize[6]/2-35,015 Say "Soma de Faturamento"
	@ aSize[6]/2-35,080 Get nFat size 60,13 picture "@E 999,999,999.99" when .f.

	@ aSize[6]/2-35,195 button "&Fechar "     size 37,13 Action Close(oDlg3)

	ACTIVATE DIALOG oDlg3 CENTERED

	PROD->(DbCloseArea())

	FErase(cArq + GetDbExtension()) // Deleting file
	FErase(cArq + OrdBagExt()) // Deleting index

Return


Static Function sfNfView(lCliInGrp)

	Local 	aCampos 	:= {}
	Local 	aStru   	:= {}
	Local 	nFatsub 	:= 0.00
	local   cAliHist    := AllTrim( SuperGetMv( 'MV_X_ALIH',,'' ) )    

	lCliInGrp	:= Iif(lCliInGrp <> Nil ,lCliInGrp,.F.)

	sfAtuCodLj()


	aStru:={}
	Aadd(aStru,{ "PRODUTO", "C", 15, 0 } )
	Aadd(aStru,{ "DESCRI" , "C", 45, 0 } )
	Aadd(aStru,{ "QTE"    , "N", 7, 0 } )
	Aadd(aStru,{ "PRCBRUT", "N", 10, 2 } )
	Aadd(aStru,{ "TOTAL"  , "N", 10, 2 } )
	Aadd(aStru,{ "VENBON" , "C", 40, 0 } )
	Aadd(aStru,{ "PRCVEN" , "N", 10, 2 } )
	Aadd(aStru,{ "VZ"     , "C", 01, 0 })

	cArq := CriaTrab(aStru,.t.)
	dbUseArea ( .T.,__localdriver, cArq, "PROD", NIL, .F. )

	cQri := ""
	If "-Lust" $ Alltrim(NOTA->FILIAL)
		cQri += "SELECT D2_TOTAL,D2_DOC,D2_PEDIDO,D2_EMISSAO,D2_COD,D2_QUANT,D2_PRCVEN,D2_VALBRUT,D2_CF,D2_TES,B1_DESC, F4_TEXTO "
		cQri += "  FROM BIGFORTA.SD2030 SD2, BIGFORTA.SB1030 SB1, BIGFORTA.SF4030 SF4 "
		cQri += " WHERE SF4.D_E_L_E_T_ = ' ' "
		cQri += "   AND SF4.F4_CODIGO = SD2.D2_TES "
		cQri += "   AND SF4.F4_FILIAL = SD2.D2_FILIAL "
		cQri += "   AND SB1.D_E_L_E_T_ = ' ' "
		cQri += "   AND SB1.B1_COD = SD2.D2_COD "
		cQri += "   AND SB1.B1_FILIAL = SD2.D2_FILIAL  "
		cQri += "   AND SD2.D_E_L_E_T_ = ' ' "
		//cQri += "   AND SD2.D2_LOJA = '" + cLj + "' "
		//cQri += "   AND SD2.D2_CLIENTE = '" + cCliente + "'
		cQri += "   AND SD2.D2_SERIE = '" + NOTA->SERIE + "' "
		cQri += "   AND SD2.D2_DOC = '" + NOTA->NOTA + "' "
		cQri += "   AND SD2.D2_FILIAL = '" +Substr(NOTA->FILIAL,1,2) + "'  "
		cQri += " ORDER BY SD2.D2_EMISSAO DESC, SD2.D2_DOC DESC , SD2.D2_COD ASC "
	ElseIf "01-Atri" $ Alltrim(NOTA->FILIAL)
		cQri += "SELECT D2_TOTAL,D2_DOC,D2_PEDIDO,D2_EMISSAO,D2_COD,D2_QUANT,D2_PRCVEN,D2_VALBRUT,D2_CF,D2_TES,B1_DESC, F4_TEXTO "
		cQri += "  FROM BIGFORTA.SD2040 SD2, BIGFORTA.SB1040 SB1, BIGFORTA.SF4040 SF4 "
		cQri += " WHERE SF4.D_E_L_E_T_ = ' ' "
		cQri += "   AND SF4.F4_CODIGO = SD2.D2_TES "
		cQri += "   AND SF4.F4_FILIAL = SD2.D2_FILIAL "
		cQri += "   AND SB1.D_E_L_E_T_ = ' ' "
		cQri += "   AND SB1.B1_COD = SD2.D2_COD "
		cQri += "   AND SB1.B1_FILIAL = SD2.D2_FILIAL  "
		cQri += "   AND SD2.D_E_L_E_T_ = ' ' "
		//cQri += "   AND SD2.D2_LOJA = '" + cLj + "' "
		//cQri += "   AND SD2.D2_CLIENTE = '" + cCliente + "'
		cQri += "   AND SD2.D2_SERIE = '" + NOTA->SERIE + "' "
		cQri += "   AND SD2.D2_DOC = '" + NOTA->NOTA + "' "
		cQri += "   AND SD2.D2_FILIAL = '" + Substr(NOTA->FILIAL,1,2) + "'  "
		cQri += " ORDER BY SD2.D2_EMISSAO DESC, SD2.D2_DOC DESC , SD2.D2_COD ASC "
	ElseIf "-02/" $ Alltrim(NOTA->FILIAL)
		cQri += "SELECT D2_TOTAL,D2_DOC,D2_PEDIDO,D2_EMISSAO,D2_COD,D2_QUANT,D2_PRCVEN,D2_VALBRUT,D2_CF,D2_TES,B1_DESC, F4_TEXTO "
		cQri += "  FROM BIGFORTA.SD2020 SD2, BIGFORTA.SB1020 SB1, BIGFORTA.SF4020 SF4 "
		cQri += " WHERE SF4.D_E_L_E_T_ = ' ' "
		cQri += "   AND SF4.F4_CODIGO = SD2.D2_TES "
		cQri += "   AND SF4.F4_FILIAL = SD2.D2_FILIAL "
		cQri += "   AND SB1.D_E_L_E_T_ = ' ' "
		cQri += "   AND SB1.B1_COD = SD2.D2_COD "
		cQri += "   AND SB1.B1_FILIAL = SD2.D2_FILIAL  "
		cQri += "   AND SD2.D_E_L_E_T_ = ' ' "
		//cQri += "   AND SD2.D2_LOJA = '" + cLj + "' "
		//cQri += "   AND SD2.D2_CLIENTE = '" + cCliente + "'
		cQri += "   AND SD2.D2_SERIE = '" + NOTA->SERIE + "' "
		cQri += "   AND SD2.D2_DOC = '" + NOTA->NOTA + "' "
		cQri += "   AND SD2.D2_FILIAL = '" + Substr(NOTA->FILIAL,1,2) + "'  "
		cQri += " ORDER BY SD2.D2_EMISSAO DESC, SD2.D2_DOC DESC , SD2.D2_COD ASC "
	Else
		cQri := "SELECT * FROM ( "
		cQri += "SELECT D2_TOTAL,D2_DOC,D2_PEDIDO,D2_EMISSAO,D2_COD,D2_QUANT,D2_PRCVEN,D2_VALBRUT,D2_CF,D2_TES,B1_DESC, F4_TEXTO "
		cQri += "  FROM "+RetSqlName("SD2") + " SD2, "+RetSqlName("SB1") + " SB1, "+ RetSqlName("SF4") + " SF4 "
		cQri += " WHERE SF4.D_E_L_E_T_ = ' ' "
		cQri += "   AND SF4.F4_CODIGO = SD2.D2_TES "
		cQri += "   AND SF4.F4_FILIAL = SD2.D2_FILIAL "
		cQri += "   AND SB1.D_E_L_E_T_ = ' ' "
		cQri += "   AND SB1.B1_COD = SD2.D2_COD "
		If !Empty(xFilial("SB1"))
			cQri += "   AND SB1.B1_FILIAL = SD2.D2_FILIAL "
		Else
			cQri += "   AND SB1.B1_FILIAL = '" + xFilial("SB1") + "' "
		Endif
		cQri += "   AND SD2.D_E_L_E_T_ = ' ' "
		If lCliInGrp
			cQri += "   AND CONCAT( SD2.D2_CLIENTE,'/',SD2.D2_LOJA) = '" + Substr(NOTA->CLIENTE,1,9) + "' "
		Else
			cQri += "   AND SD2.D2_LOJA = '" + cLj + "' "
			cQri += "   AND SD2.D2_CLIENTE = '" + cCliente + "'
		Endif
		cQri += "   AND SD2.D2_SERIE = '" + NOTA->SERIE + "' "
		cQri += "   AND SD2.D2_DOC = '" + NOTA->NOTA + "' "
		cQri += "   AND SD2.D2_FILIAL = '" +Substr(NOTA->FILIAL,1,2) + "'  "

		if !Empty( cAliHist )
			
			DBSelectArea( cAliHist )
			cQri += " UNION ALL "
			cQri += " SELECT "+ cAliHist +"_D2TOTA D2_TOTAL, "+ cAliHist +"_D2DOC D2_DOC, "+ cAliHist +"_D2PEDI D2_PEDIDO, "
			cQri += "        "+ cAliHist +"_D2EMIS D2_EMISSAO, "+ cAliHist +"_D2COD D2_COD, "+ cAliHist +"_D2QUAN D2_QUANT, "
			cQri += "        "+ cAliHist +"_D2PRCV D2_PRCVEN, "+ cAliHist +"_D2VALB D2_VALBRUT, "+ cAliHist +"_D2CF D2_CF, "
			cQri += "        "+ cAliHist +"_D2TES D2_TES, "+ cAliHist +"_B1DESC B1_DESC, "+ cAliHist +"_F4TEXT F4_TEXTO "
			cQri += "  FROM "+RetSqlName( cAliHist ) + " "+ cAliHist +" "
			cQri += " WHERE "+ cAliHist +"."+ cAliHist +"_FILIAL = '" +Substr(NOTA->FILIAL,1,2) + "' "

			If lCliInGrp
				cQri += "   AND CONCAT( "+ cAliHist +"_D2CLIE,'/',"+ cAliHist +"_D2LOJA) = '" + Substr(NOTA->CLIENTE,1,9) + "' "
			Else
				cQri += "   AND "+ cAliHist +"_D2LOJA = '" + cLj + "' "
				cQri += "   AND "+ cAliHist +"_D2CLIE = '" + cCliente + "' "
			Endif
			cQri += "   AND "+ cAliHist +"_D2SERI = '" + NOTA->SERIE + "' "
			cQri += "   AND "+ cAliHist +"_D2DOC  = '" + NOTA->NOTA + "' "
			cQri += "   AND "+ cAliHist +".D_E_L_E_T_ = ' ' "

		endif

		cQri += ") TEMP "
		cQri += " ORDER BY TEMP.D2_EMISSAO DESC, TEMP.D2_DOC DESC , TEMP.D2_COD ASC "
	Endif

	TCQUERY cQri NEW ALIAS "QD2"

	While !Eof()

		If !Empty(QD2->D2_DOC)
			dbSelectArea("PROD")
			RecLock("PROD",.T.)
			PROD->PRODUTO  := QD2->D2_COD
			PROD->DESCRI   := QD2->B1_DESC
			PROD->QTE      := QD2->D2_QUANT
			PROD->PRCVEN   := QD2->D2_PRCVEN
			PROD->TOTAL    := QD2->D2_TOTAL
			PROD->PRCBRUT  := QD2->D2_VALBRUT/QD2->D2_QUANT
			PROD->VZ     := ""
			PROD->VENBON :=  QD2->D2_TES+" - " + QD2->D2_CF + " - " + QD2->F4_TEXTO


			MsUnLock()
			nFatsub += QD2->D2_VALBRUT
		Endif
		dbSelectArea("QD2")
		dbSkip()
	Enddo
	QD2->(DbCloseArea())


	dbSelectArea("PROD")
	dbGotop()

	aCampos := {}
	Aadd(aCampos,{ "PRODUTO" ,"Produto" })
	Aadd(aCampos,{ "DESCRI"  ,"Descrição" })
	Aadd(aCampos,{ "QTE"     ,"Quantidade","@E 999,999"})
	Aadd(aCampos,{ "PRCBRUT" ,"Preço Final","@E 999,999.99"})
	Aadd(aCampos,{ "TOTAL"   ,"Total Item" ,"@E 999,999.99"})
	Aadd(aCampos,{ "VENBON"  ,"TES - CFOP - Descrição do código fiscal" })
	Aadd(aCampos,{ "PRCVEN"  ,"Preço Venda","@E 999,999.99"})
	Aadd(aCampos,{ "VZ"      ," "})

	aSize 		:= MsAdvSize( .T., .F., 400 )		// Size da Dialog
	@ aSize[7],001  TO aSize[6] , aSize[5] DIALOG oDlg4 TITLE OemToAnsi("Consulta produtos faturados referente nota fiscal->"+NOTA->NOTA)
	@ 005,005 TO aSize[6]/2-50,aSize[5]/2 - 05 BROWSE "PROD" OBJECT oBrw4 FIELDS aCampos
	@ aSize[6]/2-35,015 Say "Total Produtos"
	@ aSize[6]/2-35,080 Get nFatsub size 60,13 picture "@E 999,999,999.99" when .f.

	@ aSize[6]/2-35,195 button "&Fechar "     size 37,13 Action Close(oDlg4)

	ACTIVATE DIALOG oDlg4 CENTERED


	PROD->(DbCloseArea())
	FErase(cArq + GetDbExtension()) // Deleting file
	FErase(cArq + OrdBagExt()) // Deleting index


Return

// Exibe cotação
Static Function sfCotacao()

	Local aCampos := {}
	Local aStru   := {}

	sfAtuCodLj()

	aStru:={}
	Aadd(aStru,{ "NUMCOT" , "C", 06, 0 })
	Aadd(aStru,{ "EMISSAO", "D", 08, 0 })
	Aadd(aStru,{ "CONDPAG", "C", 20, 0 })
	Aadd(aStru,{ "STS"    , "C", 10, 0 })
	Aadd(aStru,{ "VLR"    , "N", 10, 2 })
	Aadd(aStru,{ "VZ"     , "C", 01, 0 })

	cArq := CriaTrab(aStru,.t.)
	dbUseArea ( .T.,__localdriver, cArq, "COT", NIL, .F. )

	cQri := ""
	cQri += "SELECT CJ_NUM,SUM(CK_VALOR)AS TOT,CJ_EMISSAO,CJ_CONDPAG,CJ_STATUS "
	cQri += "  FROM "+ RetSqlName("SCJ") + " SCJ, " + RetSqlName("SCK") + " SCK "
	cQri += " WHERE SCJ.D_E_L_E_T_ = ' ' "
	cQri += "   AND SCK.D_E_L_E_T_ = ' ' "
	cQri += "   AND SCK.CK_NUM = SCJ.CJ_NUM "
	cQri += "   AND SCK.CK_FILIAL = '" + xFilial("SCK") + "'  "
	cQri += "   AND SCJ.CJ_LOJA = '" + cLj + "' "
	cQri += "   AND SCJ.CJ_CLIENTE = '" + cCliente + "' "
	cQri += "   AND SCJ.CJ_FILIAL = '" + xFilial("SCJ") + "' "
	cQri += " GROUP BY SCJ.CJ_NUM,SCJ.CJ_EMISSAO,SCJ.CJ_CONDPAG,SCJ.CJ_STATUS "
	cQri += " ORDER BY SCJ.CJ_NUM DESC "

	TCQUERY cQri NEW ALIAS "QCJ"

	Dbselectarea("QCJ")
	dbgotop()
	While !Eof()

		If !Empty(QCJ->CJ_NUM)
			dbSelectArea("COT")
			RecLock("COT",.T.)
			COT->NUMCOT   := QCJ->CJ_NUM
			COT->EMISSAO  := STOD(QCJ->CJ_EMISSAO)
			Dbselectarea("SE4")
			dbsetorder(1)
			If Dbseek(xFilial("SE4")+QCJ->CJ_CONDPAG)
				COT->CONDPAG :=  QCJ->CJ_CONDPAG+" - " +  SE4->E4_DESCRI
			Else
				COT->CONDPAG := "CÓDIGO CONDIÇÃO  NÃO ENCONTRADO"
			Endif
			If QCJ->CJ_STATUS == "A"
				COT->STS      := "Em aberto"
			Elseif QCJ->CJ_STATUS == "B"
				COT->STS	:= "Efetivado"
			Elseif QCJ->CJ_STATUS == "D"
				COT->STS    := "Não orçado"
			Endif
			COT->VLR   := QCJ->TOT
			COT->VZ     := ""

			MsUnLock("COT")
		Endif
		dbSelectArea("QCJ")
		dbSkip()
	Enddo

	QCJ->(DbCloseArea())

	dbSelectArea("COT")
	dbGotop()

	aCampos := {}
	Aadd(aCampos,{ "NUMCOT"  ,"Nº Cotação" })
	Aadd(aCampos,{ "EMISSAO" ,"Emissão" })
	Aadd(aCampos,{ "CONDPAG" ,"Condição Pgto" })
	Aadd(aCampos,{ "STS"     ,"Status" })
	Aadd(aCampos,{ "VLR"     ,"Total" ,"@E 999,999.99"})
	Aadd(aCampos,{ "VZ"      ," "})
	aSize 		:= MsAdvSize( .T., .F., 400 )		// Size da Dialog
	@ aSize[7],001  TO aSize[6] , aSize[5] DIALOG oDlg5 TITLE OemToAnsi("Consulta cotações do cliente-> "+cCliente+"/"+cLj+" "+cRazao)
	@ 005,005 TO aSize[6]/2-50,aSize[5]/2 - 05 BROWSE "COT" OBJECT oBrw5 FIELDS aCampos
	@ aSize[6]/2-35,015 Button "&Visualiza" size 45,13 Action (Processa({|| sfCotView() },"Consultando"))
	@ aSize[6]/2-35,195 button "&Fechar "     size 37,13 Action Close(oDlg5)

	ACTIVATE DIALOG oDlg5 CENTERED

	COT->(DbCloseArea())

Return

// Visualiza cotação
Static Function sfCotView()

	Local aCampos := {}
	Local aStru   := {}
	Local nTotcot := 0.00
	Local cNotas  := ""

	sfAtuCodLj()

	aStru:={}
	Aadd(aStru,{ "ITEM"   , "C", 02, 0 })
	Aadd(aStru,{ "PRODUTO", "C", 15, 0 } )
	Aadd(aStru,{ "DESCRI" , "C", 45, 0 } )
	Aadd(aStru,{ "QTE"    , "N", 7, 0 } )
	Aadd(aStru,{ "PRUNIT" , "N", 10, 2 })
	Aadd(aStru,{ "PRCVEN" , "N", 10, 2 } )
	Aadd(aStru,{ "TOTAL"  , "N", 10, 2 } )
	Aadd(aStru,{ "NUMPED" , "C", 06, 0 })
	Aadd(aStru,{ "NUMDOC" , "C", 30, 0 })
	Aadd(aStru,{ "VZ"     , "C", 01, 0 })

	cArq := CriaTrab(aStru,.t.)
	dbUseArea ( .T.,__localdriver, cArq, "ITCOT", NIL, .F. )

	cQri := ""
	cQri += "SELECT CK_ITEM,CK_PRODUTO,CK_QTDVEN,CK_PRUNIT,CK_PRCVEN,CK_VALOR,CK_NUMPV,B1_DESC "
	cQri += "  FROM "+ RetSqlName("SCK") + " SCK, " +RetSqlName("SB1") + " SB1 "
	cQri += " WHERE SCK.D_E_L_E_T_ = ' ' "
	cQri += "   AND SB1.D_E_L_E_T_ = ' ' "
	cQri += "   AND SB1.B1_COD = SCK.CK_PRODUTO "
	cQri += "   AND SB1.B1_FILIAL = '" + xFilial("SB1") + "'  "
	cQri += "   AND SCK.CK_NUM = '" + COT->NUMCOT + "' "
	cQri += "   AND SCK.CK_FILIAL = '" + xFilial("SCK") + "'  "
	cQri += " ORDER BY SCK.CK_ITEM ASC "

	TCQUERY cQri NEW ALIAS "QCK"

	Dbselectarea("QCK")
	dbgotop()
	While !Eof()

		If !Empty(QCK->CK_ITEM)
			dbSelectArea("ITCOT")
			RecLock("ITCOT",.T.)
			ITCOT->ITEM    := QCK->CK_ITEM
			ITCOT->PRODUTO := QCK->CK_PRODUTO
			ITCOT->DESCRI  := QCK->B1_DESC
			ITCOT->QTE     := QCK->CK_QTDVEN
			ITCOT->PRUNIT  := QCK->CK_PRUNIT
			ITCOT->PRCVEN  := QCK->CK_PRCVEN
			ITCOT->TOTAL   := QCK->CK_VALOR

			cQrp := ""
			cQrp += "SELECT C6_NUM "
			cQrp += "  FROM "+ RetSqlName("SC6")
			cQrp += " WHERE D_E_L_E_T_ = ' '  "
			cQrp += "   AND C6_NUMORC = '" + Alltrim(COT->NUMCOT + QCK->CK_ITEM) + "' "
			cQrp += "   AND C6_FILIAL = '" + xFilial("SC6") + "'  "

			TCQUERY cQrp NEW ALIAS "QSC6"

			Dbselectarea("QSC6")
			dbgotop()

			ITCOT->NUMPED  := QSC6->C6_NUM

			QSC6->(DbCloseArea())

			cQrp := ""
			cQrp += "SELECT D2_DOC "
			cQrp += "  FROM "+ RetSqlName("SC6") + " SC6, " +RetSqlName("SD2") + " SD2 "
			cQrp += " WHERE SC6.D_E_L_E_T_ = ' ' "
			cQrp += "   AND SD2.D_E_L_E_T_ = ' ' "
			cQrp += "   AND SD2.D2_ITEMPV  = SC6.C6_ITEM "
			cQrp += "   AND SD2.D2_PEDIDO = SC6.C6_NUM "
			cQrp += "   AND SD2.D2_FILIAL = '" + xFilial("SD2") + "'  "
			cQrp += "   AND SC6.C6_NUMORC = '" + Alltrim(COT->NUMCOT + QCK->CK_ITEM) + "' "
			cQrp += "   AND SC6.C6_FILIAL = '" + xFilial("SC6") + "'  "

			TCQUERY cQrp NEW ALIAS "QCD2"

			Dbselectarea("QCD2")
			dbgotop()
			While !Eof()
				If cNotas <> ""
					cNotas += "/ "+QCD2->D2_DOC
				Else
					cNotas += QCD2->D2_DOC
				Endif
				Dbselectarea("QCD2")
				dbskip()
			Enddo
			QCD2->(DbCloseArea())

			ITCOT->NUMDOC :=  cNotas
			cNotas := ""
			ITCOT->VZ     := ""

			MsUnLock("ITCOT")
			nTotcot += QCK->CK_VALOR
		Endif
		dbSelectArea("QCK")
		dbSkip()
	Enddo
	QCK->(DbCloseArea())

	dbSelectArea("ITCOT")
	dbGotop()

	aCampos := {}
	Aadd(aCampos,{ "ITEM"    ,"Item" })
	Aadd(aCampos,{ "PRODUTO" ,"Produto" })
	Aadd(aCampos,{ "DESCRI"  ,"Descrição" })
	Aadd(aCampos,{ "QTE"     ,"Quantidade","@E 999,999"})
	Aadd(aCampos,{ "PRUNIT"  ,"Preço Tabela", "@E 999,999.99"})
	Aadd(aCampos,{ "PRCVEN"  ,"Preço Venda","@E 999,999.99"})
	Aadd(aCampos,{ "TOTAL"   ,"Total Item" ,"@E 999,999.99"})
	Aadd(aCampos,{ "NUMPED"  ,"Nº Pedido" })
	Aadd(aCampos,{ "NUMDOC"  ,"Nº Notas(s)" })
	Aadd(aCampos,{ "VZ"      ," "})
	aSize 		:= MsAdvSize( .T., .F., 400 )		// Size da Dialogg
	@ aSize[7],001  TO aSize[6] , aSize[5] DIALOG oDlg6 TITLE OemToAnsi("Consulta produtos referentes a cotação->"+COT->NUMCOT)
	@ 005,005 TO aSize[6]/2-50,aSize[5]/2 - 05 BROWSE "ITCOT" OBJECT oBrw6 FIELDS aCampos
	@ aSize[6]/2-35,015 Say "Total Produtos"
	@ aSize[6]/2-35,080 Get nTotcot size 30,13 picture "@E 999,999.99" when .f.

	@ aSize[6]/2-35,195 button "&Fechar "     size 37,13 Action Close(oDlg6)

	ACTIVATE DIALOG oDlg6 CENTERED

	ITCOT->(DbCloseArea())
	FErase(cArq + GetDbExtension()) // Deleting file
	FErase(cArq + OrdBagExt()) // Deleting index

Return

// Visualiza os títulos
Static Function sfTitView()

	Local aCampos := {}
	Local aStru   := {}
	Local nAvencer  := 0.00
	Local nVencido  := 0.00

	sfAtuCodLj()

	aStru:={}
	Aadd(aStru,{ "PREFIXO" , "C", TamSX3("E1_PREFIXO")[1], 0 })
	Aadd(aStru,{ "NUM"     , "C", TamSX3("E1_NUM")[1], 0 })
	Aadd(aStru,{ "PARCELA" , "C", TamSX3("E1_PARCELA")[1], 0 })
	Aadd(aStru,{ "EMISSAO" , "D", 08, 0 })
	Aadd(aStru,{ "VCREAL"  , "D", 08, 0 })
	Aadd(aStru,{ "DIAS"    , "C", 03, 0 })
	Aadd(aStru,{ "VLR"     , "N", 10, 2 })
	Aadd(aStru,{ "VLRJUR"  , "N", 10, 2 })
	Aadd(aStru,{ "PORTADO" , "C", 30, 0 })
	Aadd(aStru,{ "VZ"      , "C", 01, 0 })
	Aadd(aStru,{ "TIPO"    , "C", TamSX3("E1_TIPO")[1], 0 })


	cArq := CriaTrab(aStru,.t.)
	dbUseArea ( .T.,__localdriver, cArq, "TIT", NIL, .F. )

	cQri := ""
	cQri += "SELECT * "
	cQri += "  FROM "+ RetSqlName("SE1")
	cQri += " WHERE D_E_L_E_T_ = ' ' "
	cQri += "   AND E1_SALDO > 0 "
	cQri += "   AND E1_LOJA = '" + cLj + "' "
	cQri += "   AND E1_CLIENTE = '" + cCliente + "' "
	cQri += "   AND E1_FILIAL = '" + xFilial("SE1") + "' "
	cQri += " ORDER BY E1_NUM ASC,E1_PARCELA ASC  "

	TCQUERY cQri NEW ALIAS "QE1"

	Dbselectarea("QE1")
	dbgotop()
	While !Eof()

		If !Empty(QE1->E1_NUM)
			dbSelectArea("TIT")
			RecLock("TIT",.T.)
			TIT->PREFIXO := QE1->E1_PREFIXO
			TIT->NUM     := QE1->E1_NUM
			TIT->PARCELA := QE1->E1_PARCELA
			TIT->EMISSAO := STOD(QE1->E1_EMISSAO)
			TIT->VCREAL  := STOD(QE1->E1_VENCREA)
			TIT->DIAS    := Alltrim(Str(dDatabase - STOD(QE1->E1_VENCREA)))
			TIT->VLR     := QE1->E1_SALDO
			If (STOD(QE1->E1_VENCREA) - dDataBase) < 0
				TIT->VLRJUR  := (dDatabase - STOD(QE1->E1_VENCREA))*QE1->E1_VALJUR
				nVencido += QE1->E1_SALDO
			Else
				TIT->VLRJUR  := 0
			Endif
			Dbselectarea("SA6")
			dbsetorder(1)
			If Dbseek(xFilial("SA6")+QE1->E1_PORTADO+QE1->E1_AGEDEP)
				TIT->PORTADO := QE1->E1_PORTADO+" "+SA6->A6_NREDUZ
			Else
				TIT->PORTADO := QE1->E1_PORTADO
			Endif
			nAvencer  += QE1->E1_SALDO
			TIT->VZ     := ""
			TIT->TIPO 	:= QE1->E1_TIPO 
			MsUnLock("TIT")
		Endif
		dbSelectArea("QE1")
		dbSkip()
	Enddo
	QE1->(DbCloseArea())

	dbSelectArea("TIT")
	dbGotop()

	aCampos := {}
	Aadd(aCampos,{ "PREFIXO" , "Prf" })
	Aadd(aCampos,{ "NUM"     , "Nº Título" })
	Aadd(aCampos,{ "PARCELA" , "Parc." })
	Aadd(aCampos,{ "TIPO"     , "Tipo" })
	Aadd(aCampos,{ "EMISSAO" , "Emissão" })
	Aadd(aCampos,{ "VCREAL"  , "Vcto Real" })
	Aadd(aCampos,{ "DIAS"    , "Dias Atraso" })
	Aadd(aCampos,{ "VLR"     , "Saldo","@E 999,999.99" })
	Aadd(aCampos,{ "VLRJUR"  , "Juros","@E 999,999.99" })
	Aadd(aCampos,{ "PORTADO" , "Portador" })
	Aadd(aCampos,{ "VZ"     , " " })

	aSize 		:= MsAdvSize( .T., .F., 400 )		// Size da Dialog

	@ aSize[7],001  TO aSize[6] , aSize[5] DIALOG oDlg7 TITLE OemToAnsi("Consulta de títulos do cliente-> "+cCliente+"/"+cLj+" "+cRazao)
	@ 005,005 TO aSize[6]/2-50,aSize[5]/2 - 05 BROWSE "TIT" OBJECT oBrw7 FIELDS aCampos
	@ aSize[6]/2-35,215 button "&Fechar "     size 37,13 Action Close(oDlg7)

	@ aSize[6]/2-35,300 button "&Imprimir Boleto "     size 57,15 Action sfPrintBol()

	@ aSize[6]/2-35,010 Say "Total Vencido"
	@ aSize[6]/2-35,055 Get nVencido size 60,13 picture "@E 999,999,999.99" when .f.
	@ aSize[6]/2-35,110 say "Total a Vencer"
	@ aSize[6]/2-35,150 Get nAvencer size 60,13 picture "@E 999,999,999.99" when .f.

	ACTIVATE DIALOG oDlg7 CENTERED

	TIT->(DBCloseArea())
	FErase(cArq + GetDbExtension()) // Deleting file
	FErase(cArq + OrdBagExt()) // Deleting index

Return

Static Function sfPrintBol()

	Local	cKeySE1		:= TIT->PREFIXO+TIT->NUM +TIT->PARCELA



	DbSelectArea("SE1")
	DbSetOrder(1) // E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
	If DbSeek(xFilial("SE1")+cKeySE1)


		If !Empty(SE1->E1_PORTADO) .Or. (SE1->(FieldPos("E1_BCOIMP")) > 0 .And. !Empty(SE1->E1_BCOIMP))
			If SE1->E1_VENCREA  > Date()

				U_DIS111B(.T./*lAuto*/,2/* IMPRESSAO/REIMPRESSAO nOpc*/,SE1->(Recno()),.T.)
			Else
				MsgAlert("Somente títulos A Vencer podem ser impressos boletos pelo setor Comercial! Vencidos somente o Setor Financeiro poderá imprimir.","Sem permissão para impressão de boleto!")
			Endif
		Else
			MsgAlert("Não há boleto impresso para este título!","Sem boleto!")
		Endif

	Endif


Return

// Visualiza pendências
Static Function sfPendencia()

	Local aCampos := {}
	Local aStru   := {}
	Local cSts    := ""
	Local naFaturar    := 0.00
	sfAtuCodLj()

	aStru:={}
	Aadd(aStru,{ "FILIAL" , "C", 20, 0 } )
	Aadd(aStru,{ "PEDIDO" , "C", 06, 0 } )
	Aadd(aStru,{ "EMISSAO", "D", 08, 0 } )
	Aadd(aStru,{ "ITEM"   , "C", 02, 0 } )
	Aadd(aStru,{ "PRODUTO", "C", 15, 0 } )
	Aadd(aStru,{ "DESCRI" , "C", 45, 0 } )
	Aadd(aStru,{ "ESTOQUE", "C", 06, 0 } )
	Aadd(aStru,{ "QTDVEN" , "C", 07, 0 } )
	Aadd(aStru,{ "QTDSAL" , "C", 07, 0 } )
	Aadd(aStru,{ "STS"    , "C", 30, 0 } )
	Aadd(aStru,{ "PRCVEN" , "N", 10, 2 } )
	Aadd(aStru,{ "TOTAL"  , "N", 10, 2 } )
	Aadd(aStru,{ "VENBON" , "C", 30, 0 } )
	Aadd(aStru,{ "VZ"     , "C", 01, 0 })

	cArq := CriaTrab(aStru,.t.)
	dbUseArea ( .T.,__localdriver, cArq, "PEND", NIL, .F. )

	cQri := ""
	cQri += "SELECT C6_FILIAL,C6_NUM,C6_ITEM,C6_PRODUTO,C6_QTDVEN,C6_QTDENT,C6_PRCVEN,C6_VALOR,C6_TES,C6_CF,B1_DESC, "
	cQri += "       C5_EMISSAO,B2_QATU,B2_RESERVA,F4_TEXTO "
	cQri += "  FROM "+ RetSqlName("SC6") + " SC6, " +RetSqlName("SB1") + " SB1, "+RetSqlName("SC5")+ " C5, "+ RetSqlName("SB2")+" B2, " + RetSqlName("SF4")+" F4 "
	cQri += " WHERE SC6.D_E_L_E_T_ = ' ' "
	cQri += "   AND B2.D_E_L_E_T_ = ' ' "
	cQri += "   AND B2_LOCAL = C6_LOCAL "
	cQri += "   AND B2_COD = C6_PRODUTO "
	cQri += "   AND B2_FILIAL = C6_FILIAL "
	cQri += "   AND F4.D_E_L_E_T_ = ' ' "
	cQri += "   AND F4_CODIGO = C6_TES "
	cQri += "   AND F4_FILIAL = C6_FILIAL "
	cQri += "   AND SB1.D_E_L_E_T_ = ' ' "
	cQri += "   AND SB1.B1_COD = SC6.C6_PRODUTO "
	If !Empty(xFilial("SB1"))
		cQri += "   AND SB1.B1_FILIAL = C6_FILIAL "
	Else
		cQri += "   AND SB1.B1_FILIAL = '" + xFilial("SB1") + "' "
	Endif
	cQri += "   AND C5.D_E_L_E_T_ = ' ' "
	cQri += "   AND C5.C5_TIPO = 'N' "
	cQri += "   AND C5.C5_NUM = C6_NUM "
	cQri += "   AND SC6.C6_FILIAL = C5_FILIAL "
	cQri += "   AND SC6.C6_BLQ <> 'R' "
	cQri += "   AND SC6.C6_QTDENT < SC6.C6_QTDVEN "
	cQri += "   AND SC6.C6_LOJA = '" + cLj + "' "
	cQri += "   AND SC6.C6_CLI = '" + cCliente + "' "
	cQri += "   AND SC6.C6_FILIAL IN "+FormatIN(GetMv("BF_FILIAIS"),"/")
	cQri += " ORDER BY C6_NUM ASC, C6_ITEM ASC "

	TCQUERY cQri NEW ALIAS "QC6"

	TcSetField("QC6","C5_EMISSAO","D")

	While !Eof()

		If !Empty(QC6->C6_NUM)
			cDescFilial	:= QC6->C6_FILIAL
			DbSelectArea("SM0")
			DbSetOrder(1)
			nRecSm0 	:=  SM0->(Recno())
			DbGotop()
			While !Eof()
				If SM0->M0_CODIGO == cEmpAnt .And. SM0->M0_CODFIL  == Alltrim(QC6->C6_FILIAL)
					cDescFilial	:= Alltrim(QC6->C6_FILIAL)+"-"+Capital(SM0->M0_FILIAL)
					Exit
				Endif
				DbSelectArea("SM0")
				DbSkip()
			Enddo
			DbSelectArea("SM0")
			DbGoto(nRecSm0)

			dbSelectArea("PEND")
			RecLock("PEND",.T.)
			PEND->FILIAL		:= cDescFilial
			PEND->PEDIDO    	:= QC6->C6_NUM
			PEND->EMISSAO  	:= QC6->C5_EMISSAO
			PEND->ITEM     	:= QC6->C6_ITEM
			PEND->PRODUTO  	:= QC6->C6_PRODUTO
			PEND->DESCRI   	:= QC6->B1_DESC
			PEND->ESTOQUE  	:= Alltrim(str(QC6->B2_QATU - QC6->B2_RESERVA))
			PEND->QTDVEN   	:= Alltrim(str(QC6->C6_QTDVEN))
			PEND->QTDSAL   	:= Alltrim(str(QC6->C6_QTDVEN - QC6->C6_QTDENT))

			cQrc := ""
			cQrc += "SELECT * "
			cQrc += "  FROM "+ RetSqlName("SC9")
			cQrc += " WHERE D_E_L_E_T_ = ' ' "
			cQrc += "   AND C9_FILIAL = '" + xFilial("SC9") + "' "
			cQrc += "   AND C9_PEDIDO= '" + QC6->C6_NUM + "' "
			cQrc += "   AND C9_ITEM = '" + QC6->C6_ITEM + "' "

			TCQUERY cQrc NEW ALIAS "QC9"

			While !Eof()

				If cSts <> ""
					If QC9->C9_NFISCAL <> " "
						cSts += "/ "+Alltrim(str(QC9->C9_QTDLIB)) + " FAT"
					Else
						IF  QC9->C9_BLCRED <> " "
							cSts += "/ "+Alltrim(str(QC9->C9_QTDLIB)) + " CRD"
						Else
							IF QC9->C9_BLEST <> " "
								cSts += "/ "+Alltrim(str(QC9->C9_QTDLIB)) + " BLE"
							Else
								cSts += "/ "+Alltrim(str(QC9->C9_QTDLIB)) + " OK"
							Endif
						Endif
					Endif
				Else
					If QC9->C9_NFISCAL <> " "
						cSts += Alltrim(str(QC9->C9_QTDLIB)) + " FAT"
					Else
						IF  QC9->C9_BLCRED <> " "
							cSts += Alltrim(str(QC9->C9_QTDLIB)) + " CRD"
						Else
							If QC9->C9_BLEST <> " "
								cSts += Alltrim(str(QC9->C9_QTDLIB)) + " BLE"
							Else
								cSts += Alltrim(str(QC9->C9_QTDLIB)) + " OK"
							Endif
						Endif
					Endif
				Endif

				dbselectarea("QC9")
				dbskip()
			Enddo
			QC9->(DbCloseArea())

			PEND->STS      :=  cSts
			cSts := ""

			PEND->PRCVEN   :=  QC6->C6_PRCVEN
			PEND->TOTAL    :=  QC6->C6_VALOR

			Dbselectarea("SF4")
			dbsetorder(1)
			If Dbseek(xFilial("SF4")+QC6->C6_TES)
				PEND->VENBON :=  QC6->C6_TES+" - " + QC6->C6_CF + " - " + SF4->F4_TEXTO
			Else
				PEND->VENBON := "CÓDIGO CFOP NÃO ENCONTRADO"
			Endif
			PEND->VZ     := ""

			MsUnLock("PEND")
			naFaturar += (QC6->C6_QTDVEN - QC6->C6_QTDENT)* QC6->C6_PRCVEN
		Endif

		dbSelectArea("QC6")
		dbSkip()
	Enddo
	QC6->(DbCloseArea())

	dbSelectArea("PEND")
	dbGotop()

	aCampos := {}

	Aadd(aCampos,{ "FILIAL" , "Filial" } )
	Aadd(aCampos,{ "PEDIDO" , "Pedido" } )
	Aadd(aCampos,{ "EMISSAO", "Emissão" } )
	Aadd(aCampos,{ "ITEM"   , "Item" } )
	Aadd(aCampos,{ "PRODUTO", "Código" } )
	Aadd(aCampos,{ "DESCRI" , "Descrição" } )
	Aadd(aCampos,{ "ESTOQUE", "Est.Disp" } )
	Aadd(aCampos,{ "QTDVEN" , "Qte Vend" } )
	Aadd(aCampos,{ "QTDSAL" , "Saldo"} )
	Aadd(aCampos,{ "STS"    , "Status" } )
	Aadd(aCampos,{ "PRCVEN" , "Prc Venda","@E 999,999.99"} )
	Aadd(aCampos,{ "TOTAL"  , "Total","@E 999,999.99" } )
	Aadd(aCampos,{ "VENBON" , "TES - CFOP - Natureza" } )
	Aadd(aCampos,{ "VZ"     , "" })

	aSize 		:= MsAdvSize( .T., .F., 400 )		// Size da Dialog

	@ aSize[7],001  TO aSize[6] , aSize[5]  DIALOG oDlg8 TITLE OemToAnsi("Consulta pedidos e produtos em pendência do cliente-> "+cCliente+"/"+cLj+" "+cRazao)
	@ 005,005 TO aSize[6]/2-50,aSize[5]/2 - 05 BROWSE "PEND" OBJECT oBrw8 FIELDS aCampos
	@ aSize[6]/2-35,015 Say "Soma da pendência"
	@ aSize[6]/2-35,080 Get naFaturar size 60,13 picture "@E 999,999,999.99" when .f.

	@ aSize[6]/2-35,195 button "&Fechar "     size 37,13 Action Close(oDlg8)

	ACTIVATE DIALOG oDlg8 CENTERED

	PEND->(DbCloseArea())
	FErase(cArq + GetDbExtension()) // Deleting file
	FErase(cArq + OrdBagExt()) // Deleting index

Return

// Visualiza resíduos
Static Function sfResiduos()

	Local aCampos := {}
	Local aStru   := {}
	Local nElim   := 0.00
	Local cSts := ""
	sfAtuCodLj()

	aStru:={}
	Aadd(aStru,{ "PEDIDO" , "C", 06, 0 } )
	Aadd(aStru,{ "EMISSAO", "D", 08, 0 } )
	Aadd(aStru,{ "ITEM"   , "C", 02, 0 } )
	Aadd(aStru,{ "PRODUTO", "C", 15, 0 } )
	Aadd(aStru,{ "DESCRI" , "C", 45, 0 } )
	Aadd(aStru,{ "QTDVEN" , "C", 07, 0 } )
	Aadd(aStru,{ "QTDSAL" , "C", 07, 0 } )
	Aadd(aStru,{ "STS"    , "C", 30, 0 } )
	Aadd(aStru,{ "PRCVEN" , "N", 10, 2 } )
	Aadd(aStru,{ "TOTAL"  , "N", 10, 2 } )
	Aadd(aStru,{ "VENBON" , "C", 30, 0 } )
	Aadd(aStru,{ "VZ"     , "C", 01, 0 })

	cArq := CriaTrab(aStru,.t.)
	dbUseArea ( .T.,__localdriver, cArq, "RESID", NIL, .F. )

	cQri := ""
	cQri += "SELECT C6_NUM,C6_ITEM,C6_PRODUTO,C6_QTDVEN,C6_QTDENT,C6_PRCVEN,C6_VALOR,C6_TES,C6_CF,B1_DESC "
	cQri += "  FROM "+ RetSqlName("SC6") + " SC6, " +RetSqlName("SB1") + " SB1 "
	cQri += " WHERE SC6.D_E_L_E_T_ = ' ' "
	cQri += "   AND SB1.D_E_L_E_T_ = ' ' "
	cQri += "   AND SB1.B1_COD  = SC6.C6_PRODUTO  "
	cQri += "   AND SB1.B1_FILIAL = '" + xFilial("SB1") + "'  "
	cQri += "   AND SC6.C6_BLQ = 'R' "
	cQri += "   AND SC6.C6_QTDENT < SC6.C6_QTDVEN "
	cQri += "   AND SC6.C6_LOJA = '" + cLj + "' "
	cQri += "   AND SC6.C6_CLI = '" + cCliente + "' "
	cQri += "   AND SC6.C6_FILIAL = '" + xFilial("SC6") + "'  "
	cQri += " ORDER BY SC6.C6_NUM ASC, SC6.C6_ITEM ASC "

	TCQUERY cQri NEW ALIAS "QC6"

	Dbselectarea("QC6")
	dbgotop()
	While !Eof()

		If !Empty(QC6->C6_NUM)
			dbSelectArea("RESID")
			RecLock("RESID",.T.)
			RESID->PEDIDO    := QC6->C6_NUM
			dbselectarea("SC5")
			Dbsetorder(1)
			Dbseek(xFilial("SC5")+QC6->C6_NUM)
			RESID->EMISSAO  := SC5->C5_EMISSAO
			RESID->ITEM     := QC6->C6_ITEM
			RESID->PRODUTO  := QC6->C6_PRODUTO
			RESID->DESCRI   := QC6->B1_DESC
			RESID->QTDVEN   := Alltrim(str(QC6->C6_QTDVEN))
			RESID->QTDSAL   := Alltrim(str(QC6->C6_QTDVEN - QC6->C6_QTDENT))


			cQrc := ""
			cQrc += "SELECT * "
			cQrc += "  FROM "+ RetSqlName("SD2")
			cQrc += " WHERE D_E_L_E_T_ = ' ' "
			cQrc += "   AND D2_ITEMPV = '" + QC6->C6_ITEM + "' "
			cQrc += "   AND D2_PEDIDO= '" + QC6->C6_NUM + "' "
			cQrc += "   AND D2_FILIAL = '" + xFilial("SD2") + "' "

			TCQUERY cQrc NEW ALIAS "QD2"

			Dbselectarea("QD2")
			dbgotop()
			While !Eof()

				If cSts <> ""
					cSts += "/ "+Alltrim(str(QD2->D2_QUANT)) + " FAT"
				Else
					cSts += Alltrim(str(QD2->D2_QUANT)) + " FAT"
				Endif

				dbselectarea("QD2")
				dbskip()
			Enddo

			QD2->(DbCloseArea())

			RESID->STS      :=  cSts
			cSts := ""

			RESID->PRCVEN   :=  QC6->C6_PRCVEN
			RESID->TOTAL    :=  QC6->C6_VALOR
			Dbselectarea("SF4")
			dbsetorder(1)
			If Dbseek(xFilial("SF4")+QC6->C6_TES)
				RESID->VENBON :=  QC6->C6_TES+" - " + QC6->C6_CF + " - " + SF4->F4_TEXTO
			Else
				RESID->VENBON := "CÓDIGO CFOP NÃO ENCONTRADO"
			Endif
			RESID->VZ     := ""

			MsUnLock("RESID")
			nElim += (QC6->C6_QTDVEN - QC6->C6_QTDENT)* QC6->C6_PRCVEN
		Endif
		dbSelectArea("QC6")
		dbSkip()
	Enddo
	QC6->(DbCloseArea())

	dbSelectArea("RESID")
	dbGotop()

	aCampos := {}
	Aadd(aCampos,{ "PEDIDO" , "Pedido" } )
	Aadd(aCampos,{ "EMISSAO", "Emissão" } )
	Aadd(aCampos,{ "ITEM"   , "Item" } )
	Aadd(aCampos,{ "PRODUTO", "Código" } )
	Aadd(aCampos,{ "DESCRI" , "Descrição" } )
	Aadd(aCampos,{ "QTDVEN" , "Qte Vend" } )
	Aadd(aCampos,{ "QTDSAL" , "Saldo"} )
	Aadd(aCampos,{ "STS"    , "Status" } )
	Aadd(aCampos,{ "PRCVEN" , "Prc Venda","@E 999,999.99"} )
	Aadd(aCampos,{ "TOTAL"  , "Total","@E 999,999.99" } )
	Aadd(aCampos,{ "VENBON" , "TES - CFOP - Natureza" } )
	Aadd(aCampos,{ "VZ"     , "" })

	aSize 		:= MsAdvSize( .T., .F., 400 )		// Size da Dialog

	@ aSize[7],001  TO aSize[6] , aSize[5] DIALOG oDlg9 TITLE OemToAnsi("Consulta pedidos e produtos eliminados por resíduo do cliente-> "+cCliente+"/"+cLj+" "+cRazao)
	@ 005,005 TO aSize[6]/2-50,aSize[5]/2 - 05 BROWSE "RESID" OBJECT oBrw9 FIELDS aCampos
	@ aSize[6]/2-35,015 Say "Soma do eliminado"
	@ aSize[6]/2-35,080 Get nElim size 60,13 picture "@E 999,999,999.99" when .f.

	@ aSize[6]/2-35,195 button "&Fechar "     size 37,13 Action Close(oDlg9)

	ACTIVATE DIALOG oDlg9 CENTERED

	RESID->(DbCloseArea())
	FErase(cArq + GetDbExtension()) // Deleting file
	FErase(cArq + OrdBagExt()) // Deleting index

Return


User function BIG0381(cInCli,cInLoja)

	Local	aAreaOld	:= GetArea()
	Private lAltCli 	:= .F.
	Private cTpcon  	:= "Campanha"
	Private cCliente 	:= Space(TamSX3("A1_COD")[1])
	Private cLj 		:= Space(TamSX3("A1_LOJA")[1])
	Private cRazao 		:= ""

	Private	cVend1i 	:= "      "
	Private cVend1f 	:= "999999"
	Private cVend2i 	:= "      "
	Private cVend2f 	:= "999999"
	Private lUsaLits	:= cEmpAnt $ "02#11"


	If Type("lProspect") <> "U" .And. lProspect
		MsgAlert("Está selecionada a opção Prospect! Rotina só funciona com cadastro de clientes!","Selecionado Prospect")
		Return
	Endif

	If Type("M->UA_CLIENTE") <> "U"
		If !Empty(M->UA_CLIENTE)
			cCliente	:= M->UA_CLIENTE
			cLj 		:= M->UA_LOJA
			cRazao 		:= M->UA_DESCCLI
		Endif
	ElseIf Type("M->C5_CLIENTE") <> "U"
		If !Empty(M->C5_CLIENTE)
			cCliente	:= M->C5_CLIENTE
			cLj 		:= M->C5_LOJACLI
			cRazao 		:= SA1->A1_NOME
		Endif
	Endif

	If cInCli <> Nil .And. cInLoja <> Nil .And. !Empty(cInCli+cInLoja)
		cCliente	:= cInCli
		cLj			:= cInLoja
		DbSelectArea("SA1")
		DbSetOrder(1)
		DbSeek(xFilial("SA1")+cCliente+cLj)
	Endif

	@ 200,1 TO 380,500 DIALOG oDlg10 TITLE OemToAnsi("Consulta posições do cliente->"+cRazao)

	@ 010,015 Button "&Notas Fiscais"  size 60,13 Action (Processa({|| sfViewNFs() },"Consultando"))
	@ 010,085 Button "Pr&odutos faturados" size 60,13 Action ( Processa({|| sfProdutos()},"Consultando"))
	@ 010,155 Button "&Cotações" size 60,13 Action ( Processa({|| sfCotacao()},"Consultando"))
	@ 030,015 Button "&Títulos em aberto" size 60,13 action( Processa ({|| sfTitView()},"Consultando"))
	@ 030,085 Button "&Pendência" size 60,13 action ( Processa ({|| sfPendencia()},"Consultando"))
	@ 030,155 Button "&Resíduos" size 60,13 action ( Processa ({|| sfResiduos()},"Consultando"))
	//@ 045,085 Button "Re&ver clientes" size 60,13 action (lAltCli := .F.,( Processa({|| BIG038A()},"Consultando")) )
	@ 045,155 Button "Imprimir" size 60,13 Action Imprime()
	@ 060,085 button "&Fechar "     size 60,13 Action Close(oDlg10)
	@ 075,025 Say "Código cliente|Loja"
	@ 075,085 Get cCliente size 30,13 f3 "SA1"
	@ 075,115 Get cLj size 08,13
	@ 075,123 Get cRazao size 92,13 when .f.
	ACTIVATE DIALOG oDlg10 CENTERED

	RestArea(aAreaOld)

Return

User Function BIG0382()

	Local	aAreaOld	:= GetArea()
	Private cVend1i 	:= "      "
	Private cVend1f 	:= "999999"
	Private cVend2i 	:= "      "
	Private cVend2f 	:= "999999"
	Private lAltCli 	:= .T.
	Private cCampanha 	:= ""
	Private aCampanha 	:= {}
	Private cTpcon  	:= "Campanha"
	Private lUsaLits	:= cEmpAnt $ "02#11"

	If Type("lProspect") <> "U" .And. lProspect
		MsgAlert("Está selecionada a opção Prospect! Rotina só funciona com cadastro de clientes!","Selecionado Prospect")
		Return
	Endif


	cQry := ""
	cQry += "SELECT * "
	cQry += "  FROM "+ RetSqlName("SUO")
	cQry += " WHERE D_E_L_E_T_ =' '  "
	cQry += "   AND UO_FILIAL = '" + xFilial("SUO") + "' "
	cQry += "   AND '" + DTOS(dDataBase)+ "' BETWEEN UO_DTINI AND UO_DTFIM "
	cQry += " ORDER BY UO_CODCAMP DESC "

	TCQUERY cQry NEW ALIAS "QRY"

	dbSelectArea("QRY")
	dbGoTop()
	While !Eof()
		aadd(aCampanha,QRY->UO_CODCAMP + QRY->UO_DESC)
		dbSelectArea("QRY")
		dbSkip()
	End

	QRY->(DbCloseArea())

	@ 200,1 TO 380,395 DIALOG oLeTxt TITLE OemToAnsi("Paramêtros ")
	@ 02,10 TO 070,190
	@ 10,018 Say "Vendedor inicial"
	@ 10,070 Get cVend1i   SIZE 40,10
	@ 20,018 Say "Vendedor Final"
	@ 20,070 Get cVend1f   SIZE 40,10
	@ 30,018 Say "Madrinha inicial"
	@ 30,070 Get cVend2i   SIZE 40,10
	@ 40,018 Say "Madrinha final"
	@ 40,070 Get cVend2f   SIZE 40,10
	@ 50,018 Say "Selecione Campanha"
	@ 50,070 Combobox cCampanha Items aCampanha size 70,10
	@ 72,070 BUTTON "&Continua"  SIZE 40,15 ACTION (Processa({|| sfClientes() },"Localizando clientes"),oLeTxt:End() )
	@ 72,018 BUTTON "&Fechar"  SIZE 40,15 ACTION (oLeTxt:End() )

	Activate Dialog oLeTxt Centered

	RestArea(aAreaOld)

Return

Static Function Imprime()

	Local 	cDesc1 := "Este programa tem como objetivo imprimir relatorio "
	Local 	cDesc2 := "de acordo com os parametros informados pelo usuario."
	Local 	cDesc3 := "Ação Tmk Big Forta"
	Local 	titulo := "Ação Tmk Big Forta"
	Local 	nLin   := 220
	Local	nAno	:= Year(dDataBase)
	Local	nMes	:= Month(dDataBase)

	If Substr(dtos(dDatabase),5,2) == '01'
		cMes1 := Alltrim(Str(nAno-1))+"12"
		cMes2 := Alltrim(Str(nAno-1))+"11"
		cMes3 := Alltrim(Str(nAno-1))+"10"
		cMes4 := Alltrim(Str(nAno-1))+"09"
		cMes5 := Alltrim(Str(nAno-1))+"08"
	Elseif Substr(dtos(dDatabase),5,2) == '02'
		cMes1 := Alltrim(Str(nAno))+"01"
		cMes2 := Alltrim(Str(nAno-1))+"12"
		cMes3 := Alltrim(Str(nAno-1))+"11"
		cMes4 := Alltrim(Str(nAno-1))+"10"
		cMes5 := Alltrim(Str(nAno-1))+"09"

	Elseif Substr(dtos(dDatabase),5,2) == '03'
		cMes1 := Alltrim(Str(nAno))+"02"
		cMes2 := Alltrim(Str(nAno))+"01"
		cMes3 := Alltrim(Str(nAno-1))+"12"
		cMes4 := Alltrim(Str(nAno-1))+"11"
		cMes5 := Alltrim(Str(nAno-1))+"10"

	Elseif Substr(dtos(dDatabase),5,2) == '04'
		cMes1 := Alltrim(Str(nAno))+"03"
		cMes2 := Alltrim(Str(nAno))+"02"
		cMes3 := Alltrim(Str(nAno))+"01"
		cMes4 := Alltrim(Str(nAno-1))+"12"
		cMes5 := Alltrim(Str(nAno-1))+"11"

	Elseif Substr(dtos(dDatabase),5,2) == '05'
		cMes1 := Alltrim(Str(nAno))+"04"
		cMes2 := Alltrim(Str(nAno))+"03"
		cMes3 := Alltrim(Str(nAno))+"02"
		cMes4 := Alltrim(Str(nAno))+"01"
		cMes5 := Alltrim(Str(nAno-1))+"12"
	Elseif Substr(dtos(dDatabase),5,2) == '06'
		cMes1 := Alltrim(Str(nAno))+"05"
		cMes2 := Alltrim(Str(nAno))+"04"
		cMes3 := Alltrim(Str(nAno))+"03"
		cMes4 := Alltrim(Str(nAno))+"02"
		cMes5 := Alltrim(Str(nAno))+"01"
	Elseif Substr(dtos(dDatabase),5,2) == '07'
		cMes1 := Alltrim(Str(nAno))+"06"
		cMes2 := Alltrim(Str(nAno))+"05"
		cMes3 := Alltrim(Str(nAno))+"04"
		cMes4 := Alltrim(Str(nAno))+"03"
		cMes5 := Alltrim(Str(nAno))+"02"
	Elseif Substr(dtos(dDatabase),5,2) == '08'
		cMes1 := Alltrim(Str(nAno))+"07"
		cMes2 := Alltrim(Str(nAno))+"06"
		cMes3 := Alltrim(Str(nAno))+"05"
		cMes4 := Alltrim(Str(nAno))+"04"
		cMes5 := Alltrim(Str(nAno))+"03"
	Elseif Substr(dtos(dDatabase),5,2) == '09'
		cMes1 := Alltrim(Str(nAno))+"08"
		cMes2 := Alltrim(Str(nAno))+"07"
		cMes3 := Alltrim(Str(nAno))+"06"
		cMes4 := Alltrim(Str(nAno))+"05"
		cMes5 := Alltrim(Str(nAno))+"04"
	Elseif Substr(dtos(dDatabase),5,2) == '10'
		cMes1 := Alltrim(Str(nAno))+"09"
		cMes2 := Alltrim(Str(nAno))+"08"
		cMes3 := Alltrim(Str(nAno))+"07"
		cMes4 := Alltrim(Str(nAno))+"06"
		cMes5 := Alltrim(Str(nAno))+"05"

	Elseif Substr(dtos(dDatabase),5,2) == '11'
		cMes1 := Alltrim(Str(nAno))+"10"
		cMes2 := Alltrim(Str(nAno))+"09"
		cMes3 := Alltrim(Str(nAno))+"08"
		cMes4 := Alltrim(Str(nAno))+"07"
		cMes5 := Alltrim(Str(nAno))+"06"
	Elseif Substr(dtos(dDatabase),5,2) == '12'
		cMes1 := Alltrim(Str(nAno))+"11"
		cMes2 := Alltrim(Str(nAno))+"10"
		cMes3 := Alltrim(Str(nAno))+"09"
		cMes4 := Alltrim(Str(nAno))+"08"
		cMes5 := Alltrim(Str(nAno))+"07"
	Endif
	cAno     := Alltrim(Str(nAno))
	cMes     := cAno+Alltrim(StrZero(nMes,2))

	/////////////////  /01234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
	////////////////  //0         1         2         3         4         5         6         7        8         9        10        11        12         13        14        15        16        17        18        19        20        21        22
	//999999/99 |Razão                                   |Fantasia       |Endereço                                |Bairro         |Contato        |(999)9999999999|99/99/99|9,999,999|9,999,999| 9,999,999| 9,999,999| 9,999,999
	Private Cabec2  := ""
	Private Cabec1  := ""
	Private imprime := .T.
	Private aOrd    := {}

	Private lEnd         := .F.
	Private lAbortPrint  := .F.
	Private CbTxt        := ""
	Private limite       := 220
	Private tamanho      := "G"
	Private nomeprog     := "B38IMP"
	Private nTipo        := 18
	Private aReturn      := { "Zebrado", 1, "Administracao", 2, 2, 1, "", 1}
	Private nLastKey     := 0
	Private cPerg1       := "B38IMP"
	Private cbcont       := 00
	Private CONTFL       := 01
	Private m_pag        := 01
	Private wnrel        := "B38IMP"
	Private cCidOrd      := Space(40)
	Private cSemtmk      := Space(5)
	Private cCampanha    := ""
	Private nREg      := 0
	Private aClientes    := {}
	Private aClientes1   := {}
	Private aClientes2   := {}
	Private cMun  := ""
	Private nMun  := 0
	Private cVend := ""
	Private nVend := 0
	Private cSemt := Space(5)
	Private nSemt := 0

	// ValidPerg()

	Pergunte(cPerg1,.T.)

	wnrel := SetPrint(,NomeProg,cPerg1,@titulo,cDesc1,cDesc2,cDesc3,.T.,aOrd,.T.,Tamanho,,.T.)

	If nLastKey == 27
		Return
	Endif

	SetDefault(aReturn,)

	If nLastKey == 27
		Return
	Endif

	nTipo := If(aReturn[4]==1,15,18)

	RptStatus({|| Processa ({|| RunReport(Cabec1,Cabec2,Titulo,nLin) },Titulo)})
Return


Static Function RunReport(Cabec1,Cabec2,Titulo,nLin)
	Local s,j,z,y,x

	aSemanas := {{"1"},{"2"},{"3"},{"4"}}

	If mv_par06 == 1
		Cabec1  := "Código/Lj |Razão Social                            |Nome Reduzido  |Endereço                                |Bairro         |Contato        |(DDD)Fone      |Últ.Comp|    "+Substr(cMes4,5,2)+"/"+Substr(cMes4,3,2)+"|     "+;
			Substr(cMes3,5,2)+"/"+Substr(cMes3,3,2)+"|     "+;
			Substr(cMes2,5,2)+"/"+Substr(cMes2,3,2)+"|     "+;
			Substr(cMes1,5,2)+"/"+Substr(cMes1,3,2)+"|     "+;
			Substr(cMes,5,2)+"/"+Substr(cMes,3,2)+"|"
	Else
		Cabec1  := "Código/Lj |Razão Social                            |Cidade                   |Contato        |(DDD)Fone      |Últ.Comp|    "+Substr(cMes4,5,2)+"/"+Substr(cMes4,3,2)+"|     "+;
			Substr(cMes3,5,2)+"/"+Substr(cMes3,3,2)+"|     "+;
			Substr(cMes2,5,2)+"/"+Substr(cMes2,3,2)+"|     "+;
			Substr(cMes1,5,2)+"/"+Substr(cMes1,3,2)+"|     "+;
			Substr(cMes,5,2)+"/"+Substr(cMes,3,2)+"|Média     |_|_|_|_|_|_|_|_|_____________________"
	Endif

	If mv_par05  == 2
		cQrd := ""
		cQrd += "SELECT * FROM "
		cQrd += RetSqlName("SA1") + "  "
		cQrd += "WHERE A1_FILIAL = '" + xFilial("SA1") + "' "
		cQrd += "AND A1_VEND BETWEEN '" +mv_par01 + "' AND '" + mv_par02 + "' "
		//cQrd += "AND A1_VEND2 BETWEEN  '" + mv_par03 + "' AND '" +mv_par04+ "' "
		cQrd += "  "
		If mv_par06 == 1
			cQrd += "ORDER BY A1_MUN ASC,A1_ULTCOM DESC,A1_COD ASC,A1_LOJA ASC "
		Else
			cQrd += "ORDER BY A1_SEMTMK ASC,A1_ULTCOM DESC "
		Endif

	Else

		cQry := ""
		cQry += "SELECT * FROM "
		cQry += RetSqlName("SUO") + "  "
		cQry += "WHERE D_E_L_E_T_ =' '  "
		cQry += "AND UO_FILIAL = '" + xFilial("SUO") + "' "
		cQry += "AND '" + DTOS(dDataBase)+ "' BETWEEN UO_DTINI AND UO_DTFIM "
		cQry += "ORDER BY UO_CODCAMP DESC "

		TCQUERY cQry NEW ALIAS "QRY"

		dbSelectArea("QRY")
		dbGoTop()
		While !Eof()
			If cCampanha <> ""
				cCampanha += "','"+QRY->UO_CODCAMP
			Else
				cCampanha += QRY->UO_CODCAMP
			Endif
			dbSelectArea("QRY")
			dbSkip()
		Enddo
		QRY->(DbCloseArea())

		If cCampanha == ""
			cCampanha := "999999"
		Endif

		cQrd := ""
		cQrd += "SELECT * FROM "
		cQrd += RetSqlName("SA1") + "  "
		cQrd += "WHERE A1_FILIAL = '" + xFilial("SA1") + "' "
		cQrd += "AND A1_VEND BETWEEN '" +mv_par01 + "' AND '" + mv_par02 + "' "
		cQrd += "AND A1_VEND2 BETWEEN  '" + mv_par03 + "' AND '" +mv_par04+ "' "
		If cEmpAnt == "02"
			cQrd += " AND A1_CAMPANH IN('"+ cCampanha + "') "
		Endif
		If mv_par06 == 1
			cQrd += "ORDER BY A1_MUN ASC,A1_ULTCOM DESC,A1_COD ASC,A1_LOJA ASC "
		Else
			cQrd += "ORDER BY A1_SEMTMK ASC,A1_ULTCOM DESC "
		Endif
	Endif

	TCQUERY cQrd NEW ALIAS "QRD"

	Count to nReg

	ProcRegua(nReg)


	Dbselectarea("QRD")
	dbgotop()
	While !Eof()
		cCidOrd  := QRD->A1_MUN
		cSemTmk  := QRD->A1_SEMTMK

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Impressao do cabecalho do relatorio. . .                            ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ


		If mv_par06 == 1
			IncProc(Substr(cCidOrd,1,12)+"-"+QRD->A1_COD+"/"+QRD->A1_LOJA+"-"+QRD->A1_NREDUZ)
		Else
			IncProc(cSemTmk+"-"+QRD->A1_COD+"/"+QRD->A1_LOJA+"-"+QRD->A1_NREDUZ)
		Endif


		cQri := ""
		cQri += "SELECT SUM(D2_TOTAL)AS FATU FROM "
		cQri += RetSqlName("SD2") + " SD2, " +RetSqlName("SF4") + " SF4 "
		cQri += "WHERE SD2.D_E_L_E_T_ = ' ' AND SF4.D_E_L_E_T_ = ' ' "
		cQri += "AND SD2.D2_FILIAL = '" + xFilial("SD2") + "'  "
		cQri += "AND SF4.F4_FILIAL = '" + xFilial("SF4") + "'  "
		cQri += "AND SD2.D2_CLIENTE = '" + QRD->A1_COD + "' AND SD2.D2_LOJA = '" + QRD->A1_LOJA + "' "
		cQri += "AND SD2.D2_TES = SF4.F4_CODIGO AND SUBSTR(D2_EMISSAO,1,6) = '" + cMes4+ "' "

		TCQUERY cQri NEW ALIAS "QD2_1"

		Dbselectarea("QD2_1")
		dbgotop()

		cQri := ""
		cQri += "SELECT SUM(D2_TOTAL)AS FATU FROM "
		cQri += RetSqlName("SD2") + " SD2, " +RetSqlName("SF4") + " SF4 "
		cQri += "WHERE SD2.D_E_L_E_T_ = ' ' AND SF4.D_E_L_E_T_ = ' ' "
		cQri += "AND SD2.D2_FILIAL = '" + xFilial("SD2") + "'  "
		cQri += "AND SF4.F4_FILIAL = '" + xFilial("SF4") + "'  "
		cQri += "AND SD2.D2_CLIENTE = '" + QRD->A1_COD + "' AND SD2.D2_LOJA = '" + QRD->A1_LOJA + "' "
		cQri += "AND SD2.D2_TES = SF4.F4_CODIGO AND SUBSTR(D2_EMISSAO,1,6) = '" + cMes3 +"' "

		TCQUERY cQri NEW ALIAS "QD2_2"

		Dbselectarea("QD2_2")
		dbgotop()

		cQri := ""
		cQri += "SELECT SUM(D2_TOTAL)AS FATU FROM "
		cQri += RetSqlName("SD2") + " SD2, " +RetSqlName("SF4") + " SF4 "
		cQri += "WHERE SD2.D_E_L_E_T_ = ' ' AND SF4.D_E_L_E_T_ = ' ' "
		cQri += "AND SD2.D2_FILIAL = '" + xFilial("SD2") + "'  "
		cQri += "AND SF4.F4_FILIAL = '" + xFilial("SF4") + "'  "
		cQri += "AND SD2.D2_CLIENTE = '" + QRD->A1_COD + "' AND SD2.D2_LOJA = '" + QRD->A1_LOJA + "' "
		cQri += "AND SD2.D2_TES = SF4.F4_CODIGO AND SUBSTR(D2_EMISSAO,1,6) = '" + cMes2 +"' "

		TCQUERY cQri NEW ALIAS "QD2_3"

		Dbselectarea("QD2_3")
		dbgotop()


		cQri := ""
		cQri += "SELECT SUM(D2_TOTAL)AS FATU FROM "
		cQri += RetSqlName("SD2") + " SD2, " +RetSqlName("SF4") + " SF4 "
		cQri += "WHERE SD2.D_E_L_E_T_ = ' ' AND SF4.D_E_L_E_T_ = ' ' "
		cQri += "AND SD2.D2_FILIAL = '" + xFilial("SD2") + "'  "
		cQri += "AND SF4.F4_FILIAL = '" + xFilial("SF4") + "'  "
		cQri += "AND SD2.D2_CLIENTE = '" + QRD->A1_COD + "' AND SD2.D2_LOJA = '" + QRD->A1_LOJA + "' "
		cQri += "AND SD2.D2_TES = SF4.F4_CODIGO AND SUBSTR(D2_EMISSAO,1,6) = '" + cMes1+ "' "

		TCQUERY cQri NEW ALIAS "QD2_4"

		Dbselectarea("QD2_4")
		dbgotop()

		cQri := ""
		cQri += "SELECT SUM(D2_TOTAL)AS FATU FROM "
		cQri += RetSqlName("SD2") + " SD2, " +RetSqlName("SF4") + " SF4 "
		cQri += "WHERE SD2.D_E_L_E_T_ = ' ' AND SF4.D_E_L_E_T_ = ' ' "
		cQri += "AND SD2.D2_FILIAL = '" + xFilial("SD2") + "'  "
		cQri += "AND SF4.F4_FILIAL = '" + xFilial("SF4") + "'  "
		cQri += "AND SD2.D2_CLIENTE = '" + QRD->A1_COD + "' AND SD2.D2_LOJA = '" + QRD->A1_LOJA + "' "
		cQri += "AND SD2.D2_TES = SF4.F4_CODIGO AND SUBSTR(D2_EMISSAO,1,6) = '" + cMes+ "' "


		TCQUERY cQri NEW ALIAS "QD2_5"

		Dbselectarea("QD2_5")
		dbgotop()
		For s := 1 To Len(aSemanas)
			For j := 1 To Len(QRD->A1_SEMTMK) Step 1
				If Substr(QRD->A1_SEMTMK,j,1) == aSemanas[s][1]
					Aadd(aClientes,{QRD->A1_COD,QRD->A1_LOJA,QRD->A1_NOME,QRD->A1_NREDUZ,QRD->A1_CONTATO,QRD->A1_DDD,QRD->A1_TEL,;
						QRD->A1_VEND,QRD->A1_VEND2,STOD(QRD->A1_ULTCOM),QRD->A1_END,QRD->A1_BAIRRO,QRD->A1_MUN,aSemanas[s][1],QRD->A1_SATIV1,;
						QD2_1->FATU,QD2_2->FATU,QD2_3->FATU,QD2_4->FATU,QD2_5->FATU,(QD2_1->FATU+QD2_2->FATU+QD2_3->FATU+QD2_4->FATU+QD2_5->FATU)/5})
				Endif
			Next
		Next
		QD2_1->(DbCloseArea())
		QD2_2->(DbCloseArea())
		QD2_3->(DbCloseArea())
		QD2_4->(DbCloseArea())
		QD2_5->(DbCloseArea())

		Dbselectarea("QRD")
		Dbskip()
	Enddo

	QRD->(DbCloseArea())


	aClientes1  := aClone(aClientes)
	aClientes2  := aClone(aClientes)
	aSort(aClientes,,,{|x,y| x[8] < y[8] })
	If mv_par06 == 1
		aSort(aClientes1,,,{|x,y| x[13] < y[13] })
		aSort(aClientes2,,,{|x,y| x[21] > y[21] })

		For x := 1 To Len(aClientes)
			If aClientes[x][8] <> cVend

				nLin := Cabec(Titulo,Cabec1,Cabec2,NomeProg,Tamanho,nTipo)
				nLin++
				dbselectarea("SA3")
				Dbsetorder(1)
				dbseek(xFilial("SA3")+aClientes[x][8])
				@nLin,000 Psay "Vendedor-> " +aClientes[x][8]+" "+SA3->A3_NREDUZ

				For y := 1 To Len(aClientes1)
					If aClientes1[y][8] == aClientes[x][8]
						If aClientes1[y][13] <> cMun
							If nLin > 57 // Salto de Página. Neste caso o formulario tem 55 linhas...
								nLin := Cabec(Titulo,Cabec1,Cabec2,NomeProg,Tamanho,nTipo)
								nLin++
							Endif
							nLin++
							nLin++
							@nLin,000 Psay "******Cidade de-> " +aClientes1[y][13]+Repli("*",172)

							For z := 1 To Len(aClientes2)
								If aClientes2[z][8] == aClientes[x][8] .and. aClientes2[z][13] == aClientes1[y][13]


									//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
									//³ Verifica o cancelamento pelo usuario...                             ³
									//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
									If nLin > 57 // Salto de Página. Neste caso o formulario tem 55 linhas...
										nLin := Cabec(Titulo,Cabec1,Cabec2,NomeProg,Tamanho,nTipo)
										nLin++
									Endif

									nLin++
									@nLin,000 Psay aClientes2[z][1]+"/"+aClientes2[z][2]
									@nLin,010 Psay "|"
									@nLin,011 Psay Substr(aClientes2[z][3],1,39)
									@nLin,051 Psay "|"
									@nLin,052 Psay Substr(aClientes2[z][4],1,14)
									@nLin,067 Psay "|"
									@nLin,068 Psay Substr(aClientes2[z][11],1,39)
									@nLin,108 Psay "|"
									@nLin,109 Psay Substr(aClientes2[z][12],1,14)
									@nLin,124 Psay "|"
									@nLin,125 Psay Substr(aClientes2[z][5],1,14)
									@nLin,140 Psay "|"
									@nLin,141 Psay "("+aClientes2[z][6]+")"+Substr(aClientes2[z][7],1,10)
									@nLin,156 Psay "|"
									@nLin,157 Psay aClientes2[z][10]
									@nLin,165 Psay "|"

									@nLin,166 Psay Transform(aClientes2[z][16],"@E 9,999,999")
									@nLin,175 Psay "|"

									@nLin,177 Psay Transform(aClientes2[z][17],"@E 9,999,999")
									@nLin,186 Psay "|"

									@nLin,188 Psay Transform(aClientes2[z][18],"@E 9,999,999")
									@nLin,197 Psay "|"

									@nLin,199 Psay Transform(aClientes2[z][19],"@E 9,999,999")
									@nLin,208 Psay "|"

									@nLin,210 Psay Transform(aClientes2[z][20],"@E 9,999,999")
									@nLin,219 Psay "|"
								Endif
							Next

						Endif
						cMun := aClientes1[y][13]

					Endif

				Next


			Endif
			cVend := aClientes[x][8]
			cMun := ""
		Next

	Else

		aSort(aClientes1,,,{|x,y| x[14] < y[14] })
		aSort(aClientes2,,,{|x,y| Strzero(x[21],10)+Dtos(x[10])+Substr(x[13],1,15) > Strzero(y[21],10)+Dtos(y[10])+Substr(y[13],1,15) })



		For x := 1 To Len(aClientes)
			If aClientes[x][8] <> cVend
				For y := 1 To Len(aClientes1)
					If aClientes1[y][8] == aClientes[x][8]
						If aClientes1[y][14] <> cSemt

							nLin := Cabec(Titulo,Cabec1,Cabec2,NomeProg,Tamanho,nTipo)
							dbselectarea("SA3")
							Dbsetorder(1)
							dbseek(xFilial("SA3")+aClientes[x][8],.t.)
							nLin++
							@nLin,000 Psay "Vendedor-> " +aClientes[x][8]+" "+SA3->A3_NREDUZ
							nLin++
							nLin++
							@nLin,000 Psay "******Semana   -> " +aClientes1[y][14]+Repli("*",200)
							nLin++
							For z := 1 To Len(aClientes2)
								If aClientes2[z][8] == aClientes[x][8] .and. aClientes2[z][14] == aClientes1[y][14]


									//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
									//³ Verifica o cancelamento pelo usuario...                             ³
									//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
									If nLin > 57 // Salto de Página. Neste caso o formulario tem 55 linhas...
										nLin := Cabec(Titulo,Cabec1,Cabec2,NomeProg,Tamanho,nTipo)
										nLin++
									Endif

									nLin++
									@nLin,000 Psay aClientes2[z][1]+"/"+aClientes2[z][2]
									@nLin,010 Psay "|"
									@nLin,011 Psay Substr(aClientes2[z][3],1,39)
									@nLin,051 Psay "|"
									@nLin,052 Psay Substr(aClientes2[z][13],1,24)
									@nLin,077 Psay "|"
									@nLin,078 Psay Substr(aClientes2[z][5],1,14)
									@nLin,093 Psay "|"
									@nLin,094 Psay "("+aClientes2[z][6]+")"+Substr(aClientes2[z][7],1,10)
									@nLin,109 Psay "|"
									@nLin,110 Psay aClientes2[z][10]
									@nLin,118 Psay "|"

									@nLin,119 Psay Transform(aClientes2[z][16],"@E 9,999,999")
									@nLin,128 Psay "|"

									@nLin,129 Psay Transform(aClientes2[z][17],"@E 9,999,999")
									@nLin,139 Psay "|"

									@nLin,140 Psay Transform(aClientes2[z][18],"@E 9,999,999")
									@nLin,150 Psay "|"

									@nLin,151 Psay Transform(aClientes2[z][19],"@E 9,999,999")
									@nLin,161 Psay "|"

									@nLin,162 Psay Transform(aClientes2[z][20],"@E 9,999,999")
									@nLin,172 Psay "|"
									@nLin,173 Psay Transform(aClientes2[z][21],"@E 9,999,999")
									@nLin,183 Psay "|_|_|_|_|_|_|_|_|______________________"

								Endif
							Next

						Endif
						cSemt := aClientes1[y][14]
					Endif

				Next


			Endif
			cVend := aClientes[x][8]
			cSemt := ""
		Next

	Endif


	Roda(0,"","P")


	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Finaliza a execucao do relatorio...                                 ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	SET DEVICE TO SCREEN

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Se impressao em disco, chama o gerenciador de impressao...          ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	If aReturn[5]==1
		dbCommitAll()
		SET PRINTER TO
		OurSpool(wnrel)
	Endif

	MS_FLUSH()

Return

// Static Function ValidPerg

// 	Local aRegs := {}
// 	Local i,j

// 	dbSelectArea("SX1")
// 	dbSetOrder(1)

// 	cPerg1 :=  PADR(cPerg1,Len(SX1->X1_GRUPO))
// 	AADD(aRegs,{cPerg1,"01","Do Vendedor","","","mv_ch1","C",06,0,0,"G","","mv_par01","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
// 	AADD(aRegs,{cPerg1,"02","Até Vendedor","","","mv_ch2","C",06,0,0,"G","","mv_par02","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
// 	AADD(aRegs,{cPerg1,"03","Da Madrinha","","","mv_ch3","C",06,0,0,"G","","mv_par03","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
// 	AADD(aRegs,{cPerg1,"04","Até Madrinha","","","mv_ch4","C",06,0,0,"G","","mv_par04","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
// 	AADD(aRegs,{cPerg1,"05","Incluso em Campanha","","","mv_ch5","N",01,0,0,"C","","mv_par05","Sim","","","","","Não","","","","","","","","","","","","","","","","","","","","",""})
// 	AADD(aRegs,{cPerg1,"06","Impressão por ordem de","","","mv_ch6","N",01,0,0,"C","","mv_par06","Cidade","","","","","Semana Tmk","","","","","","","","","","","","","","","","","","","","",""})
// 	For i:=1 to Len(aRegs)
// 		If !dbSeek(cPerg1+aRegs[i,2])
// 			RecLock("SX1",.T.)
// 			For j:=1 to FCount()
// 				If j <= Len(aRegs[i])
// 					FieldPut(j,aRegs[i,j])
// 				Endif
// 			Next
// 			MsUnlock()
// 		Endif
// 	Next

// Return


User Function BIG0383

	Private cClialt := Space(6)
	Private cLojalt := Space(2)
	Private cSemalt := Space(4)
	Private aSemtmk := {"1","2","3","4","12","13","14","23","24","34","1234"}
	@ 200,1 TO 380,395 DIALOG oLeTxt TITLE OemToAnsi("Alterar semana Tmk")
	@ 02,10 TO 070,190
	@ 10,018 Say "Código do Cliente e Loja"
	@ 10,090 Get cClialt Size 40,13 F3 "SA1"
	@ 10,130 Get cLojalt Size 12,13
	@ 25,018 Get Iif(cClialt == '',' ',SA1->A1_NOME) size 110,15 When .f.
	@ 40,018 Say "Escolha a Semana"
	@ 40,070 Combobox cSemalt Items aSemtmk size 20,10

	@ 72,133 BMPBUTTON TYPE 01 ACTION OkLeTxt()
	@ 72,163 BMPBUTTON TYPE 02 ACTION Close(oLeTxt)

	Activate Dialog oLeTxt Centered

Return

Static Function OkleTxt()

	Dbselectarea("SA1")
	dbsetorder(1)
	dbgotop()
	If Dbseek(xFilial("SA1")+cClialt+cLojalt)
		Dbselectarea("SA1")
		RecLock("SA1",.F.)
		SA1->A1_SEMTMK := cSemalt
		MsUnLock()

		Alert("Alteração concluída com sucesso.")

	Else
		Alert("Erro na gravação, verifique parametros")
	Endif
	Close(oLeTxt)
Return




