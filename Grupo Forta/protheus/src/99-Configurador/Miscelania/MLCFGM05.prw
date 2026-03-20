#include 'protheus.ch'
#include 'parmtype.ch'


/*/{Protheus.doc} MLCFGM05
//TODO Função para retornar códigos de motivos de Exclusão de Pedido / Nota ou Residuos 
@author marce
@since 19/02/2020
@version 1.0
@return ${return}, ${return_description}
@param lRetStr, logical, descricao
@type function
/*/
User Function MLCFGM05(lRetStr)

	Local	aArrayMOt	:= {}
	Local	cStrMot		:= ""
	Local	aAreaOld	:= GetArea()
	Local	cFilX5		:= xFilial("SX5")
	Local	cTblX5		:= Padr("XB",Len(SX5->X5_TABELA))
	Default	lRetStr		:= .F. 
	
	DbSelectArea("SX5")
	DbSetOrder(1)
	If DbSeek(xFilial("SX5")+"XB")
		While !Eof() .And. SX5->X5_FILIAL == cFilX5 .And. SX5->X5_TABELA == cTblX5
			Aadd(aArrayMOt,Alltrim(SX5->X5_CHAVE)+"="+Alltrim(SX5->X5_DESCRI))
			
			cStrMot	+= Alltrim(SX5->X5_CHAVE)+"="+Alltrim(SX5->X5_DESCRI)+";"
			
			SX5->(DbSkip())
		Enddo
	Endif

	RestArea(aAreaOld)

// Retorna em formato String ou Array 
Return IIf(lRetStr,cStrMot,aArrayMot)