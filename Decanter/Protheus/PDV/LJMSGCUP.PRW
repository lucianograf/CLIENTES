#INCLUDE "RWMAKE.CH"

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Para utilizar este RDMAKE, preencha no conteudo do parametro MV_LJFISMS    ³
//³ com a seguinte expressao:                                                  ³
//³ "&ExecBlock("LJMSGCUP",.F.,.F.,{lUsaRegime,lEntrega,lUsaCartao,lFuturoTef})³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³LJMsgCup  ºAutor  ³Fernando Salvatori  º Data ³  25/04/2003 º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Imprime a mensagem no cupom fiscal                         º±±
±±º          ³ Utilizado no parametro MV_LJFISMS                          º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Rdmake Padrao                                              º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
User Function LJMSGCUP()
//Local _lUsaRegime := ParamIXB[1] //Verifica se utiliza o Regime Especial
//Local _lEntrega   := ParamIXB[2] //Verifica se utiliza Entrega 
//Local _lUsaCartao := ParamIXB[3] //Verifica se a venda esta utilizando cartao de credito/debito
//Local _lFuturoTef := ParamIXB[4] //Verifica se a venda esta utilizando cartao de credito/debito
Local _aAreaSA1   := SA1->( GetArea() )         //Area do arquivo SA1
Local _aArea      := GetArea()                  //Area atual do sistema
Local _cRet       := " "  //Mensagem de retorno

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Documentacao das variaveis:                                         ³
//³                                                                    ³
//³_lUsaRegime:                                                        ³
//³     .F. -> Indica que a venda via TEF nao utiliza o Regime Especial³
//³     .T. -> Indica que a venda via TEF utiliza Regime Especial      ³
//³_lEntrega                                                           ³
//³     .T. -> Orcamento "Entrega"                                     ³
//³     .F. -> Orcamento "Retira"                                      ³
//³_lUsaCartao                                                         ³
//³     .T. -> Utiliza Cartao de Credito/Debito (CC,CD)                ³
//³     .F. -> Nao utiliza cartao                                      ³
//³_lFuturoTef                                                         ³
//³     .F. -> Caso utilize o Regime, sera impresso como forma         ³
//³            de pagamento a frase "FUTURO TEF"                       ³
//³     .T. -> Caso utilize o Regime, sera impresso como forma         ³
//³            de pagamento a frase "RECEPCAO TEF"                     ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
    
//If _lUsaRegime .And. _lEntrega .And. _lUsaCartao .And. !_lFuturoTef	
	dbSelectArea( "SA1" )
	dbSetOrder( 1 )
	dbSeek( xFilial( "SA1" ) + SL1->L1_CLIENTE + SL1->L1_LOJA )
	
	_cRet := "Obrigado!" + " " + AllTrim(SA1->A1_NOME) + " - " + AllTrim(SA1->A1_CGC)
//EndIf

SA1->( RestArea(_aAreaSA1) )   
RestArea( _aArea )

Return _cRet
