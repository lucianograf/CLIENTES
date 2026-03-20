#INCLUDE "rwmake.ch"

/*/{Protheus.doc} U_DCAFAT09
Atualizar cadastro de clientes com dados do SEFAZ - Inscrição Estadual/Simples Nacional/Estado/Ativo Inativo
@type function
@version 
@author Marcelo Alberto Lauschner
@since 10/12/2020
@return return_type, return_description
/*/
Function U_MLFATM02()

	Private oLeTxt

	Private cString := "SA1"

	dbSelectArea("SA1")
	dbSetOrder(3)

	@ 200,1 TO 380,380 DIALOG oLeTxt TITLE OemToAnsi("Leitura de Arquivo Texto")
	@ 02,10 TO 080,190
	@ 10,018 Say " Este programa ira ler o conteudo de um arquivo texto, conforme"
	@ 18,018 Say " os parametros definidos pelo usuario, para atualização do "
	@ 26,018 Say " Cadastro de clientes para informações de Simples/Inscrição... "

	@ 70,128 BMPBUTTON TYPE 01 ACTION (OkLeTxt(),Close(oLeTxt))
	@ 70,158 BMPBUTTON TYPE 02 ACTION Close(oLeTxt)

	Activate Dialog oLeTxt Centered

Return

/*/{Protheus.doc} OkLeTxt
Função para executar a leitura do arquivo TXT de empresas ativas e atualizar o cadastro de clientes. 
@type function
@version 
@author Marcelo Alberto Lauschner
@since 10/12/2020
@return return_type, return_description
/*/
Static Function OkLeTxt

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Abertura do arquivo texto                                           ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	Private cFile	:= cGetFile( "Arquivo Texto(*.txt) | *.txt", "Selecione o Arquivo de Cadastros Ativos",,"",.T., )
	Private lSimula	:= MsgYesNo( "Deseja rodar o programa em modo de Simulação? Nenhum dado será gravado no cadastro de clientes.","A T E N Ç Ã O!!")

	If !File(cFile)
		REturn
	Endif


	aAlterados	:= {}

	Aadd(aAlterados,{ "CGC"         ,"C",14,0})
	Aadd(aAlterados,{ "NOME"        ,"C",50,0})
	Aadd(aAlterados,{ "COLUNA"      ,"C",25,0})
	Aadd(aAlterados,{ "VALORORI"    ,"C",50,0})
	Aadd(aAlterados,{ "VALORATU"    ,"C",50,0})
	Aadd(aAlterados,{ "OBSMEMO"     ,"C",250,0})

	If(Type('oTmpTRB') <> 'U')
		oTmpTRB:Delete()
		FreeObj(oTmpTRB)
	EndIf
	cNomArq := "QALT"

	If (Select("QALT") <> 0)
		dbSelectArea("QALT")
		QALT->(dbCloseArea())
	Endif

	oTmpTRB := FWTemporaryTable():New(cNomArq,aCampos)
	oTmpTRB:AddIndex( "01", {"CGC","COLUNA"})
	oTmpTRB:Create()



	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Inicializa a regua de processamento                                 ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	Processa({|| RunCont(cFile) },"Processando...")

	If(Type('oTmpTRB') <> 'U')
		oTmpTRB:Delete()
		FreeObj(oTmpTRB)
	EndIf

Return

/*/
	ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
	±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
	±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
	±±ºFun‡„o    ³ RUNCONT  º Autor ³ AP5 IDE            º Data ³  03/11/10   º±±
	±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
	±±ºDescri‡„o ³ Funcao auxiliar chamada pela PROCESSA.  A funcao PROCESSA  º±±
	±±º          ³ monta a janela com a regua de processamento.               º±±
	±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
	±±ºUso       ³ Programa principal                                         º±±
	±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
	±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
	ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/

Static Function RunCont(cFile)

	Local	lCadAtivo       := .T.
	Local   lVldSimples     := .T.
	Local   lVldInscricao   := .T.
	Local   lVldCnae        := .T.
	Local   lVdlUF          := .T.
	Local   lVldBloqueio    := .T.

	FT_FUSE(AllTrim(cFile))

	//Le cada arquivo e atribui à matriz aLinha
	While !(FT_FEOF())
		cLinha := FT_FREADLN()

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Incrementa a regua                                                  ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

		IncProc()

		aDados	:= StrTokArr(cLinha,",")

		If Len(aDados) < 9
			Loop
		Endif

		If Len(aDados) == 10
			lCadAtivo	:= .T.
		Endif


		dbSelectArea(cString)
		DbSetOrder(3)
		If DbSeek(xFilial("SA1")+aDados[1],.F.)

			// "Simples","Tabela","Inscrição","Estado","Cnae","Bloquear"
			If lVldSimples .And. lCadAtivo .And. SA1->A1_SIMPLES <> Iif(Substr(aDados[10],1,1) $ "8#9","1","2")
				DbSelectArea("QALT")
				RecLock("QALT",.T.)
				QALT->CGC		:= aDados[1]
				QALT->NOME		:= SA1->A1_COD+"/"+SA1->A1_LOJA+"-"+SA1->A1_NOME
				QALT->COLUNA	:= "A1_SIMPLES"
				QALT->VALORORI	:= SA1->A1_SIMPLES
				QALT->VALORATU	:= Iif(Substr(aDados[10],1,1) $ "8#9","1","2")	 // 1-Sim 2-Não
				QALT->OBSMEMO	:= Iif(Substr(aDados[10],1,1) $ "8#9",DTOC(Date()) + " - Alterado para Optante Simples ",DTOC(Date())+" - Alterado para Empresa Normal ")
				MsUnlock()
				If !lSimula
					RecLock(cString,.F.)
					cObsMemo		:= SA1->A1_PRF_OBS
					SA1->A1_PRF_OBS	:= Iif(Substr(aDados[10],1,1) $ "8#9",DTOC(Date()) + " - Alterado para Optante Simples ",DTOC(Date())+" - Alterado para Empresa Normal ")+Chr(13)+Chr(10)+cObsMemo
					SA1->A1_SIMPLES := Iif(Substr(aDados[10],1,1) $ "8#9","1","2")	 // 1-Sim 2-Não
					MsUnlock()
				Endif
			Endif

			// "Simples","Tabela","Inscrição","Estado","Cnae","Bloquear"
			If lVldBloqueio .And. !lCadAtivo .And. aDados[8] <> "1" .And. SA1->A1_MSBLQL <> "1" .And. Alltrim(SA1->A1_INSCR) == aDados[2]
				DbSelectArea("QALT")
				RecLock("QALT",.T.)
				QALT->CGC		:= aDados[1]
				QALT->NOME		:= SA1->A1_COD+"/"+SA1->A1_LOJA+"-"+SA1->A1_NOME
				QALT->COLUNA	:= "A1_MSBLQL"
				QALT->VALORORI	:= SA1->A1_MSBLQL
				QALT->VALORATU	:= "1"
				QALT->OBSMEMO	:= DTOC(Date())+" - Bloqueado por ("+Alltrim(aDados[9])+")"
				MsUnlock()

				If !lSimula
					RecLock(cString,.F.)
					cObsMemo		:= SA1->A1_PRF_OBS
					SA1->A1_PRF_OBS	:= DTOC(Date())+" - Bloqueado por ("+Alltrim(aDados[9])+")"+Chr(13)+Chr(10)+cObsMemo
					SA1->A1_MSBLQL  := "1"
					SA1->A1_BLOQCAD := "S"
					MsUnlock()
				Endif
			Endif

			// "Simples","Tabela","Inscrição","Estado","Cnae","Bloquear"
			If lVldBloqueio .And. lCadAtivo .And. aDados[8] == "1" .And. SA1->A1_MSBLQL == "1"
				DbSelectArea("QALT")
				RecLock("QALT",.T.)
				QALT->CGC		:= aDados[1]
				QALT->NOME		:= SA1->A1_COD+"/"+SA1->A1_LOJA+"-"+SA1->A1_NOME
				QALT->COLUNA	:= "A1_MSBLQL"
				QALT->VALORORI	:= SA1->A1_MSBLQL
				QALT->VALORATU	:= "2"
				QALT->OBSMEMO	:= DTOC(Date())+" - Desbloqueado por ("+Alltrim(aDados[9])+")"
				MsUnlock()

				If !lSimula
					RecLock(cString,.F.)
					cObsMemo		:= SA1->A1_PRF_OBS
					SA1->A1_PRF_OBS	:= DTOC(Date())+" - Desbloqueado por ("+Alltrim(aDados[9])+")"+Chr(13)+Chr(10)+cObsMemo
					SA1->A1_MSBLQL  := "2"
					SA1->A1_BLOQCAD := "N"
					MsUnlock()
				Endif
			Endif

			// "Simples","Tabela","Inscrição","Estado","Cnae","Bloquear"
			If lVldInscricao .And. aDados[8] == "0" .And. Alltrim(SA1->A1_INSCR) <> Alltrim(aDados[2])
				DbSelectArea("QALT")
				RecLock("QALT",.T.)
				QALT->CGC		:= aDados[1]
				QALT->NOME		:= SA1->A1_COD+"/"+SA1->A1_LOJA+"-"+SA1->A1_NOME
				QALT->COLUNA	:= "A1_INSCR"
				QALT->VALORORI	:= SA1->A1_INSCR
				QALT->VALORATU	:= aDados[2]
				QALT->OBSMEMO	:= DTOC(Date()) + " - Alterada Inscrição Estadual - Antiga ("+SA1->A1_INSCR+") "
				MsUnlock()

				If !lSimula
					RecLock(cString,.F.)
					cObsMemo		:= SA1->A1_PRF_OBS
					SA1->A1_PRF_OBS	:= DTOC(Date()) + " - Alterada Inscrição Estadual - Antiga ("+SA1->A1_INSCR+") "+Chr(13)+Chr(10)+cObsMemo
					SA1->A1_INSCR	:= Alltrim(aDados[2])
					MsUnlock()
				Endif
			Endif

			// "Simples","Tabela","Inscrição","Estado","Cnae","Bloquear"
			If lVdlUF .And. aDados[8] == "0" .And. SA1->A1_EST <> aDados[3]
				DbSelectArea("QALT")
				RecLock("QALT",.T.)
				QALT->CGC		:= aDados[1]
				QALT->NOME		:= SA1->A1_COD+"/"+SA1->A1_LOJA+"-"+SA1->A1_NOME
				QALT->COLUNA	:= "A1_EST"
				QALT->VALORORI	:= SA1->A1_EST
				QALT->VALORATU	:= aDados[3]
				QALT->OBSMEMO	:= DTOC(Date()) + " - Alterada Unidade Federativa - Antiga ("+SA1->A1_EST+") "
				MsUnlock()

				If !lSimula
					RecLock(cString,.F.)
					cObsMemo		:= SA1->A1_PRF_OBS
					SA1->A1_PRF_OBS	:= DTOC(Date()) + " - Alterada Unidade Federativa - Antiga ("+SA1->A1_EST+") "+Chr(13)+Chr(10)+cObsMemo
					SA1->A1_EST 	:= aDados[3]
					MsUnlock()
				Endif
			Endif

			// "Simples","Tabela","Inscrição","Estado","Cnae","Bloquear"
			If lVldCnae .And. aDados[8] == "0" .And. Alltrim(SA1->A1_CNAE) <>  aDados[7]
				DbSelectArea("QALT")
				RecLock("QALT",.T.)
				QALT->CGC		:= aDados[1]
				QALT->NOME		:= SA1->A1_COD+"/"+SA1->A1_LOJA+"-"+SA1->A1_NOME
				QALT->COLUNA	:= "A1_CNAE"
				QALT->VALORORI	:= SA1->A1_CNAE
				QALT->VALORATU	:= aDados[7]
				QALT->OBSMEMO	:= DTOC(Date()) + " - Alterado CNAE - Antigo ("+SA1->A1_CNAE+") "
				MsUnlock()

				If !lSimula
					RecLock(cString,.F.)
					cObsMemo		:= SA1->A1_PRF_OBS
					SA1->A1_PRF_OBS	:= DTOC(Date()) + " - Alterado CNAE - Antigo ("+SA1->A1_CNAE+") "+Chr(13)+Chr(10)+cObsMemo
					SA1->A1_CNAE 	:= aDados[7]
					MsUnlock()
				Endif
			Endif

		Endif
		FT_FSKIP()
	Enddo


	dbSelectArea("QALT")
	dbGotop()

	@ 001,001 TO 650,1014 DIALOG oDlg1 TITLE OemToAnsi("Relação de alterações efetuadas")

	aCampos := {}
	Aadd(aCampos,{ "CGC"     ,"CNPJ"})
	Aadd(aCampos,{ "NOME"    ,"Razão"})
	Aadd(aCampos,{ "COLUNA"  ,"Coluna"})
	Aadd(aCampos,{ "VALORORI"  ,"Valor Original"})
	Aadd(aCampos,{ "VALORATU" ,"Novo Valor"})
	Aadd(aCampos,{ "OBSMEMO"  ,"Observações"})

	@ 005,005 TO 300,500 BROWSE "QALT" OBJECT oBrw1 FIELDS aCampos
	@ 310,180 Button "&Gravar alterações" Size 50,13 Action(Processa({|| sfGrvDados()},"Atualizando base de dados..."),sfExpExc(),Close(oDlg1))
	@ 310,240 Button "&Deletar Alteração" Size 50,13 Action(sfExcLin(),oBrw1:oBrowse:SetFocus())
	@ 310,300 Button "&Exporta Excel" Size 50,13 Action(sfExpExc())
	@ 310,360 button "&Fechar "   size 35,13 Action ( Close(oDlg1))

	ACTIVATE DIALOG oDlg1 CENTERED

	QALT->(DbCloseArea())


Return


Static Function sfExpExc()

	Local	aCampos := {}
	Aadd(aCampos,{ "CGC"     			,"CGC"})
	Aadd(aCampos,{ "Razão Social"     	,"NOME"})
	Aadd(aCampos,{ "Coluna"  			,"COLUNA"})
	Aadd(aCampos,{ "Valor Antigo"  		,"VALORORI"})
	Aadd(aCampos,{ "Novo Valor" 		,"VALORATU"})
	Aadd(aCampos,{ "Descricao" 			,"OBSMEMO"})

	If FindFunction("RemoteType") .And. RemoteType() == 1
		DlgToExcel({{"GETDB","Relação de alterações Efetuadas",aCampos,"QALT"}})
	EndIf

Return

Static Function sfExcLin()

	DbSelectArea("QALT")
	RecLock("QALT",.F.)
	DbDelete()
	MsUnlock()
	MsgAlert("Registro deletado!")
	oBrw1:oBrowse:Refresh()

Return


Static Function sfGrvDados()

	DbSelectArea("QALT")
	ProcRegua(RecCount())
	DbGotop()
	While !Eof()

		IncProc()

		DbSelectArea("SA1")
		DbSetOrder(3)
		If DbSeek(xFilial("SA1")+QALT->CGC,.F.)
			RecLock("SA1",.F.)
			cObsMemo		:= SA1->A1_PRF_OBS
			SA1->A1_PRF_OBS	:= Alltrim(QALT->OBSMEMO)+Chr(13)+Chr(10)+cObsMemo
			SA1->(&(QALT->COLUNA)) := Alltrim(QALT->VALORATU)
			MsUnlock()
		Endif
		DbSelectARea("QALT")
		DbSkip()
	Enddo

	MsgAlert("Gravação Finalizada!")

Return

// 
Static Function sfAtuHistCli(dEmissao,cInCliente,cInLoja,cNumPed,cInObsrv)

	Local	cHistTlv		:= ""
	Local	nTamA1_HISTMK	:= TamSx3("A1_HISTMK")[1]
	// A1_PRF_OBS

	// Gravo no hist¢rio do cliente o contato, a data, a observa‡ao e a origem(TELEVENDAS)
	DbSelectArea("SA1")
	DbSetOrder(1)
	If DbSeek(xFilial("SA1") + cInCliente + cInLoja)
		Reclock("SA1",.F.)
		If Empty(SA1->A1_CODHIST)
			cHistTlv := DTOC(dEmissao)+"-Pedido Venda:" + cNumPed + CRLF
			cHistTlv += Alltrim(cInObsrv) + CRLF
			MSMM(,nTamA1_HISTMK,,cHistTlv,1,,,"SA1","A1_CODHIST")
		Else
			cHistTlv += DTOC(dEmissao)+"-Pedido Venda:" + cNumPed + CRLF
			cHistTlv += Alltrim(cInObsrv) + CRLF
			MSMM(SA1->A1_CODHIST,nTamA1_HISTMK,,cHistTlv,1,,,"SA1","A1_CODHIST",,.T.)
		Endif
		MsUnlock()
	Endif

Return
