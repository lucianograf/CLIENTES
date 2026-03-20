#Include 'Protheus.ch'
#INCLUDE "TBICONN.CH"

/*/{Protheus.doc} BFFATM39
(Rotina para importação de planilha com lista de produtos e quantidades para efetuar transferência de Armazém
@type User Function 
@author Marcelo Alberto Lauschner
@since 13/12/2018
@version 1.0
@return Nil
@example
(examples)
@see (links_or_references)
/*/
User Function BFFATM39()

	Private 	oDlgImp
	Private 	cLocOri		:= Space(TamSX3("D3_LOCAL")[1])
	Private 	cLocDes		:= Space(TamSX3("D3_LOCAL")[1])
	Private 	cArqImp		:= Space(150)
	Private 	oArqIMp,oDescEnt
	Private		cDescEnt	:= Space(50)
	Private		aCols,aHeader
	Private 	aButton		:= {{"VERDE"		,{|| mata261()}  ,"Transf Mod.2"},{"VERDE"		,{|| mata260()}  ,"Transf Mod.1"}}
	Private 	aSize := MsAdvSize(,.F.,400)

	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()

	DEFINE MSDIALOG oDlgImp TITLE OemToAnsi("Importação Planilha para Transferência de Armazém") From aSize[7],0 to aSize[6],aSize[5] OF oMainWnd PIXEL

	oDlgImp:lMaximized := .T.

	oPanel1 := TPanel():New(0,0,'',oDlgImp, oDlgImp:oFont, .T., .T.,, ,200,45,.T.,.T. )
	oPanel1:Align := CONTROL_ALIGN_TOP

	oPanel2 := TPanel():New(0,0,'',oDlgImp, oDlgImp:oFont, .T., .T.,, ,200,40,.T.,.T. )
	oPanel2:Align := CONTROL_ALIGN_ALLCLIENT

	oPanel3 := TPanel():New(0,0,'',oDlgImp, oDlgImp:oFont, .T., .T.,, ,200,60,.T.,.T. )
	oPanel3:Align := CONTROL_ALIGN_BOTTOM


	DEFINE FONT oFnt 	NAME "Arial" SIZE 0, -11 BOLD

	@ 012 ,005  	Say OemToAnsi("Armazém de Origeml") SIZE 60,9 PIXEl OF oPanel1 FONT oFnt
	@ 011 ,073  	MSGET cLocOri  Picture PesqPict("SD3","D3_LOCAL") Valid (ExistCpo("NNR",cLocOri) .And. cLocOri <> cLocDes) PIXEl SIZE 55, 10 OF oPanel1 HASBUTTON

	@ 025 ,005  	Say OemToAnsi("Armazém de Destino") SIZE 60,9 PIXEl OF oPanel1 FONT oFnt
	@ 024 ,073  	MSGET cLocDes  Picture PesqPict("SD3","D3_LOCAL") Valid (ExistCpo("NNR",cLocDes) .And. cLocDes <> cLocOri) PIXEl SIZE 55, 10 OF oPanel1 HASBUTTON

	@ 012 ,153   	Say OemToAnsi("Arquivo") SIZE 30,9 PIXEl	OF oPanel1 FONT oFnt
	@ 011 ,191		MSGET oArqIMp VAR cArqImp Picture "@!" PIXEl SIZE 132, 10 OF oPanel1 Valid (cArqImp := cGetFile( "Arquivos CSV(*.csv) | *.csv", "Selecione o Arquivo",,"C:\EDI\",.T., ),Processa({|| sfCarrega(@oMulti:aCols,@oMulti:aHeader,2)},"Carregando dados..."))

	Processa({|| sfCarrega(@aCols,@aHeader,1) },"Localizando registros...")

	Private oMulti := MsNewGetDados():New(034, 005, 226, 415,,"AllwaysTrue()"/*cLinhaOk*/,;
	"AllwaysTrue()"/*cTudoOk*/,"",;
	,0/*nFreeze*/,10000/*nMax*/,"AllwaysTrue()"/*cCampoOk*/,/*cSuperApagar*/,;
	/*cApagaOk*/,oPanel2,@aHeader,@aCols,{|| sfAtuRodp() })

	oMulti:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT


	ACTIVATE MSDIALOG oDlgImp ON INIT (oMulti:oBrowse:Refresh(),EnchoiceBar(oDlgImp,{|| Processa({||sfGrvDados(oMulti,"SD3")},"Efetuando gravações...") , oDlgImp:End() },{|| oDlgImp:End()},,aButton))

Return 




/*/{Protheus.doc} sfCarrega
(Monta aCols e aHeader para o Getdados)
@type function
@author marce
@since 11/06/2016
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
	Local	aCpo		:=  {"D3_COD","D3_DESCRI","D3_UM","D3_QUANT","D3_OBSERVA","D3_QTSEGUM"}
	Local	lTabRows	:= .F.	// Indica se o arquivo está no formato de preços em linhas
	Local	cUsado		:= ""
	Local	iX,nI,nColuna
	Local	aArrDados	:= {}
	Local	nPosCod		:= 0
	Local	nPosQte		:= 0
	Local	nPosObs		:= 0
	Local oTmpTable := NIL
	aCols			:= 	{}
	aHeader			:=	{}


	DbSelectArea("SX3")
	DbSetOrder(2)
	For iX := 1 To Len(aCpo)
		If DbSeek(aCpo[iX])
			Aadd(aHeader,{ AllTrim(X3Titulo()),;
			GetSx3Cache(cCampo,"X3_CAMPO")	,;
			GetSx3Cache(cCampo,"X3_PICTURE"),;
			GetSx3Cache(cCampo,"X3_TAMANHO"),;
			GetSx3Cache(cCampo,"X3_DECIMAL"),;
			"AllwaysFalse()"	,;
			GetSx3Cache(cCampo,"X3_USADO")	,;
			GetSx3Cache(cCampo,"X3_TIPO")	,;
			GetSx3Cache(cCampo,"X3_F3") 		,;
			GetSx3Cache(cCampo,"X3_CONTEXT"),;
			GetSx3Cache(cCampo,"X3_CBOX")	,;
			""}) //SX3->X3_RELACAO })
			nUsado++
			If aCpo[iX] == "D3_DESCRI"
				cUsado	:= GetSx3Cache(cCampo,"X3_USADO")
			Endif
			If Alltrim(GetSx3Cache(cCampo,"X3_CAMPO")) == "D3_COD"
				nPosCod	:= nUsado
			ElseIf Alltrim(GetSx3Cache(cCampo,"X3_CAMPO")) == "D3_QUANT"
				nPosQte	:= nUsado
			ElseIf Alltrim(GetSx3Cache(cCampo,"X3_CAMPO")) == "D3_OBSERVA"
				nPosObs	:= nUsado			
			Endif
		Endif
	Next

	DbSelectArea("DA1")
	DbSetOrder(1)
	// Se for chamado a partir da rotina de atualização do arquivo de importação
	If nRefrBox == 2 .And. cArqImp <> Nil .And. File(cArqImp)

		aCampos:={}
		AADD(aCampos,{ "LINHA" ,"C",680,0 })

		//cNomArq := CriaTrab(aCampos)

		If (Select("TRB") <> 0)
			dbSelectArea("TRB")
			dbCloseArea("TRB")
		Endif
		//dbUseArea(.T.,,cNomArq,"TRB",nil,.F.)
		oTmpTable := FWTemporaryTable():New("TRB",aCampos)
		oTmpTable:Create()

		dbSelectArea("TRB")
		Append From (cArqImp) SDF

		ProcRegua(RecCount())

		DbSelectArea("TRB")
		DbGotop()
		While !Eof()

			IncProc()

			aArrDados	:= StrTokArr(TRB->LINHA+";",";")
			// Layout Esperado
			// CODPRODUTO;QUANTIDADE;
			// 123456789012345;1;
			If Alltrim(aArrDados[1]) == "CODPRODUTO" .And. Alltrim(aArrDados[2]) == "QUANTIDADE" 
				lTabRows	:= .T.				
			ElseIf lTabRows .And. Len(aArrDados) == 2 .And. Val(StrTran(StrTran(aArrDados[2],".",""),",",".")) > 0

				Aadd(aCols,Array(Len(aHeader)+1))

				aCols[Len(aCols),Len(aHeader)+1]	:= .F.

				For nI := 1 To Len(aHeader)

					If Alltrim(aHeader[nI][2]) == "D3_COD"
						aCols[Len(aCols)][nI]				:= Padr(aArrDados[1],TamSX3("D3_COD")[1])

						DbSelectArea("SB1")
						DbSetOrder(1)
						If DbSeek(xFilial("SB1")+aArrDados[1])
							aCols[Len(aCols),Len(aHeader)+1]	:= .F.							
						Else
							aCols[Len(aCols),Len(aHeader)+1]	:= .T.
							aCols[Len(aCols),nPosObs]			:= "Produto '" + aArrDados[1]+ "' não cadastrado no Sistema."
						Endif

					ElseIf Alltrim(aHeader[nI][2]) == "D3_QUANT"

						aCols[Len(aCols)][nI] 	:= Val(StrTran(StrTran(aArrDados[2],".",""),",","."))

						DbSelectArea("SB2")
						DbSetOrder(1) // B2_FILIAL+B2_COD+B2_LOCAL
						If DbSeek(xFilial("SB2")+aCols[Len(aCols)][nPosCod]+cLocOri) 
							If (SB2->B2_QATU - SB2->B2_RESERVA) >=  aCols[Len(aCols)][nI]
								aCols[Len(aCols),Len(aHeader)+1]	:= .F.		
							Else
								aCols[Len(aCols),Len(aHeader)+1]	:= .T.
								aCols[Len(aCols),nPosObs]			:= "Produto '" + aArrDados[1]+ "' com saldo de '" + cValToChar((SB2->B2_QATU - SB2->B2_RESERVA) )+ "' insuficiente para transferência."
							Endif
						Else
							aCols[Len(aCols),Len(aHeader)+1]	:= .T.
							aCols[Len(aCols),nPosObs]			:= "Produto '" + aArrDados[1]+ "' sem cadastro no armazém de origem."
						Endif

					ElseIf Alltrim(aHeader[nI][2]) == "D3_QTSEGUM"

						aCols[Len(aCols)][nI]	:= ConvUm( aCols[Len(aCols),nPosCod],aCols[Len(aCols),nPosQte],aCols[Len(aCols),nPosQte],2 )

					ElseIf Alltrim(aHeader[nI][2]) == "D3_DESCRI"
						aCols[Len(aCols)][nI]	:= SB1->B1_DESC
					ElseIf Alltrim(aHeader[nI][2]) == "D3_UM"
						aCols[Len(aCols)][nI]	:= SB1->B1_UM
					ElseIf Alltrim(aHeader[nI][2]) == "D3_OBSERVA"
						aCols[Len(aCols)][nI]	:= IIf(aCols[Len(aCols),nPosObs] <> Nil,aCols[Len(aCols),nPosObs],CriaVar(aHeader[nI][2],.T.))
					Else
						aCols[Len(aCols)][nI] := CriaVar(aHeader[nI][2],.T.)
					Endif
				Next
				// Verifica se existe SB2 para o produto
				DbSelectArea("SB2")
				DbSetOrder(1) // B2_FILIAL+B2_COD+B2_LOCAL
				If DbSeek(xFilial("SB2")+aCols[Len(aCols)][nPosCod]+cLocDes) 

				Else
					// Cria local
					If !aCols[Len(aCols),Len(aHeader)+1]
						CriaSB2(aCols[Len(aCols)][nPosCod],cLocDes)
					Endif 
				Endif		
			Endif
			DbSelectArea("TRB")
			DbSkip()
		Enddo

		TRB->(DbCloseArea())


		FErase(cNomArq + GetDbExtension()) // Deleting file
		FErase(cNomArq + OrdBagExt()) // Deleting index

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
			//aCols[Len(aCols)][nColuna] := CriaVar(aHeader[nColuna][2],.T.)


		Next nColuna
		aCols[Len(aCols),Len(aHeader)+1]	:= .F.
	Endif

	If Type("oMulti") <> "U"
		oMulti:oBrowse:Refresh()
		sfAtuRodp()
	Endif

Return




/*/{Protheus.doc} sfGrvDados
(Efetua gravação dos dados)
@type function
@author marce
@since 11/06/2016
@version 1.0
@param oInGet, objeto, (Descrição do parâmetro)
@param cInAlias, character, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfGrvDados(oInGet,cInAlias)

	Local	nLenCols	:= 0
	Local	nLenHead	:= 0
	Local	oGetNz
	Local	nX,nY 
	Local	cCodPrd		:= ""	
	Local	nQteMov		:= 0
	Local	nQteSeg		:= 0

	// Cria valores dinânimcos
	// Número de linha do Getdados
	nLenCols	:= Len(oInGet:aCols)
	// Número de colunas do Getdados
	nLenHead	:= Len(oInGet:aHeader)

	For nX := 1 To nLenCols

		If !(oInGet:aCols[nX,Len(oInGet:aHeader)+1])
			For nY := 1 To Len(oInGet:aHeader)
				If oInGet:aHeader[nY][2] == "D3_COD    "
					cCodPrd				:= oInGet:aCols[nX][nY]
				ElseIf oInGet:aHeader[nY][2] == "D3_QUANT  "
					nQteMov				:= oInGet:aCols[nX][nY]
				ElseIf oInGet:aHeader[nY][2] == "D3_QTSEGUM"
					nQteSeg				:= oInGet:aCols[nX][nY]
				EndIf
			Next nY

			DbSelectArea("SB1")
			DbSetOrder(1)
			If DbSeek(xFilial("SB1")+cCodPrd)
				//sfTransf(cProd	,cDescri		,cUM		,cLocOri,cEndOri,cLocDes,cEndDes,cLote	,dDatVal				,nInQuant	,nInQte2UM)
				sfTransf(SB1->B1_COD,SB1->B1_DESC	,SB1->B1_UM	,cLocOri,""		,cLocDes,""		,""		,CriaVar("D3_DTVALID")	,nQteMov	,nQteSeg)
			Endif
		Endif
	Next nX

	MsgInfo("Dados gravados com sucesso!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))

Return


/*/{Protheus.doc} sfAtuRodp
(Atualiza informações de rodapé)
@type function
@author marce
@since 13/06/2016
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfAtuRodp()


Return




Static Function sfTransf(cProd,cDescri,cUM,cLocOri,cEndOri,cLocDes,cEndDes,cLote,dDatVal,nInQuant,nInQte2UM)

	Local 	nOpcAuto 	:= 3 // Indica qual tipo de acao sera tomada (Inclusao/Exclusao)
	Local 	cNextNumSeq	:= ""
	Local 	aItem		:= {}
	Local 	aAuto		:= {}
	Local 	lRet		:= .T.
	Local	cNDoc		
	Private	lMsErroAuto := .F.
	Private lMsHelpAuto := .T.

	Begin Transaction // Teste de Inclusao

		cNDoc	:= GetSXENum("SD3","D3_DOC")
		//Cabecalho a Incluir
		aAuto := {}
		Aadd(aAuto,{cNDoc,dDataBase}	) 	//Cabecalho
		//
		/*O Campos necessarios sao:
		Titulo     Campo      Tipo Tamanho Decimal
		---------- ---------- ---- ------- -------
		Prod.Orig. D3_COD      C        15       0
		Desc.Orig. D3_DESCRI   C        30       0
		UM Orig.   D3_UM       C         2       0
		Armazem Or D3_LOCAL    C         2       0
		Endereco O D3_LOCALIZ  C        15       0
		Prod.Desti D3_COD      C        15       0
		Desc.Desti D3_DESCRI   C        30       0
		UM Destino D3_UM       C         2       0
		Armazem De D3_LOCAL    C         2       0
		Endereco D D3_LOCALIZ  C        15       0
		Numero Ser D3_NUMSERI  C        20       0
		Lote       D3_LOTECTL  C        10       0
		Sub-Lote   D3_NUMLOTE  C         6       0
		Validade   D3_DTVALID  D         8       0
		Potencia   D3_POTENCI  N         6       2
		Quantidade D3_QUANT    N        12       3
		Qt 2aUM    D3_QTSEGUM  N        12       2
		Estornado  D3_ESTORNO  C         1       0
		Sequencia  D3_NUMSEQ   C         6       0
		Lote Desti D3_LOTECTL  C        10       0
		Validade D D3_DTVALID  D         8       0
		Item Grade D3_ITEMGRD  C         3       0
		Observação D3_OBSERVA  C        30       0*/

		//Itens a Incluir
		Aadd(aItem,cProd								) 	//D3_COD 		(Origem)
		Aadd(aItem,cDescri								)  	//D3_DESCRI 	(Origem)
		Aadd(aItem,cUM									) 	//D3_UM  		(Origem)
		Aadd(aItem,cLocOri								) 	//D3_LOCAL  	(Origem)
		Aadd(aItem,cEndOri								)   //D3_LOCALIZ    (Origem)
		Aadd(aItem,cProd								) 	//D3_COD  		(Destino)
		Aadd(aItem,cDescri								)  	//D3_DESCRI    	(Destino)
		Aadd(aItem,cUM									)   //D3_UM  		(Destino)
		Aadd(aItem,cLocDes								)   //D3_LOCAL  	(Destino)
		Aadd(aItem,cEndDes								)   //D3_LOCALIZ    (Destino)
		Aadd(aItem,""									)   //D3_NUMSERI
		Aadd(aItem,cLote								)   //D3_LOTECTL	(Origem)
		Aadd(aItem,""									)   //D3_NUMLOTE	
		Aadd(aItem,dDatVal								)   //D3_DTVALID
		Aadd(aItem,0									) 	//D3_POTENCI
		Aadd(aItem,nInQuant								)   //D3_QUANT
		Aadd(aItem,nInQte2UM							)   //D3_QTSEGUM
		Aadd(aItem,""									)   //D3_ESTORNO
		Aadd(aItem,CriaVar("D3_NUMSEQ")					)   //D3_NUMSEQ		
		Aadd(aItem,cLote								)   //D3_LOTECTL	(Destino)
		Aadd(aItem,dDatVal								)   //D3_DTVALID	(Destino)
		Aadd(aItem,""									)   //D3_ITEMGRD	(Item grade)
		Aadd(aitem,Padr("TRANSF.DE " + Alltrim(cLocOri) + " P/" + Alltrim(cLocDes),TamSX3("D3_OBSERVA")[1])		)	//D3_OBSERVA

		Aadd(aAuto,aItem)

		MSExecAuto({|x,y| mata261(x,y)},aAuto,nOpcAuto)

		If !lMsErroAuto
			//MsgInfo("Transferência com sucesso! Número Doc: " +cNDoc)
		Else
			lRet	:= .F. 
			MostraErro()
			DisarmTransaction()
		EndIf
		FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "Fim  : "+Time()/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	End Transaction

Return lRet
