#include"Protheus.ch"

/*/{Protheus.doc} MS520DEL
Ponto de entrada no Cancelamento de Nota Fiscal
@type function
@version  
@author Marcelo Alberto Lauschner
@since 14/10/2021
@return variant, return_description
/*/

static _aPVExcl := {}

User Function MS520DEL()

    Local aArea := GetArea()
    Local _xi   := 0
	Local 	lGrvMsg		:= SC5->(FieldPos("C5_ZMSGINT")) > 0 // Garante que o campo existe
	Local 	cMsgInt		:= ""

	DbSelectArea("SC5")
	DbSetOrder(1)
	If SC5->(DbSeek(xFilial("SC5")+SD2->D2_PEDIDO))
		RecLock("SC5",.F.)
		SC5->C5_SITDEC = " "
		If lGrvMsg
			cMsgInt	:= "Cancelamento de nota Fiscal " + SD2->D2_DOC +;
				" emitida em "+ DTOC(SD2->D2_EMISSAO) + " realizado por " +;
				UsrFullName(RetCodUsr()) + " no dia " + DTOC(Date()) + " às " + Time() + "hs - "
			cMsgInt += SC5->C5_ZMSGINT
			SC5->C5_ZMSGINT	:= cMsgInt
		Endif
		MsUnLock()
	EndIf


	//Estorna registro do controle de conta corrente / flex.

	DbSelectArea("ZCC")
	DbSetOrder(1)
	if ZCC->(DbSeek(xFilial("ZCC")+SD2->D2_PEDIDO))
		Do while ZCC->(!eof()) .AND. SD2->D2_FILIAL == ZCC->ZCC_FILIAL .AND. SD2->D2_PEDIDO == ZCC->ZCC_NUM
			RecLock('ZCC',.F.)
			ZCC->ZCC_DOC   := "CANCELADA"
			ZCC->ZCC_SERIE := ""
			MsUnlock()
			dbSkip()
		Enddo
	EndIf


    /*
    Integração com CRM Simples
    */
    IF cEmpAnt == "02" .and. cFilAnt == "0204"
        // Integração com CRM
        FwMsgRun(NIL, {|| u_PTCRM905(5,SF2->F2_DOC)}, "Aguarde", "Processando integração com CRM")

        SC5->(DbSetOrder(1))
        For _xi := 1 to Len(_aPVExcl)
            IF SC5->(MsSeek(xFilial("SC5") + _aPVExcl[_xi] ))
                u_PTCRM904(4)
            Endif
        Next

        _aPVExcl := {}
    Endif
    /*
    FIM Integração com CRM Simples
    */

RestArea(aArea)
Return



/*/{Protheus.doc} MSD2520
Esse ponto de entrada está localizado na função A520Dele(). É chamado antes da exclusão do registro no SD2.
@type function
@author Vamilly - Gilvan Prioto
@since 31/03/2021
@return logical, Prossegue ou não com a exclusão.
@obs Analisado e este PE fica dentro da transação.
@see https://tdn.totvs.com/display/public/PROT/MSD2520

PE transportado para o mesmo fonte do MS520DEL para poder usar a mesma variavel _aPVExcl

/*/
user function MSD2520()
Local lRet := .T.
	
	// Tray
	If cEmpAnt $ "02" .And. FindFunction("U_TrayMSD2")	
		U_TrayMSD2()  // Função compilada no Rdmake TPEnt.prw
	EndIf

	/*
    Integração com CRM Simples
    */
    IF cEmpAnt == "02" .and. cFilAnt == "0204"
        IF aScan(_aPVExcl,SD2->D2_PEDIDO) == 0
            aADD(_aPVExcl,SD2->D2_PEDIDO)
        Endif
    Endif
	/*
    FIM Integração com CRM Simples
    */
	
Return lRet
