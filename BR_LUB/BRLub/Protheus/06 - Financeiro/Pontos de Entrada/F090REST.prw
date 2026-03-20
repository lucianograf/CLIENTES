#Include 'Protheus.ch'

/*/{Protheus.doc} F090REST
(Ponto de entrada após a baixa automática de títulos para geração de Cheques)
@type function
@author marce
@since 02/05/2016
@version 1.0
@return ${return}, ${return_description}
@example
(examples) 
@see (links_or_references)
/*/
User Function F090REST()

	Local	cPergRel	:= Padr("FIN490",10)
	Local	aAreaOld	:= GetArea()
	Local	aAreaSEA	:= SEA->(GetArea())
	Local	aRestPerg	:= {} 
	Local 	lPEAtivo 	:= GetNewPar("BR_F090RST",.F.)
	
	// Grava as perguntas conforme o cheque gerado na Baixa
	If lPEAtivo
		aRestPerg	:= U_MLXRTPGR(.T./*lSalvaPerg*/,/*aPerguntas*/,/*nTamSx1*/)
		If nValor > 0
			U_GravaSX1(cPergRel,"01",SEF->EF_BANCO)		// 	01 - Qual Banco ?
			U_GravaSX1(cPergRel,"02",SEF->EF_AGENCIA)	//	02 - Da Agencia ?
			U_GravaSX1(cPergRel,"03",SEF->EF_CONTA)		//	03 - Da Conta ?
			U_GravaSX1(cPergRel,"04",SEF->EF_NUM)		//	04 - Do Cheque ?
			U_GravaSX1(cPergRel,"05",SEF->EF_NUM)		//	05 - Ate o Cheque ?
			U_GravaSX1(cPergRel,"06",1)					//	06 - Imprime Titulos ? 			1=Sim 2=Nao
			U_GravaSX1(cPergRel,"07",1)					//	07 - Copias por pagina ?      	1=Uma 2=Duas
			U_GravaSX1(cPergRel,"08",1)					//	08 - Numer. Sequencial ?		1=Sim 2=Nao
			U_GravaSX1(cPergRel,"09",SEF->EF_DATA)		//	09 - Data inicial ?
			U_GravaSX1(cPergRel,"10",SEF->EF_DATA)		//	10 - Data final ?
			U_GravaSX1(cPergRel,"11",1)					//	11 - Imprime linha unica ?      1=Sim 2=Nao
			U_GravaSX1(cPergRel,"12",2)					//	12 - Seleciona Filiais ? 		1=Sim 2=Nao

			// Efetua a chamada do relatório de Cópia de Cheques.
			FINR490()
		Endif

		U_MLXRTPGR(/*lSalvaPerg*/,aRestPerg/*aPerguntas*/,/*nTamSx1*/)
	Endif
	RestArea(aAreaSEA)
	RestArea(aAreaOld)

Return

