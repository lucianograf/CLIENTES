#INCLUDE "TOTVS.CH"
#include "fileio.ch"
#include "aarray.ch"
#include "json.ch"
#include "shash.ch"

/*/{Protheus.doc} nomeFunction
    (long_description)
    @type  Function
    @author user
    @since 12/08/2021
    @version version
    @param param_name, param_type, param_descr
    @return return_var, return_type, return_description
    @example
    (examples)
    @see (links_or_references)
    /*/
User Function DECGER()

	Local cMatFun   := ''
	Local cCpf      := ''
	Local cMatOri   := ''
	Local nNroSeq   :=  0
	Local cMatFun := ''
	Local cCpf    := ''
	Local cNome   := ''
	Local cBcoFun := ''
	Local cAgencia := ''
	Local cNroCnt  := ''
	Local cCabDeb  := ''
	Local cCabCrd  := ''
	Local cLiqRec  := ''
	Local cBlqVis  := ''
	Local cFiller  := ''
	Local cCargo   := ''
	Local cIndMat  := ''
	Local cFiller9 := ''
	Local nTotDeb  := ''
	Local nTotCred := ''
	Local nTotLiq  := ''
	Local nQtdLcF  := ''
	Local cBsIRRF  := ''
	Local nVlrIRRF := ''
	Local cFiller4  := ''
	Local cBsINSS := ''
	Local nVlrINSS := ''
	Local cBsFGTS := ''
	Local nVlrFGTS :=''
	Local cFiller5 :=''
	Local cBsFGTS := ''
	Local nVlFGTSM :=''
	Local cFiller6  := ''
	Local nTotDEmp := ''
	Local nTotCEmp := ''
	Local nTotLEmp := ''
	Local nTotRemp := ''
	Local cFiller7 := ''
	Local nSeqLan  := ''
	Local cCodLan  := ''
	Local cDscLan  := ''
	Local cFiller2 := ''
	Local nVlrLan  := ''
	Local cIntBnk  := ''
	Local cTpLanc  := ''
	Local cUnTrb
	Local qtdUnTrb := ''
	Local cFiller3 := ''
	Local cPrvBco1 := ''
	Local cPrvBco2 := ''
	Local cFiller4 := ''
	Local nTotal   := ''
	Private cHEFUN1   := ''
	Private cHEFUN2 := ''
	Private cHEFUN3   := ''
	Private cHEFUN9   :=''
	Private cHEMP1  := ''
	Private cHTE01    := '0E34101320000000040569T000001000001DECANTER VINHOS FINOS LTDA                     0136010220010220210220210306202103062021030616280003414056000000000000E           '
	Private cHTF01    := "134100132000000040569"
	RPCSETTYPE(3)
	RPCSetEnv("01",'0101') //ALTERAR
	cHEMP1    := cHTE01 +CRLF

	BeginSql Alias 'CTBLFOL'
    
       Select RV_TIPO, 
              RA_MAT,
              RA_CIC,
              RA_NOME,
              RA_BCDEPSA,
              RA_CTDEPSA,
              RJ_DESC,
              RC_VALOR,
              RV_COD,
              RV_DESC,
              RA_NOMECMP,
              RC_PD
            

        From SRC010 SRC
        Inner Join SRV010 SRV
            On SRV.RV_FILIAL = ''
            and SRV.RV_COD = SRC.RC_PD
            and SRV.D_E_L_E_T_ = ''

        Inner Join SRA010 SRA 
            On SRA.RA_FILIAL = SRC.RC_FILIAL
            and SRA.RA_MAT   = SRC.RC_MAT
            and SRA.D_E_L_E_T_ = ''

        Left Outer Join SRJ010 SRJ
            On RJ_FILIAL = ''
            and RJ_CODCBO = RA_CODFUNC
            and SRJ.D_E_L_E_T_ = ''

        where SRC.D_E_L_E_T_ = '' 
	EndSql

	Count to nCount
	CTBLFOL->(DbGoTop())
	While CTBLFOL->(!EOF())



		if CTBLFOL->RV_TIPO == 'V'
			cUnTrb := 'VALOR'+SPACE(4)
		elseif CTBLFOL->RV_TIPO == 'D'
			cUnTrb := 'DIAS'+SPACE(5)
		elseif CTBLFOL->RV_TIPO == 'H'
			cUnTrb := 'HORAS'+SPACE(4)
		else
			cUnTrb := SPACE(9)
		endif



		if Empty(cMatFun) .or. ALLTRIM(cMatFun) !=  ALLTRIM(CTBLFOL->RA_MAT)
			nNroSeq := STRZERO(0,3)
			cMatFun := CTBLFOL->RA_MAT+SPACE(20-LEN(CTBLFOL->RA_MAT))
			cCpf    := SUBSTR(CTBLFOL->RA_CIC,1,11)
			cNome   := SUBSTR(CTBLFOL->RA_NOMECMP,1,42)+SPACE(47-LEN(SUBSTR(CTBLFOL->RA_NOMECMP,1,42)))
			cBcoFun := "0341"//SUBSTR(CTBLFOL->RA_BCDEPSA,1,3)+SPACE(1)
			cAgencia := "0000"//"0"+SUBSTR(CTBLFOL->RA_BCDEPSA,4,4)
			cNroCnt  := "000000000000" //"00"+SUBSTR(CTBLFOL->RA_CTDEPSA,1,10)
			cCabDeb  := "DESCONTOS"+SPACE(26)
			cCabCrd  := "PROVENTOS"+SPACE(26)
			cLiqRec  := "LIQUIDO A RECEBER"+SPACE(18)
			cBlqVis  := SPACE(1)
			cFiller  := SPACE(27)
			cCargo   := "000000000000000"//CTBLFOL->RJ_DESC
			cIndMat  := SPACE(2)
			cFiller9 := SPACE(131)
			cHEFUN1   := cHTF01+cMatFun+cCpf+cNome+cAgencia+cNroCnt+cCabDeb+cCabCrd+cLiqRec+cBlqVis+cFiller+cCargo+cIndMat+cFiller9+CRLF

			//*** Deverá conter (exemplo ‘999.999,99’) Alinhar à direita, com preenchimento de espaços não utilizados com brancos a esquerda
			cFiller6  := SPACE(230)

			cCnpj    := ''//
			cFiller5 := SPACE(9)
			cFiller7 := SPACE(310)
			//cHEFUN9   := '9'+cHTF01+cCnpj+nTotDEmp+nTotCEmp+nTotLEmp+nTotRemp+cFiller7+CRLF
		endif

		if !CTBLFOL->RC_PD $ ("999/719/500/739/512")
			nSeqLan  := SOMA1(nNroSeq)
			cCodLan  := CTBLFOL->RV_COD+SPACE(4)
			cDscLan  := CTBLFOL->RV_DESC + SPACE(23-LEN(CTBLFOL->RV_DESC))
			cFiller2 := SPACE(3)
			nVlrLan  := CVALTOCHAR(CTBLFOL->RC_VALOR)
			if AT( '.', nVlrLan) == 0
				nVlrLan := nVlrLan  + '.00'
			endif
			nVlrLan  :=  STRTRAN(nVlrLan, ".", "")  //TransForm(CTBLFOL->RC_VALOR, "9999999")//TransForm(CTBLFOL->RC_VALOR, "@R 999.999,99") //CVALTOCHAR(CTBLFOL->RC_VALOR) //*** Colocar Mascará
			nVlrLan :=    SPACE(9 -LEN(nVlrLan)) +nVlrLan

			cIntBnk  := SPACE(80)
			cTpLanc  := 'D' //*** Ajustar
			qtdUnTrb := SPACE(5)
			cFiller3 := SPACE(1)
			cPrvBco1 := "00010101"
			cPrvBco2 := "00010101"
			cFiller4 := SPACE(222)
			cHEFUN2 += '2'+cMatFun+nSeqLan+cCodLan+cDscLan+cFiller2+nVlrLan+cIntBnk+'C'+cUnTrb +qtdUnTrb+cFiller3+cPrvBco1+cPrvBco2+cFiller4+CRLF
		else
			nTotal := '0'
			nQtdLcF  := SPACE(10)//*** Quantidade Lançamento Funcionário

			nTotal   :=  CVALTOCHAR(CTBLFOL->RC_VALOR)
			if AT( '.', nTotal) == 0
				nTotal := nTotal  + '.00'
			endif
			nTotal  :=  STRTRAN(nTotal, ".", "")  //TransForm(CTBLFOL->RC_VALOR, "9999999")//TransForm(CTBLFOL->RC_VALOR, "@R 999.999,99") //CVALTOCHAR(CTBLFOL->RC_VALOR) //*** Colocar Mascará
			if CTBLFOL->RC_PD == '999'
				nTotal :=    SPACE(15 -LEN(nTotal)) +nTotal
				nTotLiq  :=   nTotal
			endif


			cBsINSS := "BASE INSS"
			cBsIRRF := "BASE IRRF"
			cBsFGTS := "FGTS MES "
			nVlrINSS := SPACE(5)+"98111"
			nVlrIRRF := SPACE(5)+"88111"
			nVlrFGTS := SPACE(5)+"78111"
			nVlFGTSM := SPACE(5)+"68111"

			nTotDeb  := SPACE(10)+"98111" //SPACE(15) //***
			nTotCred := SPACE(10)+"88111" //SPACE(15) //***
			nTotDEmp := SPACE(10)+"78111" //SPACE(15) //***
			nTotCEmp := SPACE(10)+"68111" //SPACE(15) //***
			nTotRemp := SPACE(10)+"58111" //SPACE(15) //***
			nTotLEmp := SPACE(10)+"48111" //SPACE(15) //***

		Endif

		CTBLFOL->(DbSkip())

	EndDo
	cHEFUN3   := '3'+cMatFun+nTotDeb+nTotCred+nTotLiq+nQtdLcF+cBsIRRF+nVlrIRRF+cFiller5+cBsINSS+nVlrINSS+cBsFGTS+nVlrFGTS+cFiller5+cBsFGTS+nVlFGTSM+cFiller6+CRLF
	cHEFUN9   := '9'+cHTF01+cCnpj+nTotDEmp+nTotCEmp+nTotLEmp+nTotRemp+cFiller7+CRLF
	U_TSTFILE()

Return


User Function TSTFILE()

	Local nHnd
	Local cFile := '\temp\teste.txt'
	Local cLine
	nHnd := FCreate(cFile)

	FWrite(nHnd,cHEMP1+cHEFUN1+cHEFUN2+cHEFUN3+cHEFUN9)

	FClose(nHnd)


	If nHnd == -1
		MsgStop("Falha ao criar arquivo ["+cFile+"]","FERROR "+cValToChar(fError()))
		Return
	Endif

Return
