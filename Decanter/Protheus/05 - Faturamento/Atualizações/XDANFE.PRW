#Include "PROTHEUS.CH"
#Include "TOPCONN.CH"
#Include 'RPTDEF.CH'
#Include 'FWPrintSetup.ch'
#include "tbiconn.ch"

/*/{Protheus.doc} XDANFE
    Impressão de Danfe para todas as empresas.
    @type  Function
    @author  Anderson Koziel - Vamilly
    @since 27/10/2023
    @version 1.0
/*/
User Function XDANFE()
    Local aArea     := FwGetArea()
    Local cAliasSM0 := GetNextAlias()
    Local i         := 0
    Local nQTY      := 0
    Local cSql      := ""
    Local cFilDe    := "" as char
    Local cFilAt    := "" as char
    Local cDocDe    := "" as char
    Local cDocAt    := "" as char
    Local cSerieDe  := "" as char
    Local cSerieAt  := "" as char
    Local cEmisDe   := "" as char
    Local cEmisAte  := "" as char
    Local cPerg    := PadR("XDANFE" , Len( SX1->X1_GRUPO ))
    
    Private cDiret  := "" as char
    Private xEmp    := FwCodEmp()
    Private xFil    := FwCodFil()

    // Pergunta
	While .T.  
		//Cria as perguntas
        U_xSx1(cPerg,"01","Filial De       ?" ,"","","MV_CH1","C", 4, 0,0,"G","","","","","MV_PAR01","","","","","","","","","","","","","","","","",{""}, {""}, {""})
        U_xSx1(cPerg,"02","Filial Até      ?" ,"","","MV_CH2","C", 4, 0,0,"G","","","","","MV_PAR02","","","","","","","","","","","","","","","","",{""}, {""}, {""})
        U_xSx1(cPerg,"03","Da Nota Fiscal  ?" ,"","","MV_CH3","C", 9, 0,0,"G","","","","","MV_PAR03","","","","","","","","","","","","","","","","",{""}, {""}, {""})
        U_xSx1(cPerg,"04","Até Nota Fiscal ?" ,"","","MV_CH4","C", 9, 0,0,"G","","","","","MV_PAR04","","","","","","","","","","","","","","","","",{""}, {""}, {""})
        U_xSx1(cPerg,"05","Da Serie        ?" ,"","","MV_CH5","C", 3, 0,0,"G","","","","","MV_PAR05","","","","","","","","","","","","","","","","",{""}, {""}, {""})
        U_xSx1(cPerg,"06","Ate a Serie?    ?" ,"","","MV_CH6","C", 3, 0,0,"G","","","","","MV_PAR06","","","","","","","","","","","","","","","","",{""}, {""}, {""})
        U_xSx1(cPerg,"07","Data de         ?" ,"","","MV_CH7","D", 8, 0,0,"G","","","","","MV_PAR07","","","","","","","","","","","","","","","","",{""}, {""}, {""})
        U_xSx1(cPerg,"08","Data Até        ?" ,"","","MV_CH8","D", 8, 0,0,"G","","","","","MV_PAR08","","","","","","","","","","","","","","","","",{""}, {""}, {""})
        U_xSX1(cPerg,"09","Diretório       ?" ,"","","MV_CH9","C",90, 0,0,"G","","BB3PLS","","","MV_PAR09","",""   ,""   ,"",""   ,""   ,""   ,"","","","","","","","","",{"Diretório do arquivo",""},{""},{""})      
        // Abre a tela de perguntas
        If !(Pergunte(cPerg,.T.)) 
            FwRestArea(aArea)
            Return
        EndIf
		
        // Parâmetros		
        cFilDe   := MV_PAR01
        cFilAt   := MV_PAR02
        cDocDe   := MV_PAR03
        cDocAt   := MV_PAR04
        cSerieDe := MV_PAR05
        cSerieAt := MV_PAR06
        cEmisDe  := MV_PAR07
        cEmisAte := MV_PAR08
        cPasta   := Alltrim(MV_PAR09)
        
        // Aqui são feitas as validações do Pergunte().
        // Sem filial
        If Empty(cFilAt)
			FWAlertWarning("A filial [Filial até] deve ser informado!","ATENÇÃO") 
			Pergunte(cPerg , .F.)
			Loop            
        EndIf        

		// Sem Emissão
		If Empty(cEmisDe) .Or. Empty(cEmisAte)
			FWAlertWarning("A data de [Emissão De/Até] não pode estar vazia!","ATENÇÃO") 
			Pergunte(cPerg , .F.)
			Loop                    
		EndIf		

		// Data de maior que data Ate
		If cEmisDe > cEmisAte
			FWAlertWarning("A data de [Emissão De] não pode ser maior que a data [Emissão Até]!","ATENÇÃO") 
			Pergunte(cPerg , .F.)
			Loop                    
		EndIf		

        // Sem nota
        If Empty(cDocAt)
			FWAlertWarning("A nota fiscal [Nota fiscal até] deve ser informada!","ATENÇÃO") 
			Pergunte(cPerg , .F.)
			Loop            
        EndIf  

        // Sem serie
        If Empty(cSerieAt)         
			FWAlertWarning("A serie [Serie até] deve ser informada!","ATENÇÃO") 
			Pergunte(cPerg , .F.)
			Loop                
        EndIf

        // Diretorio Vazio
        If Empty(cPasta)
            FWAlertWarning("Informe o caminho do diretorio, para salvar as notas.","ATENÇÃO") 
			Pergunte(cPerg , .F.)
			Loop  
        EndIf
        
		Exit		
	EndDo    
    // FAz a Query para trazer todas as empresas
    BeginSql Alias cAliasSM0
        SELECT 
                COUNT(*) OVER (PARTITION BY 1) QTY
            ,   M0_CODIGO
        FROM (
            SELECT
                DISTINCT M0_CODIGO
            FROM 
                SYS_COMPANY           
        ) TMP

    EndSql
    // Verifica se a Query retornou resultado.
    If (cAliasSM0)->(Eof())
        FWAlertError("Nenhuma empresa encontrada!","Atenção")
        Return
    EndIf
    // Recebe a quantidade de empresas.
    nQTY := (cAliasSM0)->QTY
    // Varre a Query adicionando Union All para trazer o resultado
    While (cAliasSM0)->(!Eof()) 
        i++
        If i > 1 .And. i < nQTY
            cSql += " UNION ALL " + CRLF 
        EndIf

        cSql += " SELECT                                                                                  " + CRLF
        cSql += "       LEFT(F2_FILIAL,2) EMPRESA                                                         " + CRLF
        cSql += "     , F2_FILIAL FILIAL                                                                  " + CRLF
        cSql += "     , F2_DOC      DOCUMENTO                                                             " + CRLF
        cSql += "     , F2_SERIE    SERIE                                                                 " + CRLF
        cSql += "     , F2_CLIENTE  CLIENTE                                                               " + CRLF
        cSql += "     , F2_LOJA     LOJA                                                                  " + CRLF
        cSql += "     , A1_NOME     NOME                                                                  " + CRLF
        cSql += "     , F2_EMISSAO  EMISSAO                                                               " + CRLF
        cSql += "     , SF2.R_E_C_N_O_ RECNO                                                              " + CRLF
        cSql += " FROM                                                                                    " + CRLF
        cSql += "       SF2" + (cAliasSM0)->M0_CODIGO + "0 SF2                                            " + CRLF
        cSql += " INNER JOIN SA1" + (cAliasSM0)->M0_CODIGO +"0 SA1                                        " + CRLF
        cSql += "     ON A1_COD =  F2_CLIENTE                                                             " + CRLF
        cSql += "     AND A1_LOJA =  F2_LOJA                                                              " + CRLF
        cSql += "     AND A1_COD <> '000001'                                                              " + CRLF
        cSql += "     AND SA1.D_E_L_E_T_= ''                                                              " + CRLF
        cSql += " WHERE                                                                                   " + CRLF
        cSql += "         F2_FILIAL BETWEEN  '" + cFilDe   + "'     AND '" + cFilAt    + "'               " + CRLF
        cSql += "     AND F2_DOC BETWEEN     '" + cDocDe   + "'     AND '" + cDocAt    + "'               " + CRLF
        cSql += "     AND F2_SERIE BETWEEN   '" + cSerieDe + "'     AND '" + cSerieAt  + "'               " + CRLF
        cSql += "     AND F2_EMISSAO BETWEEN '" + DtoS(cEmisDe)  + "'     AND '" + DtoS(cEmisAte)  + "'   " + CRLF
        cSql += "     AND F2_CHVNFE <> ''                                                                 " + CRLF
        cSql += "     AND F2_TIPO = 'N'                                                                   " + CRLF
        cSql += "     AND SF2.D_E_L_E_T_ = ''                                                             " + CRLF
        
        (cAliasSM0)->(DBSkip())
    End
    
    cSql += " ORDER BY F2_FILIAL                                                                           " + CRLF
    // Salva a Query
    //MemoWrite("C:\Temp\XSM0.sql", cSql)
    // Monta a tela para marcação dos registros.
    fBuildTela(cSql,cPasta)
    FwRestArea(aArea)
Return
/*/{Protheus.doc} fBuildTela
    Monta a tela para marcação.
    @type  Function
    @author Anderson Koziel - Vamilly
    @since 27/10/2023
    @version 1.0
/*/
Static Function fBuildTela(cSql,cPasta)
	Local aArea    := FwGetArea()
	Local cInsert  := ""  as Char
	Local aStruct  := {}  as Array
	Local aFields  := {}  as Array
	Local lGo      := .F. as Logical
   
	Private cMark    := GetMark()
	Private cAlias   := GetNextAlias()
	Private aSize    := MsAdvSize()
	Private aPosObj  := {}  as Array
	Private aObjects := {}  as Array
	Private aInfo    := {}  as Array
	Private lInvert  := .F. as Logical
	Private aRecSF2  := {}  as Array
	Private oTable          as Object
	Private oDlg            as Object
	Private oMark           as Object
	Private oProcess        as Object
    Private cNFEnt   := ""
    Private cSerEnt  := ""

    Private oFontRem  := TFont():New("Courier New",09,14,,.T.,,,,.F.,.F.)
    Private oSay1,oSay2,oSay3,oSay4, oGetNota,oSay5, oSay6, oSay7, oSay8, oSay9, oSay10

	// Estrutura
	aStruct := {}
	aadd(aStruct, {"OK"     , "C"                                  , 2                                        , 0                                       })
	aadd(aStruct, {"EMPRESA", "C"                                  , 2                                        , 0                                       })
	aadd(aStruct, {"FILIAL" , GetSx3Cache("F2_FILIAL"  , "X3_TIPO"), GetSx3Cache("F2_FILIAL"  , "X3_TAMANHO" ), GetSx3Cache("F2_FILIAL", "X3_DECIMAL"  )})
	aadd(aStruct, {"DOCUMENTO" , GetSx3Cache("F2_DOC"     , "X3_TIPO"), GetSx3Cache("F2_DOC"     , "X3_TAMANHO" ), GetSx3Cache("F2_DOC", "X3_DECIMAL"  )})
	aadd(aStruct, {"SERIE"  , GetSx3Cache("F2_SERIE"   , "X3_TIPO"), GetSx3Cache("F2_SERIE"   , "X3_TAMANHO" ), GetSx3Cache("F2_SERIE", "X3_DECIMAL"   )})
	aadd(aStruct, {"CLIENTE", GetSx3Cache("F2_CLIENTE" , "X3_TIPO"), GetSx3Cache("F2_CLIENTE" , "X3_TAMANHO" ), GetSx3Cache("F2_CLIENTE" , "X3_DECIMAL")})
	aadd(aStruct, {"LOJA"   , GetSx3Cache("F2_LOJA"    , "X3_TIPO"), GetSx3Cache("F2_LOJA"    , "X3_TAMANHO" ), GetSx3Cache("F2_LOJA" , "X3_DECIMAL"   )})
	aadd(aStruct, {"NOME"   , GetSx3Cache("A1_NOME"    , "X3_TIPO"), GetSx3Cache("A1_NOME"    , "X3_TAMANHO" ), GetSx3Cache("A1_NOME" , "X3_DECIMAL"   )})
	aadd(aStruct, {"EMISSAO", GetSx3Cache("F2_EMISSAO" , "X3_TIPO"), GetSx3Cache("F2_EMISSAO" , "X3_TAMANHO" ), GetSx3Cache("F2_EMISSAO" , "X3_DECIMAL")})
    aadd(aStruct, {"RECNO"  ,  "N"                                 , 8                                        , 0                                       })

	// Campos
	aFields := {}
	aadd(aFields, {"OK"        , , ""                       , ""                       ,            ""})
	aadd(aFields, {"EMPRESA"   , , "Empresa"                , "@!"                                    })
	aadd(aFields, {"FILIAL"    , , FWX3Titulo("F2_FILIAL"  ), GetSx3Cache("F2_FILIAL"  , "X3_PICTURE")})
	aadd(aFields, {"DOCUMENTO" , , FWX3Titulo("F2_DOC"     ), GetSx3Cache("F2_DOC"     , "X3_PICTURE")})
	aadd(aFields, {"SERIE"     , , FWX3Titulo("F2_SERIE"   ), GetSx3Cache("F2_SERIE"   , "X3_PICTURE")})
	aadd(aFields, {"CLIENTE"   , , FWX3Titulo("F2_CLIENTE" ), GetSx3Cache("F2_CLIENTE" , "X3_PICTURE")})
	aadd(aFields, {"LOJA"      , , FWX3Titulo("F2_LOJA"    ), GetSx3Cache("F2_LOJA"    , "X3_PICTURE")})
	aadd(aFields, {"NOME"      , , FWX3Titulo("A1_NOME"    ), GetSx3Cache("A1_NOME"    , "X3_PICTURE")})
	aadd(aFields, {"EMISSAO"   , , FWX3Titulo("F2_EMISSAO" ), GetSx3Cache("F2_EMISSAO" , "X3_PICTURE")})
    aadd(aFields, {"RECNO"     , , "Recno"                  ,                          ,     ""       })

	// Cria temporária
	oTable := FWTemporaryTable():New(cAlias)	 // Instanciar temp	
	oTable:SetFields(aStruct)	                 // Set fields			    
	oTable:Create()	                             // Cria temporária no banco	

	// Insere os registros na tabela temporaria
    BeginContent Var cInsert
		INSERT INTO %Exp:oTable:GetRealName()%
		(
                EMPRESA 
			,   FILIAL
            ,   DOCUMENTO
            ,   SERIE
            ,   CLIENTE
            ,   LOJA
            ,   NOME
            ,   EMISSAO
            ,   RECNO
		)
        %Exp:cSql%
	EndContent
    
    // Salva a Query
    //MemoWrite("C:\Temp\XDANFE.sql", cInsert)
			
	// Executa
	If (TCSqlExec(cInsert) < 0)
		FWAlertError("Erro ao popular tabela temporária  - TCSQLError() [" + TCSQLError() + "]", "ERRO")			
        Return
	EndIf        
    // Verifica se a Query retornou resultados.
    DBSelectArea(cAlias)
    (cAlias)->(DBGoTop())
    If (cAlias)->(Eof())
        (cAlias)->(DBCloseArea())
        oTable:Delete()
		FWAlertWarning("Nenhuma nota encontrada. Revise os parâmetros!", "ATENÇÃO")			
        Return    
    EndIf

	// Coordenadas
	aSize := MsAdvSize()
	AAdd( aObjects, { 100, 0 , .T., .T. } )
	AAdd( aObjects, { 100, 100, .T., .T. } )
	aInfo := { aSize[ 1 ], aSize[ 2 ], aSize[ 3 ], aSize[ 4 ], 5, 5 }
	aPosObj := MsObjSize( aInfo, aObjects,.T.)

	// Monta a tela para escolher os itens a serem excluídos
	(cAlias)->(DBGoTop())   
	oDlg := MSDialog():New(aSize[7] ,000,Round(aSize[6]/1.5,0), Round(aSize[5]/1.5,0),"Marcar as notas P/ Impressão",,,.F.,,,,,,.T.,,,.T. )                   

	oMark := MsSelect():New(cAlias,"OK","",aFields,@lInvert,@cMark,{060, 002, Round(aPosObj[2][3] / 1.5,0), Round(aPosObj[2][4] / 1.5,0) + 4}, , , oDlg)
	oMark:bMark :=  {|| }
	oMark:oBrowse:lHasMark		 := .T.
	oMark:oBrowse:lCanAllmark	 := .T.
	oMark:oBrowse:lAdjustColSize := .T.
	oMark:oBrowse:lJustific      := .F.
	oMark:bAval 				 := {|| fMark()}
	oMark:oBrowse:bAllMark 		 := {|| fMarkAll()}        
			
	Activate MSDialog oDlg Centered On Init EnchoiceBar(oDlg,{|| Iif((lGo := fTudoOk()), oDlg:End(), oDlg) },{|| oDlg:End()})

	// Confirmou
    If lGo 
        oTable:Delete()        
        Processa({ || fPrint(aRecSF2) }, "Emissão de  Danfe", "Emitindo Danfe, Aguarde...", .F.)                
    EndIf
    FwRestArea(aArea) 
Return

Static Function fPrint(aRecSF2)
    Local aArea   := FwGetArea()
    Local nTotReg := Len(aRecSF2)
    Local x       := 0
    Local y       := 0
    Local cNota   := ""
    Local cSerie  := ""
    Local cCli    := ""
    Local cLoja   := ""
    Local lRet     := .T.
    Local lFil     := .F.
    Local cMsg     := ""
    Local aNotas  := {}
    Local cDirSrv := Alltrim(SuperGetMV('DC_XDANFE',,"\DANFE\"))
    Local cArquivo := ""
   // Local aRetorno  := {.T., ""}

    ProcRegua(nTotReg)

    For x := 1 To nTotReg
        IncProc("Imprimindo nota...: [" + cValToChar(x) + "] de [" + cValToChar(nTotReg)+ "] - " + aRecSF2[x][2] + "/" + aRecSF2[x][3] + " ")
       
        // Verifica a filial do registro       
        If (Alltrim(cFilAnt) == AllTrim(aRecSF2[x][1]))
            lFil := .T.
        Else
            lFil := .F.
        EndIf
        
        // As variaveis recebem os valores conforme o conteudo do array.
        cFil   := aRecSF2[x][1] // Numero da Filial 
        cNota  := aRecSF2[x][2] // Numero do documento
        cSerie := aRecSF2[x][3] // Serie
        cCli   := aRecSF2[x][4] // Cliente 
        cLoja  := aRecSF2[x][5] // Loja

        // Se for a mesma filial faz via Interface, caso seja diferente faz via StartJob.
        if lFil
            U_zGerDanfe( cFil, cNota, cSerie, cCli, cLoja, cPasta, nTotReg, lFil)
        Else
            if StartJob( "u_zGerDanfe", GetEnvServer(), .T.,  cFil, cNota, cSerie, cCli, cLoja, cPasta, nTotReg, lFil )
                // Seta caminho do arquivo.
                cArquivo := AllTrim(cNota) + Alltrim(cSerie) + ".pdf"
                // Copia o arquivo para a maquina do usuário.
                If CpyS2T(cDirSrv+cArquivo, cPasta)
                    // Caso o arquivo tenha sido copiado deleta do servidor.
                    FErase(cDirSrv+cArquivo)  
                    lRet := .T.
                Else
                    //Não foi possivel imprimir o documento, vai aparecer na tela de log se o retorno for falso.
                    lRet := .F.
                EndIf
            EndiF 
        EndiF
        // Adiciona as notas não impressas no array para ser utilizado no log.
        if !lRet 
            Aadd(aNotas, {cFil, cNota, cSerie})
        EndIf      
    Next x

    //Impressão de logs
    if Len(aNotas) > 0
        cMsg += "As notas abaixo não foram impressas:" + CRLF
        For y := 1 to Len(aNotas)
            cMsg += "Filial:" + cValToChar(aNotas[y][1]) + " Documento: " + Alltrim(cValToChar(aNotas[y][2])) + "-" + Alltrim(cValToChar(aNotas[y][3])) + CRLF 
        Next y
        // Abre a tabela de log se tiver notas não impressas.
        EECVIEW( cMsg ,"Danfes não Impressas.")
    Else
        // Caso não tenha nenhum erro, aparece a mensagem de alerta.
        FwAlertSucess("As notas foram impressas com sucesso." + CRLF + "Verifique seu diretorio de impressão." + CRLF + cPasta ,"Processo Finalizado!")
    EndIf
    FwRestArea(aArea)
Return

/*/{Protheus.doc} fMark
    Função para marcação dos itens
    @type  Function
    @author Anderson Koziel - Vamilly
    @since 22/10/2023   
/*/
Static Function fMark(lAll)
	Local nRecno    := (cAlias)->(Recno())

    // Volta no recno
    (cAlias)->(DBGoto(nRecno))      

    // Somente 1
    If !lAll
        If !IsMark("OK",cMark)
            RecLock(cAlias, .F.)
            (cAlias)->OK := cMark
                //nFatura += (cAlias)->ZZW_VALFT
            (cAlias)->(MsUnLock())
        Else
            RecLock(cAlias, .F.)
            (cAlias)->OK := '  '
                //nFatura -= Iif(nFatura <= 0, 0, (cAlias)->ZZW_VALFT)
            (cAlias)->(MsUnLock())
        Endif
    Else
        // Varre todos os itens
        DBSelectArea(cAlias)
        (cAlias)->(DBGoTop())
        While (cAlias)->(!Eof())

            If !IsMark("OK",cMark)
                RecLock(cAlias, .F.)
                    (cAlias)->OK := cMark
                (cAlias)->(MsUnLock())
            Else
                RecLock(cAlias, .F.)
                    (cAlias)->OK := '  '
                (cAlias)->(MsUnLock())
            Endif

            (cAlias)->(DBSkip())			
        EndDo
    Endif

	If !lAll
	    (cAlias)->(DBGoto(nRecno))
	EndIf

	oDlg:Refresh()
    //oSay1:CtrlRefresh()
	//oSay2:CtrlRefresh()
	//oSay3:CtrlRefresh()
	//oSay4:CtrlRefresh()    
Return

/*/{Protheus.doc} fMarkAll
    Função para marcação de todos os itens
    @type  Function
    @author Anderson Koziel
    @since 22/10/2023   
/*/
Static Function fMarkAll()
	Local nRecno := Recno()
	Local lRet   := .T.

    fMark(.T.)
	
    (cAlias)->(DBGoto(nRecno))
	oDlg:Refresh()
    //oSay1:CtrlRefresh()
	//oSay2:CtrlRefresh()
	//oSay3:CtrlRefresh()
	//oSay4:CtrlRefresh()
Return lRet

/*/{Protheus.doc} fTudoOk()
    Valida as marcações.
    @type  Function
    @author Anderson Koziel - Vamilly
    @since 27/10/2023
    @version 1.0
/*/
Static Function fTudoOk()
	Local lRet    := .T.
	Local lHasOne := .F.
	Local nRecno  := Recno()

    (cAlias)->(DBGoTop())
    
    While (cAlias)->(!Eof())
        If Marked("OK")
            Aadd(aRecSF2, {(cAlias)->FILIAL, DOCUMENTO, SERIE,CLIENTE,LOJA})
            lHasOne := .T.
        EndIf

        (cAlias)->(DBSkip())
    End

    If !lHasOne 
        lRet := .F.
        FWAlertWarning("Nenhum item marcado, necessário marcar pelo menos 1 item para emitir a DANFE!", "ATENÇÃO")        
        (cAlias)->(DBGoto(nRecno))
        oDlg:Refresh()        
    EndIf
Return lRet
/*/{Protheus.doc} zGerDanfe
    Realiza a impressão da DANFE
    @type  Function
    @author Anderson Koziel - Vamilly
    @since 27/10/2023
    @version 1.0
    @param cFil, Character, Filial
    @param cNota, Character, Nota
    @param cSerie, Character, Serie
    @param cCli, Character, Cliente
    @param cLoja, Character, Loja do cliente
    @param cPasta, Character, Diretorio a ser salvo o arquivo
    @param nTotReg, Number , Numero de notas a serem impressas
    @param lFil, logical , Indica se é a mesma filial que esta sendo usada
    @return lRet, logical, Mostra se a nota foi impressa ou não.
/*/
User Function zGerDanfe( cFil, cNota, cSerie, cCli, cLoja, cPasta, nTotReg, lFil)
    Local aArea    := FWGetArea()
    Local lRet     := .T.
    Local cIdent   := ""
    Local oDanfe   := Nil
    Local lEnd     := .F.
    Local dDataDe  := sToD("20100101")
    Local dDataAt  := Date()
    Local cDirSrv   := ""
    Local cArquivo := AllTrim(cNota) + Alltrim(cSerie) + ".pdf"
    
    Private PixelX
    Private PixelY
    Private nConsNeg
    Private nConsTex
    Private oRetNF
    Private nColAux
    Default cNota  := ""
    Default cSerie := ""
    Default cPasta := GetTempPath()
    
    If !lFil
        RpcSetEnv( Left(cFil,2) , cFil ,,, "FAT",, , , , ,  )
    EndIf
    cDirSrv := Alltrim(SuperGetMV('DC_XDANFE',,"\DANFE\"))
    //Se existir nota
    If !Empty(cNota)
        //Pega o IDENT da empresa
        cIdent := RetIdEnti()
           
        //Se o último caracter da pasta não for barra, será barra para integridade
        If SubStr(cPasta, Len(cPasta), 1) != "\"
            cPasta += "\"
        EndIf

        If !ExistDir(cPasta)
            MakeDir(cPasta)
        EndIf
                      
        //Define as perguntas da DANFE
        Pergunte("NFSIGW",.F.)
        MV_PAR01 := cNota    //Nota Inicial
        MV_PAR02 := cNota  //Nota Final
        MV_PAR03 := cSerie    //Série da Nota
        MV_PAR04 := 2                          //NF de Saida
        MV_PAR05 := 2                          //Frente e Verso = Nao
        MV_PAR06 := 2                          //DANFE simplificado = Nao
        MV_PAR07 := dDataDe                    //Data De
        MV_PAR08 := dDataAt                    //Data Até

        // Posiciona na SF2 e faz a busca do registro.
        DBSelectArea("SF2")
        SF2->(DbSetOrder(1))
        if SF2->(DbSeek(cFil+cNota+cSerie+cCli+cLoja)) 
            
            //Cria a Danfe
            oDanfe:=FWMSPrinter():New(cArquivo, IMP_PDF, .F., '', .T., .F., , , .T., .T., , .F.)
            //Propriedades da DANFE
            oDanfe:SetResolution(72)
            oDanfe:SetPortrait()
            oDanfe:SetPaperSize(DMPAPER_A4)
            oDanfe:SetMargin(60, 60, 60, 60)
            
            //Força a impressão em PDF
            oDanfe:nDevice := IMP_PDF   
            // Se for da mesma filial            
            If lFil
                oDanfe:lInJob   := .F.
                oDanfe:lViewPDF := .T.
                oDanfe:cPathPDF := cPasta
                oDanfe:lServer  := .F.
            Else
                //Caso seja executado via Job, isso é quando a filial da Danfe é diferente da filial posicionada.
                oDanfe:lInJob   := .T.
                oDanfe:lViewPDF := .F.
                oDanfe:cPathPDF := cDirSrv
                oDanfe:lServer  := .T.
            EndIF

            //Variáveis obrigatórias da DANFE (pode colocar outras abaixo)            
            PixelX    := oDanfe:nLogPixelX()
            PixelY    := oDanfe:nLogPixelY()
            nConsNeg  := 0.4
            nConsTex  := 0.5
            oRetNF    := Nil
            nColAux   := 0
            
            //Chamando a impressão da danfe no RDMAKE
            u_DanfeProc(@oDanfe, @lEnd, cIdent, , , .F.) 
            // Imprime a Danfe
            oDanfe:Print()
            // Elimina o objeto da memoria.
            FreeObj(oDanfe) 
        Else
            // Não encontrou o arquivo.
            lRet := .F.
        EndIf
    EndIf     
    FWRestArea(aArea)
    // Se for executado via Job, limpa o ambiente.
    If !lFil
        RpcClearEnv()
    EndIf
Return lRet