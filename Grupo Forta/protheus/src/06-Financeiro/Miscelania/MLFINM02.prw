#include 'rwmake.ch'
#include 'topconn.ch'



/*/{Protheus.doc} MLFINM02
//TODO Criador de Precisoes no Contas a Pagar por arquivo 
@author Rafael Meyer 
@since 26/01/09 
@version 1.0
@return ${return}, ${return_description}
@type function
/*/
User function MLFINM02()
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Declaracao de Variaveis                                             ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	Local	lContinua	:= .F. 
	Private cFileFluxo	:= cGetFile('*.txt',"Selecione o arquivo para importa o fluxo",1,'C:\edi\financeiro\',.F.,,.F.,.T.)
	Private nMesini := 0
	Private nMesfim := 0
	
	@ 200,001 TO 380,380 DIALOG oLeTxt TITLE OemToAnsi("Geração de Previsões")
	@ 002,010 TO 080,190
	@ 10,018 Say " Este programa ira ler o conteudo de um arquivo texto, conforme"
	@ 18,018 Say " os parametros definidos pelo usuario, com os registros do arquivo"
	@ 26,018 Say " de FATURA DA ALFA"
	@ 40,018 Say "Mes Ini"
	@ 40,070 Get nMesini Picture "@E 99" 
	@ 55,018 Say "Mes Fim"
	@ 55,070 Get nMesfim Picture "@E 99" Valid (nMesFim <=12 .And. nMesFim >= 1 .And. nMesFim >= nMesIni)
	
	@ 70,098 BMPBUTTON TYPE 01 ACTION (lContinua := .T.,Close(oLeTxt))
	@ 70,128 BMPBUTTON TYPE 02 ACTION Close(oLeTxt)
	
	Activate Dialog oLeTxt Centered
	
	If lContinua
		Processa({|| OkLeTxt() },"Processando...Aguarde...")
	Endif
	
Return


/*/{Protheus.doc} OkLeTxt
(long_description)
@author MarceloLauschner
@since 18/01/2016
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function OkLeTxt()
	
	Private lMsHelpAuto := .T.
	Private lMsErroAuto := .F.
	Private nJuros      := 0.00
	
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Abertura do arquivo texto                                           ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	
	
	
	aCampos:={}
	Aadd(aCampos,{ "LINHA" ,"C",200,0 })
	cNomArq := CriaTrab(aCampos)
	
	If (Select("TRB") <> 0)
		dbSelectArea("TRB")
		dbCloseArea("TRB")
	Endif
	
	dbUseArea(.T.,,cNomArq,"TRB",nil,.F.)
	
	If !File(Alltrim(cFileFluxo))
		MsgInfo("Arquivo texto nao existente.Programa cancelado","Informação")
		Return
	Endif
	
	dbSelectArea("TRB")
	
	Append From (Alltrim(cFileFluxo)) SDF
	
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Inicializa a regua de processamento                                 ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	
	Processa({|| RunCont() },"Processando...")
	
	TRB->(DbCloseArea())
	
	MsgInfo("Importação concluída!!","Informação")
	
Return



/*/{Protheus.doc} RunCont
(long_description)
@author MarceloLauschner
@since 18/01/2016
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function RunCont()
	
	Local	nRec	:= 0
	Local	nMeses	:= (nMesFim+1) - nMesIni
	Local	lGrvTit	:= .T.
	Private lMsHelpAuto := .T.
	Private lMsErroAuto := .F.
	
	dbSelectArea("TRB")
	Count To nRec
	nRec += nMeses
	
	ProcRegua(nRec) // Numero de registros a processar
	
	dbSelectArea("TRB")
	dbGoTop()
	While !Eof()
		
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Incrementa a regua                                                  ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		
		nMes := nMesIni
		
		For iX:= 1 To nMeses
			
			
			
			nNumtit := StrZero(nMes,2)+StrZero(Year(dDatabase),4)
			
			IncProc("Registro: " + Substr(TRB->LINHA,01,10))
			
			
			If nMes > 12
				MsgAlert("Ultrapassou o Ano corrente. Refaça o arquivo","Atencao!")
				lGrvTit	:= .F.
			Else
				cNumtit := nNumtit
			Endif
			
			dVencto := Ctod(Substr(TRB->LINHA,66,2)+ "/"+ Strzero(nMes,2)+ "/" + Substr(TRB->LINHA,72,4))
			
			If dVencto <= dDatabase
				MsgAlert("Vencimento não pode ser menor que a data de emissão. Título '" + Substr(TRB->LINHA,1,3) + cNumTit + Substr(TRB->LINHA,10,1) + "' não será importado!","Vencimento inválido!")
				lGrvTit	:= .F.
			Endif
			// Campo		Pos	-tam
			// prefixo		01	-03
			// num 			04  -06
			// parcela		10  -01
			// fornecedor	27  -06
			// loja			33	-02
			// valor		77	-06
			// historico	86 	-25
			
			dbSelectArea("SE2")
			dbSetOrder(1) //E2_FILIAL+E2_PREFIXO             + E2_NUM  + E2_PARCELA              + E2_TIPO + E2_FORNECE              + E2_LOJA
			If dbSeek(xFilial("SE2") +Substr(TRB->LINHA,1,3) + Padr(cNumTit,Len(SE2->E2_NUM)) + Substr(TRB->LINHA,10,1) + "PR "   + Substr(TRB->LINHA,27,6) + Substr(TRB->LINHA,33,2))
				MsgAlert("Já existe uma previsão com estes dados: " + Substr(TRB->LINHA,10,1) + Padr(cNumTit,Len(SE2->E2_NUM)) +  Substr(TRB->LINHA,10,1) + "PR "+ Substr(TRB->LINHA,86,25),"Atenção!")
				lGrvTit	:= .F.
			Endif
			
			If lGrvTit	
				Begin Transaction
					
					aPrevse2 := {;
						{"E2_PREFIXO",Substr(TRB->LINHA,1,3)  ,Nil},; 			// Prefixo
					{"E2_NUM"      		,cNumTit                       	,Nil},; // Num Titulo
					{"E2_PARCELA"       ,Substr(TRB->LINHA,10,1)      	,Nil},; // Parcela Titulo
					{"E2_TIPO"          ,"PR "      	                ,Nil},; // Tipo Previsao
					{"E2_NATUREZ"       ,Substr(TRB->LINHA,14,10) 	    ,Nil},; // Natureza do Titulo
					{"E2_FORNECE"       ,Substr(TRB->LINHA,27,6)   	   	,Nil},; // Codigo do Fornecedor
					{"E2_LOJA"          ,Substr(TRB->LINHA,33,2)      	,Nil},; // Loja do Fornecedor
					{"E2_EMISSAO"       ,dDataBase		              	,Nil},; // Emissao
					{"E2_VENCTO"        ,dVencto                      	,Nil},; // Data de vencimento
					{"E2_VENCREA"       ,DataValida(dVencto)          	,Nil},; // Data de vencimento real
					{"E2_VALOR"         ,Val(Alltrim(Substr(TRB->LINHA,77,6))) ,Nil},; // Valor
					{"E2_RATEIO"        ,"N"                           	,Nil},; // Valor
					{"E2_HIST"          ,Substr(TRB->LINHA,86,25)     	,Nil}}
					
					MSExecAuto({|x,y| FINA050(x,y)},aPrevse2,3)
					
				End Transaction
				
				If lMsErroAuto
					MostraErro()
				Endif
				
				lMsErroAuto := .F.
				
			Endif
			
			lGrvTit	:= .T.
			
			nMes++
		Next
		
		dbSelectArea("TRB")
		dbSkip()
	Enddo
	
	
Return
