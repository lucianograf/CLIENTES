#include 'protheus.ch'
#include 'parmtype.ch'


/*/{Protheus.doc} MT103SE2
//TODO Ponto de Entrada para adicionar campos no Getdados de Duplicatas do Documento de entrada.
@author Marcelo Alberto Lauschner 
@since 22/01/2020
@version 1.0
@return aCpoRet, Array com os dados dos campos que serão adicinados ao aCols do Contas a Pagar

@type function
/*/
User function MT103SE2()
	//aHeadSE2,lVisual
	Local	aCpoRet		:= {}
	Local	aAreaOld	:= GetArea()
	Local	aCpoSE2 := {{"E2_HIST",".T.",".T."}} // X3_CAMPO - X3_VALID  - X3_WHEN

	DbSelectArea("SX3")
	SX3->(dbSetOrder(2))

	For nX := 1 To Len(aCpoSE2)
		If SX3->(MsSeek(aCpoSE2[nX,1]))
			AADD(aCpoRet,{TRIM(x3titulo()),;
			SX3->X3_CAMPO,;
			SX3->X3_PICTURE,;
			SX3->X3_TAMANHO,;
			SX3->X3_DECIMAL,;
			aCpoSE2[nX,2],;
			SX3->X3_USADO,;
			SX3->X3_TIPO,;
			SX3->X3_F3,;
			SX3->X3_CONTEXT,;
			SX3->X3_CBOX,;
			SX3->X3_RELACAO,;
			aCpoSE2[nX,3]})
		EndIf
	Next nX
	
	RestArea(aAreaOld)

Return aCpoRet
