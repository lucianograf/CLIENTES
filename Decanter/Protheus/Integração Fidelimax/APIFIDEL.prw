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
User Function APIFIDEL(cTipo,cPostParms,cFil,cNome,cDoc,lGrvZFD,cToken,cNota,cSerie,cPtoRes,cPtoCred)

 Local nPtaCli := 0
 RPCSETTYPE(3)
 RPCSetEnv("01",'0108') //ALTERAR
 cFilReg := ''
 cTpFil  := '01'
 nTotal  := 1

 cUrl := 'https://api.fidelimax.com.br/api/Integracao/' //SUPERGETMV("MV_ZURLFID", .F., "") //https://api.fidelimax.com.br/api/Integracao/RetornaDadosCliente"
   if cTipo == 'R'
      //cPostParms :=  cPostParms := '{"CPF":"'+cDoc+'","nome":"'+cNome+'","email": "' + cEmail '","telefone": "'+ telefone+ '"}'
      cUrl += "RetornaDadosCliente"
      
  elseif cTipo == 'T'
      cUrl += "ListarConsumidores"
      //cPostParms := '{"CPF":"'+cDoc+'"}'
  elseif cTipo == 'S'
      cUrl += "ResgataPremio"
      //cPostParms := '{"CPF":"'+cDoc+'"}'
  elseif cTipo == 'A'
      //cPostParms := '{"CPF":"'+cDoc+'","nome":"'+cNome+'","email": "' + cEmail '","telefone": "'+ telefone+ '"}'
      cUrl += "CadastrarConsumidor"
  elseif cTipo == 'E'
      cUrl += "ExtratoConsumidor"
      //cPostParms :=  cPostParms := '{"CPF":"'+cDoc+'"}'
  elseif cTipo == 'P'
        //cPostParms := '{"CPF":"'+cDoc+'","verificador":"'+cDoc+'","pontuacao_reais":"'+nPontos+'"}'
        cUrl += "PontuaConsumidor"
  Endif

  nTimeOut := 120
  aHeadOut := {}
  cHeadRet := ""
  sPostRet := ""
  aadd(aHeadOut,'User-Agent: Mozilla/4.0 (compatible; Protheus '+GetBuild()+')')
  aadd(aHeadOut,'Content-Type: application/json')
  aadd(aHeadOut,cToken)
     
  sPostRet:= HttpPost(cUrl,"",cPostParms,nTimeOut,aHeadOut,@cHeadRet)
  if !empty(sPostRet)
    varinfo("WebPage", sPostRet)
      if cTipo == 'R'
          U_zJSONVL(sPostRet,cFil)
      elseif  cTipo == 'T'
          U_GRVLSTCLI(sPostRet,cFil)
      elseif cTipo == 'E'
          U_GRVEXTRA(sPostRet,cFil)
      elseif cTipo == 'S' 
          U_GRVPONTOS(sPostRet, cDoc, cNome,cFil,cTipo,cNota,cSerie,cPtoRes,cPtoCred) 
      elseif cTipo == 'P' 
          U_GRVPONTOS(sPostRet, cDoc, cNome,cFil,cTipo,cNota,cSerie,cPtoRes,cPtoCred) 
      endif
  else
    MsgAlert("HttpPost Failed.")
    varinfo("Header", cHeadRet)
  Endif

Return


/*/{Protheus.doc} GRVPONTOS
@Description 
@author 	 
@since  	 29/07/2021
/*/
User Function GRVPONTOS(sRetPos, cCGC, cNome,cFil,cTipo,cNota,cSerie,cPtoRes,cPtoCred)

Local cJsonStr,oJSon
Local NX     := 0
Local aDados := {}
Local cLoja  := ''
Local lValid := .T.
Local cDoc   := ''
Local nSaldo  := 0
Local cResp   := 0
Local cMsgErro := ''
Local lMsgEmp  := .F.


oJSon := JSonObject():New()
cErr  := oJSon:fromJson(sRetPos)

If !empty(cErr)
  MsgStop(cErr,"JSON PARSE ERROR")
  Return
Endif
    
//cLoja := oJSon["Consumidores"][NX]["pontuacoes"][1]["loja"] // Tipo [C] Conteudo [Enoteca SP]
cCGC     := cCGC + (SPACE(TamSx3("ZFD_CGC")[1] - Len(cCGC)))
nSaldo   := oJSon["saldo"]       // := Tipo [N] Conteudo [100]
cResp    := oJSon["CodigoResposta"] 
cMsgErro := oJSon["MensagemErro"] 
lMsgEmp := .F.
	
    DbSelectArea("SF2")
    SF2->(DbGoTop())
    DbSetOrder(1)  
   if DbSeek(cFil+cNota+cSerie)
      RecLock("SF2",.F.)

        if Empty(SF2->F2_ZFDACUM) .and. VAL(cPtoCred) > 0
          SF2->F2_ZFDACUM := VAL(cPtoCred)
        elseif Empty(SF2->F2_ZFDRESG) .and. VAL(cPtoRes) > 0
          SF2->F2_ZFDRESG := VAL(cPtoRes) 
        endif
       
        if  Empty(SF2->F2_ZFDOBS) 
            if Empty(cMsgErro)
                SF2->F2_ZFDOBS  := "Cód: " + CVALTOCHAR(cResp)
            else
                SF2->F2_ZFDOBS  := "Cód: " + CVALTOCHAR(cResp) + " - " + cMsgErro
            endif
        else
            if Empty(cMsgErro)
                SF2->F2_ZFDOBS  += " Cód: " + CVALTOCHAR(cResp)
            else
                SF2->F2_ZFDOBS  := " Cód: " + CVALTOCHAR(cResp) + " - " + cMsgErro
            endif
        endif
         
      SF2->(MsUnlock())
    endif

if  cResp == 100 
   
    DbSelectArea("ZFD")
    DbSetOrder(1)
    if !DbSeek(xFilial("ZFD")+cCGC)

      Reclock("ZFD",.T.)
      
        ZFD_FILIAL := ''
        ZFD_DATA   := DDATABASE 
        ZFD_CGC    := cCGC // Tipo [C] Conteudo [04320099907] 
        ZFD_NOME   := NoAcento(UPPER(cNome)) // Tipo [C] Conteudo [Camila Renaux]
        ZFD_SALDO  := nSaldo

      ZFD->(MsUnlock())
   
    else

        Reclock("ZFD",.F.)
      
        ZFD_FILIAL := ''
        ZFD_DATA   := DDATABASE 
        ZFD_CGC    := cCGC // Tipo [C] Conteudo [04320099907] 
        ZFD_NOME   := NoAcento(UPPER(cNome)) // Tipo [C] Conteudo [Camila Renaux]
        ZFD_SALDO  := nSaldo

      ZFD->(MsUnlock())
    Endif
Endif

FreeObj(oJSon)

Return cResp

/*/{Protheus.doc} GRVLSTCLI
@Description 
@author 	 
@since  	 29/07/2021
/*/
User Function GRVLSTCLI(sRetPos,cFil)

Local cJsonStr,oJSon
Local NX     := 0
Local aDados := {}
Local cLoja  := ''
Local lValid := .T.
Local cDoc   := ''
Local cFil   := ''

oJSon := JSonObject():New()
cErr  := oJSon:fromJson(sRetPos)

If !empty(cErr)
  MsgStop(cErr,"JSON PARSE ERROR")
  Return
Endif

aDados := oJSon["Consumidores"]

For NX := 1 To Len(aDados)

    cLoja := oJSon["Consumidores"][NX]["pontuacoes"][1]["loja"] // Tipo [C] Conteudo [Enoteca SP]
    cDoc  := oJSon["Consumidores"][NX]["documento"] + (SPACE(TamSx3("ZFD_CGC")[1] - Len(oJSon["Consumidores"][NX]["documento"])))

    DbSelectArea("ZFD")
    DbSetOrder(1)
    if !DbSeek(''+cDoc)

      Reclock("ZFD",.T.)
      
        ZFD_FILIAL := ''
        ZFD_DATA   := DDATABASE 
        ZFD_CGC    := oJSon["Consumidores"][NX]["documento"] // Tipo [C] Conteudo [04320099907] 
        ZFD_NOME   := UPPER(oJSon["Consumidores"][NX]["nome"]) // Tipo [C] Conteudo [Camila Renaux]
        ZFD_SALDO  := oJSon["Consumidores"][NX]["pontuacoes"][1]["saldo"] // Tipo [N] Conteudo [100]

      ZFD->(MsUnlock())

    endif

Next NX

FreeObj(oJSon)

Return 
