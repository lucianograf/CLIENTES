#Include 'totvs.ch'
//====================================================================================================================\\
/*/{Protheus.doc} AUTOCLVL
Cadastrar/Atualizar Classes de valor conforme cadastro de cliente ou fornecedor
@type function
@author Marcelo Alberto Lauschner
@since 24/10/2022
@param cPrefixo, character, Prefixo
@param cCodigo, character, Codigo 
@param cLoja, character, Loja
@return variant, Sem retorno esperado
/*/
User Function AUTOCLVL(cPrefixo, cCodigo, cLoja)

	Local aAreaBkp	:= {}
	Local cAliasCad
	Local cMsgRet
	Local cPref
	Local cCodClasse
	Local dIniExist

	Default cPrefixo := "C"

	//TODO: Ajustar  estas configurações de acordo com o cliente
	cCodClasse 	:= cPrefixo + cCodigo  // [C ou F] + [Código + Loja] do cliente ou fornecedor
	dIniExist	:= cToD("01/01/2017") // Data Inicio Existencia

	// Backup das áreas atuais
	aEval({"SA1","SA2", "CTH"}, { |area| aAdd(aAreaBkp, (area)->(GetArea()) ) } )
	aAdd(aAreaBkp, GetArea())

	If cPrefixo == "C"
		cAliasCad:= "SA1"
		cPref	 := "A1_"
	Else
		cAliasCad:= "SA2"
		cPref	 := "A2_"
	EndIf

	DbSelectArea( cAliasCad )
	DbSetOrder(1)
	If DbSeek( xFilial( cAliasCad ) + cCodigo + cLoja )
		DbSelectArea("CTH")
		DbSetOrder(1)
		If DbSeek( xFilial("CTH") + cCodClasse )
			// Classe de valor já cadastrada
			RecLock("CTH",.F.)
			CTH->CTH_DESC01:= (cAliasCad)->&( cPref + "NOME" )
			CTH->( MsUnLock() )
		Else
			// Cadastra nova classe de valor
			CTH->(RecLock("CTH",.T.))
			CTH->CTH_FILIAL		:= xFilial("CTH")
			CTH->CTH_CLASSE		:= "2" // Analítico
			CTH->CTH_NORMAL		:= "0" //
			CTH->CTH_CLVL			:= cCodClasse
			CTH->CTH_DESC01		:= (cAliasCad)->&( cPref + "NOME" )
			CTH->CTH_BLOQ			:= "2" //
			CTH->CTH_DTEXIS		:= dIniExist
			CTH->CTH_CLVLLP		:= CTH->CTH_CLVL // Classe de lucro/perda

			CTH->( MsUnLock() )
		EndIf
	Else
		cMsgRet:= "Cliente/Fornecedor não encontrado."
	EndIf

	aEval(aAreaBkp, {|area| RestArea(area)}) // Restaura as áreas anteriores

Return
