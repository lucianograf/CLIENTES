/*/{Protheus.doc} MLFATC08
Função para consultar Serasa - Infomais - Obtém dados do CNPJ informado para preencher cadastro do cliente ou fornecedor                                                                                                                           
@type function
@version  
@author marce
@since 11/09/2023
@return variant, return_description
/*/
User Function MLFATC08()

	Local    cStringRet        := ""
	Local    cErros            := ""
	Local    cAvisos           := ""
	Local    lHouveErro        := .F.
	Local    cMsgErro          := ""
	Local    cMsgSuces         := ""
	Local    CRLF              := Chr(13) + Chr(10)
	Local    lContinua         := .T.
   Local    cUserSerasa       := GetNewPar("GF_SERAUSR","48228823")
   Local    cPswdSerasa       := GetnewPar("GF_SERAPSW","Tec@6655")
   Local    cCgcConsulta      := GetNewPar("GF_SERCNPJ","06032022000110") 
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
	cStringRet += '    <cnpj>'+ cCgcConsulta + '</cnpj>'+ CRLF
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
	oWsdl:nSSLVersion       := 0
	oWsdl:lProcResp 	    := .F.

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
					Endif

					cCnpj           := oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_cnpj:TEXT
					dDataAbertura   := STOD(StrTran(Substr(oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_dataabertura:TEXT,1,10),"-","")) //TEXT: "1992-10-16T00:00:00.000-03:00

					If Type(" oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_enderecos") == "A"
						cBairro         := oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_enderecos[1]:_endereco:_bairro:TEXT
						cCep            := oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_enderecos[1]:_endereco:_cep:TEXT
						cCidade         := oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_enderecos[1]:_endereco:_cidade:TEXT
						cLogradouro     := oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_enderecos[1]:_endereco:_logradouro:_nome:TEXT
						cNumero         := oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_enderecos[1]:_endereco:_logradouro:_numero:TEXT
						cComplemento    := oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_enderecos[1]:_endereco:_logradouro:_complemento:TEXT
						cUf             := oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_enderecos[1]:_endereco:_uf:TEXT
					Endif
					cNatJuridica    := oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_naturezaJuridica:_codigo:TEXT
					cDesNatJurid    := oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_naturezaJuridica:_descricao:TEXT
					If Type("oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_nomeFantasia") <> "U"
						cNomFantasia    := oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_nomeFantasia:TEXT
					Else
						cNomFantasia    := ""
					Endif
					cPorteEmp       := oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_porte:TEXT

					// Array
					If Type("oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_quadroSocial:_quadroSocial") == "A"
						cQdSocNome      := oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_quadroSocial:_quadroSocial[1]:_nome:TEXT
						cQdQualif       := oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_quadroSocial:_quadroSocial[1]:_qualificacao:TEXT
					Endif
					If Type("oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_sintegra:_ocorrencia:_inscricaoEstadual") <> "U"
						cInscEstadual   := oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_sintegra:_ocorrencia:_inscricaoEstadual:TEXT
					Endif

					dDataSituacao   := STOD(StrTran(Substr(oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_situacaoCadastral:_dataSituacao:TEXT,1,10),"-","")) //"2023-09-08T00:00:00.000-03:00"
					cSituacao       := oLido:_S_Envelope:_S_Body:_NS2_ConsultarPJResponse:_result:_situacaoCadastral:_situacao:TEXT //

					MsgInfo("Sucesso na Integração: " + cMsgSuces, "Atenção")
				EndIF
			EndIf
		EndIf

	Else
		MsgAlert("Erro ParseURL: " + oWsdl:cError, "Atenção")
	EndIf

Return

/*
<S:Envelope xmlns:S="http://schemas.xmlsoap.org/soap/envelope/" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd" xmlns:xs="http://www.w3.org/2001/XMLSchema">
   <S:Header>
      <wsse:Security S:mustUnderstand="1">
         <wsu:Timestamp wsu:Id="_1" xmlns:ns15="http://schemas.xmlsoap.org/ws/2006/02/addressingidentity" xmlns:ns14="http://docs.oasis-open.org/ws-sx/ws-secureconversation/200512" xmlns:ns13="http://www.w3.org/2003/05/soap-envelope">
            <wsu:Created>2023-09-09T04:33:55Z</wsu:Created>
            <wsu:Expires>2023-09-09T04:38:55Z</wsu:Expires>
         </wsu:Timestamp>
      </wsse:Security>
   </S:Header>
   <S:Body>
      <ns2:ConsultarPJResponse xmlns:ns3="http://ws.wim.omninetworking.com.br/" xmlns:ns2="http://services.experian.com.br/DataLicensing/DataLicensingService/">
         <result>
            <enderecos>
               <endereco>
                  <logradouro>
                     <Nome>R DOUTOR PEDRO ZIMMERMANN</Nome>
                     <Numero>2464</Numero>
                     <Complemento>SALA 10</Complemento>
                     <CepNota>0</CepNota>
                  </logradouro>
                  <bairro>ITOUPAVAZINHA</bairro>
                  <cidade>BLUMENAU</cidade>
                  <uf>SC</uf>
                  <cep>89.066-003</cep>
               </endereco>
            </enderecos>
            <enderecos/>
            <telefones>
               <telefone>
                  <numero>(47) 3041-2001/ (47) 3041-2021</numero>
               </telefone>
            </telefones>
            <cnpj>06032022000110</cnpj>
            <razaoSocial>ATRIA LUB COMERCIO DE LUBRIFICANTES S.A.</razaoSocial>
            <nomeFantasia>********</nomeFantasia>
            <dataAbertura>2003-12-02T00:00:00.000-03:00</dataAbertura>
            <naturezaJuridica>
               <codigo>2054</codigo>
               <descricao>Sociedade Anonima Fechada</descricao>
            </naturezaJuridica>
            <cnae>
               <tnsCnae>
                  <codigo>4681805</codigo>
                  <descricao>Comercio atacadista de lubrificantes</descricao>
               </tnsCnae>
               <tnsCnae>
                  <codigo>2093200</codigo>
                  <descricao>Fabricacao de aditivos de uso industrial</descricao>
               </tnsCnae>
               <tnsCnae>
                  <codigo>4530701</codigo>
                  <descricao>Comercio por atacado de pecas e acessorios novos para veiculos automotores</descricao>
               </tnsCnae>
               <tnsCnae>
                  <codigo>4530702</codigo>
                  <descricao>Comercio por atacado de pneumaticos e camaras-de-ar</descricao>
               </tnsCnae>
               <tnsCnae>
                  <codigo>4612500</codigo>
                  <descricao>Representantes comerciais e agentes do comercio de combustiveis, minerais, produtos siderurgicos e quimicos</descricao>
               </tnsCnae>
               <tnsCnae>
                  <codigo>4623101</codigo>
                  <descricao>Comercio atacadista de animais vivos</descricao>
               </tnsCnae>
               <tnsCnae>
                  <codigo>4634699</codigo>
                  <descricao>Comercio atacadista de carnes e derivados de outros animais</descricao>
               </tnsCnae>
               <tnsCnae>
                  <codigo>4651601</codigo>
                  <descricao>Comercio atacadista de equipamentos de informatica</descricao>
               </tnsCnae>
               <tnsCnae>
                  <codigo>4684299</codigo>
                  <descricao>Comercio atacadista de outros produtos quimicos e petroquimicos nao especificados anteriormente</descricao>
               </tnsCnae>
               <tnsCnae>
                  <codigo>4689399</codigo>
                  <descricao>Comercio atacadista especializado em outros produtos intermediarios nao especificados anteriormente</descricao>
               </tnsCnae>
               <tnsCnae>
                  <codigo>6201501</codigo>
                  <descricao>Desenvolvimento de programas de computador sob encomenda</descricao>
               </tnsCnae>
               <tnsCnae>
                  <codigo>6204000</codigo>
                  <descricao>Consultoria em tecnologia da informacao</descricao>
               </tnsCnae>
               <tnsCnae>
                  <codigo>7120100</codigo>
                  <descricao>Testes e analises tecnicas</descricao>
               </tnsCnae>
               <tnsCnae>
                  <codigo>7733100</codigo>
                  <descricao>Aluguel de maquinas e equipamentos para escritorios</descricao>
               </tnsCnae>
               <tnsCnae>
                  <codigo>8211300</codigo>
                  <descricao>Servicos combinados de escritorio e apoio administrativo</descricao>
               </tnsCnae>
            </cnae>
            <situacaoCadastral>
               <codigoSituacao>1</codigoSituacao>
               <situacao>ATIVA</situacao>
               <dataSituacao>2003-12-02T00:00:00.000-03:00</dataSituacao>
               <situacaoEspecial>********</situacaoEspecial>
               <motivo/>
               <dataConsulta>2023-09-09T00:00:00.000-03:00</dataConsulta>
               <fontePesquisada>ONLINE</fontePesquisada>
            </situacaoCadastral>
            <porte>DEMAIS</porte>
            <quadroSocial>
               <quadroSocial>
                  <nome>MAURICIO BERNARDO CERDEIRA LEIBOVITZ</nome>
                  <qualificacao>10-Diretor</qualificacao>
               </quadroSocial>
               <quadroSocial>
                  <nome>ROBERTO BUENO DE CAMARGO JUNIOR</nome>
                  <qualificacao>10-Diretor</qualificacao>
               </quadroSocial>
            </quadroSocial>
            <sintegra>
               <ocorrencia>
                  <inscricaoEstadual>254695523</inscricaoEstadual>
                  <situacaoCadastral>ATIVO</situacaoCadastral>
                  <dataSituacao>2004-01-16</dataSituacao>
                  <dataConsulta>2023-07-06</dataConsulta>
                  <uf>SC</uf>
                  <logradouro>RUA DOUTOR PEDRO ZIMMERMANN</logradouro>
                  <numero>2464</numero>
                  <cep>89066000</cep>
                  <municipio>BLUMENAU</municipio>
                  <complemento>SALA 10</complemento>
                  <bairro>ITOUPAVAZINHA</bairro>
                  <fontePesquisada>HISTORICO</fontePesquisada>
               </ocorrencia>
            </sintegra>
         </result>
      </ns2:ConsultarPJResponse>
   </S:Body>
</S:Envelope>*/
