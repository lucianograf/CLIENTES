#Include "protheus.ch"

/*/

Função que receb e o aParam dos PES F200var e F650VAR
para localizar o numero do titulo anteriores a migração
do sistema, ou seja, numero de títulos utilizados no sistema antigo.


@author CHARLES REITZ
@since 28/01/2020

/*/
user  Function DECA087(cOrigPE,aParam)
    Local cWhere
    Local lF650VAR  := cOrigPE == "F650VAR"
    Local lF200VAR  := cOrigPE == "F200VAR"
    Local cBanco    := If(lF650VAR, mv_par03, mv_par06)
    Local cAgencia  :=  If(lF650VAR, mv_par04, mv_par07)
    Local cConta    := If(lF650VAR, mv_par05, mv_par08)
    Local cBCoChec  := "001/341/237/422/033"
    Local lModelo1  := If(lF650VAR,MV_PAR08 == 1,MV_PAR12 == 1) // Qual versão do cnab
    Local lF650VCR  := If(lF650VAR,MV_PAR07 == 1,.F.) // Quando for do relatório preciso saber se é do contas a receber
    //Local cNumTitu  := Alltrim(aParam[1,1]) // Quando enviado pelo protheus vai retornar o E1_IDCNAB
    Local cNossoNum := Alltrim(aParam[1,4]) // Nosso numero impresso no boleto
    Local cNumTiANt := ""
    Local lExecPE   := .F.
    Local nColIni	:= 0 //Define a coluna inicial onde se encontra o numero do titulo antigo
    
    //001 - BANCO DO BRASIL
    //341 - ITAU
    //237 - BRADESCO
    //422 - BANCO SAFRA
    //033 - SANTANDER

    // APARAM
    //FINR650 - F650VAR
    //aValores := ( { cNumTit, dBaixa, cTipo, cNossoNum, nDespes, nDescont, nAbatim, nValRec, nJuros, nMulta, 			 nValCc, dDataCred, cOcorr, 		 xBuffer })
    //FINA200 - F200VAR
    //aValores := ( { cNumTit, dBaixa, cTipo, cNossoNum, nDespes, nDescont, nAbatim, nValRec, nJuros, nMulta, nOutrDesp, nValCc, dDataCred, cOcorr, cMotBan, xBuffer,dDtVc,{} })

     //TSCB57 - William Farias: Tratado posicao da coluna inicial para o banco do brasil (001) e santander (033) que são diferentes dos demais. 
    If cBanco == '001'
    	nColIni := 39
    Else
    	nColIni := 38
    EndIf
	
	//TSCB57 - William Farias: Tratado posicao do "xBuffer" conforme o PE que chamou.
	If lF200VAR
		cNumTiANt := subStr(aParam[1,16],nColIni,25)
	Else
		cNumTiANt := subStr(aParam[1,14],nColIni,25)
	EndIf
    
    lExecPE   := len(Alltrim(cNumTiANt))>10 .AND. lModelo1 .AND. date() < stod("20201231") // Esse PE será executado ate essa data, após disso não terá mais esses títulos nos retornos dos bancos
    

    // Customização executada para localizar os titulos antigos, oriundos do sistema antigo
    If lExecPE  .AND. ((lF650VAR .AND. lF650VCR .AND.  cBanco$cBCoChec) .or. ( lF200VAR .AND.  cBanco$cBCoChec ))
        cWhere  := "% "
        //If Alltrim(cBanco) == '237'
        //    cWhere	+=  "AND LEFT(E1_NUMBCO,9) = '"+RIGHT(cNossoNum,9)+"' " // na decanter padronizamos 15 posições do nosso numero, para poder achar o titulo
        //Else
            cWhere	+=  "AND E1_NUMBCO = '"+PADL(cNossoNum,10,"0")+"' " // na decanter padronizamos 15 posições do nosso numero, para poder achar o titulo
        //EndIf
        cWhere	+= " AND E1_PORTADO = '"+alltrim(cBanco)+"'"
        cWhere	+= " AND E1_AGEDEP = '"+alltrim(cAgencia)+"'"
        cWhere	+= " AND E1_CONTA = '"+alltrim(cConta)+"'"

        cWhere  += " %"
        Beginsql alias "TRBZE1"
            SELECT E1_PREFIXO, E1_NUM, E1_PARCELA, E1_TIPO
            FROM %table:SE1% 
            WHERE D_E_L_E_T_= ''
            AND E1_FILIAL = %xFilial:SE1%
            %exp:cWhere%
        EndSql

        If  TRBZE1-> (!Eof())
            cNumTit := TRBZE1->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO)
            cTipo   := "01"
        ELSE
            cNumTit := ""
        EndIf
        TRBZE1->(dbCloseArea())

    EndIf

Return nil
