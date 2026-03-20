

/*/{Protheus.doc} MT100GE2
Ponto de entrada para gravar campos adicionais da SE2 a partir da nota de entrada 
@type function
@version  
@author Marcelo Alberto Lauschner
@since 21/10/2021
@return variant, return_description
/*/
User Function MT100GE2()

	Local _aCols   	:= PARAMIXB[1]
	Local nOpc    	:= PARAMIXB[2]
	Local _aHeadSE2	:= PARAMIXB[3]
	Local nPosHis	:=Ascan(_aHeadSE2,{|x| Alltrim(x[2]) == 'E2_HIST'})
	local cBcoPag   := AllTrim( SuperGetMv( 'MV_X_BCPAG',,'341' ) )

	If nOpc == 1
		If (cEmpAnt $ "05#12#13") // Frimazo / Santa Agro / Sanlucio 
			If nPosHis !=0 .And. !Empty(_aCols[nPosHis] )
				SE2->E2_HIST        :=  _aCols[nPosHis] // Grava o histórico digitado na nota
			Endif
		Else
			If nPosHis !=0 .And. !Empty(_aCols[nPosHis] )
				SE2->E2_HIST        :=  _aCols[nPosHis] // Grava o histórico digitado na nota
				SE2->E2_PORTADO     := cBcoPag // Grava o Portador direto
			ElseIf nPosHis !=0
				If FwIsInCallStack("MATA116")
					SE2->E2_HIST        := "FRETE S/COMPRAS "  // Grava o histórico padrão
				ElseIf !Alltrim(cEspecie) $ "CTE" // Se não for CTe 
					SE2->E2_HIST        := "FORNECEDOR " + SE2->E2_NOMFOR  // Grava o histórico padrão
				Endif 
				SE2->E2_PORTADO     := cBcoPag // Grava o portador direto
			Endif
		Endif
	EndIf


Return Nil
