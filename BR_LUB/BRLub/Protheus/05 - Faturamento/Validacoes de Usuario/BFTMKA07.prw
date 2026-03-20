#Include 'Protheus.ch'
#include 'topconn.ch'

/*/{Protheus.doc} BFTMKA07
(Unifica a função num só lugar - afins de que várias consultas no sistema sempre busquem da mesma função)
	
@author MarceloLauschner
@since 30/01/2014
@version 1.0
		
@param cInCodCli, character, (Descrição do parâmetro)
@param cInCodLoj, character, (Descrição do parâmetro)
@param cInCodProd, character, (Descrição do parâmetro)

@return numerico, Valor do reembolso de tampa 

@example
(examples)

@see (links_or_references)
/*/
User Function BFTMKA07(cInCodCli,cInCodLoj,cInCodProd,cREEMB,cInTes,cZ8VLRSEQ,nTpRet)

	Local		aAreaOld	:= GetArea()
	Local		nValRet 	:= 0
	Local		nValImp		:= 0
	Local		cQro		:= ""
	Default	cREEMB			:= IIf(Type("M->C5_REEMB")<>"U",M->C5_REEMB,IIf(Type("M->UA_REEMB")<>"U",M->UA_REEMB," "))
	Default cZ8VLRSEQ		:= ""	
	Default	cInTes			:= ""
	Default	nTpRet			:= 1	// 1-Apenas valor 2-Apenas %custo adicional 3-Array[1,2]
		
	If !Empty(cInCodCli+cInCodLoj) .And. cREEMB $ "T#W#P" // T=Customizado Texaco W=Customizado Wynns P=Padrao Texaco S=Sim (Compatibilização)
		DbSelectArea("SA1")
		DbSetOrder(1)
		If DbSeek(xFilial("SA1")+cInCodCli+cInCodLoj)
			
			If cREEMB == "P" .And. SA1->A1_REEMB == "P" //P=Padrao Texaco 
				cQro := ""
				cQro += "SELECT " + Iif(Empty(cZ8VLRSEQ),"Z8_VALOR","Z8_VLR"+cZ8VLRSEQ ) + " Z8_VALOR,Z8_PONTOS "
				cQro += "  FROM " + RetSqlName("SZ8")
				cQro += " WHERE D_E_L_E_T_ = ' ' "
				cQro += "   AND Z8_FILIAL = '" + xFilial("SZ8") + "' "
				cQro += "   AND Z8_REEMB = 'P' "
				cQro += "   AND Z8_CODPROD = '" + cInCodProd + "' "
				cQro += "   AND '" + DTOS(dDataBase) + "' BETWEEN  Z8_DATCAD AND Z8_DATFIM "
			ElseIf cREEMB == "T" .And. SA1->A1_REEMB == "T" //T=Customizado Texaco
				cQro := ""
				cQro += "SELECT Z8_VALOR,Z8_PONTOS"
				cQro += "  FROM " + RetSqlName("SZ8")
				cQro += " WHERE D_E_L_E_T_ = ' ' "
				cQro += "   AND Z8_FILIAL = '" + xFilial("SZ8") + "' "
				cQro += "   AND Z8_REEMB = 'T' "
				cQro += "   AND Z8_CLIENTE = '" + SA1->A1_COD + "' "
				cQro += "   AND Z8_LOJA = '" + SA1->A1_LOJA + "' "
				cQro += "   AND Z8_CODPROD = '" + cInCodProd + "' "
				cQro += "   AND '" + DTOS(dDataBase) + "' BETWEEN  Z8_DATCAD AND Z8_DATFIM "
			ElseIf cREEMB == "W" .And. SA1->A1_REEMB == "W" //W=Customizado Wynns
				cQro := ""
				cQro += "SELECT Z8_VALOR,Z8_PONTOS "
				cQro += "  FROM " + RetSqlName("SZ8")
				cQro += " WHERE D_E_L_E_T_ = ' ' "
				cQro += "   AND Z8_FILIAL = '" + xFilial("SZ8") + "' "
				cQro += "   AND Z8_REEMB = 'W' "
				cQro += "   AND Z8_CLIENTE = '" + SA1->A1_COD + "' "
				cQro += "   AND Z8_LOJA = '" + SA1->A1_LOJA + "' "
				cQro += "   AND Z8_CODPROD = '" + cInCodProd + "' "
				cQro += "   AND '" + DTOS(dDataBase) + "' BETWEEN  Z8_DATCAD AND Z8_DATFIM "
			Endif
			
			If Empty(cQro)
				nValRet	:= 0
				nValImp	:= 0
			Else	
				TCQUERY cQro NEW ALIAS "QRE"
				
				If !Eof()
					nValRet	:= QRE->Z8_VALOR
					nValImp	:= Round(nValRet * QRE->Z8_PONTOS / 100,2) 
				Endif
				QRE->(DbCloseArea())
			Endif
			
			// Verifica a condição da TES se Atualiza estoque e gera Duplicata
			// Pagamento de Tampinha só poderá acontecer sobre Faturamento com movimentação de estoque. 
			If !Empty(cInTes)
				DbSelectArea("SF4")
				DbSetOrder(1)
				If DbSeek(xFilial("SF4")+cInTes)
					If SF4->F4_DUPLIC <> "S" .Or. SF4->F4_ESTOQUE <> "S"
						nValRet	:= 0
						nValImp	:= 0
					Endif
				Endif
			Endif
		Endif
	Endif

	RestArea(aAreaOld)

	If nTpRet == 1
		Return nValRet
	ElseIf nTpRet == 2
		Return nValImp
	ElseIf nTpRet == 3
		Return {nValRet,nValImp}
	Endif
	
Return nValRet

