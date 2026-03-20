//Bibliotecas
#Include "Protheus.ch"
#Include "TopConn.ch"
#include 'parmtype.ch'
#include 'fwmvcdef.ch'

/*/{Protheus.doc} OMSA010
Exemplo de Ponto de Entrada em MVC - Tabela de Preço
@author zIsMVC
@since 21/06/2018
@version 1.0
@type function
@obs Deixar o nome do prw como: OMSA010_pe.prw
/*/

User Function OMSA010()
    Local aParam     := PARAMIXB
    Local xRet       := .T.
    Local oObj       := Nil
    Local cIdPonto   := ""
    Local cIdModel   := ""
    Local oModelPad  := Nil
    Local oModelGrid := Nil
    Local cProduto   := ""
    Local cTabela    := ""
    Local nValor     := 0
    Local lExcluido  := .F.
    Local nComissao  := 0
    Local nQuantid   := 0
    Local cQryZ12 := ""
    Local nErro
    Local cFunCall  := SubStr(ProcName(0),3)
    Local lPEICMAIS := ExistBlock( 'T'+ cFunCall ) .And. GetNewPar("BL_ICMAIOK",.F.)
    Local nX

    // Verifica se conseguiu receber valor do PARAMIXB
    If aParam <> NIL

        // Manter o trexo de código a seguir no final do fonte
        If lPEICMAIS
            xRet := ExecBlock( 'T'+ cFunCall, .F., .F., aParam )
        EndIf

        //Pega informações dos parâmetros
        oObj := aParam[1]
        cIdPonto := aParam[2]
        cIdModel := aParam[3]

        //Commit das operações (pos gravação)
        If cIdPonto == "FORMCOMMITTTSPOS"

            If FWCodEmp() == '10'
                oModelPad  := FWModelActive()
                oModelGrid := oModelPad:GetModel('DA1DETAIL')

                nPosPrcv    := aScan(oModelGrid:aHeader,{|x| AllTrim(x[2]) == "DA1_PRCVEN"})
                nPosPrd     := aScan(oModelGrid:aHeader,{|x| AllTrim(x[2]) == "DA1_CODPRO"})
                nPosHr      := aScan(oModelGrid:aHeader,{|x| AllTrim(x[2]) == "DA1_ZTIME"})
                nPosDta     := aScan(oModelGrid:aHeader,{|x| AllTrim(x[2]) == "DA1_ZDATAL"})

                oCols       := oModelGrid:aCols

                For nX:=1 To Len(oCols)

                    cProduto := oCols[nX][nPosPrd]

                    DbSelectArea('DA1')
                    DbSetOrder(1)
                    If DbSeek(xFilial('DA1')+DA0->DA0_CODTAB+cProduto)
                        lExcluido := oModelGrid:IsDeleted()

                        If oCols[nX][nPosPrcv] <> DA1->DA1_PRCVEN .OR. !lExcluido
                            RecLock('DA1', .F.)
                            DA1->DA1_ZTIME  := Time()
                            DA1->DA1_ZDATAL := dDataBase
                            DA1->(MsUnlock())
                        EndIf
                    Else
                        oCols[nX][nPosHr]   :=  Time()
                        oCols[nX][nPosDta]  :=  dDataBase
                    EndIf

                Next nX
                
            EndIf
        EndIf

    EndIf

Return xRet
