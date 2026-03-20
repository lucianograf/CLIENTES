#include 'protheus.ch'
#include 'restful.ch'
#include 'apwebex.ch'
#include 'parmtype.ch'

/*---------------------------------------------------------------------------+
|                             FICHA TÉCNICA DO PROGRAMA                      |
+----------------------------------------------------------------------------+
|   DADOS DO PROGRAMA                                                        |
+------------------+---------------------------------------------------------+
| Tipo             | WEBSERVICE                                   			 |
+------------------+---------------------------------------------------------+
| Módulo           | Configurador                                            |
+------------------+---------------------------------------------------------+
| Descrição        | Webservice para recebimentos de requisições via email,  |
|				   | para realizar analise de documentos - Track-IT 27622.   |
+*-----------------+---------------------------------------------------------+
| Nome             | WSDECAT009                                              |
+*-----------------+---------------------------------------------------------+
| Parâmetros       |														 |
+------------------+---------------------------------------------------------+
| Data de Criação  | 09/11/2017                                              |
+------------------+---------------------------------------------------------+
| Autor            | Thiago Henrique dos Santos                              |
+------------------+--------------------------------------------------------*/
WSRESTFUL WSDECAT009 DESCRIPTION "Analise de Documentos"

WSMETHOD GET 	DESCRIPTION "Analise de Documentos" WSSYNTAX "/WSDECAT009/{cChaveDoc}"
WSMETHOD POST 	DESCRIPTION "Analise de Documentos"	WSSYNTAX "/WSDECAT009/{aParam}"

END WSRESTFUL

//+-------------------------------------------------------------------+
//| Método GET                                      		   	      |
//+-------------------------------------------------------------------+ 
WSMETHOD GET WSSERVICE WSDECAT009

	Local lPost 	:= .T.
	Local cFunc		:= ""
	Local cHtml		:= ""
	Local cKey	 	:= ""
	Local cKeyEmp	:= ""
	Local cKeyFil	:= ""
	Local cKeyTip	:= ""
	Local cKeyChvPro:= ""
	Local cColor    := ""

	/*/ A chave recebida via GET, deve seguir um padrão, sendo que as 6 primeiras posições devem conter as informações de Empresa, Filial e Tipo do Processo:
	E = Empresa
	F = Filial
	T = Tipo Processo - A função que será executada para cada Tipo de processo, está na tabela ZE, a chave da TABELA X5_CHAVE é este Tipo de Processo, 
	o programa que será executado, estará gravado no campo X5_DESCRI 

	O restante da chave será de definição de cada processo, sendo da posição 7 até o final
	chave EEFFTTPPPPP....nP
	/*/	

	::SetContentType('text/html')

	If Len(::aURLParms) == 0
		SetRestFault(400, "Informe o parâmetro cChavDoc")
		lPost := .F.
	Else
		cKey := EMBARALHA(::aURLParms[1],0)

		If Len(cKey) < 6
			SetRestFault(400, "Parâmetro cChavDoc inválido!")
			lPost := .F.
		Else

			// Explode a chave recebida via GET 
			// chave EEUUFFTTPPPPPPPPPP......nP
			// E = Empresa
			// F = Filial
			// T = Tipo Processo (PC=Pedido de Compras)
			cKeyEmp	   := SubStr(cKey,1,2)
			cKeyFil	   := SubStr(cKey,3,4)
			cKeyTip	   := SubStr(cKey,7,2)
			If Len(cKey) >= 7
				cKeyChvPro := SubStr(cKey, 9, Len(cKey))
			EndIf

			// Prepara o ambiente na Empresa e Filial informada 
			WFPrepEnv(cKeyEmp,cKeyFil)
		
			// A rotina a ser executada para cada processo está na tabela genérica ZE
		    DBSelectArea("SX5")
			SX5->(DBSetOrder(1))
			SX5->(DBGoTop())
			If SX5->(DBSeek(xFilial("SX5") + "ZE" + UPPER(cKeyTip)))

				// Monta a chamada da função
				cFunc := AllTrim(SX5->X5_DESCRI)+"('" + cKeyChvPro +  "', ,'"  + cKeyTip + "')"

				// Executa a função do processo informado
				cHtml := &cFunc

			Else
				cColor := "#e54343"
				cHtml := u_HtmlRet("Função não encontrada na tabela [ZE] para o tipo: " + UPPER(cKeyTip), cColor )
			EndIf	 			

			// Encerra o ambiente
			RPCClearEnv()

			// Retorna a resposta para o Browser
			::SetResponse(cHtml)

		EndIf

	EndIf

Return lPost

//+-------------------------------------------------------------------+
//| Método POST                                      		   	      |
//+-------------------------------------------------------------------+ 
WSMETHOD POST WSSERVICE WSDECAT009

	Local lPost 	:= .T.
	Local cFunc		:= ""
	Local cHtml		:= ""   
	Local cKey	 	:= ""
	Local cKeyEmp	:= ""
	Local cKeyFil	:= ""
	Local cKeyTip	:= ""
	Local cKeyChvPro:= ""
	Local cKeyTexto	:= ""
	Local cJSON 	:= Self:GetContent() // --> Pega a string recebida via POST
	Local oParseJSON:= Nil 
	Local aParForm	:= {}
	Local nPosEmp	:= 0
	Local nPosFil	:= 0
	Local nPosTipo	:= 0
	Local nPosChvPro:= 0
	Local nPosObs	:= 0
	Local cColor    := ""
	conout(cJSON)
	::SetContentType("text/html")

	// Ajuste do texto recebido do post
	cJSON := STRTRAN(cJSON,'%22','"',1)

	// Transorma o resultado do post em um objeto no formato JSon
	If !FWJsonDeserialize(cJSON, @oParseJSON)
		SetRestFault(400, "Erro no processamento do JSon")
		lPost := .F.		
	EndIf

	If lPost

		// Captura as variáveis do JSon
		aParForm 	:= ClassDataArr(oParseJSON)
		nPosEmp		:= aScan(aParForm, {|x| AllTrim(x[1]) == UPPER("keyEmpresa")})
		nPosFil		:= aScan(aParForm, {|x| AllTrim(x[1]) == UPPER("keyFilial") }) 
		nPosTipo	:= aScan(aParForm, {|x| AllTrim(x[1]) == UPPER("keyTipo") 	})
		nPosChvPro	:= aScan(aParForm, {|x| AllTrim(x[1]) == UPPER("keyChvPro") })
		nPosObs		:= aScan(aParForm, {|x| AllTrim(x[1]) == UPPER("keyTexto") 	})

		// Valida se todas as variáveis necessárias foram encontradas
		If nPosEmp = 0;
		.OR. nPosFil 	= 0;
		.OR. nPosTipo 	= 0;
		.OR. nPosChvPro = 0;
		.OR. nPosObs 	= 0

			SetRestFault(400, "Erro nos parâmetros do formulário HTML")
			lPost := .F.

		EndIf

		// Captura o conteúdo das variáveis 
		cKeyEmp	   := aParForm[nPosEmp][2]
		cKeyFil	   := aParForm[nPosFil][2]
		cKeyTip	   := aParForm[nPosTipo][2]
		cKeyChvPro := aParForm[nPosChvPro][2]
		cKeyTexto  := aParForm[nPosObs][2]

	EndIf

	If lPost

		// Prepara o ambiente na Empresa e Filial informada 
		WFPrepEnv(cKeyEmp,cKeyFil)

		// A rotina a ser executada para cada processo está na tabela genérica ZE
		dbSelectArea("SX5")
		SX5->(dbSetOrder(1))
		SX5->(dbGoTop())
		If SX5->(dbSeek(xFilial("SX5")+"ZE"+UPPER(cKeyTip)))

			// Monta a chamada da função
			cFunc := AllTrim(SX5->X5_DESCRI)+"('" + cKeyChvPro + "','" + cKeyTexto + "','"  + cKeyTip + "')"

			// Executa a função do processo informado
			cHtml := &cFunc

		Else
			cColor := "#e54343"
			cHtml := u_HtmlRet("Função não encontrada na tabela [ZE] para o tipo: " + UPPER(cKeyTip), cColor )
		EndIf	

		// Encerra o ambiente
		RPCClearEnv()

		// Retorna a resposta para o Browser
		::SetResponse(cHtml)

	EndIf

Return lPost  

//+-------------------------------------------------------------------+
//| Função para montagem de HTML de retorno do WS			   	      |
//+-------------------------------------------------------------------+
User Function HtmlRet(cAMsg, cColor)

	Local cHtml := ""
	cHtml += "	<html> "
	cHtml += "		<head> <meta http-equiv='Content-Type' content='text/html; charset=iso-8859-1'> </head> "
	cHtml += "		<title>"+EncodeUTF8("Atenção!", "cp1252")+"</title> "
	cHtml += "		<body style='width: 1024px;margin-left: auto;margin-right: auto;background-color:#dfdddd; font-family: Trebuchet MS;'> "
	cHtml += " 		<div style='margin-bottom: 20px; text-align: center;'>  "
	cHtml += "			<img style='float: left;margin-right: 20px;' src='https://decantervinhos.vtexassets.com/assets/vtex/assets-builder/decantervinhos.decanter-store/2.12.31/brand/logo-redesign___2f77b3463e12e33df9e96ecda8dcadaf.svg' alt='logo_decanter'>"
	cHtml += " 			<h2 style='font-size:26px;text-align: right;'>DECANTER VINHOS FINOS LTDA</h2>"
	cHtml += "		</div>"
	cHtml += " 		<div style='font-family:inherit;font-size:1rem;padding:20px 20px;margin-bottom:10px;background-color: "+ cColor +";border-radius:5px'>"
	cHtml += " 			<H1>"+ EncodeUTF8(cAMsg) +"</H1>"
	cHtml += " 		</div> "
	cHtml += "		</body> "
	cHtml += "	</html> "

Return cHtml
