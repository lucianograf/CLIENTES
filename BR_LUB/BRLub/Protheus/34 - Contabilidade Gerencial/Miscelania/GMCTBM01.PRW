#include "protheus.ch"
#include "topconn.ch"


/*/{Protheus.doc} GMCTBM01
(Rotina Customizada para Importação da Folha - Rubi   )
@author MarceloLauschner
@since 14/06/2012
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function GMCTBM01()
	
	Private		aTotRdpe 	:= {{0,0,0,0},{0,0,0,0}}
	Private 	dDataLanc	:= dDataBase
	Private 	cArqImp		:= Space(150)
	Private 	oArqIMp,oDescEnt
	Private		cDescEnt	:= Space(50)
	Private		aCols,aHeader
	Private 	aButton		:= {{"VERDE"		,{|| CTBA102()}  ,"Lançamentos Automáticos"},{"AMARELO"	,{|| sfCadConv()}  ,"Cadastro de Conversões"}}
	Private		nPxLINHA,nPxDC,nPxDEBITO,nPxCREDIT,nPxVALOR,nPxHIST,nPxCCD,nPxCCC,nPxORIGEM
	Private 	aSize := MsAdvSize(,.F.,400)
	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()
	
	DEFINE MSDIALOG oDlg TITLE OemToAnsi("Importação Folha Pagamento Modelo Rubi") From aSize[7],0 to aSize[6],aSize[5] OF oMainWnd PIXEL
	
	oDlg:lMaximized := .T.
	
	oPanel1 := TPanel():New(0,0,'',oDlg, oDlg:oFont, .T., .T.,, ,200,35,.T.,.T. )
	oPanel1:Align := CONTROL_ALIGN_TOP
	
	oPanel2 := TPanel():New(0,0,'',oDlg, oDlg:oFont, .T., .T.,, ,200,40,.T.,.T. )
	oPanel2:Align := CONTROL_ALIGN_ALLCLIENT
	
	oPanel3 := TPanel():New(0,0,'',oDlg, oDlg:oFont, .T., .T.,, ,200,60,.T.,.T. )
	oPanel3:Align := CONTROL_ALIGN_BOTTOM
	
	
	DEFINE FONT oFnt 	NAME "Arial" SIZE 0, -11 BOLD
	
	@ 012 ,005  	Say OemToAnsi("Data Lançamento") SIZE 30,9 PIXEl OF oPanel1 FONT oFnt					//"Data"
	@ 011 ,023  	MSGET dDataLanc  Picture "99/99/9999" PIXEl SIZE 55, 10 OF oPanel1 HASBUTTON
	
	@ 012 ,083   	Say OemToAnsi("Arquivo") SIZE 30,9 PIXEl	OF oPanel1 FONT oFnt 				//"Lote"
	@ 011 ,121		MSGET oArqIMp VAR cArqImp Picture "@!" PIXEl SIZE 132, 10 OF oPanel1 Valid (cArqImp := cGetFile( "Todos os Arquivos (*.*) | *.*", "Selecione o Arquivo para importa folha",,"C:\EDI\",.T., ),Processa({|| sfCarrega(@oMulti:aCols,@oMulti:aHeader,2)},"Carregando dados..."))
	
	
	Processa({|| sfCarrega(@aCols,@aHeader,1) },"Localizando registros...")
	
	Private oMulti := MsNewGetDados():New(034, 005, 226, 415,GD_INSERT+GD_DELETE+GD_UPDATE,"U_GMCTBMV2()"/*cLinhaOk*/,;
		"AllwaysTrue()"/*cTudoOk*/,"+CT2_LINHA",;
		,4/*nFreeze*/,10000/*nMax*/,"U_GMCTBMV1()"/*cCampoOk*/,/*cSuperApagar*/,;
		/*cApagaOk*/,oPanel2,@aHeader,@aCols,{|| sfAtuRodp() })
	
	oMulti:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	
	@ 006  ,008 SAY OemToAnsi("Descrição da Entidade")	Of oPanel3 PIXEL 	FONT oFnt		//"Descri‡„o da Entidade"
	@ 006  ,073 SAY oDescEnt PROMPT cDescEnt FONT oDlg:oFont PIXEL COLOR CLR_HBLUE	Of oPanel3
	
	@ 040 ,008  SAY OemToAnsi("Total Digitado :") Of oPanel3 PIXEL	FONT oFnt				//"Total Digitado  :"
	@ 041 ,065 	MSGET oDig 	VAR aTotRdpe[1][1]	Picture "@E 999,999,999.99" Of oPanel3 READONLY SIZE 95 ,9 PIXEL
	@ 020 ,190 	SAY OemToAnsi("Total Débito  :") Of oPanel3 PIXEL	FONT oFnt				//"Total Debito  :"
	@ 040 ,190	SAY OemToAnsi("Total Crédito :") Of oPanel3 PIXEL FONT oFnt				//"Total Credito :"
	@ 021 ,240	MSGET oDeb 	VAR aTotRdPe[1][2]	Picture "@E 999,999,999.99" Of oPanel3 READONLY SIZE 95 ,9 PIXEL
	@ 041 ,240	MSGET oCred VAR aTotRdPe[1][3] Picture "@E 999,999,999.99" Of oPanel3 READONLY SIZE 95 ,9 PIXEL
	
	ACTIVATE MSDIALOG oDlg ON INIT (oMulti:oBrowse:Refresh(),EnchoiceBar(oDlg,{|| Processa({||sfGrava()},"Gerando lançamentos contábeis...")},{|| oDlg:End()},,aButton))
	
	
Return


/*/{Protheus.doc} sfGrava
(Efetua a gravação dos pré lançamentos )
@author MarceloLauschner
@since 14/06/2012
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfGrava()
	
	Local		aCab		:= {}
	Local		aItens		:= {}
	Local		aLinha		:= {}
	Local		nX
	Local		cOrigem		:= ""
	Local		cNumLote	:= "000001"
	Local		aPosDel		:= {}
	Private		lMostraErro
	ProcRegua(Len(oMulti:aCols))
	
	If aTotRdPe[1,3] <> aTotRdPe[1,2]
		MsgAlert("Valor entre débito e crédito não é igual!","Diferença no lançamento")
		Return .F.
	Endif
	
	For nX := 1 To Len(oMulti:aCols)
		IncProc()
		
		If !oMulti:aCols[nX,Len(oMulti:aHeader)+1]
			
			If 	cOrigem <> oMulti:aCols[nX,nPxORIGEM]
				If !Empty(aCab) .And. !Empty(aItens)
					lMsErroAuto	:= .F.
					
					DbSelectArea("CT2")
					
					MSExecAuto( {|X,Y,Z| CTBA102(X,Y,Z)} ,aCab ,aItens, 3)
					
					If lMsErroAuto
						If !IsBlind()
							//MsgAlert("Erro durante a inclusão do Lançamento Contábil do Funcionário '"+cOrigem+"'!","Erro ao gerar lançamentos!")
							MostraErro()
						Endif
					Else
						// Apago todas as linhas que foram cofirmadas na gravação
						For iq := 1 To Len(aPosDel)
							oMulti:aCols[aPosDel[iq],Len(oMulti:aHeader)+1]	:= .T.
						Next
					EndIf
					aPosDel		:= {}
				Endif
				DbSelectArea("CT2")
				DbSetOrder(1)
				
				While .T.
					If !DbSeek(xFilial("CT2")+DTOS(dDataLanc)+"008865"+"001"+cNumLote)//CT2_FILIAL+DTOS(CT2_DATA)+CT2_LOTE+CT2_SBLOTE+CT2_DOC
						Exit
					Endif
					cNumLote	:= Soma1(cNumLote)
				Enddo
				
				aCab	:=  { 	{'DDATALANC' ,dDataLanc		 	,NIL},;
					{'CLOTE' 	 ,"008865"			,NIL},;
					{'CSUBLOTE'  ,"001"				,NIL},;
					{'CDOC' 	 ,cNumLote			,NIL},;
					{'CPADRAO' 	 ,' ' 				,NIL},;
					{'NTOTINF'   ,0 				,NIL},;
					{'NTOTINFLOT',0 				,NIL} }
				aItens	:= {}
			Endif
		Endif
		
		cOrigem :=  oMulti:aCols[nX,nPxORIGEM]
		aLinha	:= 	{}
		
		Aadd(aLinha,	{'CT2_FILIAL'  	,xFilial("CT2")				, NIL})
		Aadd(aLinha,	{'CT2_LINHA'  	,oMulti:aCols[nX,nPxLINHA]	, NIL})
		Aadd(aLinha,	{'CT2_MOEDLC'  	,'01'   					, NIL})
		Aadd(aLinha,	{'CT2_DC'   	,oMulti:aCols[nX,nPxDC]		, NIL})
		Aadd(aLinha,	{'CT2_DEBITO'  	,oMulti:aCols[nX,nPxDEBITO]	, NIL})
		Aadd(aLinha,	{'CT2_CREDIT'   ,oMulti:aCols[nX,nPxCREDIT]	, NIL})
		Aadd(aLinha,	{'CT2_VALOR'  	,oMulti:aCols[nX,nPxVALOR]	, NIL})
		Aadd(aLinha,	{'CT2_HP'   	,' '   						, NIL})
		Aadd(aLinha,	{'CT2_HIST'   	,oMulti:aCols[nX,nPxHIST]	, NIL})
		Aadd(aLinha,	{'CT2_CCD'  	,oMulti:aCols[nX,nPxCCD]	, NIL})
		Aadd(aLinha,	{'CT2_CCC'   	,oMulti:aCols[nX,nPxCCC]	, NIL})
		
		If oMulti:aCols[nX,nPxDC] == "1"
			Aadd(aLinha,{'CT2_CLVLDB'	,cFilAnt					, NIL})
		ElseIf oMulti:aCols[nX,nPxDC] == "2
			Aadd(aLinha,{'CT2_CLVLCR'	,cFilAnt					, NIL})
		ElseIf oMulti:aCols[nX,nPxDC] == "3
			Aadd(aLinha,{'CT2_CLVLDB'	,cFilAnt					, NIL})
			Aadd(aLinha,{'CT2_CLVLCR'	,cFilAnt					, NIL})
		Endif
		
		Aadd(aLinha,	{'CT2_ORIGEM' 	,oMulti:aCols[nX,nPxORIGEM]	, NIL})
		
		Aadd(aItens,aLinha)
		
		Aadd(aPosDel,nX)
	Next
	
	If 	!Empty(cOrigem)
		If !Empty(aCab) .And. !Empty(aItens)
			lMsErroAuto	:= .F.
			
			MSExecAuto( {|X,Y,Z| CTBA102(X,Y,Z)} ,aCab ,aItens, 3)
			
			If lMsErroAuto <> Nil
				If lMsErroAuto
					If !IsBlind()
						//MsgAlert("Erro durante a inclusão do Lançamento Contábil do Funcionário '"+cOrigem+"'!","Erro ao gerar lançamentos!")
						MostraErro()
					Endif
				Else
					// Apago todas as linhas que foram cofirmadas na gravação
					For iq := 1 To Len(aPosDel)
						oMulti:aCols[aPosDel[iq],Len(oMulti:aHeader)+1]	:= .T.
					Next
				EndIf
			EndIf
		Endif
	Endif
	
	sfAtuRodp()
	
Return


/*/{Protheus.doc} sfCarrega
(Monta o aCols e aHeader do GetDados de pré lançamentos )
@author MarceloLauschner
@since 14/06/2012
@version 1.0
@param aCols, array, (Descrição do parâmetro)
@param aHeader, array, (Descrição do parâmetro)
@param nRefrBox, numérico, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfCarrega(aCols,aHeader,nRefrBox)
	
	Local	nUsado		:=  0
	Local	lContinua	:= .F. 
	Local	aCpo		:=  {"CT2_LINHA","CT2_DC","CT2_DEBITO","CT2_CREDIT","CT2_VALOR","CT2_HIST","CT2_CCD","CT2_CCC","CT2_ORIGEM"}
	Local	cLinha		:=  "001"
	Local   cCampo		:= ""
	Local 	oTmpTable
	Local	aHist250    := {	{"Provisão de férias"		,"510101002","210503001"},;
		{"Provisão 13"				,"510101003","210503002"},;
		{"Provisão INSS s/Férias"	,"510102003","210503005"},;
		{"Provisão FGTS s/Férias"	,"510102005","210503006"},;
		{"Provisão INSS s/13"		,"510102004","210503003"},;
		{"Provisão FGTS s/13"		,"510102006","210503004"}}
	aCols			:= 	{}
	aHeader			:=	{}
	
	// DbSelectArea("SX3")
	// DbSetOrder(2)
	// For iX := 1 To Len(aCpo)
	// 	If DbSeek(aCpo[iX])
	// 		Aadd(aHeader,{ AllTrim(X3Titulo()),;
	// 			SX3->X3_CAMPO	,;
	// 			SX3->X3_PICTURE,;
	// 			SX3->X3_TAMANHO,;
	// 			SX3->X3_DECIMAL,;
	// 			"",;//SX3->X3_VALID	,;
	// 			SX3->X3_USADO	,;
	// 			SX3->X3_TIPO	,;
	// 			SX3->X3_F3 		,;
	// 			SX3->X3_CONTEXT,;
	// 			SX3->X3_CBOX	,;
	// 			SX3->X3_RELACAO })
	// 		nUsado++
	// 		If nRefrBox == 1
	// 			&("nPx"+Substr(SX3->X3_CAMPO,5,6)) := nUsado
	// 		Endif
	// 	Endif
	// Next

	For iX := 1 To Len(aCpo)
		cCampo := aCpo[iX]
		Aadd(aHeader,{ AllTrim(X3Titulo()),;
			GetSx3Cache(cCampo,"X3_CAMPO")		,;
			GetSx3Cache(cCampo,"X3_PICTURE")	,;
			GetSx3Cache(cCampo,"X3_TAMANHO")	,;
			GetSx3Cache(cCampo,"X3_DECIMAL")	,;
			""									,;//SX3->X3_VALID	,;
			GetSx3Cache(cCampo,"X3_USADO")		,;
			GetSx3Cache(cCampo,"X3_TIPO")		,;
			GetSx3Cache(cCampo,"X3_F3") 		,;
			GetSx3Cache(cCampo,"X3_CONTEXT")	,;
			GetSx3Cache(cCampo,"X3_CBOX")		,;
			GetSx3Cache(cCampo,"X3_RELACAO") 	})
		nUsado++
		If nRefrBox == 1
			&("nPx"+Substr(GetSx3Cache(cCampo,"X3_CAMPO"),5,6)) := nUsado
		Endif
	Next
	
	If nRefrBox == 2 .And. cArqImp <> Nil .And. File(cArqImp)
		
		aCampos:={}
		AADD(aCampos,{ "LINHA" ,"C",680,0 })
		
		// cNomArq := CriaTrab(aCampos)
		
		If (Select("TRB") <> 0)
			dbSelectArea("TRB")
			dbCloseArea("TRB")
		Endif
		// dbUseArea(.T.,,cNomArq,"TRB",nil,.F.)

		oTmpTable := FWTemporaryTable():New("TRB",aCampos)
		oTmpTable:Create()
		
		dbSelectArea("TRB")
		Append From (cArqImp) SDF
		
		ProcRegua(RecCount())
		
		DbSelectArea("TRB")
		DbGotop()
		While !Eof()
			
			IncProc()
			
			aArrDados	:= StrTokArr(StrTran(StrTran(TRB->LINHA,".",""),",",".")+"|","|")
			
			If Len(aArrDados) == 5 .And. Alltrim(aArrDados[3]) == "Colaborador:"
				If Select("QSA2") > 0
					QSA2->(DbCloseArea())
				Endif
				
				cLinha	:=  "000"
				
				cQry := "SELECT A2_COD,A2_LOJA,A2_NOME,A2_CC,A2_NREDUZ,A2_NUMFUNC "
				cQry += "  FROM "+RetSqlName("SA2")
				cQry += " WHERE D_E_L_E_T_ = ' ' "
				cQry += "   AND A2_MSBLQL <> '1' "
				cQry += "   AND A2_NUMFUNC = '"+StrZero(Val(aArrDados[4]),6) + "' "
				cQry += "   AND A2_FILIAL = '"+xFilial("SA2")+"' "
				TCQUERY cQry NEW ALIAS "QSA2"
			ElseIf Len(aArrDados) == 3 .And. Alltrim(aArrDados[1]) == "Colaborador:"
				
				lContinua	:= .T. 
				If Select("QSA2") > 0
					If StrZero(Val(QSA2->A2_NUMFUNC),6) <> StrZero(Val(aArrDados[2]),6)
						QSA2->(DbCloseArea())
					Else
						lContinua	:= .F. 
					Endif
				Endif
				If lContinua
					cLinha	:=  "000"
				
					cQry := "SELECT A2_COD,A2_LOJA,A2_NOME,A2_CC,A2_NREDUZ,A2_NUMFUNC "
					cQry += "  FROM "+RetSqlName("SA2")
					cQry += " WHERE D_E_L_E_T_ = ' ' "
					cQry += "   AND A2_MSBLQL <> '1' "
					cQry += "   AND A2_NUMFUNC = '"+StrZero(Val(aArrDados[2]),6) + "' "
					cQry += "   AND A2_FILIAL = '"+xFilial("SA2")+"' "
					
					TCQUERY cQry NEW ALIAS "QSA2"
				Endif
				
			ElseIf Len(aArrDados) == 9 .And. Val(aArrDados[9]) > 0
				
				AADD(aCols,Array(Len(aHeader)+1))
				cLinha	:= Soma1(cLinha)
				
				For nI := 1 To Len(aHeader)
					If IsHeadRec(aHeader[nI][2])
						aCols[Len(aCols)][nI] := TRB->ZRRECNO
					ElseIf IsHeadAlias(aHeader[nI][2])
						aCols[Len(aCols)][nI] := "CT2"
					ElseIf ( aHeader[nI][10] <> "V") .AND. (aHeader[nI][08] <> "M")
						If Alltrim(aHeader[nI][2]) == "CT2_LINHA"
							aCols[Len(aCols)][nI]	:= cLinha
						ElseIf Alltrim(aHeader[nI][2]) == "CT2_DEBITO"
							aCols[Len(aCols)][nI]	:= CriaVar(aHeader[nI][2],.T.)
							If aArrDados[8] == "D"
								cQry := "SELECT CRC_CONTA"
								cQry += "  FROM CONDOR_CONV_CTB_RUBI "
								cQry += " WHERE CRC_EMP = '"+cEmpAnt+"' "
								cQry += "   AND CRC_FIL = '"+xFilial("CT2")+"' "
								cQry += "   AND CRC_CODIGO = '"+aArrDados[1]+"' "
								
								TCQUERY cQry NEW ALIAS "QCN"
								
								If !Eof()
									aCols[Len(aCols)][nI]	:= Padr(QCN->CRC_CONTA,TamSX3(aHeader[nI][2])[1])
								Endif
								QCN->(DbCloseArea())
							Endif
						ElseIf Alltrim(aHeader[nI][2]) == "CT2_CREDIT"
							aCols[Len(aCols)][nI]	:= CriaVar(aHeader[nI][2],.T.)
							If aArrDados[8] == "C"
								cQry := "SELECT CRC_CONTA"
								cQry += "  FROM CONDOR_CONV_CTB_RUBI "
								cQry += " WHERE CRC_EMP = '"+cEmpAnt+"' "
								cQry += "   AND CRC_FIL = '"+xFilial("CT2")+"' "
								cQry += "   AND CRC_CODIGO = '"+aArrDados[1]+"' "
								
								TCQUERY cQry NEW ALIAS "QCN"
								
								If !Eof()
									aCols[Len(aCols)][nI]	:= Padr(QCN->CRC_CONTA,TamSX3(aHeader[nI][2])[1])
								Endif
								QCN->(DbCloseArea())
							Endif
						ElseIf Alltrim(aHeader[nI][2]) == "CT2_VALOR"
							aCols[Len(aCols)][nI]	:= CriaVar(aHeader[nI][2],.T.)
							aCols[Len(aCols)][nI]		:= Val(aArrDados[9])
						ElseIf Alltrim(aHeader[nI][2]) == "CT2_HIST"
							aCols[Len(aCols)][nI]	:= CriaVar(aHeader[nI][2],.T.)
							aCols[Len(aCols)][nI]		:= aArrDados[1]+"-"+aArrDados[2]+"- Cód."+QSA2->A2_NUMFUNC
						ElseIf Alltrim(aHeader[nI][2]) == "CT2_CCD"
							aCols[Len(aCols)][nI]	:= CriaVar(aHeader[nI][2],.T.)
							If aArrDados[8] == "D"
								If Posicione("CT1",1,xFilial("CT1")+aCols[Len(aCols)][nPxDEBITO],"CT1_ACCUST") == "1"
									aCols[Len(aCols)][nI]	:= QSA2->A2_CC
								Endif
							Endif
						ElseIf Alltrim(aHeader[nI][2]) == "CT2_CCC"
							aCols[Len(aCols)][nI] := CriaVar(aHeader[nI][2],.T.)
							If aArrDados[8] == "C"
								If Posicione("CT1",1,xFilial("CT1")+aCols[Len(aCols)][nPxCREDIT],"CT1_CCOBRG") == "1"
									aCols[Len(aCols)][nI]	:= QSA2->A2_CC
								Endif
							Endif
							
						
						ElseIf Alltrim(aHeader[nI][2]) == "CT2_DC"
							//aCols[Len(aCols)][nI]	:= CriaVar(aHeader[nI][2],.T.)
							aCols[Len(aCols)][nI]	:= Iif(aArrDados[8]=="D","1",Iif(aArrDados[8]=="C","2"," "))
						ElseIf Alltrim(aHeader[nI][2]) == "CT2_ORIGEM"
							aCols[Len(aCols)][nI] := Padr(QSA2->A2_NUMFUNC+"-"+QSA2->A2_NREDUZ,TamSX3(aHeader[nI][2])[1])
						Else
							aCols[Len(aCols)][nI] := CriaVar(aHeader[nI][2],.T.)
						Endif
					Else
						If aHeader[nI][10] $ "V#M"
							aCols[Len(aCols)][nI] := CriaVar(aHeader[nI][2],.T.)
						Else
							aCols[Len(aCols)][nI] := CriaVar(aHeader[nI][2],.T.)
						Endif
					Endif
				Next nI
				aCols[Len(aCols),Len(aHeader)+1]	:= .F.
			ElseIf Len(aArrDados) == 11 .And. Val(aArrDados[9]) > 0
				
				AADD(aCols,Array(Len(aHeader)+1))
				cLinha	:= Soma1(cLinha)
				
				For nI := 1 To Len(aHeader)
					If IsHeadRec(aHeader[nI][2])
						aCols[Len(aCols)][nI] := TRB->ZRRECNO
					ElseIf IsHeadAlias(aHeader[nI][2])
						aCols[Len(aCols)][nI] := "CT2"
					ElseIf ( aHeader[nI][10] <> "V") .AND. (aHeader[nI][08] <> "M")
						If Alltrim(aHeader[nI][2]) == "CT2_LINHA"
							aCols[Len(aCols)][nI]	:= cLinha
						ElseIf Alltrim(aHeader[nI][2]) == "CT2_DEBITO"
							aCols[Len(aCols)][nI]	:= CriaVar(aHeader[nI][2],.T.)
							If aArrDados[8] == "D"
								cQry := "SELECT CRC_CONTA"
								cQry += "  FROM CONDOR_CONV_CTB_RUBI "
								cQry += " WHERE CRC_EMP = '"+cEmpAnt+"' "
								cQry += "   AND CRC_FIL = '"+xFilial("CT2")+"' "
								cQry += "   AND CRC_CODIGO = '"+aArrDados[1]+"' "
								
								TCQUERY cQry NEW ALIAS "QCN"
								
								If !Eof()
									aCols[Len(aCols)][nI]	:= Padr(QCN->CRC_CONTA,TamSX3(aHeader[nI][2])[1])
								Endif
								QCN->(DbCloseArea())
							Endif
						ElseIf Alltrim(aHeader[nI][2]) == "CT2_CREDIT"
							aCols[Len(aCols)][nI]	:= CriaVar(aHeader[nI][2],.T.)
							If aArrDados[8] == "C"
								cQry := "SELECT CRC_CONTA"
								cQry += "  FROM CONDOR_CONV_CTB_RUBI "
								cQry += " WHERE CRC_EMP = '"+cEmpAnt+"' "
								cQry += "   AND CRC_FIL = '"+xFilial("CT2")+"' "
								cQry += "   AND CRC_CODIGO = '"+aArrDados[1]+"' "
								
								TCQUERY cQry NEW ALIAS "QCN"
								
								If !Eof()
									aCols[Len(aCols)][nI]	:= Padr(QCN->CRC_CONTA,TamSX3(aHeader[nI][2])[1])
								Endif
								QCN->(DbCloseArea())
							Endif
						ElseIf Alltrim(aHeader[nI][2]) == "CT2_VALOR"
							aCols[Len(aCols)][nI]	:= CriaVar(aHeader[nI][2],.T.)
							aCols[Len(aCols)][nI]		:= Val(aArrDados[9])
						ElseIf Alltrim(aHeader[nI][2]) == "CT2_HIST"
							aCols[Len(aCols)][nI]	:= CriaVar(aHeader[nI][2],.T.)
							aCols[Len(aCols)][nI]		:= aArrDados[1]+"-"+aArrDados[2]+"- Cód."+QSA2->A2_NUMFUNC
						ElseIf Alltrim(aHeader[nI][2]) == "CT2_CCD"
							aCols[Len(aCols)][nI]	:= CriaVar(aHeader[nI][2],.T.)
							If aArrDados[8] == "D"
								If Posicione("CT1",1,xFilial("CT1")+aCols[Len(aCols)][nPxDEBITO],"CT1_ACCUST") == "1"
									aCols[Len(aCols)][nI]	:= QSA2->A2_CC
								Endif
							Endif
						ElseIf Alltrim(aHeader[nI][2]) == "CT2_CCC"
							aCols[Len(aCols)][nI] := CriaVar(aHeader[nI][2],.T.)
							If aArrDados[8] == "C"
								If Posicione("CT1",1,xFilial("CT1")+aCols[Len(aCols)][nPxCREDIT],"CT1_CCOBRG") == "1"
									aCols[Len(aCols)][nI]	:= QSA2->A2_CC
								Endif
							Endif
						ElseIf Alltrim(aHeader[nI][2]) == "CT2_DC"
							//aCols[Len(aCols)][nI]	:= CriaVar(aHeader[nI][2],.T.)
							aCols[Len(aCols)][nI]	:= Iif(aArrDados[8]=="D","1",Iif(aArrDados[8]=="C","2"," "))
						ElseIf Alltrim(aHeader[nI][2]) == "CT2_ORIGEM"
							aCols[Len(aCols)][nI] := Padr(QSA2->A2_NUMFUNC+"-"+QSA2->A2_NREDUZ,TamSX3(aHeader[nI][2])[1])
						Else
							aCols[Len(aCols)][nI] := CriaVar(aHeader[nI][2],.T.)
						Endif
					Else
						If aHeader[nI][10] $ "V#M"
							aCols[Len(aCols)][nI] := CriaVar(aHeader[nI][2],.T.)
						Else
							aCols[Len(aCols)][nI] := CriaVar(aHeader[nI][2],.T.)
						Endif
					Endif
				Next nI
				aCols[Len(aCols),Len(aHeader)+1]	:= .F.
			ElseIf Len(aArrDados) == 19
				If Select("QSA2") > 0
					QSA2->(DbCloseArea())
				Endif
				
				cLinha	:=  "000"
				
				cQry := "SELECT A2_COD,A2_LOJA,A2_NOME,A2_CC,A2_NREDUZ,A2_NUMFUNC "
				cQry += "  FROM "+RetSqlName("SA2")
				cQry += " WHERE D_E_L_E_T_ = ' ' "
				cQry += "   AND A2_MSBLQL <> '1' "
				cQry += "   AND A2_NUMFUNC = '"+StrZero(Val(aArrDados[1]),6) + "' "
				cQry += "   AND A2_FILIAL = '"+xFilial("SA2")+"' "
				
				TCQUERY cQry NEW ALIAS "QSA2"
				
				
				For nX := 1 To 6
					
					AADD(aCols,Array(Len(aHeader)+1))
					
					cLinha	:= Soma1(cLinha)
					
					For nI := 1 To Len(aHeader)
						If IsHeadRec(aHeader[nI][2])
							aCols[Len(aCols)][nI] := TRB->ZRRECNO
						ElseIf IsHeadAlias(aHeader[nI][2])
							aCols[Len(aCols)][nI] := "CT2"
						ElseIf ( aHeader[nI][10] <> "V") .AND. (aHeader[nI][08] <> "M")
							If Alltrim(aHeader[nI][2]) == "CT2_LINHA"
								aCols[Len(aCols)][nI]	:= cLinha
							ElseIf Alltrim(aHeader[nI][2]) == "CT2_DEBITO"
								aCols[Len(aCols)][nI]	:= CriaVar(aHeader[nI][2],.T.)
								aCols[Len(aCols)][nI]	:= Padr(aHist250[nX,2],TamSX3(aHeader[nI][2])[1])
							ElseIf Alltrim(aHeader[nI][2]) == "CT2_CREDIT"
								aCols[Len(aCols)][nI]	:= CriaVar(aHeader[nI][2],.T.)
								aCols[Len(aCols)][nI]	:= Padr(aHist250[nX,3],TamSX3(aHeader[nI][2])[1])
							ElseIf Alltrim(aHeader[nI][2]) == "CT2_VALOR"
								aCols[Len(aCols)][nI]	:= CriaVar(aHeader[nI][2],.T.)
								aCols[Len(aCols)][nI]		:= Val(aArrDados[nX+12])
							ElseIf Alltrim(aHeader[nI][2]) == "CT2_HIST"
								aCols[Len(aCols)][nI]	:= CriaVar(aHeader[nI][2],.T.)
								aCols[Len(aCols)][nI]	:= StrZero(nX,2)+"-"+aHist250[nX,1]
							ElseIf Alltrim(aHeader[nI][2]) == "CT2_CCD"
								aCols[Len(aCols)][nI]	:= CriaVar(aHeader[nI][2],.T.)
								aCols[Len(aCols)][nI]	:= QSA2->A2_CC
							ElseIf Alltrim(aHeader[nI][2]) == "CT2_CCC"
								aCols[Len(aCols)][nI] := CriaVar(aHeader[nI][2],.T.)
								//							aCols[Len(aCols)][nI]	:= QSA2->A2_CC
							ElseIf Alltrim(aHeader[nI][2]) == "CT2_DC"
								//aCols[Len(aCols)][nI]	:= CriaVar(aHeader[nI][2],.T.)
								aCols[Len(aCols)][nI]	:= "3"
							ElseIf Alltrim(aHeader[nI][2]) == "CT2_ORIGEM"
								aCols[Len(aCols)][nI] := Padr(QSA2->A2_NUMFUNC+"-"+QSA2->A2_NREDUZ,TamSX3(aHeader[nI][2])[1])
							Else
								aCols[Len(aCols)][nI] := CriaVar(aHeader[nI][2],.T.)
							Endif
						Else
							If aHeader[nI][10] $ "V#M"
								aCols[Len(aCols)][nI] := CriaVar(aHeader[nI][2],.T.)
							Else
								aCols[Len(aCols)][nI] := CriaVar(aHeader[nI][2],.T.)
							Endif
						Endif
					Next nI
					aCols[Len(aCols),Len(aHeader)+1]	:= .F.
				Next
				
			Endif
			DbSelectArea("TRB")
			DbSkip()
		Enddo
		
		TRB->(DbCloseArea())
		If Select("QSA2") > 0
			QSA2->(DbCloseArea())
		Endif
		// FErase(cNomArq + GetDbExtension()) // Deleting file
		// FErase(cNomArq + OrdBagExt()) // Deleting index
		
	Endif
	
	If Len(aCols) == 0
		AADD(aCols,Array(Len(aHeader)+1))
		For nColuna := 1 to Len( aHeader )
			
			If aHeader[nColuna][8] == "C"
				aCols[Len(aCols)][nColuna] := Space(aHeader[nColuna][4])
			ElseIf aHeader[nColuna][8] == "D"
				aCols[Len(aCols)][nColuna] := dDataBase
			ElseIf aHeader[nColuna][8] == "M"
				aCols[Len(aCols)][nColuna] := ""
			ElseIf aHeader[nColuna][8] == "N"
				aCols[Len(aCols)][nColuna] := 0
			Else
				aCols[Len(aCols)][nColuna] := .F.
			Endif
			If !Empty(aHeader[nColuna][12])
				aCols[Len(aCols)][nColuna] := &(aHeader[nColuna][12])
			Endif
			If Alltrim(aHeader[nColuna][2]) == "CT2_LINHA"
				aCols[Len(aCols)][nColuna]	:= "001"
			Endif
			
		Next nColuna
		aCols[Len(aCols),Len(aHeader)+1]	:= .F.
	Endif
	
	If Type("oMulti") <> "U"
		oMulti:oBrowse:Refresh()
		sfAtuRodp()
	Endif
	
Return



/*/{Protheus.doc} GMCTBMV1
(Valida a digitação dos campos do GetDados de pre lançamento)
@author MarceloLauschner
@since 14/06/2012
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function GMCTBMV1()
	
	Local		lRet		:= .T.
	Local		aAreaOld	:= GetArea()
	
	If ReadVar() == "M->CT2_CREDIT"
		cDescEnt	:= Posicione("CT1",1,xFilial("CT1")+M->CT2_CREDIT,"CT1_DESC01")
		If CT1->CT1_CLASSE == "1" //1=Sintetica;2=Analitica
			MsgAlert("Não é permitido digitar conta sintética para lançamentos!","Conta Sintética")
			lRet	:= .F.
		Endif
		oDescEnt:Refresh()
	ElseIf ReadVar() == "M->CT2_DEBITO"
		cDescEnt	:= Posicione("CT1",1,xFilial("CT1")+M->CT2_DEBITO,"CT1_DESC01")
		If CT1->CT1_CLASSE == "1" //1=Sintetica;2=Analitica
			MsgAlert("Não é permitido digitar conta sintética para lançamentos!","Conta Sintética")
			lRet	:= .F.
		Endif
		oDescEnt:Refresh()
	ElseIf ReadVar() == "M->CT2_CCD"
		cDescEnt	:= Posicione("CTT",1,xFilial("CTT")+M->CT2_CCD,"CTT_DESC01")
		If CTT->CTT_CLASSE == "1" //1=Sintetica;2=Analitica
			MsgAlert("Não é permitido digitar conta sintética para lançamentos!","Conta Sintética")
			lRet	:= .F.
		Endif
		oDescEnt:Refresh()
	ElseIf ReadVar() == "M->CT2_CCC"
		cDescEnt	:= Posicione("CTT",1,xFilial("CTT")+M->CT2_CCC,"CTT_DESC01")
		If CTT->CTT_CLASSE == "1" //1=Sintetica;2=Analitica
			MsgAlert("Não é permitido digitar conta sintética para lançamentos!","Conta Sintética")
			lRet	:= .F.
		Endif
		oDescEnt:Refresh()
	ElseIf ReadVar() == "M->CT2_DC"
		lRet := Pertence("123")
	ElseIf ReadVar() == "M->CT2_VALOR"
		lRet	:= M->CT2_VALOR > 0
	ElseIf ReadVar() == "M->CONTA"
		oConvGet:aCols[oConvGet:nAt,nPxDescCT]	:= Posicione("CT1",1,xFilial("CT1")+M->CONTA,"CT1_DESC01")
		If CT1->CT1_CLASSE == "1" //1=Sintetica;2=Analitica
			MsgAlert("Não é permitido digitar conta sintética para lançamentos!","Conta Sintética")
			lRet	:= .F.
		Endif
	ElseIf ReadVar() == "M->XCODIGO"
		For ip := 1 To Len(oConvGet:aCols)
			If ip # oConvGet:nAt
				If M->XCODIGO == oConvGet:aCols[ip,nPxCod]
					MsgAlert("Já há um cadastro de conversão para este CLC ->'"+M->XCODIGO+"'. Favor verificar!","Duplicidade de CLC")
					lRet	:= .F.
					Exit
				Endif
			Endif
		Next
	Endif
	
	RestArea(aAreaOld)
	
Return lRet



/*/{Protheus.doc} GMCTBMV2
(Valida a linha do GetDados de pré lançamentos  )
@author MarceloLauschner
@since  14/06/2012
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function GMCTBMV2()
	
	Local		lRet		:= .T.
	Local		aAreaOld	:= GetArea()
	
	If !oMulti:aCols[oMulti:nAt,Len(oMulti:aHeader)+1]
		If oMulti:aCols[oMulti:nAt,nPxDC] == "1" // Debito
			If !Empty(oMulti:aCols[oMulti:nAt,nPxCREDIT])
				lRet	:= .F.
				MsgAlert("Lançamento a débito com conta a crédito preenchida!","Erro de lançamento")
			ElseIf Empty(oMulti:aCols[oMulti:nAt,nPxDEBITO])
				lRet	:= .F.
				MsgAlert("Lançamento a débito sem conta a débito preenchida!","Erro de lançamento")
			Endif
		ElseIf oMulti:aCols[oMulti:nAt,nPxDC] == "2"
			If Empty(oMulti:aCols[oMulti:nAt,nPxCREDIT])
				lRet	:= .F.
				MsgAlert("Lançamento a crédito sem conta a crédito preenchida!","Erro de lançamento")
			ElseIf !Empty(oMulti:aCols[oMulti:nAt,nPxDEBITO])
				lRet	:= .F.
				MsgAlert("Lançamento a crédito com conta a débito preenchida!","Erro de lançamento")
			Endif
		ElseIf oMulti:aCols[oMulti:nAt,nPxDC] == "3"
			If Empty(oMulti:aCols[oMulti:nAt,nPxCREDIT])
				lRet	:= .F.
				MsgAlert("Lançamento a partida dobrada sem conta a crédito preenchida!","Erro de lançamento")
			ElseIf Empty(oMulti:aCols[oMulti:nAt,nPxDEBITO])
				lRet	:= .F.
				MsgAlert("Lançamento a partida dobrada sem conta a débito preenchida!","Erro de lançamento")
			Endif
		Else
			lRet	:= .F.
			MsgAlert("Opção invÁlido no campo 'Tipo de Lançamento'","Tipo de Lançamento")
		Endif
	Endif
	
	RestArea(aAreaOld)
	
Return lRet



/*/{Protheus.doc} sfAtuRodp
(Atualiza Rodape da tela de Pré Lançamentos     )
@author MarceloLauschner
@since 14/06/2012
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfAtuRodp()
	
	aTotRdpe 	:= {{0,0,0,0},{0,0,0,0}}
	
	For nX := 1 To Len(oMulti:aCols)
		If !oMulti:aCols[nX,Len(oMulti:aHeader)+1] .And.(!Empty(oMulti:aCols[nX,nPxDEBITO]) .Or. !Empty(oMulti:aCols[nX,nPxCREDIT]))
			If oMulti:aCols[nX,nPxDC] $"1#3"
				aTotRdPe[1,2]	+= oMulti:aCols[nX,nPxVALOR]
			Endif
			If oMulti:aCols[nX,nPxDC] $"2#3"
				aTotRdPe[1,3]	+= oMulti:aCols[nX,nPxVALOR]
			Endif
			aTotRdPe[1,1]	+= oMulti:aCols[nX,nPxVALOR]
		Endif
	Next
	
	oDeb:Refresh()
	oDig:Refresh()
	oCred:Refresh()
	
Return .T.



/*/{Protheus.doc} sfCadConv
(Interface para conversão CLC´s do Rubi para Contas CT2 )
@author MarceloLauschner
@since 14/06/2012
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfCadConv()
	
	Local	aHeadConv	:= {}
	Local	aColsConv	:= {}
	Local 	cCampo 		:= ""
	
	DEFINE MSDIALOG oDlgConv TITLE OemToAnsi("Cadastro de Conversões de Códigos de Lançamento do Rubi para Contas Contábeis do Protheus") From aSize[7],0 to aSize[6],aSize[5] OF oMainWnd PIXEL
	
	oDlgConv:lMaximized := .T.
	
	oPanel1 := TPanel():New(0,0,'',oDlgConv, oDlgConv:oFont, .T., .T.,, ,200,35,.T.,.T. )
	oPanel1:Align := CONTROL_ALIGN_TOP
	
	oPanel2 := TPanel():New(0,0,'',oDlgConv, oDlgConv:oFont, .T., .T.,, ,200,40,.T.,.T. )
	oPanel2:Align := CONTROL_ALIGN_ALLCLIENT
	
	Aadd(aHeadConv,{"Seq"				,	"SEQ"			,   "@!"     			,	02,	0,"",,	"C","",""})
	Aadd(aHeadConv,{"Código"			,	"XCODIGO"		,   "@!"     			,	04,	0,"",,	"C","",""})
	Private nPxCod    	:= 2
	Aadd(aHeadConv,{"Descrição Código"	,	"XDESCRICAO"	,   "@!"     			,	40,	0,"",,	"C","","R"})
	Private nPxDesc 	:= 3
	
	cCampo := "CT2_DEBITO"

	Aadd(aHeadConv,{	"Conta Contábil"	,;
		"CONTA"	 							,;
		GetSx3Cache(cCampo,"X3_PICTURE")	,;
		GetSx3Cache(cCampo,"X3_TAMANHO")	,;
		GetSx3Cache(cCampo,"X3_DECIMAL")	,;
		""									,;
		 									,;
		"C"									,;
		GetSx3Cache(cCampo,"X3_F3")			,;
		""})

	Private nPxConta	    := 4
	cCampo	:= "CT1_DESC01"
	Aadd(aHeadConv,{"Descrição Conta" ,	"DESCCONTA"	, GetSx3Cache(cCampo,"X3_PICTURE"),	GetSx3Cache(cCampo,"X3_TAMANHO"), GetSx3Cache(cCampo,"X3_DECIMAL"),"",,	"C","",""})
	Private nPxDescCT	    := 5
	
	sfMontaCols(@aColsConv)
	
	DEFINE FONT oFnt 	NAME "Arial" SIZE 0, -11 BOLD
	
	//@ 012 ,005  	Say OemToAnsi("Data Lançamento") SIZE 30,9 PIXEl OF oPanel1 FONT oFnt					//"Data"
	//@ 011 ,023  	MSGET dDataLanc  Picture "99/99/9999" PIXEl SIZE 55, 10 OF oPanel1 HASBUTTON
	
	//@ 012 ,083   	Say OemToAnsi("Arquivo") SIZE 30,9 PIXEl	OF oPanel1 FONT oFnt 				//"Lote"
	//@ 011 ,121		MSGET oArqIMp VAR cArqImp Picture "@!" PIXEl SIZE 132, 10 OF oPanel1 Valid (cArqImp := cGetFile( "Todos os Arquivos (*.*) | *.*", "Selecione o Arquivo para importa folha",,"C:\EDI\",.T., ),Processa({|| sfCarrega(@oMulti:aCols,@oMulti:aHeader,2)},"Carregando dados..."))
	
	
	Private oConvGet := MsNewGetDados():New(034, 005, 226, 415,GD_INSERT+GD_DELETE+GD_UPDATE,"AllwaysTrue()"/*cLinhaOk*/,;
		"AllwaysTrue()"/*cTudoOk*/,"+SEQ",;
		,1/*nFreeze*/,10000/*nMax*/,"U_GMCTBMV1()"/*cCampoOk*/,/*cSuperApagar*/,;
		/*cApagaOk*/,oPanel2,@aHeadConv,@aColsConv,)
	
	oConvGet:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	
	
	ACTIVATE MSDIALOG oDlgConv ON INIT (oConvGet:oBrowse:Refresh(),EnchoiceBar(oDlgConv,{|| Processa({||sfGravaConv(),},"Gerando lançamentos contábeis..."),oDlgConv:End()},{|| oDlgConv:End()},,))
	
Return



/*/{Protheus.doc} sfMontaCols
(Monta o aCols do GetDados de Conversao dos CLC´s para CT2 )
@author MarceloLauschner
@since 14/06/2012
@version 1.0
@param aColsConv, array, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfMontaCols(aColsConv)
	
	Local	cQry	:= ""
	Local	cItem	:= "01"
	
	If PSWADMIN(,,__CUSERID)==0  .And. MsgYesNo("Criar tabela de controle?")
		
		cQry := 'CREATE TABLE "CONDOR_CONV_CTB_RUBI" '
		cQry += '  ("CRC_EMP" 		CHAR(2) NOT NULL,'
		cQry += '	"CRC_FIL"		CHAR(2) NOT NULL,'
		cQry += '	"CRC_CODIGO" 	CHAR(4) NOT NULL,'
		cQry += '	"CRC_DESCRI"	CHAR(40) NOT NULL,'
		cQry += '	"CRC_CONTA" 	CHAR('+AllTrim(Str(TamSX3("CT1_CONTA")[1]))+') NOT NULL,'
		cQry += '	"CRC_DESCCT"	CHAR(40) NOT NULL)'
		
		TcSQLExec(cQry)
		
	Endif
	
	cQry := ""
	cQry += "SELECT CRC_CODIGO,CRC_DESCRI,CRC_CONTA,CRC_DESCCT "
	cQry += "  FROM CONDOR_CONV_CTB_RUBI "
	cQry += " WHERE CRC_EMP = '"+cEmpAnt+"' "
	cQry += "   AND CRC_FIL = '"+xFilial("CT2")+"' "
	cQry += " ORDER BY CRC_CODIGO "
	
	TCQUERY cQry NEW ALIAS "QRB"
	
	
	While !Eof()
		Aadd(aColsConv,{	cItem,;
			QRB->CRC_CODIGO,;
			QRB->CRC_DESCRI,;
			QRB->CRC_CONTA,;
			QRB->CRC_DESCCT,;
			.F.})
		cItem	:= Soma1(cItem)
		QRB->(DbSkip())
	Enddo
	QRB->(DbCloseArea())
	
	If Len(aColsConv) == 0
		AADD(aCols,Array(6))
		aCols[Len(aCols)][1]	:= "01"
		aCols[Len(aCols)][2]	:= Space(4)
		aCols[Len(aCols)][3]	:= Space(40)
		aCols[Len(aCols)][4]	:= CriaVar("CT1_CONTA",.T.)
		aCols[Len(aCols)][5]	:= CriaVar("CT1_DESC01",.T.)
		aCols[Len(aCols)][6]	:= .F.
	Endif
	
Return


/*/{Protheus.doc} sfGravaConv
(Grava na tabela sem SX3 os dados CLC´s X CT2 )
@author MarceloLauschner
@since 14/06/2012
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfGravaConv()
	
	Local	cQry := ""
	
	For nX := 1 To Len(oConvGet:aCols)
		
		If !oConvGet:aCols[nX,Len(oConvGet:aHeader)+1] .And. !Empty(oConvGet:aCols[nX,nPxCod])
			cQry := "SELECT COUNT(*) NEXIST "
			cQry += "  FROM CONDOR_CONV_CTB_RUBI "
			cQry += " WHERE CRC_EMP = '"+cEmpAnt+"' "
			cQry += "   AND CRC_FIL = '"+xFilial("CT2")+"' "
			cQry += "   AND CRC_CODIGO = '"+oConvGet:aCols[nX,nPxCod]+"' "
			
			TCQUERY cQry NEW ALIAS "QCN"
			
			If !Eof() .And. QCN->NEXIST > 0
				cQry := "UPDATE CONDOR_CONV_CTB_RUBI "
				cQry += "   SET CRC_DESCRI ='"+oConvGet:aCols[nX,nPxDesc]+"' "
				cQry += "      ,CRC_CONTA = '"+oConvGet:aCols[nX,nPxConta]+"' "
				cQry += "      ,CRC_DESCCT = '"+oConvGet:aCols[nX,nPxDescCT]+"' "
				cQry += " WHERE CRC_EMP = '"+cEmpAnt+"' "
				cQry += "   AND CRC_FIL = '"+xFilial("CT2")+"' "
				cQry += "   AND CRC_CODIGO = '"+oConvGet:aCols[nX,nPxCod]+"' "
			Else
				cQry := "INSERT INTO CONDOR_CONV_CTB_RUBI "
				cQry += "		(CRC_EMP,"
				cQry += "		 CRC_FIL,"
				cQry += "		 CRC_CODIGO,"
				cQry += "		 CRC_DESCRI,"
				cQry += "		 CRC_CONTA,"
				cQry += "		 CRC_DESCCT)
				cQry += " VALUES ( "
				cQry += "'"+cEmpAnt+"',"
				cQry += "'"+xFilial("CT2")+"',"
				cQry += "'"+oConvGet:aCols[nX,nPxCod]+"', "
				cQry += "'"+oConvGet:aCols[nX,nPxDesc]+"', "
				cQry += "'"+oConvGet:aCols[nX,nPxConta]+"', "
				cQry += "'"+oConvGet:aCols[nX,nPxDescCT]+"') "
			Endif
			QCN->(DbCloseArea())
			
			TcSqlExec(cQry)
		Else
			cQry := "SELECT COUNT(*) NEXIST "
			cQry += "  FROM CONDOR_CONV_CTB_RUBI "
			cQry += " WHERE CRC_EMP = '"+cEmpAnt+"' "
			cQry += "   AND CRC_FIL = '"+xFilial("CT2")+"' "
			cQry += "   AND CRC_CODIGO = '"+oConvGet:aCols[nX,nPxCod]+"' "
			
			TCQUERY cQry NEW ALIAS "QCN"
			
			If !Eof() .And. QCN->NEXIST > 0
				cQry := "DELETE FROM CONDOR_CONV_CTB_RUBI "
				cQry += " WHERE CRC_EMP = '"+cEmpAnt+"' "
				cQry += "   AND CRC_FIL = '"+xFilial("CT2")+"' "
				cQry += "   AND CRC_CODIGO = '"+oConvGet:aCols[nX,nPxCod]+"' "
			Endif
			QCN->(DbCloseArea())
			
			TcSqlExec(cQry)
			
		Endif
	Next
	
Return
