#INCLUDE "rwmake.ch"
#INCLUDE "topconn.ch"
#INCLUDE "tbiconn.ch"
#DEFINE	 SM0_CGC	18
#DEFINE  SM0_CODFIL 2		
#DEFINE  SM0_NOMRED	7
/*/{Protheus.doc} BFTMKC01
(Ação TMK dentro da Tela de Atendimento Callcenter)
@author MarceloLauschner
@since 04/05/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function MLFATC06()

	Private	cVend1i 		:= "      "
	Private 	cVend1f 	:= "999999"

	Private 	cCliente 	:= "000001"
	Private 	cLj      	:= "01"
	Private 	cRazao
	Private 	lAltCli 	:= .F.
	Private		lUsaLits	:= cEmpAnt == "02"

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
	@ 72,070 BUTTON "&Continua"  SIZE 40,15 ACTION (Processa({|| sfClientes() },"Localizando clientes"),oLeTxt:End() )
	@ 72,018 BUTTON "&Fechar"  SIZE 40,15 ACTION (oLeTxt:End() )

	Activate Dialog oLeTxt Centered


Return



/*/{Protheus.doc} sfClientes
(long_description)
@author MarceloLauschner
@since 04/05/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
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
	// Verifica se deve buscar o campo de vendedor específico 
	If SA1->(FieldPos(U_MLFATG05(1))) > 0 
		cCpoVend 	:= U_MLFATG05(1)
	Else 
		cCpoVend	:= "A1_VEND"
	Endif 

	cQrd := ""
	cQrd += "SELECT "+cCpoVend+" AS A1_VEND,A1_COD,A1_LOJA,A1_NREDUZ,A1_NOME,A1_MUN,A1_CONTATO,A1_DDD,A1_TEL,A1_ULTCOM "
	cQrd += "  FROM " + RetSqlName("SA1")
	cQrd += " WHERE A1_FILIAL = '" + xFilial("SA1") + "' "
	cQrd += "   AND "+cCpoVend+" BETWEEN '" +cVend1i + "' AND '" + cVend1f + "' "
	cQrd += " ORDER BY "+cCpoVend+" ASC,A1_ULTCOM DESC,A1_COD ASC,A1_LOJA ASC "

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
	//@ 310,125 Button "&Cotações" size 50,13 Action ( Processa({|| sfCotacao()},"Consultando"))
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


/*/{Protheus.doc} sfSearch
(long_description)
@author MarceloLauschner
@since 04/05/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
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


/*/{Protheus.doc} sfAtuCodLj
(long_description)
@author MarceloLauschner
@since 04/05/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/

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



/*/{Protheus.doc} sfViewNFs
(Consulta de Nota fiscais)
@author MarceloLauschner
@since 04/05/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfViewNFs()

	Local cNota   	:= ""
	Local cPedido 	:= ""
	Local dFat
	Local nValor  	:= 0.00
	Local cTransp 	:= ""
	Local aCampos 	:= {}
	Local aStru   	:= {}
	Local nFat    	:= 0.00
	Local aNomeFil	:= {}
	Local lCliInGrp	:= .F. 
	Local	aRecSM0		:= FWLoadSM0() // Usando função segura para retornar informação de empresas ativas
	Local	ix
	aSort(aRecSM0,,,{|x,y| x[SM0_CGC] < y[SM0_CGC] })
	
	
	sfAtuCodLj()

	If !Empty(SA1->A1_GRPVEN)
		lCliInGrp	:= .T. 
	Endif 
	

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

	cQri := ""
	cQri += "SELECT '"+cEmpAnt+"' EMPRESA,F2_FILIAL,F2_SERIE,F2_DOC,D2_PEDIDO,F2_EMISSAO,F2_VALBRUT,F2_DUPL,F2_COND, E4_DESCRI "
	cQri += "       ,F2_TRANSP + '-' + COALESCE((SELECT A4_NREDUZ "
	cQri += "                                   FROM "+RetSqlName("SA4")
	cQri += "                                  WHERE D_E_L_E_T_ = ' ' "
	cQri += "                                    AND A4_COD = F2_TRANSP "
	cQri += "                                    AND A4_FILIAL = '  ' ),' ' )F2_TRANSP "
	If lCliInGrp
		cQri += "       ,F2_CLIENTE + '/' + F2_LOJA + '-' + (SELECT A1_NOME "
		cQri += "                                               FROM " + RetSqlName("SA1") + " A1 "
		cQri += "                                              WHERE A1.D_E_L_E_T_ =' ' "
		cQri += "                                                AND A1_COD = F2_CLIENTE "
		cQri += "                                                AND A1_LOJA = F2_LOJA "
		cQri += "                                                AND A1_FILIAL = '" + xFilial("SA1") + "') CLIENTE "
	Endif
	cQri += "  FROM "+ RetSqlName("SD2") + " SD2, " + RetSqlName("SF2") + " SF2, " + RetSqlName("SE4") + " SE4 "
	cQri += " WHERE SE4.D_E_L_E_T_ = ' ' "
	cQri += "   AND SE4.E4_CODIGO = SF2.F2_COND "
	cQri += "   AND SE4.E4_FILIAL = CASE WHEN '"+xFilial("SE4")+"' = '  ' THEN '  ' ELSE D2_FILIAL END "
	cQri += "   AND SF2.D_E_L_E_T_ = ' ' "
	cQri += "   AND SF2.F2_TIPO = 'N' "
	cQri += "   AND SF2.F2_DOC = SD2.D2_DOC "
	cQri += "   AND SF2.F2_SERIE = SD2.D2_SERIE "
	cQri += "   AND SF2.F2_LOJA = SD2.D2_LOJA "
	cQri += "   AND SF2.F2_CLIENTE = SD2.D2_CLIENTE "
	cQri += "   AND SF2.F2_FILIAL = SD2.D2_FILIAL "
	cQri += "   AND SD2.D_E_L_E_T_ = ' ' "
	If lCliInGrp
		cQri += "   AND (SD2.D2_CLIENTE,SD2.D2_LOJA) IN(SELECT A1_COD,A1_LOJA "
		cQri += "                                         FROM " + RetSqlName("SA1") + " A1 "
		cQri += "                                        WHERE A1.D_E_L_E_T_ =' ' "
		cQri += "                                          AND A1_GRPVEN = '" + SA1->A1_GRPVEN +"'"
		cQri += "                                          AND A1_FILIAL = '" + xFilial("SA1") + "')"
	Else
		cQri += "   AND SD2.D2_LOJA = '" + cLj + "' "
		cQri += "   AND SD2.D2_CLIENTE = '" + cCliente + "' "
	Endif
	cQri += "   AND SD2.D2_FILIAL IN "+FormatIN(GetNewPar("GF_FILIAIS",cFilAnt+""),"/")
	cQri += " GROUP BY F2_FILIAL,SF2.F2_SERIE, SF2.F2_DOC,SD2.D2_PEDIDO,SF2.F2_EMISSAO,SF2.F2_VALBRUT,SF2.F2_TRANSP,SF2.F2_DUPL,SF2.F2_COND, E4_DESCRI "
	If lCliInGrp
		cQri += " ,F2_CLIENTE,F2_LOJA"
	Endif
	
	cQri += " UNION ALL "

	cQri += "SELECT '"+cEmpAnt+"'          AS EMPRESA,"
	cQri += "       ZZ1_FILIAL    AS F2_FILIAL,"
	cQri += "       ZZ1_SERIE     AS F2_SERIE,"
	cQri += "       SUBSTRING(ZZ1_CHNFE,27,9) AS F2_DOC,"
	cQri += "       ' '           AS D2_PEDIDO,"
	cQri += "       ZZ1_EMISSA    AS F2_EMISSAO,"
	cQri += "       SUM(ZZ1_VALNF)AS F2_VALBRUT,"
	cQri += "       CASE WHEN SUM(CASE WHEN ZZ1_CFOP IN('6656','6655','6404','6403','6110','6108','6107','6102','6101','5656','5655','5405','5403','5102','5101') THEN 1 ELSE 0 END) > 0 THEN SUBSTRING(ZZ1_CHNFE,27,9) ELSE ' ' END  AS F2_DUPL,"
	cQri += "       ' '           AS F2_COND,"
	cQri += "       ZZ1_CODPG     AS E4_DESCRI, "
	cQri += "       ' '           AS F2_TRANSP "
	cQri += "  FROM " + RetSqlName("ZZ1") + " ZZ1, " + RetSqlName("SA1") + " SA1 "
	cQri += " WHERE SA1.D_E_L_E_T_ =' ' "
	cQri += "   AND A1_MSBLQL <> '1'"
	cQri += "   AND A1_LOJA = '" + cLj + "' "
	cQri += "   AND A1_COD = '" + cCliente + "' "
	cQri += "   AND A1_FILIAL = '" + xFilial("SA1") + "'"
	cQri += "   AND ZZ1.D_E_L_E_T_ =' ' "
	cQri += "   AND ZZ1_CNPJ = A1_CGC "
	cQri += "   AND ZZ1_FILIAL IN "+FormatIN(GetNewPar("GF_FILIAIS",cFilAnt+""),"/") //= '"+xFilial("ZZ1")+"'"
	cQri += " GROUP BY ZZ1_FILIAL,ZZ1_SERIE,SUBSTRING(ZZ1_CHNFE,27,9) ,ZZ1_EMISSA,ZZ1_CODPG "
	cQri += " ORDER BY F2_EMISSAO DESC,F2_DOC "

	TCQUERY cQri NEW ALIAS "QF2"

	While !Eof()
		If !Empty(QF2->F2_DOC)

			cDescFilial	:= QF2->F2_FILIAL
			
			For ix := 1 To Len(aRecSM0)
				//MsgAlert(aRecSM0[iX][SM0_CODFIL],QF2->F2_FILIAL)
				If aRecSM0[iX][SM0_CODFIL] == QF2->F2_FILIAL
					cDescFilial	:= aRecSM0[iX][SM0_CODFIL] + "-" + aRecSM0[iX][SM0_NOMRED]
				Endif
			Next
			
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




/*/{Protheus.doc} sfProdutos
(long_description)
@author MarceloLauschner
@since 04/05/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfProdutos()

	Local aCampos 	:= {}
	Local aStru   	:= {}
	Local nFat    	:= 0.00
	Local cCodProd	:= ""
	Local lCliInGrp	:= .F. 
	Local	aRecSM0		:= FWLoadSM0() // Usando função segura para retornar informação de empresas ativas
	Local	ix
	aSort(aRecSM0,,,{|x,y| x[SM0_CGC] < y[SM0_CGC] })
	
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
	If lCliInGrp
		Aadd(aStru,{ "CLIENTE" , "C" , 80,0 })
	Endif
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


	cQri := ""
	cQri += "SELECT '"+cEmpAnt+"' EMPRESA,"
	cQri += "       D2_FILIAL,D2_TOTAL,D2_SERIE,D2_DOC,D2_PEDIDO,D2_EMISSAO,D2_COD,D2_QUANT,D2_PRCVEN,D2_VALBRUT,D2_CF,D2_TES,"
	If lUsaLits
		cQri += "       B1_DESC, F4_TEXTO ,D2_VALPROM,B1_XLITROS,F2_COND,E4_DESCRI "
	Else
		cQri += "       B1_DESC, F4_TEXTO ,0 D2_VALPROM,0 B1_XLITROS,F2_COND,E4_DESCRI "
	Endif
	If lCliInGrp
		cQri += "       ,F2_CLIENTE + '/' + F2_LOJA +'-' + (SELECT A1_NOME "
		cQri += "                                               FROM " + RetSqlName("SA1") + " A1 "
		cQri += "                                              WHERE A1.D_E_L_E_T_ =' ' "
		cQri += "                                                AND A1_COD = F2_CLIENTE "
		cQri += "                                                AND A1_LOJA = F2_LOJA "
		cQri += "                                                AND A1_FILIAL = '" + xFilial("SA1") + "') CLIENTE "
	Endif
	cQri += "  FROM "+RetSqlName("SD2") + " SD2, " + RetSqlName("SB1") + " SB1, " + RetSqlName("SA1") + " SA1, "+RetSqlName("SF4") + " SF4, "
	cQri += "       " + RetSqlName("SF2") + " SF2, " + RetSqlName("SE4") + " SE4 "
	cQri += " WHERE SF4.D_E_L_E_T_ = ' ' "
	cQri += "   AND SF4.F4_CODIGO = SD2.D2_TES "
	cQri += "   AND SF4.F4_FILIAL = SD2.D2_FILIAL "
	cQri += "   AND SE4.D_E_L_E_T_ = ' ' "
	cQri += "   AND SE4.E4_CODIGO  = F2_COND "
	cQri += "   AND SE4.E4_FILIAL = CASE WHEN '"+xFilial("SE4")+"' = '  ' THEN '  ' ELSE D2_FILIAL END "
	cQri += "   AND SF2.D_E_L_E_T_ = ' ' "
	cQri += "   AND SF2.F2_LOJA = SD2.D2_LOJA "
	cQri += "   AND SF2.F2_CLIENTE = SD2.D2_CLIENTE "
	cQri += "   AND SF2.F2_SERIE = SD2.D2_SERIE "
	cQri += "   AND SF2.F2_DOC = SD2.D2_DOC "
	cQri += "   AND SF2.F2_FILIAL = SD2.D2_FILIAL "
	cQri += "   AND SA1.D_E_L_E_T_ = ' ' "
	cQri += "   AND SA1.A1_LOJA = SD2.D2_LOJA "
	cQri += "   AND SA1.A1_COD = SD2.D2_CLIENTE "
	cQri += "   AND SA1.A1_FILIAL = '" + xFilial("SA1") + "' "
	cQri += "   AND SB1.D_E_L_E_T_ = ' ' "
	cQri += "   AND SB1.B1_COD = SD2.D2_COD "
	cQri += "   AND SB1.B1_FILIAL = CASE WHEN '"+xFilial("SB1")+"' = '"+xFilial("SD2")+"' THEN D2_FILIAL ELSE SUBSTRING(D2_FILIAL,1," + cValToChar(Len(cEmpAnt)) + ") END "
	cQri += "   AND SD2.D2_TIPO = 'N' "
	If !Empty(cCodProd)
		cQri += "  AND SD2.D2_COD = '"+cCodProd+"' "
	Endif
	cQri += "   AND SD2.D_E_L_E_T_ = ' ' "
	If lCliInGrp
		cQri += "   AND (SD2.D2_CLIENTE,SD2.D2_LOJA) IN(SELECT A1_COD,A1_LOJA "
		cQri += "                                         FROM " + RetSqlName("SA1") + " A1 "
		cQri += "                                        WHERE A1.D_E_L_E_T_ =' ' "
		cQri += "                                          AND A1_GRPVEN = '" + SA1->A1_GRPVEN +"'"
		cQri += "                                          AND A1_FILIAL = '" + xFilial("SA1") + "')"
	Else
		cQri += "   AND SD2.D2_LOJA = '" + cLj + "' "
		cQri += "   AND SD2.D2_CLIENTE = '" + cCliente + "' "
	Endif
	cQri += "   AND SD2.D2_FILIAL IN "+FormatIN(GetNewPar("GF_FILIAIS",cFilAnt+""),"/")


	cQri += " UNION ALL "

	cQri += "SELECT '"+cEmpAnt+"'          AS EMPRESA,"
	cQri += "       ZZ1_FILIAL    AS D2_FILIAL,"
	cQri += "       ZZ1_VALNF     AS D2_TOTAL,"
	cQri += "       ZZ1_SERIE     AS D2_SERIE,"
	cQri += "       SUBSTRING(ZZ1_CHNFE,27,9)      AS D2_DOC,"
	cQri += "       ' '           AS D2_PEDIDO,"
	cQri += "       ZZ1_EMISSA    AS D2_EMISSAO,"
	cQri += "       ZZ1_CODPRO    AS D2_COD,"
	cQri += "       ZZ1_QTDFAT    AS D2_QUANT,"
	cQri += "       ZZ1_PRCVEN    AS D2_PRCVEN,"
	cQri += "       ZZ1_VALNF + ZZ1_VALIPI + ZZ1_VICMST AS D2_VALBRUT, "
	cQri += "       ZZ1_CFOP      AS D2_CF,"
	cQri += "       '  '          AS D2_TES,"
	cQri += "       ZZ1_DESCPR    AS B1_DESC,"
	cQri += "       ' '           AS F4_TEXTO,"
	cQri += "       0             AS D2_VALPROM,"
	cQri += "       0             AS B1_XLITROS,"
	cQri += "       '  '          AS F2_COND,"
	cQri += "       ZZ1_CODPG     AS E4_DESCRI"
	cQri += "  FROM " + RetSqlName("ZZ1") + " ZZ1, " + RetSqlName("SA1") + " SA1 "
	cQri += " WHERE SA1.D_E_L_E_T_ =' ' "
	cQri += "   AND A1_MSBLQL <> '1'"
	cQri += "   AND A1_LOJA = '" + cLj + "' "
	cQri += "   AND A1_COD = '" + cCliente + "' "
	cQri += "   AND A1_FILIAL = '" + xFilial("SA1") + "'"
	cQri += "   AND ZZ1.D_E_L_E_T_ =' ' "
	cQri += "   AND ZZ1_CNPJ = A1_CGC "
	cQri += "   AND ZZ1_FILIAL IN "+FormatIN(GetNewPar("GF_FILIAIS",cFilAnt+""),"/") ///= '"+xFilial("ZZ1")+"'"
	If !Empty(cCodProd)
		cQri += "  AND ZZ1_CODPRO = '"+cCodProd+"' "
	Endif
	
	cQri += " ORDER BY D2_EMISSAO DESC, D2_DOC DESC , D2_SERIE DESC, D2_COD, F4_TEXTO ASC "
	
	MemoWrite("c:\edi\mlfatc06.sql",cQri)	

	TCQUERY cQri NEW ALIAS "QD2"

	While !Eof()

		If !Empty(QD2->D2_DOC)
			cDescFilial	:= QD2->D2_FILIAL
			
			For ix := 1 To Len(aRecSM0)
				If aRecSM0[iX][SM0_CODFIL] == QD2->D2_FILIAL
					cDescFilial	:= aRecSM0[iX][SM0_CODFIL] + "-" + aRecSM0[iX][SM0_NOMRED]
				Endif
			Next

			dbSelectArea("PROD")
			RecLock("PROD",.T.)
			PROD->FILIAL	:= cDescFilial
			PROD->SERIE 	:= QD2->D2_SERIE
			PROD->NOTA    	:= QD2->D2_DOC
			PROD->PEDIDO  	:= QD2->D2_PEDIDO
			PROD->EMISSAO	:= STOD(QD2->D2_EMISSAO)
			PROD->PRODUTO 	:= QD2->D2_COD
			PROD->DESCRI  	:= QD2->B1_DESC
			PROD->QTE    	:= QD2->D2_QUANT
			PROD->PRCBRUT	:= QD2->D2_VALBRUT/QD2->D2_QUANT
			PROD->PRCVEN  	:= QD2->D2_PRCVEN
			If lUsaLits
				//		PROD->PRCTAMP	:= IIf( QD2->D2_VALPROM > 0 ,QD2->D2_VALPROM/QD2->D2_QUANT , 0 )
				//		PROD->VLRTAMP	:= IIf(  QD2->D2_VALPROM > 0 , (QD2->D2_VALPROM/QD2->D2_QUANT)/(Iif(QD2->B1_XLITROS <= 0,1,QD2->B1_XLITROS)) , 0 )
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
	If lCliInGrp
		Aadd(aCampos,{"CLIENTE" , "Cliente/Loja "})
	Endif
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

	cQri += "SELECT D2_TOTAL,D2_DOC,D2_PEDIDO,D2_EMISSAO,D2_COD,D2_QUANT,D2_PRCVEN,D2_VALBRUT,D2_CF,D2_TES,B1_DESC, F4_TEXTO "
	cQri += "  FROM "+RetSqlName("SD2") + " SD2, "+RetSqlName("SB1") + " SB1, "+ RetSqlName("SF4") + " SF4 "
	cQri += " WHERE SF4.D_E_L_E_T_ = ' ' "
	cQri += "   AND SF4.F4_CODIGO = SD2.D2_TES "
	cQri += "   AND SF4.F4_FILIAL = SD2.D2_FILIAL "
	cQri += "   AND SB1.D_E_L_E_T_ = ' ' "
	cQri += "   AND SB1.B1_COD = SD2.D2_COD "
	cQri += "   AND SB1.B1_FILIAL = CASE WHEN '"+xFilial("SB1")+"' = '"+xFilial("SD2")+"' THEN D2_FILIAL ELSE SUBSTRING(D2_FILIAL,1," + cValToChar(Len(cEmpAnt)) + ") END  "
	cQri += "   AND SD2.D_E_L_E_T_ = ' ' "
	If lCliInGrp
		cQri += "   AND SD2.D2_CLIENTE + '/' + SD2.D2_LOJA = '" + Substr(NOTA->CLIENTE,1,9) + "' "
	Else
		cQri += "   AND SD2.D2_LOJA = '" + cLj + "' "
		cQri += "   AND SD2.D2_CLIENTE = '" + cCliente + "'
	Endif
	cQri += "   AND SD2.D2_SERIE = '" + NOTA->SERIE + "' "
	cQri += "   AND SD2.D2_DOC = '" + NOTA->NOTA + "' "
	cQri += "   AND SD2.D2_FILIAL = '" +Substr(NOTA->FILIAL,1,Len(cFilAnt)) + "'  "
	
	cQri += " UNION ALL "

	cQri += "SELECT ZZ1_VALNF     AS D2_TOTAL,"
	cQri += "       SUBSTRING(ZZ1_CHNFE,27,9)       AS D2_DOC,"
	cQri += "       ' '           AS D2_PEDIDO,"
	cQri += "       ZZ1_EMISSA    AS D2_EMISSAO,"
	cQri += "       ZZ1_CODPRO    AS D2_COD,"
	cQri += "       ZZ1_QTDFAT    AS D2_QUANT,"
	cQri += "       ZZ1_PRCVEN    AS D2_PRCVEN,"
	cQri += "       ZZ1_VALNF + ZZ1_VALIPI + ZZ1_VICMST AS D2_VALBRUT, "
	cQri += "       ZZ1_CFOP      AS D2_CF,"
	cQri += "       '  '          AS D2_TES,"
	cQri += "       ZZ1_DESCPR    AS B1_DESC,"
	cQri += "       ' '           AS F4_TEXTO"
	cQri += "  FROM " + RetSqlName("ZZ1") + " ZZ1 " 
	cQri += " WHERE ZZ1.D_E_L_E_T_ =' ' "
	cQri += "   AND ZZ1_FILIAL IN "+FormatIN(GetNewPar("GF_FILIAIS",cFilAnt+""),"/") //= '"+xFilial("ZZ1")+"'"
	cQri += "   AND ZZ1_SERIE = '" + NOTA->SERIE + "' "
	cQri += "   AND SUBSTRING(ZZ1_CHNFE,27,9)  = '" + NOTA->NOTA + "' "
	cQri += "   AND ZZ1_FILIAL = '" +Substr(NOTA->FILIAL,1,Len(cFilAnt)) + "'  "
	
	cQri += " ORDER BY SD2.D2_EMISSAO DESC, SD2.D2_DOC DESC , SD2.D2_COD ASC "


	TCQUERY cQri NEW ALIAS "QD2"

	While !Eof()

		If !Empty(QD2->D2_DOC)
			dbSelectArea("PROD")
			RecLock("PROD",.T.)
			PROD->PRODUTO  	:= QD2->D2_COD
			PROD->DESCRI   	:= QD2->B1_DESC
			PROD->QTE      	:= QD2->D2_QUANT
			PROD->PRCVEN   	:= QD2->D2_PRCVEN
			PROD->TOTAL    	:= QD2->D2_TOTAL
			PROD->PRCBRUT  	:= QD2->D2_VALBRUT/QD2->D2_QUANT
			PROD->VZ     	:= ""
			PROD->VENBON 	:=  QD2->D2_TES+" - " + QD2->D2_CF + " - " + QD2->F4_TEXTO


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

/*/{Protheus.doc} sfCotacao
(long_description)
@author MarceloLauschner
@since 04/05/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
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



/*/{Protheus.doc} sfCotView
(long_description)
@author MarceloLauschner
@since 04/05/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
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



/*/{Protheus.doc} sfTitView
(long_description)
@author MarceloLauschner
@since 04/05/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfTitView()

	Local aCampos := {}
	Local aStru   := {}
	Local nAvencer  := 0.00
	Local nVencido  := 0.00

	sfAtuCodLj()

	aStru:={}
	Aadd(aStru,{ "PREFIXO" , "C", 03, 0 })
	Aadd(aStru,{ "NUM"     , "C", 09, 0 })
	Aadd(aStru,{ "PARCELA" , "C", 02, 0 })
	Aadd(aStru,{ "EMISSAO" , "D", 08, 0 })
	Aadd(aStru,{ "VCREAL"  , "D", 08, 0 })
	Aadd(aStru,{ "DIAS"    , "C", 03, 0 })
	Aadd(aStru,{ "VLR"     , "N", 10, 2 })
	Aadd(aStru,{ "VLRJUR"  , "N", 10, 2 })
	Aadd(aStru,{ "PORTADO" , "C", 30, 0 })
	Aadd(aStru,{ "VZ"     , "C", 01, 0 })


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
	@ aSize[6]/2-35,010 Say "Total Vencido"
	@ aSize[6]/2-35,055 Get nVencido size 60,13 picture "@E 999,999,999.99" when .f.
	@ aSize[6]/2-35,110 say "Total a Vencer"
	@ aSize[6]/2-35,150 Get nAvencer size 60,13 picture "@E 999,999,999.99" when .f.

	ACTIVATE DIALOG oDlg7 CENTERED

	TIT->(DBCloseArea())
	FErase(cArq + GetDbExtension()) // Deleting file
	FErase(cArq + OrdBagExt()) // Deleting index

Return



/*/{Protheus.doc} sfPendencia
(long_description)
@author MarceloLauschner
@since 04/05/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfPendencia()

	Local aCampos := {}
	Local aStru   := {}
	Local cSts    := ""
	Local naFaturar    := 0.00
	Local	aRecSM0		:= FWLoadSM0() // Usando função segura para retornar informação de empresas ativas
	Local	ix
	aSort(aRecSM0,,,{|x,y| x[SM0_CGC] < y[SM0_CGC] })
	
	
	
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
	cQri += "   AND SB1.B1_FILIAL = CASE WHEN '"+xFilial("SB1")+"' = '"+xFilial("SC6")+"' THEN C6_FILIAL ELSE SUBSTRING(C6_FILIAL,1," + cValToChar(Len(cEmpAnt)) + ") END   "
	cQri += "   AND C5.D_E_L_E_T_ = ' ' "
	cQri += "   AND C5.C5_TIPO = 'N' "
	cQri += "   AND C5.C5_NUM = C6_NUM "
	cQri += "   AND SC6.C6_FILIAL = C5_FILIAL "
	cQri += "   AND SC6.C6_BLQ <> 'R' "
	cQri += "   AND SC6.C6_QTDENT < SC6.C6_QTDVEN "
	cQri += "   AND SC6.C6_LOJA = '" + cLj + "' "
	cQri += "   AND SC6.C6_CLI = '" + cCliente + "' "
	cQri += "   AND SC6.C6_FILIAL IN "+FormatIN(GetNewPar("GF_FILIAIS",cFilAnt+""),"/")
	cQri += " ORDER BY C6_NUM ASC, C6_ITEM ASC "

	TCQUERY cQri NEW ALIAS "QC6"

	TcSetField("QC6","C5_EMISSAO","D")

	While !Eof()

		If !Empty(QC6->C6_NUM)
			cDescFilial	:= QC6->C6_FILIAL
			
			For ix := 1 To Len(aRecSM0)
				If aRecSM0[iX][SM0_CODFIL] == QC6->C6_FILIAL
					cDescFilial	:= aRecSM0[iX][SM0_CODFIL] + "-" + aRecSM0[iX][SM0_NOMRED]
				Endif
			Next
			
			dbSelectArea("PEND")
			RecLock("PEND",.T.)
			PEND->FILIAL	:= cDescFilial
			PEND->PEDIDO    := QC6->C6_NUM
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


/*/{Protheus.doc} sfResiduos
(long_description)
@author MarceloLauschner
@since 04/05/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/

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


User function MLFATC6A(cInCli,cInLoja)

	Local	aAreaOld	:= GetArea()
	Private lAltCli 	:= .F.
	Private cTpcon  	:= "Campanha"
	Private cCliente 	:= Space(TamSX3("A1_COD")[1])
	Private cLj 		:= Space(TamSX3("A1_LOJA")[1])
	Private cRazao 		:= ""

	Private	cVend1i 	:= "      "
	Private cVend1f 	:= "999999"
	Private lUsaLits	:= cEmpAnt == "02" 


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
	//@ 010,155 Button "&Cotações" size 60,13 Action ( Processa({|| sfCotacao()},"Consultando"))
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

User Function MLFATC6B()

	Local	aAreaOld	:= GetArea()
	Private cVend1i 	:= "      "
	Private cVend1f 	:= "999999"
	Private lAltCli 	:= .T.
	Private cTpcon  	:= "Campanha"
	Private lUsaLits	:= cEmpAnt == "02" 

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
	@ 50,018 Say "Selecione Campanha"
	@ 72,070 BUTTON "&Continua"  SIZE 40,15 ACTION (Processa({|| sfClientes() },"Localizando clientes"),oLeTxt:End() )
	@ 72,018 BUTTON "&Fechar"  SIZE 40,15 ACTION (oLeTxt:End() )

	Activate Dialog oLeTxt Centered

	RestArea(aAreaOld)

Return

Static Function Imprime()

	Local 	cDesc1 := "Este programa tem como objetivo imprimir relatorio "
	Local 	cDesc2 := "de acordo com os parametros informados pelo usuario."
	Local 	cDesc3 := "Ação Tmk "
	Local 	cPict  := ""
	Local 	titulo := "Ação Tmk "
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
	Private cbtxt        := Space(10)
	Private cbcont       := 00
	Private CONTFL       := 01
	Private m_pag        := 01
	Private wnrel        := "B38IMP"
	Private cCidOrd      := Space(40)
	Private cSemtmk      := Space(5)
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

	ValidPerg()

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

	cQrd := ""
	cQrd += "SELECT * FROM "
	cQrd += RetSqlName("SA1") + "  "
	cQrd += "WHERE A1_FILIAL = '" + xFilial("SA1") + "' "
	cQrd += "AND A1_VEND BETWEEN '" +mv_par01 + "' AND '" + mv_par02 + "' "
	cQrd += "ORDER BY A1_MUN ASC,A1_ULTCOM DESC,A1_COD ASC,A1_LOJA ASC "


	TCQUERY cQrd NEW ALIAS "QRD"

	Count to nReg

	ProcRegua(nReg)


	Dbselectarea("QRD")
	dbgotop()
	While !Eof()
		cCidOrd  := QRD->A1_MUN
		cSemTmk  := " "

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Impressao do cabecalho do relatorio. . .                            ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ


		If mv_par06 == 1
			IncProc(Substr(cCidOrd,1,12)+"-"+QRD->A1_COD+"/"+QRD->A1_LOJA+"-"+QRD->A1_NREDUZ)
		Else
			IncProc(cSemTmk+"-"+QRD->A1_COD+"/"+QRD->A1_LOJA+"-"+QRD->A1_NREDUZ)
		Endif


		cQri := ""
		cQri += "SELECT SUM(D2_TOTAL)AS FATU "
		cQri += "  FROM " + RetSqlName("SD2") + " SD2, " +RetSqlName("SF4") + " SF4 "
		cQri += "WHERE SD2.D_E_L_E_T_ = ' ' AND SF4.D_E_L_E_T_ = ' ' "
		cQri += "  AND SD2.D2_FILIAL = '" + xFilial("SD2") + "'  "
		cQri += "  AND SF4.F4_FILIAL = '" + xFilial("SF4") + "'  "
		cQri += "  AND SD2.D2_CLIENTE = '" + QRD->A1_COD + "' "
		cQri += "  AND SD2.D2_LOJA = '" + QRD->A1_LOJA + "' "
		cQri += "  AND SD2.D2_TES = SF4.F4_CODIGO "
		cQri += "  AND SUBSTRING(D2_EMISSAO,1,6) = '" + cMes4+ "' "

		TCQUERY cQri NEW ALIAS "QD2_1"

		cQri := ""
		cQri += "SELECT SUM(D2_TOTAL)AS FATU "
		cQri += "  FROM " + RetSqlName("SD2") + " SD2, " +RetSqlName("SF4") + " SF4 "
		cQri += "WHERE SD2.D_E_L_E_T_ = ' ' AND SF4.D_E_L_E_T_ = ' ' "
		cQri += "  AND SD2.D2_FILIAL = '" + xFilial("SD2") + "'  "
		cQri += "  AND SF4.F4_FILIAL = '" + xFilial("SF4") + "'  "
		cQri += "  AND SD2.D2_CLIENTE = '" + QRD->A1_COD + "' "
		cQri += "  AND SD2.D2_LOJA = '" + QRD->A1_LOJA + "' "
		cQri += "  AND SD2.D2_TES = SF4.F4_CODIGO "
		cQri += "  AND SUBSTRING(D2_EMISSAO,1,6) = '" + cMes3+ "' "

		TCQUERY cQri NEW ALIAS "QD2_2"
		
		cQri := ""
		cQri += "SELECT SUM(D2_TOTAL)AS FATU "
		cQri += "  FROM " + RetSqlName("SD2") + " SD2, " +RetSqlName("SF4") + " SF4 "
		cQri += "WHERE SD2.D_E_L_E_T_ = ' ' AND SF4.D_E_L_E_T_ = ' ' "
		cQri += "  AND SD2.D2_FILIAL = '" + xFilial("SD2") + "'  "
		cQri += "  AND SF4.F4_FILIAL = '" + xFilial("SF4") + "'  "
		cQri += "  AND SD2.D2_CLIENTE = '" + QRD->A1_COD + "' "
		cQri += "  AND SD2.D2_LOJA = '" + QRD->A1_LOJA + "' "
		cQri += "  AND SD2.D2_TES = SF4.F4_CODIGO "
		cQri += "  AND SUBSTRING(D2_EMISSAO,1,6) = '" + cMes2+ "' "

		TCQUERY cQri NEW ALIAS "QD2_3"

		cQri := ""
		cQri += "SELECT SUM(D2_TOTAL)AS FATU "
		cQri += "  FROM " + RetSqlName("SD2") + " SD2, " +RetSqlName("SF4") + " SF4 "
		cQri += "WHERE SD2.D_E_L_E_T_ = ' ' AND SF4.D_E_L_E_T_ = ' ' "
		cQri += "  AND SD2.D2_FILIAL = '" + xFilial("SD2") + "'  "
		cQri += "  AND SF4.F4_FILIAL = '" + xFilial("SF4") + "'  "
		cQri += "  AND SD2.D2_CLIENTE = '" + QRD->A1_COD + "' "
		cQri += "  AND SD2.D2_LOJA = '" + QRD->A1_LOJA + "' "
		cQri += "  AND SD2.D2_TES = SF4.F4_CODIGO "
		cQri += "  AND SUBSTRING(D2_EMISSAO,1,6) = '" + cMes1 + "' "

		TCQUERY cQri NEW ALIAS "QD2_4"

		
		cQri := ""
		cQri += "SELECT SUM(D2_TOTAL)AS FATU "
		cQri += "  FROM " + RetSqlName("SD2") + " SD2, " +RetSqlName("SF4") + " SF4 "
		cQri += "WHERE SD2.D_E_L_E_T_ = ' ' AND SF4.D_E_L_E_T_ = ' ' "
		cQri += "  AND SD2.D2_FILIAL = '" + xFilial("SD2") + "'  "
		cQri += "  AND SF4.F4_FILIAL = '" + xFilial("SF4") + "'  "
		cQri += "  AND SD2.D2_CLIENTE = '" + QRD->A1_COD + "' "
		cQri += "  AND SD2.D2_LOJA = '" + QRD->A1_LOJA + "' "
		cQri += "  AND SD2.D2_TES = SF4.F4_CODIGO "
		cQri += "  AND SUBSTRING(D2_EMISSAO,1,6) = '" + cMes+ "' "

		TCQUERY cQri NEW ALIAS "QD2_5"

		Dbselectarea("QD2_5")
		dbgotop()
		For s := 1 To Len(aSemanas)
			For j := 1 To Len("1") Step 1
				If Substr("1",j,1) == aSemanas[s][1]
					Aadd(aClientes,{QRD->A1_COD,QRD->A1_LOJA,QRD->A1_NOME,QRD->A1_NREDUZ,QRD->A1_CONTATO,QRD->A1_DDD,QRD->A1_TEL,;
					QRD->A1_VEND,' ',STOD(QRD->A1_ULTCOM),QRD->A1_END,QRD->A1_BAIRRO,QRD->A1_MUN,aSemanas[s][1],QRD->A1_SATIV1,;
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

Static Function ValidPerg

	Local aRegs := {}
	Local i,j

	dbSelectArea("SX1")
	dbSetOrder(1)

	cPerg1 :=  PADR(cPerg1,Len(SX1->X1_GRUPO))
	AADD(aRegs,{cPerg1,"01","Do Vendedor","","","mv_ch1","C",06,0,0,"G","","mv_par01","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
	AADD(aRegs,{cPerg1,"02","Até Vendedor","","","mv_ch2","C",06,0,0,"G","","mv_par02","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
	For i:=1 to Len(aRegs)
		If !dbSeek(cPerg1+aRegs[i,2])
			RecLock("SX1",.T.)
			For j:=1 to FCount()
				If j <= Len(aRegs[i])
					FieldPut(j,aRegs[i,j])
				Endif
			Next
			MsUnlock()
		Endif
	Next

Return






