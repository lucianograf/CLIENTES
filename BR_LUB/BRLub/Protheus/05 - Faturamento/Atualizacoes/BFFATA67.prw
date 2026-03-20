#include "totvs.ch"


User Function BFFATA67()


	Local oDlsVis
	Local aSaveArea		:= GetARea()
	Local aOrdem 		:={}

	Private aSize       := MsAdvSize(.F.)
	Private aColumns2 	:= {}
	Private oBrowse 	:= nil
	Private aQuery 		:= {}
	Private nPxRecno	:= 7
	Private cAliasZD6	:= GetNextAlias()
	
	sfGetData()

	aQuery := GetLastQuery() //Função que joga para um array a Embedded Sql

	cQry	:= aQuery[2]

	DEFINE MsDialog oDlsVis TITLE "Controle de percentuais " From aSize[7],0 To aSize[6],aSize[5] Pixel STYLE nOR(WS_VISIBLE,WS_POPUP)
	oDlsVis:lMaximized := .T.

	Aadd( aOrdem, "(cAliasZD6)->ZD6_DTINI")

	oBrowse2 := FwMBrowse():New()
	oBrowse2:SetOwner(oDlsVis)
	oBrowse2:SetDataQuery(.T.)
	oBrowse2:SetQuery(cQry)
	oBrowse2:SetAlias(cAliasZD6)
	oBrowse2:SetQueryIndex(aOrdem)
	oBrowse2:SetFilterDefault( "" )
	oBrowse2:DisableDetails()
	oBrowse2:DisableReport()

	oBrowse2:SetProfileID( 'X1' )
	oBrowse2:SetMenuDef('')
	oBrowse2:AddButton( "Incluir", { ||sfIncluir(3) }, , 6)
	oBrowse2:AddButton( "Alterar", { ||sfIncluir(4) }, , 6)
	oBrowse2:AddButton( "Sair", { ||oDlsVis:End() }, , 6)

	oColumn2:=	FWBrwColumn():New()
	oColumn2:SetData({|| ZD6_CODTAB })
	oColumn2:SetType( 	GetSx3Cache("ZD6_CODTAB","X3_TIPO"))
	oColumn2:SetTitle( GetSx3Cache("ZD6_CODTAB","X3_TITULO"))
	oColumn2:SetSize(	GetSx3Cache("ZD6_CODTAB","X3_TAMANHO"))
	oColumn2:SetDecimal(	GetSx3Cache("ZD6_CODTAB","X3_DECIMAL"))
	oColumn2:SetEdit(.T.)
	oColumn2:SetReadVar("M->ZD6_CODTAB")
	oColumn2:SetPicture(	GetSx3Cache("ZD6_CODTAB","X3_PICTURE"))
	oColumn2:SETAUTOSIZE(.F.)
	oColumn2:SETWIDTH(150)
	aadd(aColumns2,oColumn2)

	oColumn2:=	FWBrwColumn():New()
	oColumn2:SetData({|| StoD(ZD6_DTINI) })
	oColumn2:SetType( 	GetSx3Cache("ZD6_DTINI","X3_TIPO"))
	oColumn2:SetTitle( GetSx3Cache("ZD6_DTINI","X3_TITULO"))
	oColumn2:SetSize(	GetSx3Cache("ZD6_DTINI","X3_TAMANHO"))
	oColumn2:SetDecimal(	GetSx3Cache("ZD6_DTINI","X3_DECIMAL"))
	oColumn2:SetEdit(.T.)
	oColumn2:SetReadVar("M->ZD6_DTINI")
	oColumn2:SetPicture(	GetSx3Cache("ZD6_DTINI","X3_PICTURE"))
	oColumn2:SETAUTOSIZE(.F.)
	oColumn2:SETWIDTH(120)
	aadd(aColumns2,oColumn2)

	oColumn2:=	FWBrwColumn():New()
	oColumn2:SetData({|| StoD(ZD6_DTFIM) })
	oColumn2:SetType( 	GetSx3Cache("ZD6_DTFIM","X3_TIPO"))
	oColumn2:SetTitle( GetSx3Cache("ZD6_DTFIM","X3_TITULO"))
	oColumn2:SetSize(	GetSx3Cache("ZD6_DTFIM","X3_TAMANHO"))
	oColumn2:SetDecimal(	GetSx3Cache("ZD6_DTFIM","X3_DECIMAL"))
	oColumn2:SetEdit(.T.)
	oColumn2:SetReadVar("M->ZD6_DTFIM")
	oColumn2:SetPicture(	GetSx3Cache("ZD6_DTFIM","X3_PICTURE"))
	oColumn2:SETAUTOSIZE(.F.)
	oColumn2:SETWIDTH(120)
	aadd(aColumns2,oColumn2)


	oColumn2:=	FWBrwColumn():New()
	oColumn2:SetData({|| ZD6_FORNEC })
	oColumn2:SetType( 	GetSx3Cache("ZD6_FORNEC","X3_TIPO"))
	oColumn2:SetTitle( GetSx3Cache("ZD6_FORNEC","X3_TITULO"))
	oColumn2:SetSize(	GetSx3Cache("ZD6_FORNEC","X3_TAMANHO"))
	oColumn2:SetDecimal(	GetSx3Cache("ZD6_FORNEC","X3_DECIMAL"))
	oColumn2:SetEdit(.T.)
	oColumn2:SetReadVar("M->ZD6_FORNEC")
	oColumn2:SetPicture(	GetSx3Cache("ZD6_FORNEC","X3_PICTURE"))
	oColumn2:SETAUTOSIZE(.F.)
	oColumn2:SETWIDTH(120)
	aadd(aColumns2,oColumn2)

	oColumn2:=	FWBrwColumn():New()
	oColumn2:SetData({|| ZD6_LOJA })
	oColumn2:SetType( 	GetSx3Cache("ZD6_LOJA","X3_TIPO"))
	oColumn2:SetTitle( GetSx3Cache("ZD6_LOJA","X3_TITULO"))
	oColumn2:SetSize(	GetSx3Cache("ZD6_LOJA","X3_TAMANHO"))
	oColumn2:SetDecimal(	GetSx3Cache("ZD6_LOJA","X3_DECIMAL"))
	oColumn2:SetEdit(.T.)
	oColumn2:SetReadVar("M->ZD6_LOJA")
	oColumn2:SetPicture(	GetSx3Cache("ZD6_LOJA","X3_PICTURE"))
	oColumn2:SETAUTOSIZE(.F.)
	oColumn2:SETWIDTH(150)
	aadd(aColumns2,oColumn2)

	oBrowse2:SetColumns(aColumns2)

	oBrowse2:Activate()

	ACTIVATE MsDialog oDlsVis Center

	RestArea(aSaveArea)

Return


Static Function sfGetData()

	If Select('LOG') <> 0
		LOG->(DbCloseArea())
	EndIf

	BeginSql Alias 'LOG'
        SELECT ZD6_CODTAB,ZD6_FORNEC,ZD6_LOJA,ZD6_DTINI,ZD6_DTFIM            
          FROM %Table:ZD6% ZD6
         WHERE ZD6.ZD6_FILIAL = %Exp:xFilial("ZD6")%
           AND ZD6.%notDel%
		 GROUP BY ZD6_FILIAL,ZD6_CODTAB,ZD6_FORNEC,ZD6_LOJA,ZD6_DTINI,ZD6_DTFIM
	EndSql

Return


Static Function sfIncluir(nInOpc)

	Local	aHeadConv	:= {}
	Local	aColsConv	:= {}
	Local	aSize 		:= MsAdvSize(,.F.,400)
	Local 	cCSS
	Local 	aColsSize	:= {}
	Local 	aAlter		:= {}
	Private dDtVigIni   := Iif(nInOpc == 4,STOD((cAliasZD6)->ZD6_DTINI),dDataBase)
	Private dDtVigFim   := Iif(nInOpc == 4,STOD((cAliasZD6)->ZD6_DTFIM),dDataBase+60)
	Private cZD6CODTAB	:= Iif(nInOpc == 4,(cAliasZD6)->ZD6_CODTAB,GetSXeNum("ZD6","ZD6_CODTAB"))
	Private cZD6FORNEC	:= Iif(nInOpc == 4,(cAliasZD6)->ZD6_FORNEC,"000468")
	Private cZD6LOJA 	:= Iif(nInOpc == 4,(cAliasZD6)->ZD6_LOJA,"33")
	Private nOpcAlt 	:= nInOpc 



	DEFINE MSDIALOG oDlgConv TITLE OemToAnsi("Cadastro de Valores Preço Nota x Serviço ") From aSize[7],0 to aSize[6],aSize[5] OF oMainWnd PIXEL

	oDlgConv:lMaximized := .T.

	oPanel1 := TPanel():New(0,0,'',oDlgConv, oDlgConv:oFont, .T., .T.,, ,200,40,.T.,.T. )
	oPanel1:Align := CONTROL_ALIGN_TOP

	@ 012 ,005  	Say OemToAnsi("Vigência Inicial") SIZE 60,9 PIXEl OF oPanel1
	@ 011 ,066  	MSGET dDtVigIni   Picture "99/99/9999" PIXEl SIZE 55, 10 Valid U_BFATA67A(nInOpc) OF oPanel1 HASBUTTON

	@ 032 ,005  	Say OemToAnsi("Vigência Final") SIZE 60,9 PIXEl OF oPanel1
	@ 031 ,066  	MSGET dDtVigFim   Picture "99/99/9999" PIXEl SIZE 55, 10 Valid U_BFATA67A(nInOpc) OF oPanel1 HASBUTTON

	@ 012 ,130  	Say OemToAnsi("Fornecedor") SIZE 50,9 PIXEl OF oPanel1
	@ 011 ,191  	MSGET cZD6FORNEC  PIXEl SIZE 55, 10  Valid U_BFATA67A(nInOpc) F3 "SA2XML" OF oPanel1 HASBUTTON When nInOpc == 3
	@ 011 ,250  	MSGET cZD6LOJA  PIXEl SIZE 15, 10 Valid U_BFATA67A(nInOpc) OF oPanel1 HASBUTTON When nInOpc == 3

	oPanel2 := TPanel():New(0,0,'',oDlgConv, oDlgConv:oFont, .T., .T.,, ,200,40,.T.,.T. )
	oPanel2:Align := CONTROL_ALIGN_ALLCLIENT


/*01*/Aadd(aHeadConv,{"Cód.Prd.Fornecedor"	            ,"ZD6_CODPRF"	   	,X3Picture("ZD6_CODPRF")	,TamSX3("ZD6_CODPRF")[1]	    ,TamSX3("ZD6_CODPRF")[2]	,"",,"C"	,X3F3("ZD6_CODPRF")		,"R"})
	Aadd(aColsSize,{aHeadConv[Len(aHeadConv)][2],5})
	Aadd(aAlter,"ZD6_CODPRF")
/*02*/Aadd(aHeadConv,{"Cód.Produto Protheus"	        ,"ZD6_PRODUT"		,X3Picture("ZD6_PRODUT") 	,TamSX3("ZD6_PRODUT")[1]		,TamSX3("ZD6_PRODUT")[2]	,"",,"C"	,X3F3("ZD6_PRODUT")		,"R"})
	Aadd(aColsSize,{aHeadConv[Len(aHeadConv)][2],5})
	Aadd(aAlter,"ZD6_PRODUT")
/*03*/Aadd(aHeadConv,{"Descrição Produto"               ,"DESCRICAO"	    ,X3Picture("B1_DESC")      	,TamSX3("B1_DESC")[1]		    ,TamSX3("B1_DESC")[2]       ,"",,"C"	,X3F3("B1_DESC")	    ,"V"})
	Aadd(aColsSize,{aHeadConv[Len(aHeadConv)][2],5})
/*04*/Aadd(aHeadConv,{"Parcela Produto Unitário"	    ,"ZD6_PRUNFE"		,X3Picture("ZD6_PRUNFE") 	,TamSX3("ZD6_PRUNFE")[1]		,TamSX3("ZD6_PRUNFE")[2]	,"",,"N"	,X3F3("ZD6_PRUNFE")		,"R"})
	Aadd(aColsSize,{aHeadConv[Len(aHeadConv)][2],5})
	Aadd(aAlter,"ZD6_PRUNFE")
/*05*/Aadd(aHeadConv,{"Valor Final c/Serviço"	        ,"ZD6_PRUSRV"		,X3Picture("ZD6_PRUSRV") 	,TamSX3("ZD6_PRUSRV")[1]		,TamSX3("ZD6_PRUSRV")[2]	,"",,"N"	,X3F3("ZD6_PRUSRV")		,"R"})
	Aadd(aColsSize,{aHeadConv[Len(aHeadConv)][2],5})
	Aadd(aAlter,"ZD6_PRUSRV")
/*06*/Aadd(aHeadConv,{"Percentual"                      ,"ZD6_PERC"		 	,"@E 999,999.999999"        ,14		                        ,6                  		,"",,"N"	,           		    ,"R"})
	Aadd(aColsSize,{aHeadConv[Len(aHeadConv)][2],5})
	Aadd(aAlter,"ZD6_PERC")
/*07*/Aadd(aHeadConv,{"Recno"	                        ,"RECNO"   	 		,""                    	    ,10                    			,0                      	,"",,"N"	,               		,"V"})
	Aadd(aColsSize,{aHeadConv[Len(aHeadConv)][2],5})

	sfMontaCols(@aColsConv,nInOpc)

	DEFINE FONT oFnt 	NAME "Arial" SIZE 0, -11 BOLD

	Private oConvGet := MsNewGetDados():New(034, 005, 226, 415,GD_INSERT+GD_DELETE+GD_UPDATE,"AllwaysTrue()"/*cLinhaOk*/,;
		"AllwaysTrue()"/*cTudoOk*/,"",aAlter;
		,0/*nFreeze*/,10000/*nMax*/,"U_BFATA67A(nOpcAlt)"/*cCampoOk*/,/*cSuperApagar*/,;
		/*cApagaOk*/,oPanel2,@aHeadConv,@aColsConv,)

	oConvGet:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	cCSS :=	 CRLF+"/* Componentes que herdam da TCBrowse:";
		+CRLF+"   BrGetDDb, MsBrGetDBase,MsSelBr, TGridContainer, TSBrowse, TWBrowse */";
		+CRLF+"QTableWidget {";
		+CRLF+"  gridline-color: #632423; /*Cor da grade*/";
		+CRLF+"  color: #000000; /*Cor da fonte*/";
		+CRLF+"  font-size: 11px; /*Tamanho da fonte*/";
		+CRLF+"  background: #FFFFFF; /*Cor do fundo da Grid*/";
		+CRLF+"  alternate-background-color: #C0D9D9; /*Cor do zebrado*/";
		+CRLF+"  selection-background-color: qlineargradient(x1: 0, y1: 0, x2: 0.8, y2: 0.8,";
		+CRLF+"                              stop: 0 #FFFF99, stop: 1 #FFCC00); /*Cor da linha selecionada*/";
		+CRLF+"}";
		+CRLF+"/* Acoes quando a celula for selecionada, aqui mudo a cor de fundo */";
		+CRLF+"QTableView:item:selected:focus {background-color: #FBD5B5} /*Cor da celula selecionada*/"
	oConvGet:oBrowse:SetCss(cCSS)


	ACTIVATE MSDIALOG oDlgConv ON INIT (oConvGet:oBrowse:Refresh(),EnchoiceBar(oDlgConv,{|| Processa({||sfGravaConv(),},"Gravando dados..."),oDlgConv:End()},{|| RollBackSX8() , oDlgConv:End()},,))

	oBrowse2:Refresh()

Return



/*/{Protheus.doc} sfMontaCols
(long_description)
@author MarceloLauschner
@since 29/06/2014
@version 1.0
@param aColsConv, array, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfMontaCols(aColsConv,nInOpc)

	If nInOpc == 3 // Incluir


	ElseIf nInOpc == 4 // Alterar

		BeginSql Alias 'QZD6'
          SELECT ZD6_CODPRF,ZD6_PRODUT,ZD6_PRUNFE,ZD6_PRUSRV,ZD6_PERC,R_E_C_N_O_ ZD6RECNO           
            FROM %Table:ZD6% ZD6
           WHERE ZD6.ZD6_FILIAL = %Exp:xFilial("ZD6")%
		     AND ZD6_CODTAB = %Exp:(cAliasZD6)->ZD6_CODTAB%
			 AND ZD6_FORNEC = %Exp:(cAliasZD6)->ZD6_FORNEC%
			 AND ZD6_LOJA   = %Exp:(cAliasZD6)->ZD6_LOJA% 
             AND ZD6.%notDel% 		  
		EndSql

		While QZD6->(!Eof())

			Aadd(aColsConv,{;
			/*01*/QZD6->ZD6_CODPRF,;
            /*02*/QZD6->ZD6_PRODUT,;
		    /*03*/AllTrim( GetAdvFVal( "SB1", "B1_DESC" , xFilial("SB1")+QZD6->ZD6_PRODUT, 1, "" ) ),;
		    /*04*/QZD6->ZD6_PRUNFE,;
		    /*05*/QZD6->ZD6_PRUSRV,;
		    /*06*/QZD6->ZD6_PERC,;
		    /*07*/QZD6->ZD6RECNO,;
				.F.})
			DbSelectArea("QZD6")
			DbSkip()
		Enddo
		QZD6->(DbCloseArea())

	Endif

	If Len(aColsConv) == 0

		Aadd(aColsConv,Array(8))
		aColsConv[Len(aColsConv)][1]	:= Space(TamSX3("ZD6_CODPRF")[1])
		aColsConv[Len(aColsConv)][2]	:= Space(TamSX3("ZD6_PRODUT")[1])
		aColsConv[Len(aColsConv)][3]	:= Space(TamSX3("B1_DESC")[1])
		aColsConv[Len(aColsConv)][4]	:= 0
		aColsConv[Len(aColsConv)][5]	:= 0
		aColsConv[Len(aColsConv)][6]	:= 0
		aColsConv[Len(aColsConv)][7]	:= 0
		aColsConv[Len(aColsConv)][8]	:= .F.
	Endif

	aSort(aColsConv,,,{|x,y| x[1]+[2] < y[1]+[2]})

Return


/*/{Protheus.doc} sfGravaConv
(Grava os dados da tela)
@author MarceloLauschner
@since 02/07/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfGravaConv()

	Local	nX

	For nX := 1 To Len(oConvGet:aCols)
		If !oConvGet:aCols[nX,Len(oConvGet:aHeader)+1]
			sfUpdate(nX)
		Else
			sfDelete(nX)
		Endif
	Next

	ConfirmSX8()

Return

/*/{Protheus.doc} XMLCNVCG
(Validação da digitação dos campos)
@author MarceloLauschner
@since 02/07/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFATA67A(nInOpc)

	Local		lRet		:= NaoVazio()
	Local		aAreaOld	:= GetArea()
	Local		nX

	If ReadVar() == "M->ZD6_CODPRF"
		lRet	:= .T.

		BeginSql Alias 'QSA5'
          SELECT A5_PRODUTO,B1_DESC
            FROM %Table:SA5% A5 , %Table:SB1%  B1 
           WHERE A5_FILIAL = %Exp:xFilial("SA5")%
		     AND A5_FORNECE = %Exp:cZD6FORNEC%
			 AND A5_LOJA    = %Exp:cZD6LOJA% 
			 AND A5_CODPRF = %Exp:M->ZD6_CODPRF%
             AND A5.%notDel%
			 AND B1_FILIAL = %Exp:xFilial("SB1")%
			 AND B1_COD = A5_PRODUTO 
			 AND B1.%NotDel%
		EndSql

		If QSA5->(!Eof())
			oConvGet:aCols[oConvGet:nAt,2]	:= QSA5->A5_PRODUTO
			oConvGet:aCols[oConvGet:nAt,3]	:= QSA5->B1_DESC
		Else
			lRet 	:= .F.
		Endif
		QSA5->(DbCloseArea())

		If lRet 
			

			For nX := 1 To Len(oConvGet:aCols)
				If !oConvGet:aCols[nX,Len(oConvGet:aHeader)+1] .And. nX # oConvGet:nAt
					If oConvGet:aCols[nX,1] ==  M->ZD6_CODPRF
						MsgAlert("Combinação já informado nesta tela na linha '"+cValToChar(nX)+"'",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
						lRet	:= .F.
					Endif
				Endif
			Next
		Endif

	ElseIf ReadVar() == "M->ZD6_PRODUT"
		lRet	:= .T.

		BeginSql Alias 'QSA5'
          SELECT A5_PRODUTO,B1_DESC,A5_CODPRF 
            FROM %Table:SA5% A5 , %Table:SB1%  B1 
           WHERE A5_FILIAL = %Exp:xFilial("SA5")%
		     AND A5_FORNECE = %Exp:cZD6FORNEC%
			 AND A5_LOJA    = %Exp:cZD6LOJA% 
			 AND A5_PRODUTO = %Exp:M->ZD6_PRODUT%
             AND A5.%notDel%
			 AND B1_FILIAL = %Exp:xFilial("SB1")%
			 AND B1_COD = A5_PRODUTO 
			 AND B1.%NotDel%
		EndSql

		If QSA5->(!Eof())
			oConvGet:aCols[oConvGet:nAt,1]	:= QSA5->A5_CODPRF
			oConvGet:aCols[oConvGet:nAt,2]	:= QSA5->A5_PRODUTO
			oConvGet:aCols[oConvGet:nAt,3]	:= QSA5->B1_DESC
		Else
			lRet 	:= .F.
		Endif
		QSA5->(DbCloseArea())

		If lRet
			For nX := 1 To Len(oConvGet:aCols)
				If !oConvGet:aCols[nX,Len(oConvGet:aHeader)+1] .And. nX # oConvGet:nAt
					If oConvGet:aCols[nX,2] ==  M->ZD6_PRODUT
						MsgAlert("Combinação já informado nesta tela na linha '"+cValToChar(nX)+"'",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
						lRet	:= .F.
					Endif
				Endif
			Next
		Endif
		

	ElseIf ReadVar() == "M->ZD6_PRUNFE"
		lRet	:= .T.

		If oConvGet:aCols[oConvGet:nAt,5] > 0 
			oConvGet:aCols[oConvGet:nAt,6]	:= 100 - Round((M->ZD6_PRUNFE / oConvGet:aCols[oConvGet:nAt,5]  ) * 100 ,6)
		Endif 

	ElseIf ReadVar() == "M->ZD6_PRUSRV"
		lRet	:= .T.
		If oConvGet:aCols[oConvGet:nAt,4] > 0 
			oConvGet:aCols[oConvGet:nAt,6]	:= 100 - Round((oConvGet:aCols[oConvGet:nAt,4] / M->ZD6_PRUSRV  ) * 100 ,6)
		Endif 

	ElseIf ReadVar() == "M->ZD6_PERC"
		lRet	:= .T.
		If oConvGet:aCols[oConvGet:nAt,5] > 0 
			oConvGet:aCols[oConvGet:nAt,4]	:= oConvGet:aCols[oConvGet:nAt,5] - Round(oConvGet:aCols[oConvGet:nAt,5] *  M->ZD6_PERC / 100 , 6 )
		ElseIf oConvGet:aCols[oConvGet:nAt,4] > 0 
			oConvGet:aCols[oConvGet:nAt,5]	:= Round(oConvGet:aCols[oConvGet:nAt,4] / ( 100 -  M->ZD6_PERC ) , 6 )
		Endif 
	ElseIf ReadVar()  == "DDTVIGINI" .Or. ReadVar()  == "DDTVIGFIM" .Or. ReadVar()  == "CZD6FORNEC" .Or. ReadVar()  == "CZD6LOJA" 

		BeginSql Alias 'QD6'
		   SELECT ZD6_CODTAB         
		     FROM %Table:ZD6% ZD6
			WHERE ZD6.ZD6_FILIAL = %Exp:xFilial("ZD6")%
			  AND ZD6_CODTAB <> %Exp:cZD6CODTAB%
			  AND ZD6_FORNEC = %Exp:cZD6FORNEC%
			  AND ZD6_LOJA   = %Exp:cZD6LOJA% 
			  AND ZD6.%notDel% 		 
			  AND (ZD6_DTFIM >= %Exp:dDtVigIni% AND ZD6_DTINI <= %Exp:dDtVigFim%)
		EndSql

		If QD6->(!Eof())
			MsgAlert("Período de vigência já encontrada na tabela '"+QD6->ZD6_CODTAB+"' ")
			lRet 	:= .F. 
		Endif 
		QD6->(DbCloseArea())
	Endif

	RestArea(aAreaOld)
	

Return lRet


/*/{Protheus.doc} sfUpdate
//Função para fazer a atualização do número do Aviso na tabela de controle de integração 
@author Marcelo Alberto Lauschner
@since 07/07/2018
@version 1.0
@return Nil 
@param cNumAdvice, characters, Numero do aviso que será atualizado
@type Static Function
/*/
Static Function sfUpdate(nZ)

	DbSelectArea("ZD6")
	DbSetOrder(1)

	If !Empty(oConvGet:aCols[nZ,nPxRecno])
		DbGoto(oConvGet:aCols[nZ,nPxRecno])
		RecLock("ZD6",.F.)
		ZD6->ZD6_FILIAL 	:= xFilial("ZD6")
		ZD6->ZD6_CODPRF		:= oConvGet:aCols[nZ,1]
		ZD6->ZD6_PRODUT		:= oConvGet:aCols[nZ,2]
		ZD6->ZD6_PRUNFE		:= oConvGet:aCols[nZ,4]
		ZD6->ZD6_PRUSRV		:= oConvGet:aCols[nZ,5]
		ZD6->ZD6_PERC		:= oConvGet:aCols[nZ,6]
		ZD6->ZD6_CODTAB		:= cZD6CODTAB
		ZD6->ZD6_FORNEC		:= cZD6FORNEC
		ZD6->ZD6_LOJA		:= cZD6LOJA
		ZD6->ZD6_DTINI		:= dDtVigIni
		ZD6->ZD6_DTFIM    	:= dDtVigFim
		ZD6->(MsUnlock())
	Else
		RecLock("ZD6",.T.)
		ZD6->ZD6_FILIAL 	:= xFilial("ZD6")
		ZD6->ZD6_CODPRF		:= oConvGet:aCols[nZ,1]
		ZD6->ZD6_PRODUT		:= oConvGet:aCols[nZ,2]
		ZD6->ZD6_PRUNFE		:= oConvGet:aCols[nZ,4]
		ZD6->ZD6_PRUSRV		:= oConvGet:aCols[nZ,5]
		ZD6->ZD6_PERC		:= oConvGet:aCols[nZ,6]
		ZD6->ZD6_CODTAB		:= cZD6CODTAB
		ZD6->ZD6_FORNEC		:= cZD6FORNEC
		ZD6->ZD6_LOJA		:= cZD6LOJA
		ZD6->ZD6_DTINI		:= dDtVigIni
		ZD6->ZD6_DTFIM    	:= dDtVigFim
		ZD6->(MsUnlock())
	Endif

Return


/*/{Protheus.doc} sfDelete
//Função para deletar registro na tabela de controle de integração
@author Marcelo Alberto Lauschner
@since 07/07/2018
@version 1.0
@return Nil

@type function
/*/
Static Function sfDelete(nZ)

	DbSelectArea("ZD6")
	DbSetOrder(1)

	If !Empty(oConvGet:aCols[nZ,nPxRecno])
		DbGoto(oConvGet:aCols[nZ,nPxRecno])
		RecLock("ZD6",.F.)
		ZD6->(DBDelete())
		ZD6->(MsUnlock())
	Endif

Return
