/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÝÝÝÝÝÝÝÝÝÝÑÝÝÝÝÝÝÝÝÝÝËÝÝÝÝÝÝÝÑÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝËÝÝÝÝÝÝÑÝÝÝÝÝÝÝÝÝÝ»±±
±±ºPrograma  ³ fxImpPed Autor ³ Sérgio Siqueira º Data ³ 10/01/2013       º±±
±±ÌÝÝÝÝÝÝÝÝÝÝØÝÝÝÝÝÝÝÝÝÝÊÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÊÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝ¹±±
±±ºDescricao ³º±±
±±º          ³                                                            º±±
±±ÌÝÝÝÝÝÝÝÝÝÝØÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝ¹±±
±±ºUso       ³ Integração Landix                                          º±±
±±ÈÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

#INCLUDE "PROTHEUS.CH"
#include "RWMAKE.ch"
#include "Topconn.ch"
#Include "ap5mail.ch"
#INCLUDE "TBICONN.CH"
#INCLUDE "TBICODE.CH"
#Include "aarray.ch"
#Include "json.ch"
#Include "shash.ch"

//Integração - Importação Materiais.


User Function GERA_CLI()  //1=Usuario, 2=senha, 3=Código Grupo Empresa, 4=Código Filial, 5=Código Usuário, 6=Id da tarefa.

	Local aTipo	 		:={'N','B','D'}
	Local cFile 		:= Space(10)
	Local oPedido 		:= nil
	Local oDadosPed 	:= nil
	Local nOpc     		:= 3 // inclusao
	Local aItens        := {}
	Local aCabSC5     	:= {}
	Local aPedIte 		:= {}

	Local cQuery  := ""  //Variavel para a query
	Local cObjIni := "Taf" //Constante TAF para ser usada no inicio do nome do Ponto de Entrada
	Local cObjPE  := "Imp" //Objeto principal CBH - Cabeçalho e item de pedido
	Local nItem   := 0     //Incrementa o campo número do item

//Definição das variáveis com os nomes dos pontos de entrada
	Local cPEIn1 := cObjIni+cObjPE+"In1"
	Local cPEFim := cObjIni+cObjPE+"Fim"
// Cabeçalho
	Local cPEIn2 := cObjIni+cObjPE+"In2"
	Local cPEFil := cObjIni+cObjPE+"Fil"
	Local cPEIte := cObjIni+cObjPE+"Ite"
// Item
	Local cPEIn2B := cObjIni+cObjPE+"In2B"
	Local cPEFilB := cObjIni+cObjPE+"FilB"
	Local cPEIteB := cObjIni+cObjPE+"IteB"

//Private _cMarca   := GetMark()
	Private aFields   := {}
	Private cArq
	Private aFields2  := {}
	Private cArq2

	Private lMsErroAuto		:= .F.
	Private	lAutoErrNoFile	:= .T. 	// Gera log em arquivo 
	Private lMsHelpAuto 	:= .T.	// N�o exibe alerta na tela 


	CPESSOA  := IIF(ORETORNO:PESSOAFISICA,"F","J")
	CNPJ     := STRTRAN(STRTRAN(STRTRAN(ORETORNO:CNPJ,".",""),"/",""),"-","")
	CCOND    := IIF(TYPE("ORETORNO:PLANOPAGAMENTO:CODIGO")!="U",ORETORNO:PLANOPAGAMENTO:CODIGO,"")
	CEMAIL   := IIF(TYPE("ORETORNO:EMAILNFE")!="U",ORETORNO:EMAILNFE,"")
	CEND     := IIF(TYPE("ORETORNO:ENDERECO:LOGRADOURO")!="U",UPPER(ORETORNO:ENDERECO:LOGRADOURO),"")
	CBAIRRO  := IIF(TYPE("ORETORNO:ENDERECO:BAIRRO")!="U",UPPER(ORETORNO:ENDERECO:BAIRRO),"")
	CCEP     := IIF(TYPE("ORETORNO:ENDERECO:CEP")!="U",StrTran(ORETORNO:ENDERECO:CEP,"-",""),"") // Ajustado para remover hifen
	CCIDADE  := IIF(TYPE("ORETORNO:PRACA:CODIGOCIDADE")!="U",SUBSTR(ORETORNO:PRACA:CODIGOCIDADE,3,5),"")
	CCOMPLE  := IIF(TYPE("ORETORNO:ENDERECO:COMPLEMENTO")!="U",ORETORNO:ENDERECO:COMPLEMENTO,"")
	COBSERVACAOENTREGA  := IIF(TYPE("ORETORNO:OBSERVACAOENTREGA")!="U","CADASTRO APP - REVISAR "+CHR(13)+CHR(10)+ORETORNO:OBSERVACAOENTREGA,"")
	CUF      := IIF(TYPE("ORETORNO:ENDERECO:UF")!="U",ORETORNO:ENDERECO:UF,"")
	CNOME    := IIF(TYPE("ORETORNO:NOME")!="U",UPPER(ORETORNO:NOME),"")
	CFANTASIA := IIF(TYPE("ORETORNO:FANTASIA")!="U",UPPER(ORETORNO:FANTASIA),"")
	CTABELA  := IIF(TYPE("ORETORNO:PRACA:CODIGO")!="U",ORETORNO:PRACA:CODIGO,"")//TEM QUE VERIFICAR ISSO, PQ NA LUZTOL NÃO TEM UMA REGRA PRA SABER EXATAMENTE QUAL A TABELA DE PREÇO DO CLIENTE
	CATIVID  := IIF(TYPE("ORETORNO:RAMOATIVIDADE:CODIGO")!="U",ORETORNO:RAMOATIVIDADE:CODIGO,"")
	CDDD     := IIF(TYPE("ORETORNO:TELEFONE")!="U",SUBSTR(ORETORNO:TELEFONE,1,2),"")
	CTEL     := IIF(TYPE("ORETORNO:TELEFONE")!="U",SUBSTR(ORETORNO:TELEFONE,3,10),"")
	CVEND    := IIF(TYPE("ORETORNO:CODIGORCA")!="U",ORETORNO:CODIGORCA  ,"")
	CINSCRI  := IIF(TYPE("ORETORNO:INSCRICAOESTADUAL")!="U",ORETORNO:INSCRICAOESTADUAL,"")
	CTIPOCLI := IIF(CPESSOA=="F","F","R")
	CCODNUV  := IIF(TYPE("ORETORNO:CODIGOCLIENTENUVEM")!="U",CVALTOCHAR(ORETORNO:CODIGOCLIENTENUVEM),"")

	CBOLETO  := IIF(TYPE("ORETORNO:COBRANCA:CODIGO")!="U",CVALTOCHAR(ORETORNO:COBRANCA:CODIGO),"")

	CCONTRIB := IIF(TYPE("ORETORNO:CONFIGURACOES:CONTRIBUINTE")!="U",ORETORNO:CONFIGURACOES:CONTRIBUINTE,.F.)
	IF CCONTRIB
		CCONTRIB := "1"
	ELSE
		CCONTRIB := "2"
	ENDIF
	ORETORNO:COBRANCA
	CNACIONAL := IIF(TYPE("ORETORNO:CONFIGURACOES:CONTRIBUINTE")!="U",ORETORNO:CONFIGURACOES:SimplesNacional,.F.)
	IF CNACIONAL
		CNACIONAL := "1"
	ELSE
		CNACIONAL := "2"
	ENDIF
// -- TESTA SE O PEDIDO Já EXISTE NA BASE DE DADOS
//SC5->(DBORDERNICKNAME("XXPEDMA"))
//IF SC5->(DBSEEK(XFILIAL("SC5")+PADL(ALLTRIM(CPEDIDO),10)+PADL(ALLTRIM(CVEND),6)))
//	MSGINFO("Pedido já importado!")
//	RETURN
//ENDIF
//TEM QUER CRIAR CAMPO PARA GRAVAR O NÚMERO DESSE CLIENTE NO PROTHEUS OU OLHAR SÓ NO CNPJ
	ACABSA1:= {}
	AADD(ACABSA1,{"A1_NOME"    ,CNOME    	,NIL})
	AADD(ACABSA1,{"A1_NREDUZ"  ,CFANTASIA   ,NIL})
	AADD(ACABSA1,{"A1_LOJA"    ,"01" 	  	,NIL})
	AADD(ACABSA1,{"A1_PESSOA"  ,CPESSOA   	,NIL})
	AADD(ACABSA1,{"A1_CGC"     ,CNPJ     	,NIL})
	AADD(ACABSA1,{"A1_COND"    ,CCOND		,NIL})
//AADD(ACABSA1,{"A1_TABELA"  ,CTABELA 	,NIL})
	AADD(ACABSA1,{"A1_CEP" 	   ,CCEP 	    ,NIL})
	AADD(ACABSA1,{"A1_END"     ,CEND	    ,NIL})
	AADD(ACABSA1,{"A1_BAIRRO"  ,CBAIRRO	    ,NIL})
	AADD(ACABSA1,{"A1_EST"     ,CUF      	,NIL})
	AADD(ACABSA1,{"A1_EMAIL"   ,CEMAIL	    ,NIL})
	AADD(ACABSA1,{"A1_COMPLEM" ,CCOMPLE   	,NIL})
	AADD(ACABSA1,{"A1_TIPO"    ,CTIPOCLI  	,NIL})
	AADD(ACABSA1,{"A1_COD_MUN" ,CCIDADE    	,NIL})
	AADD(ACABSA1,{"A1_SATIV1"  ,CATIVID   	,NIL})
	AADD(ACABSA1,{"A1_VEND"    ,CVEND  		,NIL})
	AADD(ACABSA1,{"A1_DDD"     ,CDDD     	,NIL})
	AADD(ACABSA1,{"A1_TEL"     ,CTEL		,NIL})
	AADD(ACABSA1,{"A1_INSCR"   ,CINSCRI		,NIL})
	AADD(ACABSA1,{"A1_CONTA"   ,"110201001" ,NIL})
	AADD(ACABSA1,{"A1_CONTRIB" ,CCONTRIB    ,NIL})
	AADD(ACABSA1,{"A1_SIMPLES" ,CNACIONAL   ,NIL})
	AADD(ACABSA1,{"A1_SIMPNAC" ,CNACIONAL   ,NIL})
	AADD(ACABSA1,{"A1_ZBOLETO" ,CBOLETO     ,NIL})
	AADD(ACABSA1,{"A1_RISCO"   ,"E"         ,NIL})
	AADD(ACABSA1,{"A1_VM_OBS"   ,COBSERVACAOENTREGA ,NIL})
	AADD(ACABSA1,{"A1_MAXPED"  ,"1"         ,NIL})

	BEGIN TRANSACTION
		LMSERROAUTO := .F.
		MSEXECAUTO({|X,Y,Z|MATA030(X,Y,Z)},ACABSA1,NOPC) //ACIONA EXEC AUTO PARA INSERIR O NOVO REGISTRO.

		LRET := .F.

		IF LMSERROAUTO
			NSTATUS := 5
			CCL     := ""
			CERRO   := '"Cliente nao foi cadastrado"'
			CSUCESS := '"RetornoImportacao": 3'
			//AUTOGRLOG("ERRO AO EXECUTAR IMPORTAçãO DOS PEDIDOS LANDIX")
			//AAUTOERRO := {}
			//AAUTOERRO := GETAUTOGRLOG()
			
			AEVal(GetAutoGRLog(),{|x| cErro += x + CRLF})
			ConOut(cErro)

			DISARMTRANSACTION()
		ELSE
			NSTATUS := 4
			CCL     := SA1->A1_COD+SA1->A1_LOJA
			CERRO   := '"Importado com Sucesso"'
			CSUCESS := '"RetornoImportacao": 2'
		ENDIF
		aaJson := Array(#)
		oObj   := NIL
		ADADOS  := {}
		ADADOSA := {}
		CRET2 := AOBJETO[YY]:OBJETO_JSON
		CRET2 := STRTRAN(CRET2,'"Codigo": ""','"Codigo": "'+CCL+'"')
		CRET2 := STRTRAN(CRET2,'"CriticaImportacao": ""','"CriticaImportacao": '+CERRO)
		CRET2 := STRTRAN(CRET2,'"RetornoImportacao": 1',CSUCESS)

		AADD(ADADOSA, {"Id_cliente", AOBJETO[YY]:ID_CLIENTE})
		AADD(ADADOSA, {"Objeto_Json", CRET2})
		AADD(ADADOSA, {"Data", AOBJETO[YY]:DATA})
		AADD(ADADOSA, {"Status", NSTATUS})

		AADD(ADADOS, ADADOSA)

		U_BENVIA(ADADOS   ,"PUT"    , "RetornoClientes", "StatusClientes")


	END TRANSACTION

RETURN

/*
Função para envio de email
*/
STATIC FUNCTION ENVMAIL(_cSubject, _cDest, _cBody, _cAtach)

	u_fxEnvMail(_cSubject, _cDest, _cBody, _cAtach)

Return

/*
Função que retorna a posição do campo na SX3
*/
STATIC FUNCTION fxPos(cCampo)
	Local nPos  := 0
	nPos := POSICIONE("SX3", 2, cCampo, "X3_ORDEM")
Return nPos

/*
Função que ordena o array de campos para ser passado para Cabeçalho e Detalhe
do ExecAuto
*/ 
STATIC FUNCTION fxOrdenaSX3(aCampos)
	Local aWithPos := {}
	Local aOrdenado := {}

//Le o array passado como parametro e coloca a posição de cada campo
	For a:= 1 to len(aCampos)
		aadd(aWithPos,{aCampos[a,1],aCampos[a,2], aCampos[a,3], fxPos(aCampos[a,1])})
	Next

//Ordena o array de acordo com a posição dos campos
	ASORT(aWithPos, , , { | x,y | x[4] < y[4] } )

//Monta o novo array somente com os campos originais, mas agora ordenado
	For a:=1 to Len(aWithPos)
		aadd(aOrdenado,{aWithPos[a,1],aWithPos[a,2], aWithPos[a,3]})
	Next

Return aOrdenado
