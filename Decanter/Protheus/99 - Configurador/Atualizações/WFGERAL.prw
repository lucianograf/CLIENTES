#Include 'totvs.ch'


/*/{Protheus.doc} WFGERAL
//TODO Descrição auto-gerada.
@author Marcelo Alberto Lauschner
@since 09/11/2018
@version 1.0
@return ${return}, ${return_description}
@param cEmail, characters, Destinatários
@param cTitulo, characters, Título do Email
@param cTexto, characters, Corpo do e-mail
@param cRotina, characters, Nome da rotina que efetuou a chamada
@param cAnexo, characters, Nome do arquivo de anexo
@type function
/*/
User Function WFGERAL(cEmail,cTitulo,cTexto,cRotina,cAnexo)

	Local 	oHTML
	Local	oProcess
	

	Default cEmail 	:= "marcelo@centralxml.com.br"
	Default cTitulo := "Workflow Genérico"
	Default	cTexto	:= "Mensagem de workflow"
	Default cRotina := "WFGERAL"
	Default cAnexo	:= ""

	// Troca a quebra de linha CRLF para tag html 
	cTexto	:= StrTran(cTexto,CRLF,"<br>")

	// Cria um novo processo (instância do processo)
	oProcess := TWFProcess():New("000001",OemToAnsi("Workflow genérico"))

	//Abre o HTML criado
	If IsSrvUnix()
		If !File("/workflow/wfgeral.htm")
			sfFile(1)			
		Endif
		oProcess:NewTask("Gerando HTML","/workflow/wfgeral.htm")
	Else
		If !File("\workflow\wfgeral.htm")
			sfFile(2)			
		Endif
		oProcess:NewTask("Gerando HTML","\workflow\wfgeral.htm")
	Endif

	//define o assunto do email
	oProcess:cSubject 	:= cTitulo 
	oProcess:bReturn  	:= ""
	oProcess:bTimeOut	:= {}
	oProcess:fDesc 		:= cTitulo
	oProcess:ClientName(Substr(cUsuario,7,15))

	If !Empty(cAnexo)
		oProcess:AttachFile(cAnexo)
	EndIf

	//Começo a preencher os valores do HTML. Inicialmente preencho o objeto
	oHTML := oProcess:oHTML
	oHTML:ValByName('CTITULO',ALLTRIM(cTitulo))
	oHTML:ValByName('CTEXTO',ALLTRIM(cTexto))
	oHTML:ValByName('CROTINA',ALLTRIM(cRotina))
	oProcess:cTo := cEmail

	// Inicia o processo
	oProcess:Start()

	// FInaliza o processo
	oProcess:Finish()

Return
/*/{Protheus.doc} sfFile
Verifica a necessidade de criar o HTML
@type function
@version 
@author Marcelo Alberto Lauschner
@since 24/11/2020
@param nInOpc, numeric, param_description
@return return_type, return_description
/*/
Static Function sfFile(nInOpc)

	Local	cOut	:= ""
	
	cOut += '<html>'
	cOut += '<head>'
	cOut += '<title>%CTITULO%</title>'
	cOut += '<meta charset="UTF-8">'
	cOut += '</head>'
	cOut += '<body>'
	cOut += '<font size="5"><center>%CTITULO%</center></font>'
	cOut += '<br>'
	cOut += '<table border="1" width="100%" bgcolor="#E4E4E4">'
	cOut += '<tr>'
	cOut += '<td>%CTEXTO%</td>'
 	cOut += '</tr>'
	cOut += '</table>'
	cOut += '<br><font size="2"><center>Mensagem enviada via Workflow. WFGERAL.PRW - %CROTINA%</center></font>'
	cOut += '</body>'
	cOut += '</html>'
	If nInOpc == 1
		MemoWrite("/workflow/wfgeral.htm",cOut)
	Else
		MemoWrite("\workflow\wfgeral.htm",cOut)
	Endif

Return 
