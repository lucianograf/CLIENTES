#include 'Protheus.ch'
#include "RPTDEF.CH"
#DEFINE CRLF	Chr(13)+chr(10)
/*/{Protheus.doc} FORTR001

Impressao do contrato Vendor dentro da rotina de pedido de vendas.

@author TSCB57 - WILLIAM FARIAS
@since 31/07/2019
@version 1.0
/*/
User Function FORTR001()
	Local cNumPed		:= SC5->C5_NUM
	Local cCaminho		:="\spool\"
	Local cFilePrint	:= alltrim(cNumPed)+"-contrato-vendor-"+dtos(date())+StrTran(time(),":","")
	Local aFiles	:=	{}
	Local nRemotType	:=	GetRemoteType()
	Local lRetEx		:=	.F.
	Private cPerg		:= "FORTR001"
	Private cTitulo		:= "Contrato Vendor"
	Private lDados		:= .F.

	Begin Sequence
		IF !ExistDir(cCaminho)
			MakeDir(cCaminho)
		EndIf

			//TODO: DESCOMENTAR ANTES DE POR EM PRODUCAO
//			//Valida condição de pagamento Vendor
//			If AllTrim(SC5->C5_CONDPAG) <> "V01" //Diferente de Vendor
//				MsgAlert("Pedido não possui contrato Vendor. Verifique a condição de pagamento.","Atenção - "+ProcName())
//				Return
//			Endif
		
		//Chama pergunte
		aParamBox	:=	{}
		aRet		:=	{}
		//aAdd(aParamBox,{1,"Valor",0,"@E 9,999.99","mv_par02>0","","",20,.F.}) // Tipo numérico 
		aAdd(aParamBox,{1,"Qtd. Parcelas"  		,SC5->C5_ZQPARC			,PesqPict('SC5','C5_ZQPARC'),"","","",50,.T.})
		aAdd(aParamBox,{1,"Valor Parcela"  		,SC5->C5_ZVALPAR		,PesqPict('SC5','C5_ZVALPAR'),"","","",50,.T.})
		aAdd(aParamBox,{1,"Juros"  				,SC5->C5_ZPJUROS		,PesqPict('SC5','C5_ZPJUROS'),"","","",50,.T.})
		aAdd(aParamBox,{1,"Data 1º Vencto."  	,SC5->C5_ZDT1VEN	,"","","","",50,.T.})
		aAdd(aParamBox,{3,"Saída",1,{"Enviar para Cliente","Imprimir"},80,"",.T.})
		
		If !ParamBox(aParamBox,"Parametros Vendor",@aRet)
			Break
		EndIf
		lSendMail	:= aRet[5] == 1

		SC5->(RecLock("SC5",.F.))
			SC5->C5_ZQPARC	:= MV_PAR01
			SC5->C5_ZVALPAR	:= MV_PAR02
			SC5->C5_ZPJUROS	:= MV_PAR03
			SC5->C5_ZDT1VEN	:= MV_PAR04
		SC5->(MsUnlock())
			
		//Valida parametros informados
		If Empty(MV_PAR01) .Or. Empty(MV_PAR02) .Or. Empty(MV_PAR03) 
			MsgAlert("Os parâmetros não devem estar em branco, favor verificar.","Atenção - "+ProcName())
			Break

		EndIf
			
		//Valida contrato emitido com campos já preenchidos na SC5
		If !Empty(SC5->C5_ZQPARC) .And. !Empty(SC5->C5_ZDT1VEN)  .And. !Empty(SC5->C5_ZVALPAR) .And. !Empty(SC5->C5_ZPJUROS) .AND. !MsgYesNo("Pedido já possui contrato emitido, você deseja reemitir com os novos dados informados?","Atenção - "+ProcName())
			Break
		Endif
			
	
	
		dbSelectArea("SA1")
		dbSetOrder(1)
		msSeek(FWxFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI)


		//MaFisSave()
		MaFisEnd()
		MaFisIni(SA1->A1_COD,;// 1-Codigo Cliente/Fornecedor
			SA1->A1_LOJA,;		// 2-Loja do Cliente/Fornecedor
			"C",;				// 3-C:Cliente , F:Fornecedor
			"N",;				// 4-Tipo da NF
			SA1->A1_TIPO,;		// 5-Tipo do Cliente/Fornecedor
			Nil,;
			Nil,;
			Nil,;
			Nil,;
			"MATA410")


		dbSelectArea("SC6")
		dbSetOrder(1)
		msSeek(FWxFilial("SC6")+SC5->C5_NUM)
		nItem		:=	0
		While SC6->(!Eof()) .AND. FWXFilial("SC6")+SC6->C6_NUM == FWxFilial("SC5")+SC5->C5_NUM
			nItem	++
			SB1->(msSeek(FWxFilial("SB1")+SC6->C6_PRODUTO))
			
			MaFisAdd(SB1->B1_COD,;   	// 1-Codigo do Produto ( Obrigatorio )
					SC6->C6_TES,;	   	// 2-Codigo do TES ( Opcional )
					SC6->C6_QTDVEN,;  	// 3-Quantidade ( Obrigatorio )
					SC6->C6_PRCVEN,;		  	// 4-Preco Unitario ( Obrigatorio )
					0,; 	// 5-Valor do Desconto ( Opcional )
					"",;	   			// 6-Numero da NF Original ( Devolucao/Benef )
					"",;				// 7-Serie da NF Original ( Devolucao/Benef )
					0,;					// 8-RecNo da NF Original no arq SD1/SD2
					0,;					// 9-Valor do Frete do Item ( Opcional )
					0,;					// 10-Valor da Despesa do item ( Opcional )
					0,;					// 11-Valor do Seguro do item ( Opcional )
					0,;					// 12-Valor do Frete Autonomo ( Opcional )
					SC6->C6_QTDVEN*SC6->C6_PRCVEN,;			// 13-Valor da Mercadoria ( Obrigatorio )
					0)					// 14-Valor da Embalagem ( Opiconal )
			
			SC6->(dbSkip())
		EndDO
		

		//Valida se total das parcelas é maior que 30% do total do pedido
		If MV_PAR01 * MV_PAR02 >  MaFisRet(,"NF_TOTAL") + (MaFisRet(,"NF_TOTAL") * (GetNewPar("GF_FORTR01",30)/100) ) //(30/100)*MaFisRet(,"NF_TOTAL")
			MsgAlert("Total das parcelas não deve superar " + cValToChar(GetNewPar("GF_FORTR01",30))+ "% do total do pedido, favor verificar.","Atenção - GF_FORTR01."+ProcName())
			Break
		EndIf


		If lSendMail
			If nRemotType <> -1// tratamento para nao entrar nessa regra quando for job
				// Quando é chamado pelo Smartclient o TOTVSPRINTER gera na pasta temp do cliente, sendo necessioar copiar para o servidor
				// para poder enviar no email
				cPathTPrin	:=	gettemppath()+'totvsprinter\'+cFilePrint+".pdf"
				If File(cPathTPrin)
					FErase(cPathTPrin)
				EndIf
			else
				If File(cCaminho+cFilePrint+".pdf")
					FErase(cCaminho+cFilePrint+".pdf")
				EndIf
			EndIF
			
		
			oReport := ReportDef(cFilePrint,lSendMail)
			FWMsgRun(,{|| oReport:Print(.F.) },"Gerando Contrato")
			
			
			If nRemotType <> -1 // tratamento para nao entrar nessa regra quando for job
				If File(cPathTPrin)
					If File(cCaminho+cFilePrint+".pdf")
						FErase(cCaminho+cFilePrint+".pdf")
					EndIf
					CpyT2S(cPathTPrin,cCaminho,.T.)
					sleep(500)
				EndIf
			EndIf

			//Apaga arquivos  menores que 1 dia
			aArqErase := directory(cCaminho+"*.pdf")
			For nO := 1 To Len(aArqErase)
				If aArqErase[nO][3] < date()-1
					FERASE(cCaminho+aArqErase[nO][1])
				EndIf
			Next
		
			//HTML do email
			//TODO: Verificar quais os dados de envio e corpo do email.
			//TODO: Verificar dados do servidor de email para configurar nos parametros da função ACTXFUN.
			//HTML do email
		cHtml:=	''
		cHtml+=CRLF+'<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">'
		cHtml+=CRLF+'<html xmlns="http://www.w3.org/1999/xhtml">'
		cHtml+=CRLF+'<head>'
		cHtml+=CRLF+'<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />'
		cHtml+=CRLF+'<title></title>'
		cHtml+=CRLF+'<style type="text/css">'
		cHtml+=CRLF+'body,td,th {'
		cHtml+=CRLF+'	font-family: Arial, Helvetica, sans-serif;'
		cHtml+=CRLF+'	font-size: 12px;'
		cHtml+=CRLF+'}'
		cHtml+=CRLF+'.rodape {'
		cHtml+=CRLF+'	font-size: 10px;'
		cHtml+=CRLF+'	color: #666;'
		cHtml+=CRLF+'}'
		cHtml+=CRLF+'</style>'
		cHtml+=CRLF+'</head>'
		cHtml+=CRLF+'<body>'
		cHtml+=CRLF+'<p><img src="'+Alltrim(GetMV('MV_ZWFLOGO',,"http://www.forta.com.br/libs/imgs/logo.1474463494.png"))+'" alt="Site" /></p>'
		cHtml+=CRLF+'<p>Olá, estamos  encaminhando o contrato VENDOOR referente ao pedido de venda '+SC5->C5_NUM+'</p>'
		cHtml+=CRLF+'<p>Este é um e-mail automático, não responder. <br></p>'
		cHtml+=CRLF+'</body>'
		cHtml+=CRLF+'</html>'
//				cHtml:=	''
//				cHtml+=CRLF+'<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">'
			
			// TODO: DESCOMENTAR
			cTo		 := "rafael@forta.com.br"//Alltrim(SA1->A1_EMAIL)
			cAssunto := 'Contrato Vendor Pedido '+SC5->C5_NUM
			cCC		 :=	"ml-servicos@outlook.com"
			
			aadd(aFiles,cCaminho+cFilePrint+".pdf")
			
			For nI	:= 1 To Len(aFiles)
			
				If !Empty(aFiles[1]) .AND. !File(aFiles[1])
					MsgStop("Arquivo não localizado no caminho "+aFiles[1],"Atenção-"+ProcName())
					Break
				EndIf
			Next
			
			FWMsgRun(,{|| lRetEx := U_MailSmtp() },"Autenticando E-mail")
			if lRetEx
				//cFrom,cTo,cCC,cBcc,cSubject,cBody,aAnexoMail,cReplyTo
				FWMsgRun(,{|| lRetEx := U_MailSend(/*cFrom*/,cTo, UsrRetMail(RetCodUsr()),/*cBcc*/,cAssunto,cHtml,aFiles/*,cReplyTo*/) },"Enviando Email")
				If !lRetEx
					MsgStop("Não foi possível enviar o email com o contrato","Atenção-"+ProcName())
				EndIf

			endif
			U_MailOff()
			
				// Apaga os arquivos
			For nI	:= 1 To Len(aFiles)
				If File(aFiles[1])
					FErase(aFiles[1])
				EndIf
			Next

		else
			oReport := ReportDef(cFilePrint,lSendMail)
			oReport:PrintDialog()
		EndIf
		
	End Sequence

	MaFisEnd()

Return


/*/{Protheus.doc} ReportDef

Função padrão para definição do relatório

@author TSCB57 - WILLIAM FARIAS
@since 31/07/2019
@version 1.0
/*/
Static Function ReportDef(cFilePrint,lSendMail)
	Local oReport
	Local cDescT	:=	"Efetua envio de email e impressão do contrato Vendor."
	
	oReport := TReport():New("FORTR001",cTitulo,"",;
	{|oReport|  cMsgRetorno := PrintReport(@oReport)},cDescT)
	oReport:oPage:SetPaperSize(9)//(DMPAPER_A4)	//Papel
	oReport:SetPortrait() 		//Orientação Retrato
	oReport:DisableOrientation()//Desabilita orientação 
	oReport:HideHeader()		//Nao mostra cabecalho
	oReport:HideFooter()		//Nao mostra rodape
	oReport:HideParamPage()		//Nao mostra tela de parametros
	oReport:SetColSpace(2)		//Tamanho da coluna de cada seção
	oReport:nFontBody := 12		//Tamanho da fonte
	oReport:SetEdit(.F.)
	oReport:cFontBody := 'Arial'
	oReport:SetLineHeight(40)
	oReport:DisableOrientation()
	If lSendMail
		//oReport:cPathPDF := "C:\temp"
		oReport:SetPreview(.F.)
		//oReport:cFile := cFilePrint
		oReport:SetReportPortal(cFilePrint)
		//oReport:nEnvironment	:=	1
		oReport:SetEnvironment(1)
		// oReport:LVIEWPDF := .F.
		oReport:SetViewPDF(.F.)
		oReport:nRemoteType := NO_REMOTE        // FORMA DE GERAÇÃO DO RELATÓRIO
	    oReport:nDevice     := IMP_PDF                // 6
	EndIf
	// If File(gettemppath()+'totvsprinter\'+cFilePrint+".pdf")
	// 	FErase(gettemppath()+'totvsprinter\'+cFilePrint+".pdf")
	// EndIf
	// If File(gettemppath()+'totvsprinter\'+cFilePrint+".rel")
	// 	FErase(gettemppath()+'totvsprinter\'+cFilePrint+".rel")
	// EndIf

Return oReport

/*/{Protheus.doc} PrintReport

Função padrão para impressão

@author TSCB57 - WILLIAM FARIAS
@since 31/07/2019
@version 1.0
/*/
Static	Function PrintReport(oReport, cMsgRetorno)
	Local oTFontLi	:= TFont():New('Arial'/*cName*/,/*uPar2*/,11/*nHeight*/,/*uPar4*/,/*lBold*/,/*uPar6*/,/*uPar7*/,/*uPar8*/,/*uPar9*/,/*lUnderline*/,/*lItalic*/)
	Local oTFontLiB := TFont():New('Arial'/*cName*/,/*uPar2*/,11/*nHeight*/,/*uPar4*/,.T./*lBold*/,/*uPar6*/,/*uPar7*/,/*uPar8*/,/*uPar9*/,/*lUnderline*/,/*lItalic*/)
	Local oTFontTiB := TFont():New('Arial'/*cName*/,/*uPar2*/,12/*nHeight*/,/*uPar4*/,.T./*lBold*/,/*uPar6*/,/*uPar7*/,/*uPar8*/,/*uPar9*/,/*lUnderline*/,/*lItalic*/)
	Local oBrush	:=	TBrush():New( ,  RGB(228, 228, 228)  ) //Cinza
	Local nI
	Local cString1	:= "", cString2 := "", cString3 := ""
	Local nCntLin	:= 0	//Contador de linhas
	Local nQtdLin	:= 1	//Quantidade de linhas
	Local nTamLin	:= 118	//Tamanho da linha
	Local nTamLin2	:= 160	//Tamanho da linha para centralizar
	Local cValTemp	:= ""
	Local nParcTotal := MV_PAR01*MV_PAR02
	Private nIa
	

	oReport:SetMeter(0)
	oReport:IncMeter()

	oReport:StartPage()

	If oReport:Cancel()
		MsgStop("Cancelado pelo operador","Atenção-"+ProcName())
		Return
	EndIf



//	dbSelectArea("SA1")
//	dbSetOrder(1)
//	If !SA1->(dbSeek(FWxFilial("SA1")+cCodCli+cLojCli))//!dbSeek(xFilial("SA1")+cCodCli+cLojCli)
//		Return "Cliente não localizado"
//	EndIf

	//coluna inicial
	nColInc	 :=	300
	nColInc2 :=	450
	
	oReport:PrintText('')
	oReport:PrintText('')
	oReport:PrintText('')
	oReport:Say(oReport:Row(),nColInc,PadC("CONTRATO DE COMPRA E VENDA DE EQUIPAMENTO", nTamLin2),oTFontTiB)
	oReport:SkipLine()
	oReport:Say(oReport:Row(),nColInc,PadC("AUTOMOTIVO COM RESERVA DE DOMÍNIO", nTamLin2),oTFontTiB)
	oReport:SkipLine()
	oReport:SkipLine()
	oReport:SkipLine()
	oReport:Say(oReport:Row(),nColInc2,"Pelo presente instrumento particular, as partes abaixo qualificadas:",oTFontLi)
	oReport:SkipLine()
	oReport:SkipLine()
	oReport:SkipLine()
	
	cString1 += Alltrim(SM0->M0_NOMECOM)+", pessoa jurídica de direito privado, inscrita no CNPJ sob o nº "+Transform(SM0->M0_CGC, "@R 99.999.999/9999-99")+", estabelecida na "+Alltrim(SM0->M0_ENDCOB)+", "+Alltrim(SM0->M0_BAIRCOB)+", na cidade de "+Alltrim(SM0->M0_CIDCOB)+"/"+Alltrim(SM0->M0_ESTCOB)+", CEP "+Transform(SM0->M0_CEPCOB, "@R 99999-999")+", neste ato representada na forma do seu estatuto social, doravante designada como VENDEDORA; e "
	cString1 += chr(13)+chr(10)+chr(13)+chr(10)
	cString1 += Alltrim(SA1->A1_NOME)+", pessoa jurídica de direito privado, inscrita no CNPJ sob o n.º "+Transform(SA1->A1_CGC, "@R 99.999.999/9999-99")+", com sede na "+Alltrim(SA1->A1_END)+", Bairro "+Alltrim(SA1->A1_BAIRRO)+", na cidade de "+Alltrim(SA1->A1_MUN)+"/"+Alltrim(SA1->A1_EST)+", CEP "+Transform(SA1->A1_CEP, "@R 99999-999")+", representada por seu sócio administrador, doravante designada como COMPRADORA. "
	cString1 += chr(13)+chr(10)+chr(13)+chr(10)
	cString1 += "Têm entre si, como justo e contratado, o que se segue: "
	cString1 += chr(13)+chr(10)+chr(13)+chr(10)
	cString1 += "1. A VENDEDORA vende à COMPRADORA, e esta compra, pelo preço certo e ajustado de R$"+alltrim(transform(MaFisRet(,"NF_TOTAL"),GetSX3Cache("C6_VALOR","X3_PICTURE")))+"("+AllTrim(Extenso(MaFisRet(,"NF_TOTAL"),.f.,1,,'1',.t.,.f.))+") os seguintes produtos, objeto do pedido de compra número "+alltrim(SC5->C5_NUM)+" de "+alltrim(dtoc(SC5->C5_EMISSAO))+"."
	nPageAtu := oReport:Page()
	nQtdLin := MLCount(cString1, nTamLin) // Quantidade de linhas do texto
	For nCntLin:=1 To nQtdLin
		// Imprime a linha
		If nPageAtu <> oReport:Page()
			nPageAtu	:=	oReport:Page()
			oReport:PrintText('')
			oReport:PrintText('')
			oReport:PrintText('')
		EndIf
		oReport:Say(oReport:Row(), nColInc, MemoLine(cString1, nTamLin, nCntLin), oTFontLi)
		oReport:SkipLine()	
	Next nCntLin

	oReport:SkipLine()
	oReport:SkipLine()
	
	nColInc		:=	0
	aColsPrd	:=	{}	//inicia coluna
	nAdjCol		:=	7	//ajuste coluna
	nAdjLin		:=	25	//ajuste das linhas e box,
	nIncColA	:=	300	//coluna inicial
	nAdjPag		:=	200	//Ajusta pagewidht
	
	nLinAnt		:=	oReport:LineHeight() //Salva tamanho da linha 
	oReport:SetLineHeight(70)	//Altera tamanho da linha
	aadd(aColsPrd,{"Descrição Produto"	,nIncColA	,'transform(SB1->B1_DESC,GetSX3Cache("B1_DESC","X3_PICTURE"))'		});nIncColA+=1200	//1
	aadd(aColsPrd,{"Quantidade"			,nIncColA	,'transform(SC6->C6_QTDVEN,GetSX3Cache("C6_QTDVEN","X3_PICTURE"))'	});nIncColA+=205	//2
	aadd(aColsPrd,{"Valor Unitário"		,nIncColA	,'transform(SC6->C6_PRCVEN,GetSX3Cache("C6_PRCVEN","X3_PICTURE"))'	});nIncColA+=280	//3
	// aadd(aColsPrd,{"Valor Total"		,nIncColA	,'transform(MaFisRet(nItem,"IT_TOTAL"),GetSX3Cache("C6_VALOR","X3_PICTURE"))'		});nIncColA+=215	//4
	
	//{linha inicial, coluna inicial, linha final, coluna final}
	//Monta quadros e linhas do cabeçalho
	For nI := 1 To Len(aColsPrd)
		//{linha inicial, coluna inicial, linha final, coluna final}
		If nI == Len(aColsPrd) //tratamento para ultima coluna
			oReport:Box(oReport:Row()-nAdjLin, aColsPrd[ni][2] ,oReport:Row()+oReport:LineHeight()-nAdjLin, oReport:PageWidth()-nAdjPag)
			oReport:Fillrect( {oReport:Row()-nAdjLin,aColsPrd[ni][2],oReport:Row()+oReport:LineHeight()-nAdjLin,oReport:PageWidth()-nAdjPag}, oBrush)
			//Line(nTop,nLeft,nBottom,nRight,oPen)
			oReport:Line(oReport:Row()-nAdjLin,aColsPrd[ni][2],oReport:Row()+oReport:LineHeight()-nAdjLin,aColsPrd[ni][2]) //linha vertical inicio
			oReport:Line(oReport:Row()-nAdjLin,oReport:PageWidth()-nAdjPag,oReport:Row()+oReport:LineHeight()-nAdjLin,oReport:PageWidth()-nAdjPag) //linha vertical fim
			oReport:Line(oReport:Row()-nAdjLin,aColsPrd[ni][2],oReport:Row()-nAdjLin,oReport:PageWidth()-nAdjPag) //linha horizontal inicial
			oReport:Line(oReport:Row()+oReport:LineHeight()-nAdjLin,aColsPrd[ni][2],oReport:Row()+oReport:LineHeight()-nAdjLin,oReport:PageWidth()-nAdjPag) //linha horizontal final

		Else
			oReport:Box( oReport:Row()-nAdjLin, aColsPrd[ni][2] ,oReport:Row()+oReport:LineHeight()-nAdjLin,aColsPrd[ni+1][2])
			oReport:Fillrect( {oReport:Row()-nAdjLin,aColsPrd[ni][2],oReport:Row()+oReport:LineHeight()-nAdjLin,aColsPrd[ni+1][2]}, oBrush)
			oReport:Line(oReport:Row()-nAdjLin,aColsPrd[ni][2],oReport:Row()+oReport:LineHeight()-nAdjLin,aColsPrd[ni][2]) //linha vertical inicio
			oReport:Line(oReport:Row()-nAdjLin,aColsPrd[ni+1][2],oReport:Row()+oReport:LineHeight()-nAdjLin,aColsPrd[ni+1][2]) //linha vertical fim
			oReport:Line(oReport:Row()-nAdjLin,aColsPrd[ni][2],oReport:Row()-nAdjLin,oReport:PageWidth()-nAdjPag) //linha horizontal inicial
			oReport:Line(oReport:Row()+oReport:LineHeight()-nAdjLin,aColsPrd[ni][2],oReport:Row()+oReport:LineHeight()-nAdjLin,aColsPrd[ni+1][2]) //linha horizontal final

		EndIf
	Next
	//Monta descrição de cada cabeçalho
	For nI := 1 To Len(aColsPrd)
		oReport:Say(oReport:Row(),aColsPrd[ni][2]+nAdjCol,aColsPrd[ni][1],oTFontLiB)
	Next
	oReport:SkipLine()

	dbSelectArea("SB1")
	dbSetOrder(1)

	dbSelectArea("SC6")
	dbSetOrder(1)
	msSeek(FWxFilial("SC6")+SC5->C5_NUM)
	aItems	:=	{}
	nItem		:=	0
	nPageAtu	:= oReport:Page()
	While SC6->(!Eof()) .AND. FWXFilial("SC6")+SC6->C6_NUM == FWxFilial("SC5")+SC5->C5_NUM
		nItem	++
		SB1->(msSeek(FWxFilial("SB1")+SC6->C6_PRODUTO))
		If nPageAtu <> oReport:Page()
			nPageAtu	:=	oReport:Page()
			oReport:PrintText('')
			oReport:PrintText('')
			oReport:PrintText('')
		EndIf

		MaFisAdd(SB1->B1_COD,;   	// 1-Codigo do Produto ( Obrigatorio )
				SC6->C6_TES,;	   	// 2-Codigo do TES ( Opcional )
				SC6->C6_QTDVEN,;  	// 3-Quantidade ( Obrigatorio )
				SC6->C6_PRCVEN,;		  	// 4-Preco Unitario ( Obrigatorio )
				0,; 	// 5-Valor do Desconto ( Opcional )
				"",;	   			// 6-Numero da NF Original ( Devolucao/Benef )
				"",;				// 7-Serie da NF Original ( Devolucao/Benef )
				0,;					// 8-RecNo da NF Original no arq SD1/SD2
				0,;					// 9-Valor do Frete do Item ( Opcional )
				0,;					// 10-Valor da Despesa do item ( Opcional )
				0,;					// 11-Valor do Seguro do item ( Opcional )
				0,;					// 12-Valor do Frete Autonomo ( Opcional )
				SC6->C6_QTDVEN*SC6->C6_PRCVEN,;			// 13-Valor da Mercadoria ( Obrigatorio )
				0)					// 14-Valor da Embalagem ( Opiconal )

		//Monta bordas e fundo
		For nI := 1 To Len(aColsPrd)
			If nI == Len(aColsPrd) //tratamento para ultima coluna
				If nItem%2 == 0//par
					oReport:Fillrect( {oReport:Row()-nAdjLin,aColsPrd[ni][2],oReport:Row()+oReport:LineHeight()-nAdjLin,oReport:PageWidth()-nAdjPag}, oBrush)
				EndIf
				oReport:Line(oReport:Row()-nAdjLin,aColsPrd[ni][2],oReport:Row()+oReport:LineHeight()-nAdjLin,aColsPrd[ni][2]) //linha vertical inicio
				oReport:Line(oReport:Row()-nAdjLin,oReport:PageWidth()-nAdjPag,oReport:Row()+oReport:LineHeight()-nAdjLin,oReport:PageWidth()-nAdjPag) //linha vertical fim
				oReport:Line(oReport:Row()-nAdjLin,aColsPrd[ni][2],oReport:Row()-nAdjLin,oReport:PageWidth()-nAdjPag) //linha horizontal inicial
				oReport:Line(oReport:Row()+oReport:LineHeight()-nAdjLin,aColsPrd[ni][2],oReport:Row()+oReport:LineHeight()-nAdjLin,oReport:PageWidth()-nAdjPag) //linha horizontal final
			Else
				If nItem%2 == 0//par
					oReport:Fillrect( {oReport:Row()-nAdjLin,aColsPrd[ni][2],oReport:Row()+oReport:LineHeight()-nAdjLin,aColsPrd[ni+1][2]}, oBrush)
				EndIF
				oReport:Line(oReport:Row()-nAdjLin,aColsPrd[ni][2],oReport:Row()+oReport:LineHeight()-nAdjLin,aColsPrd[ni][2]) //linha vertical inicio
				oReport:Line(oReport:Row()-nAdjLin,aColsPrd[ni+1][2],oReport:Row()+oReport:LineHeight()-nAdjLin,aColsPrd[ni+1][2]) //linha vertical fim
				oReport:Line(oReport:Row()-nAdjLin,aColsPrd[ni][2],oReport:Row()-nAdjLin,oReport:PageWidth()-nAdjPag) //linha horizontal inicial
				oReport:Line(oReport:Row()+oReport:LineHeight()-nAdjLin,aColsPrd[ni][2],oReport:Row()+oReport:LineHeight()-nAdjLin,aColsPrd[ni+1][2]) //linha horizontal final
			EndIf
			
			//Imprime informação
			cValTemp	:= &(aColsPrd[ni][3])
			cValTemp	:= alltrim(cValTemp)
			oReport:Say(oReport:Row(),aColsPrd[ni][2]+nAdjCol,cValTemp,oTFontLi)
		Next

		oReport:SkipLine()


		SC6->(dbSkip())
	EndDO


	oReport:SetLineHeight(nLinAnt)	//Restaura tamanho da linha
	oReport:SkipLine()

	//coluna inicial
	nColInc	 :=	300
	
	cString2 += "2. O preço ajustado pela venda e compra do bem objeto da cláusula primeira, será pago pela COMPRADORA, por meio de obtenção de financiamento bancário denominado de “VENDOR”, no qual a VENDEDORA obtém financiamento em nome da COMPRADORA, estritamente de acordo com a Nota Fiscal de compra, se comprometendo da COMPRADORA a pagar financiamento conforme tabela abaixo:"
	
	nQtdLin := MLCount(cString2, nTamLin) // Quantidade de linhas do texto
	nPageAtu := oReport:Page()
	For nCntLin:=1 To nQtdLin
		If nPageAtu <> oReport:Page()
			nPageAtu	:=	oReport:Page()
			oReport:PrintText('')
			oReport:PrintText('')
			oReport:PrintText('')
		EndIf

		// Imprime a linha
		oReport:Say(oReport:Row(), nColInc, MemoLine(cString2, nTamLin, nCntLin), oTFontLi)
		oReport:SkipLine()	
	Next nCntLin
	oReport:SkipLine()
	oReport:SkipLine()
	
	//////////INICIO TABELA DE CONDICAO DE PAGAMENTO//////////
	nColInc		:=	0
	aColsPrd	:=	{}	//inicia coluna
	nAdjCol		:=	7	//ajuste coluna
	nAdjLin		:=	25	//ajuste das linhas e box,
	nIncColA	:=	500	//coluna inicial
	nAdjPag		:=	400	//ajusta pagewidht
	nLinAnt		:=	oReport:LineHeight() //Salva tamanho da linha 
	oReport:SetLineHeight(70)	//Altera tamanho da linha
	

	aadd(aColsPrd,{"Pagamento a:"	,nIncColA	,'"ITAU - VENDOR"'														});nIncColA+=600	//1
	aadd(aColsPrd,{"Parcela"		,nIncColA	,'StrZero(nItem,GetSX3Cache("C5_ZQPARC","X3_TAMANHO"))'	});nIncColA+=205	//2
	aadd(aColsPrd,{"Vencimento"		,nIncColA	,'dtoc(dataValida(SC5->C5_ZDT1VEN+(30*nItem),.T.))'													});nIncColA+=241	//3
	aadd(aColsPrd,{"Valor"			,nIncColA	,'transform(SC5->C5_ZVALPAR,GetSX3Cache("C5_ZVALPAR","X3_PICTURE"))'	});nIncColA+=250	//4
	
	//{linha inicial, coluna inicial, linha final, coluna final}
	//Monta quadros e linhas do cabeçalho
	For nI := 1 To Len(aColsPrd)
		//{linha inicial, coluna inicial, linha final, coluna final}
		If nI == Len(aColsPrd) //tratamento para ultima coluna
			oReport:Box(oReport:Row()-nAdjLin, aColsPrd[ni][2] ,oReport:Row()+oReport:LineHeight()-nAdjLin, oReport:PageWidth()-nAdjPag)
			oReport:Fillrect( {oReport:Row()-nAdjLin,aColsPrd[ni][2],oReport:Row()+oReport:LineHeight()-nAdjLin,oReport:PageWidth()-nAdjPag}, oBrush)
			//Line(nTop,nLeft,nBottom,nRight,oPen)
			oReport:Line(oReport:Row()-nAdjLin,aColsPrd[ni][2],oReport:Row()+oReport:LineHeight()-nAdjLin,aColsPrd[ni][2]) //linha vertical inicio
			oReport:Line(oReport:Row()-nAdjLin,oReport:PageWidth()-nAdjPag,oReport:Row()+oReport:LineHeight()-nAdjLin,oReport:PageWidth()-nAdjPag) //linha vertical fim
			oReport:Line(oReport:Row()-nAdjLin,aColsPrd[ni][2],oReport:Row()-nAdjLin,oReport:PageWidth()-nAdjPag) //linha horizontal inicial
			oReport:Line(oReport:Row()+oReport:LineHeight()-nAdjLin,aColsPrd[ni][2],oReport:Row()+oReport:LineHeight()-nAdjLin,oReport:PageWidth()-nAdjPag) //linha horizontal final

		Else
			oReport:Box( oReport:Row()-nAdjLin, aColsPrd[ni][2] ,oReport:Row()+oReport:LineHeight()-nAdjLin,aColsPrd[ni+1][2])
			oReport:Fillrect( {oReport:Row()-nAdjLin,aColsPrd[ni][2],oReport:Row()+oReport:LineHeight()-nAdjLin,aColsPrd[ni+1][2]}, oBrush)
			oReport:Line(oReport:Row()-nAdjLin,aColsPrd[ni][2],oReport:Row()+oReport:LineHeight()-nAdjLin,aColsPrd[ni][2]) //linha vertical inicio
			oReport:Line(oReport:Row()-nAdjLin,aColsPrd[ni+1][2],oReport:Row()+oReport:LineHeight()-nAdjLin,aColsPrd[ni+1][2]) //linha vertical fim
			oReport:Line(oReport:Row()-nAdjLin,aColsPrd[ni][2],oReport:Row()-nAdjLin,oReport:PageWidth()-nAdjPag) //linha horizontal inicial
			oReport:Line(oReport:Row()+oReport:LineHeight()-nAdjLin,aColsPrd[ni][2],oReport:Row()+oReport:LineHeight()-nAdjLin,aColsPrd[ni+1][2]) //linha horizontal final

		EndIf
	Next

	//Monta descrição de cada cabeçalho
	For nI := 1 To Len(aColsPrd)
		oReport:Say(oReport:Row(),aColsPrd[ni][2]+nAdjCol,aColsPrd[ni][1],oTFontLiB)
	Next
	oReport:SkipLine()


	//Pagamento
	aItemsPag	:=	{}
	nControl1	:= 0
	nItem		:=	0 
	nPageAtu 	:=	 oReport:Page()
	For nIKK := 1 to SC5->C5_ZQPARC
		nControl1++
		nItem	++
		If nPageAtu <> oReport:Page()
			nPageAtu	:=	oReport:Page()
			oReport:PrintText('')
			oReport:PrintText('')
			oReport:PrintText('')
		EndIf

		//Monta bordas e fundo
		For nI := 1 To Len(aColsPrd)
			If nI == Len(aColsPrd) //tratamento para ultima coluna
				If nItem%2 == 0//par
					oReport:Fillrect( {oReport:Row()-nAdjLin,aColsPrd[ni][2],oReport:Row()+oReport:LineHeight()-nAdjLin,oReport:PageWidth()-nAdjPag}, oBrush)
				EndIf
				oReport:Line(oReport:Row()-nAdjLin,aColsPrd[ni][2],oReport:Row()+oReport:LineHeight()-nAdjLin,aColsPrd[ni][2]) //linha vertical inicio
				oReport:Line(oReport:Row()-nAdjLin,oReport:PageWidth()-nAdjPag,oReport:Row()+oReport:LineHeight()-nAdjLin,oReport:PageWidth()-nAdjPag) //linha vertical fim
				oReport:Line(oReport:Row()-nAdjLin,aColsPrd[ni][2],oReport:Row()-nAdjLin,oReport:PageWidth()-nAdjPag) //linha horizontal inicial
				oReport:Line(oReport:Row()+oReport:LineHeight()-nAdjLin,aColsPrd[ni][2],oReport:Row()+oReport:LineHeight()-nAdjLin,oReport:PageWidth()-nAdjPag) //linha horizontal final
			Else
				If nItem%2 == 0//par
					oReport:Fillrect( {oReport:Row()-nAdjLin,aColsPrd[ni][2],oReport:Row()+oReport:LineHeight()-nAdjLin,aColsPrd[ni+1][2]}, oBrush)
				EndIF
				oReport:Line(oReport:Row()-nAdjLin,aColsPrd[ni][2],oReport:Row()+oReport:LineHeight()-nAdjLin,aColsPrd[ni][2]) //linha vertical inicio
				oReport:Line(oReport:Row()-nAdjLin,aColsPrd[ni+1][2],oReport:Row()+oReport:LineHeight()-nAdjLin,aColsPrd[ni+1][2]) //linha vertical fim
				oReport:Line(oReport:Row()-nAdjLin,aColsPrd[ni][2],oReport:Row()-nAdjLin,oReport:PageWidth()-nAdjPag) //linha horizontal inicial
				oReport:Line(oReport:Row()+oReport:LineHeight()-nAdjLin,aColsPrd[ni][2],oReport:Row()+oReport:LineHeight()-nAdjLin,aColsPrd[ni+1][2]) //linha horizontal final
			EndIf
			
			//Imprime informação
			cValTemp	:= &(aColsPrd[ni][3])
			cValTemp	:= alltrim(cValTemp)
			oReport:Say(oReport:Row(),aColsPrd[ni][2]+nAdjCol,cValTemp,oTFontLi)
		Next
		oReport:SkipLine()
	Next


	oReport:Say(oReport:Row(),aColsPrd[LEN(aColsPrd)-1][2]+nAdjCol,"TOTAL:",oTFontTib)
	oReport:Say(oReport:Row(),aColsPrd[LEN(aColsPrd)][2]+nAdjCol,alltrim(transform(nParcTotal,GetSX3Cache("C5_ZVALPAR","X3_PICTURE"))),oTFontLi)
	oReport:SkipLine()
	//////////FIM TABELA DE CONDICAO DE PAGAMENTO//////////
	
	oReport:SetLineHeight(nLinAnt)	//Restaura tamanho da linha
	oReport:SkipLine()

	//coluna inicial
	nColInc	 :=	300
	
	cString3 += "2.1. A obtenção do financiamento pela VENDEDORA em nome da COMPRADORA ocorrerá a seu único e exclusivo critério, bem como a escolha da instituição bancária, sem que haja a obrigatoriedade de a VENDEDORA obter ou apresentar proposta para captação de financiamento junto a instituição bancária para a COMPRADORA."
	cString3 += chr(13)+chr(10)+chr(13)+chr(10)
	cString3 += "2.2. A liquidação do valor financiado operar-se-á pelo pagamento pela COMPRADORA dos valores constantes dos avisos de cobrança que lhe serão enviados diretamente pela instituição bancária financiadora, servindo os mesmos como documento automático de quitação do débito."
	cString3 += chr(13)+chr(10)+chr(13)+chr(10)
	cString3 += "3. O inadimplemento de qualquer parcela do financiamento bancário concedido à COMPRADORA, ensejará no vencimento antecipado da operação de VENDOR, bem como sujeitará a COMPRADORA ao pagamento do valor ainda devido à VENDEDORA, acrescido de juros de mora de 1% (um por cento) ao mês, desde a data do vencimento, além de multa de 2% (dois por cento) sobre a quantia assim calculada, tudo acrescido da comissão de permanência cobrada pela Instituição Financeira que conceder o crédito às taxas de mercado na ocasião do atraso, bem como demais encargos repassados pelo banco financiador."
	cString3 += chr(13)+chr(10)+chr(13)+chr(10)
	cString3 += "4. Por força de pacto de reserva de domínio, aqui expressamente instituído e aceito pelas partes, fica reservada à VENDEDORA a propriedade do bem descrito na cláusula primeira, até a total liquidação do financiamento denominado “VENDOR”, pela COMPRADORA."
	cString3 += chr(13)+chr(10)+chr(13)+chr(10)
	cString3 += "5. A posse do bem é concedida à COMPRADORA, a partir da assinatura do comprovante de entrega do equipamento (canhoto Nota Fiscal), porém, em consequência do disposto nas demais cláusulas deste contrato, constituindo-se em mora a COMPRADORA, em virtude do inadimplemento de qualquer parcela ajustada do financiamento, obrigar-se-á a restituir incontinente o objeto adquirido à VENDEDORA, restituição essa que se fará amigavelmente ou em consonância com o disposto no art. 526 do Código Civil Brasileiro."
	cString3 += chr(13)+chr(10)+chr(13)+chr(10)
	cString3 += "6. A mora ou inadimplemento da COMPRADORA no pagamento do financiamento, acarretará na rescisão do presente negócio jurídico e a imediata restituição do bem à VENDEDORA em perfeito estado de uso e conservação e, em caso de recusa, poderá a VENDEDORA promover a busca e apreensão do bem vendido de forma imediata, mediante a comprovação de notificação extrajudicial."
	cString3 += chr(13)+chr(10)+chr(13)+chr(10)
	cString3 += "7. Este contrato obriga não só os contratantes, mas também seus herdeiros e/ou sucessores, ficando eleito o foro da Comarca de Blumenau/SC, para as questões dele eventualmente advindas."
	cString3 += chr(13)+chr(10)+chr(13)+chr(10)
	cString3 += "Assim, estando justos e contratados, firmam o presente em duas vias de igual teor, na presença de duas testemunhas."
	cString3 += chr(13)+chr(10)+chr(13)+chr(10)
	cString3 += "Blumenau/SC, "+dtoc(Date())
	
	nQtdLin := MLCount(cString3, nTamLin) // Quantidade de linhas do texto
	nPageAtu := oReport:Page()
	For nCntLin:=1 To nQtdLin
		If nPageAtu <> oReport:Page()
			nPageAtu	:=	oReport:Page()
			oReport:PrintText('')
			oReport:PrintText('')
			oReport:PrintText('')
		EndIf
		// Imprime a linha
		oReport:Say(oReport:Row(), nColInc, MemoLine(cString3, nTamLin, nCntLin), oTFontLi)
		oReport:SkipLine()	
	Next nCntLin

	oReport:SkipLine()
	oReport:SkipLine()
	oReport:SkipLine()
	
	//Caso não tiver espaço, gera uma nova pagina, 1410e o tamanho necessario para finalizar com as assinaturas
	If oReport:PageHeight()-oReport:Row() <= 800
		oReport:EndPage()
		oReport:StartPage()
		oReport:PrintText('')
		oReport:PrintText('')
		oReport:PrintText('')
		oReport:PrintText('')
	EndIf

	oReport:Say(oReport:Row(),nColInc,PadC("____________________________________________________________", nTamLin2),oTFontLiB)
	oReport:SkipLine()
	oReport:Say(oReport:Row(),nColInc,PadC(Alltrim(SM0->M0_NOMECOM), 157),oTFontLiB)
	oReport:SkipLine()
	oReport:Say(oReport:Row(),nColInc,PadC("VENDEDORA", 206),oTFontLiB)
	oReport:SkipLine()
	oReport:SkipLine()
	oReport:SkipLine()
	oReport:SkipLine()
	oReport:SkipLine()
	oReport:SkipLine()
	oReport:Say(oReport:Row(),nColInc,PadC("____________________________________________________________", nTamLin2),oTFontLiB)
	oReport:SkipLine()
	oReport:Say(oReport:Row(),nColInc,PadC(Alltrim(SA1->A1_NOME), 172),oTFontLiB)
	oReport:SkipLine()
	oReport:Say(oReport:Row(),nColInc,PadC("COMPRADORA", 202),oTFontLiB)
	oReport:SkipLine()
	oReport:SkipLine()
	oReport:SkipLine()
	oReport:Say(oReport:Row(),nColInc,"TESTEMUNHAS:",oTFontLi)
	oReport:SkipLine()
	oReport:SkipLine()
	oReport:Say(oReport:Row(),nColInc,"____________________________________________________________ (CPF _______________)",oTFontLi)
	oReport:SkipLine()
	oReport:SkipLine()
	oReport:SkipLine()
	oReport:SkipLine()
	oReport:Say(oReport:Row(),nColInc,"____________________________________________________________ (CPF _______________)",oTFontLi)
	oReport:SkipLine()
	
	oReport:EndPage()

Return 