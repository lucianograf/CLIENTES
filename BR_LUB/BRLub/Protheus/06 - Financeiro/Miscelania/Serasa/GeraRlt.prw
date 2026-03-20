#Include "RwMake.ch"

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³GeraRlt   º Autor ³ Eduardo Donato     º Data ³  Mai/2007   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³Rotina responsavel por importar os dados do arquivo de      º±±
±±º          ³retorno do Serasa e gera um relatorio com o codigo e o      º±±
±±º          ³descricao do erro apresentado.															º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Versao8.11 - Parmalat                                      º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/

User Function GeraRlt( aDados )

Local cDesc1         := "Este programa tem como objetivo imprimir relatorio "
Local cDesc2         := "de acordo com os parametros informados pelo usuario."
Local cDesc3         := "SERASA-PEFIN"
Local cPict          := ""
Local titulo       	 := "SERASA-PEFIN"
Local nLin           := 80
Local Cabec1         := "| Prefixo   | Titulo   | Parcela | Tipo  | Nome do Cliente                        | Loja | Data Emissao | Vencimento Real |  Valor em R$  |  Código/Descrição dos Erros Encontrados na Transação     |       Observação     |"
Local Cabec2         := ""
Local imprime        := .T.
Local aOrd           := {}
Private lEnd         := .F.
Private lAbortPrint  := .F.
Private CbTxt        := ""
Private limite       := 220
Private tamanho      := "G"
Private nomeprog     := "GeraRlt" // Coloque aqui o nome do programa para impressao no cabecalho
Private nTipo        := 18
Private aReturn      := { "Zebrado", 1, "Administracao", 2, 2, 1, "", 1}
Private nLastKey     := 0
Private cbtxt      	 := Space(10)
Private cbcont     	 := 00
Private CONTFL     	 := 01
Private m_pag      	 := 01
Private wnrel      	 := "GeraRlt" // Coloque aqui o nome do arquivo usado para impressao em disco

//         10        20        30        40        50        60        70        80        90       100       110       120       130       140       150       160       170       180       190       200       210       220
//01234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
//| Prefixo   | Titulo   | Parcela | Tipo  | Nome do Cliente                        | Loja | Data Emissao | Vencimento Real |  Valor em R$  |  Código/Descrição dos Erros Encontrados na Transação     |       Observação     |
//   ZZZ        999999       9        00     01234567890 1234567890 123456789012345    99      99/99/99			   99/99/99        99999999,99	   XXX - TESTE DE IMPRESSAO DO RELATORIO DE RETORNO SERASA    ___________________

// Executa gravação do Log de Uso da rotina
U_BFCFGM01()

Private cString := ""

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Monta a interface padrao com o usuario...                           ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

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

RptStatus({|| RunReport(Cabec1,Cabec2,Titulo,nLin,aDados) },Titulo)
Return

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºFun‡„o    ³RUNREPORT º Autor ³ AP6 IDE            º Data ³  16/05/07   º±±
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
Local _y := 0
Local _i := 0
Local _nTam := 0
Local _nPos := 1
Local _nPosicao := 1
Local _cCodErros, _cKey
Local aDadosPE1	:= {}
Local _cQuebraLinha := '######'                     
						//Cód	Descrição			PEF	Inf
Local	aErrosPE1	:= {{"001","ARQUIVO SEM DETALHES"},;	
						{"002","PRIMEIRO REGISTRO NAO E HEADER/SEQUENCIA DIFERENTE DE 1"},;	
						{"003","REGISTRO DIFERENTE DE 0, 1 E 9"},;		
						{"004","REGISTRO FORA DE SEQUENCIA"},;	
						{"005","REGISTRO TRAILLER NAO INFORMADO	"},;		
						{"008","CODIGO DE OPERACAO DIFERENTE DE E, I"},;		
						{"009","TIPO DE PESSOA PRINCIPAL DIFERENTE DE F, J	"},;	
						{"010","TIPO DE PESSOA COOBRIGADO DIFERENTE DE F, J	"},;	
						{"011","NOME INVALIDO	"},;	
						{"012","NOME NAO PODE SER BRANCOS	"},;	
						{"013","DATA DO HEADER INVALIDA	"},;	
						{"014","DATA DA OCORRENCIA INVALIDA	"},;	
						{"016","DATA DA OCORRENCIA MAIOR QUE A ATUAL	"},;	
						{"017","DATA DA OCORRENCIA JA DECURSADA	"},;	
						{"018","IDENTIFICACAO DO ARQUIVO INVALIDA	"},;	
						{"019","REMESSA NAO POSTERIOR A ULTIMA	"},;	
						{"020","REMESSA NAO NUMERICA OU IGUAL A ZERO	"},;	
						{"021","CAMPO DE RECEBIMENTO DA REMESSA DIFERENTE DE 'E'	"},;	
						{"022","EXCLUSAO PARA REGISTRO INEXISTENTE	"},;	
						{"024","CNPJ DO HEADER INVALIDO	"},;	
						{"025","CNPJ NAO CADASTRADO NO SISTEMA (TABELA DE REMESSA)	"},;	
						{"026","FILIAL DA INSTITUICAO NAO NUMERICA	"},;	
						{"027","FILIAL DA INSTITUICAO INVALIDA	"},;	
						{"028","DOCUMENTO DO PRINCIPAL NAO NUMERICO	"},;	
						{"029","DOCUMENTO DO PRINCIPAL INVALIDO	"},;	
						{"030","DOCUMENTO DO COOBRIGADO NAO NUMERICO	"},;	
						{"031","DOCUMENTO DO COOBRIGADO INVALIDO	"},;	
						{"033","TRAILLER FORA DE SEQUENCIA	"},;	
						{"034","SEQUENCIA NAO NUMERICA	"},;	
						{"035","NATUREZA INVALIDA	"},;	
						{"036","NATUREZA INVALIDA PARA O CNPJ INFORMADO	"},;	
						{"037","PRACA INVALIDA	"},;	
						{"040","REG. NAO ATUALIZADO. ERRO NO PRINCIPAL OU COOBRIGADO DA OCORRENCIA	"},;	
						{"044","AGENCIA INVALIDA	"},;	
						{"047","CONTA NAO NUMERICA	"},;	
						{"059","INCLUSAO PARA REGISTRO JA EXISTENTE	"},;	
						{"064","CONTA INVALIDA	"},;	
						{"065","CHEQUE INVALIDO	"},;	
						{"072","ALINEA INVALIDA	"},;	
						{"081","REGISTRO APOS TRAILLER	"},;	
						{"085","NUMERO DO CONTRATO/TITULO INVALIDO	"},;	
						{"089","EMPRESA NAO PARTICIPANTE DO CONVENIO	"},;	
						{"101","DATA DE NASCIMENTO EH OBRIGATORIA/INVALIDA	"},;	
						{"102","NUMERO DO CONTRATO/TITULO EH OBRIGATORIO	"},;	
						{"103","TIPO DE DOCUMENTO INVALIDO	"},;	
						{"105","INCLUSAO BLOQUEADA FACE A DETERMINACAO ADMINISTRATIVA	"},;	
						{"106","MOVIMENTO APOS RESCISAO DE CONTRATO DO CONVENIO	"},;	
						{"109","FALTA ENDERECO	"},;	
						{"111","FALTA UF DO ENDERECO	"},;	
						{"112","FALTA CEP DO ENDERECO	"},;	
						{"113","FALTA INFORMACAO TIPO DE PESSOA	"},;	
						{"115","TIPO DE PESSOA DO PRINCIPAL DIFERENTE DE F	"},;	
						{"116","TIPO DE PESSOA DO COOBRIGADO DIFERENTE DE F	"},;	
						{"119","CEP DO ENDERECO INVALIDO	"},;	
						{"121","DATA DE NASCIMENTO INFERIOR A 18 ANOS	"},;	
						{"142","BANCO NAO TRABALHA COM CONTA CORRENTE	"},;	
						{"156","DATA OCORRENCIA INFERIOR A 4 DIAS	"},;	
						{"165","DT.TERMINO DO CONTRATO ANTERIOR A DT. DA OCORRENCIA	"},;	
						{"166","DATA DE TERMINO DO CONTRATO INVALIDA	"},;	
						{"167","FALTA UF DO RG	"},;	
						{"168","VALOR DEVE SER NUMERICO E MAIOR QUE ZEROS	"},;	
						{"169","AREA INFORMANTE DA REMESSA C/ ERRO. MOVIMENTO REJEITADO	"},;	
						{"170","BANCO INVAL. P/ NATUREZA DE/DC	"},;	
						{"171","TIPO DE PESSOA DO CREDOR DIFERENTE DE F, J	"},;	
						{"172","TIPO DE DOCUMENTO DO CREDOR INVALIDO	"},;	
						{"173","DOCUMENTO DO CREDOR NAO NUMERICO	"},;	
						{"174","DOCUMENTO DO CREDOR INVALIDO	"},;	
						{"175","NOME DO CREDOR EH OBRIGATORIO"},;		
						{"176","NOME DO CREDOR INVALIDO	"},;	
						{"177","FOI INFORMADO O CREDOR. PARTICIPANTE NAO EH ENTIDADE DE CLASSE	"},;	
						{"181","EXCL. DEVIDO DEVOL. COMUNICADO PELO CORREIO. MUDOU-SE	"},;	
						{"182","EXCL. DEVIDO DEVOL. COMUNICADO PELO CORREIO. ENDERECO INSUFICIENT	"},;	
						{"183","EXCL. DEVIDO DEVOL. COMUNICADO PELO CORREIO. NUMERO INEXISTENTE	"},;	
						{"184","EXCL. DEVIDO DEVOL. COMUNICADO PELO CORREIO. DESCONHECIDO	"},;	
						{"185","EXCL. DEVIDO DEVOL. COMUNICADO PELO CORREIO. RECUSADO	"},;	
						{"186","EXCL. DEVIDO DEVOL. COMUNICADO PELO CORREIO. NAO PROCURADO	"},;	
						{"187","EXCL. DEVIDO DEVOL. COMUNICADO PELO CORREIO. AUSENTE	"},;	
						{"188","EXCL. DEVIDO DEVOL. COMUNICADO PELO CORREIO. FALECIDO	"},;	
						{"189","EXCL.DEVIDO DEVOL.COMUNICADO PELO CORREIO.INFOR.PORTEIRO/SINDICO	"},;	
						{"190","EXCL. DEVIDO DEVOL. COMUNICADO PELO CORREIO. ENDERECO DESCONHECIDO	"},;	
						{"191","EXCL. DEVIDO DEVOL. COMUNICADO PELO CORREIO. CEP INCORRETO	"},;	
						{"192","EXCL. DEVIDO DEVOL. COMUNICADO PELO CORREIO. NAO ESPECIFICADO"},;	
						{"193","EXCL. DEVIDO DEVOL. COMUNICADO PELO CORREIO. CX POSTAL INEXISTENTE"},;	
						{"194","EXCL. DEVIDO DEVOL. COMUNICADO PELO CORREIO. IMOVEL INEXISTENTE	"},;	
						{"195","EXCL. DEVIDO DEVOL. COMUNICADO PELO CORREIO"},;	
						{"196","INCLUSAO RECUSADA/CARTA DEVOLVIDA DO CORREIO/END.IGUAL AO ANTERIOR"},;	
						{"197","ENDERECO ALTERNATIVO SOLICITADO PELA CONTRATANTE"},;	
						{"219","VALOR DO TITULO INVALIDO"},;	
						{"263","IDENTIFICACAO DO ARQUIVO INVALIDA"},;	
						{"274","CNPJ NAO EXISTE NO CADASTRO DE CNPJ/CPF ATE ESTA DAT"},;	
						{"275","CPF NAO EXISTE NO CADASTRO DE CNPJ/CPF ATE ESTA DATA"},;	
						{"276","FILIAL NAO EXISTE NO CADASTRO DE CNPJ/CPF ATE ESTA DATA	"},;	
						{"277","CNPJ CREDOR/CEDENTE NAO EXISTE NO CADASTRO DE CNPJ/CPF ATE ESTA DAT	"},;	
						{"278","CPF CREDOR/CEDENTE NAO EXISTE NO CADASTRO DE CNPJ/CPF ATE ESTA DATA"},;	
						{"279","FILIAL CREDOR/CEDENTE NAO EXISTE CADASTRO DE CNPJ/CPF ATE ESTA DAT"},;	
						{"286","DOCUMENTO DO CREDOR IGUAL AO DO NEGATIVADO"},;	
						{"289","INFORMADO A UF SEM O NUMERO DO RG"},;	
						{"290","EXCLUSAO POR DATA DE OCORRENCIA JA DECURSADA"},;	
						{"291","EXCLUSAO POR DETERMINACAO JUDICIAL"},;	
						{"292","EXCLUSAO POR SOLICITACAO DA EMPRESA PARTICIPANTE"},;	
						{"295","RAZAO SOCIAL NAO CORRESPONDE AO CNPJ INFORMADO"},;	
						{"296","NOME NAO CORRESPONDE AO CPF INFORMADO"},;	
						{"298","COOBRIGADO NAO INCLUIDO - PRINCIPAL NAO ENCONTRADO"},;	
						{"301","REGISTRO ESPECIAL - DEVOLUCAO COMUNICADO DO CORREIO - MUDOU-SE"},;	
						{"302","REGISTRO ESPECIAL - DEVOLUCAO COMUNICADO DO CORREIO - END INSUFICIENTE	"},;	
						{"303","REGISTRO ESPECIAL - DEVOLUCAO COMUNICADO DO CORREIO - NR INEXISTENTE"},;	
						{"304","REGISTRO ESPECIAL - DEVOLUCAO COMUNICADO DO CORREIO - DESCONHECIDO"},;	
						{"305","REGISTRO ESPECIAL - DEVOLUCAO COMUNICADO DO CORREIO - RECUSADO	"},;	
						{"306","REGISTRO ESPECIAL - DEVOLUCAO COMUNICADO DO CORREIO - NAO PROCURADO	"},;	
						{"307","REGISTRO ESPECIAL - DEVOLUCAO COMUNICADO DO CORREIO - AUSENTE	"},;	
						{"308","REGISTRO ESPECIAL - DEVOLUCAO COMUNICADO DO CORREIO - FALECIDO"},;	
						{"309","REGISTRO ESPECIAL - DEVOLUCAO COMUNICADO CORREIO - INFORM P/ PORTEIRO"},;	
						{"310","REGISTRO ESPECIAL - DEVOLUCAO COMUNICADO DO CORREIO - END N CONHECIDO"},;	
						{"311","REGISTRO ESPECIAL - DEVOLUCAO COMUNICADO DO CORREIO - CEP INCORRETO	"},;	
						{"312","REGISTRO ESPECIAL - DEVOLUCAO COMUNICADO DO CORREIO - N ESPECIFICADO"},;	
						{"313","REGISTRO ESPECIAL - DEVOLUCAO COMUNICADO CORREIO - CX POSTAL INEXIST"},;	
						{"314","REGISTRO ESPECIAL - DEVOLUCAO COMUNICADO CORREIO - IMOVEL INEXISTENTE	"},;	
						{"315","DEVIDO A DEVOLUCAO DO COMUNICADO DO CORREIO	"},;	
						{"356","DATA DO COMPROMISSO MAIOR QUE A ATUAL"},;	
						{"357","DATA DO COMPROMISSO INVALIDA"},;	
						{"358","VALOR DO COMPROMISSO NAO NUMERICO"},;	
						{"359","DDD DEVE SER NUMERICO	"},;	
						{"360","TELEFONE DEVE SER NUMERICO	"},;	
						{"381","INCLUSAO REJEITADA - VLR CONSID.ELEVADO - INCLUIR PELO SISCONVEM"},;	
						{"390","INCLUSAO RECUSADA - PARTICIPANTE COM LOGON BLOQUEADO"},;	
						{"391","REGISTRO REJEITADO - INCONSISTENCIA NO HEADER	"},;	
						{"392","FALTA CODIGO CLIENTE NA RSREMESSA OU CODIGO NAO TEM 5 CARACTERE	"},;	
						{"393","FALTA PROCNAME NA RSREMESS OU PROCNAME NAO TEM 8 CARACTERS	"},;	
						{"394","CNPJ NAO CORRESPONDE AO CODIGO DE CLIENTE INFORMADO	"},;	
						{"396","INCLUSAO REJEITADA-VLR.CONS.ELEVADO-NEGAT.PRIMARIA-INCL.SISCONVEM"},;	
						{"397","VLR CONSID ELEVADO-NEGAT PRIMARIA-REDIGITAR O VALOR	"},;	
						{"429","PROCNAME (REMESSA) INVALIDO - TAMANHO DO REGISTRO ERRADO	"},;	
						{"430","PROCNAME (REMESSA) INVALIDO - TIPO DE TRANSMISSAO ERRADO"},;	
						{"443","EXCLUSAO POR CONTESTACAO/DECLARACAO DO INTERESSADO"},;	
						{"465","DATA DO CANCELAMENTO DO CONTRATO NAO INFORMADA	"},;	
						{"466","EXCLUSAO POR FALTA DE DOCUMENTACAO DA DIVIDA"},;	
						{"488","PARTICIPANTE NAO POSSUI PROCURACAO DO CREDOR"},;	
						{"489","UF DO RG INVALIDO	"},;	
						{"490","FALTAM DADOS CADASTRAIS DO CREDOR DA DIVIDA	"},;	
						{"491","MUNICIPIO NAO CORRESPONDE AO CEP E/OU UF INFORMADO	"},;	
						{"495","PRO-REDE - NAO LOCALIZADO O ENDERECO DO CREDOR	"},;	
						{"609","EXCLUSAO - CARTA COMUNICADO/COMPROVANTE NAO RETORNOU DOS CORREIOS	"},;	
						{"610","INCLUSAO CONDICIONADA A APRESENTACAO DE DOCTO DA DIVIDA	"},;	
						{"611","LOGON INFORMADO NO HEADER NAO PERTENCE AO PARTICIPANTE	"},;	
						{"612","LOGON INFORMADO NO HEADER NAO ENCONTRADO	"},;	
						{"620","SCORE NAO CALCULADO POR SOLICITACAO DO CLIENTE, ANOTACAO NAO INCLUIDA	"},;	
						{"621","SCORE ACIMA DO PERMITIDO, ANOTACAO NAO INCLUIDA	"},;	
						{"650","CODIGO DO BANCO INVALIDO	"},;	
						{"651","BANCO NÃO CADASTRADO	"},;	
						{"652","DIGITO DO CODIGO DO BANCO INVALIDO	"},;	
						{"653","NOME DO BANCO NÃO INFORMADO	"},;	
						{"654","CARACTERES DA LINHA DIGITAVEL INVALIDA	"},;	
						{"655","PRIMEIRO DIGITO DA LINHA DIGITAVEL DIVERGENTE	"},;	
						{"656","SEGUNDO DIGITO DA LINHA DIGITAVEL DIVERGENTE	"},;	
						{"657","TERCEIRO DIGITO DA LINHA DIGITAVEL DIVERGENTE	"},;	
						{"658","QUARTO DIGITO DA LINHA DIGITAVEL DIVERGENTE	"},;	
						{"659","TEXTO DO LOCAL DE PAGAMENTO NÃO INFORMADO	"},;	
						{"660","DATA DE VENCIMENTO DO BOLETO INVALIDA	"},;	
						{"661","DATA DE VENCIMENTO DO BOLETO MENOR QUE A DATA DE HOJE	"},;	
						{"662","TIPO DE PESSOA DO DOCUMENTO DO CEDENTE INVALIDO	"},;	
						{"663","TIPO DE DOCUMENTO  DO CEDENTE DIVERGENTE DO TIPO DE PESSOA	"},;	
						{"664","DOCUMENTO DO CEDENTE INVALIDO	"},;	
						{"665","DIGITO DO DOCUMENTO DO CEDENTE INVALIDO	"},;	
						{"666","AGENCIA E CODIGO DO CEDENTE NÃO INFORMADO	"},;	
						{"667","DATA DO DOCUMENTO INVALIDA	"},;	
						{"668","NUMERO DO DOCUMENTO NÃO INFORMADO	"},;	
						{"669","DATA DO PROCESSAMENTO INFORMADA E INVALIDA	"},;	
						{"670","NOSSO NUMERO NÃO INFORMADO	"},;	
						{"671","QUANTIDADE DE MOEDA NÃO INFORMADA	"},;	
						{"672","QUANTIDADE DE MOEDA INVALIDA	"},;	
						{"673","QUANTIDADE DE DECIMAIS DA MOEDA NÃO INFORMADA	"},;	
						{"674","QUANTIDADE DE DECIMAIS DA MOEDA INVALIDA	"},;	
						{"675","QUANTIDADE DE DECIMAIS DA MOESA MAIOR QUE 5 CASAS DECIMAIS	"},;	
						{"676","VALOR DA MOEDA NÃO INFORMADO	"},;	
						{"677","VALOR DA MOEDA INVALIDA	"},;	
						{"678","VALOR DO DOCUMENTO INVALIDO	"},;	
						{"679","VALOR DE OUTROS ACRESCIMOS INVALIDO	"},;	
						{"680","VALOR DE DESCONTOS/ABATIMENTO INVALIDO	"},;	
						{"681","VALOR DE OUTRAS DEDUCOES INVALIDO	"},;	
						{"682","VALOR DE MORA/MULTA INVALIDO	"},;	
						{"683","VALOR COBRADO INVALIDO	"},;	
						{"684","TIPO DE PESSOA DO DOCUMENTO DO SACADOR INVALIDO	"},;	
						{"685","TIPO DE DOCUMENTO  DO SACADOR DIVERGENTE DO TIPO DE PESSOA	"},;	
						{"686","DOCUMENTO DO SACADOR INVALIDO	"},;	
						{"687","DIGITO DO DOCUMENTO DO SACADOR INVALIDO	"},;	
						{"701","EXISTE DADOS DE BOLETO E NAO INFORMADO O INDICATIVO DE TIPO DE COMUNICADO	"},;	
						{"702","INDICATIVO DE TIPO DE COMUNICADO DIFERENTE DE BRANCO OU 'B' "},;	
						{"703","TIPO DE COMUNICADO COMO BOLETO E NÃO FOI INFORMADO O REG. TP 2 E/OU 3"},;	
						{"704","TIPO DE COMUNICADO BOLETO NÃO PERMITIDO PARA COOBRIGADO	"},;	
						{"705","REG BOLETO TIPO 2 ENCONTRADO, SEM REGISTRO TIPO 1 CORRESPONDENTE"},;	
						{"706","REG BOLETO TIPO 3 ENCONTRADO, SEM REGISTRO TIPO 1 CORRESPONDENTE"},;	
						{"707","PARTICIPANTE NAO POSSUI CONTRATO PARA EMISSAO DE COMUNICADO COM BOLETO"}}

For _i := 1 To Len( aDados )
	
	If lAbortPrint
		@nLin,00 PSAY "*** CANCELADO PELO OPERADOR ***"
		Exit
	Endif
	// Diferente de Cabeçalho e rodapé
	If !aDados[_i][1] $ '0|9'
		_cCodCtr := aDados[_i][32]		
		If nLin > 55
			Cabec(Titulo,Cabec1,Cabec2,NomeProg,Tamanho,nTipo)
			nLin := 8
		Endif
		nPosSubs		:= 1		
		_cCnpj			:= SubStr( aDados[_i][10], 2, Len( aDados[_i][10] ) )
		_cPrefixo 		:= SubStr( aDados[_i][32],nPosSubs,TamSX3('E1_PREFIXO')[1] )
		nPosSubs		+= TamSX3('E1_PREFIXO')[1]
		_cNumero		:= SubStr( aDados[_i][32],nPosSubs,TamSX3('E1_NUM')[1] )
		nPosSubs		+= TamSX3('E1_NUM')[1]
		_cParcela 		:= Substr( aDados[_i][32],nPosSubs,TamSX3('E1_PARCELA')[1] ) 
		nPosSubs		+= TamSX3('E1_PARCELA')[1]
		_cTipo			:= SubStr( aDados[_i][32],nPosSubs,TamSX3('E1_TIPO')[1] )
		_cNomeCli 		:= AllTrim( Posicione( 'SA1', 3, xFilial('SA1') + Padr(_cCnpj,TamSX3('A1_CGC')[1]) , 'A1_NOME' ) )
		_cLojaCli		:= Posicione( 'SA1', 3, xFilial('SA1') + Padr(_cCnpj,TamSX3('A1_CGC')[1]) , 'A1_LOJA' )
		_dDtEmissao		:= Stod( aDados[_i][4] )
		_dDtVencRea		:= Stod( aDados[_i][5] )
		_cValor			:= aDados[_i][31]
		_nValor			:= Val(_cValor) /100 //AllTrim( Str( Val( SubStr(_cValor,1,Len(_cValor)-2) ) ) ) +"."+IIF( !Empty( SubStr(_cValor,Len(_cValor)-1,Len(_cValor) ) ), SubStr(_cValor,Len(_cValor)-1,Len(_cValor) ), '00' )
		_cCodigo		:= aDados[_i][40]
		_nTam			:= Len( AllTrim( _cCodigo ) )
		_nPos			:= 1
		
		If _nTam > 0  
			While _nPos < _nTam
				_cCodErro		:= SubStr( _cCodigo, _nPos, 3 )
				nPosErro	:= aScan(aErrosPE1,{|x| x[1] == _cCodErro})
				Aadd( aDadosPE1, { 	_nPosicao ,_cPrefixo, _cNumero, _cParcela, _cTipo, _cNomeCli,;
				_cLojaCli, _dDtEmissao, _dDtVencRea, _nValor, ;
				_cCodErro, IIf(Empty(nPosErro),"",Substr(aErrosPE1[nPosErro,2],1,50)) }) //PE1->PE1_COD, AllTrim( PE1->PE1_DESCRI ) } )
				_nPos 			:= _nPos + 3
				_nPosicao		:= _nPosicao + 1
			EndDo
			_nPosicao := 1
			Aadd( aDadosPE1, { ,_cQuebraLinha,,,,,,,,,, } )
	    Else
		Aadd( aDadosPE1, { 	_nPosicao ,_cPrefixo, _cNumero, _cParcela, _cTipo, _cNomeCli,;
				_cLojaCli, _dDtEmissao, _dDtVencRea, _nValor, ;
				"", ""})

		EndIf
	EndIf
Next _i


If Len( aDadosPE1 ) == 0
	@nLin,15 PSAY "************ ARQUIVO SEM OCORRÊNCIAS DE ERRO ************"
Endif

For _y := 1 To Len( aDadosPE1 )
	
	If aDadosPE1[_y,1] == 1
		@nLin,03 PSAY aDadosPE1[_y,2]
		@nLin,14 PSAY aDadosPE1[_y,3]
		@nLin,27 PSAY aDadosPE1[_y,4]
		@nLin,36 PSAY aDadosPE1[_y,5]
		@nLin,43 PSAY aDadosPE1[_y,6]
		@nLin,85 PSAY aDadosPE1[_y,7]
		@nLin,93 PSAY aDadosPE1[_y,8]
		@nLin,109 PSAY aDadosPE1[_y,9]
		@nLin,125 PSAY Transform(aDadosPE1[_y,10],"@E 99,999,999.99")
		@nLin,141 PSAY aDadosPE1[_y,11] +" - "+ Substr(aDadosPE1[_y,12],1,50)
		@nLin,200 PSAY "________________"
		nLin := nLin + 1 // Avanca a linha de impressao
	ElseIf !Empty( aDadosPE1[_y,1] ) .And. aDadosPE1[_y,2] # _cQuebraLinha
		@nLin,141 PSAY aDadosPE1[_y,11] +" - "+ aDadosPE1[_y,12]
		@nLin,200 PSAY "________________"
		nLin := nLin + 1 // Avanca a linha de impressao
	ElseIf Empty( aDadosPE1[_y,1] ) .And. aDadosPE1[_y,2] $ _cQuebraLinha
		@nLin,00 PSAY Replicate("_",220)
		nLin := nLin + 1
	EndIf
	
Next _y

SET DEVICE TO SCREEN

If aReturn[5]==1
	dbCommitAll()
	SET PRINTER TO
	OurSpool(wnrel)
Endif

MS_FLUSH()
Return
