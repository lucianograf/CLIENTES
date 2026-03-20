#include "totvs.ch"
#include "tbiconn.ch"
#include "topconn.ch"

/*/{Protheus.doc} GetPvc
//TODO Importação de pedidos Ajili
@author Edson / Marcelo Alberto Lauschner
@since 12/12/2019
@version 1.0
@return ${return}, ${return_description}
@teste
@type function
/*/
User Function GetPvc(aParam)


	Local	lRet 		:= .F.
	Local	nWaitSec	:= 0
	Default	cInCodLj	:= ""
	Private lDebug		:= .F.

	/// Mensagem de saída no Consol
	ConOut("+"+Replicate("-",50)+"+")
	ConOut("|"+Padr(ProcName(1)+"." + ProcName(0) + "-" + Alltrim(Str(ProcLine(0))) + DTOC(Date()) + " " + Time(),50) +"|")
	ConOut("|"+Padr("Empresa Logada: " + cEmpAnt,50)+"|")
	ConOut("|"+Padr("Filial Logada : " + cFilAnt,50)+"|")
	VarInfo("|Valores passados via aParam",aParam)
	ConOut("+"+Replicate("-",50)+"+")

	If GetNewPar("GF_AJILIOK",.T.)
		While !lRet


			If lRet	:= LockByName("GETPVC_"+cFilAnt,.T.,.T.)

				Conout("***[Inicio GETPVC_"+cFilAnt + " " + DTOC( Date() ) + " " + Time() + "]************************************************************************")
				If IsBlind()
					fGetPvc()
				Else
					Processa({|| fGetPvc()	 },"Processando pedidos...")
				Endif
				UnLockByName("GETPVC_"+cFilAnt,.T.,.T.)
				Conout("***[Fim GETPVC_"+cFilAnt + " " + DTOC( Date() ) + " " + Time() + "]****************************************************************************")

			Else
				If IsBlind()
					Sleep( 1 * 1000)
				Else
					MsAguarde({|| Sleep( 1 * 1000) }, "Aguarde " + cValToChar(10-nWaitSec) + " segundos! Importação pedidos já em execução!")
				Endif
				nWaitSec ++
				Conout("*****[Job GETPVC_ ja esta em execucao]***********************************************")
				// Havendo mais de 20 tentativas de espera por 1 segundos cada, aborta o processo
				If nWaitSec  >= 10
					lRet	:= .T.
					Exit
				Endif
			Endif
		Enddo
	Endif

Return


/*/{Protheus.doc} SchedDef
//TODO Função que permite agendar a rotina no Schedule do Protheus
@author Marcelo Alberto Lauschner
@since 21/02/2020
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
Static Function SchedDef()
	Local	aOrd	:= {}
	Local	aParam	:= {}

	Aadd(aParam,"P")
	Aadd(aParam,"PARAMDEF")
	Aadd(aParam,"")
	Aadd(aParam,aOrd)
	Aadd(aParam,)

Return aParam



Static Function fGetPvc()

	Local 	cURL		    := Alltrim(GetNewPar("GF_AJ_URL",""))
	Local 	cAcesso         := "/api/pedidos/no-id-erp-with-items?"
	Local	cApiKey			:= "api_key=" + Alltrim(GetNewPar("GF_AJ_KEY",""))
	Local 	iD1
	Local 	aHeader         := {}
	Local 	cHeaderGet      := ""
	Local 	cGetParms       := ""
	Local 	nTimeOut 		:= 120
	Local 	oJson := Nil
	Local 	lRet            := .F.
	Local 	nAprvStatus		:= 0

	Private	aVetItem		:= {}
	Private	aVetOrder		:= {}
	Private	aVetCustomer	:= {}
	Private	aVetContact		:= {}
	Private	aVetSalesman	:= {}
	Private	aVetPayTerms	:= {}
	Private	aVetPayForms	:= {}
	Private	aVetPrcTable	:= {}
	Private	aVetItems		:= {}
	Private	aVetProduct		:= {}
	Private aVetTransp		:= {}
	//Cabeçalho
	Private cFIniPed 		:= '"order" :'
	Private cFNumPed 		:= '"id" :'
	Private cNumPed  		:= 0
	Private cFCodCli 		:= '"customerId" :'
	Private cCodCli  		:= ""
	Private cFVend   		:= '"salesmanId" :'
	Private cCodVend 		:= ""
	Private cFCondPag		:= '"paymentTermsId" :'
	Private cCondPag 		:= ""
	Private cFFormPag		:= '"paymentFormsId" :'
	Private cFormPag 		:= ""
	Private cFTabPrec		:= '"pricingTableId" :'
	Private cTabPreco		:= ""
	//Itens
	Private cFIniProd		:= '"items" : ['
	Private cFItensId		:= '"id" :'
	Private cFSales  		:= '"salesOrderId" :'
	Private cFCodProd		:= '"productId" :'
	Private cCodProd 		:= ""
	Private cFQtde   		:= '"quantity" :'
	Private cQtde    		:= ""
	Private cFValUnit		:= '"unitValue" :'
	Private cValUnit 		:= ""
	Private cRetorno 		:= ""
	Private cNPedido 		:= ""
	Private aAtualiza		:= {}
	Private cIdItem  		:= ""
	Private oParseJSON 		:= Nil

	aadd(aHeader,'Content-Type: application/json')
	Aadd(aHeader, "Accept: application/json")

	cRetorno := HttpGet( cUrl+cAcesso+cApiKey , cGetParms, nTimeOut, aHeader, @cHeaderGet )

	If ValType(cRetorno) <> "C"
		MsgAlert("Erro de acesso a página de Pedidos '" +cURL +"'. Favor contatar o TI.", ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		Return
	Endif

	//MemoWrit("c:\edi\getpv.txt", cUrl+cAcesso+cApiKey + "-" + cRetorno)

	cRetorno	:= DecodeUtf8(cRetorno)

	oJson 		:= tJsonParser():New()
	nRetParser	:= 0
	strJson 	:= cRetorno
	lenStrJson 	:= Len(cRetorno)
	jsonfields	:= {}
	lRet := oJson:Json_Parser(strJson, lenStrJson, @jsonfields, @nRetParser)

	If ( lRet == .F. )
		msgAlert("##### [JSON][ERR] " + "Parser 1 com erro" + " MSG len: " + AllTrim(Str(lenStrJson)) + " bytes lidos: " + AllTrim(Str(nRetParser)))
		msgAlert("Erro a partir: " + SubStr(strJson, (nRetParser+1)))
	Else
		//		msgAlert("[JSON] "+ "+++++ PARSER 1 OK num campos: " + AllTrim(Str(Len(jsonfields))) + " MSG len: " + AllTrim(Str(lenStrJson)) + " bytes lidos: " + AllTrim(Str(nRetParser)))
		//		printJson(jsonfields, "| ")
	EndIf
	ConOut("-------------------------------------------------------", "")

	For iD1 := 1 To Len(jsonfields[1])
		//                                                // List[1] / item[iD1] / order[2]  / id[2]
		//MsgAlert("Vai chamar rotina de pedido para id " + cValToChar(jsonfields[1][iD1][2][2][2][1][2] ))

		aVetItem		:= sfGetVal (jsonfields[1],"#_OBJECT_#","",iD1)
		If lDebug
			VarInfo("aVetItem",aVetItem)
		Endif

		aVetOrder		:= sfGetVal (aVetItem,"#_OBJECT_#","order") // Order
		If lDebug
			VarInfo("aVetOrder",aVetOrder)
		Endif

		//"approvalStatus" : 103, ou 101-orcamento
		nAprvStatus	:= sfGetVal (aVetOrder,"approvalStatus","")



		// Dados do Cliente do Pedido
		aVetCustomer	:= sfGetVal (aVetOrder,"#_OBJECT_#","customer")
		If lDebug
			VarInfo("aVetCustomer",aVetCustomer)
		Endif
		// Dados do Vendedor do Pedido
		aVetSalesman	:= sfGetVal (aVetOrder,"#_OBJECT_#","salesman")
		If lDebug
			VarINfo("aVetSalesman",aVetSalesman)
		Endif
		// Dados da Condição de pagamento
		aVetPayTerms	:= sfGetVal (aVetOrder,"#_OBJECT_#","paymentTerms")
		If lDebug
			VarINfo("aVetPayTerms",aVetPayTerms)
		Endif

		// Dados da Forma de Pagamento
		aVetPayForms	:= sfGetVal (aVetOrder,"#_OBJECT_#","paymentForms")
		If lDebug
			VarINfo("aVetPayForms",aVetPayForms)
		Endif
		// Dados da Tabela de Preço usada no Pedido
		aVetPrcTable	:= sfGetVal (aVetOrder,"#_OBJECT_#","pricingTable")
		If lDebug
			VarINfo("aVetPrcTable",aVetPrcTable)
		Endif
		// Dados da Transportadora
		aVetTransp := sfGetVal (aVetOrder,"#_OBJECT_#","freightCarrier")
		If lDebug
			VarINfo("aVetTransp",aVetTransp)
		Endif

		aVetItems		:= sfGetVal (aVetItem,"items","")
		//aVetItems		:= sfGetVal (aVetItem,"#_OBJECT_#","items")

		If lDebug
			VarINfo("aVetItems",aVetItems)
		Endif
		//aVetProduct		:= sfGetVal (aVetItems,"product")

		// Se for um Orçamento
		If nAprvStatus == 101
			sfGeraOrc()
		Else
			sfGeraPedido()
		Endif

	Next

Return


/*/{Protheus.doc} sfGetVal
Função para retornar valores do vetor passado 
@type function
@version  
@author Marcelo Alberto Lauschner
@since 24/02/2022
@param aJson, array, param_description
@param cTag, character, param_description
@param cTag2, character, param_description
@param nPosIni, numeric, param_description
@return variant, return_description
/*/
Static Function sfGetVal (aJson, cTag,cTag2,nPosIni)

	Local xRet 		:= ''
	Local nPos	 	:= 0
	Default	nPosIni	:= 1

	For nPos := nPosIni To Len(aJson)
		If ValType(aJson[nPos][1]) == "C" .And. aJson[nPos][1] == cTag
			// Verifica se procura pelo nome do Ojecto anterior
			If !Empty(cTag2)
				If cTag2 == aJson[nPos-1][1]
					xRet	:= aJson[nPos][2]
				Endif
			Else
				xRet	:= aJson[nPos][2]
				Exit // Sai na primeira iteração
			Endif
		Endif
	Next

Return xRet

/*/{Protheus.doc} printJson
Função para fazer ConOut de Vetor de Json 
@type function
@version  
@author Marcelo Alberto Lauschner
@since 24/02/2022
@param aJson, array, param_description
@param niv, numeric, param_description
@return variant, return_description
/*/
Static Function printJson(aJson, niv)
	VarInfo(niv, aJson)
Return .T.


Static Function sfFindIdAj(cInAlias,nInIdAjili,cCpoOut,cInValPad,cInPesqZ00)
	Local	aAreaOld	:= GetArea()
	Local	xRetValue	:= cInValPad

	If cInPesqZ00 == Nil
		cInPesqZ00	:= ""
	Endif

	DbSelectArea("Z00")
	DbSetOrder(2)//Z00_FILIAL+Z00_ENTIDA+STRZERO(Z00_IDAJIL,11)
	If DbSeek(xFilial("Z00") +cInAlias + StrZero(nInIdAjili,11) )

		If Alltrim(Z00->Z00_CHAVE) <> Alltrim(cInPesqZ00 ) .And. !Empty(cInPesqZ00)
			cAssunto 	:= "Importação Ajili - Empresa:" + cEmpAnt+"/" + cFilAnt + " " + Capital(SM0->M0_NOME)
			cMensagem	:= "Diferença de valor de chave  Id Ajili " + cValToChar(nInIdAjili) +  " Alias " + cInAlias + " Chave Pesquisa:" + cInPesqZ00 + CRLF
			cMensagem	+= "Usuário:  " + cUserName + "-" + UsrFullName(__cUserId) + CRLF
			cMensagem	+= "Data/Hora: " + Dtoc( Date() ) + " as " + Time() + CRLF

			U_WFGERAL(	"rafael@grupoforta.com.br;ml-servicos@outlook.com"/*cEmail*/,cAssunto/*cTitulo*/,cMensagem/*cTexto*/,"GETPVC"/*cRotina*/,/*cAnexo*/)

			//MsgInfo("Deletado registro Z00 com Entidade '"+Z00->Z00_ENTIDA + "' e chave '" +Z00->Z00_CHAVE + "' ","GetPvc - Delete de registro ")
			RecLock("Z00",.F.)
			DbDelete()
			MsUnlock()
		Else

			DbSelectArea(Z00->Z00_ENTIDA)
			DbSetOrder(Z00->Z00_NCHAVE)
			If DbSeek(Z00->Z00_CHAVE)
				xRetValue	:= &(Z00->Z00_ENTIDA+"->("+cCpoOut+")") // Monta retorno dinâmico
			Else
				//MsgAlert("Não encontrou registro na entidade '"+Z00->Z00_ENTIDA+"' para o valor '"+Z00->Z00_CHAVE+"'","GetPvc - Dbseek Entidade")
				Begin Transaction
					DbSelectArea("Z00")
					DbSetOrder(2) //Z00_FILIAL+Z00_ENTIDA+STRZERO(Z00_IDAJIL,11)
					If DbSeek(xFilial("Z00") +cInAlias + StrZero(nInIdAjili,11) )
						//nIdAjili		:= Z00->Z00_IDAJIL
						RecLock("Z00",.F.)
					Else
						RecLock("Z00",.T.)
					Endif
					Z00->Z00_FILIAL 	:= xFilial("Z00")	//- Filial
					Z00->Z00_ENTIDA 	:= cInAlias			//- Entidade
					Z00->Z00_NCHAVE 	:= 1				//- Indice da Entidade
					Z00->Z00_CHAVE  	:= cInValPad		//- Chave de pesquisa/relação
					Z00->Z00_INTEGR 	:= "X"				//- Status Integração
					Z00->Z00_IDAJIL 	:= nInIdAjili		//- Id de Integração Ajili
					MsUnlock()
				End Transaction
			Endif
		Endif
	ElseIf nInIdAjili > 0 .And. !Empty(cInPesqZ00)
		//MsgAlert("Não encontrou registro na Z00 para a chave '"+xFilial("Z00") +cInAlias + StrZero(nInIdAjili,11) + "' ","GetPvc - Z00 Dbseek")
		Begin Transaction
			DbSelectArea("Z00")
			DbSetOrder(1)//Z00_FILIAL+Z00_ENTIDA+Z00_CHAVE
			//If DbSeek(xFilial("Z00") + "SA1" + SA1->(A1_FILIAL+A1_COD+A1_LOJA))
			If DbSeek(xFilial("Z00") +cInAlias + cInPesqZ00 )
				//nIdAjili		:= Z00->Z00_IDAJIL
				RecLock("Z00",.F.)
			Else
				RecLock("Z00",.T.)

			Endif
			Z00->Z00_FILIAL 	:= xFilial("Z00")	//- Filial
			Z00->Z00_ENTIDA 	:= cInAlias			//- Entidade
			Z00->Z00_NCHAVE 	:= 1				//- Indice da Entidade
			Z00->Z00_CHAVE  	:= cInPesqZ00		//- Chave de pesquisa/relação
			Z00->Z00_INTEGR 	:= "X"				//- Status Integração
			Z00->Z00_IDAJIL 	:= nInIdAjili		//- Id de Integração Ajili
			MsUnlock()
		End Transaction
	Endif

	RestArea(aAreaOld)

Return xRetValue


Static Function sfGeraPedido()


	// Local cDoc     := GetSxeNum("SC5", "C5_NUM")
	Local aCabec   	:= {}
	Local aItens   	:= {}
	Local aLinha   	:= {}
	Local xA1Cod   	:= ""
	Local xA1Loja  	:= ""
	Local cCnpjCli	:= ""
	Local xE4Codigo	:= ""
	Local nX       	:= 0
	Local iQ
	Local iE
	Local xQtde    	:= 0.000
	Local xValUnit 	:= 0.00
	Local xPrcVen	:= 0.00
	Local xTotVal  	:= 0.00
	Local nPerDesc		:= 0.00
	Local aErroAuto 	:= {}
	Local aCodRegBon	:= {}
	Local cLogErro 		:= ""
	Local nCount   		:= 0
	Local cMsgInt		:= ""
	Local cIdA1Cod		:= Space(8)
	Local lA1New		:= .F.
	Local nValFatFin	:= 0
	Local cDA0CODTAB	:= ""
	Local cC5Transp 	:= ""
	Local nC5Frete		:= 0
	Local lC6QtdLib 	:= GetNewPar("FC_C6QTLIB",.T.)
	Private lMsErroAuto := .F.
	Private C5_EMISSAO	:= Date()

	// Atribui número do pedido
	cNumPed		:= sfGetVal (aVetOrder,"id","")

	nPerDesc	:= sfGetVal (aVetOrder,"percentDiscount","")
	If nPerDesc <> Nil
		nPerDesc	:= Round(nPerDesc * 100 , 2)
	Else
		nPerDesc	:= 0
	Endif


	nDA0Codigo	:= sfGetVal (aVetPrcTable,"id","")
	If nDA0Codigo == Nil .Or. Empty(nDA0Codigo)
		nDA0Codigo	:= 0
	Endif
	If nDA0Codigo > 0
		cDA0CODTAB	:= sfFindIdAj("DA0"/*cInAlias*/,nDA0Codigo/*nInIdAjili*/,"DA0_CODTAB"/*cCpoOut*/)
	Endif
	If cDA0CODTAB <> sfGetVal (aVetPrcTable,"idErp","")
		//	MsgAlert("Diferença código de tabela de preços entre o Ajili e o ERP")
	Endif
	If cDA0CODTAB == Nil .Or. Empty(cDA0CODTAB)
		If cFilAnt == "0301"
			cDA0CODTAB	:= "201"
		ElseIf cFilAnt == "0101"
			cDA0CODTAB	:= "601"
		ElseIf cFilAnt == "0201"
			cDA0CODTAB	:= "501"
		ElseIf cFilAnt == "0401"
			cDA0CODTAB	:= "101"
		Endif
	Endif

	// Trecho que verifica se já houve importação do pedido
	cQry := "SELECT C5_NUM "
	cQry += "  FROM "+RetSqlName("SC5")
	cQry += " WHERE C5_IDAJILI = " +cValToChar(cNumPed)
	cQry += "   AND C5_FILIAL = '" + xFilial("SC5") + "' "

	TcQuery cQry New Alias "QSC5"

	If !Eof()

		cAssunto 	:= "Importação Ajili - Empresa:" + cEmpAnt+"/" + cFilAnt + " " + Capital(SM0->M0_NOME)
		cMensagem	:= "Pedido já importado anteriormente."  + CRLF
		cMensagem 	+= "Pedido: " + cValToChar(cNumPed) + CRLF
		cMensagem	+= "Usuário:  " + cUserName + "-" + UsrFullName(__cUserId) + CRLF
		cMensagem	+= "Data/Hora: " + Dtoc( Date() ) + " as " + Time() + CRLF

		U_WFGERAL(	"rafael@grupoforta.com.br;ml-servicos@outlook.com"/*cEmail*/,cAssunto/*cTitulo*/,cMensagem/*cTexto*/,"GETPVC"/*cRotina*/,/*cAnexo*/)

		fAtualiza({},QSC5->C5_NUM,.F.)

		QSC5->(DbCloseArea())
		Return

	Endif
	QSC5->(DbCloseArea())

	nCodCli		:= sfGetVal (aVetCustomer,"id","")
	cIdA1Cod	:= sfGetVal (aVetCustomer,"idErp","")

	If cIdA1Cod == Nil .Or. Empty(cIdA1Cod)
		cIdA1Cod	:= Space(8)
		cCnpjCli	:= sfGetVal (aVetCustomer,"federalId","")
		If cCnpjCli == Nil .Or. Empty(cCnpjCli)
			MsgAlert("Cliente novo para ser cadastrado porém não há informação do CNPJ no Ajili. Favor contatar o TI","")
			fAtualiza(aAtualiza,"xxxxxx",.F.)

			cAssunto 	:= "Importação Ajili - Empresa:" + cEmpAnt+"/" + cFilAnt + " " + Capital(SM0->M0_NOME)
			cMensagem	:= "Cliente novo para ser cadastrado porém não há informação do CNPJ no Ajili. Favor contatar o TI"  + CRLF
			cMensagem 	+= "Pedido: " + cValToChar(cNumPed) + CRLF
			cMensagem	+= "Usuário:  " + cUserName + "-" + UsrFullName(__cUserId) + CRLF
			cMensagem	+= "Data/Hora: " + Dtoc( Date() ) + " as " + Time() + CRLF

			U_WFGERAL(	"rafael@grupoforta.com.br;ml-servicos@outlook.com"/*cEmail*/,cAssunto/*cTitulo*/,cMensagem/*cTexto*/,"GETPVC"/*cRotina*/,/*cAnexo*/)

			aAtualiza :={}
			Return
		Endif

		DbSelectArea("SA1")
		DbSetOrder(3)
		If DbSeek(xFilial("SA1")+cCnpjCli)
			cIdA1Cod	:= SA1->A1_COD+SA1->A1_LOJA

			Begin Transaction

				DbSelectArea("SA1")
				RecLock("SA1",.F.)
				SA1->A1_MSEXP	:=  " "
				MsUnlock()

				DbSelectArea("Z00")
				DbSetOrder(1)//Z00_FILIAL+Z00_ENTIDA+Z00_CHAVE
				If DbSeek(xFilial("Z00") + "SA1" + SA1->(A1_FILIAL+A1_COD+A1_LOJA))
					//nIdAjili		:= Z00->Z00_IDAJIL
					RecLock("Z00",.F.)
				Else
					RecLock("Z00",.T.)
				Endif

				Z00->Z00_FILIAL 	:= xFilial("Z00")	//- Filial
				Z00->Z00_ENTIDA 	:= "SA1"			//- Entidade
				Z00->Z00_NCHAVE 	:= 1				//- Indice da Entidade
				Z00->Z00_CHAVE  	:= SA1->(A1_FILIAL+A1_COD+A1_LOJA)	//- Chave de pesquisa/relação
				Z00->Z00_INTEGR 	:= "X"				//- Status Integração
				Z00->Z00_IDAJIL 	:= nCodCli			//- Id de Integração Ajili
				MsUnlock()
			End Transaction

			// Efetua chamada para forçar atualização do cliente no Ajili
			U_RestCli({},cIdA1Cod)


		Else

			If !sfNewCli()
				MsgAlert("Não encontrou cadastro de cliente para o CNPJ: " + cCnpjCli + " e não conseguiu inserir o cadastro automaticamente!" )
				fAtualiza(aAtualiza,"xxxxxx",.F.)

				cAssunto 	:= "Importação Ajili - Empresa:" + cEmpAnt+"/" + cFilAnt + " " + Capital(SM0->M0_NOME)
				cMensagem	:= "Não encontrou cadastro de cliente para o CNPJ: " + cCnpjCli + " e não conseguiu inserir o cadastro automaticamente!"  + CRLF
				cMensagem 	+= "Pedido: " + cValToChar(cNumPed) + CRLF
				cMensagem	+= "Usuário:  " + cUserName + "-" + UsrFullName(__cUserId) + CRLF
				cMensagem	+= "Data/Hora: " + Dtoc( Date() ) + " as " + Time() + CRLF

				U_WFGERAL(	"rafael@grupoforta.com.br;ml-servicos@outlook.com"/*cEmail*/,cAssunto/*cTitulo*/,cMensagem/*cTexto*/,"GETPVC"/*cRotina*/,/*cAnexo*/)

				Return
			Endif

			lA1New	:= .T.

			DbSelectArea("SA1")
			DbSetOrder(3)
			If DbSeek(xFilial("SA1")+cCnpjCli)
				cIdA1Cod	:= SA1->A1_COD+SA1->A1_LOJA

				DbSelectArea("SA1")
				RecLock("SA1",.F.)
				SA1->A1_MSEXP	:= " "
				MsUnlock()

			Endif
			Begin Transaction
				DbSelectArea("Z00")
				DbSetOrder(1)//Z00_FILIAL+Z00_ENTIDA+Z00_CHAVE
				If DbSeek(xFilial("Z00") + "SA1" + SA1->(A1_FILIAL+A1_COD+A1_LOJA))
					//nIdAjili		:= Z00->Z00_IDAJIL
					RecLock("Z00",.F.)
				Else
					RecLock("Z00",.T.)

				Endif
				Z00->Z00_FILIAL 	:= xFilial("Z00")	//- Filial
				Z00->Z00_ENTIDA 	:= "SA1"			//- Entidade
				Z00->Z00_NCHAVE 	:= 1				//- Indice da Entidade
				Z00->Z00_CHAVE  	:= SA1->(A1_FILIAL+A1_COD+A1_LOJA)	//- Chave de pesquisa/relação
				Z00->Z00_INTEGR 	:= "X"				//- Status Integração
				Z00->Z00_IDAJIL 	:= nCodCli			//- Id de Integração Ajili
				MsUnlock()
			End Transaction
		Endif
	Endif

	xA1Cod		:= sfFindIdAj("SA1"/*cInAlias*/,nCodCli/*nInIdAjili*/,"A1_COD"/*cCpoOut*/, Substr(cIdA1Cod,1,6), xFilial("SA1")+cIdA1Cod )
	If xA1Cod <> Substr(cIdA1Cod,1,6)
		MsgAlert("Diferença código de cliente id Ajili " + Iif(xA1Cod <> Nil , xA1Cod , "0") + " e código pelo cnpj " + Substr(cIdA1Cod,1,6) , "Cnpj: " + cCnpjCli)

		cAssunto 	:= "Importação Ajili - Empresa:" + cEmpAnt+"/" + cFilAnt + " " + Capital(SM0->M0_NOME)
		cMensagem	:= "Diferença código de cliente id Ajili " + Iif(xA1Cod <> Nil , xA1Cod , "0") + " e código pelo cnpj " + cCnpjCli + " Código:" + Substr(cIdA1Cod,1,6) + CRLF
		cMensagem 	+= "Pedido: " + cValToChar(cNumPed) + CRLF
		cMensagem	+= "Usuário:  " + cUserName + "-" + UsrFullName(__cUserId) + CRLF
		cMensagem	+= "Data/Hora: " + Dtoc( Date() ) + " as " + Time() + CRLF

		U_WFGERAL(	"rafael@grupoforta.com.br;ml-servicos@outlook.com"/*cEmail*/,cAssunto/*cTitulo*/,cMensagem/*cTexto*/,"GETPVC"/*cRotina*/,/*cAnexo*/)
		//	Return
	Endif

	xA1Loja		:= sfFindIdAj("SA1"/*cInAlias*/,nCodCli/*nInIdAjili*/,"A1_LOJA"/*cCpoOut*/,Substr(cIdA1Cod,7,2),xFilial("SA1")+cIdA1Cod )
	If xA1Loja <> Substr(cIdA1Cod,7,2)
		MsgAlert("Diferença código de loja id Ajili " + Iif(xA1Loja <> Nil , xA1Loja , "0") + " e código pelo cnpj " + Substr(cIdA1Cod,7,2) , "Cnpj: " + cCnpjCli)
		cAssunto 	:= "Importação Ajili - Empresa:" + cEmpAnt+"/" + cFilAnt + " " + Capital(SM0->M0_NOME)
		cMensagem	:= "Diferença código de cliente id Ajili " + Iif(xA1Loja <> Nil , xA1Loja , "0") + " e código pelo cnpj " + cCnpjCli + " Loja: " + Substr(cIdA1Cod,7,2)  + CRLF
		cMensagem 	+= "Pedido: " + cValToChar(cNumPed) + CRLF
		cMensagem	+= "Usuário:  " + cUserName + "-" + UsrFullName(__cUserId) + CRLF
		cMensagem	+= "Data/Hora: " + Dtoc( Date() ) + " as " + Time() + CRLF

		U_WFGERAL(	"rafael@grupoforta.com.br;ml-servicos@outlook.com"/*cEmail*/,cAssunto/*cTitulo*/,cMensagem/*cTexto*/,"GETPVC"/*cRotina*/,/*cAnexo*/)
		//	Return
	Endif

	xA1Cod	:= Substr(cIdA1Cod,1,6)
	xA1Loja	:= Substr(cIdA1Cod,7,2)

	nCondPag	:= sfGetVal (aVetPayTerms,"id","")
	xE4Codigo	:= sfGetVal (aVetPayTerms,"idErp","")

	xE4Codigo	:= sfFindIdAj("SE4"/*cInAlias*/,nCondPag/*nInIdAjili*/,"E4_CODIGO"/*cCpoOut*/,xE4Codigo/*cInValPad*/,xE4Codigo/*cInPesqZ00*/)
	If xE4Codigo <> sfGetVal (aVetPayTerms,"idErp","")
		MsgAlert("Diferença código de condição de pagamento entre o Ajili e o ERP")
	Endif
	If xE4Codigo == Nil .Or. Empty(xE4Codigo)
		xE4Codigo	:= "107"
	Endif

	cFormPag :=  sfGetVal (aVetPayForms,"name","")

	// Verifica se deve buscar o campo de vendedor específico
	If SA1->(FieldPos(U_MLFATG05(1))) > 0
		cCpoVend 	:= U_MLFATG05(1)
	Else
		cCpoVend	:= "A1_VEND"
	Endif

	cC5Vend1	:= sfGetVal (aVetSalesman,"idErp","")

	If Empty(cC5Vend1) .Or. cC5Vend1 == Nil
		cC5Vend1	:= Posicione("SA1",1,xFilial("SA1")+xA1Cod + xA1Loja , cCpoVend)
	Endif

	cMsgInt :=  sfGetVal (aVetOrder,"notes","")
	If cMsgInt == Nil
		cMsgInt := ""
	Endif
	cMsgInt	:= "Pedido Ajili: " + cValToChar(cNumPed) + "-" + sfAjust(cMsgInt,,.T.)



	// Força o ajuste do código de vendedor conforme o cadastro do cliente se o vendedor do Vellis estiver bloqueado
	DbSelectArea("SA3")
	DbSetOrder(1)
	DbSeek(xFilial("SA3")+cC5Vend1)
	If !RegistroOk("SA3",.F.)
		If !Empty(cC5Vend1) .And. cC5Vend1 <> Posicione("SA1",1,xFilial("SA1")+xA1Cod + xA1Loja , cCpoVend)
			cC5Vend1	:= Posicione("SA1",1,xFilial("SA1")+xA1Cod + xA1Loja , cCpoVend)
			cMsgInt		:= cMsgInt + "-Vendedor ajustado."
		Endif
	Endif


	// aadd(aCabec, {"C5_NUM",     cDoc,      Nil})
	aadd(aCabec, {"C5_TIPO"		,   "N"								, Nil})
	aadd(aCabec, {"C5_CLIENTE"	, 	xA1Cod							, Nil})
	aadd(aCabec, {"C5_LOJACLI"	, 	xA1Loja							, Nil})
	aadd(aCabec, {"C5_LOJAENT"	, 	xA1Loja							, Nil})
	aadd(aCabec, {"C5_CONDPAG"	, 	xE4Codigo						, Nil})
	aadd(aCabec, {"C5_TABELA"	,  	cDA0CODTAB						, Nil})
	aadd(aCabec, {"C5_IDAJILI" 	, 	cNumPed							, Nil})
	Aadd(aCabec, {"C5_VEND1"    ,	cC5Vend1						, Nil})

	// Verifica se a forma de pagamento informada é Boleto
	If Alltrim(Upper(cFormPag)) $ GetNewPar("GF_FPGPDCC","CARTÃO#CARTAO")
		aadd(aCabec, {"C5_BANCO"	, 	"888"		, Nil})
	Endif

	// Obtém informação da transportadora
	aVetTransp 	:= sfGetVal (aVetOrder,"#_OBJECT_#","freightCarrier")
	cC5Transp	:= sfGetVal (aVetTransp,"federalId","")

	If cC5Transp <> Nil .And. Type("cC5Transp") == "C"
		DbSelectArea("SA4")
		DbSetOrder(3)
		If DbSeek(xFilial("SA4")+cC5Transp) .And. !Empty(cC5Transp)
			// Adiciona a transportadora selecioanda pelo Vendedor
			Aadd(aCabec, {"C5_TRANSP"	, SA4->A4_COD				,Nil})
		Endif
	Endif

	nC5Frete	:= sfGetVal (aVetOrder,"freightValue","")

	If nC5Frete == Nil
	Else
		Aadd(aCabec, {"C5_FRETE"	, nC5Frete			,Nil})
	Endif

	cMsgInt :=  sfGetVal (aVetOrder,"notes","")
	If cMsgInt == Nil
		cMsgInt := ""
	Endif
	cMsgInt	:= "Pedido Ajili: " + cValToChar(cNumPed) + "-" + sfAjust(cMsgInt,,.T.)



	dbSelectArea("SE4")
	dbSetOrder(1)
	If dbSeek(FwxFilial("SE4")+xE4Codigo)
		nValFatFin := SE4->E4_ZFATFIN
	EndIf


	If lDebug
		VarInfo("aCabec",aCabec)
	Endif
	cItem	:= "00"
	For nX := 1 To Len(aVetItems)

		aVetPrdItem	:= sfGetVal (aVetItems,"#_OBJECT_#","",nX)
		If lDebug
			VarInfo("aVetPrditem",aVetPrdItem)
		Endif

		aProdItem	:= sfGetVal (aVetPrdItem,"#_OBJECT_#","")
		If lDebug
			VarInfo("aProdItem",aProdItem)
		Endif

		nB1Cod	:= sfGetVal (aProdItem,"id","")
		cB1Cod	:= sfFindIdAj("SB1"/*cInAlias*/,nB1Cod/*nInIdAjili*/,"B1_COD"/*cCpoOut*/)
		If cB1Cod <> sfGetVal (aProdItem,"idErp","")
			MsgAlert("Diferença código de condição de pagamento entre o Ajili e o ERP")
		Endif
		If cB1Cod == Nil
			MsgAlert("Erro ao obter código de produto do Id " + cValToChar(nB1Cod ))
			Loop
		Endif
		xQtde    := sfGetVal (aVetPrdItem,"quantity","")// aItensPV[nX][2]
		xPrcVen  := sfGetVal (aVetPrdItem,"unitValue","")//aItensPV[nX][3]
		/*
		If nPerDesc > 0
		Aadd(aCabec, {"C5_PDESCAB"   ,	nPerDesc					, Nil}) 
		ElseIf nPerDesc < 0
		Aadd(aCabec, {"C5_ACRSFIN"    ,	(nPerDesc * -1 )			, Nil}) 
		Endif
		*/
		// Pesquisa o preço de tabela
		xValUnit	:= 0
		DbSelectArea("DA1")
		DbSetOrder(1)
		If DbSeek(xFilial("DA1") + cDA0CODTAB + cB1Cod )
			xValUnit	:= DA1->DA1_PRCVEN
			xValUnit	:= xValUnit * nValFatFin
		Endif

		If xValUnit <= 0
			xValUnit	:= 1.00
			cMsgInt		:= cMsgInt + "-Produto " +cB1Cod + " Zerado"
		Endif

		If xPrcVen <= 0
			xPrcVen	:= xValUnit
			cMsgInt		:= cMsgInt + "-Prd." + Alltrim(cB1Cod) +"/"
		Endif

		If nPerDesc > 0
			xPrcVen	-= xPrcVen * nPerDesc / 100
		ElseIf nPerDesc < 0
			xPrcVen	+= xPrcVen * nPerDesc * -1  / 100
		Endif


		xValUnit	:= Round(xValUnit,TamSx3("C6_PRUNIT")[2])
		xPrcVen		:= Round(xPrcVen ,TamSx3("C6_PRCVEN")[2])
		xTotVal  	:= Round(xQtde * xPrcVen,TamSx3("C6_VALOR")[2])

		If xValUnit > 0
			aLinha := {}

			dbSelectArea("SB1")
			DbSetOrder(1)
			DbSeek(xFilial("SB1")+cB1Cod)
			//CB-ADAP2
			If Substr(SB1->B1_COD,1,3) == "CB-" .And. SB1->B1_UM == "KT"

				cCodReg		:= ""

				DbSelectArea("SE4")
				DbSetOrder(1)
				DbSeek(xFilial("SE4")+xE4Codigo)

				aBonus	:= U_BFFATA43(aCodRegBon,xA1Cod,xA1Loja,Padr(cDA0CODTAB,3),Padr(xE4Codigo,3) ,Nil,Nil,"1"/*cTipoRet*/)

				dbSelectArea("SB1")
				DbSetOrder(1)
				DbSeek(xFilial("SB1")+cB1Cod)
				aRegCombo	:= {}
				For iQ := 1 To Len(aBonus)
					//nPosCb	:= Ascan(aRegCombo, {|x| AllTrim(x[1]) == Substr(aBonus[iQ,2],1,6)})
					nPosCb 	:= AsCan(aRegCombo, {|x| x[2] == aBonus[iQ,3]}) //ACQ_CODPRO
					If nPosCb == 0	.And. aBonus[iQ,3] == SB1->B1_COD
						Aadd(aRegCombo,{Substr(aBonus[iQ,2],1,6),;	//ACQ_CODREG+ACR_ITEM
						aBonus[iQ,3],;								//ACQ_CODPRO
						aBonus[iQ,4],;								//ACQ_DESCRI
						SB1->B1_DESC,;
							MaTabPrVen(cDA0CODTAB,aBonus[iQ,3],1,xA1Cod,xA1Loja,1/*nMoeda*/,dDataBase/*dDataVld*/,1/*nTipo*/,.F. /*lExec*/,,.F./*lProspect*/),;
							SB1->B1_ZCLCOM,;
							aBonus[iQ,14]})
						cCodReg	:= aRegCombo[1,1]
						Aadd(aCodRegBon,cCodReg)
					Endif
				Next

				aItemCombo	:= {}
				For iE := 1 To Len(aBonus)
					If Substr(aBonus[iE][2],1,6) == cCodReg
						Aadd(aItemCombo,aClone(aBonus[iE]))
					Endif
				Next

				cMsgInt		:= cMsgInt + "-Combo." + Alltrim(cB1Cod) +" Qte: " +  cValToChar(xQtde)+ "/"

				nPrcCombo	:= xPrcVen
				If Len(aRegCombo) == 0
					nQtdrej 	:= xQtde
					nPrcunrej 	:= nPrcCombo
					//Aadd(aRejeita,{"Combo digitado com erro de preço",SB1->B1_COD,SB1->B1_DESC,nQtdrej,nPrcunrej})
					cAssunto 	:= "Importação Ajili - Empresa:" + cEmpAnt+"/" + cFilAnt + " " + Capital(SM0->M0_NOME)
					cMensagem	:= "Problema de validação Combo de Produtos / " + cMsgInt + CRLF
					cMensagem 	+= "Pedido: " + cValToChar(cNumPed) + CRLF
					cMensagem	+= "Usuário:  " + cUserName + "-" + UsrFullName(__cUserId) + CRLF
					cMensagem	+= "Data/Hora: " + Dtoc( Date() ) + " as " + Time() + CRLF

					U_WFGERAL(	"rafael@grupoforta.com.br;ml-servicos@outlook.com"/*cEmail*/,cAssunto/*cTitulo*/,cMensagem/*cTexto*/,"GETPVC"/*cRotina*/,/*cAnexo*/)

					// Faz chamada para fazer o ajuste de preço de venda de cada item
				ElseIf !sfVldPrc(@nPrcCombo,@aItemCombo,aRegCombo[1,5],aRegCombo[1,7])
					nQtdrej 	:= xQtde
					nPrcunrej 	:= nPrcCombo
					//Aadd(aRejeita,{"Combo digitado com erro de preço",SB1->B1_COD,SB1->B1_DESC,nQtdrej,nPrcunrej})
					cAssunto 	:= "Importação Ajili - Empresa:" + cEmpAnt+"/" + cFilAnt + " " + Capital(SM0->M0_NOME)
					cMensagem	:= "Problema de validação Combo de Produtos / " + cMsgInt + CRLF
					cMensagem 	+= "Pedido: " + cValToChar(cNumPed) + CRLF
					cMensagem	+= "Usuário:  " + cUserName + "-" + UsrFullName(__cUserId) + CRLF
					cMensagem	+= "Data/Hora: " + Dtoc( Date() ) + " as " + Time() + CRLF

					U_WFGERAL(	"rafael@grupoforta.com.br;ml-servicos@outlook.com"/*cEmail*/,cAssunto/*cTitulo*/,cMensagem/*cTexto*/,"GETPVC"/*cRotina*/,/*cAnexo*/)

				Else

					For iE := 1 To Len(aItemCombo)
						dbSelectArea("SB1")
						dbSetOrder(1)
						If dbSeek(xFilial("SB1")+aItemCombo[iE,5])

							cItem := Soma1(cItem)

							aLinha := {{"C6_ITEM"	,cItem									,Nil}} 		// Item

							Aadd(aLinha,{"C6_PRODUTO"    ,aItemCombo[iE,5]		            ,Nil}) 		// Codigo do Produto
							Aadd(aLinha,{"C6_QTDVEN"     ,aItemCombo[iE,7]*xQtde				,Nil})	 	// Quantidade Vendida
							Aadd(aLinha,{"C6_XUPRCVE"    ,aItemCombo[iE,12]				   	,Nil})		// Preço de Venda
							Aadd(aLinha,{"C6_OPER"       ,aItemCombo[iE,8] 				   	,Nil}) 		// Tipo de Operação
							Aadd(aLinha,{"C6_XREGBNF"	,aItemCombo[iE,2]					,Nil})		// Código da Regra de Bonificação


							Aadd(aLinha,{"C6_IDAJILI" ,sfGetVal (aVetPrditem,"id",""),Nil})
							If lC6QtdLib
								Aadd(aLinha,{"C6_QTDLIB"    ,aItemCombo[iE,7]*xQtde	        ,Nil})
							Endif

							aadd(aItens, aLinha)

							// Atualiza o Id só pelo primeiro item
							If iE == 1
								AAdd(aAtualiza,sfGetVal (aVetItems,"id",""))
							Endif


						Endif
					Next
				Endif
				dbSelectArea("SB1")
				DbSetOrder(1)
				DbSeek(xFilial("SB1")+cB1Cod)
			Else
				cItem := Soma1(cItem)

				aadd(aLinha,{"C6_ITEM"   , cItem		 , Nil})
				aadd(aLinha,{"C6_PRODUTO", cB1Cod        , Nil})
				aadd(aLinha,{"C6_QTDVEN" , xQtde         , Nil})
				//aadd(aLinha,{"C6_PRCVEN" , xPrcVen       , Nil})
				aadd(aLinha,{"C6_XUPRCVE" , xPrcVen       , Nil})
				//aadd(aLinha,{"C6_VALOR"  , xTotVal       , Nil})
				If lC6QtdLib
					Aadd(aLinha,{"C6_QTDLIB"    ,xQtde	            ,Nil})
				Endif
				Aadd(aLinha,{"C6_IDAJILI" ,sfGetVal (aVetPrditem,"id",""),Nil})
				aadd(aItens, aLinha)
				AAdd(aAtualiza,sfGetVal (aVetItems,"id",""))
			Endif
		Endif

	Next nX
	// Adiciona mensagem no final , pois pode ocorrer alertas por itens
	aadd(aCabec, {"C5_ZMSGINT"	,  cMsgInt	, Nil})

	If lDebug
		VarInfo("aItens",aItens)
	Endif

	nOpcX := 3
	If Len(aItens) > 0
		// Altera a pergunta de sugestão de quantidade
		U_GRAVASX1("MTA410", "01", Iif(lC6QtdLib,1,2)) // 1-Sim 2-Não


		MSExecAuto({|a, b, c, d| MATA410(a, b, c, d)}, aCabec, aItens, nOpcX, .F.)

		If !lMsErroAuto
			ConfirmSx8()

			cQry := " SELECT C5_NUM "
			cQry += "  FROM "+RetSqlName("SC5")
			cQry += " WHERE C5_IDAJILI = " +cValToChar(cNumPed)
			cQry += "   AND C5_FILIAL = '" + xFilial("SC5") + "' "

			TcQuery cQry New Alias "QSC5"

			If !Eof()
				fAtualiza(aAtualiza,QSC5->C5_NUM,.F.)
			Else
				fAtualiza(aAtualiza,"xxxxxx",.F.)
			Endif
			QSC5->(DbCloseArea())
			aAtualiza :={}
		Else
			ConOut("Erro na inclusao!")
			If !IsBlind()
				MostraErro()
			Endif
			aErroAuto := GetAutoGRLog()
			For nCount := 1 To Len(aErroAuto)
				cLogErro += StrTran(StrTran(aErroAuto[nCount], "<", ""), "-", "") + " "
				ConOut(cLogErro)
			Next nCount

			fAtualiza(aAtualiza,"xxxxxx",.F.)

			cAssunto 	:= "Importação Ajili - Empresa:" + cEmpAnt+"/" + cFilAnt + " " + Capital(SM0->M0_NOME)
			cMensagem	:= cLogErro + CRLF
			cMensagem 	+= "Pedido: " + cValToChar(cNumPed) + CRLF
			cMensagem	+= "Usuário:  " + cUserName + "-" + UsrFullName(__cUserId) + CRLF
			cMensagem	+= "Data/Hora: " + Dtoc( Date() ) + " as " + Time() + CRLF

			U_WFGERAL(	"rafael@grupoforta.com.br;ml-servicos@outlook.com"/*cEmail*/,cAssunto/*cTitulo*/,cMensagem/*cTexto*/,"GETPVC"/*cRotina*/,/*cAnexo*/)

			aAtualiza :={}
		EndIf
		// Altera para o padrão de sempre sugerir
		U_GRAVASX1("MTA410", "01", 1) // 1-Sim 2-Não

	Else
		fAtualiza(aAtualiza,"xxxxxx",.F.)
		aAtualiza :={}
		cAssunto 	:= "Importação Ajili - Empresa:" + cEmpAnt+"/" + cFilAnt + " " + Capital(SM0->M0_NOME)
		cMensagem	:= "Não houveram itens para gerar um pedido de venda " + CRLF
		cMensagem 	+= "Pedido: " + cValToChar(cNumPed) + CRLF
		cMensagem	+= "Usuário:  " + cUserName + "-" + UsrFullName(__cUserId) + CRLF
		cMensagem	+= "Data/Hora: " + Dtoc( Date() ) + " as " + Time() + CRLF

		U_WFGERAL(	"rafael@grupoforta.com.br;ml-servicos@outlook.com"/*cEmail*/,cAssunto/*cTitulo*/,cMensagem/*cTexto*/,"GETPVC"/*cRotina*/,/*cAnexo*/)


	Endif

	// Se o clinete é novo, efetua o bloqueio do mesmo depois de incluir o pedido
	If lA1New
		DbSelectArea("SA1")
		DbSetOrder(3)
		If DbSeek(xFilial("SA1")+cCnpjCli)
			RecLock("SA1",.F.)
			SA1->A1_MSBLQL		:= "1"
			MsUnlock()
		Endif
	Endif

Return


Static Function sfGeraOrc()


	Local aCabec   		:= {}
	Local aItens   		:= {}
	Local aLinha   		:= {}
	Local xA1Cod   		:= ""
	Local xA1Loja  		:= ""
	Local cCnpjCli		:= ""
	Local xE4Codigo		:= ""
	Local nX       		:= 0
	Local iQ
	Local iE
	Local xQtde    		:= 0.000
	Local xValUnit 		:= 0.00
	Local xPrcVen		:= 0.00
	Local xTotVal  		:= 0.00
	Local nPerDesc		:= 0.00
	Local aErroAuto 	:= {}
	Local aCodRegBon	:= {}
	Local cLogErro 		:= ""
	Local nCount   		:= 0
	Local cMsgInt		:= ""
	Local cIdA1Cod		:= Space(8)
	Local lA1New		:= .F.
	Local nValFatFin	:= 0
	Local cDA0CODTAB	:= ""

	Private lMsErroAuto := .F.

	// Atribui número do pedido
	cNumPed		:= sfGetVal (aVetOrder,"id","")

	nPerDesc	:= sfGetVal (aVetOrder,"percentDiscount","")
	If nPerDesc <> Nil
		nPerDesc	:= Round(nPerDesc * 100 , 2)
	Else
		nPerDesc	:= 0
	Endif


	nDA0Codigo	:= sfGetVal (aVetPrcTable,"id","")
	If nDA0Codigo == Nil .Or. Empty(nDA0Codigo)
		nDA0Codigo	:= 0
	Endif
	If nDA0Codigo > 0
		cDA0CODTAB	:= sfFindIdAj("DA0"/*cInAlias*/,nDA0Codigo/*nInIdAjili*/,"DA0_CODTAB"/*cCpoOut*/)
	Endif
	If cDA0CODTAB <> sfGetVal (aVetPrcTable,"idErp","")
		//	MsgAlert("Diferença código de tabela de preços entre o Ajili e o ERP")
	Endif
	If cDA0CODTAB == Nil .Or. Empty(cDA0CODTAB)
		If cFilAnt == "0301"
			cDA0CODTAB	:= "201"
		ElseIf cFilAnt == "0101"
			cDA0CODTAB	:= "601"
		ElseIf cFilAnt == "0201"
			cDA0CODTAB	:= "501"
		ElseIf cFilAnt == "0401"
			cDA0CODTAB	:= "101"
		Endif
	Endif

	// Trecho que verifica se já houve importação do pedido
	cQry := "SELECT UA_NUM "
	cQry += "  FROM "+RetSqlName("SUA")
	cQry += " WHERE UA_IDAJILI = " +cValToChar(cNumPed)
	cQry += "   AND UA_FILIAL = '" + xFilial("SC5") + "' "

	TcQuery cQry New Alias "QSUA"

	If !Eof()

		cAssunto 	:= "Importação Ajili - Empresa:" + cEmpAnt+"/" + cFilAnt + " " + Capital(SM0->M0_NOME)
		cMensagem	:= "Pedido já importado anteriormente."  + CRLF
		cMensagem 	+= "Pedido: " + cValToChar(cNumPed) + CRLF
		cMensagem	+= "Usuário:  " + cUserName + "-" + UsrFullName(__cUserId) + CRLF
		cMensagem	+= "Data/Hora: " + Dtoc( Date() ) + " as " + Time() + CRLF

		U_WFGERAL(	"rafael@grupoforta.com.br;ml-servicos@outlook.com"/*cEmail*/,cAssunto/*cTitulo*/,cMensagem/*cTexto*/,"GETPVC"/*cRotina*/,/*cAnexo*/)

		fAtualiza({},QSUA->UA_NUM,.T.)

		QSUA->(DbCloseArea())
		Return

	Endif
	QSUA->(DbCloseArea())

	nCodCli		:= sfGetVal (aVetCustomer,"id","")
	cIdA1Cod	:= sfGetVal (aVetCustomer,"idErp","")

	If cIdA1Cod == Nil .Or. Empty(cIdA1Cod)
		cIdA1Cod	:= Space(8)
		cCnpjCli	:= sfGetVal (aVetCustomer,"federalId","")
		If cCnpjCli == Nil .Or. Empty(cCnpjCli)
			MsgAlert("Cliente novo para ser cadastrado porém não há informação do CNPJ no Ajili. Favor contatar o TI","")
			fAtualiza(aAtualiza,"xxxxxx",.T.)

			cAssunto 	:= "Importação Ajili - Empresa:" + cEmpAnt+"/" + cFilAnt + " " + Capital(SM0->M0_NOME)
			cMensagem	:= "Cliente novo para ser cadastrado porém não há informação do CNPJ no Ajili. Favor contatar o TI"  + CRLF
			cMensagem 	+= "Pedido: " + cValToChar(cNumPed) + CRLF
			cMensagem	+= "Usuário:  " + cUserName + "-" + UsrFullName(__cUserId) + CRLF
			cMensagem	+= "Data/Hora: " + Dtoc( Date() ) + " as " + Time() + CRLF

			U_WFGERAL(	"rafael@grupoforta.com.br;ml-servicos@outlook.com"/*cEmail*/,cAssunto/*cTitulo*/,cMensagem/*cTexto*/,"GETPVC"/*cRotina*/,/*cAnexo*/)

			aAtualiza :={}
			Return
		Endif

		DbSelectArea("SA1")
		DbSetOrder(3)
		If DbSeek(xFilial("SA1")+cCnpjCli)
			cIdA1Cod	:= SA1->A1_COD+SA1->A1_LOJA

			Begin Transaction

				DbSelectArea("SA1")
				RecLock("SA1",.F.)
				SA1->A1_MSEXP	:=  " "
				MsUnlock()

				DbSelectArea("Z00")
				DbSetOrder(1)//Z00_FILIAL+Z00_ENTIDA+Z00_CHAVE
				If DbSeek(xFilial("Z00") + "SA1" + SA1->(A1_FILIAL+A1_COD+A1_LOJA))
					//nIdAjili		:= Z00->Z00_IDAJIL
					RecLock("Z00",.F.)
				Else
					RecLock("Z00",.T.)
				Endif

				Z00->Z00_FILIAL 	:= xFilial("Z00")	//- Filial
				Z00->Z00_ENTIDA 	:= "SA1"			//- Entidade
				Z00->Z00_NCHAVE 	:= 1				//- Indice da Entidade
				Z00->Z00_CHAVE  	:= SA1->(A1_FILIAL+A1_COD+A1_LOJA)	//- Chave de pesquisa/relação
				Z00->Z00_INTEGR 	:= "X"				//- Status Integração
				Z00->Z00_IDAJIL 	:= nCodCli			//- Id de Integração Ajili
				MsUnlock()
			End Transaction

			// Efetua chamada para forçar atualização do cliente no Ajili
			U_RestCli({},cIdA1Cod)


		Else

			If !sfNewCli()
				MsgAlert("Não encontrou cadastro de cliente para o CNPJ: " + cCnpjCli + " e não conseguiu inserir o cadastro automaticamente!" )
				fAtualiza(aAtualiza,"xxxxxx",.T.)

				cAssunto 	:= "Importação Ajili - Empresa:" + cEmpAnt+"/" + cFilAnt + " " + Capital(SM0->M0_NOME)
				cMensagem	:= "Não encontrou cadastro de cliente para o CNPJ: " + cCnpjCli + " e não conseguiu inserir o cadastro automaticamente!"  + CRLF
				cMensagem 	+= "Pedido: " + cValToChar(cNumPed) + CRLF
				cMensagem	+= "Usuário:  " + cUserName + "-" + UsrFullName(__cUserId) + CRLF
				cMensagem	+= "Data/Hora: " + Dtoc( Date() ) + " as " + Time() + CRLF

				U_WFGERAL(	"rafael@grupoforta.com.br;ml-servicos@outlook.com"/*cEmail*/,cAssunto/*cTitulo*/,cMensagem/*cTexto*/,"GETPVC"/*cRotina*/,/*cAnexo*/)

				Return
			Endif

			lA1New	:= .T.

			DbSelectArea("SA1")
			DbSetOrder(3)
			If DbSeek(xFilial("SA1")+cCnpjCli)
				cIdA1Cod	:= SA1->A1_COD+SA1->A1_LOJA

				DbSelectArea("SA1")
				RecLock("SA1",.F.)
				SA1->A1_MSEXP	:= " "
				MsUnlock()

			Endif
			Begin Transaction
				DbSelectArea("Z00")
				DbSetOrder(1)//Z00_FILIAL+Z00_ENTIDA+Z00_CHAVE
				If DbSeek(xFilial("Z00") + "SA1" + SA1->(A1_FILIAL+A1_COD+A1_LOJA))
					//nIdAjili		:= Z00->Z00_IDAJIL
					RecLock("Z00",.F.)
				Else
					RecLock("Z00",.T.)

				Endif
				Z00->Z00_FILIAL 	:= xFilial("Z00")	//- Filial
				Z00->Z00_ENTIDA 	:= "SA1"			//- Entidade
				Z00->Z00_NCHAVE 	:= 1				//- Indice da Entidade
				Z00->Z00_CHAVE  	:= SA1->(A1_FILIAL+A1_COD+A1_LOJA)	//- Chave de pesquisa/relação
				Z00->Z00_INTEGR 	:= "X"				//- Status Integração
				Z00->Z00_IDAJIL 	:= nCodCli			//- Id de Integração Ajili
				MsUnlock()
			End Transaction
		Endif
	Endif

	xA1Cod		:= sfFindIdAj("SA1"/*cInAlias*/,nCodCli/*nInIdAjili*/,"A1_COD"/*cCpoOut*/, Substr(cIdA1Cod,1,6), xFilial("SA1")+cIdA1Cod )
	If xA1Cod <> Substr(cIdA1Cod,1,6)
		MsgAlert("Diferença código de cliente id Ajili " + Iif(xA1Cod <> Nil , xA1Cod , "0") + " e código pelo cnpj " + Substr(cIdA1Cod,1,6) , "Cnpj: " + cCnpjCli)

		cAssunto 	:= "Importação Ajili - Empresa:" + cEmpAnt+"/" + cFilAnt + " " + Capital(SM0->M0_NOME)
		cMensagem	:= "Diferença código de cliente id Ajili " + Iif(xA1Cod <> Nil , xA1Cod , "0") + " e código pelo cnpj " + cCnpjCli + " Código:" + Substr(cIdA1Cod,1,6) + CRLF
		cMensagem 	+= "Pedido: " + cValToChar(cNumPed) + CRLF
		cMensagem	+= "Usuário:  " + cUserName + "-" + UsrFullName(__cUserId) + CRLF
		cMensagem	+= "Data/Hora: " + Dtoc( Date() ) + " as " + Time() + CRLF

		U_WFGERAL(	"rafael@grupoforta.com.br;ml-servicos@outlook.com"/*cEmail*/,cAssunto/*cTitulo*/,cMensagem/*cTexto*/,"GETPVC"/*cRotina*/,/*cAnexo*/)
		//	Return
	Endif

	xA1Loja		:= sfFindIdAj("SA1"/*cInAlias*/,nCodCli/*nInIdAjili*/,"A1_LOJA"/*cCpoOut*/,Substr(cIdA1Cod,7,2),xFilial("SA1")+cIdA1Cod )
	If xA1Loja <> Substr(cIdA1Cod,7,2)
		MsgAlert("Diferença código de loja id Ajili " + Iif(xA1Loja <> Nil , xA1Loja , "0") + " e código pelo cnpj " + Substr(cIdA1Cod,7,2) , "Cnpj: " + cCnpjCli)
		cAssunto 	:= "Importação Ajili - Empresa:" + cEmpAnt+"/" + cFilAnt + " " + Capital(SM0->M0_NOME)
		cMensagem	:= "Diferença código de cliente id Ajili " + Iif(xA1Loja <> Nil , xA1Loja , "0") + " e código pelo cnpj " + cCnpjCli + " Loja: " + Substr(cIdA1Cod,7,2)  + CRLF
		cMensagem 	+= "Pedido: " + cValToChar(cNumPed) + CRLF
		cMensagem	+= "Usuário:  " + cUserName + "-" + UsrFullName(__cUserId) + CRLF
		cMensagem	+= "Data/Hora: " + Dtoc( Date() ) + " as " + Time() + CRLF

		U_WFGERAL(	"rafael@grupoforta.com.br;ml-servicos@outlook.com"/*cEmail*/,cAssunto/*cTitulo*/,cMensagem/*cTexto*/,"GETPVC"/*cRotina*/,/*cAnexo*/)
		//	Return
	Endif

	xA1Cod	:= Substr(cIdA1Cod,1,6)
	xA1Loja	:= Substr(cIdA1Cod,7,2)

	nCondPag	:= sfGetVal (aVetPayTerms,"id","")
	xE4Codigo	:= sfFindIdAj("SE4"/*cInAlias*/,nCondPag/*nInIdAjili*/,"E4_CODIGO"/*cCpoOut*/)
	If xE4Codigo <> sfGetVal (aVetPayTerms,"idErp","")
		//ShowHelpDlg(ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Diferença de cadastros!",;
			//		{"Diferença código de condição de pagamento entre o Ajili e o ERP"},;
			//		5,;
			//		{""},;
			//		5)
		xE4Codigo	:= "107"
	Endif
	If xE4Codigo == Nil .Or. Empty(xE4Codigo)
		xE4Codigo	:= "107"
	Endif



	cC5Vend1	:= sfGetVal (aVetSalesman,"idErp","")

	If Empty(cC5Vend1) .Or. cC5Vend1 == Nil
		cC5Vend1	:= Posicione("SA1",1,xFilial("SA1")+xA1Cod + xA1Loja , "A1_VEND")
	Endif
	cMsgInt :=  sfGetVal (aVetOrder,"notes","")
	If cMsgInt == Nil
		cMsgInt := ""
	Endif
	cMsgInt	:= "Pedido Ajili: " + cValToChar(cNumPed) + "-" + sfAjust(cMsgInt,,.T.)


	// Força o ajuste do código de vendedor conforme o cadastro do cliente se o vendedor do Vellis estiver bloqueado
	DbSelectArea("SA3")
	DbSetOrder(1)
	DbSeek(xFilial("SA3")+cC5Vend1)
	If !RegistroOk("SA3",.F.)
		If !Empty(cC5Vend1) .And. cC5Vend1 <> Posicione("SA1",1,xFilial("SA1")+xA1Cod + xA1Loja , "A1_VEND")
			cC5Vend1	:= Posicione("SA1",1,xFilial("SA1")+xA1Cod + xA1Loja , "A1_VEND")
			cMsgInt		:= cMsgInt + "-Vendedor ajustado."
		Endif
	Endif


	aadd(aCabec, {"UA_CLIENTE"	, 	xA1Cod							, Nil})
	aadd(aCabec, {"UA_LOJA"		, 	xA1Loja							, Nil})
	aadd(aCabec, {"UA_CONDPG"	, 	xE4Codigo						, Nil})
	aadd(aCabec, {"UA_TABELA"	,  	cDA0CODTAB						, Nil})
	aadd(aCabec, {"UA_IDAJILI" 	, 	cNumPed							, Nil})
	Aadd(aCabec, {"UA_VEND"     ,	cC5Vend1						, Nil})
	Aadd(aCabec, {"UA_TMK"  	,	"4"								, Nil})
	Aadd(aCabec, {"UA_OPER"     ,	"2"								, Nil})
	Aadd(aCabec, {"UA_OPERADO"  ,   "000001"						, Nil})



	cMsgInt :=  sfGetVal (aVetOrder,"notes","")
	If cMsgInt == Nil
		cMsgInt := ""
	Endif
	cMsgInt	:= "Pedido Ajili: " + cValToChar(cNumPed) + "-" + sfAjust(cMsgInt,,.T.)



	dbSelectArea("SE4")
	dbSetOrder(1)
	If dbSeek(FwxFilial("SE4")+xE4Codigo)
		nValFatFin := SE4->E4_ZFATFIN
	EndIf


	If lDebug
		VarInfo("aCabec",aCabec)
	Endif
	cItem	:= "00"
	For nX := 1 To Len(aVetItems)

		aVetPrdItem	:= sfGetVal (aVetItems,"#_OBJECT_#","",nX)
		If lDebug
			VarInfo("aVetPrditem",aVetPrdItem)
		Endif

		aProdItem	:= sfGetVal (aVetPrdItem,"#_OBJECT_#","")
		If lDebug
			VarInfo("aProdItem",aProdItem)
		Endif

		nB1Cod	:= sfGetVal (aProdItem,"id","")
		cB1Cod	:= sfFindIdAj("SB1"/*cInAlias*/,nB1Cod/*nInIdAjili*/,"B1_COD"/*cCpoOut*/)
		If cB1Cod <> sfGetVal (aProdItem,"idErp","")
			MsgAlert("Diferença código de condição de pagamento entre o Ajili e o ERP")
		Endif
		If cB1Cod == Nil
			MsgAlert("Erro ao obter código de produto do Id " + cValToChar(nB1Cod ))
			Loop
		Endif
		xQtde    := sfGetVal (aVetPrdItem,"quantity","")// aItensPV[nX][2]
		xPrcVen  := sfGetVal (aVetPrdItem,"unitValue","")//aItensPV[nX][3]
		/*
		If nPerDesc > 0
		Aadd(aCabec, {"C5_PDESCAB"   ,	nPerDesc					, Nil}) 
		ElseIf nPerDesc < 0
		Aadd(aCabec, {"C5_ACRSFIN"    ,	(nPerDesc * -1 )			, Nil}) 
		Endif
		*/
		// Pesquisa o preço de tabela
		xValUnit	:= 0
		DbSelectArea("DA1")
		DbSetOrder(1)
		If DbSeek(xFilial("DA1") + cDA0CODTAB + cB1Cod )
			xValUnit	:= DA1->DA1_PRCVEN
			xValUnit	:= xValUnit * nValFatFin
		Endif

		If xValUnit <= 0
			xValUnit	:= 1.00
			cMsgInt		:= cMsgInt + "-Produto " +cB1Cod + " Zerado"
		Endif

		If xPrcVen <= 0
			xPrcVen	:= xValUnit
			cMsgInt		:= cMsgInt + "-Prd." + Alltrim(cB1Cod) +"/"
		Endif

		If nPerDesc > 0
			xPrcVen	-= xPrcVen * nPerDesc / 100
		ElseIf nPerDesc < 0
			xPrcVen	+= xPrcVen * nPerDesc * -1  / 100
		Endif


		xValUnit	:= Round(xValUnit,TamSx3("C6_PRUNIT")[2])
		xPrcVen		:= Round(xPrcVen ,TamSx3("C6_PRCVEN")[2])
		xTotVal  	:= Round(xQtde * xPrcVen,TamSx3("C6_VALOR")[2])

		If xValUnit > 0
			aLinha := {}

			dbSelectArea("SB1")
			DbSetOrder(1)
			DbSeek(xFilial("SB1")+cB1Cod)
			//CB-ADAP2
			If Substr(SB1->B1_COD,1,3) == "CB-" .And. SB1->B1_UM == "KT"

				cCodReg		:= ""

				DbSelectArea("SE4")
				DbSetOrder(1)
				DbSeek(xFilial("SE4")+xE4Codigo)

				aBonus	:= U_BFFATA43(aCodRegBon,xA1Cod,xA1Loja,Padr(cDA0CODTAB,3),Padr(xE4Codigo,3) ,Nil,Nil,"1"/*cTipoRet*/)

				dbSelectArea("SB1")
				DbSetOrder(1)
				DbSeek(xFilial("SB1")+cB1Cod)
				aRegCombo	:= {}
				For iQ := 1 To Len(aBonus)
					//nPosCb	:= Ascan(aRegCombo, {|x| AllTrim(x[1]) == Substr(aBonus[iQ,2],1,6)})
					nPosCb 	:= AsCan(aRegCombo, {|x| x[2] == aBonus[iQ,3]}) //ACQ_CODPRO
					If nPosCb == 0	.And. Alltrim(aBonus[iQ,3]) == Alltrim(cB1Cod)
						Aadd(aRegCombo,{Substr(aBonus[iQ,2],1,6),;	//ACQ_CODREG+ACR_ITEM
						aBonus[iQ,3],;								//ACQ_CODPRO
						aBonus[iQ,4],;								//ACQ_DESCRI
						SB1->B1_DESC,;
							MaTabPrVen(cDA0CODTAB,aBonus[iQ,3],1,xA1Cod,xA1Loja,1/*nMoeda*/,dDataBase/*dDataVld*/,1/*nTipo*/,.F. /*lExec*/,,.F./*lProspect*/),;
							SB1->B1_ZCLCOM,;
							aBonus[iQ,14]})

						cCodReg	:= aRegCombo[1,1]
						Aadd(aCodRegBon,cCodReg)
					Endif
				Next

				aItemCombo	:= {}
				For iE := 1 To Len(aBonus)
					If Substr(aBonus[iE][2],1,6) == cCodReg
						Aadd(aItemCombo,aClone(aBonus[iE]))
					Endif
				Next

				cMsgInt		:= cMsgInt + "-Combo." + Alltrim(cB1Cod) +" Qte: " +  cValToChar(xQtde)+ "/"

				nPrcCombo	:= xPrcVen
				If Len(aRegCombo) ==  0
					nQtdrej 	:= xQtde
					nPrcunrej 	:= nPrcCombo
					//Aadd(aRejeita,{"Combo digitado com erro de preço",SB1->B1_COD,SB1->B1_DESC,nQtdrej,nPrcunrej})
					cAssunto 	:= "Importação Ajili - Empresa:" + cEmpAnt+"/" + cFilAnt + " " + Capital(SM0->M0_NOME)
					cMensagem	:= "Problema de validação Combo de Produtos / " + cMsgInt + CRLF
					cMensagem 	+= "Pedido: " + cValToChar(cNumPed) + CRLF
					cMensagem	+= "Usuário:  " + cUserName + "-" + UsrFullName(__cUserId) + CRLF
					cMensagem	+= "Data/Hora: " + Dtoc( Date() ) + " as " + Time() + CRLF

					U_WFGERAL(	"rafael@grupoforta.com.br;ml-servicos@outlook.com"/*cEmail*/,cAssunto/*cTitulo*/,cMensagem/*cTexto*/,"GETPVC"/*cRotina*/,/*cAnexo*/)

					// Faz chamada para fazer o ajuste de preço de venda de cada item
				ElseIf !sfVldPrc(@nPrcCombo,@aItemCombo,aRegCombo[1,5],aRegCombo[1,7])
					nQtdrej 	:= xQtde
					nPrcunrej 	:= nPrcCombo
					//Aadd(aRejeita,{"Combo digitado com erro de preço",SB1->B1_COD,SB1->B1_DESC,nQtdrej,nPrcunrej})
					cAssunto 	:= "Importação Ajili - Empresa:" + cEmpAnt+"/" + cFilAnt + " " + Capital(SM0->M0_NOME)
					cMensagem	:= "Problema de validação Combo de Produtos / " + cMsgInt + CRLF
					cMensagem 	+= "Pedido: " + cValToChar(cNumPed) + CRLF
					cMensagem	+= "Usuário:  " + cUserName + "-" + UsrFullName(__cUserId) + CRLF
					cMensagem	+= "Data/Hora: " + Dtoc( Date() ) + " as " + Time() + CRLF

					U_WFGERAL(	"rafael@grupoforta.com.br;ml-servicos@outlook.com"/*cEmail*/,cAssunto/*cTitulo*/,cMensagem/*cTexto*/,"GETPVC"/*cRotina*/,/*cAnexo*/)

				Else

					For iE := 1 To Len(aItemCombo)
						dbSelectArea("SB1")
						dbSetOrder(1)
						If dbSeek(xFilial("SB1")+aItemCombo[iE,5])

							cItem := Soma1(cItem)

							aLinha := {{"UB_ITEM"	,cItem									,Nil}} 		// Item

							Aadd(aLinha,{"UB_PRODUTO"    ,aItemCombo[iE,5]		            ,Nil}) 		// Codigo do Produto
							Aadd(aLinha,{"UB_QUANT"      ,aItemCombo[iE,7]*xQtde			,Nil})	 	// Quantidade Vendida
							Aadd(aLinha,{"UB_XUPRCVE"    ,aItemCombo[iE,12]				   	,Nil})		// Preço de Venda
							Aadd(aLinha,{"UB_OPER"       ,aItemCombo[iE,8] 				   	,Nil}) 		// Tipo de Operação
							Aadd(aLinha,{"UB_XREGBNF"  	 ,aItemCombo[iE,2]					,Nil})		// Código da Regra de Bonificação


							Aadd(aLinha,{"UB_IDAJILI" ,sfGetVal (aVetPrditem,"id",""),Nil})

							aadd(aItens, aLinha)

							// Atualiza o Id só pelo primeiro item
							If iE == 1
								AAdd(aAtualiza,sfGetVal (aVetItems,"id",""))
							Endif


						Endif
					Next
				Endif
				dbSelectArea("SB1")
				DbSetOrder(1)
				DbSeek(xFilial("SB1")+cB1Cod)
			Else
				cItem := Soma1(cItem)

				aadd(aLinha,{"UB_ITEM"   , cItem		 , Nil})
				aadd(aLinha,{"UB_PRODUTO", cB1Cod        , Nil})
				aadd(aLinha,{"UB_QUANT"  , xQtde         , Nil})
				aadd(aLinha,{"UB_XUPRCVE" , xPrcVen       , Nil})
				Aadd(aLinha,{"UB_IDAJILI" ,sfGetVal (aVetPrditem,"id",""),Nil})
				aadd(aItens, aLinha)
				AAdd(aAtualiza,sfGetVal (aVetItems,"id",""))
			Endif
		Endif

	Next nX
	// Adiciona mensagem no final , pois pode ocorrer alertas por itens
	aadd(aCabec, {"UA_ZMSGINT"	,  cMsgInt	, Nil})

	If lDebug
		VarInfo("aItens",aItens)
	Endif

	nOpcX := 3
	If Len(aItens) > 0
		MSExecAuto({|a, b, c, d| TMKA271(a, b, c, d)}, aCabec, aItens, nOpcX,'2')

		If !lMsErroAuto
			ConfirmSx8()
			dbSelectArea("SUA")
			DbOrderNickName("UAIDAJILI") // UA_IDAJILI+UA_FILIAL+UA_NUM
			If DbSeek(Str(cNumPed,11,0)+xFilial("SUA"))
				ConOut("Incluido com sucesso! " + SUA->UA_NUM)
				fAtualiza(aAtualiza,SUA->UA_NUM,.T.)
				aAtualiza :={}
			Else
				ConOut("Não encontrou registro na SUA para ID Ajili " +Str(cNumPed,11,0) )
			Endif
		Else
			ConOut("Erro na inclusao!")
			MostraErro()
			aErroAuto := GetAutoGRLog()
			For nCount := 1 To Len(aErroAuto)
				cLogErro += StrTran(StrTran(aErroAuto[nCount], "<", ""), "-", "") + " "
				ConOut(cLogErro)
			Next nCount

			fAtualiza(aAtualiza,"xxxxxx",.T.)

			cAssunto 	:= "Importação Ajili - Empresa:" + cEmpAnt+"/" + cFilAnt + " " + Capital(SM0->M0_NOME)
			cMensagem	:= cLogErro + CRLF
			cMensagem 	+= "Pedido: " + cValToChar(cNumPed) + CRLF
			cMensagem	+= "Usuário:  " + cUserName + "-" + UsrFullName(__cUserId) + CRLF
			cMensagem	+= "Data/Hora: " + Dtoc( Date() ) + " as " + Time() + CRLF

			U_WFGERAL(	"rafael@grupoforta.com.br;ml-servicos@outlook.com"/*cEmail*/,cAssunto/*cTitulo*/,cMensagem/*cTexto*/,"GETPVC"/*cRotina*/,/*cAnexo*/)

			aAtualiza :={}
		EndIf
	Else
		fAtualiza(aAtualiza,"xxxxxx",.T.)
		aAtualiza :={}
		cAssunto 	:= "Importação Ajili - Empresa:" + cEmpAnt+"/" + cFilAnt + " " + Capital(SM0->M0_NOME)
		cMensagem	:= "Não houveram itens para gerar um pedido de venda " + CRLF
		cMensagem 	+= "Pedido: " + cValToChar(cNumPed) + CRLF
		cMensagem	+= "Usuário:  " + cUserName + "-" + UsrFullName(__cUserId) + CRLF
		cMensagem	+= "Data/Hora: " + Dtoc( Date() ) + " as " + Time() + CRLF

		U_WFGERAL(	"rafael@grupoforta.com.br;ml-servicos@outlook.com"/*cEmail*/,cAssunto/*cTitulo*/,cMensagem/*cTexto*/,"GETPVC"/*cRotina*/,/*cAnexo*/)


	Endif

	// Se o clinete é novo, efetua o bloqueio do mesmo depois de incluir o pedido
	If lA1New
		DbSelectArea("SA1")
		DbSetOrder(3)
		If DbSeek(xFilial("SA1")+cCnpjCli)
			RecLock("SA1",.F.)
			SA1->A1_MSBLQL		:= "1"
			MsUnlock()
		Endif
	Endif

Return

/*/{Protheus.doc} sfVldPrc
Rotina que verifica os preços do Combo se são permitidos ou não 
@type function
@version  
@author Marcelo Alberto Lauschner
@since 27/05/2021
@param nPrcCombo, numeric, param_description
@param aItemCombo, array, param_description
@param nPrcTab, numeric, param_description
@param nDescMax, numeric, param_description
@return return_type, return_description
/*/
Static Function sfVldPrc(nPrcCombo,aItemCombo,nPrcTab,nDescMax)

	Local	lRet	:= .T.
	Local	iZ

	If nPrcCombo <   (Round(nPrcTab * (100-nDescMax)/100,2))
		lRet	:= .F.
	Else
		For iZ := 1 To Len(aItemCombo)
			If aItemCombo[iZ,10] == "1"
				aItemCombo[iZ,12] := Round(nPrcCombo * aItemCombo[iZ,13] / 100 /  aItemCombo[iZ,7],2)
			Endif
		Next
	Endif

Return lRet

/*/{Protheus.doc} sfNewCli
Rotina que cria um novo cliente na base 
@type function
@version  
@author Marcelo Alberto Lauschner
@since 27/05/2021
@return return_type, return_description
/*/
Static Function sfNewCli()


	Local	lRet		:= .F.
	Local	aCab		:= {}
	Local	xVarAux		:= ""
	Local 	cTpPessoa	:= "J"
	Local 	cLogErro	:= ""
	Local	cVarCodMun	:= ""
	Local 	nCount
	Local	cVarUf		:= ""
	Local 	iNN
	Local	aBillAddres	:=  sfGetVal (aVetCustomer,"#_OBJECT_#","billingAddress",)
	Local 	lLoop		:= .T.
	Local 	cProxNum := GETSX8NUM("SA1","A1_COD")

	// Força ajuste de códigos de clientes
	While lLoop
		If SA1->( DbSeek( xFilial("SA1")+cProxNum ) )
			ConfirmSX8()
			cProxNum:=GetSXeNum("SA1","A1_COD")
		Else
			RollbackSx8()
			lLoop	:= .F.
		Endif
	Enddo

	xVarAux		:= sfGetVal (aVetCustomer,"federalId","")
	If Len(Alltrim(xVarAux)) == 11 // Se for CPF
		cTpPessoa	:= "F"
	Endif

	aadd(aCab , {"A1_PESSOA"  	,cTpPessoa		,Nil})

	aAdd(aCab , {"A1_CGC"		,xVarAux		,Nil})


	// Preenche os dados baseado na Consulta Sefaz
	If sfReceita(xVarAux,@aCab) .And. cTpPessoa <> "F"

		// Se não adicionou o Nome Fantasia
		If  aScan(aCab,{|x| x[1] == "A1_NREDUZ"}) == 0
			xVarAux		:= Padr(sfGetVal (aVetCustomer,"name",""),TamSX3("A1_NREDUZ")[1])
			Aadd(aCab , {"A1_NREDUZ"	,xVarAux		,Nil})
		Endif

		If  aScan(aCab,{|x| x[1] == "A1_NOME"}) == 0
			xVarAux		:= Padr(sfGetVal (aVetCustomer,"corporateName",""),TamSX3("A1_NOME")[1])
			Aadd(aCab , {"A1_NOME"		,xVarAux		,Nil})
		Endif

		xVarAux		:= Padr(sfGetVal (aBillAddres,"state",""),TamSX3("A1_EST")[1])
		cVarUf		:= xVarAux
	Else

		xVarAux		:= Padr(sfGetVal (aVetCustomer,"corporateName",""),TamSX3("A1_NOME")[1])
		If Empty(xVarAux)
			xVarAux	:= Padr(sfGetVal (aVetCustomer,"name",""),TamSX3("A1_NOME")[1])
		Endif
		Aadd(aCab , {"A1_NOME"		,xVarAux		,Nil})


		xVarAux		:= Padr(sfGetVal (aVetCustomer,"name",""),TamSX3("A1_NREDUZ")[1])
		If Empty(xVarAux)
			xVarAux	:= Padr(sfGetVal (aVetCustomer,"corporateName",""),TamSX3("A1_NREDUZ")[1])
		Endif
		Aadd(aCab , {"A1_NREDUZ"	,xVarAux		,Nil})

		xVarAux		:= Padr(sfGetVal (aBillAddres,"zip",""),TamSX3("A1_CEP")[1])
		If Empty(xVarAux)
			xVarAux	:= "89010000"
		Else
			xVarAux	:= StrTran(xVarAux,"-","")
		Endif
		Aadd(aCab , {"A1_CEP"		,xVarAux		,Nil})

		xVarAux		:= AllTrim(sfGetVal (aBillAddres,"street",""))
		xVarAux 	+= ", "
		xVarAux		+= sfGetVal (aBillAddres,"number","")

		xVarAux		:= Padr(xVarAux,TamSX3("A1_END")[1])
		Aadd(aCab , {"A1_END"		,xVarAux		,Nil})

		xVarAux		:= Padr(sfGetVal (aBillAddres,"complement",""),TamSX3("A1_COMPLEM")[1])
		aAdd(aCab , {"A1_COMPLEM"	,xVarAux		,Nil})

		xVarAux		:= Padr(sfGetVal (aBillAddres,"city",""),TamSX3("A1_MUN")[1])

		cVarMun		:= Upper(xVarAux)
		cVarMun		:= sfAjust(cVarMun,,.T.)
		Aadd(aCab , {"A1_MUN"		,xVarAux		,Nil})

		xVarAux		:= Padr(sfGetVal (aBillAddres,"district",""),TamSX3("A1_BAIRRO")[1])
		If Empty(xVarAux)
			xVarAux	:= "CASA DO VENDEDOR"
		Endif
		aAdd(aCab , {"A1_BAIRRO"	,xVarAux		,Nil})

		xVarAux		:= Padr(sfGetVal (aBillAddres,"state",""),TamSX3("A1_EST")[1])
		cVarUf		:= xVarAux
		Aadd(aCab , {"A1_EST"		,xVarAux		,Nil})


		//	MsgAlert(xFilial("CC2")+AllTrim(cVarMun),"dbSeek(xFilial(CC2)+AllTrim(cVarMun))")
		dbSelectArea("CC2")
		CC2->(dbSetOrder(2))
		If CC2->(dbSeek(xFilial("CC2")+AllTrim(cVarMun)))

			While CC2->(!Eof()) .And. xFilial("CC2") == CC2->CC2_FILIAL .AND. ;
					AllTrim(cVarMun) == AllTrim(CC2->CC2_MUN)

				If CC2->CC2_EST == cVarUf
					cVarCodMun := CC2->CC2_CODMUN
					Exit
				Endif

				CC2->(dbSkip())
			Enddo
		Else
			MsgAlert("não achou dbseek " + xFilial("CC2")+AllTrim(cVarMun) )
		Endif

		CC2->(dbSetOrder(1))

		If !Empty(cVarCodMun)
			aadd(aCab , {"A1_COD_MUN"	,cVarCodMun		, Nil })
		Endif

	Endif


	xVarAux		:= sfGetVal (aVetCustomer,"phone","")
	If xVarAux == Nil
		xVarAux	:= "99999999999"
	Endif

	xVarAux		:= StrTran(xVarAux,"(","")
	xVarAux		:= StrTran(xVarAux,")","")
	xVarAux		:= StrTran(xVarAux," ","")

	// Efetua limpeza para só considerar valores numéricos
	xAuxVar	:= ""
	For iNN := 1 To Len(xVarAux)
		If Substr(xVarAux,iNN,1) $ "0123456789"
			xAuxVar	+= Substr(xVarAux,iNN,1)
		Endif
	Next

	aAdd(aCab , {"A1_DDD"		,Substr(xAuxVar,1,2)		,Nil})

	Aadd(aCab , {"A1_TEL"		,Padr(Substr(xAuxVar,3),TamSx3("A1_TEL")[1])		,Nil})

	xVarAux		:= Padr(sfGetVal (aVetCustomer,"email",""),TamSX3("A1_EMAIL")[1])
	If Empty(xVarAux)
		xVarAux	:= "vendedor_nao_pegou_email_com_cliente@naotem.email.fk"
	Endif
	Aadd(aCab , {"A1_EMAIL"		,xVarAux			,Nil})

	xVarAux		:= Padr(sfGetVal (aVetSalesman,"idErp",""),TamSX3("A1_VEND")[1])
	If Empty(xVarAux) .Or. xVarAux == Nil
		xVarAux	:= "000100"
	Endif
	AAdd(aCab , {"A1_VEND"		,xVarAux			,Nil})

	// Obtém o nome do campo do código do vendedor específico por empresa
	If SA1->(FieldPos(U_MLFATG05(1))) > 0
		Aadd(aCab , {U_MLFATG05(1)  ,xVarAux 			,Nil})
	Endif

	// Sempre como Tipo Consumidor Final na Importação
	// 10/05/2023 - Desativada a atualização destes 2 campos, pois gatilhos no cadastro irão preencher os valores.
	//Aadd(aCab , {"A1_TIPO"      ,"F"			,Nil})
	//Aadd(aCab , {"A1_CONTRIB"	,"2"			,Nil })

	// Grava com ISENTO so para importação de Cadastro
	xVarAux		:= sfGetVal (aVetCustomer,"inscricaoEstadual","")
	If xVarAux == Nil
		xVarAux	:= "ISENTO"
	Else
		If !IE(xVarAux,cVarUf)
			xVarAux	:= "ISENTO"
		Endif
	Endif
	Aadd(aCab , {"A1_INSCR"		,xVarAux		,Nil })

	Aadd(aCab , {"A1_SATIV1"	,"999999"		,Nil })

	lMSErroAuto := .F.

	Begin Transaction


		MSExecAuto({|x,y|MATA030(x,y)},aCab,3)

		If lMSErroAuto
			MostraErro()
			aErroAuto := GetAutoGRLog()
			cLogErro	:= ""
			For nCount := 1 To Len(aErroAuto)
				cLogErro += StrTran(StrTran(aErroAuto[nCount], "<", ""), "-", "") + " "
				ConOut(cLogErro)
			Next nCount


			cAssunto 	:= "Importação Ajili - Empresa:" + cEmpAnt+"/" + cFilAnt + " " + Capital(SM0->M0_NOME)
			cMensagem	:= "Erro na inclusão de novo cliente via importação Ajili " + CRLF
			cMensagem 	+= cLogErro + CRLF
			cMensagem 	+= "Pedido: " + cValToChar(cNumPed) + CRLF
			cMensagem	+= "Usuário:  " + cUserName + "-" + UsrFullName(__cUserId) + CRLF
			cMensagem	+= "Data/Hora: " + Dtoc( Date() ) + " as " + Time() + CRLF

			U_WFGERAL(	"rafael@grupoforta.com.br;ml-servicos@outlook.com"/*cEmail*/,cAssunto/*cTitulo*/,cMensagem/*cTexto*/,"GETPVC"/*cRotina*/,/*cAnexo*/)
		Else
			lRet	:= .T.
		EndIf
	End Transaction
Return  lRet



/*/{Protheus.doc} sfReceita
//Faz a consulta do CNPJ no Webservice para ter retorno mais completo
@author Marcelo Alberto Lauschner
@since 11/07/2018
@version 1.0
@return ${return}, ${return_description}
@param cInCgc, characters, descricao
@param aInACab, array, descricao
@type function
/*/
Static Function sfReceita(cInCgc,aInACab)

	// Variável Caractere
	Local	cUrlRec		:=	'https://www.receitaws.com.br/v1/cnpj/' + cInCgc
	Local	cJsonRet	:=  HttpGet(cUrlRec)
	Local	cQry
	Local	cVarAux
	// Variável Objeto
	Private oParseJSON 	:= Nil

	FWJsonDeserialize(cJsonRet, @oParseJSON)

	If Type("oParseJSON:situacao") <> "U"
		If oParseJSON:situacao <> "ATIVA"
			Return .F.
		Endif
	Endif

	If Type("oParseJSON:status") <> "U"
		If oParseJSON:status <> "OK"
			Return .F.
		Endif

	Endif


	If Type("oParseJSON:nome") <> "U" .And. !Empty(oParseJSON:nome)
		Aadd(aInACab,{"A1_NOME",Padr(NoAcento(Upper(oParseJSON:nome)),TamSX3("A1_NOME")[1]) , Nil} )
	Else
		Return .F.
	Endif

	If Type("oParseJSON:fantasia") <> "U" .And. !Empty(oParseJSON:fantasia)
		Aadd(aInACab,{"A1_NREDUZ",Padr(NoAcento(Upper(oParseJSON:fantasia)),TamSX3("A1_NREDUZ")[1]),Nil})
	Endif


	If Type("oParseJSON:cep") <> "U"
		Aadd(aInACab,{"A1_CEP",Padr(StrTran(StrTran(oParseJSON:cep,".",""),"-",""),TamSX3("A1_CEP")[1]),Nil})
	Endif


	If Type("oParseJSON:abertura") <> "U"
		Aadd(aInACab,{"A1_DTNASC", CTOD(oParseJSON:abertura),Nil})
	Endif

	If Type("oParseJSON:logradouro") <> "U"
		cVarAux		:= Padr(NoAcento(Upper(oParseJSON:logradouro)),TamSX3("A1_END")[1])
		If Type("oParseJSON:numero") <> "U"
			cVarAux	:= Padr(cVarAux + "," + NoAcento(Upper(oParseJSON:numero)),TamSX3("A1_END")[1])
		Endif
		Aadd(aInACab,{"A1_END",cVarAux,Nil})
	Endif


	If Type("oParseJSON:bairro") <> "U"
		Aadd(aInACab,{"A1_BAIRRO",Padr(NoAcento(Upper(oParseJSON:bairro)),TamSX3("A1_BAIRRO")[1]),Nil})
	Endif

	If Type("oParseJSON:complemento") <> "U"
		Aadd(aInACab,{"A1_COMPLEM",Padr(NoAcento(Upper(oParseJSON:complemento)),TamSX3("A1_COMPLEM")[1]),Nil})
	Endif

	If Type("oParseJSON:municipio") <> "U"
		Aadd(aInACab,{"A1_MUN", Padr(NoAcento(Upper(oParseJSON:municipio)),TamSX3("A1_MUN")[1]),Nil})
	Endif

	If Type("oParseJSON:uf") <> "U"
		Aadd(aInACab,{"A1_EST",Padr(NoAcento(Upper(oParseJSON:uf)),TamSX3("A1_EST")[1]),Nil})
	Else
		MsgAlert("Não encontrou informação de Estado ( UF ) ao consultar a URL "+cUrlRec )
		Return .F.
	Endif

	If Type("oParseJSON:uf") <> "U"  .And. Type("oParseJSON:municipio") <> "U"
		cQry := "SELECT CC2_CODMUN "
		cQry += "  FROM " + RetSqlName("CC2")
		cQry += " WHERE D_E_L_E_T_ =' ' "
		cQry += "   AND CC2_EST = '"+oParseJSON:uf+"' "
		//cQry += "   AND CC2_MUN LIKE '%"+ oParseJSON:municipio + "%' "
		cQry += "   AND CC2_MUN = '"+ StrTran(NoAcento(Upper(oParseJSON:municipio)),"'","''")+ "' "
		cQry += "   AND CC2_FILIAL = '"+xFilial("CC2") + "' "

		dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),"TBLEXIST",.T.,.T.)
		If TBLEXIST->(!Eof())
			Aadd(aInACab,{"A1_COD_MUN", TBLEXIST->CC2_CODMUN,Nil})
		Else
			TBLEXIST->(DbCloseArea())
			MsgAlert("Não encontrou informação de Código Municipio ao consultar a query  "+cQry )
			Return .F.
		Endif
		TBLEXIST->(DbCloseArea())
	Endif

Return .T.

Static Function fFim(nPosInicial)

	Local _k         := 0
	Local nQtdeLetra := 0

	For _k := nPosInicial to Len(cRetorno)

		If Substr(cRetorno,_k,1)==","
			nQtdeLetra := _k -  nPosInicial
			Exit
		EndIf

	Next _k

Return nQtdeLetra


Static Function fAtualiza(aAtualiza,cNumSC5,lIsOrc)


	Local 	_cRet    		:= ""
	Local 	cHGet    		:= ""
	Local 	cURL		    := Alltrim(GetNewPar("GF_AJ_URL",""))
	Local 	cAcesso2        := "/api/pedidos/update-id-erp?"
	Local	cApiKey			:= "api_key=" + Alltrim(GetNewPar("GF_AJ_KEY",""))
	Local	aHeader			:= {}
	Local 	cJsonERP 		:= ""

	aadd(aHeader,'Content-Type: application/json')
	Aadd(aHeader, "Accept: application/json")

	cJsonERP := sfMontaJson(aAtualiza,cNumSC5,lIsOrc)
	If Empty(cJsonERP)
		MsgAlert("Não houve montagem de dados para retornar o status do pedido '" + cNumSC5 + "' ao Ajili." )
		Return
	Endif

	_cRet := HttpPost( cURL+cAcesso2+cApiKey,"",encodeUTF8(cJsonERP),200,aHeader,@cHGet)
	Conout("***[RESTERP]***********************************************************************************************")

	Conout(_cRet)

	ConOut("***[RESTERP]*["+_cRet+"]***********************************************************************************************************")

	Conout(cHGet)

	_cStatus := Substr(cHGet,10,3)

	If _cStatus  <> "200"

		If _cStatus  <> "301"
			MsgAlert(_cRet,"Erro retorno Rest")
		Endif

		cAssunto 	:= "Importação Ajili - Empresa:" + cEmpAnt+"/" + cFilAnt + " " + Capital(SM0->M0_NOME)
		cMensagem	:= "Erro na atualização de dados Ajili " + CRLF
		cMensagem 	+= "URL envio:" + cURL+cAcesso2+cApiKey + CRLF
		cMensagem 	+= "Json envio: " + cJsonERP + CRLF
		cMensagem 	+= "Retorno: " + _cRet + CRLF
		cMensagem 	+= "Pedido: " + cValToChar(cNumPed) + CRLF
		cMensagem	+= "Usuário:  " + cUserName + "-" + UsrFullName(__cUserId) + CRLF
		cMensagem	+= "Data/Hora: " + Dtoc( Date() ) + " as " + Time() + CRLF

		U_WFGERAL(	"rafael@grupoforta.com.br;ml-servicos@outlook.com"/*cEmail*/,cAssunto/*cTitulo*/,cMensagem/*cTexto*/,"GETPVC"/*cRotina*/,/*cAnexo*/)

	Endif

	Conout("Status da Inclusao: "+_cStatus)

	Conout("***[RESTERP]**********************************************************************************************")

	If _cStatus == "200"
		Conout("***[RESTERP]*[Cadastrado com Sucesso!]*****************************************************************")

		If lIsOrc
			Begin Transaction
				DbSelectArea("Z00")
				DbSetOrder(1)//Z00_FILIAL+Z00_ENTIDA+Z00_CHAVE
				If DbSeek(xFilial("Z00") + "SUA" + SUA->(UA_FILIAL+UA_NUM))
					//nIdAjili		:= Z00->Z00_IDAJIL
					RecLock("Z00",.F.)
				Else
					RecLock("Z00",.T.)

				Endif
				Z00->Z00_FILIAL 	:= xFilial("Z00")	//- Filial
				Z00->Z00_ENTIDA 	:= "SUA"			//- Entidade
				Z00->Z00_NCHAVE 	:= 1				//- Indice da Entidade
				Z00->Z00_CHAVE  	:= SUA->(UA_FILIAL+UA_NUM)	//- Chave de pesquisa/relação
				Z00->Z00_INTEGR 	:= "X"				//- Status Integração
				Z00->Z00_IDAJIL 	:= SUA->UA_IDAJILI	//- Id de Integração Ajili
				MsUnlock()
			End Transaction
		Else
			Begin Transaction
				DbSelectArea("Z00")
				DbSetOrder(1)//Z00_FILIAL+Z00_ENTIDA+Z00_CHAVE
				If DbSeek(xFilial("Z00") + "SC5" + SC5->(C5_FILIAL+C5_NUM))
					//nIdAjili		:= Z00->Z00_IDAJIL
					RecLock("Z00",.F.)
				Else
					RecLock("Z00",.T.)

				Endif
				Z00->Z00_FILIAL 	:= xFilial("Z00")	//- Filial
				Z00->Z00_ENTIDA 	:= "SC5"			//- Entidade
				Z00->Z00_NCHAVE 	:= 1				//- Indice da Entidade
				Z00->Z00_CHAVE  	:= SC5->(C5_FILIAL+C5_NUM)	//- Chave de pesquisa/relação
				Z00->Z00_INTEGR 	:= "X"				//- Status Integração
				Z00->Z00_IDAJIL 	:= SC5->C5_IDAJILI	//- Id de Integração Ajili
				MsUnlock()
			End Transaction
		Endif

	EndIf
	Conout("***[RESTERP]**********************************************************************************************")

return nil


Static Function sfMontaJson(aAtualiza,cNumSC5,lIsOrc )


	Local 	cJsonERP		:= ""
	Local 	nIdSc6			:= 0
	Default lIsOrc			:= .F.

	Conout("***[RESTERP]*[Entrou na Rotina de Monta Json]*******************************************************************")

	If !lIsOrc

		dbSelectArea("SC5")
		dbSetOrder(1)
		If dbSeek(xFilial("SC5")+cNumSC5)


			cJsonERP := '['
			cJsonERP += '{'
			cJsonERP += '"id": '+cValToChar(cNumPed)+','
			cJsonERP += '"idErp": "'+cNumSC5+'",'
			cJsonERP += '"items": ['

			dbSelectArea("SC6")
			dbSetOrder(1)
			dbSeek(xFilial("SC6")+SC5->C5_NUM,.F.)


			While !Eof() .And. SC6->C6_FILIAL==xFilial("SC6") .and. SC6->C6_NUM==SC5->C5_NUM

				If nIdSc6 <> SC6->C6_IDAJILI

					cJsonERP += '{'
					cJsonERP += '"id": '+cValToChar(SC6->C6_IDAJILI)+','
					cJsonERP += '"idErp": "'+SC6->(C6_NUM+C6_ITEM)+'"'
					cJsonERP += '},'

					Begin Transaction
						DbSelectArea("Z00")
						DbSetOrder(1)//Z00_FILIAL+Z00_ENTIDA+Z00_CHAVE
						If DbSeek(xFilial("Z00") + "SC6" + SC6->(C6_FILIAL+C6_NUM+C6_ITEM))
							//nIdAjili		:= Z00->Z00_IDAJIL
							RecLock("Z00",.F.)
						Else
							RecLock("Z00",.T.)

						Endif
						Z00->Z00_FILIAL 	:= xFilial("Z00")	//- Filial
						Z00->Z00_ENTIDA 	:= "SC6"			//- Entidade
						Z00->Z00_NCHAVE 	:= 1				//- Indice da Entidade
						Z00->Z00_CHAVE  	:= SC6->(C6_FILIAL+C6_NUM+C6_ITEM)	//- Chave de pesquisa/relação
						Z00->Z00_INTEGR 	:= "X"				//- Status Integração
						Z00->Z00_IDAJIL 	:= SC6->C6_IDAJILI 		//- Id de Integração Ajili

						MsUnlock()

					End Transaction
				Endif
				nIdSc6	:= SC6->C6_IDAJILI

				DbSelectArea("SC6")
				dbSkip()
			Enddo

			cJsonERP := Left(cJsonERP,Len(cJsonERP)-1)
			cJsonERP += ']'
			cJsonERP += '}'
			cJsonERP += ']'

		Else
			cJsonERP := '['
			cJsonERP += '{'
			cJsonERP += '"id": '+cValToChar(cNumPed)+','
			cJsonERP += '"idErp": "'+cNumSC5+'" '
			cJsonERP += '}]'

		Endif

	Else

		dbSelectArea("SUA")
		dbSetOrder(1)
		If dbSeek(xFilial("SUA")+cNumSC5)


			cJsonERP := '['
			cJsonERP += '{'
			cJsonERP += '"id": '+cValToChar(cNumPed)+','
			cJsonERP += '"idErp": "'+cNumSC5+'",'
			cJsonERP += '"items": ['

			dbSelectArea("SUB")
			dbSetOrder(1)
			dbSeek(xFilial("SUB")+SUA->UA_NUM,.F.)


			While !Eof() .And. SUB->UB_FILIAL==xFilial("SUB") .and. SUB->UB_NUM==SUA->UA_NUM

				If nIdSc6 <> SUB->UB_IDAJILI

					cJsonERP += '{'
					cJsonERP += '"id": '+cValToChar(SUB->UB_IDAJILI)+','
					cJsonERP += '"idErp": "'+SUB->(UB_NUM+UB_ITEM)+'"'
					cJsonERP += '},'

					Begin Transaction
						DbSelectArea("Z00")
						DbSetOrder(1)//Z00_FILIAL+Z00_ENTIDA+Z00_CHAVE
						If DbSeek(xFilial("Z00") + "SUB" + SUB->(UB_FILIAL+UB_NUM+UB_ITEM))
							//nIdAjili		:= Z00->Z00_IDAJIL
							RecLock("Z00",.F.)
						Else
							RecLock("Z00",.T.)

						Endif
						Z00->Z00_FILIAL 	:= xFilial("Z00")	//- Filial
						Z00->Z00_ENTIDA 	:= "SUB"			//- Entidade
						Z00->Z00_NCHAVE 	:= 1				//- Indice da Entidade
						Z00->Z00_CHAVE  	:= SUB->(UB_FILIAL+UB_NUM+UB_ITEM)	//- Chave de pesquisa/relação
						Z00->Z00_INTEGR 	:= "X"				//- Status Integração
						Z00->Z00_IDAJIL 	:= SUB->UB_IDAJILI 		//- Id de Integração Ajili

						MsUnlock()

					End Transaction
				Endif
				nIdSc6	:= SUB->UB_IDAJILI

				DbSelectArea("SUB")
				dbSkip()
			Enddo

			cJsonERP := Left(cJsonERP,Len(cJsonERP)-1)
			cJsonERP += ']'
			cJsonERP += '}'
			cJsonERP += ']'

		Else
			cJsonERP := '['
			cJsonERP += '{'
			cJsonERP += '"id": '+cValToChar(cNumPed)+','
			cJsonERP += '"idErp": "'+cNumSC5+'" '
			cJsonERP += '}]'

		Endif
	Endif
	ConOut(cJsonERP)
	Conout("***[RESTERP]*[Montou o Json do ERP]***********************************************************************")

Return cJsonERP


Static Function sfAjust(cInChar,lOutJson,lUpper)

	Local	cOut		:= cInChar
	Local	aOut		:= {}
	Local	nO
	Default lOutJson	:= .F.
	Default	lUpper		:= .F.

	Aadd(aOut,{"á","\u00e1","a"})
	Aadd(aOut,{"à","\u00e0","a"})
	Aadd(aOut,{"â","\u00e2","a"})
	Aadd(aOut,{"ã","\u00e3","a"})
	Aadd(aOut,{"ä","\u00e4","a"})
	Aadd(aOut,{"Á","\u00c1","a"})
	Aadd(aOut,{"À","\u00c0","a"})
	Aadd(aOut,{"Â","\u00c2","a"})
	Aadd(aOut,{"Ã","\u00c3","a"})
	Aadd(aOut,{"Ä","\u00c4","a"})
	Aadd(aOut,{"é","\u00e9","e"})
	Aadd(aOut,{"è","\u00e8","e"})
	Aadd(aOut,{"ê","\u00ea","e"})
	Aadd(aOut,{"ê","\u00ea","e"})
	Aadd(aOut,{"É","\u00c9","e"})
	Aadd(aOut,{"È","\u00c8","e"})
	Aadd(aOut,{"Ê","\u00ca","e"})
	Aadd(aOut,{"Ë","\u00cb","e"})
	Aadd(aOut,{"í","\u00ed","i"})
	Aadd(aOut,{"ì","\u00ec","i"})
	Aadd(aOut,{"î","\u00ee","i"})
	Aadd(aOut,{"ï","\u00ef","i"})
	Aadd(aOut,{"Í","\u00cd","i"})
	Aadd(aOut,{"Ì","\u00cc","i"})
	Aadd(aOut,{"Î","\u00ce","i"})
	Aadd(aOut,{"Ï","\u00cf","i"})
	Aadd(aOut,{"ó","\u00f3","o"})
	Aadd(aOut,{"ò","\u00f2","o"})
	Aadd(aOut,{"ô","\u00f4","o"})
	Aadd(aOut,{"õ","\u00f5","o"})
	Aadd(aOut,{"ö","\u00f6","o"})
	Aadd(aOut,{"Ó","\u00d3","o"})
	Aadd(aOut,{"Ò","\u00d2","o"})
	Aadd(aOut,{"Ô","\u00d4","o"})
	Aadd(aOut,{"Õ","\u00d5","o"})
	Aadd(aOut,{"Ö","\u00d6","o"})
	Aadd(aOut,{"ú","\u00fa","u"})
	Aadd(aOut,{"ù","\u00f9","u"})
	Aadd(aOut,{"û","\u00fb","u"})
	Aadd(aOut,{"ü","\u00fc","u"})
	Aadd(aOut,{"Ú","\u00da","u"})
	Aadd(aOut,{"Ù","\u00d9","u"})
	Aadd(aOut,{"Û","\u00db","u"})
	Aadd(aOut,{"ç","\u00e7","c"})
	Aadd(aOut,{"Ç","\u00c7","c"})
	Aadd(aOut,{"ñ","\u00f1","n"})
	Aadd(aOut,{"Ñ","\u00d1","n"})
	Aadd(aOut,{"®","\u00d1","r"})
	Aadd(aOut,{"°","\u00d1"," "})
	Aadd(aOut,{"ª","\u00d1"," "})
	Aadd(aOut,{Chr(186),"\u00d1"," "})
	Aadd(aOut,{"´","\u00b4"," "})
	Aadd(aOut,{Chr(13),"\u0013"," "})
	Aadd(aOut,{Chr(10),"\u0010"," "})
	Aadd(aOut,{"/","\u0010","-"})

	Aadd(aOut,{"&","\u0026"," ","&amp;"})
	Aadd(aOut,{"<","\u0010"," ","&lt;"})
	Aadd(aOut,{">","\u0010"," ","&gt;"})
	Aadd(aOut,{'"',"\u0010"," ","&quot;"})
	Aadd(aOut,{"'","\u0027"," ","&#39;"})
	Aadd(aOut,{"Ø","\u00d8"," "," "})
	Aadd(aOut,{"½","\u00d8"," "," "})

	//ConOut("+------------------------------------+")
	//ConOut(cOut)
	If lOutJson
		For nO := 1 To Len(aOut)
			cOut	:= StrTran(cOut,aOut[nO,1],aOut[nO,2])
		Next nO
	Else
		//cOut	:= DecodeUTF8(cOut)
		//ConOut(cOut)

		For nO := 1 To Len(aOut)
			cOut	:= StrTran(cOut,aOut[nO,1],aOut[nO,3])
		Next nO

		cOut	:= Alltrim(Upper(cOut))
	Endif
	If lUpper
		cOut	:= Upper(cOut)
	Endif
	cOut	:= StrTran(cOut,"PALHOC6","PALHOCA")
	//ConOut(cInChar)
	//ConOut(cOut)
	//ConOut("+++------------------------------------+")

Return cOut
/*[ {
"order" : {
"id" : 2,
"idErp" : null,
"codeErp" : null,
"customerId" : 2297,
"contactId" : null,
"salesmanId" : 478,
"creationTime" : "2019-11-20 14:49",
"sendTime" : "2019-11-20 14:49",
"approvalStatus" : 102,
"shippingStatus" : 201,
"billingStatus" : 301,
"value" : 65.88555,
"valueWithoutDiscount" : 66.35,
"percentDiscount" : 0.007,
"valueDiscount" : 0.0,
"paymentTermsId" : 58,
"paymentFormsId" : 7,
"notes" : null,
"broken" : null,
"frete" : null,
"invoiceId" : null,
"pricingTableId" : 6,
"palletized" : false,
"shipmentAddressId" : null,
"comissionValue" : null,
"totalWeight" : null,
"customer" : {
"id" : 2297,
"idErp" : "00000203",
"status" : 2,
"federalId" : "00143758000340",
"name" : "DVA AUTOMOVEIS FLORIANOPOLIS (Cód/Lj:000002/03)",
"corporateName" : "D V A AUTOMOVEIS LTDA                                       ",
"billingAddressId" : 2277,
"shippingAddressId" : 2277,
"phone" : "33325500       ",
"fax" : "               ",
"email" : "PECAS.AUTOMOVEIS@GRUPODVA.COM.                              ",
"creditLimit" : 12500.0,
"notes" : "",
"customerCategoryId" : null,
"createdBy" : null,
"creationTime" : null,
"pipelineId" : null,
"pipelineRemoved" : null,
"blocked" : null,
"inscricaoEstadual" : null,
"pricingTableId" : null,
"rg" : null,
"filiation" : null,
"birthDate" : null,
"defaultPaymentTermsId" : 58,
"defaultPaymentFormsId" : 7,
"lastVisitTime" : null,
"lastSalesOrderTime" : null,
"billingAddress" : {
"id" : 2277,
"idErp" : null,
"street" : "RUA PASCHOAL APOSTOLO PITSICA, 4900",
"number" : "",
"complement" : "                                                  ",
"district" : "AGRONOMICA                              ",
"city" : "FLORIANOPOLIS                                               ",
"state" : "SC",
"country" : "105",
"zip" : "88025-255"
},
"shippingAddress" : {
"id" : 2277,
"idErp" : null,
"street" : "RUA PASCHOAL APOSTOLO PITSICA, 4900",
"number" : "",
"complement" : "                                                  ",
"district" : "AGRONOMICA                              ",
"city" : "FLORIANOPOLIS                                               ",
"state" : "SC",
"country" : "105",
"zip" : "88025-255"
},
"pricingTable" : null,
"customerCategory" : null
},
"contact" : null,
"salesman" : {
"id" : 478,
"idErp" : null,
"email" : "rafael@grupoforta.com.br",
"name" : "01 - Rafael Meyer",
"phone" : "(47) 98844-4820",
"balanceFlex" : null,
"superiorId" : null,
"role" : 2,
"active" : true,
"addressId" : null,
"bankNumber" : null,
"bankAgency" : null,
"bankAccount" : null,
"salesComissionPct" : null,
"salaryCosts" : null
},
"paymentTerms" : {
"id" : 58,
"idErp" : "135",
"name" : "135-35 DIAS        ",
"description" : "135-35 DIAS        ",
"active" : null,
"discount" : null,
"rules" : ""
},
"paymentForms" : {
"id" : 7,
"idErp" : null,
"name" : "Boleto",
"description" : "Boleto",
"active" : null
},
"pricingTable" : {
"id" : 6,
"idErp" : null,
"enabled" : null,
"name" : "TABELA 101                    ",
"description" : null,
"discount" : null,
"maxDiscount" : null,
"email" : null
}
},
"items" : [ {
"id" : 3,
"idErp" : null,
"salesOrderId" : 2,
"productId" : 845,
"quantity" : 1.0,
"unitValue" : 66.35,
"unitValueWithoutDiscount" : 66.35,
"notes" : null,
"unitCost" : 34.14,
"comissionValue" : null,
"comissionPctValue" : null,
"unitWeight" : null,
"product" : {
"id" : 845,
"idErp" : "100112         ",
"code" : "100112         ",
"name" : "MOTUL HD 85W140 2L                                                              ",
"description" : "MOTUL HD 85W140 2L                                                              ",
"value" : 0.0,
"promotionalValue" : null,
"minimumValue" : null,
"url" : null,
"presentation" : "PC",
"active" : true,
"barcode" : null,
"icmsPercent" : null,
"icmsReductionPercent" : null,
"ipiPercent" : null,
"weight" : null,
"campaignId" : null,
"cfopId" : null,
"lotId" : null,
"cstId" : null,
"classificacaoFiscalId" : null,
"stockGrid1Id" : null,
"stockGrid2Id" : null,
"stockTotal" : 1.0,
"stockAverageCost" : 34.14,
"perishable" : false,
"markupMinimum" : null
},
"grids" : null,
"batches" : null,
"code" : "100112         "
} ]
} ]

"freightCarrier": {
"id": null,
"idErp": null,
"active": null,
"federalId": "String",
"name": "JMI",
"corporateName": "String",
"email": "String",
"phones": "String",
"source": null
}

*/
