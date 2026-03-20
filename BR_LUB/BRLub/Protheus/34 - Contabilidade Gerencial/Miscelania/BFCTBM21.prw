#Include 'Protheus.ch'

/*/{Protheus.doc} BFCTBM21
(Criar Item contábil automaticamente para contabilização)
@author MarceloLauschner
@since 29/09/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/

User Function BFCTBM21(lAutoAll)
	
	Default		lAutoAll	:= .F.
	
	If lAutoAll
		DbSelectArea("SA1")
		DbSetOrder(1)
		Set Filter To A1_SALDUP > 0 
		While !Eof()
			// Cadastro desbloqueado
			If RegistroOk("SA1",.F.)
				// Somente cliente com saldo de duplicatas
				If SA1->A1_SALDUP > 0
					sfIncItem()
				Endif
			Endif
			DbSelectArea("SA1")
			DbSkip()
		Enddo
		DbSelectArea("SA1")
		Set Filter To
	Else
		sfIncItem()
	Endif
	
Return

/*/{Protheus.doc} sfIncItem
(Executa a rotina de inclusão do Item Contábil)
@author MarceloLauschner
@since 29/09/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfIncItem()
	
	
	Local		lRetorno		:= .F.
	Local		aAreaOld		:= GetArea()
	Local 		aDadosAuto 	:= {}		// Array com os dados a serem enviados pela MsExecAuto() para gravacao automatica
	Private 	lMsHelpAuto 	:= .F.		// Determina se as mensagens de help devem ser direcionadas para o arq. de log
	Private 	lMsErroAuto 	:= .F.		// Determina se houve alguma inconsistencia na execucao da rotina em relacao aos
	
	DbSelectArea("CTD")
	DbSetOrder(1)
	If DbSeek(xFilial("CTD")+"SA1"+SA1->A1_COD+SA1->A1_LOJA)
		RestArea(aAreaOld)
		Return .F.
	Endif
	
	aDadosAuto:= {;
		{'CTD_ITEM'   	, "SA1"+SA1->A1_COD+SA1->A1_LOJA			, Nil},;	// Especifica qual o Código do item contabil
	{'CTD_CLASSE'    		, "2"											, Nil},;	// Especifica a classe do Centro de Custo, que  poderá ser: - Sintética: Centros de Custo totalizadores dos Centros de Custo Analíticos - Analítica: Centros de Custo que recebem os valores dos lançamentos contábeis
	{'CTD_NORMAL'    		, "2"											, Nil},;	// Indica a classificação do centro de custo. 1-Receita ; 2-Despesa
	{'CTD_DESC01'    		, SA1->A1_NOME								, Nil},;	// Indica a Nomenclatura do item contabil na Moeda 1
	{'CTD_BLOQ'  			, "2"											, Nil},;	// Indica se o Centro de Custo está ou não bloqueado para os lançamentos contábeis.
	{'CTD_DTEXIS' 		, dDataBase									, Nil},;	// Especifica qual a Data de Início de Existência para este Centro de Custo
	{'CTD_RES'   			, SA1->A1_COD+SA1->A1_LOJA					, Nil}}	// Indica um “apelido” para o Centro de Custo (que poderá conter letras ou números) e que poderá ser utilizado na digitação dos lançamentos contábeis, facilitando essa digitação.
	
	MSExecAuto({|x, y| CTBA040(x, y)},aDadosAuto, 3)
	
	If lMsErroAuto
		lRetorno := .F.
		MostraErro()
	Else
		lRetorno:=.T.
	EndIf
	
Return lRetorno


