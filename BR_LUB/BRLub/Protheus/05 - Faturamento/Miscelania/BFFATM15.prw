

/*/{Protheus.doc} BFFATM15
(Analise dos destinatario de emails e mudanca em caso base teste para o proprio usuario em uso     )
@type function
@author marce
@since 01/12/2016
@version 1.0
@param cInMails, character, (Descrição do parâmetro)
@param cInProcName, character, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/

User Function BFFATM15(cInMails,cInProcName)
	
	Local	aMails		:= {}
	Local	cOutMails   := ""
	Local	iX	:= iY	:= 0
	Local	lAddMail	:= .T.
	Local	lIsHomologa	:= Alltrim(Lower(GetEnvServer())) $ "desenvolvimento#homologacao#marcelo#iago#prospera" // Este parametro permite que todos os destinos de email sejam simplificados para o proprio usuario em caso de base teste
// Rotinas em que um destinatario fica impedido de receber, criar um novo vetor para email por processo
	Local	aProcMailBlq := {}
	
	Aadd(aProcMailBlq,{"BIG012","assessortexaco1@",CTOD("01/11/2014"),CTOD("31/12/2020")})
	Aadd(aProcMailBlq,{"BIG012","assessortexaco2@",CTOD("01/11/2014"),CTOD("31/12/2020")})
	Aadd(aProcMailBlq,{"BIG012","assessortexaco3@",CTOD("01/11/2014"),CTOD("31/12/2020")})
	Aadd(aProcMailBlq,{"BIG012","assessortexaco4@",CTOD("01/11/2014"),CTOD("31/12/2020")})
	Aadd(aProcMailBlq,{"BIG012","assessortexaco5@",CTOD("01/11/2014"),CTOD("31/12/2020")})
	Aadd(aProcMailBlq,{"BIG012","assessortexaco6@",CTOD("01/11/2014"),CTOD("31/12/2020")})
	Aadd(aProcMailBlq,{"BIG012","assessortexaco7@",CTOD("01/11/2014"),CTOD("31/12/2020")})
	Aadd(aProcMailBlq,{"BIG012","assessortexaco8@",CTOD("01/11/2014"),CTOD("31/12/2020")})
	Aadd(aProcMailBlq,{"BIG012","assessortexaco9@",CTOD("01/11/2014"),CTOD("31/12/2020")})
	Aadd(aProcMailBlq,{"BIG012","assessortexaco10@",CTOD("01/11/2014"),CTOD("31/12/2020")})
	Aadd(aProcMailBlq,{"BIG012","assessortexaco11@",CTOD("01/11/2014"),CTOD("31/12/2020")})
	Aadd(aProcMailBlq,{"BIG012","assessortexaco12@",CTOD("01/11/2014"),CTOD("31/12/2020")})
	Aadd(aProcMailBlq,{"BIG012","assessortexaco13@",CTOD("01/11/2014"),CTOD("31/12/2020")})
	Aadd(aProcMailBlq,{"BIG012","assessortexaco14@",CTOD("01/11/2014"),CTOD("31/12/2020")})
	Aadd(aProcMailBlq,{"BIG012","assessortexaco15@",CTOD("01/11/2014"),CTOD("31/12/2020")})
	Aadd(aProcMailBlq,{"BIG012","assessortexaco16@",CTOD("01/11/2014"),CTOD("31/12/2020")})
	Aadd(aProcMailBlq,{"BIG012","assessortexaco17@",CTOD("01/11/2014"),CTOD("31/12/2020")})
	Aadd(aProcMailBlq,{"BIG012","vendasinternas1@",CTOD("01/11/2014"),CTOD("31/12/2020")})
	Aadd(aProcMailBlq,{"BIG012","vendasinternas2@",CTOD("01/11/2014"),CTOD("31/12/2020")})
	Aadd(aProcMailBlq,{"BIG012","vendasinternas3@",CTOD("01/11/2014"),CTOD("31/12/2020")})
	Aadd(aProcMailBlq,{"BIG012","vendasinternas4@",CTOD("01/11/2014"),CTOD("31/12/2020")})
	Aadd(aProcMailBlq,{"BIG012","vendasinternas5@",CTOD("01/11/2014"),CTOD("31/12/2020")})
	Aadd(aProcMailBlq,{"BIG012","vendasinternas6@",CTOD("01/11/2014"),CTOD("31/12/2020")})
	Aadd(aProcMailBlq,{"BIG012","vendasinternas7@",CTOD("01/11/2014"),CTOD("31/12/2020")})
	Aadd(aProcMailBlq,{"BIG012","vendaspneuspr4@",CTOD("01/11/2014"),CTOD("31/12/2020")})
	Aadd(aProcMailBlq,{"BIG012","vendaspneusrs1@",CTOD("01/11/2014"),CTOD("31/12/2020")})
	Aadd(aProcMailBlq,{"BIG012","javel@",CTOD("01/11/2014"),CTOD("31/12/2020")})
	Aadd(aProcMailBlq,{"BIG012","rose@",CTOD("01/11/2014"),CTOD("31/12/2020")})
	Aadd(aProcMailBlq,{"BIG012","mariluce@",CTOD("01/11/2014"),CTOD("31/12/2020")})
	Aadd(aProcMailBlq,{"BIG012","eliane@",CTOD("01/11/2014"),CTOD("31/12/2020")})
	
	// 20/11/2019 
	Aadd(aProcMailBlq,{"BIG012","robson.hang@",CTOD("20/11/2019"),CTOD("31/12/2040")})
	
	
	// 24/07/2015 - Solicitado por Sheila, para que o pessoal do Industrial não receba Mapa Texaco
	Aadd(aProcMailBlq,{"BIG011TX","assessortexaco6@",CTOD("01/07/2014"),CTOD("31/12/2020")})
	Aadd(aProcMailBlq,{"BIG011TX","assessortexaco10@",CTOD("01/07/2014"),CTOD("31/12/2020")})
	Aadd(aProcMailBlq,{"BIG011TX","assessortexaco12@",CTOD("01/07/2014"),CTOD("31/12/2020")})
	Aadd(aProcMailBlq,{"BIG011TX","vendasinternas7@",CTOD("01/07/2014"),CTOD("31/12/2020")})
	Aadd(aProcMailBlq,{"BIG011TX","vendasinternas6@",CTOD("01/07/2014"),CTOD("31/12/2020")})
	Aadd(aProcMailBlq,{"BIG011TX","vendasinternas4@",CTOD("01/07/2014"),CTOD("31/12/2020")})
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
		cOutMails	:= UsrRetMail(__cUserId)
		//cOutMails	:= "marcelo@centralxml.com.br"
	Endif

Return cOutMails

