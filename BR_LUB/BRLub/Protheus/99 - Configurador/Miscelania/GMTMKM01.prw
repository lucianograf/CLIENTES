#include "protheus.ch"

/*/{Protheus.doc} GMTMKM01
(Analise de e-mail via validação em PHP)

@author MarceloLauschner
@since 29/01/2014
@version 1.0

@param cInEmail, character, (Descrição do parâmetro)
@param cInOldEmail, character, (Descrição do parâmetro)
@param cA1MSBLQL, character, (Descrição do parâmetro)
@param lValdAlcada, logico, (Descrição do parâmetro)
@param lExibeAlerta,logico, Se chamado por outras rotinas que irão exibir o alerta não exibe mensagens desta rotina
@return logico, Se validou ou não o e-mail

@example
(examples)

@see (links_or_references)
/*/
User Function GMTMKM01(cInEmail,cInOldEmail,cA1MSBLQL,lValdAlcada,lExibeAlerta,cInTxtPad)
	
	Local	cUrlValid			:= Alltrim(GetNewPar("BF_URLVLML",'https://app.verify-email.org/api/v1/Ov8yGlRE2P61gOUsUtXSkCCtAeKGdg4Ozutm3WCztbwZaGqB2B/verify/')) + Alltrim(cInEmail)
	Local	lRet				:= .T.
	Local	lVldEmail			:= .F.
	Local	cRetUrl				:= ""
	Local	aListMailBlq		:= {}
	Local	cTxtFalso			:= ""
	Local   iX
	Default	cA1MSBLQL			:= " "
	Default	lValdAlcada			:= .F.
	Default lExibeAlerta		:= .T.
	Default	cInTxtPad			:= ""
	
	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()
	
	If Alltrim(Lower(GetEnvServer())) $ "desenvolvimento"
		Return lRet
	Endif
	
	// Se for Alteração - Somente valida se o email alterou
	If !lVldEmail .And. Type("ALTERA") <> "U" .And. ALTERA
		If cInOldEmail <> cInEmail
			lVldEmail	:= .T.
		Endif
	Endif
	
	If !lVldEmail .And. Type("INCLUI") <> "U" .And. INCLUI
		lVldEmail	:= .T.
	Endif
	
	// Se for cliente bloqueado não precisa mais validar email
	If lVldEmail .And. cA1MSBLQL == "1"
		lVldEmail	:= .F.
	Endif
	
	// Se a rotina for externa de cadastros a chamada deverá sempre validar o e-mail
	If !lExibeAlerta
		lVldEmail	:= .T.
	Endif
	
	// Se valida o email, chama o Httpget
	If lVldEmail
		// Assume texto inicial
		cTxtFalso	:= cInTxtPad
		
		
		Aadd(aListMailBlq,"sheila.comrl@gmail.com")
		Aadd(aListMailBlq,"mah_bnu@yahoo.com.br")
		Aadd(aListMailBlq,"renano.bnu@gmail.com")
		Aadd(aListMailBlq,"minescblu@hotmail.com")
		Aadd(aListMailBlq,"nathybus@hotmail.com")
		Aadd(aListMailBlq,"mmayerbarbosa@gmail.com")
		Aadd(aListMailBlq,"cynarametzger@hotmail.com")
		Aadd(aListMailBlq,"gisele.netblumenau@hotmail.com")
		Aadd(aListMailBlq,"luisbrodzinski@hotmail.com")
		Aadd(aListMailBlq,"greice@hotmail.com")
		Aadd(aListMailBlq,"mah_bnu@yahoo.com.br")
		Aadd(aListMailBlq,"camilafischborn@hotmail.com")
		Aadd(aListMailBlq,"kiki_ap_92@hotmail.com")
		Aadd(aListMailBlq,"napoleao.texaco@gmail.com")
		Aadd(aListMailBlq,"adriana.janase@yahoo.com.br")
		Aadd(aListMailBlq,"claudineiklaumann@hotmail.com")
		Aadd(aListMailBlq,"regiane-psilva@hotmail.com")
		Aadd(aListMailBlq,"luribeiro1989@hotmail.com")
		Aadd(aListMailBlq,"larissamewes@hotmail.com")
		Aadd(aListMailBlq,"@bigforta.com.br")
		Aadd(aListMailBlq,"@llust.com.br")
		Aadd(aListMailBlq,"@atrialub.com.br")
		Aadd(aListMailBlq,"atrialub@gmail.comf")
		Aadd(aListMailBlq,"@xxx.com.br")
		Aadd(aListMailBlq,"@yyy.com.br")
		Aadd(aListMailBlq,"@zzz.com.br")
		Aadd(aListMailBlq,"@aaa.com.br")
		Aadd(aListMailBlq,"@bbb.com.br")
		Aadd(aListMailBlq,"@ccc.com.br")
		Aadd(aListMailBlq,"@ddd.com.br")
		
		For iX := 1 To Len(aListMailBlq)
			If aListMailBlq[iX] $ Alltrim(Lower(cInEmail))
				If lExibeAlerta
					MsgAlert("O e-mail informado '"+cInEmail+"' não foi validado pela rotina pois está na lista de e-mails não permitidos!","EMAIL INFORMADO COM PROBLEMA!")
				Else
					cTxtFalso += "O e-mail informado '"+cInEmail+"' não foi validado pela rotina pois está na lista de e-mails não permitidos!"+Chr(13)+Chr(10)
				Endif
				lRet	:= .F.
			Endif
		Next
		
		// Força verificação do e-mail pela função padrão Totvs - http://tdn.totvs.com/display/tec/ISEMAIL
		If !IsEmail(Lower(Alltrim(cInEmail)))
			lRet 	:= .F.
			If lExibeAlerta
				MsgAlert("O e-mail informado '"+cInEmail+"' não foi validado pela rotina por não estar no padrão de formato de e-mail permitido.","EMAIL INFORMADO COM PROBLEMA!")
			Else
				cTxtFalso += "O e-mail informado '"+cInEmail+"' não foi validado pela rotina por não estar no padrão de formato de e-mail permitido."
			Endif
		Endif
		
		If lRet
			// Se a verificação não vier da liberção de alçadas e rotinas externas de cadastros
			If !lValdAlcada	.And. lExibeAlerta				
				Processa( {|| cRetUrl := Alltrim(HttpGet(cUrlValid)) },"Aguarde... Validando E-mail")
				If '"credits":0' $ cRetUrl 
					lRet	:= .T. 
				ElseIf '"status":1' $ cRetUrl .And. '"smtp_log":"Success"' $ cRetUrl
					lRet	:= .T.
				ElseIf '"smtp_log":"MailboxDoesNotExist"' $ cRetUrl 
					If !IsBlind()
						lRet := MsgNoYes("O e-mail informado '"+cInEmail+"' não existe! Favor verificar se está correto! Deseja confirmar assim mesmo?","EMAIL INFORMADO COM PROBLEMA!")
					Else
						lRet := .T.
					EndIf										
				
				Else
					// IAGO 28/03/2016 Ajuste para nao validar no job.
					If !isBlind()
						lRet := MsgNoYes("O e-mail informado '"+cInEmail+"' não foi validado pela rotina! Favor verificar se está correto! Deseja confirmar assim mesmo?","EMAIL INFORMADO COM PROBLEMA!")
					Else
						lRet := .T.
					EndIf										
				Endif
			Endif
		Endif
		
	Endif
	
Return lRet


/*/{Protheus.doc} GMTMKM02
(Efetua validação via Thread do email em página PHP)
@author MarceloLauschner
@since 26/05/2014
@version 1.0
@param cEmp, character, (Descrição do parâmetro)
@param cFil, character, (Descrição do parâmetro)
@param cUrlValid, character, (Descrição do parâmetro)
@param cTxtFalso, character, (Descrição do parâmetro)
@param cInMail, character, (Descrição do parâmetro)
@param cMails, character, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function GMTMKM02(cEmp,cFil,cUrlValid,cTxtFalso,cInMail,cMails)
	
	// Seta job para nao consumir licensas
	RpcSetType(3)
	// Seta job para empresa filial desejada
	RpcSetEnv( cEmp, cFil,,,)
	
	If Alltrim(HttpGet(cUrlValid)) <> "1"
		U_WFGERAL(cMails,;
			"E-mail '"+Alltrim(cInMail)+"'não validado em autenticação de provedor",;
			cTxtFalso)
	Endif
	
Return
