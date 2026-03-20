#Include 'Protheus.ch'


/*/{Protheus.doc} BFFATA43
(long_description)
@author MarceloLauschner
@since 19/09/2014
@version 1.0
@param xPar1, variável, aCols da GetDados ou Alias da GetDb
@param xPar2, variável, [1] Posicao do codigo do produto [2] Posicao da Quantidade [3] Posicao da Tabela
@param cCliente, character, Cliente
@param cLoja, character, Loja
@param cTabPreco, character,Tabela
@param cCondPg, character, (Descrição do parâmetro)
@param cFormPg, character, (Descrição do parâmetro)
@param aRecACQ, array, (Descrição do parâmetro)
@return array com informação de combos
@example
(examples)
@see (links_or_references)
/*/
User Function BFFATA43(aCodRegBon,cCliente,cLoja,cTabPreco,cCondPg,cFormPg,aRecACQ,cTipoRet)
	
	Local 		aArea    	:= GetArea()
	Local 		aAreaSF4 	:= SF4->(GetArea())
	Local 		aStruACQ 	:= ACQ->(dbStruct())
	Local 		aStruACR 	:= ACR->(dbStruct())
	Local 		cQuery   	:= ""
	Local		aACQTip1	:= {}
	Local		aACQTip2	:= {}
	
	Local 		aRetorno 	:= {}
	Local 		cCursor  	:= "ACQ"
	Local 		cCursor2 	:= "ACR"
	Local		nRecs		:= 0
	Local		nPrcVend	:= 0
	Local		nMoeda    	:= 1
	Local		dDataVld  	:= dDataBase
	Local		cTabPrcFix	:= "00P"
	DEFAULT 	cCliente  	:= Space(Len(SA1->A1_COD))
	DEFAULT 	cLoja     	:= Space(Len(SA1->A1_LOJA))
	DEFAULT 	cTabPreco 	:= Space(Len(DA0->DA0_CODTAB))
	DEFAULT 	cCondPg   	:= Space(Len(DA0->DA0_CONDPG))
	DEFAULT 	cFormPg   	:= Space(Len(ACO->ACO_FORMPG))
	DEFAULT 	aRecACQ		:=	{}
	DEFAULT		aCodRegBon	:= {}
	DEFAULT		cTipoRet	:= "1"	// 1=Retornar Array com todas as Regras de Bonificação 2=Retornar se a valida'~
	
	nRecs	:=	Len(aRecACQ)
	
	
	
	// Inicia consulta para localizar cabeçalho de cadastro de Promoções
	DbSelectArea("ACQ")
	DbSetOrder(1)
	#IFDEF TOP
		lQuery := .T.
		cCursor:= "FTRGRBONUS"
		cQuery := "SELECT * "
		cQuery += "FROM "+RetSqlName("ACQ")+" ACQ "
		cQuery += "WHERE ACQ.ACQ_FILIAL='"+xFilial("ACQ")+"' AND "
		If nRecs > 0
			cQuery	+=	"R_E_C_N_O_ IN ("
			For nX:=	1 To nRecs
				cQuery	+=	Alltrim(Str(aRecACQ[nX]))+','
			Next
			cQuery	+=	"0) AND "
		Endif
		If Len(aCodRegBon) > 0
			cQuery	+=	" ACQ_CODREG NOT IN("
			For nX:= 1 To Len(aCodRegBon)
				cQuery	+=	"'" + Substr(aCodRegBon[nX],1,6) +"',"
			Next
			cQuery	+=	"' ') AND "
		Endif
		cQuery += "(ACQ.ACQ_CODCLI = '"+cCliente+"' OR ACQ.ACQ_CODCLI='"+Space(Len(ACQ->ACQ_CODCLI))+"') AND "
		cQuery += "(ACQ.ACQ_LOJA = '"+cLoja+"' OR ACQ.ACQ_LOJA='"+Space(Len(ACQ->ACQ_LOJA))+"') AND "
		cQuery += "(ACQ.ACQ_CONDPG = '"+cCondPg+"' OR ACQ.ACQ_CONDPG='"+Space(Len(ACQ->ACQ_CONDPG))+"') AND "
		cQuery += "(ACQ.ACQ_FORMPG = '"+cFormPg+"' OR ACQ.ACQ_FORMPG='"+Space(Len(ACQ->ACQ_FORMPG))+"') AND "
		cQuery += "ACQ.D_E_L_E_T_=' ' "
		cQuery += "ORDER BY "+SqlOrder(ACQ->(IndexKey()))
		
		cQuery := ChangeQuery(cQuery)
		
		dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cCursor,.T.,.T.)
		For nX := 1 To Len(aStruACQ)
			If aStruACQ[nX][2] <> "C"
				TcSetField(cCursor,aStruACQ[nX][1],aStruACQ[nX][2],aStruACQ[nX][3],aStruACQ[nX][4])
			EndIf
		Next nX
	#ELSE
		DbSeek(xFilial("ACQ"))
	#ENDIF
	
	While If(nRecs=0.Or.lQuery,!Eof(),nCnt	<=	nRecs)
		lValido:= .F.
		If !lQuery
			If nRecs	>	0
				ACQ->(DbGoTo(aRecACQ[nCnt]))
				nCnt++
			Endif
			If ((ACQ->ACQ_CODCLI == cCliente .Or. Empty(ACQ->ACQ_CODCLI) ).And.;
					(ACQ->ACQ_LOJA == cLoja .Or. Empty(ACQ->ACQ_LOJA) ) .And.;
					(ACQ->ACQ_CONDPG == cCondPg .Or. Empty(ACQ->ACQ_CONDPG) ) .And.;
					(ACQ->ACQ_FORMPG == cFormPg .Or. Empty(ACQ->ACQ_FORMPG) ) )
				lValido := .T.
			EndIf
		Else
			lValido := .T.
		EndIf
		If FtIsDataOk("ACQ",cCursor) .And. If(ACQ->(FieldPos("ACQ_GRPVEN"))>0, !Empty(FtIsGrpOk((cCursor)->ACQ_GRPVEN,SA1->A1_GRPVEN)),.T.)
			If lValido
				lBonific := .T.
				
				
				dbSelectArea("ACR")
				dbSetOrder(1)
				#IFDEF TOP
					lQuery := .T.
					cCursor2 := cCursor+"A"
					cQuery := "SELECT * "
					cQuery += "FROM "+RetSqlName("ACR")+" ACR "
					cQuery += "WHERE ACR.ACR_FILIAL='"+xFilial("ACR")+"' AND "
					cQuery += "ACR.ACR_CODREG='"+(cCursor)->ACQ_CODREG+"' AND "
					cQuery += "ACR.D_E_L_E_T_=' ' "
					cQuery += "ORDER BY "+SqlOrder(ACR->(IndexKey()))
					
					cQuery := ChangeQuery(cQuery)
					
					dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cCursor2,.T.,.T.)
					For nX := 1 To Len(aStruACR)
						If aStruACR[nX][2] <> "C"
							TcSetField(cCursor2,aStruACR[nX][1],aStruACR[nX][2],aStruACR[nX][3],aStruACR[nX][4])
						EndIf
					Next nX
				#ELSE
					MsSeek(xFilial("ACR")+(cCursor)	->ACQ_CODREG)
				#ENDIF
				
				nPrcVend := MaTabPrVen(cTabPreco,Padr((cCursor)->ACQ_CODPRO,15),1,cCliente,cLoja,nMoeda,dDataVld,1/*nTipo*/,.F. /*lExec*/,,.F./*lProspect*/)
				ConOut(cValToChar(nPrcVend))
				ConOut(ctabpreco)
				ConOut((cCursor)->ACQ_CODPRO)
				ConOut(cCliente)
				ConOut(cLoja)
				If nPrcVend > 0 .And. Posicione("SB1",1,xFilial("SB1")+(cCursor)->ACQ_CODPRO,"B1_MSBLQL") <> "1"
					While ( !Eof() .And. (cCursor)->ACQ_CODREG == (cCursor2)->ACR_CODREG )
						Posicione("SB1",1,xFilial("SB1")+(cCursor2)->ACR_CODPRO,"B1_DESC")
						If cTipoRet == "1" 
							cTabPrcFix		:= cTabPreco
							
							If (cCursor2)->ACR_PRCFIX == "1"
								//nPrcVend	:= (cCursor2)->ACR_XPRCVE
								nPrcVend := MaTabPrVen(cTabPreco,(cCursor)->ACQ_CODPRO,1,cCliente,cLoja,nMoeda,dDataVld,1/*nTipo*/,.F. /*lExec*/,,.F./*lProspect*/)
								U_BFFATX02(cCondPg,.T./*lSUA*/,.F./*lSC5*/,@nPrcVend,/*cProcPad*/,.F./*lPrzDA0*/,cTabPreco/* cCodTab*/)
								nPrcVend	:= Round(nPrcVend * (cCursor2)->ACR_LOTE / 100 / (cCursor2)->ACR_QUANT ,2)
							Else
								nPrcVend	:= (cCursor2)->ACR_XPRCVE
								cTabPrcFix	:= "00P"
							Endif
							
							ConOut(cValToChar(nPrcVend))
							
							Aadd(aRetorno,{"ACR",;
											(cCursor)->ACQ_CODREG+(cCursor2)->ACR_ITEM,;
											(cCursor)->ACQ_CODPRO,;
											(cCursor)->ACQ_DESCRI,;
											(cCursor2)->ACR_CODPRO ,;
											SB1->B1_DESC,;
											(cCursor2)->ACR_QUANT,;
											Padr((cCursor2)->ACR_OPER,2),;
											nPrcVend,;
											(cCursor2)->ACR_PRCFIX,;
											cTabPrcFix,;
											nPrcVend,;
											(cCursor2)->ACR_LOTE})
						Endif
						dbSelectArea(cCursor2)
						dbSkip()
					EndDo
				Endif
				If lQuery
					dbSelectArea(cCursor2)
					dbCloseArea()
					dbSelectArea(cCursor)
				EndIf
			Endif
		Endif
		dbSelectArea(cCursor)
		DbSkip()
	EndDo
	If lQuery
		dbSelectArea(cCursor)
		dbCloseArea()
		dbSelectArea("ACQ")
	EndIf
	
	
	RestArea(aAreaSF4)
	RestArea(aArea)
	
Return(aRetorno)


