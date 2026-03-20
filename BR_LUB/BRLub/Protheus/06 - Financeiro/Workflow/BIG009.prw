#include "rwmake.ch"
#include "topconn.ch"

User Function BIG009()

	/*/
	ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
	ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
	ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
	ฑฑบPrograma ณBIG009 บ Autor ณ Marcelo                  บ Data ณ  01/12/04 บฑฑ
	ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
	ฑฑบDescricao ณ Workflow Inadimpl๊ncia para Vendedores                     บฑฑ
	ฑฑบ          ณ                                                            บฑฑ
	ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
	ฑฑบUso       ณ Sigafat                                                    บฑฑ
	ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
	ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
	฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
	/*/



	Local aOpenTable := {"SE1","SA1","SA6"}

	If Select("SM0") == 0
		RPCSetType(3)
		RPCSetEnv("14","01","","","","",aOpenTable) // Abre todas as tabelas.
		stExecuta()
		// Executa grava็ใo do Log de Uso da rotina
		U_BFCFGM01()
	Endif
Return


Static Function stExecuta

	//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
	//ณ Declaracao de Variaveis                                             ณ
	//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

	Local oProcess
	Local cDestMail	:= ""
	Local cCodSup	:= ""



	cQry := ""
	cQry += "SELECT E1_VEND1,SUM(E1_SALDO) AS TOTAL "
	cQry += "  FROM "+ RetSqlName("SE1") + " SE1 "
	cQry += " WHERE D_E_L_E_T_ <> '*' "
	cQry += "   AND E1_FILIAL = '" + xFilial("SE1")+ "' "
	cQry += "   AND E1_SALDO > 0 "
	cqry += "   AND E1_TIPO NOT IN('NCC','RA')"
	cQry += "   AND E1_VENCREA < '" + DTOS(Date()-3) + "' "
	cQry += " GROUP BY E1_VEND1 "

	If Select("QRV") <> 0
		dbSelectArea("QRV")
		dbCloseArea()
	Endif

	TCQUERY cQry NEW ALIAS "QRV"

	nTotVend1 :=0.00

	While !eof()

		dbselectarea("SA3")
		Dbsetorder(1)
		Dbseek(xFilial("SA3")+QRV->E1_VEND1)

		cProcess := "100001"
		cStatus  := "100001"
		oProcess := TWFProcess():New(cProcess,OemToAnsi("Titulos sem Portador diแrio"))
		oProcess:NewTask(cStatus,"\workflow\inadimplencia_vendedores.htm")
		//RastreiaWF(oProcess:fProcessID+"."+oProcess:fTaskID,cProcess,cStatus,"Iniciando Processo de Faturamento Diario","WorkFlow")
		//oProcess:cSubject := "Inadimpl๊ncia Big Forta -->>"+SA3->A3_NREDUZ

		oProcess:cSubject := "Inadimpl๊ncia - Vendedor: "+Alltrim(SA3->A3_COD)+"/"+Alltrim(SA3->A3_NREDUZ) + " Empresa:"+cEmpAnt + " " + SM0->M0_NOMECOM
		oProcess:bReturn  := ""
		oHTML := oProcess:oHTML

		cQry := ""
		cQry += "SELECT E1_PREFIXO,E1_NUM,E1_PARCELA,E1_VEND1,E1_CLIENTE,E1_PORTADO,E1_AGEDEP,E1_CONTA,E1_LOJA,E1_VEND2,E1_SALDO,(R_E_C_N_O_) AS ITEM "
		cQry += "  FROM "+ RetSqlName("SE1") + " SE1 "
		cQry += " WHERE D_E_L_E_T_ <> '*' "
		cQry += "   AND E1_FILIAL = '" + xFilial("SE1")+ "' "
		cQry += "   AND E1_SALDO > 0  "
		cQry += "   AND E1_VENCREA < '" + DTOS(Date()-3) + "' "
		cQry += "   AND E1_TIPO NOT IN('NCC','RA') "
		cQry += "   AND E1_VEND1 = '" + QRV->E1_VEND1 + "' "
		cQry += " ORDER BY E1_CLIENTE,E1_LOJA,E1_PREFIXO,E1_NUM,E1_PARCELA ASC"

		If Select("QRG") <> 0
			dbSelectArea("QRG")
			dbCloseArea()
		Endif

		TCQUERY cQry NEW ALIAS "QRG"

		While !Eof()
			dbselectarea("SE1")
			dbsetorder(1)
			dbseek(xFilial("SE1")+QRG->E1_PREFIXO+QRG->E1_NUM+QRG->E1_PARCELA)

			dbselectarea("SA1")
			dbsetorder(1)
			dbseek(xFilial("SA1")+QRG->E1_CLIENTE+QRG->E1_LOJA)

			dbselectarea("SA6")
			dbsetorder(1)
			dbseek(xFilial("SA6")+QRG->E1_PORTADO+QRG->E1_AGEDEP+QRG->E1_CONTA)


			AAdd((oHtml:ValByName("l.titulo" )),QRG->E1_NUM + "-" + QRG->E1_PARCELA)	//titulo parcela
			AAdd((oHtml:ValByName("l.cliente" )),SA1->A1_COD + "/" + SA1->A1_LOJA)      //codigo cliente loja
			AAdd((oHtml:ValByName("l.clienome" )),SA1->A1_NOME)                         //nome cliente
			AAdd((oHtml:ValByName("l.cont" )),SA1->A1_CONTATO)                         //nome cliente
			AAdd((oHtml:ValByName("l.fon" )),"("+SA1->A1_DDD+")"+SA1->A1_TEL)                         //nome cliente
			AAdd((oHtml:ValByName("l.emissao" )),SE1->E1_VENCREA - SE1->E1_EMISSAO)     //prazo vcto titulo
			AAdd((oHtml:ValByName("l.vcto" )),SE1->E1_VENCREA)                          //data vencimento real
			aadd((oHtml:ValByName("l.atras" )),(date() - SE1->E1_VENCREA))              //dias de atraso
			AAdd((oHtml:ValByName("l.vltit" )),transform(QRG->E1_SALDO,'@E 999,999.99'))//saldo do titulo
			AAdd((oHtml:ValByName("l.juros" )),transform((SE1->E1_SALDO * SE1->E1_PORCJUR)/100 * (date() - SE1->E1_VENCREA),'@E 999,999.99'))
			AAdd((oHtml:ValByName("l.port" )),QRG->E1_PORTADO+"-"+SA6->A6_NREDUZ)
			nTotVend1 := nTotVend1 + QRG->E1_SALDO

			dbselectarea("QRG")
			Dbskip()
		Enddo
		QRG->(DbCloseArea())

		oHtml:ValByName("totv",TRANSFORM(QRV->TOTAL,"@E 999,999,999.99"))

		nTotVend1 := 0.00

		//oProcess:cTo := "daniel@forta.com.br"
		cCodSup		:= SA3->A3_SUPER
		cDestMail 	:= Alltrim(SA3->A3_EMAIL)+";"+ Alltrim(SA3->A3_EMTMK) + ";" + Alltrim(SA3->A3_MENS1)+ ";" + Alltrim(SA3->A3_MENS2)

		// Mudan็a feita 21/06/2013 conforme chamado 1558 - solicitando que os gerentes tamb้m recebam a inadimplencia de seus vendedores.
		If !Empty(cCodSup)
			DbSelectArea("SA3")
			DbSetOrder(1)
			If DbSeek(xFilial("SA3")+cCodSup)
				If !Empty(SA3->A3_EMAIL)
					cDestMail += ";"+SA3->A3_EMAIL
				Endif
			Endif
		Endif

		oProcess:cTo := U_BFFATM15(cDestMail,"BIG009")

		oProcess:Start()
		oProcess:Finish()

		// For็a disparo dos e-mails pendentes do workflow
		WFSENDMAIL()

		Dbselectarea("QRV")
		dbskip()
	Enddo

	QRV->(DbCloseArea())

Return
