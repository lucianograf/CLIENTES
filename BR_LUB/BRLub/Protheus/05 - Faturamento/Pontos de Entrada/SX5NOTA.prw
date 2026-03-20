/*/{Protheus.doc} SX5NOTA
Ponto de entrada para validar série usada 
@type function
@version  
@author Marcelo Alberto Lauschner
@since 10/05/2022
@return variant, return_description
/*/
User Function SX5NOTA()

	Local	aAreaOld	:= GetArea()
	Local	lRet		:= .F.
	
	DbSelectArea("SX6")
	DbSetOrder(1)
	If !Dbseek(cFilAnt+"GM_SX5NOTA") .And. !DbSeek(Space(Len(cFilAnt))+"GM_SX5NOTA")
		RecLock("SX6",.T.)
		SX6->X6_FIL		:= cFilAnt
		SX6->X6_VAR		:= "GM_SX5NOTA"
		SX6->X6_TIPO	:= "C"
		SX6->X6_DESCRIC	:= "Usuário e séries liberados para faturamento"
		SX6->X6_DESC1	:= "Id usuário + / + Série "
		SX6->X6_DESC2	:= "Precisa cada usuário X Série"
		SX6->X6_CONTEUD	:= ""
		SX6->X6_PROPRI	:= "S"
		MsUnlock()
	Endif

	DbSelectArea("SX5")

	If __cUserId $ "000000"
		lRet	:= .T.
	ElseIf Alltrim(__cUserId)+"/"+Alltrim(SX5->X5_CHAVE) $ GetMv("GM_SX5NOTA") 
		lRet	:= .T.
	ElseIf Alltrim(SX5->X5_CHAVE) $ "1#2#3#4#5" 
		lRet	:= .T.
	Endif

	
	RestArea(aAreaOld)

Return lRet

