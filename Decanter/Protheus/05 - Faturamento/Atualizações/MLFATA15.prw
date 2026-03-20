#Include "Totvs.ch"
/*/{Protheus.doc} MLFATA15
Rotina de edição de reajustes de preços de venda 
@type function
@version  
@author marcelo
@since 5/22/2023
@return variant, return_description
/*/
User Function MLFATA15()


	Local       aAreaOld    := GetArea()
	Local       aButton     := {}
	Local       iX
	Local       aAlter      := {}
	Local       cAliasDA0   := GetNextAlias()
	Private		aTotRdpe 	:= {{0,0,0,0},{0,0,0,0}}
	Private		oTotRdp		:= {,,}
	Private     aListDA1    := {}
	Private     oNoMarked  	:= LoadBitmap( GetResources(), "LBNO" )
	Private     oMarked    	:= LoadBitmap( GetResources(), "LBOK" )
	Private     cProdIni    := Replicate(" ",TamSX3("Z03_VTEX")[1])
	Private     cProdFim    := Replicate("Z",TamSX3("Z03_VTEX")[1])
	Private     cPrdIni     := Replicate(" ",TamSX3("B1_COD")[1])
	Private     cPrdFim     := Replicate("Z",TamSX3("B1_COD")[1])
	Private     cPrdAxIni   := Replicate(" ",TamSX3("B1_COD")[1])
	Private     cPrdAxFim   := Replicate("Z",TamSX3("B1_COD")[1])
	Private     cPaisIni    := Replicate(" ",TamSX3("Z03_PAIS")[1])
	Private     cPaisFim    := Replicate("Z",TamSX3("Z03_PAIS")[1])
	Private     dDatReaj    := FirstDay(LastDay(dDataBase)+1)
	Private     nPerReaj    := 0
	Private     aCpo        := {"DA1_CODTAB","DA1_ITEM","DA1_CODPRO","B1_DESC","DA1_PRCVEN","DA1_XDTALT","DA1_XPRCAN","DA1_XNDTAJ","DA1_XNPERC","DA1_XNPRCV"}
	Private     cTabArrd    := GetNewPar("DC_RNDPRCV","101#201#203#301")


	If DA1->(FieldPos("DA1_XNDTAJ")) == 0 .Or. DA1->(FieldPos("DA1_XNDTEF")) == 0 .Or. DA1->(FieldPos("DA1_XNPRCV")) == 0  .Or. DA1->(FieldPos("DA1_XNPERC")) == 0
		MsgAlert("Campos necessários para funcionamento da rotina não foram criados!")
		Return
	Endif

	If MsgYesNo("Rodar a verificação de aplicação de preços programados?")
		U_MLFATX15()
	Endif

	DEFINE MSDIALOG oDlgImp TITLE OemToAnsi("Manutenção antecipada de Reajuste Tabela de Preços de Venda") From 0,0 to 1100,1800 OF oMainWnd PIXEL

	oDlgImp:lMaximized := .T.


	oPanFull := TPanel():New(0,0,'',oDlgImp, oDlgImp:oFont, .T., .T.,, ,80,80,.T.,.T. )
	oPanFull:Align := CONTROL_ALIGN_ALLCLIENT

	oPanFiltr := TPanel():New(0,0,'',oPanFull, oDlgImp:oFont, .T., .T.,, ,100,45,.T.,.T. )
	oPanFiltr:Align := CONTROL_ALIGN_TOP

	oPanTab := TPanel():New(0,0,'',oPanFull, oDlgImp:oFont, .T., .T.,, ,170,170,.T.,.T. )
	oPanTab:Align := CONTROL_ALIGN_LEFT

	DEFINE FONT oFnt 	NAME "Arial" SIZE 0, -11 BOLD

	If cEmpAnt == "01" // Específico Decanter 
		@ 012 ,005 Say OemToAnsi("Produtor De:") SIZE 40,9 PIXEl OF oPanFiltr FONT oFnt
		@ 011 ,050 MSGET cProdIni  F3 "Z03PRT" PIXEl SIZE 55, 10 OF oPanFiltr HASBUTTON

		@ 025 ,005 Say OemToAnsi("Produtor Até:") SIZE 40,9 PIXEl OF oPanFiltr FONT oFnt
		@ 024 ,050 MSGET cProdFim  F3 "Z03PRT" PIXEl SIZE 55, 10 OF oPanFiltr HASBUTTON
	Endif 
	@ 012 ,110 Say OemToAnsi("Código De 1:") SIZE 40,9 PIXEl OF oPanFiltr FONT oFnt
	@ 011 ,155 MSGET cPrdIni  F3 "SB1XML" Valid (Eval({|| cPrdAxIni := Padr("6" + Substr(cPrdIni,2),TamSX3("B1_COD")[1]) , .T. })) PIXEl SIZE 55, 10 OF oPanFiltr HASBUTTON

	@ 025 ,110 Say OemToAnsi("Código Até 1:") SIZE 40,9 PIXEl OF oPanFiltr FONT oFnt
	@ 024 ,155 MSGET cPrdFim  F3 "SB1XML" Valid (Eval({|| cPrdAxFim := Padr("6" + Substr(cPrdFim,2),TamSX3("B1_COD")[1]) , .T. }))  PIXEl SIZE 55, 10 OF oPanFiltr HASBUTTON

	@ 012 ,215 Say OemToAnsi("Código De 2:") SIZE 40,9 PIXEl OF oPanFiltr FONT oFnt
	@ 011 ,260 MSGET cPrdAxIni  F3 "SB1XML" PIXEl SIZE 55, 10 OF oPanFiltr HASBUTTON

	@ 025 ,215 Say OemToAnsi("Código Até 2:") SIZE 40,9 PIXEl OF oPanFiltr FONT oFnt
	@ 024 ,260 MSGET cPrdAxFim  F3 "SB1XML" PIXEl SIZE 55, 10 OF oPanFiltr HASBUTTON

	If cEmpAnt == "01" // Específico Decanter 
		@ 012 ,320 Say OemToAnsi("País De:") SIZE 40,9 PIXEl OF oPanFiltr FONT oFnt
		@ 011 ,365 MsGet cPaisIni F3 "SYA" Size 30,10 Pixel of oPanFiltr

		@ 025 ,320 Say OemToAnsi("País Até:") SIZE 40,9 PIXEl OF oPanFiltr FONT oFnt
		@ 024 ,365 MsGet cPaisFim F3 "SYA" Size 30,10 Pixel of oPanFiltr
	Endif 
	@ 012 ,400  SAY OemToAnsi("% Reajuste?") Of oPanFiltr PIXEL	FONT oFnt
	@ 011 ,445	MSGET nPerReaj Picture "@E 99.999" Of oPanFiltr  SIZE 55 ,10 PIXEL

	@ 025 ,400  SAY OemToAnsi("Data Efetivação?") Of oPanFiltr PIXEL	FONT oFnt
	@ 024 ,445	MSGET dDatReaj  Of oPanFiltr  SIZE 55 ,10 PIXEL

	@ 012 ,510 Button oBtnUpd PROMPT "&Atualizar" Action  Processa({|| sfRefrehGet() }, "Processando...") Size 55,14 of oPanFiltr Pixel
	@ 012 ,570 Button oBtnUpd PROMPT "&Gravar Alterações" Action sfGrvDados(oMulti,"DA1") Size 55,14 of oPanFiltr Pixel

	@ 028 ,510 Say OemToAnsi("Parâemetro 'DC_RNDPRCV' - Tabelas que arredondam com R$ 0,90 :" + cTabArrd) Of oPanFiltr PIXEL	FONT oFnt
	BeginSql alias cAliasDA0
    
        SELECT DA0_CODTAB,DA0_DESCRI
          FROM %Table:DA0% 
         WHERE %notDel%
           AND DA0_ATIVO = '1'
           AND DA0_FILIAL = %xFilial:DA0% 
           AND DA0_DATATE >= %Exp:DTOS(dDataBase)%
	EndSql

	While (cAliasDA0)->(!EOF())
		Aadd(aListDA1,{.F.,(cAliasDA0)->DA0_CODTAB,(cAliasDA0)->DA0_DESCRI})
		(cAliasDA0)->(DbSkip())
	Enddo
	(cAliasDA0)->(DbCloseArea())

	@ 010,005 LISTBOX oListDA1 Var cModelo FIELDS HEADER;
		" "   ,;
		"Tabela"   ,;
		"Descrição" FIELDSIZES 30,40,100 Size 467,110 ON DBLCLICK () PIXEL OF oPanTab

	oListDA1:SetArray(aListDA1)
	oListDA1:bLDblClick     := {|| aListDA1[oListDA1:nAt,1] := !aListDA1[oListDA1:nAt,1]}
	oListDA1:bHeaderClick	:= {|nRow, nCol| If(nCol == 1,(aEval( aListDA1,{ |x| x[1] := !x[1]}) ,oListDA1:Refresh()),Nil) }

	oListDA1:bLine:={ ||{Iif(aListDA1[oListDA1:nAt,1],oMarked,oNoMarked),aListDA1[oListDA1:nAT,2],aListDA1[oListDA1:nAT,3]}}
	oListDA1:Refresh()
	oListDA1:Align := CONTROL_ALIGN_ALLCLIENT

	//Processa({|| sfCarrega(@aCols,@aHeader,1) },"Localizando registros...")
	aHeader     := {}
	Aadd(aAlter,"DA1_XNDTAJ")
	Aadd(aAlter,"DA1_XNPERC")
	Aadd(aAlter,"DA1_XNPRCV")

	For iX := 1 To Len(aCpo)
		//,{X3_CAMPO,X3_PICTURE,X3_TAMANHO,X3_DECIMAL,X3_VALID,X3_USADO,X3_TIPO,X3_F3,X3_CONTEXT,X3_CBOX,X3_RELACAO,X3_WHEN,X3_VISUAL,X3_VLDUSER,X3_PICTVAR,X3_OBRIGAT })
		Aadd(aHeader,{ AllTrim(GetSx3Cache(aCpo[iX], 'X3_TITULO')),;
			GetSx3Cache(aCpo[iX], 'X3_CAMPO'),;
			GetSx3Cache(aCpo[iX], 'X3_PICTURE'),;
			GetSx3Cache(aCpo[iX], 'X3_TAMANHO'),;
			GetSx3Cache(aCpo[iX], 'X3_DECIMAL'),;
			"AllwaysTrue()"	,;
			GetSx3Cache(aCpo[iX], 'X3_USADO'),;
			GetSx3Cache(aCpo[iX], 'X3_TIPO'),;
			GetSx3Cache(aCpo[iX], 'X3_F3'),;
			GetSx3Cache(aCpo[iX], 'X3_CONTEXT'),;
			Iif(Substr(GetSx3Cache(aCpo[iX], 'X3_CBOX'),1,1) == "#",&(Substr(GetSx3Cache(aCpo[iX], 'X3_CBOX'),2)),GetSx3Cache(aCpo[iX], 'X3_CBOX')) 	,;
			GetSx3Cache(aCpo[iX], 'X3_RELACAO'),;
			GetSx3Cache(aCpo[iX], 'X3_WHEN'),;
			Iif(aScan(aAlter,{|x| x== aCpo[iX] } ) > 0 ,"A", GetSx3Cache(aCpo[iX], 'X3_VISUAL'))})

	Next
	AADD( aHeader, { "Recno WT","DA1_REC_WT", "", 09, 0,, GetSx3Cache("DA1_PRCVEN", 'X3_USADO'), "N", "DA1", "V"} )

	aCols	:= {Array(Len(aHeader)+1)}
	aCols[Len(aCols),Len(aHeader)+1]	:= .F.

	Private oMulti := MsNewGetDados():New(034, 005, 226, 415,GD_DELETE+GD_UPDATE,"AllwaysTrue()"/*cLinhaOk*/,;
		"AllwaysTrue()"/*cTudoOk*/,"",aAlter;
		,0/*nFreeze*/,1000000/*nMax*/,"AllwaysTrue()"/*cCampoOk*/,/*cSuperApagar*/,;
    		/*cApagaOk*/,oPanFull,@aHeader,@aCols,{|| /*sfAtuRodp()*/ })

	oMulti:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	/*@ 011 ,190 	SAY OemToAnsi("+(B)  R$ Despesa  :") Of oPanel3 PIXEL	FONT oFnt
	@ 010 ,240	MSGET oTotRdp[2] 	VAR aTotRdPe[1][2]	Picture "@E 999,999,999.99" Of oPanel3 READONLY SIZE 95 ,9 PIXEL

	@ 041 ,190	SAY OemToAnsi("=(A+B) R$ Total :") Of oPanel3 PIXEL FONT oFnt
	@ 040 ,240	MSGET oTotRdp[3] VAR aTotRdPe[1][3] Picture "@E 999,999,999.99" Of oPanel3 READONLY SIZE 95 ,9 PIXEL*/


	//ACTIVATE MSDIALOG oDlgImp ON INIT (oMulti:oBrowse:Refresh(),EnchoiceBar(oDlgImp,{|| Processa({||sfGrvDados()},"Efetuando gravações...") , oDlgImp:End() },{|| oDlgImp:End()},,aButton))
    Activate MsDialog oDlgImp ON INIT (EnchoiceBar(oDlgImp,{|| oDlgImp:End() },{|| oDlgImp:End()},,aButton,/*nRecno*/,/*cAlias*/ ,.F./*lMashups*/,.F./*lImpCad*/,.F./*lPadrao*/,.F./*lHasOk*/,.F./*lWalkThru*/))

    RestArea(aAreaOld)


Return 

/*/{Protheus.doc} sfGrvDados
Função para gravar os dados 
@type function
@version  
@author marcelo
@since 5/11/2023
@param oInGet, object, param_description
@param cInAlias, character, param_description
@return variant, return_description
/*/
Static Function sfGrvDados(oInGet,cInAlias)

    Local	nLenCols	:= 0
	Local	nLenHead	:= 0
	Local	nX,nY
    Local   lContinua   := .F. 

	// Cria valores dinânimcos
	// Número de linha do Getdados
	nLenCols	:= Len(oInGet:aCols)
	// Número de colunas do Getdados
	nLenHead	:= Len(oInGet:aHeader)
	Begin Transaction 	
		For nX := 1 To nLenCols
			DbSelectArea(cInAlias)
			//If !(oInGet:aCols[nX,Len(oInGet:aHeader)+1])

			// Procura se o registro já existe na tabela ou não	
			For nY := 1 To nLenHead
				If IsHeadRec(oInGet:aHeader[nY][2])
					If  !(oInGet:aCols[nX,Len(oInGet:aHeader)+1]) .And. oInGet:aCols[nX,nY] > 0 
						(cInAlias)->(MsGoto(oInGet:aCols[nX,nY]))
						RecLock(cInAlias,.F.)
                        lContinua   := .T. 
					EndIf
					Exit
				Endif
			Next nY
			If !(oInGet:aCols[nX,Len(oInGet:aHeader)+1]) .And. lContinua
				For nY := 1 To nLenHead
					If oInGet:aHeader[nY][10] # "V"
						(cInAlias)->(FieldPut(FieldPos(oInGet:aHeader[nY][2]),oInGet:aCols[nX][nY]))
					EndIf
				Next nY
				DA1_INDLOT		:= "000000000999999.99"
				DA1_QTDLOT 		:= 999999.99
				MsUnlock()	
			Endif
			//Endif
		Next nX
	End Transaction 
	MsgInfo("Dados gravados com sucesso!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))

    // Efetua refresh da Tela de GetDados 
    sfRefrehGet() 

Return 

/*/{Protheus.doc} sfRefrehGet
Função para recarregar os dados na Tela
@type function
@version  
@author marcelo
@since 5/11/2023
@return variant, return_description
/*/
Static Function sfRefrehGet()

    Local   aAreaOld        := GetArea()
    Local   cAliasDA1       := GetNextAlias()
    Local   cCpoDA1         := ""
    Local   cDA0Mark        := ""
    Local   iX 
    Local   iZ 
    

    oMulti:aCols    := {} 

    // Monta o nome dos Campos de forma dinâmica 
    For iX := 1 To Len(aCpo)        
         If !Empty(cCpoDA1)
               cCpoDA1 += ","
         Endif 
        cCpoDA1 += aCpo[iX]        
    Next 
    cCpoDA1 := "%"+cCpoDA1+"%"


    For iX := 1 To Len(aListDA1)
        If aListDA1[iX,1]
            If !Empty(cDA0Mark)
                cDA0Mark += ","
            Endif 
            cDA0Mark += "'"+aListDA1[iX,2]+"'"
        Endif 
    Next 
    If !Empty(cDA0Mark)
 
        cDA0Mark := "%DA1_CODTAB IN("+cDA0Mark+")%"

		If cEmpAnt == "01" // Específico Decanter 
			BeginSql alias cAliasDA1
				COLUMN DA1_XDTALT AS DATE 
				COLUMN DA1_XNDTAJ AS DATE             
				SELECT %Exp:cCpoDA1%,DA1.R_E_C_N_O_ DA1RECNO 
				  FROM %Table:DA1% DA1
				 INNER JOIN %Table:SB1% SB1
					ON SB1.%NotDel%
				   AND B1_COD = DA1_CODPRO
				   AND B1_FILIAL = %xFilial:SB1%
				 INNER JOIN %table:ZFT% ZFT 
					ON ZFT.%notDel%
				   AND ZFT_COD = B1_ZFT
				   AND ZFT_FILIAL = %xFilial:ZFT%
				 INNER JOIN %table:Z03% Z03 
					ON Z03.%notDel%
				   AND Z03_CODIGO = ZFT_PRODUT
				   AND Z03_FILIAL = %xFilial:SZ03%
				 WHERE DA1.%notDel%
				   AND %Exp:cDA0Mark%
				   AND DA1_FILIAL = %xFilial:DA1% 
				   AND Z03_CODIGO BETWEEN %Exp:cProdIni% AND %Exp:cProdFim% 
				   AND ((B1_COD BETWEEN %Exp:cPrdIni% AND %Exp:cPrdFim% ) OR  (B1_COD BETWEEN %Exp:cPrdAxIni% AND %Exp:cPrdAxFim% ) ) 
				   AND Z03_PAIS BETWEEN %Exp:cPaisIni % AND %Exp:cPaisFim% 
				 ORDER BY 1,3,2
			EndSql
		Else
 			 BeginSql alias cAliasDA1
				COLUMN DA1_XDTALT AS DATE 
				COLUMN DA1_XNDTAJ AS DATE             
				SELECT %Exp:cCpoDA1%,DA1.R_E_C_N_O_ DA1RECNO 
				  FROM %Table:DA1% DA1
				 INNER JOIN %Table:SB1% SB1
					ON SB1.%NotDel%
			   	   AND B1_COD = DA1_CODPRO
				   AND B1_FILIAL = %xFilial:SB1%
				  LEFT JOIN %table:ZFT% ZFT 
					ON ZFT.%notDel%
				   AND ZFT_COD = B1_ZFT
				   AND ZFT_FILIAL = %xFilial:ZFT%
				 WHERE DA1.%notDel%
				   AND %Exp:cDA0Mark%
				   AND DA1_FILIAL = %xFilial:DA1% 
				   AND ((B1_COD BETWEEN %Exp:cPrdIni% AND %Exp:cPrdFim% ) OR  (B1_COD BETWEEN %Exp:cPrdAxIni% AND %Exp:cPrdAxFim% ) ) 
				 ORDER BY 1,3,2
			EndSql
		Endif 
        While (cAliasDA1)->(!EOF())

            Aadd(oMulti:aCols,Array(Len(oMulti:aHeader)+1))

            oMulti:aCols[Len(oMulti:aCols),Len(oMulti:aHeader)+1]	:= .F.
            For iZ := 1 To Len(oMulti:aHeader)
                If oMulti:aHeader[iZ,2] == "DA1_REC_WT"
                    oMulti:aCols[Len(oMulti:aCols),iZ]  :=  (cAliasDA1)->DA1RECNO
                ElseIf oMulti:aHeader[iZ,2] == "DA1_XNDTAJ"
                    If Empty((cAliasDA1)->(FieldGet(FieldPos("DA1_XNDTAJ"))))
                        oMulti:aCols[Len(oMulti:aCols),iZ]  :=  dDatReaj
                    Else 
                        oMulti:aCols[Len(oMulti:aCols),iZ]  :=  (cAliasDA1)->(FieldGet(FieldPos(oMulti:aHeader[iZ,2])))
                        oMulti:aCols[Len(oMulti:aCols),Len(oMulti:aHeader)+1] := .T. // Vem Deletada a linha para não fazer a atualização por que já tem uma data preenchida 
                    Endif 
                ElseIf oMulti:aHeader[iZ,2] == "DA1_XNPERC"
                    // Se o campo de data de Efetivação 
                    If Empty((cAliasDA1)->DA1_XNDTAJ)
                        oMulti:aCols[Len(oMulti:aCols),iZ]  :=  nPerReaj
                    Else    
                        oMulti:aCols[Len(oMulti:aCols),iZ]  :=  (cAliasDA1)->(FieldGet(FieldPos(oMulti:aHeader[iZ,2])))                    
                    Endif                 
                ElseIf oMulti:aHeader[iZ,2] == "DA1_XNPRCV"
                    If Empty((cAliasDA1)->DA1_XNDTAJ)
                        // Verifica se a tabela deve arredondar valor para cima com 0,90 
                        If (cAliasDA1)->DA1_CODTAB $ cTabArrd
                            oMulti:aCols[Len(oMulti:aCols),iZ]  :=  Int((100+nPerReaj) / 100 * (cAliasDA1)->DA1_PRCVEN) + 0.90
                        Else 
                            oMulti:aCols[Len(oMulti:aCols),iZ]  :=  Round((100+nPerReaj) / 100 * (cAliasDA1)->DA1_PRCVEN,TamSX3("DA1_PRCVEN")[2])
                        Endif 
                    Else 
                        oMulti:aCols[Len(oMulti:aCols),iZ]  :=  (cAliasDA1)->(FieldGet(FieldPos(oMulti:aHeader[iZ,2])))                    
                    Endif                 
                Else 
                    oMulti:aCols[Len(oMulti:aCols),iZ]  :=  (cAliasDA1)->(FieldGet(FieldPos(oMulti:aHeader[iZ,2])))
                Endif 

            Next 
            
            (cAliasDA1)->(DbSkip())
        Enddo

        (cAliasDA1)->(DbCloseArea())
    Endif 

    RestArea(aAreaOld)
    oMulti:oBrowse:Refresh()

Return 


/*/{Protheus.doc} MLFATX15
Função para atualizar os preços 
@type function
@version  
@author marcelo
@since 13/03/2024
@return variant, return_description
/*/
User Function MLFATX15()

	Local 	cQry 	:= ""
	Local 	cDtAtu 	:= DTOS(dDataBase)
	//SELECT * --DA1_XNPRCV / DA1_PRCVEN  * 100 - 100 ,DA1_XNPRCV,DA1_PRCVEN,DA1_CODTAB,DA1_CODPRO  FROM DA1010 WHERE D_E_L_E_T_ =' ' AND DA1_XNDTAJ <>  ' ' ORDER BY DA1_CODPRO,DA1_CODTAB 
	//--SELECT * INTO DA1010_BK20230619 FROM DA1010 
	//SELECT COUNT(*) FROM DA1010_BK20230619 WHERE D_E_L_E_T_ =' ' AND DA1_XNDTAJ ='20230619'; 

	cQry := "UPDATE "+ RetSqlName("DA1") + " SET DA1_XPRCAN = DA1_PRCVEN  	WHERE D_E_L_E_T_ =' ' AND DA1_XNDTAJ ='"+cDtAtu+"' "
	TcSqlExec(cQry)
	cQry := "UPDATE "+ RetSqlName("DA1") + "  SET DA1_XDTALT = '"+cDtAtu+"' WHERE D_E_L_E_T_ =' ' AND DA1_XNDTAJ ='"+cDtAtu+"' "
	TcSqlExec(cQry)
	cQry := "UPDATE "+ RetSqlName("DA1") + "  SET DA1_PRCVEN = DA1_XNPRCV  	WHERE D_E_L_E_T_ =' ' AND DA1_XNDTAJ ='"+cDtAtu+"' "
	TcSqlExec(cQry)
	cQry := "UPDATE "+ RetSqlName("DA1") + "  SET DA1_XNDTEF = '"+cDtAtu+"' WHERE D_E_L_E_T_ =' ' AND DA1_XNDTAJ ='"+cDtAtu+"' "
	TcSqlExec(cQry)
	cQry := "UPDATE "+ RetSqlName("DA1") + "  SET DA1_MSEXP  = ' '         	WHERE D_E_L_E_T_ =' ' AND DA1_XNDTAJ ='"+cDtAtu+"' "
	TcSqlExec(cQry)
	cQry := "UPDATE "+ RetSqlName("DA1") + "  SET DA1_HREXP  = ' '         	WHERE D_E_L_E_T_ =' ' AND DA1_XNDTAJ ='"+cDtAtu+"' " 
	TcSqlExec(cQry)
	cQry := "UPDATE "+ RetSqlName("DA1") + "  SET DA1_XNPRCV = 0          	WHERE D_E_L_E_T_ =' ' AND DA1_XNDTAJ ='"+cDtAtu+"' "
	TcSqlExec(cQry)
	cQry := "UPDATE "+ RetSqlName("DA1") + "  SET DA1_XNDTAJ = ' '         	WHERE D_E_L_E_T_ =' ' AND DA1_XNDTAJ ='"+cDtAtu+"' "
	TcSqlExec(cQry)

Return 
