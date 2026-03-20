#include "PROTHEUS.CH"
#include  "topconn.ch"

/*/{Protheus.doc} MT100AGR
(Ponto de entrada apos lançar a nota fiscal  )
@author Marcelo Lauschner
@since 29/12/2010
@version 1.0		
@return Sem retorno
@example
(examples)
@see (http://tdn.totvs.com/display/public/mp/MT100AGR+-+Funcionalidades+em+notas+fiscais+de+entrada)
/*/
User Function MT100AGR()

	Local	aAreaOld				:= GetArea()
	Local	cQry 
	Local	nForG,nIX
	

	// Se for Formulário Proprio e fornecedor Exterior (Importação)
	If INCLUI .And. SF1->F1_FORMUL == "S" .And. SF1->F1_EST == "EX" .And. IsInCallStack("U_MLCOMM01")
		// Verifico se existem as variaveis que são declaradas pela Rotina XMLDCONDOR

		cQry := "SELECT D1_DOC,D1_SERIE,D1_FORNECE,D1_LOJA,D1_ITEM,D1_BASIMP6,D1_ALQIMP6,D1_VALIMP6,"
		cQry += "       D1_BASIMP5,D1_ALQIMP5,D1_VALIMP5 "
		cQry += "  FROM "+RetSqlName("SD1") + " D1 "
		cQry += " WHERE D_E_L_E_T_ = ' ' "
		cQry += "   AND D1_LOJA = '"+SF1->F1_LOJA+"' "
		cQry += "   AND D1_FORNECE = '"+SF1->F1_FORNECE+"' "
		cQry += "   AND D1_SERIE = '"+SF1->F1_SERIE+"' "
		cQry += "   AND D1_DOC = '"+SF1->F1_DOC+"' "
		cQry += "   AND D1_FILIAL = '"+xFilial("SD1")+"' "
		cQry += " ORDER BY D1_ITEM "

		TCQUERY cQry NEW ALIAS "QSD1"

		While !Eof()

			DbSelectArea("CD5")
			DbSetOrder(4) //CD5_FILIAL, CD5_DOC, CD5_SERIE, CD5_FORNEC, CD5_LOJA, CD5_ITEM
			If DbSeek(xFilial("CD5")+QSD1->D1_DOC+QSD1->D1_SERIE+QSD1->D1_FORNECE+QSD1->D1_LOJA+QSD1->D1_ITEM)
				RecLock("CD5",.F.)
			Else
				RecLock("CD5",.T.)
			Endif
			nIX := 0
			For nForG := 1 To Len(oMulti:aCols)

				If !oMulti:aCols[nForG,Len(oMulti:aHeader)+1] .And. !Empty(oMulti:aCols[nForG,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "D1_COD" })])
					
					If oMulti:aCols[nForG,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "D1_ITEM" })] == QSD1->D1_ITEM
						nIX := nForG
					Endif
				Endif
			Next
			CD5->CD5_FILIAL   := xFilial("CD5")
			CD5->CD5_DOC      := QSD1->D1_DOC
			CD5->CD5_SERIE    := QSD1->D1_SERIE
			CD5->CD5_ESPEC    := SF1->F1_ESPECIE
			CD5->CD5_FORNEC   := QSD1->D1_FORNECE
			CD5->CD5_LOJA     := QSD1->D1_LOJA
			CD5->CD5_ITEM     := QSD1->D1_ITEM
			CD5->CD5_TPIMP    := oMulti:aCols[nIX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "CD5_TPIMP" })]
			CD5->CD5_DOCIMP	  := oMulti:aCols[nIX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "CD5_DOCIMP" })]
			CD5->CD5_BSPIS    := oMulti:aCols[nIX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "CD5_BSPIS" })]
			CD5->CD5_ALPIS    := oMulti:aCols[nIX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "CD5_ALPIS" })]
			CD5->CD5_VLPIS    := oMulti:aCols[nIX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "CD5_VLPIS" })]
			CD5->CD5_BSCOF    := oMulti:aCols[nIX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "CD5_BSCOF" })]
			CD5->CD5_ALCOF    := oMulti:aCols[nIX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "CD5_ALCOF" })]
			CD5->CD5_VLCOF    := oMulti:aCols[nIX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "CD5_VLCOF" })]
			CD5->CD5_LOCAL    := oMulti:aCols[nIX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "CD5_LOCAL" })]
			CD5->CD5_DTPCOF   := oMulti:aCols[nIX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "CD5_DTPCOF" })]
			CD5->CD5_DTPPIS   := oMulti:aCols[nIX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "CD5_DTPPIS" })]
			CD5->CD5_NDI      := oMulti:aCols[nIX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "CD5_NDI" })]
			CD5->CD5_DTDI     := oMulti:aCols[nIX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "CD5_DTDI" })]
			CD5->CD5_LOCDES   := oMulti:aCols[nIX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "CD5_LOCDES" })]
			CD5->CD5_UFDES    := oMulti:aCols[nIX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "CD5_UFDES" })]
			CD5->CD5_DTDES    := oMulti:aCols[nIX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "CD5_DTDES" })]
			CD5->CD5_CODEXP   := oMulti:aCols[nIX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "CD5_CODEXP" })]
			CD5->CD5_LOJEXP   := oMulti:aCols[nIX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "CD5_LOJEXP" })]
			CD5->CD5_CODFAB   := oMulti:aCols[nIX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "CD5_CODFAB" })]
			CD5->CD5_LOJFAB	  := oMulti:aCols[nIX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "CD5_LOJFAB" })]
			
			CD5->CD5_NADIC    := oMulti:aCols[nIX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "CD5_NADIC" })]
			CD5->CD5_SQADIC   := oMulti:aCols[nIX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "CD5_SQADIC" })]
			CD5->CD5_BCIMP    := oMulti:aCols[nIX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "CD5_BCIMP" })]
			CD5->CD5_DSPAD    := oMulti:aCols[nIX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "CD5_DSPAD" })]
			CD5->CD5_VDESDI	  := oMulti:aCols[nIX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "CD5_VDESDI" })]
			CD5->CD5_VLRII    := oMulti:aCols[nIX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "CD5_VLRII" })]
			CD5->CD5_VLRIOF   := oMulti:aCols[nIX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "CD5_VLRIOF" })]
			CD5->CD5_VTRANS	  := oMulti:aCols[nIX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "CD5_VTRANS" })]
			CD5->CD5_VAFRMM	  := oMulti:aCols[nIX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "CD5_VAFRMM" })]
			CD5->CD5_INTERM   := oMulti:aCols[nIX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "CD5_INTERM" })]
			CD5->CD5_CNPJAE	  := oMulti:aCols[nIX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "CD5_CNPJAE" })]
			CD5->CD5_UFTERC   := oMulti:aCols[nIX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "CD5_UFTERC" })]
			CD5->CD5_SDOC	  := SF1->F1_SERIE
			MsUnlock()

			DbSelectArea("QSD1")
			DbSkip()
		Enddo
		QSD1->(DbCloseArea())
	Endif
	


	RestArea(aAreaOld)

Return


