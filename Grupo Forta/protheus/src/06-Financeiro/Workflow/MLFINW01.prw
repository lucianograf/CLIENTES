
#include "rwmake.ch"
#include "topconn.ch"


/*/{Protheus.doc} MLFINW01
//TODO Workflow de Inadimplência - Enviado para cada Vendedor 
@author Marcelo Alberto Lauschner
@since 19/02/2020
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function MLFINW01()
	
	Local dDataini 	:= ""
	Local aCond		:={}
	Local nTotal 	:= 0
	Local oProcess	
	Local cCond 	:= ""
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
		dbCloseArea("QRV")
	Endif
	
	TCQUERY cQry NEW ALIAS "QRV"
	
	nTotVend1 :=0.00
	
	While !eof()
		
		dbselectarea("SA3")
		Dbsetorder(1)
		Dbseek(xFilial("SA3")+QRV->E1_VEND1)
		
		cProcess := "100001"
		cStatus  := "100001"
		oProcess := TWFProcess():New(cProcess,OemToAnsi("Inadimplencia diaria vendedores"))
		oProcess:NewTask(cStatus,"\workflow\inadimplencia_vendedores.htm")
		
		oProcess:cSubject := "Inadimplência -->> "+SA3->A3_COD+"/"+SA3->A3_NREDUZ
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
			dbCloseArea("QRG")
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
		
		oHtml:ValByName("nomecom",AllTrim(SM0->M0_NOMECOM))
		oHtml:ValByName("endemp",Capital(AllTrim(SM0->M0_ENDENT)) + " - " + Capital(SM0->M0_BAIRENT))
		oHtml:ValByName("comemp",Transform(SM0->M0_CEPENT,"@R 99999-999") + " - " + Capital(AllTrim(SM0->M0_CIDENT)) + " - " + SM0->M0_ESTENT)
		oHtml:ValByName("fone","Fone/Fax: " + SM0->M0_TEL + " / " + SM0->M0_FAX )
		
		oHtml:ValByName("totv",TRANSFORM(QRV->TOTAL,"@E 999,999,999.99"))
		oHtml:ValByName("data",DTOC(Date()))
		oHtml:ValByName("hora",Time())
		oHtml:ValByName("rdmake","MLFINW01")
		
		nTotVend1 := 0.00
		
		cCodSup		:= SA3->A3_SUPER
		cDestMail 	:= Alltrim(SA3->A3_EMAIL)
		
		If !Empty(cCodSup)
			DbSelectArea("SA3")
			DbSetOrder(1)
			If DbSeek(xFilial("SA3")+cCodSup)
				If !Empty(SA3->A3_EMAIL)
					cDestMail += ";"+SA3->A3_EMAIL
				Endif
			Endif
		Endif
		//cDestMail	:= "ml-servicos@outlook.com"
		
		oProcess:cTo := U_MLCFGM04(cDestMail,"MLFINW01")
		oProcess:cCc := U_MLCFGM04(GetNewPar("ML_FINW01A","financeiro@grupoforta.com.br"),"MLFINW01")
		
		oProcess:Start()
		oProcess:Finish()
		
		Dbselectarea("QRV")
		dbskip()
	Enddo
	
	QRV->(DbCloseArea())
	
Return



Static Function SchedDef()
	Local	aOrd	:= {}
	Local	aParam	:= {}

	Aadd(aParam,"P")
	Aadd(aParam,"PARAMDEF")
	Aadd(aParam,"")
	Aadd(aParam,aOrd)
	Aadd(aParam,)	

Return aParam

