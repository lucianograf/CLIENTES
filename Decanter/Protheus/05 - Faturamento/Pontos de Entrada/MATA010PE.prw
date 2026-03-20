#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} MATA010

Ponto de entrada em MVC na rotina de cadastro de produtos

@author charles.reitz
@since 04/06/2019
@version undefined

@return return, return_description
@example
(examples)
@see (links_or_references)
/*/
user function ITEM()
	Local aParam     := PARAMIXB
	Local xRet       := .T.
	Local oObj       := ''
	Local cIdPonto   := ''
	Local cIdModel   := ''
	Local lIsGrid    := .F.
	Local nLinha     := 0
	Local nQtdLinhas := 0
	Local cMsg       := ''
	Local nOperation	:=	0
	local cSQL := ""
	Local cQuery	:=	""
	Local oModelSB1

	If aParam <> NIL

		oObj       := aParam[1]
		cIdPonto   := aParam[2]
		cIdModel   := aParam[3]
		lIsGrid    := ( Len( aParam ) > 3 )

		//If lIsGrid
		//	nQtdLinhas := oObj:GetQtdLine()
		//	nLinha     := oObj:nLine
		//EndIf

		If     cIdPonto == 'MODELPOS'
			//cMsg := 'Chamada na validação total do modelo (MODELPOS).' + CRLF
			//cMsg += 'ID ' + cIdModel + CRLF

			//If !( xRet := ApMsgYesNo( cMsg + 'Continua ?' ) )
			//	Help( ,, 'Help',, 'O MODELPOS retornou .F.', 1, 0 )
			//EndIf

		ElseIf cIdPonto == 'FORMPOS'
			//cMsg := 'Chamada na validação total do formulário (FORMPOS).' + CRLF
			//cMsg += 'ID ' + cIdModel + CRLF

			//If      cClasse == 'FWFORMGRID'
			//	cMsg += 'É um FORMGRID com ' + Alltrim( Str( nQtdLinhas ) ) + ;
			//	'     linha(s).' + CRLF
			//	cMsg += 'Posicionado na linha ' + Alltrim( Str( nLinha     ) ) + CRLF
			//ElseIf cClasse == 'FWFORMFIELD'
			//	cMsg += 'É um FORMFIELD' + CRLF
			//EndIf

			//If !( xRet := ApMsgYesNo( cMsg + 'Continua ?' ) )
			//	Help( ,, 'Help',, 'O FORMPOS retornou .F.', 1, 0 )
			//EndIf
		ElseIf cIdPonto == 'MODELPRE'

			If oObj:IsCopy()
				oObj:LoadValue('SB1MASTER',"B1_ZDTCTMG",CriaVar("B1_ZDTCTMG",.F.))
				oObj:LoadValue('SB1MASTER',"B1_ZHRCTMG",CriaVar("B1_ZHRCTMG",.F.))
				oObj:LoadValue('SB1MASTER',"B1_ZMMSGIN","")
				oObj:LoadValue('SB1MASTER',"B1_ZATZDTM",CriaVar("B1_ZATZDTM",.F.))
				oObj:LoadValue('SB1MASTER',"B1_ZATZHRM",CriaVar("B1_ZATZHRM",.F.))
				oObj:LoadValue('SB1MASTER',"B1_ZIDMAGE",CriaVar("B1_ZIDMAGE",.F.))
				oObj:LoadValue('SB1MASTER',"B1_ZMAGSTS",CriaVar("B1_ZMAGSTS",.F.))
				oObj:LoadValue('SB1MASTER',"B1_ZMDTEXC",CriaVar("B1_ZMDTEXC",.F.))
			EndIf

		ElseIf cIdPonto == 'FORMLINEPRE'
			//If aParam[5] == 'DELETE'
			//	cMsg := 'Chamada na pre validação da linha do formulário (FORMLINEPRE).' + CRLF
			//	cMsg += 'Onde esta se tentando deletar uma linha' + CRLF
			//	cMsg += 'É um FORMGRID com ' + Alltrim( Str( nQtdLinhas ) ) +;
			//	' linha(s).' + CRLF
			//	cMsg += 'Posicionado na linha ' + Alltrim( Str( nLinha     ) ) +; CRLF
			//	cMsg += 'ID ' + cIdModel + CRLF

			//	If !( xRet := ApMsgYesNo( cMsg + 'Continua ?' ) )
			//		Help( ,, 'Help',, 'O FORMLINEPRE retornou .F.', 1, 0 )
			//	EndIf
			//EndIf

		ElseIf cIdPonto == 'FORMLINEPOS'
			//cMsg := 'Chamada na validação da linha do formulário (FORMLINEPOS).' +; CRLF
			//cMsg += 'ID ' + cIdModel + CRLF
			//cMsg += 'É um FORMGRID com ' + Alltrim( Str( nQtdLinhas ) ) + ;
			//' linha(s).' + CRLF
			//cMsg += 'Posicionado na linha ' + Alltrim( Str( nLinha     ) ) + CRLF

			//If !( xRet := ApMsgYesNo( cMsg + 'Continua ?' ) )
			//	Help( ,, 'Help',, 'O FORMLINEPOS retornou .F.', 1, 0 )
			//EndIf

		ElseIf cIdPonto == 'MODELCOMMITTTS'
			//ApMsgInfo('Chamada apos a gravação total do modelo e dentro da transação (MODELCOMMITTTS).' + CRLF + 'ID ' + cIdModel )

		//Chamada apos a gravação total do modelo e fora da transação (MODELCOMMITNTTS)
		ElseIf cIdPonto == 'MODELCOMMITNTTS'

		ElseIf cIdPonto == 'FORMCOMMITTTSPRE'

		ElseIf cIdPonto == 'FORMCOMMITTTSPOS'
			//ApMsgInfo('Chamada apos a gravação da tabela do formulário (FORMCOMMITTTSPOS).' + CRLF + 'ID ' + cIdModel)
		ElseIf cIdPonto == 'MODELCANCEL'
			//cMsg := 'Chamada no Botão Cancelar (MODELCANCEL).' + CRLF + 'Deseja Realmente Sair ?'

			//If !( xRet := ApMsgYesNo( cMsg ) )
			//	Help( ,, 'Help',, 'O MODELCANCEL retornou .F.', 1, 0 )
			//EndIf

		ElseIf cIdPonto == 'BUTTONBAR'
			//ApMsgInfo('Adicionando Botao na Barra de Botoes (BUTTONBAR).' + CRLF + 'ID ' + cIdModel )
			//xRet := { {'Salvar', 'SALVAR', { || Alert( 'Salvou' ) }, 'Este botao Salva' } }

		EndIf

	EndIf

Return xRet
