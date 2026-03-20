#INCLUDE "topconn.ch"
#include "RWMAKE.CH"  
#include "PROTHEUS.CH" 


/*/{Protheus.doc} MLFATC07
//TODO Tela+Rotina Analise e liberação de estoques para faturament
@author Heitor do Santos - Melhoria - Marcelo Alberto Lauschner
@since 25/06/2012
@version 1.0
@return ${return}, ${return_description}
@param lOutOk, logical, descricao
@type function
/*/
User Function MLFATC07(lOutOk)

	Local cFil			:= SC5->C5_FILIAL
	Local cNum			:= SC5->C5_NUM
	Local oGetItens	
	Local _Carga
	Local nTmX    		:= 800
	Local nTmY    		:= 40
	Local nTmHLin 		:= 374 
	Local nValFat 		:= 0
	Local nValPed 		:= 0
	Local nAltTel 		:= 620
	

	Private cCliente	:=""
	Private cCondPag	:=""
	Private cTabPreco	:=""
	Private cVend1		:=""
	Private cVend2		:=""
	Private cCodVend1	:=""
	Private cCodVend2	:=""
	Private nTotFlex    := 0
	Private lVldPed     := .F.
	Private nVlRgFl     := 0 
	Private nSumQtdVen 	:= 0
	
	Private oDlg := Nil

	Default	lOutOk		:= .T. 
 
	
	// Busca os valores da tabela ZCC que controlam o FLEX
	lVldPed := .F.
	nValFat := 0
	nValPed := 0
	nVlRgFl := 0
	if  cEmpAnt $"01#02" 
		nValFat := U_xVALCTR('F')
		nValPed := U_xVALCTR('P')
		nSalIni := U_xVALCTR('I')
		nTotFlex := (nSalIni+nValFat) + nValPed
	endif


	_Carga	:=	sfPreenc(cFil,cNum,@lOutOk)

	// Vetor com elementos do Browse		
	aCols :=_Carga[1]

	If Len(aCols)==0
		MsgInfo("Pedido sem liberacao ou faturado!")
		Return
	Endif

	DEFINE DIALOG oDlg TITLE "MLFATC07 - Status do Pedido" FROM 1,1 TO 560,1350 PIXEL		//DEFINE DIALOG oDlg TITLE "Documentos em espera" FROM 180,180 TO 550,700 PIXEL
	
	aHeader := {} 
	// 			   01-Titulo	,02-Campo		,03-Picture					,04-Tamanho   				, 05-Decimal			, 06-Valid	, 07-Usado	, 08-Tipo		, 09-F3		, 10-Contexto	, 11-ComboBox	, 12-Relacao	, 13-When		, 14-Visual	, 15-Valid Usuario
	AADD(aHeader,{ " " 			,"IMG"   		,"@BMP"						,2							,0						,"","","C","", "","","","","V" } )
	AADD(aHeader,{ "Status"   	,"STATUS"   	,""							,14						,0	,"","","C","", "","","","","V" } )
	AADD(aHeader,{ "Item"   	,"ITEM"   		,""							,3							,0	,"","","C","", "","","","","V" } )
	AADD(aHeader,{ "Produto"    ,"C6_PRODUTO"  	,""							,8							,0	,"","","C","", "","","","","V" } )
	AADD(aHeader,{ "Descrição"  ,"DESCRI" 		,""							,35	,TamSx3("C6_DESCRI")[2]	,"","","C","", "","","","","V" } )
	AADD(aHeader,{ "Estoque"  	,"ESTOQUE" 		,"@E 999,999"				,7							,0	,,"","N","", "","","","","V" } )
	AADD(aHeader,{ "Qtd.Orig"  	,"QTDVEN" 		,"@E 999,999"				,7							,0	,,"","N","", "","","","","V" } )
	AADD(aHeader,{ "Um"  		,"UM"   		,""							,TamSx3("C6_UM")[1]			,TamSx3("C6_UM")[2]		,"","","C","", "","","","","V" } )                          
	AADD(aHeader,{ "Qtd.Pend"  	,"SALDO" 		,"@E 999,999"				,7							,0	,,"","N","", "","","","","V" } )
	AADD(aHeader,{ "Qtd.Lib"  	,"QTDLIB" 		,"@E 999,999"				,7							,0	,,"","N","", "","","","","V" } )
	AADD(aHeader,{ "Dt.Lib"  	,"DTLIB" 		,PesqPict("SC5","C5_EMISSAO") ,TamSx3("C5_EMISSAO")[1]	,TamSx3("C5_EMISSAO")[2]	,,"","D","", "","","","","V" } )
	AADD(aHeader,{ "Preço Tabela"  ,"C6_PRUNIT"	,"@E 999,999.99"			 ,8 						,2						,,"","N","", "","","","","V" } )
	AADD(aHeader,{ "Preço Cliente"   ,"C6_PREGRA"	,"@E 999,999.99"			 ,8							,2						,,"","N","", "","","","","V" } )
	AADD(aHeader,{ "Preço Venda"   ,"C6_PRCVEN"	,"@E 999,999.99"			 ,8							,2						,,"","N","", "","","","","V" } )
	AADD(aHeader,{ "% Desconto"    ,"C6_DESCONT"	,PesqPict("SC6","C6_DESCONT") ,TamSx3("C6_DESCONT")[1]	,TamSx3("C6_DESCONT")[2]	,,"","N","", "","","","","V" } )
	AADD(aHeader,{ "Status Desc","IMG"   		,"@BMP"						,2							,0						,"","","C","", "","","","","V" } )
/*
	AADD(aHeader,{ " " 			,"IMG"   		,"@BMP"						,2							,0						,"","","C","", "","","","","V" } )
	AADD(aHeader,{ "Status"   	,"STATUS"   	,""							,20							,0	,"","","C","", "","","","","V" } )
	AADD(aHeader,{ "Item"   	,"ITEM"   		,""							,TamSx3("C6_ITEM")[1]		,TamSx3("C6_ITEM")[2]	,"","","C","", "","","","","V" } )
	AADD(aHeader,{ "Produto"    ,"C6_PRODUTO"  	,""							,15,TamSx3("C6_PRODUTO")[2]	,"","","C","", "","","","","V" } )
	AADD(aHeader,{ "Descrição"  ,"DESCRI" 		,""							,35	,TamSx3("C6_DESCRI")[2]	,"","","C","", "","","","","V" } )
	AADD(aHeader,{ "Estoque"  	,"ESTOQUE" 		,PesqPict("SC6","C6_QTDVEN"),TamSx3("C6_QTDVEN")[1]		,TamSx3("C6_QTDVEN")[2]	,,"","N","", "","","","","V" } )
	AADD(aHeader,{ "Qtd.Orig"  	,"QTDVEN" 		,PesqPict("SC6","C6_QTDVEN"),TamSx3("C6_QTDVEN")[1]		,TamSx3("C6_QTDVEN")[2]	,,"","N","", "","","","","V" } )
	AADD(aHeader,{ "Um"  		,"UM"   		,""							,TamSx3("C6_UM")[1]			,TamSx3("C6_UM")[2]		,"","","C","", "","","","","V" } )                          
	AADD(aHeader,{ "Qtd.Pend"  	,"SALDO" 		,PesqPict("SC6","C6_QTDVEN"),TamSx3("C6_QTDVEN")[1]		,TamSx3("C6_QTDVEN")[2]	,,"","N","", "","","","","V" } )
	AADD(aHeader,{ "Qtd.Lib"  	,"QTDLIB" 		,PesqPict("SC6","C6_QTDVEN") ,TamSx3("C6_QTDVEN")[1]	,TamSx3("C6_QTDVEN")[2]	,,"","N","", "","","","","V" } )
	AADD(aHeader,{ "Dt.Lib"  	,"DTLIB" 		,PesqPict("SC5","C5_EMISSAO") ,TamSx3("C5_EMISSAO")[1]	,TamSx3("C5_EMISSAO")[2]	,,"","D","", "","","","","V" } )
	AADD(aHeader,{ "PrcTabela"  ,"C6_PRUNIT"	,"@E 999,999.99"				 ,9						,2						,,"","N","", "","","","","V" } )
	AADD(aHeader,{ "PrcVenda"   ,"C6_PRCVEN"		,"@E 999,999.99"				 ,9						,2						,,"","N","", "","","","","V" } )
	AADD(aHeader,{ "Desconto"  	,"C6_DESCONT"	,PesqPict("SC6","C6_DESCONT") ,TamSx3("C6_DESCONT")[1]	,TamSx3("C6_DESCONT")[2]	,,"","N","", "","","","","V" } )
	AADD(aHeader,{ "Status Desc","IMG"   		,"@BMP"						,2							,0						,"","","C","", "","","","","V" } )
*/
	cLinOk		:=	"AllwaysTrue"
	cTudoOk		:=	"AllwaysTrue"
	cFieldOk	:=	"AllwaysTrue"
	cSuperDel	:=	"AllwaysTrue"
	cDelOk		:=	"AllwaysTrue" 
	nFreeze 	:= 	000 
	nMax		:=	300

	
	aCpoGDa		:=	{} 
	/*
		Saldo Anterior := Soma de Todos os faturamentos do vendedor no mês
		Valor do Pedido := Valor do Pedido 
		Saldo Final     := Pedido mais total

	*/
	oGetItens	:=	MsNewGetDados():New(01,01,200,700, GD_UPDATE,;								
	cLinOk,cTudoOk,nil,aCpoGDa,nFreeze,nMax,cFieldOk, cSuperDel,;						   
	cDelOk, oDLG, aHeader, aCols)

	Private oFontTitulo := TFont():New("MS Sans Serif",,018,,.T.,,,,,.F.,.F.)

	@ 205,002 SAY "Pedido: " + cNum OF oDlg FONT oFontTitulo COLORS 16711680, 16777215 PIXEL

	@ 205,198 Say "Soma Quantidades: " + cValToChar(nSumQtdVen) OF oDlg FONT oFontTitulo COLORS 16711680, 16777215 PIXEL
	
	@ 205,nTmHLin SAY "Controle - FLEX "  OF oDlg FONT oFontTitulo COLORS 16711680, 16777215 PIXEL
	
	@ 220,002 SAY "Cliente: "+cCliente SIZE 200,7 OF oDlg PIXEL 
											
	@ 220,nTmHLin SAY "Saldo Anterior: R$ "+ TRANSFORM(nValFat,PesqPict("SC6","C6_PRCVEN")) SIZE 200,7 OF oDlg PIXEL 

	@ 230,002 SAY "Cond.Pag: "+cCondPag SIZE 150,7 OF oDlg PIXEL

	@ 230,nTmHLin SAY "Valor Pedido: R$ "+ TRANSFORM(nValPed,PesqPict("SC6","C6_PRCVEN")) SIZE 200,7 OF oDlg PIXEL 

	@ 240,002 SAY "Tab.Preco: "+cTabPreco SIZE 150,7 OF oDlg PIXEL
	@ 250,002 SAY "Cond: "+IIF(fBuscaDiag('6'),"Divergente", "OK") SIZE 150,10 OF oDlg FONT oFontTitulo COLORS IIF(fBuscaDiag('6'),CLR_RED, CLR_GREEN) PIXEL
	@ 260,002 SAY "Prazo: "+IIF(fBuscaDiag('7'),"Divergente", "OK") SIZE 150,10 OF oDlg FONT oFontTitulo COLORS IIF(fBuscaDiag('7'),CLR_RED, CLR_GREEN) PIXEL
	@ 270,002 SAY "Tabela: "+IIF(fBuscaDiag('8'),"Divergente", "OK") SIZE 150,10 OF oDlg FONT oFontTitulo COLORS IIF(fBuscaDiag('8'),CLR_RED, CLR_GREEN) PIXEL

	@ 270,198 SAY "Vendedor: "+IIF(fBuscaDiag('4'),"Vazio",IIF(fBuscaDiag('5'),"Divergente", "OK")) SIZE 150,10 OF oDlg FONT oFontTitulo COLORS IIF(fBuscaDiag('4'),CLR_YELLOW,IIF(fBuscaDiag('5'),CLR_RED, CLR_GREEN))  PIXEL
	@ 220,198 SAY "Vendedor 1: "+cCodVend1+" "+cVend1 SIZE 150,10 OF oDlg PIXEL
	@ 230,198 SAY "Vendedor 2: "+cCodVend2+" "+cVend2 SIZE 150,10 OF oDlg PIXEL

	@ 250,198 SAY "Parcela Minima: "+IIF(fBuscaDiag('2'),"Divergente", "OK") SIZE 150,10 OF oDlg FONT oFontTitulo COLORS IIF(fBuscaDiag('2'),CLR_RED, CLR_GREEN) PIXEL
	
	@ 260,nTmHLin SAY "Flex: " + IIF(fBuscaDiag('9'),"Divergente", " OK")  SIZE 150,10 OF oDlg FONT oFontTitulo COLORS IIF( fBuscaDiag('9'),CLR_RED, CLR_GREEN) PIXEL
	@ 250,nTmHLin SAY "Saldo Final: R$ " + TRANSFORM(nTotFlex,PesqPict("SC6","C6_PRCVEN")) SIZE 150,10 OF oDlg FONT oFontTitulo COLORS IIF( fBuscaDiag('9'),CLR_RED, CLR_BLUE) PIXEL
	@ 260,198 SAY "Pedido Minimo: "+IIF(fBuscaDiag('3'),"Divergente", "OK") SIZE 150,10 OF oDlg FONT oFontTitulo COLORS IIF(fBuscaDiag('3'),CLR_RED, CLR_GREEN) PIXEL
	
	
	// Cria Botoes com metodos básicos		

	TButton():New( 268, 102, "Cancelar", oDlg,{|| oDlg:End(),;			
	},40,010,,,.F.,.T.,.F.,,.F.,,,.F. )		

	ACTIVATE DIALOG oDlg CENTERED //VALID Valida(aBrowse,oBrowse:nAt)

Return 

Static Function fBuscaDiag(cTipo)
	Local cQry := ""
	Local cAlias	:= "TMPZDP"

	cQry := " SELECT TOP 1 ZDP_TIPO FROM " + RetSqlname("ZDP")
	cQry += " WHERE ZDP_FILIAL  = " + SC5->C5_FILIAL
	cQry += " AND ZDP_PEDIDO = " + SC5->C5_NUM
	cQry += " AND ZDP_REGRA='"+cTipo+"' ORDER BY R_E_C_N_O_ DESC"

	cQry := ChangeQuery(cQry)

	If Select( cAlias ) > 0
		(cAlias)->( dbCloseArea() )            
	Endif 
	
	TCQUERY cQry NEW ALIAS "TMPZDP"

	DbSelectArea(cAlias)

	if (cAlias)->(!Eof())
		If (cAlias)->ZDP_TIPO == "T"
			lRet := .F. //quando a regra for corrigida
		Else
			lRet := .T.
		endif
	else
		lRet := .F.
	Endif

return lRet
/*/{Protheus.doc} sfPreenc
Alimenta aCols com os registros que devem aparecer na tela
@type function
@version 
@author Marcelo Alberto Lauschner
@since 15/12/2020
@param cFil, character, param_description
@param cNum, character, param_description
@param lOutOk, logical, param_description
@return return_type, return_description
/*/
Static Function sfPreenc(cFil,cNum,lOutOk)

	Local _aFile	:= {}
	Local _aRet		:= {}
	Local cAlias	:= "TMPPED"
	Local nValLib	:= 0 
	Local nEstDisp	:= 0
	         
	
	dbSelectArea("SC5")
	dbSetOrder(1)
	dbSeek(xFilial("SC5")+cNum)

	cCliente	:= Alltrim(SC5->C5_CLIENTE)+"-"+SC5->C5_LOJACLI+"\ ("+Alltrim(POSICIONE("SA1",1,xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI,"A1_NOME"))+")"
	cCondPag	:= SC5->C5_CONDPAG + "("+Alltrim(POSICIONE("SE4",1,xFilial("SE4")+SC5->C5_CONDPAG,"E4_DESCRI"))+")"
	cTabPreco	:= SC5->C5_TABELA + "("+Alltrim(POSICIONE("DA0",1,xFilial("DA0")+SC5->C5_TABELA,"DA0_DESCRI"))+")"	
	cVend1		:= IIF(!EMPTY(SC5->C5_VEND1),POSICIONE("SA3",1,XFILIAL("SA3")+SC5->C5_VEND1,"A3_NOME"),"")
	cVend2		:= IIF(!EMPTY(SC5->C5_VEND2),POSICIONE("SA3",1,XFILIAL("SA3")+SC5->C5_VEND2,"A3_NOME"),"")
	cCodVend1		:= IIF(!EMPTY(SC5->C5_VEND1),(SC5->C5_VEND1),"")
	cCodVend2		:= IIF(!EMPTY(SC5->C5_VEND2),(SC5->C5_VEND2),"")

	If Select( cAlias ) > 0
		(cAlias)->( dbCloseArea() )            
	Endif 

	cQry := "SELECT C9_ITEM, C9_PRODUTO,C9_QTDLIB, C9_DATALIB,C6_ITEM,C6_PRODUTO,C6_BLQ,C6_LOCAL,C6_PRUNIT,((100-ISNULL(A1_DESC,0))*0.01 * C6_PRUNIT) AS C6_PREGRA, " 
	cQry += "       C9_BLEST,C9_BLCRED, C9_BLWMS, C9.R_E_C_N_O_ REC, "
	cQry += "       C6_DESCRI, C6_QTDVEN, C6_UM, C6_PRCVEN, C6_QTDVEN-C6_QTDENT SALDO,  
	cQry += "(SELECT TOP 1 ZDP_VALOR FROM " + RetSqlname("ZDP")+" WHERE ZDP_FILIAL  = C6_FILIAL 
	cQry += "	                     AND ZDP_PEDIDO = C6_NUM 
	cQry += "	                     AND ZDP_ITEM = C6_ITEM  
	cQry += "	                     AND ZDP_PRODUT = C6_PRODUTO ORDER BY R_E_C_N_O_ DESC) C6_DESCONT"
	cQry += " FROM " + RetSqlname("SC6")+" C6 INNER JOIN "+RetSqlname("SC9")+" C9 "
	cQry += "   ON (C9_FILIAL = C6_FILIAL AND C9_PEDIDO = C6_NUM AND C9_ITEM = C6_ITEM and C9_PRODUTO = C6_PRODUTO AND C9.D_E_L_E_T_ <> '*') " 
	cQry += " LEFT OUTER JOIN " + RetSqlname("SA1")+" SA1 ON (C6_CLI = A1_COD AND C6_LOJA = A1_LOJA AND SA1.D_E_L_E_T_ <> '*') "
	cQry += " WHERE C6_FILIAL = '"+cFil+"'  "
	cQry += "   AND C6_NUM = '"+cNum+"'  " 
	cQry += "   AND C6.D_E_L_E_T_ <> '*' " 
	cQry += "   AND C6_QTDENT < C6_QTDVEN "
	cQry += "UNION ALL"

	cQry += "SELECT C6_ITEM C9_ITEM, C6_PRODUTO C9_PRODUTO, 0 C9_QTDLIB, ' ' C9_DATALIB,C6_ITEM,C6_PRODUTO,C6_BLQ,C6_LOCAL,C6_PRUNIT,((100-ISNULL(A1_DESC,0))*0.01 * C6_PRUNIT) AS C6_PREGRA," 
	cQry += "       '  ' C9_BLEST,'  ' C9_BLCRED, '  ' C9_BLWMS, 0 REC, "
	cQry += "       C6_DESCRI, C6_QTDVEN, C6_UM, C6_PRCVEN, C6_QTDVEN-C6_QTDENT SALDO,  
	cQry += "(SELECT TOP 1 ZDP_VALOR FROM " + RetSqlname("ZDP")+"  WHERE ZDP_FILIAL  = C6_FILIAL 
	cQry += "	                     AND ZDP_PEDIDO = C6_NUM 
	cQry += "	                     AND ZDP_ITEM = C6_ITEM  
	cQry += "	                     AND ZDP_PRODUT = C6_PRODUTO ORDER BY R_E_C_N_O_ DESC) C6_DESCONT"
	cQry += " FROM " + RetSqlname("SC6")+" C6 "
	cQry += " LEFT OUTER JOIN " + RetSqlname("SA1")+" SA1 ON (C6_CLI = A1_COD AND C6_LOJA = A1_LOJA AND SA1.D_E_L_E_T_ <> '*') "
	cQry += " WHERE C6_FILIAL = '"+cFil+"'  "
	cQry += "   AND C6_NUM = '"+cNum+"'  " 
	cQry += "   AND C6.D_E_L_E_T_ <> '*' " 
	cQry += "   AND C6_QTDENT < C6_QTDVEN "
	cQry += "   AND NOT EXISTS(SELECT 1 "
	cQry += "                    FROM "+RetSqlname("SC9")+" C9 "  
	cQry += "                   WHERE C9_FILIAL = C6_FILIAL "
	cQry += "                     AND C9_PEDIDO = C6_NUM "
	cQry += "                     AND C9_ITEM = C6_ITEM " 
	cQry += "                     AND C9_PRODUTO = C6_PRODUTO "
	cQry += "                     AND C9.D_E_L_E_T_ <> '*') "
	cQry += "UNION ALL "

	cQry += "SELECT C9_ITEM, C9_PRODUTO,C9_QTDLIB, C9_DATALIB,C6_ITEM,C6_PRODUTO,C6_BLQ,C6_LOCAL,C6_PRUNIT,((100-ISNULL(A1_DESC,0))*0.01 * C6_PRUNIT) AS C6_PREGRA, " 
	cQry += "       C9_BLEST,C9_BLCRED, C9_BLWMS, C9.R_E_C_N_O_ REC, "
	cQry += "       C6_DESCRI, C6_QTDVEN, C6_UM, C6_PRCVEN, C6_QTDVEN-C6_QTDENT SALDO, "
	cQry += "(SELECT TOP 1 ZDP_VALOR FROM " + RetSqlname("ZDP")+" WHERE ZDP_FILIAL  = C6_FILIAL 
	cQry += "	                     AND ZDP_PEDIDO = C6_NUM 
	cQry += "	                     AND ZDP_ITEM = C6_ITEM  
	cQry += "	                     AND ZDP_PRODUT = C6_PRODUTO ORDER BY R_E_C_N_O_ DESC ) C6_DESCONT"
	cQry += " FROM " + RetSqlname("SC6")+" C6 INNER JOIN "+RetSqlname("SC9")+" C9 "
	cQry += "   ON (C9_FILIAL = C6_FILIAL AND C9_PEDIDO = C6_NUM AND C9_ITEM = C6_ITEM and C9_PRODUTO = C6_PRODUTO AND C9.D_E_L_E_T_ <> '*') " 
	cQry += " LEFT OUTER JOIN " + RetSqlname("SA1")+" SA1 ON (C6_CLI = A1_COD AND C6_LOJA = A1_LOJA AND SA1.D_E_L_E_T_ <> '*') "
 	cQry += " WHERE C6_FILIAL = '"+cFil+"'  "
	cQry += "   AND C6_NUM = '"+cNum+"'  " 
	cQry += "   AND C6.D_E_L_E_T_ <> '*' " 
	cQry += "   AND C6_QTDENT = C6_QTDVEN "

	cQry := ChangeQuery(cQry)

	Memowrite("C:\temp\mlfatc07-cQry-"+STRTRAN(TIME(),":","-")+".sql", cQry)

	TCQUERY cQry NEW ALIAS "TMPPED"

	DbSelectArea(cAlias)


	While (cAlias)->(!Eof())

		_cblq:="A LIBERAR"
		Do Case 
			Case 'R' $ (cAlias)->C6_BLQ  
			_cblq:='ELIMINADO RESIDUO'
			lOutOk	:= .F.				
		EndCase


		cImgDesc := ""
		Do Case 
			Case ((cAlias)->C6_DESCONT)>= 50
				cImgDesc := ("BR_CANCEL")
			Case ((cAlias)->C6_DESCONT)>= 40
				cImgDesc := ("BR_PRETO")		
			Case ((cAlias)->C6_DESCONT)>= 30
				cImgDesc := ("BR_VERMELHO")
			Case ((cAlias)->C6_DESCONT)>= 20
				cImgDesc := ("BR_LARANJA")
			Case ((cAlias)->C6_DESCONT)> 8
				cImgDesc := ("BR_AMARELO")
			Case EMPTY((cAlias)->C6_DESCONT)
				cImgDesc := ("BR_VERDE")
			Case ((cAlias)->C6_DESCONT)<= 8
				cImgDesc := ("BR_VERDE")
		EndCase

		Do Case                         

			Case !Empty((cAlias)->C9_BLEST)
				cLeg:="BR_PRETO"
				_cBL:=(cAlias)->C9_BLEST

				Do Case 
					Case _cBL=='02'
						_cblq:='BLOQUEIO DE ESTOQUE'
						lOutOk	:= .F. 
					Case _cBL=='03'
						_cblq:='BLOQUEIO MANUAL'
						lOutOk	:= .F.
					Case _cBL=='10'
						_cblq:='JÁ FATURADO'
						lOutOk	:= .F. 
					EndCase

					//_cblq:="EST-"+_cblq


			Case !Empty((cAlias)->C9_BLCRED)

				cLeg:="BR_VERMELHO"
				_cBL:=(cAlias)->C9_BLCRED
	
				Do Case 
					Case _cBL=='01'
					_cblq:='BLOQUEADO P/ CRÉDITO'
					lOutOk	:= .F.
					Case _cBL=='02'
					_cblq:='POR ESTOQUE/MV_BLQCRED'
					lOutOk	:= .F.
					Case _cBL=='04'
					_cblq:='LIMITE DE CRÉDITO VENCIDO'
					lOutOk	:= .F.
					Case _cBL=='05'
					_cblq:='BLOQUEIO CRÉDITO POR ESTORNO'
					lOutOk	:= .F.
					Case _cBL=='06'
					_cblq:='POR RISCO'
					lOutOk	:= .F.
					Case _cBL=='09'
					_cblq:='REJEITADO'
					lOutOk	:= .F.
					Case _cBL=='10'
					_cblq:='JÁ FATURADO'
					lOutOk	:= .F. 
				EndCase

			Case !Empty((cAlias)->C9_BLWMS)
				cLeg:="BR_AZUL"
				_cBL:=(cAlias)->C9_BLWMS

				Do Case 
					Case _cBL=='01'
						_cblq:='Bloqueio de Endereçamento do WMS/Somente SB2'
					Case _cBL=='02'
						_cblq:='Bloqueio de Endereçamento do WMS'
					Case _cBL=='04'
						_cblq:='Bloqueio de WMS - Externo'
					Case _cBL=='05'
						_cblq:='Em Processo Separação WMS' // Alterada a descrição para não confundir comercial, pois apenas Executado não significa que já foi expedido
					Case _cBL=='06'
						_cblq:='Liberação para Bloqueio 02'
					Case _cBL=='07'
						_cblq:='Liberação para Bloqueio 03'
				EndCase
				//_cblq:="WMS-"+_cblq
			Case (cAlias)->REC > 0
				_cblq:='Ok - Liberado'
				cLeg:="BR_AMARELO"
				lOutOk	:= .T. 
				nValLib	+= (cAlias)->C6_PRCVEN * (cAlias)->SALDO
			Otherwise
				cLeg:="BR_VERDE"
				lOutOk	:= .F. 
		EndCase	
		
		// Se por ventura bloqueou por algum motivo mas tem itens aptos para faturar mesmo assim - parcial 
		If nValLib > 0 .And. !lOutOk
			lOutOk	:= .T. 
		Endif
		
		nSumQtdVen	+= (cAlias)->C6_QTDVEN

		//CalcEst((cAlias)->C6_PRODUTO,(cAlias)->C6_LOCAL,dDataBase)[1]
		DbSelectArea("SB2")
		DbSetOrder(1)
		If DbSeek(xFilial("SB2")+(cAlias)->C6_PRODUTO+(cAlias)->C6_LOCAL)
			nEstDisp	:= 	SB2->B2_QATU - SB2->B2_RESERVA
		Else
			nEstDisp	:= 0
		Endif  

		AADD(_aRet,{cLeg,;
		substr(_cblq,1,25),;
		(cAlias)->C6_ITEM,;
		substr((cAlias)->C6_PRODUTO,1,15),;
		SUBSTR(Alltrim((cAlias)->C6_DESCRI),1,35),;
        nEstDisp,;
		(cAlias)->C6_QTDVEN,;
		Alltrim((cAlias)->C6_UM),;
		(cAlias)->SALDO,;
		(cAlias)->C9_QTDLIB,;
		STOD((cAlias)->C9_DATALIB),;
		(cAlias)->C6_PRUNIT,;
		(cAlias)->C6_PREGRA,;
		(cAlias)->C6_PRCVEN,;
		(cAlias)->C6_DESCONT,;
		cImgDesc,; //IIF(!EMPTY((cAlias)->C6_DESCONT) .AND. (cAlias)->C6_DESCONT>SuperGetMV("MV_ZDESMIN"),"BR_VERMELHO","BR_VERDE"),; 	//DIAGNOSTICO REGRAS DE NEGÓCIO	// MV_ZDESMIN: Valor máximo do desconto ex: 8 
		(cAlias)->REC,;
		.F.})

		(cAlias)->(dbSkip())
	Enddo

	(cAlias)->(dbCloseArea())

Return {_aRet,_aFile}


User Function xVALCTR(cTipo)

Local nValor := 0
Local cNumPed := SC5->C5_NUM
Local cCodVen := SC5->C5_VEND1
Local cWhere  := ''
Local cFilSC5 := ''

cFilSC5 := SC5->C5_FILIAL

 if cTipo == 'F'
		cWhere := "%ZCC_DOC <>  '' AND ZCC_SERIE <>  '' AND ZCC_ISENTO = 'N' AND  ZCC_VEND = '"+ cCodVen + "' AND FORMAT( GETDATE(), 'yyyyMM', 'en-US' ) = ZCC_MESREF%"
 
 elseif cTipo == 'P'
		cWhere := "%ZCC_DOC = '' AND  ZCC_FILIAL = '" +  cFilSC5 + "' AND ZCC_VEND = '"+ cCodVen + "' AND ZCC_NUM = '" + cNumPed + "' AND ZCC_ISENTO = 'N'%"

 elseif cTipo == 'I'
		cWhere := "%ZCC_VEND = '"+ cCodVen + "' AND ZCC_OPER = 'I' AND ZCC_ISENTO = 'N'%"
	
 Endif

 lVldPed := .F.	
 nValor  := 0
		BeginSql alias "cVlrFlex"
		Select SUM(ZCC_VALOR) AS VALOR /*, ZCC_NUM*/ from %Table:ZCC% ZCC
			Where ZCC.D_E_L_E_T_ <> '*'  and %exp:cWhere%  


//			Group By ZCC_NUM
		EndSql
		Count to nCount

		cVlrFlex->(DbGoTop())

		if cVlrFlex->(!EOF())
				
					nValor := cVlrFlex->VALOR
				
		Endif
	cVlrFlex->(DbCloseArea())

return nValor
