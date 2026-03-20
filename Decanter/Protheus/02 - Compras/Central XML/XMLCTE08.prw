#include 'totvs.ch'
/*/{Protheus.doc} U_XMLCTE08
Ponto de entrada para Adicionar campos durante o lançamento de Notas
@type function
@version  
@author Marcelo Alberto Lauschner
@since 10/03/2022
@return variant, return_description - mais um teste 20/03/2026
/*/
Function U_XMLCTE08()

	Local	aAreaOld	:= GetArea()

	Local	nD1COD		:= aScan(aLinha,{ |x| Alltrim(x[1]) =="D1_COD"} )
	Local	nD1ITEM		:= aScan(aLinha,{ |x| Alltrim(x[1]) =="D1_ITEM"} )
	Local   nD1VFCPANT  := aScan(aLinha,{ |x| Alltrim(x[1]) =="D1_VFCPANT"} )   // D1_VFCPANT - Valor do FECP antecipado
	Local   nD1BFCPANT  := aScan(aLinha,{ |x| Alltrim(x[1]) =="D1_BFCPANT"} )   // D1_BFCPANT - Base do FECP antecipado
	Local   nD1AFCPANT  := aScan(aLinha,{ |x| Alltrim(x[1]) =="D1_AFCPANT"} )   // D1_AFCPANT - Aliquota do FECP antecipado
	Local   nD1BASNDES  := aScan(aLinha,{ |x| Alltrim(x[1]) =="D1_BASNDES"} )   // D1_BASNDES - Base do Icms sT antecipado
	Local   nD1ICMNDES  := aScan(aLinha,{ |x| Alltrim(x[1]) =="D1_ICMNDES"} )   // D1_ICMNDES - Valor do ICMS ST antecipado
	Local   nD1ALQNDES  := aScan(aLinha,{ |x| Alltrim(x[1]) =="D1_ALQNDES"} )   // D1_ALQNDES - Aliquota do ICMS antecipado
	Local   nD1ALIQSOL  := aScan(aLinha,{ |x| Alltrim(x[1]) =="D1_ALIQSOL"} )   // D1_ALIQSOL - Aliquota do Solidário
	Local 	nD1ALIQCMP	:= aScan(aLinha,{ |x| Alltrim(x[1]) =="D1_ALIQCMP"} )   // D1_ALIQCMP - Aliquota do Solidário Complemento
	Local   nD1BRICMS   := aScan(aLinha,{ |x| Alltrim(x[1]) =="D1_BRICMS"} )    // D1_BRICMS  - Base do Icms ST
	Local   nD1ICMSRET  := aScan(aLinha,{ |x| Alltrim(x[1]) =="D1_ICMSRET"} )   // D1_ICMSRET - Valor do ICMS ST
	Local   nD1MARGEM   := aScan(aLinha,{ |x| Alltrim(x[1]) =="D1_MARGEM"} )  	// D1_MARGEM  - Margem do Solidário
	Local   cAliasSFT
	Local   nF1SERIE    := aScan(aCabec,{ |x| Alltrim(x[1]) == "F1_SERIE"})
	Local   nF1DOC      := aScan(aCabec,{ |x| Alltrim(x[1]) == "F1_DOC"})

	// Nota tipo Normal
	If cTipo == "N"
		// Fornecedor é uma filial de Origem
		If !Empty(SA2->A2_FILTRF) .And. nF1SERIE > 0

			cAliasSFT := GetNextAlias()
			BeginSql Alias cAliasSFT

				SELECT FT_BASERET,FT_ALIQSOL,FT_ICMSRET,FT_BSFCPST,FT_ALFCPST,FT_VFECPST,FT_MARGEM
			  	  FROM %Table:SFT% 
				 WHERE D_E_L_E_T_ = ' ' 
				   AND FT_FILIAL = %Exp:SA2->A2_FILTRF% 
                   AND FT_TIPOMOV = 'S'
                   AND FT_SERIE = %Exp:aCabec[nF1SERIE,2]% 
                   AND FT_NFISCAL = %Exp:aCabec[nF1DOC,2]% 
                   AND FT_ITEM = %Exp:Substr(aLinha[nD1ITEM,2],3,2)%
                   AND FT_PRODUTO = %Exp:aLinha[nD1COD,2]%
			EndSql

			If (cAliasSFT)->(!Eof())

				// Aliquota do ST
				If nD1ALIQSOL > 0
					aLinha[nD1ALIQSOL][2]	    :=  (cAliasSFT)->FT_ALIQSOL - (cAliasSFT)->FT_ALFCPST
				Else
					Aadd(aLinha,{"D1_ALIQSOL"	,(cAliasSFT)->FT_ALIQSOL - (cAliasSFT)->FT_ALFCPST		,Nil,Nil})
				Endif

				// Base do FECP
				If nD1BFCPANT > 0
					aLinha[nD1BFCPANT][2]	    :=  (cAliasSFT)->FT_BSFCPST
				Else
					Aadd(aLinha,{"D1_BFCPANT"	,(cAliasSFT)->FT_BSFCPST		,Nil,Nil})
				Endif

				// Aliquota do FECP
				If nD1AFCPANT > 0
					aLinha[nD1AFCPANT][2]	    :=  (cAliasSFT)->FT_ALFCPST
				Else
					Aadd(aLinha,{"D1_AFCPANT"	,(cAliasSFT)->FT_ALFCPST		,Nil,Nil})
				Endif

				// Valor do FECP
				If nD1VFCPANT > 0
					aLinha[nD1VFCPANT][2]	    :=  (cAliasSFT)->FT_VFECPST
				Else
					Aadd(aLinha,{"D1_VFCPANT"	,(cAliasSFT)->FT_VFECPST		,Nil,Nil})
				Endif



				// Margem valor
				If nD1MARGEM > 0
					aLinha[nD1MARGEM][2]	    :=  (cAliasSFT)->FT_MARGEM
				Else
					Aadd(aLinha,{"D1_MARGEM"	,(cAliasSFT)->FT_MARGEM		,Nil,Nil})
				Endif


				// Base do ST
				If nD1BASNDES > 0
					aLinha[nD1BASNDES][2]	    :=  (cAliasSFT)->FT_BASERET
				Else
					Aadd(aLinha,{"D1_BASNDES"	,(cAliasSFT)->FT_BASERET		,Nil,Nil})
				Endif

				// Aliquota do ST
				If nD1ALQNDES > 0
					aLinha[nD1ALQNDES][2]	    :=  (cAliasSFT)->FT_ALIQSOL - (cAliasSFT)->FT_ALFCPST
				Else
					Aadd(aLinha,{"D1_ALQNDES"	,(cAliasSFT)->FT_ALIQSOL - (cAliasSFT)->FT_ALFCPST		,Nil,Nil})
				Endif

				// Valor do ST
				If nD1ICMNDES > 0
					aLinha[nD1ICMNDES][2]	    :=  (cAliasSFT)->FT_ICMSRET
				Else
					Aadd(aLinha,{"D1_ICMNDES"	,(cAliasSFT)->FT_ICMSRET 	,Nil,Nil})
				Endif

				// Digitação do valor da Base do ST e valor do ST por último para ajustar valores afins de somar no custo do produto
				// Base do ST
				If nD1BRICMS > 0
					aLinha[nD1BRICMS][2]	    :=  (cAliasSFT)->FT_BASERET
				Else
					Aadd(aLinha,{"D1_BRICMS"	,(cAliasSFT)->FT_BASERET		,Nil,Nil})
				Endif

				// Aliquota do ST Complemento destino
				If nD1ALIQCMP > 0
					aLinha[nD1ALIQCMP][2]	    :=  (cAliasSFT)->FT_ALIQSOL
				Else
					Aadd(aLinha,{"D1_ALIQCMP"	,(cAliasSFT)->FT_ALIQSOL 		,Nil,Nil})
				Endif

				// Valor do ST
				If nD1ICMSRET > 0
					aLinha[nD1ICMSRET][2]	    :=  (cAliasSFT)->FT_ICMSRET
				Else
					Aadd(aLinha,{"D1_ICMSRET"	,(cAliasSFT)->FT_ICMSRET 	,Nil,Nil})
				Endif



			Endif
			(cAliasSFT)->(DbcloseArea())
		Endif

	Endif

	RestArea(aAreaOld)

Return

