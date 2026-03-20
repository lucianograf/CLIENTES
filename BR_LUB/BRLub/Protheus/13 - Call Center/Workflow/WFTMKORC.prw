#INCLUDE "rwmake.ch"
#INCLUDE "topconn.ch"
#INCLUDE "protheus.ch"


/*/{Protheus.doc} WFTMKORC
(long_description)

@author Marcelo Lauschner
@since 17/01/2014
@version 1.0

@return Sem retorno

@example
(examples)

@see (links_or_references)
/*/
User Function WFTMKORC()

	Local	aAreaOld	:= GetArea()
	Local 	nPeso    	:= 0.00
	Local	cDescE4		:= ""
	Local 	nPrzMed 	:= 0.00
	Local 	nPxItem		:= Ascan(aHeader,{|x| AllTrim(x[2]) == "UB_ITEM"})        	// Pega a posição do campo ITEM no aHeader
	Local	nPxCF		:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_CF"})
	Local	cAssessor	:= ""
	Local	cRetAlc		:= ""
	Local	lPrcTabFull	:= Substr(SUA->UA_XEMPFXC,1,2) $ "LL" // Verifico se o pedido é oriundo do segmento Lust
	Local	aMotBloq	:= {}
	Local	aItems		:= aClone(aCols)
	Local	cCfop		:= ""
	Local	nTotCfop	:= 0
	Local	cEmail 		:= ""
	Local	nI
	Local	lAvalOrc	:= sfVldAlcada(SUA->UA_NUM,aClone(aCols),aClone(aHeader))
	Local	cNea
	Local	oHtml
	Local	lNea
	Local	cProcess
	Local	cStatus
	Local	oProcess
	Local	cObs
	Local	nImpostos
	Local	nVlrFrete
	Local	lRetAlc
	Local	cObsHtml
	Local 	nTotOrc 	:= 0
	Local 	nTotDupl 	:= 0
	Local	cUsrId		:= RetCodUsr()
	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()
	
	If !IsBlind() .And. !lAvalOrc .And. !MsgYesNo("Deseja Submeter este Orçamento a Análise de Alçadas e receber o Workflow deste Orçamento?  Para envio de Workflow para cliente use a rotina 'Email Cotação'!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Envio Workflow")
		RestArea(aAreaOld)
		Return .T.
	Endif

	DbSelectArea("SUA")

	DbSelectArea("SA1")
	DbSetOrder(1)
	DbSeek(xFilial("SA1")+SUA->UA_CLIENTE+SUA->UA_LOJA)

	cNea  		:= SA1->A1_SATFORT

	cProcess := "100000"
	cStatus  := "100000"
	oProcess := TWFProcess():New(cProcess,OemToAnsi("Inclusão de Orçamento"))

	If IsSrvUnix()
		If File("/workflow/lib_orcamento.htm")
			oProcess:NewTask("Gerando HTML","/workflow/lib_orcamento.htm")
		Else
			FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "Não localizou arquivo  /workflow/lib_orcamento.htm"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			Return
		Endif
	Else
		oProcess:NewTask("Gerando HTML","\workflow\lib_orcamento.htm")
	Endif

	oProcess:cSubject := "Inclusao de Orcamento --> " + SUA->UA_NUM

	oProcess:bReturn  := ""

	oHTML := oProcess:oHTML

	oHtml:ValByName("NOMECOM"	,AllTrim(SM0->M0_NOMECOM))
	oHtml:ValByName("ENDEMP"		,Capital(AllTrim(SM0->M0_ENDENT)) + " - " + Capital(SM0->M0_BAIRENT))
	oHtml:ValByName("COMEMP"		,Transform(SM0->M0_CEPENT,"@R 99999-999") + " - " + Capital(AllTrim(SM0->M0_CIDENT)) + " - " + SM0->M0_ESTENT)
	oHtml:ValByName("FONE"		,"Fone/Fax: " + SM0->M0_TEL)
	oHtml:ValByName("EMISSAO"	,SUA->UA_EMISSAO)

	If cNea >= "R4020" .and. cNea <= "R4052"
		lNea := .T.
		oHtml:ValByName("CLIENTE",SA1->A1_COD+"/"+SA1->A1_LOJA+" - " +SA1->A1_NOME+'<font color=#FF0000>'+" <<< CLIENTE NUCLEO NEA >>>>"+'</font>')
	Else
		lNea := .F.
		oHtml:ValByName("CLIENTE",SA1->A1_COD+"/"+SA1->A1_LOJA+" - " +SA1->A1_NOME + "  CGC/CPF:" +  Transform( SA1->A1_CGC, Iif(SA1->A1_PESSOA == "J","@r 99.999.999/9999-99","@r 999.999.999-99")))
	Endif

	DbSelectArea("SE4")
	DbSetOrder(1)
	DbSeek(xFilial("SE4")+SUA->UA_CONDPG)

	oHtml:ValByName("NUMERO"		,SUA->UA_NUM)
	oHtml:ValByName("ENDERECO"	,SA1->A1_END + " - Bairro: " + SA1->A1_BAIRRO )
	oHtml:ValByName("MUNICIPIO"	,SA1->A1_MUN+" / " + SA1->A1_EST + " CEP:" + Transform(SA1->A1_CEP,"@R 99999-999"))
	oHtml:ValByName("USUARIO"	,cUserName)
	oHtml:ValByName("MINT"		,SUA->UA_MSGINT)
	oHtml:ValByName("MNOTA"		,SUA->UA_MENNOTA)


	DbSelectArea("SA3")
	DbSetOrder(1)
	DbSeek(xFilial("SA3")+SUA->UA_VEND)
	oHtml:ValByName("VENDEDOR","Vendedor--->>>"+SUA->UA_VEND+"-"+SA3->A3_NREDUZ)
	
	cEmail 	+= ";"+Alltrim(SA3->A3_EMAIL) // Adiciona o Email do Vendedor - Chamado 24.371 07/02/2020 - Solicitação Jonathan 
	
	cEmail	+= ";"+SA3->A3_MENS1		// Supervisor
	cEmail	+= ";"+SA3->A3_MENS2		//Gerente
	//cEmail	+= ";"+SA3->A3_EMTMK		// Assessora

	cAssessor  	:= SA3->A3_ACESSOR

	DbSelectArea("SF4")
	DbSetOrder(1)

	aSort(aItems,,,{|x,y| x[nPxCF]+x[nPxItem] < y[nPxCF]+y[nPxItem]})

	//Preenchendo itens
	For nI	:= 1 To Len(aItems)

		If !aItems[nI,Len(aHeader)+1]
			DbSelectArea("SUB")
			DbSetOrder(1)
			If DbSeek(xFilial("SUB") + M->UA_NUM + aItems[nI][nPxItem])
				If cCfop <> aItems[nI][nPxCF]
					If !Empty(cCfop)
						AAdd((oHtml:ValByName("P.IT")),"")
						AAdd((oHtml:ValByName("P.PRODUTO")),"")
						AAdd((oHtml:ValByName("P.ESTOQUE")),"")
						AAdd((oHtml:ValByName("P.QUANT")),"")
						AAdd((oHtml:ValByName("P.PRCTAB")),"")
						AAdd((oHtml:ValByName("P.PRCVEN")),"")
						AAdd((oHtml:ValByName("P.TAM")),"")

						// dbSelectArea("SX5")
						// dbSetOrder(1)
						// If dbSeek(xFilial("SX5")+"13"+cCfop)
						// 	AAdd((oHtml:ValByName("P.DESCRICAO"))	,cCfop+"--"+SX5->X5_DESCRI)
						// Else
						// 	AAdd((oHtml:ValByName("P.DESCRICAO"))	,cCfop)
						// Endif

						If !Empty(POSICIONE("SX5",1,xFilial('SX5')+"13"+cCfop,"X5_DESCRI"))
							//FWGetSX5("13",cCfop)
							cCfop += "--"+POSICIONE("SX5",1,xFilial('SX5')+"13"+cCfop,"X5_DESCRI")
						EndIf

						AAdd((oHtml:ValByName("P.DESCRICAO"))	,cCfop)
						AAdd((oHtml:ValByName("P.VALOR"))		,Transform(nTotCfop,"@E 999,999,999.99"))
						nTotCfop := 0.00
					Endif
					cCfop := aItems[nI][nPxCF]
				Endif

				DbSelectArea("SB1")
				DbSetOrder(1)
				DbSeek(xFilial("SB1")+SUB->UB_PRODUTO)

				AAdd((oHtml:ValByName("P.IT")) 			,SUB->UB_ITEM)
				AAdd((oHtml:ValByName("P.PRODUTO" ))	,AllTrim(SUB->UB_PRODUTO))
				AAdd((oHtml:ValByName("P.DESCRICAO" )) 	,SB1->B1_STS+"-"+AllTrim(SB1->B1_DESC))

				dbSelectArea("SB2")
				dbSetOrder(1)
				If dbSeek(xFilial("SB2")+SUB->UB_PRODUTO+SUB->UB_LOCAL)
					AAdd((oHtml:ValByName("P.ESTOQUE"))	,SB2->B2_QATU-SB2->B2_RESERVA)
				Else
					AAdd((oHtml:ValByName("P.ESTOQUE"))	,"0000")
				Endif

				AAdd((oHtml:ValByName("P.QUANT" )) 		,Transform(SUB->UB_QUANT,"@E 999,999,999"))
				AAdd((oHtml:ValByName("P.PRCTAB" )) 	,Transform(SUB->UB_PRCTAB,"@E 999,999.99"))

				nImpostos	:= MaFisRet(nI,"IT_VALIPI")+MaFisRet(nI,"IT_VALSOL")

				If lPrcTabFull
					AAdd((oHtml:ValByName("P.VALOR"))	,Transform(SUB->UB_VLRITEM+nImpostos,"@E 999,999,999.99"))
					AAdd((oHtml:ValByName("P.PRCVEN" )) ,Transform(SUB->UB_VRUNIT+(nImpostos/SUB->UB_QUANT),"@E 999,999.99"))
				Else
					AAdd((oHtml:ValByName("P.VALOR"))	,Transform(SUB->UB_VLRITEM,"@E 999,999,999.99"))
					AAdd((oHtml:ValByName("P.PRCVEN" )) ,Transform(SUB->UB_VRUNIT,"@E 999,999.99"))
				Endif

				AAdd((oHtml:ValByName("P.TAM"))			,Transform(SUB->UB_XVLRTAM,"@E 9,999.99"))

				nTotCfop 	+= SUB->UB_VLRITEM + Iif(lPrcTabFull,nImpostos,0)

				nPeso		+= SUB->UB_QUANT*SB1->B1_PESBRU

				nTotOrc 	:= SUB->UB_VLRITEM
				DbSelectArea("SF4")
				DbSetOrder(1)
				If DbSeek(xFilial("SF4") + SUB->UB_TES )
					If SF4->F4_DUPLIC == "S"
						nTotDupl 	+= SUB->UB_VLRITEM
					Endif 
				Endif 
			Endif
		Endif
	Next

	If !Empty(cCfop)
		AAdd((oHtml:ValByName("P.IT")),"")
		AAdd((oHtml:ValByName("P.PRODUTO")),"")
		AAdd((oHtml:ValByName("P.ESTOQUE")),"")
		AAdd((oHtml:ValByName("P.QUANT")),"")
		AAdd((oHtml:ValByName("P.PRCTAB")),"")
		AAdd((oHtml:ValByName("P.PRCVEN")),"")
		AAdd((oHtml:ValByName("P.TAM")),"")

		// dbSelectArea("SX5")
		// dbSetOrder(1)
		// If dbSeek(xFilial("SX5")+"13"+cCfop)
		// 	AAdd((oHtml:ValByName("P.DESCRICAO"))	,cCfop+"--"+SX5->X5_DESCRI)
		// Else
		// 	AAdd((oHtml:ValByName("P.DESCRICAO"))	,cCfop)
		// Endif

		If !Empty(POSICIONE("SX5",1,xFilial('SX5')+"13"+cCfop,"X5_DESCRI"))
			cCfop += "--"+POSICIONE("SX5",1,xFilial('SX5')+"13"+cCfop,"X5_DESCRI")//FWGetSX5("13",cCfop)
		EndIf

		AAdd((oHtml:ValByName("P.DESCRICAO"))	,cCfop)
		AAdd((oHtml:ValByName("P.VALOR"))		,Transform(nTotCfop,"@E 999,999,999.99"))
		nTotCfop := 0.00
	Endif

	nVlrFrete	:= U_BFFATM22(SUA->UA_EMISSAO/*dInData*/,SUA->UA_CLIENTE/*cInCodCli*/,SUA->UA_LOJA/*cInLojCli*/,SUA->UA_TRANSP/*cInTransp*/,nTotOrc/*nInVlrMerc*/,nPeso/*nInPeso*/,SUA->UA_FRETE/*nInVlrFrete*/)

	lRetAlc	:= U_BFFATM21("SUA"  ,nTotDupl,nTotOrc,@nPrzMed,@cDescE4,aClone(aCols),aClone(aHeader),@cRetAlc,@aMotBloq,nVlrFrete)

	oHtml:ValByName("CONDICAO"		,cDescE4+" - Média: "+Transform(nPrzMed,"@E 999,999,999")+" Dias")

	oHtml:ValByName("TOTAL"			,Transform(nTotOrc,"@E 999,999,999.99"))
	oHtml:ValByName("TOTPESO"		,Transform(nPeso,"@E 999,999.99"))
	oHtml:ValByName("FATURA"		,Transform(nTotDupl,"@E 999,999.99"))

	cObs     := ""
	cObsHtml := ""
	For nI := 1 To Len(aMotBloq)
		cObs += aMotBloq[nI][1]+Chr(13)+Chr(10)
		cObsHtml += aMotBloq[nI][1]+"<p></p>"
	Next


	oHtml:ValByName("MOTIVOS",cObsHtml)


	oHtml:ValByName("RDMAKE"			,"WFTMKORC.PRW")
	oHtml:ValByName("DATA"			,Date())
	oHtml:ValByName("HORA"			,Time())



	//Posiciona no SA3 no cadastro de vendedor da Assesssora e pega o email dela.
	DbSelectArea("SA3")
	DbSetOrder(1)
	DbSeek(xFilial("SA3")+cAssessor)

	cEmail 	+= ";"+Alltrim(SA3->A3_EMAIL)

	// Verifica se o usuário do sistema tem e-mail cadastrado e concatena e-mail
	If !Empty(UsrRetMail(cUsrId))
		oHtml:ValByName("EMAILUSER",UsrRetMail(cUsrId))
		If !UsrRetMail(cUsrId) $ cEmail
			//oProcess:cCc := UsrRetMail(__cUserId)
			cEmail += ";"+UsrRetMail(cUsrId)
		Endif
	Endif

	// 10/07/2024 - Envia o também para um email customizado por parâmetro 
	If !Empty(GetNewPar("BL_MAILWFO",""))
		cEmail += ";"+GetNewPar("BL_MAILWFO","")
	Endif 

	oProcess:cTo := U_BFFATM15(cEmail,"WFTMKORC")
	oProcess:Start()
	oProcess:Finish()

	// Força disparo dos e-mails pendentes do workflow
	WFSENDMAIL()

	If lRetAlc
		U_BFFATA35("O"/*cZ9ORIGEM*/,M->UA_NUM/*cZ9NUM*/,"6"/*cZ9EVENTO*/,"Liberação automática do orçamento sem restrição de alçadas"/*cZ9DESCR*/,oProcess:cTo /*cZ9DEST*/,cUserName/*cZ9USER*/)
	Else
		U_BFFATA35("O"/*cZ9ORIGEM*/,M->UA_NUM/*cZ9NUM*/,"6"/*cZ9EVENTO*/,"Orçamento com restrição de alçadas '"+cRetAlc+"'"/*cZ9DESCR*/,oProcess:cTo /*cZ9DEST*/,cUserName/*cZ9USER*/)
	Endif

	// Removido para o ponto de entrada TMKVFIM
	//If isInCallStack( "" )
	// Efetua chamada do envio do Link de aprovação do pedido
	//	U_BFFATA30(.T./*lAuto*/,SUA->UA_NUM/*cInPed*/,2/*nInPedOrc*/)
	//Endif
	
	MsgInfo("Workflow de Inclusão de Orçamento enviado para: " + oProcess:cTo , ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Workflow")

	RestArea(aAreaOld)
	
	
Return


/*/{Protheus.doc} Calc_IR
(long_description)
@author MarceloLauschner
@since 09/09/2014
@version 1.0
@param nValPreVen, numérico, (Descrição do parâmetro)
@param nValReemb, numérico, (Descrição do parâmetro)
@param nValCusto, numérico, (Descrição do parâmetro)
@param nValTam, numérico, (Descrição do parâmetro)
@param nPerICM, numérico, (Descrição do parâmetro)
@param nPerPIS, numérico, (Descrição do parâmetro)
@param nPerCOFINS, numérico, (Descrição do parâmetro)
@param nPerComiss, numérico, (Descrição do parâmetro)
@param nOutacres, numérico, (Descrição do parâmetro)
@param nPercent, numérico, (Descrição do parâmetro)
@param nPerRembCli, numérico, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function Calc_IR(	nValPreVen,nValReemb,nValCusto,nValTam,nPerICM,nPerPIS,nPerCOFINS,nPerComiss,nOutacres,nPercent,nPerRembCli)

	LOCAL	nMg2 := 0.00

	nMG2 := nValPreVen	- (nValCusto+nValReemb+nValTam+(nValPreVen*(nPerICM+nPerPIS+nPerCOFINS+nPercent+(U_BFFATM02()/100))))


Return( nMg2 )


/*/{Protheus.doc} BFFATM02
(long_description)

@author MarceloLauschner
@since 17/01/2014
@version 1.0

@param cInEmpAnt, character, (Descrição do parâmetro)

@return numerico, Percentual de custo para calculo IR

@example
(examples)

@see (links_or_references)
/*/
User Function BFFATM02(cInEmpAnt,cInFilAnt)

	Local aAreaOld 	:= GetArea()
	Local cQry
	Local nPercRet 	:= GetNewPar("BR_PCUSFIX",0)

	Default cInEmpAnt := cEmpAnt
	Default cInFilAnt := cFilAnt

	
	RestArea(aAreaOld)

Return(nPercRet)


/*/{Protheus.doc} sfVldAlcada
//Valida se orçamento deve ser submetido automaticamente a avaliação de alçadas. 
@author Marcelo Alberto Lauschner 
@since 01/03/2019
@version 1.0
@return ${return}, ${return_description}
@param cNumPed, characters, descricao
@param aInCols, array, descricao
@param aInHeader, array, descricao
@type function
/*/
Static Function sfVldAlcada(cNumPed,aInCols,aInHeader)

	Local	lRet		:= .T. 
	Local	iQ
	Local 	nPxItem		:= Ascan(aHeader,{|x| AllTrim(x[2]) == "UB_ITEM"})   
	Local 	nPxProd		:= Ascan(aHeader,{|x| AllTrim(x[2]) == "UB_PRODUTO"})
	
	
	For iQ	:= 1 To Len(aInCols)
		// Caso tenha algum item deletado
		If aInCols[iQ,Len(aInHeader)+1]
			DbSelectArea("SUB")
			DbSetOrder(1) //UB_FILIAL, UB_NUM, UB_ITEM, UB_PRODUTO, R_E_C_N_O_, D_E_L_E_T_
			If DbSeek(xFilial("SUB") + cNumPed + aInCols[iQ,nPxItem] + aInCols[iQ,nPxProd] )
				lRet	:= .F.
			Endif
		Else
			DbSelectArea("SUB")
			DbSetOrder(1) //UB_FILIAL, UB_NUM, UB_ITEM, UB_PRODUTO, R_E_C_N_O_, D_E_L_E_T_
			If DbSeek(xFilial("SUB")+cNumPed+aInCols[iQ,nPxItem]+aInCols[iQ,nPxProd])

			Else
				DbSelectArea("SUA")
				DbSetOrder(1)
				If DbSeek(xFilial("SUA")+ cNumPed)
					lRet	:= .F. 
				Endif
			Endif

		Endif
	Next iQ 

Return lRet

