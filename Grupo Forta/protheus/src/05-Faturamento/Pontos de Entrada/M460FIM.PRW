#INCLUDE "RWMAKE.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOPCONN.CH"

/*/{Protheus.doc} M460FIM
Ponto de entrada no final da Geração da Nota fiscal de saída. 
@type function
@version  
@author Lauschner Consulting - Marcelo Alberto Lauschner
@since 26/07/2025
@return variant, return_description
/*/
User Function M460FIM()

	Local 	aAreaSF2 	:= SF2->(GetArea())
	Local 	aAreaSD2 	:= SD2->(GetArea())
	// Integração LEXOS HUB - INICIO
	If ExistBlock("LEXM460FIM")
		ExecBlock("LEXM460FIM", .F., .F., {})
	EndIf
	// Integração LEXOS HUB - FIM

	RestArea(aAreaSF2)

	// 26/07/2025 - Efetua ajuste automático do portador do título de cartão 
	If cEmpAnt $ "01"

		DbSelectArea ("SD2") //Itens de venda da NF
		DbSetOrder(3)
		DbSeek(xFilial("SD2")+SF2->F2_DOC+SF2->F2_SERIE+SF2->F2_CLIENTE+SF2->F2_LOJA)
		If !Empty(SD2->D2_PEDIDO)
			DbSelectArea("SC5")
			DbSetOrder(1)
			If DbSeek(xFilial("SC5")+ SD2->D2_PEDIDO)
				// Se for banco Vendor
				If SC5->C5_BANCO $ "777"

					DbSelectArea ("SA6")
					Dbsetorder(1)
					// valida se o banco existe cadastro
					If  DbSeek(xfilial("SA6")+"777"+"77777"+"7777777777")
						//caso exista o portador irá seguir o comando de preencher o portado no titulo financeiro
						DbSelectArea ("SE1")
						Dbsetorder(1)
						DbSeek(xFilial("SE1")+SF2->F2_PREFIXO+SF2->F2_DUPL)
						While !Eof() .and. xFilial("SE1")  == SE1->E1_FILIAL .And. SE1->E1_PREFIXO == SF2->F2_PREFIXO .And.;
								SE1->E1_NUM == SF2->F2_DUPL .And. SE1->E1_CLIENTE == SF2->F2_CLIENTE .And. SE1->E1_LOJA == SF2->F2_LOJA
							//valida se realmente o portador esta vazio, pois pode acontecer de ser uma reimpresao de DANFE onde o titulo já foi enviado a um outro portador
							// caso seja vazio, preenche o portador conforme solicitado no chamado
							IF empty(SE1->E1_PORTADO)
								RecLock("SE1",.F.)
								SE1->E1_PORTADO := SA6->A6_COD
								SE1->E1_AGEDEP  := SA6->A6_AGENCIA
								SE1->E1_CONTA   := SA6->A6_NUMCON
								SE1->E1_SITUACA := "0"
								MsUnLock() //fecha a tabela
							endif
							DbSelectArea ("SE1")
							DbSkip()     // salta para proxima nota
						EndDo
					Else
						//msg de aviso caso não exista o banco cadastrado
						MsgInfo("O banco 777:77777:7777777777 não existe cadastro.","Banco não Cadastrado")
					Endif
				ElseIf SC5->C5_BANCO $ "888"

					DbSelectArea ("SA6")
					Dbsetorder(1)
					// valida se o banco existe cadastro
					If  DbSeek(xfilial("SA6")+"888"+"88888"+"7777777777")
						//caso exista o portador irá seguir o comando de preencher o portado no titulo financeiro
						DbSelectArea ("SE1")
						Dbsetorder(1)
						DbSeek(xFilial("SE1")+SF2->F2_PREFIXO+SF2->F2_DUPL)
						While !Eof() .and. xFilial("SE1")  == SE1->E1_FILIAL .And. SE1->E1_PREFIXO == SF2->F2_PREFIXO .And.;
								SE1->E1_NUM == SF2->F2_DUPL .And. SE1->E1_CLIENTE == SF2->F2_CLIENTE .And. SE1->E1_LOJA == SF2->F2_LOJA
							//valida se realmente o portador esta vazio, pois pode acontecer de ser uma reimpresao de DANFE onde o titulo já foi enviado a um outro portador
							// caso seja vazio, preenche o portador conforme solicitado no chamado
							IF Empty(SE1->E1_PORTADO)
								RecLock("SE1",.F.)
								SE1->E1_PORTADO := SA6->A6_COD
								SE1->E1_AGEDEP  := SA6->A6_AGENCIA
								SE1->E1_CONTA   := SA6->A6_NUMCON
								SE1->E1_SITUACA := "0"
								MsUnLock() //fecha a tabela
							endif
							DbSelectArea ("SE1")
							DbSkip()     // salta para proxima nota
						EndDo
					Else
						//msg de aviso caso não exista o banco cadastrado
						MsgInfo("O banco 888:88888:7777777777 não existe cadastro.","Banco não Cadastrado")
					Endif
				Endif
			Endif
		Endif
	Endif
	RestArea(aAreaSF2)
	RestArea(aAreaSD2)
Return
