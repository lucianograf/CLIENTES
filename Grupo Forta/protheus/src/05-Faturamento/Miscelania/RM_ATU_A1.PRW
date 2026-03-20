#include "totvs.ch"
#include "protheus.ch"

/*/{Protheus.doc} xATU_SA1
Rotina para importar dados de produtos e atualizar SA1 
@type function
@version  
@author Marcelo Alberto Lauschner
@since 01/09/2022
@return variant, return_description
/*/
User Function xATU_SA1()

	Local cArq    	:= "c:\temp\sa1.txt"
	Local cLinha  	:= ""
	Local lPrim   	:= .T.
	Local aCampos 	:= {}
	Local aDados  	:= {}
	Local j,i
	Local aDadosSA1 := {}
	
	Private aErro := {}
	If Select("SM0") == 0 	
		cVarAux	:= FwInputBox("Digite o código da Empresa para abertura do ambiente. Exemplo 99 ","99")
		cGrvDados	:= Alltrim(cVarAux)+";" 	// Empresa
		cVarAux	:= FwInputBox("Digite o código da Filial para abertura do ambiente. Exemplo 01 ","01")
		cGrvDados 	+= Alltrim(cVarAux)+";"		// Filial 
		cVarAux	:= FwInputBox("Digite o login do usuário para abertura do ambiente. Exemplo admin ","admin")
		cGrvDados 	+= Alltrim(cVarAux)+";"		// Usuário 
		cVarAux	:= FwInputBox("Digite a senha do usuário para abertura do ambiente. Exemplo 123 "," ")
		cGrvDados 	+= Alltrim(cVarAux)+ Iif(!Empty(cVarAux),""," ")+";" 	// Senha
		
		//MemoWrite("xml_user_conf_compras.usr",cGrvDados)		
		aGrvDados	:= StrTokArr(cGrvDados,";")
		cEmpLog		:= aGrvDados[1]
		cFilLog 	:= aGrvDados[2]
		cUsrLog 	:= aGrvDados[3]
		cPswLog 	:= aGrvDados[4]
	
		RpcSetType(3)
		//RpcSetEnv - Abertura do ambiente em rotinas automáticas ( [ cRpcEmp ] [ cRpcFil ] [ cEnvUser ] [ cEnvPass ] [ cEnvMod ] [ cFunName ] [ aTables ] [ lShowFinal ] [ lAbend ] [ lOpenSX ] [ lConnect ] ) --> lRet
		// Efetua abertura do ambiente na Empresa/Filial 01-01001001 só para iniciar as conexões
		RPCSetEnv(cEmpLog,cFilLog,cUsrLog,cPswLog ,"FAT"/*cEnvMod*/,/*cFunName*/,{"SX2","SM0"}/*aTables*/,/*lShowFinal*/,/*lAbend*/,.T./*lOpenSX*/)
		Sleep(5 * 1000) // Tempo para abertura
	Endif 	
	
	
	If !File(cArq)
		MsgStop("O arquivo "+ cArq + " não foi encontrado. A importação será abortada!","[ATU_SA1] - ATENCAO")
		Return
	EndIf

	FT_FUSE(cArq)
	ProcRegua(FT_FLASTREC())
	FT_FGOTOP()
	While !FT_FEOF()

		IncProc("Lendo arquivo texto...")

		cLinha := FT_FREADLN()

		If lPrim
			aCampos := Separa(cLinha,";",.T.)
			lPrim := .F.
		Else
			AADD(aDados,Separa(StrTran(StrTran(cLinha,".",""),",","."),";",.T.))
		EndIf

		FT_FSKIP()
	EndDo

	Begin Transaction
		ProcRegua(Len(aDados))
		For i:=1 to Len(aDados)

			IncProc("Importando Clientes...")
			aDadosSA1 := {}
		
			dbSelectArea("SA1")
			dbSetOrder(1)
			If dbSeek(xFilial("SA1")+aDados[i,1] + aDados[i,2])

				For j := 3 to Len(aCampos) // Pesquisa a partir da terceira coluna - pois as 2 primeiras sempre terão fixo o código do A1_COD, A1_LOJA
					If  Substr(aCampos[j],1,3) == "A1_" // Se for um campo da SA1
						Aadd(aDadosSA1,{aCampos[j],aDados[i,j]})
					Endif
				Next j

				sfGrvSA1(aDadosSA1) // Grava os dados da SA1
					

			EndIf
		Next i
	End Transaction

	FT_FUSE()

	ApMsgInfo("Importação dos Produtos concluída com sucesso!","[ATU_SA1] - SUCESSO")

Return

/*/{Protheus.doc} sfGrvSA1
Função para atualizar o cadastro do produto conforme campos recebidos do CSV 
@type function
@version  
@author Marcelo Alberto Lauschner
@since 01/09/2022
@param aIndadSA1, array, param_description
@return variant, return_description
/*/
Static Function sfGrvSA1(aIndadSA1)

	Local 	i

	Begin Transaction
		// SA1 já está posicionado
		dbSelectArea("SA1")
		dbSetOrder(1)
		Reclock("SA1",.F.)
		For i := 1 To Len(aIndadSA1)
			cCampo  := "SA1->" + aIndadSA1[i,1]
			If GetSx3Cache(aIndadSA1[i,1],"X3_TIPO") == "N"
				&cCampo := Val(aIndadSA1[i,2])
			ElseIf GetSx3Cache(aIndadSA1[i,1],"X3_TIPO") == "D"
				&cCampo := STOD(aIndadSA1[i,2])
			Else
				&cCampo := aIndadSA1[i,2]
			Endif
		Next i
		SA1->(MsUnlock())

	End Transaction

Return
