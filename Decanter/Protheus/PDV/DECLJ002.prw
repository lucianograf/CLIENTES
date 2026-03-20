#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} DECLJ001
Consulta personalizada de produto aplicando tabela de preço e regra de descontos

@author Carlos Eduardo Reinert 
@since 23/12/2019
/*/

User Function DECLJ002()

	Private aBoxCli := {}
	Private bBoxCli,oBoxCli
	
	Private cCodFil := Space(200)
	Private cCodPrd := ""
	Private cDtVal := DToC(StoD(""))
	Private cPrcFim := "0"
	Private oCodFil
	Private oCodGet
	Private oDtValGet
	Private oPrcFimGet
	Private oBold
		
	// Carrega filtro de produtos
     fFilCli()
    // 
	
	// Montagem da tela de consulta
	aSize  	 := MsAdvSize( .F. )
	aObjects := {} 
	AAdd( aObjects, { 100, 20,  .t., .f., .t. } )
	AAdd( aObjects, { 100, 100 , .t., .t. } )
	AAdd( aObjects, { 100, 42 , .t., .f. } )

	aInfo    := { aSize[ 1 ], aSize[ 2 ], aSize[ 3 ], aSize[ 4 ], 3, 3 } 
	aPosObj1 := MsObjSize( aInfo, aObjects) 
	
	DEFINE FONT oBold NAME "Arial" SIZE 0, -20 BOLD
	DEFINE MSDIALOG oDlg1 TITLE OemToAnsi("Consulta Pontos") from aSize[7],0 TO aSize[6],(aSize[5]-30) of oMainwnd PIXEL

	@ 05,015 SAY "Filtrar: " OF oDlg1 Pixel
	@ 05,050 MsGet oCodFil Var cCodFil Valid fFilCli() SIZE (aPosObj1[1,3]-70),15 FONT oBold OF oDlg1 PIXEL
	
	// Lista de Produtos
	oBoxCli := TWBrowse():New( aPosObj1[2,1],aPosObj1[2,2]+05,(aPosObj1[1,3]-30),aPosObj1[2,3]-30,,;
	{"CPF", "NOME", "SALDO", "DATA"},;
	{50,200,50,30,50,50,30},oDlg1,,,,,{||},,,,,,,.F.,,.T.,,.F.,,.t.,.t.)

	oBoxCli:SetArray(aBoxCli)
	bBoxCli := { || { 	aBoxCli[oBoxCli:nAt,1], aBoxCli[oBoxCli:nAt,2], ;
	aBoxCli[oBoxCli:nAt,3], aBoxCli[oBoxCli:nAt,4]} }
	oBoxCli:bLine := bBoxCli
	oBoxCli:bChange := {|| fChangeCli()} 
	
	
	
	DEFINE SBUTTON FROM aPosObj1[3,1]+25,(aPosObj1[1,3]-50) TYPE 1 ENABLE OF oDlg1 ACTION ( oDlg1:End() )

	ACTIVATE MSDIALOG oDlg1 CENTERED

Return


// Função na alteração de linha do grid de produto
Static Function fChangeCli()

	cCpf := aBoxCli[oBoxCli:nAt,1] 
    cNome := aBoxCli[oBoxCli:nAt,2]
	cSaldo := aBoxCli[oBoxCli:nAt,3]
	cData := aBoxCli[oBoxCli:nAt,4]
	
Return

// Função para filtro de produtos
Static Function fFilCli()
	
	Local nPrcUnit := 0
	Local aFilStr := {}
	Local nIdx := 0
	Local cFiltro := ""
	Local aItDesc := {}
	
	cCodFil := Upper(AllTrim(cCodFil))
	
	// Limpa grid de produtos
	aBoxCli := {}

	If !Empty(cCodFil)
	
		// Monta filtro dinâmico
		aFilStr := StrTokArr(cCodFil, "*")
		For nIdx := 1 To Len(aFilStr)
			cFiltro += ".and. ('"+AllTrim(aFilStr[nIdx])+"' $ (AllTrim( ZFD->ZFD_CGC)+'|'+AllTrim( ZFD->ZFD_NOME)))"
		Next
		cFiltro := AllTrim(SubStr(cFiltro, 6))
	
		// Carrega dados gerais do produto
		dbSelectArea(" ZFD")
		 ZFD->(DBGoTop())
				
		While  ZFD->(!EOF())
		
			If &cFiltro
				
				/*/
				Preço de Tabela
				/*/
				
				
				//If  ZFD->ZFD_SALDO > 0
					
					// Regra de Desconto
					/*/
					AADD( aRet , lApplyRule 			)
					AADD( aRet , nNewValueItem 		)
					AADD( aRet , nTotValueDiscount 	)
					AADD( aRet , nDiscPerTotal 		)
					AADD( aRet , nValueItem 			)
					AADD( aRet , dRuleDate			)	
					/*/		
				
					aAdd(aBoxCli, {;
						ZFD->ZFD_CGC ,;
						ZFD->ZFD_NOME,;
					    Transform(ZFD->ZFD_SALDO,"@E 99,999,999.99"),;
						DToC( ZFD->ZFD_DATA) ;
						} )
				
				//EndIf
				
			EndIf
			
			ZFD->(dbSkip())
		
		End
		
		ZFD->(dbCloseArea())
		
	EndIf
	
	// Caso não tenha nenhum produto no filtro, carrega uma linha vazia
	If Len(aBoxCli) == 0
		aAdd(aBoxCli, {;
		Space(Len(ZFD->ZFD_CGC)) ,;
		Space(Len( ZFD->ZFD_NOME)) ,;
        Transform(0,"@E 99,999,999.99")	,;
		DToC(StoD("")) ;
		} )
	Endif
	
	If Type("oBoxCli") == "O"
		
		oBoxCli:SetArray(aBoxCli)
		oBoxCli:bLine := bBoxCli
		oBoxCli:Refresh()
		
	//	fChangeCli()
		
	EndIf
	
	cCodFil := Space(200)
	
Return

