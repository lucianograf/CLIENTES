#include "protheus.ch"

/*/{Protheus.doc} M410LIOK
description
@type function
@version  
@author Marcelo Alberto Lauschner
@since 14/10/2021
@return variant, return_description
/*/
User Function M410LIOK()

	Local	aAreaOld		:= GetArea()
	Local	nPCCusto  		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_CC"})
	Local	nPxCF			:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_CF"})
	Local	lRet			:= .T.
	Local	cCfopVldCC		:= "5910/6910/5949/6949" // Final de CFops que obrigará ter Centro de Custo
	Local 	nPosEcomer		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_ZVTEX"})
	Local   nPosLocal		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_LOCAL"})
	Local 	nPosPrcVen 		:= aScan(aHeader,{|x| Alltrim(x[2]) == "C6_PRCVEN"})
	Local 	nPosTES 		:= aScan(aHeader,{|x| Alltrim(x[2]) == "C6_TES"})


	// 14/10/2021 - Pedido tipo Normal - Linha não deletada - Cfops de Brinde/Outras Saídas - Centro Custo em branco
	If lRet .And. nPCCusto > 0 .And. M->C5_TIPO == "N" .And. !aCols[n,Len(aHeader)+1] .And. Alltrim(aCols[n,nPxCF]) $ cCfopVldCC .And. Empty(aCols[n,nPCCusto])
		If !IsBlind()
			MsgAlert("Este tipo de operação requer que seja informado o centro de custo. Favor conferir o campo Centro de Custo e preencher!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Validação")
			lRet := .F.
		Endif

	Endif
	If !l410Auto .And. nPosEcomer > 0  .And. !(cFilAnt $ "0102") // Não considerar filial 0102-Floripa
		If aCols[N,nPosEcomer] == ' ' .AND. aCols[N,nPosLocal] == '02'.And. !RetCodUsr() $ "000181#000032#000212"
			APMSGALERT("Este armazem é exclusivo do e-commerce!!. Favor Corrigir","Armazem")
			lRet := .F.
		EndIf
	ENDIF

	// Chamado 1774 - Zerar o valor do preço do item quando o TES estiver configurado para zerar
	If !l410Auto .And. nPosPrcVen > 0 .And. nPosTES > 0 .And. aCols[n,nPosPrcVen] > 0

		DbSelectArea("SF4")
		DbSetOrder(1)
		If DbSeek(xFilial("SF4") + aCols[n,nPosTES])

			If 	SF4->F4_AGREG == "N" .And.;	// Agrega Valor (F4_AGREG)" igual a Não
				SF4->F4_VLRZERO == "1" .And.;  //"Vlr. Zerado" (F4_VLRZERO) = "Sim"
				GetNewPar("MV_LFAGREG") // O parâmetro MV_LFAGREG = .T. (True/ Verdadeiro) indica se deve ser feita a escrituração, mesmo não agregando valor ao total da nota. Ao habilitá-lo como = .T. (True/ Verdadeiro) as informações são geradas.
				// Zera o preço de venda
				aCols[n,nPosPrcVen]  := 0
				M->C6_PRCVEN := 0

				RunTrigger(2,N,nil,,'C6_PRCVEN')
				
				cReadAnt := __ReadVar
				__ReadVar := "M->C6_PRCVEN"
				A410MultT(__ReadVar,M->C6_PRCVEN)
				__ReadVar := cReadAnt

				// Efetua Refresh do Rodapé da tela
				If Type('oGetDad:oBrowse')<>"U"
					oGetDad:oBrowse:Refresh()
					Ma410Rodap()
				Endif

			Endif
		Endif
	Endif
	RestArea(aAreaOld)

Return lRet
