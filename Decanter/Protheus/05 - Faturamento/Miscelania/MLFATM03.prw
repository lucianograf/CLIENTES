#INCLUDE "totvs.ch"

/*/{Protheus.doc} MLFATM03
Função para tratar o retorno da liberação de pedidos via Link do Faturamento 
@type function
@version  
@author Marcelo Alberto Lauschner
@since 02/03/2022
@param nInOpc, numeric, param_description
@param oProcess, object, param_description
@return variant, return_description
/*/
User Function MLFATM03(nInOpc,oProcess)

	If nInOpc == 2
		sfReturn(oProcess)
	ElseIf nInOpc == 1
		ConOut("Time-out para execução do processo")
	Endif

Return


Static Function sfReturn(oProcess)

	Local 	cNum      	:= oProcess:oHtml:RetByName('C5_NUM')
	Local 	cAprova   	:= oProcess:oHtml:RetByName('APROVACAO')
	Local 	cObs      	:= oProcess:oHtml:RetByName('C5_MSGEXP')
	//Local 	cUser     	:= oProcess:oHtml:RetByName('USUARIO')
	Local 	cEmail    	:= oProcess:oHtml:RetByName('EMAILUSER')

	Local   aAreaOld        := GetArea()

	DbSelectArea("SC5")
	DbSetOrder(1)
	If !dbSeek(xFilial("SC5")+cNum)
		Return
	Endif

	cBkProcess	:= oProcess:fProcessID


	If cAprova == "N" .Or. SC5->C5_LIBEROK == "S" 	// pedido nao foi aprovado ou já está liberado

		// Cria um novo processo...
		cProcess := "100000"
		cStatus  := "100000"
		oProcessA := TWFProcess():New(cProcess,OemToAnsi("Pedido de Vendas nao Liberado"))
		If IsSrvUnix()
			// Arquivo html template utilizado para montagem da aprovação
			cHtmlModelo	:= "/workflow/retorno_alcada_pedido.htm"
			If !File(cHtmlModelo)
				ConOut("Não localizou arquivo "+cHtmlModelo)
				Return
			Endif
		Else
			cHtmlModelo	:= "\workflow\retorno_alcada_pedido.htm"
		Endif
		//Abre o HTML criado
		oProcessA:NewTask("Pedido de Vendas Rejeitado " + cNum, cHtmlModelo , .T.)

		oProcessA:cSubject := "Pedido de Vendas "+IIf(SC5->C5_LIBEROK == "S","Analisado ","Rejeitado ") + cNum
		//oProcessA:cBody    := "O Pedido de Vendas " + cNum + " esta bloqueado para faturamento "+Chr(13)+cObs

		oProcessA:oHTML:ValByName("NOMECOM"			,AllTrim(SM0->M0_NOMECOM))
		oProcessA:oHTML:ValByName("ENDEMP"			,Capital(AllTrim(SM0->M0_ENDENT)) + " - " + Capital(SM0->M0_BAIRENT))
		oProcessA:oHTML:ValByName("COMEMP"			,Transform(SM0->M0_CEPENT,"@R 99999-999") + " - " + Capital(AllTrim(SM0->M0_CIDENT)) + " - " + SM0->M0_ESTENT)
		oProcessA:oHTML:ValByName("FONE"			,"Fone/Fax: " + SM0->M0_TEL)
		oProcessA:oHTML:ValByName("USUARIO"			,oProcess:oHtml:RetByName('USUARIO')		)
		oProcessA:oHtml:ValByName("EMAILUSER"		,oProcess:oHtml:RetByName('emailuser') 	)

		oProcessA:oHTML:ValByName("tiporetorno"		,IIf(SC5->C5_LIBEROK == "S" ,"Análise ","Rejeição ")	)
		oProcessA:oHTML:ValByName("C5_CLIENTE"		,oProcess:oHtml:RetByName('C5_CLIENTE')	)
		oProcessA:oHTML:ValByName("C5_LOJACLI"		,oProcess:oHtml:RetByName('C5_LOJACLI')	)
		oProcessA:oHTML:ValByName("A1_NOME"			,oProcess:oHtml:RetByName('A1_NOME')	)
		oProcessA:oHTML:ValByName("C5_NUM"			,oProcess:oHtml:RetByName('C5_NUM')	)
		oProcessA:oHTML:ValByName("motivo"			,IIf(SC5->C5_LIBEROK == "S","Pedido de venda analisado, porém já liberado anteriormente!"," ") + cObs	)

		oProcessA:oHTML:ValByName("data"			,Date()		)
		oProcessA:oHTML:ValByName("hora"			,Time()		)
		oProcessA:oHTML:ValByName("rdmake"			,FunName()+"."+ProcName(0)	)

		// 21/09/2015 - Adiciona e-mail do Supervisor na rejeição de Pedido de Venda
		DbSelectArea("SA3")
		DbSetOrder(1)
		DbSeek(xFilial("SA3")+SC5->C5_VEND1)
		If !Empty(SA3->A3_EMAIL)
			cEmail	+= ";" + Alltrim(SA3->A3_EMAIL)
		Endif


		If !Empty(cEmail)
			oProcessA:cTo :=  cEmail
		Else
			oProcessA:cTo :=  "suporte@decanter.com.br"
		Endif
		oProcessA:Start()
		oProcessA:Finish()
		If cAprova == "N" .AND. Empty(SC5->C5_SITDEC)
			DbSelectArea("SC5")
			Reclock("SC5",.F.)
			SC5->C5_SITDEC := "7"
			cC5BlqCom := alltrim(SC5->C5_ZBLQCOM)
			SC5->C5_ZBLQCOM := "["+Dtoc(Date())+"]"+"["+Time()+"]: "+"Resposta do Gestor: "+AllTrim(cObs)+CRLF+cC5BlqCom
			MsUnlock()
		Endif

	ElseIf cAprova == "S"

		dbSelectArea("SC6")
		dbSetOrder(1)

		cQuery := "UPDATE "+RetSqlName("SC6")
		cQuery += "   SET C6_BLOQUEI = '  ' "
		cQuery += " WHERE C6_FILIAL='"+xFilial('SC6')+"' "
		cQuery += "   AND C6_NUM='"+SC5->C5_NUM+"' "
		cQuery += "   AND (C6_BLOQUEI = '01' OR C6_BLOQUEI = '02') "
		cQuery += "   AND D_E_L_E_T_ = ' '"

		TcSqlExec(cQuery)

		DbSelectArea("SC5")
		Reclock("SC5",.F.)
		SC5->C5_BLQ :=Space(Len(SC5->C5_BLQ))
		MsUnlock()


		cProcess := "100000"
		cStatus  := "100000"
		oProcessB := TWFProcess():New(cProcess,OemToAnsi("Pedido de Vendas Liberado"))

		//Abre o HTML criado
		If IsSrvUnix()
			// Arquivo html template utilizado para montagem da aprovação
			cHtmlModelo	:= "/workflow/retorno_alcada_pedido.htm"
			If !File(cHtmlModelo)
				ConOut("Não localizou arquivo "+cHtmlModelo)
				Return
			Endif
		Else
			cHtmlModelo	:= "\workflow\retorno_alcada_pedido.htm"
		Endif
		//Abre o HTML criado
		oProcessB:NewTask("Pedido de Vendas Liberado " + cNum, cHtmlModelo , .T.)
		oProcessB:cSubject := "Pedido de Vendas Liberado " + cNum
		oProcessB:oHTML:ValByName("NOMECOM"		,AllTrim(SM0->M0_NOMECOM))
		oProcessB:oHTML:ValByName("ENDEMP"			,Capital(AllTrim(SM0->M0_ENDENT)) + " - " + Capital(SM0->M0_BAIRENT))
		oProcessB:oHTML:ValByName("COMEMP"			,Transform(SM0->M0_CEPENT,"@R 99999-999") + " - " + Capital(AllTrim(SM0->M0_CIDENT)) + " - " + SM0->M0_ESTENT)
		oProcessB:oHTML:ValByName("FONE"			,"Fone/Fax: " + SM0->M0_TEL)
		oProcessB:oHTML:ValByName("USUARIO"		,oProcess:oHtml:RetByName('USUARIO')		)
		oProcessB:oHtml:ValByName("EMAILUSER"		,oProcess:oHtml:RetByName('emailuser') 	)

		oProcessB:oHTML:ValByName("tiporetorno"	,"Liberação "	)
		oProcessB:oHTML:ValByName("C5_CLIENTE"		,oProcess:oHtml:RetByName('C5_CLIENTE')	)
		oProcessB:oHTML:ValByName("C5_LOJACLI"		,oProcess:oHtml:RetByName('C5_LOJACLI')	)
		oProcessB:oHTML:ValByName("C5_NUM"			,oProcess:oHtml:RetByName('C5_NUM')	)
		oProcessB:oHTML:ValByName("A1_NOME"			,oProcess:oHtml:RetByName('A1_NOME')	)
		oProcessB:oHTML:ValByName("motivo"			,oProcess:oHtml:RetByName('C5_MSGEXP')	)

		oProcessB:oHTML:ValByName("data"			,Date()		)
		oProcessB:oHTML:ValByName("hora"			,Time()		)
		oProcessB:oHTML:ValByName("rdmake"			,FunName()+"."+ProcName(0)	)

		If !Empty(cEmail)
			oProcessB:cTo :=  cEmail
		Else
			oProcessB:cTo := "suporte@decanter.com.br"
		Endif


		oProcessB:Start()
		oProcessB:Finish()

		ConOut("Pedido Liberado: "+cNum)


		oProcess:Finish()
	Endif

	RestArea(aAreaOld)
Return
