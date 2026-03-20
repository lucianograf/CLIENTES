#INCLUDE "rwmake.ch"
#INCLUDE "TOPCONN.CH"
//#include "protheus.ch"
//--------------------------------+
// Favor Documentar alterações.   |
// Data - Analista - Descrição	  |
//--------------------------------+
//-------------------------------------------------------------------------------------------------
// 26/03/2010 - Marcelo Lauschner - Revisão do código
//
//-------------------------------------------------------------------------------------------------

User Function DIS010(aEtiqueta,nDiversos,cPedido,cNota,cSerie,cCliente,cLoja,cTipo)
	
	/*/
	ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
	±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
	±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
	±±ºPrograma ³DIS010 º Autor ³ Leonardo J Koerich Jr  º Data ³  22/05/03   º±±
	±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
	±±ºDescricao ³ Impressao de etiqueta para despacho                        º±±
	±±º          ³                                                            º±±
	±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
	±±ºUso       ³ Sigafat                                                    º±±
	±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
	±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
	ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
	/*/
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Declaracao de Variaveis                                             ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	
	Local nConta     := 0
	Local nTotal     := 0
	Local nVolumes   := 0
	Local nAmarrados := 0
	Local cTransp    := Space(6)
	Local cNomfil    := Space(3)
	Local cCodfil    := Space(3)
	Local cMotivo	 := Space(100)
	
	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()
	
	cSenhaDi 	:= Padr(GetNewPar("BF_PSWD010",StrZero(Day(dDataBase),2)+StrZero(Val(Substr(Time(),1,2))*2,2)),10)
	cSenhaAtu   := Space(10)
	
	cQry := "SELECT UTL_RAW.CAST_TO_VARCHAR2(DBMS_LOB.SUBSTR(z0_obs, 4000,1)) TEXTO "
	cQry += "  FROM "+RetSqlName("SZ0")
	cQry += " WHERE Z0_PEDIDO = '"+cPedido+"' "
	cQry += "   AND Z0_TIPO = 'CP' "
	cQry += "   AND Z0_DATA >= TO_CHAR(SYSDATE-4,'YYYYMMDD') "
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
		@ 030,010 BUTTON "Avancar-->" SIZE 40,10 Action(IIf(lContinua,Close(oDlg6),MsgAlert("Senha incorreta ou sem Motivo digitado!!")))
		
		ACTIVATE MSDIALOG oDlg6 CENTERED Valid (lContinua :=  Len(Alltrim(cMotivo)) > 20 )
		
	Endif
	
	QZ0->(DbCloseArea())
	
	If !lContinua
		Return
	Endif
	
	DbSelectArea("SF2")
	DbSetOrder(1)
	DbSeek(xFilial("SF2")+Padr(cNota,TamSX3("F2_DOC")[1])+cSerie)
	cTransp := SF2->F2_TRANSP
	If cTipo <> "B" .or. cTipo <> "D"
		
		DbSelectArea("SA1")
		DbSetOrder(1)
		DbSeek(xFilial("SA1")+cCliente+cLoja)
		
		DbSelectArea("PAB")
		DbSetOrder(1)
		If dbSeek(xFilial("PAB")+SA1->A1_CEP)
			cNomfil := PAB->PAB_CTRFIL
			cCodFil := PAB->PAB_NTRFIL
		Else
			cNomfil := "SEM"
			cCodFil := "ID"
		Endif
		
	Else
		DbSelectArea("SA2")
		DbSetOrder(1)
		DbSeek(xFilial("SA2")+cCliente+cLoja)
		
		DbSelectArea("PAB")
		DbSetOrder(1)
		If dbSeek(xFilial("PAB")+SA2->A2_CEP)
			cNomfil := PAB->PAB_CTRFIL
			cCodFil := PAB->PAB_NTRFIL
		Else
			cNomfil := "SEM"
			cCodFil := "ID"
		Endif
		
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
			_cPorta := Alltrim(GetNewPar("GM_PORTLPT","LPT1:9600,n,8,1"))
			
			MSCBPRINTER("ALLEGRO",_cPorta,Nil,) //Seta tipo de impressora
			MSCBCHKSTATUS(.F.)
			MSCBBEGIN(1,4) //Inicio da Imagem da Etiqueta
			
			nVolumes++
			IF SM0->M0_CODIGO == '02' .AND. SM0->M0_CODFIL = '01'
				MSCBSAY(01,32,"BIG FORTA COM REPR LTDA (47) 3041-2001","N","9","002,001") //Imprime Texto
			ELSEIF SM0->M0_CODIGO == '04' .AND. SM0->M0_CODFIL = '01'
				MSCBSAY(01,32,"ATRIA LUBRIFICANTES (51) 3077-0708","N","9","002,001") //Imprime Texto
			ENDIF
			If cTransp >= "000010" .and. cTransp <= "000100"
				MSCBSAY(01,23,"Origem -> BLU  03  Destino -> ","N","9","002,002")
				MSCBSAY(65,21,cNomfil + "  " + cCodFil,"N","9","004,003")
			Endif
			
			If cTipo <> "B" .or. cTipo <> "D"
				DbSelectArea("SA1")
				DbSetOrder(1)
				If DbSeek(xFilial("SA1")+aEtiqueta[x][1]+aEtiqueta[x][2],.T.)
					MSCBSAY(01,28,SA1->A1_NOME,"N","9","002,001") //Imprime Texto
					MSCBSAY(01,17,SA1->A1_MUN,"N","9","002,002") //Imprime Texto
				Endif
			Else
				DbSelectArea("SA2")
				DbSetOrder(1)
				If DbSeek(xFilial("SA2")+aEtiqueta[x][1]+aEtiqueta[x][2],.T.)
					MSCBSAY(01,28,SA2->A2_NOME,"N","9","002,001") //Imprime Texto
					MSCBSAY(01,17,SA2->A2_MUN,"N","9","002,002") //Imprime Texto
				Endif
			Endif
			MSCBSAY(01,12,"Ped","N","9","001,001") //Imprime Texto
			MSCBSAY(10,10,aEtiqueta[x][5],"N","9","002,002")
			MSCBSAY(45,12,"Nr.NF: " ,"N","9","001,001")
			MSCBSAY(55,10,aEtiqueta[x][6],"N","9","006,004") //Imprime pedido e nota fiscal
			
			DbSelectArea("SB1")
			DbSetOrder(1)
			If dbSeek(xFilial("SB1")+aEtiqueta[x][3])
				MSCBSAY(01,05,AllTrim(aEtiqueta[x][3]) + " - " + Substr(SB1->B1_DESC,1,30),"N","9","002,002") //Imprime Texto
				MSCBSAY(01,01,"Endereco: "+ SB1->B1_LOCAL + " - " + AllTrim(Transform(y,"@E 9999")) + "/" + AllTrim(Transform(aEtiqueta[x][4],"@E 9999")) + " Cx c/ " + AllTrim(Transform(SB1->b1_convb,"@E 9999")),"N","9","002,001") //Imprime Texto
				nConta++
				MSCBSAY(75,01,AllTrim(Str(nConta))+"/"+AllTrim(Str(nTotal)),"N","9","003,002") //Imprime Texto
			Endif
			
			cResult := MSCBEND()
			MemoWrit('DIS010',cResult)
			Sleep(700)
		Next
		
	Next
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Etiquetas diversas                                                  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	
	For y := 1 To nDiversos
		
		nVolumes++
		
		_cPorta := Alltrim(GetNewPar("GM_PORTLPT","LPT1:9600,n,8,1"))
		
		MSCBPRINTER("ALLEGRO",_cPorta,Nil,) //Seta tipo de impressora
		MSCBCHKSTATUS(.F.)
		MSCBBEGIN(1,4) //Inicio da Imagem da Etiqueta
		IF SM0->M0_CODIGO == '02' .AND. SM0->M0_CODFIL = '01'
			MSCBSAY(01,32,"BIG FORTA COM REPR LTDA (47) 3041-2001","N","9","002,001") //Imprime Texto
		ELSEIF SM0->M0_CODIGO == '04' .AND. SM0->M0_CODFIL = '01'
			MSCBSAY(01,32,"ATRIA LUBRIFICANTES (51) 3077-0708","N","9","002,001") //Imprime Texto
		ENDIF
		If cTransp >= "000010" .and. cTransp <= "000100"
			MSCBSAY(01,23,"Origem -> BLU  03  Destino -> ","N","9","002,002")
			MSCBSAY(65,21,cNomfil + "  " + cCodFil,"N","9","004,003")
		Endif
		
		If cTipo <> "B" .or. cTipo <> "D"
			DbSelectArea("SA1")
			DbSetOrder(1)
			If DbSeek(xFilial("SA1")+cCliente+cLoja)
				MSCBSAY(01,28,SA1->A1_NOME,"N","9","002,001") //Imprime Texto
				MSCBSAY(01,17,SA1->A1_MUN,"N","9","002,002") //Imprime Texto
			Endif
		Else
			DbSelectArea("SA2")
			DbSetOrder(1)
			If DbSeek(xFilial("SA2")+cCliente+cLoja)
				MSCBSAY(01,28,SA2->A2_NOME,"N","9","002,001") //Imprime Texto
				MSCBSAY(01,17,SA2->A2_MUN,"N","9","002,002") //Imprime Texto
			Endif
		Endif
		MSCBSAY(01,12,"Ped","N","9","001,001") //Imprime Texto
		MSCBSAY(10,10,cPedido,"N","9","002,002")
		MSCBSAY(45,12,"Nr.NF: " ,"N","9","001,001")
		MSCBSAY(55,10,cNota,"N","9","006,004") //Imprime pedido e nota fiscal
		MSCBSAY(07,05,"VOLUMES DIVERSOS","N","9","002,002") //Imprime Texto
		nConta++
		MSCBSAY(75,01,AllTrim(Str(nConta))+"/"+AllTrim(Str(nTotal)),"N","9","003,002") //Imprime Texto
		
		cResult := MSCBEND()
		MemoWrit('DIS010',cResult)		
	Next
	
	DbSelectArea("SF2")
	DbSetOrder(1)
	If DbSeek(xFilial("SF2")+Padr(cNota,TamSX3("F2_DOC")[1])+cSerie)
		RecLock("SF2",.F.)
		SF2->F2_VOLUME1 := nVolumes
		SF2->F2_VOLUME3 := nDiversos
		SF2->F2_ESPECI1 := "DIVERSOS"
		MsUnLock("SF2")
		dbclosearea("SF2")
	Endif
	
	// Grava Log
	U_GMCFGM01("CP",cPedido,"Pedido conferido:" + cUserName + "Volumes:"+Str(nVolumes) + " Diversos:"+Str(nDiversos) + IIf(!Empty(cMotivo)," Motivo:"+cMotivo,""),FunName())
	
Return
