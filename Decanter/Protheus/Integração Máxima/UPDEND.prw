#INCLUDE "PROTHEUS.CH"

#DEFINE SIMPLES Char( 39 )
#DEFINE DUPLAS  Char( 34 )

#DEFINE CSSBOTAO	"QPushButton { color: #024670; "+;
	"    border-image: url(rpo:fwstd_btn_nml.png) 3 3 3 3 stretch; "+;
	"    border-top-width: 3px; "+;
	"    border-left-width: 3px; "+;
	"    border-right-width: 3px; "+;
	"    border-bottom-width: 3px }"+;
	"QPushButton:pressed {	color: #FFFFFF; "+;
	"    border-image: url(rpo:fwstd_btn_prd.png) 3 3 3 3 stretch; "+;
	"    border-top-width: 3px; "+;
	"    border-left-width: 3px; "+;
	"    border-right-width: 3px; "+;
	"    border-bottom-width: 3px }"

//--------------------------------------------------------------------
/*/{Protheus.doc} UPDXML
Função de update de dicionários para compatibilização

@author TOTVS Protheus
@since  02/04/2015
@obs    Gerado por EXPORDIC - V.4.22.10.8 EFS / Upd. V.4.19.13 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
User Function UPDEND( cEmpAmb, cFilAmb )
	
	Local   aSay      := {}
	Local   aButton   := {}
	Local   aMarcadas := {}
	Local   cTitulo   := "ATUALIZAÇÃO DE DICIONÝRIOS E TABELAS"
	Local   cDesc1    := "Esta rotina tem como função fazer  a atualização  dos dicionários do Sistema ( SX?/SIX )"
	Local   cDesc2    := "Este processo deve ser executado em modo EXCLUSIVO, ou seja não podem haver outros"
	Local   cDesc3    := "usuários  ou  jobs utilizando  o sistema.  É EXTREMAMENTE recomendavél  que  se  faça um"
	Local   cDesc4    := "BACKUP  dos DICIONÝRIOS  e da  BASE DE DADOS antes desta atualização, para que caso "
	Local   cDesc5    := "ocorram eventuais falhas, esse backup possa ser restaurado."
	Local   cDesc6    := ""
	Local   cDesc7    := ""
	Local   lOk       := .F.
	Local   lAuto     := ( cEmpAmb <> NIL .or. cFilAmb <> NIL )
	Private oMainWnd  := NIL
	Private oProcess  := NIL
	Private _aPars := {}
	
	
	#IFDEF TOP
		TCInternal( 5, "*OFF" ) // Desliga Refresh no Lock do Top
	#ENDIF
	
	__cInterNet := NIL
	__lPYME     := .F.
	
	Set Dele On
	
	// Mensagens de Tela Inicial
	aAdd( aSay, cDesc1 )
	aAdd( aSay, cDesc2 )
	aAdd( aSay, cDesc3 )
	aAdd( aSay, cDesc4 )
	aAdd( aSay, cDesc5 )
	//aAdd( aSay, cDesc6 )
	//aAdd( aSay, cDesc7 )
	
	// Botoes Tela Inicial
	aAdd(  aButton, {  1, .T., { || lOk := .T., FechaBatch() } } )
	aAdd(  aButton, {  2, .T., { || lOk := .F., FechaBatch() } } )
	
	If lAuto
		lOk := .T.
	Else
		FormBatch(  cTitulo,  aSay,  aButton )
	EndIf
	
	If lOk
		If lAuto
			aMarcadas :={{ cEmpAmb, cFilAmb, "" }}
		Else
			aMarcadas := EscEmpresa()
		EndIf
		
		If !Empty( aMarcadas )
			
			Private __AliCXML 	:= AllTrim(_aPars[aScan(_aPars,{|x| AllTrim(Upper(x[2]))=="XX_TAB1"}),13])
			Private __AliIXML 	:= AllTrim(_aPars[aScan(_aPars,{|x| AllTrim(Upper(x[2]))=="XX_TAB2"}),13])
			Private __PrefCXML 	:= IIF(SubStr(__AliCXML,1,1)=="S",SubStr(__AliCXML,2,2),__AliCXML)
			Private __PrefIXML 	:= IIF(SubStr(__AliIXML,1,1)=="S",SubStr(__AliIXML,2,2),__AliIXML)
			
			If lAuto .OR. MsgNoYes( "Confirma a atualização dos dicionários ?", cTitulo )
				oProcess := MsNewProcess():New( { | lEnd | lOk := FSTProc( @lEnd, aMarcadas, lAuto ) }, "Atualizando", "Aguarde, atualizando ...", .F. )
				oProcess:Activate()
				
				If lAuto
					If lOk
						MsgStop( "Atualização Realizada.", "UPDXML" )
					Else
						MsgStop( "Atualização não Realizada.", "UPDXML" )
					EndIf
					dbCloseAll()
				Else
					If lOk
						Final( "Atualização Concluída." )
					Else
						Final( "Atualização não Realizada." )
					EndIf
				EndIf
				
			Else
				MsgStop( "Atualização não Realizada.", "UPDXML" )
				
			EndIf
			
		Else
			MsgStop( "Atualização não Realizada.", "UPDXML" )
			
		EndIf
		
	EndIf
	
Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} FSTProc
Função de processamento da gravação dos arquivos

@author TOTVS Protheus
@since  02/04/2015
@obs    Gerado por EXPORDIC - V.4.22.10.8 EFS / Upd. V.4.19.13 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSTProc( lEnd, aMarcadas, lAuto )
	Local   aInfo     := {}
	Local   aRecnoSM0 := {}
	Local   cAux      := ""
	Local   cFile     := ""
	Local   cFileLog  := ""
	Local   cMask     := "Arquivos Texto" + "(*.TXT)|*.txt|"
	Local   cTCBuild  := "TCGetBuild"
	Local   cTexto    := ""
	Local   cTopBuild := ""
	Local   lOpen     := .F.
	Local   lRet      := .T.
	Local   nI        := 0
	Local   nPos      := 0
	Local   nRecno    := 0
	Local   nX        := 0
	Local   oDlg      := NIL
	Local   oFont     := NIL
	Local   oMemo     := NIL
	
	Private aArqUpd   := {}
	
	If ( lOpen := MyOpenSm0(.T.) )
		
		dbSelectArea( "SM0" )
		dbGoTop()
		
		While !SM0->( EOF() )
			// Só adiciona no aRecnoSM0 se a empresa for diferente
			If aScan( aRecnoSM0, { |x| x[2] == SM0->M0_CODIGO } ) == 0 ;
					.AND. aScan( aMarcadas, { |x| x[1] == SM0->M0_CODIGO } ) > 0
				aAdd( aRecnoSM0, { Recno(), SM0->M0_CODIGO } )
			EndIf
			SM0->( dbSkip() )
		End
		
		SM0->( dbCloseArea() )
		
		If lOpen
			
			For nI := 1 To Len( aRecnoSM0 )
				
				If !( lOpen := MyOpenSm0(.F.) )
					MsgStop( "Atualização da empresa " + aRecnoSM0[nI][2] + " não efetuada." )
					Exit
				EndIf
				
				SM0->( dbGoTo( aRecnoSM0[nI][1] ) )
				
				RpcSetType( 3 )
				RpcSetEnv( SM0->M0_CODIGO, SM0->M0_CODFIL )
				
				lMsFinalAuto := .F.
				lMsHelpAuto  := .F.
				
				AutoGrLog( Replicate( "-", 128 ) )
				AutoGrLog( Replicate( " ", 128 ) )
				AutoGrLog( "LOG DA ATUALIZAÇÃO DOS DICIONÝRIOS" )
				AutoGrLog( Replicate( " ", 128 ) )
				AutoGrLog( Replicate( "-", 128 ) )
				AutoGrLog( " " )
				AutoGrLog( " Dados Ambiente" )
				AutoGrLog( " --------------------" )
				AutoGrLog( " Empresa / Filial...: " + cEmpAnt + "/" + cFilAnt )
				AutoGrLog( " Nome Empresa.......: " + Capital( AllTrim( GetAdvFVal( "SM0", "M0_NOMECOM", cEmpAnt + cFilAnt, 1, "" ) ) ) )
				AutoGrLog( " Nome Filial........: " + Capital( AllTrim( GetAdvFVal( "SM0", "M0_FILIAL" , cEmpAnt + cFilAnt, 1, "" ) ) ) )
				AutoGrLog( " DataBase...........: " + DtoC( dDataBase ) )
				AutoGrLog( " Data / Hora Ýnicio.: " + DtoC( Date() )  + " / " + Time() )
				AutoGrLog( " Environment........: " + GetEnvServer()  )
				AutoGrLog( " StartPath..........: " + GetSrvProfString( "StartPath", "" ) )
				AutoGrLog( " RootPath...........: " + GetSrvProfString( "RootPath" , "" ) )
				AutoGrLog( " Versão.............: " + GetVersao(.T.) )
				AutoGrLog( " Usuário TOTVS .....: " + __cUserId + " " +  cUserName )
				AutoGrLog( " Computer Name......: " + GetComputerName() )
				
				aInfo   := GetUserInfo()
				If ( nPos    := aScan( aInfo,{ |x,y| x[3] == ThreadId() } ) ) > 0
					AutoGrLog( " " )
					AutoGrLog( " Dados Thread" )
					AutoGrLog( " --------------------" )
					AutoGrLog( " Usuário da Rede....: " + aInfo[nPos][1] )
					AutoGrLog( " Estação............: " + aInfo[nPos][2] )
					AutoGrLog( " Programa Inicial...: " + aInfo[nPos][5] )
					AutoGrLog( " Environment........: " + aInfo[nPos][6] )
					AutoGrLog( " Conexão............: " + AllTrim( StrTran( StrTran( aInfo[nPos][7], Chr( 13 ), "" ), Chr( 10 ), "" ) ) )
				EndIf
				AutoGrLog( Replicate( "-", 128 ) )
				AutoGrLog( " " )
				
				If !lAuto
					AutoGrLog( Replicate( "-", 128 ) )
					AutoGrLog( "Empresa : " + SM0->M0_CODIGO + "/" + SM0->M0_NOME + CRLF )
				EndIf
				
				oProcess:SetRegua1( 8 )
				
				
				oProcess:IncRegua1( "Dicionário de arquivos" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
				FSAtuSX2()
				
				
				FSAtuSX3()
				
				
				oProcess:IncRegua1( "Dicionário de índices" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
				FSAtuSIX()

				oProcess:IncRegua1( "Consulta Padrão" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
				FSAtuSXB()
				

				
				oProcess:IncRegua1( "Dicionário de dados" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
				oProcess:IncRegua2( "Atualizando campos/índices" )
				
				// Alteração física dos arquivos
				__SetX31Mode( .F. )
				
				If FindFunction(cTCBuild)
					cTopBuild := &cTCBuild.()
				EndIf
				
				For nX := 1 To Len( aArqUpd )
					
					If cTopBuild >= "20090811" .AND. TcInternal( 89 ) == "CLOB_SUPPORTED"
						If ( ( aArqUpd[nX] >= "NQ " .AND. aArqUpd[nX] <= "NZZ" ) .OR. ( aArqUpd[nX] >= "O0 " .AND. aArqUpd[nX] <= "NZZ" ) ) .AND.;
								!aArqUpd[nX] $ "NQD,NQF,NQP,NQT"
							TcInternal( 25, "CLOB" )
						EndIf
					EndIf
					
					If Select( aArqUpd[nX] ) > 0
						dbSelectArea( aArqUpd[nX] )
						dbCloseArea()
					EndIf
					
					X31UpdTable( aArqUpd[nX] )
					
					If __GetX31Error()
						Alert( __GetX31Trace() )
						MsgStop( "Ocorreu um erro desconhecido durante a atualização da tabela : " + aArqUpd[nX] + ". Verifique a integridade do dicionário e da tabela.", "ATENÇÃO" )
						AutoGrLog( "Ocorreu um erro desconhecido durante a atualização da estrutura da tabela : " + aArqUpd[nX] )
					EndIf
					
					If cTopBuild >= "20090811" .AND. TcInternal( 89 ) == "CLOB_SUPPORTED"
						TcInternal( 25, "OFF" )
					EndIf
					
				Next nX
				
				
				oProcess:IncRegua1( "Dicionário de parâmetros" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
				FSAtuSX6()
				
				AutoGrLog( Replicate( "-", 128 ) )
				AutoGrLog( " Data / Hora Final.: " + DtoC( Date() ) + " / " + Time() )
				AutoGrLog( Replicate( "-", 128 ) )
				
				RpcClearEnv()
				
			Next nI
			
			If !lAuto
				
				cTexto := LeLog()
				
				Define Font oFont Name "Mono AS" Size 5, 12
				
				Define MsDialog oDlg Title "Atualização concluida." From 3, 0 to 340, 417 Pixel
				
				@ 5, 5 Get oMemo Var cTexto Memo Size 200, 145 Of oDlg Pixel
				oMemo:bRClicked := { || AllwaysTrue() }
				oMemo:oFont     := oFont
				
				Define SButton From 153, 175 Type  1 Action oDlg:End() Enable Of oDlg Pixel // Apaga
				Define SButton From 153, 145 Type 13 Action ( cFile := cGetFile( cMask, "" ), If( cFile == "", .T., ;
					MemoWrite( cFile, cTexto ) ) ) Enable Of oDlg Pixel
				
				Activate MsDialog oDlg Center
				
			EndIf
			
		EndIf
		
	Else
		
		lRet := .F.
		
	EndIf
	
Return lRet


//--------------------------------------------------------------------
/*/{Protheus.doc} FSAtuSX2
Função de processamento da gravação do SX2 - Arquivos

@author TOTVS Protheus
@since  02/04/2015
@obs    Gerado por EXPORDIC - V.4.22.10.8 EFS / Upd. V.4.19.13 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSAtuSX2()
	Local aEstrut   := {}
	Local aSX2      := {}
	Local cAlias    := ""
	Local cCpoUpd   := "X2_ROTINA /X2_UNICO  /X2_DISPLAY/X2_SYSOBJ /X2_USROBJ /X2_POSLGT /"
	Local cEmpr     := ""
	Local cPath     := ""
	Local nI        := 0
	Local nJ        := 0
	
	AutoGrLog( "Ýnicio da Atualização" + " SX2" + CRLF )
	
	aEstrut := { "X2_CHAVE"  , "X2_PATH"   , "X2_ARQUIVO", "X2_NOME"   , "X2_NOMESPA", "X2_NOMEENG", "X2_MODO"   , ;
		"X2_TTS"    , "X2_ROTINA" , "X2_PYME"   , "X2_UNICO"  , "X2_DISPLAY", "X2_SYSOBJ" , "X2_USROBJ" , ;
		"X2_POSLGT" , "X2_MODOEMP", "X2_MODOUN" , "X2_MODULO" }
	
	
	dbSelectArea( "SX2" )
	SX2->( dbSetOrder( 1 ) )
	SX2->( dbGoTop() )
	cPath := SX2->X2_PATH
	cPath := IIf( Right( AllTrim( cPath ), 1 ) <> "\", PadR( AllTrim( cPath ) + "\", Len( cPath ) ), cPath )
	cEmpr := Substr( SX2->X2_ARQUIVO, 4 )
	
	aAdd( aSX2, {__AliCXML,cPath,__AliCXML+cEmpr,'Cabec Config EndPoints','Cabec Config EndPoints','Cabec Config EndPoints','E','','','','','','','','','E','E',0} )
	aAdd( aSX2, {__AliIXML,cPath,__AliIXML+cEmpr,'Campos do EndPoint','Campos do EndPoint','Campos do EndPoint','E','','','','','','','','','E','E',0} )
	//
	// Atualizando dicionário
	//
	oProcess:SetRegua2( Len( aSX2 ) )
	
	dbSelectArea( "SX2" )
	dbSetOrder( 1 )
	
	For nI := 1 To Len( aSX2 )
		
		oProcess:IncRegua2( "Atualizando Arquivos (SX2)..." )
		
		If !SX2->( dbSeek( aSX2[nI][1] ) )
			
			If !( aSX2[nI][1] $ cAlias )
				cAlias += aSX2[nI][1] + "/"
				AutoGrLog( "Foi incluída a tabela " + aSX2[nI][1] )
			EndIf
			
			RecLock( "SX2", .T. )
			For nJ := 1 To Len( aSX2[nI] )
				If FieldPos( aEstrut[nJ] ) > 0
					If AllTrim( aEstrut[nJ] ) == "X2_ARQUIVO"
						FieldPut( FieldPos( aEstrut[nJ] ), SubStr( aSX2[nI][nJ], 1, 3 ) + cEmpAnt +  "0" )
					Else
						FieldPut( FieldPos( aEstrut[nJ] ), aSX2[nI][nJ] )
					EndIf
				EndIf
			Next nJ
			MsUnLock()
			
		Else
			
			//If  !( StrTran( Upper( AllTrim( SX2->X2_UNICO ) ), " ", "" ) == StrTran( Upper( AllTrim( aSX2[nI][12]  ) ), " ", "" ) )
			//	RecLock( "SX2", .F. )
			//	SX2->X2_UNICO := aSX2[nI][12]
			//	MsUnlock()
				
			//	If MSFILE( RetSqlName( aSX2[nI][1] ),RetSqlName( aSX2[nI][1] ) + "_UNQ"  )
			//		TcInternal( 60, RetSqlName( aSX2[nI][1] ) + "|" + RetSqlName( aSX2[nI][1] ) + "_UNQ" )
			//	EndIf
				
			//	AutoGrLog( "Foi alterada a chave única da tabela " + aSX2[nI][1] )
			//EndIf
			
			//RecLock( "SX2", .F. )
			//For nJ := 1 To Len( aSX2[nI] )
			//	If FieldPos( aEstrut[nJ] ) > 0
			//		If PadR( aEstrut[nJ], 10 ) $ cCpoUpd
			//			FieldPut( FieldPos( aEstrut[nJ] ), aSX2[nI][nJ] )
			//		EndIf					
			//	EndIf
			//Next nJ
			//MsUnLock()
			
		EndIf
		
	Next nI
	
	AutoGrLog( CRLF + "Final da Atualização" + " SX2" + CRLF + Replicate( "-", 128 ) + CRLF )
	
Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} FSAtuSX3
Função de processamento da gravação do SX3 - Campos

@author TOTVS Protheus
@since  02/04/2015
@obs    Gerado por EXPORDIC - V.4.22.10.8 EFS / Upd. V.4.19.13 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSAtuSX3()
	Local aEstrut   := {}
	Local aSX3      := {}
	Local cAlias    := ""
	Local cAliasAtu := ""
	Local cMsg      := ""
	Local cSeqAtu   := ""
	Local cX3Campo  := ""
	Local cX3Dado   := ""
	Local lTodosNao := .F.
	Local lTodosSim := .F.
	Local nI        := 0
	Local nJ        := 0
	Local nOpcA     := 0
	Local nPosArq   := 0
	Local nPosCpo   := 0
	Local nPosOrd   := 0
	Local nPosSXG   := 0
	Local nPosTam   := 0
	Local nPosVld   := 0
	Local nSeqAtu   := 0
	Local nTamSeek  := Len( SX3->X3_CAMPO )
	
	AutoGrLog( "Ýnicio da Atualização" + " SX3" + CRLF )
	
	aEstrut := { { "X3_ARQUIVO", 0 }, { "X3_ORDEM"  , 0 }, { "X3_CAMPO"  , 0 }, { "X3_TIPO"   , 0 }, { "X3_TAMANHO", 0 }, { "X3_DECIMAL", 0 }, { "X3_TITULO" , 0 }, ;
		{ "X3_TITSPA" , 0 }, { "X3_TITENG" , 0 }, { "X3_DESCRIC", 0 }, { "X3_DESCSPA", 0 }, { "X3_DESCENG", 0 }, { "X3_PICTURE", 0 }, { "X3_VALID"  , 0 }, ;
		{ "X3_USADO"  , 0 }, { "X3_RELACAO", 0 }, { "X3_F3"     , 0 }, { "X3_NIVEL"  , 0 }, { "X3_RESERV" , 0 }, { "X3_CHECK"  , 0 }, { "X3_TRIGGER", 0 }, ;
		{ "X3_PROPRI" , 0 }, { "X3_BROWSE" , 0 }, { "X3_VISUAL" , 0 }, { "X3_CONTEXT", 0 }, { "X3_OBRIGAT", 0 }, { "X3_VLDUSER", 0 }, { "X3_CBOX"   , 0 }, ;
		{ "X3_CBOXSPA", 0 }, { "X3_CBOXENG", 0 }, { "X3_PICTVAR", 0 }, { "X3_WHEN"   , 0 }, { "X3_INIBRW" , 0 }, { "X3_GRPSXG" , 0 }, { "X3_FOLDER" , 0 }, ;
		{ "X3_CONDSQL", 0 }, { "X3_CHKSQL" , 0 }, { "X3_IDXSRV" , 0 }, { "X3_ORTOGRA", 0 }, { "X3_TELA"   , 0 }, { "X3_POSLGT" , 0 }, { "X3_IDXFLD" , 0 }, ;
		{ "X3_AGRUP"  , 0 }, { "X3_PYME"   , 0 } }
	
	aEval( aEstrut, { |x| x[2] := SX3->( FieldPos( x[1] ) ) } )
		
	aAdd( aSX3, {__AliCXML,'01',__PrefCXML+'_FILIAL','C',4 ,0,'Filial','Sucursal','Branch','Filial do Sistema','Sucursal','Branch of the System','','',Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128),'','',1,Chr(254) + Chr(192),'','','U','N','','','','','','','','','','','033','','','','','','','','','',''} )
	aAdd( aSX3, {__AliCXML,'02',__PrefCXML+'_CODIGO','C',6 ,0,'Codigo','Codigo','Codigo','','','','',''         ,Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),'','',0,Chr(254) + Chr(192),'','','U','S','A','R','€','','','','','','','','','','','','','N','','','N','',''} )
	aAdd( aSX3, {__AliCXML,'03',__PrefCXML+'_DESC'  ,'C',40,0,'Descricao','Descricao','Descricao','','','','','',Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),'','',0,Chr(254) + Chr(192),'','','U','S','A','R','€','','','','','','','','','','','','','N','','','N','',''} )
	aAdd( aSX3, {__AliCXML,'04',__PrefCXML+'_PATH'  ,'C',60,0,'Path Endpoin','Path Endpoin','Path Endpoin','','','','','',Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),'','',0,Chr(254) + Chr(192),'','','U','S','A','R','€','','','','','','','','','','','','','N','','','N','',''} )
	aAdd( aSX3, {__AliCXML,'05',__PrefCXML+'_TIPO'  ,'C',1 ,0,'Tipo','Tipo','Tipo','','','','','',Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),'','',0,Chr(254) + Chr(192),'','','U','S','A','R','€','','1=Manual;2=5 em 5 min;3=Di�rio;4=1 em 1 hora','','','','','','','','','','','N','','','N','',''} )
	aAdd( aSX3, {__AliCXML,'06',__PrefCXML+'_FLAG'  ,'C',1 ,0,'Flag','Flag','Flag','','','','','',Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),'','',0,Chr(254) + Chr(192),'','','U','S','A','R','','','','','','','','','','','','','','N','','','N','',''} )
	aAdd( aSX3, {__AliCXML,'07',__PrefCXML+'_METODO','C',1 ,0,'Metodo','Metodo','Metodo','','','','','',Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),'','',0,Chr(254) + Chr(192),'','','U','S','A','R','','','1=POST;2=PUT;3=GET','','','','','','','','','','','N','','','N','',''} )
	aAdd( aSX3, {__AliCXML,'08',__PrefCXML+'_FUNCAO','C',40,0,'Funcao','Funcao','Funcao','','','','','',Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),'','',0,Chr(254) + Chr(192),'','','U','S','A','R','','','','','','','','','','','','','','N','','','N','',''} )	
	aAdd( aSX3, {__AliCXML,'09',__PrefCXML+'_DELETE','C',1 ,0,'Deleta Dados','Deleta Dados','Deleta Dados','','','','','',Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),'','',0,Chr(254) + Chr(192),'','','U','S','A','R','','','1=Sim;2=Nao','','','','','','','','','','','N','','','N','',''} )	
	
	aAdd( aSX3, {__AliIXML,'01',__PrefIXML+'_FILIAL','C',4 ,0,'Filial','Sucursal','Branch','Filial do Sistema','Sucursal','Branch of the System','','',Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128),'','',1,Chr(254) + Chr(192),'','','U','N','','','','','','','','','','','033','','','','','','','','','',''} )
	aAdd( aSX3, {__AliIXML,'02',__PrefIXML+'_CODIGO','C',6 ,0,'Codigo','Codigo','Codigo','','','','','',Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),'','',0,Chr(254) + Chr(192),'','','U','N','A','R','','','','','','','','','','','','','','N','','','N','',''} )
	aAdd( aSX3, {__AliIXML,'03',__PrefIXML+'_ITEM'  ,'C',3 ,0,'Item','Item','Item','','','','','',Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),'IIF(LEN(ACOLS)<=1,"001",SOMA1(ACOLS[LEN(ACOLS)-1,1]))','',0,Chr(254) + Chr(192),'','','U','N','A','R','','','','','','','','','','','','','','N','','','N','',''} )
	aAdd( aSX3, {__AliIXML,'04',__PrefIXML+'_CAMPO1','C',25,0,'Endpoint','Endpoint','Endpoint','','','','','',Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),'','',0,Chr(254) + Chr(192),'','','U','N','A','R','€','','','','','','','','','','','','','N','','','N','',''} )
	aAdd( aSX3, {__AliIXML,'05',__PrefIXML+'_CAMPO2','C',100,0,'Protheus','Protheus','Protheus','','','','@!','',Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),'','',0,Chr(254) + Chr(192),'','','U','N','A','R','€','','','','','','','','','','','','','N','','','N','',''} )
	aAdd( aSX3, {__AliIXML,'06',__PrefIXML+'_TIPO1' ,'C',1 ,0,'Tipo EndP','Tipo EndP','Tipo EndP','','','','','',Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),'','',0,Chr(254) + Chr(192),'','','U','N','A','R','€','','1=Caracter;2=Numerico;3=Data','','','','','','','','','','','N','','','N','',''} )
	aAdd( aSX3, {__AliIXML,'07',__PrefIXML+'_TIPO2' ,'C',1 ,0,'Tip Protheus','Tip Protheus','Tip Protheus','','','','','',Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),'','',0,Chr(254) + Chr(192),'','','U','N','A','R','€','','1=Dicinario;2=Constante;3=Funcao','','','','','','','','','','','N','','','N','',''} )

	aAdd( aSX3, {"SC5",'01','C5_XXPEDMA'            ,'C',10,0,'Ped Maxima','Ped Maxima','Ped Maxima','','','','','',Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),'','',0,Chr(254) + Chr(192),'','','U','S','A','R','','','','','','','','','','','','','','N','','','N','',''} )
	aAdd( aSX3, {"SB1",'01','B1_XXMAXIM'            ,'C',10,0,'Flag Maxima','Flag Maxima','Flag Maxima','','','','','',Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),'','',0,Chr(254) + Chr(192),'','','U','S','A','R','','','','','','','','','','','','','','N','','','N','',''} )
	aAdd( aSX3, {"SA1",'01','A1_XXMAXIM'            ,'C',10,0,'Flag Maxima','Flag Maxima','Flag Maxima','','','','','',Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),'','',0,Chr(254) + Chr(192),'','','U','S','A','R','','','','','','','','','','','','','','N','','','N','',''} )
	aAdd( aSX3, {"SA2",'01','A2_XXMAXIM'            ,'C',10,0,'Flag Maxima','Flag Maxima','Flag Maxima','','','','','',Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),'','',0,Chr(254) + Chr(192),'','','U','S','A','R','','','','','','','','','','','','','','N','','','N','',''} )		
	
	//
	// Atualizando dicionário
	//
	nPosArq := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_ARQUIVO" } )
	nPosOrd := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_ORDEM"   } )
	nPosCpo := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_CAMPO"   } )
	nPosTam := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_TAMANHO" } )
	nPosSXG := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_GRPSXG"  } )
	nPosVld := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_VALID"   } )
	
	aSort( aSX3,,, { |x,y| x[nPosArq]+x[nPosOrd]+x[nPosCpo] < y[nPosArq]+y[nPosOrd]+y[nPosCpo] } )
	
	oProcess:SetRegua2( Len( aSX3 ) )
	
	dbSelectArea( "SX3" )
	dbSetOrder( 2 )
	cAliasAtu := ""
	
	For nI := 1 To Len( aSX3 )
		
		//
		// Verifica se o campo faz parte de um grupo e ajusta tamanho
		//
		If !Empty( aSX3[nI][nPosSXG] )
			SXG->( dbSetOrder( 1 ) )
			If SXG->( MSSeek( aSX3[nI][nPosSXG] ) )
				If aSX3[nI][nPosTam] <> SXG->XG_SIZE
					aSX3[nI][nPosTam] := SXG->XG_SIZE
					AutoGrLog( "O tamanho do campo " + aSX3[nI][nPosCpo] + " NÃO atualizado e foi mantido em [" + ;
						AllTrim( Str( SXG->XG_SIZE ) ) + "]" + CRLF + ;
						" por pertencer ao grupo de campos [" + SXG->XG_GRUPO + "]" + CRLF )
				EndIf
			EndIf
		EndIf
		
		SX3->( dbSetOrder( 2 ) )
		
		If !( aSX3[nI][nPosArq] $ cAlias )
			cAlias += aSX3[nI][nPosArq] + "/"
			aAdd( aArqUpd, aSX3[nI][nPosArq] )
		EndIf
		
		If !SX3->( dbSeek( PadR( aSX3[nI][nPosCpo], nTamSeek ) ) )
			
			//
			// Busca ultima ocorrencia do alias
			//
			If ( aSX3[nI][nPosArq] <> cAliasAtu )
				cSeqAtu   := "00"
				cAliasAtu := aSX3[nI][nPosArq]
				
				dbSetOrder( 1 )
				SX3->( dbSeek( cAliasAtu + "ZZ", .T. ) )
				dbSkip( -1 )
				
				If ( SX3->X3_ARQUIVO == cAliasAtu )
					cSeqAtu := SX3->X3_ORDEM
				EndIf
				
				nSeqAtu := Val( RetAsc( cSeqAtu, 3, .F. ) )
			EndIf
			
			nSeqAtu++
			cSeqAtu := RetAsc( Str( nSeqAtu ), 2, .T. )
			
			RecLock( "SX3", .T. )
			For nJ := 1 To Len( aSX3[nI] )
				If     nJ == nPosOrd  // Ordem
					SX3->( FieldPut( FieldPos( aEstrut[nJ][1] ), cSeqAtu ) )
					
				ElseIf aEstrut[nJ][2] > 0
					SX3->( FieldPut( FieldPos( aEstrut[nJ][1] ), aSX3[nI][nJ] ) )
					
				EndIf
			Next nJ
			
			dbCommit()
			MsUnLock()
			
			AutoGrLog( "Criado campo " + aSX3[nI][nPosCpo] )
			
		EndIf
		
		oProcess:IncRegua2( "Atualizando Campos de Tabelas (SX3)..." )
		
	Next nI
	
	AutoGrLog( CRLF + "Final da Atualização" + " SX3" + CRLF + Replicate( "-", 128 ) + CRLF )
	
Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} FSAtuSIX
Função de processamento da gravação do SIX - Indices

@author TOTVS Protheus
@since  02/04/2015
@obs    Gerado por EXPORDIC - V.4.22.10.8 EFS / Upd. V.4.19.13 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSAtuSIX()
	Local aEstrut   := {}
	Local aSIX      := {}
	Local lAlt      := .F.
	Local lDelInd   := .F.
	Local nI        := 0
	Local nJ        := 0
	
	AutoGrLog( "Ýnicio da Atualização" + " SIX" + CRLF )
	
	aEstrut := { "INDICE" , "ORDEM" , "CHAVE", "DESCRICAO", "DESCSPA"  , ;
		"DESCENG", "PROPRI", "F3"   , "NICKNAME" , "SHOWPESQ" }
	
	aAdd( aSIX, {__AliCXML,'1',__PrefCXML+'_FILIAL+'+__PrefCXML+'_CODIGO','Codigo','Codigo','Codigo','U','','','S'} )
	aAdd( aSIX, {__AliIXML,'1',__PrefIXML+'_FILIAL+'+__PrefIXML+'_CODIGO+'+__PrefIXML+'_ITEM','Codigo+Item','Codigo+Item','Codigo+Item','U','','','S'} )

	// Atualizando dicionário
	//
	oProcess:SetRegua2( Len( aSIX ) )
	
	dbSelectArea( "SIX" )
	SIX->( dbSetOrder( 1 ) )
	
	For nI := 1 To Len( aSIX )
		
		lAlt    := .F.
		lDelInd := .F.
		
		If !SIX->( dbSeek( aSIX[nI][1] + aSIX[nI][2] ) )
			AutoGrLog( "Ýndice criado " + aSIX[nI][1] + "/" + aSIX[nI][2] + " - " + aSIX[nI][3] )
		Else
			lAlt := .T.
			aAdd( aArqUpd, aSIX[nI][1] )
			If !StrTran( Upper( AllTrim( CHAVE )       ), " ", "" ) == ;
					StrTran( Upper( AllTrim( aSIX[nI][3] ) ), " ", "" )
				AutoGrLog( "Chave do índice alterado " + aSIX[nI][1] + "/" + aSIX[nI][2] + " - " + aSIX[nI][3] )
				lDelInd := .T. // Se for alteração precisa apagar o indice do banco
			EndIf
		EndIf
		
		RecLock( "SIX", !lAlt )
		For nJ := 1 To Len( aSIX[nI] )
			If FieldPos( aEstrut[nJ] ) > 0
				FieldPut( FieldPos( aEstrut[nJ] ), aSIX[nI][nJ] )
			EndIf
		Next nJ
		MsUnLock()
		
		dbCommit()
		
		If lDelInd
			TcInternal( 60, RetSqlName( aSIX[nI][1] ) + "|" + RetSqlName( aSIX[nI][1] ) + aSIX[nI][2] )
		EndIf
		
		oProcess:IncRegua2( "Atualizando índices..." )
		
	Next nI
	
	AutoGrLog( CRLF + "Final da Atualização" + " SIX" + CRLF + Replicate( "-", 128 ) + CRLF )
	
Return NIL

//--------------------------------------------------------------------
/*/{Protheus.doc} FSAtuSXB
Função de processamento da gravação do SXB - Consulta Padrao

@author TOTVS Protheus
@since  02/04/2015
@obs    Gerado por EXPORDIC - V.4.22.10.8 EFS / Upd. V.4.19.13 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSAtuSXB()
	Local aEstrut   := {}
	Local aSXB      := {}
	Local lAlt      := .F.
	Local lDelInd   := .F.
	Local nI        := 0
	Local nJ        := 0
	Local AliaSxb   := 'INFPRD'
	AutoGrLog( "Ýnicio da Atualização" + " SXB" + CRLF )
	
	aEstrut := {AliaSxb, "XB_ALIAS" , "XB_TIPO" , "XB_SEQ", "XB_COLUNA", "XB_DESCRI"  , ;
		"XB_DESCSPA", "XB_DESCENG", "XB_CONTEM"   , "XB_WCONTEM" }
	
	//aAdd( aSXB, {__AliCXML,'1',__PrefCXML+'_FILIAL+'+__PrefCXML+'_CHVNFE','Chave Eletro','Chave Eletro','Chave Eletro','U','','','S'} )

//	aAdd( aSXB, {AliaSxb,'INFPRD','1','01','RE','CONSULTA PRODUTOS','CONSULTA PRODUTOS','CONSULTA PRODUTOS','SB1',''} )
//	aAdd( aSXB, {AliaSxb,'INFPRD','2','01','01','                 ','                 ','                 ','U_INFGETPR(&__READVAR)','' })
//	aAdd( aSXB, {AliaSxb,'INFPRD','5','01','  ','                 ','                 ','                 ','SB1->B1_COD','' })

	//aAdd( aSXB, {__AliIXML,'1',__PrefIXML+'_FILIAL+'+__PrefIXML+'_CHVNFE+'+__PrefIXML+'_ITEM','Chave NF+Item','Chave NF+Item','Chave NF+Item','U','','','S'} )
	//aAdd( aSXB, {__AliIXML,'2',__PrefIXML+'_FILIAL+'+__PrefIXML+'_CHVNFE+'+__PrefIXML+'_CHVCTE','Chave NF+Chv CTE','Chave NF+Chv CTE','Chave NF+Chv CTE','U','','','S'} )
	//
	// Atualizando dicionário
	//
	oProcess:SetRegua2( Len( aSXB ) )
	
	dbSelectArea( "SXB" )
	SXB->( dbSetOrder( 1 ) )
	
	For nI := 1 To Len( aSXB )
		
		lAlt    := .F.
		lDelInd := .F.
		
		If !SXB->( dbSeek( aSXB[nI][1] + aSXB[nI][2]  + aSXB[nI][3] + aSXB[nI][4]) )
			AutoGrLog( "Consulta criada " + aSXB[nI][1] + "/" + aSXB[nI][2] + " - " + aSXB[nI][3] + " - " + aSXB[nI][4] )
		Else
			lAlt := .T.
			aAdd( aArqUpd, aSXB[nI][1] )
			If !StrTran( Upper( AllTrim( CHAVE )       ), " ", "" ) == ;
					StrTran( Upper( AllTrim( aSXB[nI][3] ) ), " ", "" )
				AutoGrLog( "Consulta alterada " + aSXB[nI][1] + "/" + aSXB[nI][2] + " - " + aSXB[nI][3] + " - " + aSXB[nI][4] )
				lDelInd := .T. // Se for alteração precisa apagar o indice do banco
			EndIf
		EndIf
		
		RecLock( "SXB", !lAlt )
		For nJ := 1 To Len( aSXB[nI] )
			If FieldPos( aEstrut[nJ] ) > 0
				FieldPut( FieldPos( aEstrut[nJ] ), aSXB[nI][nJ] )
			EndIf
		Next nJ
		MsUnLock()
		
		dbCommit()
		
		If lDelInd
			TcInternal( 60, RetSqlName( aSXB[nI][1] ) + "|" + RetSqlName( aSXB[nI][1] ) + aSXB[nI][2] )
		EndIf
		
		oProcess:IncRegua2( "Atualizando consulta padrao..." )
		
	Next nI
	
	AutoGrLog( CRLF + "Final da Atualização" + " SXB" + CRLF + Replicate( "-", 128 ) + CRLF )
	
Return NIL





//--------------------------------------------------------------------
/*/{Protheus.doc} FSAtuSX6
Função de processamento da gravação do SX6 - Parâmetros

@author TOTVS Protheus
@since  02/04/2015
@obs    Gerado por EXPORDIC - V.4.22.10.8 EFS / Upd. V.4.19.13 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSAtuSX6()
	Local aEstrut   := {}
	Local aSX6      := aClone(_aPars)
	Local cAlias    := ""
	Local cMsg      := ""
	Local lContinua := .T.
	Local lReclock  := .T.
	Local lTodosNao := .F.
	Local lTodosSim := .F.
	Local nI        := 0
	Local nJ        := 0
	Local nOpcA     := 0
	Local nTamFil   := Len( SX6->X6_FIL )
	Local nTamVar   := Len( SX6->X6_VAR )
	
	AutoGrLog( "Ýnicio da Atualização" + " SX6" + CRLF )
	
	aEstrut := { "X6_FIL"    , "X6_VAR"    , "X6_TIPO"   , "X6_DESCRIC", "X6_DSCSPA" , "X6_DSCENG" , "X6_DESC1"  , ;
		"X6_DSCSPA1", "X6_DSCENG1", "X6_DESC2"  , "X6_DSCSPA2", "X6_DSCENG2", "X6_CONTEUD", "X6_CONTSPA", ;
		"X6_CONTENG", "X6_PROPRI" , "X6_VALID"  , "X6_INIT"   , "X6_DEFPOR" , "X6_DEFSPA" , "X6_DEFENG" , ;
		"X6_PYME"   }
	
	// Atualizando dicionário
	//
	oProcess:SetRegua2( Len( aSX6 ) )
	
	dbSelectArea( "SX6" )
	dbSetOrder( 1 )
	
	For nI := 1 To Len( aSX6 )
		lContinua := .F.
		lReclock  := .F.
		
		If !SX6->( dbSeek( PadR( aSX6[nI][1], nTamFil ) + PadR( aSX6[nI][2], nTamVar ) ) )
			lContinua := .T.
			lReclock  := .T.
			AutoGrLog( "Foi incluído o parâmetro " + aSX6[nI][1] + aSX6[nI][2] + " Conteúdo [" + AllTrim( aSX6[nI][13] ) + "]" )
		EndIf
		
		If lContinua
			If !( aSX6[nI][1] $ cAlias )
				cAlias += aSX6[nI][1] + "/"
			EndIf
			
			RecLock( "SX6", lReclock )
			For nJ := 1 To Len( aSX6[nI] )
				If FieldPos( aEstrut[nJ] ) > 0
					FieldPut( FieldPos( aEstrut[nJ] ), aSX6[nI][nJ] )
				EndIf
			Next nJ
			dbCommit()
			MsUnLock()
		EndIf
		
		oProcess:IncRegua2( "Atualizando Arquivos (SX6)..." )
		
	Next nI
	
	AutoGrLog( CRLF + "Final da Atualização" + " SX6" + CRLF + Replicate( "-", 128 ) + CRLF )
	
Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} EscEmpresa
Função genérica para escolha de Empresa, montada pelo SM0

@return aRet Vetor contendo as seleções feitas.
Se não for marcada nenhuma o vetor volta vazio

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function EscEmxxx()
	
	//---------------------------------------------
	// Parâmetro  nTipo
	// 1 - Monta com Todas Empresas/Filiais
	// 2 - Monta só com Empresas
	// 3 - Monta só com Filiais de uma Empresa
	//
	// Parâmetro  aMarcadas
	// Vetor com Empresas/Filiais pré marcadas
	//
	// Parâmetro  cEmpSel
	// Empresa que será usada para montar seleção
	//---------------------------------------------
	Local   aRet      := {}
	Local   aSalvAmb  := GetArea()
	Local   aSalvSM0  := {}
	Local   aVetor    := {}
	Local   cMascEmp  := "??"
	Local   cVar      := ""
	Local   lChk      := .F.
	Local   lOk       := .F.
	Local   lTeveMarc := .F.
	Local   oNo       := LoadBitmap( GetResources(), "LBNO" )
	Local   oOk       := LoadBitmap( GetResources(), "LBOK" )
	Local   oDlg, oChkMar, oLbx, oMascEmp, oSay
	Local   oButDMar, oButInv, oButMarc, oButOk, oButCanc
	
	Local   aMarcadas := {}
	
	
	If !MyOpenSm0(.F.)
		Return aRet
	EndIf
	
	dbSelectArea( "SM0" )
	aSalvSM0 := SM0->( GetArea() )
	dbSetOrder( 1 )
	dbGoTop()
	
	_aPars := U_bGetPar2()
	
	If Len(_aPars) > 0
		While !SM0->( EOF() )
			
			If aScan( aVetor, {|x| x[2] == SM0->M0_CODIGO} ) == 0
				aAdd(  aVetor, { aScan( aMarcadas, {|x| x[1] == SM0->M0_CODIGO .and. x[2] == SM0->M0_CODFIL} ) > 0, SM0->M0_CODIGO, SM0->M0_CODFIL, SM0->M0_NOME, SM0->M0_FILIAL } )
			EndIf
			
			dbSkip()
		End
		
		RestArea( aSalvSM0 )
		
		Define MSDialog  oDlg Title "" From 0, 0 To 280, 395 Pixel
		
		oDlg:cToolTip := "Tela para Múltiplas Seleções de Empresas/Filiais"
		
		oDlg:cTitle   := "Selecione a(s) Empresa(s) para Atualização"
		
		@ 10, 10 Listbox  oLbx Var  cVar Fields Header " ", " ", "Empresa" Size 178, 095 Of oDlg Pixel
		oLbx:SetArray(  aVetor )
		oLbx:bLine := {|| {IIf( aVetor[oLbx:nAt, 1], oOk, oNo ), ;
			aVetor[oLbx:nAt, 2], ;
			aVetor[oLbx:nAt, 4]}}
		oLbx:BlDblClick := { || aVetor[oLbx:nAt, 1] := !aVetor[oLbx:nAt, 1], VerTodos( aVetor, @lChk, oChkMar ), oChkMar:Refresh(), oLbx:Refresh()}
		oLbx:cToolTip   :=  oDlg:cTitle
		oLbx:lHScroll   := .F. // NoScroll
		
		@ 112, 10 CheckBox oChkMar Var  lChk Prompt "Todos" Message "Marca / Desmarca"+ CRLF + "Todos" Size 40, 007 Pixel Of oDlg;
			on Click MarcaTodos( lChk, @aVetor, oLbx )
		
		// Marca/Desmarca por mascara
		@ 113, 51 Say   oSay Prompt "Empresa" Size  40, 08 Of oDlg Pixel
		@ 112, 80 MSGet oMascEmp Var  cMascEmp Size  05, 05 Pixel Picture "@!"  Valid (  cMascEmp := StrTran( cMascEmp, " ", "?" ), oMascEmp:Refresh(), .T. ) ;
			Message "Máscara Empresa ( ?? )"  Of oDlg
		oSay:cToolTip := oMascEmp:cToolTip
		
		@ 128, 10 Button oButInv    Prompt "&Inverter"  Size 32, 12 Pixel Action ( InvSelecao( @aVetor, oLbx, @lChk, oChkMar ), VerTodos( aVetor, @lChk, oChkMar ) ) ;
			Message "Inverter Seleção" Of oDlg
		oButInv:SetCss( CSSBOTAO )
		@ 128, 50 Button oButMarc   Prompt "&Marcar"    Size 32, 12 Pixel Action ( MarcaMas( oLbx, aVetor, cMascEmp, .T. ), VerTodos( aVetor, @lChk, oChkMar ) ) ;
			Message "Marcar usando" + CRLF + "máscara ( ?? )"    Of oDlg
		oButMarc:SetCss( CSSBOTAO )
		@ 128, 80 Button oButDMar   Prompt "&Desmarcar" Size 32, 12 Pixel Action ( MarcaMas( oLbx, aVetor, cMascEmp, .F. ), VerTodos( aVetor, @lChk, oChkMar ) ) ;
			Message "Desmarcar usando" + CRLF + "máscara ( ?? )" Of oDlg
		oButDMar:SetCss( CSSBOTAO )
		@ 112, 157  Button oButOk   Prompt "Processar"  Size 32, 12 Pixel Action (  RetSelecao( @aRet, aVetor ), oDlg:End()  ) ;
			Message "Confirma a seleção e efetua" + CRLF + "o processamento" Of oDlg
		oButOk:SetCss( CSSBOTAO )
		@ 128, 157  Button oButCanc Prompt "Cancelar"   Size 32, 12 Pixel Action ( IIf( lTeveMarc, aRet :=  aMarcadas, .T. ), oDlg:End() ) ;
			Message "Cancela o processamento" + CRLF + "e abandona a aplicação" Of oDlg
		oButCanc:SetCss( CSSBOTAO )
		
		Activate MSDialog  oDlg Center
		
		RestArea( aSalvAmb )
		dbSelectArea( "SM0" )
		dbCloseArea()
	EndIf
Return  aRet


//--------------------------------------------------------------------
/*/{Protheus.doc} MarcaTodos
Função auxiliar para marcar/desmarcar todos os ítens do ListBox ativo

@param lMarca  Contéudo para marca .T./.F.
@param aVetor  Vetor do ListBox
@param oLbx    Objeto do ListBox

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function MarcaTodos( lMarca, aVetor, oLbx )
	Local  nI := 0
	
	For nI := 1 To Len( aVetor )
		aVetor[nI][1] := lMarca
	Next nI
	
	oLbx:Refresh()
	
Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} InvSelecao
Função auxiliar para inverter a seleção do ListBox ativo

@param aVetor  Vetor do ListBox
@param oLbx    Objeto do ListBox

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function InvSelecao( aVetor, oLbx )
	Local  nI := 0
	
	For nI := 1 To Len( aVetor )
		aVetor[nI][1] := !aVetor[nI][1]
	Next nI
	
	oLbx:Refresh()
	
Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} RetSelecao
Função auxiliar que monta o retorno com as seleções

@param aRet    Array que terá o retorno das seleções (é alterado internamente)
@param aVetor  Vetor do ListBox

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function RetSelecao( aRet, aVetor )
	Local  nI    := 0
	
	aRet := {}
	For nI := 1 To Len( aVetor )
		If aVetor[nI][1]
			aAdd( aRet, { aVetor[nI][2] , aVetor[nI][3], aVetor[nI][2] +  aVetor[nI][3] } )
		EndIf
	Next nI
	
Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} MarcaMas
Função para marcar/desmarcar usando máscaras

@param oLbx     Objeto do ListBox
@param aVetor   Vetor do ListBox
@param cMascEmp Campo com a máscara (???)
@param lMarDes  Marca a ser atribuída .T./.F.

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function MarcaMas( oLbx, aVetor, cMascEmp, lMarDes )
	Local cPos1 := SubStr( cMascEmp, 1, 1 )
	Local cPos2 := SubStr( cMascEmp, 2, 1 )
	Local nPos  := oLbx:nAt
	Local nZ    := 0
	
	For nZ := 1 To Len( aVetor )
		If cPos1 == "?" .or. SubStr( aVetor[nZ][2], 1, 1 ) == cPos1
			If cPos2 == "?" .or. SubStr( aVetor[nZ][2], 2, 1 ) == cPos2
				aVetor[nZ][1] := lMarDes
			EndIf
		EndIf
	Next
	
	oLbx:nAt := nPos
	oLbx:Refresh()
	
Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} VerTodos
Função auxiliar para verificar se estão todos marcados ou não

@param aVetor   Vetor do ListBox
@param lChk     Marca do CheckBox do marca todos (referncia)
@param oChkMar  Objeto de CheckBox do marca todos

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function VerTodos( aVetor, lChk, oChkMar )
	Local lTTrue := .T.
	Local nI     := 0
	
	For nI := 1 To Len( aVetor )
		lTTrue := IIf( !aVetor[nI][1], .F., lTTrue )
	Next nI
	
	lChk := IIf( lTTrue, .T., .F. )
	oChkMar:Refresh()
	
Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} MyOpenSM0
Função de processamento abertura do SM0 modo exclusivo

@author TOTVS Protheus
@since  02/04/2015
@obs    Gerado por EXPORDIC - V.4.22.10.8 EFS / Upd. V.4.19.13 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function MyOpenSM0(lShared)
	
	Local lOpen := .F.
	Local nLoop 
	
	For nLoop := 1 To 20
		//dbUseArea( .T., , "SIGAMAT.EMP", "SM0", lShared, .F. )
		
		//If !Empty( Select( "SM0" ) )
		//	lOpen := .T.
		//	dbSetIndex( "SIGAMAT.IND" )
		//	Exit
		//EndIf
		
		Sleep( 500 )
		
	Next nLoop
	
	If !lOpen
		MsgStop( "Não foi possível a abertura da tabela " + ;
			IIf( lShared, "de empresas (SM0).", "de empresas (SM0) de forma exclusiva." ), "ATENÇÃO" )
	EndIf
	
Return lOpen


//--------------------------------------------------------------------
/*/{Protheus.doc} LeLog
Função de leitura do LOG gerado com limitacao de string

@author TOTVS Protheus
@since  02/04/2015
@obs    Gerado por EXPORDIC - V.4.22.10.8 EFS / Upd. V.4.19.13 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function LeLog()
	Local cRet  := ""
	Local cFile := NomeAutoLog()
	Local cAux  := ""
	
	FT_FUSE( cFile )
	FT_FGOTOP()
	
	While !FT_FEOF()
		
		cAux := FT_FREADLN()
		
		If Len( cRet ) + Len( cAux ) < 1048000
			cRet += cAux + CRLF
		Else
			cRet += CRLF
			cRet += Replicate( "=" , 128 ) + CRLF
			cRet += "Tamanho de exibição maxima do LOG alcançado." + CRLF
			cRet += "LOG Completo no arquivo " + cFile + CRLF
			cRet += Replicate( "=" , 128 ) + CRLF
			Exit
		EndIf
		
		FT_FSKIP()
	End
	
	FT_FUSE()
	
Return cRet


/////////////////////////////////////////////////////////////////////////////

User Function bGetPar2()
	Local oSButton1
	Local oSButton2
	Local _aRet := {}
	Local _nOpc := 0
	Private oParams
	Private aParams := {}
	Private oDlg
	
	DEFINE MSDIALOG oDlg TITLE "Parametrização Protheus x Máxima" FROM 000, 000  TO 500, 1200 COLORS 0, 16777215 PIXEL
	fParams()
	DEFINE SBUTTON oSButton1 FROM 232, 100 TYPE 01 OF oDlg ENABLE ACTION (_nOpc := 1,oDlg:End())
	DEFINE SBUTTON oSButton2 FROM 232, 165 TYPE 02 OF oDlg ENABLE ACTION oDlg:End()
	oParams:Align := CONTROL_ALIGN_TOP
	ACTIVATE MSDIALOG oDlg CENTERED VALID bValForm()
	If _nOpc == 1
		For _I := 1 To Len(aParams)
			If Len(AllTrim(aParams[_I,4])) > 0
				aAdd(_aRet,{'  ',aParams[_I,1]	,SubStr(aParams[_I,2],1,1),aParams[_I,3],'','','','','','','','',aParams[_I,4],aParams[_I,4],aParams[_I,4],'U','','','','','',''})
			EndIf
		Next _I
	EndIf
Return(_aRet)

Static Function fParams()
		
	//aAdd( aParams, {'XX_MAXIMO' ,'Numerico'	,'Quantidade maxima de registros para endpoint'  		,1500} )
	aAdd( aParams, {'XX_TAB1'   ,'Caracter'	,'Cabecalho de cadastro de EndPoint'					,Space(03)} )
	aAdd( aParams, {'XX_TAB2'	,'Caracter'	,'Itens do cadastro de EndPoints' 						,Space(03)} )
	aAdd( aParams, {'XX_MAXURL' ,'Caracter'	,'Link principal do endpoint'               	 		,Space(150)} )
	aAdd( aParams, {'XX_MAXPASS','Caracter'	,'Senha' 		   			 					 		,Space(150)} )
	aAdd( aParams, {'XX_MAXUSER','Caracter'	,'Login'					 							,Space(150)} )
	aAdd( aParams, {'XX_MAXGET' ,'Caracter'	,'Link para envio do GET'		 						,Space(150)} )
	aAdd( aParams, {'XX_CONDPAG','Caracter'	,'Condicao padrao quando o cliente nao tem condicao'	,Space(03)} )
	aAdd( aParams, {'XX_TABELA'	,'Caracter'	,'Tabela de preço padrão quando cliente não possiu' 	,Space(03)} )
	aAdd( aParams, {'XX_TES'	,'Caracter'	,'TES para importação do pedido de venda'				,Space(03)} )	 
	aAdd( aParams, {'XX_OPER'	,'Caracter'	,'Tipo de operação para importação do pedido de venda'	,Space(02)} )	
	aAdd( aParams, {'XX_TES2'	,'Caracter'	,'TES para importação da bonificação'    				,Space(03)} )	 
	aAdd( aParams, {'XX_OPER2'	,'Caracter'	,'Tipo de operação para importação da bonificação'   	,Space(02)} )	
	aAdd( aParams, {'XX_TES3'	,'Caracter'	,'TES para importação de outro tipo de pedido'			,Space(03)} )	 
	aAdd( aParams, {'XX_OPER3'	,'Caracter'	,'Tipo de operação outro tipo de pedido'				,Space(02)} )	
			
	@ 000, 000 LISTBOX oParams Fields HEADER "Parametro","Tipo","Descricao","Conteudo" SIZE 300, 227 OF oDlg PIXEL ColSizes 50,50
	oParams:SetArray(aParams)
	oParams:bLine := {|| {;
		aParams[oParams:nAt,1],;
		aParams[oParams:nAt,2],;
		aParams[oParams:nAt,3],;
		aParams[oParams:nAt,4];
		}}
	// DoubleClick event
	oParams:bLDblClick := {|| lEditCell(@aParams,oParams,,4,,/*lEnabled*/,/*bValid*/),oParams:DrawSelect()}
	
Return

Static Function bValForm()
	Local _I := 0
	Local _lRet := .T.
	For _I := 1 To Len(aParams)
		If Len(AllTrim(aParams[_I,4])) <= 0
			MsgAlert("Preenche o conteudo de todos os parametros")
			Return(.F.)
		EndIf
	Next _I
	_lRet := MsgYesNo("Confirma os parametros informados?")
Return(_lRet)

Static Function EscEmpresa()
	
	//---------------------------------------------
	// Parâmetro  nTipo
	// 1 - Monta com Todas Empresas/Filiais
	// 2 - Monta só com Empresas
	// 3 - Monta só com Filiais de uma Empresa
	//
	// Parâmetro  aMarcadas
	// Vetor com Empresas/Filiais pré marcadas
	//
	// Parâmetro  cEmpSel
	// Empresa que será usada para montar seleção
	//---------------------------------------------
	Local   aRet      := {}
	Local   aSalvAmb  := GetArea()
	Local   aSalvSM0  := {}
	Local   aVetor    := {}
	Local   cMascEmp  := "??"
	Local   cVar      := ""
	Local   lChk      := .F.
	Local   lOk       := .F.
	Local   lTeveMarc := .F.
	Local   oNo       := LoadBitmap( GetResources(), "LBNO" )
	Local   oOk       := LoadBitmap( GetResources(), "LBOK" )
	Local   oDlg, oChkMar, oLbx, oMascEmp, oSay
	Local   oButDMar, oButInv, oButMarc, oButOk, oButCanc
	
	Local   aMarcadas := {}
	
	
	If !MyOpenSm0(.F.)
		Return aRet
	EndIf
	
	dbSelectArea( "SM0" )
	aSalvSM0 := SM0->( GetArea() )
	dbSetOrder( 1 )
	dbGoTop()
	
	_aPars := U_bGetPar2()
	
	If Len(_aPars) > 0
		While !SM0->( EOF() )
			
			If aScan( aVetor, {|x| x[2] == SM0->M0_CODIGO} ) == 0
				aAdd(  aVetor, { aScan( aMarcadas, {|x| x[1] == SM0->M0_CODIGO .and. x[2] == SM0->M0_CODFIL} ) > 0, SM0->M0_CODIGO, SM0->M0_CODFIL, SM0->M0_NOME, SM0->M0_FILIAL } )
			EndIf
			
			dbSkip()
		End
		
		RestArea( aSalvSM0 )
		
		Define MSDialog  oDlg Title "" From 0, 0 To 280, 395 Pixel
		
		oDlg:cToolTip := "Tela para Múltiplas Seleções de Empresas/Filiais"
		
		oDlg:cTitle   := "Selecione a(s) Empresa(s) para Atualização"
		
		@ 10, 10 Listbox  oLbx Var  cVar Fields Header " ", " ", "Empresa" Size 178, 095 Of oDlg Pixel
		oLbx:SetArray(  aVetor )
		oLbx:bLine := {|| {IIf( aVetor[oLbx:nAt, 1], oOk, oNo ), ;
			aVetor[oLbx:nAt, 2], ;
			aVetor[oLbx:nAt, 4]}}
		oLbx:BlDblClick := { || aVetor[oLbx:nAt, 1] := !aVetor[oLbx:nAt, 1], VerTodos( aVetor, @lChk, oChkMar ), oChkMar:Refresh(), oLbx:Refresh()}
		oLbx:cToolTip   :=  oDlg:cTitle
		oLbx:lHScroll   := .F. // NoScroll
		
		@ 112, 10 CheckBox oChkMar Var  lChk Prompt "Todos" Message "Marca / Desmarca"+ CRLF + "Todos" Size 40, 007 Pixel Of oDlg;
			on Click MarcaTodos( lChk, @aVetor, oLbx )
		
		// Marca/Desmarca por mascara
		@ 113, 51 Say   oSay Prompt "Empresa" Size  40, 08 Of oDlg Pixel
		@ 112, 80 MSGet oMascEmp Var  cMascEmp Size  05, 05 Pixel Picture "@!"  Valid (  cMascEmp := StrTran( cMascEmp, " ", "?" ), oMascEmp:Refresh(), .T. ) ;
			Message "Máscara Empresa ( ?? )"  Of oDlg
		oSay:cToolTip := oMascEmp:cToolTip
		
		@ 128, 10 Button oButInv    Prompt "&Inverter"  Size 32, 12 Pixel Action ( InvSelecao( @aVetor, oLbx, @lChk, oChkMar ), VerTodos( aVetor, @lChk, oChkMar ) ) ;
			Message "Inverter Seleção" Of oDlg
		oButInv:SetCss( CSSBOTAO )
		@ 128, 50 Button oButMarc   Prompt "&Marcar"    Size 32, 12 Pixel Action ( MarcaMas( oLbx, aVetor, cMascEmp, .T. ), VerTodos( aVetor, @lChk, oChkMar ) ) ;
			Message "Marcar usando" + CRLF + "máscara ( ?? )"    Of oDlg
		oButMarc:SetCss( CSSBOTAO )
		@ 128, 80 Button oButDMar   Prompt "&Desmarcar" Size 32, 12 Pixel Action ( MarcaMas( oLbx, aVetor, cMascEmp, .F. ), VerTodos( aVetor, @lChk, oChkMar ) ) ;
			Message "Desmarcar usando" + CRLF + "máscara ( ?? )" Of oDlg
		oButDMar:SetCss( CSSBOTAO )
		@ 112, 157  Button oButOk   Prompt "Processar"  Size 32, 12 Pixel Action (  RetSelecao( @aRet, aVetor ), oDlg:End()  ) ;
			Message "Confirma a seleção e efetua" + CRLF + "o processamento" Of oDlg
		oButOk:SetCss( CSSBOTAO )
		@ 128, 157  Button oButCanc Prompt "Cancelar"   Size 32, 12 Pixel Action ( IIf( lTeveMarc, aRet :=  aMarcadas, .T. ), oDlg:End() ) ;
			Message "Cancela o processamento" + CRLF + "e abandona a aplicação" Of oDlg
		oButCanc:SetCss( CSSBOTAO )
		
		Activate MSDialog  oDlg Center
		
		RestArea( aSalvAmb )
		dbSelectArea( "SM0" )
		dbCloseArea()
	EndIf
Return  aRet
