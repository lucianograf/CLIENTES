#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} MLCFGM04
//TODO Analise dos destinatario de emails e mudanca em caso base teste para o proprio usuario em uso  
@author marce
@since 11/02/2020
@version 1.0
@return ${return}, ${return_description}
@param cInMails, characters, descricao
@param cInProcName, characters, descricao
@type function
/*/
User Function MLCFGM04(cInMails,cInProcName)
	
	Local	aMails		:= {}
	Local	cOutMails   := ""
	Local	iX	:= iY	:= 0
	Local	lAddMail	:= .T.
	Local	lIsHomologa	:= Alltrim(Lower(GetEnvServer()))== "chumnn_comp" // Este parametro permite que todos os destinos de email sejam simplificados para o proprio usuario em caso de base teste
	// Rotinas em que um destinatario fica impedido de receber, criar um novo vetor para email por processo
	Local	aProcMailBlq := {}
	
	
	Aadd(aProcMailBlq,{"BIG011TX","suporte.industrial@",CTOD("01/07/2014"),CTOD("31/12/2020")})
	
	If Empty(cInMails)
		Return ""
	Endif
	
	aMails	:= StrTokArr(Lower(cInMails+";"),";") // Transforma em array e tudo em caixa baixa e adiciona o ';' para garantir a quebra em array
	
	For iX := 1 To Len(aMails)
		lAddMail	:= .T.
		// Procura por restricoes
		iY := 1
		While iY <= Len(aProcMailBlq)
		// Verifica se nao ha uma condicao que impede que tal email recebe email deste processo
			If (aProcMailBlq[iY,1] == Alltrim(cInProcName) .And. aProcMailBlq[iY,2]	$ aMails[iX] .And. dDataBase >= aProcMailBlq[iY,3] .And. dDataBase <= aProcMailBlq[iY,4])
				lAddMail	:= .F.
			Endif
			iY++
		Enddo
		If lAddMail .And. !Alltrim(aMails[iX]) $ cOutMails .And. IsEmail(Alltrim(aMails[iX]))
			If !Empty(cOutMails)
				cOutMails	+= ";"
			Endif
			cOutMails += Alltrim(aMails[iX])
		Endif
	Next


	// Se for ambiente de homologacao, envia email somente para o usuario que esta executando a operacao
	If lIsHomologa
		//cOutMails	:= UsrRetMail(__cUserId)
		cOutMails	:= "ml-servicos@outlook.com"
	Endif

Return cOutMails

