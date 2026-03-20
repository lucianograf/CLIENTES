#include "Protheus.ch"
#include "FWMVCDEF.CH"

/*
Ponto de Entrada do Cadastro de Contatos
*/

User Function CRMA060() ///cXXX1,cXXX2,cXXX3,cXXX4,cXXX5,cXXX6
    Local aParam        := PARAMIXB
    Local xRet          := .T.
    Local lIsGrid       := .F.
    Local cIDPonto      := ''
    Local cIDModel      := ''
    Local oObj          := NIL
    Local cAlias        := ""
    Local cChave        := ""

    If aParam <> NIL
        oObj        := aParam[1]
        cIDPonto    := aParam[2]
        cIDModel    := aParam[3]
        lIsGrid     := (Len(aParam) > 3)
        nOperation := oObj:GetOperation()

        If cIDPonto == 'MODELCOMMITTTS'

            // Alteracao
            If nOperation == 4
                IF Left(aChave[1],2)=="A1"
                    cAlias := "SA1"
                    cChave := SA1->(A1_COD+A1_LOJA)
                elseif Left(aChave[1],2)=="US"
                    cAlias := "SUS"
                    cChave := SUS->(US_COD+US_LOJA)
                endif
                IF cEmpAnt == "02" .and. cFilAnt == "0204"
                    FwMsgRun(NIL, {|| U_PTCRM901(.F.,cAlias,cChave)}, "Aguarde", "Processando integração com CRM")
                Endif
            EndIf

        EndIf
    EndIf
Return xRet
