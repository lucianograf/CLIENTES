#include 'protheus.ch'
#include 'parmtype.ch'


/*/{Protheus.doc} MLFATW01
//TODO Workflow de Cotação para pedido de Venda. 
@author Marcelo Alberto Lauschner 
@since 11/02/2020
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User function MLFATW01()

Return sfSendCot()


/*/{Protheus.doc} sfSendCot
//TODO Abre interface para usuário digitar o endereço de e-mail e observações. 
@author Marcelo Alberto Lauschner 
@since 11/02/2020
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
Static Function sfSendCot()

	Local	aAreaOld		:= GetArea()

	Local	cNumPed			:= SC5->C5_NUM
	Local 	oProcess     	:= Nil                                	//Objeto da classe TWFProcess.
	Local	lSend			:= .F.
	Local	nTotValor		:= 0
	Local	oDlgEmail
	Local	cRecebe			:= Padr(UsrRetMail(RetCodUsr()),200)
	Local	cSubject		:= Padr("Pedido: " + cNumPed + " " + AllTrim(SM0->M0_NOMECOM),200)
	Local	cBody			:= Space(500)
	Local	cCodProcesso
	Local	cHtmlModelo
	Local	cAssunto
	Local 	nItemFis 		:= 0
	Local 	nX 
	Local 	nY 
	Local 	aFisGetSC5		:= {}
	Local 	aFields			:= {}


	DEFINE MSDIALOG oDlgEmail Title OemToAnsi(ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Enviar email de cotação!") FROM 001,001 TO 380,620 PIXEL

	@ 010,010 Say "Para: " Pixel of oDlgEmail
	@ 010,050 MsGet cRecebe Size 180,10 Pixel Of oDlgEmail
	@ 025,010 Say "Assunto" Pixel of oDlgEmail
	@ 025,050 MsGet cSubject Picture "@#" Size 250,10 Pixel Of oDlgEmail
	@ 040,050 Get cBody of oDlgEmail MEMO Size 250,100 Pixel

	@ 160,050 BUTTON "Envia Email" Size 70,10 Action (lSend := .T.,oDlgEmail:End())	Pixel Of oDlgEmail
	@ 160,130 BUTTON "Cancela" Size 70,10 Action (oDlgEmail:End())	Pixel Of oDlgEmail

	ACTIVATE MsDialog oDlgEmail Centered

	If !lSend
		Return
	Endif


	// Código extraído do cadastro de processos.
	cCodProcesso := "ORC003" // SOLICITACAO DE APROVACAO DE PEDIDO A DIRETORIA

	If IsSrvUnix()
		// Arquivo html template utilizado para montagem da aprovação
		cHtmlModelo	:= "/workflow/orcamento_tmk_cliente.htm"
		If !File(cHtmlModelo)
			ConOut("Não localizou arquivo "+cHtmlModelo)
			Return
		Endif
	Else
		cHtmlModelo	:= "\workflow\orcamento_tmk_cliente.htm"
	Endif

	// Assunto da mensagem
	cAssunto 	:= cSubject


	oProcess := TWFProcess():New(cCodProcesso, cAssunto )

	oProcess:NewTask(cAssunto, cHtmlModelo)

	DbSelectArea("SA1")
	DbSetOrder(1)
	DbSeek(xFilial("SA1")+ SC5->C5_CLIENTE+SC5->C5_LOJACLI)


	oProcess:oHTML:ValByName("NOMECOM"		,AllTrim(SM0->M0_NOMECOM))
	oProcess:oHTML:ValByName("ENDEMP"		,Capital(AllTrim(SM0->M0_ENDENT)) + " - " + Capital(SM0->M0_BAIRENT))
	oProcess:oHTML:ValByName("COMEMP"		,Transform(SM0->M0_CEPENT,"@R 99999-999") + " - " + Capital(AllTrim(SM0->M0_CIDENT)) + " - " + SM0->M0_ESTENT)
	oProcess:oHTML:ValByName("FONE"			,"Fone/Fax: " + SM0->M0_TEL)
	oProcess:oHTML:ValByName("FONE1"		, SM0->M0_TEL)
	oProcess:oHtml:ValByName("EMAILUSER"	,UsrRetMail(RetCodUsr()))
	oProcess:oHTML:ValByName("ORCAMENTO"	,cNumPed			)
	oProcess:oHTML:ValByName("EMISSAO"		,SC5->C5_EMISSAO	)
	oProcess:oHTML:ValByName("CLIENTE"		,SC5->C5_CLIENTE+"/"+SC5->C5_LOJACLI	)
	oProcess:oHTML:ValByName("CGC"			,Transform(SA1->A1_CGC,"@R 99.999.999/9999-99")		)
	oProcess:oHTML:ValByName("NOME"			,SA1->A1_NOME		)

	oProcess:oHTML:ValByName("CONDPAG"		,SC5->C5_CONDPAG + " - "  + Posicione("SE4",1,xFilial("SE4")+SC5->C5_CONDPAG,"E4_DESCRI")	)
	oProcess:oHTML:ValByName("ENDERECO"		,Alltrim(SA1->A1_END) + Alltrim(SA1->A1_COMPLEM)	)
	oProcess:oHTML:ValByName("BAIRRO"		,Alltrim(SA1->A1_BAIRRO))
	oProcess:oHTML:ValByName("CIDADE"		,Alltrim(SA1->A1_MUN))
	oProcess:oHTML:ValByName("ESTADO"		,SA1->A1_EST		)

	
	aFields	 	:= FWSX3Util():GetAllFields("SC5", .F. /*/lVirtual/*/)

	For nX := 1 to Len(aFields)

		cCampo := aFields[nx]

		cValid := UPPER(GetSx3Cache(cCampo,"X3_VALID")+ GetSx3Cache(cCampo,"X3_VLDUSER"))

		If 'MAFISGET("'$cValid
			nPosIni 	:= AT('MAFISGET("',cValid)+10
			nLen		:= AT('")',Substr(cValid,nPosIni,Len(cValid)-nPosIni))-1
			cReferencia := Substr(cValid,nPosIni,nLen)
			aAdd(aFisGetSC5,{cReferencia,GetSx3Cache(cCampo,"X3_CAMPO"),MaFisOrdem(cReferencia)})
		EndIf
		If 'MAFISREF("'$cValid
			nPosIni		:= AT('MAFISREF("',cValid) + 10
			cReferencia	:=Substr(cValid,nPosIni,AT('","MT410",',cValid)-nPosIni)
			aAdd(aFisGetSC5,{cReferencia,GetSx3Cache(cCampo,"X3_CAMPO"),MaFisOrdem(cReferencia)})
		EndIf
		//	dbSkip()
		//EndDo
	Next nX

	aSort(aFisGetSC5,,,{|x,y| x[3]<y[3]})
	
	MaFisSave()
	MaFisEnd()
	MaFisIni(	Iif(Empty(SC5->C5_CLIENT),SC5->C5_CLIENTE,SC5->C5_CLIENT),;	// 1-Codigo Cliente/Fornecedor
	SC5->C5_LOJAENT,;														// 2-Loja do Cliente/Fornecedor
	IIf(SC5->C5_TIPO$'DB',"F","C"),;										// 3-C:Cliente , F:Fornecedor
	SC5->C5_TIPO,;															// 4-Tipo da NF
	SC5->C5_TIPOCLI,;														// 5-Tipo do Cliente/Fornecedor
	Nil,;																	// 6-Relacao de Impostos que suportados no arquivo
	Nil,;																	// 7-Tipo de complemento
	Nil,;																	// 8-Permite Incluir Impostos no Rodape .T./.F.
	Nil,;																	// 9-Alias do Cadastro de Produtos - ("SBI" P/ Front Loja)
	"MATA461",;																//10-Nome da rotina que esta utilizando a funcao
	Nil,;																	//11-Tipo de documento
	Nil,;																	//12-Especie do documento
	Nil,;																	//13
	Nil,;																	//14
	Nil,;																	//15
	Nil,;																	//16
	Nil)																	//17)																//17


	If Len(aFisGetSC5) > 0
		dbSelectArea("SC5")
		For nY := 1 to Len(aFisGetSC5)
			If !Empty(&("M->"+Alltrim(aFisGetSC5[ny][2])))
				MaFisAlt(aFisGetSC5[ny][1],&("M->"+Alltrim(aFisGetSC5[ny][2])),,.F.)
			EndIf
		Next nY
	Endif

	DbSelectArea("SC6")
	DbSetOrder(1)
	DbSeek(xFilial("SC6")+SC5->C5_NUM)
	While !Eof() .And. SC6->(C6_FILIAL+C6_NUM) == xFilial("SC6")+SC5->C5_NUM
		DbSelectArea("SB1")
		DbSetOrder(1)
		DbSeek(xFilial("SB1")+SC6->C6_PRODUTO)

		nItemFis++

		DbSelectArea("SF4")
		SF4->(dbSetOrder(1))
		SF4->(dbSeek(xFilial("SF4")+SC6->C6_TES))

		MaFisAdd(	SB1->B1_COD,;  			// 1-Codigo do Produto ( Obrigatorio )
		SC6->C6_TES,;	   					// 2-Codigo do TES ( Opcional )
		SC6->C6_QTDVEN,;  					// 3-Quantidade ( Obrigatorio )
		SC6->C6_PRCVEN,;		  			// 4-Preco Unitario ( Obrigatorio )
		0,;			 						// 5-Valor do Desconto ( Opcional )
		"",;	   							// 6-Numero da NF Original ( Devolucao/Benef )
		"",;								// 7-Serie da NF Original ( Devolucao/Benef )
		0,;									// 8-RecNo da NF Original no arq SD1/SD2
		0,;									// 9-Valor do Frete do Item ( Opcional )
		0,;									// 10-Valor da Despesa do item ( Opcional )
		0,;									// 11-Valor do Seguro do item ( Opcional )
		0,;									// 12-Valor do Frete Autonomo ( Opcional )
		SC6->C6_QTDVEN*SC6->C6_PRCVEN,;		// 13-Valor da Mercadoria ( Obrigatorio )
		0,;									// 14-Valor da Embalagem ( Opiconal )
		,;									// 15
		,;									// 16
		SC6->C6_ITEM,;					 	// 17
		0,;									// 18-Despesas nao tributadas - Portugal
		0,;									// 19-Tara - Portugal
		SC6->C6_CF,; 						// 20-CFO
		{},;	           					// 21-Array para o calculo do IVA Ajustado (opcional)
		"")


		AAdd((oProcess:oHtml:ValByName("it.item"))	,SC6->C6_ITEM)
		AAdd((oProcess:oHtml:ValByName("it.cod"))	,SC6->C6_PRODUTO)
		AAdd((oProcess:oHtml:ValByName("it.desc"))	,SC6->C6_DESCRI)

		nTotValor		+= SC6->C6_VALOR

		AAdd((oProcess:oHtml:ValByName("it.qte"))	,Transform(SC6->C6_QTDVEN	,X3Picture("C6_QTDVEN")))
		AAdd((oProcess:oHtml:ValByName("it.prcven")),Transform(SC6->C6_PRCVEN	,X3Picture("C6_PRCVEN")))
		AAdd((oProcess:oHtml:ValByName("it.total"))	,Transform(Mafisret(nItemFis,"IT_VALMERC")	,X3Picture("C6_VALOR")))

		SC6->(DbSkip())
	Enddo

	oProcess:oHTML:ValByName("TOTMERCADORIA"	,Transform(MaFisRet(,"NF_VALMERC") 	,X3Picture("F2_VALBRUT")))
	oProcess:oHTML:ValByName("TOTIMPOSTO"		,Transform(MaFisRet(,"NF_TOTAL")-MaFisRet(,"NF_VALMERC") ,X3Picture("F2_VALBRUT")))
	oProcess:oHTML:ValByName("TOTVALOR"			,Transform(MaFisRet(,"NF_TOTAL") 	,X3Picture("F2_VALBRUT")))

	oProcess:oHTML:ValByname("OBSERV"		,cBody			)
	oProcess:oHTML:ValByName("data"			,Date()		)
	oProcess:oHTML:ValByName("hora"			,Time()		)
	oProcess:oHTML:ValByName("rdmake"		,FunName()+"."+ProcName(0)	)

	MaFisEnd()

	oProcess:cSubject := cSubject
	cRecebe	:= Alltrim(cRecebe)+";"+UsrRetMail(RetCodUsr())
	oProcess:cTo	:= U_MLCFGM04(cRecebe,"MLFATW01")
	oProcess:Start()
	oProcess:Finish()

	MsgInfo("Mensagem enviada para '"+ cRecebe +"'",ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Workflow")

	// Chama função que força o envio de WF
	WFSENDMAIL()

	U_MLCFGM01("WF",SC5->C5_NUM,,FunName())

	RestArea(aAreaOld)

Return
