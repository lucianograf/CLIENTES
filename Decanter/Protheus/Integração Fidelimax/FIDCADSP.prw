#INCLUDE "TOTVS.CH"
#Include 'Protheus.ch'
#include "fileio.ch"

/*
Modelo utilizado para realizar a conversão do Json e padronizar.
** Json exemplo de retorno da API FIDELIMAX 
** EndPoin : https://api.fidelimax.com.br/api/Integracao/RetornaDadosCliente
{
    "nome": "Agda Regina Rodrigues de Paulo",
    "sexo": "Feminino",
    "documento": "29572144820",
    "data_nascimento": "1980-12-28T00:00:00",
    "email": "agdarodriguespaulo@gmail.com",
    "telefone": "11960221456",
    "data_cadastro": "2020-11-09T12:50:11.517",
    "data_ultima_compra": "2021-07-03T14:52:19.647",
    "CodigoResposta": 100,
    "MensagemErro": null
}

** Exemplo do Parser para referência de padronização.
oJSon["CodigoResposta"] // Tipo [N] Conteudo [100]
oJSon["data_cadastro"] // Tipo [C] Conteudo [2020-11-09T12:50:11.517]
oJSon["data_nascimento"] // Tipo [C] Conteudo [1980-12-28T00:00:00]
oJSon["data_ultima_compra"] // Tipo [C] Conteudo [2021-07-03T14:52:19.647]
oJSon["documento"] // Tipo [C] Conteudo [29572144820]
oJSon["email"] // Tipo [C] Conteudo [agdarodriguespaulo@gmail.com]
oJSon["nome"] // Tipo [C] Conteudo [Agda Regina Rodrigues de Paulo]
oJSon["sexo"] // Tipo [C] Conteudo [Feminino]
oJSon["telefone"] // Tipo [C] Conteudo [11960221456]

*/
User Function FIDCADSP()

    U_xFIDCADA('03')

Return

Static Function xGRVPTO(sRetPos)
    
Local cJsonStr,oJSon
Local NX     := 0
Local aDados := {}
Local nSaldo := 0
Local cNome  := ''
Local cLoja  := ''
Local lValid := .T.
Local cDoc    := ''
Local cFil    := ''
oJSon := JSonObject():New()
cErr  := oJSon:fromJson(sRetPos)

If !empty(cErr)
  MsgStop(cErr,"JSON PARSE ERROR")
  Return
Endif

aDados := oJSon["Consumidores"]

For NX := 1 To Len(aDados)
        if nTotReg > 1 .and. nTotReg > nValTot
            x := 10000
        endif  
        
        if cFil <> cTpFil
            cFil := cTpFil
            nValTot := oJson["total"] // Tipo [N] Conteudo [705]
        endif
       
        nTotReg += 1
        nSaldo  := oJSon["Consumidores"][NX]["pontuacoes"][1]["saldo"] // Tipo [C] Conteudo [Enoteca SP]
        cDoc    := oJSon["Consumidores"][NX]["documento"] + (SPACE(TamSx3("ZFD_CGC")[1] - Len(oJSon["Consumidores"][NX]["documento"])))     
        cNome   := oJSon["Consumidores"][NX]["nome"]       
       

    DbSelectArea("ZFD")
    DbSetOrder(1)
    if !DbSeek(xFilial("ZFD")+cDoc)

      Reclock("ZFD",.T.)
        ZFD_FILIAL  := ''
        ZFD_FILORIG := cFilReg
        ZFD_DATA   := DDATABASE 
        ZFD_CGC    := cDoc // Tipo [C] Conteudo [04320099907] 
        ZFD_NOME   := UPPER(NoAcento(cNome)) // Tipo [C] Conteudo [Camila Renaux]
        ZFD_SALDO  := nSaldo

      ZFD->(MsUnlock())
   
    else

        Reclock("ZFD",.F.)

        ZFD_DATA   := DDATABASE 
        ZFD_HREXP  := ""
        ZFD_MSEXP  := ""
        ZFD_SALDO  := oJSon["Consumidores"][NX]["pontuacoes"][1]["saldo"] // Tipo [N] Conteudo [100]
        ZFD->(MsUnlock())

    Endif

Next NX

    FreeObj(oJSon)

Return 
