#include 'PROTHEUS.CH'
#include 'FWMVCDEF.CH'
#Include 'TBICONN.CH'
#Include 'COLORS.CH'
#Include "FWMBROWSE.CH"
#Include "RWMAKE.CH"


User Function DECAT002 
    Local oBrowse as Object
    Local aSeek := {}

    oBrowse := FWMBrowse():New()
    oBrowse:SetAlias("SZ1")

    oBrowse:SetDescription("Manutenção das Campanhas de Venda")
    oBrowse:DisableDetails()

    oBrowse:AddLegend("Z1_STATUS == '1'","GREEN","Campanha Ativa")
    oBrowse:AddLegend("Z1_STATUS == '2'","GRAY","Campanha Inativa")

    
	AAdd(aSeek,{'ID ',{{"Z1_ID","C",TamSX3("Z1_ID")[1],0,"",""}},1})

    oBrowse:SetSeek(.T.,aSeek)

	oBrowse:Activate()

Return 


Static Function MenuDef()
Local aRotina := {}

	//Adicionando opcoes do menu [Padrão]
	ADD OPTION aRotina TITLE "Visualizar" ACTION "VIEWDEF.DECAT002" OPERATION 1 ACCESS 0
	//ADD OPTION aRotina TITLE "Incluir"    ACTION "VIEWDEF.DECAT002" OPERATION 3 ACCESS 0
	ADD OPTION aRotina TITLE "Alterar" 	  ACTION "VIEWDEF.DECAT002" OPERATION 4 ACCESS 0
	ADD OPTION aRotina TITLE "Excluir" 	  ACTION "VIEWDEF.DECAT002" OPERATION 5 ACCESS 0
	ADD OPTION aRotina TITLE "Copiar"  	  ACTION "VIEWDEF.DECAT002" OPERATION 9 ACCESS 0

	//Adicionando opçoes do menu [customizado]
	ADD OPTION aRotina TITLE "Gerar Campanhas" ACTION "U_DECAT001()" OPERATION 3 ACCESS 0
	ADD OPTION aRotina TITLE "Simular Campanha" ACTION "U_Dec02Sim()" OPERATION 8 ACCESS 0
	ADD OPTION aRotina TITLE "Consultar Log" ACTION "U_Dec003BRW()" OPERATION 7 ACCESS 0

Return aRotina


Static Function ModelDef() 

    Local oStSZ1 := FWFormStruct(1, 'SZ1')
    Local oStSZ2 := FWFormStruct(1, 'SZ2')
    Local oStSZ3 := FWFormStruct(1, 'SZ3')
    Local oModel as Object 

    oModel := MPFormModel():New("DECAT02M")
    oModel:AddFields("SZ1MASTER", /*cOwner*/, oStSZ1)
    oModel:AddGrid("SZ2DETAIL","SZ1MASTER",oStSZ2,/*bLinePre*/, /*bLinePost*/,/*bPre - Grid Inteiro*/,/*bPos - Grid Inteiro*/,/*bLoad - Carga do modelo manualmente*/)
    oModel:AddGrid("SZ3DETAIL","SZ1MASTER",oStSZ3,/*bLinePre*/, /*bLinePost*/,/*bPre - Grid Inteiro*/,/*bPos - Grid Inteiro*/,/*bLoad - Carga do modelo manualmente*/)

	oStSZ2:SetProperty("Z2_PRODUTO", MODEL_FIELD_VALID, { || fGetDesc("P", ""       , "Z2_PRODUTO", "Z2_PRDESC", "SZ2DETAIL")})
	oStSZ2:SetProperty("Z2_GRPROD", MODEL_FIELD_VALID, { || fGetDesc("G", ""       , "Z2_GRPROD", "Z2_GPDESC", "SZ2DETAIL")})
	oStSZ2:SetProperty("Z2_PRDESC", MODEL_FIELD_VALID, { || fGetDesc("B", ""       , "Z2_PRODUTO", "Z2_GRPROD", "SZ2DETAIL")})
	//oStSZ2:SetProperty("Z2_GRPROD", MODEL_FIELD_VALID, { || fGetDesc("G", ""       , "Z2_GRPROD", "Z2_GPDESC", "SZ2DETAIL")})


	oStSZ3:SetProperty("Z3_VEND", MODEL_FIELD_VALID, { || fGetDesc("V", ""       , "Z3_VEND", "Z3_NOME", "SZ3DETAIL")})
	oStSZ3:SetProperty("Z3_CANAL", MODEL_FIELD_VALID, { || fGetDesc("Z", ""       , "Z3_CANAL", "Z3_NOME", "SZ3DETAIL")})

	oStSZ2:SetProperty("Z2_ID" , MODEL_FIELD_INIT, {|| SZ1->Z1_ID })
	oStSZ3:SetProperty("Z3_ID" , MODEL_FIELD_INIT, {|| SZ1->Z1_ID })

	oModel:SetRelation("SZ2DETAIL",{{"Z2_FILIAL", 'xFilial("SZ2")'},{'Z2_ID','Z1_ID'}}, SZ2->(IndexKey(1))) 
	oModel:GetModel("SZ2DETAIL"):SetUniqueLine({'Z2_FILIAL', 'Z2_ID', 'Z2_PRODUTO'})
	oModel:SetPrimaryKey({'Z2_FILIAL', 'Z2_ID'})


	
	oModel:SetRelation("SZ3DETAIL", { { "Z3_FILIAL" , 'xFilial("SZ3")'}, {"Z3_ID", "Z1_ID"} }, SZ3->(IndexKey(1))) 
	oModel:GetModel("SZ3DETAIL"):SetUniqueLine({'Z3_FILIAL','Z3_ID', 'Z3_VEND', 'Z3_CANAL'})
	oModel:SetPrimaryKey({'Z3_FILIAL','Z3_ID'})

	

	oModel:SetDescription("Manutenção das Campanhas de Venda")
	oModel:GetModel("SZ1MASTER"):SetDescription("Campanhas de vendas")
	oModel:GetModel("SZ2DETAIL"):SetDescription("Itens das Campanhas")
	oModel:GetModel("SZ3DETAIL"):SetDescription("Vendedores e Canais das campanhas")

Return oModel


Static Function ViewDef()
	Local oView as Object
	Local oModel   := ModelDef()
    Local oStSZ1 := FWFormStruct(2, 'SZ1')
    Local oStSZ2 := FWFormStruct(2, 'SZ2')
    Local oStSZ3 := FWFormStruct(2, 'SZ3')



	oView := FWFormView():New()
	oView:SetModel(oModel)


	oView:AddField("VIEW_SZ1", oStSZ1,  "SZ1MASTER")
	oView:AddGrid("VIEW_SZ2",  oStSZ2,  "SZ2DETAIL")
	oView:AddGrid("VIEW_SZ3",  oStSZ3,  "SZ3DETAIL")


	oView:CreateHorizontalBox("CABEC", 30)
	oView:CreateHorizontalBox("GRID", 70)

	oView:EnableTitleView("VIEW_SZ1", "Campanhas")
	oView:EnableTitleView("VIEW_SZ2", "Itens")
	oView:EnableTitleView("VIEW_SZ3", "Metas")


	oView:CreateFolder("FOLDER","GRID")
	oView:AddSheet("FOLDER","TAB_SZ2","Itens das Campanhas")	
	oView:AddSheet("FOLDER","TAB_SZ3","Vendedores e Canais das campanhas")	

	
	
	oView:CreateHorizontalBox("HBX_SZ2",100,,,"FOLDER","TAB_SZ2") 
	oView:CreateHorizontalBox("HBX_SZ3",100,,,"FOLDER","TAB_SZ3") 


	oView:SetOwnerView("VIEW_SZ1","CABEC")
	oView:SetOwnerView("VIEW_SZ2","HBX_SZ2")	
	oView:SetOwnerView("VIEW_SZ3","HBX_SZ3") 	

    oView:SetCloseOnOk({|| .T. })

Return oView



User Function Dec02Sim() 
	Local aAreaSZ1 := SZ1->(GetArea())

	Local cFieldList := "Z2_PRODUTO;Z2_PRDESC;Z2_PERDESC"
	Local aTit 		:= {{"Produto"},{"Nome Produto"},{"Desconto venda"}}
	Local aFieldList := strTokArr(cFieldList, ";") 
	Local aHeader := {} 

	Local aAlter   := {}
	Local cIdCmp  := SZ1->Z1_ID 
	Local cDscCmp := SZ1->Z1_DESC
	Local cVend   := Space(TamSX3('A3_COD')[1])
	Local lRet	  as Logical 
	Local i as Numeric 
	local nLen as Numeric
	Private aCols   := {}
	Private oScreen as Object 
	Private oMsNewGet as Object 
 
    oScreen := TDialog():New(000,000,600,850,"Simulação de campanha.",,,,,,,,,.T.,,,,,)

    TSay():New(01,10,{|| 'Codigo Campanha?'},oScreen,,,,,,.T.,CLR_BLACK,) 
    TGet():New(08,10,{|| cIdCmp  } ,oScreen,60,12,X3Picture('Z1_ID'),,,,,,,.T.,,,,,,,.T.,,,'cIdCmp',,,,)

    TSay():New(01,80,{|| 'Desc. Campanha?'},oScreen,,,,,,.T.,CLR_BLACK,) 
    TGet():New(08,80,{|| cDscCmp  } ,oScreen,80,12,X3Picture('Z1_DESC'),,,,,,,.T.,,,,,,,.T.,,,'cDscCmp',,,,)

    TSay():New(01,180,{|| 'Informe o Vendedor'},oScreen,,,,,,.T.,CLR_BLACK,) 
    TGet():New(08,180,{|U| if( PCount() > 0, cVend := u, cVend )} ,oScreen,80,12,X3Picture('A3_COD'),,,,,,,.T.,,,,,,,,,'SA3','cVend',,,,)

	


	For i := 1 To Len(aFieldList)

   		Aadd(aHeader, {GetSx3Cache(aFieldList[i], "X3_TITULO"),;
		      GetSx3Cache(aFieldList[i], "X3_CAMPO"),;
		      GetSx3Cache(aFieldList[i], "X3_PICTURE"),;
		      GetSx3Cache(aFieldList[i], "X3_TAMANHO"),;
		      GetSx3Cache(aFieldList[i], "X3_DECIMAL"),;
		      GetSx3Cache(aFieldList[i], "X3_VALID"),;
		      GetSx3Cache(aFieldList[i], "X3_USADO"),;
		      GetSx3Cache(aFieldList[i], "X3_TIPO"),;
		      GetSx3Cache(aFieldList[i], "X3_F3"),;
		      GetSx3Cache(aFieldList[i], "X3_CONTEXT"),;
		      GetSx3Cache(aFieldList[i], "X3_CBOX"),;
		      GetSx3Cache(aFieldList[i], "X3_RELACAO"),;
		      ".T."})
	Next 
	
	AADD(aCols,{Space(15),Space(TamSX3("B1_DESC")[1]),0,})

	nLen := Len(aCols)

	aCols[nLen][len(aHeader)+1]:= .F.

	aAlter:= aHeader
	oMsNewGet:= MsNewGetDados():New(30,02,298,427, GD_UPDATE ,'AllwaysTrue()','AllwaysTrue()',"",,+;
									000,999,'AllwaysTrue()','','AllwaysTrue()',oScreen,aHeader,aCols)

	//oMsNewGet:Addline()

	TButton():New(08,300,"Simular"    ,oScreen,{|| fGetSimu(cVend,oMsNewGet:aCols) },037,012,,,,.T.,,"",,,,.F. )

	oMsNewGet:SetEditLine()

	oMsNewGet:onchange('Z2_PRODUTO',{|| aCols:=fEditCell(oMsNewGet) })
	//MsNewGetDados():Editcell(.T.)

	oMsNewGet:Enable()	
    oScreen:Activate() 



RestArea(aAreaSZ1)
Return


Static Function fGetSimu(cVend as Character, aData as Array)
	Local cLog := "Status dos itens : " + CRLF
	Local lRet as Logical
	Local i as Numeric 


	For i := 1 to Len(aData) 

		lRet := U_DecAt003("",cVend,aData[i][1],aData[i][3],0,.T.)

		If lRet 
			cLog += "o Item " + Alltrim(aData[i][1]) + " Ficaria bloqueado na situação simulada." + CRLF
		Else 
			cLog += "o Item " + Alltrim(aData[i][1]) + " Seria liberado por campanha na situação simulada" + CRLF
		EndIf

	Next  

	EecView(cLog,"Retorno Simulação")

	oScreen:End()

Return 

Static Function fEditCell(oMsNewGet as Object)
	Local cDesc   := ""
	Local aNewCol := oMsNewGet:aCols
	Local i as Numeric

	For i := 1 to Len(aNewCol)

		If !Empty(aNewCol[i][1])
			cDesc := Posicione("SB1",1,xFilial("SB1")+aNewCol[i][1])
			AAdd(aNewCol,{aNewCol[i][1],cDesc,aNewCol[i][3]})
		EndIf 
	Next 
	oMsNewGet:aCols:= aNewCol
	oMsNewGet:Refresh()

Return oMsNewGet:aCols




Static Function fGetDesc(cOption, cFldType, cFldKey, cFldDesc, cModel) AS Logical
Local oModel    As Object
Local oMdlField As Object
Local cType     As Character
Local cDesc     As Character
Local cKey      As Character
Local lRet      As Logical
	
Default cOption  := "" // F=Filial, P=Produto, G=Grupo, V=Vendedor
Default cFldType := "" // Campo do Tipo
Default cFldKey  := "" // Campo do Código 
Default cFldDesc := "" // Campo da Descrição
	
	// Load
	oModel    := FWModelActive()
	oMdlField := oModel:GetModel(cModel)	
	cKey      := oMdlField:GetValue(cFldKey)
    lRet      := .T.
	
    // 1 = Filial
    // 2 = Vendedor    
    // F=Filial, P=Produto, G=Grupo, V=Vendedor
    If !Empty(cFldType)
        cType := oMdlField:GetValue(cFldType)
        If cType == "1" // Filial 
            cOption := "F"
        Else // Vendedor
            cOption := "V"
        EndIf 
    EndIf
    
    // Grava a descriçao
    cDesc := fTrigger(cOption, cKey)
    cDesc := Iif(!Empty(cDesc), Left(AllTrim(cDesc), TamSX3(cFldDesc)[1]), cDesc)
    oMdlField:SetValue(cFldDesc, cDesc)

    // Vazio não achou descrição
    If Empty(cDesc)
		oModel:SetErrorMessage("","","","","fGetDesc",'A descrição não foi encontrada.',"Verifique se o codigo digitado está correto.")
        lRet := .F.
    EndIf

    // Se a chamada for para limpar o campo, vazio significa que limpou
    If FWIsInCallStack("fClearField") .And. Empty(cDesc)
        lRet := .T.
    EndIf    

Return lRet


Static Function fTrigger(cOption, cKey) As Character
Local cRet      As Character


Default cOption   := ""  // F=Filial, P=Produto, G=Grupo, V=Vendedor
Default cKey      := ""

    // Load
    cRet      := ""

    // Vazio retorna
    If Empty(cKey)
        Return cRet
    EndIf

    // Checa Oções
    Do Case
        Case cOption == "P"                   
            cRet := Posicione("SB1", 1, xFilial("SB1") + cKey, "B1_DESC")
        Case cOption == "G"    
            cRet := Posicione("SBM", 1, xFilial("SBM") + cKey, "BM_DESC")
		Case cOption == "B"
			cRet := Posicione("SB1", 1, xFilial("SB1") + cKey, "B1_GRUPO")
		Case cOption == "C"
			cKey := Posicione("SB1", 1, xFilial("SB1") + cKey, "B1_GRUPO")
			cRet := Posicione("SBM", 1, xFilial("SBM") + cKey, "BM_DESC")
		Case cOption == "V"			
			cRet := Posicione("SA3", 1, xFilial("SA3") + cKey, "A3_NOME")	
		Case cOption == "Z"
			cRet := Posicione("SX5",1,xFilial("SX5")+'ZA'+cKey,"X5_DESCRI")		
    End Case


Return cRet


Static Function fClearField(cField, cModel) AS Logical
Local oModel    As Object
Local oMdlField As Object
Local lRet      As Logical
	
Default cField := "" // Campo do Código
	
	// Load
	oModel    := FWModelActive()
	oMdlField := oModel:GetModel(cModel)
    lRet      := .T.

    // Grava a descriçào
    oMdlField:SetValue(cField, "")

Return lRet