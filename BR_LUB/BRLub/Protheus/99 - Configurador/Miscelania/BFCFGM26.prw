#include 'protheus.ch'
#include 'parmtype.ch'
#INCLUDE "topconn.ch"


#DEFINE _CGC		1
#DEFINE _IE			2
#DEFINE _RSOCIAL	3
#DEFINE _NREDUZ		4
#DEFINE _CEP		5
#DEFINE _END		6
#DEFINE _NUM		7
#DEFINE _BAIRRO		8
#DEFINE _COMP		9
#DEFINE _EMAIL 		10
#DEFINE _DDD		11
#DEFINE _TEL		12
#DEFINE _MUN		13
#DEFINE _EST		14
#DEFINE _RAMACC		15 
#DEFINE _PRICOM		16
#DEFINE _ULTCOM 	17 


/*/{Protheus.doc} BFCFGM26
//Função para importação de cadastro de clientes via Planilha
@author Marcelo Alberto Lauschner
@since 07/04/2018
@version 6
@return ${return}, ${return_description}

@type function
/*/
User Function BFCFGM26()
	//--------------------

	Local 	oSay1
	Local 	oSay2
	Local 	oSButton1
	Local 	oSButton2
	Local 	oSButton3
	Private oGet1
	Private cGet1 		:= Space(250)


	Static oDlg


	RpcSetType(3)
	RpcSetEnv("02","08",,,,,{"SA1"}) 

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Montagem da tela de processamento.                                  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	DEFINE MSDIALOG oDlg TITLE "Importar Arquivo" FROM 000, 000  TO 200, 550 COLORS 0, 16777215 PIXEL


	@ 032, 010 SAY oSay1 PROMPT "Arquivo:" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL

	@ 030, 035 MSGET oGet1 VAR cGet1 SIZE 180, 010 OF oDlg COLORS 0, 16777215 PIXEL
	DEFINE SBUTTON oSButton3 FROM 030, 215 TYPE 15 OF oDlg ENABLE ACTION sfSelFile(@cGet1)  PIXEL

	DEFINE SBUTTON oSButton1 FROM 050, 040 TYPE 01 OF oDlg ENABLE ACTION sfExec(Alltrim(cGet1),1)
	DEFINE SBUTTON oSButton1 FROM 050, 080 TYPE 03 OF oDlg ENABLE ACTION sfExec(Alltrim(cGet1),2)
	DEFINE SBUTTON oSButton2 FROM 050, 120 TYPE 02 OF oDlg ENABLE ACTION oDlg:End()

	ACTIVATE MSDIALOG oDlg CENTERED

Return


/*/{Protheus.doc} sfSelFile
//Seleciona o Arquivo para importar 
@author marce
@since 07/04/2018
@version 6
@return ${return}, ${return_description}
@param cGet1, characters, descricao
@type function
/*/
Static Function sfSelFile(cGet1)

	cGet1 := cGetFile( 'Arquivos CSV|*.csv|' , 'Importação de clientes', 1, 'C:\', .F.,  GETF_LOCALHARD,.F., .T. )

Return


/*/{Protheus.doc} sfExec
//Função que efetua a geração do cadastro do cliente ou Fornecedor
@author Marcelo Alberto Lauschner 
@since 07/04/2018
@version 6
@return ${return}, ${return_description}
@param cGet1, characters, descricao
@param nInOpc, numeric, descricao
@type function
/*/
Static Function sfExec(cGet1,nInOpc)

	//³ Abertura do arquivo texto                                           ³
	Local aAreaOld	:= GetArea()

	Private nHdl    := FT_FUse(cGet1)//fOpen(cGet1,32)

	If nHdl == -1
		MsgAlert("O arquivo de nome "+cArqTxt+" nao pode ser aberto! Verifique os parametros.","Atencao!")

		Return
	Endif                                                     


	FT_FGoTop()

	// Retorna o número de linhas do arquivo
	//nQtdLin := FT_FLastRec()

	aCli	:=	{}
	
	While !FT_FEOF()
		_aTMP	:={}
		_cLine 	:= FT_FReadLn()
		_cLine  += ";"
		//MsgAlert(_cLine)
		_cLine	:=	StrTran(_cLine,".","")
		_cLine	:=	StrTran(_cLine,"(","")
		_cLine	:=	StrTran(_cLine,"/","")
		_cLine	:=	StrTran(_cLine,")","")
		_cLine	:=	StrTran(_cLine,"-","")
		_cLine	:=	StrTran(_cLine,'"','')
		_cLine	:=	StrTran(_cLine,';;','; ;')
		_cLine	:=	StrTran(_cLine,';;','; ;')
		_cLine	:=	StrTran(_cLine,"'","") // Retira aspa simples 
		//MsgAlert(_cLine)
		
		_aTMP 	:=	StrTokArr(_cLine,";")
		
		If Len(_aTMP) > 0
			Aadd(aCli,_aTMP)
		Endif


		FT_FSKIP()
	EndDo
	// Fecha o Arquivo
	FT_FUSE()
	If nInOpc	== 1
		sfGrvSA1(aCli)
	ElseIf nInOpc == 2
		sfGrvSA2(aCli)
	Endif


	RestArea(aAreaOld)
Return


/*/{Protheus.doc} sfGrvSA1
//Função que efetua a gravação do Cadastro de Cliente
@author Marcelo Alberto Lauschner
@since 07/04/2018
@version 6
@return ${return}, ${return_description}
@param aCli, array, descricao
@type function
/*/
Static Function sfGrvSA1(aCli)

	Local 	aCPFNAO 	:= {}
	Local	i,j
	Private lMsErroAuto := .f.	//atualizado quando houver alguma incosistencia nos parametros

	DbSelectArea("SA1")
	dbSetOrder(3)


	For i	:= 1 To Len(aCli)


		//Se não encontrar o cliente não insere o pedido
		If SA1->(DbSeek(xFilial("SA1")+ aCli[i,_CGC]))
		
		Else
		
			_aCab		:=	{}
			
			cCODMUN		:= 	""
			
			cCGC		:=	Alltrim(aCli[i,_CGC])
			cIE			:=  Alltrim(aCli[i,_IE])
			If Empty(cIE)
				cIE	:= "ISENTO"
			Endif
			cRSOCIAL	:=	Padr(aCli[i,_RSOCIAL],TamSX3("A1_NOME")[1])
			cNREDUZ		:=	Padr(aCli[i,_NREDUZ],TamSX3("A1_NREDUZ")[1])
			If Empty(cNREDUZ)
				cNREDUZ	:= Padr(cRSOCIAL,TamSX3("A1_NREDUZ")[1])
			Endif 
			cCEP		:=	Alltrim(aCli[i,_CEP])
			cEND		:=	Alltrim(aCli[i,_END])
			cNUM		:=	Alltrim(aCli[i,_NUM])
			cBAIRRO		:= 	Padr(aCli[i,_BAIRRO],TamSX3("A1_BAIRRO")[1])
			cCOMP		:=	Alltrim(aCli[i,_COMP])
			cEMAIL		:=	Alltrim(aCli[i,_EMAIL])
			If Empty(cEMAIL)
				cEMAIL	:= "sem_email@importacaocadastro.com"
			Endif 
			cDDD		:=  Alltrim(aCli[i,_DDD])
			cTEL		:=	Alltrim(aCli[i,_TEL])
			cMUN		:=	UPPER(Alltrim(aCli[i,_MUN]))
			cEST		:=	Alltrim(aCli[i,_EST])
			cRAMACC		:=  Alltrim(aCli[i,_RAMACC])
			
			cTIPO		:=  "F" 	// Consumidor Final
			cPESSOA		:=  IIf(Len(cCGC) == 11,"F","J")
			
			If !Empty(cNUM)
				cEND+=", "+cNUM
			Endif


			dbSelectArea("CC2")
			CC2->(dbSetOrder(2))
			If CC2->(dbSeek(xFilial("CC2")+AllTrim(cMUN)))

				While CC2->(!Eof()) .And. xFilial("CC2") == CC2->CC2_FILIAL .AND. ;
					AllTrim(cMUN) == AllTrim(CC2->CC2_MUN) 

					If CC2->CC2_EST == cEST
						cCODMUN := CC2->CC2_CODMUN
						Exit
					Endif

					CC2->(dbSkip())
				Enddo

			Endif

			CC2->(dbSetOrder(1))							

			aadd(_aCab,{"A1_PESSOA"  	,cPESSOA		,Nil})
			aAdd(_aCab,{"A1_CGC"		,cCGC			,Nil})			
			aAdd(_aCab,{"A1_NOME"		,cRSOCIAL		,Nil})		
			aAdd(_aCab,{"A1_NREDUZ"		,cNREDUZ		,Nil})
			aadd(_aCab,{"A1_TIPO"       ,cTIPO			,Nil})
			aAdd(_aCab,{"A1_CEP"		,cCEP			,Nil})
			aAdd(_aCab,{"A1_END"		,cEND			,Nil})					
			aAdd(_aCab,{"A1_MUN"	  	,cMUN			,Nil})
			aAdd(_aCab,{"A1_EST"		,cEST			,Nil})
			If !empty(cCODMUN)
				aadd(_aCab,{"A1_COD_MUN"	,cCODMUN	, Nil })
			endif
			aAdd(_aCab,{"A1_INSCR"		,cIE			,Nil})		
			If Empty(cTEL)
				cTEL	:= "99999999"	
			Endif 
			aAdd(_aCab,{"A1_TEL"		,cTEL			,Nil})			
			aadd(_aCab,{"A1_CONTRIB"	,"2"			,Nil })			
			aAdd(_aCab,{"A1_COMPLEM"	,cCOMP			,Nil})					
			aAdd(_aCab,{"A1_DDD"		,cDDD			,Nil})
			aAdd(_aCab,{"A1_BAIRRO"		,cBAIRRO		,Nil})									
			aAdd(_aCab,{"A1_EMAIL"		,cEMAIL			,Nil})

			Aadd(_aCab,{"A1_RAMACCE"	,cRAMACC		,Nil})
			
			Aadd(_aCab,{"A1_OBSMEMO"	,"#IMPORTACAO MG - CADASTRO INCOMPLETO - Primeira Compra: " + Alltrim(aCli[i,_PRICOM]) + " Última Compra: " + Alltrim(aCli[i,_ULTCOM]) ,Nil})
			Aadd(_aCab,{"A1_BLOQCAD"	,"6"			,Nil})
			lMSErroAuto:=.F.
			Begin Transaction

 
				MSExecAuto({|x,y|MATA030(x,y)},_aCab,3)

				If lMSErroAuto
					DisarmTransaction()
					RollBackSX8()

					aadd(aCPFNAO, {cCGC, cRSOCIAL })

					MostraErro()
				Else
					If __lSx8
						ConfirmSx8()
					EndIf
				EndIf
			End Transaction
		Endif   
	Next i	

	For j := 1 To Len(aCPFNAO)

		MsgAlert(aCPFNAO[j,1]+"|"+aCPFNAO[j,2] )

	Next

Return


/*/{Protheus.doc} sfGrvSA2
//Função que efetua a gravação do Cadastro de Fornecedores
@author Marcelo Alberto Lauschner
@since 07/04/2018
@version 6
@return ${return}, ${return_description}
@param aCli, array, descricao
@type function
/*/
Static Function sfGrvSA2(aCli)

	Local 	aCPFNAO 	:= {}
	Local	i,j
	Private lMsErroAuto := .f.	//atualizado quando houver alguma incosistencia nos parametros

	DbSelectArea("SA2")
	dbSetOrder(3)


	For i	:= 1 To Len(aCli)


		//Se não encontrar o cliente não insere o pedido
		If SA2->(DbSeek(xFilial("SA2")+ aCli[i,_CGC]))
		
		Else
		
			_aCab		:=	{}
			
			cCODMUN		:= 	""
			
			cCGC		:=	Alltrim(aCli[i,_CGC])
			cIE			:=  Alltrim(aCli[i,_IE])
			If Empty(cIE)
				cIE	:= "ISENTO"
			Endif
			cRSOCIAL	:=	Padr(aCli[i,_RSOCIAL],TamSX3("A2_NOME")[1])
			cNREDUZ		:=	Padr(aCli[i,_NREDUZ],TamSX3("A2_NREDUZ")[1])
			cCEP		:=	Alltrim(aCli[i,_CEP])
			cEND		:=	Alltrim(aCli[i,_END])
			cNUM		:=	Alltrim(aCli[i,_NUM])
			cBAIRRO		:= 	Padr(aCli[i,_BAIRRO],TamSX3("A2_BAIRRO")[1])
			cCOMP		:=	Alltrim(aCli[i,_COMP])
			cEMAIL		:=	Alltrim(aCli[i,_EMAIL])
			cDDD		:=  Alltrim(aCli[i,_DDD])
			cTEL		:=	Alltrim(aCli[i,_TEL])
			cMUN		:=	Alltrim(aCli[i,_MUN])
			cEST		:=	Alltrim(aCli[i,_EST])
			
			cTIPO		:=  IIf(Len(cCGC) == 11,"F","J")
			
			If !Empty(cNUM)
				cEND+=", "+cNUM
			Endif


			dbSelectArea("CC2")
			CC2->(dbSetOrder(2))
			If CC2->(dbSeek(xFilial("CC2")+AllTrim(cMUN)))

				While CC2->(!Eof()) .And. xFilial("CC2") == CC2->CC2_FILIAL .And. ;
					AllTrim(cMUN) == AllTrim(CC2->CC2_MUN) 

					If CC2->CC2_EST == cEST
						cCODMUN := CC2->CC2_CODMUN
						Exit
					Endif

					CC2->(dbSkip())
				Enddo

			Endif

			CC2->(dbSetOrder(1))							

			aadd(_aCab,{"A2_TIPO"       ,cTIPO			,Nil})
			aAdd(_aCab,{"A2_CGC"		,cCGC			,Nil})			
			aAdd(_aCab,{"A2_NOME"		,cRSOCIAL		,Nil})		
			aAdd(_aCab,{"A2_NREDUZ"		,cNREDUZ		,Nil})
			aAdd(_aCab,{"A2_CEP"		,cCEP			,Nil})
			aAdd(_aCab,{"A2_END"		,cEND			,Nil})					
			aAdd(_aCab,{"A2_MUN"	  	,cMUN			,Nil})
			aAdd(_aCab,{"A2_EST"		,cEST			,Nil})
			If !empty(cCODMUN)
				aadd(_aCab,{"A2_COD_MUN"	,cCODMUN	, Nil })
			endif
			aAdd(_aCab,{"A2_INSCR"		,cIE			,Nil})			
			aAdd(_aCab,{"A2_TEL"		,cTEL			,Nil})			
			aAdd(_aCab,{"A2_COMPLEM"	,cCOMP			,Nil})					
			aAdd(_aCab,{"A2_DDD"		,cDDD			,Nil})
			aAdd(_aCab,{"A2_BAIRRO"		,cBAIRRO		,Nil})									
			aAdd(_aCab,{"A2_EMAIL"		,cEMAIL			,Nil})
			

			lMSErroAuto:=.F.
			Begin Transaction

				INCLUI	:= .T. 
				MSExecAuto({|x,y|MATA020(x,y)},_aCab,3)

				If lMSErroAuto
					DisarmTransaction()
					RollBackSX8()

					aadd(aCPFNAO, {cCGC, cRSOCIAL })

					MostraErro()
				Else
					If __lSx8
						ConfirmSx8()
					EndIf
				EndIf
			End Transaction
		Endif   
	Next i	

	For j := 1 To Len(aCPFNAO)

		MsgAlert(aCPFNAO[j,1]+"|"+aCPFNAO[j,2] )

	Next

Return
