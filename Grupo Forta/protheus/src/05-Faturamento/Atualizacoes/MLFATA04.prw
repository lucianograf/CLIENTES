#INCLUDE "rwmake.ch"
#INCLUDE "topconn.ch"
#define CRLF Chr(13)+Chr(10)

/*/{Protheus.doc} MLFATA04
// Rotina de impressão de etiquetas da conferência da Nota Fiscal
@author Marcelo Alberto Lauschner
@since 30/09/2019
@version 1.0
@return ${return}, ${return_description}
@param aEtiqueta, array, descricao
@param nDiversos, numeric, descricao
@param cPedido, characters, descricao
@param cNota, characters, descricao
@param cSerie, characters, descricao
@param cCliente, characters, descricao
@param cLoja, characters, descricao
@param cTipo, characters, descricao
@type function
/*/
User function MLFATA04(aEtiqueta,nDiversos,cPedido,cNota,cSerie,cCliente,cLoja,cTipo)

	Local nConta     	:= 0
	Local nTotal     	:= 0
	Local nVolumes   	:= 0
	Local cTransp    	:= Space(6)
	Local cNomfil    	:= Space(3)
	Local cCodfil    	:= Space(3)
	Local cMotivo	 	:= Space(100)
	Local x
	Local y
	Local lPrintEtq		:= GetNewPar("GF_MLFTA04",.T.) // Identifica se a filial deve imprimir etiqueta fisica
	Local cTxtPrint		:= ""

	cSenhaDi 	:= Padr(GetNewPar("GF_PSWD010",StrZero(Day(dDataBase),2)+StrZero(Val(Substr(Time(),1,2))*2,2)),10)
	cSenhaAtu   := Space(10)

	cQry := "SELECT * "
	cQry += "  FROM "+RetSqlName("SZ0")
	cQry += " WHERE Z0_PEDIDO = '"+cPedido+"' "
	cQry += "   AND Z0_TIPO = 'CP' "
	cQry += "   AND Z0_DATA >= '" + DTOS(Date())+ "' "
	cQry += "   AND Z0_FILIAL = '"+xFilial("SZ0")+"' "

	TCQUERY cQry NEW ALIAS "QZ0"

	lContinua := .T.

	If !Eof()
		lContinua := .F.

		@ 001,001 TO 100,400 DIALOG oDlg6 TITLE "Senha"
		@ 005,005 Say "Digite a senha do dia" Color 255
		@ 005,065 Get cSenhaAtu Valid (lContinua := Alltrim(cSenhadi) == Alltrim(cSenhaAtu)) PASSWORD
		@ 015,005 Say "Digite um motivo"
		@ 015,065 Get cMotivo Valid (lContinua :=  Len(Alltrim(cMotivo)) > 20 )
		@ 030,010 BUTTON "Avancar-->" SIZE 40,10 Action(IIf(lContinua,Close(oDlg6),MsgAlert("Senha incorreta ou sem Motivo digitado!!","Atenção!")))

		ACTIVATE MSDIALOG oDlg6 CENTERED Valid (lContinua :=  Len(Alltrim(cMotivo)) > 20 )

	Endif

	QZ0->(DbCloseArea())

	If !lContinua
		Return
	Endif

	DbSelectArea("SF2")
	DbSetOrder(1)
	DbSeek(xFilial("SF2")+Padr(cNota,TamSX3("F2_DOC")[1])+cSerie)


	DbSelectArea("SA4")
	DbSetOrder(1)
	DbSeek(xFilial("SA4") + SF2->F2_TRANSP)
	cTransp	:= "Transp:"+ Alltrim(SF2->F2_TRANSP) + "-" + Alltrim(SA4->A4_NREDUZ)

	If !cTipo $"DB"

		DbSelectArea("SA1")
		DbSetOrder(1)
		DbSeek(xFilial("SA1")+cCliente+cLoja)

		cNomfil := "SEM"
		cCodFil := "ID"

	Else
		DbSelectArea("SA2")
		DbSetOrder(1)
		DbSeek(xFilial("SA2")+cCliente+cLoja)

		cNomfil := "SEM"
		cCodFil := "ID"

	Endif
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Verifica total de etiquetas                                         ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	nTotal += nDiversos

	For x := 1 To Len(aEtiqueta)
		nLenEtq := Iif(aEtiqueta[x][8] == "M",Iif(aEtiqueta[x][9]==0,1,aEtiqueta[x][9]),1)
		nLenEtq	:= nLenEtq *  aEtiqueta[x][4] 
		nTotal	+= nLenEtq 
		//nTotal += aEtiqueta[x][4]
	Next


	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Impressao das etiquetas                                             ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	For x := 1 To Len(aEtiqueta)
		// Calcula quantas etiquetas agregadas do mesmo produto precisa ser gerada 
		nLenEtq := Iif(aEtiqueta[x][8] == "M",Iif(aEtiqueta[x][9]==0,1,aEtiqueta[x][9]),1)
		nLenEtq	:= nLenEtq *  aEtiqueta[x][4] 

		For y := 1 To nLenEtq //aEtiqueta[x][4]
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Inicio de impressao                                                 ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

			If lPrintEtq
				_cPorta := Alltrim(GetNewPar("GF_PORTLPT","LPT1:9600,n,8,1"))

				MSCBPRINTER("ALLEGRO",_cPorta,Nil,) //Seta tipo de impressora
				MSCBCHKSTATUS(.F.)
				MSCBBEGIN(1,4) //Inicio da Imagem da Etiqueta

				nVolumes++

				MSCBSAY(03,32,Substr(SM0->M0_NOMECOM ,1,37)		,"N"	,"9"	,"002,003") //Imprime Texto
				MSCBSAY(03,27,cTransp							,"N"	,"9"	,"002,003") //Imprime Texto

				If !cTipo $ "DB"
					DbSelectArea("SA1")
					DbSetOrder(1)
					If DbSeek(xFilial("SA1")+cCliente+cLoja)
						MSCBSAY(03,21,	Substr(SA1->A1_NOME,1,40)	,"N"	,"9"	,"002,003") //Imprime Texto
						MSCBSAY(03,16, SA1->A1_EST + "/" + SA1->A1_MUN	,"N","9"	,"002,003") //Imprime Texto
					Endif
				Else
					DbSelectArea("SA2")
					DbSetOrder(1)
					If DbSeek(xFilial("SA2")+cCliente+cLoja)
						MSCBSAY(03,21,SA2->A2_NOME,"N","9","002,003") //Imprime Texto
						MSCBSAY(03,16,SA2->A2_MUN,"N","9","002,003") //Imprime Texto
					Endif
				Endif
				MSCBSAY(03,10,"Pedido:"			,"N"	,"9"	,"002,002") //Imprime Texto
				MSCBSAY(18,09,aEtiqueta[x][5]	,"N"	,"9"	,"002,003")
				MSCBSAY(40,10,"N.NF: "	 		,"N"	,"9"	,"002,002")
				MSCBSAY(55,09,aEtiqueta[x][6]	,"N"	,"9"	,"004,005") //Imprime pedido e nota fiscal

				DbSelectArea("SB1")
				DbSetOrder(1)
				If dbSeek(xFilial("SB1")+aEtiqueta[x][3])
					If aEtiqueta[x][8] == "N" // Só imprimirá se for Miudeza == Não
						MSCBSAY(03,05, AllTrim(Transform(y,"@E 9999")) + "/" + AllTrim(Transform(aEtiqueta[x][4],"@E 9999")) + " - " + AllTrim(aEtiqueta[x][3]) ,"N","9","002,002") //Imprime Texto
						MSCBSAY(03,0.5, Substr(SB1->B1_DESC,1,30),"N","9","002,002") //Imprime Texto
						//MSCBSAY(01,01,AllTrim(Transform(y,"@E 9999")) + "/" + AllTrim(Transform(aEtiqueta[x][4],"@E 9999")) ,"N","9","002,001") //Imprime Texto
					ElseIf aEtiqueta[x][8] == "M" // Só imprimirá se for Miudeza == Múltiplos do mesmo produto 
						MSCBSAY(03,05, AllTrim(Transform(y,"@E 9999")) + "/" + AllTrim(Transform(nLenEtq,"@E 9999")) + " - " + AllTrim(aEtiqueta[x][3]) ,"N","9","002,002") //Imprime Texto
						MSCBSAY(03,0.5, Substr(SB1->B1_DESC,1,30),"N","9","002,002") //Imprime Texto
					Else 
						MSCBSAY(03,05,"VOLUME FECHADO-CHECKOUT","N"	,"9"	,"002,002") //Imprime Texto
					Endif
				Endif

				nConta++
				MSCBSAY(75,05,"Vol:" + AllTrim(Str(nConta))+"/"+AllTrim(Str(nTotal)),"N"	,"9"	,"002,002") //Imprime Texto

				cResult := MSCBEND()
				MemoWrit('DIS010',cResult)
				Sleep(700)
			Else
				nVolumes++
				nConta++
				cTxtPrint	+= CRLF + CRLF
				cTxtPrint	+= Substr(SM0->M0_NOMECOM ,1,37) + CRLF
				If !cTipo $ "DB"
					DbSelectArea("SA1")
					DbSetOrder(1)
					If DbSeek(xFilial("SA1")+cCliente+cLoja)
						cTxtPrint	+=	Substr(SA1->A1_NOME,1,40) + CRLF
						cTxtPrint	+=	SA1->A1_EST + "/" + SA1->A1_MUN	 + CRLF
					Endif
				Else
					DbSelectArea("SA2")
					DbSetOrder(1)
					If DbSeek(xFilial("SA2")+cCliente+cLoja)
						cTxtPrint	+=	SA2->A2_NOME + CRLF
						cTxtPrint	+=	SA2->A2_MUN + CRLF
					Endif
				Endif
				DbSelectArea("SB1")
				DbSetOrder(1)
				If dbSeek(xFilial("SB1")+aEtiqueta[x][3])
					If aEtiqueta[x][8] == "N" // Só imprimirá se for Miudeza == Não
						cTxtPrint	+= 	AllTrim(Transform(y,"@E 9999")) + "/" + AllTrim(Transform(aEtiqueta[x][4],"@E 9999")) + " - " + AllTrim(aEtiqueta[x][3]) 
						cTxtPrint	+= 	Substr(SB1->B1_DESC,1,30)
					ElseIf aEtiqueta[x][8] == "M" // Só imprimirá se for Miudeza == Não
						cTxtPrint	+= 	AllTrim(Transform(y,"@E 9999")) + "/" + AllTrim(Transform(nLenEtq,"@E 9999")) + " - " + AllTrim(aEtiqueta[x][3]) 
						cTxtPrint	+= 	Substr(SB1->B1_DESC,1,30)
					Else 
						cTxtPrint	+= 	"VOLUME FECHADO-CHECKOUT"
					Endif
				Endif

				cTxtPrint	+= 	"Pedido:" + aEtiqueta[x][5]	+ CRLF
				cTxtPrint	+=	"N.NF: "  + aEtiqueta[x][6]	+ CRLF
				cTxtPrint	+=	"Vol:" + AllTrim(Str(nConta))+"/"+AllTrim(Str(nTotal))
			Endif
		Next
	Next

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Etiquetas diversas                                                  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	For y := 1 To nDiversos

		nVolumes++

		If lPrintEtq
			_cPorta := Alltrim(GetNewPar("GF_PORTLPT","LPT1:9600,n,8,1"))

			MSCBPRINTER("ALLEGRO",_cPorta,Nil,) //Seta tipo de impressora
			MSCBCHKSTATUS(.F.)
			MSCBBEGIN(1,4) //Inicio da Imagem da Etiqueta
			MSCBSAY(03,32,Substr(SM0->M0_NOMECOM ,1,37)		,"N"	,"9"	,"002,003") //Imprime Texto
			MSCBSAY(03,27,cTransp							,"N"	,"9"	,"002,003") //Imprime Texto

			If !cTipo $ "DB"
				DbSelectArea("SA1")
				DbSetOrder(1)
				If DbSeek(xFilial("SA1")+cCliente+cLoja)
					MSCBSAY(03,21,	Substr(SA1->A1_NOME,1,40)	,"N"	,"9"	,"002,003") //Imprime Texto
					MSCBSAY(03,16, SA1->A1_EST + "/" + SA1->A1_MUN	,"N","9"	,"002,003") //Imprime Texto
				Endif
			Else
				DbSelectArea("SA2")
				DbSetOrder(1)
				If DbSeek(xFilial("SA2")+cCliente+cLoja)
					MSCBSAY(03,21,SA2->A2_NOME,"N","9","002,003") //Imprime Texto
					MSCBSAY(03,16,SA2->A2_MUN,"N","9","002,003") //Imprime Texto
				Endif
			Endif
			MSCBSAY(03,10,"Pedido:"			,"N"	,"9"	,"002,002") //Imprime Texto
			MSCBSAY(18,09,cPedido			,"N"	,"9"	,"002,003")
			MSCBSAY(40,10,"N.NF: "	 		,"N"	,"9"	,"002,002")
			MSCBSAY(55,09,cNota				,"N"	,"9"	,"004,005") //Imprime pedido e nota fiscal
			MSCBSAY(03,05,"VOLUMES DIVERSOS","N"	,"9"	,"002,002") //Imprime Texto

			nConta++
			MSCBSAY(75,05,"Vol:" + AllTrim(Str(nConta))+"/"+AllTrim(Str(nTotal)),"N"	,"9"	,"002,002") //Imprime Texto

			cResult := MSCBEND()

			//MsgInfo(cResult)

			MemoWrit('DIS010',cResult)
		Else
			nVolumes++
			nConta++
			cTxtPrint	+= CRLF + CRLF
			cTxtPrint	+= Substr(SM0->M0_NOMECOM ,1,37) + CRLF
			If !cTipo $ "DB"
				DbSelectArea("SA1")
				DbSetOrder(1)
				If DbSeek(xFilial("SA1")+cCliente+cLoja)
					cTxtPrint	+=	Substr(SA1->A1_NOME,1,40) + CRLF
					cTxtPrint	+=	SA1->A1_EST + "/" + SA1->A1_MUN	 + CRLF
				Endif
			Else
				DbSelectArea("SA2")
				DbSetOrder(1)
				If DbSeek(xFilial("SA2")+cCliente+cLoja)
					cTxtPrint	+=	SA2->A2_NOME + CRLF
					cTxtPrint	+=	SA2->A2_MUN + CRLF
				Endif
			Endif
			cTxtPrint	+= "Pedido:" + aEtiqueta[x][5]	+ CRLF
			cTxtPrint	+=	"N.NF: "  + aEtiqueta[x][6]	+ CRLF
			cTxtPrint	+=	"Vol:" + AllTrim(Str(nConta))+"/"+AllTrim(Str(nTotal))
		Endif
	Next

	Begin Transaction

		DbSelectArea("SF2")
		DbSetOrder(1)
		If DbSeek(xFilial("SF2")+Padr(cNota,TamSX3("F2_DOC")[1])+cSerie)
			RecLock("SF2",.F.)
			SF2->F2_VOLUME1 := nVolumes
			SF2->F2_VOLUME3 := nDiversos
			SF2->F2_ESPECI1 := "DIVERSOS"
			MsUnLock()
		Endif

		DbSelectArea("CB7")
		DbSetOrder(4) // CB7_FILIAL+CB7_NOTA+CB7_SERIE+CB7_LOCAL+CB7_STATUS
		If DbSeek(xFilial("CB7")+Padr(cNota,TamSX3("F2_DOC")[1])+cSerie)
			RecLock("CB7",.F.)
			CB7->CB7_VOLEMI	:= "1"
			CB7->CB7_STATUS	:= "9"
			CB7->CB7_DIVERG	:= ""
			CB7->CB7_DTFIMS	:= Date()
			CB7->CB7_HRFIMS	:= Time()
			MsUnlock()
		Endif

	End Transaction

	If !Empty(cTxtPrint) .And. !lPrintEtq
		Aviso("Impressão de volumes",cTxtPrint,{"Ok"},3)
	Endif

	// Grava Log - Fica fora do Transaction por que a função abaixo faz um próprio Transaction
	U_MLCFGM01("CP",cPedido,"Pedido conferido:" + cUserName + "Volumes:"+Str(nVolumes) + " Diversos:"+Str(nDiversos) + IIf(!Empty(cMotivo)," Motivo:"+cMotivo,""),FunName())

Return
