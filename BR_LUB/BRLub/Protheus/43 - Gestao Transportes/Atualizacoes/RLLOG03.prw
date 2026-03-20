#include "rwmake.ch"
#include "protheus.ch"
#INCLUDE "TOPCONN.CH"
#INCLUDE "COLORS.CH"
#INCLUDE "TBICONN.CH"



//---------------------------------------------------------------------------------------
// Analista   : Júnior Conte - 25/07/18
// Nome função: RLLOG03
// Parametros :
// Objetivo   : Interface de Geração de Faturas a partir das operações do cliente
// 			
// Retorno    :
// Alterações :
//---------------------------------------------------------------------------------------


USER FUNCTION RLLOG03()

	local cperg := "RLLOG03   "
	local aRegs := {}
	Local j
	Local i

	private tipo   := 0
	private nordem := 1
	private nCalJr := 1

	Aadd(aRegs,{cperg ,"01"		,"Cliente De"				,"Cliente De	"	 	,"Cliente De  "		,"mv_ch1"	,"C"		,6				,0				,0				,"G"		,""			,"mv_par01"	,""			,""				,""				,""			,""			,""				,""					,""					,""			,""			,""			,""				,""				,""			,""			,""			,""				,""				,""			,""			,""			,""			,""				,""			,"SA1" 		,"S"		,""			,""})
	Aadd(aRegs,{cperg ,"02"		,"Cliente Ate"				,"Cliente Ate	"	 	,"Cliente Ate  "	,"mv_ch2"	,"C"		,6				,0				,0				,"G"		,""			,"mv_par02"	,""			,""				,""				,""			,""			,""				,""					,""					,""			,""			,""			,""				,""				,""			,""			,""			,""				,""				,""			,""			,""			,""			,""				,""			,"SA1" 		,"S"		,""			,""})
	Aadd(aRegs,{cperg ,"03"		,"Loja    De "				,"Loja    De "			,"Loja    De "		,"mv_ch3"	,"C"		,2				,0				,0				,"G"		,""			,"mv_par03"	,""			,""				,""				,""			,""			,""				,""					,""					,""			,""			,""			,""				,""				,""			,""			,""			,""				,""				,""			,""			,""			,""			,""				,""			,"" 		,"S"		,""			,""})
	Aadd(aRegs,{cperg ,"04"		,"Loja    Ate"				,"Loja    Ate"			,"Loja    Ate"		,"mv_ch4"	,"C"		,2				,0				,0				,"G"		,""			,"mv_par04"	,""			,""				,""				,""			,""			,""				,""					,""					,""			,""			,""			,""				,""				,""			,""			,""			,""				,""				,""			,""			,""			,""			,""				,""			,"" 		,"S"		,""			,""})
	Aadd(aRegs,{cperg ,"05"		,"Data    De "				,"Data    De "			,"Data    De "		,"mv_ch5"	,"D"		,8				,0				,0				,"G"		,""			,"mv_par05"	,""			,""				,""				,""			,""			,""				,""					,""					,""			,""			,""			,""				,""				,""			,""			,""			,""				,""				,""			,""			,""			,""			,""				,""			,"" 		,"S"		,""			,""})
	Aadd(aRegs,{cperg ,"06"		,"Data    Ate"				,"Data    Ate"			,"Data    Ate"		,"mv_ch6"	,"D"		,8				,0				,0				,"G"		,""			,"mv_par06"	,""			,""				,""				,""			,""			,""				,""					,""					,""			,""			,""			,""				,""				,""			,""			,""			,""				,""				,""			,""			,""			,""			,""				,""			,"" 		,"S"		,""			,""})


	dbSelectArea("SX1")
	dbSetOrder(1)
	For i:=1 to Len(aRegs)
		If !dbSeek(cPerg+aRegs[i,2])
			RecLock("SX1",.T.)
			For j:=1 to FCount()
				If j <= Len(aRegs[i])
					FieldPut(j,aRegs[i,j])
				Endif
			Next
			MsUnlock()
		Endif
	Next

	if pergunte(cPerg,.t.)
		processa({|| sefin07()})
	endif

return(.t.)

static function sefin07()

	private aParam    := {}
	private oNo := LoadBitmap( GetResources(), "LBNO"  )
	private oOk := LoadBitmap( GetResources(), "LBTIK" )
	private oDs := LoadBitmap( GetResources(), "DISABLE" )
	private aButtons := {}
	private oFonte1 := TFont():New( "Arial",,16,,.T. )
	private oFonte2 := TFont():New( "Arial",,14,,.F. )

	private nPerAcr	:= 0

	dbselectarea("SA1")
	dbsetorder(1)


	nTotCR:=nTotCP:=nTotRa:=nTotNcc:=nTotPa:=nTotNdf:=0

	nTotAdv:=0

	cQuery := " SELECT * "
	cQuery += " FROM "
	cQuery += retsqlname("Z23") + " Z23, "
	cQuery += " WHERE "
	cQuery += " Z23.Z23_FILIAL = '"+xFilial("Z23")+"' AND "
	cQuery += " Z23.Z23_CLIENT >= '" + MV_PAR01 + "' AND "
	cQuery += " Z23.Z23_CLIENT <= '" + MV_PAR02 + "' AND "
	cQuery += " Z23.Z23_LOJA   >= '" + MV_PAR03 + "' AND "
	cQuery += " Z23.Z23_LOJA   <= '" + MV_PAR04 + "' AND "

	cQuery += " Z23.Z23_DATA   >= '" + dtos(MV_PAR05) + "' AND "

	cQuery += " Z23.Z23_DATA   <= '" + dtos(MV_PAR06) + "' AND "

	cQuery += " Z23.D_E_L_E_T_ = ' ' AND Z23.Z23_STATUS = '0' "
	cQuery += " Order by  Z23_DATA "

	cQuery := ChangeQuery(cQuery)
	TCQUERY cQuery NEW ALIAS "Work"

	aDiverg := {}

	DbSelectArea("Work")
	dbGoTop()
	nTotCr := 0
	nMaxADV := 0
	while !eof()
		DbSelectArea("SA1")
		dbseek(xfilial()+Work->Z23_CLIENT+Work->Z23_LOJA)

		dbSelectArea("Z21")
		dbSetOrder(1)
		dbSeek(xFilial("Z21")  +  Work->Z23_SERVIC  )
		if Z21->Z21_CAL15 == '1'
			//	axval := {}
			//axval := sfBusMaio(Work->Z23_OPER, Work->Z23_SERVIC )
			nTotCr +=  sfBusMaio(Work->Z23_OPER, Work->Z23_SERVIC ) //axval[1,1] //Work->Z23_VALOR
			//nTotCr +=  Work->Z23_ADVALO
		else
			nTotCr += Work->Z23_VALOR
			If Work->Z23_ADVALO > nMaxADV
				nMaxADV := Work->Z23_ADVALO
			EndIf
		endif

		aadd(aParam,{.t., Work->Z23_FILIAL,  STOD(Work->Z23_DATA), Work->Z23_OPER, Work->Z23_SERVIC, Work->Z23_CLIENT, Work->Z23_LOJA, Work->Z23_NOMCLI ,   Work->Z23_VALOR, Work->Z23_ADVALO, Work->Z23_HORA, Work->Z23_USUARI, Work->Z23_NRCONT, Work->R_E_C_N_O_ })

		DbSelectArea("Work")
		dbskip()
	enddo



	if len(aParam)==0
		msgbox("Nenhum registro em aberto para esse cliente !","Atencao","INFO")
		DbSelectArea("Work")
		DbCloseArea("Work")

		return()
	endif

	@ 000,000 TO 500,925 DIALOG oDlg TITLE "Pré-Seleção de Operações"

	oObj1 := TSay():New( 161,010,{ || "Total a Receber: " },oDlg,,oFonte1,.F.,.F.,.F.,.T.)
	oObj2 := TSay():New( 161,050,{ || transform(nTotCr+nMaxADV,"@E 999,999,999.99") }  , oDlg ,, oFonte1,.f.,.f.,.f.,.t.,CLR_HBLUE )

	oObj1 := TSay():New( 171,010,{ || "Pico AdValorem: " },oDlg,,,.F.,.F.,.F.,.T.)
	oObj2 := TSay():New( 171,050,{ || transform(nMaxADV,"@E 999,999,999.99") }  , oDlg ,, oFonte2,.f.,.f.,.f.,.t.,CLR_HBLUE )

	oObj3 := TSay():New( 156,260,{ || "Acréscimo (%)" },oDlg,,,.F.,.F.,.F.,.T.)
	@ 155,300  MSGET oGet012 VAR nPerAcr PICTURE "@E 99.99" SIZE 70,9  OF oDlg PIXEL

	@ 000,000 ListBox oLbxA Var cItBx Fields Header '','Filial', 'Data', 'Código Operação','Código Serviço','Codigo Cliente','Loja','Nome Cliente','Valor','Advaloren','Hora','Usuário','Nr Container', 'Recno' Size 462,150;
		On DBLCLICK (sefin07c(oLbxA:nAt,nTotCr),oLbxA:Refresh())
	oLbxA:SetArray(aParam)
	oLbxA:bLine := { || {If(aParam[oLbxA:nAt,1]==Nil,oDs,iif(aParam[oLbxA:nAt,1],oOk,oNo)), aParam[oLbxA:nAt,2], DtoC(aParam[oLbxA:nAt,3]), aParam[oLbxA:nAt,4],aParam[oLbxA:nAt,5],aParam[oLbxA:nAt,6],aParam[oLbxA:nAt,7],aParam[oLbxA:nAt,8],aParam[oLbxA:nAt,9],aParam[oLbxA:nAt,10],aParam[oLbxA:nAt,11],aParam[oLbxA:nAt,12], aParam[oLbxA:nAt,13], aParam[oLbxA:nAt,14]}}

	@ 232,360 BMPBUTTON TYPE 1 ACTION Processa({|| sefin07b(.T., nTotCr+nMaxADV, nPerAcr, nMaxADV)})

	@ 155,410 BUTTON "Marca/Desmarca" SIZE 50, 10 OF oDlg PIXEL Action (sefin07f(oLbxA:nAt,nTotCr),oLbxA:Refresh())
	@ 232,398 BMPBUTTON TYPE 2 ACTION Close(oDlg)

	ACTIVATE DIALOG oDlg

	DbSelectArea("Work")
	DbCloseArea("Work")

Return(.T.)

//grava fatura.
static function sefin07b(lGrava, nTotCr,  nPerAcr, nMaxADV)

	Local I

	dbSelectArea("Z26")
	dbSetOrder(1)

	IF nTotCr > 0

		cNumFat := ""
		cNumFat := GETSX8NUM("Z26","Z26_NUMFAT")
		ConfirmSX8()
		dbSelectArea("Z26")
		dbSetOrder(1)
		Reclock("Z26", .T. )
		Z26->Z26_FILIAL := xFilial("Z26")
		Z26->Z26_NUMFAT := cNumFat
		Z26->Z26_DATA   := DDATABASE
		Z26->Z26_CLIENT := aParam[1,6]
		Z26->Z26_LOJA   := aParam[1,7]
		Z26->Z26_NOMCLI := aParam[1,8]
		Z26->Z26_VALOR  := ( nTotCr + ((nTotCr*nPerAcr)/100) )
		Z26->Z26_PERACR := nPerAcr
		Z26->Z26_ADVALO := nMaxADV
		Z26->Z26_DTINI  := MV_PAR05
		Z26->Z26_DTFIN  := MV_PAR06
		MsUnLock("Z26")

		For I := 1 to len(aParam)
			//aParam[I,1]:=lMarca
			if aParam[I,1]
				DbSelectArea("Z23")
				DbSetOrder(1)
				DbGoto(aParam[I,14])

				reclock("Z23", .F.)
				Z23->Z23_STATUS := '1'
				Z23->Z23_NUMFAT := cNumFat
				msunlock("Z23")

			endif
		Next

		//Busca valor mínimo
		If Select("QRYZ23") <> 0
			dbSelectArea("QRYZ23")
			QRYZ23->(dbCloseArea())
		EndIf

		cQuery := ""
		cQuery := "SELECT Z23_FILIAL, Z23_NUMFAT, Z23_OPER, Z23_SERVIC,  Z22_VLRMIN,   SUM(Z23_VALOR)  Z23_VALOR "
		cQuery += "FROM 		"+RetSqlName("Z23")+ " Z23 "
		cQuery += "INNER JOIN   "+RetSqlName("Z22")+ " Z22 ON Z22.Z22_FILIAL = Z23.Z23_FILIAL AND Z22.Z22_OPER = Z23.Z23_OPER AND Z22.Z22_SERVIC = Z23.Z23_SERVIC "
		cQuery += "AND Z22.Z22_CLIENT = Z23.Z23_CLIENT AND Z22.Z22_LOJA = Z23.Z23_LOJA "
		cQuery += "WHERE Z23.D_E_L_E_T_ = ' '  AND Z22.D_E_L_E_T_ = ' '  AND Z23.Z23_NUMFAT = '"+cNumFat+"' "
		cQuery += "Group By Z23_FILIAL, Z23_NUMFAT, Z23_OPER, Z23_SERVIC, Z22_VLRMIN "
		cQuery := ChangeQuery(cQuery)

		TcQuery cQuery New Alias "QRYZ23"

		dbSelectArea("QRYZ23")
		QRYZ23->(dbGoTop())

		nvlrfat := 0

		While QRYZ23->(!Eof())

			if  QRYZ23->Z22_VLRMIN > QRYZ23->Z23_VALOR
				nvlrfat += ( QRYZ23->Z22_VLRMIN + ( ( QRYZ23->Z22_VLRMIN * nPerAcr) / 100 ) )
			else
				nvlrfat +=  ( QRYZ23->Z23_VALOR + ( ( QRYZ23->Z23_VALOR * nPerAcr) / 100 ) )
			endif

			QRYZ23->(dbSkip())
		EndDo

//	if  QRYZ23->Z22_VLRMIN > nvlrfat
//		nvlrfat := QRYZ23->Z22_VLRMIN 						
//	endif 

		dbSelectArea("Z26")
		dbSetOrder(1)
		if dbSeek( xFilial("Z26") + aParam[1,6] + aParam[1,7] + cNumFat  )

			RecLock("Z26", .F. )
			Z26->Z26_VALOR := nvlrfat
			msUnLock("Z26")

		endif

		MSGINFO("Fatura gerada --> " + cNumFat,"RLLOG03" )

	ENDIF
	Close(oDlg)

return(.t.)

Static Function sefin07c(par1)

	if aParam[par1,1] == Nil
		return(.t.)
	endif

	nTotCr    := 0

	aParam[par1,1]:=If(aParam[par1,1],.F.,.T.)
	For par1 := 1 To Len(aParam)
		if aParam[par1,1]

			nTotCr   += aparam[par1,9]
			nTotCr   += aparam[par1,10]


		endif
	next

	oObj1:Refresh()

Return(.t.)


Static Function sefin07f()

	Local I
	Local lMarca := IIf(len(aParam)>0,If(aParam[1,1],.F.,.T.),.F.)

	nTotCr      := 0


	For I := 1 to len(aParam)
		aParam[I,1]:=lMarca
		if aParam[I,1]
			//alert(aparam[I,9])
			nTotCr   += aparam[I,9]
			nTotCr   += aparam[I,10]




		endif
	Next


	oObj1:Refresh()


Return(.t.)



//busca dia com maior armazenagem
Static Function sfBusMaio(xOper, xServic )

	If Select("_QRYZ23") <> 0
		dbSelectArea("_QRYZ23")
		_QRYZ23->(dbCloseArea())
	EndIf

	cQuery := " SELECT MAX(Z23_VALOR) Z23_VALOR "
	cQuery += " FROM "
	cQuery += retsqlname("Z23") + " Z23, "
	cQuery += " WHERE "
	cQuery += " Z23.Z23_FILIAL = '"+xFilial("Z23")+"' AND "
	cQuery += " Z23.Z23_CLIENT >= '" + MV_PAR01 + "' AND "
	cQuery += " Z23.Z23_CLIENT <= '" + MV_PAR02 + "' AND "
	cQuery += " Z23.Z23_LOJA   >= '" + MV_PAR03 + "' AND "
	cQuery += " Z23.Z23_LOJA   <= '" + MV_PAR04 + "' AND "

	cQuery += " Z23.Z23_DATA   >= '" + dtos(MV_PAR05) + "' AND "

	cQuery += " Z23.Z23_DATA   <= '" + dtos(MV_PAR06) + "' AND "

	cQuery += " Z23.D_E_L_E_T_ = ' ' AND Z23.Z23_STATUS = '0' AND "
	cQuery += " Z23.Z23_OPER = '"+ xOper +"' AND  Z23.Z23_SERVIC = '"+ xServic +"' "


	cQuery := ChangeQuery(cQuery)

	TcQuery cQuery New Alias "_QRYZ23"

	dbSelectArea("_QRYZ23")
	_QRYZ23->(dbGoTop())
return  _QRYZ23->Z23_VALOR
