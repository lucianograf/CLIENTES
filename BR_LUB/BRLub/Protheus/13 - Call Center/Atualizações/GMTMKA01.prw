#INCLUDE "PROTHEUS.CH"
#DEFINE RDDSPED "TOPCONN"

Static __nConecta
Static lInitSped := .F.


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³GMTMKA01  ºAutor  ³Marcelo Lauschner   º Data ³  07/07/11   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Compatibilizador para Nova Tela Gerenciamento Inadimplenciaº±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ AP                                                        º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

//---------------------------------------------------------------------------------------
// Analista   : Marcelo Alberto Lauschner - 07/07/2011
// Nome função: GMTMKA01
// Parametros : 
// Objetivo   : Executa a chamada para criação da Tabela CONDORTMKC
// Retorno    : 
// Alterações : 
//---------------------------------------------------------------------------------------

User Function GMTMKA01()

Local bError := ErrorBlock({|e| ConOut("Totvs - Internal error:"+e:errorstack),DisarmTransaction(),MS_QUIT()})


If !lInitSped
	lInitSped := .T.
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Configura os parametros iniciais                     ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	PUBLIC __TTSINUSE   := .T.
	PUBLIC __cLogSiga   :="NNNNNN"
	PUBLIC __TTSBREAK   := .f.
	PUBLIC __TTSPush    := {}
	Public __lFkInUse   := .F.
	PUBLIC __TTSCommit
	PUBLIC __lACENTO    := .F.
	PUBLIC __Language   := 'PORTUGUESE'
	PUBLIC lMsFinalAuto := .T.
	PUBLIC __LocalDriver:= "DBFCDX"
	SET DELETED ON
	SET SCOREBOARD OFF
	SET DATE BRITISH
	SET(4,"DD/MM/YYYY")	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Carrega as tabelas                                   ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	LoadDicSPED("CONDORTMKC") // Tabela customizada para uso da carga de dados da Tela de cobrança
	If Select("CONDORTMKC") > 0
		CONDORTMKC->(DbCloseArea())
	Endif
	
EndIf                                                                              

//---------------------------------------------------------------------------------------
// Analista   : Marcelo Alberto Lauschner - 07/07/2011
// Nome função: GMTMKAUP
// Parametros : 
// Objetivo   : Compatibilizador para criação dos campos necessários para rotina
//              nova Gerenciamento de Inadimplencias Grupo Meyer
// Retorno    : 
// Alterações : 
//---------------------------------------------------------------------------------------

User Function GMTMKAUP() 

cArqEmp := "SigaMat.Emp"
__cInterNet := Nil
                                    
PRIVATE cMessage
PRIVATE aArqUpd	 := {}
PRIVATE aREOPEN	 := {}
PRIVATE oMainWnd 

Set Dele On

lHistorico 	:= MsgYesNo(OemToAnsi("Deseja efetuar a atualizacao do Dicionário? Esta rotina deve ser utilizada em modo exclusivo ! Faca um backup dos dicionários e da Base de Dados antes da atualização para eventuais falhas de atualização !"), OemToAnsi("Atenção"))
lEmpenho	:= .F.
lAtuMnu		:= .F.

DEFINE WINDOW oMainWnd FROM 0,0 TO 01,30 TITLE OemToAnsi("Atualização do Dicionário")

ACTIVATE WINDOW oMainWnd ;
	ON INIT If(lHistorico,(Processa({|lEnd| ComProc(@lEnd)},OemToAnsi("Processando"),OemToAnsi("Aguarde , processando preparação dos arquivos"),.F.) , Final(OemToAnsi("Atualização efetuada!"))),oMainWnd:End())
	
Return

/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ComProc   ³ Autor ³Microsiga S/A          ³ Data ³06/09/2007³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Funcao de processamento da gravacao dos arquivos           ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ Atualizacao COM                                            ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Static Function ComProc(lEnd)
Local cTexto    := ''
Local cFile     :=""
Local cMask     := "Arquivos Texto (*.TXT) |*.txt|"
Local nRecno    := 0
Local nI        := 0
Local nX        :=0
Local aRecnoSM0 := {}     
Local lOpen     := .F. 

ProcRegua(1)
IncProc(OemToAnsi("Verificando integridade dos dicionários...."))
If ( lOpen := MyOpenSm0Ex() )

	dbSelectArea("SM0")
	dbGotop()
	While !Eof() 
  		If Ascan(aRecnoSM0,{ |x| x[2] == M0_CODIGO}) == 0 //--So adiciona no aRecnoSM0 se a empresa for diferente
			Aadd(aRecnoSM0,{Recno(),M0_CODIGO})
		EndIf			
		dbSkip()
	EndDo	
		
	If lOpen
		For nI := 1 To Len(aRecnoSM0)
			SM0->(dbGoto(aRecnoSM0[nI,1]))
			RpcSetType(2) 
			RpcSetEnv(SM0->M0_CODIGO, SM0->M0_CODFIL)
			nModulo := 05 //SIGAFAT
			lMsFinalAuto := .F.
			cTexto += Replicate("-",128)+CHR(13)+CHR(10)
			cTexto += "Empresa : "+SM0->M0_CODIGO+SM0->M0_NOME+CHR(13)+CHR(10)
			ProcRegua(8)  
	
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Atualiza o dicionario de dados (SX3) ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			IncProc(OemToAnsi("Analisando Dicionario de Dados..."))
			cTexto += ComAtuSX3()
			
			IncProc(OemToAnsi("Analisando Dicionario de Dados..."))
			cTexto += ComAtuSX7()
			
			__SetX31Mode(.F.)
			For nX := 1 To Len(aArqUpd)
				IncProc(OemToAnsi("Atualizando estruturas. Aguarde... [")+aArqUpd[nx]+"]")
				If Select(aArqUpd[nx])>0
					dbSelecTArea(aArqUpd[nx])
					dbCloseArea()
				EndIf
				X31UpdTable(aArqUpd[nx])
				If __GetX31Error()
					Alert(__GetX31Trace())
					Aviso("Atencao!","Ocorreu um erro desconhecido durante a atualizacao da tabela : "+ aArqUpd[nx] + ". Verifique a integridade do dicionario e da tabela.",{"Continuar"},2)
					cTexto += "Ocorreu um erro desconhecido durante a atualizacao da estrutura da tabela : "+aArqUpd[nx] +CHR(13)+CHR(10)
				EndIf
			Next nX		
			RpcClearEnv()
			If !( lOpen := MyOpenSm0Ex() )
				Exit 
			EndIf 
		Next nI 
		   
		If lOpen
			
			cTexto := "Log da atualizacao "+CHR(13)+CHR(10)+cTexto

			__cFileLog := MemoWrite(Criatrab(,.f.)+".LOG",cTexto)
			DEFINE FONT oFont NAME "Mono AS" SIZE 5,12   //6,15
			DEFINE MSDIALOG oDlg TITLE "Atualizacao concluida." From 3,0 to 340,417 PIXEL
			@ 5,5 GET oMemo  VAR cTexto MEMO SIZE 200,145 OF oDlg PIXEL
			oMemo:bRClicked := {||AllwaysTrue()}
			oMemo:oFont:=oFont
			DEFINE SBUTTON  FROM 153,175 TYPE 1 ACTION oDlg:End() ENABLE OF oDlg PIXEL //Apaga
			DEFINE SBUTTON  FROM 153,145 TYPE 13 ACTION (cFile:=cGetFile(cMask,""),If(cFile="",.t.,MemoWrite(cFile,cTexto))) ENABLE OF oDlg PIXEL //Salva e Apaga //"Salvar Como..."
			ACTIVATE MSDIALOG oDlg CENTER
			
		EndIf 
		
	EndIf   
	RpcSetType(2) 
	RpcSetEnv(SM0->M0_CODIGO, SM0->M0_CODFIL)
	nModulo := 05 //SIGAFAT
		                                                 
	U_GMTMKA01()
	
	RpcClearEnv()
	
Else
	MsgInfo("Não foi possível abertura das empresas para atualização do dicionário de dados!")		
EndIf 	




CursorArrow()


MsgAlert("Processo finalizado!")

Return(.T.)

/*/{Protheus.doc} LoadDicSped
Criação da Tabela CONDORTMKC
@type function
@version 
@author Marcelo Alberto Lauschner
@since  07/07/2011
@param cTable, character, param_description
@return return_type, return_description
/*/
Static Function LoadDicSped(cTable)

Local aCampos := {}
Local aArqStru:= {}
Local aIndices:= {}
Local aTemp   := {}

Local cUnique := ""
Local cDriver := RDDSPED
Local cOrd    := ""
Local cOrdName:= ""

Local cDataBase := ""
Local cAlias    := ""
Local cServer   := ""
Local cConType  := ""
Local cHasMapper:= ""
Local cProtect  := ""
Local CTSerial:= ""

Local nPort     := 0
Local nX

Local lBuildIndex:= .F.
Local lUnique
Local lCreate := .F.

Do Case
	Case cTable == "CONDORTMKC"
		
		cUnique := "CTC_EMPRES+CTC_FILIAL+CTC_CLIENT+CTC_LOJA"
		
		Aadd(aCampos,{"CTC_EMPRES","C",002,0})  // Código da Empresa
		Aadd(aCampos,{"CTC_FILIAL","C",002,0})	// Código da Filial
		Aadd(aCampos,{"CTC_CLIENT","C",006,0})  // Código do Cliente
		Aadd(aCampos,{"CTC_LOJA  ","C",002,0})	// Loja
		Aadd(aCampos,{"CTC_NATRAS","N",010,0})	// Numero Titulos em Atraso
		Aadd(aCampos,{"CTC_ATRASO","N",016,2})	// Valor Titulos em Atraso
		Aadd(aCampos,{"CTC_DATA"  ,"D",008,0})	// Data da Inclusão do Cliente na Lista
		Aadd(aCampos,{"CTC_RETORN","D",008,0})	// Data do Retorno Ligação
		Aadd(aCampos,{"CTC_AGEDEP","D",008,0})	// Data do Agendamento Deposito
		Aadd(aCampos,{"CTC_ULTACF","D",008,0})	// Data do ultimo atdo Telecobranca                      
		Aadd(aCampos,{"CTC_NSERAS","N",010,0})	// Qte titulos no serasa
		Aadd(aCampos,{"CTC_DTSERA","D",008,0})	// Data Ultima Negativação Serasa
		Aadd(aCampos,{"CTC_STATUS","C",001,0})	// Status - 1=Verde(Novo sem Historico)2=Vermelho(Serasa)
		Aadd(aCampos,{"CTC_DTMIN" ,"D",008,0})	// Menor dia de Vencimento
		Aadd(aCampos,{"CTC_DTMAX" ,"D",008,0})  // Maior Dia de Vencimento
		                                                           		
		Aadd(aIndices,{cUnique,"PK"})
		Aadd(aIndices,{"CTC_EMPRES+CTC_FILIAL+CTC_CLIENT+CTC_LOJA+DTOS(CTC_DATA)","01"})
		Aadd(aIndices,{"CTC_EMPRES+CTC_FILIAL+DTOS(CTC_DATA)","02"})

EndCase
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ RDD CTRE                                             ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If cDriver == "CTREECDX"
	If (AllTrim(upper(GetPvProfString("general","ctreemode","local",GetAdv97()))) $ "SERVER,BOUNDSERVER")
		CTSerial := CTSerialNumber()
		If !CTChkSerial(CTSerial)
			UserException('CTreeServer license limited to ISAM / SXS files only. Serial Number ['+CTSerial+']')
		EndIf
	EndIf
EndIf
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ RDD TOP                                              ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If cDriver == "TOPCONN"
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Conecta no TopConn                                   ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If __nConecta == Nil
			// Verifica as chaves da seção TOPCONNECT
			cDataBase  	:= GetPvProfString("TopConnect","DataBase","ERROR",GetADV97())
			cAlias	   	:= GetPvProfString("TopConnect","Alias","ERROR",GetADV97())
			cServer	   	:= GetPvProfString("TopConnect","Server","ERROR",GetADV97())
			cConType   	:= Upper(GetPvProfString("TopConnect","Contype","TCPIP",GetADV97()))
			cHasMapper 	:= Upper(GetPvProfString("TopConnect","Mapper","ON",GetADV97()))
			cProtect   	:= GetPvProfString("TopConnect","ProtheusOnly","0",GetADV97())
			nPort      	:= Val(GetPvProfString("TopConnect","Port","0",GetADV97()))
			
			// Verifico se há chave da seção DBACCESS
			If ( 'ERROR' $ cDatabase ) .Or. Empty(cDataBase)
				cDataBase  	:= GetPvProfString("DBAccess","DataBase","ERROR",GetADV97())
			Endif
			If ( 'ERROR' $ cAlias ) .Or. Empty(cAlias)
				cAlias	   	:= GetPvProfString("DBAccess","Alias","ERROR",GetADV97())
			Endif
			If ( 'ERROR' $ cServer ) .Or. Empty(cServer)
				cServer	   	:= GetPvProfString("DBAccess","Server","ERROR",GetADV97())
			Endif
			If ( 'ERROR' $ cConType )
				cConType   	:= Upper(GetPvProfString("DBAccess","Contype","TCPIP",GetADV97()))
			Endif
			If ( 'ERROR' $ cHasMapper )
				cHasMapper 	:= Upper(GetPvProfString("DBAccess","Mapper","ON",GetADV97()))
			Endif
			If ( 'ERROR' $ cProtect )
				cProtect   	:= GetPvProfString("DBAccess","ProtheusOnly","0",GetADV97())
			Endif
			
			If nPort == 0
				nPort      	:= Val(GetPvProfString("DBAccess","Port","0",GetADV97()))
			Endif
			
			
			// Procuro as chaves na seção do Environment
			If ( 'ERROR' $ cDatabase ) .Or. Empty(cDataBase)
				cDataBase := GetPvProfString( GetEnvServer(), "DbDataBase", "", GetAdv97() )
				If Empty(cDataBase)
					cDataBase := GetPvProfString( GetEnvServer(), "TopDataBase", "ERROR", GetAdv97() )
				EndIf
			Endif
			
			If ( 'ERROR' $ cAlias )	 .Or. Empty(cAlias)
				cAlias := GetPvProfString( GetEnvServer(), "DbAlias"	, ""   , GetAdv97() )
				If Empty(cAlias)
					cAlias := GetPvProfString( GetEnvServer(), "TopAlias"	, "ERROR"   , GetAdv97() )
				EndIf
			Endif
			
			If ( 'ERROR' $ cServer ) .Or. Empty(cServer)	
				cServer    := GetPvProfString( GetEnvServer(), "DbServer"  , "", GetAdv97() )
				If empty(cServer)
					cServer := GetPvProfString( GetEnvServer(), "TopServer"  , "ERROR", GetAdv97() )
				Endif
			Endif
				
			If nPort == 0
				nPort      	:= Val(GetPvProfString(GetEnvServer(),"DbPort","0",GetADV97()))
			Endif
			
			If nPort == 0
				nPort	:= Val(GetPvProfString( GetEnvServer(), "TopPort"  , "0", GetAdv97() ))
			Endif
			
			
			cDataBase  	:= GetSrvProfString("TopDataBase",cDataBase)
			cAlias	   	:= GetSrvProfString("TopAlias",cAlias)
			cServer	   	:= GetSrvProfString("TopServer",cServer)
			cConType   	:= Upper(GetSrvProfString("TopContype",cConType))
			cHasMapper 	:= Upper(GetSrvProfString("TopMapper",cHasMapper))
			cProtect   	:= GetSrvProfString("TopProtheusOnly",cProtect)
			nPort      	:= Iif(nPort == 0 , 7890, nPort)
			
			If cProtect == "1"
				cProtect := "@@__@@"    //Assinatura para o TOP
			Else
				cProtect := ""
			EndIf
			
			If ! ( AllTrim(cContype) $ 'TCPIP/NPIPE' )
				MsgAlert('TOPConnect (INI Protheus Server)','Contype: '+cConType)
				Ms_Quit()
			EndIf
			
			If ( 'ERROR' $ cDatabase )
				MsgAlert('TOPConnect (INI Protheus Server)', 'Database: '+cDatabase)
				Ms_Quit()
			EndIf
			
			If ( 'ERROR' $ cAlias )
				MsgAlert('TOPConnect (INI Protheus Server)', 'Alias: '+cAlias)
				Ms_Quit()
			EndIf
			
			If ( 'ERROR' $ cServer )
				MsgAlert('TOPConnect (INI Protheus Server)','Server: '+cServer )
				Ms_Quit()
			EndIf
			
			TCConType(cConType)
		If (("AS" $ cAlias) .And. ("400" $ cAlias))
			While ( !KillApp() .and. !GlbLock() )
				Sleep(100)
			EndDo
			__nConecta := TCLink(cDataBase,cServer,nPort)
			GlbUnlock()
		Else
			__nConecta := -1
			__nConecta := TCLink(cProtect+"@!!@"+cDataBase+"/"+cAlias,cServer,nPort)
			If (__nConecta < 0)
				Do Case
					Case ( __nConecta == -34 )
						ConOut("No license") //TOPConnect - Excedeu licenças.
						Ms_Quit()
					Case ( __nConecta == -99 )
						ConOut("incompatible version") //"A versao do TOPConnect e incompativel com o servidor Protheus, atualize o TOPConnect"
						Ms_Quit()
					OtherWise
						ConOut("Connection failed") // 'TOPConnect - Falha de conexao' ## Erro
						Ms_Quit()
				EndCase
			EndIf
			TcInternal( 8, "Totvs Services SPED Gateway" )
		EndIf
	EndIf
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Criacao de tabelas conforme definicao                ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If ( LockByName(cTable+cDriver,.F.,.F.,.T.) )
		If !MSFile(RetArq(cDriver,cTable,.T.), ,cDriver)
			lCreate := .T.
			If TcSrvType() == "AS/400"
				TcCommit(5,.T.)
				DbCreate(cTable,aCampos,"TOPCONN")
				TcCommit(5,.F.)
				TcSysExe("CHGOBJOWN OBJ("+AllTrim(cTable)+") OBJTYPE(*FILE) NEWOWN(QUSER)")
			Else
				DBCreate(cTable, aCampos, cDriver)
			EndIf
			DbUseArea(.T.,cDriver,cTable,'__CREATETMP',.F.)
			If !Empty(cUnique) .And. !"AS"$TCSrvType()
				cUnique := ClearKey(cUnique)
				lUnique := TcCanOpen(cTable,cTable+"_UNQ")
				If ( lUnique .And. Empty(cUnique) ) .Or. (!lUnique .and. !Empty(cUnique) )
					If TcUnique(cTable,cUnique) <> 0
						UserException('Unique index creation error on table '+cTable+'. '+TCSQLError()+" or table is in use by other connection")
					EndIf
				EndIf
			EndIf
			DbCloseArea()
		Else
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Verifica se houve alteracao na tabela                ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			Use &(cTable) Alias &(cTable) SHARED NEW Via cDriver
			aArqStru := dbStruct()
			dbCloseArea()
			If CompStru(aCampos,aArqStru)
				lBuildIndex := .T.
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³ Verifica se houve alteracao na tabela                ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				aTemp := aCampos
				If aScan(aArqStru,{|x| AllTrim(x[1])=="DATE"})<>0 .And. aScan(aArqStru,{|x| AllTrim(x[1])=="DATE_NFE"})==0
					aadd(aCampos,{"DATE","D",8,0})
					aadd(aCampos,{"TIME","C",8,0})
				EndIf
				If !TcAlter(cTable,aArqStru,aCampos)
					UserException('Alter table in '+cTable+' is not possible!')
				EndIf
		    EndIf
		EndIf
		UnLockByName(cTable+cDriver,.F.,.F.,.T.)
	EndIf
Else
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ RDD CTREE                                            ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Criacao de tabelas conforme definicao                ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If !MSFile(RetArq(cDriver,cTable,.T.), ,cDriver)
		If ( LockByName(cTable+cDriver,.F.,.F.,.T.) )
			lCreate := .T.
			cOrdName := FileNoExt(cTable)+RetIndExt()
			If ( File(cOrdName) )
				If ( FErase(cOrdName) <> 0 )
					ConOut("Delete Index error. File in use.")
					Ms_Quit()
				EndIf
			EndIf
			DBCreate(cTable, aStruct, cDriver)
			UnLockByName(cTable+cDriver,.F.,.F.,.T.)
		EndIf
	EndIf
EndIf
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Verifica se os indices estao criados                 ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
cOrd := "00"
For nX := 1 To Len(aIndices)
	cOrd     := Soma1(cOrd)
	cOrdName := RetArq(cDriver,cTable+cOrd,.F.)
	If ( !MsFile(cTable,cOrdName,cDriver) )
		lBuildIndex := .T.
		Exit
	EndIf
Next nX
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Criacao de indices conforme definicao                ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If lBuildIndex
	If ( LockByName(cTable+cDriver,.F.,.F.,.T.) )
		DbUseArea(.T.,cDriver,cTable,'__CREATETMP',.F.)
		dbClearIndex()
		If !NetErr()
			If cDriver == "TOPCONN"
				cOrd := "00"
				For nX := 1 To Len(aIndices)
					cOrd := Soma1(cOrd,2)
					cOrdName := cTable+cOrd
					If ( TcCanOpen(cTable,cOrdName) )
						cQuery := 'DROP INDEX ' + cTable + '.' + cOrdName
						If TcSqlExec( cQuery ) <> 0
							cQuery := 'DROP INDEX ' + cOrdName
							TcSqlExec('DROP INDEX ' + cOrdName)
						EndIf
                	EndIf															
				Next nX
				TcRefresh( cTable )
				cOrd := "00"
				For nX := 1 To Len(aIndices)
					cOrd := Soma1(cOrd,2)
					cOrdName := cTable+cOrd
					If ( !TcCanOpen(cTable,cOrdName) )
						INDEX ON &(ClearKey(aIndices[nX][1])) TO &(cOrdName)
                	EndIf
				Next nX				
			Else
				If lBuildIndex
					CTreeDelIdx()
					cOrd := "00"
					For nX := 1 To Len(aIndices)
						cOrd     := Soma1(cOrd)
						cOrdName := cTable+cOrd+RetIndExt()
						INDEX ON &(aIndices[nX][1]) TAG &(cOrdName) TO &(FileNoExt(cTable))
					Next nX
				EndIf
			EndIf
			DbCloseArea()
		EndIf
		UnLockByName(cTable+cDriver,.F.,.F.,.T.)
	EndIf
EndIf
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Abertura de tabelas                                  ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
Use &(cTable) Alias &(cTable) SHARED NEW Via cDriver
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Abertura de indices                                  ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If cDriver == "TOPCONN"
	cOrd := "00"
	For nX := 1 To Len(aIndices)
		cOrd := Soma1(cOrd,2)
		cOrdName := cTable+cOrd
		DbSetIndex(cOrdName)
		DbSetNickName(OrdName(nX),cOrdName)
	Next nX
Else
	nX   := 1
	cOrd := "00"
	While ( ! Empty(OrdName(nX)) )
		cOrdName := cTable+cOrd
		If ( nX > Len(aIndices) )
			ConOut("Index OF "+cTable+" Corrupted")
			Ms_Quit()
		EndIf
		DbSetNickName(OrdName(nX),cOrdName)
		nX++
	EndDo
EndIf
DbSetOrder(1)

Return(.T.)

// 
Static Function CompStru(aTarget,aSource)
Local nI		:= 0
Local nPos		:= 0
Local lUnlike	:= .F.
Local nIntS, nIntT
For nI := 1 To Len( aTarget )
	nPos := Ascan( aSource, { |x| AllTrim( x[1] ) == AllTrim( aTarget [nI][1]) } )
	If ( nPos == 0 )
		lUnlike	:= .T.
	Else
		nIntS := aSource[nPos,3]-aSource[nPos,4]
		nIntT := aTarget[ni,3]-aTarget[ni,4]
		If aSource[npos,2] != "N"
			nIntS := aSource[nPos,3]
		EndIf
		If aTarget[ni,2] != "N"
			nIntT := aTarget[ni,3]
		EndIf
		If ( aSource [nPos][2] == aTarget[nI][2] )
			If nIntT == nIntS
				If ( aSource [nPos][4] <> aTarget[nI][4] )
					lUnlike	:= .T.
				EndIf
			Else
				If ( nIntS > nIntT )
				EndIf
				lUnlike	:= .T.
			EndIf
		Else
            lUnlike	:= .T.
		EndIf
	EndIf
	If ( lUnlike )
		Exit
	EndIf
Next
If ( ! lUnlike )
	For nI := 1 To Len( aSource )
		nPos := Ascan( aTarget, { |x| AllTrim( x[1] ) == AllTrim( aSource [nI][1]) } )
		If ( nPos == 0 )
			lUnLike := .T.
		EndIf
	Next
EndIf
Return( lUnlike )




/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³MyOpenSM0Ex³ Autor ³Microsiga S/A         ³ Data ³06/09/2007³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Efetua a abertura do SM0 exclusivo                         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ Atualizacao FIS                                            ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Static Function MyOpenSM0Ex()

Local lOpen := .F. 
Local nLoop := 0 

For nLoop := 1 To 20
	dbUseArea( .T.,, "SIGAMAT.EMP", "SM0", .F., .F. ) 
	If !Empty( Select( "SM0" ) ) 
		lOpen := .T. 
		dbSetIndex("SIGAMAT.IND") 
		Exit	
	EndIf
	Sleep( 500 ) 
Next nLoop 

If !lOpen
	Aviso( "Atencao !", "Nao foi possivel a abertura da tabela de empresas de forma exclusiva !", { "Ok" }, 2 ) 
EndIf                                 

Return( lOpen )



/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ComAtuSX3 ³ Autor ³Microsiga S/A          ³ Data ³06/09/2007³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Funcao de processamento da gravacao do SX3 - Campos        ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ Atualizacao COM                                            ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Static Function ComAtuSX3()
Local aSX3           := {}
Local aEstrut        := {}
Local i              := 0
Local j              := 0
Local lSX3	         := .F.
Local cTexto         := ''
Local cAlias         := ''
Local cReserv        := ''
Local cUsado         := ''
Local nI             := 0
Local lRet			 := .T.
Local cOrdem		 := "01"

aEstrut:= { "X3_ARQUIVO"	,"X3_ORDEM"  	,"X3_CAMPO"  	,"X3_TIPO"   	,"X3_TAMANHO"	,"X3_DECIMAL"	,"X3_TITULO" 	,"X3_TITSPA" 	,"X3_TITENG" 	,;
			"X3_DESCRIC"	,"X3_DESCSPA"	,"X3_DESCENG"	,"X3_PICTURE"	,"X3_VALID"  	,"X3_USADO"  	,"X3_RELACAO"	,"X3_F3"     	,"X3_NIVEL"  	,;
			"X3_RESERV" 	,"X3_CHECK"  	,"X3_TRIGGER"	,"X3_PROPRI" 	,"X3_BROWSE" 	,"X3_VISUAL" 	,"X3_CONTEXT"	,"X3_OBRIGAT"	,"X3_VLDUSER"	,;
			"X3_CBOX"   	,"X3_CBOXSPA"	,"X3_CBOXENG"	,"X3_PICTVAR"	,"X3_WHEN"   	,"X3_INIBRW" 	,"X3_GRPSXG" 	,"X3_FOLDER"	, "X3_PYME"	}


dbSelectArea("SX3")
SX3->(DbSetOrder(2))

//--Pesquisa um campo existente para gravar o Reserv e o Usado
If SX3->(MsSeek("E1_HIST")) 
	For nI := 1 To SX3->(FCount())
		If "X3_RESERV" $ SX3->(FieldName(nI))
			cReserv := SX3->(FieldGet(FieldPos(FieldName(nI))))
		EndIf
		If "X3_USADO"  $ SX3->(FieldName(nI))
			cUsado  := SX3->(FieldGet(FieldPos(FieldName(nI))))
		EndIf
	Next
EndIf

DbSelectArea("SX3")
DbSetOrder(1)
DbSeek("SK101")
While !Eof() .And. SX3->X3_ARQUIVO == "SK1"
	cOrdem := SX3->X3_ORDEM
	SX3->(DbSkip())
Enddo

//Criacao de novos campos na tabela SB1
If lRet             
		cOrdem	:= Soma1(cOrdem)
		//01 - K1_XSTATUS
		Aadd(aSX3,{	"SK1",;						//Arquivo
					cOrdem,;					//Ordem
					"K1_XSTATUS",;				//Campo
					"C",;						//Tipo
					1,;						   	//Tamanho
					0,;							//Decimal
					"Situacao",;			    //Titulo
					"Situacao",;				//Titulo SPA
					"Situacao",;	  	    	//Titulo ENG
					"Situacao Cobranca",;		//Descricao
					"Situacao Cobranca",;		//Descricao SPA
					"Situacao Cobranca",;		//Descricao ENG
					"@!",;		   				//Picture
					"",;						//VALID
					cUsado,;					//USADO
					"",;						//RELACAO
					"",;						//F3
					1,;							//NIVEL
					cReserv,;					//RESERV
					"",;						//CHECK
					"",;						//TRIGGER
					"N",;						//PROPRI
					"S",;						//BROWSE
					"A",;						//VISUAL
					"",;						//CONTEXT
					"",;						//OBRIGAT
					"",;					 	//VLDUSER
					"1=Serasa;2=Inad.Nova;3=Retornar Ligação;4=Novo c/Histórico;5=Cartório;6=Agendado Depósito;7=Protestado;8=Sem Status",;						//CBOX
					"1=Serasa;2=Inad.Nova;3=Retornar Ligação;4=Novo c/Histórico;5=Cartório;6=Agendado Depósito;7=Protestado;8=Sem Status",;						//CBOX SPA
					"1=Serasa;2=Inad.Nova;3=Retornar Ligação;4=Novo c/Histórico;5=Cartório;6=Agendado Depósito;7=Protestado;8=Sem Status",;						//CBOX ENG
					"",;						//PICTVAR
					"",;						//WHEN
					"",;						//INIBRW
					"",;						//SXG
					"",;						//FOLDER			
					"N"})						//PYME
		

		Aadd(aSX3,{	"ACG",;						//Arquivo
					"07",;					//Ordem
					"ACG_XSTATU",;				//Campo
					"C",;						//Tipo
					1,;						   	//Tamanho
					0,;							//Decimal
					"Situacao",;			    //Titulo
					"Situacao",;				//Titulo SPA
					"Situacao",;	  	    	//Titulo ENG
					"Situacao Cobranca",;		//Descricao
					"Situacao Cobranca",;		//Descricao SPA
					"Situacao Cobranca",;		//Descricao ENG
					"@!",;		   				//Picture
					"",;						//VALID
					cUsado,;					//USADO
					"",;						//RELACAO
					"",;						//F3
					1,;							//NIVEL
					cReserv,;					//RESERV
					"",;						//CHECK
					"",;						//TRIGGER
					"N",;						//PROPRI
					"S",;						//BROWSE
					"A",;						//VISUAL
					"",;						//CONTEXT
					"",;						//OBRIGAT
					"U_GMTMKA3V()",;		 	//VLDUSER
					"1=Serasa;2=Inad.Nova;3=Retornar Ligação;4=Novo c/Histórico;5=Cartório;6=Agendado Depósito;7=Protestado;8=Sem Status",;						//CBOX
					"1=Serasa;2=Inad.Nova;3=Retornar Ligação;4=Novo c/Histórico;5=Cartório;6=Agendado Depósito;7=Protestado;8=Sem Status",;						//CBOX SPA
					"1=Serasa;2=Inad.Nova;3=Retornar Ligação;4=Novo c/Histórico;5=Cartório;6=Agendado Depósito;7=Protestado;8=Sem Status",;						//CBOX ENG
					"",;						//PICTVAR
					"",;						//WHEN
					"",;						//INIBRW
					"",;						//SXG
					"",;						//FOLDER			
					"N"})						//PYME

EndIf

ProcRegua(Len(aSX3))   

SX3->(DbSetOrder(2))	

For i:= 1 To Len(aSX3)
	If !Empty(aSX3[i][1])
		If !dbSeek(aSX3[i,3])
			lSX3	:= .T.
			If !(aSX3[i,1]$cAlias)
				cAlias += aSX3[i,1]+"/"
				aAdd(aArqUpd,aSX3[i,1])
			EndIf
			RecLock("SX3",.T.)
			For j:=1 To Len(aSX3[i])
				If FieldPos(aEstrut[j])>0 .And. aSX3[i,j] != NIL
					FieldPut(FieldPos(aEstrut[j]),aSX3[i,j])
				EndIf
			Next j
			dbCommit()
			MsUnLock()
			IncProc("Atualizando Dicionario de Dados...") //
		Else
			lSX3	:= .T.
			If !(aSX3[i,1]$cAlias)
				cAlias += aSX3[i,1]+"/"
				aAdd(aArqUpd,aSX3[i,1])
			EndIf
			RecLock("SX3",.F.)
			For j:=1 To Len(aSX3[i])
				If FieldPos(aEstrut[j])>0 .And. aSX3[i,j] != NIL
					FieldPut(FieldPos(aEstrut[j]),aSX3[i,j])
				EndIf
			Next j
			dbCommit()
			MsUnLock()
			IncProc("Atualizando Dicionario de Dados...") //		
		Endif
	EndIf
Next i

DbSelectArea("SX3")
DbSetOrder(2)
DbSeek("E1_HIST")
If SX3->X3_TAMANHO <> 200
	RecLock("SX3",.F.)
	SX3->X3_TAMANHO	:= 200
	MsUnlock()
	aAdd(aArqUpd,"SE1")
	cAlias += "SE1"
Endif

DbSelectArea("SX3")
DbSetOrder(2)
DbSeek("ACG_HIST")
If SX3->X3_TAMANHO <> 200
	RecLock("SX3",.F.)
	SX3->X3_TAMANHO	:= 200
	MsUnlock()
	aAdd(aArqUpd,"ACG")
	cAlias += "ACG"
Endif

If lSX3
	cTexto := 'Foram alteradas as estruturas das seguintes tabelas : '+cAlias+CHR(13)+CHR(10)
EndIf

Return cTexto




/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ComAtuSX3 ³ Autor ³Microsiga S/A          ³ Data ³06/09/2007³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Funcao de processamento da gravacao do SX3 - Campos        ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ Atualizacao COM                                            ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Static Function ComAtuSX7()
Local	cTexto 	:= ""               
Local	cSeq    := "01"
Local	lExistX7	:= .F.		
                    
DbSelectArea("SX7")
DbSetOrder(1)
Dbseek("ACG_TITULO")
While !Eof() .And. SX7->X7_CAMPO == "ACG_TITULO"
	If Alltrim(SX7->X7_CDOMIN) =="ACG_XSTATU"
		lExistX7	:= .T.		
	Endif            
	cSeq	:= SX7->X7_SEQUENC
	DbSelectArea("SX7")
	DbSkip()
Enddo
If !lExistX7
	RecLock("SX7",.T.)
	SX7->X7_CAMPO	:= "ACG_TITULO"
	SX7->X7_SEQUENC := Soma1(cSeq)
	SX7->X7_REGRA	:= "U_GMTMKA03()"
	SX7->X7_CDOMIN 	:= "ACG_XSTATU"
	SX7->X7_TIPO	:= "P"
	SX7->X7_SEEK	:= "N"
	SX7->X7_ALIAS	:= " "
	SX7->X7_ORDEM   := 0
	SX7->X7_CHAVE	:= " "
	SX7->X7_CONDIC  := 'EXISTBLOCK("GMTMKA03")'
	SX7->X7_PROPRI	:= "U"
	MsUnlock()
	cTexto += "ACG_TITULO Sequencia "+Soma1(cSeq)
Endif
	

Return cTexto