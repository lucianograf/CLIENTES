#include 'protheus.ch'

/*/{Protheus.doc} MaPISVeic
//Ponto de Entrada para Retornar Nova Base de Cálculo, alíquota e valor do PIS
@author Marcelo Alberto Lauschner
@since 31/03/2018
@version 6
@return ${return}, ${return_description}

@type function
/*/
User function MaPISVeic() 
 
	Local		aAreaOld	:= GetArea()
	Local		nPs2Item	:= ParamIxb[1]
	Local		nPs2Base	:= ParamIxb[2]
	Local		nPs2Aliq	:= ParamIxb[3]
	Local		nPs2Vlr		:= ParamIxb[4]
	Local		nPs2NewBs	:= nPs2Base
	Local		aRet		:= {nPs2Base,nPs2Aliq,nPs2Vlr} // Monta vetor para devolver igual ao recebido se não for tratado no PE
	Local		cCodPrd		:= MaFisRet(nPs2Item,"IT_PRODUTO")
	Local		nPrdQte		:= MaFisRet(nPs2Item,"IT_QUANT")
	Local		cNFOPERNF	:= MaFisRet(,"NF_OPERNF")
	Local		cNFCLIFOR	:= MaFisRet(,"NF_CLIFOR")
	Local		cIT_TES		:= MaFisRet(nPs2Item,"IT_TS")
	/*
	If "PS2" $ cTipo
	If aPE[PE_MAPISVEIC] // ATENCAO!!! Ponto de entrada para uso exclusivo da TOTVS, nao sugerir o uso do mesmo a clientes - GDP FISCAL
	aMaPISVeic := ExecBlock("MaPISVeic",.F.,.F.,{nItem,aNfItem[nItem][IT_BASEPS2],aNfItem[nItem][IT_ALIQPS2],aNfItem[nItem][IT_VALPS2]})
	aNfItem[nItem][IT_BASEPS2] := aMaPISVeic[1]
	aNfItem[nItem][IT_ALIQPS2] := aMaPISVeic[2]
	aNfItem[nItem][IT_VALPS2]  := aMaPISVeic[3]
	
	
	EndIf
	Endif
	*/
	
	
	// Efetua verificação se esta validação deve ser executada para esta empresa/filial
	If !(cFilAnt $ "0401")
		Return aRet
	Endif

	If cNFOPERNF == "S"  .And. cNFCLIFOR == "C" // Para a Saída

		nPs2NewBs	:= sfCalNewBs(cCodPrd,nPs2Base,nPrdQte)

		//MsgAlert("Produto : " + cCodPrd + " Base: " + cValToChar(nPs2Base) + " Aliquota " + cValToChar(nPs2Aliq) + " Valor " + cValToChar(nPs2Vlr) + " NewBs " + cValToChar(nPs2NewBs))
		If nPs2Base - nPs2NewBs > 0 
			nPs2Base 	-= nPs2NewBs
			aRet[1]		:= nPs2Base
			aRet[3]		:= Round(nPs2Base * nPs2Aliq / 100,2) 
		Endif
		//MsgAlert("Produto : " + cCodPrd + " Base: " + cValToChar(aRet[1]) + " Aliquota " + cValToChar(nPs2Aliq) + " Valor " + cValToChar(aRet[3]) )
		
	ElseIf cNFOPERNF == "E"

	Endif

	RestArea(aAreaOld)

Return aRet

/*/{Protheus.doc} sfCalNewBs
// Função que pesquisa as entradas do produto que tenham atendido a quantidade de saída e efetua o cálculo do ST para reduzir da base de saída
@author Marcelo Alberto Lauschner
@since 31/03/2018
@version 6
@return ${return}, ${return_description}
@param cInPrd, characters, Código Produto
@param nInBase, numeric, Valor Base de Entrada
@param nInQte, numeric, Quantidade 
@type function
/*/
Static Function sfCalNewBs(cInPrd,nInBase,nInQte)

	Local	nQteEnt		:= 0
	Local	nVlrEnt		:= 0
	Local	nVlrRet		:= 0
	
	
	BeginSql Alias "QXIT"

	SELECT TOP 10
				ROW_NUMBER() OVER (ORDER BY FT_ENTRADA DESC) AS ROWNUM,
				FT_A.*
			FROM (
				SELECT 
					FT_QUANT,
					FT_ENTRADA,
					CASE 
						WHEN FT_ICMSRET > 0 AND FT_CREDST IN ('4', '2') THEN FT_ICMSRET
						WHEN FT_OUTRRET > 0 AND FT_CREDST IN ('4', '2') THEN FT_OUTRRET
						ELSE 0 
					END AS DIF_BASE
				FROM SFT010 FT
				JOIN SF4010 F4 ON F4_CODIGO = FT_TES AND F4_FILIAL = %xFilial:SF4%
				WHERE 
					FT_PRODUTO = %Exp:cInPrd%
					AND FT_FILIAL = %xFilial:SFT%
					AND FT.%NotDel%
					AND FT_CFOP <= '5'
					AND FT_TIPO <> 'D' 
					AND FT_QUANT > 0
					AND F4.%NotDel%
					AND F4_PISCRED IN ('1')
					AND FT_ENTRADA BETWEEN %Exp:DTOS(dDataBase-360)% AND %Exp:DTOS(dDataBase)%
					AND FT_TIPOMOV = 'E'
			) FT_A
	EndSql

	While !Eof()
		nQteEnt += QXIT->FT_QUANT
		nVlrEnt	+= QXIT->DIF_BASE
		
		If nQteEnt > nInQte 
			Exit
		Endif 
		QXIT->(DbSkip())
	Enddo
	QXIT->(DbCloseArea())
	
	nVlrRet	:= Round( Round(nVlrEnt / nQteEnt , 4) * nInQte , 2) 
	
Return nVlrRet
