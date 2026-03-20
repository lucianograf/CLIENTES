#INCLUDE "TOTVS.CH"

User Function VTEX_FEED()
local oRestClient as object
local cUrl as char
local cPath as char
local aHeadOut as array
 
    cUrl := "https://decantervinhos.myvtex.com"
    cPath := "/api/orders/feed?maxlot=10"
    aHeadOut := {} 
    Aadd(aHeadOut, "X-VTEX-API-AppKey: vtexappkey-decantervinhos-JQBAGL")
    Aadd(aHeadOut, "X-VTEX-API-AppToken: KIKYMSITHSGOAKRLOYMUXCLKOUYDFPHFOBUOURPFHXHYTBJPVERJCHRIWAKRTFORLAZYPDQXJGNZUNRMKJIAYXDHKLSUGXLBJQNSCLZRNUAVTRNIIYHKXNSNWSODKWQM")
 
 
    oRestClient := FWRest():New(cUrl)
 
    oRestClient:SetPath(cPath)
    //1oRestClient:SetPostParams(Encode64(oFile:FullRead()))
 
    if oRestClient:Get(aHeadOut)
        showResult(oRestClient:GetResult())
    else
        showResult(oRestClient:GetLastError())
    endif
 
    FreeObj(oRestClient)
 
 
return

static function showResult(cValue)
if IsBlind()
    Conout(cValue)
else
    MsgInfo(cValue)
endif
return
