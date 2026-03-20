#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} M460ICM
//TODO Ponto de Entrada para calcular Base/Aliquota/Valor do ICMS na tela de Impostos da Planilha Financeiro no Pedido de Venda. 
@author Marcelo Alberto Lauschner
@since 29/02/2020
@version 1.0
@return ${return}, ${return_description}
@type User Function
/*/
User Function M460ICM ()

	Local nItem			:= PARAMIXB[1]
	Local nBasIcm		:= _BASEICM
	Local nAlqIcm		:= _ALIQICM
	Local nValIcm		:= _VALICM
	Local aVlrImp		:= {}
	Local nVlrSol		:= MaFisRet(nItem,"IT_VALSOL") //adicionado para atender chamado Fiscal onde deve-se validar se o item possui ST
	Local aAreaOld		:= GetArea()

	// Se há base de Icms no cálculo
	If nBasIcm !=0

		aVlrImp		:= sfCalcIcm(nBasIcm, nAlqIcm, nValIcm,       ,  nVlrSol      ,        , nItem)

		_ALIQICM    := aVlrImp[1]
		_VALICM     := aVlrImp[2]
		_BASEICM	:= aVlrImp[3]

		MaFisalt("IT_BASEICM" ,aVlrImp[3] ,nItem)
		MaFisalt("IT_ALIQICM" ,aVlrImp[1] ,nItem)
		MaFisalt("IT_VALICM"  ,aVlrImp[2] ,nItem)

	EndIf

	RestArea(aAreaOld)

Return


/*/{Protheus.doc} sfCalcIcm
//TODO Efetua os cálculos conforme demanda de customização 
@author Marcelo Alberto Lauschner 
@since 29/02/2020
@version 1.0
@return ${return}, ${return_description}
@param nBasIcm, numeric, descricao
@param nAlqICM, numeric, descricao
@param nVlICM, numeric, descricao
@param nBasSol, numeric, descricao
@param nVlrSol, numeric, descricao
@param nAlqSol, numeric, descricao
@param nItem, numeric, descricao
@param nMVA, numeric, descricao
@param nBasIPI, numeric, descricao
@param nVlIPI, numeric, descricao
@param nAlqIPI, numeric, descricao
@type function
/*/
Static Function sfCalcIcm(nBasIcm, nAlqICM, nVlICM, nBasSol, nVlrSol, nAlqSol, nItem, nMVA, nBasIPI, nVlIPI, nAlqIPI)


	Local 	cMVESTADO  	:= GetMv("MV_ESTADO")
	Local	nICMPAD	 	:= GetMv("MV_ICMPAD")
	Local	cUFDest
	Local	lSimples
	Local	lContrib
	Local	cTipoPed
	Local	cTpPed
	Local	cTipCli
	Local	cInscEst

	Default nBasSol		:= 0
	Default nVlrSol		:= 0
	Default nAlqSol		:= 0


	aValor			:= {nAlqICM, nVlICM, nBasIcm, nBasSol, nVlrSol, nAlqSol}

	// Só executa na Atria e Onix SC 
	If cEmpAnt+cFilAnt $ "0201#1102#1301"
		If TYPE("M->C5_CLIENTE")<> "U"

			DbSelectArea("SA1")
			DbSetOrder(1)
			DbSeek( xFilial("SA1") + M->C5_CLIENTE + M->C5_LOJACLI )

			cUFDest  	:= SA1->A1_EST
			lSimples 	:= SA1->A1_SIMPNAC == "1" //SIMPLES
			lContrib 	:= SA1->A1_CONTRIB == "1" //CONTRIBUINTE
			cTipoPed 	:= M->C5_TIPOCLI
			cTpPed   	:= M->C5_TIPO
			cTipCli	 	:= SA1->A1_TIPO
			cInscEst	:= SA1->A1_INSCR
		Else
			DbSelectArea("SA1")
			DbSetOrder(1)
			DbSeek( xFilial("SA1") + SC5->C5_CLIENTE + SC5->C5_LOJACLI )

			cUFDest  	:= SA1->A1_EST
			lSimples 	:= SA1->A1_SIMPNAC == "1" //SIMPLES
			lContrib 	:= SA1->A1_CONTRIB == "1" //CONTRIBUINTE
			cTipoPed 	:= SC5->C5_TIPOCLI
			cTpPed   	:= SC5->C5_TIPO
			cTipCli	 	:= SA1->A1_TIPO
			cInscEst	:= SA1->A1_INSCR
		EndIf

		// Se for uma empresa de SC , com destino para SC e a data for a partir de 01/03/2020
		// Chamado 24.527
		If !cTpPed $ "DB" // Se não for Devolução ou Beneficiamento, pois busca valores dos documentos de Origem
			If cMVESTADO == "SC" .And. cUFDest == "SC" .And. dDataBase >= CTOD("01/03/2020")
				// Cliente não for Isento e Tipo de Cliente for Revendedor
				If (Upper(Substr(cInscEst,1,5)) # "ISENT" .And. cTipoPed $ "S#R" .And. aValor[1] > 12 ) .Or.; // Cliente for Contribuinte , Tipo Revendedor
				( cTipoPed $ "S#R" .And. aValor[1] > 12) // Cliente for Contribuinte , Tipo Revendedor -- lContrib retirada a validação por Contribuinte a pedido do Fiscal - se acontecer cagadas no faturamento está registrado no fonte em 25/08/2021
					// Atribui a aliquota de ICMS para 12%
					aValor[1]	:=	12.00

					// Recalcula o valor do ICMS
					If aValor[2]!=0
						aValor[2] := Round(aValor[3] * aValor[1] /100,2)
					Endif

				Endif
			EndIf
		Endif
	Endif

Return aValor
