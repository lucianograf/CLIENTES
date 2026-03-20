#Include 'Protheus.ch'

/*/{Protheus.doc} BFCOMM02
Retorna o Custo de estoque de reposição
@type function
@version
@author Marcelo Alberto Lauschner
@since 11/06/2015
@param cInFor       , character, Código do Fornecedor
@param cInLoj       , character, Loja do Fornecedor
@param cInCodPro    , character, Código do Produto
@param nInPrc       , numeric,   Preço do Produto de Entrada Default
@param nInPerFre    , numeric,   Percentual de Frete Default
@return return_type, return_description
/*/
User Function BFCOMM02(cInFor,cInLoj,cInCodPro,nInPrc,nInPerFre)


    Local	aAreaOld		:= GetArea()
    Local	nCustRet		:= 0
    Local	nItemFis		:= 0
    Local	aCusto     	    := {}
    Local 	aRet       	    := {}
    Local 	nPos       	    := 0
    Local 	nValIV     	    := 0
    Local 	nX         	    := 0
    Local 	nZ         	    := 0
    Local 	nFatorPS2   	:= 1
    Local 	nFatorCF2  	    := 1
    Local 	nValPS2     	:= 0
    Local 	nValCF2    	    := 0
    Local 	lCustPad   	    := .T.
    Local 	uRet       	    := Nil
    Local	cTipo			:= "N"
    Local 	lBonif      	:= !Empty( SF4->( FieldPos( "F4_BONIF"   ) ) )
    Local 	lCredICM   	    := SuperGetMV("MV_CREDICM", .F., .F.) 	// Parametro que indica o abatimento do credito de ICMS no custo do item, ao utilizar o campo F4_AGREG = "I"
    Local 	lValCMaj   	    := !Empty(MaFisScan("IT_VALCMAJ",.F.))	// Verifica se a MATXFIS possui a referentcia IT_VALCMAJ
    Local 	lValPMaj    	:= !Empty(MaFisScan("IT_VALPMAJ",.F.))	// Verifica se a MATXFIS possui a referentcia IT_VALCMAJ
    Local	aDupl			:= {}
    Default	nInPerFre	    := GetNewPar("BF_COMM02A",0)

    DbSelectArea("SA2")
    DbSetOrder(1)
    DbSeek(xFilial("SA2")+cInFor+cInLoj)


    If nInPrc <= 0

        cQry := "SELECT MAX(AIB_PRCCOM) PRECO "
        If AIB->(FieldPos("AIB_XFRETE")) > 0 
            cQry += "       ,MAX(AIB_XFRETE) FRETE"
        Else 
            cQry += "       ,AIB_FRETE FRETE " // Valor unitário do frete 
        Endif 
        cQry += "  FROM "+RetSqlName("AIB") + " AIB," + RetSqlName("AIA")+ " AIA "
        cQry += " WHERE AIB.D_E_L_E_T_ = ' ' "
        cQry += "   AND AIB_CODPRO = '"+cInCodPro+"'"
        cQry += "   AND AIB_LOJFOR = '"+cInLoj+"'"
        cQry += "   AND AIB_CODFOR = '"+cInFor+"'"
        cQry += "   AND AIB_CODTAB = AIA_CODTAB "
        cQry += "   AND AIB_FILIAL = '" + xFilial("AIB") +  "' "
        cQry += "   AND AIA.D_E_L_E_T_ =' ' "
        cQry += "   AND AIA_LOJFOR = '"+cInLoj+"'"
        cQry += "   AND AIA_CODFOR = '"+cInFor+"'"
        cQry += "   AND TO_CHAR(SYSDATE,'YYYYMMDD') BETWEEN AIA_DATDE AND AIA_DATATE"
        cQry += "   AND AIA_FILIAL = '"+xFilial("AIA")+"' "

        dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQry),'QAIA', .F., .T.)

        If QAIA->(!Eof())
            nInPrc 		    := QAIA->PRECO
            nInPerFre		:= QAIA->FRETE
        Endif

        QAIA->(DbCloseArea())

    Endif

    MaFisSave()
    MaFisEnd()

    MaFisIni(SA2->A2_COD,;					    // 1-Codigo Cliente/Fornecedor
        SA2->A2_LOJA,;							// 2-Loja do Cliente/Fornecedor
        "F",;									// 3-C:Cliente , F:Fornecedor
        cTipo,;									// 4-Tipo da NF
        "R",;									// 5-Tipo do Cliente/Fornecedor
        MaFisRelImp("MT100",{"SF1","SD1"}),;	// 6-Relacao de Impostos que suportados no arquivo
        Nil,;									// 7-Tipo de complemento
        Nil,;									// 8-Permite Incluir Impostos no Rodape .T./.F.
        Nil,;									// 9-Alias do Cadastro de Produtos - ("SBI" P/ Front Loja)
        "MATA100",;								// 10-Nome da rotina que esta utilizando a funcao
        Nil,;									// 11-Tipo de documento
        Nil,;  									// 12-Especie do documento
        Nil)									// 13- Codigo e Loja do Prospect

    // Garante que irá calcular pelo tipo de nota SPED
    MaFisAlt("NF_ESPECIE","SPED")

    DbSelectarea("SB1")
    DbSetOrder(1)
    DbSeek(xFilial("SB1")+cInCodPro)

    nItemFis++

    MaFisAdd(	SB1->B1_COD,;  				        // 1-Codigo do Produto ( Obrigatorio )
        RetFldProd(SB1->B1_COD,"B1_TE"),;		    // 2-Codigo do TES ( Opcional )
        1,; 										// 3-Quantidade ( Obrigatorio )
        nInPrc,;									// 4-Preco Unitario ( Obrigatorio )
        0,;	 										// 5-Valor do Desconto ( Opcional )
        "",;	   									// 6-Numero da NF Original ( Devolucao/Benef )
        "",;										// 7-Serie da NF Original ( Devolucao/Benef )
        0,;											// 8-RecNo da NF Original no arq SD1/SD2
        0,;											// 9-Valor do Frete do Item ( Opcional )
        0,;											// 10-Valor da Despesa do item ( Opcional )
        0,;											// 11-Valor do Seguro do item ( Opcional )
        0,;											// 12-Valor do Frete Autonomo ( Opcional )
        nInPrc,;									// 13-Valor da Mercadoria ( Obrigatorio )
        0,;											// 14-Valor da Embalagem ( Opiconal )
        ,;											// 15
        ,;											// 16
        ,; 											// 17
        0,;											// 18-Despesas nao tributadas - Portugal
        0,;											// 19-Tara - Portugal
        ,; 											// 20-CFO
        {},;	           						    // 21-Array para o calculo do IVA Ajustado (opcional)
        "")

    DbSelectArea("SF4")
    DbSetOrder(1)
    DbSeek(xFilial("SF4")+SB1->B1_TE)

    //ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
    //³ Calcula o percentual para credito do PIS / COFINS   ³
    //ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
    If !Empty( SF4->F4_BCRDPIS )
        nFatorPS2 := SF4->F4_BCRDPIS / 100
    EndIf

    If !Empty( SF4->F4_BCRDCOF )
        nFatorCF2 := SF4->F4_BCRDCOF / 100
    EndIf

    nValPS2 := MaFisRet(nItemFis,"IT_VALPS2") * nFatorPS2
    nValCF2 := MaFisRet(nItemFis,"IT_VALCF2") * nFatorCF2


    Aadd(aCusto,{	MaFisRet(nItemFis,"IT_TOTAL")-IIF(cTipo == "P".Or.SF4->F4_IPI=="R",0,MaFisRet(nItemFis,"IT_VALIPI"))+If((SF4->F4_CIAP=="S".And. SF4->F4_CREDICM=="S").Or.((SF4->(FieldPos("F4_ANTICMS")) > 0).And.SF4->F4_ANTICMS=="1"),0,MaFisRet(nItemFis,"IT_VALCMP"))-If(SF4->F4_INCSOL<>"N",MaFisRet(nItemFis,"IT_VALSOL"),0)-nValIV+IF(SF4->F4_ICM=="S" .And. SF4->F4_AGREG$'A|C',MaFisRet(nItemFis,"IT_VALICM"),0)+IF(SF4->F4_AGREG=='D' .And. SF4->F4_BASEICM == 0,MaFisRet(nItemFis,"IT_DEDICM"),0)-MaFisRet(nItemFis,"IT_CRPRESC")-MaFisRet(nItemFis,"IT_CRPREPR")+MaFisRet(nItemFis,"IT_VLINCMG")-IIf(lCredICM .And. SF4->F4_AGREG$"I|B",MaFisRet(nItemFis,"IT_VALICM"),0)-If(SF4->F4_AGREG == "B",MaFisRet(nItemFis,"IT_VALSOL"),0),;
        MaFisRet(nItemFis,"IT_VALIPI"),;
        MaFisRet(nItemFis,"IT_VALICM"),;
        SF4->F4_CREDIPI,;
        SF4->F4_CREDICM,;
        MaFisRet(nItemFis,"IT_NFORI"),;
        MaFisRet(nItemFis,"IT_SERORI"),;
        SB1->B1_COD,;
        SB1->B1_LOCPAD,;
        1,;
        If(SF4->F4_IPI=="R",MaFisRet(nItemFis,"IT_VALIPI"),0),;
        SF4->F4_CREDST,;
        MaFisRet(nItemFis,"IT_VALSOL"),;
        MaRetIncIV(nItemFis,"1"),;
        SF4->F4_PISCOF,;
        SF4->F4_PISCRED,;
        nValPS2 - (IIf(lValPMaj,MaFisRet(nItemFis,"IT_VALPMAJ"),0)),;
        nValCF2 - (IIf(lValCMaj,MaFisRet(nItemFis,"IT_VALCMAJ"),0)),;
        IIf(SF4->(FieldPos("F4_ESTCRED")) > 0 .And. SF4->F4_ESTCRED > 0,MaFisRet(nItemFis,"IT_ESTCRED"),0),;
        IIf(SD1->(FieldPos("D1_CRPRSIM")) >0, MaFisRet(nItemFis,"IT_CRPRSIM"), 0 ),;
        MaFisRet(nItemFis,"IT_VALANTI");
        })

    If (lBonif .And. SF4->F4_BONIF == "S")
        aRet := {{0,0,0,0,0}}
    Else
        aRet := RetCusEnt(aDupl,aCusto,cTipo)
        If SF4->F4_AGREG == "N"
            For nX := 1 to Len(aRet[1])
                aRet[1][nX] := If(aRet[1][nX]>0,aRet[1][nX],0)
            Next nX
        EndIf
    EndIf
    nCustRet	:= aRet[1][1]

    // Somo o Percentual de frete
    If nInPerFre > 0
        nCustRet	+= Round(MaFisRet(,"NF_TOTAL") * nInPerFre / 100,2)
    Endif

    MaFisRestore()

    RestArea(aAreaOld)

Return nCustRet
