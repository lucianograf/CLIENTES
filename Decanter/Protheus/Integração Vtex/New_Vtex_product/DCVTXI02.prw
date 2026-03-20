

#Include "Totvs.ch"
#Include "FwBrowse.ch"
#Include "FWMVCDEF.ch"
#Include "FWEditPanel.ch"
#Include "TopConn.ch"
Static __cProcPrinc  	:= "DCVTXI"
/*/{Protheus.doc} DCVTXI02
Função principal de inteface da Gestão de integração de Produtos com Vtex 
@type function
@version  
@author Marcelo Alberto Lauschner
@since 05/08/2024
@return variant, return_description
/*/
User Function DCVTXI02()

	Private cPrcLogFil	:= __cProcPrinc
	Private aRotina     :=  MenuDef()
	Private cCpoAltB1   :=  "B1_COD/B1_DESC/B1_PESBRU/B1_CODBAR/B1_PESO/B1_CODGTIN/B1_SAFRA/B1_ZFT/"            //Colocar aqui campos que podem ser alterados
	Private cCpoAltB5	:=  "B5_COD/B5_CEME/B5_COMPRLC/B5_ALTURLC/B5_LARGLC/" //Colocar aqui campos que podem ser alterados
	Private cCpoAltZFT	:=  "ZFT_COD/ZFT_DESCR/ZFT_CLASSI/ZFT_PORTIF/ZFT_SEGMEN/ZFT_LINHA/ZFT_PRODUT/ZFT_JAMES/ZFT_ADEGA/ZFT_PARKER/ZFT_SPECTA/ZFT_WINE/ZFT_VINOUS/ZFT_DECA/ZFT_TIM/"+;
		"ZFT_DESCOR/ZFT_PENIN/ZFT_JANCIS/ZFT_REVIST/ZFT_GRANDE/ZFT_ROSSO/ZFT_ELABOR/ZFT_HISTOR/ZFT_SOBREP/ZFT_PREMIO/ZFT_APRESE/ZFT_SUSTEN/"+;
		"ZFT_AMADUR/ZFT_INFO/ZFT_ROSCA/ZFT_DICAS/ZFT_GUARDA/ZFT_TEMPER/ZFT_ENOGAS/ZFT_SOLO/ZFT_CLIMA/ZFT_CRITIC/ZFT_ALCOOL/ZFT_VOLUME/ZFT_CORPO/ZFT_CASTA/ZFT_DTLREG/"  // Campos que não devem ser exibidos
	Private cCpoAltZ02	:= "Z02_CODIGO/Z02_DESCRI/Z02_CODREL/"  // Campos que não devem ser exibidos
	Private cCpoAltZ03	:= "Z03_CODIGO/Z03_APELID/Z03_DESCRI/Z03_SITE/Z03_PAIS/Z03_REGIAO/Z03_CODREL/Z03_SOBRE/Z03_VTEX/"  // Campos que não devem ser exibidos
	Private cCpoAltZ04	:= "Z04_CODIGO/Z04_TIPBBR/Z04_TIPUVA/Z04_DESCRI/Z04_CODREL/Z04_CTVTEX/"  // Campos que não devem ser exibidos
	Private cCpoAltDA1	:= "DA1_CODTAB/DA1_CODPRO/DA1_PRCVEN/DA1_ATIVO/DA1_ZPESPE/DA1_ITEM"  // Campos que não devem ser exibidos
	Private cCpoAltSB2	:= "B2_COD/B2_LOCAL/B2_QATU/B2_RESERVA/"  // Campos que não devem ser exibidos

	If cEmpAnt + cFilAnt <> "010101"
		MsgAlert("Somente é permitido usar esta rotina pela empresa '01' Filial '0101'","Acesso não permitido!")
	Endif
	If IsBlind()
		U_DCVTXI2H()
	Else
		DbSelectArea("SB2")
		DbSetOrder(1)

		aRotina := MenuDef()
		oBrowse := FWMBrowse():New()
		oBrowse:SetAlias('SB1')
		oBrowse:SetDescription(OemToAnsi("Controle de Integração Protheus x VTEX"))
		oBrowse:SetOnlyFields({'B1_COD','B1_SAFRA','B1_DESC','B1_PESO','B1_PESBRU','B1_CODBAR','B1_CODGTIN','B1_GRUPO','B1_ZFT'})
		oBrowse:AddFilter("Produtos Ativos com Ficha técnica" /*< cFilter>*/, '!Empty(B1_ZFT) .And. B1_MSBLQL <> "1"'/*< cExpAdvPL>*/, /*[ lNoCheck]*/, /*[ lSelected]*/, /*[ cAlias]*/, /*[ lFilterAsk]*/, /*[ aFilParser]*/, /*[ cID]*/ )
		oBrowse:AddFilter("Ficha técnica igual a" /*< cFilter>*/, 'B1_ZFT == %B1_ZFT% .And. B1_MSBLQL <> "1"'/*< cExpAdvPL>*/, /*[ lNoCheck]*/, /*[ lSelected]*/, /*[ cAlias]*/, /*[ lFilterAsk]*/, /*[ aFilParser]*/, /*[ cID]*/ )
		oBrowse:Activate()
	EndIf

Return


Static Function MenuDef()

	Local   aRotina     := {}
	Local 	aArea 		:= GetArea()

	ADD OPTION aRotina TITLE "Pesquisar"                ACTION "PesqBrw"                    OPERATION 0   ACCESS 0 //"Pesquisar"
	ADD OPTION aRotina TITLE "Visualizar"               ACTION "VIEWDEF.DCVTXI02"           OPERATION 2   ACCESS 0 //"Visualizar"
	ADD OPTION aRotina TITLE "Alterar"                  ACTION "VIEWDEF.DCVTXI02"           OPERATION 4   ACCESS 0 //"Alterar"
	ADD OPTION aRotina TITLE "Atualizar Vtex"           ACTION "U_DCVTXI2A(SB1->B1_COD)"    OPERATION 2   ACCESS 0
	ADD OPTION aRotina TITLE "Carga Full Vtex"          ACTION "U_DCVTXI2H()"			    OPERATION 2   ACCESS 0
	ADD OPTION aRotina TITLE "Pos Vtex - Produto"       ACTION "U_DCVTXI2B(SB1->B1_COD)"    OPERATION 2   ACCESS 0
	ADD OPTION aRotina TITLE "Pos Vtex - Especificação" ACTION "U_DCVTXI2C(SB1->B1_COD)"    OPERATION 2   ACCESS 0
	ADD OPTION aRotina TITLE "Pos Vtex - SKU"           ACTION "U_DCVTXI2D(SB1->B1_COD)"    OPERATION 2   ACCESS 0
	ADD OPTION aRotina TITLE "Pos Vtex - EAN"           ACTION "U_DCVTXI2E(SB1->B1_COD)"    OPERATION 2   ACCESS 0
	ADD OPTION aRotina TITLE "Logs de Sincronização"    ACTION "ProcLogView(,cPrcLogFil)"   OPERATION 2   ACCESS 0
	ADD OPTION aRotina TITLE "Eventos do Produto"       ACTION "ProcLogView(,SB1->B1_COD)"   OPERATION 2   ACCESS 0

	RestArea(aArea)

Return aRotina


Static Function ModelDef()

	Local oStructSB1 	:= FWFormStruct(1,"SB1", { |cCampo| Alltrim(cCampo)+"/" $ cCpoAltB1} )
	Local oStructSB5 	:= FWFormStruct(1,"SB5", { |cCampo| Alltrim(cCampo)+"/" $ cCpoAltB5} )
	Local oStructZFT 	:= FWFormStruct(1,"ZFT", { |cCampo| Alltrim(cCampo)+"/" $ cCpoAltZFT} )
	Local oStructZ02 	:= FWFormStruct(1,"Z02", { |cCampo| Alltrim(cCampo)+"/" $ cCpoAltZ02})
	Local oStructZ03 	:= FWFormStruct(1,"Z03", { |cCampo| Alltrim(cCampo)+"/" $ cCpoAltZ03})
	Local oStructZ04 	:= FWFormStruct(1,"Z04", { |cCampo| Alltrim(cCampo)+"/" $ cCpoAltZ04})
	Local oStructDA1 	:= FWFormStruct(1,"DA1", { |cCampo| Alltrim(cCampo)+"/" $ cCpoAltDA1})
	Local oStructSB2 	:= FWFormStruct(1,"SB2", { |cCampo| Alltrim(cCampo)+"/" $ cCpoAltSB2})
	Local oModel 		:= Nil						// Objeto do modelo de dados


	//-----------------------------------------
	//Monta o modelo do formulário
	//-----------------------------------------
	oModel:= MPFormModel():New("MODEL_DCVTXI02", /*Pre-Validacao*/, {|oModel| sfTudOk(oModel)}/*Pos-Validacao*/, {|oModel| sfCommit(oModel)}/*Commit*/, /*Cancel*/)
	oModel:AddFields("SB1MASTER", Nil/*cOwner*/, oStructSB1 ,/*Pre-Validacao*/,/*Pos-Validacao*/,/*Carga*/)
	oModel:AddGrid("SB5MASTER","SB1MASTER"/*cOwner*/, oStructSB5 ,/*Pre-Validacao*/,/*Pos-Validacao*/,/*Carga*/)


	//FwStruTrigger ( 'FIL_APROV' /*cDom*/, 'FIL_NOMAPR' /*cCDom*/, "A220Trigger('FIL_APROV')" /*cRegra*/, .F. /*lSeek*/, /*cAlias*/,  /*nOrdem*/, /*cChave*/, /*cCondic*/ )
	//aTrigger := FwStruTrigger("ZFT_PRODUT", "ZFT_DESCPR", "Z03->Z03_DESCRI",.T.,"Z03",1,'xFilial("Z03")+ZFT->ZFT_PRODUT')
	//oStructZFT:AddTrigger(aTrigger[1], aTrigger[2], aTrigger[3], aTrigger[4])

	oModel:AddGrid("ZFTMASTER","SB1MASTER"/*cOwner*/, oStructZFT ,/*Pre-Validacao*/,/*Pos-Validacao*/,/*Carga*/)
	oModel:AddGrid("Z03MASTER","ZFTMASTER"/*cOwner*/, oStructZ03 ,/*Pre-Validacao*/,/*Pos-Validacao*/,/*Carga*/)
	oModel:AddGrid("Z02MASTER","Z03MASTER"/*cOwner*/, oStructZ02 ,/*Pre-Validacao*/,/*Pos-Validacao*/,/*Carga*/)
	oModel:AddGrid("Z04MASTER","ZFTMASTER"/*cOwner*/, oStructZ04 ,/*Pre-Validacao*/,/*Pos-Validacao*/,/*Carga*/)
	oModel:AddGrid("DA1MASTER","SB1MASTER"/*cOwner*/, oStructDA1 ,/*Pre-Validacao*/,/*Pos-Validacao*/,/*Carga*/)
	oModel:AddGrid("SB2MASTER","SB1MASTER"/*cOwner*/, oStructSB2 ,/*Pre-Validacao*/,/*Pos-Validacao*/,/*Carga*/)

	// Faz relaciomaneto entre os compomentes do model

	oModel:SetRelation( 'SB5MASTER', { { 'B5_FILIAL', 'FWxFilial("SB5")'},{ 'B5_COD'	    , 'B1_COD' } }, SB5->( IndexKey( 1 ) ) )
	oModel:SetRelation( 'ZFTMASTER', { { 'ZFT_FILIAL', 'FWxFilial("ZFT")'},{ 'ZFT_COD'      , 'B1_ZFT' } }, ZFT->( IndexKey( 1 ) ) )
	oModel:SetRelation( 'Z03MASTER', { { 'Z03_FILIAL', 'FWxFilial("Z03")'},{ 'Z03_CODIGO'   , 'ZFT_PRODUT' } }, Z03->( IndexKey( 1 ) ) )
	oModel:SetRelation( 'Z02MASTER', { { 'Z02_FILIAL', 'FWxFilial("Z02")'},{ 'Z02_CODIGO'   , 'Z03_REGIAO' } }, Z02->( IndexKey( 1 ) ) )
	oModel:SetRelation( 'Z04MASTER', { { 'Z04_FILIAL', 'FWxFilial("Z04")'},{ 'Z04_CODIGO'   , 'ZFT_CLASSI' } }, Z04->( IndexKey( 1 ) ) )
	oModel:SetRelation( 'DA1MASTER', { { 'DA1_FILIAL', 'FWxFilial("DA1")'},{ 'DA1_CODPRO'   , 'B1_COD'} }, DA1->( IndexKey( 2 ) ) ) //DA1_FILIAL+DA1_CODPRO+DA1_CODTAB+DA1_ITEM

	//Agora fazendo o filtro na grid,
	oModel:GetModel('DA1MASTER'):SetLoadFilter(, "DA1_CODTAB IN('201','203','301')" )

	oModel:SetRelation( 'SB2MASTER', { { 'B2_FILIAL', 'FWxFilial("SB2")'} ,{ 'B2_COD'       , 'B1_COD' },{'B2_LOCAL','"02"'} }, SB2->( IndexKey( 1 ) ) )

	oModel:SetPrimaryKey({'B1_FILIAL','B1_COD'})

	//Define uma linha única para a grid
	oModel:GetModel("SB5MASTER"):SetUniqueLine({"B5_COD"})
	oModel:GetModel("SB5MASTER"):SetDelAllLine(.F.)
	oModel:GetModel("SB5MASTER"):SetOptional(.T.)

	oModel:GetModel("ZFTMASTER"):SetUniqueLine({"ZFT_COD"})
	oModel:GetModel("ZFTMASTER"):SetOptional(.T.)
	oModel:GetModel("ZFTMASTER"):SetDelAllLine(.F.)

	oModel:GetModel("Z03MASTER"):SetUniqueLine({"Z03_CODIGO"})
	oModel:GetModel("Z03MASTER"):SetOptional(.T.)
	oModel:GetModel("Z03MASTER"):SetDelAllLine(.F.)

	oModel:GetModel("Z02MASTER"):SetUniqueLine({"Z02_CODIGO"})
	oModel:GetModel("Z02MASTER"):SetOptional(.T.)
	oModel:GetModel("Z02MASTER"):SetDelAllLine(.F.)

	oModel:GetModel("Z04MASTER"):SetUniqueLine({"Z04_CODIGO"})
	oModel:GetModel("Z04MASTER"):SetOptional(.T.)
	oModel:GetModel("Z04MASTER"):SetDelAllLine(.F.)

	//oModel:GetModel("DA1MASTER"):SetUniqueLine({"DA1_CODTAB","DA1_CODPRO","DA1_ITEM"})
	oModel:GetModel("DA1MASTER"):SetOptional(.T.)
	oModel:GetModel("DA1MASTER"):SetDelAllLine(.F.)

	oModel:GetModel("SB2MASTER"):SetOptional(.T.)
	oModel:GetModel("SB2MASTER"):SetDelAllLine(.F.)

	// Desabilita edição de campos. São só para consulta de informação
	oStructSB1:SetProperty( 'B1_COD', MODEL_FIELD_WHEN, {|| .F.})
	oStructSB5:SetProperty( 'B5_COD', MODEL_FIELD_WHEN, {|| .F.})
	oStructSB1:SetProperty( 'B1_DESC', MODEL_FIELD_WHEN, {|| .F.})
	oStructZ03:SetProperty( 'Z03_CODIGO', MODEL_FIELD_WHEN, {|| .F.})
	oStructZ04:SetProperty( 'Z04_CODIGO', MODEL_FIELD_WHEN, {|| .F.})
	oStructZ02:SetProperty( 'Z02_CODIGO', MODEL_FIELD_WHEN, {|| .F.})
	oStructDA1:SetProperty( 'DA1_CODTAB', MODEL_FIELD_WHEN, {|| .F.})
	oStructDA1:SetProperty( 'DA1_CODPRO', MODEL_FIELD_WHEN, {|| .F.})

	//oStructSB2:SetProperty('B2QATU'       ,MODEL_FIELD_INIT, { || POSICIONE('SB2',1,XFILIAL('SB2')+SB1->B1_COD + "02","B2_QATU") } )
	//oStructSB2:SetProperty('B2QATU'       ,MODEL_FIELD_INIT, { || sfGetEst() } )
	//oStructSB2:SetProperty('B2RESERVA'    ,MODEL_FIELD_INIT, { || sfGetReserv() } )

	oModel:GetModel('ZFTMASTER'):SetNoInsertLine(.T.)
	oModel:GetModel('SB5MASTER'):SetNoInsertLine(.T.)
	oModel:GetModel('Z02MASTER'):SetNoInsertLine(.T.)
	oModel:GetModel('Z03MASTER'):SetNoInsertLine(.T.)
	oModel:GetModel('Z04MASTER'):SetNoInsertLine(.T.)
	oModel:GetModel('DA1MASTER'):SetNoInsertLine(.T.)
	oModel:GetModel('SB2MASTER'):SetNoInsertLine(.T.)

	//aGatilho := FwStruTrigger ( 'FIL_APROV' /*cDom*/, 'FIL_NOMAPR' /*cCDom*/, "A220Trigger('FIL_APROV')" /*cRegra*/, .F. /*lSeek*/, /*cAlias*/,  /*nOrdem*/, /*cChave*/, /*cCondic*/ )
	//oStru1:AddTrigger( aGatilho[1] /*cIdField*/, aGatilho[2] /*cTargetIdField*/, aGatilho[3] /*bPre*/, aGatilho[4] /*bSetValue*/ )
	oModel:SetDescription("Cadastro de Produtos e Dados Auxiliares - Integração VTEX")

Return oModel

Static Function ViewDef()

	//Local cCpoAltG1	    := "G1_COMP   /G1_QUANT  /G1_TRT    " //Colocar aqui campos que podem ser alterados
	Local oView  		:= Nil						//Objeto da interface
	Local oModel  		:= FWLoadModel("DCVTXI02")	//Objeto do modelo de dados
	Local oStructSB1 	:= FWFormStruct(2,"SB1", { |cCampo| Alltrim(cCampo)+"/" $ cCpoAltB1} )	//Estrutura da tabela SB1
	Local oStructSB5 	:= FWFormStruct(2,"SB5", { |cCampo| Alltrim(cCampo)+"/" $ cCpoAltB5} )	//Estrutura da tabela SB5
	Local oStructZFT 	:= FWFormStruct(2,"ZFT", { |cCampo| Alltrim(cCampo)+"/" $ cCpoAltZFT} )	//Estrutura da tabela ZFT
	Local oStructZ02 	:= FWFormStruct(2,"Z02", { |cCampo| Alltrim(cCampo)+"/" $ cCpoAltZ02} )	//Estrutura da tabela SG1
	Local oStructZ03 	:= FWFormStruct(2,"Z03", { |cCampo| Alltrim(cCampo)+"/" $ cCpoAltZ03} )	//Estrutura da tabela SG1
	Local oStructZ04 	:= FWFormStruct(2,"Z04", { |cCampo| Alltrim(cCampo)+"/" $ cCpoAltZ04} )	//Estrutura da tabela SG1
	Local oStructDA1 	:= FWFormStruct(2,"DA1", { |cCampo| Alltrim(cCampo)+"/" $ cCpoAltDA1} )	//Estrutura da tabela SG1
	Local oStructSB2 	:= FWFormStruct(2,"SB2", { |cCampo| Alltrim(cCampo)+"/" $ cCpoAltSB2} )	//Estrutura da tabela SG1

	//-----------------------------------------
	//Monta o modelo da interface do formulário
	//-----------------------------------------
	oView := FWFormView():New()
	oView:SetModel(oModel)
	oView:EnableControlBar(.T.)


	oStructSB2:SetProperty("B2_QATU", MVC_VIEW_CANCHANGE, .F.)
	oStructSB2:SetProperty("B2_RESERVA", MVC_VIEW_CANCHANGE, .F.)
	oStructDA1:SetProperty("DA1_PRCVEN", MVC_VIEW_CANCHANGE, .F.)
	oStructDA1:SetProperty("DA1_CODPRO", MVC_VIEW_CANCHANGE, .F.)

	//---------------------------------------------------------------------------------

	//Cria a visualizacao do cadastro
	//oView:AddField("VIEW_PRIN", oStructPrin, "SBMMASTER")
	//oView:AddField("VIEW_SECU", oStructSecu, "SBMMASTER")
	//oView:AddField("VIEW_TERC", oStructTerc, "SBMMASTER")

	//Cria o controle de Abas
	//oView:CreateFolder('ABAS')
	//oView:AddSheet('ABAS', 'ABA_PRIN', 'Aba 1 - Principal')
	// oView:AddSheet('ABAS', 'ABA_SECU', 'Aba 2 - Secundária')
	//oView:AddSheet('ABAS', 'ABA_TERC', 'Aba 3 - Outros Campos')

	//Cria os Box que serão vinculados as abas
	//oView:CreateHorizontalBox( 'BOX_PRIN' ,100, /*owner*/, /*lUsePixel*/, 'ABAS', 'ABA_PRIN')
	//oView:CreateHorizontalBox( 'BOX_SECU' ,100, /*owner*/, /*lUsePixel*/, 'ABAS', 'ABA_SECU')
	//oView:CreateHorizontalBox( 'BOX_TERC' ,100, /*owner*/, /*lUsePixel*/, 'ABAS', 'ABA_TERC')

	//Amarra as Abas aos Views de Struct criados
	//oView:SetOwnerView('VIEW_PRIN','BOX_PRIN')
	//oView:SetOwnerView('VIEW_SECU','BOX_SECU')
	//oView:SetOwnerView('VIEW_TERC','BOX_TERC')
	// ----------------------------------------------------------------------------

	oView:AddField( "VIEW_SB1" , oStructSB1 ,"SB1MASTER" )
	oView:AddGrid( "VIEW_SB5" , oStructSB5 ,"SB5MASTER" )
	oView:AddGrid( "VIEW_ZFT" , oStructZFT ,"ZFTMASTER" )
	oView:AddGrid( "VIEW_Z03" , oStructZ03 ,"Z03MASTER" )
	oView:AddGrid( "VIEW_Z04" , oStructZ04 ,"Z04MASTER" )
	oView:AddGrid( "VIEW_Z02" , oStructZ02 ,"Z02MASTER" )
	oView:AddGrid( "VIEW_DA1" , oStructDA1 ,"DA1MASTER" )
	oView:AddGrid( "VIEW_SB2" , oStructSB2 ,"SB2MASTER" )

	oView:CreateFolder('ABAS')
	oView:AddSheet('ABAS', 'ABA_SB1', 'Produtos')
	oView:AddSheet('ABAS', 'ABA_SB5', 'Complemento Produtos')
	oView:AddSheet('ABAS', 'ABA_ZFT', 'Ficha Técnica')
	oView:AddSheet('ABAS', 'ABA_Z03', 'Produtores')
	oView:AddSheet('ABAS', 'ABA_Z04', 'Categorias')
	oView:AddSheet('ABAS', 'ABA_Z02', 'Regiões')
	oView:AddSheet('ABAS', 'ABA_DA1', 'Preços')
	oView:AddSheet('ABAS', 'ABA_SB2', 'Estoque')

	oView:CreateHorizontalBox( 'BOX_SB1' ,100, /*owner*/, /*lUsePixel*/, 'ABAS', 'ABA_SB1')
	oView:CreateHorizontalBox( 'BOX_SB5' ,100, /*owner*/, /*lUsePixel*/, 'ABAS', 'ABA_SB5')
	oView:CreateHorizontalBox( 'BOX_ZFT' ,100, /*owner*/, /*lUsePixel*/, 'ABAS', 'ABA_ZFT')
	oView:CreateHorizontalBox( 'BOX_Z03' ,100, /*owner*/, /*lUsePixel*/, 'ABAS', 'ABA_Z03')
	oView:CreateHorizontalBox( 'BOX_Z04' ,100, /*owner*/, /*lUsePixel*/, 'ABAS', 'ABA_Z04')
	oView:CreateHorizontalBox( 'BOX_Z02' ,100, /*owner*/, /*lUsePixel*/, 'ABAS', 'ABA_Z02')
	oView:CreateHorizontalBox( 'BOX_DA1' ,100, /*owner*/, /*lUsePixel*/, 'ABAS', 'ABA_DA1')
	oView:CreateHorizontalBox( 'BOX_SB2' ,100, /*owner*/, /*lUsePixel*/, 'ABAS', 'ABA_SB2')

	oView:SetOwnerView( "VIEW_SB1" , "BOX_SB1" )
	oView:SetOwnerView( "VIEW_SB5" , "BOX_SB5" )
	oView:SetOwnerView( "VIEW_ZFT" , "BOX_ZFT" )
	oView:SetOwnerView( "VIEW_Z03" , "BOX_Z03" )
	oView:SetOwnerView( "VIEW_Z04" , "BOX_Z04" )
	oView:SetOwnerView( "VIEW_Z02" , "BOX_Z02" )
	oView:SetOwnerView( "VIEW_DA1" , "BOX_DA1" )
	oView:SetOwnerView( "VIEW_SB2" , "BOX_SB2" )

	//oView:EnableTitleView('VIEW_SB1',"Cadastro do Produto")
	//oView:EnableTitleView("VIEW_SB5","Cadastro de Complemento do Produto")
	//oView:EnableTitleView("VIEW_ZFT","Cadastro de Ficha Técnica")
	//oView:EnableTitleView("VIEW_Z03","Cadastro de Produtores")
	//oView:EnableTitleView("VIEW_Z02","Cadastro de Regiões")
	//oView:EnableTitleView("VIEW_Z04","Cadastro de Categorias")
	//oView:EnableTitleView("VIEW_SB2","Saldos Estoque para E-commerce Vtex")
	//oView:EnableTitleView('VIEW_DA1',"Tabelas de Preços")

Return oView

Static Function sfTudOk(oModel)

	Local lRet      := .T.  //Retorno da funcao
	Local nOpc      := 0	//Numero da operacao (1: Visualizacao, 3: Inclusao, 4: Alteracao, 5: Exclusao)
	Local cCodigo   := ""

	nOpc    := oModel:GetOperation()
	cCodigo := FwFldGet("B1_COD")

Return lRet


/*/{Protheus.doc} DCVTXI2A
Função para executa integração do produto por chamada de menu 
@type function
@version  
@author marcelo
@since 18/05/2024
@param cInCodPrd, character, param_description
@return variant, return_description
/*/
User Function DCVTXI2A(cInCodPrd)

	Local   cIdPrdVtex  := ""
	Local   nIdSkuVtex  := 0
	Local   cProc		:= __cProcPrinc
	Local   cSubProc    := Alltrim(cInCodPrd)
	Local   cIdCV8      := ""
	Local   cMensIni    := "Processo de integração Vtex/Produto:" + cInCodPrd

	//ProcLogAtu(cType,cMsg,cDetalhes,cBatchProc,lCabec,cFilProc)

	If MsgYesNo("Deseja executar a rotina de integração de Produtos com Vtex? ")
		ProcLogIni( {},cProc,cSubProc,@cIdCV8 )
		ProcLogAtu( "INICIO" , cMensIni ,,,.T. )

		// Efetua carga dos dados do Produto
		Processa({|| cIdPrdVtex := U_DCVTXI03(cInCodPrd) },"Aguarde! Enviando dados para o Vtex..")
		// Efetua carga da Ficha Técnica
		If !Empty(cIdPrdVtex)
			Processa({|| U_DCVTXI04(cInCodPrd,cIdPrdVtex) },"Aguarde! Enviando dados para o Vtex..")
			// Efetua vínculo da Politica Comercial
			Processa({|| U_DCVTXI05(cInCodPrd,cIdPrdVtex) },"Aguarde! Enviando dados para o Vtex..")
			// Efetua carga dos dados logisticos
			Processa({|| nIdSkuVtex := U_DCVTXI06(cInCodPrd,cIdPrdVtex) },"Aguarde! Enviando dados para o Vtex..")
			// Efetua carga do código Ean
			Processa({|| U_DCVTXI07(cInCodPrd,cIdPrdVtex,nIdSkuVtex) },"Aguarde! Enviando dados para o Vtex..")
			// Efetua carga do estoque
			Processa({|| U_DCVTXI08(cInCodPrd,cIdPrdVtex,,nIdSkuVtex) },"Aguarde! Enviando dados para o Vtex..")
			// Efetua carga de preços
			Processa({|| U_DCVTXI09(cInCodPrd,cIdPrdVtex,,nIdSkuVtex) },"Aguarde! Enviando dados para o Vtex" )
		Endif

		ProcLogAtu( "FIM" ,,,,.T.)
		ProcLogView(cFilAnt,cProc,cSubProc,cIdCV8)
	Endif

Return

/*/{Protheus.doc} DCVTXI2B
Função para fazer consulta de Produto Vtex 
@type function
@version  
@author marcelo
@since 18/05/2024
@param cInCodPrd, character, param_description
@return variant, return_description
/*/
User Function DCVTXI2B(cInCodPrd)
	U_DCVTXI03(cInCodPrd,1)
Return

/*/{Protheus.doc} DCVTXI2C
Função para consultar de Especificação Vtex 
@type function
@version  
@author marcelo
@since 18/05/2024
@param cInCodPrd, character, param_description
@return variant, return_description
/*/
User Function DCVTXI2C(cInCodPrd)
	U_DCVTXI04(cInCodPrd,,1)
Return

/*/{Protheus.doc} DCVTXI2D
Função para consultar SKU no VTex 
@type function
@version  
@author marcelo
@since 18/05/2024
@param cInCodPrd, character, param_description
@return variant, return_description
/*/
User Function DCVTXI2D(cInCodPrd)
	U_DCVTXI06(cInCodPrd,,1)
Return

/*/{Protheus.doc} DCVTXI2E
Função para consultar EAN no Vtex 
@type function
@version  
@author marcelo
@since 18/05/2024
@param cInCodPrd, character, param_description
@return variant, return_description
/*/
User Function DCVTXI2E(cInCodPrd)
	U_DCVTXI07(cInCodPrd,,,1)
Return

User Function DCVTXI2F(cInSerie,cInDoc)

	Local   cIdPrdVtex  := ""
	Local   nIdSkuVtex  := 0
	Local   cProc		:= "DCVTXI2F_"+Alltrim(cInDoc)
	Local   cSubProc    := Alltrim(cInDoc)
	Local   cIdCV8      := ""
	Local   cMensIni    := "Processo de integração Vtex Produtos da Nota " + cInDoc


	DbSelectArea("SD2")
	DbSetOrder(3)
	DbSeek(xFilial("SD2")+cInDoc+cInSerie)
	While !Eof() .And. SD2->(D2_FILIAL+D2_DOC+D2_SERIE) == xFilial("SD2")+cInDoc+cInSerie

		cSubProc    := Alltrim(SD2->D2_COD)

		ProcLogIni( {},cProc,cSubProc,@cIdCV8 )
		ProcLogAtu( "INICIO" , cMensIni ,,,.T. )

		// Efetua carga dos dados do Produto
		cIdPrdVtex := U_DCVTXI03(SD2->D2_COD)
		If !Empty(cIdPrdVtex)
			// Efetua carga da Ficha Técnica
			U_DCVTXI04(SD2->D2_COD,cIdPrdVtex)
			// Efetua vínculo da Politica Comercial
			U_DCVTXI05(SD2->D2_COD,cIdPrdVtex)
			// Efetua carga dos dados logisticos
			nIdSkuVtex := U_DCVTXI06(SD2->D2_COD,cIdPrdVtex)
			// Efetua carga do código Ean
			U_DCVTXI07(SD2->D2_COD,cIdPrdVtex,nIdSkuVtex)
			// Efetua carga do estoque
			U_DCVTXI08(SD2->D2_COD,cIdPrdVtex,,nIdSkuVtex)
			// Efetua carga de preço 
			U_DCVTXI09(SD2->D2_COD,cIdPrdVtex,nIdSkuVtex)
		Endif

		ProcLogAtu( "FIM" ,,,,.T.)

		DbSelectArea("SD2")
		DbSkip()
	Enddo

Return
/*/{Protheus.doc} DCVTXI2G
Função para atualizar produto no Vtex por chamada externa 
@type function
@version  
@author marcelo
@since 18/05/2024
@param cInCod, character, param_description
@return variant, return_description
/*/
User Function DCVTXI2G(cInCod)

	Local 	aAreaOld	:= GetArea()
	Local   cIdPrdVtex  := ""
	Local   nIdSkuVtex  := 0
	Local   cProc		:= "DCVTXI2G_"+Alltrim(cInCod)
	Local   cSubProc    := Alltrim(cInCod)
	Local   cIdCV8      := ""
	Local   cMensIni    := "Processo de integração Vtex Produto " + cInCod



	cSubProc    := Alltrim(cInCod)

	ProcLogIni( {},cProc,cSubProc,@cIdCV8 )
	ProcLogAtu( "INICIO" , cMensIni ,,,.T. )

	// Efetua carga dos dados do Produto
	cIdPrdVtex := U_DCVTXI03(cInCod)
	If !Empty(cIdPrdVtex)
		// Efetua carga da Ficha Técnica
		U_DCVTXI04(cInCod,cIdPrdVtex)
		// Efetua vínculo da Politica Comercial
		U_DCVTXI05(cInCod,cIdPrdVtex)
		// Efetua carga dos dados logisticos
		nIdSkuVtex := U_DCVTXI06(cInCod,cIdPrdVtex)
		// Efetua carga do código Ean
		U_DCVTXI07(cInCod,cIdPrdVtex,nIdSkuVtex)
		// Efetua carga do estoque
		U_DCVTXI08(cInCod,cIdPrdVtex,,nIdSkuVtex)
		// Efetua carga de preço 
		U_DCVTXI09(cInCod,cIdPrdVtex,,nIdSkuVtex)

	Endif
	ProcLogAtu( "FIM" ,,,,.T.)

	RestArea(aAreaOld)

Return
/*/{Protheus.doc} sfExec
//Executa a consulta de produtos que ainda não estão integrados e roda a função de integração para cada produto
@author Marcelo Alberto Lauschner 
@since 07/02/2019
@version 1.0
@return Nil 
@type Static Function
/*/
User Function DCVTXI2H()

	If IsBlind()
		sfExecFull()
	Else
		If MsgYesNo("Deseja executar a rotina de integração de Produtos com Vtex? ")
			Processa({|| sfExecFull() },"Aguarde! Enviando dados para o Vtex" )
		Endif
	Endif
Return

Static Function sfExecFull()

	beginSQL Alias "SB1TMP"
    
			 SELECT SB1.R_E_C_N_O_ AS B1RECNO
			   FROM %table:SB1% SB1
			  INNER JOIN %table:ZFT% ZFT 
			     ON ZFT.D_E_L_E_T_ <> '*'
				AND ZFT_COD = B1_ZFT
				AND ZFT_FILIAL = %xFilial:ZFT%
			  INNER JOIN %table:SB2% SB2 
			     ON SB2.D_E_L_E_T_ <> '*'
				AND B2_FILIAL = '0101'
				AND B2_COD = B1_COD
				AND B2_LOCAL = '02'
			  INNER JOIN %table:DA0% DA0 ON DA0.D_E_L_E_T_ <> '*'
				AND DA0_ATIVO = '1'
				AND DA0_CODTAB = '301'
				AND DA0_FILIAL = %xFilial:DA0%
			  INNER JOIN %table:DA1% DA1 ON DA1.D_E_L_E_T_ <> '*'
				AND DA1_CODTAB = DA0_CODTAB
				AND DA1_CODPRO = B1_COD
				AND DA1_PRCVEN <> 0
				AND DA1_ATIVO = '1'
				AND DA1_FILIAL = %xFilial:DA1%
			  INNER JOIN %table:Z03% Z03 
			     ON Z03.D_E_L_E_T_ <> '*'
				AND ZFT_PRODUT = Z03_CODIGO
				AND Z03_FILIAL = %xFilial:SZ03%
			  INNER JOIN %table:Z02% Z02 
			     ON Z02.D_E_L_E_T_ <> '*'
				AND Z02_CODIGO = Z03_REGIAO
				AND Z02_FILIAL = %xFilial:Z02%
			  INNER JOIN %table:Z04% Z04 
			     ON Z04.D_E_L_E_T_ <> '*'
				AND ZFT_CLASSI = Z04_CODIGO
				AND ZFT_FILIAL = %xFilial:ZFT%
			  INNER JOIN %table:SYA% SYA 
				 ON SYA.D_E_L_E_T_ <> '*'
				AND YA_CODGI = Z03_PAIS
				AND YA_FILIAL = %xFilial:SYA%
			  INNER JOIN %Table:SB5% B5 
				 ON B5.D_E_L_E_T_ <> '*'
				AND B5_COD = B1_COD 
				AND B5_FILIAL = %xFilial:SB5%
			  WHERE SB1.D_E_L_E_T_ <> '*'
				AND B1_TIPO = 'ME'
				AND B1_MSBLQL = '2' 
			 
	EndSQL
	Count to nCount
	SB1TMP->(dbGotop())

	ProcRegua(nCount)

	While !SB1TMP->(EOF())
		IncProc()
		DbSelectArea("SB1")
		DbGoto(SB1TMP->B1RECNO)

		U_DCVTXI2G(SB1->B1_COD)

		DbSelectArea("SB1TMP")
		DbSkip()
	Enddo
	SB1TMP->(DbCloseArea())
Return

Static Function SchedDef()
	// aReturn[1] - Tipo
	// aReturn[2] - Pergunte
	// aReturn[3] - Alias
	// aReturn[4] - Array de ordem
	// aReturn[5] - Titulo
Return { "P", "DCVTXI02", "", {}, "" }


Static Function sfCommit(oModel)

	Local lRet      := .T.  //Retorno da funcao
	Local nOpc      := 0	//Numero da operacao (1: Visualizacao, 3: Inclusao, 4: Alteracao, 5: Exclusao)
	Local cCodigo   := ""
	Default oModel := Nil

	nOpc    := oModel:GetOperation()
	cCodigo := FwFldGet("B1_COD")

	If nOpc == MODEL_OPERATION_INSERT // Incluir
		// Se precisar fazer algo antes de efetivar a inclusão
	ElseIf nOpc == MODEL_OPERATION_UPDATE // Alterar
		// Se precisar fazer algo antes de efetivar a alteração
	ElseIf nOpc == MODEL_OPERATION_DELETE // Excluir
		// Se precisar fazer alto antes de efetivar a Exclusão
	Endif

	BEGIN TRANSACTION

		// Persiste os Dados
		FWModelActive(oModel)
		FwFormCommit(oModel)


	END TRANSACTION

	// Efetua integração imediata com o Vtex
	U_DCVTXI2A(cCodigo)

Return lRet

