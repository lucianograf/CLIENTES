#include "protheus.ch"

/*/{Protheus.doc} M450AROT
(long_description)
@author MarceloLauschner
@since 17/04/12
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function M450AROT()
	
	Local	aAreaOld	:= GetArea()
	Local	cDescCont	:= "" // Descrição de contratos existentes para o Cliente
	Local	cCliLoja	:= ""
	Local	cQry		:= ""
	
	// Efetua verificação se esta validação deve ser executada para esta empresa/filial
	If !U_BFCFGM25("M450AROT")
		Return .T.
	Endif
	
	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()
	
	
	// Caso não exista o campo no cadastro de clientes retorna
	DbSelectArea("SA1")
	If SA1->(FieldPos("A1_OBCONTR")) == 0 
		RestArea(aAreaOld)
		Return
	Endif
	
	/* desativado até uma nova necessidade, pois precisa ser reescrito para mssql invés de oracle 
	
	// Zera a observação de contrato nos clientes que tiveram vigência encerrada.
	cQry := "UPDATE "+RetSqlName("SA1")
	cQry += "   SET A1_OBCONTR = '"+Padr(cDescCont,TamSX3("A1_OBCONTR")[1])+"' "
	cQry += " WHERE D_E_L_E_T_ = ' ' "
	cQry += "   AND A1_FILIAL = '"+xFilial("SA1")+"' "
	cQry += "   AND (A1_COD,A1_LOJA) IN (SELECT ZM_CLIENTE,ZM_LOJA "
	cQry += "                              FROM " + RetSqlName("SZM") 
	cQry += "                             WHERE D_E_L_E_T_ =' ' "
	cQry += "                               AND ZM_FILIAL IN "+FormatIN(GetMv("BF_FILIAIS"),"/")"
	cQry += "                               AND( ZM_DATAINI > TO_CHAR(SYSDATE,'YYYYMMDD') OR ZM_DATAFIM <= TO_CHAR(SYSDATE,'YYYYMMDD')))
    cQry += "   AND A1_OBCONTR != ' ' "
    Begin Transaction 
		TcSqlExec(cQry)
	End Transaction 
	
	// Zera a observação de contrato nos clientes que nem tem cadastro de contratos
	cQry := "UPDATE "+RetSqlName("SA1")
	cQry += "   SET A1_OBCONTR = '"+Padr(cDescCont,TamSX3("A1_OBCONTR")[1])+"' "
	cQry += " WHERE D_E_L_E_T_ = ' ' "
	cQry += "   AND A1_FILIAL = '"+xFilial("SA1")+"' "
	cQry += "   AND NOT EXISTS (SELECT ZM_CLIENTE "
	cQry += "                     FROM " + RetSqlName("SZM") 
	cQry += "                    WHERE D_E_L_E_T_ =' ' "
	cQry += "                      AND ZM_FILIAL IN "+FormatIN(GetMv("BF_FILIAIS"),"/")"
	cQry += "                      AND ZM_CLIENTE = A1_COD "
	cQry += "                      AND ZM_LOJA = A1_LOJA )"
	cQry += "   AND A1_OBCONTR != ' ' "
    
    Begin Transaction 
		TcSqlExec(cQry)
	End Transaction 
	TcRefresh(RetSqlName("SA1"))
	
	cQry := "SELECT ZM_CLIENTE,ZM_LOJA,CASE WHEN ZM_TPALVO = 'L' THEN 'Litros ' ELSE 'R$ 'END TIPO_ALVO,COUNT(*) N_CONTRATOS,SUM(ZM_INVEST) INVESTIMENTO,SUM(ZM_ALVO) ALVO "
	cQry += "  FROM "+RetSqlName("SZM") + " ZM "
	cQry += " WHERE D_E_L_E_T_ = ' ' "
	cQry += "   AND TO_CHAR(SYSDATE,'YYYYMMDD') BETWEEN ZM_DATAINI AND ZM_DATAFIM "
	cQry += "   AND ZM_FILIAL IN "+FormatIN(GetMv("BF_FILIAIS"),"/")
	cQry += " GROUP BY ZM_CLIENTE,ZM_LOJA,ZM_TPALVO "
	cQry += " ORDER BY ZM_CLIENTE,ZM_LOJA "
	
	DbUseArea (.T.,"TOPCONN",TcGenQry(,,cQry),"QZM",.F.,.T.)
	
	While !Eof()
		
		
		
		If !Empty(cCliLoja) .And. cCliLoja <> QZM->ZM_CLIENTE+QZM->ZM_LOJA
			
			DbSelectArea("SA1")
			DbSetOrder(1)
			If DbSeek(xFilial("SA1")+Substr(cCliLoja,1,6)+Substr(cCliLoja,7,2)) .And. Padr(cDescCont,TamSX3("A1_OBCONTR")[1]) <> SA1->A1_OBCONTR 
				RecLock("SA1",.F.)
				SA1->A1_OBCONTR := Padr(cDescCont,TamSX3("A1_OBCONTR")[1])
				MsUnlock()
			Endif
			
			cDescCont	:= ""
		Endif
		
		cCliLoja	:= QZM->ZM_CLIENTE+QZM->ZM_LOJA
		cDescCont	+= "Há "+Alltrim(Str(QZM->N_CONTRATOS)) + " contrato(s) de "+Alltrim(QZM->TIPO_ALVO) +  " com Investimento de "+Alltrim(Transform(QZM->INVESTIMENTO,"@E 999,999,999.99"))+ " e alvo de " + Alltrim(Transform(QZM->ALVO,"@E 999,999,999.99")) + " / "
		
		DbSelectArea("QZM")
		DbSkip()
	Enddo
	
	If !Empty(cCliLoja)
		DbSelectArea("SA1")
		DbSetOrder(1)
		If DbSeek(xFilial("SA1")+Substr(cCliLoja,1,6)+Substr(cCliLoja,7,2)) .And. Padr(cDescCont,TamSX3("A1_OBCONTR")[1]) <> SA1->A1_OBCONTR 
			RecLock("SA1",.F.)
			SA1->A1_OBCONTR := Padr(cDescCont,TamSX3("A1_OBCONTR")[1])
			MsUnlock()
		Endif
		
	Endif
	QZM->(DbCloseArea())
	
	*/
	RestArea(aAreaOld)
	
Return


