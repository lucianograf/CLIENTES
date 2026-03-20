#include "totvs.ch"
#include "topconn.ch"

Function U_BFCOMM03()


	Local   	aCabec      := {}
	Local   	aLinha      := {}
	Local 		aItems		:= {}
	Local 		cMV_NUMITEN := GetMv("MV_NUMITEN")

	Local   	cQry        := ""
	Local 		cSerieNf	:= "P3 "
	Local 		aB1MsBlql	:= {}
	Local 		aA1MsBlql 	:= {}
	Local 		cCliAtu		:= ""
	Local 		iX 
	Private		lMsErroAuto	:= .F.
	Private		lMsHelpAuto := .F.

	cQry := "SELECT B6_CLIFOR,B6_LOJA,B6_PRODUTO,B6_QUANT,B6_TES,B6_DOC,B6_TPCF,B6_SALDO,B6_PRUNIT,B6_LOCAL,"
	cQry += "       D2_EMISSAO,D2_IDENTB6,D2_CF,D2_FILIAL,D2_DOC,D2_SERIE,D2_CLIENTE,D2_LOJA,D2_COD,D2_ITEM "
	cQry += "  FROM "+RetSqlName("SB6")+ " B6," + RetSqlName("SD2")+ " D2 "
	cQry += " WHERE D2.D_E_L_E_T_ = ' ' "
	cQry += "   AND B6.D_E_L_E_T_ = ' ' "
	cQry += "   AND D2_IDENTB6 = B6_IDENT "
	cQry += "   AND D2_FILIAL = '"+xFilial("SD2")+"' "
	cQry += "   AND D2_DOC = B6_DOC "
	cQry += "   AND D2_COD = B6_PRODUTO "
	cQry += "   AND D2_QUANT = B6_QUANT "
	cQry += "   AND D2_SERIE = B6_SERIE "
	cQry += "   AND B6_FILIAL = '"+xFilial("SB6") + "' "
	cQry += "   AND B6_PODER3 = 'R' "
	cQry += "   AND B6_SALDO > 0 "
	cQry += "   AND B6_TES > '500' "
	cQry += "   AND B6_TPCF = 'C' "
	cQry += "   AND B6_EMISSAO <='20210331' "
	//cQry += "   AND B6_PRODUTO BETWEEN 'AI0' AND 'AI999' "
	//cQry += "   AND B6_PRODUTO IN( 'AI1590','AI1591','02153.000158','23722.000159','43170.000159') "
	//cQry += "   AND B6_PRODUTO NOT IN('E15007','E15008','E15009','E15010')"
	//cQry += "   AND B6_TPCF = 'F' "
	//cQry += "   AND B6_CLIFOR NOT IN('001000')
	//cQry += "   AND B6_CLIFOR NOT IN('004663') " // MG - Maxima Logistia mantém
	//cQry += "   AND D2_CF IN('5915','6915')
	cQry += " ORDER BY B6_CLIFOR,B6_LOJA,B6_DOC,D2_ITEM"
	TcQuery cQry New Alias "QSB6"

	While !Eof()

		If cCliAtu <> QSB6->(B6_CLIFOR+B6_LOJA) .Or. Len(aItems) == cMV_NUMITEN

			If Len(aCabec) > 0 .And. Len(aItems)
				lMsErroAuto	:= .F.
				lMsHelpAuto := .F.


				Mata103(aClone(aCabec), aClone(aItems) , 3 , .F.)

				If lMsErroAuto
					MostraErro()
				Endif
				aCabec	:= {}
				aItems	:= {}
			Endif

			If QSB6->B6_TPCF  == "C"
				DbSelectArea("SA1")
				DbSetOrder(1)
				DbSeek(xFilial("SA1")+QSB6->(B6_CLIFOR+B6_LOJA))

				If !RegistroOK("SA1",.F.)
					Aadd(aA1MsBlql,SA1->(Recno()))
					RecLock("SA1",.F.)
					SA1->A1_MSBLQL 	:= "2"
					MsUnlock()
				Endif

				Aadd(aCabec,{"F1_TIPO"   	,"B"										,Nil,Nil})
				Aadd(aCabec,{"F1_FORMUL" 	,"S"										,Nil,Nil})
				// Aadd(aCabec,{"F1_DOC"    	,sfNextDoc(cSerieNf) 						,Nil,Nil}) //Comentado, pois no padrão já busca o próximo número de nota automático em caso de formulário próprio
				Aadd(aCabec,{"F1_SERIE"     ,cSerieNf						 			,Nil,Nil})
				Aadd(aCabec,{"F1_EMISSAO"	,dDataBase									,Nil,Nil})
				Aadd(aCabec,{"F1_FORNECE"	,SA1->A1_COD								,Nil,Nil})
				Aadd(aCabec,{"F1_LOJA"   	,SA1->A1_LOJA								,Nil,Nil})
				Aadd(aCabec,{"F1_ESPECIE"	,Padr("NF",TamSX3("F1_ESPECIE")[1])	        ,Nil,Nil})
				Aadd(aCabec,{"F1_EST"		,SA1->A1_EST								,Nil,Nil})
				Aadd(aCabec,{"F1_COND"		,"128"			    						,Nil,Nil})
			Else
				DbSelectArea("SA2")
				DbSetOrder(1)
				DbSeek(xFilial("SA2")+QSB6->(B6_CLIFOR+B6_LOJA))

				Aadd(aCabec,{"F1_TIPO"   	,"N"										,Nil,Nil})
				Aadd(aCabec,{"F1_FORMUL" 	,"S"										,Nil,Nil})
				Aadd(aCabec,{"F1_DOC"    	,sfNextDoc(cSerieNf)						,Nil,Nil})
				Aadd(aCabec,{"F1_SERIE"     ,cSerieNf						 			,Nil,Nil})
				Aadd(aCabec,{"F1_EMISSAO"	,dDataBase									,Nil,Nil})
				Aadd(aCabec,{"F1_FORNECE"	,SA2->A2_COD								,Nil,Nil})
				Aadd(aCabec,{"F1_LOJA"   	,SA2->A2_LOJA								,Nil,Nil})
				Aadd(aCabec,{"F1_ESPECIE"	,Padr("NF",TamSX3("F1_ESPECIE")[1])	        ,Nil,Nil})
				Aadd(aCabec,{"F1_EST"		,SA2->A2_EST								,Nil,Nil})
				Aadd(aCabec,{"F1_COND"		,"128"			    						,Nil,Nil})
			Endif
			cCliAtu := QSB6->(B6_CLIFOR+B6_LOJA)
		Endif

		DbSelectArea("SD2")
		DbSetOrder(3) // D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
		DbSeek( QSB6->(D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM))

		DbSelectArea("SB1")
		DbSetOrder(1)
		DbSeek(xFilial("SB1")+QSB6->D2_COD)

		If !RegistroOK("SB1",.F.)
			Aadd(aB1MsBlql,SB1->(Recno()))
			RecLock("SB1",.F.)
			SB1->B1_MSBLQL 	:= "2"
			MsUnlock()
		Endif

		DbSelectArea("SF4")
		DbSetOrder(1)
		DbSeek(xFilial("SF4")+Iif(cFilAnt$"01#08","320","316"	))

		aLinha	:= {}

		Aadd(aLinha,{"D1_COD"		, QSB6->D2_COD										,Nil,Nil})
		Aadd(aLinha,{"D1_QUANT"		, QSB6->B6_SALDO									,Nil,Nil})
		Aadd(aLinha,{"D1_VUNIT"		, QSB6->B6_PRUNIT									,Nil,Nil})

		Aadd(aLinha,{"D1_TOTAL"		, QSB6->B6_PRUNIT * QSB6->B6_SALDO					,Nil,Nil})
		Aadd(aLinha,{"D1_LOCAL"		, QSB6->B6_LOCAL 									,Nil,Nil})
		Aadd(aLinha,{"D1_TES"		, Iif(cFilAnt$"01#08","320","316"	)				,Nil,Nil})
		Aadd(aLinha,{"D1_CF"		, Iif( QSB6->D2_CF == "5920 ","1921 ","1907 ")		,Nil,Nil})
		Aadd(aLinha,{"D1_NFORI"		, QSB6->D2_DOC 										,Nil,Nil})
		Aadd(aLinha,{"D1_SERIORI"	, QSB6->D2_SERIE									,Nil,Nil})
		Aadd(aLinha,{"D1_ITEMORI"	, QSB6->D2_ITEM										,Nil,Nil})
		AAdd(aLinha,{"D1_IDENTB6"	, QSB6->D2_IDENTB6									,Nil,Nil} )

		Aadd(aItems,aLinha)

		DbSelectArea("QSB6")
		DbSkip()
	Enddo
	QSB6->(DbCloseArea())


	If Len(aCabec) > 0 .And. Len(aItems)
		lMsErroAuto	:= .F.
		lMsHelpAuto := .F.


		Mata103(aClone(aCabec), aClone(aItems) , 3 , .F.)

		If lMsErroAuto
			MostraErro()
		Endif
		aCabec	:= {}
		aItems	:= {}
	Endif

	For iX := 1 To Len(aB1MsBlql)
		DbSelectArea("SB1")
		DbGoto(aB1MsBlql[iX])
		RecLock("SB1",.F.)
		SB1->B1_MSBLQL 	:= "1"
		MsUnlock()
	Next

	For iX := 1 To Len(aA1MsBlql)
		DbSelectArea("SA1")
		DbGoto(aA1MsBlql[iX])
		RecLock("SA1",.F.)
		SA1->A1_MSBLQL 	:= "1"
		MsUnlock()
	Next
Return


Static Function sfNextDoc(cInSerie)

	Local 	aAreaOld	:= GetArea()
	Local 	cNumSx5		:= "000001"
	Local 	cFilSX5 	:= FWxFilial("SX5")
	Local 	nX

	// DbSelectArea("SX5")
	// DbSetOrder(1)

	// SX5->(DbSeek( cFilSx5+"01" ))

	// While ! SX5->(Eof()) .And. SX5->X5_Tabela == "01"
	// 	If AllTrim(SX5->(X5_Chave)) == AllTrim(cInSerie)

	// 		cNumSx5 := Alltrim(SX5->(X5Descri())) 
			
	// 		RecLock("SX5",.F.)
	// 		SX5->X5_DESCRI	:= Soma1(cNumSx5)
	// 		MsUnlock()
	// 		Exit
	// 	EndIf
	// 	SX5->(DbSkip())
	// Enddo 

	// RestArea(aAreaOld)

	aRetSX5 := FWGetSX5("01",cInSerie)
	For nX := 1 to Len(aRetSX5)
		If aRetSX5[1] == cFilSX5
			cNumSx5 := Padr(Alltrim(aRetSX5[4]),TamSX3("F1_DOC")[1]) 
		EndIf
	Next nX

	// cNumSx5 := Padr(cNumSx5,TamSX3("F1_DOC")[1]) 

Return cNumSx5	
