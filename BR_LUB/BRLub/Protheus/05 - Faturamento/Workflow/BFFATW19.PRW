#Include 'Protheus.ch'
#Include 'totvs.ch'


/*/{Protheus.doc} BFFATW19
(Mapa de Vendas Texaco Gerencial equipe restrita - Com margem de venda )

@author MarceloLauschner
@since 16/07/2015
@version 1.0

@return Sem retorno

@example
(examples)

@see (links_or_references)
/*/
User Function BFFATW19()
	
	
	Local 		aOpenTable 		:= {"SE1","SA3","SCT","SC5","SC6","SF2","SD2","SD1","SF4","SZ8","SB1"}
	Local	 	aVendedores		:= {{"000903"},;
		{"000909"},;
		{"000910"},;
		{"000911"},;
		{"001207"},;
		{"001220"},;
		{"001256"},;
		{"001258"},;
		{"001211"},;
		{"001216"},;
		{"001250"},;
		{"000408"},;
		{"000410"},;
		{"001248"},;
		{"001249"},;
		{"001253"},;
		{"001243"},;
		{"001257"}}
	
	If Select("SM0") == 0
		RPCSetType(3)
		RPCSetEnv("02","01","","","","",aOpenTable) // Abre todas as tabelas.
		//dDataBase	:= CTOD("31/01/2016")
		//If !MsgNoYes("Deseja realmente rodar mapa??")
		
		//Endif
	Else
		If !SM0->M0_CODIGO == '02'
			MsgAlert("Esse mapa deve ser gerado apenas na BF!")
			Return
		Endif
		If !MsgNoYes("Deseja realmente rodar mapa??")
			Return
		Endif
	Endif
	
	sfExecuta(aVendedores)
	
Return


/*/{Protheus.doc} sfExecuta
(Execução da rotina)

@author MarceloLauschner
@since 07/04/2014
@version 1.0

@return Sem retorno

@example
(examples)

@see (links_or_references)
/*/
Static Function sfExecuta(aInVend)
	
	Local		oProcess
	Local		oHTML
	Local		cProcess 	:= "100002"
	Local		cStatus  	:= "100002"
	Local		cFilMapa	:= ""
	Local		aSubTotais	:= {}//{"","",0,"","",0,0,0,0,0,0,0,0,0}
	Local		aTotal		:= {"Total Geral","",{0,0},"","",{0,0},{0,0},{0,0},{0,0},0,{0,0},0,{0,0},0,0,0,0}
	Local		nValMargem	:= 0
	Local		nPerMargem	:= 0
	Local		aFilNomes	:= {{"01","-Santa Catarina"},{"04","-Paraná"},{"05","-Rio Grande do Sul"},{"07","-São Paulo"},{"08","-Minas Gerais"}}
	Local		x
	Private	dDataIni	:= FirstDay(dDataBase)
	Private	aVetorMapa	:= {}
	Private	nContAdd	:= 0
	Private cSendMail	:= ""
	
	// Estrutura  Vetor
	//	1 - Código Vendedor
	// 	2 - Filial
	// 	3 - Meta
	//	4 - Gerente
	// 	5 - Nome Reduzido
	// 	6 - Vendido
	// 	7 - Eliminado
	// 	8 - Pendente
	//	9 - Faturado
	// 	10- Clientes
	//	11- Devolvido
	//	12- Prazo Médio
	// 	13- Margem
	// 	14- Contador
	//	15- Duplicatas
	//	16- Num.Devoluções
	// 	17- Bonificações
	// 	18- Supervisor
	
	oProcess := TWFProcess():New(cProcess,OemToAnsi("Envio Mapa de Vendas Gerencial com Margens"))
	
	If IsSrvUnix()
		If File("/workflow/mapa_gerentes_margem.htm")
			oProcess:NewTask("Gerando HTML","/workflow/mapa_gerentes_margem.htm")
		Else
			FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "Não localizou arquivo  /workflow/mapa_gerentes_margem.htm"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			Return
		Endif
	Else
		oProcess:NewTask("Gerando HTML","\workflow\mapa_gerentes_margem.htm")
	Endif
	
	DbSelectArea("SA3")
	dbSetOrder(1)
	Dbseek(xFilial("SA3")+"001000")
	oProcess:cSubject := "Mapa de Vendas Texaco Gerencial "+ SA3->A3_COD + "-" + SA3->A3_NREDUZ + " "+ Substr(DTOS(dDatabase),5,2) + "/" + Substr(DTOS(dDatabase),1,4)
	oProcess:bReturn  := ""
	oHTML := oProcess:oHTML
	
	// Executa função que monta Vetor das Metas
	sfMetas(aInVend)
	// Executa função que monta Vetor das Vendas
	sfVendido(aInVend)
	// Executa função que monta Vetor de pendência
	sfPendente(aInVend)
	// Executa função que monta Vetor de Faturamento
	sfFaturado(aInVend)
	// Executa função que monta Vetor de Devoluções
	sfDevolvido(aInVend)
	// Executa função que monta Vetor dos Prazos
	sfPrazo(aInVend)
	
	
	
	aSort(aVetorMapa,,,{|x,y| x[2]+x[1] < y[2]+y[1]})
	
	
	For x := 1 To Len(aVetorMapa)
		If aVetorMapa[x,2] <> cFilMapa .And. !Empty(cFilMapa)
			
			AAdd((oHtml:ValByName("l.vend" ))	,  "Total Filial "+cFilMapa + aFilNomes[aScan(aFilNomes,{|x| x[1] == cFilMapa}),2] )
			//Aadd((oHtml:ValByName("l.vend"   )) ,  "Total Gerente " + cFilMapa + "-" + Capital(Posicione("SA3",1,xFilial("SA3")+cFilMapa,"A3_NREDUZ")) + cInNomAux )
			AAdd((oHtml:ValByName("l.vl_met" ))	,  Transform(aSubTotais[Len(aSubTotais),3,1],"@E 999,999,999"))
			AAdd((oHtml:ValByName("l.lt_met" ))	,  Transform(aSubTotais[Len(aSubTotais),3,2],"@E 999,999,999"))
			AAdd((oHtml:ValByName("l.vl_ven" ))	,  Transform(aSubTotais[Len(aSubTotais),6,1],"@E 999,999,999"))
			AAdd((oHtml:ValByName("l.lt_ven" ))	,  Transform(aSubTotais[Len(aSubTotais),6,2],"@E 999,999,999"))
			AAdd((oHtml:ValByName("l.vl_eli" ))	,  Transform(aSubTotais[Len(aSubTotais),7,1],"@E 999,999,999"))
			AAdd((oHtml:ValByName("l.lt_eli" ))	,  Transform(aSubTotais[Len(aSubTotais),7,2],"@E 999,999,999"))
			AAdd((oHtml:ValByName("l.vl_pen" ))	,  Transform(aSubTotais[Len(aSubTotais),8,1],"@E 999,999,999"))
			AAdd((oHtml:ValByName("l.lt_pen" ))	,  Transform(aSubTotais[Len(aSubTotais),8,2],"@E 999,999,999"))
			AAdd((oHtml:ValByName("l.vl_fat" ))	,  Transform(aSubTotais[Len(aSubTotais),9,1],"@E 999,999,999"))
			AAdd((oHtml:ValByName("l.lt_fat" ))	,  Transform(aSubTotais[Len(aSubTotais),9,2],"@E 999,999,999"))
			AAdd((oHtml:ValByName("l.vl_pmt" ))	,  Transform(aSubTotais[Len(aSubTotais),9,1]/aSubTotais[Len(aSubTotais),3,1]*100,"@E 999.99"))
			AAdd((oHtml:ValByName("l.lt_pmt" ))	,  Transform(aSubTotais[Len(aSubTotais),9,2]/aSubTotais[Len(aSubTotais),3,2]*100,"@E 999.99"))
			AAdd((oHtml:ValByName("l.cli" ))	,  Transform(aSubTotais[Len(aSubTotais),10],"@E 9,999"))
			AAdd((oHtml:ValByName("l.vl_dev" ))	,  Transform(aSubTotais[Len(aSubTotais),11,1],"@E 999,999,999"))
			AAdd((oHtml:ValByName("l.lt_dev" ))	,  Transform(aSubTotais[Len(aSubTotais),11,2],"@E 999,999,999"))
			AAdd((oHtml:ValByName("l.dev" ))	,  Transform(aSubTotais[Len(aSubTotais),16],"@E 9,999"))
			AAdd((oHtml:ValByName("l.vl_liq"))	,  Transform(aSubTotais[Len(aSubTotais),9,1]-aSubTotais[Len(aSubTotais),11,1],"@E 999,999,999.99"))
			AAdd((oHtml:ValByName("l.lt_liq"))	,  Transform(aSubTotais[Len(aSubTotais),9,2]-aSubTotais[Len(aSubTotais),11,2],"@E 999,999,999"))
			AAdd((oHtml:ValByName("l.bon"))		,  Transform(aSubTotais[Len(aSubTotais),17],"@E 9,999,999.99"))
			AAdd((oHtml:ValByName("l.prazo" ))	,  Transform(aSubTotais[Len(aSubTotais),12]/aSubTotais[Len(aSubTotais),15],"@E 9,999"))
			
			//aSubTotais[Len(aSubTotais),9]-aSubTotais[Len(aSubTotais),11] * 1.00066030548229^
			//	Faturado - Devolvido - Custo - (Faturado * Prazo)
			nValMargem	:= aSubTotais[Len(aSubTotais),9,1]-aSubTotais[Len(aSubTotais),11,1]-aSubTotais[Len(aSubTotais),13,1]
			nValMargem -= aSubTotais[Len(aSubTotais),13,2]
			nPerMargem	:= nValMargem/(aSubTotais[Len(aSubTotais),9,1]-aSubTotais[Len(aSubTotais),11,1])*100
			
			AAdd((oHtml:ValByName("l.vmg" ))		,  Transform(nValMargem,"@E 999,999,999.99"))
			AAdd((oHtml:ValByName("l.pmg" ))		,  Transform(nPerMargem,"@E 999.99"))
			
			AAdd(aSubTotais,aClone(aVetorMapa[x]))
			aSubTotais[Len(aSubTotais),14] 	:= IIf(aVetorMapa[x,12] > 0 , 1 , 0 )
		Else
			If Empty(cFilMapa)
				Aadd(aSubTotais,aClone(aVetorMapa[x]))
				aSubTotais[Len(aSubTotais),14] 	:= IIf(aVetorMapa[x,12] > 0 , 1 , 0 )
			Else
				aSubTotais[Len(aSubTotais),3,1]	+= aVetorMapa[x,3,1]
				aSubTotais[Len(aSubTotais),3,2]	+= aVetorMapa[x,3,2]
				aSubTotais[Len(aSubTotais),6,1]	+= aVetorMapa[x,6,1]
				aSubTotais[Len(aSubTotais),6,2]	+= aVetorMapa[x,6,2]
				aSubTotais[Len(aSubTotais),7,1]	+= aVetorMapa[x,7,1]
				aSubTotais[Len(aSubTotais),7,2]	+= aVetorMapa[x,7,2]
				aSubTotais[Len(aSubTotais),8,1]	+= aVetorMapa[x,8,1]
				aSubTotais[Len(aSubTotais),8,2]	+= aVetorMapa[x,8,2]
				aSubTotais[Len(aSubTotais),9,1]	+= aVetorMapa[x,9,1]
				aSubTotais[Len(aSubTotais),9,2]	+= aVetorMapa[x,9,2]
				aSubTotais[Len(aSubTotais),10]	+= aVetorMapa[x,10]
				aSubTotais[Len(aSubTotais),11,1]	+= aVetorMapa[x,11,1]
				aSubTotais[Len(aSubTotais),11,2]	+= aVetorMapa[x,11,2]
				aSubTotais[Len(aSubTotais),12]	+= aVetorMapa[x,12]
				aSubTotais[Len(aSubTotais),13,1]	+= aVetorMapa[x,13,1]
				aSubTotais[Len(aSubTotais),13,2] 	+= aVetorMapa[x,13,2]
				aSubTotais[Len(aSubTotais),14] 	+= IIf(aVetorMapa[x,12] > 0 , 1 , 0 )
				aSubTotais[Len(aSubTotais),15]	+= aVetorMapa[x,15]
				aSubTotais[Len(aSubTotais),16]	+= aVetorMapa[x,16]
				aSubTotais[Len(aSubTotais),17]	+= aVetorMapa[x,17]
			Endif
		Endif
		
		aTotal[3,1]	+= aVetorMapa[x,3,1]
		aTotal[3,2]	+= aVetorMapa[x,3,2]
		aTotal[6,1]	+= aVetorMapa[x,6,1]
		aTotal[6,2]	+= aVetorMapa[x,6,2]
		aTotal[7,1]	+= aVetorMapa[x,7,1]
		aTotal[7,2]	+= aVetorMapa[x,7,2]
		aTotal[8,1]	+= aVetorMapa[x,8,1]
		aTotal[8,2]	+= aVetorMapa[x,8,2]
		aTotal[9,1]	+= aVetorMapa[x,9,1]
		aTotal[9,2]	+= aVetorMapa[x,9,2]
		aTotal[10]	+= aVetorMapa[x,10]
		aTotal[11,1]	+= aVetorMapa[x,11,1]
		aTotal[11,2]	+= aVetorMapa[x,11,2]
		aTotal[12]	+= aVetorMapa[x,12]
		aTotal[13,1]	+= aVetorMapa[x,13,1]
		aTotal[13,2]	+= aVetorMapa[x,13,2]
		aTotal[14]	+= IIf(aVetorMapa[x,12] > 0 , 1 , 0 )
		aTotal[15]	+= aVetorMapa[x,15]
		aTotal[16]	+= aVetorMapa[x,16]
		aTotal[17]	+= aVetorMapa[x,17]
		
		AAdd((oHtml:ValByName("l.vend" ))	,  aVetorMapa[x,1]+"-"+aVetorMapa[x,5])
		AAdd((oHtml:ValByName("l.vl_met" ))	,  Transform(aVetorMapa[x,3,1],"@E 999,999,999"))
		AAdd((oHtml:ValByName("l.lt_met" ))	,  Transform(aVetorMapa[x,3,2],"@E 999,999,999"))
		AAdd((oHtml:ValByName("l.vl_ven" ))	,  Transform(aVetorMapa[x,6,1],"@E 999,999,999"))
		AAdd((oHtml:ValByName("l.lt_ven" ))	,  Transform(aVetorMapa[x,6,2],"@E 999,999,999"))
		AAdd((oHtml:ValByName("l.vl_eli" ))	,  Transform(aVetorMapa[x,7,1],"@E 999,999,999"))
		AAdd((oHtml:ValByName("l.lt_eli" ))	,  Transform(aVetorMapa[x,7,2],"@E 999,999,999"))
		AAdd((oHtml:ValByName("l.vl_pen" ))	,  Transform(aVetorMapa[x,8,1],"@E 999,999,999"))
		AAdd((oHtml:ValByName("l.lt_pen" ))	,  Transform(aVetorMapa[x,8,2],"@E 999,999,999"))
		AAdd((oHtml:ValByName("l.vl_fat" ))	,  Transform(aVetorMapa[x,9,1],"@E 999,999,999"))
		AAdd((oHtml:ValByName("l.lt_fat" ))	,  Transform(aVetorMapa[x,9,2],"@E 999,999,999"))
		AAdd((oHtml:ValByName("l.vl_pmt" ))	,  Transform(aVetorMapa[x,9,1]/aVetorMapa[x,3,1]*100,"@E 999.99"))
		AAdd((oHtml:ValByName("l.lt_pmt" ))	,  Transform(aVetorMapa[x,9,2]/aVetorMapa[x,3,2]*100,"@E 999.99"))
		AAdd((oHtml:ValByName("l.cli" ))	,  Transform(aVetorMapa[x,10],"@E 9,999"))
		AAdd((oHtml:ValByName("l.vl_dev" ))	,  Transform(aVetorMapa[x,11,1],"@E 999,999,999"))
		AAdd((oHtml:ValByName("l.lt_dev" ))	,  Transform(aVetorMapa[x,11,2],"@E 999,999,999"))
		AAdd((oHtml:ValByName("l.dev" ))	,  Transform(aVetorMapa[x,16],"@E 9,999"))
		AAdd((oHtml:ValByName("l.vl_liq" ))	,  Transform(aVetorMapa[x,9,1]-aVetorMapa[x,11,1],"@E 999,999,999.99"))
		AAdd((oHtml:ValByName("l.lt_liq" ))	,  Transform(aVetorMapa[x,9,2]-aVetorMapa[x,11,2],"@E 999,999,999"))
		AAdd((oHtml:ValByName("l.bon" ))	,  Transform(aVetorMapa[x,17],"@E 9,999,999.99"))
		AAdd((oHtml:ValByName("l.prazo" ))	,  Transform(aVetorMapa[x,12]/aVetorMapa[x,15],"@E 9,999"))
		
		nValMargem	:= aVetorMapa[x,9,1]-aVetorMapa[x,11,1]-aVetorMapa[x,13,1]
		nValMargem -= aVetorMapa[x,13,2]
		
		nPerMargem	:= nValMargem/(aVetorMapa[x,9,1]-aVetorMapa[x,11,1])*100
		
		AAdd((oHtml:ValByName("l.vmg" ))		,  Transform(nValMargem,"@E 999,999,999.99"))
		AAdd((oHtml:ValByName("l.pmg" ))		,  Transform(nPerMargem,"@E 999.99"))
		
		cFilMapa := aVetorMapa[x,2]
		
	Next
	
	If !Empty(cFilMapa)
		//Aadd((oHtml:ValByName("l.vend"   )) ,  "Total Gerente " + cFilMapa + "-" + Capital(Posicione("SA3",1,xFilial("SA3")+cFilMapa,"A3_NREDUZ"))+cInNomAux )
		AAdd((oHtml:ValByName("l.vend" ))		,  "Total Filial "+cFilMapa + aFilNomes[aScan(aFilNomes,{|x| x[1] == cFilMapa}),2]  )
		AAdd((oHtml:ValByName("l.vl_met" ))	,  Transform(aSubTotais[Len(aSubTotais),3,1],"@E 999,999,999"))
		AAdd((oHtml:ValByName("l.lt_met" ))	,  Transform(aSubTotais[Len(aSubTotais),3,2],"@E 999,999,999"))
		AAdd((oHtml:ValByName("l.vl_ven" ))	,  Transform(aSubTotais[Len(aSubTotais),6,1],"@E 999,999,999"))
		AAdd((oHtml:ValByName("l.lt_ven" ))	,  Transform(aSubTotais[Len(aSubTotais),6,2],"@E 999,999,999"))
		AAdd((oHtml:ValByName("l.vl_eli" ))	,  Transform(aSubTotais[Len(aSubTotais),7,1],"@E 999,999,999"))
		AAdd((oHtml:ValByName("l.lt_eli" ))	,  Transform(aSubTotais[Len(aSubTotais),7,2],"@E 999,999,999"))
		AAdd((oHtml:ValByName("l.vl_pen" ))	,  Transform(aSubTotais[Len(aSubTotais),8,1],"@E 999,999,999"))
		AAdd((oHtml:ValByName("l.lt_pen" ))	,  Transform(aSubTotais[Len(aSubTotais),8,2],"@E 999,999,999"))
		AAdd((oHtml:ValByName("l.vl_fat" ))	,  Transform(aSubTotais[Len(aSubTotais),9,1],"@E 999,999,999"))
		AAdd((oHtml:ValByName("l.lt_fat" ))	,  Transform(aSubTotais[Len(aSubTotais),9,2],"@E 999,999,999"))
		AAdd((oHtml:ValByName("l.vl_pmt" ))	,  Transform(aSubTotais[Len(aSubTotais),9,1]/aSubTotais[Len(aSubTotais),3,1]*100,"@E 999.99"))
		AAdd((oHtml:ValByName("l.lt_pmt" ))	,  Transform(aSubTotais[Len(aSubTotais),9,2]/aSubTotais[Len(aSubTotais),3,2]*100,"@E 999.99"))
		AAdd((oHtml:ValByName("l.cli" ))	,  Transform(aSubTotais[Len(aSubTotais),10],"@E 9,999"))
		AAdd((oHtml:ValByName("l.vl_dev" ))	,  Transform(aSubTotais[Len(aSubTotais),11,1],"@E 999,999,999"))
		AAdd((oHtml:ValByName("l.lt_dev" ))	,  Transform(aSubTotais[Len(aSubTotais),11,2],"@E 999,999,999"))
		AAdd((oHtml:ValByName("l.dev" ))	,  Transform(aSubTotais[Len(aSubTotais),16],"@E 9,999"))
		AAdd((oHtml:ValByName("l.vl_liq"))	,  Transform(aSubTotais[Len(aSubTotais),9,1]-aSubTotais[Len(aSubTotais),11,1],"@E 999,999,999.99"))
		AAdd((oHtml:ValByName("l.lt_liq"))	,  Transform(aSubTotais[Len(aSubTotais),9,2]-aSubTotais[Len(aSubTotais),11,2],"@E 999,999,999"))
		AAdd((oHtml:ValByName("l.bon"))		,  Transform(aSubTotais[Len(aSubTotais),17],"@E 9,999,999.99"))
		AAdd((oHtml:ValByName("l.prazo" ))	,  Transform(aSubTotais[Len(aSubTotais),12]/aSubTotais[Len(aSubTotais),15],"@E 9,999"))
		
		
		nValMargem	:= aSubTotais[Len(aSubTotais),9,1]-aSubTotais[Len(aSubTotais),11,1]-aSubTotais[Len(aSubTotais),13,1]
		nValMargem -= aSubTotais[Len(aSubTotais),13,2]
		nPerMargem	:= nValMargem/(aSubTotais[Len(aSubTotais),9,1]-aSubTotais[Len(aSubTotais),11,1])*100
		
		AAdd((oHtml:ValByName("l.vmg" ))		,  Transform(nValMargem,"@E 999,999,999.99"))
		AAdd((oHtml:ValByName("l.pmg" ))		,  Transform(nPerMargem,"@E 999.99"))
	Endif
	
	AAdd((oHtml:ValByName("l.vend" ))	,  aTotal[1])
	AAdd((oHtml:ValByName("l.vl_met" ))	,  Transform(aTotal[3,1],"@E 999,999,999"))
	AAdd((oHtml:ValByName("l.lt_met" ))	,  Transform(aTotal[3,2],"@E 999,999,999"))
	AAdd((oHtml:ValByName("l.vl_ven" ))	,  Transform(aTotal[6,1],"@E 999,999,999"))
	AAdd((oHtml:ValByName("l.lt_ven" ))	,  Transform(aTotal[6,2],"@E 999,999,999"))
	AAdd((oHtml:ValByName("l.vl_eli" ))	,  Transform(aTotal[7,1],"@E 999,999,999"))
	AAdd((oHtml:ValByName("l.lt_eli" ))	,  Transform(aTotal[7,2],"@E 999,999,999"))
	AAdd((oHtml:ValByName("l.vl_pen" ))	,  Transform(aTotal[8,1],"@E 999,999,999"))
	AAdd((oHtml:ValByName("l.lt_pen" ))	,  Transform(aTotal[8,2],"@E 999,999,999"))
	AAdd((oHtml:ValByName("l.vl_fat" ))	,  Transform(aTotal[9,1],"@E 999,999,999"))
	AAdd((oHtml:ValByName("l.lt_fat" ))	,  Transform(aTotal[9,2],"@E 999,999,999"))
	AAdd((oHtml:ValByName("l.vl_pmt" ))	,  Transform(aTotal[9,1]/aTotal[3,1]*100,"@E 999.99"))
	AAdd((oHtml:ValByName("l.lt_pmt" ))	,  Transform(aTotal[9,2]/aTotal[3,2]*100,"@E 999.99"))
	AAdd((oHtml:ValByName("l.cli" ))	,  Transform(aTotal[10],"@E 9,999"))
	AAdd((oHtml:ValByName("l.vl_dev" ))	,  Transform(aTotal[11,1],"@E 999,999,999"))
	AAdd((oHtml:ValByName("l.lt_dev" ))	,  Transform(aTotal[11,2],"@E 999,999,999"))
	AAdd((oHtml:ValByName("l.dev" ))	,  Transform(aTotal[16],"@E 9,999"))
	AAdd((oHtml:ValByName("l.vl_liq"))	,  Transform(aTotal[9,1]-aTotal[11,1],"@E 999,999,999.99"))
	AAdd((oHtml:ValByName("l.lt_liq"))	,  Transform(aTotal[9,2]-aTotal[11,2],"@E 999,999,999"))
	AAdd((oHtml:ValByName("l.bon"))		,  Transform(aTotal[17],"@E 9,999,999.99"))
	AAdd((oHtml:ValByName("l.prazo" ))	,  Transform(aTotal[12]/aTotal[15],"@E 9,999"))
		
	nValMargem	:= aTotal[9,1]-aTotal[11,1]-aTotal[13,1]
	nValMargem -= aTotal[13,2]
		
	nPerMargem	:= nValMargem/(aTotal[9,1]-aTotal[11,1])*100
	AAdd((oHtml:ValByName("l.vmg" ))	,  Transform(nValMargem,"@E 999,999,999.99"))
	AAdd((oHtml:ValByName("l.pmg" ))	,  Transform(nPerMargem,"@E 999.99"))
	
	
	
	
	oProcess:ClientName(Substr(cUsuario,7,15))
	//oProcess:cTo := "informatica1@atrialub.com.br"
	oProcess:cTo := U_BFFATM15(cSendMail+";jonathan@atrialub.com.br;mauricio@atrialub.com.br;leandro@atrialub.com.br;big@atrialub.com.br;daniel@atrialub.com.br;karina@atrialub.com.br;","BFFATW19")
	oProcess:Start()
	oProcess:Finish()

	// Força disparo dos e-mails pendentes do workflow
	WFSENDMAIL()
Return


/*/{Protheus.doc} sfMetas
(Monta vetor para dados de Metas)

@author MarceloLauschner
@since 16/07/2015
@version 1.0

@return Sem Retorno

@example
(examples)

@see (links_or_references)
/*/
Static Function sfMetas(aInVend)
	
	Local	cQry
	Local	iZ 
	// CT_VALOR		Valor Texaco
	// CT_VALWY		Valor Wynns
	// CT_VALKR		Valor Michelin
	// CT_VALAGRE 	Valor Filtro
	cQry := ""
	cQry += "SELECT SUM(CT_VALOR+CT_MTESP02) META,"
	cQry += "       SUM(CT_QUANT) LITROS,"
	cQry += "       A3_GEREN,"
	cQry += "       A3_COD,"
	cQry += "       A3_NREDUZ,"
	cQry += "       CT_FILIAL "
	cQry += "  FROM "+RetSqlName("SCT") + " CT, "+ RetSqlName("SA3") + " A3 "
	cQry += "WHERE A3.D_E_L_E_T_ = ' ' "
	If Len(aInVend) > 0
		cQry += "   AND A3_COD IN("
		For iZ := 1 To Len(aInVend)
			If iZ > 1
				cQry += ","
			Endif
			cQry += "'" + aInVend[iZ,1] + "'"
		Next
		cQry += ")"
	Endif
	cQry += "  AND A3_COD = CT_VEND "
	cQry += "  AND A3_FILIAL = '"+xFilial("SA3")+"' "
	cQry += "  AND CT_REGIAO <> ' ' "
	cQry += "  AND CT_QUANT > 1 "
	cQry += "  AND (CT_MTESP02 > 1 OR CT_VALOR > 1 ) "
	cQry += "  AND CT.D_E_L_E_T_ = ' ' "
	cQry += "  AND CT_DATA BETWEEN '" + DTOS(dDataIni) + "' AND '" + DTOS(dDataBase) + "' "
	cQry += "  AND CT_FILIAL IN "+FormatIN(GetMv("BF_FILIAIS"),"/")
	cQry += "GROUP BY A3_COD,A3_NREDUZ,A3_GEREN,CT_FILIAL "
	cQry += "ORDER BY A3_COD "
	
	
	dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQry),'QRA', .F., .T.)
	While !Eof()
		nPos := aScan(aVetorMapa,{|x| x[1]+x[4] == QRA->A3_COD+QRA->A3_GEREN })
		If nPos == 0
			Aadd(aVetorMapa,{;
				QRA->A3_COD,;				//	1 - Código Vendedor
			QRA->CT_FILIAL,;				// 	2 - Filial
			{QRA->META,QRA->LITROS},;		// 	3 - Meta
			QRA->A3_GEREN,;					//	4 - Gerente
			QRA->A3_NREDUZ,;				// 	5 - Nome Reduzido
			{0,0},;							// 	6 - Vendido
			{0,0},;							// 	7 - Eliminado
			{0,0},;							// 	8 - Pendente
			{0,0},;							//	9 - Faturado
			0,;								// 	10- Clientes
			{0,0},;							//	11- Devolvido
			0,;								//	12- Prazo Médio
			{0,0},;							// 	13- Margem
			++nContAdd,;					//	14
			0,;								// 	15- Duplicata
			0,;								// 	16- Num.Devoluções
			0})								// 	17- Bonificações
		Else
			aVetorMapa[nPos,3,1] += QRA->META
			aVetorMapa[nPos,3,2] += QRA->LITROS
		Endif
		Dbselectarea("QRA")
		Dbskip()
	Enddo
	IncProc("Metas ok")
	QRA->(dbCLoseArea())
	
Return


/*/{Protheus.doc} sfVendido
(Monta vetor com dados de Vendido e Eliminado Residuo)

@author MarceloLauschner
@since 16/07/2015
@version 1.0

@return Sem retorno

@example
(examples)

@see (links_or_references)
/*/
Static Function sfVendido(aInVend)
	
	Local	cQry
	Local	iZ
	
	cQry := ""
	cQry += "SELECT SUM(C6_VALOR) AS VENDA, "
	cQry += "       SUM(C6_QTDVEN * B1_QTELITS) LITROS,"
	cQry += "       SUM(CASE WHEN C6_BLQ = 'R' THEN (C6_QTDVEN-C6_QTDENT)*C6_PRCVEN ELSE 0 END) RESIDUO,"
	cQry += "       SUM(CASE WHEN C6_BLQ = 'R' THEN (C6_QTDVEN-C6_QTDENT)*B1_QTELITS ELSE 0 END) RESIDUO_LTS,"
	cQry += "		  C5_VEND1,"
	cQry += "       A3_GEREN,"
	cQry += "       A3_NREDUZ,"
	cQry += "       C5_FILIAL"
	cQry += "  FROM "+ RetSqlName("SC5") + " C5,"+RetSqlName("SC6")+" C6,"+RetSqlName("SF4")+" F4,"+RetSqlName("SB1")+" B1,"+RetSqlName("SA3")+" A3 "
	cQry += " WHERE A3.D_E_L_E_T_ = ' ' "
	cQry += "   AND A3_MSBLQL != '1' "
	If Len(aInVend) > 0
		cQry += "   AND A3_COD IN("
		For iZ := 1 To Len(aInVend)
			If iZ > 1
				cQry += ","
			Endif
			cQry += "'" + aInVend[iZ,1] + "'"
		Next
		cQry += ")"
	Endif
	cQry += "   AND A3_COD = C5_VEND1 "
	cQry += "   AND A3_FILIAL = '"+xFilial("SA3")+"' "
	cQry += "   AND B1_PROC = '000468' "
	cQry += "   AND B1.D_E_L_E_T_ = ' ' "
	cQry += "   AND B1_COD = C6_PRODUTO "
	cQry += "   AND B1_FILIAL = C5_FILIAL "
	cQry += "   AND F4_DUPLIC = 'S' "
	cQry += "   AND F4.D_E_L_E_T_ = ' ' "
	cQry += "   AND F4_CODIGO = C6_TES "
	cQry += "   AND F4_FILIAL = C5_FILIAL "
	cQry += "   AND C6.D_E_L_E_T_ = ' ' "
	cQry += "   AND C6_NUM = C5_NUM "
	cQry += "   AND C6_FILIAL = C5_FILIAL  "
	cQry += "   AND C5.D_E_L_E_T_ = ' ' "
	cQry += "   AND C5_EMISSAO BETWEEN '" + DTOS(dDataIni) + "' AND '" + DTOS(dDataBase) + "' "
	cQry += "   AND C5_FILIAL IN "+FormatIN(GetMv("BF_FILIAIS"),"/")
	cQry += " GROUP BY C5_FILIAL,C5_VEND1,A3_NREDUZ,A3_GEREN "
	
	
	dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQry),'QRB', .F., .T.)
	While !Eof()
		nPos := aScan(aVetorMapa,{|x| x[1]+x[4] == QRB->C5_VEND1+QRB->A3_GEREN })
		If nPos == 0
			Aadd(aVetorMapa,{;
				QRB->C5_VEND1,;			//	1 - Código Vendedor
			QRB->C5_FILIAL,;			// 	2 - Filial
			{0,0},;						// 	3 - Meta
			QRB->A3_GEREN,;				//	4 - Gerente
			QRB->A3_NREDUZ,;			// 	5 - Nome Reduzido
			{QRB->VENDA,QRB->LITROS},;	// 	6 - Vendido
			{QRB->RESIDUO,QRB->RESIDUO_LTS},;// 	7 - Eliminado
			{0,0},;						// 	8 - Pendente
			{0,0},;						//	9 - Faturado
			0,;							// 	10- Clientes
			{0,0},;						//	11- Devolvido
			0,;							//	12- Prazo Médio
			{0,0},;						// 	13- Margem
			++nContAdd,;				//	14
			0,;							// 	15- Duplictas
			0,;							// 	16- Num.Devoluções
			0})							// 	17- Bonificações
		Else
			aVetorMapa[nPos,6,1] += QRB->VENDA
			aVetorMapa[nPos,7,1] += QRB->RESIDUO
			aVetorMapa[nPos,6,2] += QRB->LITROS
			aVetorMapa[nPos,7,2] += QRB->RESIDUO_LTS
		Endif
		Dbselectarea("QRB")
		Dbskip()
	Enddo
	QRB->(dbCLoseArea())
	IncProc("Vendas ok")
Return


/*/{Protheus.doc} sfPendente
(long_description)

@author MarceloLauschner
@since 16/07/2015
@version 1.0

@return Sem retorno

@example
(examples)

@see (links_or_references)
/*/
Static Function sfPendente(aInVend)
	
	Local	cQry
	Local	iZ 
	
	cQry := ""
	cQry += "SELECT SUM(CASE WHEN C6_BLQ != 'R' THEN (C6_QTDVEN-C6_QTDENT)*C6_PRCVEN ELSE 0 END) PENDENTE,"
	cQry += "       SUM(CASE WHEN C6_BLQ != 'R' THEN (C6_QTDVEN-C6_QTDENT)*B1_QTELITS ELSE 0 END) LITROS,""
	cQry += "		  C5_VEND1,"
	cQry += "       A3_GEREN,"
	cQry += "       A3_NREDUZ,"
	cQry += "       C5_FILIAL"
	cQry += "  FROM "+ RetSqlName("SC5") + " C5,"+RetSqlName("SC6")+" C6,"+RetSqlName("SF4")+" F4,"+RetSqlName("SB1")+" B1,"+RetSqlName("SA3")+" A3 "
	cQry += " WHERE A3.D_E_L_E_T_ = ' ' "
	If Len(aInVend) > 0
		cQry += "   AND A3_COD IN("
		For iZ := 1 To Len(aInVend)
			If iZ > 1
				cQry += ","
			Endif
			cQry += "'" + aInVend[iZ,1] + "'"
		Next
		cQry += ")"
	Endif
	cQry += "   AND A3_MSBLQL != '1' "
	cQry += "   AND A3_COD = C5_VEND1 "
	cQry += "   AND A3_FILIAL = '"+xFilial("SA3")+"' "
	cQry += "   AND B1.D_E_L_E_T_ = ' ' "
	cQry += "   AND B1_PROC = '000468' "
	cQry += "   AND B1_COD = C6_PRODUTO "
	cQry += "   AND B1_FILIAL = C5_FILIAL "
	cQry += "   AND F4_DUPLIC = 'S' "
	cQry += "   AND F4.D_E_L_E_T_ = ' ' "
	cQry += "   AND F4_CODIGO = C6_TES "
	cQry += "   AND F4_FILIAL = C5_FILIAL "
	cQry += "   AND C6.D_E_L_E_T_ = ' ' "
	cQry += "   AND C6_NUM = C5_NUM "
	cQry += "   AND C6_FILIAL = C5_FILIAL  "
	cQry += "   AND C5.D_E_L_E_T_ = ' ' "
	cQry += "   AND C5_EMISSAO BETWEEN '" + DTOS(dDataIni-120) + "' AND '" + DTOS(dDataBase) + "' "
	cQry += "   AND C5_FILIAL IN "+FormatIN(GetMv("BF_FILIAIS"),"/")
	cQry += " GROUP BY C5_FILIAL,C5_VEND1,A3_NREDUZ,A3_GEREN "
	cQry += "HAVING SUM(CASE "
	cQry += "            WHEN C6_BLQ != 'R' THEN "
	cQry += "              (C6_QTDVEN - C6_QTDENT) * C6_PRCVEN "
	cQry += "            ELSE "
	cQry += "              0 "
	cQry += "           END) > 0 "
	
	
	dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQry),'QRB', .F., .T.)
	While !Eof()
		nPos := aScan(aVetorMapa,{|x| x[1]+x[4] == QRB->C5_VEND1+QRB->A3_GEREN })
		If nPos == 0
			Aadd(aVetorMapa,{;
				QRB->C5_VEND1,;				//	1 - Código Vendedor
			QRB->C5_FILIAL,;				// 	2 - Filial
			{0,0},;							// 	3 - Meta
			QRB->A3_GEREN,;					//	4 - Gerente
			QRB->A3_NREDUZ,;				// 	5 - Nome Reduzido
			{0,0},;							// 	6 - Vendido
			{0,0},;							// 	7 - Eliminado
			{QRB->PENDENTE,QRB->LITROS},;	// 	8 - Pendente
			{0,0},;							//	9 - Faturado
			0,;								// 	10- Clientes
			{0,0},;							//	11- Devolvido
			0,;								//	12- Prazo Médio
			{0,0},;							// 	13- Margem
			++nContAdd,;					// 	14
			0,;								//	15- Duplicatas
			0,;								// 	16- Num.Devoluções
			0})								// 	17- Bonificações
		Else
			aVetorMapa[nPos,8,1] += QRB->PENDENTE
			aVetorMapa[nPos,8,2] += QRB->LITROS
		Endif
		Dbselectarea("QRB")
		Dbskip()
	Enddo
	QRB->(dbCLoseArea())
	IncProc("Pendências ok")
Return

/*/{Protheus.doc} sfFaturado
(Obtém os dados de faturamento)
@author MarceloLauschner
@since 16/07/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfFaturado(aInVend)
	
	Local	cQry
	Local	iZ
	
	cQry := ""
	cQry += "SELECT SUM(D2_VALBRUT) FATURADO,"
	cQry += "       SUM(BONIFICADO) BONIFICACAO,"
	cQry += "       SUM(D2_QUANT*B1_QTELITS) LITROS,"
	cQry += "       COUNT(DISTINCT(D2_CLIENTE||D2_LOJA)) CLIENTES , "
	cQry += "       SUM(D2_CUSTO + D2_VALICM + D2_ICMSCOM + D2_DIFAL + D2_VALPROM + D2_VALIMP5 + D2_VALIMP6) CUSTO, "
	cQry += "       SUM(D2_VALBRUT*B1_PRMINFO/100) B1_PRMINFO,"
	cQry += "       F2_VEND1,"
	cQry += "       D2_FILIAL,"
	cQry += "       A3_GEREN,"
	cQry += "       A3_NREDUZ"
	cQry += "   FROM( "
	cQry += "        SELECT DECODE(F4_DUPLIC,'S',D2_VALBRUT,0) D2_VALBRUT,DECODE(F4_DUPLIC,'S',0,D2_VALBRUT) BONIFICADO,"
	cQry += "               D2_CLIENTE,D2_LOJA,D2_VALICM,D2_ICMSCOM,D2_DIFAL,D2_VALPROM,D2_VALIMP5,D2_VALIMP6,B1_PRMINFO,B1_QTELITS,D2_QUANT,"
	cQry += "               F2_VEND1,D2_FILIAL,A3_GEREN,A3_NREDUZ,"
	cQry += "               D2_CUSTO1 D2_CUSTO "
	// Comentado em 21/07/2015 a pedido de Daniel, pois o WF deve ser calculado pelo custo médio real.
	//cQry += "               BF_RET_CUSTO_SD2_REP(D2_PEDIDO,D2_ITEMPV,D2_COD,D2_FILIAL,D2_CUSTO1/D2_QUANT)* D2_QUANT D2_CUSTO "
	cQry += "  FROM "+RetSqlName("SD2")+" D2,"+RetSqlName("SF2")+" F2,"+RetSqlName("SF4")+" F4,"+RetSqlName("SB1")+" B1, "
	cQry +=           RetSqlName("SA1")+" A1,"+RetSqlName("SA3")+" A3 "
	cQry += " WHERE A3.D_E_L_E_T_ = ' ' "
	If Len(aInVend) > 0
		cQry += "   AND A3_COD IN("
		For iZ := 1 To Len(aInVend)
			If iZ > 1
				cQry += ","
			Endif
			cQry += "'" + aInVend[iZ,1] + "'"
		Next
		cQry += ")"
	Endif
	cQry += "   AND A3_MSBLQL != '1' "
	cQry += "   AND A3_COD = F2_VEND1 "
	cQry += "   AND A3_FILIAL = '"+xFilial("SA3")+"' "
	cQry += "   AND A1.D_E_L_E_T_ = ' ' "
	cQry += "   AND A1_LOJA = D2_LOJA "
	cQry += "   AND A1_COD = D2_CLIENTE "
	cQry += "   AND A1_FILIAL = '"+xFilial("SA1")+"' "
	cQry += "   AND B1.D_E_L_E_T_ = ' ' "
	cQry += "   AND B1_PROC = '000468' "
	cQry += "   AND B1_COD = D2_COD "
	cQry += "   AND B1_FILIAL = D2_FILIAL "
	cQry += "   AND F4_XTPMOV NOT IN('BA','VS','TF','RT','TA','RC','RA','SP','TE')"
	cQry += "   AND F4_ESTOQUE = 'S' "
	cQry += "   AND F4.D_E_L_E_T_ = ' ' "
	cQry += "   AND F4_CODIGO = D2_TES "
	cQry += "   AND F4_FILIAL = D2_FILIAL  "
	cQry += "   AND F2.D_E_L_E_T_ = ' ' "
	cQry += "   AND F2_SERIE =  D2_SERIE "
	cQry += "   AND F2_DOC = D2_DOC "
	cQry += "   AND F2_LOJA = D2_LOJA "
	cQry += "   AND F2_CLIENTE = D2_CLIENTE "
	cQry += "   AND F2_FILIAL = D2_FILIAL  "
	cQry += "   AND D2.D_E_L_E_T_ = ' ' "
	cQry += "   AND D2_TIPO = 'N' "
	cQry += "   AND D2_EMISSAO BETWEEN '" + DTOS(dDataIni) + "' AND '" + DTOS(dDataBase) + "' "
	cQry += "   AND D2_FILIAL IN "+FormatIN(GetMv("BF_FILIAIS"),"/") + " )"
	cQry += "GROUP BY D2_FILIAL,F2_VEND1,A3_GEREN,A3_NREDUZ"
	
	
	MemoWrite("/log_sqls/bffatw19_fat.sql",cQry )
	
	dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQry),'QRE', .F., .T.)
	While !Eof()
		nPos := aScan(aVetorMapa,{|x| x[1]+x[4] == QRE->F2_VEND1+QRE->A3_GEREN })
		If nPos == 0
			Aadd(aVetorMapa,{;
				QRE->F2_VEND1,;				//	1 - Código Vendedor
			QRE->D2_FILIAL,;				// 	2 - Filial
			{0,0},;							// 	3 - Meta
			QRE->A3_GEREN,;					//	4 - Gerente
			QRE->A3_NREDUZ,;				// 	5 - Nome Reduzido
			{0,0},;							// 	6 - Vendido
			{0,0},;							// 	7 - Eliminado
			{0,0},;							// 	8 - Pendente
			{QRE->FATURADO,QRE->LITROS},;	//	9 - Faturado
			QRE->CLIENTES,;					// 	10- Clientes
			{0,0},;							//	11- Devolvido
			0,;								//	12- Prazo Médio
			{QRE->CUSTO,QRE->B1_PRMINFO},;	// 	13- Margem
			++nContAdd,;					//	14
			0,;								//	15-
			0,;								// 	16- Num.Devoluções
			QRE->BONIFICACAO})				//	17- Bonificações
		Else
			aVetorMapa[nPos,9,1] += QRE->FATURADO
			aVetorMapa[nPos,9,2] += QRE->LITROS
			aVetorMapa[nPos,10] += QRE->CLIENTES
			aVetorMapa[nPos,13,1] += QRE->CUSTO
			aVetorMapa[nPos,13,2] += QRE->B1_PRMINFO
			aVetorMapa[nPos,17] += QRE->BONIFICACAO
		Endif
		
		Dbselectarea("QRE")
		Dbskip()
	Enddo
	
	QRE->(dbClosearea())
	IncProc("Faturamento ok")
	
Return



/*/{Protheus.doc} sfPrazo
(Calcula o prazo médio )
@author MarceloLauschner
@since 16/07/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfPrazo(aInVend)
	
	Local	cQry
	Local	iZ
	
	cQry := "SELECT SUM(PRAZO) PRAZO,SUM(E1_VALOR) DUPLICATAS,F2_VEND1,D2_FILIAL,A3_GEREN,A3_NREDUZ "
	cQry += "  FROM ( "
	cQry += "SELECT ROUND((TO_DATE(E1_VENCREA,'YYYYMMDD')-TO_DATE(E1_EMISSAO,'YYYYMMDD'))*E1_VALOR,2) PRAZO, "
	cQry += "       E1_VALOR,"
	cQry += "       F2_VEND1,"
	cQry += "       D2_FILIAL,"
	cQry += "       A3_GEREN,"
	cQry += "       A3_NREDUZ"
	cQry += "  FROM "+RetSqlName("SD2")+" D2,"+RetSqlName("SF2")+" F2,"+RetSqlName("SF4")+" F4,"+RetSqlName("SB1")+" B1, "
	cQry +=           RetSqlName("SA1")+" A1,"+RetSqlName("SA3")+" A3, " + RetSqlName("SE1") + " E1 "
	cQry += " WHERE A3.D_E_L_E_T_ = ' ' "
	If Len(aInVend) > 0
		cQry += "   AND A3_COD IN("
		For iZ := 1 To Len(aInVend)
			If iZ > 1
				cQry += ","
			Endif
			cQry += "'" + aInVend[iZ,1] + "'"
		Next
		cQry += ")"
	Endif
	cQry += "   AND A3_MSBLQL != '1' "
	cQry += "   AND A3_COD = F2_VEND1 "
	cQry += "   AND A3_FILIAL = '"+xFilial("SA3")+"' "
	cQry += "   AND A1.D_E_L_E_T_ = ' ' "
	cQry += "   AND A1_LOJA = D2_LOJA "
	cQry += "   AND A1_COD = D2_CLIENTE "
	cQry += "   AND A1_FILIAL = '"+xFilial("SA1")+"' "
	cQry += "   AND E1.D_E_L_E_T_ =' ' "
	cQry += "   AND E1_NUM = F2_DUPL "
	cQry += "   AND E1_PREFIXO = F2_PREFIXO "
	cQry += "   AND E1_FILIAL = '"+xFilial("SE1") + "' "
	cQry += "   AND B1.D_E_L_E_T_ = ' ' "
	cQry += "   AND B1_PROC = '000468' "
	cQry += "   AND B1_COD = D2_COD "
	cQry += "   AND B1_FILIAL = D2_FILIAL "
	cQry += "   AND F4_ESTOQUE = 'S' "
	cQry += "   AND F4_DUPLIC = 'S' "
	cQry += "   AND F4.D_E_L_E_T_ = ' ' "
	cQry += "   AND F4_CODIGO = D2_TES "
	cQry += "   AND F4_FILIAL = D2_FILIAL  "
	cQry += "   AND F2.D_E_L_E_T_ = ' ' "
	cQry += "   AND F2_SERIE =  D2_SERIE "
	cQry += "   AND F2_DOC = D2_DOC "
	cQry += "   AND F2_LOJA = D2_LOJA "
	cQry += "   AND F2_CLIENTE = D2_CLIENTE "
	cQry += "   AND F2_FILIAL = D2_FILIAL  "
	cQry += "   AND D2.D_E_L_E_T_ = ' ' "
	cQry += "   AND D2_EMISSAO BETWEEN '" + DTOS(dDataIni) + "' AND '" + DTOS(dDataBase) + "' "
	cQry += "   AND D2_FILIAL IN "+FormatIN(GetMv("BF_FILIAIS"),"/")
	cQry += "GROUP BY E1_PREFIXO,E1_NUM,E1_PARCELA,F2_VEND1,D2_FILIAL,A3_GEREN,A3_NREDUZ,E1_VALOR,E1_EMISSAO,E1_VENCREA) "
	cQry += "GROUP BY D2_FILIAL,F2_VEND1,A3_GEREN,A3_NREDUZ"
	
	
	dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQry),'QRE', .F., .T.)
	While !Eof()
		nPos := aScan(aVetorMapa,{|x| x[1]+x[4] == QRE->F2_VEND1+QRE->A3_GEREN })
		If nPos == 0
			Aadd(aVetorMapa,{;
				QRE->F2_VEND1,;				//	1 - Código Vendedor
			QRE->D2_FILIAL,;				// 	2 - Filial
			{0,0},;							// 	3 - Meta
			QRE->A3_GEREN,;					//	4 - Gerente
			QRE->A3_NREDUZ,;				// 	5 - Nome Reduzido
			{0,0},;							// 	6 - Vendido
			{0,0},;							// 	7 - Eliminado
			{0,0},;							// 	8 - Pendente
			{0,0},;							//	9 - Faturado
			0,;								// 	10- Clientes
			{0,0},;							//	11- Devolvido
			QRE->PRAZO,;					//	12- Prazo Médio
			{0,0},;							// 	13- Margem
			++nContAdd,;					//	14
			QRE->DUPLICATAS,;				//	15-
			0,;								// 	16- Num.Devoluções
			0})								// 	17- Bonificações
			
		Else
			aVetorMapa[nPos,12] += QRE->PRAZO
			aVetorMapa[nPos,15] += QRE->DUPLICATAS
		Endif
		
		Dbselectarea("QRE")
		Dbskip()
	Enddo
	
	QRE->(dbClosearea())
	IncProc("Faturamento ok")
	
Return


/*/{Protheus.doc} sfDevolvido
(Calcula valor das devoluções)
@author MarceloLauschner
@since 16/07/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfDevolvido(aInVend)
	
	Local	cQry
	Local	iZ
	
	cQry := ""
	cQry += "SELECT SUM(DECODE(F4_DUPLIC,'S',(D1_TOTAL - D1_VALDESC + D1_VALIPI + D1_ICMSRET),0)) DEVOLVIDO, "
	cQry += "       SUM(D1_QUANT*B1_QTELITS) LITROS,"
	cQry += "       SUM(((D2_CUSTO + D2_VALICM + D2_ICMSCOM + D2_DIFAL + D2_VALPROM + D2_VALIMP5 + D2_VALIMP6 ) / D2_QUANT) * D1_QUANT) CUSTO, "
	cQry += "       SUM(((DECODE(F4_DUPLIC,'S',D2_VALBRUT,0) * B1_PRMINFO / 100) / D2_QUANT) * D1_QUANT) B1_PRMINFO, "
	cQry += "		  COUNT(DISTINCT(D1_DOC||D1_SERIE)) AS NDEV,"
	cQry += "       F2_VEND1,"
	cQry += "       D1_FILIAL,"
	cQry += "       A3_GEREN,"
	cQry += "       A3_NREDUZ "
	cQry += "   FROM( "
	cQry += "        SELECT D1_TOTAL,D1_VALDESC,D1_VALIPI,D1_ICMSRET,D1_QUANT,D2_QUANT,D2_VALBRUT,"
	cQry += "               D1_DOC,D1_SERIE,D2_VALICM,D2_ICMSCOM,D2_DIFAL,D2_VALPROM,D2_VALIMP5,D2_VALIMP6,B1_PRMINFO,"
	cQry += "               F2_VEND1,D1_FILIAL,A3_GEREN,A3_NREDUZ,F4_DUPLIC,B1_QTELITS,"
	cQry += "               D2_CUSTO1 D2_CUSTO "
	// Comentado em 21/07/2015 a pedido de Daniel, pois o WF deve ser calculado pelo custo médio real.
	//cQry += "               BF_RET_CUSTO_SD2_REP(D2_PEDIDO,D2_ITEMPV,D2_COD,D2_FILIAL,D2_CUSTO1/D2_QUANT)* D2_QUANT D2_CUSTO "
	cQry += "  FROM "+RetSqlName("SD1")+" D1,"+RetSqlName("SF4")+" F4,"+RetSqlName("SF2")+" F2,"+RetSqlName("SB1")+" B1,"+RetSqlName("SA3")+" A3, "
	cQry +=           RetSqlName("SD2")+" D2 "
	cQry += " WHERE A3.D_E_L_E_T_ = ' ' "
	If Len(aInVend) > 0
		cQry += "   AND A3_COD IN("
		For iZ := 1 To Len(aInVend)
			If iZ > 1
				cQry += ","
			Endif
			cQry += "'" + aInVend[iZ,1] + "'"
		Next
		cQry += ")"
	Endif
	cQry += "   AND A3_MSBLQL != '1' "
	cQry += "   AND A3_COD = F2_VEND1 "
	cQry += "   AND A3_FILIAL = '"+xFilial("SA3")+"'"
	cQry += "   AND B1.D_E_L_E_T_ = ' ' "
	cQry += "   AND B1_PROC = '000468' "
	cQry += "   AND B1_COD = D1_COD "
	cQry += "   AND B1_FILIAL = D1_FILIAL "
	cQry += "   AND F2.D_E_L_E_T_ = ' ' "
	cQry += "   AND F2_SERIE = D1_SERIORI "
	cQry += "   AND F2_DOC = D1_NFORI "
	cQry += "   AND F2_LOJA = D1_LOJA "
	cQry += "   AND F2_CLIENTE = D1_FORNECE "
	cQry += "   AND F2_FILIAL = D1_FILIAL  "
	cQry += "   AND F4_DUPLIC = 'S' "
	cQry += "   AND F4_XTPMOV NOT IN('BA','VS','TF','RT','TA','RC','RA') "
	cQry += "   AND F4_ESTOQUE = 'S' "
	cQry += "   AND F4.D_E_L_E_T_ = ' ' "
	cQry += "   AND F4_CODIGO = D2_TES "
	cQry += "   AND F4_FILIAL = D1_FILIAL  "
	cQry += "   AND D2.D_E_L_E_T_ =' ' "
	cQry += "   AND D2_ITEM = D1_ITEMORI "
	cQry += "   AND D2_SERIE = D1_SERIORI "
	cQry += "   AND D2_DOC = D1_NFORI "
	cQry += "   AND D2_LOJA = D1_LOJA "
	cQry += "   AND D2_CLIENTE = D1_FORNECE "
	cQry += "   AND D2_FILIAL = D1_FILIAL "
	cQry += "   AND D1_TIPO = 'D' "
	cQry += "   AND D1.D_E_L_E_T_ = ' ' "
	cQry += "   AND D1_DTDIGIT BETWEEN '" + DTOS(dDataIni) + "' AND '" + DTOS(dDataBase) + "' "
	cQry += "   AND D1_FILIAL IN "+FormatIN(GetMv("BF_FILIAIS"),"/") + " )"
	cQry += " GROUP BY D1_FILIAL,F2_VEND1,A3_GEREN,A3_NREDUZ"
	
	
	dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQrY),'QRF', .F., .T.)
	While !Eof()
		nPos := aScan(aVetorMapa,{|x| x[1]+x[4] == QRF->F2_VEND1+QRF->A3_GEREN })
		If nPos == 0
			Aadd(aVetorMapa,{;
				QRF->F2_VEND1,;				//	1 - Código Vendedor
			QRF->D1_FILIAL,;				// 	2 - Filial
			{0,0},;							// 	3 - Meta
			QRF->A3_GEREN,;					//	4 - Gerente
			QRF->A3_NREDUZ,;				// 	5 - Nome Reduzido
			{0,0},;							// 	6 - Vendido
			{0,0},;							// 	7 - Eliminado
			{0,0},;							// 	8 - Pendente
			{0,0},;							//	9 - Faturado
			0,;								// 	10- Clientes
			{QRF->DEVOLVIDO,QRF->LITROS},;	//	11- Devolvido
			0,;								//	12- Prazo Médio
			{QRF->CUSTO*-1,QRF->B1_PRMINFO*-1},;// 	13- Margem
			++nContAdd,;					//	14
			0,;								// 	15- Duplicatas
			0,;								// 	16- Num.Devoluções
			0})								// 	17- Bonificações
		Else
			aVetorMapa[nPos,11,1] += QRF->DEVOLVIDO
			aVetorMapa[nPos,11,2] += QRF->LITROS
			aVetorMapa[nPos,13,1] -= QRF->CUSTO
			aVetorMapa[nPos,13,2] -= QRF->B1_PRMINFO
			aVetorMapa[nPos,16] += QRF->NDEV
		Endif
		
		Dbselectarea("QRF")
		Dbskip()
	Enddo
	
	QRF->(dbClosearea())
	
	IncProc("Devolucao ok")
	
Return
