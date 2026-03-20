#INCLUDE "Protheus.ch"
#include "topconn.ch"
//#include "rwmake.ch"

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³TMKCBPRO  ºAutor  ³MARCELO G. PEREIRA  º Data ³  04/10/04   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Adiciona um botao na barra de ferramentas do call center.   º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ TODAS VERSOES                                              º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
User Function MA030BUT()

	Local aBtnSup := {}
	// Executa gravação do Log de Uso da rotina
	//U_BFCFGM01()

	Aadd(aBtnSup,{"AMARELO",{||sfReceita()},"Consulta Receita" })
	
Return aBtnSup


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
	Local	cJson		:= ""
	Local	cQry		
	Local	cVarAux
	// Variável Lógica
	Local	lRetCep		:= .T. 
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


	If Type("oParseJSON:nome") <> "U"
		M->A1_NOME	:= Padr(NoAcento(Upper(oParseJSON:nome)),TamSX3("A1_NOME")[1])
	Endif

	If Type("oParseJSON:fantasia") <> "U"
		M->A1_NREDUZ	:= Padr(NoAcento(Upper(oParseJSON:fantasia)),TamSX3("A1_NREDUZ")[1])
	Endif

	If Type("oParseJSON:email") <> "U"
		M->A1_EMAIL	:= Padr(oParseJSON:email,TamSX3("A1_EMAIL")[1])
	Endif

	If Type("oParseJSON:cep") <> "U"
		M->A1_CEP	:= Padr(StrTran(StrTran(oParseJSON:cep,".",""),"-",""),TamSX3("A1_CEP")[1])
		lRetCep	:= U_BFCFGA04("M->A1_CEP")
		// Aciona gatilhos do campo CEP
		If ExistTrigger('A1_CEP')      
			RunTrigger(1,nil,nil,,'A1_CEP')
		Endif
	Endif


	If Type("oParseJSON:abertura") <> "U"
		M->A1_DTNASC	:= CTOD(oParseJSON:abertura)
	Endif

	// Se a validação do CEP não ocorreu, preenche os dados a partir da RECEITA 
	If !lRetCep
		If Type("oParseJSON:logradouro") <> "U" 
			M->A1_END	:= Padr(NoAcento(Upper(oParseJSON:logradouro)),TamSX3("A1_END")[1])
		Endif

		If Type("oParseJSON:numero") <> "U"	
			cVarAux		:= Alltrim(M->A1_END)
			M->A1_END	:= Padr(cVarAux + "," + NoAcento(Upper(oParseJSON:numero)),TamSX3("A1_END")[1])
		Endif

		If Type("oParseJSON:bairro") <> "U" 
			M->A1_BAIRRO	:= Padr(NoAcento(Upper(oParseJSON:bairro)),TamSX3("A1_BAIRRO")[1])
		Endif

		If Type("oParseJSON:complemento") <> "U" 
			M->A1_COMPLEM	:= Padr(NoAcento(Upper(oParseJSON:complemento)),TamSX3("A1_COMPLEM")[1])
		Endif

		If Type("oParseJSON:municipio") <> "U" 
			M->A1_MUN	:= Padr(NoAcento(Upper(oParseJSON:municipio)),TamSX3("A1_MUN")[1])
		Endif

		If Type("oParseJSON:uf") <> "U" 
			M->A1_EST	:= Padr(NoAcento(Upper(oParseJSON:uf)),TamSX3("A1_EST")[1])
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

			cVarAux			:= Alltrim(M->A1_BAIRRO)

			If Empty(cVarAux) .And. Type("oParseJSON:bairro") <> "U" 
				M->A1_BAIRRO	:= Padr(NoAcento(Upper(oParseJSON:bairro)),TamSX3("A1_BAIRRO")[1])
				M->A1_BAIRROE	:= Padr(NoAcento(Upper(oParseJSON:bairro)),TamSX3("A1_BAIRROE")[1])
				M->A1_BAIRROC	:= Padr(NoAcento(Upper(oParseJSON:bairro)),TamSX3("A1_BAIRROC")[1])
			Endif

		Endif
	Endif
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
