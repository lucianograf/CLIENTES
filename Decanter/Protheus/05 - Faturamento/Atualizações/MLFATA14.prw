#include 'protheus.ch'

/*/{Protheus.doc} MLFATA14
// Rotina para consulta de Log de Pedidos 
@author Marcelo Alberto Lauschner 
@since 21/04/2022
@version 1.0
@return Nil
@type User Function
/*/
User function MLFATA14()


	Local cVldAlt := ".F." // Validacao para permitir a alteracao. Pode-se utilizar ExecBlock.
	Local cVldExc := ".F." // Validacao para permitir a exclusao. Pode-se utilizar ExecBlock.

	dbSelectArea("Z00")
	dbSetOrder(1)

	AxCadastro("Z00","Historico e Logs de Pedido",cVldAlt,cVldExc)

Return



/*/{Protheus.doc} stVerLog
(long_description)
@author MarceloLauschner
@since 15/04/2014
@version 1.0
@param cInPedido, character, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function MLFAT14A()

	Local		oPed2
	Local		lOk			:= .F.
	Local 		aAreaOld	:= GetArea()
	Private		cZ0Filial	:= xFilial("Z00")

	Private cPedSZ0		:= SC5->C5_NUM

	DEFINE MSDIALOG oPed2 FROM 000,000 TO 0120,400 Of oMainWnd Pixel Title OemToAnsi("Consulta Log pedidos" )
	@ 035,005 Say "Número Pedido" of oPed2 Pixel
	@ 035,050 MsGet cPedSZ0	Size 40,10 Valid ExistCpo("SC5",cPedSZ0)  of oPed2 Pixel

	Activate MsDialog oPed2 On Init EnchoiceBar(oPed2,{|| lOk := .T., oPed2:End() },{|| oPed2:End()},,)

	If lOk
		dbSelectArea("Z00")
		dbSetOrder(1)
		Set Filter To (Z00->Z00_FILIAL == cZ0Filial .And. Z00->Z00_PEDIDO == cPedSZ0)

		AxCadastro("Z00","Historico Pedido - Workflow",".F.",".F.")

		dbSelectArea("Z00")
		dbSetOrder(1)
		Set Filter To
	Endif

	RestArea(aAreaOld)

Return
