#include 'protheus.ch'

/*/{Protheus.doc} DECA100
Carrega vendedor 2 e comissão 2 do cliente na tela do pedido de venda.

Adicionar chamada na validacao de usuario do campo C5_LOJACLI.

@author TSCB57 - William Farias
@since 29/07/2019
@version 1.0
@return logic
/*/
User Function DECA100(nOpcOut)

	//C5_VEND2 e o campo C5_COMIS2 seja preenchido com informações do cadastro do cliente dos campos A1_ZVEND2 e A1_ZCOMIS2 conforme imagem abaixo:

	Local aArea		:= GetArea()
	Local xRet		:= Space(TamSX3("C5_VEND2")[1])
	Local cVend2 	:= Space(TamSX3("C5_VEND2")[1])
	Local nComis2 	:= 0

	Default nOpcOut := 1 

	If FWIsInCallStack("A410Inclui") .Or. FWIsInCallStack("A410Altera")

		dbSelectArea("SA1")
		dbSetOrder(1)
		If !dbSeek(xFilial("SA1")+M->C5_CLIENTE+M->C5_LOJACLI)
			ShowHelpDlg(ProcName(0)+"."+ Alltrim(Str(ProcLine(0))),;
				{"Cliente não encontrado na busca de Vendedor 2'."},;
				5,;
				{"."},;
				5)
		Else	
			dbSelectArea("SA3")
			SA3->(dbSetOrder(1))
			DbSeek(xFilial("SA3")+M->C5_VEND1 )

			// Se existir o cadastro de vendedor 2 no Cliente e tiver comissão preenchida
			If !Empty(SA1->A1_ZVEND2) .And. !Empty(SA1->A1_ZCOMIS2)
				cVend2 	:= SA1->A1_ZVEND2
				nComis2	:= SA1->A1_ZCOMIS2
			// Se tiver o vendedor no cadastro de Vendedor e tiver comissão preenchida 
			ElseIf !Empty(SA3->A3_ZVEND2) .And. !Empty(SA3->A3_ZCOMIS2)
				cVend2	:= SA3->A3_ZVEND2
				nComis2 := SA3->A3_ZCOMIS2
			Endif 

			// Verifica se o vendedor localizado tem cadastro e está ativo 
			dbSelectArea("SA3")
			SA3->(dbSetOrder(1))
			If DbSeek(xFilial("SA3")+cVend2)
				
				If !RegistroOk("SA3",.F.)
					ShowHelpDlg(ProcName(0)+"."+ Alltrim(Str(ProcLine(0))),;
						{"Cadastro de vendedor 2: "+M->C5_VEND2+" Bloqueado'."},;
						5,;
						{"."},;
						5)

					cVend2 	:= Space(TamSX3("A1_ZVEND2")[1])
					nComis2	:= 0
				EndIf
			EndIf
		EndIf
	EndIf
	If nOpcOut == 1
		xRet	:= cVend2 
	ElseIf nOpcOut == 2 
		xRet 	:= nComis2
	Endif 
	RestArea(aArea)

Return xRet
