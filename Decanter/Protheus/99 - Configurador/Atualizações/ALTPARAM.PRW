#Include "Protheus.ch"
/*
+------------------------------------------------------------------------------------+
¦Programa  ¦       ¦ Autor ¦ Ricardo Diniz - NM                   ¦Data ¦29.09.2009  ¦
+----------+-------------------------------------------------------------------------¦
¦Descricao ¦ ALTPARAM                                                  				 ¦
+----------+-------------------------------------------------------------------------¦
¦ Uso      ¦ ESPECIFICO PARA PARÂMETROS DE BLOQUEIO                                  ¦
+------------------------------------------------------------------------------------¦
¦           ATUALIZACOES SOFRIDAS DESDE A CONSTRUCAO INICIAL            		     ¦
+------------------------------------------------------------------------------------¦
¦PROGRAMADOR ¦ DATA   ¦ MOTIVO DA ALTERACAO                             		     ¦
+------------+--------+--------------------------------------------------------------¦
¦Felipe Tironi ¦ 13/07/2018 ¦ "MV_ULMES" substituido por "MV_DBLQMOV".               ¦
+------------------------------------------------------------------------------------+
*/
User Function ALTPARAM()

	Local lBtnOk  	:= .F.
	Local dDtaFin 	:= GetMv("MV_DATAFIN")
	Local dDtaFis 	:= GetMv("MV_DATAFIS")
	Local dDtaEst 	:= GetMv("MV_ULMES")
	Local dDtaCom 	:= GetMv("MV_DBLQMOV")
	Local dDtaFat 	:= GetMv("MV_DATAFAT")
	Local oFont    	:= TFont():New( "Times New Roman",,16,,.T.,,,,.F.,.F. )


	DEFINE MSDIALOG oDlg FROM 000,00 TO 280,300 PIXEL TITLE OemToAnsi("Altera Parâmetros ")

	oGroup := TGroup():New(005,005,025,145,"",oDlg,,,.T.,.T.)
	oSay   := TSay():New(012,010,{|| 'Bloqueio Financeiro' },oDlg,,oFont,,,,.T.,,,280,050)
	@ 010,085 MSGET o Var dDtaFin Size 040,10 PICTURE "@!" Valid !Empty(dDtaFin) OF oDlg PIXEL

	oGroup := TGroup():New(030,005,050,145,"",oDlg,,,.T.,.T.)
	oSay   := TSay():New(037,010,{|| 'Bloqueio Fiscal' },oDlg,,oFont,,,,.T.,,,280,050)
	@ 035,085 MSGET o Var dDtaFis Size 040,10 PICTURE "@!" Valid !Empty(dDtaFis) OF oDlg PIXEL

	oGroup := TGroup():New(055,005,075,145,"",oDlg,,,.T.,.T.)
	oSay   := TSay():New(062,010,{|| 'Bloqueio Compras/Estoque' },oDlg,,oFont,,,,.T.,,,280,050)
	@ 060,085 MSGET o Var dDtaCom Size 040,10 PICTURE "@!" Valid !Empty(dDtaCom) OF oDlg PIXEL

	oGroup := TGroup():New(080,005,100,145,"",oDlg,,,.T.,.T.)
	oSay   := TSay():New(087,010,{|| 'Bloqueio Faturamento' },oDlg,,oFont,,,,.T.,,,280,050)
	@ 085,085 MSGET o Var dDtaFat Size 040,10 PICTURE "@!" Valid !Empty(dDtaFat) OF oDlg PIXEL

	oGroup := TGroup():New(105,005,125,145,"",oDlg,,,.T.,.T.)
	oSay   := TSay():New(112,010,{|| 'Fechamento Estoque' },oDlg,,oFont,,,,.T.,,,280,050)
	@ 110,085 MSGET o Var dDtaEst Size 040,10 PICTURE "@!" Valid !Empty(dDtaEst) OF oDlg PIXEL


	Define sButton From 130, 080 type 1 Action (lBtnOk := .T.    .And.  oDlg:End()) Enable of oDlg
	Define sButton From 130, 115 type 2 Action !(lBtnOk := .F.)  .And.  oDlg:End() Enable of oDlg



	Activate MsDialog oDlg Centered

	If lBtnOk
		If !Empty(dDtaFis)
			PutMv("MV_DATAFIS",dDtaFis)
		EndIf

		If !Empty(dDtaFin)
			PutMv("MV_DATAFIN",dDtaFin)
		EndIf

		If !Empty(dDtaEst)
			PutMv("MV_ULMES",dDtaEst)
		EndIf

		If !Empty(dDtaCom)
			PutMv("MV_DBLQMOV",dDtaCom)
		EndIf

		If !Empty(dDtaFat)
			PutMv("MV_DATAFAT",dDtaFat)
		EndIf
	EndIf

Return
