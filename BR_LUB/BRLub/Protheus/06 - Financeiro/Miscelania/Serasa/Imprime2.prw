#Include "Rwmake.ch"

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³Imprime2  º Autor ³ Eduardo Donato     º Data ³  Mai/2007   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Imprime o Relatorio de Itens a serem Enviados para o       º±±
±±º          ³ Serasa-Pefin.                                              º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Versao8.11 - Parmalat                                      º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/

User Function Imprime2( nParam, aDados )

Local cDesc1         	:= "Este programa tem como objetivo imprimir relatorio "
Local cDesc2         	:= "de acordo com os parametros informados pelo usuario."
Local cDesc3         	:= ""
Local cPict          	:= ""
Local titulo       		:= "Titulos a Serem Enviados para o Serasa"
Local nLin         		:= 80
Local imprime      		:= .T.
Local _cData					:= SubStr( Dtos( dDataBase ),7,2)+"/"+SubStr( Dtos( dDataBase ),5,2)+"/"+SubStr( Dtos( dDataBase ),1,4)
Local aOrd 						:= {}
Local Cabec1				  :="                                                             RELACAO DE TITULOS PARA SEREM ENVIADOS PARA O SERASA - MOTIVO :"+IIF( nParam == 1,"REMESSA","EXCLUSÃO")+" - DATA: "+_cData+"                                 "
Local Cabec2				  :="|Pref-Numero|Parc|Natureza  |Tipo |    CPF / CNPJ    |Codigo-Loja / Nome do Cliente                         |Emissao   |Vencimento|Venc. Real|    Valor R$      |     Saldo R$     |  Chave Arquivo   |Status|   Observacao |"
Private lEnd         	:= .F.
Private lAbortPrint  	:= .F.
Private CbTxt        	:= ""
Private limite       	:= 220
Private tamanho      	:= "G"
Private nomeprog     	:= "TITENVSERASA" // Coloque aqui o nome do programa para impressao no cabecalho
Private nTipo        	:= 18
Private aReturn      	:= { "Zebrado", 1, "Administracao", 2, 2, 1, "", 1}
Private nLastKey     	:= 0
Private cbtxt        	:= Space(10)
Private cbcont       	:= 00
Private CONTFL       	:= 01
Private m_pag        	:= 01
Private wnrel        	:= "TITSER" // Coloque aqui o nome do arquivo usado para impressao em disco
Private cString 			:= ""

// Executa gravação do Log de Uso da rotina
U_BFCFGM01()

//         10        20        30        40        50        60        70        80        90       100       110       120       130       140       150       160       170       180       190       200       210       220
//01234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
//|                                                    |                  Relacao de Titulos Enviados para o Serasa Motivo : Remessa - Data: 99/99/99                      |                                                  |
//|Pref-Numero|Parc|Natureza  |Tipo |    CPF / CNPJ    |Codigo-Loja / Nome do Cliente                         |Emissao   |Vcto      |Venc. Real|   Valor R$   | Saldo R$     | Chave Arquivo  |Status|        Observacao        |
//|ZZ-123456  | Z  |1234567890| 123 |12.345.678/9012-34| 123456-99  / 1234567890123456789012345678901234567890|99/99/9999|99/99/9999|99/99/9999|999,999,999.99|999,999,999.99|1234567890123456|  99  |__________________________|


wnrel := SetPrint(cString,NomeProg,"",@titulo,cDesc1,cDesc2,cDesc3,.T.,aOrd,.T.,Tamanho,,.T.)

If nLastKey == 27
	Return
Endif

SetDefault(aReturn,cString)

If nLastKey == 27
	Return
Endif

nTipo := If(aReturn[4]==1,15,18)

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Processamento. RPTSTATUS monta janela com a regua de processamento. ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

RptStatus( {|| RunReport(Cabec1,Cabec2,Titulo,nLin,aDados) },Titulo )
Return

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºFun‡„o    ³RUNREPORT º Autor ³ AP6 IDE            º Data ³  31/05/07   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescri‡„o ³ Funcao auxiliar chamada pela RPTSTATUS. A funcao RPTSTATUS º±±
±±º          ³ monta a janela com a regua de processamento.               º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Programa principal                                         º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/

Static Function RunReport(Cabec1,Cabec2,Titulo,nLin,aDados)
Local _x , _y := 0
Local aDadosVis := {}
Local aDadosVip	:= aDados
Local _cPrefixo, _cNumero, _cParcela, _cNatureza, _cTipo,_cCgc
Local _cCodCli, _cLojCLi, _cNomCLi, _dEmissao, _dVencto, _dVencRea
Local _nValor, _nSaldo, _cKeyArq


SetRegua(0)

DbSelectArea("SE1")

For _y := 1 To Len( aDadosVip )
	
	SE1->( dbGoTo( aDadosVip[_y,16] ) )
	
	_cPrefixo 		:= AllTrim( aDadosVip[_y,2] )
	_cNumero		:= aDadosVip[_y,3]
	_cParcela		:= IIF( Empty( aDadosVip[_y,4] ), Space(1), aDadosVip[_y,4] )
	_cNatureza		:= AllTrim( aDadosVip[_y,5] )
	_cTipo			:= AllTrim( aDadosVip[_y,6] )
	_nValor			:= aDadosVip[_y,7]
	_nSaldo			:= aDadosVip[_y,8]
	_cCodCli		:= SE1->E1_CLIENTE
	Posicione ('SA1',1, xFilial('SA1') + SE1->E1_CLIENTE+SE1->E1_LOJA, 'A1_CGC')
	_cCgc			:= Transform(SA1->A1_CGC,IIF( Len( Alltrim(SA1->A1_CGC) ) == 14, PesqPict("SA1","A1_CGC"),"99.999.999-99") )
	_cLojCli		:= SE1->E1_LOJA
	_cNomCli		:= AllTrim( aDadosVip[_y,9] )
	_dEmissao		:= aDadosVip[_y,12]
	_dVencto		:= aDadosVip[_y,13]
	_dVencRea		:= aDadosVip[_y,14]
			
//	_cKeyArq		:= StrZero(Val(aDadosVip[_y,3]),11)+IIF(!Empty(aDadosVip[_y,2]),AllTrim(aDadosVip[_y,2]),'99')+IIF(!Empty(aDadosVip[_y,4]),aDadosVip[_y,4],'Z')+AllTrim(aDadosVip[_y,6] )
	_cKeyArq		:= SE1->E1_FILIAL+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+SE1->E1_TIPO
	
	Aadd( aDadosVis, {	 _cPrefixo,;
						 _cNumero,;
						 _cParcela,; 
						 _cNatureza, ;
						 _cTipo,;
						 _cCgc,;
						 _cCodCli, ;
						 _cLojCLi, ;
						 _cNomCLi, ;
						 _dEmissao, ;
						 _dVencto, ;
						 _dVencRea,;
	                     _nValor, ;
	                     _nSaldo, ;
	                     _cKeyArq } )
	If _y == 1
		Aadd( aDadosVis, {	_cPrefixo, _cNumero, _cParcela, _cNatureza, _cTipo,_cCgc,;
		_cCodCli, _cLojCLi, _cNomCLi, _dEmissao, _dVencto, _dVencRea,;
		_nValor, _nSaldo, _cKeyArq } )

		Aadd( aDadosVis, {	_cPrefixo, _cNumero, _cParcela, _cNatureza, _cTipo,_cCgc,;
		_cCodCli, _cLojCLi, _cNomCLi, _dEmissao, _dVencto, _dVencRea,;
		_nValor, _nSaldo, _cKeyArq } )
	EndIf
	
Next _y




For _x := 1 To Len( aDadosVis )
	
	If lAbortPrint
		@nLin,00 PSAY "*** CANCELADO PELO OPERADOR ***"
		Exit
	Endif
	
	If nLin > 55 // Salto de Página. Neste caso o formulario tem 55 linhas...
		Cabec(Titulo,Cabec1,Cabec2,NomeProg,Tamanho,nTipo)
		nLin := 8
	Endif
//         10        20        30        40        50        60        70        80        90       100       110       120       130       140       150       160       170       180       190       200       210       220
//01234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
//|                                                    |                  Relacao de Titulos Enviados para o Serasa Motivo : Remessa - Data: 99/99/99                      |                                                  |
//|Pref-Numero|Parc|Natureza  |Tipo |    CPF / CNPJ    |Codigo-Loja / Nome do Cliente                         |Emissao   |Vencimento|Venc. Real|    Valor R$      |     Saldo R$     |  Chave Arquivo   |Status|   Observacao |
//|ZZZ 123456 | Z  |1234567890| 123 |12.345.678/9012-34| 123456-99  / 1234567890123456789012345678901234567890|99/99/9999|99/99/9999|99/99/9999| 9,999,999,999.99 | 9,999,999,999.99 | 1234567890123456 |  99  |______________|
	
	@nLin,00 PSAY "|"
	@nLin,01 PSAY aDadosVis[_x][1]
//	@nLin,03 PSAY "-"
	@nLin,05 PSAY aDadosVis[_x][2]
	@nLin,12 PSAY "|"
	@nLin,14 PSAY aDadosVis[_x][3]
	@nLin,17 PSAY "|"
	@nLin,18 PSAY aDadosVis[_x][4]
	@nLin,28 PSAY "|"
	@nLin,30 PSAY aDadosVis[_x][5]
	@nLin,34 PSAY "|"
	@nLin,35 PSAY aDadosVis[_x][6]
	@nLin,53 PSAY "|"
	@nLin,55 PSAY aDadosVis[_x][7]
	@nLin,62 PSAY aDadosVis[_x][8]
	@nLin,66 PSAY "/"
	@nLin,68 PSAY aDadosVis[_x][9]
	@nLin,108 PSAY "|"
	@nLin,109 PSAY aDadosVis[_x][10]
	@nLin,119 PSAY "|"
	@nLin,120 PSAY aDadosVis[_x][11]
	@nLin,130 PSAY "|"
	@nLin,131 PSAY aDadosVis[_x][12]
	@nLin,141 PSAY "|"
	@nLin,142 PSAY Transform( aDadosVis[_x][13], "@E 9,999,999,999.99")	//	PesqPict( "SE1", "E1_VALOR" ) )
	@nLin,160 PSAY "|"
	@nLin,161 PSAY Transform( aDadosVis[_x][14], "@E 9,999,999,999.99") // PesqPict( "SE1", "E1_SALDO" ) )
	@nLin,179 PSAY "|"
	@nLin,181 PSAY aDadosVis[_x][15]
	@nLin,198 PSAY "|"
	@nLin,201 PSAY IIF( Mv_Par01 == 1, '  ', '20')
	@nLin,205 PSAY "|"
	@nLin,206 PSAY Replicate("_",14)
	@nLin,220 PSAY "|"
	If _x != 1
		nLin := nLin + 1 // Avanca a linha de impressao
		@nLin,00 PSAY Replicate("_",220)
		nLin := nLin + 1
	EndIf
Next _x

SET DEVICE TO SCREEN

If aReturn[5]==1
	dbCommitAll()
	SET PRINTER TO
	OurSpool(wnrel)
Endif

MS_FLUSH()

Return
