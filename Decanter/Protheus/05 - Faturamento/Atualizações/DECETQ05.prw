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
User Function DECETQ05()

	Local		aAreaOld	:= GetArea()
	Local		aFields		:= {}
	Private 	oBrowser	:= FWMBrowse():New()
	Private 	aRotina		:= MenuDef()
	//Default cChave		:= ""

	DbSelectArea("SD1")
	DbSetOrder(1)
    
	//Aadd(aFields,{" "           /*01*/,{|| }/*02*/,"C"/*03*/,PesqPict("SD1","D1_LEGENDA")/*04*/,1/*05*/,TamSX3("D1_LEGENDA")[1]/*06*/,TamSX3("D1_LEGENDA")[2]/*07*/,/*08*/,/*09*/,/*10*/,/*11*/,/*12*/,/*13*/,/*14*/,/*15*/,/*16*/})
	//Aadd(aFields,{"Filial"      /*01*/,{|| xFilial("SD1")}/*02*/,"C"/*03*/,PesqPict("SD1","D1_FILIAL")/*04*/,1/*05*/,TamSX3("D1_FILIAL")[1]/*06*/,TamSX3("D1_FILIAL")[2]/*07*/,/*08*/,/*09*/,/*10*/,/*11*/,/*12*/,/*13*/,/*14*/,/*15*/,/*16*/})
	Aadd(aFields,{"Produto"     /*01*/,{|| SD1->D1_COD}/*02*/,"C"/*03*/,PesqPict("SD1","D1_COD")/*04*/,1/*05*/,TamSX3("D1_COD")[1]/*06*/,TamSX3("D1_COD")[2]/*07*/,/*08*/,/*09*/,/*10*/,/*11*/,/*12*/,/*13*/,/*14*/,/*15*/,/*16*/})
	Aadd(aFields,{"Descrição"   /*01*/,{|| SD1->D1_DESCR}/*02*/,"C"/*03*/,PesqPict("SD1","D1_DESCR")/*04*/,1/*05*/,TamSX3("D1_DESCR")[1]/*06*/,TamSX3("D1_DESCR")[2]/*07*/,/*08*/,/*09*/,/*10*/,/*11*/,/*12*/,/*13*/,/*14*/,/*15*/,/*16*/})
	Aadd(aFields,{"Quantidade"  /*01*/,{|| SD1->D1_QUANT}/*02*/,"N"/*03*/,PesqPict("SD1","D1_QUANT")/*04*/,1/*05*/,TamSX3("D1_QUANT")[1]/*06*/,TamSX3("D1_QUANT")[2]/*07*/,/*08*/,/*09*/,/*10*/,/*11*/,/*12*/,/*13*/,/*14*/,/*15*/,/*16*/})
	Aadd(aFields,{"Nota"        /*01*/,{|| SD1->D1_DOC}/*02*/,"C"/*03*/,PesqPict("SD1","D1_DOC")/*04*/,1/*05*/,TamSX3("D1_DOC")[1]/*06*/,TamSX3("D1_DOC")[2]/*07*/,/*08*/,/*09*/,/*10*/,/*11*/,/*12*/,/*13*/,/*14*/,/*15*/,/*16*/})
	Aadd(aFields,{"Dt.Emissão"  /*01*/,{|| SD1->D1_EMISSAO}/*02*/,"D"/*03*/,PesqPict("SD1","D1_EMISSAO")/*04*/,1/*05*/,TamSX3("D1_EMISSAO")[1]/*06*/,TamSX3("D1_EMISSAO")[2]/*07*/,/*08*/,/*09*/,/*10*/,/*11*/,/*12*/,/*13*/,/*14*/,/*15*/,/*16*/})
	Aadd(aFields,{"Dt.Digitação"/*01*/,{|| SD1->D1_DTDIGIT}/*02*/,"D"/*03*/,PesqPict("SD1","D1_DTDIGIT")/*04*/,1/*05*/,TamSX3("D1_DTDIGIT")[1]/*06*/,TamSX3("D1_DTDIGIT")[2]/*07*/,/*08*/,/*09*/,/*10*/,/*11*/,/*12*/,/*13*/,/*14*/,/*15*/,/*16*/})
	Aadd(aFields,{"Fornecedor"  /*01*/,{|| SD1->D1_FORNECE}/*02*/,"C"/*03*/,PesqPict("SD1","D1_FORNECE")/*04*/,1/*05*/,TamSX3("D1_FORNECE")[1]/*06*/,TamSX3("D1_FORNECE")[2]/*07*/,/*08*/,/*09*/,/*10*/,/*11*/,/*12*/,/*13*/,/*14*/,/*15*/,/*16*/})
	Aadd(aFields,{"Loja"        /*01*/,{|| SD1->D1_LOJA}/*02*/,"C"/*03*/,PesqPict("SD1","D1_LOJA")/*04*/,1/*05*/,TamSX3("D1_LOJA")[1]/*06*/,TamSX3("D1_LOJA")[2]/*07*/,/*08*/,/*09*/,/*10*/,/*11*/,/*12*/,/*13*/,/*14*/,/*15*/,/*16*/})
	Aadd(aFields,{"Nome"        /*01*/,{|| Iif(SD1->D1_TIPO $ "D#B",Posicione("SA1",1,xFilial("SA1")+SD1->(D1_FORNECE+D1_LOJA),"A1_NREDUZ"),Posicione("SA2",1,xFilial("SA2")+SD1->(D1_FORNECE+D1_LOJA),"A2_NREDUZ"))}/*02*/,"C"/*03*/,PesqPict("SA2","A2_NREDUZ")/*04*/,1/*05*/,TamSX3("A2_NREDUZ")[1]/*06*/,TamSX3("A2_NREDUZ")[2]/*07*/,/*08*/,/*09*/,/*10*/,/*11*/,/*12*/,/*13*/,/*14*/,/*15*/,/*16*/})
	Aadd(aFields,{"Grupo Prd"   /*01*/,{|| SD1->D1_GRUPO}/*02*/,"C"/*03*/,PesqPict("SD1","D1_GRUPO")/*04*/,1/*05*/,TamSX3("D1_GRUPO")[1]/*06*/,TamSX3("D1_GRUPO")[2]/*07*/,/*08*/,/*09*/,/*10*/,/*11*/,/*12*/,/*13*/,/*14*/,/*15*/,/*16*/})
	Aadd(aFields,{"CFOP"        /*01*/,{|| SD1->D1_CF}/*02*/,"C"/*03*/,PesqPict("SD1","D1_CF")/*04*/,1/*05*/,TamSX3("D1_CF")[1]/*06*/,TamSX3("D1_CF")[2]/*07*/,/*08*/,/*09*/,/*10*/,/*11*/,/*12*/,/*13*/,/*14*/,/*15*/,/*16*/})
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

	oBrowser:SetAlias('SD1')
	oBrowser:SetOnlyFields( {'D1_TIPO' }) //, 'D1_COD','D1_QUANT','D1_DOC','D1_SERIE','D1_EMISSAO' ,'D1_DTDIGIT', 'D1_FORNECE','D1_LOJA','D1_CF','D1_GRUPO' } )
	oBrowser:SetDescription('Impressão de Etiquetas de Produtos ')


	
	// Filtro
	// Comentado o filtro pois a rotina de apontamento irá gerar e encerrar a OP a cada apontamento, não ficando mais OP em aberto
	oBrowser:SetFilterDefault(" !(D1_GRUPO $ 'SE0B#SE0S#SE0F#SE0G') .And. D1_TIPO $ 'N#D' .And. !(D1_CF $ '1353 #2353 #1933 #2933 #1352 #2352 #1905 #') ")

    // Legenda
	//oBrowser:AddLegend( "SD1->D1_TIPO == 'N'"    , "RED"		, "Nota Fornecedor"	)
	//oBrowser:AddLegend( "SD1->D1_TIPO == 'D'"    , "YELLOW"  	, "Devolução Venda"	)
    
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
	oModel := MPFormModel():New('MODEL_DECETQ05',{|oModel| sfBeforeModel(oModel)}/*bPreValidacao*/, { |oModel| sfAfterModel(oModel) }/*bPosValidacao*/, /*bCommit*/,/*bCancel*/ )

	// Monta as estruturas das tabelas
	oStruSC2 := FWFormStruct( 1, 'SD1', ,/*lViewUsado*/ )

	//Adiciona Enchoices
	oModel:AddFields( 'DECETQ05', /*cOwner*/, oStruSC2 )


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
	Local oModel	:= FWLoadModel( 'DECETQ05' )
	Local oStruSD1


	// Monta as estruturas das tabelas
	oStruSD1 := FWFormStruct( 2, 'SD1')

	oView := FWFormView():New()
	oView:SetModel(oModel)
	oView:AddField("DECETQ05", oStruSD1, "DECETQ05")
	oView:CreateHorizontalBox( "MASTER" , 100, /*cIDOwner*/, /*lFixPixel*/, /*cIDFolder*/, /*cIDSheet*/ )
	oView:SetOwnerView( "DECETQ05" , "MASTER" )

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
	//aAdd( aRotina, { 'Visualizar'	        , 'VIEWDEF.DECETQ05', 0, 2, 0, NIL } )
	aAdd( aRotina, { 'Impressão Etiquetas' 	, 'StaticCall(DECETQ05,sfPrintEtq)', 0, 5, 0, NIL } )


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
        U_GravaSX1(cPerg,"01",SD1->D1_QUANT)
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

		If DbSeek(xFilial("SB1")+SD1->D1_COD)
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
