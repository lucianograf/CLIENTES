#include "TOTVS.CH"
#include "aarray.ch"
#include "json.ch"
#include "shash.ch"

/*/{Protheus.doc} JOBFID01
    (long_description)
    @type  Function
    @author Jefferson de Souza
    @since 03/08/2021
    @version version
    @param param_name, param_type, param_descr
    @return return_var, return_type, return_description
    @example
    (examples)
    @see (links_or_references)
    /*/
User Function JOBFID01()
    
    Local cCpf       := '' 
    Local cNome      := ''
    Local cEmail     := ''
    Local cTelefone  := ''
    Local cPosCli    := ''
    Local cPosPta    := ''
	Local cPosZFD    := ''
    Local cValPont   := ''
	Local cTpReg     := ''
	Local nVlrTot    := 0
	Local cPtoRes    := ''
	Local cPtoCre    := ''
	
	Local cNota      := ''
	Local cSerie     := ''
	Local cFilReg    := ''
	Local lOk        := .F.
    Private cToken     := ''
	Private cTpPremio

     RPCSETTYPE(3)
     RPCSetEnv("01","0108")

   	
	BeginSql alias "cExtrato"
	
		select REG,SUM(PONTUACAO) AS PONTUACAO,SUM(VALOR) AS VALOR,SUM(PTOGERAL) AS PTOGERAL,CPF,NOME,EMAIL,DDD,CODCLI,LOJA,CONDPG,EMISSAO,TEL,FORMPG,FILIAL,NOTA,SERIE
		From (

		Select CASE WHEN SL4.L4_FORMA  IN('FD') THEN 'R'
					Else 'P'
					End AS 'REG' ,FLOOR(SUM(L4_VALOR)* 0.1) AS PONTUACAO, SUM(L4_VALOR) AS VALOR, 
					FLOOR(SUM(L4_VALOR)) AS PTOGERAL, A1_CGC AS CPF, TRANSLATE(A1_NOME,'ÁÉÍÓÚáéíóú','AEIOUaeiou') AS NOME, A1_EMAIL AS EMAIL,
					 A1_DDD AS DDD,A1_COD AS CODCLI,  A1_LOJA AS LOJA, L1_CONDPG AS CONDPG, 
					 F2_EMISSAO AS EMISSAO, A1_TEL AS TEL, L1_FORMPG AS FORMPG, F2_FILIAL AS FILIAL,
					 F2_DOC AS NOTA, F2_SERIE AS SERIE
                               
            from %Table:SF2% SF2
			Inner Join  %Table:SL1% SL1
			On SL1.L1_FILIAL = SF2.F2_FILIAL
				and SL1.L1_DOC   = SF2.F2_DOC
				and SL1.L1_SERIE = SF2.F2_SERIE
				and SL1.%NotDel%

			Inner Join %Table:SA1% SA1
			On SA1.A1_FILIAL = ''
				and SA1.A1_COD   = SF2.F2_CLIENTE
				and SA1.A1_LOJA  = SF2.F2_LOJA
				and SA1.%NotDel%

			Inner Join  %Table:SL4% SL4
				On SL4.L4_FILIAL = SL1.L1_FILIAL
				and SL4.L4_NUM   = SL1.L1_NUM
				and SL4.%NotDel% and SL4.L4_FORMA NOT IN('FI','VP')
			Where  SF2.%NotDel% and SUBSTRING(F2_SERIE,1,2) IN('CF','10') and SF2.F2_IMPORT = '' AND SA1.A1_PESSOA = 'F'
			and L1_FILIAL IN ('0108','0102','0103') and SA1.A1_COD <> '000001' and F2_EMISSAO >='20210923' and SA1.A1_CLIPRI <> 'COLABORA'
			
			
			Group By A1_CGC , L1_CONDPG , F2_EMISSAO, F2_FILIAL, 
			         L1_FORMPG,A1_NOME,A1_DDD,A1_TEL,A1_EMAIL,F2_DOC,F2_SERIE,A1_COD , A1_LOJA,L4_FORMA 
			
			/*order By REG Desc*/
			) AS tab
			GROUP BY REG,CPF,NOME,EMAIL,DDD,CODCLI,LOJA,CONDPG,EMISSAO,TEL,FORMPG,FILIAL,NOTA,SERIE
			order By REG Desc

	    EndSql
		Count to nCount

	cExtrato->(DbGoTop())
	while cExtrato->(!EOF())
		

		cTpReg     := ''
		cCpf       := ''
        cNome      := ''
        cEmail     := ''
        cTelefone  := ''
        cValPont    := ''
        cPosCli    := ''
        cPosPta    := ''
		cPosRes    := ''
		cTpPremio  := ''
		cPtoRes    := ''
		cPtoCre    := ''
		nVlrTot    := 0
		cFilReg    := ''
		cNota      := ''
		cSerie     := ''

		cNota  	   := cExtrato->NOTA + (SPACE(TamSx3("F2_DOC")[1] - Len(cExtrato->NOTA)))
		cSerie 	   := cExtrato->SERIE + (SPACE(TamSx3("F2_SERIE")[1] - Len(cExtrato->SERIE)))	
		cTpReg     := cExtrato->REG
        cCpf       := cExtrato->CPF
        cNome      := cExtrato->NOME
        cEmail     := cExtrato->EMAIL
        cTelefone  := "("+cExtrato->DDD+")"+cExtrato->TEL
        cValPont   :=  CVALTOCHAR(cExtrato->VALOR)
		cFilReg    := cExtrato->FILIAL
		cIdVer     := cNota+cSerie+cExtrato->FILIAL
		lOk        := U_xToken(cFilReg)

		if lOk == .F.
			//Verificar criação de log
			Return
		Endif


        cPosCli    := '{"CPF":"'+cCpf+'","nome":"'+cNome+'","email":"'+ cEmail+'","telefone": "'+ cTelefone+'"}'
        cPosPta    := '{"CPF":"'+cCpf+'","pontuacao_reais": "'+cValPont+'","verificador":"'+ cIdVer+'"}'
		

		//Cadastra Consumidor no Fidelimax
        U_APIFIDEL('A',cPosCli,cFilReg,'',cCpf, .F., cToken)
		
		if cTpReg == 'R'
			cPtoRes   :=  CVALTOCHAR(cExtrato->PTOGERAL)
			cPosRes    := '{"CPF":"'+cCpf+'","quantidade":"'+cPtoRes+'","premio_identificador":"'+cTpPremio+'"}'
			
			//U_APIFIDEL('S',cPosRes,cFilReg,cNome,cCpf, .F., cToken, cNota , cSerie,cPtoRes,cPtoCre )
			
			U_APIFIDEL('S',cPosRes,cFilReg,cNome,cCpf, .F., cToken, cNota , cSerie,cPtoRes,cPtoCre )
			//Pontua Cliente Site Fidelimax
			
		else
			cPtoCre   :=  CVALTOCHAR(cExtrato->PTOGERAL)
			U_APIFIDEL('P',cPosPta,cFilReg,cNome,cCpf, .F., cToken, cNota , cSerie,cPtoRes,cPtoCre )
			
		endif

      	/*Reclock("ZFE",.T.)
		ZFE_FILIAL  := cExtrato->FILIAL // SF2->F2_FILIAL
		ZFE_CPF     := cExtrato->CPF
		ZFE_VERIFI  := cIdVer
		ZFE_SALDO   := 0
		if cTpReg == 'P'
			ZFE_CREDIT  := cExtrato->PONTUACAO
			ZFE_TPCOMP  := 'VENDA'
		else
			ZFE_DEBITO  := cExtrato->PONTUACAO
			ZFE_TPCOMP  := 'RESGATE'
		Endif

		ZFE_DTPONT  := DATE()
		ZFE_TPCOMP  := ''
		ZFE_LOJA    := cExtrato->FILIAL 
		ZFE_TPPONT  := 0
		ZFE_DOC     :=  cExtrato->NOTA
		ZFE_SERIE   :=  cExtrato->SERIE
		ZFE_CLIENT  :=  cExtrato->CODCLI
		ZFE_LOJCLI  :=  cExtrato->LOJA
		ZFE_CONDPG  :=  cExtrato->CONDPG 
		ZFE_FRMPAG  :=  cExtrato->FORMPG
		ZFE_VALOR   :=  cExtrato->VALOR
		ZFE->(MsUnlock())*/
		
		DbSelectArea("SF2")
		DbSetOrder(1)
		If DBSEEK(cFilReg+cNota+cSerie)
				Reclock("SF2",.F.)	
					 SF2->F2_IMPORT   := 'S'
					SF2->F2_DTIMPORT := DATE()
				SF2->(MsUnlock())
		Endif
   
     cExtrato->(DbSkip())	   
     end 
cExtrato->(DbCloseArea())

xEstorno()

Return 

// Pensar no estorno de Fidelização.
Static Function xEstorno()

Local cCpf 	   := ''
Local cPto 	   := ''
Local cValPont := ''
Local cIdVer   := ''
Local cPosEst  := ''
Local cRetEst  := 0
Local lOk      := .T.
Local cNome    := ''

BeginSql alias "cEstorno"
	
		Select 
		       A1_CGC AS CPF, A1_NOME AS NOME, A1_EMAIL AS EMAIL, A1_DDD AS DDD,A1_COD AS CODCLI,
			   A1_LOJA AS LOJA, F2_EMISSAO AS EMISSAO, A1_TEL AS TEL, 
			   F2_FILIAL AS FILIAL,F2_DOC AS NOTA, F2_SERIE AS SERIE
            
                   
            from %Table:SF2% SF2

			Inner Join %Table:SA1% SA1
			On SA1.A1_FILIAL = ''
				and SA1.A1_COD   = SF2.F2_CLIENTE
				and SA1.A1_LOJA  = SF2.F2_LOJA
				and SA1.%NotDel%

	
			Where  SF2.D_E_L_E_T_ = '*' and SUBSTRING(F2_SERIE,1,2) IN('CF','10') and SF2.F2_IMPORT = 'S' and SA1.A1_PESSOA = 'F'
			 and F2_FILIAL IN ('0108','0102','0103')  and F2_EMISSAO >= '20210923' and SA1.A1_COD <> '000001' and SA1.A1_CLIPRI <> 'COLABORA'
			
			
			Group By A1_CGC ,F2_EMISSAO, F2_FILIAL, 
			       A1_NOME,A1_DDD,A1_TEL,A1_EMAIL,F2_DOC,F2_SERIE,A1_COD , A1_LOJA

	    EndSql
		Count to nCount

		cEstorno->(DbGoTop())
		while cEstorno->(!EOF())

		cCpf 	   := ''
		cPto 	   := ''
		cValPont   := '' 
	    cIdVer     := ''	
		cNome      := ''

		cNota  	   := cEstorno->NOTA + (SPACE(TamSx3("F2_DOC")[1] - Len(cEstorno->NOTA)))
		cSerie 	   := cEstorno->SERIE + (SPACE(TamSx3("F2_SERIE")[1] - Len(cEstorno->SERIE)))	
		cTpReg     := ''
		cNome      := cEstorno->NOME
        cCpf       := cEstorno->CPF
		cFilReg    := cEstorno->FILIAL
		cIdVer     := cNota+cSerie+cFilReg
		lOk        := U_xToken(cFilReg)

		If lOk == .F.
			Return
		Endif
			
 		//cPosPta    := '{"CPF":"'+cCpf+'","pontuacao_reais": "'+cValPont+'","verificador":"'+ cIdVer+'"}'
		cPosEst := '{"CPF":"'+cCpf+'","verificador":"'+ cIdVer+'","pontuacao_reais": 0, "estorno": true}'
				//Cadastra Consumidor no Fidelimax
        U_APIFIDEL('P',cPosEst, cFilReg,cNome,cCpf, .F., cToken,cNota , cSerie,'0','0')

		/*	Reclock("ZFE",.T.)
			ZFE_FILIAL  := cEstorno->FILIAL // SF2->F2_FILIAL
			ZFE_CPF     := cEstorno->CPF
			ZFE_VERIFI  := cIdVer
			ZFE_SALDO   := 0

			if cTpReg == 'P'
				ZFE_CREDIT  := cEstorno->PONTUACAO
				ZFE_TPCOMP  := 'VENDA'
			else
				ZFE_DEBITO  := cEstorno->PONTUACAO
				ZFE_TPCOMP  := 'RESGATE'
			Endif

			ZFE_DTPONT  := DATE()
			
			ZFE_LOJA    := cEstorno->FILIAL 
			ZFE_TPPONT  := 0
			ZFE_DOC     :=  cEstorno->NOTA
			ZFE_SERIE   :=  cEstorno->SERIE
			ZFE_CLIENT  :=  cEstorno->CODCLI
			ZFE_LOJCLI  :=  cEstorno->LOJA
			ZFE_CONDPG  :=  cEstorno->CONDPG 
			ZFE_FRMPAG  :=  cEstorno->FORMPG
			ZFE_VALOR   :=  cEstorno->VALOR
			ZFE->(MsUnlock())*/
					
			
		cEstorno->(DbSkip())
	end
	
	cEstorno->(DbCloseArea())


Return

/*/{Protheus.doc} xToken
@Description 
@author 	 
@since  	 05/08/2021
/*/
User Function xToken(cFilReg)

Local lOk := .F.
		
		If cFilReg == '0108'
			cToken := 'AuthToken: 2d7482d3-5fc4-4817-88c0-0278bde5d60b-445'
			// Não Alterar, pois é o código de referência da plataforma
			cTpPremio  := 'premio geral BNU'
			lOk := .T.
		elseif cFilReg == '0102'
			cToken := 'AuthToken: 0d03ac86-bb54-4bb8-9b8e-35a9c29991d5-446'
			// Não Alterar, pois é o código de referência da plataforma
			cTpPremio  := 'premio geral FLN'
			lOk := .T.
		elseif cFilReg == '0103'
			cToken :='AuthToken: 002bbd28-4e46-48fd-a1b6-12147b7b8894-444'
			// Não Alterar, pois é o código de referência da plataforma
			cTpPremio  := 'premio geral SP'
			lOk := .T.
		endif
	
	
Return lOk
