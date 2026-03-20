#Include "Protheus.ch"

/*/{Protheus.doc} PE01NFESEFAZ
	PE para manipulação das informações da NF
	@type function
	@version 1.0
	@author Daniel Scheeren - Gruppe
	@since 14/08/2023
	@return variant, return_description
	/*/
User Function PE01NFESEFAZ()

	Local aArea        	:= GetArea()
	Local aAreaSF2     	:= SF2->(GetArea())
	Local aAreaSD2     	:= SD2->(GetArea())
	Local aAreaSC5     	:= SC5->(GetArea())
	Local aAreaSC6     	:= SC6->(GetArea())
	Local aAreaSF4     	:= SF4->(GetArea())
	Local aRetorno		:= {}
	Local aProd     	:= ParamIXB[1]
	Local cMensCli  	:= ParamIXB[2]
	Local cMensFis  	:= ParamIXB[3]
	Local aDest     	:= ParamIXB[4]
	Local aNota     	:= ParamIXB[5]
	Local aInfoItem 	:= ParamIXB[6]
	Local aDupl     	:= ParamIXB[7]
	Local aTransp   	:= ParamIXB[8]
	Local aEntrega  	:= ParamIXB[9]
	Local aRetirada 	:= ParamIXB[10]
	Local aVeiculo  	:= ParamIXB[11]
	Local aReboque  	:= ParamIXB[12]
	Local aNfVincRur	:= ParamIXB[13]
	Local aEspVol     	:= ParamIXB[14]
	Local aNfVinc     	:= ParamIXB[15]
	Local aDetPag    	:= ParamIXB[16]
	Local oFunGenericas 
	
	// Integração LEXOS HUB - INICIO
	If U_LEXFilInt()
		oFunGenericas := LexosFnGenericas():New()
		
		oFunGenericas:AlteraCondPagNFCliente(aNota, aProd, @aDetPag, aDupl)

		oFunGenericas:AlteraEnderecoCliente(aNota, aProd, @aDest)
	EndIf	
	// Integração LEXOS HUB - FIM

	// Retorna dados manipulados.
	AAdd(aRetorno, aProd)
	AAdd(aRetorno, cMensCli)
	AAdd(aRetorno, cMensFis)
	AAdd(aRetorno, aDest)
	AAdd(aRetorno, aNota)
	AAdd(aRetorno, aInfoItem)
	AAdd(aRetorno, aDupl)
	AAdd(aRetorno, aTransp)
	AAdd(aRetorno, aEntrega)
	AAdd(aRetorno, aRetirada)
	AAdd(aRetorno, aVeiculo)
	AAdd(aRetorno, aReboque)
	AAdd(aRetorno, aNfVincRur)
	AAdd(aRetorno, aEspVol)
	AAdd(aRetorno, aNfVinc)
	AAdd(aRetorno, aDetPag)

	// retorna as areas das tabelas
	RestArea(aAreaSF2)
	RestArea(aAreaSD2)
	RestArea(aAreaSC5)
	RestArea(aAreaSC6)
	RestArea(aAreaSF4)
	RestArea(aArea)

Return aRetorno
