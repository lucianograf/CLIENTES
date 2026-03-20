#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOPCONN.ch"

/*/{Protheus.doc} SPED1601
Ponto de entrada para gerar registro 1601 
@type function
@version  
@author Luciano / 
@since 3/2/2023
@return variant, return_description
/*/
User Function SPED1601()

	Local aReg1601  := {}
	Local dDataDe   := Iif(Len(paramixb) >= 1 , paramixb[1], ctod("  /  /  "))
	Local dDataAte  := Iif(Len(paramixb) >= 2 , paramixb[2], ctod("  /  /  "))
	Local cQuery    := ""
	Local cAliasTrb := GetNextAlias()


	// COD_PART_IP - COD_PART_IT - TOT_VS - TOT_ISS - TOT_OUTROS
	// Exemplo do Array
	// aAdd (aReg1601, {"CODIGO_CLIENTE_ADM_CARTAO","CODIGO_INTERMEDIADOR",0,0,0})
	// OBS:
	// COD_PART_IP: O valor informado deve existir no campo COD_PART do registro 0150.
	// COD_PART_IT: O valor informado deve existir no campo COD_PART do registro 0150.
	// TOT_VS : o valor deve ser preenchido com o total bruto de vendas que tiveram escrituração de ICMS , inclusive como ICMS Isento ou Outros
	// TOT_ISS: o valor deve ser preenchido com o total bruto de prestação de serviços que tiveram incidência de ISS.
	// TOT_OUTROS : o valor de ser preenchido com o total bruto das operações que não estejam no campo de incidência do ICMS ou ISS.

    /*
    No modulo SIGAFAT não há o controle de Administradoras de Cartão para poder fazer amarração, portanto a ideia é fazer um DEPARA com a condição de pagamento
    e ter um registro na tabela SA1 que corresponda a operadora.
    Ex.: Foi criado a Condição de Pagamento "002" que corresponde as vendas de Cartão de Credito, também foi criado um registro na tabela SA1 com as informações
    da operadora de Cartão de Credito.
    Sugestão para montagem da Consulta no banco de Dados:
    */
	//IIF(SD1->D1_TIPO=='D'.AND.SF4->F4_DUPLIC=='N'.AND.SF4->F4_PODER3="N",SD1->D1_CUSTO,0)


	cFil:= xfilial("SFT")

	cQuery := "SELECT DISTINCT(A1_COD+A1_LOJA) AS COD_PART_IP"
	cQuery += "  FROM "+RetSQLName("SE5")+" SE5, "+RetSQLName("SA6")+" SA6, "+RetSQLName("SA1")+" SA1 "
	cQuery += " WHERE SA6.D_E_L_E_T_ = ' ' "
	cQuery += "   AND SA6.A6_COD = SE5.E5_BANCO "
	cQuery += "   AND A6_CGC <> ' '  "
	cQuery += "   AND SA6.A6_CGC = SA1.A1_CGC   "
	cQuery += "   AND A6_FILIAL = '" + xFilial("SA6") + "' "

	cQuery += "   AND SA1.D_E_L_E_T_ = ' ' ""
	cQuery += "   AND SA1.A1_COD = SE5.E5_BANCO  "
	cQuery += "   AND A1_FILIAL = '" + xFilial("SA1") + "' "

	cQuery += "   AND SE5.D_E_L_E_T_ = ' ' "
	cQuery += "   AND SE5.E5_FILORIG = '"+ cFil +"'  "
	cQuery += "   AND E5_DATA BETWEEN '" + DTOS(dDataDe) + "' AND '" + DTOS(dDataAte) + "' "
	cQuery += "   AND E5_FILIAL = '" + xFilial("SE5") + "' "

	cQuery := ChangeQuery( cQuery )
	//MemoWrit('C:\temp\1601',cQuery)

	DbUseArea( .T., 'TOPCONN', TcGenQry(,,cQuery), cAliasTrb, .T., .F. )

	While !(cAliasTrb)->( Eof() )

		// Fica a critério do cliente a melhor maneira de realização a amarração dos cadastros
		// No entanto, deve-se observar que esta informação deve ser enviada com o código do CLIENTE + LOJA com todos os caracteres
		cCodAdm := (cAliasTrb)->COD_PART_IP  // "C09   01" // CODIGO + LOJA -> AE_CODCLI + AE_LOJCLI

		aADD(aReg1601, {cFil,cCodAdm,"",1,0,0})
		//aADD(aReg1601, {(cAliasTrb)->FILIAL,cCodAdm,(cAliasTrb)->INTERMEDIADOR,(cAliasTrb)->TOT_VS,(cAliasTrb)->TOT_ISS,(cAliasTrb)->TOT_OUT})

		(cAliasTrb)->(DbSkip())
	EndDo

	(cAliasTrb)->(DbCloseArea())

Return aReg1601
