#INCLUDE "TOPCONN.CH"
#Include "Protheus.ch"
#Include "TBIConn.ch" 
#Include "Colors.ch"
#Include "RPTDef.ch"
#Include "FWPrintSetup.ch"

USER FUNCTION IBGE()

LOCAL CRETORNO := ""

DO CASE

	CASE TMP->CC2_EST == "AC"
		CRETORNO := "12"		
	CASE TMP->CC2_EST == "AL"
		CRETORNO := "27"
	CASE TMP->CC2_EST == "AM"
		CRETORNO := "13"
	CASE TMP->CC2_EST == "AP"
		CRETORNO := "16"
	CASE TMP->CC2_EST == "BA"
		CRETORNO := "29"
	CASE TMP->CC2_EST == "CE"
		CRETORNO := "23"
	CASE TMP->CC2_EST == "DF"
		CRETORNO := "53"
	CASE TMP->CC2_EST == "ES"
		CRETORNO := "32"
	CASE TMP->CC2_EST == "GO"
		CRETORNO := "52"
	CASE TMP->CC2_EST == "MA"
		CRETORNO := "21"
	CASE TMP->CC2_EST == "MG"
		CRETORNO := "31"
	CASE TMP->CC2_EST == "MS"
		CRETORNO := "50"
	CASE TMP->CC2_EST == "MT"
		CRETORNO := "51"
	CASE TMP->CC2_EST == "PA"
		CRETORNO := "15"
	CASE TMP->CC2_EST == "PB"
		CRETORNO := "25"
	CASE TMP->CC2_EST == "PE"
		CRETORNO := "26"
	CASE TMP->CC2_EST == "PI"
		CRETORNO := "22"
	CASE TMP->CC2_EST == "PR"
		CRETORNO := "41"
	CASE TMP->CC2_EST == "RJ"
		CRETORNO := "33"
	CASE TMP->CC2_EST == "RN"
		CRETORNO := "24"
	CASE TMP->CC2_EST == "RO"
		CRETORNO := "11"
	CASE TMP->CC2_EST == "RR"
		CRETORNO := "14"
	CASE TMP->CC2_EST == "RS"
		CRETORNO := "43"
	CASE TMP->CC2_EST == "SC"
		CRETORNO := "42"
	CASE TMP->CC2_EST == "SE"
		CRETORNO := "28"
	CASE TMP->CC2_EST == "SP"
		CRETORNO := "35"
	CASE TMP->CC2_EST == "TO"
		CRETORNO := "17"
ENDCASE
	
RETURN(CRETORNO)


USER FUNCTION IBGE2()

	LOCAL CRETORNO := ""

	IF EMPTY(TMP->A1_ESTE)
		CMUN := TMP->A1_ESTE
	ELSE
		CMUN := TMP->A1_EST
	ENDIF

	DO CASE
	
		CASE CMUN == "AC"
			CRETORNO := "12"		
		CASE CMUN == "AL"
			CRETORNO := "27"
		CASE CMUN == "AM"
			CRETORNO := "13"
		CASE CMUN == "AP"
			CRETORNO := "16"
		CASE CMUN == "BA"
			CRETORNO := "29"
		CASE CMUN == "CE"
			CRETORNO := "23"
		CASE CMUN == "DF"
			CRETORNO := "53"
		CASE CMUN == "ES"
			CRETORNO := "32"
		CASE CMUN == "GO"
			CRETORNO := "52"
		CASE CMUN == "MA"
			CRETORNO := "21"
		CASE CMUN == "MG"
			CRETORNO := "31"
		CASE CMUN == "MS"
			CRETORNO := "50"
		CASE CMUN == "MT"
			CRETORNO := "51"
		CASE CMUN == "PA"
			CRETORNO := "15"
		CASE CMUN == "PB"
			CRETORNO := "25"
		CASE CMUN == "PE"
			CRETORNO := "26"
		CASE CMUN == "PI"
			CRETORNO := "22"
		CASE CMUN == "PR"
			CRETORNO := "41"
		CASE CMUN == "RJ"
			CRETORNO := "33"
		CASE CMUN == "RN"
			CRETORNO := "24"
		CASE CMUN == "RO"
			CRETORNO := "11"
		CASE CMUN == "RR"
			CRETORNO := "14"
		CASE CMUN == "RS"
			CRETORNO := "43"
		CASE CMUN == "SC"
			CRETORNO := "42"
		CASE CMUN == "SE"
			CRETORNO := "28"
		CASE CMUN == "SP"
			CRETORNO := "35"
		CASE CMUN == "TO"
			CRETORNO := "17"
	ENDCASE
	
	IF EMPTY(TMP->A1_CODMUNE)
		CRETORNO += TMP->A1_COD_MUN
	ELSE
		CRETORNO += TMP->A1_CODMUNE
	ENDIF

RETURN(CRETORNO)

USER FUNCTION ROTA_CLI(XCLI,XLOJA)

	LOCAL CRETORNO := ""
	LOCAL CQUERY   := ""

	CQUERY += " SELECT DA8_COD FROM " + RETSQLNAME("DA8") + " DA8
	CQUERY += " INNER JOIN " + RETSQLNAME("DA9") + " DA9 ON DA9_FILIAL = DA8_FILIAL AND DA9_ROTA = DA8_COD AND DA9.D_E_L_E_T_ = ' '
	CQUERY += " INNER JOIN " + RETSQLNAME("DA7") + " DA7 ON DA7_FILIAL = DA9_FILIAL AND DA9_ROTEIR = DA7_ROTA  AND DA9_PERCUR = DA7_PERCUR AND DA7.D_E_L_E_T_ = ' '
	CQUERY += " INNER JOIN " + RETSQLNAME("SA1") + " SA1 ON A1_CEP BETWEEN DA7_CEPDE AND DA7_CEPATE AND A1_COD = '"+XCLI+"' AND A1_LOJA = '"+XLOJA+"' AND SA1.D_E_L_E_T_ = ' '
	CQUERY += " WHERE DA8.D_E_L_E_T_ = ' '
	CQUERY += " AND DA8_ATIVO = '1'
	
	CQUERY += " UNION ALL
	
	CQUERY += " SELECT DA8_COD FROM " + RETSQLNAME("DA8") + " DA8
	CQUERY += " INNER JOIN " + RETSQLNAME("DA9") + " DA9 ON DA9_FILIAL = DA8_FILIAL AND DA9_ROTA = DA8_COD AND DA9.D_E_L_E_T_ = ' '
	CQUERY += " INNER JOIN " + RETSQLNAME("DA7") + " DA7 ON DA7_FILIAL = DA9_FILIAL AND DA9_ROTEIR = DA7_ROTA  AND DA9_PERCUR = DA7_PERCUR AND DA7.D_E_L_E_T_ = ' '
	CQUERY += " INNER JOIN " + RETSQLNAME("SA1") + " SA1 ON A1_COD = DA7_CLIENT AND A1_LOJA = DA7_LOJA AND A1_COD = '"+XCLI+"' AND A1_LOJA = '"+XLOJA+"' AND SA1.D_E_L_E_T_ = ' '
	CQUERY += " WHERE DA8.D_E_L_E_T_ = ' '
	CQUERY += " AND DA8_ATIVO = '1'"

	IF SELECT("ROTAS") > 0
		ROTAS->(DBCLOSEAREA(  ))
	ENDIF

	TCQUERY CQUERY NEW ALIAS "ROTAS"

	IF !ROTAS->(EOF())
		CRETORNO := ROTAS->DA8_COD
	ENDIF

RETURN(CRETORNO)	

User Function EXP_XMLZ()
    Local aArea     := GetArea()
    Local cIdent    := ""
    Local cArquivo  := ""
    Local oDanfe    := Nil
    Local lEnd      := .F.
    Local nTamNota  := TamSX3('F2_DOC')[1]
	Local nTamSerie := TamSX3('F2_SERIE')[1]
	LOCAL XMLRET    := ""
    Private PixelX
    Private PixelY
    Private nConsNeg
    Private nConsTex
    Private oRetNF
    Private nColAux
     XCNOTA   := TMP->F2_DOC //aAmarra[oAmarra:nAt,3]//"000236916"
     XCSERIE  := TMP->F2_SERIE //aAmarra[oAmarra:nAt,2]"1"
     cPasta  := GetTempPath()
                     
    //Se existir nota
    If ! Empty(XCNOTA)
        //Pega o IDENT da empresa
        cIdent := RetIdEnti()
         
        //Se o último caracter da pasta não for barra, será barra para integridade
        If SubStr(cPasta, Len(cPasta), 1) != "\"
            cPasta += "\"
        EndIf
         
        //Gera o XML da Nota
        cArquivo := XCNOTA + "_" + dToS(Date()) + "_" + StrTran(Time(), ":", "-")
		XMLRET := u_zSpedXM(XCNOTA, XCSERIE, cPasta + cArquivo  + ".xml", .F.)

	ENDIF
RETURN(XMLRET)	

/*/{Protheus.doc} zSpedXML
Função que gera o arquivo xml da nota (normal ou cancelada) através do documento e da série disponibilizados
@author Atilio
@since 25/07/2017
@version 1.0
@param cDocumento, characters, Código do documento (F2_DOC)
@param XCSERIE, characters, Série do documento (F2_SERIE)
@param cArqXML, characters, Caminho do arquivo que será gerado (por exemplo, C:\TOTVS\arquivo.xml)
@param lMostra, logical, Se será mostrado mensagens com os dados (erros ou a mensagem com o xml na tela)
@type function
@example Segue exemplo abaixo
    u_zSpedXML("000000001", "1", "C:\TOTVS\arquivo1.xml", .F.) //Não mostra mensagem com o XML
     
    u_zSpedXML("000000001", "1", "C:\TOTVS\arquivo2.xml", .T.) //Mostra mensagem com o XML
/*/

User Function zSpedXM(cDocumento, XCSERIE, cArqXML, lMostra)
    Local aArea        := GetArea()
    Local cURLTss      := PadR(GetNewPar("MV_SPEDURL","http://"),250)  
    Local oWebServ
    Local cIdEnt       := RetIdEnti(.F.)
    Local cTextoXML    := ""
    Default cDocumento := ""
    Default XCSERIE     := ""
    Default cArqXML    := GetTempPath()+"arquivo_"+XCSERIE+cDocumento+".xml"
    Default lMostra    := .F.
     
    //Se tiver documento
    If !Empty(cDocumento)
        cDocumento := PadR(cDocumento, TamSX3('F2_DOC')[1])
        XCSERIE     := PadR(XCSERIE,     TamSX3('F2_SERIE')[1])
         
        //Instancia a conexão com o WebService do TSS    
        oWebServ:= WSNFeSBRA():New()
        oWebServ:cUSERTOKEN        := "TOTVS"
        oWebServ:cID_ENT           := cIdEnt
        oWebServ:oWSNFEID          := NFESBRA_NFES2():New()
        oWebServ:oWSNFEID:oWSNotas := NFESBRA_ARRAYOFNFESID2():New()
        aAdd(oWebServ:oWSNFEID:oWSNotas:oWSNFESID2,NFESBRA_NFESID2():New())
        aTail(oWebServ:oWSNFEID:oWSNotas:oWSNFESID2):cID := (XCSERIE+cDocumento)
        oWebServ:nDIASPARAEXCLUSAO := 0
        oWebServ:_URL              := AllTrim(cURLTss)+"/NFeSBRA.apw"   
         
        //Se tiver notas
        If oWebServ:RetornaNotas()
         
            //Se tiver dados
            If Len(oWebServ:oWsRetornaNotasResult:OWSNOTAS:oWSNFES3) > 0
             
                //Se tiver sido cancelada
                If oWebServ:oWsRetornaNotasResult:OWSNOTAS:oWSNFES3[1]:oWSNFECANCELADA != Nil
                    cTextoXML := oWebServ:oWsRetornaNotasResult:OWSNOTAS:oWSNFES3[1]:oWSNFECANCELADA:cXML
                     
                //Senão, pega o xml normal
                Else
                    cTextoXML := oWebServ:oWsRetornaNotasResult:OWSNOTAS:oWSNFES3[1]:oWSNFE:cXML
                EndIf
                 
                //Gera o arquivo
                //MemoWrite(cArqXML, cTextoXML)
                 
                //Se for para mostrar, será mostrado um aviso com o conteúdo
                If lMostra
                    Aviso("zSpedXML", cTextoXML, {"Ok"}, 3)
                EndIf
                 
            //Caso não encontre as notas, mostra mensagem
            Else
                ConOut("zSpedXML > Verificar parâmetros, documento e série não encontrados ("+cDocumento+"/"+XCSERIE+")...")
                 
                If lMostra
                    Aviso("zSpedXML", "Verificar parâmetros, documento e série não encontrados ("+cDocumento+"/"+XCSERIE+")...", {"Ok"}, 3)
                EndIf
            EndIf
         
        //Senão, houve erros na classe
        Else
            ConOut("zSpedXML > "+IIf(Empty(GetWscError(3)), GetWscError(1), GetWscError(3))+"...")
             
            If lMostra
                Aviso("zSpedXML", IIf(Empty(GetWscError(3)), GetWscError(1), GetWscError(3)), {"Ok"}, 3)
            EndIf
        EndIf
    EndIf
    RestArea(aArea)
Return(cTextoXML)

USER FUNCTION GERENT_MAX()




RETURN
