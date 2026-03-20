#Include 'Protheus.ch'

/*/{Protheus.doc} User Function CNABTRIB
Tributos segmento N
@author ARTHUR VINICIUS VOLTOLINI
@since 10/10/2023
@version 1.0
@type function
/*/

User Function CNABTRIB()

    Local nValor 		:= STRZERO(INT(SE2->E2_VALOR*100),14)
    Local nJuros        := STRZERO(INT(SE2->E2_JUROS*100),14)
    Local nMulta        := STRZERO((SE2->E2_ACRESC*100),14)
    Local nTotal        := STRZERO(INT(SE2->(E2_SALDO + E2_ACRESC + E2_JUROS) * 100),14)
    Local cInsc         := ""
    Local cCGC          := ""
    Local cNumTit   	:= SE2->(E2_PREFIXO + E2_NUM + E2_PARCELA)
    Local dVenc1		:= SUBSTR(DTOS(SE2->E2_VENCREA),5,2)+SUBSTR(DTOS(SE2->E2_VENCREA),1,4) 
    Local dVenc2    	:= GRAVADATA(SE2->E2_VENCREA,.F.,5) 
    Local dEmis1    	:= GRAVADATA(SE2->E2_EMISSAO,.F.,5)
    Local cIdCnab       := ALLTRIM(SE2->E2_IDCNAB)
    Local cContrib      := IF(ALLTRIM(SE2->E2_CODRET) == "2631",PADR(SA2->A2_NOME,30),PADR(SM0->M0_NOME,30))

    IF  SEE->EE_CODIGO == "341"

        IF ALLTRIM(SE2->E2_CODRET)=="2631" .and. !EMPTY(ALLTRIM(SA2->A2_CGC))
            cCgc := PADL(ALLTRIM(SA2->A2_CGC),14,"0")
            cInsc:= IF(SA2->A2_TIPO == "J", "2", "1")
        Else   
            cCgc := PADL(SM0->M0_CGC,14,"0")
            cInsc := "2"
        EndIf

        If  SEA->EA_MODELO$ "16" //DARF NORMAL
            _CNABN := "02" + SE2->E2_CODRET + cInsc + cCGC + dEmis1 + STRZERO(0,17) + nValor + nMulta + nJuros + nTotal + dVenc2 + dVenc2 + Space(30) + cContrib
        EndIF
    EndIF

Return _CNABN                   
