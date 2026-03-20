#include 'totvs.ch'
/*/{Protheus.doc} SF1140I
//Ponto de entrada após lançamento da Pré-nota
@author Marcelo Alberto Lauschner
@since 17/07/2017
@version 6
@type function
/*/
User Function SF1140I()

	Local	oDlgPlaca
	Local	oPlaca
	Local 	oVeiculo1,oVeiculo2,oVeiculo3 
	Local	lOk			:= .F.
	Local 	nPLiqui		:= SF1->F1_PLIQUI
	Local 	nPBruto		:= SF1->F1_PBRUTO 
	Private	cPlaca		:= IIf(Type("cF1Placa") == "C",cF1Placa,Space(TamSX3("F1_PLACA")[1])) // Variável cF1Placa é criada na Central XML
	Private cVeiculo1 	:= cVeiculo2	:= cVeiculo3 	:= Space(TamSX3("F1_VEICUL1")[1])
	
	
	cVeiculo	:= Posicione("DA3",3,xFilial("DA3")+cPlaca,"DA3_COD")

	DEFINE MSDIALOG oDlgPlaca FROM 000,000 TO 310,480 Title OemToAnsi(ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Informe a Placa do veículo!") Of oMainWnd Pixel
	oDlgPlaca:lMaximized	:= .F.

	oPanelPlaca := TPanel():New(0,0,'',oDlgPlaca, oDlgPlaca:oFont, .T., .T.,, ,200,90,.T.,.T. )
	oPanelPlaca:Align := CONTROL_ALIGN_ALLCLIENT

	@ 012,005 Say "Placa: " of oPanelPlaca Pixel
	@ 010,050 MsGet oPlaca Var cPlaca F3 "DA3" Picture "@!" Size 40,10 Valid(Vazio() .Or. ExistCpo("DA3",cPlaca,3)) of oPanelPlaca Pixel

	@ 026,005 Say "Veículo 1: " of oPanelPlaca Pixel
	@ 024,050 MsGet oVeiculo1 Var cVeiculo1 F3 "DA3" Picture "@!" Size 40,10 Valid(Vazio() .Or. ExistCpo("DA3",cVeiculo1,1)) of oPanelPlaca Pixel

	@ 040,005 Say "Veículo 2: " of oPanelPlaca Pixel
	@ 038,050 MsGet oVeiculo2 Var cVeiculo2 F3 "DA3" Picture "@!" Size 40,10 Valid(Vazio() .Or. ExistCpo("DA3",cVeiculo2,1)) of oPanelPlaca Pixel

	@ 054,005 Say "Veículo 3 : " of oPanelPlaca Pixel
	@ 052,050 MsGet oVeiculo3 Var cVeiculo3 F3 "DA3" Picture "@!" Size 40,10 Valid(Vazio() .Or. ExistCpo("DA3",cVeiculo3,1)) of oPanelPlaca Pixel

	@ 068,005 Say "Peso Bruto: " of oPanelPlaca Pixel
	@ 066,050 MsGet oPesoBruto Var nPBruto Picture PesqPict("SF1","F1_PBRUTO") Size 60,10 of oPanelPlaca Pixel

	@ 082,005 Say "Peso Liquido : " of oPanelPlaca Pixel
	@ 080,050 MsGet oPesoLiquido Var nPLiqui Picture PesqPict("SF1","F1_PLIQUI")  Size 60,10  of oPanelPlaca Pixel

	Activate MsDialog oDlgPlaca On Init EnchoiceBar(oDlgPlaca,{|| lOk := .T., oDlgPlaca:End() },{|| oDlgPlaca:End()},,)

	If lOk
		DbSelectArea("SF1")
		RecLock("SF1",.F.)
		SF1->F1_PLACA	:= cPlaca
		SF1->F1_VEICUL1	:= cVeiculo1
		SF1->F1_VEICUL2	:= cVeiculo2
		SF1->F1_VEICUL3	:= cVeiculo3
		SF1->F1_PLIQUI	:= nPLiqui
		SF1->F1_PBRUTO	:= nPBruto
		MsUnlock()
	Endif

Return
