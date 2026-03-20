#include "rwmake.ch"


/*/{Protheus.doc} BFFINM01
(Altera arquivo Cnab do Bradesco Bic )
@author MarceloLauschner
@since 19/04/2012
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function MLFINM01()
	
	Local		lCont		:= .F.
	Local		lPrivez		:=.T.
	Local		cConcMsg	:= ""
	Private 	cPerg		:= "MLFINM01"
	
	ValidPerg()
	
	Pergunte(cPerg,.T.)
	
	#IFDEF WINDOWS
		@ 100, 050 TO 330, 517 DIALOG oDlg1 TITLE "Ajustes Arquivo Retorno"
		@ 005, 002 To 087, 230
		@ 018, 010 Say "Este programa tem como objetivo fazer Ajustes no Arquivo Retorno - cfe parametros  "  SIZE 210, 11
		@ 034, 010 Say "especificados para correto tratamento dos titulos pela Recepcao Bancaria .         "  SIZE 210, 11
		@ 050, 010 Say "-------------------------------------------------------------------------------    "  SIZE 210, 11
		@ 064, 010 Say "Apos o processamento o programa exibira' o relatorio de Retorno CNAB.              "  SIZE 210, 11
		@ 096, 154 BMPBUTTON TYPE 5 ACTION Pergunte(cPerg)
		@ 096, 191 BMPBUTTON TYPE 1 ACTION (lCont := .T.,Close(oDlg1))
		ACTIVATE DIALOG oDlg1 CENTERED
	#ENDIF
	
	If !lCont
		Return
	Endif
	
	
	If mv_par02 == "341"   // Banco Bic
		
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Gera arquivo de Trabalho                                     ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		aCampos := {}
		aAreaSE1 := SE1->(GetArea())
		//Lay-out do Arquivo-Retorno - Registro Header Label
		//Descrição de Registro - Tamanho 400 Bytes
		//A - Alfanumérico - Conteúdo em Caixa Alta (Letras Maiúsculas) N – Numérico
		//Posição	De a	Nome do Campo						Tamanho do Campo 	Conteúdo A N
		//001 a 001 		Identificação do Registro 			001 				0 			X
		//002 a 002 		Identificação do Arquivo Retorno 	001 				2 			X
		//003 a 009 		Literal Retorno 					007 				Retorno X
		//010 a 011 		Código do Serviço 					002 01 X
		//012 a 026 		Literal Serviço 					015 Cobrança X
		//027 a 046 		Código da Empresa 					020 Nº Empresa X
		//047 a 076 		Nome da Empresa por Extenso 		030 Razão Social X
		//077 a 079 		Nº do Bradesco na Câmara
		//	Compensação
		//003 237 X
		//080 a 094 		Nome do Banco por Extenso 			015 Bradesco X
		//095 a 100 		Data da Gravação do Arquivo 		006 DDMMAA X
		//101 a 108 		Zeros 								008 Zeros X
		//109 a 113 		Nº Aviso Bancário 					005 Nº aviso X
		//114 a 379 		Branco 								266 Branco
		//380 a 385 		Data do Crédito 					006 DDMMAA X
		//386 a 394 		Branco 								009 Branco
		//395 a 400 		Nº Seqüencial de registro 			006 000001 X
		//26/61	Número/Documento 4008_0008 Versão 05 Data de Publicação 18/07/2008 Lay-out do Arquivo-Retorno - Registro de Transação – Tipo 1
		//Descrição de Registro Tamanho 400 Bytes
		//A - Alfanumérico - Conteúdo em Caixa Alta (Letras Maiúsculas) N - Numérico
		//Posição 	De a	Nome do Campo						Tamanho do Campo	Conteúdo A N
		Aadd(aCampos,{"POS001","C",001,0})	//001 a 001 		*) Identificação do Registro 		001 1 X
		Aadd(aCampos,{"POS002","C",002,0})	//002 a 003			(*)Tipo de Inscrição Empresa 		002	01-CPF	02-CNPJ	03-PIS/PASEP 98-Não tem 99-Outros X
		Aadd(aCampos,{"POS003","C",014,0})	//004 a 017			(*) Nº Inscrição da Empresa 		014 CNPJ/CPF Número Filial Controle X
		Aadd(aCampos,{"POS004","C",004,0})	//018 a 021			AGÊNCIA AGÊNCIA MANTENEDORA DA CONTA 018   021 9(04)  
		Aadd(aCampos,{"POS005","C",002,0})	//022 a 023 		ZEROS COMPLEMENTO DE REGISTRO 022   023 9(02) 
		Aadd(aCampos,{"POS006","C",005,0})	//024 a 028 		“00” CONTA NÚMERO DA CONTA CORRENTE DA EMPRESA 024   028 9(05)  
		Aadd(aCampos,{"POS007","C",001,0})	//029 a 029 		DAC DÍGITO DE AUTO CONFERÊNCIA AG/CONTA EMPRESA 029   029 9(01)  
		Aadd(aCampos,{"POS008","C",008,0})	//030 a 037			BRANCOS    COMPLEMENTO DE REGISTRO 030   037  X(08)  
		Aadd(aCampos,{"POS009","C",025,0})	//038 a 062 		USO DA EMPRESA  IDENTIFICAÇÃO DO TÍTULO NA EMPRESA 038   062 X(25) NOTA 2  
		Aadd(aCampos,{"POS010","C",008,0})	//063 a 070 		NOSSO NÚMERO  IDENTIFICAÇÃO DO TÍTULO NO BANCO  063   070  9(08)  
		Aadd(aCampos,{"POS011","C",012,0})	//071 a 082 		BRANCOS  COMPLEMENTO DO REGISTRO 071   082 X(12)    CARTEIRA  
		Aadd(aCampos,{"POS012","C",003,0})	//083 a 085 		NUMERO DA CARTEIRA 083   085 9(03)   NOTA 5 
		Aadd(aCampos,{"POS013","C",008,0})	//086 a 093 		NOSSO NÚMERO IDENTIFICAÇÃO DO TÍTULO NO BANCO  086   093  9(08) 
		Aadd(aCampos,{"POS014","C",001,0})	//094 a 094 		DAC NOSSO NÚMERO DAC DO NOSSO NÚMERO 094   094  9(01) NOTA 3 
		Aadd(aCampos,{"POS015","C",013,0})	//095 a 107 		BRANCOS  COMPLEMENTO DO REGISTRO  095   107 X(13)   
		Aadd(aCampos,{"POS016","C",001,0})	//108 a 108 		CARTEIRA CÓDIGO DA CARTEIRA  108   108 X(01)   NOTA 5   
		Aadd(aCampos,{"POS017","C",002,0})	//109 a 110 		CÓD. DE OCORRÊNCIA  IDENTIFICAÇÃO DA OCORRÊNCIA  109   110 9(02) NOTA 17   
		Aadd(aCampos,{"POS018","C",006,0})	//111 a 116 		DATA DE OCORRÊNCIA  DATA DE OCORRÊNCIA NO BANCO  111   116 9(06)   DDMMAA   
		Aadd(aCampos,{"POS019","C",010,0})	//117 a 126 		Nº DO DOCUMENTO  Nº DO DOCUMENTO DE COBRANÇA (DUPL, NP ETC) 117   126  X(10) NOTA 18 
		Aadd(aCampos,{"POS020","C",008,0})	//127 a 134 		NOSSO NÚMERO  CONFIRMAÇÃO DO NÚMERO DO TÍTULO NO BANCO  127   134 9(08)  
		Aadd(aCampos,{"POS021","C",012,0})	//135 a 146 		BRANCOS  COMPLEMENTO DO REGISTRO 135   146 X(12)   
		Aadd(aCampos,{"POS022","C",006,0})	//147 a 152 		VENCIMENTO  DATA DE VENCIMENTO DO TÍTULO  147   152 9(06)  DDMMAA  
		Aadd(aCampos,{"POS023","C",013,0})	//153 a 165 		VALOR DO TÍTULO  VALOR NOMINAL DO TÍTULO  153   165 9(11)V9(2)  
		Aadd(aCampos,{"POS024","C",003,0})	//166 a 168 		CÓDIGO DO BANCO  NÚMERO DO BANCO NA CÂMARA DE COMPENSAÇÃO  166   168 9(03)  
		Aadd(aCampos,{"POS025","C",004,0})	//169 a 172 		AGÊNCIA COBRADORA  AG. COBRADORA, AG. DE LIQUIDAÇÃO OU BAIXA 169   172  9(04)  NOTA 9 
		Aadd(aCampos,{"POS026","C",001,0})	//173 a 173 		DAC AG. COBRADORA  DAC DA AGÊNCIA COBRADORA  173   173  9(01)   
		Aadd(aCampos,{"POS027","C",002,0})	//174 a 175 		ESPÉCIE  ESPÉCIE DO TÍTULO  174   175 9(02) NOTA 10  
		Aadd(aCampos,{"POS028","C",013,0})	//176 a 188			TARIFA DE COBRANÇA VALOR DA DESPESA DE COBRANÇA 176   188  9(11)V9(2)  
		Aadd(aCampos,{"POS029","C",026,0})	//189 a 214 		BRANCOS  COMPLEMENTO DO REGISTRO 189   214 X(26)   
		Aadd(aCampos,{"POS030","C",013,0})	//215 a 227 		VALOR DO IOF   VALOR DO IOF A SER RECOLHIDO (NOTAS SEGURO) 215   227 9(11)V9(2)  
		Aadd(aCampos,{"POS031","C",013,0})	//228 a 240			VALOR ABATIMENTO VALOR DO ABATIMENTO CONCEDIDO  228   240  9(11)V((2) NOTA 19 
		Aadd(aCampos,{"POS032","C",013,0})	//241 a 253			DESCONTOS  VALOR DO DESCONTO CONCEDIDO  241   253 9(11)V9(2) NOTA 19 
		Aadd(aCampos,{"POS033","C",013,0})	//254 a 266			VALOR PRINCIPAL  VALOR LANÇADO EM CONTA CORRENTE 254   266 9(11)V9(2)  
		Aadd(aCampos,{"POS034","C",013,0})	//267 a 279			JUROS DE MORA/MULTA VALOR DE MORA E MULTA 267   279  9(11)V9(2)  
		Aadd(aCampos,{"POS035","C",013,0})	//280 a 292 		OUTROS CRÉDITOS VALOR DE OUTROS CRÉDITOS 280  292 9(11)V9(2)  
		Aadd(aCampos,{"POS036","C",001,0})	//293 a 293 		BOLETO DDA INDICADOR DE BOLETO DDA 293   293 X(01) NOTA 34 
		Aadd(aCampos,{"POS037","C",002,0})	//294 a 295 		BRANCOS COMPLEMENTO DO REGISTRO 294   295 X(02)  
		Aadd(aCampos,{"POS038","C",006,0})	//296 a 301			DATA CRÉDITO DATA DE CRÉDITO DESTA LIQUIDAÇÃO 296   301 X(06) DDMMAA 
		Aadd(aCampos,{"POS039","C",004,0})	//302 a 305			INSTR.CANCELADA CÓDIGO DA INSTRUÇÃO CANCELADA 302   305 9(04) NOTA 20 
		Aadd(aCampos,{"POS040","C",006,0})	//306 a 311			BRANCOS COMPLEMENTO DE REGISTRO 306   311 X(06)  ZEROS 
		Aadd(aCampos,{"POS041","C",013,0})	//312 a 324			COMPLEMENTO DE REGISTRO 312   324 9(13)  
		Aadd(aCampos,{"POS042","C",030,0})	//325 a 354			NOME DO PAGADOR NOME DO PAGADOR 325   354 X(30)  
		Aadd(aCampos,{"POS043","C",023,0})	//355 a 377			BRANCOS COMPLEMENTO DO REGISTRO 355   377 X(23)  
		Aadd(aCampos,{"POS044","C",008,0})	//378 a 385			ERROS / MENSAGEM INFORMATIVA REGISTROS REJEITADOS OU ALEGAÇÃO DO PAGADOR OU REGISTRO DE MENSAGEM INFORMATIVA 378   385 X(08) NOTA 20  
		Aadd(aCampos,{"POS045","C",007,0})	//386 a 392			BRANCOS  COMPLEMENTO DO REGISTRO 386   392 X(07)  
		Aadd(aCampos,{"POS046","C",002,0})	//393 a 394			CÓD. DE LIQUIDAÇÃO MEIO PELO QUAL O TÍTULO FOI LIQUIDADO 393   394 X(02) NOTA 28 
		Aadd(aCampos,{"POS047","C",006,0})	//395 a 400 		Nº Seqüencial de Registro 			006 Nº Seqüencial
		
		
		
		cArqTra := CriaTrab(aCampos)
		DbUseArea( .T.,, cArqTra,cArqTra, .T. , .F. )
		cArqTra1:=Substr(cArqTra,1,7)+"1"
		
		DbSelectArea(cArqTra)
		Index on POS043 to &cArqTra1
		
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Abre o arquivo texto                                                ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		cCaminho := ""
		cVarArq1 := cCaminho+Trim(mv_par01)
		nArq001     := fOpen(cVarArq1,0)
		
		
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Verifica a existencia do arquivo                                    ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If !File(cVarArq1 )
			MsgAlert("Arquivo " + cVarArq1 + " Nao Existe","Processamento Cancelado!")
			fClose(nArq001)
			Return(nil)
		Endif
		
		nLinha := 0
		Do While .T.
			nLinha++
			cLinha  := Space(402)
			Fread(nArq001,@cLinha,402)
			
			If !(Substr(cLinha,001,001) $ "0#1#9" )
				fClose(nArq001)
				Exit
			Endif
			cPOS001	:= Substr(cLinha,001,001)	//001 a 001 		*) Identificação do Registro 		001 1 X
			cPOS002	:= Substr(cLinha,002,002)	//002 a 003			(*)Tipo de Inscrição Empresa 		002	01-CPF	02-CNPJ	03-PIS/PASEP 98-Não tem 99-Outros X
			cPOS003	:= Substr(cLinha,004,014)	//004 a 017			(*) Nº Inscrição da Empresa 		014 CNPJ/CPF Número Filial Controle X
			cPOS004	:= Substr(cLinha,018,004)	//018 a 021			AGÊNCIA AGÊNCIA MANTENEDORA DA CONTA 018   021 9(04)  
			cPOS005	:= Substr(cLinha,022,002)	//022 a 023 		ZEROS COMPLEMENTO DE REGISTRO 022   023 9(02) 
			cPOS006	:= Substr(cLinha,024,005)	//024 a 028 		“00” CONTA NÚMERO DA CONTA CORRENTE DA EMPRESA 024   028 9(05)  
			cPOS007	:= Substr(cLinha,029,001)	//029 a 029 		DAC DÍGITO DE AUTO CONFERÊNCIA AG/CONTA EMPRESA 029   029 9(01)  
			cPOS008	:= Substr(cLinha,030,008)	//030 a 037			BRANCOS    COMPLEMENTO DE REGISTRO 030   037  X(08)  
			cPOS009	:= Substr(cLinha,038,025)	//038 a 062 		USO DA EMPRESA  IDENTIFICAÇÃO DO TÍTULO NA EMPRESA 038   062 X(25) NOTA 2  
			cPOS010	:= Substr(cLinha,063,008)	//063 a 070 		NOSSO NÚMERO  IDENTIFICAÇÃO DO TÍTULO NO BANCO  063   070  9(08)  
			cPOS011	:= Substr(cLinha,071,012)	//071 a 082 		BRANCOS  COMPLEMENTO DO REGISTRO 071   082 X(12)    CARTEIRA  
			cPOS012	:= Substr(cLinha,083,003)	//083 a 085 		NUMERO DA CARTEIRA 083   085 9(03)   NOTA 5 
			cPOS013	:= Substr(cLinha,086,008)	//086 a 093 		NOSSO NÚMERO IDENTIFICAÇÃO DO TÍTULO NO BANCO  086   093  9(08) 
			cPOS014	:= Substr(cLinha,094,001)	//094 a 094 		DAC NOSSO NÚMERO DAC DO NOSSO NÚMERO 094   094  9(01) NOTA 3 
			cPOS015	:= Substr(cLinha,095,013)	//095 a 107 		BRANCOS  COMPLEMENTO DO REGISTRO  095   107 X(13)   
			cPOS016	:= Substr(cLinha,108,001)	//108 a 108 		CARTEIRA CÓDIGO DA CARTEIRA  108   108 X(01)   NOTA 5   
			cPOS017	:= Substr(cLinha,109,002)	//109 a 110 		CÓD. DE OCORRÊNCIA  IDENTIFICAÇÃO DA OCORRÊNCIA  109   110 9(02) NOTA 17   
			cPOS018	:= Substr(cLinha,111,006)	//111 a 116 		DATA DE OCORRÊNCIA  DATA DE OCORRÊNCIA NO BANCO  111   116 9(06)   DDMMAA   
			cPOS019	:= Substr(cLinha,117,010)	//117 a 126 		Nº DO DOCUMENTO  Nº DO DOCUMENTO DE COBRANÇA (DUPL, NP ETC) 117   126  X(10) NOTA 18 
			cPOS020	:= Substr(cLinha,127,008)	//127 a 134 		NOSSO NÚMERO  CONFIRMAÇÃO DO NÚMERO DO TÍTULO NO BANCO  127   134 9(08)  
			cPOS021	:= Substr(cLinha,135,012)	//135 a 146 		BRANCOS  COMPLEMENTO DO REGISTRO 135   146 X(12)   
			cPOS022	:= Substr(cLinha,147,006)	//147 a 152 		VENCIMENTO  DATA DE VENCIMENTO DO TÍTULO  147   152 9(06)  DDMMAA  
			cPOS023	:= Substr(cLinha,153,013)	//153 a 165 		VALOR DO TÍTULO  VALOR NOMINAL DO TÍTULO  153   165 9(11)V9(2)  
			cPOS024	:= Substr(cLinha,166,003)	//166 a 168 		CÓDIGO DO BANCO  NÚMERO DO BANCO NA CÂMARA DE COMPENSAÇÃO  166   168 9(03)  
			cPOS025	:= Substr(cLinha,169,004)	//169 a 172 		AGÊNCIA COBRADORA  AG. COBRADORA, AG. DE LIQUIDAÇÃO OU BAIXA 169   172  9(04)  NOTA 9 
			cPOS026	:= Substr(cLinha,173,001)	//173 a 173 		DAC AG. COBRADORA  DAC DA AGÊNCIA COBRADORA  173   173  9(01)   
			cPOS027	:= Substr(cLinha,174,002)	//174 a 175 		ESPÉCIE  ESPÉCIE DO TÍTULO  174   175 9(02) NOTA 10  
			cPOS028	:= Substr(cLinha,176,013)	//176 a 188			TARIFA DE COBRANÇA VALOR DA DESPESA DE COBRANÇA 176   188  9(11)V9(2)  
			cPOS029	:= Substr(cLinha,189,026)	//189 a 214 		BRANCOS  COMPLEMENTO DO REGISTRO 189   214 X(26)   
			cPOS030	:= Substr(cLinha,215,013)	//215 a 227 		VALOR DO IOF   VALOR DO IOF A SER RECOLHIDO (NOTAS SEGURO) 215   227 9(11)V9(2)  
			cPOS031	:= Substr(cLinha,228,013)	//228 a 240			VALOR ABATIMENTO VALOR DO ABATIMENTO CONCEDIDO  228   240  9(11)V((2) NOTA 19 
			cPOS032	:= Substr(cLinha,241,013)	//241 a 253			DESCONTOS  VALOR DO DESCONTO CONCEDIDO  241   253 9(11)V9(2) NOTA 19 
			cPOS033	:= Substr(cLinha,254,013)	//254 a 266			VALOR PRINCIPAL  VALOR LANÇADO EM CONTA CORRENTE 254   266 9(11)V9(2)  
			cPOS034	:= Substr(cLinha,267,013)	//267 a 279			JUROS DE MORA/MULTA VALOR DE MORA E MULTA 267   279  9(11)V9(2)  
			cPOS035	:= Substr(cLinha,280,013)	//280 a 292 		OUTROS CRÉDITOS VALOR DE OUTROS CRÉDITOS 280  292 9(11)V9(2)  
			cPOS036	:= Substr(cLinha,293,001)	//293 a 293 		BOLETO DDA INDICADOR DE BOLETO DDA 293   293 X(01) NOTA 34 
			cPOS037	:= Substr(cLinha,294,002)	//294 a 295 		BRANCOS COMPLEMENTO DO REGISTRO 294   295 X(02)  
			cPOS038	:= Substr(cLinha,296,006)	//296 a 301			DATA CRÉDITO DATA DE CRÉDITO DESTA LIQUIDAÇÃO 296   301 X(06) DDMMAA 
			cPOS039	:= Substr(cLinha,302,004)	//302 a 305			INSTR.CANCELADA CÓDIGO DA INSTRUÇÃO CANCELADA 302   305 9(04) NOTA 20 
			cPOS040	:= Substr(cLinha,306,006)	//306 a 311			BRANCOS COMPLEMENTO DE REGISTRO 306   311 X(06)  ZEROS 
			cPOS041	:= Substr(cLinha,312,013)	//312 a 324			COMPLEMENTO DE REGISTRO 312   324 9(13)  
			cPOS042	:= Substr(cLinha,325,030)	//325 a 354			NOME DO PAGADOR NOME DO PAGADOR 325   354 X(30)  
			cPOS043	:= Substr(cLinha,355,023)	//355 a 377			BRANCOS COMPLEMENTO DO REGISTRO 355   377 X(23)  
			cPOS044	:= Substr(cLinha,378,008)	//378 a 385			ERROS / MENSAGEM INFORMATIVA REGISTROS REJEITADOS OU ALEGAÇÃO DO PAGADOR OU REGISTRO DE MENSAGEM INFORMATIVA 378   385 X(08) NOTA 20  
			cPOS045	:= Substr(cLinha,386,007)	//386 a 392			BRANCOS  COMPLEMENTO DO REGISTRO 386   392 X(07)  
			cPOS046	:= Substr(cLinha,393,002)	//393 a 394			CÓD. DE LIQUIDAÇÃO MEIO PELO QUAL O TÍTULO FOI LIQUIDADO 393   394 X(02) NOTA 28 
			cPOS047	:= Substr(cLinha,395,006)	//395 a 400 		Nº Seqüencial de Registro 			006 Nº Seqüencial
		
			
			// Faz o teste para processar apenas uma vez
			If !Empty(cPOS021) .And. Substr(cLinha,001,001) == "0"
				lPrivez:=.F.
				MsgInfo("Informacao. Nao e a primeira vez que foi processado essa arquivo.")
				Exit
			Endif
			// Atribuo um valor só para validar que o arquivo já foi processado
			If Substr(cLinha,001,001) == "0"
				cPOS021 := Padr(DTOS(Date()),12)
			Endif
			
			DbSelectArea(cArqTra)         // Arquivo de Trabalho
			DbSeek(cPOS047)
			If Found()
				lRec := .F.
			Else
				lRec := .T.
			Endif
			
			// Ajusta o Campo Especie
			//Codigo do Banco	077079 341
			//++Data Ocorrencia111116
			//++Numero Titulo  0400490
			//++Vlr Desp Cobr. 1761882
			//++Vlr Desconto   2412532
			//++Vlr Abatimento 2282402
			//++Vlr Principal  2542662
			//++Valor Juros    2672792
			//++Valor Multa
			//++Ocorrencia     1091100
			//++Esp+cie        1741750
			//Valor IOF		2152272
			//Outros Cr‚ditos 	2802922
			//++Data Cr‚dito   111116
			//Nosso Numero   	063070
			//Cod Rejeicao
			// Data Vencimento 	147152
			//Codigo do Banco  341
			
			// Localiza titulos para atender a posição 040-049
			
			// Somente linhas diferente de 0 e 9 e com conteudo no Documento informado 
			If Substr(cLinha,1,1) $ "1" .And. !Empty(Alltrim(cPOS013)) .And. !Empty(Alltrim(cPOS009)) .And. Substr(cPOS009,1,2) <> "06"
				
				dbSelectArea("SE1")
				dbSetOrder(2)
				aStru:= SE1->(dbStruct())
				
				cQry := "SELECT R_E_C_N_O_ AS E1RECNO "
				cQry += "  FROM " + RetSqlName("SE1")
				cQry += " WHERE D_E_L_E_T_ = ' ' "
				cQry += "   AND SUBSTRING(E1_NUMBCO,1,9) = '"+ cPOS013+cPOS014 + "' "
				cQry += "   AND E1_PORTADO = '341' "
				//cQry += "   AND E1_CODOG = '" + + "'"
				//cQry += "   AND E1_VENCREA BETWEEN TO_CHAR(SYSDATE - 30,'YYYYMMDD') AND TO_CHAR(SYSDATE + 45,'YYYYMMDD') "
				cQry += "   AND E1_FILIAL = '" + xFilial("SE1") + "' "
				
				MsgRun("Procurando Titulo para cobrança sem registro","Aguarde..",{|| dbUseArea(.T., "TOPCONN", TCGenQry(,,cQry), 'QSE1', .F., .T.) })
				
				For ni := 1 to Len(aStru)
					If aStru[ni,2] != 'C'
						TCSetField('QSE1', aStru[ni,1], aStru[ni,2],aStru[ni,3],aStru[ni,4])
					Endif
				Next
				
				DbSelectArea("QSE1")
				If !Eof()
					DbSelectArea("SE1")
					DbGoto(QSE1->E1RECNO)
					sfGrvE1IDCNAB()
					
					//038 a 062 		USO DA EMPRESA  IDENTIFICAÇÃO DO TÍTULO NA EMPRESA 038   062 X(25) NOTA 2  
					cPOS009	:= "06"+SE1->E1_IDCNAB
					
				Else
					cConcMsg += "Título '"+cPOS010+"' Nosso.Num '"+cPOS013+cPOS014+"' R$ "+AllTrim(Transform(Val(cPOS023)/100,"@E 999,999,999.99"))	+Chr(13) +Chr(10)
					cPOS016 := "0000000000"
					cPOS047 := "XXXXXX"
				Endif
				DBSelectArea("QSE1")
				DbCloseArea()
			Endif
			
			//Executa a gravacao das variaveis nos campos do arquivo temporario
			DbSelectArea(cArqTra)         // Arquivo de Trabalho
			Reclock(cArqTra,.T.)
			
			cSeq := "000"
			For x := 1 To 47
				cSeq := Soma1(cSeq)
				Replace &("POS"+cSeq) With  &("cPOS"+cSeq)
			Next
			MsUnLock()
			
		Enddo
		
		If lPrivez
			cArq1:=mv_par01
			nHdl :=fCreate(cArq1)
			cChrFIM:=CHR(13)+CHR(10)       // Caracteres para final de linha
			If nHdl==-1
				#IFDEF WINDOWS
					MsgAlert("O arquivo de nome "+cArq1+" nao pode ser executado! Verifique os parametros.","Atencao!")
				#ENDIF
				Return
			Endif
			
			cLin:=""
			DbSelectArea(cArqTra)
			DbGoTop()
			Do While !Eof()
				
				If POS047 == "XXXXXX"
					DbSelectArea(cArqTra)
					DbSkip()
					Loop
				Endif
				
				// Executa a gravacao dos dados do arquivo temporario para o arquivo texto
				cSeq := "000"
				For y := 1 To 47
					cSeq := Soma1(cSeq)
					cLin += &("POS"+cSeq)
				Next
				
				cLin += cChrFIM
				
				If fWrite(nHdl,cLin,Len(cLin)) != Len(cLin)
					#IFDEF WINDOWS
						If !MsgAlert("Ocorreu um erro na gravacao do arquivo "+cArq1+".   Continua?","Atencao!")
							Exit
						Endif
					#ENDIF
				Endif
				cLin:=""
				
				DbSelectArea(cArqTra)
				DbSkip()
			Enddo
			fClose(nHdl)
			
		Endif
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Deleta o Arquivo de Trabalho                                 ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		DbSelectArea(cArqTra)
		DbCloseArea()
		FErase(cArqTra + GetDbExtension()) // Deleting file
		FErase(cArqTra + OrdBagExt()) // Deleting index
		
		RestArea(aAreaSE1)
	Endif
	
	If !Empty(cConcMsg)
		Aviso("Titulos não encontrados!","Os seguintes títulos do arquivo não foram localizados!"+Chr(13)+Chr(10)+Chr(13)+Chr(10)+cConcMsg,{"Ok"},3)
	Endif
	
	// Atualiza Perguntas do SX1
	DbSelectArea("SX1")
	DbSetOrder(1)
	cPerg := PADR("FIN650",Len(SX1->X1_GRUPO))
	
	U_GravaSX1(cPerg,"01",Trim(mv_par01))
	
	Finr650()   // Relatorio de Retorno Cnab
	
	
	
Return(.T.)


//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
//³ Cria Perguntas no SX1                                        ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
Static Function ValidPerg()
	
	Local	i,j
	cAlias := Alias()
	aRegs  := {}
	
	DbSelectArea("SX1")
	DbSetOrder(1)
	cPerg := PADR(cPerg,Len(SX1->X1_GRUPO))
	
	
	//          Grupo/Ordem/Pergunta             /PE/PI/Variavel/Tip/T/D/P/GSC/Vl/Var01     /D1/DS/DE/Cn/V2/D2/DS/DE/Cn/V3/D3/DS/DE/Cn/V4/D4/DS/DE/Cn/V5/D5/DS/DE/Cn/F3/GRPSXG
	AADD(aRegs,{cPerg,"01","Arquivo de Entrada ?","","","mv_ch1","C",50,0,0,"G","","mv_par01","","","","","","","","","","","","","","","","","","","","","","","","","DIR",""})
	AADD(aRegs,{cPerg,"02","Codigo do Banco    ?","","","mv_ch2","C",03,0,0,"G","","mv_par02","","","","","","","","","","","","","","","","","","","","","","","","","SA6",""})
	
	DbSelectArea("SX1")
	DbSetOrder(1)
	For i:=1 to Len(aRegs)
		If !DbSeek(cPerg+aRegs[i,2])
			RecLock("SX1",.T.)
			For j:=1 to FCount()
				If j<=Len(aRegs[i])
					FieldPut(j,aRegs[i,j])
				Endif
			Next
			MsUnlock()
		Else
			RecLock("SX1",.F.)
			For j:=1 to FCount()
				If j<=Len(aRegs[i])
					FieldPut(j,aRegs[i,j])
				Endif
			Next
			MsUnlock()
		Endif
	Next
	DbSelectArea(cAlias)
Return




Static Function sfGrvE1IDCNAB()

	Local	cIdCnab
	Local	aOrdSE1

	If Empty(SE1->E1_IDCNAB) // So gera outro identificador, caso o titulo ainda nao o tenha
			// Gera identificador do registro CNAB no titulo enviado
		cIdCnab := GetSxENum("SE1", "E1_IDCNAB","E1_IDCNAB"+cEmpAnt,11)
				
		dbSelectArea("SE1")
		aOrdSE1 := SE1->(GetArea())
		dbSetOrder(19)
		While SE1->(MsSeek(cIdCnab))
			If ( __lSx8 )
				ConfirmSX8()
			EndIf
			cIdCnab := GetSxENum("SE1", "E1_IDCNAB","E1_IDCNAB"+cEmpAnt,11)
		EndDo
			
		SE1->(RestArea(aOrdSE1))
		Reclock("SE1")
		SE1->E1_IDCNAB := cIdCnab
		MsUnlock()
		ConfirmSx8()
	Endif
		
Return cIdCnab