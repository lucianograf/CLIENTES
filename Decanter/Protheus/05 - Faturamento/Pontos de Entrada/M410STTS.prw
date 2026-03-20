#include 'TOTVS.CH'
#include 'topconn.ch'

/*/{Protheus.doc} M410STTS

Descrição:
Este ponto de entrada pertence à rotina de pedidos de venda, MATA410().
Está em todas as rotinas de inclusão, alteração, exclusão, cópia e devolução de compras.

Executado após todas as alterações no arquivo de pedidos terem sido feitas.

Parâmetros:
nOper --> Tipo: Numérico - Descrição: Operação que está sendo executada, sendo:

3 - Inclusão
4 - Alteração
5 - Exclusão
6 - Cópia
7 - Devolução de Compras

@type function
@param nOper, number, Descrição: Operação que está sendo executada, sendo:  3 - Inclusão 4 - Alteração 5 - Exclusão 6 - Cópia 7 - Devolução de Compras
@author Decanter**
@since 30/07/2019
@version 12.1.027 - Out  2020
@see *
/*/

User Function M410STTS()

	Local _nOper 		:= PARAMIXB[1]
	Local aArea    		:= GetArea()
	Local aAreaC5  		:= SC5->(GetArea())
	Local aAreaC6  		:= SC6->(GetArea())
	Local nVlrPedidoMin := SuperGetMV("MV_ZPARMIN")
	Local nDscPol       := SuperGetMV("MV_ZDESPOL")
	Local nDscGer       := SuperGetMV("MV_ZDESGERL")
	Local nValorPedido 	:= 0
	Local nPesoBruto 	:= 0
	Local nMediaPedido	:= 0
	Local nMediaCliente	:= 0
	Local NI			:= 0
	Local nTOTDIA		:= 0
	Local nTOTPRA		:= 0
	Local nVlrParcMin	:= 0
	Local nPrcBase      := 0
	Local nPrcCli       := 0
	Local nDscTot       := 0
	Local nValProm	    := 0
	Local nDesCli		:= 0
	Local nSumQtdVen 	:= 0
	Local cQry			:= ""
	Local cTpOper       := ''
	Local cTpOper2      := ''
	Local cIsento		:= "N"
	Local lC5BlqOk		:= .T. // Define que o pedido será liberado caso não encontre nenhuma negativa abaixo
	Local _aParcela		:= {}
	Local nValFat 		:= 0
	Local nValPed 		:= 0
	Local nSalIni		:= 0
	Local cMotBlq1		:= ''
	Local cMotBlq2	    := ''
	Local cMotSendWF 	:= ""
	Local cMotRegrWF	:= ""
	Local nCont			:= 0
	Local lBlqCmp 		:= .F. // Controla o bloqueio por campanhas.
	Local lBlqNeg 		:= .F. // Controla o bloqueio de regra de negocio.
	Local lAlc          := .F. // Controla se algum item bloqueou por campanha e envia e deve gerar alçada
	Local cCodEmp 		:= FWCodEmp()
	Local cCodFil 		:= FWCodFil()
	Local cCodPed 		:= SC5->C5_NUM
	Local cCodCli 		:= SC5->C5_CLIENTE
	Local lCuston 		:= SuperGetMv("DC_ITEMEXC",.F.) As Logical  // Habilita exclusão de item do pedido.
	Local lAprHie 		:= SuperGetMv("DC_APRHIE" ,.F.) As Logical  // Habilita aprovação por Hierarquia.
	Local lFound		:= .F.
	Local aProdCamp		:= {}
	Local nPosCamp		:= 0

	// MRBranco
	Local nDesc       := 0
	Local nDescCab    := 0
	Local nPrcLista   := 0
	Local nPrcNew     := 0
	Local lBlqRule    := .F. // Bloqueou por regra ou verba
	Local nTopDesc    := 0
	Local cConsignado := AllTrim(SuperGetMV("DC_OPCONSG",,"05/09"))
	Local cCFConsig   := AllTrim(SuperGetMV("DC_CFCONSG",,"917"))
	Local lConsignado := .F.
	Local lOrcamento  := .F.

	Private lVldPed     := .F.

    /*
    Integração com CRM Simples
    */
    IF cEmpAnt == "02" .and. cFilAnt == "0204"
        If _nOper == 3 .or. _nOper == 6 // Inclusão ou Cópia
            FwMsgRun(NIL, {|| U_PTCRM904(3)}, "Aguarde", "Processando integração com CRM")
        EndIf

        If _nOper == 4 // Alteração
            FwMsgRun(NIL, {|| U_PTCRM904(4)}, "Aguarde", "Processando integração com CRM")
        EndIf
    Endif
    /*
    FIM Integração com CRM Simples
    */


	//Verifica se o campo existe.
	if SC5->(FieldPos( "C5_XORCAME" )) > 0
		//Verifica se o pedido é para impressão, funciona como fosse um orçamento.
		lOrcamento  := Iif(SC5->C5_XORCAME =='1' , .T. , .F.)
	Endif

	nTotlex := (nSalIni+nValFat) + nValPed

	// LOG DE INCLUSÃO
	If _nOper == 3
		RecLock("SC5", .F.)
		SC5->C5_LOGINC := CUSERNAME
		MsUnLock()
	EndIf

	//LOG DE ALTERAÇÃO
	If _nOper == 4
		RecLock("SC5", .F.)
		SC5->C5_LOGALT := CUSERNAME
		SC5->C5_SITDEC := " "

		IF SC5->C5_XBLQCMP
			SC5->C5_XBLQCMP := .F.
		EndIf
		SC5->(MsUnLock())

		/*
			Alterar status dos itens dos itens excluidos na tabela ZZO
			Jonivani - Vamilly
			Date - 09/11/2023
			Paraemtros: Filial, pedido, cliente, Codigo Cliente
		*/
		IF lCuston
			StartJob( "U_DECAT006()", GetEnvServer(), .T., {cCodEmp, cCodFil, cCodPed, cCodCli})
		EndIf
	EndIf

	// Se não for pedido tipo N-NOrmal - Retorna antes
	If SC5->C5_TIPO $ "D#B#C#I#P"
		RestArea(aArea)
		Return
	Endif

	DbSelectArea("SA1")
	DbSetOrder(1)
	DbSeek(xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI)
	nVlrPedidoMin	:= SA1->A1_ZPEDMIN
	nVlrParcMin		:= SA1->A1_ZPARCMI
	nDesCli			:= SA1->A1_DESC

	DbSelectArea("SB1")
	DbSetOrder(1)
	DbSeek(xFilial("SB1")+SC6->C6_PRODUTO)

	DbSelectArea("SE4")
	DbSetOrder(1)
	DbSeek(xFilial("SE4")+SA1->A1_COND)
	nPMedioCli	:= SE4->E4_ZPRAZOM

	DbSelectArea("SE4")
	DbSetOrder(1)
	DbSeek(xFilial("SE4")+SC5->C5_CONDPAG)
	nPMedioPed	:= SE4->E4_ZPRAZOM

	DbSelectArea("SA3")
	DbSetOrder(1)
	DbSeek(xFilial("SA3")+SC5->C5_VEND1)
	//Canal
	DbSelectArea("ADK")
	DbSetOrder(1)
	DbSeek(xFilial("ADK")+SA3->A3_UNIDAD)
	//Praca
	DbSelectArea("ACA")
	DbSetOrder(1)
	DbSeek(xFilial("ACA")+SA3->A3_GRPREP)


	//DIAGNOSTICO REGRAS DE NEGÓCIO
	// Parâmetros:
	// MV_ZPEDMIN: Valor do pedido mínimo ex: 1000
	// MV_ZPARMIN: Valor da parcela minina ex: 300
	// MV_ZDESMIN: Valor máximo do desconto ex: 8
	// MV_ZDESPOL: Percentual de desconto política
	// MV_ZDESGER: Percentual de desconto Gerente


	// Marcelo A Lauschner - Solicitação para só manter os registros da última situação
	// 17/05/2021 - Deleta os registros do pedido, pois serão incluídos novos registros atualizados

	Monitor_log.U_Record_Log(SC5->C5_NUM, ProcName() , "Antes de deletar ZDP e ZCC - Linha 176" , .T.)

	cQry := "DELETE FROM " + RetSqlName("ZDP")
	cQry += " WHERE D_E_L_E_T_ =' ' "
	cQry += "   AND ZDP_PEDIDO = '"+SC5->C5_NUM + "' "
	cQry += "   AND ZDP_FILIAL = '" + xFilial("ZDP") + "' "

	Begin Transaction
		Iif(TcSqlExec(cQry) < 0,ConOut(TcSqlError()),TcSqlExec("COMMIT"))
	End Transaction

	// DV* JS  Dt: 15/07/2021
	// Deleta os registros do pedido, pois serão incluídos novos registros atualizados
	cQry := "DELETE FROM " + RetSqlName("ZCC")
	cQry += " WHERE D_E_L_E_T_ =' ' "
	cQry += "   AND ZCC_NUM  = '"+SC5->C5_NUM + "' "
	cQry += "   AND ZCC_FILIAL = '" + xFilial("ZCC") + "' "
	Begin Transaction
		Iif(TcSqlExec(cQry) < 0,ConOut(TcSqlError()),TcSqlExec("COMMIT"))
	End Transaction

	Monitor_log.U_Record_Log(SC5->C5_NUM, ProcName() , "Depois de deletar a ZDP e ZCC - Linha 197" , .T.)

	DbSelectArea("SC6")
	DbSetOrder(1)
	DbSeek(xFilial("SC6")+SC5->C5_NUM)
	While !Eof() .And. SC6->(C6_FILIAL+C6_NUM) == xFilial("SC6")+SC5->C5_NUM

		/*
			!!! Esse comentário deverá ser eliminado após a finalização das tratativas
			Para calcular valor de incremento ou decremento do Flex, primeiro será necessário
			encontrar o preço base que deverá ser composto pelo preço do item sem IPI, subtraindo
			os descontos permitidos e após isso, o que a diferença positiva ou negativa, em relação
			ao preço base encontrado, determinará o valor do Flex e o tipo do movimento.
		*/
		if _NOPER <> 7 .and. cEmpAnt $"01#02"
			BeginSql Alias "cAliasDsc"
				SELECT
					C6_FILIAL,
					C5_VEND1,
					C6_LOCAL,
					C6_ITEM,
					C6_PRODUTO,
					C6_DESCRI,
					ISNULL(C6_PRUNIT, C6_PRCVEN) C6_PRUNIT,
					A1_DESC,
					((100 - ISNULL(A1_DESC, 0)) * 0.01 * C6_PRUNIT) AS PRCCLI,
					C6_QTDVEN,
					C6_PRCVEN,
					'' AS C6_DESCONT
				FROM
					%Table:SC6% SC6
					LEFT OUTER JOIN %Table:SC5% SC5
				ON (
						C5_FILIAL = C6_FILIAL
						AND C5_NUM = C6_NUM
						AND SC5.%notDel%
					)
					LEFT OUTER JOIN %Table:SA1% SA1
				ON (
						C6_CLI = A1_COD
						AND C6_LOJA = A1_LOJA
						AND SA1.%notDel%
					)
				WHERE
					C6_FILIAL = %Exp:SC6->C6_FILIAL%
					AND C6_NUM = %Exp:SC5->C5_NUM%
					AND C6_ITEM = %Exp:SC6->C6_ITEM%
					AND SC6.%notDel%
			EndSql

			Count to nCount

			nPrcCli := 0
			nDscTot := 0

			cAliasDsc->(DBGoTop())
			While cAliasDsc->(!EoF())

				nPrcTab := cAliasDsc->C6_PRUNIT
				nPrcCli  := cAliasDsc->PRCCLI
				nSumQtdVen	+= cAliasDsc->C6_QTDVEN
				cAliasDsc->(DbSkip())

			EndDo
			cAliasDsc->(DbCloseArea())

			cTpOper  := ''
			cTpOper2 := ''
			nPrcBase := 0
			nTotFlx  := 0
			nDscTot  := 0
			nValProm := 0
			cIsento	 := "N"

			DbSelectArea("DA1")
			DbSetOrder(1)
			DbSeek(xFilial("DA1")+'ZCC'+SC6->C6_PRODUTO)
			nValProm := DA1->DA1_PRCVEN

			If nValProm > 0
				cIsento		:= "S"
			EndIf

			if ALLTRIM(SC6->C6_CF) $ "5102#6102#6108#5405"
				cTpOper2  := 'V'
			else
				cTpOper2  := 'O'
			EndIf

			if ALLTRIM(SC6->C6_CF) == '6910' .or. ALLTRIM(SC6->C6_CF) == '5910'
				cTpOper  := 'B'
				nTotFlx  := - ROUND((SC6->C6_PRUNIT * SC6->C6_QTDVEN * ((100-nDscPol)*0.01) ),2)
				nPrcBase := 0
				nDscTot  := 0
			else
				cTpOper   := 'V'
				if nDesCli > 8 .AND. cIsento == "N"
					nPrcBase := nPrcCli
					nTotFlx  := ROUND((SC6->C6_PRCVEN* SC6->C6_QTDVEN) - (nPrcCli * SC6->C6_QTDVEN),2)
					nDscTot  := ROUND( ((nPrcCli - SC6->C6_PRCVEN)/nPrcCli)*100,2)
				elseif cIsento == "N"
					nPrcBase := nPrcTab * ((100-nDscPol)*0.01)
					nTotFlx  := ROUND((SC6->C6_PRCVEN* SC6->C6_QTDVEN) - (nPrcBase * SC6->C6_QTDVEN),2)
					nDscTot  := ROUND( ((nPrcTab - SC6->C6_PRCVEN)/nPrcTab)*100,2)
				else
					nPrcBase := 0
					nTotFlx  := 0
					nDscTot  := 0
				endif
			endif

			if SC5->C5_ZCC == '1'
				RecLock('ZCC',.T.)
				ZCC->ZCC_FILIAL	:= SC6->C6_FILIAL
				ZCC->ZCC_VEND	:= SC5->C5_VEND1
				ZCC->ZCC_ISENTO	:= cIsento // Verificar tratamento
				ZCC->ZCC_OPER	:= cTpOper // Após calculo atribuir se a operação é de crédito ou débito
				ZCC->ZCC_TIPO	:= '1' // Verificar tratamento
				ZCC->ZCC_NUM	:= SC5->C5_NUM
				ZCC->ZCC_ITEM	:= SC6->C6_ITEM
				ZCC->ZCC_PRODUT	:= SC6->C6_PRODUTO
				ZCC->ZCC_DOC	:= SC6->C6_NOTA
				ZCC->ZCC_SERIE	:= SC6->C6_SERIE
				ZCC->ZCC_CLI	:= SC6->C6_CLI
				ZCC->ZCC_LOJA	:= SC6->C6_LOJA
				ZCC->ZCC_QTDVEN	:= SC6->C6_QTDVEN
				ZCC->ZCC_PRCVEN	:= SC6->C6_PRCVEN
				ZCC->ZCC_PRUNIT	:= SC6->C6_PRUNIT
				ZCC->ZCC_PRCREG	:= nPrcCli // Verificar tratamento
				ZCC->ZCC_DESCCL	:= SA1->A1_DESC // Verificar tratamento

				ZCC->ZCC_DESCGR	:= nDscGer
				ZCC->ZCC_DESC	:= nDscTot // Verificar tratamento
				ZCC->ZCC_DESCPL	:= nDscPol // Verificar tratamento
				ZCC->ZCC_PRBASE	:= nPrcBase // Verificar tratamento
				ZCC->ZCC_LIMITE	:= 0 // Verificar tratamento
				ZCC->ZCC_VALOR	:= nTotFlx // Verificar tratamento(((SC6->C6_PRCVEN/SC6->C6_PRUNIT)-1)*-100)
				ZCC->ZCC_HIST	:= ''// Verificar tratamento
				ZCC->ZCC_DATA	:= SC5->C5_EMISSAO
				ZCC->ZCC_USER	:= CUSERNAME
				ZCC->ZCC_MESREF := AnoMes(SC5->C5_EMISSAO)
				ZCC->(MsUnLock())
			EndIf
		Endif

		/* MRBranco - Begin
        Aplica o desconto em cascata, igual padrão do sistema, primeiro do cabeçalho depois do item
        Iniciando pelo campo 2 desconsiderando o primeiro C5_DESC1
        A variavel nDesc é o desconto do item com o cabeçalho quando tiver
		*/
		/*
		// Variaveis de controle
		nDesc     := 0
		nPrcLista := SC6->C6_PRUNIT
		nPrcNew   := nPrcLista

		// Cabecalho desconto 1
		If SC5->C5_DESC1 > 0
			nPrcNew := nPrcNew - (nPrcNew * (SC5->C5_DESC1/100))
		EndIf

		// Cabecalho desconto 2
		If SC5->C5_DESC2 > 0
			nPrcNew := nPrcNew - (nPrcNew * (SC5->C5_DESC2/100))
		EndIf

		// Cabecalho desconto 3
		If SC5->C5_DESC3 > 0
			nPrcNew := nPrcNew - (nPrcNew * (SC5->C5_DESC3/100))
		EndIf

		// Cabecalho desconto 4
		If SC5->C5_DESC4 > 0
			nPrcNew := nPrcNew - (nPrcNew * (SC5->C5_DESC4/100))
		EndIf

		// Após o desconto 4 do cabeçalho, aplica o desconto do item se tiver
		If SC6->C6_ZDESITE > 0
			nPrcNew := nPrcNew - (nPrcNew * (SC6->C6_ZDESITE/100))
		EndIf

		// Calcula o desconto para passar para função padrão que avalia regra de negócio
		nDesc := 100 - (nPrcNew / nPrcLista) * 100
		// MRBranco - End
		*/

		nDesc := SC5->C5_DESC1 + SC5->C5_DESC2 + SC5->C5_DESC3 + SC5->C5_DESC4 + SC6->C6_ZDESITE

		//FwAlertError( SC6->C6_ITEM + SC6->C6_PRODUTO + "Desconto [" + AllTrim(Transform( nDesc ,"@E 999,999,999.99")) + "]", "Desconto")

		//============================================================================================================================================================================
		// Fontes Vamilly referente a regra de bloqueio ou liberação por Campanhas de vendas.
		// Verifica se existe campanha para este item.
		If nDesc > 0
			lFound := U_DECAT003(SC5->C5_NUM,SC5->C5_VEND1,SC6->C6_PRODUTO,nDesc,0, .F., .T.)
		EndIf

		// Caso não encontre a campanha.
		If !lFound
			If SC6->C6_BLOQUEI 	== '01'	// bloqueio por Regra de Negócios (FATA100).
				// É feito para retornar a legenda correta do bloqueio.
				lBlqNeg := .T.
			EndIf
		EndIf

		// Verifica se o desconto é maior que zero e se não está com bloqueio de negócios.
		If nDesc > 0 .And. (!lBlqNeg .Or. lFound)
			lBlqCmp := U_DECAT003(SC5->C5_NUM,SC5->C5_VEND1,SC6->C6_PRODUTO,nDesc,0)

			//Caso ele não seja bloqueado por campanha, adiciona o item ao array.
			If !lBlqCmp
				Aadd(aProdCamp, Alltrim(SC6->C6_ITEM + SC6->C6_PRODUTO))
			EndIf

			// Se algum item bloqueou por campanha então deve gerar alçada
			// Se ativar a alçada 1 vez não entra mais
			If !lAlc
				lAlc := lBlqCmp
			EndIf
		EndIf
		// Se o pedido passou por campanha, verifica o se ficou por regra de negocio e limpa, pois a campanha é mandatória.
		If !lBlqCmp .AND. SC6->C6_BLOQUEI == '01'
			RecLock("SC6", .F.)
			SC6->C6_BLOQUEI := ''
			SC6->(MsUnLock())
		End
		//============================================================================================================================================================================

		//Desconto por item do pedido;
		RecLock("ZDP", .T.)
		ZDP->ZDP_FILIAL := cFilAnt
		ZDP->ZDP_PEDIDO := SC5->C5_NUM
		ZDP->ZDP_ITEM   := SC6->C6_ITEM
		ZDP->ZDP_REGRA := '1'
		ZDP->ZDP_USER   := CUSERNAME
		ZDP->ZDP_DATA   := Date()
		ZDP->ZDP_HORA   := Time()
		ZDP->ZDP_PRODUT:= SC6->C6_PRODUTO
		If lBlqCmp .Or. lBlqNeg
			ZDP->ZDP_VALOR  := (((SC6->C6_PRCVEN/SC6->C6_PRUNIT)-1)*-100)
			ZDP->ZDP_OBS    := "DESCONTO " + ALLTRIM(STR((((SC6->C6_PRCVEN/SC6->C6_PRUNIT)-1)*-100)))
			ZDP->ZDP_TIPO   := .F.
			lC5BlqOk		:= .F.
			cMotSendWF	+= "1-ITEM:"+SC6->C6_ITEM + " DESCONTO " + ALLTRIM(STR((((SC6->C6_PRCVEN/SC6->C6_PRUNIT)-1)*-100))) + CRLF
		else
			ZDP->ZDP_VALOR  := (((SC6->C6_PRCVEN/SC6->C6_PRUNIT)-1)*-100)
			ZDP->ZDP_OBS    := "REGRA DE DESCONTO OK"
			ZDP->ZDP_TIPO   := .T.
		EndIf
		MsUnLock()

		nValorPedido += SC6->C6_VALOR
		nPesoBruto += (SB1->B1_PESBRU * SC6->C6_QTDVEN)

		//Verifica pelo tipo de operação se é consignação.
		If !lConsignado
			//Faz 3 validações: Pelo tipo de operação, pelo CFOP e pelo tipo de operação informado no cabeçalho do pedido.
			If AllTrim(SC6->C6_OPER) $ cConsignado .Or. Right(AllTrim(SC6->C6_CF),3) $ cCFConsig .Or. AllTrim(SC5->C5_ZOPRMAX) == "CS"
				lConsignado := .T.
			Endif
		EndIf

		SC6->(dbSkip())
	Enddo

	Monitor_log.U_Record_Log(SC5->C5_NUM, ProcName() , "Depois do while do SC6 - Linha 462" , .T.)

	// MRBranco - Begin
	// Valida regra de negócio e desconsidera desconto do cliente A1_DESC

	aArea 	    := FWGetArea()
	aAreaSC6    := SC6->(FWGetArea())
	aAreaSC5    := SC5->(FWGetArea())
	aProdDesc   := {}  // array com os itens do pedido para avaliar regra de negocio

	nDescCab  	:= SC5->C5_DESC1 + SC5->C5_DESC2
	// Se bloqueou por campanha/alçada e tem desconto no cadastro então entra na regra
	If (lAlc .Or. lBlqNeg) .And. nDescCab > 0 .And. !lOrcamento

		/*
        Reaplica os descontos desconsiderando o valor do cadadasto, que é gravado no C5_DESC1
        Porém, os outros descontos deve considerar C5_DESC2, C5_DESC3, C5_DESC4

        Neste laço, controlo a transação, vou alterando o campo de bloqueio para vazio (via reclock), julgando que não está bloqueado por regra/verba
        no final, avalio se o pedido está bloqueado, caso esteja bloqueado eu cancelo a transação disarmando a mesma, caso o pedido não esteja bloqueado
        então mantém a transação sem desarma-la, desta forma, não preciso varresr os itens (sc6) novamente depois para desmarcar o campo bloqueio
		*/
		Begin Transaction
			DBSelectArea("SC6")
			SC6->(DBSetOrder(1))
			If SC6->(DbSeek(xFilial("SC6" ) + SC5->C5_NUM))
				While  SC6->(!Eof()) .And. SC6->(C6_FILIAL + C6_NUM) == xFilial("SC6") + SC5->C5_NUM

					If Len(aProdCamp) > 0
						nPosCamp := aScan( aProdCamp,{|x| x == AllTrim(SC6->C6_ITEM + SC6->C6_PRODUTO) })

						If nPosCamp > 0
							SC6->(DbSkip())
							Loop
						EndIf
					EndIf

					// Variaveis de controle
					nDesc     := 0
					nPrcLista := SC6->C6_PRUNIT
					nPrcNew   := nPrcLista

					/*
                    Aplica o desconto em cascata, igual padrão do sistema, primeiro do cabeçalho depois do item
                    Iniciando pelo campo 2 desconsiderando o primeiro C5_DESC1
					*/

					// Cabecalho desconto 2
					If SC5->C5_DESC2 > 0
						nPrcNew := nPrcNew - (nPrcNew * (SC5->C5_DESC2/100))
					EndIf

					// Cabecalho desconto 3
					If SC5->C5_DESC3 > 0
						nPrcNew := nPrcNew - (nPrcNew * (SC5->C5_DESC3/100))
					EndIf

					// Cabecalho desconto 4
					If SC5->C5_DESC4 > 0
						nPrcNew := nPrcNew - (nPrcNew * (SC5->C5_DESC4/100))
					EndIf

					// Após o desconto 4 do cabeçalho, aplica o desconto do item se tiver
					If SC6->C6_ZDESITE > 0
						nPrcNew := nPrcNew - (nPrcNew * (SC6->C6_ZDESITE/100))
					EndIf

					// Calcula o desconto para passar para função padrão que avalia regra de negócio
					nDesc := 100 - (nPrcNew / nPrcLista) * 100

					//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
					//³       Estrutura do array aProdDesc                                          ³
					//³       [1] - Codigo do Produto                                               ³
					//³       [2] - Item do Pedido de Venda                                         ³
					//³       [3] - Preco de Venda                                                  ³
					//³       [4] - Preco de Lista                                                  ³
					//³       [5] - % do Desconto Concedido no item do pedido                       ³
					//³       [6] - % do Desconto Permitido pela regra (FtRegraNeg)                 ³
					//³       [7] - Indica se sera necessario verificar o saldo de verba            ³
					//³                             01 - Bloqueio de regra de negocio               ³
					//³                             02 - Bloqueio para verificacao de verba         ³
					//³       [8] - Valor a ser abatido da verba caso seja aprovada (FtVerbaVen)    ³
					//³       [9] - Flag que indica se o item sera analisado nas regras             ³
					//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
					Aadd(aProdDesc, {SC6->C6_PRODUTO, SC6->C6_ITEM, SC6->C6_PRCVEN, SC6->C6_PRUNIT,	nDesc, 0, "", 0, .T.})

					// Verifica o maior desconto e passa para variavel nTopDesc
					// vai ser o desconto que será analisado na campanha
					If nDesc > nTopDesc
						nTopDesc := nDesc
					EndIf

					// Altera o bloqueio para vazio no controle de transação
					RecLock("SC6", .F.)
					SC6->C6_BLOQUEI := ''
					SC6->(MSUNLock())

					SC6->(DbSkip())
				End

				/*
                Avalia regra padrão de negócio, só passando os valor por item sem o desconto do cliente
                A função retorna: .T.=Não bloqueou e .F.=Bloqueou
                Inverto o retorno para fazer sentido com o nome da varivael lBlqRule que é .T.=Bloqueou e .F.=Não bloqueou
				*/
				lBlqRule := !FtRegraNeg(SC5->C5_CLIENTE, SC5->C5_LOJACLI, SC5->C5_TABELA, SC5->C5_CONDPAG, NIL, @aProdDesc, .F., SC5->C5_VEND1, .T.)

				/*
                Caso não tenha bloqueado por regra/verba sem o valor de desconto do cliente
                então libera a variavel que controla o bloqueio, libera o pedido (sc5) e os itens (sc6),
                no caso dos itens já foi alterado no laço, então basta manter sem desarmar a transação.
                Caso tenha bloqueado por regra, então mantém o pedido (sc5) bloqueado e cancela a alteração
                dos itens disarmando a transação para mante-los bloqueados também
				*/
				If lBlqRule
					DisarmTransaction()
				Else
					lBlqNeg := .F.
					RecLock("SC5", .F.)
					SC5->C5_BLQ	:= ""
					SC5->(MSUnLock())
				EndIf
			EndIf
		End Transaction
	EndIf

	Monitor_log.U_Record_Log(SC5->C5_NUM, ProcName() , "Depois do bloqueio de regra da SC6 - Linha 588" , .T.)

	FWRestArea(aAreaSC6)
	FWRestArea(aAreaSC5)
	FWRestArea(aArea)
	// MRBranco - End



	//Valor mínimo de parcela;
	//calculo a partir da condição do pedido
	_aParcela := Condicao(nValorPedido,SC5->C5_CONDPAG, 0,DDATABASE)

	FOR NI := 1 TO LEN(_APARCELA)
		nTOTDIA += _APARCELA[NI][2]
		nTOTPRA += (DateDiffDay(_APARCELA[NI][1],DDATABASE)*_APARCELA[NI][2])
	NEXT

	nMediaPedido := nPMedioPed //nTOTPRA/nTOTDIA

	If LEN(_APARCELA)>0 .And. _APARCELA[1][2] < nVlrParcMin
		RecLock("ZDP", .T.)
		ZDP->ZDP_FILIAL := cFilAnt
		ZDP->ZDP_PEDIDO := SC5->C5_NUM
		ZDP->ZDP_ITEM   := ""
		ZDP->ZDP_REGRA := '2'
		ZDP->ZDP_VALOR  := _APARCELA[1][2]
		ZDP->ZDP_OBS    := "PARCELA ABAIXO DE " + ALLTRIM(Str(nVlrParcMin)) + " REAIS"
		ZDP->ZDP_USER   := CUSERNAME
		ZDP->ZDP_DATA   := Date()
		ZDP->ZDP_HORA   := Time()
		ZDP->ZDP_PRODUT:= ""
		ZDP->ZDP_TIPO   := .F.
		MsUnLock()
		lC5BlqOk		:= .F.
		cMotSendWF	+= "2-PARCELA ABAIXO DE " + ALLTRIM(Str(nVlrParcMin)) + " REAIS" + CRLF
	Else
		RecLock("ZDP", .T.)
		ZDP->ZDP_FILIAL := cFilAnt
		ZDP->ZDP_PEDIDO := SC5->C5_NUM
		ZDP->ZDP_ITEM   := ""
		ZDP->ZDP_REGRA := '2'
		ZDP->ZDP_VALOR  := 0
		ZDP->ZDP_OBS    := "REGRA DE PARCELA OK"
		ZDP->ZDP_USER   := CUSERNAME
		ZDP->ZDP_DATA   := Date()
		ZDP->ZDP_HORA   := Time()
		ZDP->ZDP_PRODUT:= ""
		ZDP->ZDP_TIPO   := .T.
		MsUnLock()
	EndIf
	//Valor de pedido mínimo;

	If nValorPedido < nVlrPedidoMin
		RecLock("ZDP", .T.)
		ZDP->ZDP_FILIAL := cFilAnt
		ZDP->ZDP_PEDIDO := SC5->C5_NUM
		ZDP->ZDP_ITEM   := ""
		ZDP->ZDP_REGRA := '3'
		ZDP->ZDP_VALOR  := nValorPedido
		ZDP->ZDP_OBS    := "PEDIDO ABAIXO DE " + ALLTRIM(Str(nVlrPedidoMin)) + " REAIS"
		ZDP->ZDP_USER   := CUSERNAME
		ZDP->ZDP_DATA   := Date()
		ZDP->ZDP_HORA   := Time()
		ZDP->ZDP_PRODUT:= ""
		ZDP->ZDP_TIPO   := .F.
		MsUnLock()
		lC5BlqOk		:= .F.
		cMotSendWF	+= "3-PEDIDO ABAIXO DE " + ALLTRIM(Str(nVlrPedidoMin)) + " REAIS" + CRLF
	Else
		RecLock("ZDP", .T.)
		ZDP->ZDP_FILIAL := cFilAnt
		ZDP->ZDP_PEDIDO := SC5->C5_NUM
		ZDP->ZDP_ITEM   := ""
		ZDP->ZDP_REGRA := '3'
		ZDP->ZDP_VALOR  := nValorPedido
		ZDP->ZDP_OBS    := "REGRA DE PEDIDO MINIMO OK"
		ZDP->ZDP_USER   := CUSERNAME
		ZDP->ZDP_DATA   := Date()
		ZDP->ZDP_HORA   := Time()
		ZDP->ZDP_PRODUT:= ""
		ZDP->ZDP_TIPO   := .T.
		MsUnLock()
	EndIf
	//Vendedor em branco;

	If Empty(SC5->C5_VEND1)
		RecLock("ZDP", .T.)
		ZDP->ZDP_FILIAL := cFilAnt
		ZDP->ZDP_PEDIDO := SC5->C5_NUM
		ZDP->ZDP_ITEM   := ""
		ZDP->ZDP_REGRA := '4'
		ZDP->ZDP_VALOR  := 0
		ZDP->ZDP_OBS    := "VENDEDOR VAZIO"
		ZDP->ZDP_USER   := CUSERNAME
		ZDP->ZDP_DATA   := Date()
		ZDP->ZDP_HORA   := Time()
		ZDP->ZDP_PRODUT:= ""
		ZDP->ZDP_TIPO   := .F.
		MsUnLock()
		lC5BlqOk		:= .F.
		cMotSendWF	+= "4-VENDEDOR VAZIO" + CRLF
	Else
		RecLock("ZDP", .T.)
		ZDP->ZDP_FILIAL := cFilAnt
		ZDP->ZDP_PEDIDO := SC5->C5_NUM
		ZDP->ZDP_ITEM   := ""
		ZDP->ZDP_REGRA := '4'
		ZDP->ZDP_VALOR  := 0
		ZDP->ZDP_OBS    := "REGRA DE VENDEDOR VAZIO OK"
		ZDP->ZDP_USER   := CUSERNAME
		ZDP->ZDP_DATA   := Date()
		ZDP->ZDP_HORA   := Time()
		ZDP->ZDP_PRODUT:= ""
		ZDP->ZDP_TIPO   := .T.
		MsUnLock()
	EndIf
	//Vendedor do pedido divergente do vendedor do cadastro do cliente;

	If SC5->C5_VEND1 <> SA1->A1_VEND
		RecLock("ZDP", .T.)
		ZDP->ZDP_FILIAL := cFilAnt
		ZDP->ZDP_PEDIDO := SC5->C5_NUM
		ZDP->ZDP_ITEM   := ""
		ZDP->ZDP_REGRA := '5'
		ZDP->ZDP_VALOR  := 0
		ZDP->ZDP_OBS    := "VENDEDOR "+SC5->C5_VEND1+" DIFERENTE DO VENDEDOR DO CLIENTE "+SA1->A1_VEND
		ZDP->ZDP_USER   := CUSERNAME
		ZDP->ZDP_DATA   := Date()
		ZDP->ZDP_HORA   := Time()
		ZDP->ZDP_PRODUT:= ""
		ZDP->ZDP_TIPO   := .F.
		MsUnLock()
		lC5BlqOk		:= .F.
		cMotSendWF	+= "5-VENDEDOR "+SC5->C5_VEND1+" DIFERENTE DO VENDEDOR DO CLIENTE "+SA1->A1_VEND + CRLF
	Else
		RecLock("ZDP", .T.)
		ZDP->ZDP_FILIAL := cFilAnt
		ZDP->ZDP_PEDIDO := SC5->C5_NUM
		ZDP->ZDP_ITEM   := ""
		ZDP->ZDP_REGRA := '5'
		ZDP->ZDP_VALOR  := 0
		ZDP->ZDP_OBS    := "REGRA DE VENDEDOR DIFERENTE DO VENDEDOR DO CLIENTE OK"
		ZDP->ZDP_USER   := CUSERNAME
		ZDP->ZDP_DATA   := Date()
		ZDP->ZDP_HORA   := Time()
		ZDP->ZDP_PRODUT:= ""
		ZDP->ZDP_TIPO   := .T.
		MsUnLock()
	EndIf

	//Condição de pagamento do pedido divergente da condição do cadastro do cliente;

	If SC5->C5_CONDPAG <> SA1->A1_COND
		RecLock("ZDP", .T.)
		ZDP->ZDP_FILIAL := cFilAnt
		ZDP->ZDP_PEDIDO := SC5->C5_NUM
		ZDP->ZDP_ITEM   := ""
		ZDP->ZDP_REGRA := '6'
		ZDP->ZDP_VALOR  := 0
		ZDP->ZDP_OBS    := "CONDICAO "+SC5->C5_CONDPAG+" DIFERENTE DA CONDICAO DO CLIENTE "+SA1->A1_COND
		ZDP->ZDP_USER   := CUSERNAME
		ZDP->ZDP_DATA   := Date()
		ZDP->ZDP_HORA   := Time()
		ZDP->ZDP_PRODUT:= ""
		ZDP->ZDP_TIPO   := .F.
		MsUnLock()
		lC5BlqOk		:= .T.
		cMotSendWF	+= "6-CONDICAO "+SC5->C5_CONDPAG+" DIFERENTE DA CONDICAO DO CLIENTE "+SA1->A1_COND + CRLF
	Else
		RecLock("ZDP", .T.)
		ZDP->ZDP_FILIAL := cFilAnt
		ZDP->ZDP_PEDIDO := SC5->C5_NUM
		ZDP->ZDP_ITEM   := ""
		ZDP->ZDP_REGRA := '6'
		ZDP->ZDP_VALOR  := 0
		ZDP->ZDP_OBS    := "REGRA CONDICAO DIFERENTE DA CONDICAO DO CLIENTE OK"
		ZDP->ZDP_USER   := CUSERNAME
		ZDP->ZDP_DATA   := Date()
		ZDP->ZDP_HORA   := Time()
		ZDP->ZDP_PRODUT:= ""
		ZDP->ZDP_TIPO   := .T.
		MsUnLock()
	EndIf

	// Prazo médio da condição do pedido diferente do prazo médio da condição do cliente;

	//cliente
	_aParcela := Condicao(nValorPedido,SA1->A1_COND, 0,DDATABASE)

	FOR NI := 1 TO LEN(_APARCELA)
		nTOTDIA += _APARCELA[NI][2]
		nTOTPRA += (DateDiffDay(_APARCELA[NI][1],DDATABASE)*_APARCELA[NI][2])
	NEXT

	nMediaCliente := nPMedioCli//nTOTPRA/nTOTDIA

	If nMediaPedido > nMediaCliente
		RecLock("ZDP", .T.)
		ZDP->ZDP_FILIAL := cFilAnt
		ZDP->ZDP_PEDIDO := SC5->C5_NUM
		ZDP->ZDP_ITEM   := ""
		ZDP->ZDP_REGRA := '7'
		ZDP->ZDP_VALOR  := nMediaPedido
		ZDP->ZDP_OBS    := "PRAZO MEDIO DIFERENTE CLIENTE"
		ZDP->ZDP_USER   := CUSERNAME
		ZDP->ZDP_DATA   := Date()
		ZDP->ZDP_HORA   := Time()
		ZDP->ZDP_PRODUT:= ""
		ZDP->ZDP_TIPO   := .F.
		MsUnLock()
		lC5BlqOk		:= .F.
		cMotSendWF	+= "7-PRAZO MEDIO DIFERENTE CLIENTE" + CRLF
	Else
		RecLock("ZDP", .T.)
		ZDP->ZDP_FILIAL := cFilAnt
		ZDP->ZDP_PEDIDO := SC5->C5_NUM
		ZDP->ZDP_ITEM   := ""
		ZDP->ZDP_REGRA := '7'
		ZDP->ZDP_VALOR  := nMediaPedido
		ZDP->ZDP_OBS    := "REGRA PRAZO MEDIO DIFERENTE CLIENTE OK"
		ZDP->ZDP_USER   := CUSERNAME
		ZDP->ZDP_DATA   := Date()
		ZDP->ZDP_HORA   := Time()
		ZDP->ZDP_PRODUT:= ""
		ZDP->ZDP_TIPO   := .T.
		MsUnLock()
	EndIf

	//Tabela de preco do pedido divergente da condição do cadastro do cliente;

	If SC5->C5_TABELA <> SA1->A1_TABELA
		RecLock("ZDP", .T.)
		ZDP->ZDP_FILIAL := cFilAnt
		ZDP->ZDP_PEDIDO := SC5->C5_NUM
		ZDP->ZDP_ITEM   := ""
		ZDP->ZDP_REGRA := '8'
		ZDP->ZDP_VALOR  := 0
		ZDP->ZDP_OBS    := "TABELA "+SC5->C5_TABELA+" DIFERENTE DA TABELA DO CLIENTE "+SA1->A1_TABELA
		ZDP->ZDP_USER   := CUSERNAME
		ZDP->ZDP_DATA   := Date()
		ZDP->ZDP_HORA   := Time()
		ZDP->ZDP_PRODUT:= ""
		ZDP->ZDP_TIPO   := .F.
		MsUnLock()
		lC5BlqOk		:= .F.
		cMotSendWF	+= "8-TABELA "+SC5->C5_TABELA+" DIFERENTE DA TABELA DO CLIENTE "+SA1->A1_TABELA + CRLF
	Else
		RecLock("ZDP", .T.)
		ZDP->ZDP_FILIAL := cFilAnt
		ZDP->ZDP_PEDIDO := SC5->C5_NUM
		ZDP->ZDP_ITEM   := ""
		ZDP->ZDP_REGRA := '8'
		ZDP->ZDP_VALOR  := 0
		ZDP->ZDP_OBS    := "REGRA TABELA DIFERENTE DA TABELA DO CLIENTE OK"
		ZDP->ZDP_USER   := CUSERNAME
		ZDP->ZDP_DATA   := Date()
		ZDP->ZDP_HORA   := Time()
		ZDP->ZDP_PRODUT:= ""
		ZDP->ZDP_TIPO   := .T.
		MsUnLock()
	EndIf

	// Regra de bloqueio que utiliza a Tabela ZCC e segue os valores do Espelho de Pedido.
	nValFat  :=  U_xVALCTR('F')
	nValPed  :=  U_xVALCTR('P')
	nSalIni  :=  U_xVALCTR('I')

	nTotFlex := (nSalIni+nValFat) + nValPed

	/*
	If (nTotFlex < 0) .AND. (nValPed < 0)
		RecLock("ZDP", .T.)
		ZDP->ZDP_FILIAL := cFilAnt // comentado para que os pedidos não sejam bloqueados
		ZDP->ZDP_PEDIDO := SC5->C5_NUM
		ZDP->ZDP_ITEM   := ""
		ZDP->ZDP_REGRA := '9'
		ZDP->ZDP_VALOR  := 0
		ZDP->ZDP_OBS    := "ESSE PEDIDO NÃO ATENDE A REGRA DE DESCONTO(FLEX)"
		ZDP->ZDP_USER   := CUSERNAME
		ZDP->ZDP_DATA   := Date()
		ZDP->ZDP_HORA   := Time()
		ZDP->ZDP_PRODUT:= ""
		ZDP->ZDP_TIPO   := .F.
		MsUnLock()
		lC5BlqOk		:= .F.
		cMotSendWF	+= "9-ESSE PEDIDO NÃO ATENDE A REGRA DE DESCONTO(FLEX)" + CRLF
	EndIf
	*/

	//INICIO DOS TESTES COM TRANSPORTADORA INTELIGENTE
	nPesoEst = nPesoBruto //////nSumQtdVen * 1.25  //estimado
	nValorEst := nValorPedido
	cTranspo := ''
	//	If SC5->C5_TPFRETE == 'C' .AND. cFilAnt $ "0101#0102#0103#0104#0105#0106#0107#0202"
	If EMPTY(SC5->C5_TRANSP) .AND. SC5->C5_TPFRETE == 'C' .AND. cFilAnt $ "0101#0102#0103#0104#0105#0106#0107#0108#0202" .AND. INCLUI
		//Se o peso do pedido ultrapassar 500KG sempre irá forçar transportadora Cotar Frete 9999
		If nPesoEst >= 500
			cTranspo := "9999"
		else
			cTranspo := U_DCFATG03(;
				cFilAnt,;     // 1 Filial de Origem
				SA1->A1_EST,;         // 2 Uf Destino
				SA1->A1_COD_MUN,;        // 3 Código Municipio Destino
				SA1->A1_REGIAO,;     // 4 Código Região destino
				SA3->A3_UNIDAD,;      // 5 Código do Canal de atendimento
				SA3->A3_GRPREP,;      // 6 Código da praça
				SA1->A1_SATIV1,;     // 7 Segmento
				SC5->C5_VEND1,;	// 8 Vendedor
				,;     // 9 Expresso
				SC5->C5_CLIENTE,;     // 10 Código do Cliente
				SC5->C5_LOJACLI,;       // 11 Loja do cliente
				SA1->A1_PESSOA,;     // 12 Tipo de pessoa
				SA1->A1_CEP,;        // 13 CEP destino
				SC5->C5_TABELA,;     // 14 Codigo Tabela
				SA1->A1_GRPVEN,;     // 15 Grupo de Vendas
				nPesoEst,;       // 16 Peso
				nValorEst,;       // 17 Valor
				)
		EndIF      // 18 Frete
		if !Empty(cTranspo)
			RecLock("SC5",.F.)
			//SC5->C5_ZTIFLAG	:= SC5->C5_TRANSP
			SC5->C5_TRANSP	:= cTranspo
			MsUnlock()
		Endif
	Endif


	// Se houve alguma negativa nas validações, bloqueia o pedido por Regra
	If !lC5BlqOk .And. SC5->C5_TIPO == "N" .And. !Empty(SC5->C5_XXPEDMA) .And. cEmpAnt $"01#02" .And. INCLUI

		// Somente se o cliente for do tipo Automatizado
		If SA1->(FieldPos("A1_ZAUTO")) > 0 .And. SA1->A1_ZAUTO == "1"
			DbSelectArea("SC5")
			RecLock("SC5", .F.)
			SC5->C5_BLQ		:= "1"
			MsUnLock()
			cMotSendWF	+= "10-CLIENTE AUTOMATIZADO COM PEDIDO MAGENTO" + CRLF
		Endif
	Endif

	// Se o cliente tiver risco C,D ou E força o bloqueio por regra e grava o diagnóstico

	If SA1->A1_RISCO $ "C#D#E" .And. cEmpAnt $"01#02" .And. cTpOper2 == 'O' .And. (INCLUI .OR. ALTERA)
		DbSelectArea("SC5")
		RecLock("SC5", .F.)
		SC5->C5_BLQ		:= "1"
		cMotBlq1  := "Bloqueado por cliente ter risco "+SA1->A1_RISCO+" e não passará por avaliação de crédito - Consultar setor financeiro"+ Chr(13) + Chr(10)
		SC5->C5_ZBLQCOM  := cMotBlq1
		MsUnLock()
		cMotSendWF	+= "11-Bloqueado por cliente ter risco "+SA1->A1_RISCO+" e não passará por avaliação de crédito - Consultar setor financeiro" + CRLF
	Endif

	//Bloqueia todos os pedidos de brinde/bonificação originados pelo Maxpedidos.

	If SC5->C5_TIPO == "N" .And. !Empty(SC5->C5_XXPEDMA) .And. TRIM(SC5->C5_ZOPRMAX) <> '01' .And. cEmpAnt $"01#02" .And. (INCLUI .OR. ALTERA)
		DbSelectArea("SC5")
		RecLock("SC5", .F.)
		SC5->C5_BLQ		:= "1"
		cMotBlq2 := "Bloqueado por ser brinde/bonificação digitado no Max Pedidos"+ Chr(13) + Chr(10)
		SC5->C5_ZBLQCOM  := cMotBlq1 + cMotBlq2
		MsUnLock()
		cMotSendWF	+= "12-Bloqueado por ser brinde/bonificação digitado no Max Pedidos" + CRLF
	Endif

	// Bloqueia pedidos consignados.
	If SC5->C5_TIPO == "N" .And. lConsignado .And. cEmpAnt $"01#02" .And. (INCLUI .OR. ALTERA)
		DbSelectArea("SC5")
		RecLock("SC5", .F.)
		SC5->C5_BLQ		:= "1"
		cMotBlq2 := "Bloqueado por ser consignado."+ Chr(13) + Chr(10)
		SC5->C5_ZBLQCOM  := cMotBlq1 + cMotBlq2
		SC5->(MsUnLock())
		cMotSendWF	+= "13-Bloqueado por ser consignado." + CRLF
	EndIF

	// Grava uma lista de pedidos em aberto num campo para identificarem com facilidades mais pedidos do cliente, podemos ligar pedidos para uso da logistica.

	if SC5->C5_TIPO == "N" .and. cEmpAnt $"01#02" .And. INCLUI
		BeginSql Alias "cAliasPA"
			SELECT
				C5_FILIAL AS FILIAL,
				C5_NUM AS PEDIDO,
				C5_ZDTINC AS DTINC,
				C5_ZHRINC AS HRINC,
				C5_LOGINC AS LOGINC,
				C5_LOGALT AS LOGALT
			FROM
				%Table:SC5% SC5
			WHERE
				C5_CLIENTE = %Exp:SC5->C5_CLIENTE%
				AND C5_NUM <> %Exp:SC5->C5_NUM%
				AND C5_SITDEC <> '5'
				AND C5_NOTA = ''
				AND SC5.%notDel%
		EndSql

		cPedAbert := ''
		cAliasPA->(DBGoTop())
		While cAliasPA->(!EoF())
			cPedAbert += "Filial: "+cAliasPA->FILIAL+" Pedido: "+cAliasPA->PEDIDO+" Criado em: "+cAliasPA->DTINC+" "+cAliasPA->HRINC+" Inc:"+cAliasPA->LOGINC+" Alt:"+cAliasPA->LOGALT+Chr(13) + Chr(10)
			cAliasPA->(DbSkip())
		EndDo
		cAliasPA->(DbCloseArea())
		DbSelectArea("SC5")
		RecLock("SC5", .F.)
		SC5->C5_ZPDABER  := cPedAbert
		MsUnLock()
	EndIf

	If  cEmpAnt $"01#02" .AND. SC5->C5_CLIENTE == '03558806' .AND. SC5->C5_ZCC == '1'
		If nValPed < 0
			If nTotFlex + nValPed < 0
				DbSelectArea("SC5")
				RecLock("SC5", .F.)
				SC5->C5_BLQ		:= "1"
				cMotBlq3 := "Desconto maior que o permitido sem saldo no flex - Resultado do pedido: R$ ";
					+cValToChar(nValPed)+" Resultado do Mês: R$ "+cValToChar(nValPed+nTotFlex)+Chr(13) + Chr(10)
				SC5->C5_ZBLQCOM  := cMotBlq1 + cMotBlq2 + cMotBlq3
				MsUnLock()
				cMotSendWF	+= "15-Desconto maior que o permitido sem saldo no flex - Resultado do pedido: R$ ";
					+cValToChar(nValPed)+" Resultado do Mês: R$ "+cValToChar(nValPed+nTotFlex) + CRLF
			EndIf
		EndIf
	EndIf

	// Se ainda não tiver valor o campo. Pois em pedidos Vtex o campo é usado para gravar o que vem do Vtex para devolver valor correto
	If cEmpAnt $"01#02" .AND. nValorPedido > 0 .And. Empty(SC5->C5_ZVLRLIB)
		DbSelectArea("SC5")
		RecLock("SC5", .F.)
		SC5->C5_ZVLRLIB := nValorPedido
		MsUnLock()
	EndIf


	// Verifica se o pedido tem algum bloqueio de Regra ou Verba
	If SC5->C5_BLQ == "1"
		cMotSendWF += "13-Pedido bloqueado por regra"+CRLF
	Elseif SC5->C5_BLQ == "2"
		cMotSendWF	+= "14-Pedido bloqueado por verba" + CRLF
	Endif

	// Verifica se caiu em regra de negócio e faz o Reclock nos campos para acertar a legenda no Monitor de pedidos e seguir o fluxo.
	If lBlqNeg
		RecLock("SC5",.F.)
		SC5->C5_BLQ 	:= '1'
		SC5->C5_LIBEROK := ' '
		SC5->C5_ZBLQCOM += "Pedido bloqueado por ter itens bloqueados por Regra "
		SC5->(MsUnlock())
	Endif

	// MRBranco - Begin
	// Comentado porque não encontrei a utilidade e também, porque já utilizei no início do fonte

	/*
	aArea 	:= GetArea()
	aAreaSC6 	:= SC6->(GetArea())
	aAreaSC5	:= SC5->(GetArea())
	aProdDesc := {}  //array com os itens do pedido para avaliar regra de negocio
	nDescon		:= 0

	//busca os itens do pedido selecionado no Browser
	DbSelectArea("SC6")
	DbSetOrder(1)

	If DbSeek(xFilial("SC6")+SC5->C5_NUM)
		//Monta um array com os itens do pedido para passar pra funcao que avalia as regras de negocio
		While ( (!SC6->(EOF()) ) .AND.( SC6->(C6_FILIAL+C6_NUM) == xFilial("SC6")+SC5->C5_NUM ) )

			If ( SC6->C6_DESCONT == 0 .Or. ((SC5->C5_DESC1+SC5->C5_DESC2+SC5->C5_DESC3+SC5->C5_DESC4) <> 0) ) .And. SC6->C6_PRCVEN < SC6->C6_PRUNIT
				nDescon := (100 - (SC6->C6_PRCVEN / SC6->C6_PRUNIT) * 100)
			Else
				nDescon := SC6->C6_DESCONT
			EndIf

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³       Estrutura do array aProdDesc                                          ³
			//³       [1] - Codigo do Produto                                               ³
			//³       [2] - Item do Pedido de Venda                                         ³
			//³       [3] - Preco de Venda                                                  ³
			//³       [4] - Preco de Lista                                                  ³
			//³       [5] - % do Desconto Concedido no item do pedido                       ³
			//³       [6] - % do Desconto Permitido pela regra (FtRegraNeg)                 ³
			//³       [7] - Indica se sera necessario verificar o saldo de verba            ³
			//³                             01 - Bloqueio de regra de negocio               ³
			//³                             02 - Bloqueio para verificacao de verba         ³
			//³       [8] - Valor a ser abatido da verba caso seja aprovada (FtVerbaVen)    ³
			//³       [9] - Flag que indica se o item sera analisado nas regras             ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			Aadd(aProdDesc, {SC6->C6_PRODUTO, SC6->C6_ITEM, SC6->C6_PRCVEN, SC6->C6_PRUNIT,	nDescon, 0, "", 0,.T.})

			SC6->(DbSkip())

		End
	EndIf


	//avalia se existe bloqueio de regra
	lTLVReg1	:= FtRegraNeg(SC5->C5_CLIENTE, SC5->C5_LOJACLI, SC5->C5_TABELA	, SC5->C5_CONDPAG, NIL, @aProdDesc, .F., SC5->C5_VEND1, .T., .T.)

	SC6->(RestArea(aAreaSC6))
	SC5->(RestArea(aAreaSC5))
	RestArea(aArea)
	*/
	// MRBRanco - End


	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Exibe uma mensagêm dinâmica com os produtos que estão   ³
	//³com o desconto acima do permitido pela regra do negócio.³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	For nCont := 1 To Len(aProdDesc)
		If aProdDesc[nCont][7] == "02" //.Or. (!lTLVReg1 .And. Empty(aProdDesc[nCont][7]) )

			If nCont == 1 .Or. Empty(cMotRegrWF)
				cMotRegrWF += "Os seguintes produtos ocasionarão o bloqueio do pedido devido à regra de negócios referente ao desconto:" + CRLF
			Endif
			cMotRegrWF += AllTrim(aProdDesc[nCont][1]) + " atual " + Transform(aProdDesc[nCont][5],"@E 999,999.99") + " máximo permitido: " + Transform(aProdDesc[nCont][6],"@E 999,999.99") + CRLF  // " - atual: " // " máximo permitido: "
		Endif
		If aProdDesc[nCont][7] == "01" .And. !("Regra de negocios - bloqueada por produto não consta na regra." $ cMotRegrWF)
			cMotRegrWF	+= "Regra de negocios - bloqueada por produto não consta na regra."
		Endif
	Next nCont

	cMotSendWF	+= cMotRegrWF

	If !Empty(cMotSendWF) .And. SC5->C5_CLIENTE $ "03558806"
		sfSendWF(cMotSendWF,IsBlind())
	Endif


	// Tray
	If cEmpAnt $ "02" .And. FindFunction("U_TrayMTTS")
		U_TrayMTTS(_nOper)  // Função compilada no Rdmake TPEnt.prw
	EndIf

	//============================================================================================================================================================================
	//Fontes Vamilly referente as aprovações por Hierarquia.
	/*
		Aprovações por Hierarquia
		User - MRBranco - Vamilly
		Date - 05/07/2024
	*/

	// 3-Inclusão, 4-Alteração, 6-Cópia
	If (_nOper == 3 .Or. _nOper == 4 .Or. _nOper == 6) .And. !lOrcamento
		// lAlc - significa que teve bloqueio por campanha
		// lBlq - significa que teve bloqueio de regra de negócio
		If lAlc .Or. lBlqNeg
			If lAprHie // Indica se aprovação por alçada está ativada
				// Se não tiver desconto no cliente o nTopDesc é zero, pois pega o desconto do item na próxima rotina
				U_DECAT007(SC5->C5_VEND1, nTopDesc)
			EndIf
		Endif
	EndIf

	//============================================================================================================================================================================   

	Monitor_log.U_Record_Log(SC5->C5_NUM, ProcName() , "Antes do Return - Linha 1147" , .T.)

	RestArea(aAreaC6)
	RestArea(aAreaC5)
	RestArea(aArea)
Return


/*/{Protheus.doc} sfSendWF
(long_description)
@author MarceloLauschner
@since 29/10/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/

Static Function sfSendWF(cMotSendWF,lInIsAuto,cInIdUser,cInRecebe,cOrdemCompra)

	Local	cNumPed			:= SC5->C5_NUM
	Local 	oProcess      	:= Nil                                	//Objeto da classe TWFProcess.
	Local 	cMailId       	:= ""                                 	//ID do processo gerado.
	Local 	cHostWFExt    	:= GetNewPar("DC_URLWFEX",'http:/remoto.decanter.com.br:18089')	//URL configurado no ini para WF Link.
	Local 	cHostWFInt    	:= GetNewPar("DC_URLWFIN",'http:/192.168.0.230:8089')		   	//URL configurado no ini para WF Link.
	Local	nTotValor		:=	0
	Local 	nTotBruto		:=	0
	Local 	nTotPeso		:=  0
	Local 	nTotDesc 		:=  0
	Local	lSend			:= .F.
	Local 	cMailVend		:= ""
	Local	oDlgEmail
	Local	cRecebe			:= Padr(GetNewPar("DC_MT410ST","suporte@decanter.com.br;"),200)
	Local	cSubject		:= Padr("Aprovação de Pedido de Vendas --> "+ cNumPed,150)
	Local	cBody			:= Padr(" ",500)
	Local	cQry			:= ""
	Local	aRecebe			:= {"000000-suporte@decanter.com.br"}
	Local	iQ				:= 0
	Local	cBkProcess		:= ""
	Local	aArrSZS			:= {}
	Local	iL
	Default	lInIsAuto		:= .T.
	Default	cInIdUser		:= __cUserId
	Default cInRecebe		:= ""
	Default cOrdemCompra	:= SC5->C5_ZXPED
	Private	cUsrSendWf		:= ""

	// Monta lista de usuários diferente de Gerente

	cQry += "SELECT C5_VEND1,A3_EMAIL,A3_ZMAILWF "
	cQry += "  FROM "+ RetSqlName("SC5")+" C5,"+RetSqlName("SA3")+" A3A "
	cQry += " WHERE A3A.D_E_L_E_T_ = ' ' "
	cQry += "   AND A3A.A3_COD  = C5_VEND1 "
	cQry += "   AND A3A.A3_FILIAL = '"+xFilial("SA3")+"' "
	cQry += "   AND C5.D_E_L_E_T_ = ' ' "
	cQry += "   AND C5_NUM = '"+cNumPed+"' "
	cQry += "   AND C5_FILIAL = '"+xFilial("SC5")+"' "
	cQry += " ORDER BY 1,2 "

	//MemoWrite("/log_sqls/bffata30_sendwf.sql",cQry)

	dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQry),'QSZS', .F., .T.)

	While !Eof()

		// Verifica se tem o e-mail de Workflow no cadastro do vendedor
		nPos := aScan(aArrSZS,{|x|  x[1] == QSZS->A3_ZMAILWF })
		If nPos == 0 .And. !Empty(QSZS->A3_ZMAILWF)
			Aadd(aArrSZS,{QSZS->A3_ZMAILWF,QSZS->C5_VEND1 + "-"+ Alltrim(QSZS->A3_ZMAILWF)})
		Endif

		// Verifica se tem o email do Gerente
		nPos := aScan(aArrSZS,{|x|  x[1] == QSZS->A3_EMAIL })
		If nPos == 0 .And. !Empty(QSZS->A3_EMAIL)
			Aadd(aArrSZS,{QSZS->A3_EMAIL,QSZS->C5_VEND1 + "-"+ Alltrim(QSZS->A3_EMAIL)})
		Endif
		If !Empty(QSZS->A3_ZMAILWF)
			If !Empty(cMailVend)
				cMailVend	+= ";"
			Endif
			cMailVend += Alltrim(QSZS->A3_ZMAILWF)
		Endif

		If !Empty(QSZS->A3_EMAIL)
			If !Empty(cMailVend)
				cMailVend	+= ";"
			Endif
			cMailVend	+= Alltrim(QSZS->A3_EMAIL)
		Endif

		QSZS->(DbSkip())
	Enddo

	QSZS->(DbCloseArea())

	For iQ := 1 To Len(aArrSZS)
		nPos := aScan(aRecebe,{|x| x == aArrSZS[iQ,1]})
		If nPos == 0
			Aadd(aRecebe, aArrSZS[iQ,2] )
		Endif
	Next



	If !lInIsAuto

		//MsgAlert(cMotSendWF,"Bloqueios de Alçada!")

		DEFINE MSDIALOG oDlgEmail Title OemToAnsi(ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Enviar email para solicitação de aprovação!") FROM 001,001 TO 380,620 PIXEL

		@ 010,010 Say "Para: " Pixel of oDlgEmail
		@ 010,050 MsComboBox cRecebe Items aRecebe Size 180,10 Pixel Of oDlgEmail
		@ 025,010 Say "Assunto" Pixel of oDlgEmail
		@ 025,050 MsGet cSubject Size 250,10 Pixel Of oDlgEmail
		@ 040,050 Get cBody of oDlgEmail MEMO Size 250,100 Pixel

		@ 160,050 BUTTON "Envia Email" Size 70,10 Action (lSend := .T.,oDlgEmail:End())	Pixel Of oDlgEmail
		@ 160,130 BUTTON "Cancela" Size 70,10 Action (oDlgEmail:End())	Pixel Of oDlgEmail

		ACTIVATE MsDialog oDlgEmail Centered

		If !lSend
			Return
		Endif
	Endif
	//ConOut("Passou automatico linha 3983")
	For iL := 1 To Len(aRecebe)
		// Se for automático mando o link para todos
		If lInIsAuto
			If Empty(cInRecebe)
				cRecebe	:= aRecebe[iL]
			Else
				cRecebe	:= cInRecebe
			Endif
		Else
			// Se for manual paro no primeiro Loop
			If iL > 1
				Exit
			Endif
		Endif

		// Zera variaveis totalizadoras por causa do loop dos destinatários
		nTotValor		:=	0
		nTotBruto		:=	0
		nTotPeso		:=  0
		nTotDesc 		:=  0

		cUsrSendWf	:= Substr(cRecebe,1,6)

		// Código extraído do cadastro de processos.
		cCodProcesso := "PED003" // SOLICITACAO DE APROVACAO DE PEDIDO A DIRETORIA

		If IsSrvUnix()
			// Arquivo html template utilizado para montagem da aprovação
			cHtmlModelo	:= "/workflow/aprovacao_pedido.htm"
			If !File(cHtmlModelo)
				ConOut("Não localizou arquivo "+cHtmlModelo)
				Return
			Endif
		Else
			cHtmlModelo	:= "\workflow\aprovacao_pedido.htm"
			If !File(cHtmlModelo)
				ConOut("Não localizou arquivo "+cHtmlModelo)
				Return
			Endif
		Endif


		// Assunto da mensagem
		cAssunto 	:= cSubject


		cEmail		:= Substr(cRecebe,8)
		oProcess 	:= TWFProcess():New(cCodProcesso, cAssunto )

		oProcess:NewTask(cAssunto, cHtmlModelo)

		cBkProcess	:= oProcess:fProcessID
		// Repasse o texto do assunto criado para a propriedade especifica do processo.

		DbSelectArea("SC5")
		DbSetOrder(1)
		DbSeek(xFilial("SC5")+cNumPed)

		DbSelectArea("SA1")
		DbSetOrder(1)
		DbSeek(xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI)

		oProcess:oHTML:ValByName("NOMECOM"		,AllTrim(SM0->M0_NOMECOM))
		oProcess:oHTML:ValByName("ENDEMP"		,Capital(AllTrim(SM0->M0_ENDENT)) + " - " + Capital(SM0->M0_BAIRENT))
		oProcess:oHTML:ValByName("COMEMP"		,Transform(SM0->M0_CEPENT,"@R 99999-999") + " - " + Capital(AllTrim(SM0->M0_CIDENT)) + " - " + SM0->M0_ESTENT)
		oProcess:oHTML:ValByName("FONE"			,"Fone/Fax: " + SM0->M0_TEL)
		oProcess:oHTML:ValByName("USUARIO"		,cUsrSendWf			)
		oProcess:oHtml:ValByName("EMAILUSER"	,cMailVend	,"M410STTS")
		oProcess:oHTML:ValByName("C5_NUM"		,SC5->C5_NUM		)
		oProcess:oHTML:ValByName("C5_EMISSAO"	,SC5->C5_EMISSAO	)
		oProcess:oHTML:ValByName("C5_CLIENTE"	,SC5->C5_CLIENTE	)
		oProcess:oHTML:ValByName("C5_LOJACLI"	,SC5->C5_LOJACLI	)
		oProcess:oHTML:ValByName("A1_NOME"		,SA1->A1_NOME		)
		oProcess:oHTML:ValByName("A1_END"		,SA1->A1_END		)

		oProcess:oHTML:ValByName("A1_COMPLEM"	,SA1->A1_COMPLEM		)
		oProcess:oHTML:ValByName("C5_TRANSP"	,SC5->C5_TRANSP	+ "-" + Posicione("SA4",1,xFilial("SA4")+SC5->C5_TRANSP,"A4_NREDUZ")	)
		oProcess:oHTML:ValByName("A4_NREDUZ"	,SA4->A4_NREDUZ		)
		oProcess:oHTML:ValByName("A1_BAIRRO"	,SA1->A1_BAIRRO		)
		oProcess:oHTML:ValByName("A1_MUN"		,SA1->A1_MUN		)
		oProcess:oHTML:ValByName("A1_EST"		,SA1->A1_EST		)
		oProcess:oHTML:ValByName("C5_VEND1"		,SC5->C5_VEND1 + "-" + Posicione("SA3",1,xFilial("SA3")+SC5->C5_VEND1,"A3_NREDUZ")	)
		oProcess:oHTML:ValByName("C5_VEND2"		,SC5->C5_VEND2 + "-" + Posicione("SA3",1,xFilial("SA3")+SC5->C5_VEND2,"A3_NREDUZ")	)
		oProcess:oHTML:ValByName("C5_CONDPAG"	,SC5->C5_CONDPAG + "-" + Posicione("SE4",1,xFilial("SE4")+SC5->C5_CONDPAG,"E4_DESCRI")	)
		oProcess:oHTML:ValByName("A1_TABELA"	,SC5->C5_TABELA + "-" + Posicione("DA0",1,xFilial("DA0")+SC5->C5_TABELA,"DA0_DESCRI")	)
		oProcess:oHTML:ValByName("C5_MSGINT"	,Iif(Empty(cOrdemCompra),"","Ordem Compra:"+cOrdemCompra) + SC5->C5_ZMSGINT )
		oProcess:oHTML:ValByName("C5_MENNOTA"	,SC5->C5_MENNOTA	)


		cQry := "SELECT C6_ITEM,C6_QTDVEN,C6_PRODUTO,C6_LOCAL,C6_PRUNIT,C6_PRCVEN,C6_VALOR,B1_DESC,B1_PESO,C6_BLOQUEI "
		cQry += "  FROM " + RetSqlname("SC6")+" C6 "
		cQry += " INNER JOIN " +RetSqlName("SB1") + " B1 "
		cQry += "    ON B1.D_E_L_E_T_ = '  ' "
		cQry += "   AND B1_COD = C6_PRODUTO "
		cQry += "   AND B1_FILIAL = '" + xFilial("SB1") + "' "
		cQry += " WHERE C6_FILIAL = '"+xFilial("SC6")+"'  "
		cQry += "   AND C6_NUM = '"+cNumPed+"'  "
		cQry += "   AND C6.D_E_L_E_T_ <> '*' "

		TCQUERY cQry NEW ALIAS "TMPPED"

		While TMPPED->(!Eof())


			//CalcEst((cAlias)->C6_PRODUTO,(cAlias)->C6_LOCAL,dDataBase)[1]
			DbSelectArea("SB2")
			DbSetOrder(1)
			If DbSeek(xFilial("SB2")+TMPPED->C6_PRODUTO+TMPPED->C6_LOCAL)
				nEstDisp	:= 	SB2->B2_QATU - SB2->B2_RESERVA
			Else
				nEstDisp	:= 0
			Endif

			cQry := "SELECT TOP 1 D2_PRCVEN,D2_EMISSAO,D2_QUANT"
			cQry += "  FROM " + RetSqlName("SD2") + " D2 "
			cQry += " WHERE D2.D_E_L_E_T_ =' ' "
			cQry += "   AND D2_LOJA = '"+SC5->C5_LOJACLI + "' "
			cQry += "   AND D2_CLIENTE = '" + SC5->C5_CLIENTE + "' "
			cQry += "   AND D2_COD = '" + TMPPED->C6_PRODUTO + "' "
			cQry += "   AND D2_FILIAL = '" + xFilial("SD2") + "' "
			cQry += " ORDER BY D2_EMISSAO DESC,D2_DOC DESC "

			TcQuery cQry New Alias "QSD2"

			If QSD2->(!Eof())

				AAdd((oProcess:oHtml:ValByName("it.uqtd"))		,QSD2->D2_QUANT)
				AAdd((oProcess:oHtml:ValByName("it.udat"))		,DTOC(STOD(QSD2->D2_EMISSAO)))
				AAdd((oProcess:oHtml:ValByName("it.uprc"))		,Transform(QSD2->D2_PRCVEN,"@E 999,999,999.99"))

			Else
				AAdd((oProcess:oHtml:ValByName("it.uqtd"))		,0)
				AAdd((oProcess:oHtml:ValByName("it.udat"))		,"")
				AAdd((oProcess:oHtml:ValByName("it.uprc"))		,Transform(0,"@E 999,999,999.99"))

			Endif
			QSD2->(DbCloseArea())
			AAdd((oProcess:oHtml:ValByName("it.item"))		,TMPPED->C6_ITEM)
			AAdd((oProcess:oHtml:ValByName("it.cod"))		,TMPPED->C6_PRODUTO )
			AAdd((oProcess:oHtml:ValByName("it.desc"))		,TMPPED->B1_DESC )
			AAdd((oProcess:oHtml:ValByName("it.sts"))		,TMPPED->C6_BLOQUEI)

			AAdd((oProcess:oHtml:ValByName("it.saldo"))		,nEstDisp)
			AAdd((oProcess:oHtml:ValByName("it.qte"))		,TMPPED->C6_QTDVEN)
			AAdd((oProcess:oHtml:ValByName("it.prctab"))	,Transform(TMPPED->C6_PRUNIT,"@E 999,999,999.99"))



			nDescItem := Round((TMPPED->C6_PRUNIT - TMPPED->C6_PRCVEN ) / TMPPED->C6_PRUNIT * 100,2)

			AAdd((oProcess:oHtml:ValByName("it.desconto"))	,Transform(nDescItem,"@E 999.99"))
			AAdd((oProcess:oHtml:ValByName("it.prcven"))	,Transform(TMPPED->C6_PRCVEN,"@E 999,999,999.99"))
			AAdd((oProcess:oHtml:ValByName("it.total"))		,Transform(TMPPED->C6_VALOR,"@E 999,999,999.99"))
			AAdd((oProcess:oHtml:ValByName("it.peso"))		,Transform(TMPPED->(C6_QTDVEN*B1_PESO),"@E 999,999,999.999"))

			nTotValor		+=  TMPPED->C6_PRCVEN * TMPPED->C6_QTDVEN
			nTotBruto		+=	TMPPED->C6_PRUNIT * TMPPED->C6_QTDVEN
			nTotPeso		+=  TMPPED->(C6_QTDVEN*B1_PESO)
			nTotDesc 		+=  (TMPPED->C6_PRUNIT - TMPPED->C6_PRCVEN ) * TMPPED->C6_QTDVEN

			TMPPED->(dbSkip())
		Enddo

		TMPPED->(dbCloseArea())



		oProcess:oHTML:ValByName("TOTBRUTO"		,Transform(nTotBruto,"@E 999,999,999.99")	)
		oProcess:oHTML:ValByName("TOTDESC"		,Transform(nTotDesc / nTotBruto * 100,"@E 999,999,999.99")	)
		oProcess:oHTML:ValByName("TOTVALOR"		,Transform(nTotValor,"@E 999,999,999.99")	)

		oProcess:oHTML:ValByName("TOTPESO"		,Transform(nTotPeso,"@E 999,999,999.99")			)

		oProcess:oHTML:ValByname("OBSERV"		,StrTran(cBody,CRLF,"<br>")			)

		oProcess:oHTML:ValByname("BLQALCADAS"	,StrTran(cMotSendWF,CRLF,"<br>")			)


		oProcess:oHTML:ValByName("data"			,Date()		)
		oProcess:oHTML:ValByName("hora"			,Time()		)
		oProcess:oHTML:ValByName("rdmake"		,FunName()+"."+ProcName(0)	)

		oProcess:cTo	:= cInIdUser//cUsuarioProtheus

		oProcess:oHTML:ValByName("DESTINATARIOS"		,cEmail)

		oProcess:aParams := {{'01',cInIdUser},{'02',cEmail}}


		// Informamos qual função será executada no evento de timeout.
		oProcess:bTimeOut        := {{"U_MLFATM03(1)", 0, 0, 5 }}
		// Informamos qual função será executada no evento de retorno.
		oProcess:bReturn        :=  "U_MLFATM03(2)"
		// Iniciamos a tarefa e recuperamos o nome do arquivo gerado.
		cMailID := oProcess:Start()

		If IsSrvUnix()
			// Arquivo html template utilizado para montagem da aprovação
			cHtmlModelo	:= "/workflow/aprovacao_pedido_link.htm"
			If !File(cHtmlModelo)
				ConOut("Não localizou arquivo "+cHtmlModelo)
				Return
			Endif
		Else
			cHtmlModelo	:= "\workflow\aprovacao_pedido_link.htm"
		Endif

		// Crie uma tarefa.
		oProcess:NewTask(cAssunto, cHtmlModelo)

		ConOut("(INICIO|WFLINK)Processo: " + oProcess:fProcessID + " - Task: " + oProcess:fTaskID )
		// Repasse o texto do assunto criado para a propriedade especifica do processo.

		oHTML := oProcess:oHTML

		oHtml:ValByName("NOMECOM"		,AllTrim(SM0->M0_NOMECOM))
		oHtml:ValByName("ENDEMP"		,Capital(AllTrim(SM0->M0_ENDENT)) + " - " + Capital(SM0->M0_BAIRENT))
		oHtml:ValByName("COMEMP"		,Transform(SM0->M0_CEPENT,"@R 99999-999") + " - " + Capital(AllTrim(SM0->M0_CIDENT)) + " - " + SM0->M0_ESTENT)
		oHtml:ValByName("FONE"			,"Fone/Fax: " + SM0->M0_TEL)
		oHtml:ValByName("EMAILUSER"		,Posicione("SA3",1,xFilial("SA3") + SC5->C5_VEND1,"A3_ZMAILWF")+";"+UsrRetMail(cInIdUser))

		oHtml:ValByName("C5_NUM"		,SC5->C5_NUM	)
		oHtml:ValByName("C5_CLIENTE"	,SC5->C5_CLIENTE	)
		oHtml:ValByName("C5_LOJACLI"	,SC5->C5_LOJACLI	)
		oHtml:ValByName("A1_NOME"		,SA1->A1_NOME		)
		oHtml:ValByname("OBSERV"		,StrTran(cBody,CRLF,"<br>")				)
		oHtml:ValByName("proc_link_ext"	,cHostWFExt + "/messenger/emp" + cEmpAnt + "/"+cInIdUser+"/" + cMailId + ".htm")
		oHtml:ValByName("nome_link_ext"	,cHostWFExt + "/messenger/emp" + cEmpAnt + "/"+cInIdUser+"/" + cMailId + ".htm")

		oHtml:ValByName("proc_link_int"	,cHostWFInt + "/messenger/emp" + cEmpAnt + "/"+cInIdUser+"/" + cMailId + ".htm")
		oHtml:ValByName("nome_link_int"	,cHostWFInt + "/messenger/emp" + cEmpAnt + "/"+cInIdUser+"/" + cMailId + ".htm")

		oHtml:ValByName("data"			,Date()		)
		oHtml:ValByName("hora"			,Time()		)
		oHtml:ValByName("rdmake"		,FunName()+"."+ProcName(0)	)

		oProcess:cTo := cEmail

		oHtml:ValByName("DESTINATARIOS"		,cEmail)

		oProcess:cSubject := cAssunto

		oProcess:Start()
	Next

Return

