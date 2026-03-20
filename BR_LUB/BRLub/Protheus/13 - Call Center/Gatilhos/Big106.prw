#INCLUDE "rwmake.ch"
#INCLUDE "tbiconn.ch"
#INCLUDE "topconn.ch"

/*/{Protheus.doc} BIG106
(Gatilho para avisar que o clientes possui email invalido ou se participa de alguma promoção)

@author Christian Daniel Costa
@since 24/08/2011
@version 1.0

@return character, Loja do cliente

@example
(examples)

@see (links_or_references)
/*/
User Function BIG106()


	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Declaracao de Variaveis                                             ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	Local	aAreaOld	:= 	GetArea()
	Local 	cCliente	:=  M->UA_CLIENTE
	Local	cLoja    	:=  M->UA_LOJA
	Local	cTxtPad	:= 	""
	Local 	cArqLck   	:= GetPathSemaforo()+"BIG106"+cEmpAnt+cFilAnt+__cUserId+".LCK"
	Local	cReadLck	:= ""
	Local	cQrcE
	Local	aRetAux
	Local	cRetEmail	:= ""
	Local	nX 


	// Verifica se existe o arquivo de lock para evitar duplicidades de validação de e-mails
	// Por que a rotina big106 é chamada tanto para validar o código como a loja
	If File(cArqLck)
		cReadLck := MemoRead(cArqLck)
		If cReadLck == cCliente+cLoja
			RestArea(aAreaOld)
			Return (M->UA_LOJA)
		Endif
	Endif


	dbselectarea("SA1")
	dbsetorder(1)
	MsSeek(xFilial("SA1")+cCliente+cLoja)

	cTxtPad	:= 	"Cliente: "+SA1->A1_COD+"/"+SA1->A1_LOJA+"-"+SA1->A1_NOME +Chr(13)+Chr(10)+;
	"E-mail: "+SA1->A1_EMAIL+Chr(13)+Chr(10)+;
	"E-mail Antigo ou Auxiliar : "+SA1->A1_REFCOM3+Chr(13)+Chr(10)+;
	"Se o e-mail não for corrigido corretamente, caso haja pedido para o cliente, o mesmo não será liberado e faturado!"

	aRetAux		:= StrTokArr(SA1->A1_EMAIL + ";",";")
	For nX := 1 To Len(aRetAux)
		If !U_GMTMKM01(Lower(Alltrim(aRetAux[nX])),"",SA1->A1_MSBLQL,.F./*lValdAlcada*/,.F./*lExibeAlerta*/,cTxtPad/*cInTxtPad*/)
			If !IsBlind() 
				MsgAlert("CLIENTE COM EMAIL INVÁLIDO PARA NOTA FISCAL ELETRÔNICA!! O PEDIDO FICARÁ BLOQUEADO SE O CADASTRO DO CLIENTE NÃO FOR ATUALIZADO"+Chr(13)+Chr(10)+;
				"E-mail: "+SA1->A1_EMAIL+Chr(13)+Chr(10)+;
				"E-mail antigo ou auxiliar: "+SA1->A1_REFCOM3+Chr(13)+Chr(10),;
				ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" - Aviso sobre E-mail ")
			Endif
		Endif                                                                             
	Next


	cQrcE := ""
	cQrcE += "	SELECT U5_EMAIL EMAIL FROM "
	cQrcE += RetSqlName("SU5") + " U5, "
	cQrcE += RetSqlName("AC8")+ " AC "
	cQrcE += "  WHERE U5.D_E_L_E_T_ = ' ' "
	cQrcE += "    AND AC8_CODENT = ('" +cCliente+cLoja + "' ) "
	cQrcE += "    AND U5_CODCONT = AC8_CODCON "
	cQrcE += "    AND U5_FILIAL = '  ' "
	cQrcE += "    AND U5_STATUS IN('2') " // 2=Atualizado
	cQrcE += "    AND U5_ATIVO IN(' ','1') " //1=Sim 2=Não
	cQrcE += "    AND AC8_FILIAL = '  ' "
	cQrcE += "    AND AC8_ENTIDA = 'SA1' "

	TCQUERY cQrcE NEW ALIAS "QREM"

	While !Eof() 
		cTxtPad += Chr(13)+ Chr(10) + "E-mail Contato :" + QREM->EMAIL
		aRetAux		:= StrTokArr(QREM->EMAIL + ";",";")
		For nX := 1 To Len(aRetAux)
			If !U_GMTMKM01(Lower(Alltrim(aRetAux[nX])),"",SA1->A1_MSBLQL,.F./*lValdAlcada*/,.F./*lExibeAlerta*/,cTxtPad/*cInTxtPad*/)
				If !IsBlind() 
					MsgAlert("CONTATO COM EMAIL INVÁLIDO!! O PEDIDO FICARÁ BLOQUEADO SE O CADASTRO DO CONTATO NÃO FOR ATUALIZADO!!!!!" + Chr(13)+Chr(10)+;
					"E-mail: "+QREM->EMAIL+Chr(13)+Chr(10),;
					ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" - Aviso sobre E-mail ")
				Endif
			Endif                                                                             
		Next

		DbSelectArea("QREM")
		DbSkip()
	Enddo	
	QREM->(DbCloseArea())

	// Criar um arquivo para ser processado no ponto de entrada M521DNFS para enviar o cancelamento de nota fiscal imediatamente a exclusao da nota
	If File(cArqLck)
		FErase(cArqLck)
	EndIf
	MemoWrite(cArqLck,SA1->A1_COD+SA1->A1_LOJA)

	RestArea(aAreaOld)

Return (M->UA_LOJA)
