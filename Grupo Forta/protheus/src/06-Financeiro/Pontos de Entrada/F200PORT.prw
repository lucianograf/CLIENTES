#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} F200PORT
(Ponto de entrada que com retorno T/F se a baixa será pelo portador do Titulo ou pelo parametro)
@author MarceloLauschner
@since 20/08/2010 
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function F200PORT()

	
Return .F. //!MsgYesNo("Considerar Banco/Agência/Conta informados nos paramêtros? " + chr(13)+chr(13) +"Se a opção for 'Não' os títulos serão baixados o Banco/Agência/Conta que estiver como portador de cada título!","A T E N Ç Ã O!!")


/*/{Protheus.doc} F200X1VLD
(long_description)
@author MarceloLauschner
@since 06/02/2015
@version 1.0
@param nParValid, numérico, (Descrição do parâmetro)
@param cVldRot, character, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function F200X1VLD(nParValid,cVldRot) // Numero do parametro a validar
	// Rotina de pergunta a ser validada
	Local		cArqRet			:= MV_PAR05
	Local		cBanco			:= MV_PAR06
	Local		cAgenc  		:= MV_PAR07
	Local   	cConta			:= MV_PAR08
	Local		cSubCc			:= MV_PAR09
	Local		nModCnab		:= 1
	Local		aAreaOld		:= GetArea()

	Local		cQry 			:= ""
	Local		lRet			:= .F.
	Default 	cVldRot			:= "AFI200"
	Default		nParValid		:= 6


	dbSelectArea("SEE")
	DbSetOrder(1)

	// Se for validação a partir do relatorio de Comunicacao Bancaria
	If cVldRot == "FIN650"     
		cArqRet		:= MV_PAR02
		cBanco		:= MV_PAR03
		cAgenc  	:= MV_PAR04
		cConta		:= MV_PAR05
		nModCnab	:= MV_PAR08

		SEE->( dbSeek(xFilial("SEE")+cBanco+cAgenc+cConta) )

		cSubCc		:= MV_PAR06
		If nParValid == 2  // Se validação do parametro 2-Arquivo de retorno, permite continuar mesmo nao coincidindo os dados pois ainda falta alterar banco/agencia/conta	
			lRet 	:= .T.
		Else
			If nParValid == 3 // Se validação do código de banco, posiciona na subconta encontrada pois não existe retorna dele pelo F3
				cSubCc 		:= SEE->EE_SUBCTA
				MV_PAR06    := cSubCc
				MV_PAR08	:= IIf(SEE->EE_NRBYTES == 240,2,1)
			Endif
			lRet	:= .F.
		Endif          

	ElseIf cVldRot == "AFI150" // Rotina de geração de arquivo de envio cnab
		cArqRet		:= MV_PAR03 // Arquivo de configuracao .rem
		cBanco		:= MV_PAR05
		cAgenc  	:= MV_PAR06
		cConta		:= MV_PAR07
		nModCnab	:= MV_PAR09
		SEE->( dbSeek(xFilial("SEE")+cBanco+cAgenc+cConta) )
		cSubCc		:= MV_PAR08
		If nParValid == 3  // Se validação do parametro 3-Arquivo de remessa, permite continuar mesmo nao coincidindo os dados pois ainda falta alterar banco/agencia/conta	
			lRet 	:= .T.
		Else
			If nParValid == 5 // Se validação do código de banco, posiciona na subconta encontrada pois não existe retorna dele pelo F3
				cSubCc 		:= SEE->EE_SUBCTA
				MV_PAR08    := cSubCc
				MV_PAR09	:= IIf(SEE->EE_NRBYTES == 240,2,1)
			Endif

			lRet	:= .F.
		Endif
	Else
		If nParValid == 5  // Se validação do parametro 5-Arquivo de retorno, permite continuar mesmo nao coincidindo os dados pois ainda falta alterar banco/agencia/conta	
			lRet 	:= .T.
		Else            
			If nParValid == 6 // Se validação do código de banco, posiciona na subconta encontrada pois não existe retorna dele pelo F3
				SEE->( dbSeek(xFilial("SEE")+cBanco+cAgenc+cConta) )
				cSubCc 		:= SEE->EE_SUBCTA
				MV_PAR09    := cSubCc
				nModCnab	:= IIf(SEE->EE_NRBYTES == 240,2,1)
				MV_PAR12	:= nModCnab
			Endif
			lRet	:= .F.
		Endif
	Endif

	dbSelectArea("SEE")
	DbSetOrder(1)
	If SEE->( dbSeek(xFilial("SEE")+cBanco+cAgenc+cConta+cSubCc) )

		// Caso seja rotina Geracao bordero ira comparar com arquivo de remessa(.rem) ou então arquivo de retorno.
		If !Empty(cArqRet) .And. (Iif(cVldRot == "AFI150",Alltrim(Upper(SEE->EE_ARQREM)),Alltrim(Upper(SEE->EE_ARQRET)))) ==  Alltrim(Upper(cArqRet)) // Faço upper e trim do texto para evitar erros de caixa alta e espaço
			RestArea(aAreaOld)
			Return .T.
		Else
			If lRet
				MsgAlert("Você precisa mudar as configurações de código de Banco/Agência/Conta!","A T E N Ç Ã O!!")
			Else
				MsgAlert("Arquivo de configuração de retorno '"+cArqRet+"' inválido para este Banco/Agência/Conta informados!","A T E N Ç Ã O!!")
				If cVldRot == "FIN650"     
					MV_PAR02	:= SEE->EE_ARQRET
				ElseIf cVldRot == "AFI150" // Rotina de geração de arquivo de envio cnab
					MV_PAR03	:= SEE->EE_ARQREM  // Arquivo de configuracao .rem
				Else
					MV_PAR05	:= SEE->EE_ARQRET
				Endif
			Endif	
			RestArea(aAreaOld)
			Return lRet
		Endif
	Else
		MsgAlert("Não existe cadastro de configuração de Banco para os paramêtros informados!","A T E N Ç Ã O!!")
		RestArea(aAreaOld)
		Return lRet
	Endif

	RestArea(aAreaOld)
Return .F.

