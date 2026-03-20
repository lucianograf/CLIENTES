#include 'protheus.ch'
#include 'parmtype.ch'
#INCLUDE "topconn.ch"

#DEFINE N_NUMNF 2
#DEFINE N_PCOD	3
#DEFINE N_CUSTO 4
#DEFINE N_VEND	5

/*/{Protheus.doc} MLCFGM02
// Rotina para importar CSV e atualizar D2_CUSTO1 e F2_VEND1
@author Marcelo Alberto Lauschner
@since 21/08/2019
@version 1.0
@return ${return}, ${return_description}
@type User Function
/*/
User function MLCFGM02()
	

	Local 	oSay1
	Local 	oSay2
	Local 	oSButton1
	Local 	oSButton2
	Local 	oSButton3
	Private oGet1
	Private cGet1 		:= Space(250)


	Static oDlg


	RpcSetType(3)
	RpcSetEnv("01","0101",,,,,{"SF2","SD2"}) 

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Montagem da tela de processamento.                                  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	DEFINE MSDIALOG oDlg TITLE "Importar Arquivo" FROM 000, 000  TO 200, 550 COLORS 0, 16777215 PIXEL


	@ 032, 010 SAY oSay1 PROMPT "Arquivo:" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL

	@ 030, 035 MSGET oGet1 VAR cGet1 SIZE 180, 010 OF oDlg COLORS 0, 16777215 PIXEL
	DEFINE SBUTTON oSButton3 FROM 030, 215 TYPE 15 OF oDlg ENABLE ACTION sfSelFile(@cGet1)  PIXEL

	DEFINE SBUTTON oSButton1 FROM 050, 040 TYPE 01 OF oDlg ENABLE ACTION sfExec(Alltrim(cGet1),1)
	//DEFINE SBUTTON oSButton1 FROM 050, 080 TYPE 03 OF oDlg ENABLE ACTION sfExec(Alltrim(cGet1),2)
	DEFINE SBUTTON oSButton2 FROM 050, 120 TYPE 02 OF oDlg ENABLE ACTION oDlg:End()

	ACTIVATE MSDIALOG oDlg CENTERED

Return


/*/{Protheus.doc} sfSelFile
//TODO Descrição auto-gerada.
@author Marcelo Alberto Lauschner
@since 21/08/2019
@version 1.0
@return ${return}, ${return_description}
@param cGet1, characters, descricao
@type Static Function
/*/
Static Function sfSelFile(cGet1)

	cGet1 := cGetFile( 'Arquivos CSV|*.csv|' , 'Importação de arquivo', 1, 'C:\edi\', .F.,  GETF_LOCALHARD,.F., .T. )

Return


/*/{Protheus.doc} sfExec
//TODO Descrição auto-gerada.
@author Marcelo Alberto Lauschner
@since 21/08/2019
@version 1.0
@return ${return}, ${return_description}
@param cGet1, characters, descricao
@param nInOpc, numeric, descricao
@type function
/*/
Static Function sfExec(cGet1,nInOpc)

	//³ Abertura do arquivo texto                                           ³
	Local 	aAreaOld	:= GetArea()
	Local	_aTmp	
	Local	_cLine
	Local	aLinhas
	Local	nHdl    := FT_FUse(cGet1)//fOpen(cGet1,32)
	Local	nQtdLin
	
	If nHdl == -1
		MsgAlert("O arquivo de nome "+cArqTxt+" nao pode ser aberto! Verifique os parametros.","Atencao!")
		Return
	Endif                                                     


	FT_FGoTop()

	// Retorna o número de linhas do arquivo
	nQtdLin := FT_FLastRec()
	If !MsgNoYes("Deseja executar rotina de atualização em " + cValToChar(nQtdLin) + " registros? ")
		RestArea(aAreaOld)
		Return 
	Endif
	
	aLinhas	:=	{}
	
	While !FT_FEOF()
		_aTMP	:={}
		_cLine 	:= FT_FReadLn()
		_cLine  += ";"
		
		//MsgAlert(_cLine)
		
		_cLine	:=	StrTran(_cLine,".","")
		_cLine	:=	StrTran(_cLine,",",".")
		_cLine	:=	StrTran(_cLine,'"','')
		_cLine	:=	StrTran(_cLine,';;','; ;')
		_cLine	:=	StrTran(_cLine,';;','; ;')
		_aTMP 	:=	StrTokArr(_cLine,";")
		
		If Len(_aTMP) > 0
			Aadd(aLinhas,_aTMP)
		Endif


		FT_FSKIP()
	EndDo
	// Fecha o Arquivo
	FT_FUSE()
	
	If nInOpc	== 1
		Processa({||  sfGrvSD2(aLinhas) },"Processando...")
	Endif


	RestArea(aAreaOld)
Return


/*/{Protheus.doc} sfGrvSD2
// Localizar registros e efetua gravação na SD2 e SF2
@author Marcelo Alberto Lauschner
@since 21/08/2019
@version 1.0
@return ${return}, ${return_description}
@param aLinhas, array, descricao
@type function
/*/
Static Function sfGrvSD2(aLinhas)

	Local	i
	Local	cQry
	
	ProcRegua(Len(aLinhas))

	For i	:= 1 To Len(aLinhas)
		IncProc( cValToChar(i) + " Nota " + aLinhas[i,N_NUMNF ])
		cQry := "SELECT D2.R_E_C_N_O_ D2RECNO,F2.R_E_C_N_O_ F2RECNO " 
		cQry += "  FROM " + RetSqlName("SD2") + " D2, " + RetSqlName("SF2") + " F2 "
		cQry += " WHERE D2.D_E_L_E_T_ =' ' "
		cQry += "   AND D2_COD = '" + aLinhas[i,N_PCOD] + "' "
		cQry += "   AND D2_DOC = '" + aLinhas[i,N_NUMNF ] + "' "
		cQry += "   AND D2_FILIAL = '" + xFilial("SD2") + "' " 
		cQry += "   AND F2.D_E_L_E_T_ = ' ' "
		cQry += "   AND F2_LOJA = D2_LOJA "
		cQry += "   AND F2_CLIENTE = D2_CLIENTE "
		cQry += "   AND F2_SERIE = D2_SERIE "
		cQry += "   AND F2_DOC = D2_DOC "
		cQry += "   AND F2_FILIAL = '" + xFilial("SF2")+ "'" 
		
		TcQuery cQry New Alias "QSD2"
		
		While QSD2->(!Eof())
			
			DbSelectArea("SD2")
			DbGoto(QSD2->D2RECNO)
			RecLock("SD2",.F.)
			SD2->D2_CUSTO1 	:= Val(aLinhas[i,N_CUSTO])
			MsUnlock()
			
			DbSelectArea("SF2")
			DbGoto(QSD2->F2RECNO)
			RecLock("SF2",.F.)
			SF2->F2_VEND1 	:= aLinhas[i,N_VEND]
			MsUnlock()
			
			DbSelectArea("QSD2")
			DbSkip()
		Enddo
		
		QSD2->(DbCloseArea())   
	Next i	

Return
