#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} sfNew
(Verifica a existencia da conta e chama o cadastro auto)
@author Marcelo Lauschner
@since 11/12/2013
@version 1.0
@return sem retorno
@example (examples)
@see (links_or_references)
/*/
User Function MLCTBM03(cA1CONTA,cA1COD,cA1NOME)

	Local	oModelA1 	:= FWModelActive()//->Carregando Model Ativo
	Local	oModelX	
	Local	lRet		:= .T. 
	Local	lContinua	:= .T. 

	If ALTERA .Or. INCLUI
		If Empty(cA1CONTA)
			// Verifica se a conta existe pelo Código REduzido
			If !Empty(cA1COD)
				DbSelectArea("CT1")
				DbSetOrder(2) //CT1_RES
				If DbSeek(xFilial("CT1")+"C"+cA1COD)
					MsgAlert("Já existe a conta contábil '"+CT1->CT1_CONTA+"' com a descrição '"+CT1->CT1_DESC01,"Conta já existe")
					cA1CONTA	:= CT1->CT1_CONTA
					If oModelA1 <> Nil
					//	oModelA1:GetModel('SA1MASTER'):SetValue('A1_CONTA',cA1CONTA)
					Endif 
					If Type("M->A1_CONTA") == "C"
						M->A1_CONTA	:= cA1CONTA
					Endif
					lContinua	:= .F. 
				Endif
			Endif	
			
			If lContinua
				DbSelectArea("CT1")
				DbSetOrder(6) //CT1_DESC01
				If DbSeek(xFilial("CT1")+cA1COD+"-"+cA1NOME) .Or. ;
				DbSeek(xFilial("CT1")+cA1NOME)
					MsgAlert("Já existe a conta contábil '"+CT1->CT1_CONTA+"' com a descrição '"+CT1->CT1_DESC01,"Conta já existe")
					cA1CONTA	:= CT1->CT1_CONTA
					If oModelA1 <> Nil
					//	oModelA1:GetModel('SA1MASTER'):SetValue('A1_CONTA',cA1CONTA)
					Endif 
					If Type("M->A1_CONTA") == "C"
						M->A1_CONTA	:= cA1CONTA
					Endif
				Else
					sfModelCT1('1120101',cA1NOME,"C"+cA1COD)


					DbSelectArea("CT1")
					DbSetOrder(6) //CT1_DESC01
					If DbSeek(xFilial("CT1")+cA1COD+"-"+cA1NOME) .Or. ;
					DbSeek(xFilial("CT1")+cA1NOME)
						cA1CONTA	:= CT1->CT1_CONTA
						If oModelA1 <> Nil
						//	oModelA1:GetModel('SA1MASTER'):SetValue('A1_CONTA',cA1CONTA)
						Endif 
						If Type("M->A1_CONTA") == "C"
							M->A1_CONTA	:= cA1CONTA
						Endif
					Endif
				Endif
			Endif
		Else
			MsgAlert("Já há Conta Contábil informada no campo Conta Passivo","A T E N Ç Ã O!!")
		Endif
	Endif

Return .T. 

//Exemplo de rotina automática para inclusão de contas contábeis no ambiente Contabilidade Gerencial (SigaCTB).
/// ROTINA AUTOMATICA - INCLUSAO DE CONTA CONTABIL CTB
Static Function sfModelCT1(cCodSup,cDescCT1,cInCodLoj)
	Local nX,nY
	Local aRecSX7 	:= {}
	Local aItens 		:= {}
	Local aCab			:= {}
	Local cNextCT1  	:= ""
	Local cCodCT1   	:= cCodSup + "000001"
	Local nOpcAuto :=0
	Local oCT1
	Local aLog
	Local cLog :=""
	Local lRet := .T.
	Local __oModelAut
	Local cAliasS1
	Local oCVD 

	PRIVATE lMsErroAuto := .F.

	cAliasS1  := GetNextAlias()

	BeginSql Alias cAliasS1
		SELECT COALESCE(MAX(CT1_CONTA),%Exp:cCodCT1%) NEXTCT1
		FROM %Table:CT1% CT1
		WHERE CT1.%NotDel%
		AND CT1_FILIAL = %xFilial:CT1%
		AND CT1_CLASSE = '2'
		AND CT1_CONTA LIKE %Exp:AllTrim(cCodSup)%+'%' 
	EndSql

	If !Eof()
		cNextCT1	:= Soma1(Padr((cAliasS1)->NEXTCT1,12))
	Endif
	(cAliasS1)->(DbCloseArea())

	If !Empty(cNextCT1)
		If cNextCT1 < cCodSup + "999999"

			If __oModelAut == Nil //somente uma unica vez carrega o modelo CTBA020-Plano de Contas CT1
				__oModelAut := FWLoadModel('CTBA020')
			EndIf


			nOpcAuto:=3


			__oModelAut:SetOperation(nOpcAuto) // 3 - Inclusão | 4 - Alteração | 5 - Exclusão
			__oModelAut:Activate() //ativa modelo

			//---------------------------------------------------------
			// Preencho os valores da CT1
			//---------------------------------------------------------

			oCT1 := __oModelAut:GetModel('CT1MASTER') //Objeto similar enchoice CT1 
			oCT1:SETVALUE('CT1_CONTA'		,cNextCT1)
			oCT1:SETVALUE('CT1_DESC01'		,Padr(cDescCT1,Len(CT1->CT1_DESC01)))
			oCT1:SETVALUE('CT1_CLASSE'		,'2')
			oCT1:SETVALUE('CT1_NORMAL' 		,'1')
			oCT1:SETVALUE('CT1_BLOQ' 		,'2')
			oCT1:SetVAlue('CT1_RES'			,cInCodLoj)		
			oCT1:SETVALUE('CT1_DTEXIS' 		,FirstDay(dDataBase-90))
			//oCT1:SETVALUE('CT1_CTALP' 		,'240203003')
			oCT1:SETVALUE('CT1_NTSPED'	 	,'01')
			oCT1:SETVALUE('CT1_ACCUST' 		,'2')
			oCT1:SETVALUE('CT1_SPEDST' 		,'1')
			oCT1:SETVALUE('CT1_NATCTA' 		,'01')
			oCT1:SETVALUE('CT1_INDNAT' 		,'1')		// Classe Manad - 2-Passivo

			//---------------------------------------------------------
			// Preencho os valores da CVD
			//---------------------------------------------------------

			oCVD := __oModelAut:GetModel('CVDDETAIL') //Objeto similar getdados CVD

			oCVD:SETVALUE('CVD_FILIAL' ,CVD->(xFilial('CVD'))) 
			oCVD:SETVALUE('CVD_ENTREF','10')
			oCVD:SETVALUE('CVD_CODPLA',PadR("000001" ,Len(CVD->CVD_CODPLA)))
			oCVD:SETVALUE('CVD_VERSAO',PadR('0001',Len(CVD->CVD_VERSAO)))			
			oCVD:SETVALUE('CVD_CTAREF',PadR('1.01.02.02.01', Len(CVD->CVD_CTAREF)))// 2.01.01.03.01                 
		
		//	oCVD:SETVALUE('CVD_CUSTO',' ') 
		//	oCVD:SETVALUE('CVD_TPUTIL','A')
		//	oCVD:SETVALUE('CVD_CLASSE','2') 
		//	oCVD:SETVALUE('CVD_NATCTA','01')
		//	oCVD:SETVALUE('CVD_CTASUP',Padr('1.01.02.02',Len(CVD->CVD_CTASUP)))	//2.01.01.03                    


			//---------------------------------------------------------
			// Preencho os valores da CTS
			//---------------------------------------------------------


			//	oCTS := __oModelAut:GetModel('CTSDETAIL') //Objeto similar getdados CTS
			//	oCTS:SETVALUE('CTS_FILIAL' ,CTS->(xFilial('CTS'))) 
			//	oCTS:SETVALUE('CTS_CODPLA' ,'001')
			//	oCTS:SETVALUE('CTS_CONTAG' ,'0000021')


			If __oModelAut:VldData() //validacao dos dados pelo modelo

				__oModelAut:CommitData() //gravacao dos dados

			Else

				aLog := __oModelAut:GetErrorMessage() //Recupera o erro do model quando nao passou no VldData

				//laco para gravar em string cLog conteudo do array aLog
				For nX := 1 to Len(aLog)
					If !Empty(aLog[nX])
						cLog += Alltrim(aLog[nX]) + CRLF
					EndIf
				Next nX

				lMsErroAuto := .T. //seta variavel private como erro
				AutoGRLog(cLog) //grava log para exibir com funcao mostraerro
				mostraerro()
				lRet := .F. //retorna false

			EndIf

			__oModelAut:DeActivate() //desativa modelo
		Else
			MsgAlert("Estourou limite de criação de contas deste grupo. Favor informar CPD para mudar faixa de numeração!","Estouro de faixa de contas")
		Endif
	Else
		MsgAlert("Erro ao obter dados para incluir conta contábil automática!","Erro Select")
	Endif
Return( lRet )