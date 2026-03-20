User Function STIFINAN()
Local aRet := ParamIXB

//-------------------------
//Campo "Data"
//-------------------------
//aRet[1][2] := dDataBase //Data de Vencimento da Parcela (Valor inicial do campo "Data")
aRet[1][3] := .F. //.T.=Permite editar, .F.=Não permite editar

//-------------------------
//Campo "Valor"
//-------------------------
//aRet[2][2] := STBCalcSald("1") //Saldo restante do pagamento (Valor inicial do campo "Valor")
//aRet[2][3] := .T. //.T.=Permite editar, .F.=Não permite editar

//-------------------------
//Campo "Parcelas"
//-------------------------
//aRet[3][2] := 1 //Qtde de Parcelas (Valor inicial do campo "Parcelas")
aRet[3][3] := .F. //.T.=Permite editar, .F.=Não permite editar

Return aRet
