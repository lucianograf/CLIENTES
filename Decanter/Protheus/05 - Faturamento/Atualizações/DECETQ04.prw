#include 'protheus.ch'
#include 'parmtype.ch'
#Include 'FWMVCDef.ch'

/*/{Protheus.doc} DECETQ04
Browser para impressão de etiquetas de identificação a partir de itens de notas de entrada 
@type function
@version 1.0
@author Marcelo Alberto Lauschner
@since 15/12/2020
@return return_Nil 
/*/
User function DECETQ04()

	Local		aAreaOld	:= GetArea()
	Local		aFields		:= {}
	Private 	oBrowser	:= FWMBrowse():New()
	Private 	aRotina		:= MenuDef()
	//Default cChave		:= ""

	// Atualiza a sequencia correta do SZ1 no SXE e SXF,
	DbSelectArea("SD2")
	DbSetOrder(1)

	Aadd(aFields,{"Nota"/*01*/,{|| SD2->D2_DOC}/*02*/,"C"/*03*/,PesqPict("SD2","D2_DOC")/*04*/,1/*05*/,TamSX3("D2_DOC")[1]/*06*/,TamSX3("D2_DOC")[2]/*07*/,/*08*/,/*09*/,/*10*/,/*11*/,/*12*/,/*13*/,/*14*/,/*15*/,/*16*/})
	Aadd(aFields,{"Emissão"/*01*/,{|| SD2->D2_EMISSAO}/*02*/,"D"/*03*/,PesqPict("SD2","D2_EMISSAO")/*04*/,1/*05*/,TamSX3("D2_EMISSAO")[1]/*06*/,TamSX3("D2_EMISSAO")[2]/*07*/,/*08*/,/*09*/,/*10*/,/*11*/,/*12*/,/*13*/,/*14*/,/*15*/,/*16*/})
	//Aadd(aFields,{"Produto"/*01*/,{|| SD1->D1_COD}/*02*/,"C"/*03*/,PesqPict("SD1","D1_COD")/*04*/,1/*05*/,TamSX3("D1_COD")[1]/*06*/,TamSX3("D1_COD")[2]/*07*/,/*08*/,/*09*/,/*10*/,/*11*/,/*12*/,/*13*/,/*14*/,/*15*/,/*16*/})
	//Aadd(aFields,{"Quantidade"/*01*/,{|| SD1->D1_QUANT}/*02*/,"N"/*03*/,PesqPict("SD1","D1_QUANT")/*04*/,1/*05*/,TamSX3("D1_QUANT")[1]/*06*/,TamSX3("D1_QUANT")[2]/*07*/,/*08*/,/*09*/,/*10*/,/*11*/,/*12*/,/*13*/,/*14*/,/*15*/,/*16*/})
	//Aadd(aFields,{"Etq.Impressas"/*01*/,{|| SD1->D1_XPRTETQ}/*02*/,"N"/*03*/,PesqPict("SD1","D1_XPRTETQ")/*04*/,1/*05*/,TamSX3("D1_XPRTETQ")[1]/*06*/,TamSX3("D1_XPRTETQ")[2]/*07*/,/*08*/,/*09*/,/*10*/,/*11*/,/*12*/,/*13*/,/*14*/,/*15*/,/*16*/})
	//D1_XPRTETQ
	//[n][01] Título da coluna
	//[n][02] Code-Block de carga dos dados
	//[n][03] Tipo de dados
	//[n][04] Máscara
	//[n][05] Alinhamento (0=Centralizado, 1=Esquerda ou 2=Direita)
	//[n][06] Tamanho
	//[n][07] Decimal
	//[n][08] Indica se permite a edição
	//[n][09] Code-Block de validação da coluna após a edição
	//[n][10] Indica se exibe imagem
	//[n][11] Code-Block de execução do duplo clique
	//[n][12] Variável a ser utilizada na edição (ReadVar)
	//[n][13] Code-Block de execução do clique no header
	//[n][14] Indica se a coluna está deletada
	//[n][15] Indica se a coluna será exibida nos detalhes do Browse
	//[n][16] Opções de carga dos dados (Ex: 1=Sim, 2=Não)

	oBrowser:SetFields(aFields)

	oBrowser:SetAlias('SD2')
	oBrowser:SetOnlyFields( { 'D2_FILIAL', 'D2_DOC', 'D2_EMISSAO' , 'D2_COD' , 'D2_QUANT' } )
	oBrowser:SetDescription('Impressão de Etiquetas de Produtos ')


	// Legenda
	//oBrowser:AddLegend( " DTOS(dDataBase) >= DTOS(ZX_DTINI) .AND. (DTOS(dDataBase) <= DTOS(ZX_DTFIN) .OR. EMPTY(ZX_DTFIN))	" 	, "OK"		, "Vigente"	)
	//oBrowser:AddLegend( "!(	DTOS(dDataBase) >= DTOS(ZX_DTINI) .AND. (DTOS(dDataBase) <= DTOS(ZX_DTFIN)))						"	, "CANCEL"	, "Não Vigente"	)

	// Filtro
	// Comentado o filtro pois a rotina de apontamento irá gerar e encerrar a OP a cada apontamento, não ficando mais OP em aberto
	If FWIsInCallStack("U_DEC05A11")
		oBrowser:SetFilterDefault(" D2_DOC = '" + SF2->F2_DOC + "' .And. D2_SERIE = '"+SF2->F2_SERIE+"' .And. D2_FILIAL = '" + xFilial("SD2") + "' ")
	Endif 
	
    oBrowser:Activate()

	RestArea(aAreaOld)

Return Nil



/*/{Protheus.doc} ModelDef
//Função para obter a estrutura da tabela SC2 
@author Marcelo Alberto Lauschner
@since 21/01/2019
@version 1.0
@return oModel, Objeto MPFormModel
@type function
/*/
Static Function ModelDef()

	Local oStruSC2
	Local oModel

	// Cria o objeto do Modelo de Dados - Tem que ser diferente do nome do Fonte.
	oModel := MPFormModel():New('MODEL_DECETQ04',{|oModel| sfBeforeModel(oModel)}/*bPreValidacao*/, { |oModel| sfAfterModel(oModel) }/*bPosValidacao*/, /*bCommit*/,/*bCancel*/ )

	// Monta as estruturas das tabelas
	oStruSC2 := FWFormStruct( 1, 'SD2', ,/*lViewUsado*/ )

	//Adiciona Enchoices
	oModel:AddFields( 'DECETQ04', /*cOwner*/, oStruSC2 )


Return ( oModel )



/*/{Protheus.doc} ViewDef
// Função para retornar interface da edição/visualização do Registro
@author Marcelo Alberto Lauschner
@since 21/01/2019
@version 1.0
@return oView, Objeto FWFormView

@type function
/*/
Static Function ViewDef()
	Local oView		:= nil
	Local oModel	:= FWLoadModel( 'DECETQ04' )
	Local oStruSD1


	// Monta as estruturas das tabelas
	oStruSD1 := FWFormStruct( 2, 'SD2')

	oView := FWFormView():New()
	oView:SetModel(oModel)
	oView:AddField("DECETQ04", oStruSD1, "DECETQ04")
	oView:CreateHorizontalBox( "MASTER" , 100, /*cIDOwner*/, /*lFixPixel*/, /*cIDFolder*/, /*cIDSheet*/ )
	oView:SetOwnerView( "DECETQ04" , "MASTER" )

Return oView



/*/{Protheus.doc} MenuDef
// Função que retorna os botões do Menu do Browser
@author Marcelo Alberto Lauschner
@since 21/01/2019
@version 1.0
@return aRotina, Array com os botões 

@type function
/*/
Static Function MenuDef()

	Local aRotina	:= {}
	aAdd( aRotina, { 'Visualizar'	        , 'VIEWDEF.DECETQ04', 0, 2, 0, NIL } )
	aAdd( aRotina, { 'Impressão Etiquetas' 	, 'StaticCall(DECETQ04,sfPrintEtq)', 0, 5, 0, NIL } )


Return ( aRotina )


/*/{Protheus.doc} sfBeforeModel
// Função a ser executada antes de abrir a tela do Registro
@author Marcelo Alberto Lauschner
@since 21/01/2019
@version 1.0
@return lRet, Lógico
@param oModel, object, descricao
@type function
/*/
Static Function sfBeforeModel(oModel)
	Local 	nOpc		:= oModel:nOperation
	Local	lRet		:= .T.


Return lRet


/*/{Protheus.doc} sfAfterModel
// Função que valida a tela do registro após confirmar a tela do registro
@author Marcelo Alberto Lauschner
@since 21/01/2019
@version 1.0
@return lRet, Lógico 
@param oModel, object, descricao
@type function
/*/
Static Function sfAfterModel(oModel)

	Local nOpc		:= oModel:nOperation
	Local nRecNo	:= Iif(nOpc == 3,0,SD1->(Recno())) //Se for INCLUSÃO Ignora Recno
	Local lRet		:= .T.

Return lRet


Static Function sfPrintEtq()

   Local nVol  	:= 0
	Local nX
	Local cPrintTxt
	Local cPrintMsg	:= ""
	Local cCodBar   := ""
	Local nLinAux 	:= 0
	Local nColAux 	:= 57

    Local cPerg     := "ETIQC004"
	
    // Ajusta a pergunta conforme a quantidade do item 
    If FindFunction("U_GravaSX1")
        U_GravaSX1(cPerg,"01",SD2->D2_QUANT)
    Endif 

	If !Pergunte(cPerg,.T.)
        Return 
    Endif 

	nVol := mv_par01
	nVol += 1
	nVol := Int(nVol/2)

	If nVol =  0
		MSGALERT( "Não foi informa o número de etiquetas a serem impressas!", "Mensagem" )
	Else
		DbSelectArea("SB1")
		DbSetOrder(1)
		If DbSeek(xFilial("SB1")+SD2->D2_COD)
			cCodBar	:= SB1->B1_COD

			For nX := 1 To nVol

				MSCBPRINTER("ZEBRA","LPT"+cValToChar(MV_PAR03),,,.f.,,,,,,.f.,)

				MSCBCHKSTATUS(.F.)
				MSCBBEGIN(1,6)


				//MSCBSAY(080,15,"www.decanter.com.br", "R","0","050,050")

				//MSCBSAY(065,105,DToC(Date())+" - "+Time(), "R","0","050,050")


				cPrintTxt	:= Substr(SB1->B1_DESC,1,40)
				cPrintMsg 	+= Chr(13)+Chr(10)+cPrintTxt

				nLinAux	:= 02
				MSCBSAY(03,nLinAux,cPrintTxt,"N","B","002,001") //Imprime Texto

				// Imprime Segunda Etiqueta 
				MSCBSAY(nColAux,nLinAux,cPrintTxt,"N","B","002,001") //Imprime Texto



				If !Empty(Substr(SB1->B1_DESC,41,40))
					cPrintTxt	:= Substr(SB1->B1_DESC,41,40)
					cPrintMsg 	+= Chr(13)+Chr(10)+cPrintTxt
					nLinAux	+= 02
					MSCBSAY(03,nLinAux,cPrintTxt,"N","B","002,001") //Imprime Texto

					// Imprime Segunda Etiqueta 
					MSCBSAY(nColAux,nLinAux,cPrintTxt,"N","B","002,001") //Imprime Texto
				Endif

				If !Empty(MV_PAR02)
					cPrintTxt	:= Alltrim(Substr(MV_PAR02,1,40))
					cPrintMsg 	+= Chr(13)+Chr(10)+cPrintTxt
					nLinAux	+= 02
					MSCBSAY(03,nLinAux,cPrintTxt,"N","B","002,001") //Imprime Texto

					// Imprime Segunda Etiqueta 
					MSCBSAY(nColAux,nLinAux,cPrintTxt,"N","B","002,001") //Imprime Texto

					cPrintTxt	:= Alltrim(Substr(MV_PAR02,41,40))

					If !Empty(cPrintTxt)
						cPrintMsg 	+= Chr(13)+Chr(10)+cPrintTxt
						nLinAux	+= 02
						MSCBSAY(03,nLinAux,cPrintTxt,"N","B","002,001") //Imprime Texto

						// Imprime Segunda Etiqueta 
						MSCBSAY(nColAux,nLinAux,cPrintTxt,"N","B","002,001") //Imprime Texto
					Endif
				Endif

				//MSCBSAYBAR(30,03,Alltrim(StrTran(AllTrim(Transform("33442Z","@R 99.99.9.X")),"-","")),"N","MB07",12,.F.,.T.,.F.,,2,2,.F.)
				//MSCBSAYBAR(06,10,AllTrim(cCodBar),,"N","MB04"/*MB04 - EAN 13 */,14,.T./*lDigver*/,.T./*lLinha*/,.F.,,3,2,.F.)
				nLinAux	+= 02
				MSCBSAYBAR(03,nLinAux,Alltrim(StrTran(AllTrim(cCodBar),"-","")),"N","MB07",7,.F.,.T.,.F.,,2,2,.F.)
				
				// Imprime Segunda Etiqueta 
				MSCBSAYBAR(nColAux,nLinAux,Alltrim(StrTran(AllTrim(cCodBar),"-","")),"N","MB07",7,.F.,.T.,.F.,,2,2,.F.)

				//cPrintTxt := {{"01",AllTrim(SB1->B1_XDUN14)},{"3102",StrZero(nPesoCx * 100 ,6) },{"12",Substr(DTOS(dDtVldLote),3,6)}}
				// cSubSetIni - usar o comando C- Compactar o código de barras
				//MSCBSAYBAR(15/*nXmm*/,35.5/*nYmm*/,cPrintTxt/*cConteudo*/,"N"/*cRotação*/,"E"/*cTypePrt*/,10/*nAltura*/,.F./*lDigver*/,.F./*lLinha*/,.F./*lLinBaixo*/,"C"/*cSubSetIni*/,0/*nLargura*/,0/*nRelacao*/,.T.)

			/*MSCBSAY(	nXmm 		Posição X em Milímetros
			nYmm 		Posição Y em Milímetros
			cTexto 		String a ser impresso 
			cRotação 	String com o tipo de Rotação (N,R,I,B): N - Normal R - Cima para baixo I - Invertido B - Baixo para cima
			cFonte 		String com os tipos de Fonte: Datamax - (0,1,2,3,4,5,6,7,8,9) 9 – fonte escalar
			cTam 		String com o tamanho da Fonte
			lReverso	Imprime em reverso quando tiver sobre um box preto
			*/ 

				MSCBEND()
				MSCBCLOSEPRINTER()

			Next
		Endif

	EndIf

    
Return 
