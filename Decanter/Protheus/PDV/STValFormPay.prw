User Function STValFormPay()

//Local cTipoForma := PARAMIXB[1]  //Tipo da forma de pagamento recebido via parametro

//Local nValor := PARAMIXB[2] // Valor da forma de pagamento recebido via parametro

Local nParc := PARAMIXB[3]  //Quantidade de parcelas recebido via parametro

Local lRet := .T.

If  nParc >6
       lRet := .F.
EndIf


Return lRet
