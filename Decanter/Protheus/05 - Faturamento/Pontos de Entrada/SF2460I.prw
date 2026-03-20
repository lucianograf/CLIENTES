#INCLUDE "PROTHEUS.CH"
#INCLUDE "RWMAKE.CH"
/*/{Protheus.doc} SF2460I
Ponto de Entrada - Final da geração da nota fiscal / Ajusta grupo de perguntas para impressão do Danfe / 
@type function
@version 
@author William Farias
@since 28/08/2019
@return return_type, return_description
/*/
User Function SF2460I()
	Local	aAreaOld		:= GetArea()


	// Gravo log de geração de nota fiscal
	U_DCCFGM02("NF",,"Geração de nota fiscal "+SF2->F2_DOC,FunName())

	// Atualiza status do Pedido faturado - Monitor Pedidos
	If SC5->(DbSeek(xFilial("SC5")+SD2->D2_PEDIDO))
		RecLock("SC5",.F.)
		SC5->C5_SITDEC = "5"
		MsUnLock()
	EndIf

	//Atualiza o controle do conta corrente - FLEX
	DbSelectArea("ZCC")
	DbSetOrder(1)
	if DbSeek(SF2->F2_FILIAL+SD2->D2_PEDIDO)
		Do while ZCC->(!eof()) .AND. SF2->F2_FILIAL == ZCC->ZCC_FILIAL .AND. SD2->D2_PEDIDO == ZCC->ZCC_NUM
			RecLock('ZCC',.F.)
			ZCC->ZCC_DOC   := SF2->F2_DOC
			ZCC->ZCC_SERIE := SF2->F2_SERIE
			ZCC->ZCC_DATA  := SF2->F2_EMISSAO
			MsUnlock()
			dbSkip()
		Enddo
	EndIf


	//Atualiza o controle do conta corrente - FLEX
	//DbSelectArea("ZCC")
	//DbSetOrder(1)
	//if DbSeek(SF2->F2_FILIAL+SD2->D2_PEDIDO)
	//	RecLock('ZCC',.F.)
	//		ZCC->ZCC_DOC   := SF2->F2_DOC
	//		ZCC->ZCC_SERIE := SF2->F2_SERIE
	//		ZCC->ZCC_DATA  := SF2->F2_EMISSAO
	//	ZCC->(MsUnlock())
	//EndIf

	// 06/10/2020 - Atualizar flag no cadastro do Cliente para integração Máxima
	If !(SF2->F2_TIPO $ "D#B")
		DbSelectArea("SA1")
		DbSetOrder(1)
		If DbSeek(xFilial("SA1")+SF2->F2_CLIENTE+SF2->F2_LOJA)
			If GetNewPar("DC_INMAXOK",.F.)
				U_XFLAG("SA1")
			Endif 
		Endif
	Endif

	// Atualiza Grupo de perguntas
	U_GravaSX1("NFSIGW","01",SF2->F2_DOC)
	U_GravaSX1("NFSIGW","02",SF2->F2_DOC)
	U_GravaSX1("NFSIGW","03",SF2->F2_SERIE)
	U_GravaSX1("NFSIGW","04",2)
	U_GravaSX1("NFSIGW","05",2)
	U_GravaSX1("NFSIGW","06",2)
	U_GravaSX1("NFSIGW","07",SF2->F2_EMISSAO)
	U_GravaSX1("NFSIGW","08",SF2->F2_EMISSAO)

		// Tray
	If cEmpAnt $ "02" .And. FindFunction("U_TraySF24")
		U_TraySF24()  // Função compilada no Rdmake TPEnt.prw
	EndIf
	
	RestArea(aAreaOld)

Return
