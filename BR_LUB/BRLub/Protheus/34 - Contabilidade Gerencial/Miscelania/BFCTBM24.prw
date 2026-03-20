#include 'protheus.ch'
#include 'parmtype.ch'
/*/{Protheus.doc} sfNew
(Verifica a existencia da conta e chama o cadastro auto)
@author Marcelo Lauschner
@since 11/12/2013
@version 1.0
@return sem retorno
/*/
User Function BFCTBM24(cA2XCCPASV,cA2COD,cA2NOME)

	Local	oModelA1 	:= FWModelActive()//->Carregando Model Ativo
	local   cPREFCTA    := AllTriM( SuperGetMv( 'BF_PREFCTA',,'210101' ) )
	
	If ALTERA .Or. INCLUI
		If Empty(cA2XCCPASV)
			DbSelectArea("CT1")
			DbSetOrder(6) //CT1_DESC01
			If DbSeek(xFilial("CT1")+cA2COD+"-"+cA2NOME) .Or. ;
					DbSeek(xFilial("CT1")+cA2NOME)
				MsgAlert("Já existe a conta contábil '"+CT1->CT1_CONTA+"' com a descrição '"+CT1->CT1_DESC01,"Conta já existe")
				cA2XCCPASV	:= CT1->CT1_CONTA
				If oModelA1 <> Nil .And. oModelA1:GetModel('SA2MASTER') <> Nil
					oModelA1:GetModel('SA2MASTER'):SetValue('A2_XCCPASV',cA2XCCPASV)
				Endif
				If Type("M->A2_XCCPASV") == "C"
					M->A2_XCCPASV	:= cA2XCCPASV
				Endif
			Else
				// Para empresa Redelog o Grupo de contas de Fornecedores é 210101
				sfModelCT1( cPREFCTA,cA2NOME)

				DbSelectArea("CT1")
				DbSetOrder(6) //CT1_DESC01
				If DbSeek(xFilial("CT1")+cA2COD+"-"+cA2NOME) .Or. ;
						DbSeek(xFilial("CT1")+cA2NOME)
					cA2XCCPASV	:= CT1->CT1_CONTA
					If oModelA1 <> Nil .And. oModelA1:GetModel('SA2MASTER') <> Nil
						oModelA1:GetModel('SA2MASTER'):SetValue('A2_XCCPASV',cA2XCCPASV)
					Endif
					If Type("M->A2_XCCPASV") == "C"
						M->A2_XCCPASV	:= cA2XCCPASV
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
Static Function sfModelCT1(cCodSup,cDescCT1)

	Local cNextCT1  	:= ""
	Local cCodCT1   	:= cCodSup + "001"
	Local nOpcAuto :=0
	Local oCT1
	Local aLog
	Local cLog :=""
	Local lRet := .T.
	Local __oModelAut
	Local oCVD
	local nX
	local lExists := .T. as logical

	PRIVATE lMsErroAuto := .F.

	cNextCT1 := cCodCT1

	// Percorre a tabela CT1 verificando por faixas de contas contábeis não utilizadas
	DBSelectArea( "CT1" )
	CT1->( DBSetOrder( 1 ) )
	while lExists .and. cNextCT1 < (cCodSup + "999")
		lExists := CT1->( DBSeek( FWxFilial( "CT1" ) + cNextCT1 ) )
		if lExists
			cNextCT1 := Soma1( cNextCT1 )
		endif
	enddo

	If !Empty(cNextCT1)
		If cNextCT1 < cCodSup + "999"

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
			oCT1:SETVALUE('CT1_NORMAL' 		,'2')
			oCT1:SETVALUE('CT1_BLOQ' 		,'2')
			oCT1:SETVALUE('CT1_DTEXIS' 		,FirstDay(FirstDay(dDataBase)-1))
			oCT1:SETVALUE('CT1_CTALP' 		,'240203003')
			If cEmpAnt == "14"
				oCT1:SETVALUE('CT1_GRUPO' 		,'00020000')
			Endif 
			oCT1:SETVALUE('CT1_NTSPED'	 	,'02')
			oCT1:SETVALUE('CT1_ACCUST' 		,'2')
			oCT1:SETVALUE('CT1_SPEDST' 		,'2')
			oCT1:SETVALUE('CT1_NATCTA' 		,'02')
			oCT1:SETVALUE('CT1_INDNAT' 		,'2')		// Classe Manad - 2-Passivo

			//---------------------------------------------------------
			// Preencho os valores da CVD
			//---------------------------------------------------------

			oCVD := __oModelAut:GetModel('CVDDETAIL') //Objeto similar getdados CVD

			oCVD:SETVALUE('CVD_FILIAL' ,CVD->(xFilial('CVD')))
			oCVD:SETVALUE('CVD_ENTREF','10')
			If cEmpAnt == "14"
				oCVD:SETVALUE('CVD_CODPLA',PadR('014LP',Len(CVD->CVD_CODPLA)))
			ElseIf cEmpAnt == "06"
				oCVD:SETVALUE('CVD_CODPLA',PadR('000001',Len(CVD->CVD_CODPLA)))
			ElseIf cEmpAnt == "02" // Age Lubrificantes 
				oCVD:SETVALUE('CVD_CODPLA',PadR('02PR',Len(CVD->CVD_CODPLA)))
			Else
				oCVD:SETVALUE('CVD_CODPLA',PadR('014',Len(CVD->CVD_CODPLA)))
			Endif
			oCVD:SETVALUE('CVD_VERSAO',PadR('0001',Len(CVD->CVD_VERSAO)))
			oCVD:SETVALUE('CVD_CTAREF',PadR('2.01.01.03.01', Len(CVD->CVD_CTAREF)))// 2.01.01.03.01
			oCVD:SETVALUE('CVD_CUSTO',' ')
			oCVD:SETVALUE('CVD_CLASSE','2')
			oCVD:SETVALUE('CVD_TPUTIL','A')
			oCVD:SETVALUE('CVD_NATCTA','02')
			oCVD:SETVALUE('CVD_CTASUP',Padr('2.01.01.03',Len(CVD->CVD_CTASUP)))	//2.01.01.03

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
