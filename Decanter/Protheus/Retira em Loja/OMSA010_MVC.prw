#Include "Protheus.ch" 
#Include "TopConn.ch"
#Include "FWMVCDEF.ch"

/*/{Protheus.doc} OMSA010
@author LWM INOVAÇÃO
@since 12/09/2023
@version 1.0 
@type function 
@obs Intragracao com a Vtex 
/*/
 
User Function OMSA010() 
    Local aParam     := PARAMIXB
    Local xRet       := .T.
    Local oObj       := ""
    Local cIdPonto   := ""
    Local cIdModel   := ""
    Local lIsGrid    := .F.
    Local nLinha     := 0
    Local nQtdLinhas := 0
    Local cMsg       := ""
    Local nOp

    If (aParam <> NIL)
        oObj := aParam[1]
        cIdPonto := aParam[2]
        cIdModel := aParam[3]
        lIsGrid := (Len(aParam) > 3)

        nOpc := oObj:GetOperation() // PEGA A OPERAÇÃO

        if (cIdPonto =="MODELCOMMITTTS")
            if DA0->DA0_ATIVO="1" .and. alltrim(str(nOpc)  )  $ '3,4'//inclusao , alteracao
            // Desativada a integração para só subir via Job diário na função DCVTXI09 
            endif
       endif
    EndIf
Return (xRet)
