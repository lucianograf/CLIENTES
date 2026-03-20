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
User Function FIDCAD()

    U_xFIDCADA('01')

Return

User Function xFIDCADA(cFilCli)

 Local nPtaCli := 0
 
 RPCSETTYPE(3)
 RPCSetEnv("01",'0108') //ALTERAR
 cFilReg := ''
 cTpFil  := cFilCli
 nTotal  := 1000
 nTotReg := 1
 nValTot := 0
 nPula   := '0'
 x       := 0 

 cUrl := 'https://api.fidelimax.com.br/api/Integracao/' //SUPERGETMV("MV_ZURLFID", .F., "") //https://api.fidelimax.com.br/api/Integracao/RetornaDadosCliente"
 cUrl += "ListarConsumidores"
 

  if cTpFil ==  '01'
        cFilReg := '0108'
		cToken := 'AuthToken: 2d7482d3-5fc4-4817-88c0-0278bde5d60b-445'
    elseif cTpFil ==  '02'  
        cFilReg := '0102'
		cToken := 'AuthToken: 0d03ac86-bb54-4bb8-9b8e-35a9c29991d5-446'
	elseif cTpFil ==  '03'
	    cFilReg:= '0103'
		cToken :='AuthToken: 002bbd28-4e46-48fd-a1b6-12147b7b8894-444'
  Endif

    nTimeOut := 120
    aHeadOut := {}
    cHeadRet := ""
    sPostRet := ""
   // aadd(aHeadOut,'User-Agent: Mozilla/4.0 (compatible; Protheus '+GetBuild()+')')
    aadd(aHeadOut,'Content-Type: application/json;charset=utf-8')
    aadd(aHeadOut,cToken)

  for x := 1 To nTotal
        
      cPostParms := '{"novos": "false", "skip":"'+nPula+'","take" : 50 }' 
      nPula      := CVALTOCHAR(VAL(nPula)+50)
      sPostRet:= HttpPost(cUrl,"",cPostParms,nTimeOut,aHeadOut,@cHeadRet)
      
    if !empty(sPostRet)
            xGRVPTO(sPostRet)
    else
        MsgAlert("HttpPost Failed.")
        varinfo("Header", cHeadRet)
    Endif

 Next x      

    if cTpFil == '01'
        U_xFIDCADA('02')
    elseif cTpFil == '02'
        U_xFIDCADA('03')   
    endif

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
//Memowrite("C:\temp\CONSUMIDORES-"+STRTRAN(TIME(),":","-")+".txt", Len(aDados))

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

User Function zLmpCEsp(cConteudo)
 
    //Retirando caracteres
    cConteudo := StrTran(cConteudo, "'", "")
    cConteudo := StrTran(cConteudo, "#", "")
    cConteudo := StrTran(cConteudo, "%", "")
    cConteudo := StrTran(cConteudo, "*", "")
    cConteudo := StrTran(cConteudo, "&", "E")
    cConteudo := StrTran(cConteudo, ">", "")
    cConteudo := StrTran(cConteudo, "<", "")
    cConteudo := StrTran(cConteudo, "!", "")
    cConteudo := StrTran(cConteudo, "@", "")
    cConteudo := StrTran(cConteudo, "$", "")
    cConteudo := StrTran(cConteudo, "(", "")
    cConteudo := StrTran(cConteudo, ")", "")
    cConteudo := StrTran(cConteudo, "_", "")
    cConteudo := StrTran(cConteudo, "=", "")
    cConteudo := StrTran(cConteudo, "+", "")
    cConteudo := StrTran(cConteudo, "{", "")
    cConteudo := StrTran(cConteudo, "}", "")
    cConteudo := StrTran(cConteudo, "[", "")
    cConteudo := StrTran(cConteudo, "]", "")
    cConteudo := StrTran(cConteudo, "/", "")
    cConteudo := StrTran(cConteudo, "?", "")
    cConteudo := StrTran(cConteudo, ".", "")
    cConteudo := StrTran(cConteudo, "\", "")
    cConteudo := StrTran(cConteudo, "|", "")
    cConteudo := StrTran(cConteudo, ":", "")
    cConteudo := StrTran(cConteudo, ";", "")
    cConteudo := StrTran(cConteudo, '"', '')
    cConteudo := StrTran(cConteudo, 'Â°', '')
    cConteudo := StrTran(cConteudo, '¨', '')
    cConteudo := StrTran(cConteudo, 'Âª', '')
     
     
    cConteudo := Alltrim(cConteudo)
       
Return cConteudo
