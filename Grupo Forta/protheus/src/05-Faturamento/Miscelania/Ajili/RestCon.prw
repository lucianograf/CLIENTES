#include "totvs.ch"
#include "tbiconn.ch"

*****************************
user function RestCon(aParam)
*****************************

default aparam := {"01","01"} // caso nao receba nenhum parametro

Private __LFRTCOUNTLICENSE := .F.

	RpcSetType(3)
	RpcSetEnv(aparam[1],aparam[2],,,'FAT')


	dDtAtu 	:= Date()
	lRet 	:= LockByName("RESTCON",.T.,.F.,.T.)
   
	If lRet
	   
		Conout("***[Inicio RESTCON "+time()+"]************************************************************************")

        RodaCon()		

		Conout("***[Fim RESTCON "+time()+"]****************************************************************************")
  	
	Else
		Conout("*****[Job RESTCON ja esta em execucao]***********************************************")  			
	Endif
	
	RpcClearEnv()
		
Return

*************************
Static Function RodaCon()
*************************

Local cURL		         := SuperGetMv("CD_RESTCLI", .F., "http://condor1.ajili.com.br")
//local oRestClient := FWRest():New(cURL)
local aHeader            := {}
local aHeadOut           := {}
local cHeaderGet         := ""
local cAcesso            := "/api/contacts?api_key=$2a$10$ExnTdKv5KLjbZYi8TUe4wOvVL/j.4Ef7FQqOIj7JwU1wTHOkn/hUi"
Local xRet

Local nTimeOut 			 := 120
Local cMsg	 			 := ""
Local cJsonCon			 := ""
Local nTypeStamp		 := 4					//	estampa de tempo em milissegundos desde 01/01/1970 00:00:00

Local cActive            := ""       // "active": true,
Local cAniver            := ""       //  "birthday": "2019-09-04T22:21:26.764Z",
Local cCliente           := "0"      //"customerId": 0,
Local cEmail             := ""       //  "email": "string",
Local cId                := "0"      //"id": 0,
Local cIdErp             := ""       //  "idErp": "string",
Local cNome              := ""       //  "name": "string",
Local cNotes             := ""                //  "notes": "string",
Local cTelefone          := ""                //  "phone": "string",
Local cTitulo            := ""      //  "title": "string"
Local nSA1IdAjili        := 0
Local nSU5IdAjili        := 0

aadd(aHeader,'Content-Type: application/json')
Aadd(aHeader, "Accept: application/json")

_xFil := xFilial("SuU5")

dbSelectArea("SU5")
dbSetOrder(1)
dbSeek(_xFil,.F.)

While !Eof() .And. SU5->U5_FILIAL == _xFil 
   
   dbSelectARea("SA1")
   dbSetOrder(1)
   If dbSeek(xFilial("SA1")+SU5->U5_CLIENTE+SU5->U5_LOJA,.F.)
      nSA1IdAjili := SA1->A1_IDAJILI
   EndIf

   Conout("***[RESTCON]*[Id Ajili: "+Str(nSA1IdAjili,11,0)+"]********************************************************************************")

   If nSA1IdAjili == 0
      dbSelectArea("SU5")
      dbSkip()
      Loop
   EndIf

   JsonCon := MontaJson()

   cRetorno := HttpPost( cURL+cAcesso,"",encodeUTF8(JsonCon),200,aHeader,@cHeaderGet)

   Conout("***[RESTCON]***********************************************************************************************")

   Conout(cRetorno)

    wrk := JsonObject():new()
    wrk:fromJson(cRetorno)
 
   cRet := wrk:GetJsonText("id")
   
   ConOut("***[RESTCON]*["+cRet+"]***********************************************************************************************************")   
   
   nSU5IdAjili := Val(cRet)

   Conout("***[RESTCON]*[Id Ajili: "+Str(nSU5IdAjili,11,0)+"]**********************************************************************************************")
   
   Conout(cHeaderGet)

   _cStatus := Substr(cHeaderGet,10,3)
   
   Conout("Status da Inclusao: "+_cStatus)
   
   Conout("***[RESTCON]**********************************************************************************************")
   
   If _cStatus=="200"
      Conout("***[RESTCON]*[Cadastrado com Sucesso!]*****************************************************************")
      If RecLock("SU5",.F.)
         SU5->U5_XINTEGR := "X"
         SU5->U5_IDAJILI := nSU5IdAjili
         MsUnLock("SU5")
      EndIf
   EndIf    
   Conout("***[RESTCON]**********************************************************************************************")
   
   dbSelectArea("SU5")
   dbSkip()
   
End

return nil

***************************
Static Function MontaJson()
***************************
Local cURL		         := SuperGetMv("CD_RESTCLI", .F., "http://condor1.ajili.com.br")
local aHeader            := {}
local aHeadOut           := {}
local cHeaderGet         := ""
local cAcesso            := "/api/contacts?api_key=$2a$10$ExnTdKv5KLjbZYi8TUe4wOvVL/j.4Ef7FQqOIj7JwU1wTHOkn/hUi"
Local xRet

Local nTimeOut 			 := 120
Local cMsg	 			 := ""
Local cJsonCon			 := ""
Local nTypeStamp		 := 4					//	estampa de tempo em milissegundos desde 01/01/1970 00:00:00
Local cTimeStAtual 		 := FWTimeStamp(nTypeStamp,Date(),Time()) 
Local cDataAniver        := Substr(DtoS(SU5->U5_NIVER),1,4)+"-"+Substr(DtoS(SU5->U5_NIVER),5,2)+"-"+Substr(DtoS(SU5->U5_NIVER),7,2)+" 00:00"          
Local cActive            := "true"             // "active": true,
Local cAniver            := IIF(Empty(SU5->U5_NIVER),"",cDataAniver)     //  "birthday": "2019-09-04T22:21:26.764Z",
Local cCliente           := ""                 //"customerId": 0,
Local cEmail             := SU5->U5_EMAIL      //  "email": "string",
Local cId                := 0                //"id": 0,
Local cIdErp             := SU5->U5_CODCONT+xFilial("SU5")    //  "idErp": "string",
Local cNome              := SU5->U5_CONTAT     //  "name": "string",
Local cNotes             := SU5->U5_OBS        //  "notes": "string",
Local cTelefone          := POSICIONE("AGB",1,XFILIAL("AGB")+"SU5"+SU5->U5_CODCONT,"AGB_TELEFO")     //  "phone": "string",
Local cTitulo            := POSICIONE("SX5",1,"T6"+SU5->U5_NIVEL,"X5_DESCRI") //  "title": "string"
Local nSA1IdAjili        := 0
Local nSU5IdAjili        := 0 
Conout("***[RESTCON]*[Entrou na Rotina de Monta Json]*******************************************************************")

dbSelectARea("SA1")
dbSetOrder(1)
If dbSeek(xFilial("SA1")+SU5->U5_CLIENTE+SU5->U5_LOJA,.F.)
   nSA1IdAjili := SA1->A1_IDAJILI
EndIf

JsonCon := '{'
JsonCon += '"active": '+cActive+','
JsonCon += '"birthday": "'+cAniver+'",'
JsonCon += '"customerId": '+Str(nSA1IdAjili,11,0)+','
JsonCon += '"email": "'+cEmail+'",'
If !Empty(SU5->U5_IDAJILI)
   JsonCon += '"id": '+Str(SU5->U5_IDAJILI,11,0)+','
EndIf
JsonCon += '"idErp": "'+cIdErp+'",'
JsonCon += '"name": "'+cNome+'",'
JsonCon += '"notes": "'+cNotes+'",'
JsonCon += '"phone": "'+cTelefone+'",'
JsonCon += '"title": "'+cTitulo+'"'
JsonCon += '}'

Conout("***[RESTCON]*[Montou o Json do Contato]***********************************************************************")

Return JsonCon

//-----------------------------------------------
