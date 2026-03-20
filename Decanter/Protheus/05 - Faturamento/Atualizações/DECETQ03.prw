#Include 'Protheus.ch'
/*/{Protheus.doc} DecEtq03
Rotina de impressão de etiquetas de Produto - 
@type function
@version  
@author Marcelo Alberto Lauschner
@since 05/05/2021
@return return_type, return_description
/*/
User Function DecEtq03()

	Local    cPerg    := "ETIQC003"

	If Pergunte(cPerg,.T.)
		MsAguarde({||sfPrint()},"Aguarde","Imprimindo Etiquetas.....")
	EndIf

Return

/*/{Protheus.doc} sfPrint
Impressão das etiquetas 
@type function
@version  
@author Marcelo Alberto Lauschner
@since 28/04/2021
@return return_type, return_description
/*/
Static Function sfPrint()

	Local nVol  	:= 0
	Local nX
	Local cPrintTxt
	Local cPrintMsg	:= ""
	Local cCodBar   := ""
	Local nLinAux 	:= 0
	Local nColAux 	:= 59

	nVol := mv_par02
	nVol += 1
	nVol := Int(nVol/2)

	If nVol =  0
		MSGALERT( "Não foi informa o número de etiquetas a serem impressas!", "Mensagem" )
	Else
		DbSelectArea("SB1")
		DbSetOrder(1)
		If DbSeek(xFilial("SB1")+MV_PAR01)
			cCodBar	:= SB1->B1_COD

			For nX := 1 To nVol

				MSCBPRINTER("ZEBRA","LPT"+cValToChar(MV_PAR04),,,.f.,,,,,,.f.,)

				MSCBCHKSTATUS(.F.)
				MSCBBEGIN(1,6)


				//MSCBSAY(080,15,"www.decanter.com.br", "R","0","050,050")

				//MSCBSAY(065,105,DToC(Date())+" - "+Time(), "R","0","050,050")


				cPrintTxt	:= Substr(SB1->B1_DESC,1,40)
				cPrintMsg 	+= Chr(13)+Chr(10)+cPrintTxt

				nLinAux	:= 02
				MSCBSAY(06,nLinAux,cPrintTxt,"N","B","002,001") //Imprime Texto

				// Imprime Segunda Etiqueta 
				MSCBSAY(nColAux,nLinAux,cPrintTxt,"N","B","002,001") //Imprime Texto



				If !Empty(Substr(SB1->B1_DESC,41,40))
					cPrintTxt	:= Substr(SB1->B1_DESC,41,40)
					cPrintMsg 	+= Chr(13)+Chr(10)+cPrintTxt
					nLinAux	+= 02
					MSCBSAY(06,nLinAux,cPrintTxt,"N","B","002,001") //Imprime Texto

					// Imprime Segunda Etiqueta 
					MSCBSAY(nColAux,nLinAux,cPrintTxt,"N","B","002,001") //Imprime Texto
				Endif

				If !Empty(MV_PAR03)
					cPrintTxt	:= Alltrim(Substr(MV_PAR03,1,40))
					cPrintMsg 	+= Chr(13)+Chr(10)+cPrintTxt
					nLinAux	+= 02
					MSCBSAY(06,nLinAux,cPrintTxt,"N","B","002,001") //Imprime Texto

					// Imprime Segunda Etiqueta 
					MSCBSAY(nColAux,nLinAux,cPrintTxt,"N","B","002,001") //Imprime Texto

					cPrintTxt	:= Alltrim(Substr(MV_PAR03,41,40))

					If !Empty(cPrintTxt)
						cPrintMsg 	+= Chr(13)+Chr(10)+cPrintTxt
						nLinAux	+= 02
						MSCBSAY(06,nLinAux,cPrintTxt,"N","B","002,001") //Imprime Texto

						// Imprime Segunda Etiqueta 
						MSCBSAY(nColAux,nLinAux,cPrintTxt,"N","B","002,001") //Imprime Texto
					Endif
				Endif

				//MSCBSAYBAR(30,03,Alltrim(StrTran(AllTrim(Transform("33442Z","@R 99.99.9.X")),"-","")),"N","MB07",12,.F.,.T.,.F.,,2,2,.F.)
				//MSCBSAYBAR(06,10,AllTrim(cCodBar),,"N","MB04"/*MB04 - EAN 13 */,14,.T./*lDigver*/,.T./*lLinha*/,.F.,,3,2,.F.)
				nLinAux	+= 02
				MSCBSAYBAR(06,nLinAux,Alltrim(StrTran(AllTrim(cCodBar),"-","")),"N","MB07",7,.F.,.T.,.F.,,2,2,.F.)
				
				// Imprime Segunda Etiqueta 
				MSCBSAYBAR(nColAux,nLinAux,Alltrim(StrTran(AllTrim(cCodBar),"-","")),"N","MB07",7,.F.,.T.,.F.,,2,2,.F.)

				//cPrintTxt := {{"01",AllTrim(SB1->B1_XDUN14)},{"3102",StrZero(nPesoCx * 100 ,6) },{"12",Substr(DTOS(dDtVldLote),3,6)}}
				// cSubSetIni - usar o comando C- Compactar o código de barras
				//MSCBSAYBAR(15/*nXmm*/,35.5/*nYmm*/,cPrintTxt/*cConteudo*/,"N"/*cRotação*/,"E"/*cTypePrt*/,10/*nAltura*/,.F./*lDigver*/,.F./*lLinha*/,.F./*lLinBaixo*/,"C"/*cSubSetIni*/,0/*nLargura*/,0/*nRelacao*/,.T.)

			/*MSCBSAY(	nXmm 		Posição X em Milímetros
			nYmm 		Posição Y em Milímetros
			cTexto 		String a ser impresso 
			cRotação 	String com o tipo de Rotação (N,R,I,B): N - Normal R - Cima para baixo I - Invertido B - Baixo para cima
			cFonte 		String com os tipos de Fonte: Datamax - (0,1,2,3,4,5,6,7,8,9) 9 – fonte escalar
			cTam 		String com o tamanho da Fonte
			lReverso	Imprime em reverso quando tiver sobre um box preto
			*/ 

				MSCBEND()
				MSCBCLOSEPRINTER()

			Next
		Endif

	EndIf

	//(cAliasSF2)->(DbSkip())

	//End

Return
