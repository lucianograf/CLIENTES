#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWMVCDEF.CH"

/*/{Protheus.doc} ATGFEA01
Rotina para manutenção de Prazos e Coletas das transportadoras
@type function
@version 1
@author Iago Luiz Raimondi
@since 08/12/2022
@return variant, aRotina
/*/
User Function ATGFEA01()

	Private oBrowse

	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias("GUN")
	oBrowse:SetMenuDef("ATGFEA01")
	oBrowse:SetDescription("Cadastro de Prazos e Coletas")
	oBrowse:SetFilterDefault("GUN_TPTAB == '1'")
	oBrowse:SetOnlyFields({'GUN_CODTAB', 'GUN_CDTRP', 'GUN_INFRTO', 'GUN_INFRTD', 'GUN_TPPRAZ', 'GUN_PRAZO', 'GUN_XROTA'})
	oBrowse:Activate()

Return

/*/{Protheus.doc} MenuDef
MenuDef
@type function
@version 1
@author Iago Luiz Raimondi
@since 08/12/2022
@return variant, aRotina
/*/
Static Function MenuDef()

	Local aRotina := {}

	aAdd( aRotina, { 'Pesquisar',           'AxPesqui',             0, 1, 0, NIL } )
	aAdd( aRotina, { 'Visualizar',          'ViewDef.ATGFEA01',     0, 2, 0, NIL } )
	aAdd( aRotina, { 'Incluir',             'ViewDef.ATGFEA01',     0, 3, 0, NIL } )
	aAdd( aRotina, { 'Alterar',             'ViewDef.ATGFEA01',     0, 4, 0, NIL } )
	aAdd( aRotina, { 'Excluir' ,            'ViewDef.ATGFEA01',     0, 5, 0, NIL } )
	aAdd( aRotina, { 'Imprimir Rotas' ,		'U_AGFEA01A',           0, 8, 0, NIL } )

Return aRotina

/*/{Protheus.doc} ViewDef
ViewDef
@type function
@version 1
@author Iago Luiz Raimondi
@since 08/12/2022
@return variant, oView
/*/
Static Function ViewDef()

	Local oModel  	:= FWLoadModel("GFEA019")
	Local oStruct 	:= FWFormStruct(2,"GUN")
	Local oView   	:= Nil
	Local nX	  	:= 0

	Local aCmpPrazo := {'GUN_CODTAB', 'GUN_TPTAB', 'GUN_DUPSEN', 'GUN_DATDE', 'GUN_DATATE', 'GUN_PRIOR', 'GUN_NRCIOR', 'GUN_NRREOR',;
		'GUN_CDREM', 'GUN_NRCIDS', 'GUN_NRREDS', 'GUN_CDDEST', 'GUN_INFRTO', 'GUN_INFRTD', 'GUN_CDTPOP',;
		'GUN_DSTPOP', 'GUN_CDTPVC', 'GUN_DSTPVC', 'GUN_CDGRP', 'GUN_DSGRP', 'GUN_CDTRP', 'GUN_NMTRP',;
		'GUN_MODAL', 'GUN_CDCLFR', 'GUN_DSCLFR', 'GUN_TPPRAZ', 'GUN_PRAZO', 'GUN_XROTA'}

	oView := FWFormView():New()

	oView:SetModel(oModel)
	oView:AddField( "GFEA019_GUN" , oStruct, /*cLinkID*/ )	//

	// Realiza a leitura da estrutura do model e retira os campos que não estão definidos no array base
	For nX := Len(oStruct:aFields) To 1 STEP -1
		If ASCAN(aCmpPrazo,oStruct:aFields[nX][1]) == 0
			oStruct:RemoveField(oStruct:aFields[nX][1])
		EndIf
	Next
Return oView


/*/{Protheus.doc} AGFEA01A
Relatorio dos prazos e coleta 
@type function
@version 1
@author Iago Luiz Raimondi
@since 08/12/2022
/*/
User Function AGFEA01A()

	Local oFwMsEx
	Local cNextAlias := GetNextAlias()
	Local aRet 		 := {}
	Local aCab		 := {}
	Local aItens 	 := {}
	Local cTitulo	 := "ATGFEA01 - Prazos e Coletas"
	Local cTabela	 := "Lista de Prazos e Coletas"

	If sfPerg(aRet)

		aCab := {"COD_ID",;
			"DES_IDA_VOLTA",;
			"DAT_DE","DAT_ATE",;
			"COD_CIDORI",;
			"DES_CIDORI",;
			"COD_CIDDES",;
			"DES_CIDDES",;
			"COD_TRANSP",;
			"DES_TRANSP",;
			"DES_PRAZO",;
			"NUM_PRAZO",;
			"NUM_COLETA"}

		If Select(cNextAlias) <> 0
			(cNextAlias)->(DbCloseArea())
		EndIf

		BeginSql Alias cNextAlias

		SELECT G.GUN_CODTAB AS COD_ID,
		       CASE
		         WHEN G.GUN_DUPSEN = '1' THEN
		          'SIM'
		         ELSE
		          'NÃO'
		       END AS DES_IDA_VOLTA,
		       TO_DATE(G.GUN_DATDE, 'YYYYMMDD') AS DAT_DE,
		       TO_DATE(G.GUN_DATATE, 'YYYYMMDD') AS DAT_ATE,
		       G.GUN_NRCIOR AS COD_CIDORI,
		       CDO.GU7_NMCID AS DES_CIDORI,
		       G.GUN_NRCIDS AS COD_CIDDES,
		       CDD.GU7_NMCID AS DES_CIDDES,
		       G.GUN_CDTRP AS COD_TRANSP,
		       GU3.GU3_NMEMIT AS DES_TRANSP,
		       CASE
		         WHEN G.GUN_TPPRAZ = '0' THEN
		          'DIAS ÚTEIS'
		         WHEN G.GUN_TPPRAZ = '1' THEN
		          'DIAS CORRIDOS'
		         WHEN G.GUN_TPPRAZ = '2' THEN
		          'HORAS'
		       END AS DES_PRAZO,
		       G.GUN_PRAZO AS NUM_PRAZO,
		       G.GUN_XROTA AS NUM_COLETA
		  FROM %Table:GUN% G

		 INNER JOIN %Table:GU3% GU3
		    ON GU3.GU3_FILIAL = ' '
		   AND GU3.GU3_CDEMIT = G.GUN_CDTRP
		   AND GU3.%NotDel%

		 INNER JOIN %Table:GU7% CDO
		    ON CDO.GU7_FILIAL = ' '
		   AND CDO.GU7_NRCID = G.GUN_NRCIOR
		   AND CDO.%NotDel%

		 INNER JOIN %Table:GU7% CDD
		    ON CDD.GU7_FILIAL = ' '
		   AND CDD.GU7_NRCID = G.GUN_NRCIDS
		   AND CDD.%NotDel%

		 WHERE G.%NotDel%
		   AND G.GUN_CDTRP BETWEEN %Exp:MV_PAR01% AND %Exp:MV_PAR02%

		EndSql

		While !(cNextAlias)->(Eof())
			Aadd(aItens,{COD_ID,;
				DES_IDA_VOLTA,;
				DAT_DE,DAT_ATE,;
				COD_CIDORI,;
				DES_CIDORI,;
				COD_CIDDES,;
				DES_CIDDES,;
				COD_TRANSP,;
				DES_TRANSP,;
				DES_PRAZO,;
				NUM_PRAZO,;
				NUM_COLETA})
			(cNextAlias)->(DbSkip())
		EndDo
		(cNextAlias)->(DbCloseArea())

		sfExcel(cTitulo,cTabela,aCab,aItens)

	EndIf

Return

/*/{Protheus.doc} sfPerg
ParamBox 
@type function
@version 1
@author Iago Luiz Raimondi
@since 08/12/2022
@return variant, lRet
/*/
Static Function sfPerg(aRet)

	Local 	aPergPar	:=	{}
	Local 	cTransp	    := Space(TamSX3("GU3_CDEMIT")[1])
	Local 	lRet 		:= .F.

	aadd(aPergPar,{1, "Transportadora De", 	cTransp,"@!","Vazio() .Or. ExistCpo('GU3')","GU3",".T.",50,.F.})
	aadd(aPergPar,{1, "Transportadora Até", cTransp,"@!","!Vazio() .Or. ExistCpo('GU3')","GU3",".T.",50,.F.})

	lRet := ParamBox(@aPergPar,"Parametros ",@aRet, , ,.T.,)

Return lRet

/*/{Protheus.doc} sfExcel
Gera arquivo xml e abre na tela 
@type function
@version 1
@author Iago Luiz Raimondi
@since 08/12/2022
/*/
Static Function sfExcel(cTitulo,cTabela,aCab,aItens)

	Local nI
	Local nJ
	Local cArq
	Local cDirTmp := GetTempPath()

	Default aCab := {}
	Default aItens := {}

	oFwMsEx := FWMsExcel():New()
	oFwMsEx:AddWorkSheet( cTitulo )
	oFwMsEx:AddTable( cTitulo, cTabela )

	For nI := 1 To Len(aCab)
		oFwMsEx:AddColumn( cTitulo, cTabela , aCab[nI]  ,1,1)
	Next

	For nJ := 1 To Len(aItens)
		oFwMsEx:AddRow( cTitulo, cTabela, aItens[nJ] )
	Next

	oFwMsEx:Activate()

	cArq :=  GetNextALias()+ ".xml"
	oFwMsEx:GetXMLFile( cArq )

	If __CopyFile( cArq, cDirTmp + cArq )
		oExcelApp := MsExcel():New()
		oExcelApp:WorkBooks:Open( cDirTmp + cArq )
		oExcelApp:SetVisible(.T.)

		MsgInfo( "Arquivo " + cArq + " gerado com sucesso no diretório!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
	Else
		MsgAlert( "Erro: Arquivo não copiado para temporário do usuário!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
	EndIf

Return
