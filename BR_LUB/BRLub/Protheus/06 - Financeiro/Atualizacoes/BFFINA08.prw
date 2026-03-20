#INCLUDE "RWMAKE.CH"
#include 'totvs.ch'
#INCLUDE "FWPrintSetup.ch"
#INCLUDE "TBICONN.CH"
#INCLUDE "COLORS.CH"
#INCLUDE "RPTDEF.CH"
#Include "PROTHEUS.CH"
#INCLUDE 'FWMVCDEF.CH'
#INCLUDE "FWBrowse.ch"
#INCLUDE "TOPCONN.CH"
#include 'parmtype.ch'


#define CR chr(13)+chr(10)
#define SL CHR(10)


#DEFINE STYLEBUTTON "QPushButton {	border: none;}"+;
    "QPushButton:pressed {"+;
    "background-color: white;}"
#define N_POS_CPO_FLAG	01
#define N_POS_CPO_PREV	02
#define N_POS_CPO_FORN	03
#define N_POS_CPO_LOJA	04
#define N_POS_CPO_NOME	05
#define N_POS_CPO_NRED	06
#define N_POS_CPO_NMUN	07
#define N_POS_CPO_UFES	08
#define N_POS_CPO_NUMP	09
#define N_POS_CPO_TIPO	10
#define N_POS_CPO_EMIS	11
#define N_POS_CPO_MOED	12
#define N_POS_CPO_TRAN	13
#define N_POS_CPO_ITEM	15
#define N_POS_CPO_PESO	16
#define N_POS_CPO_VALR	17
#define N_POS_CPO_USER	18




User Function BFFINA08()


    //Criação de folders
    Local	aMenus		        := {'VENDA CRÉDITO','VENDA DÉBITO','EXTRATO ELETRONICO'}
    Private oFolders	        := Nil
    Private aRotina 	        := {	{ OemToAnsi("Pesquisar") , "AxPesqui"      , 0, 1 },;
        { OemToAnsi("Visualizar"), "A410Visual"    , 0, 2 }}

    Private cDepto      := space(2)
    Private nDias       := 21
    Private nTurno      := Space(2)
    Private nPosOP      := 1
    Private nPosCodP    := 2
    Private nPosDescr   := 3
    Private nPosQTD     := 4
    Private nPosSLD     := 5
    Private nPosProd    := 6
    Private nPosPcsT    := 7
    Private nPosLead    := 8
    Private nPosRecur   := 9
    Private nPriorida   := 10
    Private nPosDUtil   := 11
    Private nPosDtIni   := 12
    Private nPosHrIni   := 13
    Private nPosDtEntr  := 14
    Private nPosHrFim   := 15
    Private nPosDtZA1   := 16
    Private nPosRecZA   := 17
    Private nPosDcZA1   := 18
    Private nLin		:= 006
    Private nPriorBKP   := 1
    Private cDtaBkp     := ""
    Private cDtaHrBkp   := ""
    Private cDataFim    := ""
    Private cHrFim      := ""

    Private aSize1              := MsAdvSize()
    Private cCadastro 	        := ''

    //ENTRADAS --------------------- COMEÇO
    //- Objetos de tela
    Private aMDLg			    := FWGetDialogSize(oMainWnd) //Array com dimensao da janela principal
    Private oLayerVC		    := FWLayer():New()
    Private oLayerVD		    := FWLayer():New()
    Private oLayerFI		    := FWLayer():New()
    
    Private	oComGridDet		    := Nil
    Private	oEntGetTcBrw	    := Nil
    Private oVCMenu		        := Nil
    Private oVDMenu		        := Nil
    Private oFIMenu		        := Nil
    Private	oVCToolBar		    := Nil
    Private	oVDToolBar		    := Nil
    Private	oFIToolBar		    := Nil


    Private lComAltMen		    := .f.

    Private ocOrdem
    Private cOrdem
    Private acOrdem
    Private ocDupl
    Private cDupl	            := 3
    Private acDupl
    Private oListVC             := NIL
    Private oListVD             := NIL
    Private oListFI             := NIL
    Private oListPedPCP         := NIL
    Private oListPedAlm         := NIL
    Private lMark			    := .F.	//Marcacao do tiquete
    //Fim - Variaveis de Filtro

    Private aVetPedCOM          := {}
    Private aVetPedPCP          := {}
    Private aVetPedAlm          := {}
    Private aVetPedOri          := {}
    Private aVetorGrv 	        := {}
    Private cProcura            :=SPACE(40)
    Private ocProcura
    Private aVetorBkp           := {}
    Private lNoFreeObj		    := .T.


    Private cArqImp	            := Space(150)
    Private	aCols,aHeader
    Private aPedMain            := {}
    Private oMainGrid           := NIL



    // Monta janela principal de interacao com o usuario
    _oDlgWnd := TDialog():New(aMDLg[1],aMDLg[2],aMDLg[3],aMDLg[4],OemToAnsi("Conciliação Bancária MaxiPago"),,,,nOr(WS_VISIBLE ,WS_POPUP),,,,,.T.,,,,,,.F.)
    _oDlgWnd:lMaximized := .T.
    oFontText := TFont():New('Verdana',0,14,,.T.,,,,.T.,.F.)

    //Função que monta o Painel Azul
    U_RtPanelH("Conciliação Bancária MaxiPago",_oDlgWnd)

    //Cria as folders principais
    oFolders := TFolder():New( 0,0,aMenus,,_oDlgWnd,1,,,.T.,.F.,200,200 )
    oFolders:Align := CONTROL_ALIGN_ALLCLIENT

    //Carrega os menus em cada folder
    EEVC()
    EEVD()
    EEFI()

    // Inicia o dialog na janela
    _oDlgWnd:Activate(,,,.T.,{||,.T.},,{||} )

Return




//-------------------------------------------------------------------
/*/{Protheus.doc} EEVC



@author  Rafael Pianezzer de Souza
@since   03/03/22
@version version
/*/
//-------------------------------------------------------------------
Static Function EEVC(cDepto,nTurno)

    Local lShowAba	        := .T.
    Local cOrigem 	        := "COM"
    Local nFimJ1			:= Int(asize1[3] / 2) - 12
    Local nIniJ2			:= Int(asize1[3] / 2) + 12
    Local nLinFim			:= Int(asize1[4]) - 35
    Local lInvPed           := .T.

    Private cProcura    := Space(40)
    Private ocProcura


    // Inicia os objetos Layers que separam as janelas internas na rotina.
    oLayerVC:Init(oFolders:aDialogs[1],.F.)
    oLayerVC:AddLine('Lin1',97,.F.)
    oLayerVC:AddCollumn('ColTool',15,.F.,'Lin1')
    oLayerVC:AddCollumn('ColGrid',85,.F.,'Lin1')
    oLayerVC:AddWindow('ColTool','wTool',OemToAnsi("Opções"),100,.F.,.F.,,'Lin1')
    oLayerVC:AddWindow('ColGrid','wGrid',OemToAnsi("Arquivo importação"),100,.F.,.F.,,'Lin1')
    oVCToolBar := oLayerVC:GetWinPanel('ColTool','wTool','Lin1')
    oVCToolBar:FreeChildren()
    oVCGridDet := oLayerVC:GetWinPanel('ColGrid','wGrid','Lin1')
    oVCGridDet:FreeChildren()

    // Cria as opcoes lateriais
    oVCMenu:=TTrackMenu():New(oVCToolBar,001,001,050,400, {|o,cID| fVCMenu(o,cID) } ,30,"#FDFDFE","#FFFFFF","#C0C0C0","#57A2EE",TFont():New('Arial',,9),"#000000")
    oVCMenu:Add("CADCLI","Processar Arquivo","instrume.png")
    oVCMenu:Add("CLOSE","Sair",'FINAL.png')

    @nLin   ,010 SAY "Selecione: " SIZE 050,7 PIXEL OF oVCGridDet
    @nLin   ,060 BUTTON oArqIMp PROMPT "Arquivo" PIXEl SIZE 132, 10 OF oVCGridDet ACTION (cArqImp := cGetFile( "Todos os Arquivos (*.*) | *.*", "Selecione o Arquivo",,"C:\",.T., ),Processa({|| sfCarrega('EEVC')},"Carregando dados..."))

    @ 020,05 LISTBOX oListVC VAR cVar FIELDS HEADER ;
        "OP","COD PRODUTO","DESCRIÇÃO","QTD","SALDO","PRODUZIR","PCS P/ TURNO","LEAD TIME (Dias)","RECURSO","PRIORIDADE","DIAS UTEIS","INICIO","HR INI","ENTREGA","HR FIM","OP INICIADA","RECURSO EM USO","DESC REC. EM USO";
        FIELDSIZES 20,20,0,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20 SIZE asize1[6]-115,asize1[4]-135 PIXEL  OF oVCGridDet
    //
    //oListCM:blDblClick:= {|| fEditField(@aVetPedCOM)}
    //
    //oListCM:lcoldrag := .T.
    //oListCM:lmodified := .T.
    //oListCM:lAdjustColSize := .T.
    //
    //lRet := MsgYesno("Você deseja carregar a visão salva do departamento?",FunName())

    //FWMsgRun(,{|| MontaQuery(cOrigem,'N',cDepto,lRet,nTurno) },"Gerando dados do simulador..")

    // Alinha o menu para usar todo o espaco
    oVCMenu:Align:= CONTROL_ALIGN_ALLCLIENT
    oVCMenu:Refresh()

Return



Static Function EEVD()

    Local lShowAba	    := .T.

    Private cProcura    := Space(40)
    Private ocProcura

    // Inicia os objetos Layers que separam as janelas internas na rotina.
    oLayerVD:Init(oFolders:aDialogs[2],.F.)
    oLayerVD:AddLine('Lin1',97,.F.)
    oLayerVD:AddCollumn('ColTool',15,.F.,'Lin1')
    oLayerVD:AddCollumn('ColGrid',85,.F.,'Lin1')
    oLayerVD:AddWindow('ColTool','wTool',OemToAnsi("Opções"),100,.F.,.F.,,'Lin1')
    oLayerVD:AddWindow('ColGrid','wGrid',OemToAnsi("Arquivo importação"),100,.F.,.F.,,'Lin1')
    oVDToolBar := oLayerVD:GetWinPanel('ColTool','wTool','Lin1')
    oVDToolBar:FreeChildren()
    oVDGridDet := oLayerVD:GetWinPanel('ColGrid','wGrid','Lin1')
    oVDGridDet:FreeChildren()

    // Cria as opcoes lateriais
    oVDMenu:=TTrackMenu():New(oVDToolBar,001,001,050,400, {|o,cID| fVCMenu(o,cID) } ,30,"#FDFDFE","#FFFFFF","#C0C0C0","#57A2EE",TFont():New('Arial',,9),"#000000")


    oVDMenu:Add("CADCLI","Processar Arquivo","instrume.png")
    oVDMenu:Add("CLOSE","Sair",'FINAL.png')


    @nLin   ,010 SAY "Selecione: " SIZE 050,7 PIXEL OF oVDGridDet
    @nLin   ,060 BUTTON oArqIMp PROMPT "Arquivo" PIXEl SIZE 132, 10 OF oVDGridDet ACTION (cArqImp := cGetFile( "Todos os Arquivos (*.*) | *.*", "Selecione o Arquivo",,"C:\",.T., ),Processa({|| sfCarrega('EEVD')},"Carregando dados..."))

    @ 020,05 LISTBOX oListVD VAR cVar FIELDS HEADER ;
        "OP","COD PRODUTO","DESCRIÇÃO","QTD","SALDO","PRODUZIR","PCS P/ TURNO","LEAD TIME (Dias)","RECURSO","PRIORIDADE","DIAS UTEIS","INICIO","HR INI","ENTREGA","HR FIM","OP INICIADA","RECURSO EM USO","DESC REC. EM USO";
        FIELDSIZES 20,20,0,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20 SIZE asize1[6]-115,asize1[4]-135 PIXEL  OF oVDGridDet

    //oListCM:blDblClick:= {|| fEditField(@aVetPedCOM)}

    //oListCM:lcoldrag := .T.
    //oListCM:lmodified := .T.
    //oListCM:lAdjustColSize := .T.

    //lRet := MsgYesno("Você deseja carregar a visão salva do departamento?",FunName())

    //FWMsgRun(,{|| MontaQuery(cOrigem,'N',cDepto,lRet,nTurno) },"Gerando dados do simulador..")

    oFolders:aEnable(2, lShowAba)

    // Alinha o menu para usar todo o espaco
    oVDMenu:Align:= CONTROL_ALIGN_ALLCLIENT
    oVDMenu:Refresh()

Return



Static Function EEFI()

    Local lShowAba	    := .T.

    Private cProcura    := Space(40)
    Private ocProcura

    // Inicia os objetos Layers que separam as janelas internas na rotina.
    oLayerFI:Init(oFolders:aDialogs[3],.F.)
    oLayerFI:AddLine('Lin1',97,.F.)
    oLayerFI:AddCollumn('ColTool',15,.F.,'Lin1')
    oLayerFI:AddCollumn('ColGrid',85,.F.,'Lin1')
    oLayerFI:AddWindow('ColTool','wTool',OemToAnsi("Opções"),100,.F.,.F.,,'Lin1')
    oLayerFI:AddWindow('ColGrid','wGrid',OemToAnsi("Arquivo importação"),100,.F.,.F.,,'Lin1')
    oFIToolBar := oLayerFI:GetWinPanel('ColTool','wTool','Lin1')
    oFIToolBar:FreeChildren()
    oFIGridDet := oLayerFI:GetWinPanel('ColGrid','wGrid','Lin1')
    oFIGridDet:FreeChildren()

    // Cria as opcoes lateriais
    oFIMenu:=TTrackMenu():New(oFIToolBar,001,001,050,400, {|o,cID| fVCMenu(o,cID) } ,30,"#FDFDFE","#FFFFFF","#C0C0C0","#57A2EE",TFont():New('Arial',,9),"#000000")


    oFIMenu:Add("CADCLI","Processar Arquivo","instrume.png")
    oFIMenu:Add("CLOSE","Sair",'FINAL.png')


    @nLin ,010 SAY "Selecione: " SIZE 050,7 PIXEL OF oFIGridDet
    @nLin ,060 BUTTON oArqIMp PROMPT "Arquivo" PIXEl SIZE 132, 10 OF oFIGridDet ACTION (cArqImp := cGetFile( "Todos os Arquivos (*.*) | *.*", "Selecione o Arquivo",,"C:\",.T., ),Processa({|| sfCarrega('EEFI')},"Carregando dados..."))

    @ 020,05 LISTBOX oListFI VAR cVar FIELDS HEADER ;
        "OP","COD PRODUTO","DESCRIÇÃO","QTD","SALDO","PRODUZIR","PCS P/ TURNO","LEAD TIME (Dias)","RECURSO","PRIORIDADE","DIAS UTEIS","INICIO","HR INI","ENTREGA","HR FIM","OP INICIADA","RECURSO EM USO","DESC REC. EM USO";
        FIELDSIZES 20,20,0,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20 SIZE asize1[6]-115,asize1[4]-135 PIXEL  OF oFIGridDet

    //oListCM:blDblClick:= {|| fEditField(@aVetPedCOM)}

    //oListCM:lcoldrag := .T.
    //oListCM:lmodified := .T.
    //oListCM:lAdjustColSize := .T.

    //lRet := MsgYesno("Você deseja carregar a visão salva do departamento?",FunName())

    //FWMsgRun(,{|| MontaQuery(cOrigem,'N',cDepto,lRet,nTurno) },"Gerando dados do simulador..")

    oFolders:aEnable(3, lShowAba)

    // Alinha o menu para usar todo o espaco
    oFIMenu:Align:= CONTROL_ALIGN_ALLCLIENT
    oFIMenu:Refresh()

Return




//-------------------------------------------------------------------
/*/{Protheus.doc} fVCMenu

Função que chama as funções de menu (Comercial)
@author  Rafael Pianezzer de Souza
@since   20/8/20
@version version
/*/
//-------------------------------------------------------------------
Static Function fVCMenu(o,cID)

    If	lComAltMen
        Return
    EndIf

    lComAltMen := .T. // flag de controle para evitar duas chamadas ao clicar duas vezes no mesmo menu.

    Do Case
        Case cID = "CLOSE"
            _oDlgWnd:End()
        Case cID = "HIST"
            MsgRun(OemToAnsi('Aguarde...'),' ',{|| CursorWait(),fHistLog(),CursorArrow()})
        Case cID = "CADCLI"
            MsgRun(OemToAnsi('Aguarde...'),' ',{|| CursorWait(),FWMsgRun(,{|| fSaveData() },"Salvando..."),CursorArrow()})
        Case cID = "GRAFAP"
            MsgRun(OemToAnsi('Aguarde...'),' ',{|| CursorWait(),U_fMetxRea(cDepto,'MD'),CursorArrow()})
        Case cID = "IMPRES"
            MsgRun(OemToAnsi('Aguarde...'),' ',{|| CursorWait(),U_fImpGrid(),CursorArrow()})
    End Case

    lComAltMen := .F.

Return




//-------------------------------------------------------------------
/*/{Protheus.doc} MontaQuery

Consulta query

@author  Rafael Pianezzer de Souza
@since   06/07/21
@version version
/*/
//-------------------------------------------------------------------
Static Function MontaQuery(cOrigem,cAcao,cDepto,lRet,nTurno)
    Local aSalvAmb 	    :=  GetArea()
    Local _lRet    	    :=  .T.
    Local nX,nY,nJ,nK
    Local aVetZA9       :=  {}
    Local aVetOPS       :=  {}
    Local _nTurno       := Val(nTurno)
    Local aVetBkpZA9    := {}
    Local nPosAnt       := 1
    Local nPrior        := 1
    Local nPos          := 1
    Local aReorRec      := {}
    Local nPosReor      := 0
    Local lAchouSec     := .F.

    Private _aPedsTot	:= {}

    MSGRUN(oemtoansi("    Consultando a Base de Dados..."),"",{||inkey(0.01)})

    DbSelectArea('ZA9')

    //Se True, irá carregar a visão salva anterior, adicionando as novas OPS que não estavam anteriormente
    If lRet

        //Consulta os registros salvos no depto.
        fConsSave(cDepto)

        While !QRY->(Eof())

            //Consulta para pegar Lead time do Recurso.
            _nLeadTime := fConsSG2(QRY->ZA9_PRODUT,cDepto)

            aAdd(aVetZA9,{QRY->ZA9_OP,;                                                                     //1
                QRY->ZA9_PRODUT,;                                                                           //2
                POSICIONE('SB1',1,xFilial('SB1')+QRY->ZA9_PRODUT,"B1_DESC"),;                               //3
                POSICIONE('SC2',1,xFilial('SC2')+QRY->ZA9_OP+QRY->ZA9_PRODUT,"C2_QUANT"),;                  //4
                QRY->ZA9_SALDO,;                                                                            //5
                QRY->ZA9_QTDPRO,;                                                                           //6
                _nTurno*_nLeadTime,;                                                                        //7
                QRY->ZA9_DIASPR,;                                                                           //8
                QRY->ZA9_RECURS,;                                                                           //9
                QRY->ZA9_PRIORI,;                                                                           //10
                QRY->ZA9_DIASIM,;                                                                           //11
                (StoD(QRY->ZA9_DTAINI)),;                                                                   //12
                QRY->ZA9_HRINIC,;                                                                           //13
                (StoD(QRY->ZA9_DTAFIM)),;                                                                   //14
                QRY->ZA9_HRFIM,;                                                                            //15
                (StoD(QRY->ZA1_DTINIC)),;
                QRY->H1_CODIGO,;
                QRY->H1_DESCRI;
                })

            QRY->(DBSkip())
        EndDo


        //=========================================== MONTAGEM DAS OPS EM ABERTO - INICIO =============================================================//
        fMontaOPS(cDepto)
        //=========================================== MONTAGEM DAS OPS EM ABERTO - FIM ================================================================//

        aVetOPS := aClone(aVetPedCOM)

        //Atualiza os dados dos registros salvos que ainda estão em aberto com saldo menor que o salvo anteriormente.
        For nX:=1 To Len(aVetZA9)
            For nJ:=1 To Len(aVetOPS)
                If Alltrim(aVetZA9[nX,nPosOP]) == Alltrim(aVetOPS[nJ,nPosOP])
                    If aVetZA9[nX,nPosSLD] <> aVetOPS[nJ,nPosSLD]
                        aVetZA9[nX,nPosSLD]  := aVetOPS[nJ,nPosSLD]
                        aVetZA9[nX,nPosProd] := aVetOPS[nJ,nPosProd]
                        aVetZA9[nX,nPosLead] := aVetOPS[nJ,nPosLead]
                        Exit
                    EndIf

                    //Atualização do recurso.
                    If aVetZA9[nX,nPosRecur] <> aVetOPS[nJ,nPosRecur]

                        //Verifica se o recurso Salvo no roteiro tem como secundario o salvo na visão anterior, se não encontrar, substitui.
                        fGetRecSec(aVetOPS[nJ,nPosRecur],aVetZA9[nX,nPosCodP])

                        While !RECURSO->(Eof())
                            If Alltrim(aVetZA9[nX,nPosRecur]) == Alltrim(RECURSO->H3_RECALTE)
                                lAchouSec := .T.
                                Exit
                            EndIf
                            RECURSO->(DbSkip())
                        EndDo

                        If !lAchouSec
                            cRecAnt := aVetZA9[nX,nPosRecur]
                            aVetZA9[nX,nPosRecur] := aVetOPS[nJ,nPosRecur]
                            //Recursos Alterados no roteiro após terem sidos salvos.
                            aadd(aReorRec,{aVetZA9[nX],cRecAnt})
                        EndIf

                    EndIf

                    aRet := fConsZA1(aVetZA9[nX,nPosOP],cDepto)

                    If !Empty(aRet)
                        aVetZA9[nX,nPosDtZA1] := StoD(aRet[1])
                        aVetZA9[nX,nPosRecZA] := aRet[2]
                        aVetZA9[nX,nPosDcZA1] := Alltrim(aRet[3])
                    EndIf

                EndIf

            Next nJ
        Next nX

        //Consulta as OPS que não estavam salvas na visão anterior.
        fDifZA9XOP(cDepto)

        While !DIFZA9->(Eof())

            aVetBkpZA9 := {}

            cAddRec := DIFZA9->G2_RECURSO

            For nX:=1 To Len(aVetZA9)
                If Alltrim(aVetZA9[nX,nPosRecur]) == Alltrim(cAddRec)
                    nPos    := nX
                    nPosAnt := nX - 1
                    nPrior  := aVetZA9[nPos,nPriorida]
                EndIf
            Next nX

            cHrProd := Round((DIFZA9->SALDO / DIFZA9->LEAD_TIME),2)
            aRet    := fGetDH(DtoS(aVetZA9[nPosAnt,nPosDtEntr]),cHrProd,Val(nTurno),aVetZA9[nPosAnt,nPosHrFim])

            //Soma 1 na prioridade
            nPrior++
            nPosDado := nPos

            //Soma 1 na próxima posição.
            nPos++

            //Adiciona mais um item no array
            Aadd(aVetZA9,NIL)

            //Adiciona na posição especifica, empurrando pra baixo o resto do array
            AINS(aVetZA9,nPos)

            Aadd(aVetBkpZA9,{ DIFZA9->C2_NUM,;
                DIFZA9->C2_PRODUTO,;
                DIFZA9->B1_DESC,;
                DIFZA9->C2_QUANT,;
                DIFZA9->SALDO,;
                DIFZA9->SALDO,;
                Val(nTurno)*DIFZA9->LEAD_TIME,;
                Round(DIFZA9->SALDO/(Val(nTurno)*DIFZA9->LEAD_TIME),2) ,;
                cAddRec,;
                nPrior,;
                nDias,;
                StoD(aRet[1]),;
                aRet[2],;
                StoD(aRet[3]),;
                aRet[4],;
                (StoD(DIFZA9->ZA1_DTINIC)),;
                DIFZA9->H1_CODIGO,;
                DIFZA9->H1_DESCRI;
                })

            aVetZA9[nPos] := aVetBkpZA9[1]

            DIFZA9->(DBSkip())

        EndDo

        If !Empty(aReorRec)
            For nX:=1 To Len(aReorRec)
                //Função que rerodena os recursos que foram alterados após a gravação da visão.
                fOrdemRec(aVetZA9,aReorRec,nX)
            Next nX

        EndIf

        aVetPedCom := aClone(aVetZA9)

    Else

        //=========================================== MONTAGEM DAS OPS EM ABERTO - INICIO =============================================================//
        fMontaOPS(cDepto)
        //=========================================== MONTAGEM DAS OPS EM ABERTO - FIM ================================================================//

    EndIf

    //Monta o array na GRID
    fMontGrid(aVetPedCom)

    QRY->(dbGoTop())

    If Select("QRY") <> 0
        DbSelectArea("QRY")
        dbCloseArea("QRY")
    EndIf

    RestArea( aSalvAmb )

Return (_lRet)


//-------------------------------------------------------------------
/*/{Protheus.doc} AdicVetCom

Função pra preencher os dados
@author  Rafael Pianezzer de Souza
@since   06/07/21
@version version
/*/
//-------------------------------------------------------------------
Static Function AdicVetCom(aVetor,cAlias,lVazio,lSame,nPrior,lRet)

    Local nSaldo        := 0
    Local cDataIni      := ""
    Local aRet          := {}
    Local cHrIni        := ""

    If ValType(nTurno) == 'C'
        nTurno := Val(nTurno)
    EndIf

    nSaldo        := SALDO

    If !lVazio

        cHrProd := Round(QRY->SALDO/QRY->LEAD_TIME,2)
        _nPosHrFim := Len(aVetor)
        _cHrFimAnt := iif(_nPosHrFim == 0 ,'',aVetor[_nPosHrFim][15])

        //Se mudou o recurso Zera a hora fim anterior
        If !lSame
            _cHrFimAnt := ''
        EndIf

        aRet := fGetDH(cDtaBkp,cHrProd,nTurno,_cHrFimAnt)

        If lSame
            cDataIni := aRet[1]
            cHrIni   := aRet[2]
            cDataFim := aRet[3]
            cHrFim   := aRet[4]
        Else
            cDataIni := aRet[1]
            cHrIni   := aRet[2]
            cDataFim := aRet[3]
            cHrFim   := aRet[4]
            cDataIni := DTOS(dDataBase)

        Endif

        dbSelectArea(cAlias)

        cRecurso        := G2_RECURSO
        nQtdPro         := nSaldo

        aAdd(aVetor,{C2_NUM,;                       //1
            C2_PRODUTO,;                            //2
            (B1_DESC),;                             //3
            C2_QUANT,;                              //4
            SALDO,;                                 //5
            nQtdPro,;                               //6
            nTurno*LEAD_TIME,;                      //7
            Round(nQtdPro/(nTurno*LEAD_TIME),2),;   //8
            cRecurso,;                              //9
            nPrior,;                                //10
            nDias,;                                 //11
            (StoD(cDataIni)),;                      //12
            cHrIni,;                                //13
            (StoD(cDataFim)),;                      //14
            cHrFim,;                                //15
            (StoD(ZA1_DTINIC)),;                    //16
            H1_CODIGO,;                             //17
            H1_DESCRI;                              //18
            })

    Else
        aAdd(aVetor,{"",;                           //1
            "",;                                    //2
            "",;                                    //3
            "",;                                    //4
            "",;                                    //5
            "",;                                    //6
            "",;                                    //7
            "",;                                    //8
            "",;                                    //9
            "",;                                    //10
            "",;                                    //11
            "",;                                    //12
            "",;                                    //13
            "",;                                    //14
            "",;                                    //15
            "",;                                    //16
            "",;                                    //17
            "";                                     //19
            })
    EndIF

    nPrior := nPriorBKP

Return



//-------------------------------------------------------------------
/*/{Protheus.doc} fMontGrid

Monta a grid de acordo com o Array passado.

@author  Rafael Pianezzer de Souza
@since   06/07/21
@version version
/*/
//-------------------------------------------------------------------
Static Function fMontGrid(aVetPedCOM)

    Local _lRet   := .T.


    If !Empty(aVetPedCOM)

        oListCM:SetArray(aVetPedCOM)

        oListCM:bLine := {||{   aVetPedCOM[oListCM:nAt,1],;     //1
            aVetPedCOM[oListCM:nAt,2],;                         //2
            aVetPedCOM[oListCM:nAt,3],;                         //3
            aVetPedCOM[oListCM:nAt,4],;                         //4
            aVetPedCOM[oListCM:nAt,5],;                         //5
            aVetPedCOM[oListCM:nAt,6],;                         //6
            aVetPedCOM[oListCM:nAt,7],;                         //7
            aVetPedCOM[oListCM:nAt,8],;                         //8
            aVetPedCOM[oListCM:nAt,9],;                         //9
            aVetPedCOM[oListCM:nAt,10],;                        //10
            aVetPedCOM[oListCM:nAt,11],;                        //11
            aVetPedCOM[oListCM:nAt,12],;                        //12
            aVetPedCOM[oListCM:nAt,13],;                        //13
            aVetPedCOM[oListCM:nAt,14],;                        //14
            aVetPedCOM[oListCM:nAt,15],;                        //15
            aVetPedCOM[oListCM:nAt,16],;                        //16
            aVetPedCOM[oListCM:nAt,17],;                        //16
            aVetPedCOM[oListCM:nAt,18];                        //16
            }}

        oListCM:Refresh()
        oComGridDet:Refresh()

    EndIf

Return (_lRet)




//-------------------------------------------------------------------
/*/{Protheus.doc} fEditField

Colunas que poderão serem editadas.

@author  Rafael Pianezzer de Souza
@since   06/07/21
@version version
/*/
//-------------------------------------------------------------------
Static Function fEditField(aVetPedCOM)

    Local nProduzir   := aVetPedCOM[oListCM:nAt,nPosProd]
    Local cRecurso    := aVetPedCOM[oListCM:nAt,nPosRecur]
    Local nPriorid    := aVetPedCOM[oListCM:nAt,nPriorida]
    Local cOp         := aVetPedCOM[oListCM:nAt,nPosOP]
    Local aReorRec    := {}
    Local lAlter      := .F.

    If  oListCM:ColPos() == nPosProd            // PRODUZIR
        lEditCell(@aVetPedCOM,oListCM, PesqPict('SC2', "C2_QUANT"),oListCM:ColPos())
        lAlter := .T.
    ElseIf oListCM:ColPos() == nPosRecur         // RECURSO
        lEditCell(@aVetPedCOM,oListCM,PesqPict('SH1', "H1_CODIGO"),oListCM:ColPos())
        lAlter := .T.
    ElseIf        oListCM:ColPos() == nPriorida  // PRIORIDADE
        lEditCell(@aVetPedCOM,oListCM,"@R 99",oListCM:ColPos())
        lAlter := .T.
    EndIf

    If lAlter

        //Habilita a edição de campo
        lEditCell(@aVetPedCOM,oListCM,"@!",oListCM:ColPos())

        If nProduzir <> aVetPedCOM[oListCM:nAt,nPosProd]
            aVetPedCOM[oListCM:nAt,8] := Round(aVetPedCOM[oListCM:nAt,nPosProd]/(aVetPedCOM[oListCM:nAt,7]),2)
        EndIf

        If oListCM:ColPos() == nPosRecur//cRecurso <> aVetPedCOM[oListCM:nAt,nPosRecur]

            //Busca a lista de recursos auxiliares para o principal
            cRet := fListRec(cRecurso, aVetPedCOM[oListCM:nAt,nPosCodP])

            If cRecurso <> cRet
                aVetPedCOM[oListCM:nAt,nPosRecur] := cRecurso
                //aadd(aReorRec,aVetPedCOM[oListCM:nAt])
                //Função que rerodena os recursos que foram alterados após a gravação da visão.
                //fOrdemRec(aVetZA9,aReorRec,nX)
                FWMsgRun(,{|| fReordena(aVetPedCOM,oListCM:nAt,'RECURSO',aVetPedCOM[oListCM:nAt,nPriorida],cOp,cRet) },"Atualizando..")

            Else
                aVetPedCOM[oListCM:nAt,nPosRecur] := cRecurso
            EndIf

            Return
        EndIf

        If nPriorid <> aVetPedCOM[oListCM:nAt,nPriorida]
            FWMsgRun(,{|| fReordena(aVetPedCOM,oListCM:nAt,'PRIORIDADE',aVetPedCOM[oListCM:nAt,nPriorida],cOp) },"Atualizando..")
            Return
        EndIf



    EndIf


Return



//-------------------------------------------------------------------
/*/{Protheus.doc} Parametro

Lista de parametros inicial

@author  Rafael Pianezzer de Souza
@since   06/07/21
@version version
/*/
//-------------------------------------------------------------------
Static Function Parametro()

    Private aRet		:= {}
    Private aPergPar	:=	{}
    Private lRet		:= .F.
    //Private cDepto      := Space(2)
    //Private nDias       := Space(2)
    //Private nTurno      := Space(2)

    aadd(aPergPar,{1,"Departamento",cDepto,"","","OP","",20,.T.})
    aadd(aPergPar,{1,"Dias Trabalhados",nDias,"","","","",2,.T.})
    aadd(aPergPar,{1,"Hrs Trab.",nTurno,"","","","",2,.T.})

    If ParamBox(aPergPar,"Selecione:",@aRet)
        cDepto	:= aRet[1]
        nDias	:= aRet[2]
        nTurno	:= aRet[3]
        lRet := .T.
        Return lRet
    EndIf

Return lRet


//-------------------------------------------------------------------
/*/{Protheus.doc} fValidFiel

Função de validação de campo

@author  Rafael Pianezzer de Souza
@since   06/07/21
@version version
/*/
//-------------------------------------------------------------------
Static Function fValidFiel(cTipo,cVar)
    Local lRet      := .T.
    Local nPosH     := 3
    Local nPosHBkp  := 0

    If Alltrim(cTipo) == 'H'
        nPosHBkp := At(':',cVar)

        If nPosHBkp <> nPosH
            lRet := .F.
        EndIf
    EndIf


    If Alltrim(cTipo) == 'D'
        If ValType(cVar) <> 'D'
            lRet := .F.
        EndIf
    EndIf

Return lRet



//-------------------------------------------------------------------
/*/{Protheus.doc} fSaveData

Função para salvar a visão

@author  Rafael Pianezzer de Souza
@since   06/07/21
@version version
/*/
//-------------------------------------------------------------------
Static Function fSaveData()

    Local lRet          := .F.
    Local nX
    Local nPosOP        := 1
    Local nPosCdPro     := 2
    Local nPosDescr     := 3
    Local nPosQTD       := 4
    Local nPosSLD       := 5
    Local nPosProdz     := 6
    Local nPosPcsT      := 7
    Local nPosLead      := 8
    Local nPosRec       := 9
    Local nPosPrio      := 10
    Local nPosDUtil     := 11
    Local nPosDtIn      := 12
    Local nPosHrIn      := 13
    Local nPosDtFim     := 14
    Local nPosHrFim     := 15


    DBSelectArea('ZA9')
    DbSetOrder(1)

    lRet    := MsgYesNo("Você deseja sobrescrever a visão anterior do departamento?",FunName())

    If lRet
        Begin transaction

            DbSelectArea('ZA9')
            DbSetOrder(2)
            If DbSeek(xFilial('ZA9')+cDepto)

                While Alltrim(ZA9->ZA9_DEPTO) == Alltrim(cDepto)
                    RecLock('ZA9',.F.)
                    ZA9->(DBDelete())
                    ZA9->(MsUnlock())
                    ZA9->(DBSkip())
                EndDo

            EndIf

            For nX:=1 To Len(aVetPedCOM)
                Reclock('ZA9',.T.)
                ZA9->ZA9_FILIAL := xFilial('ZA9')
                ZA9->ZA9_OP     := aVetPedCOM[nX,nPosOP]
                ZA9->ZA9_PRODUT := aVetPedCOM[nX,nPosCdPro]
                ZA9->ZA9_SALDO  := aVetPedCOM[nX,nPosSLD]
                ZA9->ZA9_QTDPRO := aVetPedCOM[nX,nPosProdz]
                ZA9->ZA9_DIASPR := aVetPedCOM[nX,nPosLead]
                ZA9->ZA9_RECURS := aVetPedCOM[nX,nPosRec]
                ZA9->ZA9_PRIORI := aVetPedCOM[nX,nPosPrio]
                ZA9->ZA9_DIASIM := aVetPedCOM[nX,nPosDUtil]
                ZA9->ZA9_DTAINI := (aVetPedCOM[nX,nPosDtIn])
                ZA9->ZA9_HRINIC := aVetPedCOM[nX,nPosHrIn]
                ZA9->ZA9_DTAFIM := (aVetPedCOM[nX,nPosDtFim])
                ZA9->ZA9_HRFIM  := aVetPedCOM[nX,nPosHrFim]
                ZA9->ZA9_DTPROC := dDataBase
                ZA9->ZA9_HRPROC := SubStr(Time(),1,5)
                ZA9->ZA9_DEPTO  := cDepto
                ZA9->(MsUnLock())
            Next nX

        End Transaction

        MsgAlert("Dados gerados com sucesso.",FunName())

    EndIf

Return


//-------------------------------------------------------------------
/*/{Protheus.doc} fListRec

Função que gera a lista dos recursos alternativos relacionados na SH3

@author  Rafael Pianezzer de Souza
@since   13/7/21
@version version
/*/
//-------------------------------------------------------------------
Static Function fListRec(cRecurso,cCodProd)

    Local cQuery            :=""
    Local _aCols            := {}
    Local I
    Local oDlg
    Local nJanLarg          := 0400
    Local nJanAltu          := 0700
    Local cNewVal           := ''
    Private aDadosRec       := {}
    Private aCampPed        := {}
    Private cCodigo         := ""
    Private _bRet           := .T.


    If Select('RECURSO') <> 0
        RECURSO->(DbCloseArea())
    EndIf

    BeginSql Alias 'RECURSO'
        SELECT
            H3_PRODUTO,
            H3_OPERAC,
            H3_RECPRIN,
            SH1PRI.H1_DESCRI PRINC,
            H3_RECALTE,
            SH1ALT.H1_DESCRI DESCALTER
        FROM
            %table:SH3% SH3
        INNER JOIN %table:SH1% SH1ALT (NOLOCK)
        ON (
                SH1ALT.H1_FILIAL = H3_FILIAL
                AND H3_RECALTE = SH1ALT.H1_CODIGO
                AND SH1ALT.D_E_L_E_T_ = ''
            )
        INNER JOIN %table:SH1% SH1PRI (NOLOCK)
        ON (
                SH1PRI.H1_FILIAL = H3_FILIAL
                AND H3_RECPRIN = SH1PRI.H1_CODIGO
                AND SH1PRI.D_E_L_E_T_ = ''
            )
        WHERE
            SH3.H3_FILIAL = %xFilial:SH3%
            AND SH3.H3_RECPRIN = %exp:cRecurso%
            AND SH3.H3_PRODUTO = %exp:cCodProd%
            AND SH3.%notDel%
    EndSql

    aQuery := GetLastQuery()
    cQuery := aQuery[2]

    cAliasTmp := CriaTrab(Nil,.F.)
    dbUseArea(.T.,"TOPCONN", TCGENQRY(,,cQuery),cAliasTmp, .F., .T.)

    DBSelectArea(cAliasTmp)
    DBGoTop()

    If Eof()
        MsgAlert("Não foi encontrado recurso alternativo para o produto, favor verificar.")
        Return cRecurso
    Endif

    Do While !EOF()
        AAdd( aDadosRec, { (cAliasTmp)->H3_PRODUTO, (cAliasTmp)->H3_OPERAC, (cAliasTmp)->H3_RECPRIN, (cAliasTmp)->PRINC, (cAliasTmp)->H3_RECALTE,(cAliasTmp)->DESCALTER} )
        DbSkip()
    Enddo
    DBCloseArea(cAliasTmp)

    Define MsDialog oDlgSB1 Title "Pesquisar Alternativo" From 0,0 To nJanLarg,nJanAltu Of oMainWnd Pixel

    @ 5,5 LISTBOX oLstSB1 VAR lVarMat Fields HEADER "Cod Produto" , "Operacao" , "Rec Princ.", "Descricao Rec Princ.", "Rec Alter.", "Descricao Rec Alter."  ;//FIELDSIZES 15,30;
        SIZE 345,180 On DblClick ( cNewVal := fGetRec(oLstSB1:nAt, @aDadosRec, @_bRet) ) FIELD SIZES 05,50,05,100 OF oDlgSB1 PIXEL //05,50,05,100

    oLstSB1:SetArray(aDadosRec)
    oLstSB1:bLine := { || {aDadosRec[oLstSB1:nAt,1], aDadosRec[oLstSB1:nAt,2], aDadosRec[oLstSB1:nAt,3], aDadosRec[oLstSB1:nAt,4], aDadosRec[oLstSB1:nAt,5], aDadosRec[oLstSB1:nAt,6]} }

    Activate MSDialog oDlgSB1 Centered

    If Empty(cNewVal)
        cNewVal := cRecurso
    EndIf

Return cNewVal


//-------------------------------------------------------------------
/*/{Protheus.doc} fGetRec

Duplo clique na chamada da
Função que gera a lista dos recursos alternativos relacionados na SH3

@author  Rafael Pianezzer de Souza
@since   13/7/21
@version version
/*/
//-------------------------------------------------------------------
Static Function fGetRec(nPos,aArray,cRet)
    Local cNewVal   := aArray[nPos][5]

    oDlgSB1:End()
Return cNewVal



//-------------------------------------------------------------------
/*/{Protheus.doc} fGetDH

Função que classifica data e hora inicio e fim de acordo com o roteiro.

@author  Rafael Pianezzer de Souza
@since   13/7/21
@version version
/*/
//-------------------------------------------------------------------
Static Function fGetDH(cDataIni,nTempHr,nTurno,_cHrFimAnt)

    Local _cDataIni         := cDataIni
    Local _nTempHr          := nTempHr
    Local _cHrIni           := ""
    Local _nRestHr          := _nTempHr%nTurno
    Local _cDataFim         := ""
    Local _cHrFim           := ""
    Local nTotHr            := 10
    Local _nTotRest         := 0

    If Empty(_cHrFimAnt)
        _cHrIni := '07:00'
    Else
        _cHrIni := _cHrFimAnt
    EndIf

    //Verifica se a quantidade de horas de produção é menor que 1. Se for maior, valida se será mais que o dia corrente.
    If nTempHr < 1
        _cDataFim   := _cDataIni
        _cDataFim   := fDataFim(_cDataFim)
        _cHrFim     := IntToHora(HoraToInt(_cHrIni)+_nRestHr)
    Else
        _nTotRest := fGetTime(IntToHora(HoraToInt(_cHrIni)+1))
        _nTotRest := nTotHr - _nTotRest

        //Verifica se o resto de horas é maior que um dia.
        If nTempHr > _nTotRest

            //Disconta as horas do dia atual e valida o calculo dia dias de produção.
            _nSobra     := nTempHr - _nTotRest
            _nDias      := _nSobra / nTurno

            //Se qtd de dias que restou for maior que 1, irá calcular qts dias pra frente baseado em 8 hrs
            If _nDias > 1
                _cDataBKP   := DtoS(StoD(_cDataIni)+1)
                While _nSobra > 0 .AND. _nSobra > nTurno
                    _nSobra     := _nSobra - nTurno
                    _cDataBKP   := DtoS(StoD(_cDataBKP)+1)
                    Loop
                EndDo

                _cHrFim := IntToHora(HoraToInt('07:00')+_nSobra)

            Else
                _cDataBKP   := DtoS(StoD(_cDataIni)+1)
                _cHrFim     := IntToHora(HoraToInt('07:00')+_nSobra)
            EndIf

            _cDataFim := fDataFim(_cDataBKP,_nDias,_nSobra)


        Else
            _cDataFim   := _cDataIni
            _cDataFim   := fDataFim(_cDataFim)
            _cHrFim     := IntToHora(HoraToInt(_cHrIni)+nTempHr)
        EndIf

    EndIf


Return {_cDataIni,_cHrIni,_cDataFim,_cHrFim}



//-------------------------------------------------------------------
/*/{Protheus.doc} fDataFim

Calculo da data fim no grid.

@author  Rafael Pianezzer de Souza
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function fDataFim(_cDataBKP,_nDias,_nSobra)

    _cDataFim :=  DtoS(StoD(_cDataBKP))

    If Dow(StoD(_cDataFim)) == 7
        _cDataFim := DtoS(StoD(_cDataFim)+2)
    Elseif Dow(StoD(_cDataFim)) == 1
        _cDataFim := DtoS(StoD(_cDataFim)+1)
    EndIf

    _cDataBKP := _cDataFim

Return _cDataBKP



//-------------------------------------------------------------------
/*/{Protheus.doc} fGetTime

Função auxiliar para validar qual hora do dia representa hora produtiva

@author  Rafael Pianezzer de Souza
@since   30/7/21
@version version
/*/
//-------------------------------------------------------------------
Static Function fGetTime(cHora)

    Local nTime := 0

    If SubStr(cHora,1,2) == '07'
        nTime := 0
    ElseIf SubStr(cHora,1,2) == '08'
        nTime := 1
    ElseIf SubStr(cHora,1,2) == '09'
        nTime := 2
    ElseIf SubStr(cHora,1,2) == '10'
        nTime := 3
    ElseIf SubStr(cHora,1,2) == '11'
        nTime := 4
    ElseIf SubStr(cHora,1,2) == '13'
        nTime := 5
    ElseIf SubStr(cHora,1,2) == '14'
        nTime := 6
    ElseIf SubStr(cHora,1,2) == '15'
        nTime := 7
    ElseIf SubStr(cHora,1,2) == '16'
        nTime := 8
    ElseIf SubStr(cHora,1,2) == '17'
        nTime := 9
    ElseIf SubStr(cHora,1,2) == '18'
        nTime := 10
    EndIf

Return nTime


//-------------------------------------------------------------------
/*/{Protheus.doc} fConsSG2

Consulta para pegar Lead time do Recurso.

@author  Rafael Pianezzer de Souza
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function fConsSG2(cProduto, _cDepto)

    If Select('cAliasSG2')<> 0
        cAliasSG2->(DbCloseArea())
    EndIf

    BeginSql alias "cAliasSG2"
        SELECT *
        FROM
            SG2010 SG2
        WHERE
            SG2.G2_PRODUTO = %exp:cProduto%
            AND SG2.G2_DEPTO = %exp:_cDepto%
            AND SG2.%notDel%
            AND SG2.G2_CODIGO = (
                SELECT
                    MAX(G2_CODIGO)
                FROM
                    SG2010 SG2D
                WHERE
                    SG2D.G2_PRODUTO = %exp:cProduto%
                    AND SG2D.G2_DEPTO = %exp:_cDepto%
                    AND SG2D.%notDel%
            )
    EndSql

    If !cAliasSG2->(Eof())
        _nLeadTime := cAliasSG2->G2_LOTEPAD * cAliasSG2->G2_TEMPAD
    Else
        _nLeadTime := 0
    EndIf

Return _nLeadTime



//-------------------------------------------------------------------
/*/{Protheus.doc} fReordena

Função que realizará a ordenação do vetor da grid, recalculando todas as datas de inicio e fim, e suas respectivas hora inicio e final.

@author  Rafael Pianezzer de Souza
@since   30/7/21
@version version
/*/
//-------------------------------------------------------------------
Static Function fReordena(aVetPedCOM,nPos,cOrigem,xDado,cOp,cRetRec)

    Local aVetEdit      := {}
    Local aVetEdit2     := {}
    Local aVetAlter     := {}
    Local aVetAlter2    := {}
    Local aAux          := {}
    Local aVetPed       := aClone(aVetPedCOM)
    Local nX,nY
    Local nPosAnt       := 0
    Local cRecurso      := aVetPedCOM[oListCM:nAt,nPosRecur]
    Local aPos          := {}
    Local nMaxPos       := 1
    Local nMaxPrior     := 0



    If corigem == "PRIORIDADE"

        aVetPed     := aClone(aVetPedCOM)
        aVetEdit    :={}
        aVetEdit2   :={}
        aVetAlter   :={}
        aVetAlter2  :={}

        //Separa em 2 arrays o principal, e um do recurso que estamos querendo reordenar.
        For nX:=1 To Len(aVetPedCOM)
            If Alltrim(aVetPedCOM[nX,nPosRecur]) == Alltrim(cRecurso)
                Aadd(aVetAlter,aVetPed[nX])
                Aadd(aPos,nX)
            Else
                Aadd(aVetEdit2,aVetPed[nX])
            EndIf
        Next nX

        //Ordena o vetor filtrado com os recursos posicionando pela prioridade
        aSort(aVetAlter,,, { |x, y| x[nPriorida] < y[nPriorida] } )

        //Aumenta em 1 a prioridade para controle de reposicionamento.
        nPriorCnt := xDado+1

        //Percorre o array alterando as
        For nX:=1 To Len(aVetAlter)
            If xDado == aVetAlter[nX,nPriorida] .AND. aVetAlter[nX,nPosOP] <> cOp
                For nY:=nX To Len(aVetAlter)
                    aVetAlter[nY,nPriorida] := nPriorCnt
                    nPriorCnt++
                Next nY
            EndIf
        Next nX


        For nX:=1 To Len(aVetAlter)

            nPosIni := nX
            If nX == 1
                cHrProd := Round((aVetAlter[nPosIni,nPosProd]) / (aVetAlter[nPosIni,nPosPcsT]/nTurno),2)
                _cDtaBkp := fDataFim(DtoS(dDataBase))
                aRet := fGetDH(_cDtaBkp,cHrProd,nTurno,"07:00")
            Else
                nPosAnt := nX - 1
                cHrProd := Round((aVetAlter[nPosIni,nPosProd]) / (aVetAlter[nPosIni,nPosPcsT]/nTurno),2)
                aRet := fGetDH(DtoS(aVetEdit[nPosAnt,nPosDtEntr]),cHrProd,nTurno,aVetEdit[nPosAnt,nPosHrFim])
            EndIf

            Aadd(aVetEdit,{ aVetAlter[nPosIni,nPosOP],;
                aVetAlter[nPosIni,nPosCodP],;
                aVetAlter[nPosIni,nPosDescr],;
                aVetAlter[nPosIni,nPosQTD],;
                aVetAlter[nPosIni,nPosSLD],;
                aVetAlter[nPosIni,nPosProd],;
                aVetAlter[nPosIni,nPosPcsT],;
                aVetAlter[nPosIni,nPosLead],;
                aVetAlter[nPosIni,nPosRecur],;
                aVetAlter[nPosIni,nPriorida],;
                aVetAlter[nPosIni,nPosDUtil],;
                StoD(aRet[1]),;
                aRet[2],;
                StoD(aRet[3]),;
                aRet[4],;
                aVetAlter[nPosIni,nPosDtZA1],;
                aVetAlter[nPosIni,nPosRecZA],;
                aVetAlter[nPosIni,nPosDcZA1];
                })

        Next nX


        //Encontrar aonde estava a primeira posição do recurso alterado.
        nPosIni := 1
        For nX:=aPos[1] To Len(aVetPedCOM)
            If Alltrim(aVetPedCOM[nX,nPosRecur]) == Alltrim(cRecurso)
                aVetPedCOM[nX,nPosOP]           := aVetEdit[nPosIni,nPosOP]
                aVetPedCOM[nX,nPosCodP]         := aVetEdit[nPosIni,nPosCodP]
                aVetPedCOM[nX,nPosDescr]        := aVetEdit[nPosIni,nPosDescr]
                aVetPedCOM[nX,nPosQTD]          := aVetEdit[nPosIni,nPosQTD]
                aVetPedCOM[nX,nPosSLD]          := aVetEdit[nPosIni,nPosSLD]
                aVetPedCOM[nX,nPosProd]         := aVetEdit[nPosIni,nPosProd]
                aVetPedCOM[nX,nPosPcsT]         := aVetEdit[nPosIni,nPosPcsT]
                aVetPedCOM[nX,nPosLead]         := aVetEdit[nPosIni,nPosLead]
                aVetPedCOM[nX,nPosRecur]        := aVetEdit[nPosIni,nPosRecur]
                aVetPedCOM[nX,nPriorida]        := aVetEdit[nPosIni,nPriorida]
                aVetPedCOM[nX,nPosDUtil]        := aVetEdit[nPosIni,nPosDUtil]
                aVetPedCOM[nX,nPosDtIni]        := aVetEdit[nPosIni,nPosDtIni]
                aVetPedCOM[nX,nPosHrIni]        := aVetEdit[nPosIni,nPosHrIni]
                aVetPedCOM[nX,nPosDtEntr]       := aVetEdit[nPosIni,nPosDtEntr]
                aVetPedCOM[nX,nPosHrFim]        := aVetEdit[nPosIni,nPosHrFim]
                aVetPedCOM[nX,nPosDtZA1]        := aVetEdit[nPosIni,nPosDtZA1]
                aVetPedCOM[nX,nPosRecZA]        := aVetEdit[nPosIni,nPosRecZA]
                aVetPedCOM[nX,nPosDcZA1]        := aVetEdit[nPosIni,nPosDcZA1]
            EndIf

            nPosIni++
            //Se for a ultima posição do array de posições, ele sairá
            If aPos[Len(aPos)] == nX
                Exit
            EndIf

        Next nX

        aVetAlter := aClone(aVetPedCOM)

    ElseIf corigem == "PRODUZIR"


    ElseIf corigem == "RECURSO"

        aAux        := {}
        aVetPed     := aClone(aVetPedCOM)
        aVetEdit    :={}
        aVetEdit2   :={}
        aVetAlter   :={}
        aVetAlter2  :={}


        //Separa em 2 arrays o principal, e um do recurso que estamos querendo reordenar.
        For nX:=1 To Len(aVetPedCOM)
            If Alltrim(aVetPedCOM[nX,nPosRecur]) == Alltrim(cRetRec)
                nMaxPrior   := aVetPedCOM[nX,nPriorida]
                nMaxPos     := nX
            EndIf
        Next nX

        //Separa em 2 arrays o principal, e um do recurso que estamos querendo reordenar.
        For nX:=1 To Len(aVetPedCOM)
            If Alltrim(aVetPedCOM[nX,nPosOP]) == Alltrim(cOp)
                Aadd(aAux,aVetPedCOM[nX])
                nPosRemov := nX
            EndIf
        Next nX

        nMaxPos++

        //Separa em 2 arrays o principal, e um do recurso que estamos querendo reordenar.
        For nX:=1 To Len(aVetPedCOM)
            If  nX == nMaxPos
                Aadd(aVetAlter,{ aAux[1,nPosOP],;
                    aAux[1,nPosCodP],;
                    aAux[1,nPosDescr],;
                    aAux[1,nPosQTD],;
                    aAux[1,nPosSLD],;
                    aAux[1,nPosProd],;
                    aAux[1,nPosPcsT],;
                    aAux[1,nPosLead],;
                    cRetRec,;
                    nMaxPrior+1,;
                    aAux[1,nPosDUtil],;
                    aAux[1,nPosDtIni],;
                    aAux[1,nPosHrIni],;
                    aAux[1,nPosDtEntr],;
                    aAux[1,nPosHrFim],;
                    aAux[1,nPosDtZA1],;
                    aAux[1,nPosRecZA],;
                    aAux[1,nPosDcZA1];
                    })
            EndIf

            If nX <> nPosRemov
                Aadd(aVetAlter,aVetPedCOM[nX])
            EndIf

        Next nX

    EndIf


    aVetPedCOM  := {}
    aVetPedCOM  := aClone(aVetAlter)

    oListCM:bLine := NIL

    aVetPed     :={}
    aVetEdit    :={}

    //Atualiza a GRID com a nova ordenação.
    fMontGrid(aVetPedCOM)



Return .T.



//-------------------------------------------------------------------
/*/{Protheus.doc} fConsOps

Função responsável pela consulta das OPS em aberto para p departamento, após a consulta faz a montagem
em tela dos registros calculando data e hora

@author  Rafael Pianezzer de Souza
@since   30/7/21
@version version
/*/
//-------------------------------------------------------------------
Static Function fConsOps(cDepto)


    If Select("QRY") <> 0
        QRY->(dbCloseArea())
    EndIf

    BEGINSQL ALIAS "QRY"
        SELECT *
        FROM
            (
                SELECT
                    SC2.C2_NUM + SC2.C2_ITEM + SC2.C2_SEQUEN C2_NUM,
                    SC2.C2_PRODUTO,
                    SB1.B1_DESC,
                    SC2.C2_DATPRI,
                    SC2.C2_DATPRF,
                    SC2.C2_QUANT,
                    SC2.C2_QUJE,
                    SC2.C2_PERDA,
                    ISNULL(ZA1.ZA1_DTINIC, '') ZA1_DTINIC,
                    ISNULL(SH1APON.H1_CODIGO, '') H1_CODIGO,
                    ISNULL(SH1APON.H1_DESCRI, '') H1_DESCRI,
                    ISNULL(G2OPEAPON.G2_CODIGO, '') G2_CODIGO,
                    ISNULL(G2OPEAPON.G2_DESCRI, '') G2_DESCRI,
                    ISNULL(ZA1_HRINIC, '') ZA1_HRINIC,
                    CASE
                        WHEN G2OPEAPON.G2_OPERAC = '01'
                            THEN (
                            ISNULL(
                                SC2.C2_QUANT - (
                                    (
                                        SELECT
                                            SUM(H6_QTDPROD) H6_QTDPROD
                                        FROM
                                            %table:SH6% H6
                                        WHERE
                                            H6.H6_OP = SC2.C2_NUM + SC2.C2_ITEM + SC2.C2_SEQUEN
                                            AND H6.H6_OPERAC = '01'
                                            AND H6.%notDel%
                                    ) + (
                                        SELECT
                                            SUM(H6_QTDPERD) H6_QTDPERD
                                        FROM
                                            %table:SH6% H6
                                        WHERE
                                            H6.H6_OP = SC2.C2_NUM + SC2.C2_ITEM + SC2.C2_SEQUEN
                                            AND H6.H6_OPERAC = '01'
                                            AND H6.%notDel%
                                    )
                                ),
                                SC2.C2_QUANT
                            )
                        )
                        ELSE (
                            SC2.C2_QUANT - (
                                (
                                    SELECT
                                        ISNULL(SUM(H6_QTDPROD), 0) H6_QTDPROD
                                    FROM
                                        %table:SH6% SH6ATU (NOLOCK)
                                    WHERE
                                        SH6ATU.H6_FILIAL = '0101'
                                        AND SH6ATU.H6_PRODUTO = SC2.C2_PRODUTO
                                        AND SH6ATU.H6_OP = SC2.C2_NUM + SC2.C2_ITEM + SC2.C2_SEQUEN
                                        AND SH6ATU.H6_OPERAC = SG2.G2_OPERAC
                                        AND SH6ATU.H6_QTDPROD > 0
                                        AND SH6ATU.D_E_L_E_T_ = ''
                                ) + (
                                    SELECT
                                        ISNULL(SUM(H6_QTDPERD), 0) H6_QTDPERD
                                    FROM
                                        %table:SH6% SH6ATU (NOLOCK)
                                    WHERE
                                        SH6ATU.H6_FILIAL = '0101'
                                        AND SH6ATU.H6_PRODUTO = SC2.C2_PRODUTO
                                        AND SH6ATU.H6_OP = SC2.C2_NUM + SC2.C2_ITEM + SC2.C2_SEQUEN
                                        AND SH6ATU.H6_OPERAC = SG2.G2_OPERAC
                                        AND SH6ATU.H6_QTDPERD > 0
                                        AND SH6ATU.D_E_L_E_T_ = ''
                                )
                            )
                        )
                    END AS SALDO,
                    SG2.G2_DEPTO,
                    SG2.G2_LOTEPAD,
                    SG2.G2_TEMPAD,
                    (SG2.G2_LOTEPAD * SG2.G2_TEMPAD) LEAD_TIME,
                    SG2.G2_MAOOBRA,
                    SG2.G2_RECURSO,
                    SG2.G2_SETUP,
                    //ISNULL(ZA3_PRIORI, 3) ZA3_PRIORI
                    CASE
                        WHEN ZA1_DTINIC IS NOT NULL
                            THEN '1'
                        ELSE ISNULL(ZA3_PRIORI, 3)
                    END ZA3_PRIORI
                FROM
                    %table:SC2% SC2 (NOLOCK)
                INNER JOIN SB1010 SB1 (NOLOCK)
                ON (
                        B1_FILIAL = SC2.C2_FILIAL
                        AND SC2.C2_PRODUTO = B1_COD
                        AND SB1.D_E_L_E_T_ = ''
                    )
                LEFT JOIN %table:ZA1% ZA1 (NOLOCK)
                ON (
                        ZA1_FILIAL = SC2.C2_FILIAL
                        AND ZA1_OP = SC2.C2_NUM + SC2.C2_ITEM + SC2.C2_SEQUEN
                        AND ZA1_DTFIM = ''
                        AND ZA1.ZA1_DEPTO = %exp:cDepto%
                        AND ZA1.D_E_L_E_T_ = ''
                    )
                LEFT JOIN %table:SH1% SH1APON (NOLOCK)
                ON (
                        SH1APON.H1_FILIAL = SC2.C2_FILIAL
                        AND SH1APON.H1_CODIGO = ZA1.ZA1_RECURS
                        AND SH1APON.D_E_L_E_T_ = ''
                    )
                LEFT JOIN %table:SG2% G2OPEAPON (NOLOCK)
                ON (
                        G2OPEAPON.G2_FILIAL = SC2.C2_FILIAL
                        AND G2OPEAPON.G2_CODIGO = SB1.B1_OPERPAD
                        AND G2OPEAPON.G2_PRODUTO = SC2.C2_PRODUTO
                        AND G2OPEAPON.G2_OPERAC = ZA1.ZA1_OPERAC
                        AND G2OPEAPON.G2_DEPTO = %exp:cDepto%
                        AND G2OPEAPON.D_E_L_E_T_ = ''
                    )
                LEFT JOIN %table:SG2% SG2 (NOLOCK)
                ON (
                        SG2.G2_FILIAL = SC2.C2_FILIAL
                        AND SG2.G2_CODIGO = (
                            SELECT
                                MAX(G2_CODIGO)
                            FROM
                                SG2010 SG2D
                            WHERE
                                SG2D.G2_PRODUTO = SC2.C2_PRODUTO
                                AND SG2D.G2_DEPTO = %exp:cDepto%
                                AND SG2D.%notDel%
                        )
                        AND SG2.G2_PRODUTO = SC2.C2_PRODUTO
                        AND SG2.D_E_L_E_T_ = ''
                    )
                LEFT JOIN %table:ZA3% ZA3 (NOLOCK)
                ON (
                        ZA3_FILIAL = ''
                        AND ZA3_OP = SC2.C2_NUM + SC2.C2_ITEM + SC2.C2_SEQUEN
                        AND ZA3_DEPTO = SG2.G2_DEPTO
                        AND ZA3.D_E_L_E_T_ = ''
                    )
                WHERE
                    SC2.C2_FILIAL = '0101'
                    AND SC2.C2_QUANT > SC2.C2_QUJE
                    AND SC2.C2_DATRF = ''
                    AND SC2.D_E_L_E_T_ = ''
                    AND SC2.C2_TPOP = 'F'
                    AND SG2.G2_DEPTO = %exp:cDepto%
                GROUP BY
                    SC2.C2_NUM,
                    SC2.C2_ITEM,
                    SC2.C2_SEQUEN,
                    SC2.C2_PRODUTO,
                    SB1.B1_DESC,
                    SC2.C2_DATPRI,
                    SC2.C2_DATPRF,
                    SC2.C2_QUANT,
                    SC2.C2_QUJE,
                    SC2.C2_PERDA,
                    ZA1.ZA1_DTINIC,
                    SH1APON.H1_CODIGO,
                    SH1APON.H1_DESCRI,
                    SG2.G2_OPERAC,
                    G2OPEAPON.G2_CODIGO,
                    G2OPEAPON.G2_DESCRI,
                    SG2.G2_DEPTO,
                    SG2.G2_LOTEPAD,
                    SG2.G2_MAOOBRA,
                    SG2.G2_RECURSO,
                    SG2.G2_TEMPAD,
                    ZA3_PRIORI,
                    ZA1_HRINIC,
                    SG2.G2_SETUP,
                    G2OPEAPON.G2_OPERAC
            ) A
        WHERE
            A.SALDO > 0
        ORDER BY
            A.G2_RECURSO
    ENDSQL

Return


//-------------------------------------------------------------------
/*/{Protheus.doc} fConsSave

Função responsável pela consulta das OPS salvas no deparmento.

@author  Rafael Pianezzer de Souza
@since   30/7/21
@version version
/*/
//-------------------------------------------------------------------
Static Function fConsSave(cDepto)


    If Select("QRY") <> 0
        QRY->(dbCloseArea())
    EndIf

    BEGINSQL ALIAS "QRY"
        SELECT *
        FROM
            (
                SELECT
                    ZA9_OP,
                    ZA9_PRODUT,
                    ZA9_SALDO,
                    ZA9_QTDPRO,
                    ZA9_DIASPR,
                    ZA9_RECURS,
                    ZA9_PRIORI,
                    ZA9_DIASIM,
                    ZA9_DTAINI,
                    ZA9_HRINIC,
                    ZA9_DTAFIM,
                    ZA9_HRFIM,
                    ZA9_DEPTO,
                    ISNULL(ZA1.ZA1_DTINIC, '') ZA1_DTINIC,
                    ISNULL(SH1APON.H1_CODIGO, '') H1_CODIGO,
                    ISNULL(SH1APON.H1_DESCRI, '') H1_DESCRI,
                    CASE
                        WHEN G2OPEAPON.G2_OPERAC = '01'
                            THEN (
                            ISNULL(
                                SC2.C2_QUANT - (
                                    (
                                        SELECT
                                            SUM(H6_QTDPROD) H6_QTDPROD
                                        FROM
                                            %table:SH6% H6
                                        WHERE
                                            H6.H6_OP = ZA9_OP
                                            AND H6.H6_OPERAC = '01'
                                            AND H6.%notDel%
                                    ) + (
                                        SELECT
                                            SUM(H6_QTDPERD) H6_QTDPERD
                                        FROM
                                            %table:SH6% H6
                                        WHERE
                                            H6.H6_OP = ZA9_OP
                                            AND H6.H6_OPERAC = '01'
                                            AND H6.%notDel%
                                    )
                                ),
                                SC2.C2_QUANT
                            )
                        )
                        ELSE (
                            SC2.C2_QUANT - (
                                (
                                    SELECT
                                        ISNULL(SUM(H6_QTDPROD), 0) H6_QTDPROD
                                    FROM
                                        SH6010 SH6ATU (NOLOCK)
                                    WHERE
                                        SH6ATU.H6_FILIAL = %xFilial:SH6%
                                        AND SH6ATU.H6_PRODUTO = SC2.C2_PRODUTO
                                        AND SH6ATU.H6_OP = SC2.C2_NUM + SC2.C2_ITEM + SC2.C2_SEQUEN
                                        AND SH6ATU.H6_OPERAC = G2OPEAPON.G2_OPERAC
                                        AND SH6ATU.H6_QTDPROD > 0
                                        AND SH6ATU.%notDel%
                                ) + (
                                    SELECT
                                        ISNULL(SUM(H6_QTDPERD), 0) H6_QTDPERD
                                    FROM
                                        SH6010 SH6ATU (NOLOCK)
                                    WHERE
                                        SH6ATU.H6_FILIAL = %xFilial:SH6%
                                        AND SH6ATU.H6_PRODUTO = SC2.C2_PRODUTO
                                        AND SH6ATU.H6_OP = SC2.C2_NUM + SC2.C2_ITEM + SC2.C2_SEQUEN
                                        AND SH6ATU.H6_OPERAC = G2OPEAPON.G2_OPERAC
                                        AND SH6ATU.H6_QTDPERD > 0
                                        AND SH6ATU.%notDel%
                                )
                            )
                        )
                    END AS SALDO
                FROM
                    %table:ZA9% ZA9
                INNER JOIN %table:SB1% SB1 (NOLOCK)
                ON (
                        B1_FILIAL = %xFilial:SB1%
                        AND ZA9_PRODUT = B1_COD
                        AND SB1.%notDel%
                    )
                INNER JOIN %table:SC2% SC2
                ON (
                        C2_FILIAL = %xFilial:SC2%
                        AND C2_NUM + C2_ITEM + C2_SEQUEN = ZA9_OP
                        AND C2_QUANT > C2_QUJE
                        AND C2_DATRF = ' '
                        AND SC2.%notDel%
                    )
                INNER JOIN %table:SG2% G2OPEAPON (NOLOCK)
                ON (
                        G2OPEAPON.G2_FILIAL = SC2.C2_FILIAL
                        AND G2OPEAPON.G2_CODIGO = SB1.B1_OPERPAD
                        AND G2OPEAPON.G2_PRODUTO = SC2.C2_PRODUTO
                        AND G2OPEAPON.G2_DEPTO = %exp:cDepto%
                        AND G2OPEAPON.%notDel%
                    )
                LEFT JOIN %table:ZA1% ZA1 (NOLOCK)
                ON (
                        ZA1_FILIAL = SC2.C2_FILIAL
                        AND ZA1_OP = SC2.C2_NUM + SC2.C2_ITEM + SC2.C2_SEQUEN
                        AND ZA1_DTFIM = ''
                        AND ZA1.ZA1_DEPTO = %exp:cDepto%
                        AND ZA1.%notDel%
                    )
                LEFT JOIN %table:SH1% SH1APON (NOLOCK)
                ON (
                        SH1APON.H1_FILIAL = SC2.C2_FILIAL
                        AND SH1APON.H1_CODIGO = ZA1.ZA1_RECURS
                        AND SH1APON.%notDel%
                    )
                WHERE
                    ZA9_FILIAL = ' '
                    AND ZA9_DEPTO = %exp:cDepto%
                    AND ZA9.%notDel% //AND ZA9_OP = '26305701001'
            ) A
        WHERE
            A.SALDO > 0
        ORDER BY
            ZA9_RECURS,
            ZA9_PRIORI
    EndSql


Return



//-------------------------------------------------------------------
/*/{Protheus.doc} fDifZA9XOP

Função responsável pela consulta das OPS salvas no deparmento.

@author  Rafael Pianezzer de Souza
@since   30/7/21
@version version
/*/
//-------------------------------------------------------------------
Static Function fDifZA9XOP(cDepto)


    If Select("DIFZA9") <> 0
        DIFZA9->(dbCloseArea())
    EndIf

    BEGINSQL ALIAS "DIFZA9"
        SELECT *
        FROM
            (
                SELECT
                    SC2.C2_NUM + SC2.C2_ITEM + SC2.C2_SEQUEN C2_NUM,
                    SC2.C2_PRODUTO,
                    SB1.B1_DESC,
                    SC2.C2_DATPRI,
                    SC2.C2_DATPRF,
                    SC2.C2_QUANT,
                    SC2.C2_QUJE,
                    SC2.C2_PERDA,
                    ISNULL(ZA1.ZA1_DTINIC, '') ZA1_DTINIC,
                    ISNULL(SH1APON.H1_CODIGO, '') H1_CODIGO,
                    ISNULL(SH1APON.H1_DESCRI, '') H1_DESCRI,
                    ISNULL(G2OPEAPON.G2_CODIGO, '') G2_CODIGO,
                    ISNULL(G2OPEAPON.G2_DESCRI, '') G2_DESCRI,
                    ISNULL(ZA1_HRINIC, '') ZA1_HRINIC,
                    CASE
                        WHEN G2OPEAPON.G2_OPERAC = '01'
                            THEN (
                            ISNULL(
                                C2_QUANT - (
                                    (
                                        SELECT
                                            SUM(H6_QTDPROD) H6_QTDPROD
                                        FROM
                                            %table:SH6% H6
                                        WHERE
                                            H6.H6_OP = C2_NUM + C2_ITEM + C2_SEQUEN
                                            AND H6.H6_OPERAC = '01'
                                            AND H6.%notDel%
                                    ) + (
                                        SELECT
                                            SUM(H6_QTDPERD) H6_QTDPERD
                                        FROM
                                            %table:SH6% H6
                                        WHERE
                                            H6.H6_OP = C2_NUM + C2_ITEM + C2_SEQUEN
                                            AND H6.H6_OPERAC = '01'
                                            AND H6.%notDel%
                                    )
                                ),
                                SC2.C2_QUANT
                            )
                        )
                        ELSE (
                            SC2.C2_QUANT - (
                                (
                                    SELECT
                                        ISNULL(SUM(H6_QTDPROD), 0) H6_QTDPROD
                                    FROM
                                        %table:SH6% SH6ATU (NOLOCK)
                                    WHERE
                                        SH6ATU.H6_FILIAL = %xFilial:SH6%
                                        AND SH6ATU.H6_PRODUTO = SC2.C2_PRODUTO
                                        AND SH6ATU.H6_OP = SC2.C2_NUM + SC2.C2_ITEM + SC2.C2_SEQUEN
                                        AND SH6ATU.H6_OPERAC = SG2.G2_OPERAC
                                        AND SH6ATU.H6_QTDPROD > 0
                                        AND SH6ATU.D_E_L_E_T_ = ''
                                ) + (
                                    SELECT
                                        ISNULL(SUM(H6_QTDPERD), 0) H6_QTDPERD
                                    FROM
                                        %table:SH6% SH6ATU (NOLOCK)
                                    WHERE
                                        SH6ATU.H6_FILIAL = %xFilial:SH6%
                                        AND SH6ATU.H6_PRODUTO = SC2.C2_PRODUTO
                                        AND SH6ATU.H6_OP = SC2.C2_NUM + SC2.C2_ITEM + SC2.C2_SEQUEN
                                        AND SH6ATU.H6_OPERAC = SG2.G2_OPERAC
                                        AND SH6ATU.H6_QTDPERD > 0
                                        AND SH6ATU.D_E_L_E_T_ = ''
                                )
                            )
                        )
                    END AS SALDO,
                    SG2.G2_DEPTO,
                    SG2.G2_LOTEPAD,
                    SG2.G2_TEMPAD,
                    (SG2.G2_LOTEPAD * SG2.G2_TEMPAD) LEAD_TIME,
                    SG2.G2_MAOOBRA,
                    SG2.G2_RECURSO,
                    SG2.G2_SETUP,
                    CASE
                        WHEN ZA1_DTINIC IS NOT NULL
                            THEN '1'
                        ELSE ISNULL(ZA3_PRIORI, 3)
                    END ZA3_PRIORI
                FROM
                    %table:SC2% SC2 (NOLOCK)
                INNER JOIN SB1010 SB1 (NOLOCK)
                ON (
                        B1_FILIAL = SC2.C2_FILIAL
                        AND SC2.C2_PRODUTO = B1_COD
                        AND SB1.D_E_L_E_T_ = ''
                    )
                LEFT JOIN %table:ZA1% ZA1 (NOLOCK)
                ON (
                        ZA1_FILIAL = SC2.C2_FILIAL
                        AND ZA1_OP = SC2.C2_NUM + SC2.C2_ITEM + SC2.C2_SEQUEN
                        AND ZA1_DTFIM = ''
                        AND ZA1.ZA1_DEPTO = %exp:cDepto%
                        AND ZA1.D_E_L_E_T_ = ''
                    )
                LEFT JOIN %table:SH1% SH1APON (NOLOCK)
                ON (
                        SH1APON.H1_FILIAL = SC2.C2_FILIAL
                        AND SH1APON.H1_CODIGO = ZA1.ZA1_RECURS
                        AND SH1APON.D_E_L_E_T_ = ''
                    )
                LEFT JOIN %table:SG2% G2OPEAPON (NOLOCK)
                ON (
                        G2OPEAPON.G2_FILIAL = SC2.C2_FILIAL
                        AND G2OPEAPON.G2_CODIGO = SB1.B1_OPERPAD
                        AND G2OPEAPON.G2_PRODUTO = SC2.C2_PRODUTO
                        AND G2OPEAPON.G2_OPERAC = ZA1.ZA1_OPERAC
                        AND G2OPEAPON.G2_DEPTO = %exp:cDepto%
                        AND G2OPEAPON.D_E_L_E_T_ = ''
                    )
                LEFT JOIN %table:SG2% SG2 (NOLOCK)
                ON (
                        SG2.G2_FILIAL = SC2.C2_FILIAL
                        AND SG2.G2_CODIGO = (
                            SELECT
                                MAX(G2_CODIGO)
                            FROM
                                SG2010 SG2D
                            WHERE
                                SG2D.G2_PRODUTO = SC2.C2_PRODUTO
                                AND SG2D.G2_DEPTO = %exp:cDepto%
                                AND SG2D.%notDel%
                        )
                        AND SG2.G2_PRODUTO = SC2.C2_PRODUTO
                        AND SG2.D_E_L_E_T_ = ''
                    )
                LEFT JOIN %table:ZA3% ZA3 (NOLOCK)
                ON (
                        ZA3_FILIAL = ''
                        AND ZA3_OP = SC2.C2_NUM + SC2.C2_ITEM + SC2.C2_SEQUEN
                        AND ZA3_DEPTO = SG2.G2_DEPTO
                        AND ZA3.D_E_L_E_T_ = ''
                    )
                WHERE
                    SC2.C2_FILIAL = %xFilial:SC2%
                    AND SC2.C2_QUANT > SC2.C2_QUJE
                    AND SC2.C2_DATRF = ''
                    AND SC2.D_E_L_E_T_ = ''
                    AND SC2.C2_TPOP = 'F'
                    AND SG2.G2_DEPTO = %exp:cDepto%
                    AND NOT EXISTS(
                        SELECT *
                        FROM
                            %table:ZA9% ZA9
                        WHERE
                            ZA9_FILIAL = ''
                            AND ZA9_DEPTO = %exp:cDepto%
                            AND ZA9_OP = C2_NUM + C2_ITEM + C2_SEQUEN
                            AND ZA9.%notDel%
                    )
                GROUP BY
                    SC2.C2_NUM,
                    SC2.C2_ITEM,
                    SC2.C2_SEQUEN,
                    SC2.C2_PRODUTO,
                    SB1.B1_DESC,
                    SC2.C2_DATPRI,
                    SC2.C2_DATPRF,
                    SC2.C2_QUANT,
                    SC2.C2_QUJE,
                    SC2.C2_PERDA,
                    ZA1.ZA1_DTINIC,
                    SH1APON.H1_CODIGO,
                    SH1APON.H1_DESCRI,
                    SG2.G2_OPERAC,
                    G2OPEAPON.G2_CODIGO,
                    G2OPEAPON.G2_DESCRI,
                    SG2.G2_DEPTO,
                    SG2.G2_LOTEPAD,
                    SG2.G2_MAOOBRA,
                    SG2.G2_RECURSO,
                    SG2.G2_TEMPAD,
                    ZA3_PRIORI,
                    ZA1_HRINIC,
                    SG2.G2_SETUP,
                    G2OPEAPON.G2_OPERAC
            ) A
        WHERE
            A.SALDO > 0
        ORDER BY
            A.G2_RECURSO
    EndSql

Return


//-------------------------------------------------------------------
/*/{Protheus.doc} fMontaOPS

Faz a montagem das OPS novas.

@author  Rafael Pianezzer de Souza
@since   30/7/21
@version version
/*/
//-------------------------------------------------------------------
Static Function fMontaOPS(cDepto)

    Local cRecBkp       :=  ""
    Local nPrior        :=  1

    //Realiza a consulta na query
    fConsOps(cDepto)

    If !QRY->(Eof())
        While !QRY->(Eof())

            If Alltrim(cRecBkp) == Alltrim(QRY->G2_RECURSO)
                lSame := .T.
                nPrior++
            Else
                lSame := .F.
                cDtaHrBkp := ""
                nPrior := 1

                cDtaBkp := DTOS(dDataBase)
                cDtaBkp := fDataFim(cDtaBkp)

            Endif

            //Adiciona no array aVetPedCOM
            AdicVetCom(@aVetPedCOM,"QRY",.F.,lSame,nPrior,lRet)
            dbSelectArea("QRY")
            cRecBkp := QRY->G2_RECURSO
            cDtaBkp := cDataFim
            cDtaHrBkp := cHrFim

            QRY->(dbSkip())

        EndDo
    EndIf

Return


//-------------------------------------------------------------------
/*/{Protheus.doc} fGetMaxPos

Pega a posição do registro no array

@author  Rafael Pianezzer de Souza
@since   30/7/21
@version version
/*/
//-------------------------------------------------------------------
Static Function fGetMaxPos(aAux1,cRecurso)
    Local nPos := 0
    Local nX

    For nX:=1 To Len(aAux1)
        If Alltrim(cRecurso) == Alltrim(aAux1[nX,nPosRecur])
            nPos := nX
        EndIf
    Next nX

Return nPos



//-------------------------------------------------------------------
/*/{Protheus.doc} fConsZA1

Consulta as OPS apontadas na hora da execução do simulador do carga maquina

@author  Rafael Pianezzer de Souza
@since   30/7/21
@version version
/*/
//-------------------------------------------------------------------
Static Function fConsZA1(cOP,cDepto)


    If Select('APONTADO')<>0
        APONTADO->(DBCloseArea())
    EndIf

    BeginSql alias 'APONTADO'
        SELECT
            ZA1_DTINIC,
            ZA1_RECURS,
            H1_DESCRI
        FROM
            %table:ZA1% ZA1
        INNER JOIN SH1010 SH1
        ON (
                H1_FILIAL = '0101'
                AND H1_CODIGO = ZA1_RECURS
                AND SH1.%notDel%
            )
        WHERE
            ZA1_OP = %exp:cOP%
            AND ZA1_DTFIM = ''
            AND ZA1_DEPTO = %exp:cDepto%
            AND ZA1.%notDel%
    EndSql


Return {APONTADO->ZA1_DTINIC,APONTADO->ZA1_RECURS,APONTADO->H1_DESCRI}



//-------------------------------------------------------------------
/*/{Protheus.doc} fOrdemRec

Função que ordenará os recursos alterados depois da visão salva

@author  Rafael Pianezzer de Souza
@since   10/8/21
@version version
/*/
//-------------------------------------------------------------------
Static Function fOrdemRec(aVetZA9,aReorRec,nPos)

    Local nX
    Local cAddRec       := ""
    Local cRecAnt       := ""
    Local cOp           := ""

    aVetBkpZA9 := {}

    cAddRec := aReorRec[nPos,1,nPosRecur]
    cRecAnt := aReorRec[nPos,2]
    cOp     := aReorRec[nPos,1,nPosOP]
    nSaldo  := aReorRec[nPos,1,nPosProd]
    nLeadT  := aReorRec[nPos,1,nPosPcsT]
    nPosBKP := nPos  //Bkp da posição do item a ajustar

    For nX:=1 To Len(aVetZA9)
        If Alltrim(aVetZA9[nX,nPosRecur]) == Alltrim(cAddRec) .AND. Alltrim(aVetZA9[nX,nPosOP]) <> Alltrim(cOp)
            nPos    := nX
            nPosAnt := nX - 1
            nPrior  := aVetZA9[nPos,nPriorida]
        EndIf
    Next nX

    cHrProd := Round((nSaldo / (nLeadT/8)),2)
    aRet    := fGetDH(DtoS(aVetZA9[nPosAnt,nPosDtEntr]),cHrProd,(nTurno),aVetZA9[nPosAnt,nPosHrFim])

    //Soma 1 na prioridade
    nPrior++
    nPosDado := nPos

    //Soma 1 na próxima posição.
    nPos++

    //Adiciona mais um item no array
    Aadd(aVetZA9,NIL)

    //Adiciona na posição especifica, empurrando pra baixo o resto do array
    AINS(aVetZA9,nPos)

    Aadd(aVetBkpZA9,{ aReorRec[nPosBKP,1,nPosOP],;
        aReorRec[nPosBKP,1,nPosCodP],;
        aReorRec[nPosBKP,1,nPosDescr],;
        aReorRec[nPosBKP,1,nPosQTD],;
        aReorRec[nPosBKP,1,nPosSLD],;
        aReorRec[nPosBKP,1,nPosProd],;
        aReorRec[nPosBKP,1,nPosPcsT],;
        aReorRec[nPosBKP,1,nPosLead] ,;
        cAddRec,;
        nPrior,;
        nDias,;
        StoD(aRet[1]),;
        aRet[2],;
        StoD(aRet[3]),;
        aRet[4],;
        (aReorRec[nPosBKP,1,nPosDtZA1]),;
        aReorRec[nPosBKP,1,nPosRecZA],;
        aReorRec[nPosBKP,1,nPosDcZA1];
        })

    aVetZA9[nPos] := aVetBkpZA9[1]

    For nX:=1 To Len(aVetZA9)

        If nX > 1
            cRecAnt := Alltrim(aVetZA9[nX-1,nPosRecur])
        Else
            cRecAnt := Alltrim(aVetZA9[nX,nPosRecur])
        EndIf

        If Alltrim(aVetZA9[nX,nPosOP]) == Alltrim(cOp) .AND.  Alltrim(cRecAnt) == Alltrim(cRecAnt) .AND. nPos <> nX
            aDel(aVetZA9,nX)
            aSize(aVetZA9,Len(aVetZA9)-1)
            Exit
        EndIf
    Next nX


Return


//-------------------------------------------------------------------
/*/{Protheus.doc} RtPanelH


@author  Rafael Pianezzer de Souza
@since   30/7/21
@version version
/*/
//-------------------------------------------------------------------
User Function RtPanelH(cTitulo,oCtrl,nHeight)
    Local	oRet	as object
    Local	cStylePanel	as character
    Local	cLogo		as character
    Local	cColor		as character
    Local	oFontTitulo	as object
    Default	cTitulo		:= ""
    Default	nHeight		:= 040
    Private oButHlp

    //Inicializa as variáveis necessárias
    oFontTitulo	:= TFont():New("san serif",,-25,.T.,.T.)
    cLogo		:= "\logo\" + cEmpAnt + ".bmp"

    //Verifica a cor para a empresa
    Do Case
        Case cEmpAnt == "09"
            cColor	:= "#2E2E2E"
        Otherwise
            cColor	:= "#0B173B"
    EndCase

    //Estilo css
    cStylePanel	:= "QFrame{border-radius:0px; border-style:solid; border-right:5px;"
    cStylePanel	+= "border-left:5px; border-color:" + cColor
    cStylePanel += " ;background-color:" + cColor  + "}"

    //Painel prinicipal
    oRet := tPanelCss() :New(000,000,nil,oCtrl,nil,nil,nil,nil,nil,000,nHeight,nil,nil)
    oRet:setCss(cStylePanel)

    //Título

    If ! Empty(AllTrim(cTitulo))
        TSay():New(010,090,bSetGet(cTitulo),oRet,,oFontTitulo,.F.,.F.,.F.,.T.,CLR_WHITE,,400,120,.F.,.F.,.F.,.F.,.F.)
    EndIf

    oRet:Align := CONTROL_ALIGN_TOP

Return	oRet


//Inicio da rotina de impressão da tela de apont. da OP
User Function fImpGrid()

    Local aAreaAnt := GetArea()
    Local oReport:= nil

    //Executa as ações
    oReport := reportDef()
    oReport:printDialog()
    RestArea(aAreaAnt)
Return




Static Function sfCarrega(cOrigem)

    Local oFile         := NIL
    Local nCount        := 1
    Local cEEVC         := "002"
    Local cEEVD         := "00"
    Local cEEFI         := "030"
    Local cEmissao      := ""
    Local cSeqArq       := ""


   //Cria o Objeto do arquivo selecionado 
   oFile := FWFileReader():New(cArqImp)

	If oFile:Open()
		While oFile:Eof()
			cLinha := oFile:GetLine()

            If nCount == 1
                If  (SubStr(cLinha,1,3) <> cEEVC .AND. cOrigem == 'EEVC') .OR.; 
                    (SubStr(cLinha,1,2) <> cEEVD .AND. cOrigem == 'EEVD') .OR.;
                    (SubStr(cLinha,1,3) <> cEEVD .AND. cOrigem == 'EEFI')
                        MsgStop("Você selecionou um arquivo inválido, favor verificar.",FunName())           
                        Return .F.    
                EndIf
            
			cEmissao    := Substr(cLinha,4,2)+"/"+Substr(cLinha,6,2)+"/"+Substr(cLinha,8,4)
			cSeqArq     := Substr(cLinha,072,6)
			
            EndIf

            If cOrigem == 'EEVC'
                If SubStr(cLinha,1,3) == '005'

                Else
                
                EndIf
            ElseIf cOrigem == 'EEVD'
            ElseIf cOrigem == 'EEFI'

            EndIf
			

        nCount++
		EndDo

		oFile:Close()
		

	Else
		MsgStop("Não foi possível abrir o arquivo : ERRO "+Str(fError(),4),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
	EndIf

Return


