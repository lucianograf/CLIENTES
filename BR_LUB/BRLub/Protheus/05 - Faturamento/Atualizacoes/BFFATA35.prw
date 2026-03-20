#Include 'Protheus.ch'


/*/{Protheus.doc} BFFATA35
(long_description)
@author MarceloLauschner
@since 03/06/2014
@version 1.0
@param cZ9ORIGEM, character, (Descrição do parâmetro)
@param cZ9NUM, character, (Descrição do parâmetro)
@param cZ9EVENTO, character, (Descrição do parâmetro)
@param cZ9DESCR, character, (Descrição do parâmetro)
@param cZ9SMAIL, character, (Descrição do parâmetro)
@param cZ9DEST, character, (Descrição do parâmetro)
@param cZ9USER, character, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFFATA35(cZ9ORIGEM,cZ9NUM,cZ9EVENTO,cZ9DESCR,cZ9DEST,cZ9USER,cZ9PRCRET)
	
	Local	aAreaOld	:= GetArea()
	Default	cZ9DEST		:= ""
	Default	cZ9USER		:= ""
	Default	cZ9PRCRET	:= ""
	
	DbSelectArea("SZ9")
	RecLock("SZ9",.T.)
	SZ9->Z9_FILIAL	:= xFilial("SZ9")
	SZ9->Z9_ORIGEM	:= cZ9ORIGEM
	SZ9->Z9_NUM		:= cZ9NUM
	SZ9->Z9_DATA	:= Date()
	SZ9->Z9_HORA	:= Time()
	SZ9->Z9_EVENTO	:= cZ9EVENTO
	SZ9->Z9_DESCR	:= cZ9DESCR
	SZ9->Z9_DEST	:= cZ9DEST
	SZ9->Z9_USER	:= cZ9USER
	SZ9->Z9_PRCRET	:= cZ9PRCRET
	MsUnlock()
	RestArea(aAreaOld)
	
Return

/*/{Protheus.doc} sfRetOpc
(Retornar lista de opções de followup de pedidos)
@author MarceloLauschner
@since 03/06/2014
@version 1.0
@param cInOpc, character, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfRetOpc(cInOpc)
	
	Local	aOpcRet	:= {	{"1","1-Envio de e-mail para aprovação"},;
		{"2","2-Follow-up de comunicação"},;
		{"3","3-Rejeição de liberação de Pedido"},;
		{"4","4-Aprovação e liberação de Pedido"},;
		{"5","5-Liberação Pedido"},;
		{"6","6-Envio de Workflow"},;
		{"7","7-Liberação Automática Pedido-Callcenter"},;
		{"8","8-Solicitação de Alçada Price"},;
		{"9","9-Solicitação de Alçada Diretoria"}}
	Local	nV 
	 	
	For nV	:= 1 To Len(aOpcRet)
		If aOpcRet[nV,1] == cInOpc
			Return aOpcRet[nV,2]
		Endif
	Next
	
Return ""

