#include "rwmake.ch"
#include "protheus.ch"
#INCLUDE "TOPCONN.CH"
#INCLUDE "COLORS.CH"
#INCLUDE "TBICONN.CH"



//---------------------------------------------------------------------------------------
// Analista   : Júnior Conte - 17/07/18
// Nome função: RLLOG04
// Parametros :
// Objetivo   : Gerar valores de armazenagem M3
// 			
// Retorno    :
// Alterações :
//---------------------------------------------------------------------------------------



User Function RLLOG04
	Private  cPergXml	:= "RLLOG04"
	// ValidPerg()
	If !Pergunte(cPergXml,.T.)
		REturn
	Endif
	Processa({|| sfCalcula() },"Aguarde enquanto o cálculo é efetuado....")
	Processa({|| sfGeraZ23() },"Aguarde enquanto o cálculo é efetuado....")
	Processa({|| sfGeraTXS() },"Gerando Taxas....")

	//sfGeraTXS
	//Processa({|| sfGerAdv()  },"Calculando Advaloren....")
Return

//---------------------------------------------------------------------------------------
// Analista   : Júnior Conte - 17/07/2018
// Nome função: ValidPerg
// Parametros :
// Objetivo   : Criar as perguntas para a rotina
// Retorno    :
// Alterações :
//---------------------------------------------------------------------------------------
// Static Function ValidPerg()

// 	Local aRegs := {}
// 	Local i,j

// 	dbSelectArea("SX1")
// 	dbSetOrder(1)
// 	cPergXml :=  PADR(cPergXml,Len(SX1->X1_GRUPO))
// 	//     "X1_GRUPO" ,"X1_ORDEM","X1_PERGUNT"    			,"X1_PERSPA"		,"X1_PERENG"		,"X1_VARIAVL","X1_TIPO"	,"X1_TAMANHO"	,"X1_DECIMAL"	,"X1_PRESEL"	,"X1_GSC"	,"X1_VALID"	,"X1_VAR01"	,"X1_DEF01"	,"X1_DEFSPA1"	,"X1_DEFENG1"	,"X1_CNT01"	,"X1_VAR02"	,"X1_DEF02"		,"X1_DEFSPA2"		,"X1_DEFENG2"		,"X1_CNT02"	,"X1_VAR03"	,"X1_DEF03"	,"X1_DEFSPA3"	,"X1_DEFENG3"	,"X1_CNT03"	,"X1_VAR04"	,"X1_DEF04"	,"X1_DEFSPA4"	,"X1_DEFENG4"	,"X1_CNT04"	,"X1_VAR05"	,"X1_DEF05"	,"X1_DEFSPA5","X1_DEFENG5"	,"X1_CNT05"	,"X1_F3"	,"X1_PYME"	,"X1_GRPSXG"	,"X1_HELP"
// 	Aadd(aRegs,{cPergXml ,"01"		,"Cliente De"				,"Cliente De	"	 	,"Cliente De  "		,"mv_ch1"	,"C"		,6				,0				,0				,"G"		,""			,"mv_par01"	,""			,""				,""				,""			,""			,""				,""					,""					,""			,""			,""			,""				,""				,""			,""			,""			,""				,""				,""			,""			,""			,""			,""				,""			,"SA1" 		,"S"		,""			,""})
// 	Aadd(aRegs,{cPergXml ,"02"		,"Cliente Ate"				,"Cliente Ate	"	 	,"Cliente Ate  "	,"mv_ch2"	,"C"		,6				,0				,0				,"G"		,""			,"mv_par02"	,""			,""				,""				,""			,""			,""				,""					,""					,""			,""			,""			,""				,""				,""			,""			,""			,""				,""				,""			,""			,""			,""			,""				,""			,"SA1" 		,"S"		,""			,""})
// 	Aadd(aRegs,{cPergXml ,"03"		,"Loja    De "				,"Loja    De "			,"Loja    De "		,"mv_ch3"	,"C"		,2				,0				,0				,"G"		,""			,"mv_par03"	,""			,""				,""				,""			,""			,""				,""					,""					,""			,""			,""			,""				,""				,""			,""			,""			,""				,""				,""			,""			,""			,""			,""				,""			,"" 		,"S"		,""			,""})
// 	Aadd(aRegs,{cPergXml ,"04"		,"Loja    Ate"				,"Loja    Ate"			,"Loja    Ate"		,"mv_ch4"	,"C"		,2				,0				,0				,"G"		,""			,"mv_par04"	,""			,""				,""				,""			,""			,""				,""					,""					,""			,""			,""			,""				,""				,""			,""			,""			,""				,""				,""			,""			,""			,""			,""				,""			,"" 		,"S"		,""			,""})
// 	Aadd(aRegs,{cPergXml ,"05"		,"Data    De "				,"Data    De "			,"Data    De "		,"mv_ch5"	,"D"		,8				,0				,0				,"G"		,""			,"mv_par05"	,""			,""				,""				,""			,""			,""				,""					,""					,""			,""			,""			,""				,""				,""			,""			,""			,""				,""				,""			,""			,""			,""			,""				,""			,"" 		,"S"		,""			,""})
// 	Aadd(aRegs,{cPergXml ,"06"		,"Data    Ate"				,"Data    Ate"			,"Data    Ate"		,"mv_ch6"	,"D"		,8				,0				,0				,"G"		,""			,"mv_par06"	,""			,""				,""				,""			,""			,""				,""					,""					,""			,""			,""			,""				,""				,""			,""			,""			,""				,""				,""			,""			,""			,""			,""				,""			,"" 		,"S"		,""			,""})
// 	Aadd(aRegs,{cPergXml ,"07"		,"Produto De"				,"Produto De	"	 	,"Cliente De  "		,"mv_ch7"	,"C"		,15				,0				,0				,"G"		,""			,"mv_par07"	,""			,""				,""				,""			,""			,""				,""					,""					,""			,""			,""			,""				,""				,""			,""			,""			,""				,""				,""			,""			,""			,""			,""				,""			,"SB1" 		,"S"		,""			,""})
// 	Aadd(aRegs,{cPergXml ,"08"		,"Produto Ate"				,"Produto Ate	"	 	,"Cliente Ate  "	,"mv_ch8"	,"C"		,15 			,0				,0				,"G"		,""			,"mv_par08"	,""			,""				,""				,""			,""			,""				,""					,""					,""			,""			,""			,""				,""				,""			,""			,""			,""				,""				,""			,""			,""			,""			,""				,""			,"SB1" 		,"S"		,""			,""})


// 	For i:=1 to Len(aRegs)
// 		If !dbSeek(cPergXml+aRegs[i,2])
// 			RecLock("SX1",.T.)
// 			For j:=1 to FCount()
// 				If j <= Len(aRegs[i])
// 					FieldPut(j,aRegs[i,j])
// 				Endif
// 			Next
// 			MsUnlock("SX1")
// 		Else
// 			/*		RecLock("SX1",.F.)
// 			For j:=1 to FCount()
// 				If j <= Len(aRegs[i])
// 					FieldPut(j,aRegs[i,j])
// 				Endif             '
// 			Next
// 			MsUnlock("SX1")*/
// 		Endif
// 	Next

// Return

//---------------------------------------------------------------------------------------
// Analista   :Júnior Conte - 30/07/2018
// Nome função: sfCalcula
// Parametros :
// Objetivo   : Efetua o cálculo para gravação.
// Retorno    :
// Alterações :
//---------------------------------------------------------------------------------------
Static Function  sfCalcula()

	Local	cQry		:= ""
	Local	lConvProd	:= .F.

	aCols	:= {}
	//DbSelectArea("SB1")
	//DbSetOrder(1)

	DbSelectArea("Z24")
	DbSetOrder(1)

	If Select("QRYSA7") <> 0
		dbSelectArea("QRYSA7")
		QRYSA7->(dbCloseArea())
	EndIf

	cQuery := ""
	cQuery := "SELECT A7_FILIAL,  A7_PRODUTO, A7_CODCLI, B1_LOCPAD, A7_LOJA, A7_DESCCLI, A7_CLIENTE, A7_CUBM3, A7_XCODOPE, A7_XQTDPAL "
	cQuery += "FROM "+RetSqlName("SA7")+ " SA7 "
	cQuery += "INNER JOIN "+RetSqlName("SB1")+"  SB1 ON SB1.B1_FILIAL = SA7.A7_FILIAL AND SB1.B1_COD = A7_PRODUTO "
	cQuery += "WHERE SA7.D_E_L_E_T_ = ' ' AND SA7.A7_PRODUTO  BETWEEN '"+MV_PAR07+"'  AND  '"+MV_PAR08+"'  "
	cQuery += "AND SA7.A7_CLIENTE BETWEEN '"+MV_PAR01+"' AND '"+MV_PAR02+"' "
	cQuery += "AND SA7.A7_LOJA BETWEEN '"+MV_PAR03+"' AND   '"+MV_PAR04+"' "
	cQuery += "AND SA7.A7_XCODOPE <>  ' ' "


	cQuery := ChangeQuery(cQuery)

	TcQuery cQuery New Alias "QRYSA7"

	dbSelectArea("QRYSA7")
	QRYSA7->(dbGoTop())

	While QRYSA7->(!Eof())

		dbSelectArea("Z20")
		dbSetOrder(1)
		dbSeek( xFilial("Z20") +  QRYSA7->A7_XCODOPE  )


		dbSelectArea("Z22")
		dbSetOrder(2)
		if dbSeek(xFilial("Z22") + QRYSA7->A7_XCODOPE +  QRYSA7->A7_CLIENTE +  QRYSA7->A7_LOJA )


			While Z22->(!EOF()) .AND. Z22->Z22_FILIAL + Z22->Z22_OPER  +  Z22->Z22_CLIENT + Z22->Z22_LOJA == xFilial("Z22") + QRYSA7->A7_XCODOPE  +  QRYSA7->A7_CLIENTE +  QRYSA7->A7_LOJA


				dbSelectArea("Z21")
				dbSetOrder(1)
				dbSeek(xFilial("Z21") + Z22->Z22_SERVIC)


				IF alltrim(Z21->Z21_TPCALC) == '1'  .AND.  Z22->Z22_TIPO <> '4'  .AND.  Z22->Z22_TIPO <> '3' .AND.  Z22->Z22_TIPO <> '5'


					ddtest := mv_par05

					while ddtest <= mv_par06

						aSaldos		:=	CalcEst(QRYSA7->A7_PRODUTO,QRYSA7->B1_LOCPAD, ddtest+1)

						nQuant		:=	aSaldos[1]
						nValor 		:=  0
						nValPag		:=  0

						dbSelectArea("SB1")
						dbSetOrder(1)
						dbSeek(xFilial("SB1") +  QRYSA7->A7_PRODUTO)

						nPeso   	:=  SB1->B1_PESBRU
						nCubagem 	:=  0
						if   Z20->Z20_TIPOPE == '1'
							nCubagem 	:= 	QRYSA7->A7_CUBM3
						elseif  Z20->Z20_TIPOPE == '3'
							nCubagem  	:=   (( nQuant * nPeso )/1000)
						endif

						IF Z20->Z20_TIPOPE == '1' //M3
							nValor := ( nCubagem * Z22->Z22_VALOR )  * nQuant
							nValPag := ( nCubagem * Z22->Z22_VALPAG )  * nQuant
						ELSEIF  Z20->Z20_TIPOPE == '2'	//POS PORTA PALET
							nValor := ( nQuant / QRYSA7->A7_XQTDPAL )  * Z22->Z22_VALOR
							nValPag := ( nQuant / QRYSA7->A7_XQTDPAL )  * Z22->Z22_VALPAG
						ELSEIF  Z20->Z20_TIPOPE == '3'  // POR PESO
							nValor := (( nQuant * nPeso )/1000)  * Z22->Z22_VALOR
							nValPag := (( nQuant * nPeso )/1000)  * Z22->Z22_VALPAG
						ELSEIF  Z20->Z20_TIPOPE == '4' // POR UNIDADE
							nValor :=  nQuant	 * Z22->Z22_VALOR
							nValPag :=  nQuant	 * Z22->Z22_VALPAG
						ENDIF


						xservic := Z22->Z22_SERVIC

						xoper   := Z22->Z22_OPER




						if nQuant > 0   .AND. nValor > 0
							
							ntxadv := 0							
							If Z22->Z22_TIPO == "1" // Se armazenagem calcula advalorem sobre pico
								ntxadv  := (Z22->Z22_PERADV /100)
							ElseIf Z22->Z22_TIPO == "2" // Aqui calcula advalorem como servico normal sobre tudo
								ntxadv  := (sfBusZ22(QRYSA7->A7_CLIENTE,QRYSA7->A7_LOJA,QRYSA7->A7_XCODOPE)/100)
							EndIf
							nvlradv := 0
							cDoc    := ""
							if ntxadv > 0
								nCusto := 0
								nCusto := sfBusSD1(QRYSA7->A7_CLIENTE, QRYSA7->A7_LOJA,  QRYSA7->A7_PRODUTO )[1]
								cDoc   := sfBusSD1(QRYSA7->A7_CLIENTE, QRYSA7->A7_LOJA,  QRYSA7->A7_PRODUTO )[2]
								nvlradv :=  (nQuant * nCusto) * ntxadv
								/*
								If Z22->Z22_SERVIC= '004'
									Alert("Produto:" +AllTrim(QRYSA7->A7_PRODUTO )+" Valor:"+Str(nCusto)+"")
								EndIf 
								*/
							ENDIF
							//FIM DO CALCULO DO ADVALOREN

							DbSelectArea("Z24")
							DbSetOrder(1)
							if !DBSEEK(QRYSA7->A7_FILIAL + QRYSA7->A7_CLIENTE + QRYSA7->A7_LOJA + QRYSA7->A7_PRODUTO + DTOS(ddtest) +  QRYSA7->A7_XCODOPE  + xservic   )
								reclock("Z24" , .t. )
								Z24->Z24_FILIAL		:= QRYSA7->A7_FILIAL 
								Z24->Z24_CLIENT		:= QRYSA7->A7_CLIENTE
								Z24->Z24_LOJA 		:= QRYSA7->A7_LOJA
								Z24->Z24_NOMCLI		:= Posicione("SA1", 1, xFilial("SA1") +  QRYSA7->A7_CLIENTE + QRYSA7->A7_LOJA , "A1_NOME")
								IF Z22->Z22_TIPO == '2'
									Z24->Z24_VALOR 		:= nvlradv
								ELSE
									Z24->Z24_VALOR 		:= nValor
								ENDIF
								Z24->Z24_PERCUB		:= nCubagem
								Z24->Z24_QTDARM		:= nQuant
								Z24->Z24_STATUS		:= '0'
								Z24->Z24_DATA 		:=  ddtest
								Z24->Z24_USUARI		:= SUBSTR(CUSUARIO, 7, 15)
								Z24->Z24_PRODUT		:= QRYSA7->A7_PRODUTO
								Z24->Z24_DESPRO		:= QRYSA7->A7_DESCCLI
								Z24->Z24_ADVALO		:= nvlradv
								Z24->Z24_OPER		:= xoper
								Z24->Z24_SERVIC		:= xservic
								Z24->Z24_DOC 		:= cDoc
								Z24->Z24_VALPAG		:= nValPag
								Z24->Z24_FORNEC		:= Z22->Z22_FORNEC
								Z24->Z24_LJFORN		:= Z22->Z22_LJFORN

								msunlock("Z24")
							else

								if alltrim(Z24->Z24_STATUS) == '1'
									Alert("Este registro já foi gerado fatura Cliente: " +  Z24->Z24_CLIENT +  " Produto: " + Z24->Z24_PRODUT + " Data: " + dtoc(Z24->Z24_DATA) )
								else
									reclock("Z24" , .f. )
									Z24->Z24_FILIAL		:= QRYSA7->A7_FILIAL
									Z24->Z24_CLIENT		:= QRYSA7->A7_CLIENTE
									Z24->Z24_LOJA 		:= QRYSA7->A7_LOJA
									Z24->Z24_NOMCLI		:= Posicione("SA1", 1, xFilial("SA1") +  QRYSA7->A7_CLIENTE + QRYSA7->A7_LOJA , "A1_NOME")
									IF Z22->Z22_TIPO == '2'
										Z24->Z24_VALOR 		:= nvlradv
									ELSE
										Z24->Z24_VALOR 		:= nValor
									ENDIF
									Z24->Z24_PERCUB		:= nCubagem
									Z24->Z24_QTDARM		:= nQuant
									Z24->Z24_STATUS		:= '0'
									Z24->Z24_DATA 		:=  ddtest
									Z24->Z24_USUARI		:= SUBSTR(CUSUARIO, 7, 15)
									Z24->Z24_PRODUT		:= QRYSA7->A7_PRODUTO
									Z24->Z24_DESPRO		:= QRYSA7->A7_DESCCLI
									Z24->Z24_ADVALO		:= nvlradv
									Z24->Z24_OPER		:= xoper
									Z24->Z24_SERVIC		:= xservic
									Z24->Z24_DOC 		:= cDoc
									Z24->Z24_VALPAG		:= nValPag
									Z24->Z24_FORNEC		:= Z22->Z22_FORNEC
									Z24->Z24_LJFORN		:= Z22->Z22_LJFORN
									msunlock("Z24")
								endif
							endif
						endif
						ddtest := ddtest + 1

					enddo
				endif
				dbSelectArea("Z22")
				DBSKIP()
			ENDDO
		endif

		DbSelectArea("QRYSA7")
		DbSkip()
	Enddo
	QRYSA7->(DbCloseArea())


Return

//---------------------------------------------------------------------------------------
// Analista   :Júnior Conte - 31/07/2018
// Nome função: sfGeraZ23
// Parametros :
// Objetivo   : Efetua a geração da tabela Z23 das operações de armazenagem
// Retorno    :
// Alterações :
//---------------------------------------------------------------------------------------

Static Function  sfGeraZ23()


	If Select("QRYZ24") <> 0
		dbSelectArea("QRYZ24")
		QRYZ24->(dbCloseArea())
	EndIf

	cQuery := ""
	cQuery := "SELECT  Z24_FILIAL, Z24_CLIENT, Z24_LOJA, Z24_OPER, Z24_SERVIC, Z24_DATA,   SUM(Z24_VALOR) Z24_VALOR,  SUM(Z24_ADVALO) Z24_ADVALO, SUM(Z24_PERCUB) Z24_PERCUB,  "
	cQuery += " SUM(Z24_VALPAG) Z24_VALPAG, Z24_FORNEC, Z24_LJFORN "
	cQuery += "FROM "+RetSqlName("Z24")+ " Z24 "
	cQuery += "WHERE Z24.D_E_L_E_T_ = ' '  AND Z24.Z24_STATUS = '0'  "
	cQuery += "AND Z24.Z24_CLIENT BETWEEN '"+MV_PAR01+"' AND '"+MV_PAR02+"' "
	cQuery += "AND Z24.Z24_LOJA   BETWEEN '"+MV_PAR03+"' AND   '"+MV_PAR04+"' "
	cQuery += "AND Z24.Z24_DATA   BETWEEN '"+DTOS(MV_PAR05)+ "' AND   '"+DTOS(MV_PAR06)+"' "
	cQuery += "AND Z24.Z24_PRODUT BETWEEN '" + MV_PAR07 + "' AND   '" + MV_PAR08 + "' "
	cQuery += "GROUP BY Z24_FILIAL, Z24_CLIENT, Z24_LOJA ,Z24_OPER, Z24_SERVIC, Z24_DATA, Z24_FORNEC, Z24_LJFORN  "

	cQuery := ChangeQuery(cQuery)

	TcQuery cQuery New Alias "QRYZ24"

	dbSelectArea("QRYZ24")
	QRYZ24->(dbGoTop())


	WHILE  QRYZ24->(!EOF())

		nLimQtd 	:= 0
		nVlrLim 	:= 0		
		nVlr 		:= QRYZ24->Z24_VALOR
		nVlrOri		:= 0

		dbSelectArea("Z22")
		dbSetOrder(1)
		if DbSeek(QRYZ24->Z24_FILIAL +  QRYZ24->Z24_OPER +  QRYZ24->Z24_SERVIC  +   QRYZ24->Z24_CLIENT  +  QRYZ24->Z24_LOJA  )
			nLimQtd := Z22->Z22_LIMQTD
			nVlrLim := Z22->Z22_VLRLIM
			nVlrOri	:= Z22->Z22_VALOR
		endif

		nVlrMaior := 0
		If QRYZ24->Z24_PERCUB > nLimQtd
			nVlr := nLimQtd * nVlrOri
			nVlrMaior := (QRYZ24->Z24_PERCUB - nLimQtd) * nVlrLim
		EndIf


		DbSelectArea("Z23")
		DbSetOrder(1)
		if !DBSEEK(  QRYZ24->Z24_FILIAL +  QRYZ24->Z24_CLIENT +  QRYZ24->Z24_LOJA  + QRYZ24->Z24_OPER + QRYZ24->Z24_SERVIC  +  '0' + QRYZ24->Z24_DATA    )

			reclock("Z23" , .T. )
			Z23->Z23_FILIAL		:= QRYZ24->Z24_FILIAL
			Z23->Z23_OPER		:= QRYZ24->Z24_OPER
			Z23->Z23_SERVIC		:= QRYZ24->Z24_SERVIC
			Z23->Z23_CLIENT		:= QRYZ24->Z24_CLIENT
			Z23->Z23_LOJA 		:= QRYZ24->Z24_LOJA
			Z23->Z23_NOMCLI		:= Posicione("SA1", 1, xFilial("SA1") +  QRYZ24->Z24_CLIENT + QRYZ24->Z24_LOJA , "A1_NOME")
			Z23->Z23_VALOR 		:= nVlr + nVlrMaior
			Z23->Z23_ADVALO 	:= QRYZ24->Z24_ADVALO
			Z23->Z23_STATUS		:= '0'
			Z23->Z23_DATA 		:= STOD(QRYZ24->Z24_DATA)
			Z23->Z23_USUARI		:= SUBSTR(CUSUARIO, 7, 15)
			Z23->Z23_HORA		:= SUBSTR(TIME(), 1,5)
			Z23->Z23_FORNEC		:= QRYZ24->Z24_FORNEC
			Z23->Z23_LJFORN		:= QRYZ24->Z24_LJFORN
			Z23->Z23_VALPAG		:= QRYZ24->Z24_VALPAG  
			Z23->Z23_PESOB		:= QRYZ24->Z24_PERCUB * 1000
			msunlock("Z23")
		else

			reclock("Z23" , .F. )
			Z23->Z23_FILIAL		:= QRYZ24->Z24_FILIAL
			Z23->Z23_OPER		:= QRYZ24->Z24_OPER
			Z23->Z23_SERVIC		:= QRYZ24->Z24_SERVIC
			Z23->Z23_CLIENT		:= QRYZ24->Z24_CLIENT
			Z23->Z23_LOJA 		:= QRYZ24->Z24_LOJA
			Z23->Z23_NOMCLI		:= Posicione("SA1", 1, xFilial("SA1") +  QRYZ24->Z24_CLIENT + QRYZ24->Z24_LOJA , "A1_NOME")
			Z23->Z23_VALOR 		:= nVlr + nVlrMaior
			Z23->Z23_ADVALO 	:= QRYZ24->Z24_ADVALO
			Z23->Z23_STATUS		:= '0'
			Z23->Z23_DATA 		:= STOD(QRYZ24->Z24_DATA)
			Z23->Z23_USUARI		:= SUBSTR(CUSUARIO, 7, 15)
			Z23->Z23_HORA		:= SUBSTR(TIME(), 1,5)
			Z23->Z23_FORNEC		:= QRYZ24->Z24_FORNEC
			Z23->Z23_LJFORN		:= QRYZ24->Z24_LJFORN
			Z23->Z23_VALPAG		:= QRYZ24->Z24_VALPAG  
			Z23->Z23_PESOB		:= QRYZ24->Z24_PERCUB * 1000
			msunlock("Z23")
		endif

		DbSelectArea("QRYZ24")
		DbSkip()
	ENDDO

	QRYZ24->(DbCloseArea())

Return

/*  Retorna custo da ultima mercadoria */
Static Function  sfBusSD1(CCODCLI, CLOJACLI,  CPRODUTO)


	If Select("QRYSD1") <> 0
		dbSelectArea("QRYSD1")
		QRYSD1->(dbCloseArea())
	EndIf

	cQuery := ""
	cQuery := "SELECT  D1_DTDIGIT, D1_DOC,  D1_VUNIT "
	cQuery += "FROM "+RetSqlName("SD1")+ " SD1 "
	cQuery += "WHERE SD1.D_E_L_E_T_ = ' '  "
	cQuery += "AND SD1.D1_FORNECE = '"+CCODCLI+"' "
	cQuery += "AND SD1.D1_LOJA    = '"+CLOJACLI+"' "
	cQuery += "AND SD1.D1_COD     = '"+CPRODUTO+"' "
	cQuery += "ORDER BY D1_DTDIGIT, D1_DOC  DESC "

	cQuery := ChangeQuery(cQuery)

	TcQuery cQuery New Alias "QRYSD1"

	dbSelectArea("QRYSD1")
	QRYSD1->(dbGoTop())


	NCUSTO := 0
	NCUSTO := QRYSD1->D1_VUNIT

	CDOC  := ""
	CDOC  := QRYSD1->D1_DOC



Return  { NCUSTO , CDOC }

/* Gera advaloren */
Static Function  sfGerAdv()


	If Select("QRYZ24") <> 0
		dbSelectArea("QRYZ24")
		QRYZ24->(dbCloseArea())
	EndIf

	cQuery := ""
	cQuery := "SELECT  Z24_FILIAL, Z24_CLIENT, Z24_LOJA, Z24_OPER, Z24_SERVIC, Z24_DATA,  SUM(Z24_ADVALO) VALOR  "
	cQuery += "FROM "+RetSqlName("Z24")+ " Z24 "
	cQuery += "WHERE Z24.D_E_L_E_T_ = ' '  AND Z24.Z24_STATUS = '0'  "
	cQuery += "AND Z24.Z24_CLIENT BETWEEN '"+MV_PAR01+"' AND '"+MV_PAR02+"' "
	cQuery += "AND Z24.Z24_LOJA   BETWEEN '"+MV_PAR03+"' AND   '"+MV_PAR04+"' "
	cQuery += "AND Z24.Z24_DATA   BETWEEN '"+DTOS(MV_PAR05)+ "' AND   '"+DTOS(MV_PAR06)+"' "
	cQuery += "AND Z24.Z24_PRODUT BETWEEN '"+ MV_PAR07 + "' AND   '"+ MV_PAR08 +"' "
	cQuery += "GROUP BY Z24_FILIAL, Z24_CLIENT, Z24_LOJA ,Z24_OPER, Z24_SERVIC, Z24_DATA  "

	cQuery := ChangeQuery(cQuery)

	TcQuery cQuery New Alias "QRYZ24"

	dbSelectArea("QRYZ24")
	QRYZ24->(dbGoTop())


	WHILE  QRYZ24->(!EOF())

		IF QRYZ24->VALOR > 0
			DbSelectArea("Z23")
			DbSetOrder(1)
			if !DBSEEK(  QRYZ24->Z24_FILIAL +  QRYZ24->Z24_CLIENT +  QRYZ24->Z24_LOJA  + QRYZ24->Z24_OPER +  '004'  +  '0' + QRYZ24->Z24_DATA    )

				reclock("Z23" , .T. )
				Z23->Z23_FILIAL		:= QRYZ24->Z24_FILIAL
				Z23->Z23_OPER		:= QRYZ24->Z24_OPER
				Z23->Z23_SERVIC		:= '004'
				Z23->Z23_CLIENT		:= QRYZ24->Z24_CLIENT
				Z23->Z23_LOJA 		:= QRYZ24->Z24_LOJA
				Z23->Z23_NOMCLI		:= Posicione("SA1", 1, xFilial("SA1") +  QRYZ24->Z24_CLIENT + QRYZ24->Z24_LOJA , "A1_NOME")
				Z23->Z23_VALOR 		:= QRYZ24->VALOR
				Z23->Z23_STATUS		:= '0'
				Z23->Z23_DATA 		:= STOD(QRYZ24->Z24_DATA)
				Z23->Z23_USUARI		:= SUBSTR(CUSUARIO, 7, 15)
				Z23->Z23_HORA		:= SUBSTR(TIME(), 1,5)
				msunlock("Z23")
			else
				reclock("Z23" , .F. )
				Z23->Z23_FILIAL		:= QRYZ24->Z24_FILIAL
				Z23->Z23_OPER		:= QRYZ24->Z24_OPER
				Z23->Z23_SERVIC		:= '004'
				Z23->Z23_CLIENT		:= QRYZ24->Z24_CLIENT
				Z23->Z23_LOJA 		:= QRYZ24->Z24_LOJA
				Z23->Z23_NOMCLI		:= Posicione("SA1", 1, xFilial("SA1") +  QRYZ24->Z24_CLIENT + QRYZ24->Z24_LOJA , "A1_NOME")
				Z23->Z23_VALOR 		:= QRYZ24->VALOR
				Z23->Z23_STATUS		:= '0'
				Z23->Z23_DATA 		:= STOD(QRYZ24->Z24_DATA)
				Z23->Z23_USUARI		:= SUBSTR(CUSUARIO, 7, 15)
				Z23->Z23_HORA		:= SUBSTR(TIME(), 1,5)
				msunlock("Z23")
			endif
		ENDIF

		DbSelectArea("QRYZ24")
		DbSkip()
	ENDDO

	QRYZ24->(DbCloseArea())

Return

/*  Retorna valor da amarração operação x serviço */
Static Function  sfBusZ22(CCODCLI, CLOJACLI, COPER)


	If Select("QRYSD1") <> 0
		dbSelectArea("QRYSD1")
		QRYSD1->(dbCloseArea())
	EndIf

	cQuery := ""
	cQuery := "SELECT  Z22_VALOR "
	cQuery += "FROM "+RetSqlName("Z22")+ " Z22 "
	cQuery += "WHERE Z22.D_E_L_E_T_ = ' '  "
	cQuery += "AND Z22.Z22_OPER = '"+COPER+"' "
	cQuery += "AND Z22.Z22_CLIENT = '"+CCODCLI+"' "
	cQuery += "AND Z22.Z22_LOJA   = '"+CLOJACLI+"' "
	cQuery += "AND Z22.Z22_SERVIC = '004' "


	cQuery := ChangeQuery(cQuery)

	TcQuery cQuery New Alias "QRYSD1"

	dbSelectArea("QRYSD1")
	QRYSD1->(dbGoTop())


	XVALOR := 0
	XVALOR := QRYSD1->Z22_VALOR



Return  XVALOR

//---------------------------------------------------------------------------------------
// Analista   :Júnior Conte - 31/07/2018
// Nome função: sfGeraTXS
// Parametros :
// Objetivo   : Gera Taxas de forma automática.
// Alterações :
//---------------------------------------------------------------------------------------

Static Function  sfGeraTXS()

	Local nI

	If Select("QRYZ22") <> 0
		dbSelectArea("QRYZ22")
		QRYZ22->(dbCloseArea())
	EndIf

	cQuery := "SELECT  *  "
	cQuery += "FROM "+RetSqlName("Z22")+ " Z22 "
	cQuery += "WHERE Z22.D_E_L_E_T_ = ' '  "
	cQuery += "AND Z22.Z22_CLIENT BETWEEN '"+MV_PAR01+"' AND '"+MV_PAR02+"' "
	cQuery += "AND Z22.Z22_LOJA   BETWEEN '"+MV_PAR03+"' AND   '"+MV_PAR04+"' AND Z22.Z22_TIPO IN ('3', '4', '5') "


	cQuery := ChangeQuery(cQuery)

	TcQuery cQuery New Alias "QRYZ22"

	dbSelectArea("QRYZ22")
	QRYZ22->(dbGoTop())


	WHILE  !QRYZ22->(EOF())

		_xTipox := POSICIONE("Z20", 1, xFilial("Z20")+ QRYZ22->Z22_OPER, "Z20_TIPOPE")

		if  Alltrim(_xTipox) == '3' // Movimentacao TONELADA

			ddtest := mv_par05

			while ddtest <= mv_par06

				aDocs := {}
				if QRYZ22->Z22_TIPO == '4' // taxa movimentação entrada
					aDocs := sfRPsd1(QRYZ22->Z22_CLIENT, QRYZ22->Z22_LOJA, ddtest ) //[1] Doc [2]-PesoB
				elseif   QRYZ22->Z22_TIPO == '5' // taxa movimentação de saída
					aDocs := sfRPsd2(QRYZ22->Z22_CLIENT, QRYZ22->Z22_LOJA, ddtest ) //[1] Doc [2]-PesoB [3]-CNPJ Destino
				endif

				For nI := 1 To Len(aDocs)

					DbSelectArea("Z23")
					DbSetOrder(3)
					if !DBSEEK( QRYZ22->Z22_FILIAL+QRYZ22->Z22_CLIENT+QRYZ22->Z22_LOJA+QRYZ22->Z22_OPER+QRYZ22->Z22_SERVIC + aDocs[nI][1] + DTOS(ddtest) )
						reclock("Z23" , .T. )
						Z23->Z23_FILIAL		:= xFilial("Z23")
						Z23->Z23_OPER		:= QRYZ22->Z22_OPER
						Z23->Z23_SERVIC		:= QRYZ22->Z22_SERVIC
						Z23->Z23_CLIENT		:= QRYZ22->Z22_CLIENT
						Z23->Z23_LOJA 		:= QRYZ22->Z22_LOJA
						Z23->Z23_NOMCLI		:= Posicione("SA1", 1, xFilial("SA1") +  QRYZ22->Z22_CLIENT + QRYZ22->Z22_LOJA , "A1_NOME")
						Z23->Z23_STATUS		:= '0'
						Z23->Z23_DATA 		:= ddtest
						Z23->Z23_DTDE 		:= ddtest
						Z23->Z23_DTATE 		:= ddtest
						If (QRYZ22->Z22_TIPO == '5' .And. aDocs[nI][3] == "06032022000110") // Nao paga OUT quando for Atria
							Z23->Z23_VALOR 		:= 0 // PESO B
							Z23->Z23_VALPAG 	:= 0 // PESO B
						Else
							Z23->Z23_VALOR 		:= (QRYZ22->Z22_VALOR * ( aDocs[nI][2] /1000 )) // PESO B
							Z23->Z23_VALPAG 	:= (QRYZ22->Z22_VALPAG * ( aDocs[nI][2] /1000 )) // PESO B
						EndIf
						Z23->Z23_FORNEC		:= QRYZ22->Z22_FORNEC
						Z23->Z23_LJFORN		:= QRYZ22->Z22_LJFORN
						Z23->Z23_DOC		:= aDocs[nI][1]
						Z23->Z23_PESOB		:= aDocs[nI][2]
						Z23->Z23_USUARI		:= SUBSTR(CUSUARIO, 7, 15)
						Z23->Z23_HORA		:= SUBSTR(TIME(), 1,5)
						msunlock("Z23")

					else
						reclock("Z23" , .F. )
						Z23->Z23_FILIAL		:= xFilial("Z23")
						Z23->Z23_OPER		:= QRYZ22->Z22_OPER
						Z23->Z23_SERVIC		:= QRYZ22->Z22_SERVIC
						Z23->Z23_CLIENT		:= QRYZ22->Z22_CLIENT
						Z23->Z23_LOJA 		:= QRYZ22->Z22_LOJA
						Z23->Z23_NOMCLI		:= Posicione("SA1", 1, xFilial("SA1") +  QRYZ22->Z22_CLIENT + QRYZ22->Z22_LOJA , "A1_NOME")
						Z23->Z23_STATUS		:= '0'
						Z23->Z23_DATA 		:= ddtest
						Z23->Z23_DTDE 		:= ddtest
						Z23->Z23_DTATE 		:= ddtest
						If (QRYZ22->Z22_TIPO == '5' .And. aDocs[nI][3] == "06032022000110") // Nao paga OUT quando for Atria
							Z23->Z23_VALOR 		:= 0
							Z23->Z23_VALPAG		:= 0
						Else
							Z23->Z23_VALOR 		:= (QRYZ22->Z22_VALOR   * ( aDocs[nI][2] /1000 ))
							Z23->Z23_VALPAG		:= (QRYZ22->Z22_VALPAG   * ( aDocs[nI][2] /1000 ))
						EndIf
						Z23->Z23_FORNEC		:= QRYZ22->Z22_FORNEC
						Z23->Z23_LJFORN		:= QRYZ22->Z22_LJFORN
						Z23->Z23_DOC		:= aDocs[nI][1]
						Z23->Z23_PESOB		:= aDocs[nI][2]
						Z23->Z23_USUARI		:= SUBSTR(CUSUARIO, 7, 15)
						Z23->Z23_HORA		:= SUBSTR(TIME(), 1,5)
						msunlock("Z23")

					ENDIF
				Next

				ddtest := ddtest + 1
			enddo

		elseif  Alltrim(_xTipox) == '1' // Movimentacao M3

			ddtest := mv_par05

			while ddtest <= mv_par06

				DbSelectArea("Z23")
				DbSetOrder(3)
				if !DBSEEK( QRYZ22->Z22_FILIAL+QRYZ22->Z22_CLIENT+QRYZ22->Z22_LOJA+QRYZ22->Z22_OPER+QRYZ22->Z22_SERVIC + Space(9) + DTOS(ddtest) )

					NQTDNOTA 	:= 0
					NQTDNOTA	:= U_RLLOG02Z(QRYZ22->Z22_CLIENT, QRYZ22->Z22_LOJA,ddtest,ddtest, QRYZ22->Z22_TIPO, QRYZ22->Z22_VALOR)[1]
					NXCUSTO   := 0
					NXCUSTO	:= U_RLLOG02Z(QRYZ22->Z22_CLIENT, QRYZ22->Z22_LOJA,ddtest,ddtest, QRYZ22->Z22_TIPO, QRYZ22->Z22_VALOR)[2]


					IF NQTDNOTA > 0

						reclock("Z23" , .T. )
						Z23->Z23_FILIAL		:= xFilial("Z23")
						Z23->Z23_OPER		:= QRYZ22->Z22_OPER
						Z23->Z23_SERVIC		:= QRYZ22->Z22_SERVIC
						Z23->Z23_CLIENT		:= QRYZ22->Z22_CLIENT
						Z23->Z23_LOJA 		:= QRYZ22->Z22_LOJA
						Z23->Z23_NOMCLI		:= Posicione("SA1", 1, xFilial("SA1") +  QRYZ22->Z22_CLIENT + QRYZ22->Z22_LOJA , "A1_NOME")
						Z23->Z23_STATUS		:= '0'
						Z23->Z23_DATA 		:= ddtest
						Z23->Z23_DTDE 		:= ddtest
						Z23->Z23_DTATE 		:= ddtest
						//NQTDNOTA 	:= 0
						//NQTDNOTA	:= U_RLLOG02Z(QRYZ22->Z22_CLIENT, QRYZ22->Z22_LOJA,ddtest,ddtest, QRYZ22->Z22_TIPO, QRYZ22->Z22_VALOR)
						Z23->Z23_NRNOTA		:= NQTDNOTA
						nxval := 0
						IF U_RLLOG02W(QRYZ22->Z22_TIPO)
							Z23->Z23_VALOR 		:=   QRYZ22->Z22_VALOR * NQTDNOTA
							//	nxval				:=   QRYZ22->Z22_VALOR * NQTDNOTA
						ELSE
							Z23->Z23_VALOR 		:=   QRYZ22->Z22_VALOR  * NQTDNOTA
							Z23->Z23_ADVALO 	:=   NXCUSTO * ( QRYZ22->Z22_PERADV  / 100	)  // ( quantidade vendida * custo ) * ( z22_peradv / 100 )
							//nxval				:=   QRYZ22->Z22_VALOR
						ENDIF
						//	Z23->Z23_VALOR 		:= U_RLLOG02Y(QRYZ22->Z22_VALOR, NQTDNOTA)
						//Z23->Z23_ADVALO 	:= ( nxval * QRYZ22->Z22_PERADV ) /100
						Z23->Z23_USUARI		:= SUBSTR(CUSUARIO, 7, 15)
						Z23->Z23_HORA		:= SUBSTR(TIME(), 1,5)
						msunlock("Z23")

					ENDIF

				else
					NQTDNOTA  := 0
					NQTDNOTA  := U_RLLOG02Z(QRYZ22->Z22_CLIENT, QRYZ22->Z22_LOJA,ddtest,ddtest, QRYZ22->Z22_TIPO, QRYZ22->Z22_VALOR)[1]

					NXCUSTO   := 0
					NXCUSTO	  := U_RLLOG02Z(QRYZ22->Z22_CLIENT, QRYZ22->Z22_LOJA,ddtest,ddtest, QRYZ22->Z22_TIPO, QRYZ22->Z22_VALOR)[2]

					IF Z23->Z23_STATUS == '0' .AND. NQTDNOTA > 0
						reclock("Z23" , .F. )
						Z23->Z23_FILIAL		:= xFilial("Z23")
						Z23->Z23_OPER		:= QRYZ22->Z22_OPER
						Z23->Z23_SERVIC		:= QRYZ22->Z22_SERVIC
						Z23->Z23_CLIENT		:= QRYZ22->Z22_CLIENT
						Z23->Z23_LOJA 		:= QRYZ22->Z22_LOJA
						Z23->Z23_NOMCLI		:= Posicione("SA1", 1, xFilial("SA1") +  QRYZ22->Z22_CLIENT + QRYZ22->Z22_LOJA , "A1_NOME")
						Z23->Z23_STATUS		:= '0'
						Z23->Z23_DATA 		:= ddtest
						Z23->Z23_DTDE 		:= ddtest
						Z23->Z23_DTATE 		:= ddtest
						Z23->Z23_NRNOTA		:= NQTDNOTA

						nxval := 0

						IF U_RLLOG02W(QRYZ22->Z22_TIPO)
							Z23->Z23_VALOR 		:=   QRYZ22->Z22_VALOR * NQTDNOTA
							//	nxval				:=   QRYZ22->Z22_VALOR * NQTDNOTA
						ELSE
							Z23->Z23_VALOR 		:=   QRYZ22->Z22_VALOR  * NQTDNOTA
							//Z23->Z23_ADVALO 	:= ( nxval * QRYZ22->Z22_PERADV ) /100	// ( quantidade vendida * custo ) * ( z22_peradv / 100 )
							//Z23->Z23_ADVALO 	:=  ( NQTDNOTA  * NXCUSTO )  //( nxval * QRYZ22->Z22_PERADV ) /100	// ( quantidade vendida * custo ) * ( z22_peradv / 100 )
							Z23->Z23_ADVALO 	:=   NXCUSTO * ( QRYZ22->Z22_PERADV  / 100	)
							//nxval				:=   QRYZ22->Z22_VALOR
						ENDIF
						//	Z23->Z23_VALOR 		:= U_RLLOG02Y(QRYZ22->Z22_VALOR, NQTDNOTA)
						//Z23->Z23_ADVALO 	:= ( nxval * QRYZ22->Z22_PERADV ) /100
						Z23->Z23_USUARI		:= SUBSTR(CUSUARIO, 7, 15)
						Z23->Z23_HORA		:= SUBSTR(TIME(), 1,5)
						msunlock("Z23")
					ELSE
						ALERT("Cliente com calculo de taxas já faturada para este período. " + Z23->Z23_NOMCLI	 )
					ENDIF

				endif

				ddtest := ddtest + 1

			enddo

		ElseIf Alltrim(_xTipox) == '4' // Movimentacao UNIDADE

			ddtest := mv_par05

			while ddtest <= mv_par06

				aDocs := {}
				if QRYZ22->Z22_TIPO == '4' // taxa movimentação entrada
					aDocs := sfUNsd1(QRYZ22->Z22_CLIENT, QRYZ22->Z22_LOJA, ddtest ) //[1] Doc [2]-Und
				elseif   QRYZ22->Z22_TIPO == '5' // taxa movimentação de saída
					aDocs := sfUNsd2(QRYZ22->Z22_CLIENT, QRYZ22->Z22_LOJA, ddtest ) //[1] Doc [2]-Und
				endif

				For nI := 1 To Len(aDocs)

					DbSelectArea("Z23")
					DbSetOrder(3)
					if !DBSEEK( QRYZ22->Z22_FILIAL+QRYZ22->Z22_CLIENT+QRYZ22->Z22_LOJA+QRYZ22->Z22_OPER+QRYZ22->Z22_SERVIC + aDocs[nI][1] + DTOS(ddtest) )
						reclock("Z23" , .T. )
						Z23->Z23_FILIAL		:= xFilial("Z23")
						Z23->Z23_OPER		:= QRYZ22->Z22_OPER
						Z23->Z23_SERVIC		:= QRYZ22->Z22_SERVIC
						Z23->Z23_CLIENT		:= QRYZ22->Z22_CLIENT
						Z23->Z23_LOJA 		:= QRYZ22->Z22_LOJA
						Z23->Z23_NOMCLI		:= Posicione("SA1", 1, xFilial("SA1") +  QRYZ22->Z22_CLIENT + QRYZ22->Z22_LOJA , "A1_NOME")
						Z23->Z23_STATUS		:= '0'
						Z23->Z23_DATA 		:= ddtest
						Z23->Z23_DTDE 		:= ddtest
						Z23->Z23_DTATE 		:= ddtest
						Z23->Z23_VALOR 		:= (QRYZ22->Z22_VALOR * aDocs[nI][2]) // UND
						Z23->Z23_VALPAG 	:= (QRYZ22->Z22_VALPAG * aDocs[nI][2]) // UND
						Z23->Z23_FORNEC		:= QRYZ22->Z22_FORNEC
						Z23->Z23_LJFORN		:= QRYZ22->Z22_LJFORN
						Z23->Z23_DOC		:= aDocs[nI][1]
						Z23->Z23_PESOB		:= 0
						Z23->Z23_USUARI		:= SUBSTR(CUSUARIO, 7, 15)
						Z23->Z23_HORA		:= SUBSTR(TIME(), 1,5)
						msunlock("Z23")

					else
						reclock("Z23" , .F. )
						Z23->Z23_FILIAL		:= xFilial("Z23")
						Z23->Z23_OPER		:= QRYZ22->Z22_OPER
						Z23->Z23_SERVIC		:= QRYZ22->Z22_SERVIC
						Z23->Z23_CLIENT		:= QRYZ22->Z22_CLIENT
						Z23->Z23_LOJA 		:= QRYZ22->Z22_LOJA
						Z23->Z23_NOMCLI		:= Posicione("SA1", 1, xFilial("SA1") +  QRYZ22->Z22_CLIENT + QRYZ22->Z22_LOJA , "A1_NOME")
						Z23->Z23_STATUS		:= '0'
						Z23->Z23_DATA 		:= ddtest
						Z23->Z23_DTDE 		:= ddtest
						Z23->Z23_DTATE 		:= ddtest
						Z23->Z23_VALOR 		:= (QRYZ22->Z22_VALOR * aDocs[nI][2] ) // UND
						Z23->Z23_VALPAG		:= (QRYZ22->Z22_VALPAG * aDocs[nI][2] ) // UND
						Z23->Z23_FORNEC		:= QRYZ22->Z22_FORNEC
						Z23->Z23_LJFORN		:= QRYZ22->Z22_LJFORN
						Z23->Z23_DOC		:= aDocs[nI][1]
						Z23->Z23_PESOB		:= 0
						Z23->Z23_USUARI		:= SUBSTR(CUSUARIO, 7, 15)
						Z23->Z23_HORA		:= SUBSTR(TIME(), 1,5)
						msunlock("Z23")

					ENDIF
				Next

				ddtest := ddtest + 1
			enddo

		EndIf

		DbSelectArea("QRYZ22")
		DbSkip()
	ENDDO

	QRYZ22->(DbCloseArea())

Return


/*  Retorna peso notas de entrada por produto e por data de digitação */
Static Function  sfRPsd1(CCODCLI, CLOJACLI, ddtest)

	Local aReturn := {}

	If Select("QRYSD1") <> 0
		QRYSD1->(dbCloseArea())
	EndIf

	cQuery := ""
	cQuery := "SELECT D1_DOC AS DOC, SUM(SB1.B1_PESBRU * SD1.D1_QUANT ) AS PESOB "
	cQuery += "FROM "+RetSqlName("SD1")+ " SD1 "
	cQuery += "INNER JOIN " + RetSqlName("SB1") +" SB1 "
	cQUery += "  ON SB1.D_E_L_E_T_ = ' '  "
	cQuery += "  AND SB1.B1_FILIAL = SD1.D1_FILIAL "
	cQuery += "  AND SB1.B1_COD = SD1.D1_COD"
	cQuery += "  AND SB1.B1_TIPO <> 'MO'"
	cQuery += " INNER JOIN "+RetSqlName("SF4")+ " SF4"
	cQuery += "  ON SF4.D_E_L_E_T_ = ' '"
	cQuery += " AND SF4.F4_FILIAL = SD1.D1_FILIAL"
	cQuery += " AND SF4.F4_CODIGO = SD1.D1_TES"
	cQuery += " AND SF4.F4_ESTOQUE = 'S'"
	cQuery += "WHERE SD1.D_E_L_E_T_ = ' '     "
	cQuery += "AND SD1.D1_FORNECE = '"+CCODCLI+"' "
	cQuery += "AND SD1.D1_LOJA    = '"+CLOJACLI+"' "
	cQuery += "AND SD1.D1_DTDIGIT = '"+dtos(ddtest)+"' "
	cQuery += "GROUP BY D1_DOC "

	cQuery := ChangeQuery(cQuery)

	TcQuery cQuery New Alias "QRYSD1"

	While QRYSD1->(!EoF())
		Aadd(aReturn, {QRYSD1->DOC,QRYSD1->PESOB})
		QRYSD1->(dbSkip())
	EndDo

	QRYSD1->(dbCloseArea())

Return  aReturn


/*  Retorna peso notas de saída por produto e por data de emissao */
Static Function  sfRPsd2(CCODCLI, CLOJACLI, ddtest)

	Local aReturn := {}

	If Select("QRYSD2") <> 0
		QRYSD2->(dbCloseArea())
	EndIf

	cQuery := "SELECT D2_DOC AS DOC, SUM(PESOB) AS PESOB, MAX(CNPJ_DEST) AS CNPJ_DEST
	cQuery += "  FROM ("
	cQuery += "  SELECT D2_DOC,"
	cQuery += "  	D2_SERIE,"
	cQuery += " 	D2_ITEM,"
	cQuery += "  	D2_COD,"
	cQuery += "  	B1.B1_PESBRU * D2.D2_QUANT AS PESOB,"
	cQuery += "  	MAX(Z1.Z1_DEST) AS CNPJ_DEST"
	cQuery += "  FROM "+RetSqlName("SD2")+" D2"
	cQuery += " INNER JOIN "+RetSqlName("SB1")+" B1"
	cQuery += "    ON B1.D_E_L_E_T_ = ' '"
	cQuery += "   AND B1.B1_FILIAL = D2.D2_FILIAL"
	cQuery += "   AND B1.B1_COD = D2.D2_COD"
	cQuery += "   AND B1.B1_TIPO <> 'MO'"
	cQuery += " INNER JOIN "+RetSqlName("SF4")+" F4"
	cQuery += "    ON F4.D_E_L_E_T_ = ' '"
	cQuery += "   AND F4.F4_FILIAL = D2.D2_FILIAL"
	cQuery += "   AND F4.F4_CODIGO = D2.D2_TES"
	cQuery += "   AND F4.F4_ESTOQUE = 'S'"
	cQuery += "  LEFT JOIN "+RetSqlName("SC6")+" C6"
	cQuery += "    ON C6.D_E_L_E_T_ = ' '"
	cQuery += "   AND C6.C6_FILIAL = D2.D2_FILIAL"
	cQuery += "   AND C6.C6_NOTA = D2.D2_DOC"
	cQuery += "   AND C6.C6_SERIE = D2.D2_SERIE"
	cQuery += "   AND C6.C6_PRODUTO = D2.D2_COD"
	cQuery += "  LEFT JOIN "+RetSqlName("SZ2")+" Z2"
	cQuery += "    ON Z2.D_E_L_E_T_ = ' '"
	cQuery += "   AND Z2.Z2_FILIAL = C6.C6_FILIAL"
	cQuery += "   AND Z2.R_E_C_N_O_ = C6.C6_XKEYSZ2"
	cQuery += "  LEFT JOIN "+RetSqlName("SZ1")+" Z1"
	cQuery += "    ON Z1.D_E_L_E_T_ = ' '"
	cQuery += "   AND Z1.Z1_FILIAL = Z2.Z2_FILIAL"
	cQuery += "   AND Z1.Z1_CHAVE = Z2.Z2_CHAVE"
	cQuery += " WHERE D2.D_E_L_E_T_ = ' '"
	cQuery += "   AND D2.D2_EMISSAO = '"+DToS(ddtest)+"'"
	cQuery += "   AND D2.D2_CLIENTE = '"+CCODCLI+"'"
	cQuery += "   AND D2.D2_LOJA = '"+CLOJACLI+"'"
	cQuery += " GROUP BY D2_DOC,
	cQuery += "   D2_SERIE,
	cQuery += "   D2_ITEM,
	cQuery += "   D2_COD,
	cQuery += "   B1.B1_PESBRU * D2.D2_QUANT)"
	cQuery += " GROUP BY D2_DOC"

	cQuery := ChangeQuery(cQuery)

	TcQuery cQuery New Alias "QRYSD2"

	While QRYSD2->(!EoF())
		Aadd(aReturn, {QRYSD2->DOC,QRYSD2->PESOB,QRYSD2->CNPJ_DEST})
		QRYSD2->(dbSkip())
	EndDo

	QRYSD2->(dbCloseArea())

Return  aReturn


/*  Retorna quantidade und de entrada por produto e por data de digitação */
Static Function  sfUNsd1(CCODCLI, CLOJACLI, ddtest)

	Local aReturn := {}

	If Select("QRYSD1") <> 0
		QRYSD1->(dbCloseArea())
	EndIf

	cQuery := ""
	cQuery := "SELECT D1_DOC AS DOC, SUM(SD1.D1_QUANT) AS UND "
	cQuery += "FROM "+RetSqlName("SD1")+ " SD1 "
	cQuery += "INNER JOIN " + RetSqlName("SB1") +" SB1 "
	cQUery += "  ON SB1.D_E_L_E_T_ = ' '  "
	cQuery += "  AND SB1.B1_FILIAL = SD1.D1_FILIAL "
	cQuery += "  AND SB1.B1_COD = SD1.D1_COD"
	cQuery += "  AND SB1.B1_TIPO <> 'MO'"
	cQuery += " INNER JOIN "+RetSqlName("SF4")+ " SF4"
	cQuery += "  ON SF4.D_E_L_E_T_ = ' '"
	cQuery += " AND SF4.F4_FILIAL = SD1.D1_FILIAL"
	cQuery += " AND SF4.F4_CODIGO = SD1.D1_TES"
	cQuery += " AND SF4.F4_ESTOQUE = 'S'"
	cQuery += "WHERE SD1.D_E_L_E_T_ = ' '     "
	cQuery += "AND SD1.D1_FORNECE = '"+CCODCLI+"' "
	cQuery += "AND SD1.D1_LOJA    = '"+CLOJACLI+"' "
	cQuery += "AND SD1.D1_DTDIGIT = '"+dtos(ddtest)+"' "
	cQuery += "GROUP BY D1_DOC "

	cQuery := ChangeQuery(cQuery)

	TcQuery cQuery New Alias "QRYSD1"

	While QRYSD1->(!EoF())
		Aadd(aReturn, {QRYSD1->DOC,QRYSD1->UND})
		QRYSD1->(dbSkip())
	EndDo

	QRYSD1->(dbCloseArea())

Return  aReturn


/*  Retorna peso notas de saída por produto e por data de emissao */
Static Function  sfUNsd2(CCODCLI, CLOJACLI, ddtest)

	Local aReturn := {}

	If Select("QRYSD2") <> 0
		QRYSD2->(dbCloseArea())
	EndIf

	cQuery := "  SELECT D2_DOC AS DOC,"
	cQuery += "  	SUM(D2.D2_QUANT) AS UND"
	cQuery += "  FROM "+RetSqlName("SD2")+" D2"
	cQuery += " INNER JOIN "+RetSqlName("SB1")+" B1"
	cQuery += "    ON B1.D_E_L_E_T_ = ' '"
	cQuery += "   AND B1.B1_FILIAL = D2.D2_FILIAL"
	cQuery += "   AND B1.B1_COD = D2.D2_COD"
	cQuery += "   AND B1.B1_TIPO <> 'MO'"
	cQuery += " INNER JOIN "+RetSqlName("SF4")+" F4"
	cQuery += "    ON F4.D_E_L_E_T_ = ' '"
	cQuery += "   AND F4.F4_FILIAL = D2.D2_FILIAL"
	cQuery += "   AND F4.F4_CODIGO = D2.D2_TES"
	cQuery += "   AND F4.F4_ESTOQUE = 'S'"
	cQuery += " WHERE D2.D_E_L_E_T_ = ' '"
	cQuery += "   AND D2.D2_EMISSAO = '"+DToS(ddtest)+"'"
	cQuery += "   AND D2.D2_CLIENTE = '"+CCODCLI+"'"
	cQuery += "   AND D2.D2_LOJA = '"+CLOJACLI+"'"
	cQuery += " GROUP BY D2_DOC"

	cQuery := ChangeQuery(cQuery)

	TcQuery cQuery New Alias "QRYSD2"

	While QRYSD2->(!EoF())
		Aadd(aReturn, {QRYSD2->DOC,QRYSD2->UND})
		QRYSD2->(dbSkip())
	EndDo

	QRYSD2->(dbCloseArea())

Return  aReturn
