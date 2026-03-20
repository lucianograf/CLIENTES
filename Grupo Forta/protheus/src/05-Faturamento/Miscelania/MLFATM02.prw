#include "rwmake.ch"
#INCLUDE "topconn.ch"

User function MLFATM02()

return U_DIS093()

/*/{Protheus.doc} DIS093
//TODO Alterar Vendedor da NF, Pedido, Duplicata e Comissão 
@author Rafael Meyer  
@since 08/03/05  
@version 1.0
@return ${return}, ${return_description}
@type function
/*/
User Function DIS093()

	

	Private cString
	Private oLeTxt
	Private cString := "SC5"
	Private oNrPedido

	cNum  		:= Space(6)
	cRepr 		:= Space(6)
	crepr2 		:= Space(6)
	cReprant 	:= Space(6)

	@ 200,1 TO 380,395 DIALOG oLeTxt TITLE OemToAnsi("Informações do Pedido")
	@ 02,10 TO 070,190
	@ 10,018 Say "Número do Pedido:"
	@ 10,070 Get cNum Object oNrPedido
	@ 30,018 Say "Novo Vend. 1:"
	@ 30,070 Get cRepr
	@ 50,018 Say "Novo Vend. 2:"
	@ 50,070 Get cRepr2


	@ 72,133 BMPBUTTON TYPE 01 ACTION OkLeTxt()
	@ 72,163 BMPBUTTON TYPE 02 ACTION Close(oLeTxt)

	Activate Dialog oLeTxt Centered

Return

Static Function OkLeTxt()

	Close(oLeTxt)

	DbSelectArea("SC5")
	DbSetOrder(1)
	If !dbSeek(xFilial("SC5")+cNum)
		MsgAlert("O pedido nao e valido","Não há Dados!")
		Return
	Endif

	//msgAlert("Vend1"+SC5->C5_VEND1","Informacao","INFO")

	If MsgYesNo("De V1: "+SC5->C5_VEND1+" p/ v2 "+cRepr+" ? e V2: "+cRepr2,"Continua?")
		cReprant := SC5->C5_VEND1
		Reclock("SC5",.F.)
		Replace C5_VEND1 with cRepr
		Replace C5_VEND2 with cRepr2
		DbUnLock()
		MSUnLock()
		MsgInfo("Pedido " + SC5->C5_NUM + "Alterado!!","Alteração de Pedido")
	Else
		MsgAlert("Troca Abortada!!","Abandono")
		Return
	Endif

	cQra := ""
	cQra += "SELECT C9_SERIENF, C9_NFISCAL "
	cQra += "  FROM "+ RetSqlName("SC9") 
	cQra += " WHERE C9_FILIAL = '" + xFilial("SC9") + "' "
	cQra += "   AND C9_PEDIDO = '"+ cNum +"' "
	cQra += "   AND D_E_L_E_T_ = ' ' "
	cQra += " GROUP BY C9_SERIENF, C9_NFISCAL"

	TCQUERY cQra NEW ALIAS "SEL"

	While !Eof()
		DbSelectArea("SF2")
		DbSetOrder(1)
		If dbSeek(xFilial("SF2")+SEL->C9_NFISCAL+SEL->C9_SERIENF)
			Reclock("SF2",.F.)
			Replace F2_VEND1 with cRepr
			Replace F2_VEND2 with cRepr2
			DbUnLock()
			MSUnLock()
			MsgInfo("Nota Fiscal " + SEL->C9_NFISCAL + "Alterada!!","Alteração de Nota.")
		Else
			MsgAlert("A NF não é válida! Comunique o TI","Erro de nota fiscal")
		Endif

		DbSelectArea("SE1")
		DbSetOrder(1)
		If !dbSeek(xFilial("SE1")+SEL->C9_SERIENF+SEL->C9_NFISCAL)
			msgAlert("A Dupl nao e valida","Informacao","INFO")
		Endif
		While !Eof().and. xfilial("SE1")  == SE1->E1_FILIAL;
		.AND. SE1->E1_PREFIXO == SEL->C9_SERIENF;
		.AND. SE1->E1_NUM     == SEL->C9_NFISCAL
			Reclock("SE1",.F.)
			Replace E1_VEND1 with cRepr
			Replace E1_VEND2 with cRepr2
			DbUnLock()
			MSUnLock()
			
			MsgInfo("Duplicata " + SE1->E1_NUM+"-"+SE1->E1_PARCELA + "Alterada!!","Alteração de Título.")
			
			DbSelectArea ("SE1")
			DbSkip()     // salta para proxima nota
		EndDo

		DbSelectArea("SE3")
		DbSetOrder(1)
		If !dbSeek(xFilial("SE3")+SEL->C9_SERIENF+SEL->C9_NFISCAL)
			SEL->(DbCloseArea())
			Return
		Endif
		While !Eof().and. xfilial("SE3")  == SE3->E3_FILIAL;
		.AND. SE3->E3_PREFIXO == SEL->C9_SERIENF;
		.AND. SE3->E3_NUM     == SEL->C9_NFISCAL
			If !Empty(SE3->E3_DATA)
				MsgAlert("A comissão já foi paga para o representante"+ cReprant + " Informe Financeiro","Informacao","INFO")
				DbSelectArea ("SE3")
				DbSkip()     // salta para proxima nota
				Loop
			Endif

			Reclock("SE3",.F.)
			Replace E3_VEND with cRepr
			Replace E3_VEND2 with cRepr2
			DbUnLock()
			MSUnLock()
			
			MsgInfo("Comissão " + SE3->E3_NUM + "Alterada!!","Alteração de Comissão.")
			
			DbSelectArea ("SE3")
			DbSkip()     // salta para proxima nota
		EndDo
		dbSelectArea("SEL")
		dbSkip()
	End
	SEL->(DbCloseArea())


Return
