#INCLUDE "PROTHEUS.CH"
#include "rwmake.ch"
#Include 'topconn.ch'

/*/{Protheus.doc} BFFATA21
//Rotina de reimpressão de etiquetas
@author Marcelo Alberto Lauschner
@since 30/05/2018
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function BFFATA21()

	If cEmpAnt == "05"
		sfReimpFZ()
	Else
		sfReImp()
	Endif
Return 

/*/{Protheus.doc} sfReimp
//Reimpressão de etiquetas Atrialub
@author Marcelo Alberto Lauschner
@since 30/05/2018
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
Static Function sfReimp()

	Local	cQry		:= ""
	Local	aEtiqueta	:= {}
	Private cBox    	:= Space(2)
	Private cSep   		:= Space(1)
	Private cMesa   	:= Space(1)
	Private cConf   	:= Space(1)

	If CB7->CB7_VOLEMI == "1" .And. !Empty(CB7->CB7_CODOPE)
		If !MsgYesNo("Já foram emitidas etiquetas para esta ordem de separação. Deseja reimprimir?","Etiquetas já emitidas")
			Return
		Endif
	Endif
    
// Se não houve 
	If Empty(CB7->CB7_CODOPE) .And. CB7->CB7_VOLEMI # "1"
		MsgAlert("Este pedido não foi separado por Coletor para poder imprimir etiquetas por esta rotina!","Rotina não autorizada")
		Return
	Endif

	cQry := "SELECT CB8_PROD,SUM(CB8_QTDORI-CB8_QTECAN) QTE"
	cQry += "  FROM "+RetSqlName("CB8") +  " CB8 "
	cQry += " WHERE D_E_L_E_T_ = ' ' "
	cQry += "   AND CB8_ORDSEP = '"+CB7->CB7_ORDSEP+"' "
	cQry += "   AND CB8_FILIAL = '"+xFilial("CB8")+"' "
	cQry += " GROUP BY CB8_PROD "

	TcQuery cQry New Alias "QCB8"

	While !Eof()
	
		DbSelectArea("SB1")
		DbSetOrder(1)
		DbSeek(xFilial("SB1")+QCB8->CB8_PROD)
	
		If SB1->B1_MIUD == "N" .And. ((QCB8->QTE / IIf(SB1->B1_CONVB==0,1,SB1->B1_CONVB)) >= 1)
			AADD(aEtiqueta,{ ;
				CB7->CB7_CLIENTE,;
				CB7->CB7_LOJA,;
				QCB8->CB8_PROD,;
				((QCB8->QTE-Mod(QCB8->QTE,IIf(SB1->B1_CONVB==0,1,SB1->B1_CONVB)))/IIf(SB1->B1_CONVB==0,1,SB1->B1_CONVB)),;
				CB7->CB7_PEDIDO,;
				"Endereco: "+SB1->B1_LOCAL,;
				QCB8->QTE-Mod(QCB8->QTE,IIf(SB1->B1_CONVB==0,1,SB1->B1_CONVB))})
			DbSelectArea("CB6")
			DbSetOrder(2)
			If !DbSeek(xFilial("CB6")+CB7->CB7_PEDIDO+QCB8->CB8_PROD)
				cCodVol := GetSX8Num("CB6","CB6_VOLUME")
				ConfirmSX8()
		
				RecLock("CB6",.T.)
				CB6->CB6_FILIAL	:= xFilial("CB6")
				CB6->CB6_VOLUME	:= cCodVol
				CB6->CB6_PEDIDO	:= CB7->CB7_PEDIDO
				CB6->CB6_TIPVOL	:= "CXS"
				CB6->CB6_STATUS	:= "2"
				CB6->CB6_LOCALI	:= QCB8->CB8_PROD
				MsUnlock()
			Endif
		Endif
		DbSelectArea("QCB8")
		DbSkip()
	Enddo
	QCB8->(DbCloseArea())

	cQry := "SELECT COUNT(*) QTEDIV"
	cQry += "  FROM "+RetSqlName("CB6")
	cQry += " WHERE D_E_L_E_T_ = ' ' "
	cQry += "   AND CB6_PEDIDO = '"+CB7->CB7_PEDIDO+"' "
	cQry += "   AND CB6_STATUS IN('1','3') "
	cQry += "   AND CB6_TIPVOL = 'DIV' "
	cQry += "   AND CB6_FILIAL = '"+xFilial("CB6")+"' "

	TcQuery cQry New Alias "QCB6"

	nDiversos := QCB6->QTEDIV

	QCB6->(DbCloseArea())
	
	DbSelectArea("SC5")
	DbSetOrder(1)
	DbSeek(xFilial("SC5")+CB7->CB7_PEDIDO)
//C5_ESPECI2	:= cBox+cSep+cMesa+cConf  
//                 12   3    4     5  
	cBox	:=  Substr(CB7->CB7_PRESEP,1,2)
	cSep	:=	Substr(CB7->CB7_PRESEP,3,1)
	cMesa	:=  Substr(CB7->CB7_PRESEP,4,1)
	cConf	:=  Substr(CB7->CB7_PRESEP,5,1)
	                
	@ 001,001 TO 180,395 DIALOG oDlg2 TITLE OemToAnsi("Volumes diversos")
	@ 002,010 TO 070,190
	@ 010,018 Say "Informe o numero de volumes diversos:"
	@ 010,120 Get nDiversos Picture "@E 99999" Size 30,10

	@ 20,018 Say "Box"
	@ 20,075 Get cBox Picture "@!"
	@ 30,018 Say "Separador"
	@ 30,075 Get cSep Picture "@!"
	@ 40,018 Say "Mesa"
	@ 40,075 Get cMesa Picture "@!"
	@ 50,018 Say "Conferente"
	@ 50,075 Get cConf Picture "@!"

	@ 75,150 BUTTON "Avancar--->" SIZE 40,10 Action Close(oDlg2)

	ACTIVATE MSDIALOG oDlg2 CENTERED

	If Len(aEtiqueta) <> 0 .Or. !Empty(nDiversos)
	
		U_DIS010P(aEtiqueta,nDiversos,CB7->CB7_PEDIDO,CB7->CB7_CLIENTE,CB7->CB7_LOJA,SC5->C5_TIPO)
		DbSelectArea("CB7")
		RecLock("CB7",.F.)
		CB7->CB7_VOLEMI	:= "1"
		CB7->CB7_STATUS	:= "9"
		CB7->CB7_PRESEP	:= cBox+cSep+cMesa+cConf
		CB7->CB7_DIVERG	:= ""
		MsUnlock()
	
		cQry := "UPDATE "+RetSqlName("CB6")
		cQry += "   SET CB6_STATUS = '3' "
		cQry += " WHERE D_E_L_E_T_ = ' ' "
		cQry += "   AND CB6_PEDIDO = '"+CB7->CB7_PEDIDO+"' "
		cQry += "   AND CB6_STATUS IN('1','2') "
		cQry += "   AND CB6_FILIAL = '"+xFilial("CB6")+"' "
    
		TcSqlExec(cQry)
	
	Endif

Return


/*/{Protheus.doc} sfReimpFZ
//Reimpressão de etiquetas Frimazo
@author Marcelo Alberto Lauschner
@since 30/05/2018
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
Static Function sfReimpFZ()

	Local	cQry		:= ""
	Local	aEtiqueta	:= {}
	Local	nOpca 		:= 0
	Private cBox    	:= Space(2)
	Private cSep   		:= Space(1)
	Private cMesa   	:= Space(1)
	Private cConf   	:= Space(1)

	If CB7->CB7_VOLEMI == "1" .And. !Empty(CB7->CB7_CODOPE)
		If !MsgYesNo("Já foram emitidas etiquetas para esta ordem de separação. Deseja reimprimir?","Etiquetas já emitidas")
			Return
		Endif
	Endif
    
// Se não houve 
	If Empty(CB7->CB7_CODOPE) .And. CB7->CB7_VOLEMI # "1"
		MsgAlert("Este pedido não foi separado por Coletor para poder imprimir etiquetas por esta rotina!","Rotina não autorizada")
		Return
	Endif


	cQry := "SELECT COUNT(*) QTEDIV"
	cQry += "  FROM "+RetSqlName("CB6")
	cQry += " WHERE D_E_L_E_T_ = ' ' "
	cQry += "   AND CB6_PEDIDO = '"+CB7->CB7_PEDIDO+"' "
	cQry += "   AND CB6_STATUS IN('1','3') "
	cQry += "   AND CB6_TIPVOL = 'CXS' "
	cQry += "   AND CB6_FILIAL = '"+xFilial("CB6")+"' "

	TcQuery cQry New Alias "QCB6"

	nDiversos := QCB6->QTEDIV

	QCB6->(DbCloseArea())
	
	DbSelectArea("SC5")
	DbSetOrder(1)
	DbSeek(xFilial("SC5")+CB7->CB7_PEDIDO)
                
	@ 001,001 TO 120,395 DIALOG oDlg2 TITLE OemToAnsi("Volumes diversos")
	@ 002,010 TO 050,190
	@ 010,018 Say "Informe o numero de volumes diversos:"
	@ 010,120 Get nDiversos Picture "@E 99999" Size 30,10

	@ 035,120 BUTTON "Avancar--->" SIZE 40,10 Action (nOpca := 1 ,Close(oDlg2))

	ACTIVATE MSDIALOG oDlg2 CENTERED

	If nOpca == 1 .And. ( Len(aEtiqueta) <> 0 .Or. !Empty(nDiversos) )
	
		U_FZFATA02(aEtiqueta,nDiversos,CB7->CB7_PEDIDO,CB7->CB7_CLIENTE,CB7->CB7_LOJA,SC5->C5_TIPO,SC5->C5_PESOL,SC5->C5_PBRUTO)
		
		DbSelectArea("CB7")
		RecLock("CB7",.F.)
		CB7->CB7_VOLEMI	:= "1"
		CB7->CB7_STATUS	:= "9"
		CB7->CB7_PRESEP	:= cBox+cSep+cMesa+cConf
		CB7->CB7_DIVERG	:= ""
		MsUnlock()
	
		cQry := "UPDATE "+RetSqlName("CB6")
		cQry += "   SET CB6_STATUS = '3' "
		cQry += " WHERE D_E_L_E_T_ = ' ' "
		cQry += "   AND CB6_PEDIDO = '"+CB7->CB7_PEDIDO+"' "
		cQry += "   AND CB6_STATUS IN('1','2') "
		cQry += "   AND CB6_FILIAL = '"+xFilial("CB6")+"' "
    
		TcSqlExec(cQry)
	
	Endif

Return 
