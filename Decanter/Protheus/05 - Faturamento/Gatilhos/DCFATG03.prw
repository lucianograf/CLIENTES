#include "totvs.ch"
/*/{Protheus.doc} DCFATG03(cInFilOri,
Função para retornar o código da transportadora conforme verificação inteligente 
@type function
@version  
@author Marcelo Alberto Lauschner
@since 26/10/2021
@return variant, return_description
/*/
User Function DCFATG03(;
		cInFilOri,;     // 1 Filial de Origem 
		cInUF,;         // 2 Uf Destino 
        cInMun,;        // 3 Código Municipio Destino 
        cInRegiao,;     // 4 Código Região destino 
        cInCanal,;      // 5 Código do Canal de atendimento 
        cInPraca,;      // 6 Código da praça 
        cInSegmen,;     // 7 Segmento 
        cInVend,;       // 8 Vendedor
        cInExpres,;     // 9 Expresso 
        cInCodCli,;     // 10 Código do Cliente     
        cInLoja,;       // 11 Loja do cliente 
        cInPessoa,;     // 12 Tipo de pessoa 
        cInCep,;        // 13 CEP destino 
        cInTabela,;     // 14 Codigo Tabela 
        cInGrpVen,;     // 15 Grupo de Vendas 
        nInPeso,;       // 16 Peso 
        nInValor,;      // 17 Peso     
        nInFrete)       // 18 Frete

	Local       aAreaOld        := GetArea()
	Local       cOutTransp      := Space(TamSX3("C5_TRANSP")[1])
	Local       cRetSql         := ""
	Default     cInFilOri       := " "
    Default     cInUF           := " "
    Default     cInMun           := " "
	Default     cInRegiao       := " "
    Default     cInCanal        := " "
    Default     cInPraca        := " "
    Default     cInSegmen       := " "
    Default     cInVend         := " "
    Default     cInExpres       := " "
    Default     cInCodCli       := " "
    Default     cInLoja         := " "
    Default     cInPessoa       := " "
    Default     cInCep          := " "
    Default     cInTabela       := " "
    Default     cInGrpVen       := " "
    Default     nInPeso         := 0
    Default     nInValor         := 0
    Default     nInFrete        := 0

	cRetSql += "SELECT ZTI_TS,ZTI_COD "
	cRetSql	+= "  FROM " + RetSqlName("ZTI") + " ZTI "
	cRetSql += " WHERE ZTI.ZTI_FILIAL = '" + xFilial("ZTI") + "'"
	cRetSql += "   AND ZTI.D_E_L_E_T_=' ' "
	cRetSql	+= "   AND (ZTI.ZTI_FILORI = '" + cInFilOri + "' OR ZTI.ZTI_FILORI = ' ' ) "
	cRetSql	+= "   AND (ZTI.ZTI_UF     = '" + cInUF+ "'  OR ZTI.ZTI_UF     = ' ' )"
	cRetSql	+= "   AND (ZTI.ZTI_MUN    = '" + cInMun+ "'  OR ZTI.ZTI_MUN    = ' ' )"
	cRetSql	+= "   AND (ZTI.ZTI_REGIAO = '" + cInRegiao+ "'  OR ZTI.ZTI_REGIAO = ' ' )"
	cRetSql	+= "   AND (ZTI.ZTI_CANAL  = '" + cInCanal+ "'  OR ZTI.ZTI_CANAL  = ' ' )"
	cRetSql	+= "   AND (ZTI.ZTI_PRACA  = '" + cInPraca+ "'  OR ZTI.ZTI_PRACA  = ' ' )"
	cRetSql	+= "   AND (ZTI.ZTI_SEGMEN = '" + cInSegmen+ "'  OR ZTI.ZTI_SEGMEN = ' ' )"
	cRetSql	+= "   AND (ZTI.ZTI_VEND   = '" + cInVend+ "'  OR ZTI.ZTI_VEND   = ' ' )"
	cRetSql	+= "   AND (ZTI.ZTI_EXPRES = '" + cInExpres+ "'  OR ZTI.ZTI_EXPRES = ' ' )"
	cRetSql	+= "   AND (ZTI.ZTI_PESSOA = '" + cInPessoa+ "'  OR ZTI.ZTI_PESSOA = ' ' )"
	cRetSql	+= "   AND (ZTI.ZTI_CEP    = '" + cInCep+ "'  OR ZTI.ZTI_CEP    = ' ' )"
	cRetSql	+= "   AND (ZTI.ZTI_TABELA = '" + cInTabela+ "'  OR ZTI.ZTI_TABELA = ' ' )"
	cRetSql	+= "   AND (ZTI.ZTI_GRPVEN = '" + cInGrpVen+ "'  OR ZTI.ZTI_GRPVEN = ' ' )"
    
    // Filtra por peso e valor do frete acima do valor informado - na ordenação os 2 campos são ordenados na ordem crescente 
    // desta forma ZTI_PESO (100,500,800) nInPeso (120) = irá filtrar 500 e 800, sendo a ordenação será 500,800 e como só pegará a primeira linha, assumirá 500
	cRetSql	+= "   AND (ZTI.ZTI_VALOR  <=  " + cValToChar(nInValor)+ " )"
	cRetSql	+= "   AND (ZTI.ZTI_PESO   <=  " + cValToChar(nInPeso)+ " )"
	cRetSql	+= "   AND (ZTI.ZTI_FRETE  >=  " + cValToChar(nInFrete)+ "   OR ZTI.ZTI_FRETE  = 0   )"
    
    // Filtro de cliente específico - estes 2 campos não estão no order by, pois entende-se que o cliente/loja são o nível mais baixo e específico de filtro 
    cRetSql	+= "   AND (ZTI.ZTI_CODCLI = '" + cInCodCli+ "'  OR ZTI.ZTI_CODCLI = ' ' )"
	cRetSql	+= "   AND (ZTI.ZTI_LOJA   = '" + cInLoja+ "'  OR ZTI.ZTI_LOJA   = ' ' )"

	// ordenação de campos texto é feito decrescente para primeiro pegar valores que possam estar preenchidos 
	cRetSql += " ORDER BY ZTI_CODCLI DESC,"
	cRetSql += "          ZTI_LOJA DESC,"
	cRetSql += "          ZTI_FILORI DESC,"
    cRetSql += "          ZTI_VALOR DESC,"
    cRetSql += "          ZTI_VEND DESC,"
	cRetSql += "          ZTI_UF DESC,"
    cRetSql += "          ZTI_MUN DESC,"
    cRetSql += "          ZTI_REGIAO DESC,"
    cRetSql += "          ZTI_CANAL DESC,"
    cRetSql += "          ZTI_PRACA DESC,"
    cRetSql += "          ZTI_SEGMEN DESC,"
    cRetSql += "          ZTI_EXPRES DESC,"
    cRetSql += "          ZTI_PESSOA DESC,"
    cRetSql += "          ZTI_CEP DESC,"
    cRetSql += "          ZTI_TABELA DESC,"
    cRetSql += "          ZTI_GRPVEN DESC,"
    // Peso e frete são ordenados ascendente para manter o conceito de intervalo 
    cRetSql += "          ZTI_PESO DESC,"
    cRetSql += "          ZTI_FRETE " 

    DBUseArea(.T.,"TOPCONN",TCGENQRY(,,cRetSql),"QRYZTI",.F.,.T.)

    If !Eof()
        cOutTransp  := QRYZTI->ZTI_TS  // Código Transportadora de saída
    Endif 

    QRYZTI->(DbCloseArea())

	RestArea(aAreaOld)


Return cOutTransp
