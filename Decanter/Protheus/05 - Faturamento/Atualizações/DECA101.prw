#Include 'Protheus.ch'
/*/{Protheus.doc} DECA101
Adiciona o Tipo Operacao no primeiro item do pedido de venda e replica para os demais itens.
Adicionar gatilho para o campo C6_QTDVEN contra ele mesmo.
Regra: M->C6_QTDVEN
Condição: U_DECA101()
@author TSCB57 - William Farias
@since 29/07/2019
@version 1.0
@return logic
/*/
User Function DECA101()
	// 09/07/2020 - Marcelo A Lauschner / Código revisado e removidos trechos inutilizados

	Local aArea		:= GetArea()
	Local lRet		:= .T.
	Local cOperN 	:= GDFieldGet( "C6_OPER"	, 1 )
	
	If (INCLUI .Or. ALTERA) 
		If N > 1

			If len( aCols ) > 1
				cProd := GDFieldGet( "C6_PRODUTO"	, N)
				GDFieldPut("C6_OPER"	, cOperN	, N)
				MaTesInt(2,cOperN,M->C5_CLIENT,M->C5_LOJAENT,If(M->C5_TIPO$'DB',"F","C"),cProd,"C6_TES")
				
				// 09/07/2020 - Marcelo Lauschner - Executa o Gatilho do campo C6_TES
				RunTrigger(2,N,nil,,'C6_TES')

			EndIf
			//Validacoes
			A410SitTrib()// Esta função só posiciona SB1 e SF4 sem alterar nada
		// -- comentado.	Mta410Oper(N) // Esta função só funciona para cópia de pedidos
			A410MultT()
		EndIf
	EndIf

	RestArea(aArea)

Return lRet
