#include "totvs.ch"

User Function MLFATG04(nInOpc,cInIE,cInUF)

	Local   aAreaOld    := GetArea()
	Local   cRet        := ""


	If nInOpc == 1

	ElseIf nInOpc == 2


	Endif

	RestArea(aAreaOld)

Return cRet

Static Function sfConsCad(cIE,cUF)

	Local aAreaOld		:= GetArea()
	Local cURL     		:= PadR(GetNewPar("MV_SPEDURL","http://"),250)
	Local cIdEnt    	:= ""
	Local cRazSoci 		:= ""
	Local cRegApur    	:= ""
	Local cCnpj	      	:= ""
	Local cCpf	      	:= ""
	Local cSituacao   	:= ""
	Local cPictCNPJ		:= ""

	Local dIniAtiv    	:= Date()
	Local dAtualiza		:= Date()
	Local lRet			:= .T.
	Local nX	    	:= {}

	Private oWS

	cIdEnt		:=  U_MLTSSENT()


	oWs:= WsNFeSBra() :New()
	oWs:cUserToken    	:= "TOTVS"
	oWs:cID_ENT			:= cIdEnt
	oWs:cUF				:= cUF
	oWs:cCNPJ			:= ""
	oWs:cCPF			:= ""
	oWs:cIE				:= Alltrim(cIE)
	oWs:_URL          	:= AllTrim(cURL)+"/NFeSBRA.apw"

	If oWs:CONSULTACONTRIBUINTE()

		If Type("oWs:OWSCONSULTACONTRIBUINTERESULT:OWSNFECONSULTACONTRIBUINTE") <> "U"
			If ( Len(oWs:OWSCONSULTACONTRIBUINTERESULT:OWSNFECONSULTACONTRIBUINTE) > 0 )
				nX := Len(oWs:OWSCONSULTACONTRIBUINTERESULT:OWSNFECONSULTACONTRIBUINTE)

				If ValType(oWs:OWSCONSULTACONTRIBUINTERESULT:OWSNFECONSULTACONTRIBUINTE[nX]:dInicioAtividade) <> "U"
					dIniAtiv  := oWs:OWSCONSULTACONTRIBUINTERESULT:OWSNFECONSULTACONTRIBUINTE[nX]:dInicioAtividade
				Else
					dIniAtiv  := ""
				EndIf
				cRazSoci  	:= oWs:OWSCONSULTACONTRIBUINTERESULT:OWSNFECONSULTACONTRIBUINTE[nX]:cRazaoSocial
				cRegApur  	:= oWs:OWSCONSULTACONTRIBUINTERESULT:OWSNFECONSULTACONTRIBUINTE[nX]:cRegimeApuracao
				cCnpj	    := oWs:OWSCONSULTACONTRIBUINTERESULT:OWSNFECONSULTACONTRIBUINTE[nX]:cCNPJ
				cCpf	    := oWs:OWSCONSULTACONTRIBUINTERESULT:OWSNFECONSULTACONTRIBUINTE[nX]:cCPF
				cIe       	:= oWs:OWSCONSULTACONTRIBUINTERESULT:OWSNFECONSULTACONTRIBUINTE[nX]:cIE
				cUf	    	:= oWs:OWSCONSULTACONTRIBUINTERESULT:OWSNFECONSULTACONTRIBUINTE[nX]:cUF
				cSituacao 	:= oWs:OWSCONSULTACONTRIBUINTERESULT:OWSNFECONSULTACONTRIBUINTE[nX]:cSituacao

				If ValType(oWs:OWSCONSULTACONTRIBUINTERESULT:OWSNFECONSULTACONTRIBUINTE[nX]:dUltimaSituacao) <> "U"
					dAtualiza := oWs:OWSCONSULTACONTRIBUINTERESULT:OWSNFECONSULTACONTRIBUINTE[nX]:dUltimaSituacao
				Else
					dAtualiza := ""
				EndIf

				If ( cSituacao == "1" )
					cSituacao := "1 - Habilitado"
				ElseIf ( cSituacao == "0" )
					cSituacao := "0 - Não Habilitado"
				EndIf


				If ( !Empty(cCnpj) )
					cCnpj		:= cCnpj
					cPictCNPJ	:= "@R 99.999.999/9999-99"
				Else
					cCnpj		:= cCPF
					cPictCNPJ	:= "@R 999.999.999-99"
				EndIf


				If cSituacao == "0 - Não Habilitado"
					lRet	:= .F.

					If IsBlind()
						DEFINE MSDIALOG oDlgKey TITLE "Retorno do Consulta Contribuinte" FROM 0,0 TO 200,355 PIXEL OF GetWndDefault()  //"Retorno do Consulta Contribuinte"

						@ 008,010 SAY "Início das Atividades:"	 PIXEL  OF oDlgKey    	//"Início das Atividades:"
						@ 008,072 SAY If(Empty(dIniAtiv),"",DtoC(dIniAtiv))	 PIXEL OF oDlgKey
						@ 008,115 SAY "UF:" 		 PIXEL OF oDlgKey		//"UF:"
						@ 008,124 SAY cUf			 PIXEL OF oDlgKey
						@ 020,010 SAY "Razão Social:"		 PIXEL OF oDlgKey 		//"Razão Social:"
						@ 020,048 SAY cRazSoci		 PIXEL OF oDlgKey
						@ 032,010 SAY "CNPJ/CPF:"		 PIXEL OF oDlgKey  	//"CNPJ/CPF:"
						@ 032,040 SAY cCnpj		 PIXEL PICTURE cPictCNPJ OF oDlgKey
						@ 032,115 SAY "IE:"		 PIXEL OF oDlgKey  	//"IE:"
						@ 032,123 SAY cIe			 PIXEL OF oDlgKey
						@ 044,010 SAY "Regime:"		 PIXEL OF oDlgKey  	//"Regime:"
						@ 044,035 SAY cRegApur		 PIXEL OF oDlgKey
						@ 056,010 SAY "Situação:"		 PIXEL OF oDlgKey  	//"Situação:"
						@ 056,038 SAY cSituacao		 PIXEL OF oDlgKey
						@ 068,010 SAY "Atualizado em:"   	 PIXEL OF oDlgKey  	 //"Atualizado em:"
						@ 068,055 SAY If(Empty(dAtualiza),"",DtoC(dAtualiza))	 PIXEL OF oDlgKey

						@ 80,137 BUTTON oBtnCon PROMPT "Ok" SIZE 38,11 PIXEL ACTION oDlgKey:End()	//"Ok"

						ACTIVATE DIALOG oDlgKey CENTERED
					Endif
				EndIf
			EndIf
		Else
			//Aviso("SPED",IIf(Empty(GetWscError(3)),GetWscError(1),GetWscError(3)),{"Erro Sped TSS"},3)
		EndIf
	Endif
	RestArea(aAreaOld)
Return lRet
