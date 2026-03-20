#INCLUDE "PARMTYPE.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "RWMAKE.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "AP5MAIL.CH"
#INCLUDE "TBICONN.CH"

/*/{Protheus.doc} DECAT008
Rotina de para
@type function
@version  2210
@author Vamilly - MRBranco
@since 09/07/2024
@param cAChave, character, chave
@param cAObs, character, observaçoes da aprovação ou rejeição
@param cSCRType, character,
@return variant, HTML
/*/
Static cKeyCR  := "_A"       // Chave da SCR
Static cGreen  := "#006A68" //"#00CED1"  // DarkTurquoise (0,206,209)
Static cRed    := "#DC143C"  // Crimson (220,20,60)
Static cYellow := "#e5c743"  // Yellow

User Function DECAT008(cAChave,cAObs, cSCRType)

	Local cHtml 	:= ""
	Local cColor    := cRed

	Private cKeyNum  := ""
	Private cKeyUser := ""
	Private cKeyOper := ""
	Private cKeyRecn := ""
	Private cKeyInEx := ""

	DEFAULT cAObs	:= ""

	Conout("[DECAT008] - Numero da chave: ")
	Conout(cAChave)

	Conout("[DECAT008] - OBS [" + cAObs + "]")

	// Valida se a chave informada no link foi recebida conforme padrão
	If Len(cAChave) >= 15
		// Padrão Chave do Processo
		//                                   123456789012345678901234567890
		// Motagem da chave conforme padrão: NNNNNNUUUUUUOOORRRRRRRRRRRRRRR
		Conout("[DECAT008] - Entrou aqui ")
		cKeyNum  := SubStr(cAChave,1,6)		// NNNNNN 			- Número do Pedido de Compras
		cKeyUser := SubStr(cAChave,7,6)		// UUUUUU 			- Usuário Aprovador
		cKeyOper := SubStr(cAChave,13,3)	// OOO	  			- Operação (APR/ BLQ)
		cKeyRecn := SubStr(cAChave,16,15)	// RRRRRRRRRRRRRRR	- Recno SCR
		cKeyInEx := SubStr(cAChave,31,01)	// S             	- Link Interno ou Externo
	Else
		Conout("[DECAT008] - Entrou aqui 1 ")
		cHtml	:=  U_HtmlRet("A chave do processo informada é inválida! Entre em contato com o Departamento de TI", cColor)
	EndIf

	If Empty(cHtml)

		// Caso o html for vazio, é porque a SCR está pendente
		If Empty(cHtml)
			//If cKeyOper == "APR" .OR. (cKeyOper == "BLQ" .And. !Empty(cAObs))
			If !Empty(cAObs)
				Conout("[DECAT008] - Entrou aqui 2 ")
				cHtml := U_DECAT08RUN(cKeyNum,cKeyUser,cKeyOper,DecodeUTF8(cAObs, "cp1252"),cKeyRecn,cKeyInEx,cSCRType)
			Else
				Conout("[DECAT008] - Entrou aqui 3 ")
				// Esta função retorna um html com a situação caso a situação não seja pendente
				cHtml := fVldStaPC(cKeyNum,cKeyUser,cKeyOper,cKeyRecn,cKeyInEx,cSCRType)
				If Empty(cHtml)
					cHtml := fGetHtmObs(cEmpAnt,cFilant,cKeyNum,cKeyUser,cKeyOper,cKeyRecn,cKeyInEx,cSCRType)
				EndIf
			EndIf
		EndIf
	EndIf

Return cHtml

/*/{Protheus.doc} DECAT08RUN
    Executa processo de validação de alçadas, aprovação ou rejeição
    @type  Function
    @author Vamilly - MRBranco
    @since 09/07/2024
    @param cNumPC, Character, pedido de venda
    @param cUserApr, Character, usuário que irá aprovar ou reprovar
    @param cOperc, Character, APR=Aprovação / BLQ=Rejeição
    @param cObserv, Character, pedido de venda
    @param cRecn, Character, recno da SCR
    @param cInEx, Character, link externo ou interno
    @param cSCRType, Character, tipo de registro na SCR
    @return Character, cRet, vazio ou html com alguma mensagem de problema
/*/
User Function DECAT08RUN(cNumPC,cUserApr,cOperc,cObserv,cRecn,cInEx,cSCRType)
	Local cRet		:= ""
	Local aRetSaldo	:= {}
	Local nTotal	:= 0
	Local lLiberou	:= .F.
	Local lOk		:= .T.
	Local nOpc		:= 0
	Local lDescont  := cSCRType == cKeyCR
	Local cColor    := cRed

	nOpc := IIF(cOperc=='APR',4,6)

	If !Empty(cRet := fVldStaPC(cNumPC,cUserApr,cOperc,cRecn,cInEx,cSCRType))
		lOk := .F.
	EndIf

	BEGIN TRANSACTION
		If lOk

			DBSelectArea("SCR")
			SCR->(DBSetOrder(2))	// CR_FILIAL+CR_TIPO+CR_NUM+CR_USER
			SCR->(DBGoTop())
			If SCR->(DBSeek(xFilial("SCR")+cSCRType+PADR(cNumPC,TamSx3("CR_NUM")[1],"")+cUserApr))

				SC5->(DBSetOrder(1))
				SC5->(DBSeek(xFilial("SC5")+Substr(SCR->CR_NUM,1,6)))

				aRetSaldo := MaSalAlc(SCR->CR_APROV,dDataBase)
				nTotal 	  := xMoeda(SCR->CR_TOTAL,SCR->CR_MOEDA,aRetSaldo[2],SCR->CR_EMISSAO,,SCR->CR_TXMOEDA)

				If nOpc = 4 // Liberação

					lLiberou  := MaAlcDoc({SCR->CR_NUM,SCR->CR_TIPO,nTotal,SCR->CR_APROV,,SCR->CR_GRUPO,,,,,},dDataBase,nOpc)
					lLiberou  := fVldSitPed(SCR->CR_NUM, SCR->CR_GRUPO, SCR->(Recno()),cSCRType)

					If lLiberou // Verifica se o PC foi aprovado totalmente


						If cSCRType $ cKeyCR

							/* Grava campo de identificação de aprovação por alçada  C5_XALCAD
                                ""  := Sem Alçada
                                "0" := Aguardando aprovação por alçada
                                "1" := Aprovado por alçada
                                "2" := Rejeitado por alçada
							*/
							Reclock("SC5",.F.)
							SC5->C5_LIBEROK := " "
							SC5->C5_BLQ     := " "
							SC5->C5_ZBLQCOM := SC5->C5_ZBLQCOM + CRLF + "Pedido aprovado por  [" + UsrFullName(SCR->CR_USERLIB) + "] em " + DtoC(SCR->CR_DATALIB) + " as " + Time()
							SC5->C5_SITDEC  := " "
							SC5->(MsUnlock())

							// Função para liberar automatico o pedido.
							U_DECATLIBPD()

							// Grava observação na SCR.
							Reclock("SCR",.F.)
							SCR->CR_OBS := cObserv
							SCR->(MsUnlock())

							// E-mail de aprovação (04) para o comprador
							cRet := U_DECAT08WF(Substr(SC5->C5_NUM,1,6),"04",lDescont)
							cColor := cGreen // verde
							cRet := u_HtmlRet("O Pedido de Venda [" + cKeyNum + "] foi APROVADO com sucesso! " + IIF(!Empty(cRet),"!! Falha no envio de e-mail da sequência! " + cRet,""), cColor)
						Endif

					Else

						If SCR->CR_STATUS == '03' // Status = 03, registro atual aprovado
							//E-mail para o próximo nível (03)
							Reclock("SCR",.F.)
							SCR->CR_OBS := cObserv
							SCR->(MsUnlock())
							cRet := U_DECAT08WF(Substr(SC5->C5_NUM,1,6),"03",lDescont)
							cColor := cGreen // verde
							cRet := u_HtmlRet("O Pedido de Venda [" + cKeyNum + "] foi APROVADO com sucesso! " + IIF(!Empty(cRet),"!! Falha no envio de e-mail da sequência! " + cRet,""), cColor)
						Else	// Se o registro atual não foi aprovado (cr_status <> 03) é porque algum problema aconteceu.
							cRet := u_HtmlRet("Falha na análise do Pedido de Venda [" + cKeyNum + "]. Realize o procedimento utilizando o sistema Protheus!", cColor)
						EndIf

					EndIf

				Else  // Bloqueio

					// Estorna a liberação do pedido ao ser rejeitado
					DBSelectArea("SC9")
					DBSetOrder(1)
					IF DBSeek(xFilial("SC9")+SC5->C5_NUM)
						While SC9->(!EOF()) .AND. SC9->C9_PEDIDO = SC5->C5_NUM
							If SC9->(!Deleted())
								A460Estorna(.T.)
								SC9->(DBSkip())
							Endif
						End
					EndIf

					Reclock("SCR",.F.)
					SCR->CR_OBS := cObserv
					SCR->(MsUnlock())

					cAXNivel 	:= SCR->CR_NIVEL
					cAGrupo 	:= SCR->CR_GRUPO
					cAAprovOri 	:= SCR->CR_APROV
					cAUserOri 	:= SCR->CR_USER
					lLiberou	:= .F.

					SCR->(DBSetOrder(1))
					SCR->(DBSeek(xFilial("SCR")+cSCRType+PADR(cKeyNum,TamSx3("CR_NUM")[1],"")+cAXNivel))
					While !SCR->(EOF()) .And. SCR->(CR_FILIAL+CR_TIPO+CR_NUM) == xFilial("SCR")+cSCRType+PADR(cKeyNum,TamSx3("CR_NUM")[1],"")
						If SCR->(CR_GRUPO) == cAGrupo
							RecLock("SCR",.F.)
							SCR->CR_DATALIB := dDataBase
							SCR->CR_USERLIB := cAUserOri
							SCR->CR_LIBAPRO := cAAprovOri
							If SCR->CR_APROV == cAAprovOri .And. SCR->CR_NIVEL == cAXNivel
								SCR->CR_STATUS := "06"
							Else
								SCR->CR_STATUS := "05"
							EndIf
							SCR->(MsUnLock())
						EndIf
						SCR->(DBSkip())
					EndDo

					// Voltar pedido rejeitado com observação do do bloqueio
					Reclock("SC5",.F.)
					SC5->C5_BLQ     := "1"
					SC5->C5_SITDEC  := "6" // Bolqueio , nomitor de pedidos
					SC5->C5_ZBLQCOM := SC5->C5_ZBLQCOM + CRLF + "Pedido rejeitado por [" + UsrFullName(cAUserOri) + "] em " + DtoC(dDataBase) + " as " + Time()
					//SC5->C5_ZMOTREJ := SC5->C5_ZMOTREJ + CRLF + "Pedido rejeitado por [" + UsrFullName(SCR->CR_USERLIB) + "] em " + DtoC(SCR->CR_DATALIB) + " as " + Time()
					SC5->(MsUnlock())

					If !lLiberou

						//E-mail de bloqueio (05)
						cRet := U_DECAT08WF(cKeyNum,"05",lDescont)
						cRet := u_HtmlRet("O Pedido de Venda [" + cKeyNum + "] foi BLOQUEADO com sucesso! " + IIF(!Empty(cRet),"!! Falha no envio de e-mail da sequência! " + cRet,""), cColor)

					Else
						cRet := u_HtmlRet("Falha na análise do Pedido de Venda [" + cKeyNum + "]. Realize o procedimento utilizando o sistema Protheus!", cColor)
					EndIf

				EndIf //nOpc = 4

			EndIf // seek SCR

		EndIf // lOk

	END TRANSACTION

Return cRet

/*/{Protheus.doc} DECAT08WF
    Função de montagem de html e envio de WF's do Processo de aprovação pedido de vendas
    @type  Function
    @author Vamilly - MRBranco
    @since 09/07/2024
    @param cANum, Character, pedido de venda
    @param cOpcao, Character, opções da função
    	                        01-Inclusão de PV
                                02-Alteração de PV
                                03-Próximo Nível
                                04-Pedido Aprovado
                                05-Pedido Bloqueado
                                10-Aprovação Desconto
    @param lDescont, Logical, indica se a chamada é da rotina de desconto
    @return Character, cRet, vazio ou alguma mensagem com problema
/*/
User Function DECAT08WF(cANum,cOpcao,lDescont)
	Local aPreApro   := {}
	Local aProdutos  := {}
	Local cAssunto   := ""
	Local cBodyAprov := ""
	Local cBodyItens := ""
	Local cCond      := ""
	Local cData      := ""
	Local cDesStatus := ""
	Local cEmailVend := ""
	Local cEndMail   := ""
	Local cForn      := ""
	Local cUserAprov := ""
	Local cUserApr   := ""
	Local cUserLib   := ""
	Local cPath      := GetSrvProfString("STARTPATH" , "") + "extras\DECAT008\html\"
	Local cHtml      := MemoRead(cPath + "index.html")
	Local cHtmlApro  := MemoRead(cPath + "table_aprovacao.html")
	Local cHtmlItens := MemoRead(cPath + "table_itens.html")
	Local cLink      := ""
	Local cRet       := ""
	Local cText1     := ""
	Local cText2     := ""
	Local cTextDes   := ""
	Local nI         := 0
	Local nTotD      := 0
	Local nTotP      := 0
	Local nX         := 0
	Local nDesApliP  := 0   As Numeric // Desconto aplicado campo padrão
	Local nDesPercP  := 0   As Numeric // % aplicado campo padrão
	Local nDesApliC  := 0   As Numeric // Desconto aplicado campos customizado
	Local nDesPerHie := 0   As Numeric // Total de desconto aplicado para solcitar aprovação
	Local nDescPerm  := 0   As Numeric // % de desconto permito
	Local nTotItem   := 0   As Numeric
	Local vValPerm   := 0   As Numeric
	Local nValAplic  := 0   As Numeric
	Local nValDifPer := 0   As Numeric

	/*/
	01-Inclusão de PC
	02-Alteração de PC
	03-Próximo Nível
	04-Pedido Aprovado
	05-Pedido Bloqueado
	10-Aprovação Desconto
	/*/
	cSCRType := cKeyCR

	// Ajuste do link WEB de controle de documentos
	cLink := fLnkWSRest()

	If Empty(cLink)
		cRet += "Configuração do parâmetro DC_URLREST inválida!"
		Return cRet
	EndIf

	// Posiciona na SC5 senão estiver
	If SC5->C5_NUM != Left(cANum, 6)
		SC5->(DBSetOrder(1))
		SC5->(DBSeek(xFilial("SC5") + cANum))
	Endif

	// Posiciona Vendedor
	SA3->(DBSetOrder(1))
	SA3->(DBSeek(xFilial("SA3") + SC5->C5_VEND1))

	// Busca os aprovadores da sequência e as observações
	SCR->(DBSetOrder(1)) // CR_FILIAL + CR_TIPO + CR_NUM
	SCR->(DBGoTop())
	If SCR->(DBSeek(xFilial("SCR") + cSCRType + cANum))
		While !SCR->(EOF()) .AND. (SCR->CR_FILIAL+SCR->CR_TIPO+ALLTRIM(SCR->CR_NUM)) == (xFilial("SCR")+cSCRType+cANum)

			// Nível status
			If SCR->CR_STATUS == "01"
				cDesStatus := "Aguardando niveis anteriores"
			Elseif SCR->CR_STATUS == "02"
				cDesStatus := "Pendente"
			Elseif SCR->CR_STATUS == "03"
				cDesStatus := "Aprovado"
			ElseIf SCR->CR_STATUS == "04"
				cDesStatus := "Bloqueado"
			ElseIf SCR->CR_STATUS == "05"
				cDesStatus := "Liberado outro aprovador"
			ElseIf SCR->CR_STATUS == "06"
				cDesStatus := "Rejeitado"
			Else
				cDesStatus := "Rejeitado outro aprovador"
			EndIf

			// Usuários de aprovação
			cUserApr   := UsrFullName(SCR->CR_USER)
			cUserLib   := UsrFullName(SCR->CR_USERLIB)

			//<tr><td>@@SEQUENCIA@@</td><td>@@APROVADOR@@</td><td>@@STATUS@@</td><td>@@DATA@@</td><td>@@COMENTARIO@@</td></tr>
			Aadd(aPreApro,{ SCR->CR_NIVEL,;
				IIf(Empty(cUserLib), cUserApr, cUserLib),;
				cDesStatus,;
				IIF(Empty(SCR->CR_DATALIB), "", DTOC(SCR->CR_DATALIB)),;
				SCR->CR_OBS} )

			SCR->(DBSkip())
		EndDo
	Else
		cRet += "Não encontrou aprovador"
		Return cRet
	EndIf

	// Ajuste do texto para cada tipo de envio
	cTextDes := If(lDescont,"Descontos","")


	// Textos
	If cOpcao $ "01/02/03/10"
		cText1 := "Análise " + cTextDes + " do Pedido de Venda: " + cANum
	ElseIf cOpcao $ "04/05"
		If cOpcao = "04" .And. !lDescont
			cText1 := "Aprovação " + cTextDes + " do Pedido de Venda: " + cANum
			cText2 := "<span style='background-color:" + cGreen + "; color:#FFFAFA; font-size:15px; padding: 5px 10px; text-decoration:none; display: inline-block;'>APROVADO </span>"
		Elseif cOpcao = "04" .And. lDescont
			cText1 := "Aprovação Desconto do Pedido de Venda: " + cANum
			cText2 := "<span style='background-color:" + cRed + "; color:#FFFAFA; font-size:15px; padding: 5px 10px; text-decoration:none; display: inline-block;'>BLOQUEADO </span>"
		Elseif cOpcao = "05"
			cText1 := "Rejeição Desconto do Pedido de Venda: " + cANum
			cText2 := "<span style='background-color:" + cRed + "; color:#FFFAFA; font-size:15px; padding: 5px 10px; text-decoration:none; display: inline-block;'>BLOQUEADO </span>"
		Else
			cText1 := "Rejeição " + cTextDes + " do Pedido de Venda: " + cANum
			cText2 := "<span style='background-color:" + cRed + "; color:#FFFAFA; font-size:15px; padding: 5px 10px; text-decoration:none; display: inline-block;'>BLOQUEADO </span>"
		EndIf
	EndIf

	If cOpcao $ "01/02/03/10" .Or. lDescont
		cText1 := cText1
	Else
		cText1 += "O Pedido de Venda  " + cANum + " foi  " + cText2 + " "
	EndIf

	// Subject
	cAssunto := cText1

	// Varre os itens para enviar email
	DBSelectArea("SB1")
	DBSelectArea("SC6")
	If SC6->(DBSeek(xFilial("SC6") + cANum))
		While SC6->(!Eof()) .And. SC6->C6_FILIAL  + SC6->C6_NUM = xFilial("SC6") + cANum

			SB1->(DBSetOrder(1))
			SB1->(DBSeek(xFilial("SB1")+SC6->C6_PRODUTO))
			cForn     := SC6->C6_CLI + "/" + SC6->C6_LOJA + "-" + AllTrim(Posicione("SA1",1,xFilial("SA1")+SC6->C6_CLI+SC6->C6_LOJA,"A1_NOME"))
			cData     := DTOC(SC5->C5_EMISSAO)
			cCond     := AllTrim(Posicione("SE4",1,xFilial("SE4")+SC5->C5_CONDPAG,"E4_DESCRI"))

			// e-mail do vendedor
			SA3->(DBSetOrder(1))
			SA3->(DBSeek(xFilial("SA3")+SC5->C5_VEND1))
			cEmailVend := AllTrim(SA3->A3_EMAIL)
			cVendedor  := SC5->C5_VEND1 + " - " + AllTrim(SA3->A3_NOME)

			// e-mail do gerente
			SA1->(DBSetOrder(1))
			SA1->(DBSeek(xFilial("SA1") + SC5->(C5_CLIENTE+C5_LOJACLI)))

			nTotItem  := SC6->C6_VALOR+((SC6->C6_VALOR*100)/SC6->C6_ZDESITE)
			nDesApliP := SC6->C6_VALDESC // Vlr Desconto
			nDesPercP := SC6->C6_DESCONT // % Desconto
			nDesApliC := SC6->C6_ZDESITE // Campo customizado Decanter %
			nDescPerm := U_DECAT07C(SC5->C5_VEND1,SC6->C6_PRODUTO,nDesApliC)

			// Calcula o valor do desconto para a aprovação
			vValPerm   := ((nTotItem * nDescPerm)/100)
			nValApli   := ((nTotItem * nDesApliC)/100)
			nValDifPer := nDesApliC - nDescPerm

			// Somar totalizadores
			nTotP += nValAplic // Total desconto aplicado
			nTotD += vValPerm // Total desconto permitido

			// Verifica se o desconto aplicado é maior que o permitido
			If nDesApliC > nDescPerm
				// Maior desconto aplicado
				If nDesApliC > nDesPerHie
					nDesPerHie := nDesApliC
					nDesPercP  := nDescPerm
				EndIf
			EndIf

			Aadd(aProdutos,{/*01*/SC6->C6_ITEM,;
				/*02*/SC6->C6_PRODUTO,;
				/*03*/SC6->C6_DESCRI,;
				/*04*/SC6->C6_QTDVEN,;
				/*05*/SC6->C6_PRCVEN,;
				/*06*/SC6->C6_VALOR,;
				/*07*/nDesApliC,;
				/*08*/nValAplic,;
				/*09*/nDescPerm,;
				/*10*/vValPerm,;
				/*11*/nValDifPer})

			SC6->(DBSkip())
		EndDo
	Else
		cRet += "Não encontrou itens pedido (sc6)"
		Return cRet
	EndIf

	// Preenche as variaveis do Cabeçalho left
	cHtml	:= StrTran(cHtml,'@@TITLE@@',AllTrim(cText1))
	cHtml	:= StrTran(cHtml,'@@TYPE@@', IIf(cOpcao $ "01/10"," Inclusão, ",IIf(cOpcao="02"," Alteração, "," ")))

	// tabela 1
	cHtml	:= StrTran(cHtml,'@@NUMERO_PEDIDO@@',AllTrim(cANum))
	cHtml	:= StrTran(cHtml,'@@DATA_EMISSAO@@',AllTrim(cData))
	cHtml	:= StrTran(cHtml,'@@CLIENTE@@',AllTrim(cForn))
	cHtml	:= StrTran(cHtml,'@@NOMEVENDEDOR@@',AllTrim(If(Empty(cVendedor),"SEM VENDEDOR",cVendedor)))
	cHtml	:= StrTran(cHtml,'@@DESC_CONDICAO@@'             ,AllTrim(cCond))
	cHtml	:= StrTran(cHtml,'@@DESC_CLIENTE@@'              ,AllTrim(Transform(SA1->A1_DESC,"@E 999,999,999.99")))
	cHtml	:= StrTran(cHtml,'@@VLR_PEDIDO@@'                ,AllTrim(Transform(SC5->C5_ZVLRLIB,"@E 999,999,999.99")))
	cHtml	:= StrTran(cHtml,'@@VLR_DESCCAB@@'               ,AllTrim(Transform(SC5->C5_DESC2,"@E 999,999,999.99")))
	cHtml	:= StrTran(cHtml,'@@TP_PEDIDO@@'                 ,AllTrim(X3Combo("C5_ZOPRMAX", SC5->C5_ZOPRMAX)))
	cHtml	:= StrTran(cHtml,'@@PEDIDO_REL@@'                ,AllTrim(SC5->C5_ZPDRELA)) //Pedido Relacionado.
	cHtml	:= StrTran(cHtml,'@@PER_BONIFICA@@'              ,AllTrim(Transform(fGetBonus(),"@E 999.99")) + "%")
	cHtml	:= StrTran(cHtml,'@@MSG_VEND@@'                  ,AllTrim(SC5->C5_ZMSGINT))

	// tabela 2
	cHtml	:= StrTran(cHtml,'@@PERCENT_DESCONTO_APLICADO@@' ,AllTrim(Transform(nDesPerHie,"@E 999,999,999.99")))
	cHtml	:= StrTran(cHtml,'@@PERCENT_DESCONTO_PERMITIDO@@',AllTrim(Transform(nDesPercP,"@E 999,999,999.99")))
	cHtml	:= StrTran(cHtml,'@@PERCENT_SOLICITADO@@'        ,AllTrim(Transform(nDesPerHie,"@E 999,999,999.99")))

	// Preenche a tabela de itens
	For nX := 1 To Len(aProdutos)
		cBodyItens += cHtmlItens

		If aProdutos[nX][7] > aProdutos[nX][9]
			cBodyItens := StrTran(cBodyItens, "@@BORDER@@"  			, "#e3b9b9")
		Else
			cBodyItens := StrTran(cBodyItens, "@@BORDER@@"  			, "#fdfdfd")
		EndIf

		cBodyItens := StrTran(cBodyItens, "@@ITEM@@"        			, aProdutos[nX][1])
		cBodyItens := StrTran(cBodyItens, "@@CODIGO@@"      			, aProdutos[nX][2])
		cBodyItens := StrTran(cBodyItens, "@@DESCRICAO@@"   			, aProdutos[nX][3])
		cBodyItens := StrTran(cBodyItens, "@@QUANTIDADE@@"  			, cValToChar(aProdutos[nX][4]))
		cBodyItens := StrTran(cBodyItens, "@@UNITARIO@@"    			, Transform(aProdutos[nX][5],"@E 99,999,999.99"))
		cBodyItens := StrTran(cBodyItens, "@@TOTAL@@"               	, Transform(aProdutos[nX][6],"@E 99,999,999.99"))
		cBodyItens := StrTran(cBodyItens, "@@PERCENT_DESCONTO@@" 		, Transform(aProdutos[nX][7],"@E 99,999,999.99"))
		cBodyItens := StrTran(cBodyItens, "@@VAL_DESCONTO@@" 			, Transform(aProdutos[nX][8],"@E 99,999,999.99"))
		cBodyItens := StrTran(cBodyItens, "@@PERCENT_DESC_PERMITIDO@@"  , Transform(aProdutos[nX][9],"@E 99,999,999.99"))
		cBodyItens := StrTran(cBodyItens, "@@VAL_DESC_PERMITIDO@@" 	    , Transform(aProdutos[nX][10],"@E 99,999,999.99"))
		//cBodyItens := StrTran(cBodyItens, "@@VAL_SOLICITACAO_ITEM@@"    , Transform(aProdutos[nX][11],"@E 99,999,999.99"))
	Next nX

	cHtml := StrTran(cHtml,"@@BODYTABLEITENS@@", cBodyItens)

	// Preencher as vairiaveis da tabela de sequencia de aprovaçoes
	If Len(aPreApro) > 0
		For nI := 1 To Len(aPreApro)
			cBodyAprov += cHtmlApro
			cBodyAprov := StrTran(cBodyAprov, "@@SEQUENCIA@@" 	, AllTrim(aPreApro[nI][1] ))
			cBodyAprov := StrTran(cBodyAprov, "@@APROVADOR@@"   , AllTrim(aPreApro[nI][2] ))
			cBodyAprov := StrTran(cBodyAprov, "@@STATUS@@" 	    , AllTrim(aPreApro[nI][3] ))
			cBodyAprov := StrTran(cBodyAprov, "@@DATA@@" 	    , AllTrim(aPreApro[nI][4] ))
			cBodyAprov := StrTran(cBodyAprov, "@@COMENTARIO@@" 	, AllTrim(aPreApro[nI][5] ))
		Next nI
	Endif

	cHtml := StrTran(cHtml,"@@BODYTABLEAPROV@@", cBodyAprov)

	// E-mail de copia
	cCopiaAprov :=  GetMV("DC_CPAPROV") // Email copia para aprovador

	If cOpcao $ "01/02/03/10"
		DBSelectArea("SCR")
		SCR->(DBSetOrder(1))
		SCR->(DBGoTop())
		If SCR->(DBSeek(xFilial("SCR") + cSCRType + AvKey(cANum,"CR_NUM")))
			While !SCR->(EOF()) .And. SCR->(CR_FILIAL+CR_TIPO+AllTrim(CR_NUM)) == (xFilial("SCR")+cSCRType+AllTrim(AVKEY(cANum,"CR_NUM")))

				If SCR->CR_STATUS <> "02"
					SCR->(DBSkip())
					Loop
				EndIf

				PSWOrder(1)
				PSWSeek(SCR->CR_USER,.T.)  		// retorna um array com as informações do usuário
				cEndMail   := PswRet(1)[1,14] 	// recebe o e-mail do usuário logado
				cUserAprov := UsrFullName(SCR->CR_USER)


				If Empty(cEndMail)
					cRet += " Usuário Aprovador " + AllTrim(UsrFullName(SCR->CR_USER))  + " não possui e-mail cadastrado! "
					SCR->(DBSkip())
					Loop
				EndIf

				// Informar nome do aprovador
				cHtml	:= StrTran(cHtml,'@@NOMEDEST@@',AllTrim(cUserAprov))

				// aparecer os botoes
				cHtml	:= StrTran(cHtml,"@@DISPLAY@@","block")

				//                                   123456789012345678901234567890123456
				// Motagem da chave conforme padrão: EEFFTTNNNNNNUUUUUUOOOKKKKKKKKKKKKKKK
				// E = Empresa - 1 ao 2
				// U = Unidade Negocio - 3 ao 4
				// F = Filial - 5 ao 6
				// T = Tipo Processo (PC para Pedidos de Compras) - 5 ao 6
				// N = Número Pedido - 7 ao 12
				// U = Usuário - 13 ao 18
				// O = Operaçao - 19 ao 21
				// K = Chave do Registro - 22 ao 36
				cChavAprI:= EMBARALHA(cEmpAnt+xFilial("SCR")+cSCRType+cANum+SCR->CR_USER+"APR"+StrZero(SCR->(Recno()),15)+"I",1)
				cChavBlqI:= EMBARALHA(cEmpAnt+xFilial("SCR")+cSCRType+cANum+SCR->CR_USER+"BLQ"+StrZero(SCR->(Recno()),15)+"I",1)


				// Atribui link e chave aos botoe
				cHtml 	:= StrTran(cHtml,'@@CHAVEAPRI@@',fLnkWSRest("I")+cChavAprI)
				cHtml 	:= StrTran(cHtml,'@@CHAVEBLQI@@',fLnkWSRest("I")+cChavBlqI)

				// Envia e-mail
				cCopiaAprov := "" // não envia e-mail de cópia na aprovação, somente na confirmação
				cRet 	+= SendMail(cEndMail, cCopiaAprov, cAssunto, cHtml)

				// Mensagem no pedido para aprovação
				// Posiciona na SC5 senão estiver
				If SC5->C5_NUM != Left(cANum, 6)
					SC5->(DBSetOrder(1))
					SC5->(DBSeek(xFilial("SC5") + cANum))
				Endif

				// Alterad
				RecLock("SC5", .F.)
				SC5->C5_ZBLQCOM := SC5->C5_ZBLQCOM + CRLF + "Solicitação de aprovação de alçada enviada para [" + UsrFullName(SCR->CR_USER) + "] em " + DtoC(dDataBase) + " as " + Time()
				SC5->(MSUnLock())

				// Retorna como antes para trocar o nome do proximo aprovador.
				cHtml	:= StrTran(cHtml,AllTrim(cUserAprov)+","   , '@@NOMEDEST@@'+',')
				cHtml 	:= StrTran(cHtml,fLnkWSRest("I")+cChavAprI , '@@CHAVEAPRI@@')
				cHtml 	:= StrTran(cHtml,fLnkWSRest("I")+cChavBlqI , '@@CHAVEBLQI@@')

				SCR->(DBSkip())
			EndDo
		EndIf

	Elseif cOpcao $ "04/05"

		// Captura o e-mail do comprador e envia a mensagem de bloqueio ou aprovação
		cEndMail   := cCopiaAprov
		cHtml      := StrTran(cHtml, '@@NOMEDEST@@' ,cVendedor)

		// Ocultar os botoes
		cHtml	:= StrTran(cHtml,"@@DISPLAY@@","none")

		If Empty(cEmailVend)
			cRet += " Vendedor " + AllTrim(UsrFullName(cUserAprov))  + " não possui e-mail cadastrado! "
		Else
			cRet += SendMail(cEmailVend, cEndMail, cAssunto, cHtml)
		EndIf
	EndIf

Return cRet

/*/{Protheus.doc} SendMail
    Função de envio de e-mail
    @type  Function
    @author Vamilly - MRBranco
    @since 09/07/2024
    @param cATo, Character, destinatario PARA
    @param cACC, Character, destinatario COPIA
    @param cAAssunto, Character, assunto do e-mail
    @param cAHtml, Character, html do corpo do e-mail
    @return Character, cRet, vazio ou alguma mensagem de problema
/*/
Static Function SendMail(cATo, cACC, cAAssunto, cAHtml)
	Local cRet         := ""
	Private cAssunto   := cAAssunto
	Private cTo        := cATo
	Private cHtml      := cAHtml
	Private cError     := ""
	Private cServer    := TRIM(GETMV("MV_RELSERV")) //Nome do Servidor que envia email
	Private cFrom      := TRIM(GETMV("MV_RELACNT")) //Conta que envia email
	Private cPass      := TRIM(GETMV("MV_RELPSW")) //Senha da conta que envia email
	Private lResulConn := lResulSend := .T.
	Private lAutOk     := GetMV("MV_RELAUTH",,.F.)
	Private cBCC       := GetMV("DC_MAILADT",,"" ) // E-mail auditoria

	cACC :=  cACC +";"+ cBCC

	Conout('DECAT008 - Entrou no envio de e-mail do pedido [' + SC5->C5_NUM + "]")

	If Empty(cServer+cFrom+cPass)
		cRet := " DECAT008 - Inconsistência nos parâmetros do server Protheus para envio de e-mail "
		Return cRet
	EndIf

	If Empty(cATo)
		cRet := " DECAT008 - Inconsistência no endereço de envio do e-mail "
		Return cRet
	EndIf
	CONNECT SMTP SERVER cServer ACCOUNT cFrom PASSWORD cPass RESULT lResulConn
	If !lResulConn
		GET MAIL ERROR cError
		cRet := " DECAT008 - Falha na conexão " + cError + " "
	Else
		If lAutOk
			lResulAuth := MailAuth(cFrom, cPass)
			If !lResulAuth
				GET MAIL ERROR cError
				cRet := (" DECAT008 - Falha na autenticação da conta " + cError + " ")
			EndIf
		EndIf
	EndIf
	If Empty(cRet)
		SEND MAIL FROM cFrom TO cATo CC cACC SUBJECT cAssunto BODY cHtml RESULT lResulSend
		If !lResulSend
			GET MAIL ERROR cError
			cRet := (" DECAT008 - Falha no envio do e-mail " + cError + " ")
		EndIf
		DISCONNECT SMTP SERVER
	EndIf

	If !Empty(cRet)
		FwAlertError(cRet)
	EndIf

Return cRet

/*/{Protheus.doc} fGetHtmObs
    Função de montagem de tela html para informação de Motivo de Rejeiçãoo
    @type  Function
    @author Vamilly - MRBranco
    @since 09/07/2024
    @param cAKEmpresa, Character, empresa do pedido
    @param cAKFilial, Character, filial do pedido
    @param cAKNumero, Character, pedido de venda
    @param cAKUsario, Character, usuário para aprovação ou rejeição
    @param cAKOperac, Character, APR=Aprovação / BLQ=Rejeição
    @param cAKeyRecn, Character, recno da SCR
    @param cAKInEx, Character, link externo ou interno
    @param cSCRType, Character, tipo de registro na SCR
    @return Character, cHtml, html formatado para exibir na tela (retorno ws)
/*/
Static Function fGetHtmObs(cAKEmpresa, cAKFilial, cAKNumero, cAKUsario, cAKOperac, cAKeyRecn, cAKInEx, cSCRType)
	Local cHtml 	:= ""
	Local cPath  	:= GetSrvProfString("STARTPATH" , "") + "extras\DECAT008\html\"
	Local cModelHtml:= MemoRead(cPath + "formObs_mod.html")
	Local cLinkWS	:= ""
	Local cDescTela	:= IIF(cAKOperac="APR",EncodeUTF8("Informe um comentário para a aprovação:", "cp1252"),"Informe a justificativa para o bloqueio:")
	Local cTitulo	:= IIF(cAKOperac="APR",EncodeUTF8("Comentário de Aprovação", "cp1252"),"Motivo de Bloqueio")
	Local cColor    := IIF(cAKOperac="APR", cGreen, cRed)

	// Ajuste do link WEB de controle de documentos
	cLinkWS := fLnkWSRest(cAKInEx)
	If Empty(cLinkWS)
		cHtml := EncodeUtf8("Configuração do parâmetro DC_URLREST inválida!")
		Return cHtml
	EndIf

	// Padrão Chave do Processo
	//                                   123456789012345678901234567890
	// Motagem da chave conforme padrão: NNNNNNUUUUUUOOORRRRRRRRRRRRRRR
	// NNNNNN 			- Número do Pedido de Compras
	// UUUUUU 			- Usuário Aprovador
	// OOO	  			- Operação (APR/ BLQ)
	// RRRRRRRRRRRRRRR	- Recno SCR

	cHtml := cModelHtml
	cHtml := StrTran(cHtml, "@@CHAVETIT@@"	,cTitulo,1)
	cHtml := StrTran(cHtml, "@@CHAVEDESC@@"	,cDescTela,1)
	cHtml := StrTran(cHtml, "@@CHAVEEMP@@"	,cAKEmpresa,1)
	cHtml := StrTran(cHtml, "@@CHAVEFIL@@"	,cAKFilial,1)
	cHtml := StrTran(cHtml, "@@CHAVETIPO@@"	,cSCRType,1)
	cHtml := StrTran(cHtml, "@@CHAVECHVPR@@",cAKNumero+cAKUsario+cAKOperac+cAKeyRecn,1)
	cHtml := StrTran(cHtml, "@@CHAVEACAO@@" ,cAKOperac,1)
	cHtml := StrTran(cHtml, "@@CHAVELINK@@" ,cLinkWS,1)
	cHtml := StrTran(cHtml, "@@COLOR@@"     ,cColor,1)
	cHtml := StrTran(cHtml, "@@PROCESSO@@"  ,EncodeUTF8("Análise de Pedido de Venda - ", "cp1252")+cAKNumero,1)

Return cHtml

/*/{Protheus.doc} fVldStaPC
    Função para validar o status do registro que será bloqueado ou alterado
    @type  Function
    @author Vamilly - MRBranco
    @since 09/07/2024
    @param cKeyNum, Character, pedido de venda
    @param cKeyUser, Character, usuário para aprovação ou rejeição
    @param cKeyOper, Character, APR=Aprovação / BLQ=Rejeição
    @param cKeyRecn, Character, recno da SCR
    @param cKeyInEx, Character, link externo ou interno
    @param cSCRType, Character, tipo de registro na SCR
    @return Character, cHtml, html formatado para exibir na tela (retorno ws)
/*/
Static Function fVldStaPC(cKeyNum,cKeyUser,cKeyOper,cKeyRecn,cKeyInEx,cSCRType)

	Local cHtmlRet	:= ""
	Local cOper		:= ""
	Local lOk		:= .T.
	Local aAreaSC5	:= SC5->(FWGetArea())
	Local aAreaSCR	:= SC5->(FWGetArea())
	Local cColor    := cRed


	DBSelectArea("SC5")
	SC5->(DBSetOrder(1))

	DBSelectArea("SCR")  // CR_FILIAL + CR_TIPO + CR_NUM + CR_USER
	SCR->(DBSetOrder(2))

	// Verifica se o Pedido de Compras Existe
	If !SC5->(DBSeek(xFilial("SC5") + cKeyNum))
		lOk      := .F.
		cHtmlRet := u_HtmlRet("O pedido de venda [" + AllTrim(cKeyNum) + "] não foi localizado!", cColor)
	EndIf

	// Verifica se o Pedido de Compras está na SCR
	If lOk
		cNumSCR := PADR(cKeyNum, TamSX3("CR_NUM")[1])
		If !SCR->(DBSeek(xFilial("SCR")+cSCRType+cNumSCR+cKeyUser))
			lOk 	 := .F.
			cColor   := cYellow
			cHtmlRet:= u_HtmlRet("O pedido de venda [" + AllTrim(cNumSCR) + "] não está pendente para análise!", cColor)
		EndIf
	EndIf

	// Verifica se o registro (Recno) do e-mail é igual
	If lOk
		If SCR->(Recno()) <> Val(cKeyRecn)
			lOk 	:= .F.
			cColor   := cYellow // AMARELO
			cHtmlRet:= u_HtmlRet("O pedido de venda [" + AllTrim(cKeyNum) + "] não está disponível para análise porque foi alterado pelo solicitante!", cColor)
		EndIf
	EndIf

	// Verifica o Status atual do Pedido na SCR
	If lOk

		// Se a SCR não estiver pendente, já foi analisada anteriormente
		If SCR->CR_STATUS <> "02"

			lOk   := .F.
			cOper := SCR->CR_STATUS

			// Se a SCR for = 05, ela foi aprovada/bloqueado por outro aprovador, a função getOperReg busca qual foi a decisão do aprovador anterior.
			If cOper == '05'
				cOper := getOperReg()
			EndIf

			// Avaliio a situação atual para retornar
			Do Case
				Case cOper == '03'
					cHtmlRet := u_HtmlRet("Operação não permitida. O pedido de venda [" + cKeyNum + "] já foi aprovado anteriormente!", cColor)
				Case cOper == '04'
					cHtmlRet := u_HtmlRet("Operação não permitida. O pedido de venda [" + cKeyNum + "] já foi bloqueado anteriormente!", cColor)
				OtherWise
					cHtmlRet := u_HtmlRet("Operação não permitida. O pedido de venda [" + cKeyNum + "] já foi analisado anteriormente!", cColor)
			EndCase

		EndIf

	EndIf

	FWRestArea(aAreaSC5)
	FWRestArea(aAreaSCR)

Return cHtmlRet

//+---------------------------------------------------------------------------------------+
//|    |
//+---------------------------------------------------------------------------------------+
/*/{Protheus.doc} getOperReg
    Função para buscar qual foi a operação de registros aprovado pro outros aprovadores
    @type  Function
    @author Vamilly - MRBranco
    @since 09/07/2024
    @return Character, cRet, status da SCR
/*/
Static Function getOperReg()

	Local cChave 	:= SCR->(CR_FILIAL+CR_TIPO+CR_NUM+CR_USERLIB)
	Local aArea  	:= FWGetArea()
	Local aAreaSCR	:= SCR->(FWGetArea())
	Local cRet		:= '05'

	SCR->(DBSetOrder(2))
	If SCR->(DBSeek(cChave))
		cRet := SCR->CR_STATUS
	EndIf

	FWRestArea(aAreaSCR)
	FWRestArea(aArea)

Return cRet

/*/{Protheus.doc} fLnkWSRest
    Função para montar o Link do WebService de analise de documentos
    @type  Function
    @author Vamilly - MRBranco
    @since 09/07/2024
    @param cKeyInEx, Character, link externo ou interno
    @return Character, cLinkWSAP, url do WS
/*/
Static Function fLnkWSRest(cAKInEx)
	Local cLinkWSAP := ""
	Local cAIpWSI	:= GetMV("DC_URLREST",,"http://192.168.0.231:8081/rest")

	cAKInEx := "I"

	If !Empty(cAIpWSI)
		If cAKInEx == "I"
			cLinkWSAP := IIF(Substr(cAIpWSI, Len(cAIpWSI)-1,1)=="/",cAIpWSI,cAIpWSI+"/")
		Endif
		cLinkWSAP := cLinkWSAP + "WSDECAT009/"
	EndIf
Return cLinkWSAP

/*/{Protheus.doc} fVldStaPC
    Função para validar a situação do pedido.
    @type  Function
    @author Vamilly - MRBranco
    @since 09/07/2024
    @param cADocto, Character, pedido de venda
    @param cAGrupo, Character, grupo para aprovação ou rejeição
    @param nARec, Character, recno da SCR
    @param cSCRType, Character, tipo de registro na SCR
    @return Character, cHtml, html formatado para exibir na tela (retorno ws)
/*/
Static Function fVldSitPed(cADocto, cAGrupo, nARec, cSCRType )

	Local lRet 	 := .T.
	Local aArea	 := SCR->(FWGetArea())

	//Reposiciona e verifica se ja esta totalmente liberado
	DBSelectArea("SCR")
	SCR->(DBSetOrder(1))
	SCR->(MsGoto(nARec))
	While SCR->(!Eof()) .And. xFilial("SCR")+cSCRType+cADocto == SCR->(CR_FILIAL+CR_TIPO+CR_NUM)
		If cAGrupo == SCR->CR_GRUPO
			If SCR->CR_STATUS != "03" .And. SCR->CR_STATUS != "05" .And. SCR->CR_STATUS != "04"
				lRet := .F.
				Exit
			EndIf
		Endif
		SCR->(DBSkip())
	End

	FWRestArea(aArea)

Return lRet


/*/{Protheus.doc} fHistSCR
    Retorna o histórico de alçadas aprovações
    @type  Function
    @author Vamilly - MRBranco
    @since 09/07/2024
    @param cTypeCR, Character, Tipo da SCR (CR_TIPO)
    @param cNumCR, Character, Número do documento a pesquisar da SCR (CR_NUM)
/*/
User Function fHistSCR(cTypeCR, cNumCR)
	Local oDlg
	Local oLB
	Local oMG
	Local oBtnOk
	Local cQuery    := ""
	Local cKeyCR    := cTypeCR
	Local cAlias    := GetNextAlias()
	Local cDocCR    := cNumCR
	Local aSCR      := {}

	cQuery := "	SELECT 									 		   														" + CRLF
	cQuery += "		CR_FILIAL,CR_NUM,CR_NIVEL,CR_USER,CR_STATUS,CR_DATALIB,												" + CRLF
	cQuery += "		ISNULL(CONVERT(VARCHAR(8000),CONVERT(VARBINARY(8000),CR_OBS)),'') CR_OBS,							" + CRLF
	cQuery += "		CR_TOTAL,CR_EMISSAO,CR_USERLIB,																		" + CRLF
	cQuery += "		CR_VALLIB,CR_TIPOLIM,CR_WF,CR_MOEDA,CR_TXMOEDA,CR_TIPO,CR_APROV,CR_LIBAPRO,CR_USERORI,CR_APRORI		" + CRLF
	cQuery += "	FROM  							  		  			" + CRLF
	cQuery += "		SCR010 SCR WITH (NOLOCK) 			  			" + CRLF
	cQuery += "	WHERE									   			" + CRLF
	cQuery += "			SCR.D_E_L_E_T_ = ''				   			" + CRLF
	cQuery += "		AND CR_FILIAL = '"+xFilial("SCR")+"' 			" + CRLF
	cQuery += "		AND CR_TIPO = '" + cKeyCR    + "' 		   	    " + CRLF
	cQuery += "		AND CR_NUM = '"  + cDocCR + "'    			    " + CRLF
	cQuery += "	ORDER BY 											" + CRLF
	cQuery += "		SCR.R_E_C_N_O_,                             	" + CRLF
	cQuery += "		CR_FILIAL, CR_TIPO, CR_NUM, CR_NIVEL, CR_USER	" + CRLF

	TCQuery cQuery new  ALIAS (cAlias)
	TCSetField(cAlias, "CR_DATALIB"  ,"D")
	DBSelectArea(cAlias)
	(cAlias)->( DBGoTop() )
	While (cAlias)->( !Eof() )
		aAdd(aSCR, {				   				;
			cDocCR							, 	;
			(cAlias)->CR_NIVEL				, 	;
			UsrRetName((cAlias)->CR_USER)	,	;
			getSitApro((cAlias)->CR_STATUS)	,	;
			UsrRetName((cAlias)->CR_USERLIB)	,	;
			(cAlias)->CR_DATALIB				,	;
			(cAlias)->CR_OBS						;
			})

		(cAlias)->( DBSkip() )
	EndDo
	(cAlias)->( DBCloseArea() )

	If Empty(aSCR)
		FWAlertInfo( "Não foi encontrado processo de aprovações para este pedido.", "ALÇADAS")
		Return
	Endif

	DEFINE MSDIALOG oDlg TITLE 'Aprovadores' FROM 0,0 To 250,900 PIXEL

	@ 1, 1 LISTBOX oLB FIELDS HEADER "Pedido", "Nivel", "Usuario", "Situacao"+Space(20), "Avaliado por", "Data Liber." SIZE 451,70 OF oDlg PIXEL

	oLB:SetArray(aSCR)

	oLB:bLine := {|| {			;
		aSCR[oLB:nAt,1]	,	;
		aSCR[oLB:nAt,2]	,	;
		aSCR[oLB:nAt,3]	,	;
		aSCR[oLB:nAt,4]	,	;
		aSCR[oLB:nAt,5]	,	;
		aSCR[oLB:nAt,6]		;
		}}

	oLB:bChange := {||oMG:Refresh()}

	oMG := TMultiget():New(72,1,{|u|if(Pcount()>0,aSCR[oLB:nAt,7]:=u,aSCR[oLB:nAt,7])},oDlg,451,35,,,,,,.T.,,,,,,.T.,,,,,.T.)
	oMG:LCANGOTFOCUS := .F.

	oBtnOk := TButton():New(110, 401,'Voltar',oDlg,{|| oDlg:End() },50,12,,,,.T.)

	ACTIVATE DIALOG oDlg CENTERED
Return

/*/{Protheus.doc} getSitApro
    Função que retorna a descrição do status da SCR
    @type  Function
    @author Vamilly - MRBranco
    @since 09/07/2024
    @param cASit, Character, código do status da SCR
    @return Character, cRet, descrição do status
/*/
Static Function getSitApro(cASit)
	Local cRet := ""

	Do Case
		Case cASit == '01'
			cRet := 'Aguardando niveis anteriores'
		Case cASit == '02'
			cRet := 'Pendente'
		Case cASit == '03'
			cRet := 'Aprovado'
		Case cASit == '04'
			cRet := 'Bloqueado'
		Case cASit == '05'
			cRet := 'Liberado outro aprovador'
		Case cASit == '06'
			cRet := 'Rejeitado'
		Case cASit == '06'
			cRet := 'Rejeitado outro aprovador'
	EndCase
Return cRet


/*/{Protheus.doc} fResendMail()
    Reenvia e-mail para aprovação
    @type  Function
    @author Vamilly - MRBranco
    @since 09/07/2024
    @param cTypeCR, Character, Tipo da SCR (CR_TIPO)
    @param cNumCR, Character, Número do documento a pesquisar da SCR (CR_NUM)
/*/
User Function fResendMail(cTypeCR, cNumCR)
	Local aArea := FWGetArea()

	DBSelectArea("SCR")
	SCR->(DBSetOrder(1)) // CR_FILIAL + CR_TIPO + CR_TIPO
	SCR->(DBGoTop())
	If !SCR->(DBSeek(xFilial("SCR") + cTypeCR + PadR(cNumCR, TamSx3("CR_NUM")[1])))
		FWAlertError("Não é possivel reenviar e-mail, pedido não esta aguardando aprovação por alçadas.", "ALÇADAS")
		FWRestArea(aArea)
		Return
	EndIf

	// Validar estagio que o pedido esta.
	If U_PEDLIB() == 0 .And. SC5->C5_SITDEC == " " //.And. SC5->C5_LIBEROK == "S".And. SC5->C5_BLQ == "1"
		// Envia e-mail
		U_DECAT08WF(cNumCR, "10", .T.)
		FWAlertSuccess("E-mail enviado com sucesso!", "ALÇADAS")
	Else
		FWAlertError("Não é possivel reenviar e-mail, pedido não esta aguardando aprovação por alçadas.", "ALÇADAS")
	EndIf
	FWRestArea(aArea)
Return

/*/{Protheus.doc} DECATLIBPD
Funnção para realizar a  liberação do pedido de venda
@type function
@version 2210
@author Vamilly - MRBranco
@since 9/12/2023
/*/
User Function DECATLIBPD()
	Local aArea    := FWGetArea()
	Local aAreaSC5 := SC5->(FWGetArea()) // Pedido de Vendas
	Local aAreaSC6 := SC6->(FWGetArea()) // Itens de Pedido Vendas
	Local aAreaSC9 := SC9->(FWGetArea()) // Pedidos Liberados
	Local nQtdLib  := 0
	Local aLibSC6  := {}

	DBSelectArea("SC6")
	SC6->(DBSetOrder(1))
	If SC6->(DBSeek(xFilial("SC6") + SC5->C5_NUM))
		While SC6->(!Eof()) .And. SC6->C6_NUM == SC5->C5_NUM

			nQtdLib := (SC6->C6_QTDVEN - (MAX(SC6->C6_QTDEMP, 0) + SC6->C6_QTDENT)) // calcula o saldo a liberar
			If nQtdLib > 0

				// Libera por Pedido
				Begin Transaction
					RecLock("SC6")
					SC6->C6_QTDLIB  := nQtdLib
					SC6->C6_BLOQUEI := ""
					SC6->(MsUnLock())

					Aadd(aLibSC6, SC6->(Recno()))
				End Transaction
			EndIf

			SC6->(DBSkip())
		End

		// Libera por Total de Pedido
		If Len(aLibSC6) > 0
			Begin Transaction
				lLiber  := .F.
				lTransf := .F.
				SC6->(MaAvLibPed(SC5->C5_NUM,lLiber,lTransf,.F.,aLibSC6,Nil,Nil,Nil))
			End Transaction
		EndIf

		// Atualiza o Flag do Pedido de Venda
		Begin Transaction
			SC6->(MaLiberOk({SC5->C5_NUM}, .F.))
		End Transaction

		// liberar pedido para montagem
		Reclock("SC5",.F.)
		SC5->C5_SITDEC   := " "
		SC5->C5_LIBEROK  := "S"
		SC5->(MsUnlock())
	EndIf

	// Retorna areas
	FWRestArea(aAreaSC9)
	FWRestArea(aAreaSC6)
	FWRestArea(aAreaSC5)
	FWRestArea(aArea)
Return

/*/{Protheus.doc} fGetBonus
	Função para buscar a porcentagem de bonus. Percentual de Bonificação em relação ao pedido de venda.
	@type  Function
	@author Anderson Koziel
	@since 28/11/2024
	@version 1.0
	@return Numeric, Percentual de Bonificação em relação ao pedido de venda.
/*/
Static function fGetBonus() as Numeric
	Local aArea      := FWGetArea() as Array
	Local nPorcBonus := Zero()	as Numeric
	Local nValorPed  := Zero()	as Numeric
	Local nValorBon  := Zero()	as Numeric

	//Caso não tem pedido de boonificação relacionado, retorna zero.
	If Empty(SC5->C5_ZPDRELA)
		FWRestArea(aArea)
		Return Zero()
	EndIf

	//Pega o valor do pedido, que já está posicionado.
	nValorBon := SC5->C5_ZVLRLIB

	//Busco o pedido de venda relacionado.
	SC5->(DBSetOrder(1))
	If SC5->(DBSeek(SC5->C5_ZPDRELA)) //C5_FILIAL + C5_NUM
		nValorPed := SC5->C5_ZVLRLIB

		nPorcBonus := (nValorBon / nValorPed) * 100
	EndIf

	//Retorna a Area.
	FWRestArea(aArea)
Return nPorcBonus
