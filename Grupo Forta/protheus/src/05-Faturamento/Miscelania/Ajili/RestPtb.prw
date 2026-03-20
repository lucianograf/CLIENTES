#include "totvs.ch"
#include "tbiconn.ch"
#include "topconn.ch"


/*/{Protheus.doc} RestPtb
//TODO Integração de Tabelas de Preços - Protheus x Ajili 
@author Marcelo Alberto Lauschner 
@since 21/02/2020
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function RestPtb(aParam)

	
	Local	lRet 		:= .F.
	Local	nWaitSec	:= 0
	Default	cInCodLj	:= ""
	Default	aParam		:= {}
	Private lDebug		:= .F. 
	Private cNomRot		:= "RESTPTB_"+cFilAnt
	
	/// Mensagem de saída no Consol	
	ConOut("+-"+Replicate("-",100)+"+")
	ConOut("| "+Padr(cNomRot + " " + FunName() + "." + ProcName(0) + "-" + Alltrim(Str(ProcLine(0))) ,100) +"|")
	ConOut("| "+Padr(cNomRot + " Inicio " + DTOC(Date()) + " " + Time(),100) +"|")
	ConOut("| "+Padr(cNomRot + " Empresa Logada: " + cEmpAnt,100)+"|")
	ConOut("| "+Padr(cNomRot + " Filial Logada : " + cFilAnt,100)+"|")
	VarInfo(cNomRot+".Valores passados via aParam",aParam)
	
	If GetNewPar("GF_AJILIOK",.T.)
	
		While !lRet
			
			
			If lRet	:= LockByName(cNomRot,.T.,.T.)
			
				Processa({|| sfRodaPtb() },"Processando preços...")		
				
				UnLockByName(cNomRot,.T.,.T.)
				
	
			Else
				
				MsAguarde({|| Sleep( 1 * 1000) }, "Aguarde " + cValToChar(10-nWaitSec) + " segundos! Exportação de preços já em execução!")
				
				nWaitSec ++ 

				ConOut("|"+Padr("["+cNomRot+"]Job ja esta em execucao. Tentativa " + cValToChar(nWaitSec) ,100)+"|")
				
				// Havendo mais de 10 tentativas de espera por 1 segundos cada, aborta o processo 
				If nWaitSec  >= 10 
					lRet	:= .T.
					Exit
				Endif						
			Endif
		Enddo
	Endif
	ConOut("| "+Padr(cNomRot + " Final " + DTOC(Date()) + " " + Time(),100) +"|")
	ConOut("+-"+Replicate("-",100)+"+")

Return



/*/{Protheus.doc} SchedDef
//TODO Função que permite agendar a rotina no Schedule do Protheus
@author Marcelo Alberto Lauschner
@since 21/02/2020
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
Static Function SchedDef()
	Local	aOrd	:= {}
	Local	aParam	:= {}

	Aadd(aParam,"P")
	Aadd(aParam,"PARAMDEF")
	Aadd(aParam,"")
	Aadd(aParam,aOrd)
	Aadd(aParam,)	

Return aParam



/*/{Protheus.doc} sfRodaPtb
//TODO Executa a rotina de integração 
@author Marcelo Alberto Lauschner
@since 21/02/2020
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
Static Function sfRodaPtb()

	Local 	cURL		    := Alltrim(GetNewPar("GF_AJ_URL",""))
	Local 	cAcesso         := "/api/pricing-tables?"
	Local	cApiKey			:= "api_key=" + Alltrim(GetNewPar("GF_AJ_KEY",""))
	Local 	cGetParms       := ""
	Local 	nTimeOut 		:= 120
	Local 	aHeader         := {}
	Local 	cHeaderGet      := ""                   
	Local 	cJsonCon		:= ""
	Local	cQry		
	Local	nRec	
	Local	nRecAtu			:= 0

	aadd(aHeader,'Content-Type: application/json')
	Aadd(aHeader, "Accept: application/json")

	cQry := "SELECT DA0_FILIAL, DA0.R_E_C_N_O_ DA0RECNO,DA0_CODTAB,DA0_DESCRI "
	cQry += "  FROM " + RetSqlName("DA0") + " DA0 "  
	cQry += "  INNER JOIN " + RetSqlName("DA1") + " DA1 " 
	cQry += "    ON DA1.D_E_L_E_T_ =' ' " 
	cQry += "   AND DA1_FILIAL = '" + xFilial("DA1") + "' " 
	cQry += "   AND DA1_CODTAB = DA0_CODTAB " 
	cQry += " INNER JOIN " + RetSqlName("SB1") + " SB1 " 
	cQry += "    ON SB1.D_E_L_E_T_ =' ' "
	cQry += "   AND B1_COD = DA1_CODPRO "
	cQry += "   AND B1_XINTEGR = 'S' "
	cQry += "   AND B1_TIPO IN('ME','PA','GN','MP','MC','KT','SV') "
	cQry += "   AND B1_MSBLQL <> '1' "
	cQry += "   AND B1_FILIAL = '" + xFilial("SB1")  + "' "
	cQry += " WHERE DA0.D_E_L_E_T_ =' ' " 
	cQry += "   AND DA0_FILIAL = '" + xFilial("DA0") + "' AND DA0_INTEGR = 'S' "
	//cQry += "   AND (DA0_MSEXP = ' ' OR DA1_MSEXP = ' ' )"	// Retirada validação de carga em 13/10/2024 
	cQry += " GROUP BY DA0_FILIAL, DA0.R_E_C_N_O_,DA0_CODTAB,DA0_DESCRI "
	cQry += " ORDER BY DA0_FILIAL,DA0_CODTAB "

	TcQuery cQry New Alias "QDA0"
	
	Count To nRec

	ProcRegua(nRec)

	QDA0->(DbGotop())
	
	While QDA0->(!Eof())  

		nIdAjili		:= 0
		
		nRecAtu ++ 
		IncProc("Registro " + cValToChar(nRecAtu) + " de " + cValToChar(nRec)  )
		
		DbSelectArea("Z00")
		DbSetOrder(1)//Z00_FILIAL+Z00_ENTIDA+Z00_CHAVE
		If DbSeek(xFilial("Z00") + "DA0" + QDA0->(DA0_FILIAL+DA0_CODTAB))
			nIdAjili		:= Z00->Z00_IDAJIL
		Endif

		cJsonPtb := sfMontaJson(nIdAjili)
		ConOut("["+cNomRot+"][JSON HTTPPOST]["+cJsonPtb+"]}")
		
		cRetorno := HttpPost( cURL+cAcesso+cApiKey,"",encodeUTF8(cJsonPtb),200,aHeader,@cHeaderGet)
	
		ConOut("["+cNomRot+"][RETORNO]["+cRetorno+"]")
	
		nDA0IdAjili := Val(cRetorno)

		_cStatus := Substr(cHeaderGet,10,3)

	
		If _cStatus $ "200" .And. nDA0IdAjili > 0 // Inclusão / Alteração / Reativação 
		
			DbSelectArea("Z00")
			DbSetOrder(1)//Z00_FILIAL+Z00_ENTIDA+Z00_CHAVE
			If DbSeek(xFilial("Z00") + "DA0" +QDA0->(DA0_FILIAL+DA0_CODTAB))
				//nIdAjili		:= Z00->Z00_IDAJIL
				RecLock("Z00",.F.)
			Else
				RecLock("Z00",.T.)
			Endif
			Z00->Z00_FILIAL 	:= xFilial("Z00")	//- Filial
			Z00->Z00_ENTIDA 	:= "DA0"			//- Entidade
			Z00->Z00_NCHAVE 	:= 1				//- Indice da Entidade 
			Z00->Z00_CHAVE  	:= QDA0->(DA0_FILIAL+DA0_CODTAB)	//- Chave de pesquisa/relação 
			Z00->Z00_INTEGR 	:= "X"				//- Status Integração
			Z00->Z00_IDAJIL 	:= nDA0IdAjili		//- Id de Integração Ajili
			Z00->Z00_MSEXP		:= DTOS(Date())
			MsUnlock()
			
			// Atualiza controle de exportação de registro 
			DbSelectArea("DA0")
			DbGoto(QDA0->DA0RECNO)
			RecLock("DA0",.F.)
			DA0->DA0_MSEXP 	:= DTOS(Date())
			MsUnlock()
			
		Else
			MsgAlert("Status " + _cStatus + " para tabela de preço " + QDA0->DA0_CODTAB + " Retorno " + cRetorno)
		EndIf    
		
		dbSelectArea("QDA0")
		dbSkip()
	Enddo
	QDA0->(DbCloseArea())
	
return 


Static Function sfMontaJson(nIdAjili)


	Local cJsonPtb			:= ""
	Local cFilSB1			:= xFilial("SB1")
	
	dbSelectArea("DA1")
	dbSetOrder(1)
	dbSeek(xFilial("DA1")+QDA0->DA0_CODTAB)

	cJsonPtb := '{'
	cJsonPtb += '"specificPricePerProduct": {'

	While !Eof() .And. DA1->DA1_FILIAL == xFilial("DA1") .And. DA1->DA1_CODTAB == QDA0->DA0_CODTAB
		
		DbSelectArea("Z00")
		DbSetOrder(1)//Z00_FILIAL+Z00_ENTIDA+Z00_CHAVE
		If DbSeek(xFilial("Z00") + "SB1" + cFilSB1 + DA1->DA1_CODPRO )
			cJsonPtb += '"' + AllTrim(Str(Z00->Z00_IDAJIL,11,0)) + '":' + Alltrim( Str(DA1->DA1_PRCVEN,12,2))+','
		EndIf
		
		DbSelectArea("DA1")
		RecLock("DA1",.F.)
		DA1->DA1_MSEXP	:= DTOS(Date())
		MsUnlock()
		
		dbSelectArea("DA1")
		dbSkip()
	Enddo

	cJsonPtb := Left(cJsonPtb,Len(cJsonPtb)-1)
	cJsonPtb += '},'
	cJsonPtb += '"specificVisibilityPerProduct": {'
	nCont				:= 0

	dbSelectArea("DA1")
	dbSetOrder(1)
	dbSeek(xFilial("DA1")+QDA0->DA0_CODTAB)

	While !Eof() .And. DA1->DA1_FILIAL == xFilial("DA1") .And. DA1->DA1_CODTAB == QDA0->DA0_CODTAB 

		DbSelectArea("Z00")
		DbSetOrder(1)//Z00_FILIAL+Z00_ENTIDA+Z00_CHAVE
		If DbSeek(xFilial("Z00") + "SB1" + cFilSB1 + DA1->DA1_CODPRO )
			cJsonPtb += '"'+AllTrim(Str(Z00->Z00_IDAJIL,11,0))+'": true,'
		EndIf

		dbSelectArea("DA1")
		dbSkip()
	Enddo

	cJsonPtb := Left(cJsonPtb,len(cJsonPtb)-1)

	cJsonPtb += '},'
	cJsonPtb += '"table": {'
	cJsonPtb += '"description": "'+QDA0->DA0_CODTAB+"-"+QDA0->DA0_DESCRI+'",'
	cJsonPtb += '"discount": 0,'
	cJsonPtb += '"email": "",'
	cJsonPtb += '"enabled": true,'
	If !Empty(nIdAjili)
		cJsonPtb += '"id": '+Alltrim(Str(nIdAjili,11,0))+','
	EndIf
	cJsonPtb += '"idErp": "'+AllTrim(QDA0->DA0_FILIAL+QDA0->DA0_CODTAB)+'",'
	cJsonPtb += '"maxDiscount": 0,'
	cJsonPtb += '"name": "'+QDA0->DA0_DESCRI+'"'
	cJsonPtb += '}'
	cJsonPtb += '}'

	
Return cJsonPtb

//-----------------------------------------------
