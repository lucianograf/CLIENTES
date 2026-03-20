#include 'protheus.ch'
#include 'parmtype.ch'


/*/{Protheus.doc} MLCFGM01
//TODO Descrição auto-gerada.
@author marce
@since 21/05/2020
@version 1.0
@return ${return}, ${return_description}
@param cTipo, characters, descricao
@param cPedido, characters, descricao
@param cObserv, characters, descricao
@param cResp, characters, descricao
@param lBtnCancel, logical, descricao
@param cMotDef, characters, descricao
@param lAutoExec, logical, descricao
@param cInUserAuto, characters, descricao
@param cInDestMail, characters, descricao
@type function
/*/
User Function MLCFGM01(cTipo,cPedido,cObserv,cResp,lBtnCancel,cMotDef,lAutoExec,cInUserAuto,cInDestMail)

	//Return {""/*cMotBlq*/,.T./*lContinua*/}

	//	Static Function sfTeste()
	//-------------------------------------------------------------------------------------------------
	// 23/07/2011 - Marcelo Lauschner
	// Alterado tratativa da variavel cPedido no caso de cancelamento de Documento para a Superlog
	// pois CTRC não possui Pedido de venda para gravar historico na SZ0 e portanto fica o valor de F2_DOC
	//-------------------------------------------------------------------------------------------------

	Local		aAreaOld	:= GetArea()
	Local		cDescTipo	:= ""
	Local		oDlgObs
	Local		cMotBlq		:= Space(150)
	Local		lJustif		:= .F.
	Local		lSelCodMot	:= .F.
	Local		lContinua	:= .F.
	Local		cCodMot		:= ""
	Default		cMotDef		:= cMotBlq
	Default		cTipo		:= "LG"
	Default 	lBtnCancel	:= .F.
	Default 	cObserv		:= ""
	Default		lAutoExec	:= .F.
	Default		cInUserAuto	:= cUserName
	Default		cPedido		:= ""
	Default		cInDestMail	:= ""

	If !Empty(cMotDef)
		cMotBlq	:= Padr(cMotDef,150)
	Endif


	If cTipo == "IP"
		cDescTipo	:= "Inclusão de Pedido"
	ElseIf cTipo == "AP"
		cDescTipo	:= "Alteração de Pedido"
	ElseIf cTipo == "AC"
		cDescTipo	:= "Alteração Cabeçalho de Pedido"
	ElseIf cTipo == "FL"
		cDescTipo	:= "Follwo-up de Pedido"
	ElseIf cTipo == "LF"
		cDescTipo	:= "Liberação de Alçada"
	ElseIf cTipo == "LP"
		cDescTipo	:= "Liberação de Pedido"
	ElseIf cTipo == "BT"
		cDescTipo	:= "Bloqueio/Pendência Comercial"
	ElseIf cTipo == "BF"
		cDescTipo	:= "Bloqueio/Pendência Financeira"
	ElseIf cTipo == "BA"
		cDescTipo	:= "Bloqueio/Pagto Antecipado"
	ElseIf cTipo == "LA"
		cDescTipo	:= "Liberação/Pgto Antecipado"
	ElseIf cTipo == "LC"
		cDescTipo	:= "Liberação Crédito"
	ElseIf cTipo == "LR"
		cDescTipo	:= "Pedido Rejeitado"
		lJustif	:= .T.
	ElseIf cTipo == "ED"
		cDescTipo	:= "Enviado p/Expedição"
	ElseIf cTipo == "IM" // Impressao manual para separacao
		cDescTipo	:= "Impressão Pedido p/Separação"
	ElseIf cTipo == "EC"
		cDescTipo	:= "Enviado p/Separação/Emissão NF"
	ElseIf cTipo == "CP"
		cDescTipo	:= "Conferência/Emissão Etiquetas"
	ElseIf cTipo == "ET"
		cDescTipo	:= "Exportado para Arquivo EDI"
	ElseIf cTipo == "WF"
		cDescTipo	:= "Gerado Workflow de Cotação do Pedido"
	ElseIf cTipo == "ST"
		cDescTipo	:= "Atualização Status Pedido"
	ElseIf cTipo == "CN"
		cDescTipo	:= "Cancelamento NotaFiscal/Pedido"
		DbSelectArea("SD2")
		DbSetOrder(3)
		DbSeek(xFilial("SD2")+SF2->F2_DOC+SF2->F2_SERIE+SF2->F2_CLIENTE+SF2->F2_LOJA)
		cPedido		:= SD2->D2_PEDIDO
		lJustif		:= .T.
		lSelCodMot	:= .T.
	ElseIf cTipo == "NF"
		cDescTipo	:= "Gerada Nota Fiscal Doc.Saída"
		DbSelectArea("SD2")
		DbSetOrder(3)
		DbSeek(xFilial("SD2")+SF2->F2_DOC+SF2->F2_SERIE+SF2->F2_CLIENTE+SF2->F2_LOJA)
		cPedido		:= SD2->D2_PEDIDO
	ElseIf cTipo == "IN"
		cDescTipo	:= "Geração/Impressão da Danfe "
		DbSelectArea("SD2")
		DbSetOrder(3)
		DbSeek(xFilial("SD2")+SF2->F2_DOC+SF2->F2_SERIE+SF2->F2_CLIENTE+SF2->F2_LOJA)
		cPedido		:= SD2->D2_PEDIDO

	ElseIf cTipo == "EF"
		cDescTipo	:= "Pedido Retornado ao TMK"
		lJustif		:= .T.
	ElseIf cTipo == "DB"
		cDescTipo	:= "Lançamento Box/Sep/Conf/Mes"
	ElseIf cTipo == "ER"
		cDescTipo	:= "Eliminação de Resíduos"
		lJustif		:= .T.
		lSelCodMot	:= .T.
	ElseIf cTipo == "EP"
		cDescTipo	:= "Exclusão do Pedido"
		lJustif		:= .T.
		lSelCodMot	:= .T.
	ElseIf cTipo == "LE"
		cDescTipo	:= "Liberação de Estoque"
		lJustif		:= .T.
	ElseIf cTipo == "EL"
		cDescTipo	:= "Exclusao de Lote Contábil"
		lJustif		:= .T.
	Endif

	If lJustif

		If !lAutoExec
			DEFINE MSDIALOG oDlgObs FROM 000,000 TO 150,370 OF oMainWnd PIXEL TITLE OemToAnsi(cDescTipo +" "+ cPedido )
			@ 012,010 Say "Justificativa" of oDlgObs Pixel

			If lSelCodMot
				@ 010,045 Combobox cCodMot Items U_MLCFGM05() Size 140,13 Pixel of oDlgObs
			Endif

			@ 030,010 MsGet cMotBlq	Size 175,10 Valid(Len(Alltrim(StrTran(StrTran(cMotBlq," ",""),".",""))) > 12)   of oDlgObs Pixel
			@ 050,010 BUTTON "&Avança" of oDlgObs pixel SIZE 40,10 ACTION (lContinua	:= .T.,oDlgObs:End() )

			If lBtnCancel
				@ 050,050 BUTTON "&Cancela" of oDlgObs pixel SIZE 40,10 ACTION (oDlgObs:End() )
			Endif
			ACTIVATE msDIALOG oDlgObs CENTERED Valid(Len(Alltrim(StrTran(StrTran(cMotBlq," ",""),".",""))) > 12)
			If lBtnCancel
				If !lContinua
					cMotBlq	:= "Operação cancelada pelo usuário/"+cMotBlq
				Endif
			Endif
		Else
			cMotBlq	+= "/Processo automático."
		Endif
	Endif

	Begin Transaction
		RecLock("SZ0",.T.)
		SZ0->Z0_FILIAL := xFilial("SZ0")
		SZ0->Z0_PEDIDO := cPedido
		SZ0->Z0_DATA   := Date()
		SZ0->Z0_HORA   := Time()
		SZ0->Z0_USER   := cInUserAuto
		If SZ0->(FieldPos("Z0_ROTINA")) <> 0
			SZ0->Z0_ROTINA   := cResp
		Endif

		If SZ0->(FieldPos("Z0_DESTMAI")) <> 0
			SZ0->Z0_DESTMAI   := cInDestMail
		Endif
		SZ0->Z0_TIPO   := cTipo

		If SZ0->(FieldPos("Z0_CONTEUD")) <> 0
			SZ0->Z0_CONTEUD	:= cDescTipo
		Endif
		If SZ0->(FieldPos("Z0_OBS")) <> 0
			SZ0->Z0_OBS    := IIf(!Empty(cMotBlq),"Motivo: "+cMotBlq + Chr(13)+ Chr(10)+cObserv,cObserv)
		Endif
		If SZ0->(FieldPos("Z0_CODMOT")) <> 0
			SZ0->Z0_CODMOT    := cCodMot
		Endif

		MsUnLock()

		// Grava o código do motivo no pedido de vendas tb
		If lSelCodMot
			DbSelectArea("SC5")
			RecLock("SC5",.F.)
			SC5->C5_ZSTATS 	:= cCodMot
			MsUnlock()
		Endif
	End Transaction

	RestArea(aAreaOld)

	// Faz a chamada para atualizar o pedido no site 
	DbSelectArea("SC5")
	DbSetOrder(1)
	If DbSeek(xFilial("SC5")+cPedido)
		// Se for faturamento do pedido, já ajusta o status
		If cTipo $ "IN#NF"
			RecLock("SC5",.F.)
			SC5->C5_ZSTATS 	:= "002"
			MsUnlock()
		Endif 
		// Se for pedido Vellis já sobe status 
		If !Empty(SC5->C5_IDAJILI)
			U_Rest1Pvc(cPedido)
		Endif 
	Endif 


Return {cMotBlq,lContinua}




