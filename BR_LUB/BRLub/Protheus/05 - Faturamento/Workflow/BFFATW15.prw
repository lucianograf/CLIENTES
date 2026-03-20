#Include 'Protheus.ch'
#Include 'TopConn.ch'


/*/{Protheus.doc} BFFATW06
(Workflow de notas fiscais sem Chave eletrônica)
@author Iago Luiz Raimondi
@since 19/01/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFFATW15()
	
	Private oDlg,oGrp1,oGrp2,oGrp3,oTGet1,oTGet2,oTGet3,oTButton1,oTButton2
	Private dDtDe 	:= Date()-1 
	Private dDtAte 	:= Date()
	Private cMail		:= "fiscal1@atrialub.com.br;fiscal2@atrialub.com.br;" //PARAMETRO??
	cMail += Space(300-Len(cMail))
	
	If Select("SM0") == 0
		
		RPCSetType(3)
		RPCSetEnv("02","01")
		sfExecWf()
		RpcClearEnv()
		
		// Adicionada a Redelog 
		RPCSetType(3)
		RPCSetEnv("06","01")
		sfExecWf()
		RpcClearEnv()
		
		// Adicionada a Onix 
		RPCSetType(3)
		RPCSetEnv("11","01")
		sfExecWf()
		RpcClearEnv()
		
	Else
		
		DEFINE DIALOG oDlg TITLE "Wf NF's sem chave" FROM 000,000 TO 400,600 PIXEL
		oGrp1    	:= TGroup():New(02,05,32,210," E-mail ",oDlg,,,.T.)
		oGrp2    	:= TGroup():New(35,05,70,125," Periodo ",oDlg,,,.T.)
		oGrp3    	:= TGroup():New(02,220,70,295," Ações ",oDlg,,,.T.)
		
		oTGet1 	:= TGet():New(15,12,{|u| If(Pcount()>0,cMail := u,cMail)},oGrp1,190,008,"@!",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.)
		
		oTGet2 	:= TGet():New(50,12,{|u| If(PCount()>0,dDtDe := u,dDtDe)},oGrp2,050,008,"@!",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.T.,,,,,,.T.)
		oTGet3 	:= TGet():New(50,67,{|u| If(PCount()>0,dDtAte := u,dDtAte)},oGrp2,050,008,"@!",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.T.,,,,,,.T.)
		
		oTButton1 	:= TButton():New(15,228,"Fechar",oGrp3,{||oDlg:End()},59,10,,,.F.,.T.,.F.,,.F.,,,.F. )
		oTButton2 	:= TButton():New(30,228,"Processar",oGrp3,{||sfExecWf()},59,10,,,.F.,.T.,.F.,,.F.,,,.F. )
		ACTIVATE DIALOG oDlg CENTERED
		
	EndIf
	
Return

/*/{Protheus.doc} sfExecWf
(long_description)
@author Iago Luiz Raimondi
@since 19/01/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfExecWf()
	
	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()
	
	If !isBlind()
		MsgRun("Verificando NF's sem chave...","NF",{||sfNFSemChave()})
	Else
		FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "BFFATW15>>Inicio do processamento.["+Time()+"]"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		sfNFSemChave()
	Endif
	
	If !isBlind()
		MsgInfo("Fim do processamento.")
	Else
		FWLogMsg("INFO", /*cTransactionId*/, Funname()/*cCategory*/, /*cStep*/, /*cMsgId*/, "BFFATW15>>Fim do processamento.["+Time()+"]"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	EndIf
Return


/*/{Protheus.doc} sfNFSemChave
(long_description)
@author Iago Luiz Raimondi
@since 19/01/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfNFSemChave()
	
	
	cQry 	:= ""
	cQry 	+= "  SELECT F2.F2_FILIAL,"
	cQry 	+= "	      F2.F2_DOC,"
	cQry 	+= "	      F2.F2_SERIE,"
	cQry 	+= "	      F2.F2_EMISSAO,"
	cQry 	+= "	      F2.F2_FIMP,"
	cQry 	+= "	      F2.F2_CHVNFE"
	cQry 	+= "    FROM "+RetSqlName("SF2")+" F2"
	cQry 	+= "   WHERE F2.F2_FILIAL <> ' ' "
	cQry 	+= "     AND F2.D_E_L_E_T_ = ' ' "
	cQry 	+= "     AND F2.F2_ESPECIE IN('SPED','CTE') "
	// IAGO 26/03/2015 Chamado(10383)
	//cQry 	+= "     AND (F2.F2_FIMP = 'T' OR F2.F2_FIMP = ' ')"
	cQry 	+= "     AND F2.F2_FIMP IN ('T',' ','N')"
	cQry 	+= "     AND F2.F2_CHVNFE = ' '"
	cQry 	+= "     AND F2.F2_EMISSAO BETWEEN '"+DTOS(dDtDe)+"' AND '"+DTOS(dDtAte)+"'"
	
	If Select("QRY") <> 0
		dbSelectArea("QRY")
		dbCloseArea()
	EndIf
	
	TCQUERY cQry NEW ALIAS "QRY"
	
	nCount := 0
	
	
	While QRY->(!EOF())
		nCount++
		If nCount == 1
			oProcess := TWFProcess():New("BFFATW06",OemToAnsi("Notas sem CHAVE"))
			If IsSrvUnix()
				If File("/workflow/nf_sem_chave.htm")
					oProcess:NewTask("Gerando HTML","/workflow/nf_sem_chave.htm")
				Else
					FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "Não localizou arquivo /workflow/nf_sem_chave.htm"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
					Return
				Endif
			Else
				oProcess:NewTask("Gerando HTML","\workflow\nf_sem_chave.htm")
			Endif
			
			oProcess:cSubject := "Notas sem CHAVE ["+DTOC(dDtDe)+" até "+DTOC(dDtAte)+"]"
			oProcess:bReturn  := ""
		Endif

		AAdd(oProcess:oHtml:ValByName("WF.FILIAL" ),	QRY->F2_FILIAL)
		AAdd(oProcess:oHtml:ValByName("WF.NUMERO"),	QRY->F2_DOC)
		AAdd(oProcess:oHtml:ValByName("WF.SERIE"),	QRY->F2_SERIE)
		AAdd(oProcess:oHtml:ValByName("WF.EMISSAO"),	Transform(STOD(QRY->F2_EMISSAO),"@E"))
		// IAGO 26/03/2015 Chamado(10383) 
		//AAdd(oProcess:oHtml:ValByName("WF.STATUS"),	IIf(Empty(QRY->F2_FIMP),"Nota sem transmitir.","Nota não foi impressa.")+" | Sem chave")
		AAdd(oProcess:oHtml:ValByName("WF.STATUS"),	IIf(QRY->F2_FIMP == "T","Nota não foi impressa.","Nota sem transmitir.")+" | Sem chave")
		
		QRY->(dbSkip())
	End
	
	If nCount > 0
		oProcess:cTo := U_BFFATM15(AllTrim(cMail),"BFFATW15")
		oProcess:Start()
		oProcess:Finish()

		// Força disparo dos e-mails pendentes do workflow
		WFSENDMAIL()
	EndIf

	If Select("QRY") <> 0
		dbSelectArea("QRY")
		dbCloseArea()
	EndIf

Return



