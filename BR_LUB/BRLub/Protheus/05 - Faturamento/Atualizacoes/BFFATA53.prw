#INCLUDE "rwmake.ch"
#INCLUDE "TOPCONN.CH"



User Function DIS010P(aEtiqueta,nDiversos,cPedido,cCliente,cLoja,cTipo)

Return U_BFFATA53(aEtiqueta,nDiversos,cPedido,cCliente,cLoja,cTipo)


/*/{Protheus.doc} BFFATA53
(Impressão de etiquetas de conferência de pedidos)
@author MarceloLauschner
@since 20/10/2016
@version 1.0
@param aEtiqueta, array, (Descrição do parâmetro)
@param nDiversos, numérico, (Descrição do parâmetro)
@param cPedido, character, (Descrição do parâmetro)
@param cCliente, character, (Descrição do parâmetro)
@param cLoja, character, (Descrição do parâmetro)
@param cTipo, character, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFFATA53(aEtiqueta,nDiversos,cPedido,cCliente,cLoja,cTipo)

	Local	aAreaOld	:= GetArea()
	Local 	nConta     	:= 0
	Local 	nTotal     	:= 0
	Local 	nVolumes   	:= 0
	Local 	cTransp    	:= Space(6)
	Local 	cNomfil    	:= Space(3)
	Local	cMotivo	 	:= Space(100)
	Local 	cPrintTxt	:= ""
	Local 	cPrintMsg	:= ""
	Local	lOnlyView	:= .F. 
	Local 	x 
	Local 	y 
	Local	lIsHomologa	:= Alltrim(Lower(GetEnvServer())) == "desenvolvimento" .Or.;
	(cEmpAnt+cFilAnt == "0205" .And. __cUserId $ "000242" ) .Or. ;// Chamado 004237 - Permitir que usuário não imprima etiquetas
	(cEmpAnt+cFilAnt == "0207" .And. __cUserId $ "000242" )// Chamado 16152 - Permitir que usuário não imprima etiquetas

	// Verifica parâmetro por filial x usuários liberados 
	If __cUserId $ GetNewPar("BF_FTA53UR","000000")
		lOnlyView	:= .T.
	Endif 
	
	// Verifica regras especificas 
	If cEmpAnt+cFilAnt == "0204" .And. __cUserId $ "000218"
		lIsHomologa	:= .T.
	ElseIf __cUserId $ "000130#000307"
		lIsHomologa	:= .T.
	Endif

	If lIsHomologa
		If MsgYesNo("Ambiente de homologação/Desenvolvimento! Deseja imprimir etiquetas fisicas?","Visualização Etiquetas")
			lIsHomologa	:= .F.
		Endif
	Endif
	
	If lOnlyView
		lIsHomologa	:= .T. 
	Endif

	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()

	//1-cCliente,;
	//2-cLoja,;
	//3-OKC->C9_PRODUTO,;
	//4-((OKC->QTE-Mod(OKC->QTE,IIf(SB1->B1_CONVB==0,1,SB1->B1_CONVB)))/IIf(SB1->B1_CONVB==0,1,SB1->B1_CONVB)),;
	//5-cPedido,;
	//6-SB1->B1_LOCAL})


	cSenhaDi 	:= Padr(GetNewPar("BF_PSWD010",StrZero(Day(dDataBase),2)+StrZero(Val(Substr(Time(),1,2))*2,2)),10)
	cSenhaAtu   := Space(10)


	cQry := "SELECT R_E_C_N_O_ AS Z0RECNO "
	cQry += "  FROM "+RetSqlName("SZ0")
	cQry += " WHERE Z0_PEDIDO = '"+cPedido+"' "
	cQry += "   AND Z0_TIPO = 'CP' "
	cQry += "   AND Z0_DATA >= '"+DTOS(Date()-4)+"'"
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
		@ 030,010 BUTTON "Avancar-->" SIZE 40,10 Action(IIf(lContinua,Close(oDlg6),MsgAlert("Senha incorreta ou sem Motivo digitado!!","BFFATA53")))

		ACTIVATE MSDIALOG oDlg6 CENTERED Valid (lContinua :=  Len(Alltrim(cMotivo)) > 20 )

	Endif

	QZ0->(DbCloseArea())

	If !lContinua
		RestArea(aAreaOld)
		Return
	Endif

	dbSelectArea("SC5")
	dbSetOrder(1)
	dbSeek(xFilial("SC5")+cPedido)

	cTransp := SC5->C5_TRANSP

	dbSelectArea("SA4")
	dbSetOrder(1)
	dbSeek(xFilial("SA4")+cTransp)

	cNomfil	:= U_FPDC_007(cTipo,cCliente,cLoja)

	If !cTipo $ "B#D"
		dbSelectArea("SA1")
		dbSetOrder(1)
		dbSeek(xFilial("SA1")+cCliente+cLoja)
	Else
		dbSelectArea("SA2")
		dbSetOrder(1)
		dbSeek(xFilial("SA2")+cCliente+cLoja)
	Endif


	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Verifica total de etiquetas                                         ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	nTotal += nDiversos

	For x := 1 To Len(aEtiqueta)
		nTotal += aEtiqueta[x][4]
	Next


	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Impressao das etiquetas                                             ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	For x := 1 To Len(aEtiqueta)

		For y := 1 To aEtiqueta[x][4]

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Inicio de impressao                                                 ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If !lIsHomologa
				_cPorta := Alltrim(GetNewPar("GM_PORTLPT","LPT1:9600,n,8,1"))
				MSCBPRINTER("ALLEGRO",_cPorta,Nil,) //Seta tipo de impressora
				MSCBCHKSTATUS(.F.)
				MSCBBEGIN(1,4) //Inicio da Imagem da Etiqueta
			Endif

			nVolumes++
			cPrintTxt	:= " "+Alltrim(SM0->M0_NOME)+" Tel:"+ Alltrim(SM0->M0_TEL)
			cPrintMsg	+= Chr(13)+Chr(10)+cPrintTxt
			If !lIsHomologa
				MSCBSAY(01,32,cPrintTxt,"N","9","002,001")//Imprime Texto
			Endif

			If !cTipo $ "B#D"
				cPrintTxt	:= SA1->A1_NOME
				cPrintMsg 	+= Chr(13)+Chr(10)+cPrintTxt
				If !lIsHomologa
					MSCBSAY(01,28,cPrintTxt,"N","9","002,001")//Imprime Texto
				Endif
				cPrintTxt	:= Alltrim(SA1->A1_MUN)+"-"+SA1->A1_EST
				cPrintMsg 	+= Chr(13)+Chr(10)+cPrintTxt
				If !lIsHomologa
					MSCBSAY(01,17,cPrintTxt,"N","9","002,002") //Imprime Texto
				Endif
			Else
				cPrintTxt	:= SA2->A2_NOME
				cPrintMsg 	+= Chr(13)+Chr(10)+cPrintTxt
				If !lIsHomologa
					MSCBSAY(01,28,cPrintTxt,"N","9","002,001") //Imprime Texto
				Endif
				cPrintTxt	:= (SA2->A2_MUN)+"-"+SA2->A2_EST
				cPrintMsg 	+= Chr(13)+Chr(10)+cPrintTxt
				If !lIsHomologa
					MSCBSAY(01,17,cPrintTxt,"N","9","002,002") //Imprime Texto
				Endif
			Endif

			If cTransp == "000010"
				cPrintTxt	:= cNomFil
				cPrintMsg 	+= Chr(13)+Chr(10)+cPrintTxt
				If !lIsHomologa
					MSCBSAY(65,21,cPrintTxt,"N","9","004,003")
				Endif
			Else
				cPrintTxt	:= cNomFil+"-"+cTransp+"-"+Alltrim(SA4->A4_NREDUZ)
				cPrintMsg 	+= Chr(13)+Chr(10)+cPrintTxt
				If !lIsHomologa
					MSCBSAY(35,21,cPrintTxt,"N","9","002,002")
				Endif
			Endif

			cPrintTxt	:= "Nr.Pedido: "
			cPrintMsg 	+= Chr(13)+Chr(10)+cPrintTxt
			If !lIsHomologa
				MSCBSAY(45,12,cPrintTxt ,"N","9","001,001")
			Endif
			cPrintTxt	:= cPedido
			cPrintMsg 	+= Chr(13)+Chr(10)+cPrintTxt
			If !lIsHomologa
				MSCBSAY(56,10,cPrintTxt,"N","9","006,004") //Imprime pedido
			Endif

			//MSCBSAY(01,12,"Pedido","N","9","001,001") //Imprime Texto
			//MSCBSAY(10,10,aEtiqueta[x][5],"N","9","002,002")

			DbSelectArea("SB1")
			DbSetOrder(1)
			If dbSeek(xFilial("SB1")+aEtiqueta[x][3])
				cPrintTxt	:= AllTrim(aEtiqueta[x][3])
				cPrintMsg 	+= Chr(13)+Chr(10)+cPrintTxt
				If !lIsHomologa
					MSCBSAY(01,12,cPrintTxt,"N","9","002,002") //Imprime Texto
				Endif
				// Chamado 20.602 
				// Imprime na Etiqueta o código do produto Fornecedor conforme o cadastro padrão de fornecedor no Produto x SA5 
				If SB1->B1_PROC == "000468"
					DbSelectArea("SA5")
					DbSetOrder(1)
					If Dbseek(xFilial("SA5") + SB1->B1_PROC + SB1->B1_LOJPROC + SB1->B1_COD  )
						cPrintTxt	:= "Cód.Forn: " + Alltrim(SA5->A5_CODPRF)  
						cPrintMsg 	+= Chr(13)+Chr(10)+cPrintTxt
						If !lIsHomologa
							MSCBSAY(01,09,cPrintTxt ,"N","9","001,001")
						Endif
					Endif
				Endif
				
				cPrintTxt	:= SB1->B1_UM + "-" +  Alltrim(Substr(SB1->B1_DESC,1,40))
				cPrintMsg 	+= Chr(13)+Chr(10)+cPrintTxt
				If !lIsHomologa
					MSCBSAY(02,05,cPrintTxt,"N","9","002,002") //Imprime Texto
				Endif
				
				cPrintTxt	:= Alltrim(Substr(SB1->B1_DESC,41,Len(SB1->B1_DESC)-40))
				cPrintMsg 	+= Chr(13)+Chr(10)+cPrintTxt
				If !lIsHomologa
					MSCBSAY(01,02,cPrintTxt,"N","9","001,001") //Imprime Texto
				Endif
				
				cPrintTxt	:= Alltrim(aEtiqueta[x][6]) + " - " + AllTrim(Transform(y,"@E 9999")) + "/" + AllTrim(Transform(aEtiqueta[x][4],"@E 9999"))
				//+Iif(SB1->B1_CONVB > 1," Cx c/ " + AllTrim(Transform(SB1->b1_convb,"@E 9999")),"")
				cPrintMsg 	+= Chr(13)+Chr(10)+cPrintTxt
				If !lIsHomologa
					MSCBSAY(01,01,cPrintTxt,"N","9","002,001") //Imprime Texto
				Endif
				nConta++
				cPrintTxt	:= "Vol."+AllTrim(Str(nConta))+"/"+AllTrim(Str(nTotal))
				cPrintMsg 	+= Chr(13)+Chr(10)+cPrintTxt
				If !lIsHomologa
					MSCBSAY(75,01,cPrintTxt,"N","9","003,002") //Imprime Texto
				Endif
			Endif

			If !lIsHomologa
				cResult := MSCBEND()
				MemoWrit('DIS010P',cResult)
			Endif

		Next
	Next

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Etiquetas diversas                                                  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	For y := 1 To nDiversos

		nVolumes++
		If !lIsHomologa
			_cPorta := Alltrim(GetNewPar("GM_PORTLPT","LPT1:9600,n,8,1"))
			MSCBPRINTER("ALLEGRO",_cPorta,Nil,) //Seta tipo de impressora
			MSCBCHKSTATUS(.F.)
			MSCBBEGIN(1,4) //Inicio da Imagem da Etiqueta
		Endif
		cPrintTxt	:= " "+Alltrim(SM0->M0_NOME)+" Tel:"+ Alltrim(SM0->M0_TEL)
		cPrintMsg 	+= Chr(13)+Chr(10)+cPrintTxt
		If !lIsHomologa
			MSCBSAY(01,32,cPrintTxt,"N","9","002,001")//Imprime Texto
		Endif

		If cTransp == "000010"
			cPrintTxt	:= cNomFil
			cPrintMsg 	+= Chr(13)+Chr(10)+cPrintTxt
			If !lIsHomologa
				MSCBSAY(65,21,cPrintTxt,"N","9","004,003")
			Endif
		Else
			cPrintTxt	:= cNomFil+"-"+cTransp+"-"+Alltrim(SA4->A4_NREDUZ)
			cPrintMsg 	+= Chr(13)+Chr(10)+cPrintTxt
			If !lIsHomologa
				MSCBSAY(35,21,cPrintTxt,"N","9","002,002")
			Endif
		Endif
		If !cTipo $ "B#D"
			cPrintTxt	:= SA1->A1_NOME
			cPrintMsg 	+= Chr(13)+Chr(10)+cPrintTxt
			If !lIsHomologa
				MSCBSAY(01,28,cPrintTxt,"N","9","002,001")//Imprime Texto
			Endif
			cPrintTxt	:= Alltrim(SA1->A1_MUN)+"-"+SA1->A1_EST
			cPrintMsg 	+= Chr(13)+Chr(10)+cPrintTxt
			If !lIsHomologa
				MSCBSAY(01,17,cPrintTxt,"N","9","002,002") //Imprime Texto
			Endif
		Else
			cPrintTxt	:= SA2->A2_NOME
			cPrintMsg 	+= Chr(13)+Chr(10)+cPrintTxt
			If !lIsHomologa
				MSCBSAY(01,28,cPrintTxt,"N","9","002,001") //Imprime Texto
			Endif
			cPrintTxt	:= Alltrim(SA2->A2_MUN)+"-"+SA2->A2_EST
			cPrintMsg 	+= Chr(13)+Chr(10)+cPrintTxt
			If !lIsHomologa
				MSCBSAY(01,17,cPrintTxt,"N","9","002,002") //Imprime Texto
			Endif
		Endif

		cPrintTxt	:= "Nr.Pedido: "
		cPrintMsg 	+= Chr(13)+Chr(10)+cPrintTxt
		If !lIsHomologa
			MSCBSAY(45,12,cPrintTxt ,"N","9","001,001")
		Endif
		cPrintTxt	:= cPedido
		cPrintMsg 	+= Chr(13)+Chr(10)+cPrintTxt
		If !lIsHomologa
			MSCBSAY(55,10,cPrintTxt,"N","9","006,004") //Imprime pedido
		Endif

		cPrintTxt	:= "VOLUMES DIVERSOS"
		cPrintMsg 	+= Chr(13)+Chr(10)+cPrintTxt
		If !lIsHomologa
			MSCBSAY(07,05,cPrintTxt,"N","9","002,002") //Imprime Texto
		Endif
		nConta++
		cPrintTxt	:= "Vol."+AllTrim(Str(nConta))+"/"+AllTrim(Str(nTotal))
		cPrintMsg 	+= Chr(13)+Chr(10)+cPrintTxt
		If !lIsHomologa
			MSCBSAY(75,01,cPrintTxt,"N","9","003,002") //Imprime Texto
		Endif

		If !lIsHomologa
			cResult := MSCBEND()
			MemoWrit('DIS010P',cResult)
		Endif
	Next

	If !Empty(cPrintMsg) .And. lIsHomologa
		Aviso("Impressão de volumes",cPrintMsg,{"Ok"},3)
	Endif

	dbSelectArea("SC5")
	dbSetOrder(1)
	If dbSeek(xFilial("SC5")+cPedido)
		RecLock("SC5",.F.)
		SC5->C5_VOLUME1 := nVolumes
		SC5->C5_VOLUME2 := 0
		SC5->C5_VOLUME3 := nDiversos
		SC5->C5_ESPECI1	:= "DIVERSOS"
		SC5->C5_ESPECI2	:= ""  //cBox+cSep+cMesa+cConf
		SC5->C5_ESPECI3	:= ""
		SC5->C5_ESPECI4	:= ""

		MsUnLock()
	Endif

	// Grava Log
	U_GMCFGM01("CP",cPedido,"Pedido conferido:" + cUserName + "Volumes:"+Str(nVolumes) + " Diversos:"+Str(nDiversos) +;
	"Dados Box+Sep+Mesa+Conf.:"+cBox+cSep+cMesa+cConf+;
	IIf(!Empty(cMotivo)," Motivo:"+cMotivo,""),FunName())

	RestArea(aAreaOld)

Return .T.
