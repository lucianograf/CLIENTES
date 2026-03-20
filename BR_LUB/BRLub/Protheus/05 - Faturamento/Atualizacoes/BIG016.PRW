#INCLUDE "rwmake.ch"
#INCLUDE "TOPCONN.CH"


/*/{Protheus.doc} BIG016
(Impressao de etiqueta endereçamento deposito)
@author MarceloLauschner
@since 18/01/2005
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BIG016()
	
	
	Local	lCont			:= .F.
	Private	lLayoutCondor	:= .F. 
	Private cEnd1 			:= ""
	Private cEnd2 			:= ""
	Private cCpoLocal		:= "B1_LOCAL"
	
	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()
	If SB1->(FieldPos("B1_LOCAL")) > 0 
		cEnd1 		:= Space(TamSX3("B1_LOCAL")[1])
		cEnd2 		:= Space(TamSX3("B1_LOCAL")[1])
		cCpoLocal	:= "B1_LOCAL"
	ElseIf SB1->(FieldPos("B1_XLOCAL")) > 0 
		cEnd1 		:= Space(TamSX3("B1_XLOCAL")[1])
		cEnd2 		:= Space(TamSX3("B1_XLOCAL")[1])
		cCpoLocal	:= "B1_XLOCAL"
	Else 
		Return 
	Endif 
	
	@ 200,1 TO 380,395 DIALOG oDlg1 TITLE OemToAnsi("Paramêtros para impressão de Etiquetas")
	@ 02,10 TO 070,190
	@ 10,018 Say "Do endereço"
	@ 10,070 Get cEnd1 Picture Iif(cFilAnt == "01","@R 99.99.9.X","@!") Size 40,10
	@ 25,018 Say "Até enderço"
	@ 25,070 Get cEnd2 Picture Iif(cFilAnt == "01","@R 99.99.9.X","@!") Size 40,10
	@ 75,020 BUTTON "Confirma" SIZE 40,10 ACTION (lCont	:= .T.,Close(oDlg1))
	@ 75,070 BUTTON "Imp.Layout Superlog" SIZE 60,10 ACTION (lLayoutCondor := .T.,lCont	:= .T.,Close(oDlg1))
	@ 75,140 Button "Cancela" Size 40,10 Action Close(oDlg1)
	
	ACTIVATE MSDIALOG oDlg1 CENTERED
	
	If lCont
		Imp()
	Endif
	
	
Return


/*/{Protheus.doc} Imp
(long_description)
@author MarceloLauschner
@since 26/05/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function Imp()
	
	If !MsgYesNo("Deseja realmente prosseguir?","Informacao")
		Return
	Endif
	
	If Select("QRY") > 0
		QRY->(DbCloseArea())
	Endif
	
	cQry := ""
	cQry += "SELECT "+cCpoLocal+" B1LOCAL,B1_DESC,B1_CODBAR,B1_COD "
	cQry += "  FROM "+RetSqlName("SB1") + " "
	cQry += " WHERE D_E_L_E_T_ =  ' ' "
	cQry += "   AND "+cCpoLocal+" BETWEEN '"+cEnd1+"' AND '"+cEnd2+"' "
	cQry += " ORDER BY "+cCpoLocal+" ASC "
	
	TCQUERY cQry NEW ALIAS "QRY"
	
	While !Eof()
		
		_cPorta := Alltrim(GetNewPar("GM_PORTLPT","LPT1:9600,n,8,1"))
		
		MSCBPRINTER("ALLEGRO",_cPorta,Nil,) 	//Seta tipo de impressora
		MSCBCHKSTATUS(.F.)
		MSCBBEGIN(1,4) 							//Inicio da Imagem da Etiqueta
	
		If lLayoutCondor
			MSCBSAY(05,22,Transform(QRY->B1LOCAL,"@R 99.99.9.X"),"N","9","006,005")
			MSCBSAY(05,14,QRY->B1_COD,"N","9","004,003") //Imprime Texto   
			MSCBSAYBAR(65,14,Alltrim(StrTran(AllTrim(Transform(QRY->B1LOCAL,"@R 99.99.9.X")),"-","")),"N","MB07",12,.F.,.T.,.F.,,2,2,.F.)
			MSCBSAY(05,07,Substr(QRY->B1_DESC,1,24),"N","9","003,002") //Imprime Texto
			MSCBSAY(05,03,Substr(QRY->B1_DESC,25,16),"N","9","003,002") //Imprime Texto
		Else
			MSCBSAY(01,28,"Setor:","N","9","001,001")
			MSCBSAY(07,28,Substr(QRY->B1LOCAL,1,2),"N","9","005,004") 		
			MSCBSAY(25,23,QRY->B1_COD,"N","9","006,004")
			MSCBSAY(07,18,Substr(QRY->B1LOCAL,3,1),"N","9","005,004") 		
			MSCBSAY(20,16,Substr(QRY->B1_DESC,1,22),"N","9","003,002") 		
			MSCBSAY(28,10,Substr(QRY->B1_DESC,23,15),"N","9","003,002") 	
			MSCBSAY(01,18,"Rua:","N","9","001,001")
			MSCBSAY(07,06,Substr(QRY->B1LOCAL,4,3),"N","9","005,004") 	
			MSCBSAY(01,06,"Local:","N","9","001,001")
			MSCBSAY(40,02,QRY->B1_CODBAR,"N","9","002,002") //Imprime Texto
		Endif
		
		cResult := MSCBEND()
		
		MemoWrit('BIG016',cResult)
		
		Dbselectarea("QRY")
		dbskip()
	Enddo
	
	QRY->(DbCloseArea())
	MsgInfo("Processo finalizado!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
	
Return

