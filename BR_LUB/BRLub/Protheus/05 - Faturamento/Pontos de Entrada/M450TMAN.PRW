

/*/{Protheus.doc} M450TMAN
(Avalia se o pedido é de origem Tmk ou vendedor )
@author MarceloLauschner
@since 01/02/2012
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function M450TMAN()
	
	Local	aAreaOld	:= GetArea()
	Local	aRetBox
	Local	cRet
	
	// Efetua verificação se esta validação deve ser executada para esta empresa/filial
	If !U_BFCFGM25("M450TMAN")
		Return .T.
	Endif
	
	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()
	
	If Type("aHeader") <> "U"
		If aScan(aHeader,{|x| Alltrim(x[2]) == "C5_PROPRI"}) > 0 .And. Select("PED") > 0
			dbSelectArea("PED")
			dbSetOrder(1)
			DbGotop() // Forço o inicio da tabela
			DbSeek(TRB->A1_COD+TRB->A1_LOJA)
			While !Eof() .And. TRB->A1_COD == PED->C5_CLIENTE .And.TRB->A1_LOJA == PED->C5_LOJACLI
				If PED->C5_PROPRI <> "4"
					aRetBox := RetSx3Box( Posicione('SX3', 2, 'C5_PROPRI', 'X3CBox()' ),,, Len(PED->C5_PROPRI) )
					cRet	:= AllTrim( aRetBox[ Ascan( aRetBox, { |x| x[ 2 ] == PED->C5_PROPRI} ), 3 ])
					
					MsgAlert("Este cliente tem pedidos com origem diferente de 4=Representante!!"+Chr(13)+Chr(10)+"O pedido '"+PED->C5_NUM+"' tem a origem '"+PED->C5_PROPRI+"-"+cRet+"'","A T E N Ç Ã O!!!")
					Exit
				Endif
				dbSelectArea("PED")
				dbSkip()
			EndDo
		Endif
	Else
		MsgAlert("Não existe a variável aBrowse",'M450TMAN')
	Endif
	
	RestArea(aAreaOld)
	
Return .T.
