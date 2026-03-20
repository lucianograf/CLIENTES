#Include 'Totvs.ch'
 
//-------------------------------------------------------------------
/*/{Protheus.doc} RLESTR01
Relatorio de Conferencia de fechamento de estoque
Kardex x SB9 ou Kardex x SB2(B2_QFIM)

@author Júnior
@since 23/02/18
@version 1.0
/*/
//-------------------------------------------------------------------
User Function RLESTR01()

Local oReport := Nil

//--------------------------
// Interface de impressao
//--------------------------
oReport:= ReportDef()
oReport:PrintDialog()

Return NIL
//-------------------------------------------------------------------
/*/{Protheus.doc} ReportDef
Definicoes do relatorio

@author Felipe Nunes de Toledo
@since 06/11/14
@version 1.0

@return oReport  -> Objeto TRepor com as definicoes do relatorio
/*/
//-------------------------------------------------------------------
Static Function ReportDef()

Local oReport    := Nil
Local oSection1  := Nil                                       
Local cPerg      := PADR("RLESTR01",Len("X1_GRUPO"))
Local cAliasQry  := GetNextAlias()
Local cPictQtd   := PesqPict('SB2','B2_QFIM')
Local cPictCus   := PesqPict('SB2','B2_VFIM1')
Local nTamQtd    := TamSx3('B2_QFIM' )[1]
Local nTamCus    := TamSx3('B2_VFIM1')[1]

oReport := TReport():New('RLESTR01','Conferência do saldo Kardex x SB9/SB2(QFIM).',cPerg, {|oReport| ReportPrint(@oReport,@cAliasQry)},'Este relatório exibe o saldo Kardex x Saldo SB9 ou SB2(QFIM)')
oReport:SetPortrait() //-- modo retrato

AjustaSx1(cPerg)
Pergunte(cPerg,.F.)

oSection1 := TRSection():New(oReport,"Descrição Genérica do Produto",{"SB1"},Nil, .F., .F.)

TRCell():New( oSection1,'B2_FILIAL'    , ,'FL'           ,/*Picture*/,/*nTam*/,/*lPixel*/,{ || (cAliasQry)->FILIAL       } )
TRCell():New( oSection1,'B2_COD'       , ,'PRODUTO'      ,/*Picture*/,/*nTam*/,/*lPixel*/,{ || (cAliasQry)->COD          } )
TRCell():New( oSection1,'B1_DESC'      , ,'DESCRIÇÃO'    ,/*Picture*/,/*nTam*/,/*lPixel*/,{ || (cAliasQry)->B1_DESC      } )
TRCell():New( oSection1,'B1_TIPO'      , ,'TP'           ,/*Picture*/,/*nTam*/,/*lPixel*/,{ || (cAliasQry)->B1_TIPO      } )
TRCell():New( oSection1,'B2_LOCAL'     , ,'ARMZ'         ,/*Picture*/,/*nTam*/,/*lPixel*/,{ || (cAliasQry)->LOCAL        } )
TRCell():New( oSection1,'B1_UM'        , ,'UM'           ,/*Picture*/,/*nTam*/,/*lPixel*/,{ || (cAliasQry)->B1_UM        } )
TRCell():New( oSection1,'Doc'          , ,'DOC'          ,/*Picture*/,15,/*lPixel*/,{ || (cAliasQry)->DOCUMENTO    } )
TRCell():New( oSection1,'Emissao'      , ,'EMISSAO'      ,/*Picture*/,/*nTam*/,/*lPixel*/,{ || STOD((cAliasQry)->EMISSAO)      } )
TRCell():New( oSection1,'QTENT'        , ,'ENTRADA'      ,cPictQtd   ,nTamQtd ,/*lPixel*/,{ || (cAliasQry)->QTD_ENT   } )
TRCell():New( oSection1,'QTSAI'        , ,'SAIDA'        ,cPictQtd   ,nTamQtd ,/*lPixel*/,{ || (cAliasQry)->QTD_SAI   } )
//TRCell():New( oSection1,'CUSKARD'      , ,'CUSTO KARDEX' ,cPictCus   ,nTamCus ,/*lPixel*/,{ || (cAliasQry)->CUSTO_KARDEX } )
TRCell():New( oSection1,'SALDO'        , ,'SALDO'          ,cPictQtd   ,nTamQtd ,/*lPixel*/,{ || CalcEst((cAliasQry)->COD ,(cAliasQry)->LOCAL, datavalida(STOD((cAliasQry)->EMISSAO) + 1)   )[1] } ) //CalcEst((cAliasQry)->COD ,(cAliasQry)->LOCAL, STOD((cAliasQry)->EMISSAO)   )[1]  
//TRCell():New( oSection1,'CUSFECHA'     , ,'CUSTO.FECHA'  ,cPictCus   ,nTamCus ,/*lPixel*/,{ || If(mv_par07==1, SB2->B2_VFIM1, SB9->B9_VINI1) } )
//TRCell():New( oSection1,'QTDDIF'       , ,'DIF. QTD'     ,cPictQtd   ,nTamQtd ,/*lPixel*/,{ || (cAliasQry)->QTD_KARDEX - If(mv_par07==1,SB2->B2_QFIM,SB9->B9_QINI) } )

oSection1:SetNoFilter( {'SB1'} )

Return(oReport)
//-------------------------------------------------------------------
/*/{Protheus.doc} ReportPrint
Impressao do relatorio 

@param   oReport        Objeto TReport
@param   cAliasQry      Alias da Query do Relatorio

@author Júnior Conte
@since 23/02/2018
@version 1.0
/*/
//-------------------------------------------------------------------
Static Function ReportPrint(oReport, cAliasQry)

Local oSection1  := oReport:Section(1)
Local dUlFecha   := Ctod( "01/01/80","ddmmyy" )
Local dDataIni   := mv_par07 //Ctod( "01/01/80","ddmmyy" )
Local dDataFim   := mv_par08

//-- Data do Fechamento Anterior
dUlFecha := LastDtB9(dDataIni)
//-- Data Inicial dos Movimentos
dDataIni := dUlFecha+1

//-- Adiciona a Data do Saldo no Titulo das Colunas
//oSection1:Cell('QTDENT'):SetTitle('QTDENT' +  CHR(13)+CHR(10) + '(' + DtoC(dDataFim) + ')')
//oSection1:Cell('CUSKARD'):SetTitle('CUS.KARDEX' +  CHR(13)+CHR(10) + '(' + DtoC(dDataFim) + ')')

//-------------------------------------------------------------
// Converte os parametros do tipo range, para um range cheio,
// caso o conteudo do parametro esteja vazio
//-------------------------------------------------------------
FullRange(oReport:uParam)
//---------------------------------------------
// Transforma parametros Range em expressao SQL
//---------------------------------------------
MakeSqlExpr(oReport:uParam)

//-----------------------------------------
// Query do Relatorio
//-----------------------------------------
BEGIN REPORT QUERY oSection1
BeginSql Alias cAliasQry
	SELECT  FILIAL, COD, B1_DESC, CAMPO1, B1_TIPO, B1_UM, LOCAL, DOCUMENTO, EMISSAO,  SUM(QTDENT) QTD_ENT,SUM(QTDSAI) QTD_SAI, SUM(CUSTO) CUSTO_KARDEX	         
	  FROM (
           /*SALDO INICIAL*/
	       SELECT R_E_C_N_O_  CAMPO1,  B9_FILIAL FILIAL, B9_COD COD, B9_LOCAL LOCAL, "" DOCUMENTO, "" EMISSAO,  B9_QINI QTDENT, 0 QTDSAI,  B9_VINI1 CUSTO 
	         FROM %table:SB9% SB9
	        WHERE SB9.B9_FILIAL  BETWEEN %Exp:mv_par01% AND  %Exp:mv_par02%
	          AND SB9.B9_LOCAL   BETWEEN %Exp:mv_par03% AND  %Exp:mv_par04%
	          AND SB9.B9_COD     BETWEEN %Exp:mv_par05% AND  %Exp:mv_par06%
	          AND SB9.B9_DATA    = %Exp:DtoS(dUlFecha)%
	          AND SB9.%NotDel%
	 
	        UNION 
	          ALL
	
           /* MOV. INTERNO ENTRADA*/
           SELECT R_E_C_N_O_  CAMPO1, D3_FILIAL FILIAL, D3_COD COD, D3_LOCAL LOCAL, D3_DOC DOCUMENTO, D3_EMISSAO EMISSAO,  SUM(D3_QUANT) QTDENT, SUM(0) QTDSAI,SUM(D3_CUSTO1) CUSTO 
             FROM %table:SD3% SD3
            WHERE SD3.D3_FILIAL  BETWEEN %Exp:mv_par01% AND  %Exp:mv_par02%
              AND SD3.D3_LOCAL   BETWEEN %Exp:mv_par03% AND  %Exp:mv_par04%
              AND SD3.D3_COD     BETWEEN %Exp:mv_par05% AND  %Exp:mv_par06%
              AND SD3.D3_EMISSAO BETWEEN %Exp:DtoS(dDataIni)% AND %Exp:DtoS(dDataFim)%
              AND SD3.D3_ESTORNO <> 'S'
              AND SD3.D3_TM <= 500 
              AND SD3.%NotDel%
            GROUP 
               BY    D3_FILIAL, D3_COD, D3_LOCAL, D3_DOC, D3_EMISSAO, R_E_C_N_O_
	
	        UNION 
	          ALL
	
           /* MOV. INTERNO SAIDA*/
           SELECT R_E_C_N_O_  CAMPO1, D3_FILIAL FILIAL, D3_COD COD, D3_LOCAL LOCAL, D3_DOC DOCUMENTO, D3_EMISSAO EMISSAO,SUM(0) QTDENT, - SUM(D3_QUANT) QTDSAI, - SUM(D3_CUSTO1) CUSTO                                                    
             FROM %table:SD3% SD3
            WHERE SD3.D3_FILIAL  BETWEEN %Exp:mv_par01% AND  %Exp:mv_par02%
              AND SD3.D3_LOCAL   BETWEEN %Exp:mv_par03% AND  %Exp:mv_par04%
              AND SD3.D3_COD     BETWEEN %Exp:mv_par05% AND  %Exp:mv_par06%
              AND SD3.D3_EMISSAO BETWEEN %Exp:DtoS(dDataIni)% AND %Exp:DtoS(dDataFim)%
              AND SD3.D3_ESTORNO <> 'S'
              AND SD3.D3_TM > 500
              AND SD3.%NotDel%
            GROUP 
               BY     D3_FILIAL, D3_COD, D3_LOCAL, D3_DOC, D3_EMISSAO, R_E_C_N_O_
	
	        UNION 
	          ALL
	
           /*DOC. ENTRADA*/   
           SELECT SD1.R_E_C_N_O_  CAMPO1, D1_FILIAL FILIAL, D1_COD COD, D1_LOCAL LOCAL, D1_DOC DOCUMENTO, D1_DTDIGIT EMISSAO, SUM(D1_QUANT) QTDENT,SUM(0) QTDSAI,  SUM(D1_CUSTO) CUSTO 
             FROM %table:SD1% SD1
            INNER 
             JOIN %table:SF4% SF4
               ON SF4.F4_FILIAL  = %xFilial:SF4%
              AND SF4.F4_CODIGO  = D1_TES
              AND SF4.F4_ESTOQUE = 'S'
              AND SF4.%NotDel%
            WHERE SD1.D1_FILIAL  BETWEEN %Exp:mv_par01% AND  %Exp:mv_par02%
              AND SD1.D1_LOCAL   BETWEEN %Exp:mv_par03% AND  %Exp:mv_par04%
              AND SD1.D1_COD     BETWEEN %Exp:mv_par05% AND  %Exp:mv_par06%
              AND SD1.D1_DTDIGIT BETWEEN %Exp:DtoS(dDataIni)% AND %Exp:DtoS(dDataFim)%
              AND SD1.D1_ORIGLAN <> 'LF'
              AND SD1.%NotDel%
            GROUP 
		       BY    D1_FILIAL, D1_COD, D1_LOCAL, D1_DOC, D1_DTDIGIT, SD1.R_E_C_N_O_ 
		
	        UNION 
	          ALL
	
           /*DOC. SAIDA*/  
           SELECT SD2.R_E_C_N_O_   CAMPO1, D2_FILIAL FILIAL, D2_COD COD, D2_LOCAL LOCAL, D2_DOC DOCUMENTO, D2_EMISSAO EMISSAO, SUM(0) QTDENT, - SUM(D2_QUANT) QTDSAI, - SUM(D2_CUSTO1) CUSTO          
             FROM %table:SD2% SD2
            INNER 
             JOIN %table:SF4% SF4 
               ON SF4.F4_FILIAL  = %xFilial:SF4%
              AND SF4.F4_CODIGO  = SD2.D2_TES
              AND SF4.F4_ESTOQUE = 'S'
              AND SF4.%NotDel%
            WHERE SD2.D2_FILIAL  BETWEEN %Exp:mv_par01% AND  %Exp:mv_par02%
              AND SD2.D2_LOCAL   BETWEEN %Exp:mv_par03% AND  %Exp:mv_par04%
              AND SD2.D2_COD     BETWEEN %Exp:mv_par05% AND  %Exp:mv_par06%
              AND SD2.D2_EMISSAO BETWEEN %Exp:DtoS(dDataIni)% AND %Exp:DtoS(dDataFim)%
              AND SD2.D2_ORIGLAN <> 'LF'
              AND SD2.%NotDel%
            GROUP 
               BY   D2_FILIAL, D2_COD, D2_LOCAL, D2_DOC, D2_EMISSAO, SD2.R_E_C_N_O_ 
           ) TRB                      
     INNER
      JOIN %table:SB1% SB1
        ON SB1.B1_FILIAL = %xFilial:SB1%
       AND SB1.B1_COD    = TRB.COD
       AND SB1.%NotDel%  
       
	 GROUP 
	    BY  FILIAL, COD, B1_DESC,   B1_TIPO, B1_UM, LOCAL, DOCUMENTO, EMISSAO, CAMPO1
	 ORDER 
	    BY  FILIAL, COD, LOCAL, EMISSAO, CAMPO1
EndSql 
END REPORT QUERY oSection1

/*
If mv_par07 == 1 //-- Mov. x B2_QFIM
	//-- Define o Titulo do Relatorio
	oReport:SetTitle('Conferência do Saldo Movimento x B2_QFIM')
	
	//-- Define titulos das colunas
  //	oSection1:Cell('QTDFECHA'):SetTitle('B2_QFIM'  )
	//oSection1:Cell('CUSFECHA'):SetTitle('B2_VFIM1' )
	
	//----------------------------------------------------------------------
	// Posiciona em um registro de uma outra tabela. O posicionamento sera
	// realizado antes da impressao de cada linha do relatorio.
	//----------------------------------------------------------------------
	TRPosition():New(oSection1,'SB2',1,{|| (cAliasQRY)->FILIAL + (cAliasQRY)->COD + (cAliasQRY)->LOCAL})
	
	//-- Lista Somente Divergentes
	If MV_PAR09 == 2
	  //	oSection1:SetLineCondition({|| (cAliasQry)->QTD_KARDEX <> SB2->B2_QFIM  })
	EndIf
Else //--Mov. x B9_QINI
	//-- Define o Titulo do Relatorio
	oReport:SetTitle('Conferência do Saldo Movimento x SB9')
	
	//-- Define titulos das colunas
	//oSection1:Cell('QTDFECHA'):SetTitle('B9_QINI'  +  CHR(13)+CHR(10) + '(' + DtoC(dDataFim) + ')')
	//oSection1:Cell('CUSFECHA'):SetTitle('B9_VINI1' +  CHR(13)+CHR(10) + '(' + DtoC(dDataFim) + ')')
	
	//----------------------------------------------------------------------
	// Posiciona em um registro de uma outra tabela. O posicionamento sera
	// realizado antes da impressao de cada linha do relatorio.
	//----------------------------------------------------------------------
	TRPosition():New(oSection1,'SB9',1,{|| (cAliasQRY)->FILIAL + (cAliasQRY)->COD + (cAliasQRY)->LOCAL + DtoS(dDataFim)})
	
	//-- Lista Somente Divergentes
	If MV_PAR09 == 2
	  //	oSection1:SetLineCondition({|| (cAliasQry)->QTD_KARDEX <> SB9->B9_QINI  })
	EndIf
EndIf
 */
//------------------------
// Impressao do Relatorio
//------------------------
oSection1:Print()

Return Nil
//-------------------------------------------------------------------
/*/{Protheus.doc} LastDtB9
Retorna a Data do Fechamento anterior a data de refencia indicada
no parametro do relatorio

@author Júnior Conte
@since 23/02/2018
@version 1.0

@return dRet     -> Data do Fechamento Anterior a Data de Referencia
/*/
//-------------------------------------------------------------------
Static Function LastDtB9(dDataFim)
Local dRet       := Ctod( "01/01/80","ddmmyy" )
Local cAliasSB9  := GetNextAlias()

BeginSql Alias cAliasSB9
	COLUMN B9_DATA AS DATE

	SELECT MAX(B9_DATA) B9_DATA
	  FROM %table:SB9% SB9
	 WHERE
	       SB9.B9_FILIAL  BETWEEN %Exp:mv_par01% AND  %Exp:mv_par02%
	   AND SB9.B9_LOCAL   BETWEEN %Exp:mv_par03% AND  %Exp:mv_par04%
	   AND SB9.B9_COD     BETWEEN %Exp:mv_par05% AND  %Exp:mv_par06%
	   AND SB9.B9_DATA    < %Exp:DtoS(dDataFim)%
	   AND SB9.%NotDel%
EndSql

If (cAliasSB9)->(!Eof())
	dRet := (cAliasSB9)->B9_DATA
EndIf

DbSelectArea(cAliasSB9)
DbCloseArea()

Return(dRet)
//-------------------------------------------------------------------
/*/{Protheus.doc} AjustaSX1
Ajusta as perguntas do SX1

@param   cPerg        Nome do grupo de Perguntas (X1_GRUPO)

@author Júnior Conte
@since 23/02/2018
@version 1.0
/*/
//-------------------------------------------------------------------
Static Function AjustaSX1(cPerg)
Local aAreaAnt := GetArea()
Local aHelpPor := {}
Local aHelpEng := {}
Local aHelpSpa := {}

//-------------------------------------------------------------------
// Variaveis utilizadas para parametros
// mv_par01 - Da Filial
// mv_par02 - Ate Filial
// mv_par03 - Do Armazem
// mv_par04 - Ate o Armazem
// mv_par05 - Do Produto
// mv_par06 - Ate o Produto
// mv_par07 - Sld.a Comparar (1=Mov. x B2_QFIM,2=Mov. x B9_QINI)
// mv_par08 - Data de Referencia
// mv_par09 - Lista somente Divergente
//-------------------------------------------------------------------

//---------------------------------------MV_PAR01--------------------------------------------------
//aHelpPor := {"Informe a Filial inicial a ser considerada ","na filtragem do relatorio"}
//PutSX1(cPerg,"01","Da Filial","","","mv_ch1","C",Len(SB2->B2_FILIAL),0,0,"G","","","","","mv_par01","","","","","","","","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa)
	
//---------------------------------------MV_PAR02--------------------------------------------------
//aHelpPor := {"Informe a Filial final a ser considerado ","na filtragem do relatorio"}
//PutSX1(cPerg,"02","Ate a Filial","","","mv_ch2","C",Len(SB2->B2_FILIAL),0,0,"G","","","","","mv_par02","","","","","","","","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa)

//---------------------------------------MV_PAR03--------------------------------------------------
//aHelpPor := {"Informe o Armazem inicial a ser       ","considerado na filtragem do relatorio."}
//PutSX1(cPerg,"03","Do Armazem","","","mv_ch3","C",Len(SB2->B2_LOCAL),0,1,"G","","","","","mv_par03","","","","","","","","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa)

//---------------------------------------MV_PAR04--------------------------------------------------
//aHelpPor := {"Informe o Armazem final a ser         ","considerado na filtragem do relatorio."}
//PutSX1(cPerg,"04","Ate o Armazem ?","","","mv_ch4","C",Len(SB2->B2_LOCAL),0,1,"G","","","","","mv_par04","","","","","","","","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa)

//---------------------------------------MV_PAR05--------------------------------------------------
//aHelpPor := {"Informe o Produto inicial a ser       ","considerado na filtragem do relatorio."}
//PutSX1(cPerg,"05","Do Produto","","","mv_ch5","C",Len(SB1->B1_COD),0,0,"G","","SB1","","","mv_par05","","","","","","","","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa)

//---------------------------------------MV_PAR06--------------------------------------------------
//aHelpPor := {"Informe o Produto final a ser         ","considerado na filtragem do relatorio."}
//PutSX1(cPerg,"06","Ate o Produto","","","mv_ch6","C",Len(SB1->B1_COD),0,0,"G","","SB1","","","mv_par06","","","","","","","","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa)

//---------------------------------------mv_par08--------------------------------------------------
//aHelpPor := {"Informe a data Inicial."}
//PutSX1(cPerg,"07","Data Inicial","","","mv_ch7","D",8,0,0,"G","","","","","mv_par07","","","","","","","","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa)

//---------------------------------------mv_par08--------------------------------------------------
//aHelpPor := {"Informe a data de referencia do Saldo."}
//PutSX1(cPerg,"08","Data Final  ","","","mv_ch8","D",8,0,0,"G","","","","","mv_par08","","","","","","","","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa)

//---------------------------------------MV_PAR09--------------------------------------------------
/*
aHelpPor := {"Informe quais itens a serem      ","apresentados no relatorio                  "}
PutSX1(cPerg,"09","Listas quais itens","","","mv_ch9","N",1,0,0,"C","","","","","mv_par09","Todos","Todos","Todos","","Divergentes","Divergentes","Divergentes","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa)
*/
//---------------------------------------MV_PAR05--------------------------------------------------  
/*
aHelpPor := {"Informe o Cliente inicial a ser       ","considerado na filtragem do relatorio."}
PutSX1(cPerg,"10","Do Cliente","","","mv_ch10","C",Len(SA1->A1_COD),0,0,"G","","SA1","","","mv_par10","","","","","","","","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa)

//---------------------------------------MV_PAR06--------------------------------------------------
aHelpPor := {"Informe o Cliente final a ser         ","considerado na filtragem do relatorio."}
PutSX1(cPerg,"11","Ate o Cliente","","","mv_ch11","C",Len(SA1->A1_COD),0,0,"G","","SA1","","","mv_par11","","","","","","","","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa)
*/

RestArea(aAreaAnt)
Return Nil
