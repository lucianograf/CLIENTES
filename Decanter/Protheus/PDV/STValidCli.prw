#INCLUDE "PROTHEUS.CH"


User Function STValidCli ()
Local lRet := .T.
Local cCliCod := PARAMIXB[1] //Caracter – A1_COD
Local cLoja := PARAMIXB[2] //Caracter – A1_LOJA
Local cXCGC := ''
Local nLimCred := 0
Local nLimUsad := 0
Local nLimDisp := 0


    DbSelectArea("SA1")
	DbSetOrder(1)
    DbSeek(xFilial("SA1")+cCliCod+cLoja)
    cXCGC := SA1->A1_CGC
	nLimCred := SA1->A1_LC
	nLimUsad := SA1->A1_SALDUP
	nLimDisp := nLimCred - nLimUsad

	If cFilAnt $ "0101#0108" .AND. ( ALLTRIM(SA1->A1_VEND) == '' .OR. (ALLTRIM(SA1->A1_VEND) $ "000101-000138-000001-000002-000003-000130") )
	STDSPBasket("SL1","L1_VEND","000001")
	//msginfo('corrigido vendedor padrao no reinicio')
	EndIf

	If ALLTRIM(SA1->A1_CLIPRI) == 'COLABORA'
		MsgInfo("Limite total: "+cValToChar(nLimCred)+CHR(13)+CHR(10)+CHR(13)+CHR(10)+"Limite utilizado: "+cValToChar(nLimUsad)+CHR(13)+CHR(10)+CHR(13)+CHR(10)+"Limite disponivel: "+cValToChar(nLimDisp)," Credito Funcionario ")
	EndIf

	If (ALLTRIM(SA1->A1_VEND) <> '') .AND. !(ALLTRIM(SA1->A1_VEND) $ "000101-000138-000001-000002-000003-000130") .AND. cFilAnt $ "0101#0108"
    	DbSelectArea("SA3")
		DbSetOrder(1)
    	DbSeek(xFilial("SA3")+SA1->A1_VEND)
		//MsgInfo("Vendedor deste cliente: "+SA3->A3_COD+" - "+SA3->A3_NREDUZ," Carteira de clientes ")
		STDSPBasket("SL1","L1_VEND", SA1->A1_VEND)
	EndIf

    DbSelectArea("ZFD")
	DbSetOrder(1)
	if DbSeek(xFilial("ZFD")+cXCGC)
        MsgInfo("Fidelidade: "+cValToChar(ZFD->ZFD_SALDO)+" pontos" +CHR(13)+CHR(10)+CHR(13)+CHR(10)+"Data: "+DToC(zfd->ZFD_DATA)," Decanter+ ")
    EndIf
	

//lRet := MsgYesNo("Permite a seleção deste cliente?","Atenção")

Return lRet


/*

	DbSelectArea("ZCC")
	DbSetOrder(1)
	if DbSeek(SF2->F2_FILIAL+SD2->D2_PEDIDO)
		RecLock('ZCC',.F.)
			ZCC->ZCC_DOC   := SF2->F2_DOC
			ZCC->ZCC_SERIE := SF2->F2_SERIE
			ZCC->ZCC_DATA  := SF2->F2_EMISSAO
		ZCC->(MsUnlock())
	EndIf

 */
