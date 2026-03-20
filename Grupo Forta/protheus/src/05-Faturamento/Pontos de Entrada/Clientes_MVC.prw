#include "protheus.ch"
#Include "FWMVCDef.ch"

//-------------------------------------------------------------------
/*/{Protheus.doc} CRMA980

Pontos de entrada de clientes migrado para a versão MVC.

@author  Rafael Pianezzer de Souza
@since   03/02/22
@version version
/*/
//-------------------------------------------------------------------
User Function CRMA980()

	Local aParam            := PARAMIXB
	Local xRet              := .T.
	Local oObj              := ""
	Local cIdPonto          := ""
	Local cIdModel          := ""
	Local lIsGrid           := .F.
	Local aArea 			:= GetArea() 
	
	If aParam <> NIL


		oObj := aParam[1]
		cIdPonto := aParam[2]
		cIdModel := aParam[3]
		lIsGrid := (Len(aParam) > 3)

		If cIdPonto == "MODELPOS"
		ElseIf cIdPonto == "MODELVLDACTIVE"
		ElseIf cIdPonto == "FORMPOS"
			
			nOper 		:= oObj:GetOperation()
			If Type("ALTERA") <> "L"
				Private	ALTERA	:= nOper == MODEL_OPERATION_UPDATE
			Endif
			
			If Type("INCLUI") <> "L"
				Private	INCLUI	:= nOper == MODEL_OPERATION_INSERT
			Endif
			
			/* ==========================================   TROCA DE FUNÇÃO MA030TOK ========================================== */

			// 11/12/2024 - Validação de cadastro com bloqueio para alertar ao usuário para fazer o desbloqueio e continuar 
			If Alltrim(cIdModel) == "SA1MASTER"

				If (!ALTERA .And. !INCLUI ) .Or. FwIsInCallStack("U_GetPvc")
					RestArea(aArea)
					Return .T.
				Endif

				oField := oObj:GetModel("SA1MASTER")
				
				// Se o cliente estiver bloqueado e o usuário estiver na lista de usuários com permissão 
				If oField:GetValue("SA1MASTER","A1_MSBLQL")  == "1" .And. RetCodUsr() $ (GetNewPar("GF_M440VL2","000002#000139#000081") +GetNewPar("GF_M440VL1","000002#000139#000081"))
					// Só se o cliente já estiver bloqueado 
					If ALTERA .And. SA1->A1_MSBLQL == "1"
						MsgAlert("O cadastro do cliente está Status = 2-Inativo. Desbloqueie o cliente para efetivar alterações!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
						RestArea(aArea)
						Return .F.
					Endif 
				Endif

				U_MA030TOK() 
			Endif

		ElseIf cIdPonto == "FORMLINEPRE"

		ElseIf cIdPonto == "FORMLINEPOS"

		ElseIf cIdPonto == "MODELCOMMITTTS"


				/* ==========================================   TROCA DE FUNÇÃO M030INC ========================================== */

				/* ==========================================   TROCA DE FUNÇÃO ALTCLI ========================================== */


				/* ==========================================   TROCA DE FUNÇÃO M030EXC ========================================== */


		ElseIf cIdPonto == "MODELCOMMITNTTS"

		ElseIf cIdPonto == "FORMCOMMITTTSPRE"


		ElseIf cIdPonto == "FORMCOMMITTTSPOS"

		ElseIf cIdPonto == "MODELCANCEL"

		ElseIf cIdPonto == "BUTTONBAR"
			xRet	:= { {"Consulta Receita","AMARELO",{|| sfReceita() }} , {"Consulta Serasa Infomais","AMARELO",{|| FWMsgRun(,{||  sfSerasa() },"Efetuando consulta no Serasa...") }}}

		EndIf

	EndIf
	RestArea(aArea)
Return xRet




/*/{Protheus.doc} sfReceita
//Função que verifica via HTTPS os dados do cadastro do CNPJ
@author Marcelo Alberto Lauschner
@since 11/05/2018
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
Static Function sfReceita()

	// Variável Caractere
	Local	cUrlRec		:=	'https://www.receitaws.com.br/v1/cnpj/' + M->A1_CGC
	Local	cJsonRet	:=  HttpGet(cUrlRec)
	Local	cQry
	Local	cVarAux
	Local	oModelA1 	:= FWModelActive()
	// Variável Lógica
	Local	lRetCep		:= .F.
	// Variável Objeto
	Private oParseJSON 	:= Nil

	FWJsonDeserialize(cJsonRet, @oParseJSON)

	If Type("oParseJSON:situacao") <> "U"
		If oParseJSON:situacao <> "ATIVA"
			ShowHelpDlg(ProcName(0)+"."+ Alltrim(Str(ProcLine(0))),;
				{"CNPJ com Situação Cadastral diferente de 'Ativa'."},;
				5,;
				{"Dados devem ser preenchidos manualmente se necessário fazer o cadastro."},;
				5)
			Return
		Endif
	Else
		ShowHelpDlg(ProcName(0)+"."+ Alltrim(Str(ProcLine(0))),;
			{"Erro na chamada. Retorno: "+cJsonRet},;
			5,;
			{"Efetue o cadastro do cliente manualmente a partir da consulta no Sintegra!"},;
			5)
		Return
	Endif

	If Type("oParseJSON:status") <> "U"
		If oParseJSON:status <> "OK"
			ShowHelpDlg(ProcName(0)+"."+ Alltrim(Str(ProcLine(0))),;
				{"CNPJ com Status diferente de 'OK'."},;
				5,;
				{"Dados devem ser preenchidos manualmente se necessário fazer o cadastro."},;
				5)
			Return
		Endif

	Endif

	//If oModelA1 <> Nil .And. oModelA1:GetModel('SA2MASTER') <> Nil
	//	oModelA1:GetModel('SA2MASTER'):SetValue('A2_XCCPASV',cA2XCCPASV)
	//Endif
	//If Type("M->A2_XCCPASV") == "C"
	//	M->A2_XCCPASV	:= cA2XCCPASV
	//Endif


	If Type("oParseJSON:nome") <> "U"
		M->A1_NOME	:= Padr(NoAcento(Upper(oParseJSON:nome)),TamSX3("A1_NOME")[1])

		If oModelA1 <> Nil .And. oModelA1:GetModel('SA1MASTER') <> Nil
			oModelA1:GetModel('SA1MASTER'):SetValue('A1_NOME',M->A1_NOME)
		Endif
	Endif

	If Type("oParseJSON:fantasia") <> "U"
		M->A1_NREDUZ	:= Padr(NoAcento(Upper(oParseJSON:fantasia)),TamSX3("A1_NREDUZ")[1])
		If oModelA1 <> Nil .And. oModelA1:GetModel('SA1MASTER') <> Nil
			oModelA1:GetModel('SA1MASTER'):SetValue('A1_NREDUZ',M->A1_NREDUZ)
		Endif
	Endif

	If Type("oParseJSON:email") <> "U"
		M->A1_EMAIL	:= Padr(oParseJSON:email,TamSX3("A1_EMAIL")[1])
		If oModelA1 <> Nil .And. oModelA1:GetModel('SA1MASTER') <> Nil
			oModelA1:GetModel('SA1MASTER'):SetValue('A1_EMAIL',M->A1_EMAIL)
		Endif
	Endif

	If Type("oParseJSON:cep") <> "U"
		M->A1_CEP	:= Padr(StrTran(StrTran(oParseJSON:cep,".",""),"-",""),TamSX3("A1_CEP")[1])
		If oModelA1 <> Nil .And. oModelA1:GetModel('SA1MASTER') <> Nil
			oModelA1:GetModel('SA1MASTER'):SetValue('A1_CEP',M->A1_CEP)
		Endif
		//lRetCep	    := Se necessário criar uma regra própria para preenchimetno do CEP
		// Aciona gatilhos do campo CEP
		If ExistTrigger('A1_CEP')
			RunTrigger(1,nil,nil,,'A1_CEP')
		Endif
	Endif


	If Type("oParseJSON:abertura") <> "U"
		M->A1_DTNASC	:= CTOD(oParseJSON:abertura)
		If oModelA1 <> Nil .And. oModelA1:GetModel('SA1MASTER') <> Nil
			oModelA1:GetModel('SA1MASTER'):SetValue('A1_DTNASC',M->A1_DTNASC)
		Endif
	Endif

	// Se a validação do CEP não ocorreu, preenche os dados a partir da RECEITA
	If !lRetCep
		If Type("oParseJSON:logradouro") <> "U"
			M->A1_END	:= Padr(NoAcento(Upper(oParseJSON:logradouro)),TamSX3("A1_END")[1])
			M->A1_ENDCOB	:= M->A1_END
			M->A1_ENDENT	:= M->A1_END
			If oModelA1 <> Nil .And. oModelA1:GetModel('SA1MASTER') <> Nil
				oModelA1:GetModel('SA1MASTER'):SetValue('A1_END',M->A1_END)
				oModelA1:GetModel('SA1MASTER'):SetValue('A1_ENDCOB',M->A1_END)
				oModelA1:GetModel('SA1MASTER'):SetValue('A1_ENDENT',M->A1_END)
			Endif
		Endif

		If Type("oParseJSON:numero") <> "U"
			cVarAux		:= Alltrim(M->A1_END)
			M->A1_END	:= Padr(cVarAux + "," + NoAcento(Upper(oParseJSON:numero)),TamSX3("A1_END")[1])
			M->A1_ENDCOB	:= M->A1_END
			M->A1_ENDENT	:= M->A1_END
			If oModelA1 <> Nil .And. oModelA1:GetModel('SA1MASTER') <> Nil
				oModelA1:GetModel('SA1MASTER'):SetValue('A1_END',M->A1_END)
				oModelA1:GetModel('SA1MASTER'):SetValue('A1_ENDCOB',M->A1_END)
				oModelA1:GetModel('SA1MASTER'):SetValue('A1_ENDENT',M->A1_END)
			Endif
		Endif

		If Type("oParseJSON:bairro") <> "U"
			M->A1_BAIRRO	:= Padr(NoAcento(Upper(oParseJSON:bairro)),TamSX3("A1_BAIRRO")[1])
			M->A1_BAIRROE	:= M->A1_BAIRRO
			M->A1_BAIRROC	:= M->A1_BAIRRO
			If oModelA1 <> Nil .And. oModelA1:GetModel('SA1MASTER') <> Nil
				oModelA1:GetModel('SA1MASTER'):SetValue('A1_BAIRRO',M->A1_BAIRRO)
				oModelA1:GetModel('SA1MASTER'):SetValue('A1_BAIRROE',M->A1_BAIRRO)
				oModelA1:GetModel('SA1MASTER'):SetValue('A1_BAIRROC',M->A1_BAIRRO)
			Endif
		Endif

		If Type("oParseJSON:complemento") <> "U"
			M->A1_COMPLEM	:= Padr(NoAcento(Upper(oParseJSON:complemento)),TamSX3("A1_COMPLEM")[1])
			If oModelA1 <> Nil .And. oModelA1:GetModel('SA1MASTER') <> Nil
				oModelA1:GetModel('SA1MASTER'):SetValue('A1_COMPLEM',M->A1_COMPLEM)
			Endif
		Endif

		If Type("oParseJSON:municipio") <> "U"
			M->A1_MUN	:= Padr(NoAcento(Upper(oParseJSON:municipio)),TamSX3("A1_MUN")[1])
			If oModelA1 <> Nil .And. oModelA1:GetModel('SA1MASTER') <> Nil
				oModelA1:GetModel('SA1MASTER'):SetValue('A1_MUN',M->A1_MUN)
			Endif
		Endif

		If Type("oParseJSON:uf") <> "U"
			M->A1_EST	:= Padr(NoAcento(Upper(oParseJSON:uf)),TamSX3("A1_EST")[1])
			If oModelA1 <> Nil .And. oModelA1:GetModel('SA1MASTER') <> Nil
				oModelA1:GetModel('SA1MASTER'):SetValue('A1_EST',M->A1_EST)
			Endif
		Endif

		cQry := "SELECT CC2_CODMUN "
		cQry += "  FROM " + RetSqlName("CC2")
		cQry += " WHERE D_E_L_E_T_ =' ' "
		cQry += "   AND CC2_EST = '"+oParseJSON:uf+"' "
		cQry += "   AND CC2_MUN LIKE '%"+ oParseJSON:municipio + "%' "
		cQry += "   AND CC2_FILIAL = '"+xFilial("CC2") + "' "

		dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),"TBLEXIST",.T.,.T.)
		If TBLEXIST->(!Eof())
			M->A1_COD_MUN	:=  TBLEXIST->CC2_CODMUN
		Endif
		TBLEXIST->(DbCloseArea())

	Else
		If Type("oParseJSON:numero") <> "U"
			cVarAux			:= Alltrim(M->A1_END)
			If Empty(cVarAux)
				If Type("oParseJSON:logradouro") <> "U"
					cVarAux	:= Padr(NoAcento(Upper(oParseJSON:logradouro)),TamSX3("A1_END")[1])
				Endif
			Endif
			M->A1_END		:= Padr(Alltrim(cVarAux) + ", " + NoAcento(Upper(oParseJSON:numero)),TamSX3("A1_END")[1])
			M->A1_ENDCOB	:= Padr(Alltrim(cVarAux) + ", " + NoAcento(Upper(oParseJSON:numero)),TamSX3("A1_ENDCOB")[1])
			M->A1_ENDENT	:= Padr(Alltrim(cVarAux) + ", " + NoAcento(Upper(oParseJSON:numero)),TamSX3("A1_ENDENT")[1])

			If oModelA1 <> Nil .And. oModelA1:GetModel('SA1MASTER') <> Nil
				oModelA1:GetModel('SA1MASTER'):SetValue('A1_END',M->A1_END)
				oModelA1:GetModel('SA1MASTER'):SetValue('A1_ENDCOB',M->A1_END)
				oModelA1:GetModel('SA1MASTER'):SetValue('A1_ENDENT',M->A1_END)
			Endif
			cVarAux			:= Alltrim(M->A1_BAIRRO)

			If Empty(cVarAux) .And. Type("oParseJSON:bairro") <> "U"
				M->A1_BAIRRO	:= Padr(NoAcento(Upper(oParseJSON:bairro)),TamSX3("A1_BAIRRO")[1])
				M->A1_BAIRROE	:= Padr(NoAcento(Upper(oParseJSON:bairro)),TamSX3("A1_BAIRROE")[1])
				M->A1_BAIRROC	:= Padr(NoAcento(Upper(oParseJSON:bairro)),TamSX3("A1_BAIRROC")[1])
				If oModelA1 <> Nil .And. oModelA1:GetModel('SA1MASTER') <> Nil
					oModelA1:GetModel('SA1MASTER'):SetValue('A1_BAIRRO',M->A1_BAIRRO)
					oModelA1:GetModel('SA1MASTER'):SetValue('A1_BAIRROE',M->A1_BAIRRO)
					oModelA1:GetModel('SA1MASTER'):SetValue('A1_BAIRROC',M->A1_BAIRRO)
				Endif
			Endif

		Endif
	Endif
Return

/*/{Protheus.doc} sfSerasa
Rotina para cadastro de cliente a partir de consulta do Serasa 
@type function
@version  
@author marce
@since 11/09/2023
@return variant, return_description
/*/
Static Function sfSerasa()

	Local   cStringRet      := ""
	Local   cErros          := ""
	Local   cAvisos         := ""
	Local   lHouveErro      := .F.
	Local   cMsgErro        := ""
	Local   lContinua       := .T.
	Local 	iX
	Local   cUserSerasa     := GetNewPar("GF_SERAUSR","48228823")
	Local   cPswdSerasa     := GetnewPar("GF_SERAPSW","Tec@6655")
	Local	oModelA1 		:= FWModelActive()

	//Montando o XML que será enviado

	cStringRet += '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:dat="http://services.experian.com.br/DataLicensing/DataLicensingService/">'+ CRLF
	cStringRet += ' <soapenv:Header>'+ CRLF
	cStringRet += '  <wsse:Security soapenv:mustUnderstand="1" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">'+ CRLF
	cStringRet += '   <wsse:UsernameToken wsu:Id="UsernameToken-2">'+ CRLF
	cStringRet += '    <wsse:Username>'+Alltrim(cUserSerasa)+'</wsse:Username>'+ CRLF
	cStringRet += '    <wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText">'+Alltrim(cPswdSerasa)+'</wsse:Password>'+ CRLF
	cStringRet += '   </wsse:UsernameToken>'+ CRLF
	cStringRet += '  </wsse:Security>'+ CRLF
	cStringRet += ' </soapenv:Header>'+ CRLF
	cStringRet += ' <soapenv:Body>'+ CRLF
	cStringRet += '  <dat:ConsultarPJ>'+ CRLF
	cStringRet += '   <parameters>'+ CRLF
	cStringRet += '    <cnpj>'+M->A1_CGC+'</cnpj>'+ CRLF
	cStringRet += '    <RetornoPJ>'+ CRLF
	cStringRet += '     <cnpj>true</cnpj>'+ CRLF
	cStringRet += '     <razaoSocial>true</razaoSocial>'+ CRLF
	cStringRet += '     <nomeFantasia>true</nomeFantasia>'+ CRLF
	cStringRet += '     <dataAbertura>true</dataAbertura>'+ CRLF
	cStringRet += '     <naturezaJuridica>true</naturezaJuridica>'+ CRLF
	cStringRet += '     <cnae>true</cnae>'+ CRLF
	cStringRet += '     <sintegra>ONLINE_HISTORICO</sintegra>'+ CRLF
	cStringRet += '     <endereco>true</endereco>'+ CRLF
	cStringRet += '     <telefone>true</telefone>'+ CRLF
	cStringRet += '     <quadroSocial>true</quadroSocial>'+ CRLF
	cStringRet += '     <composicaoSocietaria>true</composicaoSocietaria>'+ CRLF
	cStringRet += '     <situacaoCadastral>ONLINE_HISTORICO</situacaoCadastral>'+ CRLF
	cStringRet += '     <porte>true</porte>'+ CRLF
	cStringRet += '    </RetornoPJ>'+ CRLF
	cStringRet += '   </parameters>'+ CRLF
	cStringRet += '  </dat:ConsultarPJ>'+ CRLF
	cStringRet += ' </soapenv:Body>'+ CRLF
	cStringRet += '</soapenv:Envelope>'+ CRLF


	//Instancia a classe na variável oWsdl
	oWsdl := TWsdlManager():New()

	//Define o modo de trabalho como "VERBOSE"
	oWsdl:lVerbose          := .T.
	oWsdl:lSSLInsecure      := .T.
	oWsdl:bNoCheckPeerCert  := .T. // Desabilita o check de CAs
	oWsdl:nTimeout          := 60
	//oWsdl:nSSLVersion       := 0
	oWsdl:lProcResp 	    	:= .F.

	//oWsdl:SetAuthentication("48228823" , "Tec@6655")

	//Tenta fazer o parse da URL
	lRet := oWsdl:ParseURL("https://sitenet.serasa.com.br/experian-data-licensing-ws/dataLicensingService?wsdl")

	If lRet

		//Tenta definir a operação
		lRet := oWsdl:SetOperation("ConsultarPJ")
		If ! lRet
			MsgAlert("Erro SetOperation: " + oWsdl:cError, "Atenção")
			lContinua := .F.
		EndIf

		//Se for continuar o processamento
		If lContinua
			//Envia o XML montado
			lRet := oWsdl:SendSoapMsg( cStringRet )

			//Se houve falha, exibe a mensagem
			If ! lRet
				MsgAlert("Erro SendSoapMsg: " + oWsdl:cError, "Atenção")
			Else
				//Pega a resposta do SOAP e transforma em Objeto a resposta
				cMsgRet := oWsdl:GetSoapResponse()
				oLido := XmlParser(cMsgRet, "_", @cErros, @cAvisos)

				//MsgInfo("Sucesso na Integração: Retorno " + oWsdl:GetParsedResponse() , "Atenção")

				//Se existir alguma mensagem de Warning, e quiser exibir, basta descomentar a linha do MsgInfo
				If ! Empty(cAvisos)
					MsgInfo("Aviso(s) ao converter em objeto: " + cAvisos, "Atenção")
				EndIf

				//Se existe a tag de erro
				If At('<motivoErro>', cMsgRet) > 0
					cMsgErro := oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_razaoSocial:TEXT
					lHouveErro := .T.
				Else
					lHouveErro := .F.
				EndIf

				//Se houve erro ou deu certo, mostra a mensagem
				If lHouveErro
					MsgStop("Erro na Integração: " + cMsgErro, "Atenção")
				Else

					// Array
					If Type("oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_Cnae:_tnsCnae") == "A"
						cCodCnae        := oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_Cnae:_tnsCnae[1]:_codigo:TEXT
						cNomCnae        := oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_Cnae:_tnsCnae[1]:_descricao:TEXT
					Else
						cCodCnae		:= ""
					Endif

					cCnpj           := oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_cnpj:TEXT


					If Type(" oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_enderecos") == "A"
						cBairro         := oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_enderecos[1]:_endereco:_bairro:TEXT
						cCep            := oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_enderecos[1]:_endereco:_cep:TEXT
						cCidade         := oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_enderecos[1]:_endereco:_cidade:TEXT
						cLogradouro     := oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_enderecos[1]:_endereco:_logradouro:_nome:TEXT
						cNumero         := oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_enderecos[1]:_endereco:_logradouro:_numero:TEXT
						If Type("oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_enderecos[1]:_endereco:_logradouro:_complemento") <> "U"
							cComplemento    := oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_enderecos[1]:_endereco:_logradouro:_complemento:TEXT
						Else
							cComplemento	:= ""
						Endif
						cUf             := oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_enderecos[1]:_endereco:_uf:TEXT
					Else
						cBairro         := oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_enderecos:_endereco[1]:_bairro:TEXT
						cCep            := oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_enderecos:_endereco[1]:_cep:TEXT
						cCidade         := oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_enderecos:_endereco[1]:_cidade:TEXT
						cLogradouro     := oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_enderecos:_endereco[1]:_logradouro:_nome:TEXT
						cNumero         := oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_enderecos:_endereco[1]:_logradouro:_numero:TEXT
						If Type("oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_enderecos:_endereco[1]:_logradouro:_complemento") <> "U"
							cComplemento    := oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_enderecos:_endereco[1]:_logradouro:_complemento:TEXT
						Else
							cComplemento	:= ""
						Endif

						cUf             := oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_enderecos:_endereco[1]:_uf:TEXT
					Endif
					cNatJuridica    := oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_naturezaJuridica:_codigo:TEXT
					cDesNatJurid    := oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_naturezaJuridica:_descricao:TEXT

					// Atualiza a Razão Social
					cRazaoSocial 	:= oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_razaoSocial:TEXT
					M->A1_NOME	:= Padr(NoAcento(Upper(cRazaoSocial)),TamSX3("A1_NOME")[1])
					If oModelA1 <> Nil .And. oModelA1:GetModel('SA1MASTER') <> Nil
						oModelA1:GetModel('SA1MASTER'):SetValue('A1_NOME',M->A1_NOME)
					Endif

					// Atualiza Nome Fantasia
					If Type("oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_nomeFantasia") <> "U"
						cNomFantasia    := oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_nomeFantasia:TEXT
						If cNomFantasia == "********"
							cNomFantasia    := cRazaoSocial
						Endif
					Else
						cNomFantasia    := cRazaoSocial
					Endif
					M->A1_NREDUZ	:= Padr(NoAcento(Upper(cNomFantasia)),TamSX3("A1_NREDUZ")[1])
					If oModelA1 <> Nil .And. oModelA1:GetModel('SA1MASTER') <> Nil
						oModelA1:GetModel('SA1MASTER'):SetValue('A1_NREDUZ',M->A1_NREDUZ)
					Endif

					If Type("oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_porte") <> "U"
						cPorteEmp       := oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_porte:TEXT
					Else
						cPorteEmp		:= ""
					Endif

					// Atualiza data de abertura da Empresa
					dDataAbertura   := STOD(StrTran(Substr(oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_dataabertura:TEXT,1,10),"-","")) //TEXT: "1992-10-16T00:00:00.000-03:00
					M->A1_DTNASC	:= dDataAbertura
					If oModelA1 <> Nil .And. oModelA1:GetModel('SA1MASTER') <> Nil
						oModelA1:GetModel('SA1MASTER'):SetValue('A1_DTNASC',M->A1_DTNASC)
					Endif

					M->A1_CEP	:= Padr(StrTran(StrTran(cCep,".",""),"-",""),TamSX3("A1_CEP")[1])
					If oModelA1 <> Nil .And. oModelA1:GetModel('SA1MASTER') <> Nil
						oModelA1:GetModel('SA1MASTER'):SetValue('A1_CEP',M->A1_CEP)
					Endif


					If !Empty(cNumero)
						cVarAux			:= Alltrim(NoAcento(Upper(cLogradouro))) + ", "+ Alltrim(cNumero)
						M->A1_END		:= Padr(cVarAux,TamSX3("A1_END")[1])
						If oModelA1 <> Nil .And. oModelA1:GetModel('SA1MASTER') <> Nil
							oModelA1:GetModel('SA1MASTER'):SetValue('A1_END',M->A1_END)
						Endif
					Else
						M->A1_END		:= Padr(NoAcento(Upper(cLogradouro)),TamSX3("A1_END")[1])
						If oModelA1 <> Nil .And. oModelA1:GetModel('SA1MASTER') <> Nil
							oModelA1:GetModel('SA1MASTER'):SetValue('A1_END',M->A1_END)
						Endif
					Endif
					If !Empty(cComplemento) .And. cComplemento <> "********"
						M->A1_COMPLEM	:= Padr(NoAcento(Upper(cComplemento)),TamSX3("A1_COMPLEM")[1])
						If oModelA1 <> Nil .And. oModelA1:GetModel('SA1MASTER') <> Nil
							oModelA1:GetModel('SA1MASTER'):SetValue('A1_COMPLEM',M->A1_COMPLEM)
						Endif
					Endif

					M->A1_BAIRRO	:= Padr(NoAcento(Upper(cBairro)),TamSX3("A1_BAIRRO")[1])
					If oModelA1 <> Nil .And. oModelA1:GetModel('SA1MASTER') <> Nil
						oModelA1:GetModel('SA1MASTER'):SetValue('A1_BAIRRO',M->A1_BAIRRO)
					Endif

					M->A1_MUN	:= Padr(NoAcento(Upper(cCidade)),TamSX3("A1_MUN")[1])
					If oModelA1 <> Nil .And. oModelA1:GetModel('SA1MASTER') <> Nil
						oModelA1:GetModel('SA1MASTER'):SetValue('A1_MUN',M->A1_MUN)
					Endif

					M->A1_EST	:= Padr(NoAcento(Upper(cUF)),TamSX3("A1_EST")[1])
					If oModelA1 <> Nil .And. oModelA1:GetModel('SA1MASTER') <> Nil
						oModelA1:GetModel('SA1MASTER'):SetValue('A1_EST',M->A1_EST)
					Endif

					cQry := "SELECT CC2_CODMUN "
					cQry += "  FROM " + RetSqlName("CC2")
					cQry += " WHERE D_E_L_E_T_ =' ' "
					cQry += "   AND CC2_EST = '"+cUF+"' "
					cQry += "   AND CC2_MUN = '"+ cCidade + "' "
					cQry += "   AND CC2_FILIAL = '"+xFilial("CC2") + "' "

					dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),"TBLEXIST",.T.,.T.)
					If TBLEXIST->(!Eof())
						M->A1_COD_MUN	:=  TBLEXIST->CC2_CODMUN
						If oModelA1 <> Nil .And. oModelA1:GetModel('SA1MASTER') <> Nil
							oModelA1:GetModel('SA1MASTER'):SetValue('A1_COD_MUN',M->A1_COD_MUN)
						Endif
					Endif
					TBLEXIST->(DbCloseArea())
					// Se for um Array
					If Type("oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_sintegra:_ocorrencia") == "A"

						aSintCli	:= oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_sintegra:_ocorrencia
						// Percorre os cadastros até achar um Ativo
						For iX := 1 To Len(aSintCli)
							cSituacao	:= aSintCli[iX]:_situacaoCadastral:TEXT
							If  aSintCli[iX]:_situacaoCadastral:TEXT == "ATIVO"
								cInscEstadual	:= aSintCli[iX]:_inscricaoEstadual:TEXT
								cSituacao	:= aSintCli[iX]:_situacaoCadastral:TEXT
								Exit
							Endif
						Next
						// Se tiver só uma ocorrência
					ElseIf Type("oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_sintegra:_ocorrencia:_inscricaoEstadual") <> "U"
						cInscEstadual   := oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_sintegra:_ocorrencia:_inscricaoEstadual:TEXT
						If Type("oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_situacaoCadastral:_situacao") <> "U"
							dDataSituacao   := STOD(StrTran(Substr(oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_situacaoCadastral:_dataSituacao:TEXT,1,10),"-","")) //"2023-09-08T00:00:00.000-03:00"
							cSituacao       := oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_situacaoCadastral:_situacao:TEXT //
						Else
							dDataSituacao	:= dDataBase
							cSituacao		:= "Sem Status Retorno"
						Endif
						// Não encontrou informação
					Else
						cInscEstadual	:= "ISENTO"
						dDataSituacao	:= dDataBase
						cSituacao		:= "ATIVO"
					Endif

					M->A1_INSCR	:= Padr(NoAcento(Upper(cInscEstadual)),TamSX3("A1_INSCR")[1])
					If oModelA1 <> Nil .And. oModelA1:GetModel('SA1MASTER') <> Nil
						oModelA1:GetModel('SA1MASTER'):SetValue('A1_INSCR',M->A1_INSCR)
					Endif

					M->A1_CNAE	:= Padr(cCodCnae,TamSX3("A1_CNAE")[1])
					If oModelA1 <> Nil .And. oModelA1:GetModel('SA1MASTER') <> Nil
						oModelA1:GetModel('SA1MASTER'):SetValue('A1_CNAE',M->A1_CNAE)
					Endif

					// Array
					If Type("oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_quadroSocial:_quadroSocial") == "A"
						If Type("oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_quadroSocial:_quadroSocial[1]:_nome") <> "U"
							cQdSocNome      := oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_quadroSocial:_quadroSocial[1]:_nome:TEXT
						Else
							cQdSocNome		:= ""
						Endif
						If Type("oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_quadroSocial:_quadroSocial[1]:_qualificacao") <> "U"
							cQdQualif       := oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_quadroSocial:_quadroSocial[1]:_qualificacao:TEXT
						Else
							cQdQualif		:= ""
						Endif
					Endif


					If !(cSituacao $ "ATIVA#ATIVO")
						M->A1_MSBLQL	:= "1"
						If oModelA1 <> Nil .And. oModelA1:GetModel('SA1MASTER') <> Nil
							oModelA1:GetModel('SA1MASTER'):SetValue('A1_MSBLQL',M->A1_MSBLQL)
						Endif
					Endif
					MsgInfo("Sucesso na Integração: Situação do cadastro: " + cSituacao , "Atenção")
				EndIF
			EndIf
		EndIf

	Else
		MsgAlert("Erro ParseURL: " + oWsdl:cError, "Atenção")
	EndIf

Return

/*/{Protheus.doc} sfAjust
//Ajusta o texto do JSON
@author Marcelo Alberto Lauschneer
@since 11/05/2018
@version 1.0
@return ${return}, ${return_description}
@param cInChar, characters, descricao
@param lOutJson, logical, descricao
@type function
/*/
Static Function sfAjust(cInChar,lOutJson)

	Local	cOut		:= DecodeUTF8(cInChar, "iso8859-1")
	Local	aOut		:= {}
	Local	nO
	Default lOutJson	:= .F.
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
	Aadd(aOut,{"&","\u0026"," "})
	Aadd(aOut,{"'","\u0027"," "})
	Aadd(aOut,{"´","\u00b4"," "})
	Aadd(aOut,{Chr(13),"\u0013"," "})
	Aadd(aOut,{Chr(10),"\u0010"," "})
	//ConOut("+------------------------------------+")
	//ConOut(cOut)
	If lOutJson
		For nO := 1 To Len(aOut)
			cOut	:= StrTran(cOut,aOut[nO,1],aOut[nO,2])
		Next nO

	Else
		cOut	:= DecodeUTF8(cOut)
		//ConOut(cOut)

		For nO := 1 To Len(aOut)
			cOut	:= StrTran(cOut,aOut[nO,1],aOut[nO,3])
		Next nO

		cOut	:= Alltrim(Upper(cOut))
	Endif
	//ConOut(cInChar)
	//ConOut(cOut)
	//ConOut("+++------------------------------------+")

Return cOut
