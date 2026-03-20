#include 'PROTHEUS.CH'
#include 'FINA811.CH'
#include 'FWMVCDEF.CH'
#Include 'TBICONN.CH'
#Include 'COLORS.CH'
#Include "FWMBROWSE.CH"
#Include "RWMAKE.CH"


//======================================================================================================================================
// Autor:Giovane Lucas Wiedermann | Vamilly
// Data: 26/10/2023
//======================================================================================================================================
// Programa: Wizard para inclusÃ£o de campanhas. 
//======================================================================================================================================


User Function DECAT001()
Local cNxtBtn := "Proximo"
Local cRetBtn := "Voltar"


Private oStepWiz	As object
Private o1stPage	As Object
Private o2ndPage	As Object
Private o3rdPage	As Object
Private o4thPage	As Object
Private o5thPage	As Object

// Variáveis PG1 
Private cIDCamp   := GetSXENum("SZ1","Z1_ID")
Private cNomCamp := Space(TamSX3('Z1_DESC')[1]) 
Private dIniCamp := CtoD('//')
Private dFimCamp := CtoD('//')
Private cDescCmp := Space(300)

// Variáveis PG2 




Private cProdDe  := Space(TamSX3('B1_COD')[1])  
Private cProdAte := 'ZZZZZZZZZZZZZZZ'
Private cGrpDe   := Space(TamSX3('BM_GRUPO')[1])  
Private cGrpAte  := 'ZZZZZZ'
Private cForDe   := Space(TamSX3('A2_COD')[1])  
Private cForate  := 'ZZZZZZ'
Private cFamde   := Space(TamSX3('YC_COD')[1])  
Private cFamAte  := Space(TamSX3('YC_COD')[1])  
Private cVenDe   := Space(TamSX3('A3_COD')[1])  
Private cVenAte  := 'ZZZZZZ'
Private cCnlDe	 := Space(TamSX3('A3_COD')[1])  
Private cCnlAte	 := 'ZZZZZZ'
Private cCmbImp  := Space(8)
Private nPerDesc := 0
Private nValDesc := 0


// Variáveis PG3 
Private cAlias := ""
Private cAliasSA3 as Character
Private oMrkVend	As Object
Private lMrkSA3 as logical


// Variáveis PG4

Private oMrkCnl As Object
Private lMrkSX5 as logical
Private lMrkSB1 as logical
Private cAliasCnl := "" 

// Variáveis PG5

Private oMrkCmp As Object
Private cAliasSB1 := "" 
Private nNewdesc  := 0


oStepWiz := FWWizardControl():New(,{600,850})//Instancia a classe FWWizardControl
oStepWiz:ActiveUISteps()

    //CriaÃ§Ã£o das pÃ¡ginas e steps do Wizard
	//----------------------
	// Pagina 1
	//----------------------
	o1stPage := oStepWiz:AddStep("1STSTEP",{|Panel| cria_pn1(Panel)}) // Adiciona um Step
	o1stPage:SetStepDescription('Carga Inicial') // Define o tÃ­tulo do "step"
	o1stPage:SetNextTitle(cNxtBtn) // Define o tÃ­tulo do botÃ£o de avanÃ§o
	o1stPage:SetNextAction({|| valid_pag1()}) // Define o bloco ao clicar no botÃ£o PrÃ³ximo
	o1stPage:SetCancelAction({|| .T.}) // Define o bloco ao clicar no botÃ£o Cancelar

    //----------------------
	// Pagina 2
	//----------------------
	o2ndPage := oStepWiz:AddStep("2NDSTEP", {|Panel| cria_pn2(Panel)})
	o2ndPage:SetStepDescription('Parametrizacao')
	o2ndPage:SetNextTitle(cNxtBtn)
	o2ndPage:SetPrevTitle(cRetBtn) // Define o tÃ­tulo do botÃ£o para retorno
	o2ndPage:SetNextAction({|| valid_pag2()})
	o2ndPage:SetCancelAction({|| BtnCancel()})
	o2ndPage:SetPrevAction({|| .T.}) //Define o bloco ao clicar no botÃ£o Voltar


    //----------------------
	// Pagina 3
	//----------------------
	o3rdPage := oStepWiz:AddStep("3RDSTEP", {|Panel|cria_pn3(Panel)})
	o3rdPage:SetStepDescription("Selecionar Vendedores")
	o3rdPage:SetNextTitle(cNxtBtn)
	o3rdPage:SetPrevTitle(cRetBtn)
	o3rdPage:SetNextAction({|| .T.})
	o3rdPage:SetPrevAction({|| BackToPg2()})
	o3rdPage:SetCancelAction({|| BtnCancel()})

    //----------------------
	// Pagina 4
	//----------------------
	o4thPage := oStepWiz:AddStep("4THSTEP", {|Panel|cria_pn4(Panel)})
	o4thPage:SetStepDescription("Selecionar Canais")
	o4thPage:SetNextTitle(cNxtBtn)
	o4thPage:SetPrevTitle(cRetBtn)
	o4thPage:SetPrevAction({|| BackToPg3()})
	o4thPage:SetCancelAction({|| BtnCancel()})


	//----------------------
	// Pagina 5
	//----------------------
	o5thPage := oStepWiz:AddStep("5THSTEP", {|Panel|cria_pn5(Panel)})
	o5thPage:SetStepDescription("Finalizar o Processo")
	o5thPage:SetNextTitle("Concluir")
	o5thPage:SetPrevTitle(cRetBtn)
	o5thPage:SetNextAction({||Confirm()})
	o5thPage:SetPrevAction({|| BackToPg4()})
	o5thPage:SetCancelAction({|| BtnCancel()})


    oStepWiz:Activate()
	oStepWiz:Destroy()

Return 



//--------------------------------------------
// FunÃ§Ãµes de RelaÃ§Ã£o com o Browse 
//--------------------------------------------
Static Function BtnCancel() As Logical

	Local lRet As Logical

	lRet := MsgYesNo("Cancelar o processo ?","DECAT001")
	If lRet 
		SetKey(VK_F4, {||})
		RollBackSX8()
	EndIf 

Return lRet

//--------------------------------------------
// FunÃ§Ãµes PÃ¡gina 1
//--------------------------------------------
Static Function cria_pn1(oDlg as Object)
	Private  oTFont := TFont():New('Courier new',,16,.T.)
	Private oTFont2 := TFont():New(,,-12,.T.,.T.,,,,,)
	Private oPanel as Object
	Private oPanel2 as Object 


	// Cria o Quadro maior ao fundo 
	oPanel:=TGet():New(01,01,{||  } ,oDlg,428,203,'@!',,,CLR_GRAY,,,,.T.,,,,,,,.T.,,,,,,,)

	// ID Campanha
	TSay():New(10,10,{|| 'ID Campanha'},oPanel,,,,,,.T.,CLR_BLACK,) //
	TGet():New(20,10,{|u|  cIDCamp  } ,oPanel,60,12,'@!',,,CLR_GRAY,,,,.T.,,,,,,,.T.,,,'cIDCamp',,,,)

	// Nome Campanha
	TSay():New(40,10,{|| 'Nome Campanha'},oPanel,,,,,,.T.,CLR_BLACK,) //
	TGet():New(50,10,{|u| if( PCount() > 0, cNomCamp := u, cNomCamp ) } ,oPanel,120,12,'@!',,,,,,,.T.,,,,,,,,,,'cNomCamp',,,,)

	// Inicio Vigencia
	TSay():New(70,10,{|| 'Inicio Vigencia'},oPanel,,,,,,.T.,CLR_BLACK,) //
	TGet():New(80,10,{|u| if( PCount() > 0, dIniCamp := u, dIniCamp ) } ,oPanel,60,12,,,,,,,,.T.,,,,,,,,,,'dIniCamp',,,,)

	// Fim Vigencia
	TSay():New(100,10,{|| 'Fim Vigencia'},oPanel,,,,,,.T.,CLR_BLACK,) //
	TGet():New(110,10,{|u| if( PCount() > 0, dFimCamp := u, dFimCamp ) } ,oPanel,60,12,,,,,,,,.T.,,,,,,,,,,'dFimCamp',,,,)

	// Detalhes Campanha
	TSay():New(130,10,{|| 'Detalhes Campanha'},oPanel,,,,,,.T.,CLR_BLACK,) //
	TGet():New(140,10,{|u| if( PCount() > 0, cDescCmp := u, cDescCmp ) } ,oPanel,160,40,'@!',,,,,,,.T.,,,,,,,,,,'cDescCmp',,,,)

	// Cria o Painel com o texto informativo
	oPanel2 := TGet():New(21,200,{|u| if( PCount() > 0, cDescCmp := u, cDescCmp ) } ,oDlg,200,100,'@!',,,CLR_GRAY,,,,.T.,,,,,,,.T.,,,'',,,,)

	TSay():New(01,05,{|| 'Processo de Geração de Campanhas de venda'},oPanel2,,oTFont2,,,,.T.,CLR_BLACK,)
	TSay():New(25,05,{|| 'Clique em "Próximo" para:'},oPanel2,,,,,,.T.,CLR_BLACK,) 	
	TSay():New(35,10,{|| '- Definir os parâmetros da rotina;'},oPanel2,,,,,,.T.,CLR_BLACK,) 
	TSay():New(45,10,{|| '- Selecionar os Vendedores envolvidos;'},oPanel2,,,,,,.T.,CLR_BLACK,) 
	TSay():New(55,10,{|| '- Selecionar os Canais Envolvidos;'},oPanel2,,,,,,.T.,CLR_BLACK,) 	
	TSay():New(65,10,{|| '- Selecionar os Produtos e descontos na campanha;'},oPanel2,,,,,,.T.,CLR_BLACK,) 	
	TSay():New(75,10,{|| '- Conferencia;'},oPanel2,,,,,,.T.,CLR_BLACK,) 	
	TSay():New(85,05,{|| 'Ao final do processo, será gerada a campanha para os dados selecionados.'},oPanel2,,,,,,.T.,CLR_BLACK,) 	


Return 

Static Function Valid_pag1
	Local lRet := .T. 

	If Empty(cNomCamp) .Or. Empty(dIniCamp) .Or. Empty(dFimCamp) 
		FWAlertError("Parâmetros inválidos para continuidade!","DECAT001")
		lRet := .F.
	EndIf

	If lRet .And. dFimCamp < Date() 
		lRet := FWAlertYesNo("Data de fim da vigência menor que a data atual, a campanha será considerada INVÁLIDA, deseja continuar ?","DECAT001")
	EndIf
Return lRet
//--------------------------------------------
// FunÃ§Ãµes PÃ¡gina 2
//--------------------------------------------
Static Function cria_pn2(oDlg as Object)
	Private oBoard as Object 
	Private oPanel as Object 
	Private oTFont2 := TFont():New(,,-16,.T.,.T.,,,,,)
	Private aOptions := {'1=Decanter','2=Timbro','3=Ambos'}

	oBoard:=TGet():New(01,01,{||   } ,oDlg,428,67,'@!',,,CLR_GRAY,,,,.T.,,,,,,,.T.,,,'',,,,)
	oPanel:=TGet():New(71,01,{||   } ,oDlg,428,133,'@!',,,CLR_GRAY,,,,.T.,,,,,,,.T.,,,'',,,,)



	TSay():New(01,05,{|| 'Seleção dos itens das campanhas'},oBoard,,oTFont2,,,,.T.,CLR_BLACK,)
	TSay():New(25,05,{|| 'Preencha os parâmetros abaixo de acordo com os dados de produtos que irão ser envolvidos na pesquisa'},oBoard,,,,,,.T.,CLR_BLACK,) 	
	TSay():New(35,05,{|| 'Na etapa 5 desse Processo será possível Filtrar e marcar os itens que irão de fato para a campanha '},oBoard,,,,,,.T.,CLR_BLACK,) 


	// Produto De?
	TSay():New(05,10,{|| 'Produto De?'},oPanel,,,,,,.T.,CLR_BLACK,) //
	TGet():New(05,66,{|u| if( PCount() > 0, cProdDe := u, cProdDe ) } ,oPanel,60,12,X3Picture('B1_COD'),,,,,,,.T.,,,,,,,,,'SB1','cProdDe',,,,)

	// Produto Ate?
	TSay():New(30,10,{|| 'Produto Ate?'},oPanel,,,,,,.T.,CLR_BLACK,) //
	TGet():New(30,66,{|u| if( PCount() > 0, cProdAte := u, cProdAte ) } ,oPanel,60,12,X3Picture('B1_COD'),,,,,,,.T.,,,,,,,,,'SB1','cProdAte',,,,)

	// Grupo de Produto De?
	TSay():New(55,10,{|| 'Grupo de Produto De?'},oPanel,,,,,,.T.,CLR_BLACK,) //
	TGet():New(55,66,{|u| if( PCount() > 0, cGrpDe := u, cGrpDe ) } ,oPanel,60,12,X3Picture('BM_GRUPO'),,,,,,,.T.,,,,,,,,,'SBM','cGrpDe',,,,)

	// Grupo de Produto Ate?
	TSay():New(80,10,{|| 'Grupo de Produto Ate?'},oPanel,,,,,,.T.,CLR_BLACK,) //
	TGet():New(80,66,{|u| if( PCount() > 0, cGrpAte := u, cGrpAte ) } ,oPanel,60,12,X3Picture('BM_GRUPO'),,,,,,,.T.,,,,,,,,,'SBM','cGrpAte',,,,)

	// Fornecedor De?
	TSay():New(05,130,{|| 'Produtor De?'},oPanel,,,,,,.T.,CLR_BLACK,) //
	TGet():New(05,190,{|u| if( PCount() > 0, cForDe := u, cForDe ) } ,oPanel,60,12,X3Picture('A2_COD'),,,,,,,.T.,,,,,,,,,'Z03PRT','cForDe',,,,)

	// Fornecedor Ate?
	TSay():New(30,130,{|| 'Produtor Ate?'},oPanel,,,,,,.T.,CLR_BLACK,) //
	TGet():New(30,190,{|u| if( PCount() > 0, cForate := u, cForate ) } ,oPanel,60,12,X3Picture('A2_COD'),,,,,,,.T.,,,,,,,,,'Z03PRT','cForate',,,,)

	// Familia de produtos De?
	TSay():New(55,130,{|| 'Valor de desconto?'},oPanel,,,,,,.T.,CLR_BLACK,) //
	TGet():New(55,190,{|u| if( PCount() > 0, nValDesc := u, nValDesc ) } ,oPanel,60,12,"@< 999,999.99",,,,,,,.T.,,,,,,,,,,'nValDesc',,,,)

	// Familia de produtos Ate?
	TSay():New(80,130,{|| 'Perc. de desconto ?'},oPanel,,,,,,.T.,CLR_BLACK,) //
	TGet():New(80,190,{|u| if( PCount() > 0, nPerDesc := u, nPerDesc ) } ,oPanel,60,12,"@< 99.99",,,,,,,.T.,,,,,,,,,,'nPerDesc',,,,)

	// Vendedor De? 
	TSay():New(05,256,{|| 'Vendedor De?'},oPanel,,,,,,.T.,CLR_BLACK,) //
	TGet():New(05,316,{|u| if( PCount() > 0, cVenDe := u, cVenDe ) } ,oPanel,60,12,X3Picture('A3_COD'),,,,,,,.T.,,,,,,,,,'SA3','cVenDe',,,,)

	// Vendedor Ate?
	TSay():New(30,256,{|| 'Vendedor Ate?'},oPanel,,,,,,.T.,CLR_BLACK,) //
	TGet():New(30,316,{|u| if( PCount() > 0, cVenAte := u, cVenAte ) } ,oPanel,60,12,X3Picture('A3_COD'),,,,,,,.T.,,,,,,,,,'SA3','cVenAte',,,,)

	// Canal De?
	TSay():New(55,256,{|| 'Canal De?'},oPanel,,,,,,.T.,CLR_BLACK,) //
	TGet():New(55,316,{|u| if( PCount() > 0, cCnlDe := u, cCnlDe ) } ,oPanel,60,12,X3Picture('SYC_COD'),,,,,,,.T.,,,,,,,,,'SX5ZA','cCnlDe',,,,)

	// Canal Ate?'
	TSay():New(80,256,{|| 'Canal Ate?'},oPanel,,,,,,.T.,CLR_BLACK,) //
	TGet():New(80,316,{|u| if( PCount() > 0, cCnlAte := u, cCnlAte ) } ,oPanel,60,12,X3Picture('SYC_COD'),,,,,,,.T.,,,,,,,,,'SX5ZA','cCnlAte',,,,)

	/*// Canal de importação 
	TSay():New(105,10,{|| 'Canal de Importação ?'},oPanel,,,,,,.T.,CLR_BLACK,)
	TComboBox():New(105,66,{|u| if( PCount() > 0, cCmbImp := u, cCmbImp ) },aOptions,60,12,oPanel,,,,,,.T.,,,,,,,,,'cCmbImp')*/

Return 

Static Function BackToPg2

Return .T.

Static Function Valid_pag2
	Local lRet := .T.

	/*iF Empty(cProdAte) .Or. Empty(cGrpAte) .Or. Empty(cForate) .Or. Empty(cFamAte) .Or. Empty(cVenAte) .Or. Empty(cCnlAte)
		IF FWAlertYesNo("Alguns parametros não foram definidos, o sistema irá considerar todos os registros para esses casos, deseja continuar?","DECAT001")
			


		EndIf
	EndIf */
Return lRet


//--------------------------------------------
// FunÃ§Ãµes PÃ¡gina 3
//--------------------------------------------
Static Function cria_pn3(oDlg as Object)
	Local aStruct 	:= {}	As Array
	Local aColumns  := {}	As Array
	Local nX 		:= 1	As Numeric
	Local aSeek		:= {}	As Array
	
	Local oGetSA3	:= Dec001SA3():New()
	Local oPanel	as Object 



	oPanel:=TGet():New(01,01,{|u|  } ,oDlg,428,203,'@!',,,CLR_GRAY,,,,.T.,,,,,,,.T.,,,,,,,)

	oGetSA3:GetAlias() 
	aStruct := oGetSA3:aStruct 
	cAliasSA3  := oGetSA3:cAlias
	lMrkSA3 := .F.

	For nX := 1 To Len(aStruct)
		If	Rtrim(aStruct[nX][1]) $ 'A3_FILIAL|A3_COD|A3_NOME'
			AAdd(aColumns,FWBrwColumn():New())
			aColumns[Len(aColumns)]:SetData( &('{||'+aStruct[nX][1]+'}') )
			aColumns[Len(aColumns)]:SetTitle(RetTitle(aStruct[nX][1]))
			aColumns[Len(aColumns)]:SetSize(aStruct[nX][3])
			aColumns[Len(aColumns)]:SetDecimal(aStruct[nX][4])
			aColumns[Len(aColumns)]:SetPicture(PesqPict('SA3',aStruct[nX][1]))				
		EndIf
	Next nX

	AAdd(aSeek,{'Nome Vendedor',{{"A3_NOME","C",TamSX3("A3_NOME")[1],0,"",""}},1})

	oMrkVend:= FWMarkBrowse():New()
	oMrkVend:oBrowse:SetEditCell(.T.)
	oMrkVend:oBrowse:SetMenuDef('DECAT001')
	//oMrkLayout:oBrowse:SetMainProc("FINA811")
	oMrkVend:SetFieldMark("A3_MRK")
	oMrkVend:SetOwner(oPanel)
	oMrkVend:SetAlias(cAliasSA3)
	oMrkVend:SetProfileId("0001")
	oMrkVend:SetAllMark({|| SetMrkAll(1,cAliasSA3) })
	oMrkVend:bAfterMark := {|| oMrkVend:Refresh()}
	oMrkVend:SetValid({|| MrkValid(cAliasSA3)})
	oMrkVend:SetDescription('')
	oMrkVend:SetColumns(aColumns)
	oMrkVend:SetSeek(.T.,aSeek)
	oMrkVend:Activate()


Return 


Static Function BackToPg3

Return .T.

//--------------------------------------------
// FunÃ§Ãµes PÃ¡gina 4
//--------------------------------------------
Static Function cria_pn4(oDlg as Object)
	Local aStruct 	:= {}	As Array
	Local aColumns  := {}	As Array
	Local nX 		:= 1	As Numeric
	Local aSeek		:= {}	As Array
	//Local cAlias	:= ""
	Local oGetCnl	:= Dc001SX5():New()
	Local oPanel	as Object 


	oPanel:=TGet():New(01,01,{||  } ,oDlg,428,203,'@!',,,CLR_GRAY,,,,.T.,,,,,,,.T.,,,,,,,)

	oGetCnl:GetAlias() 
	aStruct := oGetCnl:aStruct 
	cAliasCnl  := oGetCnl:cAlias
 	lMrkSX5 := .F.

	For nX := 1 To Len(aStruct)
		If	Rtrim(aStruct[nX][1]) $ 'X5_FILIAL|X5_CHAVE|X5_DESCRI'
			AAdd(aColumns,FWBrwColumn():New())
			aColumns[Len(aColumns)]:SetData( &('{||'+aStruct[nX][1]+'}') )
			aColumns[Len(aColumns)]:SetTitle(RetTitle(aStruct[nX][1]))
			aColumns[Len(aColumns)]:SetSize(aStruct[nX][3])
			aColumns[Len(aColumns)]:SetDecimal(aStruct[nX][4])
			aColumns[Len(aColumns)]:SetPicture(PesqPict('SX5',aStruct[nX][1]))				
		EndIf
	Next nX

	AAdd(aSeek,{'Nome Vendedor',{{"X5_DESCRI","C",TamSX3("X5_DESCRI")[1],0,"",""}},1})

	oMrkCnl:= FWMarkBrowse():New()
	oMrkCnl:oBrowse:SetEditCell(.T.)
	//oMrkLayout:oBrowse:SetMainProc("FINA811")
	oMrkCnl:SetFieldMark("X5_MRK")
	oMrkCnl:oBrowse:SetMenuDef('DECAT001')
	oMrkCnl:SetOwner(oPanel)
	oMrkCnl:SetAlias(cAliasCnl)
	oMrkCnl:SetProfileId("0001")
	oMrkCnl:SetAllMark({|| SetMrkAll(2,cAliasCnl) })
	oMrkCnl:bAfterMark := {|| oMrkCnl:Refresh()}
	oMrkCnl:SetValid({|| MrkValid(cAliasCnl)})
	oMrkCnl:SetDescription('')
	oMrkCnl:SetColumns(aColumns)
	oMrkCnl:SetSeek(.T.,aSeek)
	oMrkCnl:Activate()
Return 

Static Function BackToPg4

Return .T.
//--------------------------------------------
// FunÃ§Ãµes PÃ¡gina 5
//--------------------------------------------

Static Function cria_pn5(oDlg as Object)
	Local aStruct 	:= {}	As Array
	Local aColumns  := {}	As Array
	Local nX 		:= 1	As Numeric
	Local aSeek		:= {}	As Array
	Local cMsg		:= "Para alterar o % de desconto de um item, basta utilizar a tecla F4."
	//Local cAlias	:= ""
	Local oGetCmp	:= Dc001SB1():New()
	Local oPanel	as Object 

	oPanel:=TGet():New(01,01,{||  } ,oDlg,428,203,'@!',,,CLR_GRAY,,,,.T.,,,,,,,.T.,,,,,,,)

	//

	oGetCmp:GetAlias() 
	aStruct := oGetCmp:aStruct 
	cAliasSB1  := oGetCmp:cAlias
 	lMrkSX5 := .F.

	For nX := 1 To Len(aStruct)	 	
		If	Rtrim(aStruct[nX][1]) $ 'B1_FILIAL|B1_COD|B1_DESC|B1_GRUPO'//|B1_CNLIMP|B1_SAFRA|B1_TIPVIN'
			AAdd(aColumns,FWBrwColumn():New())
			aColumns[Len(aColumns)]:SetData( &('{||'+aStruct[nX][1]+'}') )
			aColumns[Len(aColumns)]:SetTitle(RetTitle(aStruct[nX][1]))
			aColumns[Len(aColumns)]:SetSize(aStruct[nX][3])
			aColumns[Len(aColumns)]:SetDecimal(aStruct[nX][4])
			aColumns[Len(aColumns)]:SetPicture(PesqPict('SB1',aStruct[nX][1]))				
		EndIf
		If	Rtrim(aStruct[nX][1]) $ 'Z2_PERDESC|Z2_VALDESC|Z2_QMIN'//|B1_CNLIMP|B1_SAFRA|B1_TIPVIN'
			AAdd(aColumns,FWBrwColumn():New())
			aColumns[Len(aColumns)]:SetData( &('{||'+aStruct[nX][1]+'}') )
			aColumns[Len(aColumns)]:SetTitle(RetTitle(aStruct[nX][1]))
			aColumns[Len(aColumns)]:SetSize(aStruct[nX][3])
			aColumns[Len(aColumns)]:SetDecimal(aStruct[nX][4])
			aColumns[Len(aColumns)]:SetPicture(PesqPict('SZ2',aStruct[nX][1]))				
		EndIf
		If	Rtrim(aStruct[nX][1]) $ 'B1_MRK'//|B1_CNLIMP|B1_SAFRA|B1_TIPVIN'
			AAdd(aColumns,FWBrwColumn():New())
			aColumns[Len(aColumns)]:SetData( &('{||'+aStruct[nX][1]+'}') )
			aColumns[Len(aColumns)]:SetTitle('MKR')
			aColumns[Len(aColumns)]:SetSize(aStruct[nX][3])
			aColumns[Len(aColumns)]:SetDecimal(aStruct[nX][4])
			aColumns[Len(aColumns)]:SetPicture("@!")				
		EndIf

	Next nX

	AAdd(aSeek,{'Produto',{{"B1_COD","C",TamSX3("B1_COD")[1],0,"",""}},1})
	AAdd(aSeek,{'Produto',{{"B1_DESC","C",TamSX3("B1_DESC")[1],0,"",""}},1})

	oMrkCmp:= FWMarkBrowse():New()
	oMrkCmp:oBrowse:SetEditCell(.T.)
	oMrkCmp:oBrowse:SetPreEditCell({||  .T.})
	oMrkCmp:oBrowse:SetMenuDef('DECAT001')
	//oMrkLayout:oBrowse:SetMainProc("FINA811")
	oMrkCmp:SetFieldMark("B1_MRK")
	oMrkCmp:SetOwner(oPanel)
	oMrkCmp:SetAlias(cAliasSB1)
	oMrkCmp:SetProfileId("0001")
	oMrkCmp:SetAllMark({|| SetMrkAll(3,cAliasSB1) })
	//oMrkCmp:bAfterMark := {|| oMrkCmp:Refresh()}
	oMrkCmp:SetValid({|| MrkValid(cAliasSB1)})
	oMrkCmp:SetDescription('Para editar o % de desconto posicione no registro e pressione a tecla F4')
	oMrkCmp:SetColumns(aColumns)
	oMrkCmp:SetSeek(.T.,aSeek)
	oMrkCmp:AddButton('Filtros',{|| FilterPnl(cAliasSB1)},,2)
	//oMrkCmp:AddButton('Editar', {|| AlterDesc(oPanel,(cAliasSB1)->B1_COD)},,2)

	SetKey(VK_F4, {|| AlterDesc(oPanel,(cAliasSB1)->B1_COD)})

	TSay():New(05,05,{|| cMsg},oPanel,,,,,,.T.,CLR_BLACK,) 
	oMrkCmp:Activate()

Return 

Static Function BackToPg5

Return .T.

Static Function Confirm 
	Local lRet As Logical

	If  MsgYesNo("Confirma a geração das campanhas para os itens selecionados? ","DECAT001")
		FwMsgRun(Nil,{|| Dec001Run() },"Gerando Campanha","Gravando Registros da Campanha "+ AllTrim(cIDCamp))
		lRet := .T. 
	Else 
		lRet := .F.
	EndIf

	If lRet
		ConfirmSX8()
		FWAlertSucess("Campanha gerada com sucesso!!")

	EndIf 

Return lRet      

Static Function AlterDesc(oPanel as Object,cProd as Character)
	Local oWindow as Object 
	Local cPrdEnd := cProd
	Local cXCmb  := '1'
	Local aCombo := {"1=Código Raiz","2=Código inteiro"}

	
	nNewDesc := 0 
	oWindow := TGet():New(60,100,{||  } ,oPanel,150,130,'@!',,,CLR_GRAY,,,,.T.,,,,,,,.T.,,,,,,,)

	// Produto De?
	TSay():New(05,10,{|| 'Produto De?'},oWindow,,,,,,.T.,CLR_BLACK,) //
	TGet():New(05,80,{|u| if( PCount() > 0, cProd := u, cProd )} ,oWindow,60,12,X3Picture('B1_COD'),,,,,,,.T.,,,,,,,,,,'cProd',,,,)

	// Produto Ate?
	TSay():New(25,10,{|| 'Produto Ate?'},oWindow,,,,,,.T.,CLR_BLACK,) //
	TGet():New(25,80,{|u| if( PCount() > 0, cPrdEnd := u, cPrdEnd )} ,oWindow,60,12,X3Picture('B1_COD'),,,,,,,.T.,,,,,,,,,,'cPrdEnd',,,,)

	TSay():New(85,10,{|| 'Filtrar produto por?'},oWindow,,,,,,.T.,CLR_BLACK,) //
	TComboBox():New(85, 80, {|u| if( PCount() > 0, cXCmb := u, cXCmb )}, aCombo, 062, 010, oWindow,,,,,,.T.,,,,,,,,,'cXCmb')

	// Familia de produtos Ate?
	TSay():New(45,10,{|| 'Perc. de desconto atual ?'},oWindow,,,,,,.T.,CLR_BLACK,) //
	TGet():New(45,80,{|u|  nPerDesc  } ,oWindow,60,12,"@< 99.99",,,,,,,.T.,,,,,,,.T.,,,'nPerDesc',,,,)

	// Perc de desconto novo 
	TSay():New(65,10,{|| 'Novo Perc. de desconto ?'},oWindow,,,,,,.T.,CLR_BLACK,) //
	TGet():New(65,80,{|u| if( PCount() > 0, nNewDesc := u, nNewDesc ) } ,oWindow,60,12,"@< 99.99",,,,,,,.T.,,,,,,,,,,'nNewDesc',,,,)

	TButton():New(110,100,"Confirmar"    ,oWindow,{|| SetDesc(oWindow,cXCmb,cProd,cPrdEnd) },037,010,,,,.T.,,"",,,,.F. )

	TButton():New(110,30,"Cancelar"    ,oWindow,{|| oWindow:lVisibleControl:= .f. },037,012,,,,.T.,,"",,,,.F. )


Return


Static Function SetDesc(oWindow as Object,cOpc AS Character,cProd as Character,cPrdEnd as Character)
	Local cAlias := GetNextAlias() 
	Local aArea  := (cAliasSB1)->( GetArea())
	Local cPar01 := IIF(Len(AllTrim(cProd))=5,cProd,SubStr(cProd,2,5))
	Local cPar02 := IIF(Len(AllTrim(cPrdEnd))=5,cPrdEnd,SubStr(cPrdEnd,2,5))
	Local lAlt	:= .F.


	//cAlias := GetPrdRg(cProd,cProdEnd)

	If nNewDesc > 0 

		DBSelectArea(cAliasSB1) 
		(cAliasSB1)->( DbGoTop() )
		While !(cAliasSB1)->( EoF() )
			lAlt := .F.

			IF cOpc == '2' 
				IF (cAliasSB1)->B1_COD >= cProd .And.  (cAliasSB1)->B1_COD <= cPrdEnd
					lAlt := .T. 
				EndIf 
			Else 
				IF SubStr((cAliasSB1)->B1_COD,2,5) >= cPar01 .And. SubStr((cAliasSB1)->B1_COD,2,5) <= cPar02
					lAlt := .T. 
				EndIf 
			EndIf 

			If lAlt 
				RecLock(cAliasSB1)
					( cAliasSB1 ) -> Z2_PERDESC := nNewDesc
				( cAliasSB1 ) ->( MsUnlock() )
			EndIf


		(cAliasSB1) ->(DbSkip()) 
		EndDo  	

	Else 
		FWAlertError("Percentual informado como zero, processo cancelado!","DECAT001")

	EndIf 

	RestArea(aArea)
	oWindow:lVisibleControl:= .f.
	oMrkCmp:Refresh()

Return 
//--------------------------------------------
// Funções Gerais
//--------------------------------------------



Static Function MrkValid(cAlias as Character) As Logical
	Local cCodCrt	As Character
	Local aAreaFWP	As Array

	/*cCodCrt		:= (cAlias)->FWP_CODCRT
	aArea	:= (cAlias)->(GetArea())

	(cAlias)->(dbGoTop())

	While !(cAlias)->(Eof())
		If (cAlias)->FWP_CODCRT != cCodCrt
			(cAlias)->FWP_OK := ''
		EndIf
		(cTrabFWP)->(dbSkip())
	EndDo

	RestArea(cAlias)*/
Return .T.

Static Function SetMrkAll(nTrab as Numeric,cAlias as Character) 
	Local aArea		As Array
	Local cMarca	As Character

	cMarca := ""

	If nTrab == 1
		aArea:=(cAlias)->( GetArea() )
		If lMrkSA3 
			cMarca := "" 
			lMrkSA3 := .F.
		Else 
			cMarca := oMrkVend:cMark
			lMrkSA3 := .T.
		EndIf 

		While !(cAlias)->(Eof())
			(cAlias)->A3_MRK := cMarca
		(cAlias)->(DbSkip())
		EndDo

		RestArea(aArea)
		oMrkVend:Refresh()

	ElseIf nTrab == 2 
		aArea:=(cAlias)->( GetArea() )
		If lMrkSX5 
			cMarca  := "" 
			lMrkSX5 := .F.
		Else 
			cMarca  := oMrkCnl:cMark 
			lMrkSX5 := .T.
		EndIf

		While !(cAlias)->(Eof())
			(cAlias)->X5_MRK := cMarca
		(cAlias)->(DbSkip())
		EndDo

		RestArea(aArea)
		oMrkCnl:Refresh()
 
	ElseIf nTrab == 3
		aArea:=(cAlias)->( GetArea() )
		If lMrkSB1
			cMarca  := "" 
			lMrkSB1 := .F.
		Else 
			cMarca  := oMrkCmp:cMark 
			lMrkSB1 := .T.
		EndIf

		While !(cAlias)->(Eof())
			(cAlias)->B1_MRK := cMarca
		(cAlias)->(DbSkip())
		EndDo

		RestArea(aArea)
		oMrkCmp:Refresh()

	EndIf 


Return 

Static Function FilterPnl(cBrowse as Character)
	Local cAlias  := GetNextAlias()
	Local aArea   := (cBrowse)->( GetArea() )
	Local cPrdFrm := ""
	Local cPrdTo := ""

	If Pergunte("DECAT001",.T.)

		If FwAlertYesNo("Deseja limpar os itens marcados ?")
			While !(cBrowse)->( EoF() )
				If !Empty((cBrowse)->B1_MRK)
					RecLock(cBrowse,.F.)
						(cBrowse)->B1_MRK := ""
					(cBrowse)->(MSUnlock())
				EndIf
			(cBrowse)->(DbSkip())
			EndDo
		EndIf

		cPrdFrm := IIF(Len(Alltrim(MV_PAR03))=5,MV_PAR03,SubStr(MV_PAR03,2,5))
		cPrdTo  := IIF(Len(Alltrim(MV_PAR04))=5,MV_PAR04,SubStr(MV_PAR04,2,5))

		
		If mv_par09 = 1 //Código Raiz 
			BeginSQL Alias cAlias 
				SELECT
						B1_FILIAL
					,	B1_COD
					,	B1_DESC 
				FROM
					%Table:SB1% SB1 INNER JOIN %Table:ZFT% ZFT ON 
						ZFT_FILIAL = B1_FILIAL 
					AND ZFT_COD = B1_ZFT 
					AND ZFT_PRODUT BETWEEN %Exp:MV_PAR07% AND %Exp:MV_PAR08% 
					AND ZFT.%Notdel%
				WHERE
					SUBSTRING(B1_COD,2,5) BETWEEN %Exp:cPrdFrm% AND %Exp:cPrdTo%
				AND B1_GRUPO BETWEEN %Exp:MV_PAR05% AND %Exp:MV_PAR06%
				AND	SB1.D_E_L_E_T_ = '' 
			EndSql 
		Else 
			BeginSQL Alias cAlias 
				SELECT
						B1_FILIAL
					,	B1_COD
					,	B1_DESC 
				FROM
					%Table:SB1% SB1 INNER JOIN %Table:ZFT% ZFT ON 
						ZFT_FILIAL = B1_FILIAL 
					AND ZFT_COD = B1_ZFT 
					AND ZFT_PRODUT BETWEEN %Exp:MV_PAR07% AND %Exp:MV_PAR08% 
					AND ZFT.%Notdel%
				WHERE
					B1_COD BETWEEN %Exp:MV_PAR03% AND %Exp:MV_PAR04%
				AND B1_GRUPO BETWEEN %Exp:MV_PAR05% AND %Exp:MV_PAR06%
				AND	SB1.D_E_L_E_T_ = '' 
			EndSql
		EndIf

		DBSelectArea(cAlias)

		While  !(cAlias)->( EoF() )
			DbSelectArea(cBrowse)
			(cBrowse)->( DBGoTop())
			(cBrowse)->( DBSetOrder(1))
			(cBrowse)->( DbSeek((cAlias)->B1_COD) )
			If Found() 
				RecLock(cBrowse,.F.)
					(cBrowse)->B1_MRK := oMrkCmp:cMark
				(cBrowse)->(MSUnlock())
			EndIf
		(cAlias)->( DbSkip() )
		EndDo

		RestArea(aArea)
		oMrkCmp:Refresh()	
	EndIf
Return 

Static Function Dec001Run()
Local lHasZA3 := .F.


	DBSelectArea("SZ1")
	SZ1->( DBSetOrder(1) )

	DBSelectArea("SZ2")
	SZ2->( DBSetOrder(1) )

	DbSelectArea("SZ3")
	SZ3->( DbSetOrder(1) )


	Begin Transaction 

		// Cabeçalho 
		RecLock("SZ1",.T.)
			SZ1->Z1_FILIAL  := xFilial("SZ1")
			SZ1->Z1_ID		:=  cIDCamp    
			SZ1->Z1_DESC   	:= cNomCamp
			SZ1->Z1_STATUS 	:= '1'
			SZ1->Z1_DTINI  	:= dIniCamp
			SZ1->Z1_DTFIM  	:= dFimCamp
			SZ1->Z1_USER   	:= __cUserId	
			SZ1->Z1_DTINC  	:= Date()
		SZ1->( MsUnlock() )


		// Produto
		DbSelectArea(cAliasSB1)

		While !(cAliasSB1)->( Eof() )
			iF !Empty((cAliasSB1)->B1_MRK)
				RecLock("SZ2",.T.)
					SZ2->Z2_FILIAL  := xFilial("SZ2")
					SZ2->Z2_ID      := cIDCamp
					SZ2->Z2_GRPROD  := (cAliasSB1)->(B1_GRUPO)
					SZ2->Z2_GPDESC  := (cAliasSB1)->(BM_DESC)
					SZ2->Z2_PRODUTO := (cAliasSB1)->(B1_COD)
					SZ2->Z2_PRDESC 	:= (cAliasSB1)->(B1_DESC)
					SZ2->Z2_PERDESC	:= (cAliasSB1)->(Z2_PERDESC)
					SZ2->Z2_VALDESC	:= (cAliasSB1)->(Z2_VALDESC)
					SZ2->Z2_QMIN   	:= (cAliasSB1)->(Z2_QMIN)
				SZ2->( MsUnlock() )
			EndIf
		(cAliasSB1)->( DbSkip() )			
		EndDo 

		// Grava os vendedores e canais se Houverem 
		DbSelectArea(cAliasSA3)

			While !(cAliasSA3)->( Eof() )

				iF !Empty((cAliasSA3)->A3_MRK)
					lHasZA3 := .T. 
					RecLock("SZ3",.T.)
						SZ3->Z3_FILIAL := xFilial("SZ3")
						SZ3->Z3_ID     := cIDCamp
						SZ3->Z3_VEND   := (cAliasSA3)->(A3_COD)
					//	SZ3->Z3_CANAL  := (cAliasSA3)->(A3_CANAL)
						SZ3->Z3_NOME   := (cAliasSA3)->(A3_NOME)
					SZ3->(MsUnlock())
				EndIf

			(cAliasSA3)->( DbSkip() )			
			EndDo 

		// Grava os vendedores e canais se Houverem 
		DbSelectArea(cAliasCnl)

			While !(cAliasCnl)->( Eof() )

				iF !Empty((cAliasCnl)->X5_MRK)
					lHasZA3 := .T. 
					RecLock("SZ3",.T.)
						SZ3->Z3_FILIAL := xFilial("SZ3")
						SZ3->Z3_ID     := cIDCamp
						SZ3->Z3_CANAL  := (cAliasCnl)->(X5_CHAVE)
						SZ3->Z3_NOME   := (cAliasCnl)->(X5_DESCRI)
					SZ3->(MsUnlock())
				EndIf
			(cAliasCnl)->( DbSkip() )			
			EndDo 


		IF !lHasZA3 
			RecLock("SZ3",.T.)
				SZ3->Z3_FILIAL := xFilial("SZ3")
				SZ3->Z3_ID     := cIDCamp			
			SZ3->(MsUnlock())
		EndIf

	End Transaction 

	SetKey(VK_F4, {||})
Return 


//--------------------------------------------
// Classes e Métodos auxiliares auxiliares 
//--------------------------------------------

Class DecAt001 

	Data cAlias as Char 
	Data cLastQuery as Char
	Data cFieldList as Char 
	Data aFieldList as Array
	Data aStruct as Array 
	Data oTempTable as Object 
	//Data cLastQuery as Character

	Method new() Constructor
	Method GetAlias()
	Method getQuery()
	Method setUp()
	Method setCustomIndex()

EndClass 

Class Dec001SA3 From DecAt001


	Method new() Constructor
	Method getQuery()
	Method setUp()
	Method setCustomIndex()
	Method GetAlias()

EndClass 

Class Dc001SX5 From DecAt001


	Method new() Constructor
	Method getQuery()
	Method setUp()
	Method setCustomIndex()
	Method GetAlias()

EndClass 

Class Dc001SB1 From DecAt001


	Method new() Constructor
	Method getQuery()
	Method setUp()
	Method setCustomIndex()
	Method GetAlias()

EndClass 

Method New() class DecAt001
	::cAlias     := getNextAlias()
	::cLastQuery := ""
	::aStruct    := {}
	::cFieldList := ""
	::aFieldList := {}
Return Self


Method New() class Dec001SA3
	_Super:New()
	::SetUp()

Return Self 	

Method New() class Dc001SX5
	_Super:New()
	::SetUp()

Return Self 

Method New() class Dc001SB1
	_Super:New()
	::SetUp()

Return Self 

Method GetQuery() class Dec001SA3

	Private cQuery := GetNextAlias()
		
	BeginSQL Alias cQuery 
	SELECT 
			A3_FILIAL
		,	A3_COD
		,	A3_NOME
	FROM
		%Table:SA3% SA3 
	WHERE
			A3_FILIAL = %Exp:xFilial("SA3")%
		AND A3_COD BETWEEN %Exp:cVenDe% AND %Exp:cVenAte%
		AND A3_MSBLQL = '2'
		AND SA3.%Notdel%
	EndSQL 

Return cQuery

Method GetQuery() class Dc001SX5

	Private cQuery := GetNextAlias()
		
	BeginSQL Alias cQuery 
		SELECT 
				X5_FILIAL
			,	X5_CHAVE
			,	X5_DESCRI
		FROM
			%Table:SX5% SX5 
		WHERE
				X5_FILIAL = %Exp:xFilial("SX5")%
			AND X5_CHAVE BETWEEN %Exp:cCnlDe% AND %Exp:cCnlAte%
			AND X5_TABELA = 'ZA'
			AND SX5.%Notdel%
	EndSQL 

Return cQuery

Method GetQuery() class Dc001SB1
	Local cPrdDNew := IIF(Len(Alltrim(cProdDe))>5,SubStr(cProdDe,2,5),cProdDe)
	Local cPrdANew := IIF(Len(Alltrim(cProdAte))>5,SubStr(cProdAte,2,5),cProdAte)

	Private cQuery := GetNextAlias()
		
	BeginSQL Alias cQuery 
		SELECT
				B1_FILIAL
			,	B1_COD
			,	B1_DESC 
			,	B1_GRUPO
			,	(SELECT BM_DESC FROM %TABLE:SBM% SBM WHERE BM_GRUPO = B1_GRUPO AND SBM.%notdel%) BM_DESC	
		FROM
			%Table:SB1% SB1 INNER JOIN %Table:ZFT% ZFT ON 
				ZFT_FILIAL = B1_FILIAL 
			AND ZFT_COD = B1_ZFT 
			AND ZFT_PRODUT BETWEEN %Exp:cForDe% AND %Exp:cForate%
			AND ZFT.%Notdel% 
		WHERE
				B1_FILIAL = %Exp:xFilial("SB1")%
			AND SUBSTRING(B1_COD,2,5) BETWEEN %Exp:cPrdDNew% AND %Exp:cPrdANew%
			AND B1_GRUPO BETWEEN %Exp:cGrpDe% AND %Exp:cGrpAte%
			AND SB1.%Notdel%
	EndSQL 



Return cQuery

Method setCustomIndex() Class Dec001SA3

	::oTempTable:AddIndex("1", {"A3_COD"})
	::oTempTable:AddIndex("2", {"A3_NOME"})
Return

Method setCustomIndex() Class Dc001SX5

	::oTempTable:AddIndex("1", {"X5_CHAVE"})
	::oTempTable:AddIndex("2", {"X5_DESCRI"})
Return

Method setCustomIndex() Class Dc001SB1

	::oTempTable:AddIndex("1", {"B1_COD"})
	::oTempTable:AddIndex("2", {"B1_DESC"})
Return

Method Setup() Class Dec001SA3 
	Local nX as Numeric


	::cFieldList := "A3_FILIAL;A3_COD;A3_NOME"

	::aFieldList := strTokArr(::cFieldList, ";")

	For nX := 1 To len(::aFieldList)
		AAdd(::aStruct, FWSX3Util():getFieldStruct( allTrim(::aFieldList[nX]) ))
	Next nX

	aAdd(::aStruct, {'A3_MRK','C',1,0}) // Adiciono o campo de marca


Return 

Method Setup() Class Dc001SX5 
	Local nX as Numeric


	::cFieldList := "X5_FILIAL;X5_CHAVE;X5_DESCRI"

	::aFieldList := strTokArr(::cFieldList, ";")

	For nX := 1 To len(::aFieldList)
		AAdd(::aStruct, FWSX3Util():getFieldStruct( allTrim(::aFieldList[nX]) ))
	Next nX

	aAdd(::aStruct, {'X5_MRK','C',1,0}) // Adiciono o campo de marca


Return 

Method Setup() Class Dc001SB1 
	Local nX as Numeric


	::cFieldList := "Z1_ID;B1_FILIAL;B1_COD;Z2_PERDESC;B1_DESC;B1_GRUPO;BM_DESC;A2_COD;Z1_DESC;Z1_DTINI;Z1_DTFIM;Z2_VALDESC;Z2_QMIN"//B1_CNLIMP|B1_SAFRA|B1_TIPVIN"

	::aFieldList := strTokArr(::cFieldList, ";")

	For nX := 1 To len(::aFieldList)
		AAdd(::aStruct, FWSX3Util():getFieldStruct( allTrim(::aFieldList[nX]) ))
	Next nX

	aAdd(::aStruct, {'B1_MRK','C',1,0}) // Adiciono o campo de marca


Return 

Method GetAlias() Class Dec001SA3
 Local cQuery := Self:getQuery()

	If ::oTempTable == NIL
		::oTempTable := FWTemporaryTable():New( ::cAlias )
		::oTempTable:SetFields(::aStruct)
		::setCustomIndex()
		::oTempTable:Create()
	EndIf

	DBSelectArea(cQuery)
	While !(cQuery)->(EoF())
		RecLock(::cAlias,.T.)
		(::cAlias)->A3_FILIAL   := (cQuery)->A3_FILIAL
		(::cAlias)->A3_COD 		:= (cQuery)->A3_COD
		(::cAlias)->A3_NOME		:= (cQuery)->A3_NOME
		(::cAlias)->(MSUnlock())
		
	(cQuery)->(DbSkip())
	EndDo

	(cQuery)->(DbCloseArea())		


Return

Method GetAliaS() Class Dc001SX5
 Local cQuery := Self:getQuery()
 
	If ::oTempTable <> Nil
		nTcSql := TcSQLExec("DELETE FROM " + ::oTempTable:GetRealName() )
		If nTcSql < 0 //Se ocorrer algum problema refaz a temporária
			::oTempTable:Delete()
			::oTempTable := Nil
		Else
			(::cAlias)->(dbGoTo(1))  //Necessário para atualização do Alias após deleção dos dados
		EndIf
	EndIf

	If ::oTempTable == NIL
		::oTempTable := FWTemporaryTable():New( ::cAlias )
		::oTempTable:SetFields(::aStruct)
		::setCustomIndex()
		::oTempTable:Create()
	EndIf

	DBSelectArea(cQuery)
	While !(cQuery)->(EoF())
	
		RecLock(::cAlias,.T.)
		(::cAlias)->X5_FILIAL   := (cQuery)->X5_FILIAL
		(::cAlias)->X5_CHAVE 	:= (cQuery)->X5_CHAVE 
		(::cAlias)->X5_DESCRI	:= (cQuery)->X5_DESCRI
		(::cAlias)->(MSUnlock())
		
	(cQuery)->(DbSkip())
	EndDo

	(cQuery)->(DbCloseArea())		


Return

Method GetAlias() Class Dc001SB1
 Local cQuery := Self:getQuery()


	If ::oTempTable <> Nil
		nTcSql := TcSQLExec("DELETE FROM " + ::oTempTable:GetRealName() )
		If nTcSql < 0 //Se ocorrer algum problema refaz a temporária
			::oTempTable:Delete()
			::oTempTable := Nil
		Else
			(::cAlias)->(dbGoTo(1))  //Necessário para atualização do Alias após deleção dos dados
		EndIf
	EndIf

	If ::oTempTable == NIL
		::oTempTable := FWTemporaryTable():New( ::cAlias )
		::oTempTable:SetFields(::aStruct)
		::setCustomIndex()
		::oTempTable:Create()
	EndIf


	//;Z1_DTINI;Z1_DTFIM;Z2_PERDESC;Z2_VALDESC;Z2_QMIN
	DBSelectArea(cQuery)
	While !(cQuery)->(EoF())
		RecLock(::cAlias,.T.)
			(::cAlias)->Z1_ID		:= cIDCamp
			(::cAlias)->B1_FILIAL   := (cQuery)->B1_FILIAL
			(::cAlias)->B1_COD 		:= (cQuery)->B1_COD
			(::cAlias)->B1_DESC		:= (cQuery)->B1_DESC
			(::cAlias)->B1_GRUPO	:= (cQuery)->B1_GRUPO
			(::cAlias)->BM_DESC		:= (cQuery)->BM_DESC
			(::cAlias)->Z1_DESC		:= cNomCamp 
			(::cAlias)->Z1_DTINI	:= dIniCamp
			(::cAlias)->Z1_DTFIM	:= dFimCamp
			(::cAlias)->Z2_PERDESC	:= nPerDesc 
			(::cAlias)->Z2_VALDESC	:= nValDesc 
			(::cAlias)->Z2_QMIN		:= 0 
		(::cAlias)->(MSUnlock())
		
	(cQuery)->(DbSkip())
	EndDo

	(cQuery)->(DbCloseArea())		


Return
