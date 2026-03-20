#INCLUDE "PROTHEUS.CH"


/*/{Protheus.doc} GMCFGM01
(Gravação de log de pedidos em diversos pontos do sistema)
@author MarceloLauschner
@since 04/07/2015
@version 1.0
@param cTipo, character, (Descrição do parâmetro)
@param cPedido, character, (Descrição do parâmetro)
@param cObserv, character, (Descrição do parâmetro)
@param cResp, character, (Descrição do parâmetro)
@param lBtnCancel, ${param_type}, (Descrição do parâmetro)
@param cMotDef, character, (Descrição do parâmetro)
@param lAutoExec, ${param_type}, (Descrição do parâmetro)
@param cInUserAuto, character, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function GMCFGM01(cTipo,cPedido,cObserv,cResp,lBtnCancel,cMotDef,lAutoExec,cInUserAuto)
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
	Local		lContinua	:= .F.
	Default		cMotDef		:= cMotBlq
	Default		cTipo		:= "LG"
	Default 	lBtnCancel	:= .F.
	Default 	cObserv		:= ""
	Default		lAutoExec	:= .F.
	Default		cInUserAuto	:= cUserName
	Default		cPedido		:= ""
	
	// Efetua verificação se esta validação deve ser executada para esta empresa/filial
	If !U_BFCFGM25("GMCFGM01")
		Return   {cMotBlq,.T. /*lContinua*/}
	Endif
	
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
	ElseIf cTipo == "CN"
		cDescTipo	:= "Cancelamento NotaFiscal/Pedido"
		DbSelectArea("SD2")
		DbSetOrder(3)
		DbSeek(xFilial("SD2")+SF2->F2_DOC+SF2->F2_SERIE+SF2->F2_CLIENTE+SF2->F2_LOJA)
		cPedido		:= SD2->D2_PEDIDO
		lJustif		:= .T.
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
	ElseIf cTipo == "EP"
		cDescTipo	:= "Exclusão do Pedido"
		lJustif		:= .T.
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
			@ 010,010 Say "Justificativa" of oDlgObs Pixel
			@ 025,010 MsGet cMotBlq	Size 175,10 Valid(Len(Alltrim(StrTran(StrTran(cMotBlq," ",""),".",""))) > 12)   of oDlgObs Pixel
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
	
	RecLock("SZ0",.T.)
	SZ0->Z0_FILIAL := xFilial("SZ0")
	SZ0->Z0_PEDIDO := cPedido
	SZ0->Z0_DATA   := Date()
	SZ0->Z0_HORA   := Time()
	SZ0->Z0_USER   := cInUserAuto
	SZ0->Z0_DEST   := cResp
	SZ0->Z0_TIPO   := cTipo
	
	If SZ0->(FieldPos("Z0_DESCOC")) <> 0
		SZ0->Z0_DESCOC	:= cDescTipo
	Endif
	If SZ0->(FieldPos("Z0_CONTEUD")) <> 0
		SZ0->Z0_CONTEUD	:= cDescTipo
	Endif
	If SZ0->(FieldPos("Z0_OBS")) <> 0
		SZ0->Z0_OBS    := IIf(!Empty(cMotBlq),"Motivo: "+cMotBlq + Chr(13)+ Chr(10)+cObserv,cObserv)
	Endif
	MsUnLock()
	
	RestArea(aAreaOld)
	
Return {cMotBlq,lContinua}
