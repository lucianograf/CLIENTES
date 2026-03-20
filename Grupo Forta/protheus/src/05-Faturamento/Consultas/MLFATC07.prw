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

	Private cCliente	:=""
	Private cCondPag	:=""
	Private cVend1		:=""
	Private cVend2		:=""

	Private oDlg := Nil

	Default	lOutOk		:= .T. 


	_Carga	:=	sfPreenc(cFil,cNum,@lOutOk)

	// Vetor com elementos do Browse		
	aCols :=_Carga[1]

	If Len(aCols)==0
		MsgInfo("Pedido sem liberacao ou faturado!")
		Return
	Endif

	DEFINE DIALOG oDlg TITLE "MLFATC07 - Status do Pedido" FROM 1,1 TO 560,1200 PIXEL		//DEFINE DIALOG oDlg TITLE "Documentos em espera" FROM 180,180 TO 550,700 PIXEL


	aHeader := {} 
	// 			   01-Titulo	,02-Campo		,03-Picture					,04-Tamanho   				, 05-Decimal			, 06-Valid	, 07-Usado	, 08-Tipo		, 09-F3		, 10-Contexto	, 11-ComboBox	, 12-Relacao	, 13-When		, 14-Visual	, 15-Valid Usuario
	AADD(aHeader,{ " " 			,"IMG"   		,"@BMP"						,2							,0						,"","","C","", "","","","","V" } )
	AADD(aHeader,{ "Status"   	,"STATUS"   	,""							,20							,0	,"","","C","", "","","","","V" } )
	AADD(aHeader,{ "Item"   	,"ITEM"   		,""							,TamSx3("C6_ITEM")[1]		,TamSx3("C6_ITEM")[2]	,"","","C","", "","","","","V" } )
	AADD(aHeader,{ "Produto"    ,"C6_PRODUTO"  	,""							,15,TamSx3("C6_PRODUTO")[2]	,"","","C","", "","","","","V" } )
	AADD(aHeader,{ "Descrição"  ,"DESCRI" 		,""							,35	,TamSx3("C6_DESCRI")[2]	,"","","C","", "","","","","V" } )
	AADD(aHeader,{ "Qtd.Orig"  	,"QTDVEN" 		,PesqPict("SC6","C6_QTDVEN"),TamSx3("C6_QTDVEN")[1]		,TamSx3("C6_QTDVEN")[2]	,,"","N","", "","","","","V" } )
	AADD(aHeader,{ "Um"  		,"UM"   		,""							,TamSx3("C6_UM")[1]			,TamSx3("C6_UM")[2]		,"","","C","", "","","","","V" } )                          
	AADD(aHeader,{ "Saldo"  	,"SALDO" 		,PesqPict("SC6","C6_QTDVEN"),TamSx3("C6_QTDVEN")[1]		,TamSx3("C6_QTDVEN")[2]	,,"","N","", "","","","","V" } )
	AADD(aHeader,{ "Qtd.Lib"  	,"QTDLIB" 		,PesqPict("SC6","C6_QTDVEN") ,TamSx3("C6_QTDVEN")[1]	,TamSx3("C6_QTDVEN")[2]	,,"","N","", "","","","","V" } )
	AADD(aHeader,{ "Dt.Lib"  	,"DTLIB" 		,PesqPict("SC6","C5_EMISSAO") ,TamSx3("C5_EMISSAO")[1]	,TamSx3("C5_EMISSAO")[2]	,,"","D","", "","","","","V" } )

	cLinOk		:=	"AllwaysTrue"
	cTudoOk		:=	"AllwaysTrue"
	cFieldOk	:=	"AllwaysTrue"
	cSuperDel	:=	"AllwaysTrue"
	cDelOk		:=	"AllwaysTrue" 
	nFreeze 	:= 	000 
	nMax		:=	300
	aCpoGDa		:=	{} 

	oGetItens	:=	MsNewGetDados():New(01,01,200,600, GD_UPDATE,;								
	cLinOk,cTudoOk,nil,aCpoGDa,nFreeze,nMax,cFieldOk, cSuperDel,;						   
	cDelOk, oDLG, aHeader, aCols)

	Private oFontTitulo := TFont():New("MS Sans Serif",,018,,.T.,,,,,.F.,.F.)

	@ 205,002 SAY "Pedido "+Alltrim(cNum) SIZE 100,7 OF oDlg FONT oFontTitulo COLORS 16711680, 16777215 PIXEL
	//@ 215,002 SAY Alltrim(cNum) SIZE 100,7 OF oDlg FONT oFontTitulo COLORS 16711680, 16777215 PIXEL

	@ 220,002 SAY "Cliente: "+cCliente SIZE 200,7 OF oDlg PIXEL 
	@ 230,002 SAY "Cond.Pag: "+cCondPag SIZE 150,7 OF oDlg PIXEL

	@ 245,180 SAY "Vendedor 1: "+cVend1 SIZE 100,7 OF oDlg PIXEL
	@ 255,180 SAY "Vendedor 2: "+cVend2 SIZE 100,7 OF oDlg PIXEL

	// Cria Botoes com metodos básicos		

	TButton():New( 260, 102, "Cancelar", oDlg,{|| oDlg:End(),;			
	},40,010,,,.F.,.T.,.F.,,.F.,,,.F. )		

	ACTIVATE DIALOG oDlg CENTERED //VALID Valida(aBrowse,oBrowse:nAt)

Return 


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³TLLIBPED  ºAutor  ³Microsiga           º Data ³  06-25-12   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Alimenta aCols com os registros que devem aparecer na tela º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ AP                                                        º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function sfPreenc(cFil,cNum,lOutOk)

	Local _aFile	:={}
	Local _aRet		:={}
	Local cAlias	:= "TMPPED"
	Local nValLib	:=0 
	         
	
	dbSelectArea("SC5")
	dbSetOrder(1)
	dbSeek(xFilial("SC5")+cNum)

	cCliente	:= Alltrim(SC5->C5_CLIENTE)+"-"+SC5->C5_LOJACLI+"\ ("+Alltrim(POSICIONE("SA1",1,xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI,"A1_NOME"))+")"
	cCondPag	:= SC5->C5_CONDPAG + "("+Alltrim(POSICIONE("SE4",1,xFilial("SE4")+SC5->C5_CONDPAG,"E4_DESCRI"))+")"
	cVend1		:= IIF(!EMPTY(SC5->C5_VEND1),POSICIONE("SA3",1,XFILIAL("SA3")+SC5->C5_VEND1,"A3_NOME"),"")
	cVend2		:= IIF(!EMPTY(SC5->C5_VEND2),POSICIONE("SA3",1,XFILIAL("SA3")+SC5->C5_VEND2,"A3_NOME"),"")

	If Select( cAlias ) > 0
		(cAlias)->( dbCloseArea() )            
	Endif 

	cQry := "SELECT C9_ITEM, C9_PRODUTO,C9_QTDLIB, C9_DATALIB,C6_ITEM,C6_PRODUTO,C6_BLQ, " 
	cQry += "       C9_BLEST,C9_BLCRED, C9_BLWMS, C9.R_E_C_N_O_ REC, "
	cQry += "       C6_DESCRI, C6_QTDVEN, C6_UM, C6_PRCVEN, C6_QTDVEN-C6_QTDENT SALDO "
	cQry += " FROM " + RetSqlname("SC6")+" C6 INNER JOIN "+RetSqlname("SC9")+" C9 "
	cQry += "   ON (C9_FILIAL = C6_FILIAL AND C9_PEDIDO = C6_NUM AND C9_ITEM = C6_ITEM and C9_PRODUTO = C6_PRODUTO AND C9.D_E_L_E_T_ <> '*') " 
	cQry += " WHERE C6_FILIAL = '"+cFil+"'  "
	cQry += "   AND C6_NUM = '"+cNum+"'  " 
	cQry += "   AND C6.D_E_L_E_T_ <> '*' " 
	cQry += "   AND C6_QTDENT < C6_QTDVEN "
	cQry += "UNION ALL"
	cQry += "SELECT C6_ITEM C9_ITEM, C6_PRODUTO C9_PRODUTO, 0 C9_QTDLIB, ' ' C9_DATALIB,C6_ITEM,C6_PRODUTO,C6_BLQ, " 
	cQry += "       '  ' C9_BLEST,'  ' C9_BLCRED, '  ' C9_BLWMS, 0 REC, "
	cQry += "       C6_DESCRI, C6_QTDVEN, C6_UM, C6_PRCVEN, C6_QTDVEN-C6_QTDENT SALDO "
	cQry += " FROM " + RetSqlname("SC6")+" C6 "
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

	cQry += "SELECT C9_ITEM, C9_PRODUTO,C9_QTDLIB, C9_DATALIB,C6_ITEM,C6_PRODUTO,C6_BLQ, " 
	cQry += "       C9_BLEST,C9_BLCRED, C9_BLWMS, C9.R_E_C_N_O_ REC, "
	cQry += "       C6_DESCRI, C6_QTDVEN, C6_UM, C6_PRCVEN, C6_QTDVEN-C6_QTDENT SALDO "
	cQry += " FROM " + RetSqlname("SC6")+" C6 INNER JOIN "+RetSqlname("SC9")+" C9 "
	cQry += "   ON (C9_FILIAL = C6_FILIAL AND C9_PEDIDO = C6_NUM AND C9_ITEM = C6_ITEM and C9_PRODUTO = C6_PRODUTO AND C9.D_E_L_E_T_ <> '*') " 
	cQry += " WHERE C6_FILIAL = '"+cFil+"'  "
	cQry += "   AND C6_NUM = '"+cNum+"'  " 
	cQry += "   AND C6.D_E_L_E_T_ <> '*' " 
	cQry += "   AND C6_QTDENT = C6_QTDVEN "

	cQry := ChangeQuery(cQry)

	TCQUERY cQry NEW ALIAS "TMPPED"

	DbSelectArea(cAlias)


	While (cAlias)->(!Eof())

		_cblq:="A LIBERAR"
		Do Case 
			Case 'R' $ (cAlias)->C6_BLQ  
			_cblq:='ELIMINADO RESIDUO'
			lOutOk	:= .F.				
		EndCase

		Do Case                         
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

			Case !Empty((cAlias)->C9_BLEST)
				cLeg:="BR_PRETO"
				_cBL:=(cAlias)->C9_BLEST

				Do Case 
					Case _cBL=='02'
						_cblq:='BLOQUEIO DE ESTOQUE'
						//lOutOk	:= .F. 
					Case _cBL=='03'
						_cblq:='BLOQUEIO MANUAL'
						//lOutOk	:= .F.
					EndCase

					//_cblq:="EST-"+_cblq

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

		/*
		AADD(aHeader,{ " " 			,"IMG"   		
		AADD(aHeader,{ "Status"   	,"STATUS"   	
		AADD(aHeader,{ "Item"   	,"ITEM"   		
		AADD(aHeader,{ "Produto"    ,"C6_PRODUTO"  	
		AADD(aHeader,{ "Descrição"  ,"DESCRI" 		
		AADD(aHeader,{ "Qtd.Orig"  		,"QTDVEN" 	
		AADD(aHeader,{ "Um"  		,"UM"   		
		AADD(aHeader,{ "Saldo"  		,"SALDO" 	
		AADD(aHeader,{ "Qtd.Lib"  	,"QTDLIB" 		
		AADD(aHeader,{ "Dt.Lib"  	,"DTLIB" 		
		*/
		//C9_ITEM, C9_PRODUTO, C6_DESCRI, C6_QTDVEN, C6_UM, C6_PRCVEN, C6_QTDVEN-C6_QTDENT SALDO,C9_QTDLIB, C9_DATALIB
		AADD(_aRet,{cLeg,;
		substr(_cblq,1,25),;
		(cAlias)->C6_ITEM,;
		substr((cAlias)->C6_PRODUTO,1,15),;
		SUBSTR(Alltrim((cAlias)->C6_DESCRI),1,35),;
		(cAlias)->C6_QTDVEN,;
		Alltrim((cAlias)->C6_UM),;
		(cAlias)->SALDO,;
		(cAlias)->C9_QTDLIB,;
		STOD((cAlias)->C9_DATALIB),;
		(cAlias)->REC,;
		.F.})

		(cAlias)->(dbSkip())
	Enddo

	(cAlias)->(dbCloseArea())

Return {_aRet,_aFile}

