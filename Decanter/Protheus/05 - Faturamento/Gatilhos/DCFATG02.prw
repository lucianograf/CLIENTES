
/*/{Protheus.doc} DCFATG02
Gatilho para retornar o código da 
@type function
@version  
@author Marcelo Alberto Lauschner
@since 24/08/2021
@return variant, return_description
/*/
User Function DCFATG02()

	Local       aAreaOld    := GetArea()
	Local       cRetReg     := ""
    Local       cA1EST      := M->A1_EST


    If cA1EST $ "AC#AP#AM#PA#RO#RR#TO"
        cRetReg     := "001"
    ElseIf cA1EST $ "RS#PR#SC"
        cRetReg     := "002"
    ElseIf cA1EST $ "DF#GO#MT#MS"
        cRetReg     := "006"
    ElseIf cA1EST $ "AL#BA#CE#MA#PB#PE#PI#RN#SE"
        cRetReg     := "007"
    ElseIf cA1EST $ "ES#MG#RJ#SP"
        cRetReg     := "008"
    Endif 

	RestArea(aAreaOld)

Return cRetReg
