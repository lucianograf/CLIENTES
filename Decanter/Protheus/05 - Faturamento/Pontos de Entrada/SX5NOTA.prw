
/*/{Protheus.doc} SX5NOTA
Ponto de entrada para restringir as séries de Notas liberadas para uso 
@type function
@version  
@author Marcelo Alberto Lauschner
@since 15/07/2021
@return variant, return_description
/*/
User Function SX5NOTA()

	Local	aAreaOld	:= GetArea()
	Local	lRet		:= .F.


	DbSelectArea("SX5")
    // Se for Admin - libera todas 
	If __cUserId $ "000000"
		lRet	:= .T.
    // Exceção de série por usuário por filial * Criar o parâmetro MV_ZSX5NOT por filial e conteúdo 000000/RPS#000100/RPS por exemplo para liberar a série RPS para alguns usuários 
	ElseIf Alltrim(__cUserId)+"/"+Alltrim(SX5->X5_CHAVE) $ GetNewPar("MV_ZSX5NOT","000000#RPS") // 000000/IS#000002/IS
		lRet	:= .T.
    Endif

    // Se não atendeu valores acima, procura por empresa 
	If !lRet
        // Se for empresa Decanter 
		If cEmpAnt == "01"
			If cFilAnt $ "0102" // Logistica Floripa 
                // Verifica se está na rotina MDFE - Manifesto de Carga para liberar a série 5 
				If FwIsInCallStack("SPEDMDFE")
					If Alltrim(SX5->X5_CHAVE) $ "5"
						lRet 	:= .T.
					Endif
				Else
                    // Libera a série 1 
					If Alltrim(SX5->X5_CHAVE) $ "1"
						lRet 	:= .T.
					Endif
				Endif
            Else 
                // Libera a série 1 
                If Alltrim(SX5->X5_CHAVE) $ "1"
					lRet 	:= .T.
				Endif
			Endif
		Else
            // Libera a série 
			If Alltrim(SX5->X5_CHAVE) $ "1#2"
				lRet 	:= .T.
			Endif
		Endif
	Endif

	RestArea(aAreaOld)

Return lRet
