#include "rwmake.ch"
#include "protheus.ch"
/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±                         ROTINAS DO EDI 					                ±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡„o    ³ EdiValCgc³ Autor ³ Gildesio Campos       ³ Data ³30.10.2003³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡„o ³ Retorna .T. ou .F. na validacao do CGC/CPF                 ³±±
±±³          ³ Se retornar .T. CGC ou CPF Valido                          ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ cCgcCpf                                                    ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³ EDI                                                        ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
User Function EdiValCgc(cCGC,nTpRet,nMsg)

Local nCnt,i,j,cDVC,nSum,nDIG,cDIG:=cCGC1:=''

cCGC := EDICgc(cCgc)   // Elimina caracteres nao numericos do CGC
cCGC1:= cCGC

nTpRet:= If(nTpRet==NIL,0,nTpRet)
nMsg  := If(nMsg==NIL,0,nMsg)

If cCgc == '00000000000000'
	Return(cCgc)
Endif

nTamanho:=Len(AllTrim(cCGC))

If nTamanho == 14 .And. Substr(cCGC,1,3) == "000"
	cCGC1 := Substr(cCGC,4)          	//  Utiliza para calculo do DV do CPF
EndIf

cDVC:=AllTrim(SubStr(cCGC,13,2))
cCGC:=AllTrim(SubStr(cCGC,1,12))

FOR j := 12 TO 13
	nCnt := 1
	nSum := 0
	
	FOR i := j TO 1 Step -1
		nCnt++
		IF nCnt > 9
			nCnt := 2
		EndIf
		nSum +=(Val(SubStr(cCGC,i,1))*nCnt)
	Next i
	nDIG := IIF((nSum%11) < 2,0,11-(nSum%11))
	cCGC := cCGC+STR(nDIG,1)
	cDIG := cDIG+STR(nDIG,1)
Next j

/* Se lRet = .T. - CGC VALIDO */
lRet := IIF(cDIG == cDVC,.T.,.F.)

/* Se lRet = .F. - Valida CPF */
IF !lRet
	nTamanho := Len(AllTrim(Substr(cCGC1,1,11)))
	cCGC     := AllTrim(Substr(cCGC1,1,11))
	
	IF nTamanho < 14
		cDVC := SubStr(cCGC,10,2)
		cCPF := SubStr(cCGC, 1,9)
		cDIG:=''
		
		FOR j := 10 TO 11
			nCnt:= j
			nSum:= 0
			
			For i:= 1 To Len(Trim(cCPF))
				nSum += (Val(SubStr(cCPF,i,1))*nCnt)
				nCnt--
			Next i
			
			nDIG:=IIF((nSum%11)<2,0,11-(nSum%11))
			cCPF:=cCPF+STR(nDIG,1)
			cDIG:=cDIG+STR(nDIG,1)
		Next j
		
		lRet:=IIF(cDIG==cDVC,.T.,.F.)
		IF lRet
			cCGC := cCPF    //+Space(3)
			cRet := "F"
		Else   // CPF/CGC INVALIDO
			cCgc := ""
		EndIF
	EndIF
Else
	cRet := "J"
EndIF

If lRet
	If nTpRet <> 0
		If nTpRet == 1 //-- Codigo
			cCGC := SubStr(cCGC,1,8)
		ElseIf nTpRet == 2 //-- Loja
			cCGC := SubStr(cCGC,9,4)
		Else
			cCGC := cRet //-- Tipo de Pessoa
		EndIf
	EndIf
Else
	If nMsg == 1	//Exibe Mensagem informando o numero da nota
		cNomeDes := Alltrim(Substr(__cEDILinTxt,4,35))
		cInscCli := Substr(__cEDILinTxt,39,14)
		
		//		FT_FSKIP() //-- Salta para a proxima linha no arquivo texto sendo importado
		//		__cEDILinTxt := AllTrim(FT_FREADLN())
		//		cNumNFC  := Substr(__cEDILinTxt,35,6)  //Right(__xEdiCont,6)
		//		FT_FSKIP(-1) //-- Volta para linha anterior
		//		__cEDILinTxt := AllTrim(FT_FREADLN())
		
		MsgBox("Cliente: " + cNomeDes + " Cpf/Cgc: "+cInscCli,"Nota Fiscal nao importada","INFO")
	EndIf
EndIf

Return(cCGC)

/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡„o    ³EdiTipoCli³ Autor ³ Eduardo de Souza      ³ Data ³ 01/03/04 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡„o ³ Retorna o Tipo de Cliente                                  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ ExpC1 - Estado do Cliente                                  ³±±
±±³          ³ ExpC2 - Incricao do Cliente                                ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³ EDI                                                        ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
User Function EdiTipoCli(cEstado,cInscricao,cTipo)

Local cRet := If(cTipo=="J","R","F")

If cTipo == "J" .And. AllTrim(cEstado) == "SP"
	If !Empty(AllTrim(cInscricao)) .And. Upper(AllTrim(cInscricao)) <> "ISENTO"
		cRet := "R"
	Else
		cRet := "F"
	EndIf
EndIf

Return cRet

/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡„o    ³EDICgc    ³ Autor ³ Gildesio Campos       ³ Data ³ 15/03/04 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡„o ³ Elimina caracteres do CGC                                  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³                                                            ³±±
±±³          ³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³ EDI                                                        ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Static Function EDICgc( cCgc )

Local cRet := StrTran( cCgc, "", "." )
//cRet := StrTran( cCgc, " ", ".")
cRet := StrTran( cCgc, ".", "" )
cRet := StrTran( cRet, "/", "" )
cRet := StrTran( cRet, "-", "" )

Return( cRet )
/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³EDICDRDES ³ Autor ³ Edson Ito             ³ Data ³24/05/2005³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Retorna o codigo da regiao destino  A1_CDRDES, caso nao    ³±±
±±³          ³ exista, inclui na Tabela Municipio X Regiao                ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ EDICDRDES()                                                ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ EDI                                                        ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
User Function EDICDRDES(_cMunic,_cEst,_cCep)

Local _cRet
Local _cArea := GetArea()     
Local   cQuery    := ""    

_cMunic:=_cMunic+Space(TamSx3("DUY_DESCRI")[1]-Len(_cMunic))

cAliasDUY := GetNextAlias()
cQuery := "SELECT DUY_GRPVEN"
cQuery += " FROM "+RetSqlName("DUY")+ " DUY "
cQuery += " WHERE DUY_FILIAL = '"+xFilial("DUY")+"'"
cQuery += "   AND DUY_DESCRI = '"+_cMunic+"'"
cQuery += "   AND DUY_EST	 = '"+_cEst+"'"
cQuery += "   AND DUY_CATGRP = '3'"
cQuery += "   AND D_E_L_E_T_ = ' '"
cQuery := ChangeQuery(cQuery)
dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasDUY)
If (cAliasDUY)->(!Eof()) 
	_cRet:=(cAliasDUY)->DUY_GRPVEN
EndIf

If Empty(_cRet) // obtem o codigo no cadastro de municipio e estados
	_cRet := Posicione("DEA",2,XFILIAL("DEA")+_cEst+NoAcento(Ansitooem(Upper(_cMunic))),"DEA_CDRDES")
Endif
If Empty(_cRet)
	DbSelectArea("DEA")
	DbSetOrder(2)
	DbSeek(xFilial("DEA")+_cEst+NoAcento(Ansitooem(Upper(_cMunic))))
	If Eof()
		RecLock("DEA",.T.)
		DEA->DEA_MUN  := NoAcento(Ansitooem(Upper(_cMunic)))
		DEA->DEA_EST  := _cEst
		MsUnLock()
	Endif
Endif

RestArea(_cArea)
Return (_cRet)
/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³EDICDRDES ³ Autor ³ Edson Ito             ³ Data ³24/05/2005³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Retorna o codigo da regiao destino  A1_CDRDES, caso nao    ³±±
±±³          ³ exista, inclui na Tabela Municipio X Regiao                ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ EDICDRDES()                                                ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ EDI                                                        ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
User Function EDIREGCEP(_cCep)
Local aArea     := GetArea()
Local aAreaDUY  := DUY->(GetArea())
Local _cRet     := Space(Len(SA1->A1_CDRDES))
Local cAliasDUY := "" 
Local cQuery    := ""

cAliasDUY := GetNextAlias()
cQuery := "SELECT DUY_GRPVEN "
cQuery += "  FROM " + RetSqlName("DUY") + " DUY "

cQuery += " WHERE DUY_FILIAL     = '" + xFilial("DUY") + "' "
cQuery += "   AND DUY_XCEPI     <= '" + _cCep + "' "
cQuery += "   AND DUY_XCEPF     >= '" + _cCep + "' "
cQuery += "   AND DUY_CATGRP     = '3' "
cQuery += "   AND DUY.D_E_L_E_T_ = ' '"

cQuery := ChangeQuery(cQuery)
DBUseArea(.t.,"TOPCONN",TCGENQRY(,,cQuery),cAliasDUY,.t.,.t.)

If !(cAliasDUY)->(Eof())
	_cRet := (cAliasDUY)->DUY_GRPVEN
EndIf

RestArea(aAreaDUY)
RestArea(aArea)

Return (_cRet)

/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³EDIVlrDt8 ³ Autor ³ Edson Ito             ³ Data ³ 01/10/07 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Retorna o valor total dos conhecimentos                    ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ Utilizado no layout do Mercador                            ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
User Function EDIVlrDt8()
Local _cquery    := ""
Local _nVlrTot   := 0
Local _cAliasDT8 := GetNextAlias()
Local aAreaDT8   := DT8->(GetArea())
Local aAreaDT6   := DT6->(GetArea())

_cQuery := "SELECT SUM(DT8.DT8_VALTOT) VALTOT, SUM(DT8.DT8_VALPAS) VALPAS"
_cQuery += " FROM "+RetSqlName("DT8")+ " DT8 JOIN "+RetSqlName("DT6")+" DT6 ON DT6.DT6_FILIAL = '"+xFilial("DT6")+"'"
_cQuery += " AND DT8.DT8_FILDOC = DT6.DT6_FILDOC AND DT8.DT8_DOC = DT6.DT6_DOC AND DT8.DT8_SERIE = DT6.DT6_SERIE "
_cQuery += " WHERE DT6.DT6_DATEMI >= '"+ Dtos(MV_PAR07) +"' AND DT6.DT6_DATEMI <= '"+ Dtos(MV_PAR08)+"'"
_cQuery += " AND DT6.DT6_CLIDEV >= '"+ MV_PAR01 +"' AND DT6.DT6_CLIDEV <= '"+ MV_PAR03+"'"
_cQuery += " AND DT6.DT6_LOJDEV = '"+ DEC->DEC_LOJCLI +"'"
_cQuery += " AND DT6.DT6_FILORI = '" + cFilAnt +"'"
_cQuery += " AND DT6.DT6_NUM >= '"+ MV_PAR05+"' AND DT6.DT6_NUM <= '" + MV_PAR06+"'"
_cQuery += " AND DT6.DT6_SERIE <> 'PED' AND DT6.DT6_SERIE <> 'DAC' AND DT6.DT6_SERIE <> 'COL' AND DT8.DT8_CODPAS = 'TF' "
_cQuery += " AND DT8.D_E_L_E_T_ = ' ' AND DT6.D_E_L_E_T_ = ' '"

_cQuery := ChangeQuery(_cQuery)
dBUseArea(.t.,"TOPCONN",TCGENQRY(,,_cQuery),_cAliasDT8,.t.,.t.)
DbSelectArea(_cAliasDT8)
If Eof()  // quando importados do Sitla os registros nao sao gravados no DT8
	(_cAliasDT8)->(dbCloseArea())
	_cAliasDT8 := GetNextAlias()
	_cQuery := "SELECT SUM(DT6.DT6_VALTOT) VALTOT "
	_cQuery += "FROM "+RetSqlName("DT6")+" DT6 " 
	_cQuery += "WHERE DT6.DT6_FILIAL = '"+xFilial("DT6")+"'"
	_cQuery += " AND DT6.DT6_DATEMI >= '"+ Dtos(MV_PAR07) +"' AND DT6.DT6_DATEMI <= '"+ Dtos(MV_PAR08)+"'"
	_cQuery += " AND DT6.DT6_CLIDEV >= '"+ MV_PAR01 +"' AND DT6.DT6_CLIDEV <= '"+ MV_PAR03+"'"
	_cQuery += " AND DT6.DT6_LOJDEV = '"+ DEC->DEC_LOJCLI +"'"
	_cQuery += " AND DT6.DT6_FILORI = '" + cFilAnt +"'"
	_cQuery += " AND DT6.DT6_SERIE <> 'PED' AND DT6.DT6_SERIE <> 'DAC' AND DT6.DT6_SERIE <> 'COL' "
	_cQuery += " AND DT6.D_E_L_E_T_ = ' '"
	_cQuery := ChangeQuery(_cQuery)
	dBUseArea(.t.,"TOPCONN",TCGENQRY(,,_cQuery),_cAliasDT8,.t.,.t.)
EndIf

_nVlrTot   := (_cAliasDT8)->VALTOT

(_cAliasDT8)->(dbCloseArea())

RestArea ( aAreaDT8 )
RestArea ( aAreaDT6 )

Return(_nVlrTot)

/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³EDIQtdDt8 ³ Autor ³ Edson Ito             ³ Data ³ 01/10/07 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Retorna a quantidade de conhecimentos                      ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ Utilizado no layout do Mercador                            ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
User Function EDIQtdDt8()

Local _cquery    := ""
Local _nQtdTot   := 0
Local _cAliasDT6 := GetNextAlias()
Local aAreaDT6   := DT6->(GetArea())

_cQuery := "SELECT COUNT(*) QTDE"
_cQuery += " FROM " +RetSqlName("DT6")+" DT6 "
_cQuery += " WHERE DT6.DT6_FILIAL = '" +xFilial("DT6")+"'"
_cQuery += " AND DT6.DT6_DATEMI >= '"+ Dtos(MV_PAR07) +"' AND DT6.DT6_DATEMI <= '"+ Dtos(MV_PAR08)+"'"
_cQuery += " AND DT6.DT6_CLIDEV >= '"+ MV_PAR01 +"' AND DT6.DT6_CLIDEV <= '"+ MV_PAR03+"'"
_cQuery += " AND DT6.DT6_LOJDEV =  '"+ DEC->DEC_LOJCLI +"'"
_cQuery += " AND DT6.DT6_FILORI = '" + cFilAnt +"'"
_cQuery += " AND DT6.DT6_NUM >= '"+ MV_PAR05+"' AND DT6.DT6_NUM <= '" + MV_PAR06+"'"
_cQuery += " AND DT6.DT6_SERIE <> 'PED' AND DT6.DT6_SERIE <> 'DAC' AND DT6.DT6_SERIE <> 'COL'"
_cQuery += " AND DT6.D_E_L_E_T_ = ' '"

_cQuery := ChangeQuery(_cQuery)
dBUseArea(.t.,"TOPCONN",TCGENQRY(,,_cQuery),_cAliasDT6,.t.,.t.)

_nQtdTot   := (_cAliasDT6)->QTDE

(_cAliasDT6)->(dbCloseArea())

RestArea ( aAreaDT6 )

Return(_nQtdTot)

/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ LCompFre ³ Autor ³ Edson Ito             ³ Data ³ 10/01/08 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Retorno do valor do frete baseado no componente passado    ³±±
±±³          ³ como parametro                                             ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ Exp1 - 1 = Valor Sem Imposto                               ³±±
±±³          ³ Exp2 - 2 = Valor Com Imposto                               ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³                                                            ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
User Function LCompFre(_nV,_ColImp)

Local _cQuery    := ""
Local _nQtdTot   := 0
Local _cAliasDT8 := GetNextAlias()
Local aAreaDT3   := DT3->(GetArea())
Local aAreaDT6   := DT6->(GetArea())
Local aAreaDT8   := DT8->(GetArea())
Local aAreaSD2	 := SD2->(GetArea())
Local aAreaSF2	 := SF2->(GetArea())
Local aAreaSF4	 := SF4->(GetArea())

DbSelectArea("SD2")
DbSetOrder(3)
DbSeek(DT6->DT6_FILDOC+DT6->DT6_DOC+DT6->DT6_SERIE+DT6->DT6_CLIDEV+DT6->DT6_LOJDEV)

DbSelectArea("SF4")
DbSetOrder(1)
DbSeek(xFilial("SF4")+SD2->D2_TES)
If SF4->F4_ICMSST = "1"  // 1-Sim
	_cQuery  := "SELECT DT8.DT8_CODPAS,DT8.DT8_VALPAS VALFRETE,DT8.DT8_VALTOT VALTOTAL"
Else
	_cQuery  := "SELECT DT8.DT8_CODPAS,DT8.DT8_VALTOT VALFRETE "
EndIf
_cQuery  += "FROM "+ RetSqlName("DT8")+ " DT8 "
_cQuery  += "JOIN "+ RetSqlName("DT3")+ " DT3 "
_cQuery  += "ON DT3.DT3_CODPAS = DT8.DT8_CODPAS "
_cQuery  += "AND DT3.DT3_TIPCMP IN ('"+_ColImp+"') "
_cQuery  += "WHERE DT3.DT3_FILIAL = DT8.DT8_FILIAL "
_cQuery  += "AND DT8.DT8_FILDOC = '"+DT6->DT6_FILDOC+"' "
_cQuery  += "AND DT8.DT8_DOC    = '"+DT6->DT6_DOC+"' "
_cQuery  += "AND DT8.DT8_SERIE  = '"+DT6->DT6_SERIE+"' "
_cQuery  += "AND DT8.D_E_L_E_T_ = ' ' "
_cQuery  += "AND DT8.DT8_CODPAS <> 'TF' "
_cQuery  += "AND DT3.D_E_L_E_T_ = ' ' "
//_cQuery  += "GROUP BY DT8.DT8_CODPAS,DT8.DT8_VALPAS"
_cQuery := ChangeQuery(_cQuery)
dBUseArea(.t.,"TOPCONN",TCGENQRY(,,_cQuery),_cAliasDT8,.t.,.t.)
DbSelectArea(_cAliasDT8)
While !Eof()
	If SF4->F4_ICMSST = "1"
		If _nV = 2 // Valor com Imposto
			_nQtdTot += (_cAliasDT8)->VALTOTAL
		Else
			_nQtdTot += (_cAliasDT8)->VALFRETE
		EndIf
	Else
		_nQtdTot += (_cAliasDT8)->VALFRETE
	EndIf
	DbSkip()
EndDo	

(_cAliasDT8)->(dbCloseArea())

RestArea ( aAreaDT3 )
RestArea ( aAreaDT6 )
RestArea ( aAreaDT8 )
RestArea ( aAreaSD2 )
RestArea ( aAreaSF2 )
RestArea ( aAreaSF4 )

Return(_nQtdTot)

/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ VlrICMS  ³ Autor ³ Edson Ito             ³ Data ³ 21/01/08 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Retorno do valor de ICMS e Aliquota da Substituicao        ³±±
±±³          ³ Tributaria                                                 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ Exp  - 1 = Valor ICMS, 2 = Aliquota,  3 = Base ICMS        ³±±
±±³          ³        4 = Subst.Trib.,5 = Frete Liq ou Bruto              ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ Iharabras                                                  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
User Function VlrICMS(_nOpc)

Local _cQuery	:= ""
Local _nQtdTot	:= 0
Local _nBsIcms	:= 0
Local _nAlqIcm	:= 0
Local _nVlIcms	:= 0
Local _nRetInf	:= 0
Local _nRetInf	:= ''
Local aAreaSD2	:= SD2->(GetArea())
Local aAreaSF2	:= SF2->(GetArea())
Local aAreaSF4	:= SF4->(GetArea())

DbSelectArea("SD2")
DbSetOrder(3)
DbSeek(DT6->DT6_FILDOC+DT6->DT6_DOC+DT6->DT6_SERIE+DT6->DT6_CLIDEV+DT6->DT6_LOJDEV)

DbSelectArea("SF4")
DbSetOrder(1)
DbSeek(xFilial("SF4")+SD2->D2_TES)

If SF4->F4_ICMSST = "1"
	If _nOpc = 1 // Valor ICMS
		DbSelectArea("SF2")
		DbSetOrder(1)
		DbSeek(DT6->DT6_FILDOC+DT6->DT6_DOC+DT6->DT6_SERIE+DT6->DT6_CLIDEV+DT6->DT6_LOJDEV)
		If SF2->F2_ICMSRET > 0 .OR. SF2->F2_VALICM > 0
			_nVlIcms := Iif(SF2->F2_ICMSRET>0,SF2->F2_ICMSRET,SF2->F2_VALICM)
		EndIf
		_nRetInf := _nVlIcms
	ElseIf _nOpc = 2 // Aliquota ICMS
		DbSelectArea("SD2")
		DbSetOrder(3)
		DbSeek(DT6->DT6_FILDOC+DT6->DT6_DOC+DT6->DT6_SERIE+DT6->DT6_CLIDEV+DT6->DT6_LOJDEV)
		If (((SD2->D2_PRUNIT/SD2->D2_VALBRUT)*100)-100)*(-1) <= 0
			_nAlqIcm := 0
		Else
			_nAlqIcm := ROUND(100+((SD2->D2_PRUNIT/SD2->D2_VALBRUT)*(-100)),0)
		EndIf
		_nRetInf := _nAlqIcm
	ElseIf _nOpc = 3 // Base ICMS
		DbSelectArea("SF2")
		DbSetOrder(1)
		DbSeek(DT6->DT6_FILDOC+DT6->DT6_DOC+DT6->DT6_SERIE+DT6->DT6_CLIDEV+DT6->DT6_LOJDEV)
		If SF2->F2_BASEICM > 0
			_nBsIcms := SF2->F2_BASEICM
		Else
			If SF2->F2_BRICMS <> 0
				_nBsIcms := SF2->F2_BRICMS
			EndIf
		EndIf
		_nRetInf := _nBsIcms
	EndIf
Else
	_nRetInf := 0
	If _nOpc = 1 // Valor ICMS
		DbSelectArea("SF2")
		DbSetOrder(1)
		DbSeek(DT6->DT6_FILDOC+DT6->DT6_DOC+DT6->DT6_SERIE+DT6->DT6_CLIDEV+DT6->DT6_LOJDEV)
		If SF2->F2_VALICM > 0
			_nVlIcms := SF2->F2_VALICM
		EndIf
		_nRetInf := _nVlIcms
	ElseIf _nOpc = 2 // Aliquota ICMS
		DbSelectArea("SD2")
		DbSetOrder(3)
		DbSeek(DT6->DT6_FILDOC+DT6->DT6_DOC+DT6->DT6_SERIE+DT6->DT6_CLIDEV+DT6->DT6_LOJDEV)
		If SD2->D2_VALICM <> 0
			_nAlqIcm := Round(SD2->D2_VALICM/SD2->D2_TOTAL,2)*100
		Else
			If (((SD2->D2_PRUNIT/SD2->D2_VALBRUT)*100)-100)*(-1) <= 0
				_nAlqIcm := 0
			Else
				_nAlqIcm := ROUND(100+((SD2->D2_PRUNIT/SD2->D2_VALBRUT)*(-100)),0)
			EndIf
		EndIf
		_nRetInf := _nAlqIcm
	ElseIf _nOpc = 3 // Base ICMS
		DbSelectArea("SF2")
		DbSetOrder(1)
		DbSeek(DT6->DT6_FILDOC+DT6->DT6_DOC+DT6->DT6_SERIE+DT6->DT6_CLIDEV+DT6->DT6_LOJDEV)
		If SF2->F2_BASEICM > 0
			_nBsIcms := SF2->F2_BASEICM
		Else
			If SF2->F2_BRICMS <> 0
				_nBsIcms := SF2->F2_VALMERC
			EndIf
		EndIf
		_nRetInf := _nBsIcms
	EndIf	
EndIf
If _nOpc = 4 // Substituicao Tributaria?
//	msgstop("Opcao "+ Str(_nOpc,1)+"Tes "+ SD2->D2_TES+" ICMS ST "+SF4->F4_ICMSST,"Atencao")
	_nRetInf := " "
	If SF4->F4_ICMSST = "1"
		_nRetInf := "1" // 1-Sim
	Else
		_nRetInf := "2" // 2-Nao
	EndIf
EndIf

If _nOpc = 5 // Frete Liquido ou Frete Bruto em funcao da Substituicao Tributaria.
	If SF4->F4_ICMSST = "1"
		_nRetInf := DT6->DT6_VALFRE
	Else
		_nRetInf := DT6->DT6_VALTOT
	EndIf
EndIf

RestArea ( aAreaSD2 )
RestArea ( aAreaSF2 )
RestArea ( aAreaSF4 )

Return(_nRetInf)

/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ FtVlIcms ³ Autor ³ Edson Ito             ³ Data ³ 21/01/08 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Retorno do valor de ICMS da Substituicao Tributaria        ³±±
±±³          ³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ ALTERADA POR ALEXANDRE FREITAS-CRIADO VETOR _aRet 21/12/12³±±
±±³          ³ _aRet[1] = VALOR TOTAL DOC - VALOR TOTAL FRETE             ³±±
±±³          ³ _aRet[2] = TOIAL DE DOCUMENTOS                             ³±±
±±³          ³ _aRet[3] = TOTAL DO VALOR ICMS                             ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ Iharabras                                                  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
User Function FtVlIcms()

Local _cQuery    := ""
Local _nQtdTot   := 0
Local _aRet		 := {}
Local _cAliasSE1 := GetNextAlias()
Local _aAreaDT6  := DT6->(GetArea())
Local _aAreaSE1  := SE1->(GetArea())

_cQuery  := "SELECT Count(DT6.DT6_DOC) as TOTDOC, Sum(DT6.DT6_VALTOT) VALTOT, Sum(DT6.DT6_VALFRE) VALFRE, Sum(DT6.DT6_VALIMP) VALIMP"
_cQuery  += "FROM "+ RetSqlName("DT6")+ " DT6 INNER JOIN "+ RetSqlName("SE1")+ " SE1 "
_cQuery  += "ON SE1.E1_FILIAL = '"+xFilial("SE1")+"' AND SE1.E1_CLIENTE = DT6.DT6_CLIDEV AND SE1.E1_LOJA = DT6.DT6_LOJDEV "
_cQuery  += "AND SE1.E1_PREFIXO = DT6.DT6_PREFIX AND SE1.E1_NUM = DT6.DT6_NUM AND SE1.E1_TIPO = DT6.DT6_TIPO AND SE1.D_E_L_E_T_ =  ' ' "
_cQuery  += "WHERE DT6.DT6_FILIAL = '" + xFilial("DT6")+"' "
//_cQuery  += "AND SE1.E1_CLIENTE BETWEEN '"+DEC->DEC_CODCLI+"' AND '"+DEC->DEC_CODCLI+"' "
//_cQuery  += "AND SE1.E1_LOJA    BETWEEN '"+DEC->DEC_LOJCLI+"' AND '"+DEC->DEC_LOJCLI+"' "
_cQuery  += "AND SE1.E1_CLIENTE BETWEEN '"+MV_PAR01+"' AND '"+MV_PAR03+"' "
_cQuery  += "AND SE1.E1_LOJA    BETWEEN '"+MV_PAR02+"' AND '"+MV_PAR04+"' "
_cQuery  += "AND DT6.DT6_NUM    = '"+SE1->E1_NUM+"' "
_cQuery  += "AND DT6.DT6_PREFIX = '"+SE1->E1_PREFIXO+"' "
_cQuery  += "AND DT6.DT6_TIPO   = '"+SE1->E1_TIPO+"' "
_cQuery  += "AND DT6.D_E_L_E_T_ = ' ' "
_cQuery  += "AND SE1.D_E_L_E_T_ = ' ' "
_cQuery := ChangeQuery(_cQuery)
dBUseArea(.t.,"TOPCONN",TCGENQRY(,,_cQuery),_cAliasSE1,.t.,.t.)
_nQtdTot   := (_cAliasSE1)->VALTOT - (_cAliasSE1)->VALFRE
                   
Aadd(_aRet,_nQtdTot)
Aadd(_aRet,(_cAliasSE1)->TOTDOC)
Aadd(_aRet,(_cAliasSE1)->VALIMP)

(_cAliasSE1)->(dbCloseArea())

RestArea ( _aAreaDT6 )
RestArea ( _aAreaSE1 )

Return(_aRet)


/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ FtVlIcms ³ Autor ³ Edson Ito             ³ Data ³ 21/01/08 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Retorno do valor de ICMS da Substituicao Tributaria        ³±±
±±³          ³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³                                                            ³±±
±±³          ³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ Iharabras                                                  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
User Function FtVlLiq()

Local _cQuery    := ""
Local _nValLiq   := 0
Local _cAliasSE1 := GetNextAlias()
Local _aAreaDT6  := DT6->(GetArea())
Local _aAreaSE1  := SE1->(GetArea())

_cQuery  := "SELECT Sum(DT6_VALTOT) VALTOT, Sum(DT6_VALFRE) VALFRE "
_cQuery  += "FROM "+ RetSqlName("DT6")+ " DT6 LEFT JOIN "+ RetSqlName("SE1")+ " SE1 "
_cQuery  += "ON E1_FILIAL = '"+xFilial("SE1")+"' AND E1_CLIENTE = DT6_CLIDEV AND E1_LOJA = DT6_LOJDEV "
_cQuery  += "AND E1_PREFIXO = DT6_PREFIX AND E1_NUM = DT6_NUM AND E1_TIPO = DT6_TIPO AND SE1.D_E_L_E_T_ =  ' ' "
_cQuery  += "WHERE DT6.DT6_FILIAL = '" + xFilial("DT6")+"' "
_cQuery  += "AND SE1.E1_CLIENTE BETWEEN '"+DEC->DEC_CODCLI+"' AND '"+DEC->DEC_CODCLI+"' "
//_cQuery  += "AND SE1.E1_LOJA    BETWEEN '"+DEC->DEC_LOJCLI+"' AND '"+DEC->DEC_LOJCLI+"' "
_cQuery  += "AND DT6.DT6_NUM    = '"+SE1->E1_NUM+"' "
_cQuery  += "AND DT6.DT6_PREFIX = '"+SE1->E1_PREFIXO+"' "
_cQuery  += "AND DT6.DT6_TIPO   = '"+SE1->E1_TIPO+"' "
_cQuery  += "AND DT6.D_E_L_E_T_ = ' ' "
_cQuery  += "AND SE1.D_E_L_E_T_ = ' ' "
_cQuery := ChangeQuery(_cQuery)
dBUseArea(.t.,"TOPCONN",TCGENQRY(,,_cQuery),_cAliasSE1,.t.,.t.)
_nValLiq   := (_cAliasSE1)->VALFRE

(_cAliasSE1)->(dbCloseArea())

RestArea ( _aAreaDT6 )
RestArea ( _aAreaSE1 )

Return(_nValLiq)


/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³EDICODPRO ³ Autor ³ Edson Ito             ³ Data ³02/03/2006³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Retorna Codigo de Produto                                  ³±±
±±³          ³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ EDICODPRO()                                                ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ _cCodPro = Codigo do Produto ou Descricao                  ³±±
±±³          ³ _cTipo = 1-Pesquisa pelo Codigo 2-Pesquisa pela Descricao  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ EDI                                                        ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
User Function EDICODPRO(_cCodPro,_cTipo)

Local _cQuery    := ""
Local _cCodCli   := ""
Local _cAliasDE7 := GetNextAlias()
Local cProdut    := SuperGetMV("ES_PRODDIG",,"")

_cQuery := "SELECT * "
_cQuery += "FROM "+RetSqlName("DE7") + " DE7"
_cQuery += " WHERE "
_cQuery += "DE7.DE7_CODCLI = '"+DEC->DEC_CODCLI +"' AND "
_cQuery += "DE7.DE7_LOJCLI = '"+DEC->DEC_LOJCLI +"' AND "
If _ctipo = "1"  // Codigo
   _cQuery += "DE7.DE7_PRDEMB = '"+_cCodPro +"' AND "
Else // Descricao
   _cQuery += "DE7.DE7_DSCEMB IN "+"('"+_cCodPro+"')"+" AND "
EndIf
_cQuery += "DE7.D_E_L_E_T_ <> '*'"
_cQuery := ChangeQuery(_cQuery)
dBUseArea(.t.,"TOPCONN",TCGENQRY(,,_cQuery),_cAliasDE7,.t.,.t.)
(_cAliasDE7)->(DbGoBottom())
If (_cAliasDE7)->(!Bof())
   _cCodCli := (_cAliasDE7)->DE7_CODPRO
EndIf

_cCodCli := Iif(Empty(_cCodCli),cProdut,_cCodCli)

(_cAliasDE7)->(dbCloseArea())
DbSelectArea("DE7")

Return(_cCodCli)

/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ValCodLoj ³ Autor ³ Edson Ito             ³ Data ³ 11/02/08 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Verifica Codigo e Loja do Cliente para efetuar a Inclusao  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ Cliente Syngenta                                           ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
User Function ValCodLoj(_nCod,_nPos)  //1-Codigo  2-Loja

Local lRet       := ""
Local _acAreaSA1 := SA1->(GetArea())
Local _cCgcCpf   := SubStr(__CEDILINTXT,_nPos,14)

DbSelectArea("SA1")
DbSetOrder(3) // A1_FILIAL+A1_CGC
If DbSeek(xFilial("SA1")+_cCgcCpf,.T.)	
	_cCodigo := SA1->A1_COD
	_cLoja 	 := SA1->A1_LOJA
		If _nCod = 1	// Codigo
		lRet := _cCodigo
	Else			// Loja
		lRet := _cLoja
	EndIf  
ElseIf DbSeek(xFilial("SA1")+Substr(_cCgcCpf,4,11),.T.)	
	_cCodigo := SA1->A1_COD
	_cLoja 	 := SA1->A1_LOJA
	If _nCod = 1	// Codigo
		lRet := _cCodigo
	Else			// Loja
		lRet := _cLoja
	EndIf
ElseIf DbSeek(xFilial("SA1")+SubStr(_cCgcCpf,1,8),.T.)
	// Verifica se o Cliente ja esta cadastrado com o principal do CNPJ
	If SubStr(_cCgcCpf,1,8) = SubStr(SA1->A1_CGC,1,8)
		_cCodigo := SA1->A1_COD
		If Len(Alltrim(_cCgcCpf)) < 14
			_cLoja := "01"
		Else
			_cLoja := substr(_cCgcCpf,11,2)
		EndIf
	Else
		// Pega o Ultimo Codigo do Cliente
		_cCodigo := GetSx8Num("SA1","A1_COD")
		If Len(Alltrim(_cCgcCpf)) < 14
			_cLoja := "01"
		Else
			_cLoja := substr(_cCgcCpf,11,2)
		EndIf
	EndIf
	If _nCod = 1	// Codigo
		lRet := _cCodigo
	Else			// Loja
		lRet := _cLoja
	EndIf
Else
	If _nCod = 1	// Codigo
    	lRet := Substr(_cCgcCpf,1,8)
    	
    ElseIf _nCod = 2	// Loja
    	lRet := Substr(_cCgcCpf,9,4)
    EndIf	
EndIf

RestArea ( _acAreaSA1 )
Return lRet
/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ EdiVdOc3 ³ Autor ³ Edson Ito             ³ Data ³ 26/02/08 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Valida data do EDI para Ocorrencias                        ³±±
±±³          ³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ EdiVdOc3()                                                 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ Envio / Recebimento (EDI)                                  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
User Function EdiVdOc3(_MvPar10)

Local lRet      := .T.
Local lContinua := .F.
Local aArea     := GetArea()
Local aAreaDUA  := DUA->(GetArea())

DbSelectArea("DUA")
DbSetOrder(4)
If MsSeek(xFilial("DUA")+DT6->DT6_FILDOC+DT6->DT6_DOC+DT6->DT6_SERIE)
	If DUA->DUA_SERTMS == "3"
		If _MvPar10 = 2 // NAO enviado
			If Empty(DUA->DUA_DATEDI)
				lRet := .T.
			Else
				lRet := .F.
			EndIf
		Else
			lRet := .T.
		EndIf
	Else
		lRet := .F.
	EndIf
EndIf

RestArea ( aArea    )
RestArea ( aAreaDUA )

Return lRet

/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ EdiVdOc4 ³ Autor ³ Edson Ito             ³ Data ³ 04/03/08 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Valida se existem ocorrencias para o Cliente, Nota Fiscal  ³±±
±±³          ³ De/Ate e Agrupamento de CNPJ, conforme parametros.         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ EdiVdOc4()                                                 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ Envio / Recebimento (EDI)                                  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
User Function EdiVdOc4()

Local lRet      	:=  .F.
Local lContinua 	:=  .F.
Local aAreaDTC  	:=  DTC->(GetArea())
Local aAreaDT6  	:=  DT6->(GetArea())
Local aAreaDUD  	:=  DUD->(GetArea())

If !Empty(DUA->DUA_FILDOC) .And. !Empty(DUA->DUA_DOC) .And. !Empty(DUA->DUA_SERIE)
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Verifica Cliente De / Ate.     				     	³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	DbSelectArea("DT6")
	DbSetOrder(1)
	If MsSeek(xFilial("DT6")+DUA->DUA_FILDOC+DUA->DUA_DOC+DUA->DUA_SERIE)
		If !(DT6->DT6_CLIREM == DEC->DEC_CODCLI)
			If mv_par09 == 1 // Agrupamento de CNPJ
				DbSelectArea("SA1")
				DbSetOrder(1)
				If MsSeek(xFilial("SA1")+DEC->DEC_CODCLI)
					DbSelectArea("DE4")
					DbSetOrder(1)
					If MsSeek(xFilial("DE4")+SA1->A1_CGC)
						While DE4->(!Eof()) .And. DE4->DE4_FILIAL + DE4->DE4_CNPJ == xFilial("DE4") + SA1->A1_CGC
							DbSelectArea("SA1")
							DbSetOrder(3)
							If MsSeek(xFilial("SA1")+DE4->DE4_CNPJ1)
								If SA1->A1_COD == DT6->DT6_CLIREM
									lContinua := .t.
								EndIf
							EndIf
							DbSelectArea("DE4")
							DbSkip()
						EndDo
					EndIf
				EndIf
			EndIf
		Else
			DbSelectArea("SA1")
			DbSetOrder(1)
			If MsSeek(xFilial("SA1")+DT6->DT6_CLIREM)
				lContinua := .T.
			EndIf
		EndIf
		If lContinua
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Verifica Nota Fiscal De / Ate.						³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			DbSelectArea("DTC")
			DbSetOrder(3)
			If MsSeek(xFilial("DTC")+DT6->DT6_FILDOC+DT6->DT6_DOC+DT6->DT6_SERIE)
				While DTC->(!Eof()) .And. DTC->DTC_FILIAL + DTC->DTC_FILDOC + DTC->DTC_DOC + DTC->DTC_SERIE == ;
					xFilial("DTC") + DT6->DT6_FILDOC + DT6->DT6_DOC + DT6->DT6_SERIE
					If DTC->DTC_NUMNFC >= mv_par05 .And. DTC->DTC_NUMNFC <= mv_par06
						lRet := .T.
						Exit
					EndIf
					
					DbSelectArea("DTC")
					DbSkip()
				EndDo
			EndIf
		EndIf
	EndIf
Else
	DbSelectArea("DUD")
	DbSetOrder(2)
	If MsSeek(xFilial("DUD")+DUA->DUA_FILORI+DUA->DUA_VIAGEM)
		While DUD->(!Eof()) .And. DUD->DUD_FILIAL + DUD->DUD_FILORI + DUD->DUD_VIAGEM == xFilial("DUD") + DUA->DUA_FILORI + DUA->DUA_VIAGEM
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Verifica Cliente De / Ate.     				     	³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			DbSelectArea("DT6")
			DbSetOrder(1)
			If MsSeek(xFilial("DT6")+DUD->DUD_FILDOC+DUD->DUD_DOC+DUD->DUD_SERIE)
				If !(DT6->DT6_CLIREM == DEC->DEC_CODCLI)
					If mv_par09 == 1 // Agrupamento de CNPJ
						DbSelectArea("SA1")
						DbSetOrder(1)
						If MsSeek(xFilial("SA1")+DEC->DEC_CODCLI)
							DbSelectArea("DE4")
							DbSetOrder(1)
							If MsSeek(xFilial("DE4")+SA1->A1_CGC)
								While DE4->(!Eof()) .And. DE4->DE4_FILIAL + DE4->DE4_CNPJ == xFilial("DE4") + SA1->A1_CGC
									DbSelectArea("SA1")
									DbSetOrder(3)
									If MsSeek(xFilial("SA1")+DE4->DE4_CNPJ1)
										If SA1->A1_COD == DT6->DT6_CLIREM
											lContinua := .t.
										EndIf
									EndIf
									DbSelectArea("DE4")
									DbSkip()
								EndDo
							EndIf
						EndIf
					EndIf
				Else
					DbSelectArea("SA1")
					DbSetOrder(1)
					If MsSeek(xFilial("SA1")+DT6->DT6_CLIREM)
						lContinua := .T.
					EndIf
				EndIf
				If lContinua
					//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
					//³ Verifica Nota Fiscal De / Ate.						³
					//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
					DbSelectArea("DTC")
					DbSetOrder(3)
					If MsSeek(xFilial("DTC")+DT6->DT6_FILDOC+DT6->DT6_DOC+DT6->DT6_SERIE)
						While DTC->(!Eof()) .And. DTC->DTC_FILIAL + DTC->DTC_FILDOC + DTC->DTC_DOC + DTC->DTC_SERIE == ;
							xFilial("DTC") + DT6->DT6_FILDOC + DT6->DT6_DOC + DT6->DT6_SERIE
							If DTC->DTC_NUMNFC >= mv_par05 .And. DTC->DTC_NUMNFC <= mv_par06
								lRet := .T.
								Exit
							EndIf
							DbSelectArea("DTC")
							DbSkip()
						EndDo
					EndIf
				EndIf
			EndIf
			DbSelectArea("DUD")
			DbSkip()
		EndDo
	EndIf
EndIf

RestArea ( aAreaDTC )
RestArea ( aAreaDT6 )
RestArea ( aAreaDUD )

Return lRet

/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ EdiVdOc5 ³ Autor ³ Edson Ito             ³ Data ³ 11/03/08 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Verificacao em Ocorrencia do Cliente Basf                  ³±±
±±³          ³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ EdiVdOc5()                                                 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³                                                            ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
User Function EdiVdOc5()

Local _lRet      	:= .F.
Local _cQuery 		:= ""
Local _cAliasDUA	:= GetNextAlias()
Local aAreaDTC  	:= DTC->(GetArea())
Local aAreaDT6  	:= DT6->(GetArea())
Local aAreaDUA 		:= DUA->(GetArea())

If !Empty(DUA->DUA_FILDOC) .And. !Empty(DUA->DUA_DOC) .And. !Empty(DUA->DUA_SERIE) .and. Alltrim(DUA->DUA_SERIE)='U'
	_cQuery :="SELECT DUA.DUA_FILDOC,DUA.DUA_DOC,DUA.DUA_SERIE,DTC.DTC_LOTNFC,DTC.DTC_XOTO,DT6.DT6_FILDOC FIL,DT6.DT6_DOC DOC,DT6.DT6_SERIE SER,"
	_cQuery +="DTC.DTC_NUMNFC,DTC.DTC_EMINFC,DT6.DT6_PRZENT,DUA.DUA_DATOCO,DUA.DUA_HOROCO,DUA.DUA_RECEBE,DUA.DUA_CODOCO"
	_cQuery +=" FROM " + RetSqlName("DTC") + " DTC"
	_cQuery +=" JOIN " + RetSqlName("DUA") +" DUA"
	_cQuery +=" ON DUA.DUA_FILDOC  = DTC.DTC_FILDOC"
	_cQuery +="	AND DUA.DUA_DOC	   = DTC.DTC_DOC"
	_cQuery +="	AND DUA.DUA_SERIE  = DTC.DTC_SERIE"
	_cQuery +=" AND DUA.DUA_CODOCO = 'E001'"
	_cQuery +="	AND DUA.DUA_FILIAL = '" + xFilial("DUA") + "' "
	_cQuery +="	AND DUA.D_E_L_E_T_ = ' '"
	_cQuery +=" JOIN " + RetSqlName("DT6") +" DT6 ON DTC.DTC_FILDOC = DT6.DT6_FILDOC"
	_cQuery +="	AND DT6.DT6_DOC	   = DTC.DTC_DOC"
	_cQuery +="	AND DT6.DT6_SERIE  = DTC.DTC_SERIE"
	_cQuery +="	AND DT6.DT6_TIPFRE = '1'"
	_cQuery +="	AND DT6.D_E_L_E_T_ = ' '"
	_cQuery +=" WHERE DT6.DT6_FILIAL = '" + xFilial("DT6") + "' "
	_cQuery +=" AND DT6.DT6_CLIDEV = '"+DEC->DEC_CODCLI+ "'"        //IN ("+Alltrim(_cCodCli)+") "
	_cQuery +=" AND DUA.DUA_DATOCO BETWEEN '" + Dtos(MV_PAR07) +"' AND '" + Dtos(MV_PAR08) + "' "
	_cQuery +=" AND DT6.DT6_FILDOC = '"+DUA->DUA_FILDOC +"'"
	_cQuery +=" AND DT6.DT6_DOC	   = '"+DUA->DUA_DOC    +"'"
	_cQuery +=" AND DT6.DT6_SERIE  = '"+DUA->DUA_SERIE  +"'"
	_cQuery +=" AND DUA.DUA_CODOCO = 'E001'"
	_cQuery +=" AND DTC.D_E_L_E_T_ = ' '"
	_cQuery +=" ORDER BY DTC.DTC_FILDOC,DTC.DTC_DOC"
	_cQuery := ChangeQuery(_cQuery)
	DBUseArea(.t.,"TOPCONN",TCGENQRY(,,_cQuery),_cAliasDUA,.t.,.t.)
	DbSelectArea(_cAliasDUA)
	DbGoTop()
	If !Eof()
		_lRet := .T.
	Else
		_lRet := .F.
	EndIf
	(_cAliasDUA)->(dbCloseArea())
EndIf

RestArea ( aAreaDTC )
RestArea ( aAreaDT6 )
RestArea ( aAreaDUA )

Return _lRet

/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ EdiVdDc1 ³ Autor ³ Edson Ito             ³ Data ³ 12/03/08 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Verificacao em Documento de Cobranca do Cliente Basf       ³±±
±±³          ³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ EdiVdDc1()                                                 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³                                                            ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
User Function EdiVdDC1()

Local _lRet      	:= .F.
Local _cQuery 		:= ""
Local _cAliasSE1	:= GetNextAlias()
Local aAreaDTC  	:= DTC->(GetArea())
Local aAreaDT6  	:= DT6->(GetArea())
Local aAreaSE1 		:= SE1->(GetArea())

_cQuery :="SELECT DT6.DT6_FILDOC,DT6.DT6_DOC,DT6.DT6_SERIE,DT6.DT6_PREFIX,DT6.DT6_NUM,DT6.DT6_TIPO,"
_cQuery +="SE1.E1_NUM,DTC.DTC_DOC,DTC.DTC_NUMNFC"
_cQuery +=" FROM " + RetSqlName("DT6") + " DT6"
_cQuery +=" JOIN " + RetSqlName("SE1") +" SE1"
_cQuery +=" ON DT6.DT6_FILIAL = SE1.E1_FILIAL"
_cQuery +="	AND DT6.DT6_PREFIX = SE1.E1_PREFIXO"
_cQuery +="	AND DT6.DT6_NUM = SE1.E1_NUM"
_cQuery +=" AND DT6.DT6_TIPO = SE1.E1_TIPO"
_cQuery +="	AND DT6.D_E_L_E_T_ = ' '"
_cQuery +=" JOIN " + RetSqlName("DTC") +" DTC "
_cQuery +=" ON DT6.DT6_FILDOC = DTC.DTC_FILDOC"
_cQuery +="	AND DT6.DT6_DOC	   = DTC.DTC_DOC"
_cQuery +="	AND DT6.DT6_SERIE  = DTC.DTC_SERIE"
_cQuery +=" WHERE DT6.DT6_FILIAL = '" + xFilial("DT6") + "'"
_cQuery +=" AND DT6.DT6_PREFIX = '"+SE1->E1_PREFIXO+ "'"
_cQuery +=" AND DT6.DT6_NUM = '" +SE1->E1_NUM+ "'"
_cQuery +=" AND DT6.DT6_TIPO = '"+SE1->E1_TIPO+"'"
_cQuery +=" AND DT6.DT6_DOCTMS IN ('2','8')"
_cQuery +=" AND SE1.D_E_L_E_T_ = ' '"
_cQuery +=" AND rtrim(SE1.E1_ORIGEM) = 'TMSA850'"
_cQuery +=" AND SE1.E1_SITFAT <> '3'"
_cQuery := ChangeQuery(_cQuery)
DBUseArea(.t.,"TOPCONN",TCGENQRY(,,_cQuery),_cAliasSE1,.t.,.t.)
DbSelectArea(_cAliasSE1)
DbGoTop()
If !Eof()
	_lRet := .T.
EndIf

(_cAliasSE1)->(dbCloseArea())

RestArea ( aAreaDTC )
RestArea ( aAreaDT6 )
RestArea ( aAreaSE1 )

Return _lRet

/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ FatICMS  ³ Autor ³ Edson Ito             ³ Data ³ 14/03/08 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Retorno do valor de ICMS baseado em Documentos de Cobranca ³±±
±±³          ³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ Basf                                                       ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
User Function FatICMS()

Local _nRet		 := 0
Local _cQuery    := ""
Local _cAliasSF2 := GetNextAlias()
Local _nQtdTot   := 0
Local _nValIcms	 := 0
Local _nRetIcms	 := 0
Local aAreaSD2   := SD2->(GetArea())
Local aAreaSF2   := SF2->(GetArea())
Local aAreaSF4   := SF4->(GetArea())
Local aAreaDT6   := DT6->(GetArea())

_cQuery := "SELECT Sum(SF2.F2_ICMSRET) ICMSRET, Sum(SF2.F2_VALICM) VALICM "
_cQuery += "FROM "+ RetSqlName("DT6") + " DT6 "
_cQuery += "JOIN "+ RetSqlName("SE1") + " SE1 "
_cQuery += "ON DT6.DT6_FILIAL = SE1.E1_FILIAL "
_cQuery += "AND DT6.DT6_PREFIX = SE1.E1_PREFIXO "
_cQuery += "AND DT6.DT6_NUM = SE1.E1_NUM "
_cQuery += "AND DT6.DT6_TIPO = SE1.E1_TIPO "
_cQuery += "AND DT6.D_E_L_E_T_ = ' ' "
_cQuery += "JOIN "+ RetSqlName("SF2") + " SF2 "
_cQuery += "ON SF2.F2_FILIAL = DT6.DT6_FILDOC "
_cQuery += "AND SF2.F2_DOC = DT6.DT6_DOC "
_cQuery += "AND SF2.F2_SERIE = DT6.DT6_SERIE "
_cQuery += "WHERE DT6.DT6_FILIAL = '"+xFilial("DT6")+ "' "
_cQuery += "AND DT6.DT6_DOCTMS IN ('2','8') "
_cQuery += "AND SE1.E1_NUM = '" + SE1->E1_NUM +"' "
_cQuery += "AND SE1.D_E_L_E_T_ = ' ' "
_cQuery += "AND rtrim(SE1.E1_ORIGEM) = 'TMSA850' "
_cQuery += "AND SE1.E1_SITFAT <> '3' "  // Cancelado
_cQuery += "AND SF2.D_E_L_E_T_ = ' '
_cQuery := ChangeQuery(_cQuery)
DBUseArea(.t.,"TOPCONN",TCGENQRY(,,_cQuery),_cAliasSF2,.t.,.t.)
DbSelectArea(_cAliasSF2)
DbGoTop()
_nValIcms := (_cAliasSF2)->VALICM
_nRetIcms := (_cAliasSF2)->ICMSRET
If !Eof()
	If _nValIcms = 0
		_nRet := _nRetIcms
	Else
		_nRet := _nValIcms
	EndIf
EndIf

(_cAliasSF2)->(dbCloseArea())

RestArea ( aAreaSD2 )
RestArea ( aAreaSF2 )
RestArea ( aAreaSF4 )
RestArea ( aAreaDT6 )

Return(_nRet)

/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ CobrCgc  ³ Autor ³ Edson Ito             ³ Data ³ 14/03/08 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Retorna CGC do Cliente do CTRC baseado no Doc Entrada      ³±±
±±³          ³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³                                                            ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/

User Function CobrCgc()

Local lRet       := ""
Local _acAreaSA1 := SA1->(GetArea())
Local _acAreaDTC := DTC->(GetArea())

DbSelectArea("DTC")
DbSetOrder(3)
DbSeek(xFilial("DTC")+DUA->DUA_FILDOC+DUA->DUA_DOC+DUA->DUA_SERIE)

DbSelectArea("SA1")
DbSetOrder(1)  //A1_FILIAL+A1_COD+A1_LOJA
DbSeek(xFilial("SA1")+DTC->DTC_CLIDEV+DTC->DTC_LOJDEV)
If !Eof()
	lRet := SA1->A1_CGC
EndIf

RestArea ( _acAreaSA1 )
RestArea ( _acAreaDTC )

Return lRet

/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ RegGeral ³ Autor ³ Edson Ito             ³ Data ³ 24/04/08 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Regra Geral na condicao de Faturas                         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ Clientes                                                   ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
User Function RegGeral()

Local _lRet     := .T.
Local _cQuery	:= ""
Local _cAliasE1	:= GetNextAlias()

_cQuery := "SELECT DT6.DT6_FILDOC, DT6.DT6_DOC, DT6.DT6_SERIE,DT6.DT6_PREFIX,DT6.DT6_NUM,DT6.DT6_TIPO,SE1.E1_NUM"
_cQuery += " FROM " + RetSqlName("DT6") +" DT6"
_cQuery += " JOIN " + RetSqlName("SE1") +" SE1"
_cQuery += " ON DT6.DT6_FILIAL = SE1.E1_FILIAL"
_cQuery += " AND DT6.DT6_PREFIX = SE1.E1_PREFIXO"
_cQuery += " AND DT6.DT6_NUM = SE1.E1_NUM"
_cQuery += " AND DT6.DT6_TIPO = SE1.E1_TIPO"
_cQuery += " AND DT6.D_E_L_E_T_ = ' '"
_cQuery += " WHERE DT6.DT6_FILIAL = ' '"
_cQuery += " AND SE1.D_E_L_E_T_ = ' '"
_cQuery += " AND rtrim(SE1.E1_ORIGEM) = 'TMSA850'"
_cQuery += " AND SE1.E1_SITFAT <> '3'"
_cQuery += " AND SE1.E1_NUM = '"+ SE1->E1_NUM + "'"

_cQuery := ChangeQuery(_cQuery)
DBUseArea(.t.,"TOPCONN",TCGENQRY(,,_cQuery),_cAliasE1,.t.,.t.)
DbSelectArea(_cAliasE1)
DbGoTop()
If Eof()
	_lRet := .F.
EndIf

(_cAliasE1)->(dbCloseArea())

Return(_lRet)

/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ EDISQIDES³ Autor ³ Katia Alves Bianchi   ³ Data ³ 12/11/09 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Funcao para buscar sequencia de inscricao                  ³±±
±±³          ³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³                                                            ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
User Function EDISQIDES(_cCGC,_cInscr)

Local _cSequen:=""
Local cClides :=Posicione("SA1",3,xFilial("SA1")+_cCGC,"A1_COD")
Local cLojdes :=Posicione("SA1",3,xFilial("SA1")+_cCGC,"A1_LOJA")

DbSelectArea("DV3")
DV3->(DbSetOrder(2))
IF (DV3->(MsSeek(xFilial("DV3") +cClides+cLojdes+ Alltrim(_cInscr))))
	_cSequen:=DV3->DV3_SEQUEN			
EndIf

Return _cSequen

/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ValCodGef ³ Autor ³ Katia Alves Bianchi   ³ Data ³ 22/04/10 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Verifica Codigo e Loja do Cliente para efetuar a Inclusao  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ Gefco                                                      ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
User Function ValCodGef(_nCod,_nPos)  //1-Codigo  2-Loja

Local lRet       := ""
Local _acAreaSA1 := SA1->(GetArea())
Local _cCgcCpf   := SubStr(__CEDILINTXT,_nPos,14)

DbSelectArea("SA1")
DbSetOrder(3) // A1_FILIAL+A1_CGC
If DbSeek(xFilial("SA1")+_cCgcCpf,.T.)	
	_cCodigo := SA1->A1_COD
	_cLoja 	 := SA1->A1_LOJA
	If _nCod = 1	// Codigo
		lRet := _cCodigo
	Else			// Loja
		lRet := _cLoja
	EndIf  
ElseIf DbSeek(xFilial("SA1")+Substr(_cCgcCpf,4,11),.T.)	
	_cCodigo := SA1->A1_COD
	_cLoja 	 := SA1->A1_LOJA
	If _nCod = 1	// Codigo
		lRet := _cCodigo
	Else			// Loja
		lRet := _cLoja
	EndIf
Else
	If _nCod = 1	// Codigo
    	lRet := GetSx8Num("SA1","A1_COD")
    	ConfirmSx8()
    ElseIf _nCod = 2	// Loja
    	lRet := '01' //IF(SUBSTR(__CEDILINTXT,_nPos,3)='000','01',SUBSTR(__CEDILINTXT,_nPos+10,02))
    EndIf	
EndIf

RestArea ( _acAreaSA1 )
Return lRet

/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ SeqDigita³ Autor ³ Edson Ito             ³ Data ³ 10/01/11 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Retorna Sequencia de Digitacao para geracao e impressao    ³±±
±±³          ³ dos CTRC's(documentos)                                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³                                                            ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/

User Function SeqDigita(_cNotaSerie)

Local nSeqDigi	:= GetMv("ES_SEQDIGI")	// onde sera guardado numero crescente


Return      

/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³BuscaOco ³ Autor ³ Katia Bianchi         ³ Data ³04/11/2010³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Retorna a descricao da ocorrencia                          ³±±
±±³          ³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ BuscaOco()                                                ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ EDI                                                        ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
User Function BuscaOco(_cCodOco,_cCodMot)

Local _aRet		:= {}
Local _cCliGen	:= GetMv("MV_CLIGEN")
Local _cArea	:= GetArea()

IF Empty(_cCodMot)
	IF !EMPTY(POSICIONE("DE6",1,XFILIAL("DE6")+DEC->DEC_CODCLI+DEC->DEC_LOJCLI+_cCodOco,"DE6_OCOEMB"))
         //MsgAlert("1")
		Aadd(_aRet,DE6->DE6_DSCEMB)
		Aadd(_aRet,DE6->DE6_OCOEMB)
	ELseIf !EMPTY(POSICIONE("DE6",1,XFILIAL("DE6")+_cCliGen+_cCodOco,"DE6_OCOEMB"))
		Aadd(_aRet,DE6->DE6_DSCEMB)
		Aadd(_aRet,DE6->DE6_OCOEMB)
	Else
		Aadd(_aRet,POSICIONE("DT2",1,XFILIAL("DT2")+_cCodOco,"DT2_DESCRI"))
		Aadd(_aRet,"")
		//MsgAlert("2")
    EndIf
Else
	Aadd(_aRet,MSMM(DUA->DUA_CODMOT))
	Aadd(_aRet,"")
	//MsgAlert("3")                                         
EndIf

RestArea(_cArea) 

Return (_aRet)         

/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³EDICDIBGE ³ Autor ³ Katia Bianchi         ³ Data ³04/11/2010³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Retorna o codigo do IBGE informado na regiao de destino    ³±±
±±³          ³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ EDICDRDES()                                                ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ EDI                                                        ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
User Function EDICDIBGE(_cMunic,_cEst,_cCep)

Local _cRet
Local _cArea := GetArea()            


IF !Empty(_cCep)  //Busca Pelo CEP
	DbSelectArea("JC2") 
	DbSetOrder(1)
	If DbSeek(xFilial("JC2")+_cCep)
		_cRet := JC2->JC2_CODCID
	EndIf	
Else //Busca pelo Municipio
	_cMunic:=_cMunic+Space(TamSx3("DUY_DESCRI")[1]-Len(_cMunic))
	
	// obtem o codigo no cadastro de regiões
	DbSelectArea("DUY") 
	DbSetOrder(3)
	If DbSeek(xFilial("DUY")+NoAcento(Ansitooem(Upper(_cMunic)))+_cEst)
		While DUY->(!Eof()) .And. DUY->(DUY_FILIAL+DUY_DESCRI+DUY_EST)==xFilial("DUY")+NoAcento(Ansitooem(Upper(_cMunic)))+_cEst
			If DUY->DUY_CATGRP<>'1' .and. !Empty(DUY->DUY_CODMUN)
				_cRet := DUY->DUY_CODMUN
				RestArea(_cArea)
				Return (_cRet) 
			EndIf
			DbSelectArea("DUY")
			DbSkip()
		EndDo
	EndIf
EndIf

RestArea(_cArea)
Return (_cRet)      

/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³VldOcoren ³ Autor ³ Katia Bianchi         ³ Data ³19/05/2011³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Valida o tipo da ocorrência                                ³±±
±±³          ³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ VldOcoren()                                                ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ EDI                                                        ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
User Function VldOcoren(nTipo)
Local lRet    := .F.
Local _cArea := GetArea()
Default nTipo := 1

IF nTipo = 1	
	DT6->(DbsetOrder(1))
	IF DT6->(DBSEEK(xFilial("DT6")+DUA->DUA_FILDOC+DUA->DUA_DOC+DUA->DUA_SERIE))
		//IF DT6->DT6_CLIREM==MV_PAR01 .AND. DT6->DT6_LOJREM==MV_PAR02 
			DT2->(DbsetOrder(1))
			IF DT2->(DBSEEK(xFilial("DT2")+DUA->DUA_CODOCO))
				If DT2->DT2_TIPOCO<>"06" .and. DT2->DT2_TIPPND<>"04"
					lRet := .T.
				EndIf
			Endif  
		//Endif
	Endif
ElseIf nTipo = 2
	DT6->(DbsetOrder(1))
	IF DT6->(DBSEEK(xFilial("DT6")+DUA->DUA_FILDOC+DUA->DUA_DOC+DUA->DUA_SERIE))
		//IF DT6->DT6_CLIREM==MV_PAR01 .AND. DT6->DT6_LOJREM==MV_PAR02
			If !Empty(DT6->DT6_DOCDCO)
				cChave:=DT6->DT6_FILDCO+DT6->DT6_DOCDCO+DT6->DT6_SERDCO  
			Else
				cChave:=DT6->DT6_FILDOC+DT6->DT6_DOC+DT6->DT6_SERIE
			EndIf			
			DTC->(DbsetOrder(7))
			IF DTC->(DBSEEK(xFilial("DTC")+cChave+DTC->DTC_NUMNFC+DTC->DTC_SERNFC)) 
				If DTC->DTC_NFENTR=="1"
					lRet := .T.
				EndIf
			EndIf
		//Endif
	Endif
ElseIf nTipo = 3
		DT6->(DbsetOrder(1))
	IF DT6->(DBSEEK(xFilial("DT6")+DUA->DUA_FILDOC+DUA->DUA_DOC+DUA->DUA_SERIE))
		//IF DT6->DT6_CLIREM==MV_PAR01 .AND. DT6->DT6_LOJREM==MV_PAR02 
			DT2->(DbsetOrder(1))
			IF DT2->(DBSEEK(xFilial("DT2")+DUA->DUA_CODOCO))
				If DT2->DT2_TIPOCO=="06" //.and. DT2->DT2_TIPPND=="04"
					lRet := .T.
				EndIf
			Endif  
		//Endif
	Endif
ElseIf nTipo = 4	 
	DbSelectArea("DV4") 
	DV4->(DbsetOrder(1))
	IF DV4->(DBSEEK(xFilial("DV4")+DUA->DUA_FILOCO+DUA->DUA_NUMOCO+DUA->DUA_FILDOC+DUA->DUA_DOC+DUA->DUA_SERIE+DTC->DTC_NUMNFC+DTC->DTC_SERNFC))
			lRet := .T.
	Endif  	
ElseIf nTipo = 5	 
	DbSelectArea("DV4") 
	DV4->(DbsetOrder(1))
	IF !DV4->(DBSEEK(xFilial("DV4")+DUA->DUA_FILOCO+DUA->DUA_NUMOCO+DUA->DUA_FILDOC+DUA->DUA_DOC+DUA->DUA_SERIE+DTC->DTC_NUMNFC+DTC->DTC_SERNFC))
			lRet := .T.
	Endif 	
Endif
RestArea(_cArea)
RETURN lRet
/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³NoPontos  ºAutor  ³Andre Godoi         º Data ³  20/11/09   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Retira caracteres dIferentes de numero, como, ponto,       º±±
±±º          ³virgula, barra, traco                                       º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ AP                                                         º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
User Function EDINPonto(cString)
	Local cChar     := ""
	Local nX        := 0
	Local cPonto    := "."
	Local cBarra    := "/"
	Local cTraco    := "-"
	Local cVirgula  := ","
	Local cBarraInv := "\"
	Local cPVirgula := ";"
	Local cUnderline:= "_"
	Local cParent   := "()"
	Local cParent1  := "("
	Local cParent2  := ")"


	For nX:= 1 To Len(cString)
		cChar := SubStr(cString, nX, 1)
		If cChar$cPonto+cVirgula+cBarra+cTraco+cBarraInv+cPVirgula+cUnderline+cParent+cParent1+cParent2
			cString := StrTran(cString,cChar,"")
			nX := nX - 1
		EndIf
	Next
	cString := AllTrim(_NoTags(cString))

Return cString

/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ VldFat   ³ Autor ³ Douglas Oliveira Dantas ³ Data ³ 29/05/12 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Valida se existem Faturas De/Ate, conforme parametros.       ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ VldFat()                                                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ Envio                                                        ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
User Function VlFat()
Local lRet      	:=  .F.
Local aAreaDT6  	:=  DT6->(GetArea())

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Verifica Fatura De / Ate.     				     	³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
DbSelectArea("DT6")
DbSetOrder(1)
If DT6->DT6_NUM >= mv_par08 .And. DT6->DT6_NUM <= mv_par09
	lRet := .T.
EndIf		

RestArea ( aAreaDT6 )
Return lRet 
/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ VldPrd   ³ Autor ³ Douglas Oliveira Dantas ³ Data ³ 29/05/12 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Valida se existem Produtos De/Ate, conforme parametros.      ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ VldPrd()                                                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ Envio                                                        ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
User Function VlPrd()
Local lRet      	:=  .F.
Local aAreaDTC  	:=  DTC->(GetArea())
Local aAreaDT6  	:=  DT6->(GetArea())
Local cChave		:= ''

If !Empty(DT6->DT6_DOCDCO)
	cChave:=DT6->DT6_FILDCO+DT6->DT6_DOCDCO+DT6->DT6_SERDCO  
Else
	cChave:=DT6->DT6_FILDOC+DT6->DT6_DOC+DT6->DT6_SERIE
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Verifica Produto De / Ate.     				     	³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
DbSelectArea("DTC")
DbSetOrder(3)
If MsSeek(xFilial("DTC")+cChave)
	While DTC->(!Eof()) .And. DTC->DTC_FILIAL + DTC->DTC_FILDOC + DTC->DTC_DOC + DTC->DTC_SERIE == ;
		xFilial("DTC") + cChave
		If DTC->DTC_CODPRO >= mv_par10 .And. DTC->DTC_CODPRO <= mv_par11
			lRet := .T.
		EndIf
	DbSelectArea("DTC")
	DbSkip()
	EndDo
EndIf

RestArea ( aAreaDTC )
RestArea ( aAreaDT6 )
Return lRet
/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ VldGrp   ³ Autor ³ Douglas Oliveira Dantas ³ Data ³ 29/05/12 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Valida se existem Grupos de produto De/Ate, conforme         ³±±
±±³          ³ parametros.                                                  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ VldGrp()                                                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ Envio                                                        ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
User Function VlGrp()
Local lRet      	:=  .F.
Local aAreaDTC  	:=  DTC->(GetArea())
Local aAreaDT6  	:=  DT6->(GetArea())
Local aAreaSB1  	:=  SB1->(GetArea())
Local cChave		:= ''

If !Empty(DT6->DT6_DOCDCO)
	cChave:=DT6->DT6_FILDCO+DT6->DT6_DOCDCO+DT6->DT6_SERDCO  
Else
	cChave:=DT6->DT6_FILDOC+DT6->DT6_DOC+DT6->DT6_SERIE
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Verifica Grupo de Produto De / Ate.     		    ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
DbSelectArea("DTC")
DbSetOrder(3)
If MsSeek(xFilial("DTC")+cChave)
	While DTC->(!Eof()) .And. DTC->DTC_FILIAL + DTC->DTC_FILDOC + DTC->DTC_DOC + DTC->DTC_SERIE == ;
		xFilial("DTC") + cChave
		DbSelectArea("SB1")
        DbSetOrder(1)
        If DbSeek (xFilial("SB1")+DTC->DTC_CODPRO)
			If SB1->B1_GRUPO >= mv_par12 .And. SB1->B1_GRUPO <= mv_par13
				lRet := .T.
			EndIf
		EndIf	
	DbSelectArea("DTC")
	DbSkip()
	EndDo
EndIf

RestArea ( aAreaDTC )
RestArea ( aAreaDT6 )
RestArea ( aAreaSB1 )
Return lRet          
/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ Vlddev   ³ Autor ³ Douglas Oliveira Dantas ³ Data ³ 29/05/12 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Valida tipo de devedor, conforme parametros.                 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ Vlddev()                                                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ Envio                                                        ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
User Function Vldev()
Local lRet      	:=  .F.
Local aAreaDT6  	:=  DT6->(GetArea())

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Verifica Devedor.     				            	³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
DbSelectArea("DT6")
DbSetOrder(1)
If mv_par14==1 
	lRet := .T.
ElseIf DT6->DT6_DEVFRE == "1" .AND. mv_par14==2 
	lRet := .T.
ElseIf DT6->DT6_DEVFRE == "2" .AND. mv_par14==3 
	lRet := .T.
EndIf

RestArea ( aAreaDT6 )
Return lRet
/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ Vldtdc   ³ Autor ³ Douglas Oliveira Dantas ³ Data ³ 29/05/12 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Valida tipo de documento, conforme parametros.               ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ Vldtdc()                                                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ Envio                                                        ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
User Function Vltdc()
Local lRet      	:=  .T.
Local aAreaDT6  	:=  DT6->(GetArea())

If !Empty(mv_par15)
	lRet :=  .F.
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Verifica tipo de documento.			            	³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	DbSelectArea("DT6")
	DbSetOrder(1)
	If DT6->DT6_DOCTMS == mv_par15 
		lRet := .T.
	EndIf
EndIf

RestArea ( aAreaDT6 )
Return lRet
/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ VldFIL   ³ Autor ³ Douglas Oliveira Dantas ³ Data ³ 29/05/12 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Valida filial do documento, conforme parametros.             ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ VldFIL()                                                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ Envio                                                        ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
User Function VlFIL()
Local lRet      	:=  .F.
Local aAreaDT6  	:=  DT6->(GetArea())

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Verifica filial do documento.		            	³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
DbSelectArea("DT6")
DbSetOrder(1)
If DT6->DT6_FILDOC >= mv_par16 .And. DT6->DT6_FILDOC <= mv_par17
	lRet := .T.
EndIf

RestArea ( aAreaDT6 )
Return lRet           
/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ Vlddoc   ³ Autor ³ Douglas Oliveira Dantas ³ Data ³ 29/05/12 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Valida  documento, conforme parametros.                      ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ Vlddoc()                                                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ Envio                                                        ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
User Function Vldoc()
Local lRet      	:=  .F.
Local aAreaDT6  	:=  DT6->(GetArea())

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Verifica filial do documento.		            	³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
DbSelectArea("DT6")
DbSetOrder(1)
If DT6->DT6_DOC >= mv_par18 .And. DT6->DT6_DOC <= mv_par19
	lRet := .T.
EndIf

RestArea ( aAreaDT6 )
Return lRet

/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³PosOcor   ³ Autor ³ Katia Bianchi         ³ Data ³19/05/2011³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Valida o tipo da ocorrência                                ³±±
±±³          ³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ PosOcor()                                                  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ EDI                                                        ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
User Function PosOcor()
Local _cArea   := GetArea()
Public _xxcChave   := ""                            

DT6->(DbsetOrder(1))
IF DT6->(DBSEEK(xFilial("DT6")+DUA->DUA_FILDOC+DUA->DUA_DOC+DUA->DUA_SERIE))
	If !Empty(DT6->DT6_DOCDCO)
		_xxcChave:=XFILIAL("DTC")+DT6->DT6_FILDCO+DT6->DT6_DOCDCO+DT6->DT6_SERDCO  
	Else
		_xxcChave:=XFILIAL("DTC")+DT6->DT6_FILDOC+DT6->DT6_DOC+DT6->DT6_SERIE
	EndIf			
Endif

RestArea(_cArea)
RETURN _xxcChave            

/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ EdiVldOc ³ Autor ³ Eduardo de Souza      ³ Data ³ 10/06/03 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Valida se existem ocorrencias para o Cliente De/Ate, Nota  ³±±
±±³          ³ Fiscal De/Ate e Agrupamento de CNPJ, conforme parametros.  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ EdiVdOc1()                                                 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ Envio / Recebimento (EDI)                                  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
User Function EdiVldOc()

Local lRet      := .F.
Local lContinua := .F.
Local aAreaDTC  := DTC->(GetArea())
Local aAreaDT6  := DT6->(GetArea())
Local aAreaDUD  := DUD->(GetArea())

If !Empty(DUA->DUA_FILDOC) .And. !Empty(DUA->DUA_DOC) .And. !Empty(DUA->DUA_SERIE)
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Verifica Cliente De / Ate.     				     	³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	DbSelectArea("DT6")
	DbSetOrder(1)
	If MsSeek(xFilial("DT6")+DUA->DUA_FILDOC+DUA->DUA_DOC+DUA->DUA_SERIE)			
          
		If   DT6->DT6_DOCTMS = '6'
			cCliente:=DT6->DT6_CLIDES + DT6->DT6_LOJDES
		Else
			cCliente:=DT6->DT6_CLIREM + DT6->DT6_LOJREM
		EndIF        

		If !(cCliente == DEC->DEC_CODCLI + DEC->DEC_LOJCLI)

			If mv_par09 == 1 // Agrupamento de CNPJ

				DbSelectArea("SA1")
				DbSetOrder(1)
				If MsSeek(xFilial("SA1")+DEC->DEC_CODCLI+DEC->DEC_LOJCLI)
					
					DbSelectArea("DE4")
					DbSetOrder(1)
					If MsSeek(xFilial("DE4")+SA1->A1_CGC)
						While DE4->(!Eof()) .And. DE4->DE4_FILIAL + DE4->DE4_CNPJ == xFilial("DE4") + SA1->A1_CGC
						
							DbSelectArea("SA1")
							DbSetOrder(3)
							If MsSeek(xFilial("SA1")+DE4->DE4_CNPJ1)							
								If SA1->A1_COD + SA1->A1_LOJA == cCliente
									lContinua := .t.
								EndIf							
							EndIf
							DbSelectArea("DE4")
							DbSkip()
						EndDo
					EndIf
				EndIf
			EndIf
        
        Else
	   		DbSelectArea("SA1")
			DbSetOrder(1)
			If MsSeek(xFilial("SA1")+cCliente)
				lContinua := .T.
			EndIf
		
		EndIf
		
		If lContinua
						
			If !Empty(DT6->DT6_DOCDCO)
				cChave:=DT6->DT6_FILDCO+DT6->DT6_DOCDCO+DT6->DT6_SERDCO  
			Else
				cChave:=DT6->DT6_FILDOC+DT6->DT6_DOC+DT6->DT6_SERIE
			EndIf
			
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Verifica Nota Fiscal De / Ate.						³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			DbSelectArea("DTC")
			DbSetOrder(3)
			If MsSeek(xFilial("DTC")+cChave)
				While DTC->(!Eof()) .And. DTC->DTC_FILIAL + DTC->DTC_FILDOC + DTC->DTC_DOC + DTC->DTC_SERIE == ;
											xFilial("DTC") + cChave
					If DTC->DTC_NUMNFC >= mv_par05 .And. DTC->DTC_NUMNFC <= mv_par06										
						lRet := .T.
						Exit
					EndIf

					DbSelectArea("DTC")
					DbSkip()
				EndDo
			EndIf
		EndIf
	EndIf

Else

	DbSelectArea("DUD")
	DbSetOrder(2)
	If MsSeek(xFilial("DUD")+DUA->DUA_FILORI+DUA->DUA_VIAGEM)
		While DUD->(!Eof()) .And. DUD->DUD_FILIAL + DUD->DUD_FILORI + DUD->DUD_VIAGEM == xFilial("DUD") + DUA->DUA_FILORI + DUA->DUA_VIAGEM
	
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Verifica Cliente De / Ate.     				     	³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			DbSelectArea("DT6")
			DbSetOrder(1)
			If MsSeek(xFilial("DT6")+DUD->DUD_FILDOC+DUD->DUD_DOC+DUD->DUD_SERIE)
				If   DT6->DT6_DOCTMS = '6'
					cCliente:=DT6->DT6_CLIDES + DT6->DT6_LOJDES
				Else
					cCliente:=DT6->DT6_CLIREM + DT6->DT6_LOJREM
				EndIF  
				
				If !(cCliente == DEC->DEC_CODCLI + DEC->DEC_LOJCLI)
		
					If mv_par09 == 1 // Agrupamento de CNPJ
		
						DbSelectArea("SA1")
						DbSetOrder(1)
						If MsSeek(xFilial("SA1")+DEC->DEC_CODCLI+DEC->DEC_LOJCLI)
							
							DbSelectArea("DE4")
							DbSetOrder(1)
							If MsSeek(xFilial("DE4")+SA1->A1_CGC)
								While DE4->(!Eof()) .And. DE4->DE4_FILIAL + DE4->DE4_CNPJ == xFilial("DE4") + SA1->A1_CGC
								
									DbSelectArea("SA1")
									DbSetOrder(3)
									If MsSeek(xFilial("SA1")+DE4->DE4_CNPJ1)							
										If SA1->A1_COD + SA1->A1_LOJA == cCliente
											lContinua := .t.
										EndIf							
									EndIf
									DbSelectArea("DE4")
									DbSkip()
								EndDo
							EndIf
						EndIf
					EndIf
		        
		        Else
			   		DbSelectArea("SA1")
					DbSetOrder(1)
					If MsSeek(xFilial("SA1")+cCliente)
						lContinua := .T.
					EndIf
				
				EndIf
				
				If lContinua
					
					If !Empty(DT6->DT6_DOCDCO)
						cChave:=DT6->DT6_FILDCO+DT6->DT6_DOCDCO+DT6->DT6_SERDCO  
					Else
						cChave:=DT6->DT6_FILDOC+DT6->DT6_DOC+DT6->DT6_SERIE
					EndIf
								
					//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
					//³ Verifica Nota Fiscal De / Ate.						³
					//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
					DbSelectArea("DTC")
					DbSetOrder(3)
					If MsSeek(xFilial("DTC")+cChave)
						While DTC->(!Eof()) .And. DTC->DTC_FILIAL + DTC->DTC_FILDOC + DTC->DTC_DOC + DTC->DTC_SERIE == ;
													xFilial("DTC") + cChave
							If DTC->DTC_NUMNFC >= mv_par05 .And. DTC->DTC_NUMNFC <= mv_par06										
								lRet := .T.
								Exit
							EndIf
		
							DbSelectArea("DTC")
							DbSkip()
						EndDo
					EndIf
				EndIf
			EndIf
	        DbSelectArea("DUD")
	        DbSkip()
		EndDo
    EndIf
EndIf

RestArea ( aAreaDTC )
RestArea ( aAreaDT6 )
RestArea ( aAreaDUD )

Return lRet
