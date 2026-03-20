#include "protheus.ch"
#INCLUDE "topconn.ch"

//User Function DIS126()
//Return U_BFFATA31()

/*/{Protheus.doc} BFFATA31
(Roteirizador de entregas e faturamento)
@author MarceloLauschner
@since 18/04/2014
@version 1.0
@return Sem retorno
@example
(examples)
@see (links_or_references)

/*/
User Function BFFATA31()

	Local		nAddHead		:= 0
	Local		aButton			:= {}
	Local	 	aSize 			:= MsAdvSize(,.F.,400)
	Local		aHeadPAB 		:= {}
	Local	 	aColsPAB		:= {}
	Local	 	aCapAlt  		:= {}
	Local	 	aUf  			:= {"SC","PR","RS","SP","MG"}
	Local		aOpcAgrupa		:= {"M=Município","B=Bairro/Município","C=Cep"}
	Local		iC
	Local		cQry
	Local		cPabCodSeq		:= ""
	Private 	cUf 	 		:= SM0->M0_ESTENT
	Private		cOpcAgrupa		:= "M"
	Private 	oUf,oOpcFiltra,oOpcAgrupa,oOpcMun
	Private 	cMun     		:= ""
	Private 	aMun    	 	:= {}
	Private 	oMun
	Private 	cOpcFiltra		:= "N"
	Private		cOpcMun			:= "N"
	Private 	nPxBairro,nPxRota,nPxPrazo,nPxCtrFil,nPxNtrFil,nPxTransp,nPxMun,nPxUf,nPxCep,nPxEnd,nPxCodSeq
	Private 	oTransp
	Private		cTransp			:= Space(TamSX3("A4_COD")[1])
	Private 	cMunic			:= Space(TamSX3("PAB_MUN")[1])
	Private 	cRegiao			:= Space(TamSX3("PAB_CTRFIL")[1])
	Private 	cSubReg			:= Space(TamSX3("PAB_NTRFIL")[1])
	Private		oMunic,oRegiao,oSubReg
	Private	lIsSuper		:= __cUserId $ GetNewPar("BF_FATA31A","000130")
	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()


	// 22/02/2019 - Melhoria para sempre corrigir o código sequencial da PAB
	cQry := "UPDATE " + RetSqlName("PAB") + "   SET PAB_CODSEQ = RIGHT(REPLICATE('0',10) + R_E_C_N_O_,10) "
	cQry += " WHERE PAB_FILIAL = '" + xFilial("PAB")+ "' "
	cQry += "   AND D_E_L_E_T_ = ' ' "
	cQry += "   AND PAB_CODSEQ = ' ' "

	Begin Transaction
		TcSqlExec(cQry)
	End Transaction
	// Atualiza a sequencia correta do PAB no SXE e SXF,
	DbSelectArea("PAB")
	DbSetOrder(3)
	Do While .T.
		cPabCodSeq := GetSxeNum("PAB","PAB_CODSEQ")
		If dbSeek( xFilial( "PAB" ) + cPabCodSeq )
			If __lSx8
				ConfirmSx8()
			EndIf
		Else
			RollBackSX8()
			Exit
		EndIf
	EndDo



	cCampo1 := "PAB_UF"
	cCampo2 := "PAB_CEP"
	cCampo3 := "PAB_MUN"
	cCampo4 := "PAB_BAIINI"
	cCampo5 := "PAB_ROTA"
	cCampo6 := "PAB_PRAZO"
	cCampo7 := "PAB_CTRFIL"
	cCampo8 := "PAB_NTRFIL"
	cCampo9 := "PAB_TRANSP"
	cCampo10 := "PAB_END"
	cCampo11 := "PAB_CODSEQ"

	Aadd(aHeadPAB		,{Alltrim(GetSx3Cache(cCampo1,"X3_TITULO"))	,GetSx3Cache(cCampo1,"X3_CAMPO")	,GetSx3Cache(cCampo1,"X3_PICTURE")	,GetSx3Cache(cCampo1,"X3_TAMANHO")	,GetSx3Cache(cCampo1,"X3_DECIMAL")	,GetSx3Cache(cCampo1,"X3_VLDUSER"),	,	GetSx3Cache(cCampo1,"X3_TIPO"),GetSx3Cache(cCampo1,"X3_F3"),"",GetSx3Cache(cCampo1,"X3_CBOX")})
	nPxUf	:= ++nAddHead

	//DbSeek("PAB_CEP")
	Aadd(aHeadPAB		,{Alltrim(GetSx3Cache(cCampo2,"X3_TITULO"))	,GetSx3Cache(cCampo2,"X3_CAMPO")	,GetSx3Cache(cCampo2,"X3_PICTURE")	,GetSx3Cache(cCampo2,"X3_TAMANHO")	,GetSx3Cache(cCampo2,"X3_DECIMAL")	,GetSx3Cache(cCampo2,"X3_VLDUSER"),	,	GetSx3Cache(cCampo2,"X3_TIPO"),GetSx3Cache(cCampo2,"X3_F3"),"",GetSx3Cache(cCampo2,"X3_CBOX")})
	nPxCep	:= ++nAddHead

	//DbSeek("PAB_MUN")
	Aadd(aHeadPAB		,{Alltrim(GetSx3Cache(cCampo3,"X3_TITULO"))	,GetSx3Cache(cCampo3,"X3_CAMPO")	,GetSx3Cache(cCampo3,"X3_PICTURE")	,GetSx3Cache(cCampo3,"X3_TAMANHO")	,GetSx3Cache(cCampo3,"X3_DECIMAL")	,GetSx3Cache(cCampo3,"X3_VLDUSER"),	,	GetSx3Cache(cCampo3,"X3_TIPO"),GetSx3Cache(cCampo3,"X3_F3"),"",GetSx3Cache(cCampo3,"X3_CBOX")})
	nPxMun	:= ++nAddHead

	//DbSeek("PAB_BAIINI")
	Aadd(aHeadPAB		,{Alltrim(GetSx3Cache(cCampo4,"X3_TITULO"))	,GetSx3Cache(cCampo4,"X3_CAMPO")	,GetSx3Cache(cCampo4,"X3_PICTURE")	,GetSx3Cache(cCampo4,"X3_TAMANHO")	,GetSx3Cache(cCampo4,"X3_DECIMAL")	,GetSx3Cache(cCampo4,"X3_VLDUSER"),	,	GetSx3Cache(cCampo4,"X3_TIPO"),GetSx3Cache(cCampo4,"X3_F3"),"",GetSx3Cache(cCampo4,"X3_CBOX")})
	nPxBairro	:= ++nAddHead

	//DbSeek("PAB_ROTA")
	Aadd(aHeadPAB		,{Alltrim(GetSx3Cache(cCampo5,"X3_TITULO"))	,GetSx3Cache(cCampo5,"X3_CAMPO")	,GetSx3Cache(cCampo5,"X3_PICTURE")	,GetSx3Cache(cCampo5,"X3_TAMANHO")	,GetSx3Cache(cCampo5,"X3_DECIMAL")	,GetSx3Cache(cCampo5,"X3_VLDUSER"),	,	GetSx3Cache(cCampo5,"X3_TIPO"),GetSx3Cache(cCampo5,"X3_F3"),"",GetSx3Cache(cCampo5,"X3_CBOX")})
	Aadd(aCapAlt,"PAB_ROTA")
	nPxRota	:= ++nAddHead

	//DbSeek("PAB_PRAZO")
	Aadd(aHeadPAB		,{Alltrim(GetSx3Cache(cCampo6,"X3_TITULO"))	,GetSx3Cache(cCampo6,"X3_CAMPO")	,GetSx3Cache(cCampo6,"X3_PICTURE")	,GetSx3Cache(cCampo6,"X3_TAMANHO")	,GetSx3Cache(cCampo6,"X3_DECIMAL")	,GetSx3Cache(cCampo6,"X3_VLDUSER"),	,	GetSx3Cache(cCampo6,"X3_TIPO"),GetSx3Cache(cCampo6,"X3_F3"),"",GetSx3Cache(cCampo6,"X3_CBOX")})
	Aadd(aCapAlt,"PAB_PRAZO")
	nPxPrazo	:= ++nAddHead

	//DbSeek("PAB_CTRFIL")
	Aadd(aHeadPAB		,{Alltrim(GetSx3Cache(cCampo7,"X3_TITULO"))	,GetSx3Cache(cCampo7,"X3_CAMPO")	,GetSx3Cache(cCampo7,"X3_PICTURE")	,GetSx3Cache(cCampo7,"X3_TAMANHO")	,GetSx3Cache(cCampo7,"X3_DECIMAL")	,GetSx3Cache(cCampo7,"X3_VLDUSER"),	,	GetSx3Cache(cCampo7,"X3_TIPO"),GetSx3Cache(cCampo7,"X3_F3"),"",GetSx3Cache(cCampo7,"X3_CBOX")})
	Aadd(aCapAlt,"PAB_CTRFIL")
	nPxCtrFil	:= ++nAddHead

	//DbSeek("PAB_NTRFIL")
	Aadd(aHeadPAB		,{Alltrim(GetSx3Cache(cCampo8,"X3_TITULO"))	,GetSx3Cache(cCampo8,"X3_CAMPO")	,GetSx3Cache(cCampo8,"X3_PICTURE")	,GetSx3Cache(cCampo8,"X3_TAMANHO")	,GetSx3Cache(cCampo8,"X3_DECIMAL")	,GetSx3Cache(cCampo8,"X3_VLDUSER"),	,	GetSx3Cache(cCampo8,"X3_TIPO"),GetSx3Cache(cCampo8,"X3_F3"),"",GetSx3Cache(cCampo8,"X3_CBOX")})
	Aadd(aCapAlt,"PAB_NTRFIL")
	nPxNtrFil	:= ++nAddHead

	//DbSeek("PAB_TRANSP")
	Aadd(aHeadPAB		,{Alltrim(GetSx3Cache(cCampo9,"X3_TITULO"))	,GetSx3Cache(cCampo9,"X3_CAMPO")	,GetSx3Cache(cCampo9,"X3_PICTURE")	,GetSx3Cache(cCampo9,"X3_TAMANHO")	,GetSx3Cache(cCampo9,"X3_DECIMAL")	,GetSx3Cache(cCampo9,"X3_VLDUSER"),	,	GetSx3Cache(cCampo9,"X3_TIPO"),GetSx3Cache(cCampo9,"X3_F3"),"",GetSx3Cache(cCampo9,"X3_CBOX")})
	Aadd(aCapAlt,"PAB_TRANSP")
	nPxTransp	:= ++nAddHead

	//DbSeek("PAB_END")
	Aadd(aHeadPAB		,{Alltrim(GetSx3Cache(cCampo10,"X3_TITULO"))	,GetSx3Cache(cCampo10,"X3_CAMPO")	,GetSx3Cache(cCampo10,"X3_PICTURE")	,GetSx3Cache(cCampo10,"X3_TAMANHO")	,GetSx3Cache(cCampo10,"X3_DECIMAL")	,GetSx3Cache(cCampo10,"X3_VLDUSER"),	,	GetSx3Cache(cCampo10,"X3_TIPO"),GetSx3Cache(cCampo10,"X3_F3"),"",GetSx3Cache(cCampo10,"X3_CBOX")})
	nPxEnd		:= ++nAddHead

	//DbSeek("PAB_CODSEQ")
	Aadd(aHeadPAB		,{Alltrim(GetSx3Cache(cCampo11,"X3_TITULO"))	,GetSx3Cache(cCampo11,"X3_CAMPO")	,GetSx3Cache(cCampo11,"X3_PICTURE")	,GetSx3Cache(cCampo11,"X3_TAMANHO")	,GetSx3Cache(cCampo11,"X3_DECIMAL")	,GetSx3Cache(cCampo11,"X3_VLDUSER"),	,	GetSx3Cache(cCampo11,"X3_TIPO"),GetSx3Cache(cCampo11,"X3_F3"),"",GetSx3Cache(cCampo11,"X3_CBOX")})
	nPxCodSeq		:= ++nAddHead

	If lIsSuper
		Aadd(aCapAlt,"PAB_BAIINI")
		Aadd(aCapAlt,"PAB_END")
		Aadd(aButton,{"PRETO", {|| sfAtuAdmPAB() } ,"Atualiza Tabela CEPs" })

	Endif

	Aadd(aButton,{"PRETO",{|| sfGeraPlan()},"Exportar Planilha"})

	Aadd(aButton,{"PRETO",{|| sfReativa()},"Inverter Deletados"})

	Aadd(aButton,{"PRETO",{|| sfRepcli()},"Replicar campo"})

	Aadd(aColsPAB,Array(Len(aHeadPAB)+1))
	For iC := 1 To Len(aHeadPAB)
		aColsPAB[Len(aColsPAB)][iC]	:= CriaVar(aHeadPAB[iC][2],.T.)
	Next
	aColsPAB[Len(aColsPAB),Len(aHeadPAB)+1]	:= .F.


	DEFINE MSDIALOG oDlg Title OemToAnsi("Roteirizador de Entregas") From aSize[7],0 to aSize[6],aSize[5] Of oMainWnd Pixel

	oDlg:lMaximized := .T.



	//@ 006,090 Say "Municipio" color 16711680
	//	Private oMun := TComboBox():New(005,035,{|u|if(PCount()>0,oMun:=u,oMun)},{"S=Sim","N=Não"},70,10,oDlg,,{|| Alert("Teste") },,,,.T.,,,,,,,,,'cAgrupa')
	oPanel1 := TPanel():New(0,0,'',oDlg, oDlg:oFont, .T., .T.,, ,250,105,.T.,.T. )
	oPanel1:Align := CONTROL_ALIGN_TOP

	@ 006,008 Say "Selecione um Estado" Of oPanel1 Pixel
	oUf := TComboBox():New(005,075,{|u|if(PCount()>0,cUf:=u,cUf)},aUf,35,10,oPanel1,,,,,,	.T.,,,,,,,,,'cUf')

	@ 018,008 Say "Tipo de Agrupamento" Of oPanel1 Pixel
	oOpcAgrupa := TComboBox():New(017,075,{|u|if(PCount()>0,cOpcAgrupa:=u,cOpcAgrupa)},aOpcAgrupa,75,10,oPanel1,,,,,,.T.,,,,,,,,,'cOpcAgrupa')

	@ 030,008 Say "Filtra Transportadora?" Of oPanel1 Pixel
	oOpcFiltra := TComboBox():New(029,075,{|u|if(PCount()>0,cOpcFiltra:=u,cOpcFiltra)},{"S=Sim","N=Não"},35,10,oPanel1,,,,,,.T.,,,,,,,,,'cOpcFiltra')

	@ 042,008 Say "Transportadora" Of oPanel1 Pixel
	@ 041,075 MsGet oTransp Var cTransp Size 40,10 F3 "SA4" Valid sfVldTransp() Of oPanel1 Pixel

	@ 054,008 Say "Filtra Cidade?" Of oPanel1 Pixel
	oOpcMun := TComboBox():New(054,075,{|u|if(PCount()>0,cOpcMun:=u,cOpcMun)},{"S=Sim","N=Não"},35,10,oPanel1,,,,,,.T.,,,,,,,,,'cOpcMun')

	@ 066,008 Say "Cidade" Of oPanel1 Pixel
	@ 063,075 MsGet oMunic Var cMunic Size 40,10 F3 "CC2PAB" Valid sfVldMun() Of oPanel1 Pixel

	@ 078,008 Say "Região" Of oPanel1 Pixel
	@ 077,075 MsGet oRegiao Var cRegiao Size 40,10 Valid sfVldReg()  Of oPanel1 Pixel

	@ 090,008 Say "Sub-Região" Of oPanel1 Pixel
	@ 089,075 MsGet oSubReg Var cSubReg Size 40,10 Valid sfVldReg() Of oPanel1 Pixel

	Private oItems := MsNewGetDados():New(025,005,230,290,IIf(lIsSuper,GD_DELETE,0)+GD_UPDATE,"AllwaysTrue()"/*cLinhaOk*/,"AllwaysTrue()"/*cTudoOk*/,"",;
		aCapAlt,4/*nFreeze*/,10000/*nMax*/,"AllwaysTrue()"/*cCampoOk*/,"AllwaysTrue()"/*cSuperApagar*/,"U_BFATA31A()"/*cApagaOk*/,oDlg,@aHeadPAB,@aColsPAB,/*bChangeXIT*/)
	oItems:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	Activate MsDialog oDlg ON INIT EnchoiceBar(oDlg,{|| Processa( {|| sfGrvPAB()},"Aguarde...")},{|| oDlg:End()},,aButton)


Return



Static Function sfReativa()

	Local 	nL

	For nL	:= 1 To Len(oItems:aCols)
		If !oItems:aCols[nL,Len(oItems:aHeader)+1]
			oItems:aCols[nL,Len(oItems:aHeader)+1]	:= .T.
		Else
			oItems:aCols[nL,Len(oItems:aHeader)+1]	:= .F.
		Endif
	Next

Return


Static Function sfRepcli()

	Local 	nL
	Local 	xValue 	:= 	oItems:aCols[oItems:nAt][oItems:oBrowse:nColPos]

	If MsgYesNo("Deseja replicar o valor '"+ Iif(ValType(xValue)=="C",xValue,cValToChar(xValue))+"' da coluna "+oItems:aHeader[oItems:oBrowse:nColPos][1] + " para todas as linhas não deletadas?")

		For nL	:= 1 To Len(oItems:aCols)
			If !oItems:aCols[nL,Len(oItems:aHeader)+1]
				oItems:aCols[nL,oItems:oBrowse:nColPos]	:= xValue
			Endif
		Next
		oItems:oBrowse:Refresh()
	Endif

Return

/*/{Protheus.doc} sfGrvPAB
(Efetua gravação dos dados)
@author MarceloLauschner
@since 18/04/2014
@version 1.0
@return Sem retorno
@example
(examples)
@see (links_or_references)
/*/
Static Function sfGrvPAB()

	Local	cQry	:= ""
	Local	cHeadAlt	:= "PAB_ROTA  #PAB_TRANSP#PAB_PRAZO #PAB_CTRFIL#PAB_NTRFIL"
	Local	nConPAB	:= 0
	Local	nConSA1	:= 0
	Local 	lAtuAll := MsgYesNo("Atualizar todos os clientes com os informações da tela?","Atualizar Clientes?")
	Local	nC,nL

	// Gravação por CEP, cada registro da PAB e passando .T. para atualizar clientes
	If oOpcAgrupa:nAt	== 3			//	CEP
		sfAtuAdmPAB(.T.)
		// Gravação por agrupamento de Municipio
	ElseIf oOpcAgrupa:nAt	== 1	// Municipio

		ProcRegua(Len(oItems:aCols))


		For nL	:= 1 To Len(oItems:aCols)
			IncProc()
			If !oItems:aCols[nL,Len(oItems:aHeader)+1]
				cQry := ""
				cQry += "SELECT PAB_CODSEQ "
				cQry += "  FROM " + RetSqlName("PAB")
				cQry += " WHERE D_E_L_E_T_ = ' ' "
				//If !Empty(cRegiao)
				//	cQry += "   AND PAB_CTRFIL = '"+oItems:aCols[nL,nPxCtrFil]+"' "//nPxNtrFil
				//Endif
				cQry += "   AND (PAB_TRANSP <> '" + oItems:aCols[nL,nPxTransp] + "' OR PAB_ROTA <> '" + oItems:aCols[nL,nPxRota] + "' OR PAB_PRAZO <> '" + oItems:aCols[nL,nPxPrazo] + "' OR PAB_CTRFIL <> '"+oItems:aCols[nL,nPxCtrFil]+"'  OR PAB_NTRFIL <> '"+oItems:aCols[nL,nPxNtrFil]+"')"
				cQry += "   AND PAB_UF = '"+oItems:aCols[nL,nPxUf]+"' "
				cQry += "   AND PAB_MUN = '"+StrTran(oItems:aCols[nL,nPxMun],"'","''")+"' "
				cQry += "   AND PAB_FILIAL = '"+xFilial("PAB")+"' "

				dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQry),'QPAB', .F., .T.)

				While !Eof()

					DbSelectArea("PAB")
					DbSetOrder(3)
					If DbSeek(xFilial("PAB")+QPAB->PAB_CODSEQ)
						RecLock("PAB",.F.)
						For nC := 1 To Len(oItems:aHeader)
							If Alltrim(oItems:aHeader[nC,2]) $ cHeadAlt
								PAB->(FieldPut(FieldPos(oItems:aHeader[nC,2]),oItems:aCols[nL][nC]))
								nConPAB++
							Endif
						Next
						MsUnLock()
						DbCommit()

					Endif
					DbSelectArea("QPAB")
					DbSkip()
				Enddo
				QPAB->(DbCloseArea())


				cQry := ""
				cQry += "SELECT COUNT(*) NCLI "
				cQry += "  FROM " + RetSqlName("SA1")
				cQry += " WHERE D_E_L_E_T_ = ' ' "
				cQry += "   AND A1_TRANSP != '"+oItems:aCols[nL,nPxTransp]+"' "
				cQry += "   AND A1_EST = '"+oItems:aCols[nL,nPxUf]+"' "
				cQry += "   AND A1_MUN = '"+StrTran(oItems:aCols[nL,nPxMun],"'","''")+"' "
				cQry += "   AND NOT EXISTS (SELECT ZK_CLIENTE "
				cQry += "                     FROM " + RetSqlName("SZK")+ " ZK "
				cQry += "                    WHERE D_E_L_E_T_ = ' ' "
				cQry += "                      AND ZK_TRANSP = A1_TRANSP "
				cQry += "                      AND ZK_CLIENTE = A1_COD "
				cQry += "                      AND ZK_LOJA = A1_LOJA "
				cQry += "                       AND '" + DTOS(Date()) + "' BETWEEN ZK_DTINI AND ZK_DTFIM)"
				cQry += "   AND A1_FILIAL = '"+xFilial("SA1")+"' "

				dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQry),'QSA1', .F., .T.)

				If !Eof()
					If lAtuAll  .Or. MsgYesNo("Serão atualizados '" + cValToChar(QSA1->NCLI) + "' clientes!","Atualizar Clientes?")
						nConSA1	+= QSA1->NCLI
						cQry := ""
						cQry += "UPDATE " + RetSqlName("SA1")
						cQry += "   SET A1_TRANSP = '"+oItems:aCols[nL,nPxTransp]+"' "
						cQry += " WHERE D_E_L_E_T_ = ' ' "
						cQry += "   AND A1_TRANSP != '"+oItems:aCols[nL,nPxTransp]+"' "
						cQry += "   AND A1_EST = '"+oItems:aCols[nL,nPxUf]+"' "
						cQry += "   AND A1_MUN = '"+StrTran(oItems:aCols[nL,nPxMun],"'","''")+"' "
						cQry += "   AND NOT EXISTS (SELECT ZK_CLIENTE "
						cQry += "                     FROM " + RetSqlName("SZK") +" ZK "
						cQry += "                    WHERE D_E_L_E_T_ = ' ' "
						cQry += "                      AND ZK_TRANSP = A1_TRANSP "
						cQry += "                      AND ZK_CLIENTE = A1_COD "
						cQry += "                      AND ZK_LOJA = A1_LOJA "
						cQry += "                      AND '" + DTOS(Date()) + "' BETWEEN ZK_DTINI AND ZK_DTFIM)"
						cQry += "   AND A1_FILIAL = '"+xFilial("SA1")+"' "
						Begin Transaction
							TcSqlExec(cQry)
						End Transaction
					Endif
				Endif
				QSA1->(DbCloseArea())

			Endif
		Next
		MsgStop(cValToChar(nConSA1) +  " Registro(s) Alterado(s) no cadastro de clientes!!","A V I S O!! BFFATA31.sfGrvPAB")
		MsgStop(Str(nConPAB)+" Registro(s) Alterado(s) no cadastro de CEPs!!","A V I S O!! BFFATA31.sfGrvPAB")
		// Gravação por agrupamento de Bairro/Municipio
	ElseIf oOpcAgrupa:nAt	== 2	// Bairro/Municipio
		ProcRegua(Len(oItems:aCols))
		For nL	:= 1 To Len(oItems:aCols)

			IncProc()

			If !oItems:aCols[nL,Len(oItems:aHeader)+1]
				cQry := ""
				cQry += "SELECT PAB_CODSEQ "
				cQry += "  FROM " + RetSqlName("PAB")
				cQry += " WHERE D_E_L_E_T_ = ' ' "
				cQry += "   AND PAB_UF = '"+oItems:aCols[nL,nPxUf]+"' "
				cQry += "   AND (PAB_TRANSP <> '" + oItems:aCols[nL,nPxTransp] + "' OR PAB_ROTA <> '" + oItems:aCols[nL,nPxRota] + "' OR PAB_PRAZO <> '" + oItems:aCols[nL,nPxPrazo] + "' OR PAB_CTRFIL <> '"+oItems:aCols[nL,nPxCtrFil]+"'  OR PAB_NTRFIL <> '"+oItems:aCols[nL,nPxNtrFil]+"')"
				cQry += "   AND PAB_BAIINI = '"+StrTran(oItems:aCols[nL,nPxBairro],"'","''")+"' "
				cQry += "   AND PAB_MUN = '"+StrTran(oItems:aCols[nL,nPxMun],"'","''")+"' "
				cQry += "   AND PAB_FILIAL = '"+xFilial("PAB")+"' "

				dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQry),'QPAB', .F., .T.)

				While !Eof()

					DbSelectArea("PAB")
					DbSetOrder(3)
					If DbSeek(xFilial("PAB")+QPAB->PAB_CODSEQ)
						RecLock("PAB",.F.)
						For nC := 1 To Len(oItems:aHeader)
							If Alltrim(oItems:aHeader[nC,2]) $ cHeadAlt
								PAB->(FieldPut(FieldPos(oItems:aHeader[nC,2]),oItems:aCols[nL][nC]))
								nConPAB++
							Endif
						Next
						MsUnLock()
						DbCommit()

					Endif
					DbSelectArea("QPAB")
					DbSkip()
				Enddo
				QPAB->(DbCloseArea())

				cQry := ""
				cQry += "SELECT COUNT(*) NCLI "
				cQry += "  FROM " + RetSqlName("SA1")
				cQry += " WHERE D_E_L_E_T_ = ' ' "
				cQry += "   AND A1_TRANSP != '"+oItems:aCols[nL,nPxTransp]+"' "
				cQry += "   AND A1_EST = '"+oItems:aCols[nL,nPxUf]+"' "
				cQry += "   AND A1_BAIRRO = '"+StrTran(oItems:aCols[nL,nPxBairro],"'","''")+"' "
				cQry += "   AND A1_MUN = '"+StrTran(oItems:aCols[nL,nPxMun],"'","''")+"' "
				cQry += "   AND NOT EXISTS (SELECT ZK_CLIENTE "
				cQry += "                     FROM " + RetSqlName("SZK")+ " ZK "
				cQry += "                    WHERE D_E_L_E_T_ = ' ' "
				cQry += "                      AND ZK_TRANSP = A1_TRANSP "
				cQry += "                      AND ZK_CLIENTE = A1_COD "
				cQry += "                      AND ZK_LOJA = A1_LOJA "
				cQry += "                      AND '" + DTOS(Date()) + "' BETWEEN ZK_DTINI AND ZK_DTFIM)"
				cQry += "   AND A1_FILIAL = '"+xFilial("SA1")+"' "

				dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQry),'QSA1', .F., .T.)

				If !Eof()
					If lAtuAll .Or. MsgYesNo("Serão atualizados '" + cValToChar(QSA1->NCLI) + "' clientes!","Atualizar Clientes?")

						cQry := ""
						cQry += "UPDATE " + RetSqlName("SA1")
						cQry += "   SET A1_TRANSP = '"+oItems:aCols[nL,nPxTransp]+"' "
						cQry += " WHERE D_E_L_E_T_ = ' ' "
						cQry += "   AND A1_TRANSP != '"+oItems:aCols[nL,nPxTransp]+"' "
						cQry += "   AND A1_EST = '"+oItems:aCols[nL,nPxUf]+"' "
						cQry += "   AND A1_BAIRRO = '"+StrTran(oItems:aCols[nL,nPxBairro],"'","''")+"' "
						cQry += "   AND A1_MUN = '"+StrTran(oItems:aCols[nL,nPxMun],"'","''")+"' "
						cQry += "   AND NOT EXISTS (SELECT ZK_CLIENTE "
						cQry += "                     FROM " + RetSqlName("SZK") +" ZK "
						cQry += "                    WHERE D_E_L_E_T_ = ' ' "
						cQry += "                      AND ZK_TRANSP = A1_TRANSP "
						cQry += "                      AND ZK_CLIENTE = A1_COD "
						cQry += "                      AND ZK_LOJA = A1_LOJA "
						cQry += "                      AND '" + DTOS(Date()) + "' BETWEEN ZK_DTINI AND ZK_DTFIM)"
						cQry += "   AND A1_FILIAL = '"+xFilial("SA1")+"' "
						Begin Transaction
							TcSqlExec(cQry)
						End Transaction
					Endif
				Endif
				QSA1->(DbCloseArea())
			Endif
		Next
		MsgStop("Registro(s) Alterado(s) no cadastro de clientes!!","A V I S O!! BFFATA31.sfGrvPAB")
		MsgStop(Str(nConPAB)+" Registro(s) Alterado(s) no cadastro de CEPs!!","A V I S O!! BFFATA31.sfGrvPAB")
	Endif
	Processa({|| sfMontaAcols()},"Aguarde...","Carregando dados",.F.)

Return


/*/{Protheus.doc} sfAtuAdmPAB
(Atualização de dados na PAB)
@author MarceloLauschner
@since 18/04/2014
@version 1.0
@param lAtuCli,lógico, (Se deverá fazer a atualização de clientes ou não)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfAtuAdmPAB(lAtuCli)

	Local		nConPAB	:= 0
	Local		nL,nL2
	Local		cQry
	Local		lDelLin	:= MsgNoYes("Deseja apagar os registros na PAB que estão deletados nesta tela? ")
	Default	lAtuCli	:= .F.

	If oOpcAgrupa:nAt	== 3
		For nL	:= 1 To Len(oItems:aCols)
			If oItems:aCols[nL,Len(oItems:aHeader)+1]
				If lDelLin
					DbSelectArea("PAB")
					DbSetOrder(3)
					If DbSeek(xFilial("PAB")+oItems:aCols[nL,nPxCodSeq])
						RecLock("PAB",.F.)
						DbDelete()
						MsUnlock()
					Endif
				Endif
			Else
				DbSelectArea("PAB")
				DbSetOrder(3)
				If DbSeek(xFilial("PAB")+oItems:aCols[nL,nPxCodSeq])
					RecLock("PAB",.F.)
					For nL2 := 1 To Len(oItems:aHeader)
						If ( oItems:aHeader[nL2][10] <> "V" )
							PAB->(FieldPut(FieldPos(oItems:aHeader[nL2][2]),oItems:aCols[nL][nL2]))
						EndIf
					Next
					MsUnLock()
				Endif

				If lAtuCli
					cQry := ""
					cQry += "UPDATE " + RetSqlName("SA1")
					cQry += "   SET A1_TRANSP = '"+oItems:aCols[nL,nPxTransp]+"' "
					cQry += " WHERE D_E_L_E_T_ = ' ' "
					cQry += "   AND A1_EST = '"+oItems:aCols[nL,nPxUf]+"' "
					cQry += "   AND A1_CEP = '"+StrTran(oItems:aCols[nL,nPxCep],"'","''")+"' "
					cQry += "   AND A1_MUN = '"+StrTran(oItems:aCols[nL,nPxMun],"'","''")+"' "
					cQry += "   AND A1_FILIAL = '"+xFilial("SA1")+"' "

					TcSqlExec(cQry)
				Endif
			Endif
			nConPAB++
		Next
		If lAtuCli
			MsgStop("Registro(s) Alterado(s) no cadastro de clientes!!","A V I S O!! BFFATA31.sfGrvPAB")
		Endif
		MsgStop(Str(nConPAB)+" Registro(s) Alterado(s) no cadastro de CEPs!!","A V I S O! BFFATA31.sfAtuAdmPAB ")
	Else
		MsgAlert("Esta opção para gravar dados da Tabela só é possível quando estiver selecionada a opção 'C=Cep' na opção de agrupamento","A T E N Ç Ã O!! BFFATA31.sfAtuAdmPAB")
	Endif

	Processa({|| sfMontaAcols()},"Aguarde...","Carregando dados",.F.)


Return


/*/{Protheus.doc} sfVldTransp
(Valida a digitação de transportadora)
@author MarceloLauschner
@since 18/04/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfVldTransp()
	Local	lRet	:= .F.

	If oOpcFiltra:nAt == 1 .And. ExistCpo("SA4",cTransp)
		lRet	:= .T.
		Processa({|| sfMontaAcols()},"Aguarde...","Carregando dados",.F.)
	ElseIf Empty(cTransp)
		lRet	:= .T.
		Processa({|| sfMontaAcols()},"Aguarde...","Carregando dados",.F.)
	Else
		MsgInfo("Favor não informar código de transportadora","BFFATA31.sfVldTransp")
	Endif

Return lRet



Static Function sfVldMun()

	Local	lRet	:= .F.

	If oOpcMun:nAt == 1 .And. ExistCpo("CC2",cMunic,2)
		lRet	:= .T.
		cMunic	:= StrTran(cMunic,"'","''")
		Processa({|| sfMontaAcols()},"Aguarde...","Carregando dados",.F.)
	ElseIf Empty(cMunic)
		lRet	:= .T.
		Processa({|| sfMontaAcols()},"Aguarde...","Carregando dados",.F.)
	Else
		MsgInfo("Favor não informar nome de cidade!","BFFATA31.sfVldMun")
	Endif

Return lRet



Static Function sfVldReg()

	Local	lRet	:= .T.

	Processa({|| sfMontaAcols()},"Aguarde...","Carregando dados",.F.)

Return lRet

/*/{Protheus.doc} sfMontaAcols
(Efetua montagem dos dados do getdados para atualização)
@author MarceloLauschner
@since 18/04/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfMontaAcols()

	Local	iC
	Local	cQry

	oItems:aCols	:= {}

	cQry := ""
	cQry += "SELECT "
	If oOpcAgrupa:nAt	== 1	// Municipio
		cQry += "   ' ' PAB_CEP, ' ' PAB_BAIINI,' ' PAB_END,' ' PAB_CODSEQ, "
	ElseIf oOpcAgrupa:nAt	== 2	// Bairro/Municipio
		cQry += "   ' ' PAB_CEP, PAB_BAIINI,' ' PAB_END,' ' PAB_CODSEQ, "
	ElseIf oOpcAgrupa:nAt	== 3	// CEP
		cQry += "   PAB_CEP,PAB_BAIINI,PAB_END,PAB_CODSEQ, "
	Endif
	cQry += "       PAB_UF,PAB_MUN,PAB_ROTA,PAB_PRAZO,PAB_CTRFIL,PAB_NTRFIL,PAB_TRANSP "
	cQry += "  FROM "+RetSqlName("PAB")
	cQry += " WHERE D_E_L_E_T_ = ' ' "
	cQry += "   AND PAB_UF = '"+oUf:aItems[oUf:nAt]+"' "
	If oOpcFiltra:nAt == 1 // Sim para filtrar por transportadora
		cQry += "  AND PAB_TRANSP = '"+cTransp+"' "
	Endif

	If !Empty(cRegiao)
		cQry += "  AND PAB_CTRFIL = '"+cRegiao+"' "
	Endif
	If !Empty(cSubReg)
		cQry += "  AND PAB_NTRFIL = '"+cSubReg+"' "
	Endif

	If oOpcMun:nAt == 1 // Sim para filtrar por transportadora
		cQry += "  AND PAB_MUN = '"+cMunic+"' "
	Endif

	cQry += "   AND PAB_FILIAL = '" +xFilial("PAB")+ "' "
	cQry += " GROUP BY "
	If oOpcAgrupa:nAt	== 1	// Municipio
		//cQry += "   1,2,3,4, "
	ElseIf oOpcAgrupa:nAt	== 2	// Bairro/Municipio
		//cQry += "   1,PAB_BAIINI,3,4, "
		cQry += "   PAB_BAIINI, "
	ElseIf oOpcAgrupa:nAt	== 3	// CEP
		cQry += "   PAB_CEP,PAB_BAIINI,PAB_END,PAB_CODSEQ, "
	Endif
	cQry += " PAB_UF,PAB_MUN,PAB_ROTA,PAB_PRAZO,PAB_CTRFIL,PAB_NTRFIL,PAB_TRANSP"
	cQry += " ORDER BY 6,2,1 "


	TCQUERY cQry NEW ALIAS "QRY"

	While !Eof()


		Aadd(oItems:aCols,Array(Len(oItems:aHeader)+1))

		For iC := 1 To Len(oItems:aHeader)

			If QRY->(FieldPos(oItems:aHeader[iC,2])) > 0
				oItems:aCols[Len(oItems:aCols)][iC]	:= 	QRY->(FieldGet(FieldPos(oItems:aHeader[iC,2])))
			ElseIf aHeader[iC][8] == "C"
				oItems:aCols[Len(oItems:aCols)][iC] 	:= Space(oItems:aHeader[IC][4])
			ElseIf aHeader[iC][8] == "D"
				oItems:aCols[Len(oItems:aCols)][iC] 	:= dDataBase
			ElseIf aHeader[iC][8] == "M"
				oItems:aCols[Len(oItems:aCols)][iC]	:= ""
			ElseIf aHeader[iC][8] == "N"
				oItems:aCols[Len(oItems:aCols)][iC] 	:= 0
			Else
				oItems:aCols[Len(oItems:aCols)][iC] 	:= .F.
			Endif

			//oItems:aCols[Len(oItems:aCols)][iC]	:= QRY->(&(oItems:aHeader[iC][2]))
		Next
		oItems:aCols[Len(oItems:aCols),Len(oItems:aHeader)+1]	:= .T.

		dbSelectArea("QRY")
		dbSkip()
	End
	QRY->(DbCloseArea())

	If Len(oItems:aCols) <= 0
		Aadd(oItems:aCols,Array(Len(oItems:aHeader)+1))
		For iC := 1 To Len(oItems:aHeader)
			oItems:aCols[Len(oItems:aCols)][iC]	:= CriaVar(oItems:aHeader[iC][2],.T.)
		Next
		oItems:aCols[Len(oItems:aCols),Len(oItems:aHeader)+1]	:= .F.
	Endif
	oItems:Refresh()

Return




/*/{Protheus.doc} BFATA31A
(Validação a opção de deletar linhas do getdados)
@author MarceloLauschner
@since 18/04/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFATA31A()

	Local		lRet		:= .F.
	If lIsSuper .And. oOpcAgrupa:nAt == 3
		lRet	:= .T.
	ElseIf oOpcAgrupa:nAt == 1
		lRet	:= .T. // MsgYesNo("Deseja "+Iif(!oItems:aCols[oItems:nAt,Len(oItems:aHeader)+1],"desmarcar","marcar")+" este Município para ser atualizado?","BFFATA31.BFATA31A")
	ElseIf oOpcAgrupa:nAt == 2
		lRet	:= MsgYesNo("Deseja "+Iif(!oItems:aCols[oItems:nAt,Len(oItems:aHeader)+1],"desmarcar","marcar")+" este Bairro/Município para ser atualizado?","BFFATA31.BFATA31A")
	Endif

Return lRet



Static Function sfGeraPlan()

	//Variáveis para Geração Excel
	Local oFwMsEx		:= NIL
	Local cArq			:= ""
	Local cDir			:= GetSrvProfString("Startpath","")
	Local cWork_1		:= "Grade " + cUF
	Local cTable_1		:= "DATA DE ENTREGA (SEG/TER/QUA/QUI/SEX)" + CRLF + "DIA DO FATURAMENTO (2ª/3ª/4ª/5ª/6ª)	"
	Local cDirTmp		:= GetTempPath()
	Local cCadastro		:= "GRADE DE ENTREGAS - " + cUF

	// cria planilha com a guia k001
	oFwMsEx := FWMsExcel():New()
	oFwMsEx:AddWorkSheet( cWork_1 )
	oFwMsEx:AddTable( cWork_1, cTable_1 )

	// adiciona as colunas
	oFwMsEx:AddColumn( cWork_1, cTable_1 , "Município"	  	,1,1)
	oFwMsEx:AddColumn( cWork_1, cTable_1 , "Transportadora" ,1,1)
	oFwMsEx:AddColumn( cWork_1, cTable_1 , "Filial" 		,1,1)
	oFwMsEx:AddColumn( cWork_1, cTable_1 , "Prazo"		 	,1,1)
	oFwMsEx:AddColumn( cWork_1, cTable_1 , " SEG "			,1,1)
	oFwMsEx:AddColumn( cWork_1, cTable_1 , " TER "			,1,1)
	oFwMsEx:AddColumn( cWork_1, cTable_1 , " QUA "			,1,1)
	oFwMsEx:AddColumn( cWork_1, cTable_1 , " QUI "			,1,1)
	oFwMsEx:AddColumn( cWork_1, cTable_1 , " SEX "			,1,1)


	sfAddRow(@oFwMsEx,cWork_1/*cInWork*/,cTable_1/*cInTable*/)

	oFwMsEx:Activate()

	cArq := GetNextALias()+".xml"//CriaTrab( Nil, .F. ) + ".xml"
	MsgRun( "Gerando o arquivo, aguarde...", cCadastro, {|| oFwMsEx:GetXMLFile( cArq ) } )
	IF __CopyFile( cArq, cDirTmp + cArq )
		oExcelApp := MsExcel():New()
		oExcelApp:WorkBooks:Open( cDirTmp + cArq )
		oExcelApp:SetVisible(.T.)
	ELSE
		MsgInfo( "Arquivo não copiado para temporário do usuário." )
	EndIF

Return


Static Function sfAddRow(oInFwMEx,cInWork,cInTable)
	Local	aAuxExp	:= {}
	Local	nL

	For nL	:= 1 To Len(oItems:aCols)


		Aadd(aAuxExp,oItems:aCols[nL,nPxMun])
		Aadd(aAuxExp,oItems:aCols[nL,nPxTransp] + " - " + Posicione("SA4",1,xFilial("SA4")+oItems:aCols[nL,nPxTransp],"A4_NREDUZ"))
		Aadd(aAuxExp,oItems:aCols[nL,nPxCtrFil])
		Aadd(aAuxExp,Substr(oItems:aCols[nL,nPxPrazo],1,2) + " Hs")
		Aadd(aAuxExp,sfCaldDia("2",oItems:aCols[nL,nPxRota],oItems:aCols[nL,nPxPrazo]))
		Aadd(aAuxExp,sfCaldDia("3",oItems:aCols[nL,nPxRota],oItems:aCols[nL,nPxPrazo]))
		Aadd(aAuxExp,sfCaldDia("4",oItems:aCols[nL,nPxRota],oItems:aCols[nL,nPxPrazo]))
		Aadd(aAuxExp,sfCaldDia("5",oItems:aCols[nL,nPxRota],oItems:aCols[nL,nPxPrazo]))
		Aadd(aAuxExp,sfCaldDia("6",oItems:aCols[nL,nPxRota],oItems:aCols[nL,nPxPrazo]))

		oInFwMEx:AddRow( cInWork, cInTable, aAuxExp , 1)

		aAuxExp	:= {}

	Next

Return

Static Function sfCaldDia(cInDia,cInRota,cInPzHrs)
	Local	cOut		:= ""
	Local	nDias		:= Int(Val(cInPzHrs) / 24)
	Local	nDiaEnt		:= 1
	Local	iX
	Local	nDiaRota	:= 1

	For iX := 1 To Len(AllTrim(cInRota)) Step 1
		nDiaRota	:= Val(SubStr(cInRota,iX,1))
		nDiaEnt		:= nDiaRota + nDias

		If nDiaEnt >= 7 .And. nDiaEnt <= 11// Se cai no fim de semana
			nDiaEnt += 2
			nDiaEnt -= 7
		ElseIf nDiaEnt >= 12
			nDiaEnt += 2
			nDiaEnt -= 7
			nDiaEnt += 2
			nDiaEnt -= 7
		Endif

		If nDiaEnt == Val(cInDia)
			cOut	:= cValToChar(nDiaRota) + "ª-Feira"
			Exit
		Endif
	Next

Return cOut
