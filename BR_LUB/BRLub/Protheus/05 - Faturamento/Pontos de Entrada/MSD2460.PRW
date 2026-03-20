
/*/{Protheus.doc} MSD2460
(Ponto de Entrada Gravação dos itens das Notas Fiscais  )
@author Marcelo Alberto Lauschner
@since 28/08/2006
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function MSD2460()
	
	Local aAreaOld 	:= GetArea()
	
	// Efetua verificação se esta validação deve ser executada para esta empresa/filial
	If !U_BFCFGM25("MSD2460")
		Return .T.
	Endif
	
	// Executa gravação do Log de Uso da rotina
	//U_BFCFGM01("MSD2460")
	
	// Tipo de pedido Normal
	// Houve preço de tampa informado no item do pedido
	// Gera duplicata
	// Atualiza estoque
	If SC5->C5_TIPO == "N" .And. SC6->C6_XVLRTAM > 0 .And. SF4->F4_DUPLIC == "S" .And. SF4->F4_ESTOQUE == "S"
		// Inicio gravação Tampas
		If SA1->A1_REEMB == "P" //P=Padrao Texaco
			// Verifica se o cadastro ainda é vigente 
			cQra := ""
			cQra += "SELECT Z8.R_E_C_N_O_  Z8RECNO"
			cQra += "  FROM " + RetSqlName("SZ8") + " Z8 "
			cQra += " WHERE " + DTOS(SD2->D2_EMISSAO) + " BETWEEN Z8_DATCAD AND Z8_DATFIM "
			cQra += "   AND Z8.D_E_L_E_T_ = ' ' "
			cQra += "   AND Z8_CODPROD = '" + SD2->D2_COD + "' "
			cQra += "   AND Z8_REEMB = 'P' "
			cQra += "   AND Z8_FILIAL = '" + xFilial("SZ8") + "' "
			
			dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQra),'QRA', .F., .T.)
			
			If !Eof()
				
				DbSelectArea("SC5")
				RecLock("SC5",.F.)
				SC5->C5_REEMB 	:= SA1->A1_REEMB
				MsUnlock()

				DbSelectArea("SZ8")
				DbGoto(QRA->Z8RECNO)
				// Grava registro na Tabela
				DbSelectArea("SZA")
				RecLock("SZA",.T.)
				SZA->ZA_DOC			:= SD2->D2_DOC
				SZA->ZA_VEND		:= SC5->C5_VEND1
				SZA->ZA_DATA 		:= SD2->D2_EMISSAO
				SZA->ZA_CLIENTE 	:= SD2->D2_CLIENTE
				SZA->ZA_LOJA 		:= SD2->D2_LOJA
				SZA->ZA_VALOR  		:= Round(SC6->C6_XVLRTAM*SD2->D2_QUANT,2)
				SZA->ZA_OBSERV 		:= "FATURAMENTO NF - PEDIDO:" + SC5->C5_NUM + " - P=TAMPA PADRAO TEXACO"
				SZA->ZA_TIPOMOV 	:= "C"
				SZA->ZA_ITEM    	:= SD2->D2_ITEM
				SZA->ZA_PRODUTO 	:= SD2->D2_COD
				SZA->ZA_QTDORI 		:= SD2->D2_QUANT
				SZA->ZA_VALUNIT 	:= SC6->C6_XVLRTAM
				SZA->ZA_REFEREN 	:= "T"
				SZA->ZA_ORIGEM  	:= "F"
				SZA->ZA_PONTOS 		:= Round(SC6->C6_XFLEX * SD2->D2_QUANT,2)
				MsUnLock("SZA")
				
				Reclock("SD2",.F.)
				SD2->D2_VALPROM := Round(SC6->C6_XVLRTAM*SD2->D2_QUANT,2)
				SD2->D2_VALPTOS	:= Round(SC6->C6_XFLEX * SD2->D2_QUANT,2)
				MSUnLock()
				
			EndIf
			QRA->(dbCloseArea())
		
		ElseIf  SA1->A1_REEMB == "T"

			DbSelectArea("SC5")
			RecLock("SC5",.F.)
			SC5->C5_REEMB 	:=  "T" 
			SC5->(MsUnlock())

			// Verifica se o cadastro ainda é vigente
			cQra := ""
			cQra += "SELECT Z8.R_E_C_N_O_ Z8RECNO "
			cQra += "  FROM " + RetSqlName("SZ8") + " Z8 "
			cQra += " WHERE " + DTOS(SD2->D2_EMISSAO) + " BETWEEN Z8_DATCAD AND Z8_DATFIM "
			cQra += "   AND Z8.D_E_L_E_T_ = ' ' "
			cQra += "   AND Z8_CODPROD = '" + SD2->D2_COD + "' "
			cQra += "   AND Z8_LOJA = '" + SD2->D2_LOJA + "'"
			cQra += "   AND Z8_CLIENTE = '" + SD2->D2_CLIENTE + "'"
			cQra += "   AND Z8_REEMB = 'T' "
			cQra += "   AND Z8_FILIAL = '" + xFilial("SZ8") + "' "
			
			dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQra),'QRA', .F., .T.)
			
			If !Eof()
				DbSelectArea("SZ8")
				DbGoto(QRA->Z8RECNO)

				aArrTamp	:= U_BFTMKA07(SD2->D2_CLIENTE,SD2->D2_LOJA ,SD2->D2_COD,SC5->C5_REEMB,,,3)

				DbSelectArea("SC6")
				RecLock("SC6",.F.)
				SC6->C6_XVLRTAM		:= aArrTamp[1]
				SC6->C6_XFLEX 		:= aArrTamp[2]
				MsUnlock()


				// Grava registro na Tabela
				DbSelectArea("SZA")
				RecLock("SZA",.T.)
				SZA->ZA_DOC			:= SD2->D2_DOC
				SZA->ZA_VEND		:= SC5->C5_VEND1
				SZA->ZA_DATA 		:= SD2->D2_EMISSAO
				SZA->ZA_CLIENTE 	:= SD2->D2_CLIENTE
				SZA->ZA_LOJA 		:= SD2->D2_LOJA
				SZA->ZA_VALOR  		:= Round(SC6->C6_XVLRTAM*SD2->D2_QUANT,2)
				SZA->ZA_OBSERV 		:= "FATURAMENTO NF - PEDIDO:" + SC5->C5_NUM + " - T=TAMPA CUSTOMIZADO"
				SZA->ZA_TIPOMOV 	:= "C"
				SZA->ZA_ITEM    	:= SD2->D2_ITEM
				SZA->ZA_PRODUTO 	:= SD2->D2_COD
				SZA->ZA_QTDORI 		:= SD2->D2_QUANT
				SZA->ZA_VALUNIT 	:= SC6->C6_XVLRTAM
				SZA->ZA_REFEREN 	:= "T"
				SZA->ZA_ORIGEM  	:= "F"
				SZA->ZA_PONTOS 		:= Round(SC6->C6_XFLEX * SD2->D2_QUANT,2)
				MsUnLock("SZA")
				
				Reclock("SD2",.F.)
				SD2->D2_VALPROM := Round(SC6->C6_XVLRTAM*SD2->D2_QUANT,2)
				SD2->D2_VALPTOS	:= Round(SC6->C6_XFLEX * SD2->D2_QUANT,2)
				MSUnLock()
				
			EndIf
			QRA->(dbCloseArea())
		Endif
	Endif
	// Restaura a area Anterior
	RestArea(aAreaOld)
	
Return
