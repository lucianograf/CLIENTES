#INCLUDE "PROTHEUS.CH"

/*/{Protheus.doc} DCCFGM02
Rotina para gravação de Log de pedidos. Acionamento em diversos pontos de entrada e rotinas que envolvam Pedido de Venda
@type function
@version  
@author Marcelo Alberto Lauschner
@since 14/04/2022
@param cTipo, character, param_description
@param cPedido, character, param_description
@param cObserv, character, param_description
@param cResp, character, param_description
@param lBtnCancel, logical, param_description
@param cMotDef, character, param_description
@param lAutoExec, logical, param_description
@param cInUserAuto, character, param_description
@return variant, return_description
/*/
User Function DCCFGM02(cTipo,cPedido,cObserv,cResp,lBtnCancel,cMotDef,lAutoExec,cInUserAuto)
	
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
	Default		cInUserAuto	:= RetCodUsr() + "-" + UsrFullName(RetCodUsr())
	Default		cPedido		:= ""
	
    // Caso não seja a empresa 01-Decanter ou 02-Hermann - Não executa a gravação de log 
    If !(cEmpAnt $ "01#02")
        Return({"",.T.})
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
	ElseIf cTipo == "TS"
		cDescTipo	:= "Transmissão Nota para Sefaz"
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
	ElseIf cTipo == 'IO'
		cDescTipo	:= "Inclusão de Ocorrência GFE"
	ElseIf cTipo == 'EO'
		cDescTipo	:= "Exclusão de Ocorrência GFE"
	ElseIf cTipo == 'AO'
		cDescTipo	:= "Alteração de Ocorrência GFE"
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
	
	RecLock("Z00",.T.)
	Z00->Z00_FILIAL := xFilial("Z00")
	Z00->Z00_PEDIDO := cPedido
	Z00->Z00_DATA   := Date()
	Z00->Z00_HORA   := Time()
	Z00->Z00_USER   := cInUserAuto
	Z00->Z00_DEST   := cResp
	Z00->Z00_TIPO   := cTipo	
	Z00->Z00_DESC	:= cDescTipo
	Z00->Z00_OBS     := IIf(!Empty(cMotBlq),"Motivo: "+cMotBlq + Chr(13)+ Chr(10)+cObserv,cObserv)
	MsUnLock()
	
	RestArea(aAreaOld)
	
Return {cMotBlq,lContinua}
