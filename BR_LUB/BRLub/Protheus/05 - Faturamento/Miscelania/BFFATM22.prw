#Include 'Protheus.ch'
#Include 'TopConn.ch'

/*/{Protheus.doc} BFFATM22
(Função para calcular frete real baseado na tabela de fretes ativa por transportadora)
@author MarceloLauschner
@since 29/10/2014
@version 1.0
@param dInData, data, (Descrição do parâmetro)
@param cInCodCli, character, (Descrição do parâmetro)
@param cInLojCli, character, (Descrição do parâmetro)
@param cInTransp, character, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFFATM22(dInData,cInCodCli,cInLojCli,cInTransp,nInVlrMerc,nInPeso,nInVlrFrete)
	
	Local	aAreaOld	:= GetArea()
	
	// Estas 3 variáveis precisam ser declaradas com este nome pois são usadas dentro das fórmulas do campo SA4->A4_DIS125
	Local	nFrete		:= 0	
	Local	nValMerc	:= nInVlrMerc
	Local	nPeso		:= nInPeso
	Local	nFretVlr	:= 0
	Local	cEstUf 		:= ""
	Default nInVlrFrete	:= 0
		
	DbSelectArea("SA1")
	DbSetOrder(1)
	If DbSeek(xFilial("SA1")+cInCodCli+cInLojCli)
		
		cEstUf	:= SA1->A1_EST
		
		// Posiciona na tabela  Transportadora X Estado X Cidades
		cQry := "SELECT ZK_CLIENTE,ZK_LOJA,R_E_C_N_O_ ZKRECNO "
		cQry += "  FROM " + RetSqlName("SZK")
		cQry += " WHERE D_E_L_E_T_ = ' ' "
		cQry += "   AND '" + DTOS(dInData) + "' BETWEEN ZK_DTINI AND ZK_DTFIM "
		cQry += "   AND ZK_CODMUN = '"+SA1->A1_COD_MUN+"' "
		cQry += "   AND ZK_EST = '"+SA1->A1_EST+"' "
		cQry += "   AND ZK_TRANSP = '"+cInTransp+"' "
		cQry += "   AND ZK_FILIAL = '"+xFilial("SZK")+"' "
		cQry += " ORDER BY ZK_CLIENTE,ZK_LOJA "
		
		DbSelectArea("SZK")
		DbSetOrder(1)
		
		TCQUERY cQry NEW ALIAS "QSZK"
		
		While !Eof()
			// Se houver cliente cadastrado para a cidade, verifica se o cliente for diferente do cliente em cursor - Para localizar taxas especificas por cliente
			
			If (!Empty(QSZK->ZK_CLIENTE) .And. QSZK->ZK_CLIENTE+QSZK->ZK_LOJA <> SA1->A1_COD+SA1->A1_LOJA)
				QSZK->(DbSkip())
				Loop
			Endif
			aBlock	:= {}
			DbSelectArea("SA4")
			DbSetOrder(1)
			If DbSeek(xFilial("SA4")+cInTransp) .And. !Empty(SA4->A4_DIS125)
				Aadd(aBlock,&(SA4->A4_DIS125))
				DbSelectArea("SZK")
				DbGoto(QSZK->ZKRECNO)
				For x := 1 To Len(aBlock)
					Eval(aBlock[x])
				Next
			Endif
			DbSelectArea("QSZK")
			QSZK->(DbSkip())
		Enddo
		QSZK->(DbCloseArea())
		
	Endif
	
	// 07/07/2015 - Adequação de percentual de frete conforme orientação da logistica. 
	
	If nFrete <= 0
		nFrete		:= Round(nValMerc * GetNewPar("BR_PFRETPD",3.5) / 100 , 2)		
	Endif
	
	nFrete	-= nInVlrFrete
	 
	RestArea(aAreaOld)
	
Return nFrete

