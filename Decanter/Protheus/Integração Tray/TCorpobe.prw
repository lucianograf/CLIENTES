#Include 'Protheus.ch'

/*/{Protheus.doc} TCorpobe
Retorna a descrição do corpo baseado no registro da ficha tecnica.
@type  Function
@author Anderson - Vamilly
@since 07/09/2023
@version 1.0
@Cliente Decanter
/*/

User Function TCorpobe(cCod)
	Local cCorpo := POSICIONE('ZFT', 1, XFILIAL('ZFT') + cCod, 'ZFT_CORPO')
	Local cRet   := ''

	If cCorpo == '1'
		cRet := 'Corpo leve'
	ElseIf cCorpo == '2'
		cRet := 'Corpo medio'
	ElseIf cCorpo == '3'
		cRet := 'Encorpado'
	Endif

Return cRet

User Function TClassif(cCod)

	Local cClassi := POSICIONE('ZFT', 1, XFILIAL('ZFT') + cCod, 'ZFT_CLASSI')
	Local cRet := ''

	If cClassi == '33'
		cRet := 'Cocktail'
	ElseIf cClassi == '34'
		cRet := 'Branco Brut'
	ElseIf cClassi == '35'
		cRet := 'Rose Brut'
	ElseIf cClassi == '36'
		cRet := 'Branco Demi Sec'
	ElseIf cClassi == '37'
		cRet := 'Branco Moscatel'
	ElseIf cClassi == '38'
		cRet := 'Branco Nature'
	ElseIf cClassi == '39'
		cRet := 'Rose Nature'
	ElseIf cClassi == '40'
		cRet := 'Tintos'
	ElseIf cClassi == '41'
		cRet := 'Brancos'
	ElseIf cClassi == '42'
		cRet := 'Roses'

	Endif


Return cRet
