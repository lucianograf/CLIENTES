#include 'protheus.ch'
#include 'parmtype.ch'
#INCLUDE 'FWMVCDEF.CH'

/*/{Protheus.doc} CTBA020
// Ponto de entrada para validar a Edição de Plano de Contas 
@author Marcelo Alberto Lauschner
@since 27/04/2019
@version 1.0
@return  lOk, Logical 
@type User Function
/*/
User function CTBA020()

	Local aParam 	:= ParamIXB
	Local cIDExec	:= ""
	Local cIDForm	:= ""
	Local lOk		:= .T.
	Local nOper		:= 0
	Local oModel	:= Nil
	Local cUserId   := RetCodUsr() 
	Local lIsGrid	:= .F. 
	Local cMsg		:= ""
	Local nLinha	:= 0
	Local nQtdLinhas := 0
	Local cClasse
	Begin Sequence
	
		If !Empty(aParam)
			oModel 	:= aParam[1]
			cIDExec := aParam[2]
			cIDForm	:= aParam[3]
			nOper 	:= oModel:GetOperation()


			
			If cIDExec  == "MODELPOS" .And. (nOper == 3 .Or. nOper == 4) 
				If IsBlind()	
					lOk	:= .T. 
				Else 
					If oModel:GetModel("CVDDETAIL"):IsEmpty()
						//cMsg += "Conta Referencial em Branco !" + CRLF

						//If !( lOk := ApMsgYesNo( cMsg + 'Continua ?' ) )
						lOk	:= .F. 
						Help( ,, 'Help',, 'Conta Referencial não informada', 1, 0 )
						//EndIf
					ElseIf Empty(oModel:GetValue("CVDDETAIL","CVD_CTAREF")) 
						//cMsg += "Conta Referencial Deletada!" + CRLF

						//If !( lOk := ApMsgYesNo( cMsg + 'Continua ?' ) )
						lOk	:= .F. 
						Help( ,, 'Help',, 'O FORMPOS retornou .F.', 1, 0 )
						//EndIf
					Endif

				Endif
			Endif

			If cIDExec == "FORMPOS" .And. (nOper == 3 .Or. nOper == 4) .And. !IsBlind()

				cClasse := oModel:ClassName() 

				If cClasse == 'FWFORMGRID' .And. cIDForm == "CVDDETAIL" 
				///	cMsg := 'Chamada na validação total do formulário (FORMPOS).' + CRLF
				//	cMsg += 'ID ' + cIDForm + CRLF
				//	cMsg += 'É um FORMGRID com ' + Alltrim( Str( oModel:Length(.T.) ) ) + ;
				//	' linha(s).' + CRLF
				//	cMsg += 'Posicionado na linha ' + Alltrim( Str( oModel:GetLine() ) ) + CRLF

					If Empty(oModel:GetValue("CVD_CTAREF")) .And. !oModel:IsDeleted(oModel:GetLine()) .And. M->CT1_CLASSE <> "1"
					//	cMsg += "Conta Referencial em Branco !" + CRLF

					//	If !( lOk := ApMsgYesNo( cMsg + 'Continua ?' ) )
						lOk	:= .F. 
						Help( ,, 'Help',, 'Não há cadastro de Plano de Contas Referencial', 1, 0 )
					//	EndIf
					ElseIf oModel:Length(.T.) <= 0 .And. M->CT1_CLASSE <> "1"
						//cMsg	+= "Linha deletada!" + CRLF

						//If !( lOk := ApMsgYesNo( cMsg + 'Continua ?' ) )
							lOk	:= .F. 
							Help( ,, 'Help',, 'Não há cadastro de Plano de Contas Referencial', 1, 0 )
						//EndIf
					Endif

				EndIf


			EndIf
		EndIf

	End Sequence

Return lOk
