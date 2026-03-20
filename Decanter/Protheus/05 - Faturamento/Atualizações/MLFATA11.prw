#include 'protheus.ch'
#Include 'FWMVCDef.ch'

/*/{Protheus.doc} MLFATA11
Browser para impressão de etiquetas de identificação a partir de itens de notas de entrada 
@type function
@version 1.0
@author Marcelo Alberto Lauschner
@since 15/12/2020
@return return_Nil 
/*/
User function MLFATA11()

	Local		aAreaOld	:= GetArea()
	Local		aFields		:= {}
	Private 	oBrowser	:= FWMBrowse():New()
	Private 	aRotina		:= MenuDef()
	//Default cChave		:= ""

	// Atualiza a sequencia correta do SZ1 no SXE e SXF,
	DbSelectArea("SD1")
	DbSetOrder(1)

	Aadd(aFields,{"Nota"/*01*/,{|| SD1->D1_DOC}/*02*/,"C"/*03*/,PesqPict("SD1","D1_DOC")/*04*/,1/*05*/,TamSX3("D1_DOC")[1]/*06*/,TamSX3("D1_DOC")[2]/*07*/,/*08*/,/*09*/,/*10*/,/*11*/,/*12*/,/*13*/,/*14*/,/*15*/,/*16*/})
	Aadd(aFields,{"Data Entrada"/*01*/,{|| SD1->D1_DTDIGIT}/*02*/,"D"/*03*/,PesqPict("SD1","D1_DTDIGIT")/*04*/,1/*05*/,TamSX3("D1_DTDIGIT")[1]/*06*/,TamSX3("D1_DTDIGIT")[2]/*07*/,/*08*/,/*09*/,/*10*/,/*11*/,/*12*/,/*13*/,/*14*/,/*15*/,/*16*/})
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

	oBrowser:SetAlias('SD1')
	oBrowser:SetOnlyFields( { 'D1_FILIAL', 'D1_DOC', 'D1_DTDIGIT' , 'D1_COD' , 'D1_QUANT'  } )
	oBrowser:SetDescription('Impressão de Etiquetas de Produtos ')


	// Legenda
	//oBrowser:AddLegend( " DTOS(dDataBase) >= DTOS(ZX_DTINI) .AND. (DTOS(dDataBase) <= DTOS(ZX_DTFIN) .OR. EMPTY(ZX_DTFIN))	" 	, "OK"		, "Vigente"	)
	//oBrowser:AddLegend( "!(	DTOS(dDataBase) >= DTOS(ZX_DTINI) .AND. (DTOS(dDataBase) <= DTOS(ZX_DTFIN)))						"	, "CANCEL"	, "Não Vigente"	)

	// Filtro
	// Comentado o filtro pois a rotina de apontamento irá gerar e encerrar a OP a cada apontamento, não ficando mais OP em aberto
	If GetNewPar("GFMLFAT11X",.T.)
		oBrowser:SetFilterDefault(" D1_TIPO $ 'D#N' .And. !(D1_CF $ '1353 #2353 #1933 #2202 #2933 #1253 #1907 #1407 #1303 #1949 #2949 ') ")
	Else 
		oBrowser:SetFilterDefault(" D1_XPRTETQ < D1_QUANT .And. D1_DTDIGIT > dDatabase-30 .And. D1_TIPO $ 'D#N' .And. !(D1_CF $ '1353 #2353 #1933 #2202 #2933 #1253 #1907 #1407 #1303 #1949 #2949 ') ")
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
	oModel := MPFormModel():New('MODEL_MLFATA11',{|oModel| sfBeforeModel(oModel)}/*bPreValidacao*/, { |oModel| sfAfterModel(oModel) }/*bPosValidacao*/, /*bCommit*/,/*bCancel*/ )

	// Monta as estruturas das tabelas
	oStruSC2 := FWFormStruct( 1, 'SD1', ,/*lViewUsado*/ )

	//Adiciona Enchoices
	oModel:AddFields( 'MLFATA11', /*cOwner*/, oStruSC2 )


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
	Local oModel	:= FWLoadModel( 'MLFATA11' )
	Local oStruSD1


	// Monta as estruturas das tabelas
	oStruSD1 := FWFormStruct( 2, 'SD1')

	oView := FWFormView():New()
	oView:SetModel(oModel)
	oView:AddField("MLFATA11", oStruSD1, "MLFATA11")
	oView:CreateHorizontalBox( "MASTER" , 100, /*cIDOwner*/, /*lFixPixel*/, /*cIDFolder*/, /*cIDSheet*/ )
	oView:SetOwnerView( "MLFATA11" , "MASTER" )

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
	If __cUserId $ GetNewPar("GF_MLFAT11","000016")
		aAdd( aRotina, { 'Visualizar'	        , 'VIEWDEF.MLFATA11', 0, 2, 0, NIL } )
	Endif 
	aAdd( aRotina, { 'Impressão Etiquetas' 	, 'StaticCall(MLFATA11,sfPrintEtq)', 0, 5, 0, NIL } )


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


/*/{Protheus.doc} sfPrintEtq
//Função responsável pela impressão das etiquetas de Rótulos
@author Marcelo Alberto Lauschner
@since 21/01/2019
@version 1.0
@return  Nil 
@type function
/*/
Static Function sfPrintEtq()

	Local		aAreaOld	:= GetArea()
	Local		lIsHomologa	:= .F.
	Local		cPrintMsg	:= ""
	Local		cPrintTxt	:= ""
	Local		oPanelDlg
	Local		oDlgEtq
	Local		lOk
	Local		nQteEtq		:= SD1->D1_QUANT - SD1->D1_XPRTETQ
	Local		ix
	Local       cCodBar
	Private 	lImprInvent		:= .F. 

	If GetNewPar("GFMLFAT11X",.T.)
		lImprInvent		:= .T.
		DbSelectArea("SB2")
		DbSetOrder(1)
		DbSeek(xFilial("SB2")+SD1->D1_COD+SD1->D1_LOCAL) 
		nQteEtq			:= SB2->B2_QATU 
		MsgInfo("Impressão de etiquetas para inventário. Quantidade exibida é o estoque fisico do item")
	Endif 
	// Posiciona no cadastro de Produto
	DbSelectArea("SB1")
	DbSetOrder(1)
	DbSeek(xFilial("SB1")+SD1->D1_COD)

	cCodBar     := SB1->B1_CODBAR


	If __cUserId $ GetNewPar("GF_MLFAT11","000016")
		If MsgNoYes("Gerar apenas relatório de impressão de etiquetas?   Usado para quando não houver impressora Argox física.",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			lIsHomologa	:= .T.
		Endif
	Endif

	DEFINE MSDIALOG oDlgEtq FROM 000,000 TO 230,400 Of oMainWnd Pixel Title OemToAnsi("Informe o número de etiquetas que serão impressas!" )

	oPanelDlg := TPanel():New(0,0,'',oDlgEtq, oDlgEtq:oFont, .T., .T.,, ,200,65,.T.,.T. )
	oPanelDlg:Align := CONTROL_ALIGN_ALLCLIENT

	@ 010,005 Say "Número de Etiquetas" of oPanelDlg Pixel
	@ 010,060 MsGet nQteEtq	Size 40,10 Valid (nQteEtq > 0  .And. nQteEtq <= ( Iif(lImprInvent,9999,SD1->D1_QUANT - SD1->D1_XPRTETQ) ) ) Size 30,10 of oPanelDlg Pixel

	@ 026,005 Say "Código de Barras" of oPanelDlg Pixel
	@ 025,060 MsGet cCodBar	Size 60,10  Size 30,10 of oPanelDlg Pixel When .F.

	Activate MsDialog oDlgEtq On Init EnchoiceBar(oDlgEtq,{|| lOk := .T., oDlgEtq:End() },{|| oDlgEtq:End()},,)

	If !lOk
		Return
	Endif

	//Inicio da Imagem da Etiqueta

	//1  nXmm 		Array of Record		Posição X em Milímetros				X
	//2  nYmm		Array of Record		Posição Y em Milímetros				X
	//3  cTexto		Array of Record		String a ser impresso ou itens especificando uma variável "@".(Ex: "@2").
	//Obs: quando for especificado uma variável, o seu conteúdo deverá ser apenas o caractere "@" seguido de um número, "@1" ou "@2" e assim por diante.
	//4  cRotação Array of Record 	String com o tipo de Rotação (N,R,I,B): N - Normal R - Cima para baixo  I - Invertido B - Baixo para cima
	//5  cFonte 	Array of Record		String com os tipos de Fonte:
	//Zebra - (A,B,C,D,E,F,G,H,0) 0(zero)- fonte escalar
	//Datamax - (0,1,2,3,4,5,6,7,8,9) 9 – fonte escalar
	//Eltron - (0,1,2,3,4,5)
	//Intermec - (0,1,7,20,21,22,27)
	//6  cTam		Array of Record		String com o tamanho da Fonte
	//7  *lReverso 	Array of Record	Imprime em reverso quando tiver sobre um box preto
	//8  lSerial	Array of Record		Serializa o código
	//9  cIncr		Array of Record		Incrementa quando for serial positivo ou negativo
	//10 *lZerosL	Array of Record		Coloca zeros a esquerda no numero serial
	//11 lNoAlltrim	Array of Record		Permite brancos a esquerda e direi

	/*
	+-------------------------------------------------------------+
	|Dt.Ent.: 00/00/0000  N.NF.: 000000000                        |
	|                                                            |
	|Produto: 1234567890123456                                                             |
	| +----------------------------+                              |            
	| | Código de barras Ean13     |                              |
	| +----------------------------+                              |
	|                                                             |
	+-------------------------------------------------------------+
	*/

	DbSelectArea("CB0")
	RecLock("CB0",.T.)
	CB0->CB0_FILIAL	:= xFilial("CB0")
	CB0->CB0_CODETI := GetSXENum("CB0","CB0_CODETI")            //Cod.Etiqueta
	CB0->CB0_TIPO   := "01"                                     //Tipo da Etiq  01=Produto;02=Endereco;03=Unitizador;04=Usuario;05=Volume
	CB0->CB0_CODPRO := SD1->D1_COD                              //Produto
	CB0->CB0_QTDE   := nQteEtq                                  //Quantidade
	CB0->CB0_USUARI := cUserName                                //Usuario
	CB0->CB0_DISPID := ComputerName()                           //Dispositivo
	CB0->CB0_LOCAL  := SD1->D1_LOCAL                            //Almoxarifado
	//CB0->CB0_LOCALI                     //Endereco
	CB0->CB0_FORNEC := SD1->D1_FORNECE                          //Cod fornece
	CB0->CB0_LOJAFO := SD1->D1_LOJA                             //Loja fornece
	CB0->CB0_NFENT  := SD1->D1_DOC                              //NF de entrad
	CB0->CB0_SERIEE := SD1->D1_SERIE                            //Serie NF ent
	CB0->CB0_STATUS := "3"                                      //Status Etiq. 1=Encerrada Requisicao;2=Encerrada Inventario;3=Encerrada Mov. Interno.
	CB0->CB0_ITNFE  := SD1->D1_ITEM                             //Item NFE
	MsUnlock()

	ConfirmSX8()


	For iX := 1 To nQteEtq
		If !lIsHomologa
			cPrintMsg   := ""
			_cPorta := Alltrim(GetNewPar("GF_PORLPT2","LPT1:9600,n,8,1"))

			MSCBPRINTER("ALLEGRO",_cPorta,Nil,) 	//Seta tipo de impressora

			MSCBCHKSTATUS(.F.)

			MSCBBEGIN(1,4)

			
			cPrintTxt	:= " Produto: "
			cPrintMsg 	+= Chr(13)+Chr(10)+cPrintTxt

			MSCBSAY(05,30,cPrintTxt,"N","2","001,001") //Imprime Texto

			cPrintTxt	:= SB1->B1_COD
			cPrintMsg 	+= Chr(13)+Chr(10)+cPrintTxt

			MSCBSAY(20,27,cPrintTxt,"N","9","004,003") //Imprime Texto


			cPrintTxt	:= Substr(SB1->B1_DESC,1,24)
			cPrintMsg 	+= Chr(13)+Chr(10)+cPrintTxt

			MSCBSAY(06,23,cPrintTxt,"N","9","003,002") //Imprime Texto


			cPrintTxt	:= Substr(SB1->B1_DESC,25,16)
			cPrintMsg 	+= Chr(13)+Chr(10)+cPrintTxt

			MSCBSAY(06,19,cPrintTxt,"N","9","003,002") //Imprime Texto

			cPrintTxt	:= cCodBar
			cPrintMsg 	+= Chr(13)+Chr(10)+cPrintTxt

			MSCBSAY(33,1,cPrintTxt,"N","9","003,002") //Imprime Texto


			//MSCBSAYBAR(30,03,Alltrim(StrTran(AllTrim(Transform("33442Z","@R 99.99.9.X")),"-","")),"N","MB07",12,.F.,.T.,.F.,,2,2,.F.)
			//MSCBSAYBAR(06,10,AllTrim(cCodBar),,"N","MB04"/*MB04 - EAN 13 */,14,.T./*lDigver*/,.T./*lLinha*/,.F.,,3,2,.F.)

			MSCBSAYBAR(33,05.5,Alltrim(StrTran(AllTrim(cCodBar),"-","")),"N","MB07",12,.F.,.T.,.F.,,2,2,.F.)

			/*MSCBSAY(	nXmm 		Posição X em Milímetros
			nYmm 		Posição Y em Milímetros
			cTexto 		String a ser impresso 
			cRotação 	String com o tipo de Rotação (N,R,I,B): N - Normal R - Cima para baixo I - Invertido B - Baixo para cima
			cFonte 		String com os tipos de Fonte: Datamax - (0,1,2,3,4,5,6,7,8,9) 9 – fonte escalar
			cTam 		String com o tamanho da Fonte
			lReverso	Imprime em reverso quando tiver sobre um box preto
			*/ 



			cResult := MSCBEND()
			//MsgInfo(cResult)
			MSCBCLOSEPRINTER()

			// Atualiza a contagem de etiquetas impressas
			DbSelectArea("SD1")
			RecLock("SD1",.F.)
			SD1->D1_XPRTETQ += nQteEtq
			MsUnlock()

		Else
			cPrintMsg   := ""

			cPrintTxt	:= " Produto: "
			cPrintMsg 	+= Chr(13)+Chr(10)+cPrintTxt

			cPrintTxt	:= SB1->B1_COD
			cPrintMsg 	+= Chr(13)+Chr(10)+cPrintTxt

			cPrintTxt	:= Substr(SB1->B1_DESC,1,24)
			cPrintMsg 	+= Chr(13)+Chr(10)+cPrintTxt

			cPrintTxt	:= Substr(SB1->B1_DESC,25,16)
			cPrintMsg 	+= Chr(13)+Chr(10)+cPrintTxt

			cPrintTxt	:= "Cód.Bar: " + cCodBar
			cPrintMsg 	+= Chr(13)+Chr(10)+cPrintTxt

			If !Empty(cPrintMsg)
				Aviso("Impressão de etiqueta",cPrintMsg,{"Ok"},3)
			Endif
		Endif
	Next

	//MSCBSAYBAR(23,;	// 1 - Posição X em Milímetros
	//22,;			// 2 - Posição Y em Milímetros
	//Strzero(1,10),; // 3 - String a ser impressa especificando uma variável "@" ou array somente quando o parâmetro cTypePrt for igual á MB07.  cConteudo :={{"01","07893316010411"},; {"10","0000970100"+MSCB128B()+"1"+MSCB128C()},; {"37","0004"},; {"21","000494"}} • A possição 1 do array (ex: “01”) informa o AI utilizadado (que será visto no item 3.6.1. “Utilização do código de barras 128”).• Já a possição 2 do array (ex: "07893316010411”) é o conteúdo do AI.
	//"MB07",;		// 4 - String com o Modelo de Código de Barras: MB01 - Interleaved 2 of 5 / EAN14 MB02 - Code 39  MB03 - EAN 8 MB04 - EAN 13 MB05 - UPC A MB06 - UPC E MB07 - CODE 128 Obs: Caso o leitor queira utilizar o modelo do padrão de programação da impressora, o mesmo deverá consultar documentação do fabricante.
	//"C",;			// 5
	//8.36,;			// 6 - Altura do código de Barras em Milímetros
	//.F.,;
		//.T.,;
		//.F.,;
		//,;
		//2,;
		//1)

	//MemoWrit('FZPCPA01',cResult)


	RestArea(aAreaOld)

Return



/*/{Protheus.doc} sfNoAcento
//Função que remove caracteres especiais digitados. 
@author Marcelo Alberto Lauschner
@since 21/01/2019
@version 1.0
@return cString , Caractere 
@param cString, characters, descricao
@type function
/*/
Static Function sfNoAcento(cString)

	Local cChar  := ""
	Local nX     := 0
	Local nY     := 0
	Local cVogal := "aeiouAEIOU"
	Local cAgudo := "áéíóú"+"ÁÉÍÓÚ"
	Local cCircu := "âêîôû"+"ÂÊÎÔÛ"
	Local cTrema := "äëïöü"+"ÄËÏÖÜ"
	Local cCrase := "àèìòù"+"ÀÈÌÒÙ"
	Local cTio   := "ãõÃÕ"
	Local cCecid := "çÇ"
	Local cMaior := "&lt;"
	Local cMenor := "&gt;"
	Local cGrau	 := "ºª"

	For nX:= 1 To Len(cString)
		cChar:=SubStr(cString, nX, 1)
		IF cChar$cAgudo+cCircu+cTrema+cCecid+cTio+cCrase
			nY:= At(cChar,cAgudo)
			If nY > 0
				//MsgAlert(cValToChar(nY) + "|"+ cChar+"|"+SubStr(cVogal,nY,1),cAgudo)
				cString := StrTran(cString,cChar,SubStr(cVogal,nY,1))
			EndIf
			nY:= At(cChar,cCircu)
			If nY > 0
				//MsgAlert(cValToChar(nY) + "|"+ cChar+"|"+SubStr(cVogal,nY,1),cCircu)
				cString := StrTran(cString,cChar,SubStr(cVogal,nY,1))
			EndIf
			nY:= At(cChar,cTrema)
			If nY > 0
				//MsgAlert(cValToChar(nY) + "|"+ cChar+"|"+SubStr(cVogal,nY,1),cTrema)
				cString := StrTran(cString,cChar,SubStr(cVogal,nY,1))
			EndIf
			nY:= At(cChar,cCrase)
			If nY > 0
				//MsgAlert(cValToChar(nY) + "|"+ cChar+"|"+SubStr(cVogal,nY,1),cCrase)
				cString := StrTran(cString,cChar,SubStr(cVogal,nY,1))
			EndIf
			nY:= At(cChar,cTio)
			If nY > 0
				//MsgAlert(cValToChar(nY) + "|"+ cChar+"|"+SubStr("aoAO",nY,1),cTio)
				cString := StrTran(cString,cChar,SubStr("aoAO",nY,1))
			EndIf
			nY:= At(cChar,cCecid)
			If nY > 0
				cString := StrTran(cString,cChar,SubStr("cC",nY,1))
			EndIf

			nY:= At(cChar,cGrau)
			If nY > 0
				cString := StrTran(cString,cChar,SubStr("oa",nY,1))
			EndIf

		Endif
	Next

	If cMaior$ cString
		cString := strTran( cString, cMaior, "" )
	EndIf
	If cMenor$ cString
		cString := strTran( cString, cMenor, "" )
	EndIf

	cString := StrTran( cString, CRLF, " " )

	For nX:=1 To Len(cString)
		cChar:=SubStr(cString, nX, 1)
		If (Asc(cChar) < 32 .Or. Asc(cChar) > 123) .and. !cChar $ '|'
			cString:=StrTran(cString,cChar,".")
		Endif
	Next nX
Return cString
