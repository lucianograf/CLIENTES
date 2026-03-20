#INCLUDE "TOPCONN.CH"
#INCLUDE "PROTHEUS.CH"


/*/{Protheus.doc} FOR009B
// Função para Replicação de Cadastro de Tampas
@author Marcelo Alberto Lauschner
@since 19/04/2019
@version 1.0
@return Nil
@type User Function
/*/
User Function FOR009B

	Local	cCadastro1  := ""

	Local	oScl
	Local	aScl		:= {}
	Local	cSc9		:= ""
	Local	cVarPesq	:= Space(6)
	Local	oDlgSZ8	
	Local	oNoMarked  	:= LoadBitmap( GetResources(), "LBNO" )
	Local	oMarked    	:= LoadBitmap( GetResources(), "LBOK" )

	//sfVldPerg()

	U_GRAVASX1("FOR009","07",cFilAnt) // Sempre grava a Filial Atual 
	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()

	If !Pergunte("FOR009",.T.)
		Return
	Endif

	If !sfSelReg(@aScl)
		Return 
	Endif

	DbSelectArea("SA1")
	DbSetOrder(1)
	DbSeek(xFilial("SA1")+MV_PAR03+MV_PAR04)

	cCadastro1	:= OemToAnsi("Selecione os produtos que devem ser replicados para o cliente " + SA1->A1_COD + "/" + SA1->A1_LOJA + "-" + Alltrim(SA1->A1_NREDUZ) + " - " + Alltrim(SA1->A1_MUN) )

	DEFINE MSDIALOG oDlgSZ8 FROM 000,000 TO 600,1200 OF oMainWnd PIXEL TITLE cCadastro1

	@ 010,005 LISTBOX oScl VAR cSc9 ;
	Fields HEADER " ",;    	//1
	" ",;                  		//2
	"Código Produto",;     		//3
	"Descrição",;             	//4
	"Valor Tampa",;				//5
	"R$ Custo Adicional",;		//6
	"Tipo Reembolso",;			//7
	"Data Inicio",;				//8
	"Data Final";				//9
	SIZE 590, 260;
	ON DBLCLICK (sfInverte(@oScl,@aScl)) OF oDlgSZ8 PIXEL
	oScl:nFreeze := 2
	oScl:SetArray(aScl)
	oScl:bLine:={ ||{sfLegenda(@oScl,@aScl),;
	Iif(aScl[oScl:nAT,02],oMarked,oNoMarked),;
	aScl[oScl:nAT,03],;
	aScl[oScl:nAT,04],;
	Transform(aScl[oScl:nAT,05],"@E 999,999.99"),;
	Transform(aScl[oScl:nAT,06],"@E 999,999.99"),;
	aScl[oScl:nAT,07],;
	aScl[oScl:nAT,08],;
	aScl[oScl:nAT,09]}}
	oScl:Refresh()

	oScl:bHeaderClick := {|| IIf(oScl:ColPos == 2 , aEval(aScl,{|x| x[2] := Iif(!x[2] .And. x[1] > 0 ,.T., .F.), oScl:Refresh() }),Nil) }

	@ 280,050 SAY "Pesquisar Produto" of oDlgSZ8 pixel

	@ 280,110 MSGET cVarPesq Valid sfSearch(@cVarPesq , @aScl ,@oScl) of oDlgSZ8 pixel

	@ 280,240 BUTTON "Grava Dados" of oDlgSZ8 pixel SIZE 40,10 ACTION (Processa({|| sfGrvDados(aScl) },"Gerando Dados "),oDlgSZ8:End() )
	@ 280,295 BUTTON "Cancela" 	   of oDlgSZ8 pixel SIZE 40,10 ACTION (oDlgSZ8:End() )

	ACTIVATE MSDIALOG oDlgSZ8 CENTERED

Return


/*/{Protheus.doc} sfGrvDados
// Grava os dados de Replicação
@author Marcelo Alberto Lauschner
@since 19/04/2019
@version 1.0
@return Nil 
@param aScl, array, Vetor com os dados que serão replicados
@type Static Function
/*/
Static Function sfGrvDados(aScl)

	Local	x,mr
	Local	lContinua	:= .F. 
	Local	cQra
	Local	nRecAtu		:= 0
	Local	nNoRec		:= 0
	Local	nUPdRec		:= 0
	Local 	nCont		:= 0

	For x := 1 To Len(aScl)
		If aScl[x,2]      //verifica se existem pedidos marcados para continuar
			lContinua  := .T.
		Endif
	Next

	If lContinua  // se houverem pedidos marcados continua processo

		For mr:= 1 to len(aScl)

			If aScl[mr,2]


				cQra := ""
				cQra += "SELECT R_E_C_N_O_ Z8RECNO,Z8_DATCAD,Z8_DATFIM,Z8_CODPROD,R_E_C_N_O_ Z8RECNO"
				cQra += "  FROM " + RetSqlName("SZ8") + " "
				cQra += " WHERE D_E_L_E_T_ = ' ' "
				cQra += "   AND Z8_CODPROD = '" + aScl[mr,3] +"'"
				cQra += "   AND Z8_LOJA = '"+MV_PAR04+"' "
				cQra += "   AND Z8_CLIENTE = '"+MV_PAR03+"' "
				cQra += "   AND Z8_REEMB = '" + aScl[mr,7] + "'"
				cQra += "   AND Z8_FILIAL = '" + MV_PAR07 + "'"
				cQra += "   AND '" + DTOS(aScl[mr,9]) + "' >= Z8_DATCAD AND '" + DTOS(aScl[mr,8]) + "' <= Z8_DATFIM  "


				TCQUERY cQra NEW ALIAS "QRA"
				
				Count To nCont
				
				DbSelectArea("QRA")
				DbGotop()
				
				If nCont > 1
					ShowHelpDlg(ProcName(0)+"."+ Alltrim(Str(ProcLine(0))),;
						{"Produto '" + QRA->Z8_CODPROD + "' com mais de 1 cadastro neste intervalo de vigência de '" + DTOC(aScl[mr,8]) + "' a '" + DTOC(aScl[mr,9]) + "'"},;
						5,;
						{"O cadastro de Tampas deste produto deverá ser feito manualmente."},;
						5) 
				
				ElseIf !Eof() 
					If MV_PAR08 == 2
						ShowHelpDlg(ProcName(0)+"."+ Alltrim(Str(ProcLine(0))),;
						{"Produto '" + QRA->Z8_CODPROD + "' já cadastrado neste intervalo de vigência de '" + DTOC(aScl[mr,8]) + "' a '" + DTOC(aScl[mr,9]) + "'"},;
						5,;
						{"O cadastro de Tampas deste produto deverá ser feito manualmente."},;
						5) 
						nNoRec++
					Else
						DbSelectArea("SZ8")
						DbGoto(QRA->Z8RECNO)
						RecLock("SZ8",.F.)
						SZ8->Z8_FILIAL 	:= MV_PAR07
						SZ8->Z8_CLIENTE := MV_PAR03
						SZ8->Z8_LOJA 	:= MV_PAR04
						SZ8->Z8_CODPROD := aScl[mr,3]
						SZ8->Z8_VALOR 	:= aScl[mr,5]
						SZ8->Z8_PONTOS	:= aScl[mr,6]
						SZ8->Z8_REEMB	:= aScl[mr,7]
						SZ8->Z8_DATCAD  := aScl[mr,8]
						SZ8->Z8_DATFIM  := aScl[mr,9]
						MsUnlock()
						nUPdRec++
					Endif
				Else

					RecLock("SZ8",.T.)
					SZ8->Z8_FILIAL 	:= MV_PAR07
					SZ8->Z8_CLIENTE := MV_PAR03
					SZ8->Z8_LOJA 	:= MV_PAR04
					SZ8->Z8_CODPROD := aScl[mr,3]
					SZ8->Z8_VALOR 	:= aScl[mr,5]
					SZ8->Z8_PONTOS	:= aScl[mr,6]
					SZ8->Z8_REEMB	:= aScl[mr,7]
					SZ8->Z8_DATCAD  := aScl[mr,8]
					SZ8->Z8_DATFIM  := aScl[mr,9]
					MsUnlock()
					nRecAtu++
				Endif
				QRA->(DbCloseArea())

			Endif
		Next
		If nRecAtu > 0
			MsgInfo("Foram cadastrados " + cValToChar(nRecAtu) + " registros!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		Endif
		
		If nUPdRec > 0
			MsgInfo("Foram atualizados " + cValToChar(nUPdRec) + " registros!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		Endif

		If nNoRec > 0
			MsgAlert("Não foram replicados " + cValToChar(nNoRec) + " registros por problemas de vigência de data ou já cadastrados.",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		Endif
	Endif

Return


/*/{Protheus.doc} sfSelReg
// Montagem dos dados para exibir a replicação
@author Marcelo Alberto Lauschner
@since 19/04/2019
@version 1.0
@return lRet, Logical, Retorna se houveram dados e se validou as informações digitadas
@param aScl, array, descricao
@type Static Function
/*/
Static Function sfSelReg(aScl)

	Local	cQra
	Local	nRecCount
	Local	nStsPrd		:= 1
	Local	lRet		:= .T.
	Local	lUsaDtZ8	:= MsgYesNo("Deseja considerar a data de vigência dos parâmetros informados para a Replicação de cadastro? Caso informe não, será considerada a data de vigência vinda do Cliente Base! ",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))

	DbSelectArea("SA1")
	DbSetOrder(1)
	If DbSeek(xFilial("SA1")+MV_PAR05+MV_PAR06)
		lRet		:= .T.
	Else
		lRet		:= .F.
		ShowHelpDlg(ProcName(0)+"."+ Alltrim(Str(ProcLine(0))),;
		{"Cliente Base Inexistente '" + MV_PAR05+"/"+MV_PAR06 + "'!"},;
		5,;
		{"Verifique o Código e Loja do Cliente Base para buscar as informações"},;
		5) 
	Endif


	DbSelectArea("SA1")
	DbSetOrder(1)
	If DbSeek(xFilial("SA1")+MV_PAR03+MV_PAR04)
		lRet		:= .T.
	Else
		lRet		:= .F.
		ShowHelpDlg(ProcName(0)+"."+ Alltrim(Str(ProcLine(0))),;
		{"Cliente a Cadastrar Inexistente '" + MV_PAR03+"/"+MV_PAR04 + "'!"},;
		5,;
		{"Verifique o Código e Loja do Cliente a Cadastrar para buscar as informações"},;
		5) 
	Endif

	If lUsaDtZ8 .And. ( MV_PAR01 >= MV_PAR02  ) // .Or. MV_PAR01 < dDataBase .Or. MV_PAR02 <= dDataBase)
		lRet		:= .F.
		ShowHelpDlg(ProcName(0)+"."+ Alltrim(Str(ProcLine(0))),;
		{"Parâmetros de Data de Ínicio ou Fim de Vigência informados estão com divergência!"},;
		5,;
		{"Verifique se a Data Final é maior que a Data Inicial e se a data de Vigência é Maior ou Igual a data atual."},;
		5)
	Endif

	cQra := ""
	cQra += "SELECT * "
	cQra += "  FROM " + RetSqlName("SZ8") + " "
	cQra += " WHERE D_E_L_E_T_ = ' ' "
	cQra += "   AND Z8_CLIENTE = '"+mv_par05+"' "
	cQra += "   AND Z8_LOJA = '"+mv_par06+"' "
	cQra += "   AND Z8_FILIAL = '" + xFilial("SZ8") + "'"
	If lUsaDtZ8
		cQra += "   AND ('" + DTOS(MV_PAR01) + "' <= Z8_DATCAD OR '" + DTOS(MV_PAR02) + "' >= Z8_DATFIM ) "
	Else 
		cQra += "   AND TO_CHAR(SYSDATE,'YYYYMMDD') BETWEEN Z8_DATCAD AND Z8_DATFIM " // Filtra apenas Produtos ativos
	Endif 


	If Select("QRA") <> 0
		dbSelectArea("QRA")
		dbCloseArea("QRA")
	Endif

	TCQUERY cQra NEW ALIAS "QRA"

	Count To nRecCount
	ProcRegua(nRecCount)

	dbSelectArea("QRA")
	dbGoTop()
	While QRA->(!Eof())

		IncProc("Processando produto -> "+QRA->Z8_CODPROD)
		nStsPrd		:= 1
		If QRA->Z8_REEMB == "T" // Texaco
			nStsPrd		:= 2
		ElseIf QRA->Z8_REEMB == "W" // Wynss 
			nStsPrd		:= 3
		Endif
		DbSelectArea("SB1")
		DbSetOrder(1)
		If DbSeek(xFilial("SB1")+QRA->Z8_CODPROD)
			AAdd( aScl, { 	nStsPrd,;		// 1
			STOD(QRA->Z8_DATFIM) >= Date(),;						 	// 2
			QRA->Z8_CODPROD,;				// 3
			SB1->B1_DESC,;					// 4
			QRA->Z8_VALOR,;	   				// 5
			QRA->Z8_PONTOS,;				// 6
			QRA->Z8_REEMB,;					// 7
			STOD(QRA->Z8_DATCAD),;			// 8
			STOD(QRA->Z8_DATFIM)})			// 9
			//Iif(lUsaDtZ8,MV_PAR01,STOD(QRA->Z8_DATCAD)),;			// 8
			//Iif(lUsaDtZ8,MV_PAR02,STOD(QRA->Z8_DATFIM))})			// 9
		Endif
		dbSelectArea("QRA")
		dbSkip()
	Enddo
	QRA->(DbCloseArea())

	If Len(aScl) < 1
		MsgAlert("Nao houveram regsitros selecionados","Atencao!")
		AADD(aScl,{nStsPrd,.F.,"","",0,0,0,CTOD(""),CTOD("")})
		lRet		:= .F.
		Return
	Endif

Return lRet	


/*/{Protheus.doc} sfInverte
// Inverte seleção do Produto
@author Marcelo Alberto Lauschner
@since 19/04/2019
@version 1.0
@return Nil
@param oScl, object, descricao
@param aScl, array, descricao
@type Static Function
/*/
Static Function sfInverte(oScl,aScl)

	aScl[oScl:nAt,2] := Iif(!aScl[oScl:nAt,2] .And. aScl[oScl:nAt,1] > 0 ,.T., .F.)
Return


/*/{Protheus.doc} sfLegenda
// Monta legenda dos itens 
@author Marcelo Alberto Lauschner
@since 19/04/2019
@version 1.0
@return nRet, Objeto com a Cor 
@param oScl, object, descricao
@param aScl, array, descricao
@type Static Function
/*/
Static Function sfLegenda(oScl,aScl)

	Local	nRet	:= 1
	If 		aScl[oScl:nAt,1] == 1
		nRet	:= LoaDbitmap( GetResources(), "BR_VERMELHO" )
	ElseIf	aScl[oScl:nAt,1] == 2
		nRet	:= LoaDbitmap( GetResources(), "BR_VERDE" )
	ElseIf	aScl[oScl:nAt,1] == 3
		nRet	:= LoaDbitmap( GetResources(), "BR_AMARELO" )
	Else
		nRet	:= LoaDbitmap( GetResources(), "BR_AZUL" )
	EndIf
Return nRet


/*/{Protheus.doc} sfSearch
// Função para pesquisar produto 
@author Marcelo Alberto Lauschner
@since 19/04/2019
@version 1.0
@return Nil 
@param cVarPesq, characters, descricao
@param aScl, array, descricao
@param oScl, object, descricao
@type Static Function
/*/
Static Function sfSearch(cVarPesq,aScl,oScl)

	Local	nAscan

	nAscan := Ascan(aScl,{|x| Alltrim(cVarPesq) $ x[3] })

	If nAscan <= 0
		nAscan	:= 1
	EndIF

	oScl:nAT 	:= nAscan
	cVarPesq	:= space(15)
	oScl:SetFocus()
	oScl:Refresh()

Return 


/*/{Protheus.doc} sfVldPerg
//Função para criação do Grupo de Perguntas
@author Marcelo Alberto Lauschner
@since 19/04/2019
@version 1.0
@return Nil
@type Static Function
/*/
Static Function sfVldPerg()

	Local	cPerg		:= Padr("FOR009",10)
	Local 	aAreaOld	:= GetArea()
	Local aRegs := {}
	Local i,j

	dbSelectArea("SX1")
	dbSetOrder(1)
	//cPerg :=  PADR(cPerg,Len(SX1->X1_GRUPO))

	AADD(aRegs,{cPerg,"01","Data Ini Contr" ,"","","mv_ch1","D",08,0,0,"G","","mv_par01","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
	AADD(aRegs,{cPerg,"02","Data Fin Contr" ,"","","mv_ch2","D",08,0,0,"G","","mv_par02","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
	AADD(aRegs,{cPerg,"03","Cli a Cadastr" 	,"","","mv_ch3","C",06,0,0,"G","","mv_par03","","","","","","","","","","","","","","","","","","","","","","","","","SA1","",""})
	AADD(aRegs,{cPerg,"04","Loja a Cadastr"	,"","","mv_ch4","C",02,0,0,"G","","mv_par04","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
	AADD(aRegs,{cPerg,"05","Cli Base" 		,"","","mv_ch5","C",06,0,0,"G","","mv_par05","","","","","","","","","","","","","","","","","","","","","","","","","SA1","",""})
	AADD(aRegs,{cPerg,"06","Loja Base"		,"","","mv_ch6","C",02,0,0,"G","","mv_par06","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
	AADD(aRegs,{cPerg,"07","Filial Destino" ,"","","mv_ch7","C",02,0,0,"G","","mv_par07","","","","","","","","","","","","","","","","","","","","","","","","","SM0","",""})
	AADD(aRegs,{cPerg,"08","Tipo Atualização?","","","mv_ch8","N",01,0,0,"C","","mv_par08","Atualiza Existentes"  ,"","","","","Somente Novos","","","","","","","","","","","","","","","","","","","","",""})


	For i:=1 to Len(aRegs)
		If !dbSeek(cPerg+aRegs[i,2])
			RecLock("SX1",.T.)
			For j:=1 to FCount()
				If j <= Len(aRegs[i])
					FieldPut(j,aRegs[i,j])
				Endif
			Next
			MsUnlock("SX1")
		Endif
	Next

	RestArea(aAreaOld)

Return
