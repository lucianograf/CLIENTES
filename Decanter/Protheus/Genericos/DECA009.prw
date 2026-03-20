#include 'protheus.ch'
#include 'parmtype.ch'
#Include 'FWMVCDEF.ch'

/*/{Protheus.doc} function_method_class_name

Inclusão e Alteração do cadastro de CEP

@author CHARLES REITZ
@since 14/06/2019
@version version
parametersSection
@return return, return_description
@example
(examples)
@see (links_or_references)
/*/
user function DECA009()

	Local oBrowse

	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias("Z05")
	oBrowse:SetDescription('CEP´s')
	oBrowse:SetMenuDef("DECA009")
	oBrowse:Activate()

return

Static Function MenuDef()

	Private aRotina := {}

	ADD OPTION aRotina TITLE 'Visualizar' ACTION 'VIEWDEF.DECA009' OPERATION 2 ACCESS 0
	ADD OPTION aRotina TITLE 'Incluir'    ACTION 'VIEWDEF.DECA009' OPERATION 3 ACCESS 0
	ADD OPTION aRotina TITLE 'Alterar'    ACTION 'VIEWDEF.DECA009' OPERATION 4 ACCESS 0
	ADD OPTION aRotina TITLE 'Excluir'    ACTION 'VIEWDEF.DECA009' OPERATION 5 ACCESS 0
	ADD OPTION aRotina TITLE 'Imprimir'   ACTION 'VIEWDEF.DECA009' OPERATION 8 ACCESS 0
	ADD OPTION aRotina TITLE 'Copiar'     ACTION 'VIEWDEF.DECA009' OPERATION 9 ACCESS 0

Return aRotina

Static Function ModelDef()

	Local oModel
	Local oStruZ05 := FWFormStruct(1,"Z05")

	oModel := MPFormModel():New("DECA009M")
	oModel:addFields('FORMZ05',,oStruZ05)
	oModel:SetPrimaryKey({'Z05_FILIAL','Z05_CODIGO'})
	oModel:SetDescription("Modelo de Dados do Cadatro de Uvas")
	//oModel:getModel('FORMZ05'):SetDescription('Cadastro de CEP´s')

Return oModel

Static Function ViewDef()

	Local oModel := ModelDef()//FwLoadModel()
	Local oView
	Local oStrZ05:= FWFormStruct(2, 'Z05')

	oView := FWFormView():New()
	oView:SetModel(oModel)
	oView:AddField('VIEW_Z05',oStrZ05,'FORMZ05' )
	oView:CreateHorizontalBox( 'UVA', 100)
	oView:SetOwnerView('VIEW_Z05','UVA')

Return oView

/*/{Protheus.doc} A009Get

Preenche os dados do campod e cep

@author charles.totvs
@since 14/06/2019
@version undefined
@example
(examples)
@see (links_or_references)
/*/
User Function A009Get(cAliFin)
	Local lRet 	:=	.F.
	Local cCep	:= ""
	Default cAliFin := "SA1"

	Begin Sequence

		If cAliFin == "SA1"
			cCep	:=	STRTRAN(M->A1_CEP, '-', '')
		Else
			cCep	:=	STRTRAN(M->A2_CEP, '-', '')
		EndIf

		dbSelectArea("Z05")
		dbSetOrder(1)
		if !MsSeek(cCep)
			//Help(NIL, NIL, "CEP", NIL, "Não localizado o CEP Informado", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Informe um CEP válido"})
			//Break
		EndIf

		dbSelectArea("CC2")
		dbSetOrder(1)
		if !MsSeek(FWXFilial("CC2")+Z05->Z05_ESTADO+Right(Z05->Z05_CODIBG,5))
			//Help(NIL, NIL, "CEP", NIL, "Não localizado código do IBGE na tabela do sistema", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Verifique no cadastro de CEP se a informação do código do municipio está correta"})
			//Break
		EndIf

		dbSelectArea("Z05")
		dbSetOrder(1)
		if !DbSeek(cCep)

			If cAliFin == "SA1"

				MsAguarde({||  lRet	:=	sfCep(M->A1_CEP,{"M->A1_END","M->A1_BAIRRO","M->A1_MUN","M->A1_EST","M->A1_IBGE","M->A1_COD_MUN","M->A1_COMPLEM","",""},;
					{"M->A1_ENDCOB","M->A1_BAIRROC","M->A1_MUNC","M->A1_ESTC","","","","A1_CEPC"},;
					{"M->A1_ENDENT","M->A1_BAIRROE","M->A1_MUNE","M->A1_ESTE","","","","M->A1_CEPE"})},;
					"Aguarde!", "Aguarde a localização dos dados informados!")
				//	M->A1_EST		:= 'SC'
				//		M->A1_END		:= 'ENDERECO PADRAO'
				//		M->A1_MUN		:= 'CIDADE PADRAO'
				//		M->A1_BAIRRO	:= 'BAIRRO PADRAO'
				//		M->A1_COD_MUN	:= '02404
			Else
				MsAguarde({||  lRet	:=	sfCep(M->A2_CEP,{"M->A2_END","M->A2_BAIRRO","M->A2_MUN","M->A2_EST","M->A2_IBGE","M->A2_COD_MUN","M->A2_COMPLEM","",""})},;
					"Aguarde!", "Aguarde a localização dos dados informados!")


				//		M->A2_EST		:= 'SC'
				//		M->A2_END		:= 'ENDERECO PADRAO'
				//		M->A2_MUN		:= 'CIDADE PADRAO'
				//		M->A2_BAIRRO	:= 'BAIRRO PADRAO'
				//		M->A2_COD_MUN	:= '02404'
			EndIf

		ELSE

			If cAliFin == "SA1"
				M->A1_EST		:= Z05->Z05_ESTADO
				If !Empty(Z05->Z05_ENDERE)
					M->A1_END		:= Padr(Z05->Z05_ENDERE,GetSX3Cache("A1_END","X3_TAMANHO"))
				Endif 
				If !Empty(Z05->Z05_CIDADE)
					M->A1_MUN		:= Padr(Z05->Z05_CIDADE,GetSX3Cache("A1_MUN","X3_TAMANHO"))
				Endif 
				If !Empty(Z05->Z05_BAIRRO)
					M->A1_BAIRRO	:= Padr(Z05->Z05_BAIRRO,GetSX3Cache("A1_BAIRRO","X3_TAMANHO"))
				Endif 
				M->A1_COD_MUN	:= CC2->CC2_CODMUN
			Else
				M->A2_EST		:= Z05->Z05_ESTADO
				If !Empty(Z05->Z05_ENDERE)
					M->A2_END		:= Padr(Z05->Z05_ENDERE,GetSX3Cache("A2_END","X3_TAMANHO"))
				Endif 
				If !Empty(Z05->Z05_CIDADE)
					M->A2_MUN		:= Padr(Z05->Z05_CIDADE,GetSX3Cache("A2_MUN","X3_TAMANHO"))
				Endif 
				If !Empty(Z05->Z05_BAIRRO)
					M->A2_BAIRRO	:= Padr(Z05->Z05_BAIRRO,GetSX3Cache("A2_BAIRRO","X3_TAMANHO"))
				Endif 
				M->A2_COD_MUN	:= CC2->CC2_CODMUN
			EndIf

		EndIf
		lRet	:=	.T.
	End Sequence

Return lRet

/*/{Protheus.doc} Z05CDIBG

Valida campo código de IBGE

@author TSCB57 - William Farias
@since 17/07/2019
@version 1.0
/*/
User Function Z05CDIBG()

	Local aArea		:= GetArea()
	Local lRet		:= .F.
	Local oMdlZ05	:= fwModelActive()
	Local oZ05Mast	:= oMdlZ05:getModel("FORMZ05")
	Local nPosCodEst := 0
	Local cEstado	:= ""
	Local cCodEst	:= ""
	Local aCodEst	:= {{"AC"	,	"12"},;
		{"AL"	,	"27"},;
		{"AP"	,	"16"},;
		{"AM"	,	"13"},;
		{"BA"	,	"29"},;
		{"CE"	,	"23"},;
		{"DF"	,	"53"},;
		{"ES"	,	"32"},;
		{"GO"	,	"52"},;
		{"MA"	,	"21"},;
		{"MT"	,	"51"},;
		{"MS"	,	"50"},;
		{"MG"	,	"31"},;
		{"PA"	,	"15"},;
		{"PB"	,	"25"},;
		{"PR"	,	"41"},;
		{"PE"	,	"26"},;
		{"PI"	,	"22"},;
		{"RR"	,	"14"},;
		{"RO"	,	"11"},;
		{"RJ"	,	"33"},;
		{"RN"	,	"24"},;
		{"RS"	,	"43"},;
		{"SC"	,	"42"},;
		{"SP"	,	"35"},;
		{"SE"	,	"28"},;
		{"TO"	,	"17"} }
	Begin Sequence
		If Inclui .Or. Altera
			//Carrega e verifica o estado.
			cEstado	:= oZ05Mast:getValue("Z05_ESTADO")
			If Empty(cEstado)
				MsgAlert("Campo Estado não deve estar em branco, verifique!")
				Break
			EndIf
			nPosCodEst	:= Ascan( aCodEst,{ |X| UPPER( AllTrim(X[1]) ) == cEstado } )
			If nPosCodEst <> 0
				cCodEst := alltrim(aCodEst[nPosCodEst][2])
			Else
				MsgAlert("Não encontrado código do estado informado: "+cEstado)
				Break
			EndIf
			//Carrega os dados do código IBGE.
			cCodMunIbg := alltrim(oZ05Mast:getValue("Z05_CODIBG"))
			If Empty(cCodMunIbg)
				MsgAlert("Campo Cód. IBGE não deve estar em branco, verifique!")
				Break
			EndIf
			If Len(cCodMunIbg) <> 5
				MsgAlert("O Cód. IBGE informado deve possuir 5 dígitos, verifique!")
				Break
			EndIf
			oZ05Mast:loadValue("Z05_CODIBG", cCodEst+cCodMunIbg)
			lRet := .T.
		EndIf
	End Sequence

	RestArea(aArea)

Return lRet




Static Function sfCep(cCep,aArray,aArray2,aArray3)

	Local	aAreaOld	:= GetArea()
	Local	cUrlGet		:= "http://viacep.com.br/ws/"+ Alltrim(StrTran(cCep,"-","")) + "/piped"
	Local	cCepRet		:= ""
	Local	aCepRet		:= {}
	Local	nZ
	Local	nPosAux		:= 0
	Local	cVarAux		:= ""
	Local	lGrava		:= .F.
	Local	cMensagem	:= ""
	Local	cRecebe		:= ""
	Local	cAssunto	:= ""
	Default	aArray		:= {"","","","","","","","",""}
	Default	aArray2		:= {"","","","","","","",""}
	Default	aArray3		:= {"","","","","","","",""}


	//cep:89066-000|logradouro:Rua Doutor Pedro Zimmermann|complemento:de 1452 a 2600 - lado par|bairro:Itoupavazinha|localidade:Blumenau|uf:SC|unidade:|ibge:4202404|gia:

	//cCepRet	:= HttpGet(cUrlGet)
	//HTTPSGet( < cURL >, < cCertificate >, < cPrivKey >, < cPassword >, [ cGETParms ], [ nTimeOut ], [ aHeadStr ], [ @cHeaderRet ], [ lClient ] )
	cCepRet := HTTPGet( cUrlGet )


	//MsgAlert(cUrlGet + "|" + cCepRet)

	If Substr(cCep,6,3) $ "899#"
		// Força pegar o CEP da Agência dos correios da Cidade
		If (Empty(cCepRet) .Or. "erro:true" $ cCepRet .Or. Empty(cCep))
			cCepRet := HTTPGet( "http://viacep.com.br/ws/"+ Alltrim(StrTran(Substr(cCep,1,5)+"970","-","")) + "/piped" )
			cCepRet	:= StrTran(cCepRet,"-970","-899")
			cCepRet	:= StrTran(cCepRet,"logradouro:","lgrd:")
		Endif
	ElseIf (Empty(cCepRet) .Or. "erro:true" $ cCepRet .Or. Empty(cCep))

		MsgInfo("Código de Endereçamento Postal '" + cCep + "' informado não existe na Base dos Correios! Favor Verifique'",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))

		Return .F.
	Endif
	cCepRet	:= sfDecodeUtf(cCepRet)
	cCepRet	:= sfNoAcento(cCepRet)

	aCepRet	:= StrTokArr(cCepRet,"|")

	If Len(aCepRet) < 8

		MsgInfo("Código de Endereçamento Postal '" + cCep + "' informado não existe na Base dos Correios! Favor Verifique'" + CRLF + cCepRet,ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))

		Return .F.
	Endif

	// Verifica se atualiza automático a Z05
	If GetNewPar("DC_ATUZ05",.T.)
		DbSelectArea("Z05")
		DbSetOrder(1)
		If dbSeek( xFilial("Z05") + cCep )
			lGrava	:= .F.
		Else
			lGrava	:= .T.
		Endif

		DbSelectArea("Z05")
		RecLock("Z05",lGrava)

		For nZ 	:= 1 To Len(aCepRet)
			nPosAux	:= At(":",aCepRet[nZ])
			cVarAux	:= Upper(Substr(aCepRet[nZ],nPosAux+1))

			If "cep:" $ aCepRet[nZ]
				cVarAux	:= StrTran(cVarAux,"-","")
				Z05->Z05_CEP	:= AllTrim(cVarAux)
			ElseIf "logradouro:" $ aCepRet[nZ]
				Z05->Z05_ENDERE	:= AllTrim(cVarAux)
			ElseIf "complemento:" $ aCepRet[nZ]
			ElseIf "bairro:" $ aCepRet[nZ]
				Z05->Z05_BAIRRO	:= AllTrim(cVarAux)
			ElseIf "localidade:" $ aCepRet[nZ]
			ElseIf "uf:" $ aCepRet[nZ]
				Z05->Z05_ESTADO		:= AllTrim(cVarAux)
			ElseIf "unidade:" $ aCepRet[nZ]

			ElseIf "ibge:" $ aCepRet[nZ]
				Z05->Z05_CODIBG	:= AllTrim(cVarAux)
			Endif
		Next Nz
		MsUnlock()
	Endif 

	For nZ 	:= 1 To Len(aCepRet)
		nPosAux	:= At(":",aCepRet[nZ])
		cVarAux	:= Upper(Substr(aCepRet[nZ],nPosAux+1))

		If "cep:" $ aCepRet[nZ]
			cVarAux	:= StrTran(cVarAux,"-","")
			If !Empty(aArray[8])
				&(aArray[8])    := PadR(AllTrim(cVarAux),Len(&(aArray[8])))
			Endif
			If !Empty(aArray2[8])
				&(aArray2[8])    := PadR(AllTrim(cVarAux),Len(&(aArray2[8])))
			Endif
			If !Empty(aArray3[8])
				&(aArray3[8])    := PadR(AllTrim(cVarAux),Len(&(aArray3[8])))
			Endif
		ElseIf "logradouro:" $ aCepRet[nZ]
			If !Empty(aArray[1])
				&(aArray[1])    := IIF(Empty(&(aArray[1])).Or. !Empty(cVarAux),PadR(AllTrim(cVarAux),Len(&(aArray[1]))),&(aArray[1]))
			Endif
			If !Empty(aArray2[1])
				&(aArray2[1])    := IIF(Empty(&(aArray2[1])).Or. !Empty(cVarAux),PadR(AllTrim(cVarAux),Len(&(aArray2[1]))),&(aArray2[1]))
			Endif
			If !Empty(aArray3[1])
				&(aArray3[1])    := IIF(Empty(&(aArray3[1])).Or. !Empty(cVarAux),PadR(AllTrim(cVarAux),Len(&(aArray3[1]))),&(aArray3[1]))
			Endif
		ElseIf "complemento:" $ aCepRet[nZ]
			If !Empty(aArray[7])
				&(aArray[7])    := IIF(Empty(&(aArray[7])) .Or. !Empty(cVarAux) ,PadR(AllTrim(cVarAux),Len(&(aArray[7]))),&(aArray[7]))
			Endif
			If !Empty(aArray2[7])
				&(aArray2[7])    := IIF(Empty(&(aArray2[7])) .Or. !Empty(cVarAux) ,PadR(AllTrim(cVarAux),Len(&(aArray2[7]))),&(aArray2[7]))
			Endif
			If !Empty(aArray3[7])
				&(aArray3[7])    := IIF(Empty(&(aArray3[7])) .Or. !Empty(cVarAux),PadR(AllTrim(cVarAux),Len(&(aArray3[7]))),&(aArray3[7]))
			Endif
		ElseIf "bairro:" $ aCepRet[nZ]
			If !Empty(aArray[2])
				&(aArray[2])    := IIF(Empty(&(aArray[2])) .Or. !Empty(cVarAux),PadR(AllTrim(cVarAux),Len(&(aArray[2]))),&(aArray[2]))
			Endif
			If !Empty(aArray2[2])
				&(aArray2[2])    := IIF(Empty(&(aArray2[2])) .Or. !Empty(cVarAux) ,PadR(AllTrim(cVarAux),Len(&(aArray2[2]))),&(aArray2[2]))
			Endif
			If !Empty(aArray3[2])
				&(aArray3[2])    := IIF(Empty(&(aArray3[2])).Or. !Empty(cVarAux) ,PadR(AllTrim(cVarAux),Len(&(aArray3[2]))),&(aArray3[2]))
			Endif
		ElseIf "localidade:" $ aCepRet[nZ]
			If !Empty(aArray[3])
				&(aArray[3])    := PadR(AllTrim(cVarAux),Len(&(aArray[3])))
			Endif
			If !Empty(aArray2[3])
				&(aArray2[3])    := PadR(AllTrim(cVarAux),Len(&(aArray2[3])))
			Endif
			If !Empty(aArray3[3])
				&(aArray3[3])    := PadR(AllTrim(cVarAux),Len(&(aArray3[3])))
			Endif
		ElseIf "uf:" $ aCepRet[nZ]
			If !Empty(aArray[4])
				&(aArray[4])    := PadR(AllTrim(cVarAux),Len(&(aArray[4])))
			Endif
			If !Empty(aArray2[4])
				&(aArray2[4])    := PadR(AllTrim(cVarAux),Len(&(aArray2[4])))
			Endif
			If !Empty(aArray3[4])
				&(aArray3[4])    := PadR(AllTrim(cVarAux),Len(&(aArray3[4])))
			Endif
		ElseIf "unidade:" $ aCepRet[nZ]

		ElseIf "ibge:" $ aCepRet[nZ]
			If !Empty(aArray[5])
				&(aArray[5])    := PadR(AllTrim(cVarAux),Len(&(aArray[5])))
			Endif
			If !Empty(aArray[6])
				// Verifica se o Munícipio está cadastrado
				DbSelectArea("CC2")
				DbSetOrder(1)
				If DbSeek(xFilial("CC2")+&(aArray[4])+ Substr(cVarAux,3))
					&(aArray[6])    := PadR(AllTrim(Substr(cVarAux,3)),Len(&(aArray[6])))
				Else
					cRecebe		:= "marcelo@centralxml.com.br"
					cAssunto	:= "Cadastro de Municipios "+Substr(cVarAux,3)+" inexistente. Cidade "+ &(aArray[3])
					cMensagem	:= "Cadastro de Municipios "+Substr(cVarAux,3)+" inexistente. Cidade "+ &(aArray[3])
					MsgAlert(cMensagem, ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
					//sfSendMail( cRecebe, cAssunto, cMensagem, .F./*lExibSend*/, /*cArqAttAch*/, /*cAttachName*/ )
				Endif
			Endif
		Endif
	Next Nz

	RestArea(aAreaOld)

Return .T.


Static Function sfNoAcento(cString)

	Local cChar  := ""
	Local nX     := 0
	Local nY     := 0
	Local cVogal := "aeiouAEIOU"
	Local cAgudo := "áéíóú"+"ÁÉÍÓÚ"
	Local cCircu := "âêîôû"+"ÂÊÎÔÛ"
	Local cTrema := "äëïöü"+"ÄËÏÖÜ"
	Local cCrase := "àèìòù"+"ÀÈÌÒÙ"
	Local cTio   := "ãõÃÕ"
	Local cCecid := "çÇ"
	Local cMaior := "&lt;"
	Local cMenor := "&gt;"



	For nX:= 1 To Len(cString)
		cChar:=SubStr(cString, nX, 1)
		IF cChar$cAgudo+cCircu+cTrema+cCecid+cTio+cCrase
			nY:= At(cChar,cAgudo)
			If nY > 0
				//MsgAlert(cValToChar(nY) + "|"+ cChar+"|"+SubStr(cVogal,nY,1),cAgudo)
				cString := StrTran(cString,cChar,SubStr(cVogal,nY,1))
			EndIf
			nY:= At(cChar,cCircu)
			If nY > 0
				//MsgAlert(cValToChar(nY) + "|"+ cChar+"|"+SubStr(cVogal,nY,1),cCircu)
				cString := StrTran(cString,cChar,SubStr(cVogal,nY,1))
			EndIf
			nY:= At(cChar,cTrema)
			If nY > 0
				//MsgAlert(cValToChar(nY) + "|"+ cChar+"|"+SubStr(cVogal,nY,1),cTrema)
				cString := StrTran(cString,cChar,SubStr(cVogal,nY,1))
			EndIf
			nY:= At(cChar,cCrase)
			If nY > 0
				//MsgAlert(cValToChar(nY) + "|"+ cChar+"|"+SubStr(cVogal,nY,1),cCrase)
				cString := StrTran(cString,cChar,SubStr(cVogal,nY,1))
			EndIf
			nY:= At(cChar,cTio)
			If nY > 0
				//MsgAlert(cValToChar(nY) + "|"+ cChar+"|"+SubStr("aoAO",nY,1),cTio)
				cString := StrTran(cString,cChar,SubStr("aoAO",nY,1))
			EndIf
			nY:= At(cChar,cCecid)
			If nY > 0
				cString := StrTran(cString,cChar,SubStr("cC",nY,1))
			EndIf
		Endif
	Next

	If cMaior$ cString
		cString := strTran( cString, cMaior, "" )
	EndIf
	If cMenor$ cString
		cString := strTran( cString, cMenor, "" )
	EndIf

	cString := StrTran( cString, CRLF, " " )

	For nX:=1 To Len(cString)
		cChar:=SubStr(cString, nX, 1)
		If (Asc(cChar) < 32 .Or. Asc(cChar) > 123) .and. !cChar $ '|'
			cString:=StrTran(cString,cChar,".")
		Endif
	Next nX
Return cString

Static Function sfDecodeUtf(xString)
	//cep:89041-003|logradouro:Rua General OsÃ³rio|complemento:de 751 a 1799 - lado Ã­mpar|bairro:Velha|localidade:Blumenau|uf:SC|unidade:|ibge:4202404|gia:

	Local	cBuffer		:= ""  //Ã‰ Ã€ Ãü Ãë Ãç
	Local	aAcento		:= {"á" , "à", "â", "ã", "ä", "é", "è", "ê", "ë", "í", "ì", "î", "ï", "ó", "ò", "ô", "õ", "ö", "ú", "ù", "û", "ü", "ç","Á", "À", "Â", "Ã", "Ä", "É", "È", "Ê", "Ë" , "Í" ,"Í"			, "Ì" , "Î","Ï" ,"Ó", "Ò" , "Ô", "Õ", "Ö","Ú" ,"Ù" ,"Û", "Ü" ,"Ç"          , "Ç" ,"Á" ,"É" ,"Ç"	 ,"Á"				,"Ã"  ,"Õ" ,"Á"  ," "	}
	Local	aUtf8 		:= {"Ã¡","Ã ","Ã¢","Ã£","Ã¤","Ã©","Ã¨","Ãª","Ã«","Ã­","Ã¬","Ã®","Ã¯","Ã³","Ã²","Ã´","Ãµ","Ã¶","Ãº","Ã¹","Ã»","Ã¼","Ã§","Ã?","Ã€","Ã‚","Ãƒ","Ã„","Ã‰","Ãˆ","ÃŠ","Ã‹","Ã?" ,"Ã"+chr(141), "ÃŒ","ÃŽ","Ã?","Ã“","Ã’","Ã”","Ã•","Ã–","Ãš","Ã™","Ã›","Ãœ","Ç"+Chr(135) , "Ã‡","Ãü","Ãë","Ãç" ,"Ã"+chr(129)+"S"  ,"Ãâ", "Ãò","Ãü",""	}
	Local	iC,iU
	Local	lExistUtf8	:= .F.

	Aadd(aAcento,"É" )
	Aadd(aUtf8  ,"Ã‰")

	Aadd(aAcento,"Á")
	Aadd(aUtf8  ,"Ã" + Chr(129))

	//0xA0 0x20 0x4b 0x4D

	Do Case
	Case ValType(xString) == "C"
		For iC := 1 To Len(xString)
			lExistUtf8		:= .F.
			For iU := 1 To Len(aAcento)
				If Substr(xString,iC,2) == aUtf8[iU]
					cBuffer	+= aAcento[iU]
					lExistUtf8		:= .T.
					iC++ // Acrescenta 1 ao contador por que são 2 caracteres substituidos
				Endif
			Next
			If !lExistUtf8
				cBuffer	+= Substr(xString,iC,1)
			Endif
		Next
	Case ValType(xString) == "N"
		cBuffer	:= Str(xString)
	EndCase
	//If lIsDebug
	//	Aviso(ProcName(1)+ "." + ProcName(0)+"."+ Alltrim(Str(ProcLine(0))),cBuffer,{"Ok"},3)
	//Endif

Return cBuffer
