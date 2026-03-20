#Include 'totvs.ch'
#include "tbiconn.ch"
#Include "TopConn.ch"

#DEFINE NOPC_CLI 1
#DEFINE NOPC_ROT 2

/*/{Protheus.doc} BFFATA36
Roteirizador de clientes para vendedores
@type function
@version 12.1.33
@author MarceloLaushner
@since 9/17/2014
/*/
User Function BFFATA36()
	
	Local		aSize 		:= MsAdvSize( .F., .F., 400 )
	Local		oDlgAgenda
	Local		aHeadCli	:= {}
	Local		aHeadRot	:= {}
	Local		nSeqC		:= 0
	Local		aAlterCli	:= {}
	Local		aAlterRot	:= {}
	Local		aButtons	:= {}
	Private		lIsSuper	:= RetCodUsr() $ GetNewPar("BF_FATA36A","000130") // Id de usuários liberados para editar campos especificos
	Private		cPerg1		:= "BFFATA36"
	Private 	bRefrXmlF		:= {|| Pergunte(cPerg1,.T.),sfMontaCols(NOPC_CLI),sfMontaCols(NOPC_ROT) }
	
	
	//DbSelectArea("SX3")
	//DbSetOrder(2)

	
	// Montagem do aHeader de clientes
	// 1 Codigo
	//DbSeek("A1_COD")
	cCampo1 := "A1_COD"
	Aadd(aHeadCli		,{Trim(X3Titulo()),GetSx3Cache(cCampo1,"X3_CAMPO"),GetSx3Cache(cCampo1,"X3_PICTURE"),GetSx3Cache(cCampo1,"X3_TAMANHO"),GetSx3Cache(cCampo1,"X3_DECIMAL")	,""/*GetSx3Cache(cCampo,"X3_VALID")*/,,GetSx3Cache(cCampo1,"X3_TIPO"),GetSx3Cache(cCampo1,"X3_F3"),""})
	Private	nPcCod	:= ++nSeqC
	
	// 2 Loja
	//DbSeek("A1_LOJA")
	cCampo2 := "A1_LOJA"
	Aadd(aHeadCli		,{Trim(X3Titulo()),GetSx3Cache(cCampo2,"X3_CAMPO"),GetSx3Cache(cCampo2,"X3_PICTURE"),GetSx3Cache(cCampo2,"X3_TAMANHO"),GetSx3Cache(cCampo2,"X3_DECIMAL")	,""/*GetSx3Cache(cCampo,"X3_VALID")*/,,GetSx3Cache(cCampo2,"X3_TIPO"),GetSx3Cache(cCampo2,"X3_F3"),""})
	Private	nPcLoja	:= ++nSeqC
	
	// 3 Nome
	//DbSeek("A1_NOME")
	cCampo3 := "A1_NOME"
	Aadd(aHeadCli		,{Trim(X3Titulo()),GetSx3Cache(cCampo3,"X3_CAMPO"),GetSx3Cache(cCampo3,"X3_PICTURE"),GetSx3Cache(cCampo3,"X3_TAMANHO"),GetSx3Cache(cCampo3,"X3_DECIMAL")	,""/*GetSx3Cache(cCampo,"X3_VALID")*/,,GetSx3Cache(cCampo3,"X3_TIPO"),GetSx3Cache(cCampo3,"X3_F3"),""})
	Private	nPcNome	:= ++nSeqC
	
	
	// Cidade
	//DbSeek("A1_MUN")
	cCampo4 := "A1_MUN"
	Aadd(aHeadCli		,{Trim(X3Titulo()),GetSx3Cache(cCampo4,"X3_CAMPO"),GetSx3Cache(cCampo4,"X3_PICTURE"),GetSx3Cache(cCampo4,"X3_TAMANHO"),GetSx3Cache(cCampo4,"X3_DECIMAL")	,""/*GetSx3Cache(cCampo,"X3_VALID")*/,,GetSx3Cache(cCampo4,"X3_TIPO"),GetSx3Cache(cCampo4,"X3_F3"),""})
	Private	nPcMun := ++nSeqC
	
	//  Estado
	//DbSeek("A1_EST")
	cCampo5 := "A1_EST"
	Aadd(aHeadCli		,{Trim(X3Titulo()),GetSx3Cache(cCampo5,"X3_CAMPO"),GetSx3Cache(cCampo5,"X3_PICTURE"),GetSx3Cache(cCampo5,"X3_TAMANHO"),GetSx3Cache(cCampo5,"X3_DECIMAL")	,""/*GetSx3Cache(cCampo,"X3_VALID")*/,,GetSx3Cache(cCampo5,"X3_TIPO"),GetSx3Cache(cCampo5,"X3_F3"),""})
	Private	nPcEst := ++nSeqC
	
	//  CEP
	DbSeek("A1_CEP")
	cCampo6 := "A1_CEP"
	Aadd(aHeadCli		,{Trim(X3Titulo()),GetSx3Cache(cCampo6,"X3_CAMPO"),GetSx3Cache(cCampo6,"X3_PICTURE"),GetSx3Cache(cCampo6,"X3_TAMANHO"),GetSx3Cache(cCampo6,"X3_DECIMAL")	,""/*GetSx3Cache(cCampo,"X3_VALID")*/,,GetSx3Cache(cCampo6,"X3_TIPO"),GetSx3Cache(cCampo6,"X3_F3"),""})
	Private	nPcCep := ++nSeqC
	
	//  ROTA - Calculada pela PAB
	//DbSeek("A1_ROTA")
	cCampo7 := "A1_ROTA"
	Aadd(aHeadCli		,{Trim(X3Titulo()),GetSx3Cache(cCampo7,"X3_CAMPO"),GetSx3Cache(cCampo7,"X3_PICTURE"),GetSx3Cache(cCampo7,"X3_TAMANHO"),GetSx3Cache(cCampo7,"X3_DECIMAL")	,""/*GetSx3Cache(cCampo,"X3_VALID")*/,,GetSx3Cache(cCampo7,"X3_TIPO"),GetSx3Cache(cCampo7,"X3_F3"),""})
	Private	nPcRota := ++nSeqC
	
	
	// Semana de atendimento
	//DbSeek("A1_SEMTMK")
	cCampo8 := "A1_SEMTMK"
	Aadd(aHeadCli	,{Trim(X3Titulo()),GetSx3Cache(cCampo8,"X3_CAMPO"),GetSx3Cache(cCampo8,"X3_PICTURE"),GetSx3Cache(cCampo8,"X3_TAMANHO"),GetSx3Cache(cCampo8,"X3_DECIMAL")	,GetSx3Cache(cCampo8,"X3_VALID"),,GetSx3Cache(cCampo8,"X3_TIPO"),GetSx3Cache(cCampo8,"X3_F3"),""})
	Private	nPcSemTmk := ++nSeqC
	Aadd(aAlterCli,GetSx3Cache(cCampo8,"X3_CAMPO"))
	
	// Dia semana
	//DbSeek("A1_DIAWEEK")
	cCampo9 := "A1_DIAWEEK"
	Aadd(aHeadCli		,{Trim(X3Titulo()),GetSx3Cache(cCampo9,"X3_CAMPO"),GetSx3Cache(cCampo9,"X3_PICTURE"),GetSx3Cache(cCampo9,"X3_TAMANHO"),GetSx3Cache(cCampo9,"X3_DECIMAL")	,GetSx3Cache(cCampo9,"X3_VALID"),,GetSx3Cache(cCampo9,"X3_TIPO"),GetSx3Cache(cCampo9,"X3_F3"),""})
	Private	nPcDiaWeek := ++nSeqC
	Aadd(aAlterCli,GetSx3Cache(cCampo9,"X3_CAMPO"))
	
	//  Intervalo dias para visita
	//DbSeek("A1_TEMVIS")
	cCampo10 := "A1_TEMVIS"
	Aadd(aHeadCli		,{Trim(X3Titulo()),GetSx3Cache(cCampo10,"X3_CAMPO"),GetSx3Cache(cCampo10,"X3_PICTURE"),GetSx3Cache(cCampo10,"X3_TAMANHO"),GetSx3Cache(cCampo10,"X3_DECIMAL")	,GetSx3Cache(cCampo10,"X3_VALID"),,GetSx3Cache(cCampo10,"X3_TIPO"),GetSx3Cache(cCampo10,"X3_F3"),""})
	Private	nPcTemVis := ++nSeqC
	Aadd(aAlterCli,GetSx3Cache(cCampo10,"X3_CAMPO"))
	
	//  Sequencia Visita
	//DbSeek("A1_SEQVIST")
	cCampo11 := "A1_SEQVIST"
	Aadd(aHeadCli		,{Trim(X3Titulo()),GetSx3Cache(cCampo11,"X3_CAMPO"),GetSx3Cache(cCampo11,"X3_PICTURE"),GetSx3Cache(cCampo11,"X3_TAMANHO"),GetSx3Cache(cCampo11,"X3_DECIMAL")	,GetSx3Cache(cCampo11,"X3_VALID"),,GetSx3Cache(cCampo11,"X3_TIPO"),GetSx3Cache(cCampo11,"X3_F3"),""})
	Private	nPcSeqVist := ++nSeqC
	Aadd(aAlterCli,GetSx3Cache(cCampo11,"X3_CAMPO"))
	
	//  Potencial
	//DbSeek("A1_POTENC")
	cCampo12 := "A1_POTENC"
	Aadd(aHeadCli		,{Trim(X3Titulo()),GetSx3Cache(cCampo12,"X3_CAMPO"),GetSx3Cache(cCampo12,"X3_PICTURE"),GetSx3Cache(cCampo12,"X3_TAMANHO"),GetSx3Cache(cCampo12,"X3_DECIMAL")	,""/*GetSx3Cache(cCampo,"X3_VALID")*/,,GetSx3Cache(cCampo12,"X3_TIPO"),GetSx3Cache(cCampo12,"X3_F3"),""})
	Private	nPcPotenc := ++nSeqC
	If lIsSuper
		Aadd(aAlterCli,GetSx3Cache(cCampo12,"X3_CAMPO"))
	Endif
	
	//  Potencial
	//DbSeek("A1_POTENC2")
	cCampo13 := "A1_POTENC2"
	Aadd(aHeadCli		,{Trim(X3Titulo()),GetSx3Cache(cCampo13,"X3_CAMPO"),GetSx3Cache(cCampo13,"X3_PICTURE"),GetSx3Cache(cCampo13,"X3_TAMANHO"),GetSx3Cache(cCampo13,"X3_DECIMAL")	,""/*GetSx3Cache(cCampo,"X3_VALID")*/,,GetSx3Cache(cCampo13,"X3_TIPO"),GetSx3Cache(cCampo13,"X3_F3"),""})
	Private	nPcPotenc2 := ++nSeqC
	If lIsSuper
		Aadd(aAlterCli,GetSx3Cache(cCampo13,"X3_CAMPO"))
	Endif
	// Endereco
	//DbSeek("A1_END")
	cCampo14 := "A1_END"
	Aadd(aHeadCli		,{Trim(X3Titulo()),GetSx3Cache(cCampo14,"X3_CAMPO"),GetSx3Cache(cCampo14,"X3_PICTURE"),GetSx3Cache(cCampo14,"X3_TAMANHO"),GetSx3Cache(cCampo14,"X3_DECIMAL")	,""/*GetSx3Cache(cCampo,"X3_VALID")*/,,GetSx3Cache(cCampo14,"X3_TIPO"),GetSx3Cache(cCampo14,"X3_F3"),""})
	Private	nPcEnd := ++nSeqC
	
	// Bairro
	//DbSeek("A1_BAIRRO")
	cCampo15 := "A1_BAIRRO"
	Aadd(aHeadCli		,{Trim(X3Titulo()),GetSx3Cache(cCampo15,"X3_CAMPO"),GetSx3Cache(cCampo15,"X3_PICTURE"),GetSx3Cache(cCampo15,"X3_TAMANHO"),GetSx3Cache(cCampo15,"X3_DECIMAL")	,""/*GetSx3Cache(cCampo,"X3_VALID")*/,,GetSx3Cache(cCampo15,"X3_TIPO"),GetSx3Cache(cCampo15,"X3_F3"),""})
	Private	nPcBairro := ++nSeqC
	
	// Vend.Tmk
	//DbSeek("A1_GERAT")
	cCampo16 := "A1_GERAT"
	Aadd(aHeadCli		,{Trim(X3Titulo()),GetSx3Cache(cCampo16,"X3_CAMPO"),GetSx3Cache(cCampo16,"X3_PICTURE"),GetSx3Cache(cCampo16,"X3_TAMANHO"),GetSx3Cache(cCampo16,"X3_DECIMAL")	,GetSx3Cache(cCampo16,"X3_VALID"),,GetSx3Cache(cCampo16,"X3_TIPO"),GetSx3Cache(cCampo16,"X3_F3"),""})
	Private	nPcGerat := ++nSeqC
	If lIsSuper
		Aadd(aAlterCli,GetSx3Cache(cCampo16,"X3_CAMPO"))
	Endif
	
	// Tabela Precos
	//DbSeek("A1_TABELA")
	cCampo17 := "A1_TABELA"
	Aadd(aHeadCli		,{Trim(X3Titulo()),GetSx3Cache(cCampo17,"X3_CAMPO"),GetSx3Cache(cCampo17,"X3_PICTURE"),GetSx3Cache(cCampo17,"X3_TAMANHO"),GetSx3Cache(cCampo17,"X3_DECIMAL")	,GetSx3Cache(cCampo17,"X3_VALID"),,GetSx3Cache(cCampo17,"X3_TIPO"),GetSx3Cache(cCampo17,"X3_F3"),""})
	Private	nPcTabela := ++nSeqC
	If lIsSuper
		Aadd(aAlterCli,GetSx3Cache(cCampo17,"X3_CAMPO"))
	Endif
	
	// Vendedor
	//DbSeek("A1_VEND")
	cCampo18 := "A1_VEND"
	Aadd(aHeadCli		,{Trim(X3Titulo()),GetSx3Cache(cCampo18,"X3_CAMPO"),GetSx3Cache(cCampo18,"X3_PICTURE"),GetSx3Cache(cCampo18,"X3_TAMANHO"),GetSx3Cache(cCampo18,"X3_DECIMAL")	,GetSx3Cache(cCampo18,"X3_VALID"),,GetSx3Cache(cCampo18,"X3_TIPO"),GetSx3Cache(cCampo18,"X3_F3"),""})
	Private	nPcVend := ++nSeqC
	If lIsSuper .And. RetCodUsr() $ GetNewPar("BF_ALVND1","000000")
		Aadd(aAlterCli,GetSx3Cache(cCampo18,"X3_CAMPO"))
	Endif
	
	// Vendedor 2
	//DbSeek("A1_VEND2")
	cCampo19 := "A1_VEND2"
	Aadd(aHeadCli		,{Trim(X3Titulo()),GetSx3Cache(cCampo19,"X3_CAMPO"),GetSx3Cache(cCampo19,"X3_PICTURE"),GetSx3Cache(cCampo19,"X3_TAMANHO"),GetSx3Cache(cCampo19,"X3_DECIMAL")	,GetSx3Cache(cCampo19,"X3_VALID"),,GetSx3Cache(cCampo19,"X3_TIPO"),GetSx3Cache(cCampo19,"X3_F3"),""})
	Private	nPcVend2 := ++nSeqC
	If lIsSuper .And. RetCodUsr() $ GetNewPar("BF_ALVND2","000000")
		Aadd(aAlterCli,GetSx3Cache(cCampo19,"X3_CAMPO"))
	Endif
	
	// Vendedor 3
	//DbSeek("A1_VEND3")
	cCampo20 := "A1_VEND3"	
	Aadd(aHeadCli		,{Trim(X3Titulo()),GetSx3Cache(cCampo20,"X3_CAMPO"),GetSx3Cache(cCampo20,"X3_PICTURE"),GetSx3Cache(cCampo20,"X3_TAMANHO"),GetSx3Cache(cCampo20,"X3_DECIMAL")	,GetSx3Cache(cCampo20,"X3_VALID"),,GetSx3Cache(cCampo20,"X3_TIPO"),GetSx3Cache(cCampo20,"X3_F3"),""})
	Private	nPcVend3 := ++nSeqC
	If lIsSuper .And. RetCodUsr() $ GetNewPar("BF_ALVND3","000000")
		Aadd(aAlterCli,GetSx3Cache(cCampo20,"X3_CAMPO"))
	Endif
	
	// Vendedor 4
	//DbSeek("A1_VEND4")
	cCampo21 := "A1_VEND4"
	Aadd(aHeadCli		,{Trim(X3Titulo()),GetSx3Cache(cCampo21,"X3_CAMPO"),GetSx3Cache(cCampo21,"X3_PICTURE"),GetSx3Cache(cCampo21,"X3_TAMANHO"),GetSx3Cache(cCampo21,"X3_DECIMAL")	,GetSx3Cache(cCampo21,"X3_VALID"),,GetSx3Cache(cCampo21,"X3_TIPO"),GetSx3Cache(cCampo21,"X3_F3"),""})
	Private	nPcVend4 := ++nSeqC
	If lIsSuper .And. RetCodUsr() $ GetNewPar("BF_ALVND4","000000") 
		Aadd(aAlterCli,GetSx3Cache(cCampo21,"X3_CAMPO"))
	Endif
	
	
	// Montagem do aHeader de roteiro do dia selecionado
	// Zero contador
	nSeqC := 0
	
	// Semana de atendimento
	//DbSeek("A1_SEMTMK")
	cCampo22 := "A1_SEMTMK"
	Aadd(aHeadRot		,{Trim(X3Titulo()),GetSx3Cache(cCampo22,"X3_CAMPO"),GetSx3Cache(cCampo22,"X3_PICTURE"),GetSx3Cache(cCampo22,"X3_TAMANHO"),GetSx3Cache(cCampo22,"X3_DECIMAL")	,GetSx3Cache(cCampo22,"X3_VALID"),,GetSx3Cache(cCampo22,"X3_TIPO"),GetSx3Cache(cCampo22,"X3_F3"),""})
	Private	nPrSemTmk := ++nSeqC
	Aadd(aAlterRot,GetSx3Cache(cCampo22,"X3_CAMPO"))
	
	// Dia semana
	//DbSeek("A1_DIAWEEK")
	cCampo23 := "A1_DIAWEEK"
	Aadd(aHeadRot		,{Trim(X3Titulo()),GetSx3Cache(cCampo23,"X3_CAMPO"),GetSx3Cache(cCampo23,"X3_PICTURE"),GetSx3Cache(cCampo23,"X3_TAMANHO"),GetSx3Cache(cCampo23,"X3_DECIMAL")	,GetSx3Cache(cCampo23,"X3_VALID"),,GetSx3Cache(cCampo23,"X3_TIPO"),GetSx3Cache(cCampo23,"X3_F3"),""})
	Private	nPrDiaWeek := ++nSeqC
	Aadd(aAlterRot,GetSx3Cache(cCampo23,"X3_CAMPO"))
	
	//  Intervalo dias para visita
	//DbSeek("A1_TEMVIS")
	cCampo24 := "A1_TEMVIS"
	Aadd(aHeadRot		,{Trim(X3Titulo()),GetSx3Cache(cCampo24,"X3_CAMPO"),GetSx3Cache(cCampo24,"X3_PICTURE"),GetSx3Cache(cCampo24,"X3_TAMANHO"),GetSx3Cache(cCampo24,"X3_DECIMAL")	,GetSx3Cache(cCampo24,"X3_VALID"),,GetSx3Cache(cCampo24,"X3_TIPO"),GetSx3Cache(cCampo24,"X3_F3"),""})
	Private	nPrTemVis := ++nSeqC
	Aadd(aAlterRot,GetSx3Cache(cCampo24,"X3_CAMPO"))
	
	//  Sequencia Visita
	//DbSeek("A1_SEQVIST")
	cCampo25 := "A1_SEQVIST"
	Aadd(aHeadRot		,{Trim(X3Titulo()),GetSx3Cache(cCampo25,"X3_CAMPO"),GetSx3Cache(cCampo25,"X3_PICTURE"),GetSx3Cache(cCampo25,"X3_TAMANHO"),GetSx3Cache(cCampo25,"X3_DECIMAL")	,GetSx3Cache(cCampo25,"X3_VALID"),,GetSx3Cache(cCampo25,"X3_TIPO"),GetSx3Cache(cCampo25,"X3_F3"),""})
	Private	nPrSeqVist := ++nSeqC
	Aadd(aAlterRot,GetSx3Cache(cCampo25,"X3_CAMPO"))
	
	// Vendedor
	//DbSeek("A1_VEND")
	cCampo26 := "A1_VEND"
	Aadd(aHeadRot		,{Trim(X3Titulo()),GetSx3Cache(cCampo26,"X3_CAMPO"),GetSx3Cache(cCampo26,"X3_PICTURE"),GetSx3Cache(cCampo26,"X3_TAMANHO"),GetSx3Cache(cCampo26,"X3_DECIMAL")	,GetSx3Cache(cCampo26,"X3_VALID"),,GetSx3Cache(cCampo26,"X3_TIPO"),GetSx3Cache(cCampo26,"X3_F3"),""})
	Private	nPrVend := ++nSeqC
	If lIsSuper
		Aadd(aAlterRot,GetSx3Cache(cCampo26,"X3_CAMPO"))
	Endif
	
	// Codigo
	//DbSeek("A1_COD")
	cCampo27 := "A1_COD"
	Aadd(aHeadRot		,{Trim(X3Titulo()),GetSx3Cache(cCampo27,"X3_CAMPO"),GetSx3Cache(cCampo27,"X3_PICTURE"),GetSx3Cache(cCampo27,"X3_TAMANHO"),GetSx3Cache(cCampo27,"X3_DECIMAL")	,""/*GetSx3Cache(cCampo,"X3_VALID")*/,,GetSx3Cache(cCampo27,"X3_TIPO"),GetSx3Cache(cCampo27,"X3_F3"),""})
	Private	nPrCod	:= ++nSeqC
	
	// Loja
	//DbSeek("A1_LOJA")
	cCampo28 := "A1_LOJA"
	Aadd(aHeadRot		,{Trim(X3Titulo()),GetSx3Cache(cCampo28,"X3_CAMPO"),GetSx3Cache(cCampo28,"X3_PICTURE"),GetSx3Cache(cCampo28,"X3_TAMANHO"),GetSx3Cache(cCampo28,"X3_DECIMAL")	,""/*GetSx3Cache(cCampo,"X3_VALID")*/,,GetSx3Cache(cCampo28,"X3_TIPO"),GetSx3Cache(cCampo28,"X3_F3"),""})
	Private	nPrLoja	:= ++nSeqC
	
	// Nome
	//DbSeek("A1_NOME")
	cCampo29 := "A1_NOME"
	Aadd(aHeadRot		,{Trim(X3Titulo()),GetSx3Cache(cCampo29,"X3_CAMPO"),GetSx3Cache(cCampo29,"X3_PICTURE"),GetSx3Cache(cCampo29,"X3_TAMANHO"),GetSx3Cache(cCampo29,"X3_DECIMAL")	,""/*GetSx3Cache(cCampo,"X3_VALID")*/,,GetSx3Cache(cCampo29,"X3_TIPO"),GetSx3Cache(cCampo29,"X3_F3"),""})
	Private	nPrNome	:= ++nSeqC
	
	// Endereco
	//DbSeek("A1_END")
	cCampo30 := "A1_END"
	Aadd(aHeadRot		,{Trim(X3Titulo()),GetSx3Cache(cCampo30,"X3_CAMPO"),GetSx3Cache(cCampo30,"X3_PICTURE"),GetSx3Cache(cCampo30,"X3_TAMANHO"),GetSx3Cache(cCampo30,"X3_DECIMAL")	,""/*GetSx3Cache(cCampo,"X3_VALID")*/,,GetSx3Cache(cCampo30,"X3_TIPO"),GetSx3Cache(cCampo30,"X3_F3"),""})
	Private	nPrEnd := ++nSeqC
	
	// Bairro
	//DbSeek("A1_BAIRRO")
	cCampo31 := "A1_BAIRRO"
	Aadd(aHeadRot		,{Trim(X3Titulo()),GetSx3Cache(cCampo31,"X3_CAMPO"),GetSx3Cache(cCampo31,"X3_PICTURE"),GetSx3Cache(cCampo31,"X3_TAMANHO"),GetSx3Cache(cCampo31,"X3_DECIMAL")	,""/*GetSx3Cache(cCampo,"X3_VALID")*/,,GetSx3Cache(cCampo31,"X3_TIPO"),GetSx3Cache(cCampo31,"X3_F3"),""})
	Private	nPrBairro := ++nSeqC
	
	// Cidade
	//DbSeek("A1_MUN")
	cCampo32 := "A1_MUN"
	Aadd(aHeadRot		,{Trim(X3Titulo()),GetSx3Cache(cCampo32,"X3_CAMPO"),GetSx3Cache(cCampo32,"X3_PICTURE"),GetSx3Cache(cCampo32,"X3_TAMANHO"),GetSx3Cache(cCampo32,"X3_DECIMAL")	,""/*GetSx3Cache(cCampo,"X3_VALID")*/,,GetSx3Cache(cCampo32,"X3_TIPO"),GetSx3Cache(cCampo32,"X3_F3"),""})
	Private	nPrMun := ++nSeqC
	
	// Cidade
	//DbSeek("A1_CEP")
	cCampo33 := "A1_CEP"
	Aadd(aHeadRot		,{Trim(X3Titulo()),GetSx3Cache(cCampo33,"X3_CAMPO"),GetSx3Cache(cCampo33,"X3_PICTURE"),GetSx3Cache(cCampo33,"X3_TAMANHO"),GetSx3Cache(cCampo33,"X3_DECIMAL")	,""/*GetSx3Cache(cCampo,"X3_VALID")*/,,GetSx3Cache(cCampo33,"X3_TIPO"),GetSx3Cache(cCampo33,"X3_F3"),""})
	Private	nPrCep := ++nSeqC
	
	//  ROTA - Calculada pela PAB
	//DbSeek("A1_ROTA")
	cCampo34 := "A1_ROTA"
	Aadd(aHeadRot		,{Trim(X3Titulo()),GetSx3Cache(cCampo34,"X3_CAMPO"),GetSx3Cache(cCampo34,"X3_PICTURE"),GetSx3Cache(cCampo34,"X3_TAMANHO"),GetSx3Cache(cCampo34,"X3_DECIMAL")	,""/*GetSx3Cache(cCampo,"X3_VALID")*/,,GetSx3Cache(cCampo34,"X3_TIPO"),GetSx3Cache(cCampo34,"X3_F3"),""})
	Private	nPrRota := ++nSeqC
	
	//  Estado
	//DbSeek("A1_EST")
	cCampo35 := "A1_EST"
	Aadd(aHeadRot		,{Trim(X3Titulo()),GetSx3Cache(cCampo35,"X3_CAMPO"),GetSx3Cache(cCampo35,"X3_PICTURE"),GetSx3Cache(cCampo35,"X3_TAMANHO"),GetSx3Cache(cCampo35,"X3_DECIMAL")	,""/*GetSx3Cache(cCampo,"X3_VALID")*/,,GetSx3Cache(cCampo35,"X3_TIPO"),GetSx3Cache(cCampo35,"X3_F3"),""})
	Private	nPrEst := ++nSeqC
	
	//  Ultima Visita
	//DbSeek("A1_ULTVIS")
	cCampo36 := "A1_ULTVIS"
	Aadd(aHeadRot		,{Trim(X3Titulo()),GetSx3Cache(cCampo36,"X3_CAMPO"),GetSx3Cache(cCampo36,"X3_PICTURE"),GetSx3Cache(cCampo36,"X3_TAMANHO"),GetSx3Cache(cCampo36,"X3_DECIMAL")	,""/*GetSx3Cache(cCampo,"X3_VALID")*/,,GetSx3Cache(cCampo36,"X3_TIPO"),GetSx3Cache(cCampo36,"X3_F3"),""})
	Private	nPrUltVis := ++nSeqC
	
	//  Ultima Compra
	//DbSeek("A1_ULTCOM")
	cCampo37 := "A1_ULTCOM"
	Aadd(aHeadRot		,{Trim(X3Titulo()),GetSx3Cache(cCampo37,"X3_CAMPO"),GetSx3Cache(cCampo37,"X3_PICTURE"),GetSx3Cache(cCampo37,"X3_TAMANHO"),GetSx3Cache(cCampo37,"X3_DECIMAL")	,""/*GetSx3Cache(cCampo,"X3_VALID")*/,,GetSx3Cache(cCampo37,"X3_TIPO"),GetSx3Cache(cCampo37,"X3_F3"),""})
	Private	nPrUltCom := ++nSeqC
	
	//  Contato
	//DbSeek("A1_CONTATO")
	cCampo38 := "A1_CONTATO"
	Aadd(aHeadRot		,{Trim(X3Titulo()),GetSx3Cache(cCampo38,"X3_CAMPO"),GetSx3Cache(cCampo38,"X3_PICTURE"),GetSx3Cache(cCampo38,"X3_TAMANHO"),GetSx3Cache(cCampo38,"X3_DECIMAL")	,""/*GetSx3Cache(cCampo,"X3_VALID")*/,,GetSx3Cache(cCampo38,"X3_TIPO"),GetSx3Cache(cCampo38,"X3_F3"),""})
	Private	nPrContato := ++nSeqC
	
	//  Fone
	//DbSeek("A1_TEL")
	cCampo39 := "A1_TEL"
	Aadd(aHeadRot		,{Trim(X3Titulo()),GetSx3Cache(cCampo39,"X3_CAMPO"),GetSx3Cache(cCampo39,"X3_PICTURE"),GetSx3Cache(cCampo39,"X3_TAMANHO"),GetSx3Cache(cCampo39,"X3_DECIMAL")	,""/*GetSx3Cache(cCampo,"X3_VALID")*/,,GetSx3Cache(cCampo39,"X3_TIPO"),GetSx3Cache(cCampo39,"X3_F3"),""})
	Private	nPrTel := ++nSeqC
	
	//  Potencial
	//DbSeek("A1_POTENC")
	cCampo40 = "A1_POTENC"
	Aadd(aHeadRot		,{Trim(X3Titulo()),GetSx3Cache(cCampo40,"X3_CAMPO"),GetSx3Cache(cCampo40,"X3_PICTURE"),GetSx3Cache(cCampo40,"X3_TAMANHO"),GetSx3Cache(cCampo40,"X3_DECIMAL")	,""/*GetSx3Cache(cCampo,"X3_VALID")*/,,GetSx3Cache(cCampo40,"X3_TIPO"),GetSx3Cache(cCampo40,"X3_F3"),""})
	Private	nPrPotenc := ++nSeqC
	If lIsSuper
		Aadd(aAlterRot,GetSx3Cache(cCampo40,"X3_CAMPO"))
	Endif
	
	//  Potencial
	//DbSeek("A1_POTENC2")
	cCampo41 := "A1_POTENC2"
	Aadd(aHeadRot		,{Trim(X3Titulo()),GetSx3Cache(cCampo41,"X3_CAMPO"),GetSx3Cache(cCampo41,"X3_PICTURE"),GetSx3Cache(cCampo41,"X3_TAMANHO"),GetSx3Cache(cCampo41,"X3_DECIMAL")	,""/*GetSx3Cache(cCampo,"X3_VALID")*/,,GetSx3Cache(cCampo41,"X3_TIPO"),GetSx3Cache(cCampo41,"X3_F3"),""})
	Private	nPrPotenc2 := ++nSeqC
	If lIsSuper
		Aadd(aAlterRot,GetSx3Cache(cCampo41,"X3_CAMPO"))
	Endif
	
	
	sfVldPerg()
	
	If !Pergunte(cPerg1,.T.)
		Return
	Endif
	
	
	
	DEFINE MSDIALOG oDlgAgenda  FROM aSize[1],aSize[2] TO aSize[3] , aSize[4] Of oMainWnd Pixel Title OemToAnsi("Roteirizador de Vendas")
	
	
	oDlgAgenda:lMaximized := .T.
	
	//	Private oFolder := TFolder():New(001,001,{"Roteiros 1","Roteiros 2"},{"HEADER"},oDlgAgenda,,,, .T., .F.,80,90)
	//oFolder:Align := CONTROL_ALIGN_TOP
	
	Private oFolder1 := TFolder():New(001,001,{"Sem/Dia/Freq/Seq","Roteiro","Maps Google"},{"HEADER"},oDlgAgenda,,,, .T., .F.,600,600)
	oFolder1:Align := CONTROL_ALIGN_ALLCLIENT
	
	Private oGetCli := MsNewGetDados():New(000,000,600,600,GD_UPDATE,;
		"AllwaysTrue()"/*cLinhaOk*/,;
		"AllwaysTrue()"/*cTudoOk*/,"",;
		aAlterCli,0/*nFreeze*/,10000/*nMax*/,/*cCampoOk*/,;
		"AllwaysTrue()"/*cSuperApagar*/,/*cApagaOk*/,;
		oFolder1:aDialogs[1],aHeadCli,{},)
	oGetCli:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	
	// Efetua montagem dos dados do acols depois de existir o objeto
	sfMontaCols(NOPC_CLI)
	
	Private oPanel1 := TPanel():New(0,0,'',oFolder1:aDialogs[2], oDlgAgenda:oFont, .T., .T.,, ,200,80,.T.,.T. )
	oPanel1:Align := CONTROL_ALIGN_TOP
	
	
	Private oCalend1:= MsCalend():New(02,02,oPanel1,.F.)
	oCalend1:Disable()
	oCalend1:Refresh()
	
	Private oCalend2:=MsCalend():New(02,150,oPanel1)
	oCalend2:dDiaAtu := dDataBase
	oCalend2:bChangeMes := {|| oCalend3:dDiaAtu := oCalend2:dDiaAtu+28,;
		oCalend1:dDiaAtu := oCalend2:dDiaAtu-28,;
		oCalend1:Refresh(),;
		oCalend3:Refresh() }
	
	oCalend2:bChange    := {|| 	oCalend3:dDiaAtu := oCalend2:dDiaAtu+28,;
		oCalend1:dDiaAtu := oCalend2:dDiaAtu-28,sfMontaCols(NOPC_ROT),sfViewMaps(),;
		oCalend1:Refresh(),;
		oCalend3:Refresh()}
	
	Private oCalend3:=MsCalend():New(02,298,oPanel1)
	oCalend3:Disable()
	oCalend3:Refresh()
	
	oCalend3:dDiaAtu := oCalend2:dDiaAtu+28
	oCalend1:dDiaAtu := oCalend2:dDiaAtu-28
	
	Private oGetRot := MsNewGetDados():New(000,000,600,600,GD_UPDATE,;
		"AllwaysTrue()"/*cLinhaOk*/,;
		"AllwaysTrue()"/*cTudoOk*/,"",;
		aAlterRot,0/*nFreeze*/,10000/*nMax*/,/*cCampoOk*/,;
		"AllwaysTrue()"/*cSuperApagar*/,/*cApagaOk*/,;
		oFolder1:aDialogs[2],aHeadRot,{},)
	oGetRot:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	
	sfMontaCols(NOPC_ROT)
	
	Private oPanel2 := TPanel():New(0,0,'', oFolder1:aDialogs[3] , oDlgAgenda:oFont, .T., .T.,, ,200,25,.T.,.T. )
	oPanel2:Align := CONTROL_ALIGN_TOP
	Private cTGet2	:= Space(100)
	Private oGetUrl
	
	@ 001,005 MsGet oGetUrl Var cTGet2 Size 360,10 of oPanel2 Pixel
	@ 001,370 Button "Navegar" Size 40,10 Action oTIBrowser:Navigate(cTGet2) Of oPanel2 Pixel
	
	Private oTIBrowser:= TIBrowser():New(001,001, 100,100, "www.google.com.br", oFolder1:aDialogs[3] )
	oTiBrowser:Align := CONTROL_ALIGN_ALLCLIENT
	
	Private oPanel3 := TPanel():New(0,0,'',oDlgAgenda, oDlgAgenda:oFont, .T., .T.,, ,200,40,.T.,.T. )
	oPanel3:Align := CONTROL_ALIGN_BOTTOM
	
	Aadd(aButtons,{'PESQUISA',{|| sfViewMaps(2)},OemToAnsi("Google Maps"),OemToAnsi("Google Maps")})
	Aadd(aButtons,{'PESQUISA',bRefrXmlF , OemToAnsi("Filtrar"),OemToAnsi("Filtrar")})
	Aadd(aButtons,{'PESQUISA',{ || sfExpExcel() } , OemToAnsi("Exporta Excel"),OemToAnsi("Exporta Excel")})

	Aadd(aButtons,{'PESQUISA',{ || sfAgenda() } , OemToAnsi("Gerar Agenda"),OemToAnsi("Gerar Agenda")})

	// IAGO 22/06/2017 Projeto Agenda
	Aadd(aButtons,{'PESQUISA',{ || sfAgeAut() } , OemToAnsi("Gerar Agenda Aut."),OemToAnsi("Gerar Agenda Aut.")})
	
	
	Aadd(aButtons,{'PESQUISA',{ || sfSearch() } , OemToAnsi("Localizar"),OemToAnsi("Localizar")})
	
	//IAGO 17/05/2017
	Aadd(aButtons,{'PESQUISA',{ || U_BFFATA57() } , OemToAnsi("Imp.CSV Clientes"),OemToAnsi("Imp.CSV Clientes")})


	
	ACTIVATE MSDIALOG oDlgAgenda ON INIT EnchoiceBar(oDlgAgenda,{|| sfGrava(),Pergunte(cPerg1,.F.),sfMontaCols(NOPC_CLI),sfMontaCols(NOPC_ROT)},{|| oDlgAgenda:End() },,aButtons) Centered
	
Return

/*/{Protheus.doc} sfMontaCols
Montagem do aCols da rotina
@type function
@version 12.1.33
@author Marcelo Lauschner
@since 9/17/2014
@param nInOpc, numeric, número da opção
/*/
Static Function sfMontaCols(nInOpc)
	
	Local cQry      := ""
	Local aStruSA1  := SA1->(dbStruct())
	Local cAliasSA1 := "QSA1"
	Local nLinAdd   := 0
	local nIX       := 0 as numeric
	
	If nInOpc == NOPC_CLI
		
		oGetCli:aCols	:= {}
		
		cQry := "SELECT A1_COD,A1_LOJA,A1_NOME,A1_END,A1_BAIRRO,A1_MUN,A1_EST,A1_SEMTMK,"
		cQry += "       A1_TABELA,A1_GERAT,A1_TEMVIS,A1_DIAWEEK,A1_SEQVIST,A1_CEP,A1_VEND,A1_VEND2,A1_VEND3,A1_VEND4,A1_POTENC,A1_POTENC2, "
		cQry += "       COALESCE((SELECT MAX(PAB_ROTA) "
		cQry += "              FROM " + RetSqlName("PAB") + " PAB "
		cQry += "             WHERE D_E_L_E_T_ = ' ' "
		cQry += "               AND PAB_CEP = A1_CEP "
		cQry += "               AND PAB_FILIAL = '" + xFilial("PAB") + "'),' ') A1_ROTA "
		cQry += "  FROM " +RetSqlName("SA1") + " A1 "
		cQry += " WHERE D_E_L_E_T_ = ' ' "
		cQry += "   AND A1_CEP BETWEEN '" + MV_PAR03 + "' AND '" + MV_PAR04 + "' "
		cQry += "   AND (A1_VEND BETWEEN '" + MV_PAR01 + "'  AND '" + MV_PAR02 + "' "
		If !Empty(MV_PAR05)
			cQry += "  OR A1_VEND2 = '" +MV_PAR05 + "' "
		Endif
		If !Empty(MV_PAR06)
			cQry += "  OR A1_VEND3 = '" +MV_PAR06 + "' "
		Endif
		If !Empty(MV_PAR07)
			cQry += "  OR A1_VEND4 = '" +MV_PAR07 + "' "
		Endif
		cQry += "   )"
		cQry += "   AND A1_MSBLQL <> '1' "
		cQry += "   AND A1_FILIAL = '" + xFilial("SA1") + "'  "
		cQry += " ORDER BY A1_CEP,A1_MUN,A1_BAIRRO,A1_END "
		
		dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),cAliasSA1,.T.,.T.)
		
		For nIX := 1 To Len(aStruSA1)
			If aStruSA1[nIX,2]<>"C"
				TcSetField(cAliasSA1,aStruSA1[nIX,1],aStruSA1[nIX,2],aStruSA1[nIX,3],aStruSA1[nIX,4])
			EndIf
		Next nIX
		
		While !Eof()
			Aadd(oGetCli:aCols,Array(Len(oGetCli:aHeader)+1))
			nLinAdd++
			oGetCli:aCols[nLinAdd,nPcCod]                 := (cAliasSA1)->A1_COD
			oGetCli:aCols[nLinAdd,nPcLoja]                := (cAliasSA1)->A1_LOJA
			oGetCli:aCols[nLinAdd,nPcNome]                := (cAliasSA1)->A1_NOME
			oGetCli:aCols[nLinAdd,nPcEnd]                 := (cAliasSA1)->A1_END
			oGetCli:aCols[nLinAdd,nPcBairro]              := (cAliasSA1)->A1_BAIRRO
			oGetCli:aCols[nLinAdd,nPcMun]                 := (cAliasSA1)->A1_MUN
			oGetCli:aCols[nLinAdd,nPcEst]                 := (cAliasSA1)->A1_EST
			oGetCli:aCols[nLinAdd,nPcCep]                 := (cAliasSA1)->A1_CEP
			oGetCli:aCols[nLinAdd,nPcTabela]              := (cAliasSA1)->A1_TABELA
			oGetCli:aCols[nLinAdd,nPcGerat]               := (cAliasSA1)->A1_GERAT
			oGetCli:aCols[nLinAdd,nPcVend]                := (cAliasSA1)->A1_VEND
			oGetCli:aCols[nLinAdd,nPcVend2]               := (cAliasSA1)->A1_VEND2
			oGetCli:aCols[nLinAdd,nPcVend3]               := (cAliasSA1)->A1_VEND3
			oGetCli:aCols[nLinAdd,nPcVend4]               := (cAliasSA1)->A1_VEND4
			oGetCli:aCols[nLinAdd,nPcSemTmk]              := (cAliasSA1)->A1_SEMTMK
			oGetCli:aCols[nLinAdd,nPcDiaWeek]             := (cAliasSA1)->A1_DIAWEEK
			oGetCli:aCols[nLinAdd,nPcTemVis]              := (cAliasSA1)->A1_TEMVIS
			oGetCli:aCols[nLinAdd,nPcSeqVist]             := (cAliasSA1)->A1_SEQVIST
			oGetCli:aCols[nLinAdd,nPcPotenc]              := (cAliasSA1)->A1_POTENC
			oGetCli:aCols[nLinAdd,nPcPotenc2]             := (cAliasSA1)->A1_POTENC2
			oGetCli:aCols[nLinAdd,nPcRota]                := (cAliasSA1)->A1_ROTA
			oGetCli:aCols[nLinAdd,Len(oGetCli:aHeader)+1] := .F.
			
			DbSelectarea(cAliasSA1)
			DbSkip()
		Enddo
		(cAliasSA1)->(dbclosearea())
		oGetCli:Refresh()
	ElseIf nInOpc == NOPC_ROT
		oGetRot:aCols	:= {}
		
		cQry := "SELECT A1_COD,A1_LOJA,A1_NOME,A1_MUN,A1_EST,A1_SEMTMK,A1_TEMVIS,A1_DIAWEEK,A1_SEQVIST, "
		cQry += "       A1_END,A1_BAIRRO,A1_CEP,A1_VEND,A1_ULTCOM,A1_CONTATO,CONCAT(A1_DDD,A1_TEL) A1_TEL ,"
		cQry += "       A1_ULTVIS,A1_POTENC,A1_POTENC2,"
		cQry += "       COALESCE((SELECT MAX(PAB_ROTA) "
		cQry += "              FROM " + RetSqlName("PAB") + " PAB "
		cQry += "             WHERE D_E_L_E_T_ = ' ' "
		cQry += "               AND PAB_CEP = A1_CEP "
		cQry += "               AND PAB_FILIAL = '" + xFilial("PAB") + "'),' ') A1_ROTA, "
		cQry += "       "+ RetSem(oCalend2:dDiaAtu) + " SEMANA, "
		cQry += "       " + cValToChar(NoRound(Val(RetSem(oCalend2:dDiaAtu))/4,0)+1) + " NVEZ "
		cQry += "  FROM " +RetSqlName("SA1") + " A1 "
		cQry += " WHERE D_E_L_E_T_ = ' ' "
		cQry += "   AND CASE "
		cQry += "         WHEN (" + RetSem(oCalend2:dDiaAtu) + " - CASE WHEN A1_SEMTMK = ' ' THEN '0' ELSE A1_SEMTMK END) % (A1_TEMVIS / 7)) = 0 THEN "
		cQry += "            CASE WHEN " + RetSem(oCalend2:dDiaAtu) + " % 4 = 0 THEN "
		cQry += "                4 "
		cQry += "              ELSE "
		cQry += "                " + RetSem(oCalend2:dDiaAtu) + " % 4 "
		cQry += "              END "
		cQry += "         ELSE "
		cQry += "          0 "
		cQry += "       END <> 0 "
		cQry += "   AND A1_CEP BETWEEN '" + MV_PAR03 + "' AND '" + MV_PAR04 + "' "
		cQry += "   AND (A1_VEND BETWEEN '" + MV_PAR01 + "'  AND '" + MV_PAR02 + "' "
		If !Empty(MV_PAR05)
			cQry += "  OR A1_VEND2 = '" +MV_PAR05 + "' "
		Endif
		If !Empty(MV_PAR06)
			cQry += "  OR A1_VEND3 = '" +MV_PAR06 + "' "
		Endif
		If !Empty(MV_PAR07)
			cQry += "  OR A1_VEND4 = '" +MV_PAR07 + "' "
		Endif
		cQry += "   )"
		cQry += "   AND A1_MSBLQL <> '1' "
		cQry += "   AND "+ cValToChar(Day(oCalend2:dDiaAtu)) +" = A1_DIAWEEK "
		cQry += "   AND A1_FILIAL = '" + xFilial("SA1") + "'  "
		cQry += " ORDER BY A1_SEQVIST "
		
		dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),cAliasSA1,.T.,.T.)
		
		For nIX := 1 To Len(aStruSA1)
			If aStruSA1[nIX,2]<>"C"
				TcSetField(cAliasSA1,aStruSA1[nIX,1],aStruSA1[nIX,2],aStruSA1[nIX,3],aStruSA1[nIX,4])
			EndIf
		Next nIX
		
		While !Eof()
			Aadd(oGetRot:aCols,Array(Len(oGetRot:aHeader)+1))
			nLinAdd++
			oGetRot:aCols[nLinAdd,nPrCod]                 := (cAliasSA1)->A1_COD
			oGetRot:aCols[nLinAdd,nPrLoja]                := (cAliasSA1)->A1_LOJA
			oGetRot:aCols[nLinAdd,nPrNome]                := (cAliasSA1)->A1_NOME
			oGetRot:aCols[nLinAdd,nPrMun]                 := (cAliasSA1)->A1_MUN
			oGetRot:aCols[nLinAdd,nPrEst]                 := (cAliasSA1)->A1_EST
			oGetRot:aCols[nLinAdd,nPrEnd]                 := (cAliasSA1)->A1_END
			oGetRot:aCols[nLinAdd,nPrBairro]              := (cAliasSA1)->A1_BAIRRO
			oGetRot:aCols[nLinAdd,nPrCep]                 := (cAliasSA1)->A1_CEP
			oGetRot:aCols[nLinAdd,nPrVend]                := (cAliasSA1)->A1_VEND
			oGetRot:aCols[nLinAdd,nPrUltCom]              := (cAliasSA1)->A1_ULTCOM
			oGetRot:aCols[nLinAdd,nPrUltVis]              := (cAliasSA1)->A1_ULTVIS
			oGetRot:aCols[nLinAdd,nPrPotenc]              := (cAliasSA1)->A1_POTENC
			oGetRot:aCols[nLinAdd,nPrPotenc2]             := (cAliasSA1)->A1_POTENC2
			oGetRot:aCols[nLinAdd,nPrContato]             := (cAliasSA1)->A1_CONTATO
			oGetRot:aCols[nLinAdd,nPrTel]                 := (cAliasSA1)->A1_TEL
			oGetRot:aCols[nLinAdd,nPrSemTmk]              := (cAliasSA1)->A1_SEMTMK
			oGetRot:aCols[nLinAdd,nPrDiaWeek]             := (cAliasSA1)->A1_DIAWEEK
			oGetRot:aCols[nLinAdd,nPrTemVis]              := (cAliasSA1)->A1_TEMVIS
			oGetRot:aCols[nLinAdd,nPrSeqVist]             := (cAliasSA1)->A1_SEQVIST
			oGetRot:aCols[nLinAdd,nPrRota]                := (cAliasSA1)->A1_ROTA
			oGetRot:aCols[nLinAdd,Len(oGetRot:aHeader)+1] := .F.
			
			DbSelectarea(cAliasSA1)
			DbSkip()
		Enddo
		(cAliasSA1)->(dbclosearea())
		oGetRot:Refresh()
		
	Endif
	
Return

/*/{Protheus.doc} sfVldPerg
Valida perguntas da SX1
@type function
@version 12.1.33
@author Marcelo Lauschner
@since 8/2/2014
/*/
Static Function sfVldPerg()
	
	// Local	aSx1Cab		:= {"X1_GRUPO",;	//1
	// 						"X1_ORDEM",;	//2
	// 						"X1_PERGUNT",;	//3	
	// 						"X1_VARIAVL",;	//4
	// 						"X1_TIPO",;		//5
	// 						"X1_TAMANHO",;	//6
	// 						"X1_DECIMAL",;	//7
	// 						"X1_PRESEL",;	//8
	// 						"X1_GSC",;		//9
	// 						"X1_VAR01",;	//10	
	// 						"X1_F3"}		//11
							
	Local	aSX1Resp	:= {}
	
	Aadd(aSX1Resp,{	cPerg1,;					//1
					'01',;					//2
					'Vendedor De',;		//3
					'mv_ch1',;				//4
					'C',;					//5
					6,;						//6
					0,;						//7
					0,;						//8
					'G',;					//9	
					'mv_par01',;			//10
					'SA3'})					//11
	
	Aadd(aSX1Resp,{	cPerg1,;					//1
					'02',;					//2
					'Vendedor Até',;		//3
					'mv_ch2',;				//4
					'C',;					//5
					6,;						//6
					0,;						//7
					0,;						//8
					'G',;					//9	
					'mv_par02',;			//10
					'SA3'})					//11

	Aadd(aSX1Resp,{	cPerg1,;					//1
					'03',;					//2
					'CEP Inicial',;		//3
					'mv_ch3',;				//4
					'C',;					//5
					8,;						//6
					0,;						//7
					0,;						//8
					'G',;					//9	
					'mv_par03',;			//10
					'PAB'})					//11
					
	Aadd(aSX1Resp,{	cPerg1,;					//1
					'04',;					//2
					'CEP Inicial',;		//3
					'mv_ch4',;				//4
					'C',;					//5
					8,;						//6
					0,;						//7
					0,;						//8
					'G',;					//9	
					'mv_par04',;			//10
					'PAB'})					//11					
	
	Aadd(aSX1Resp,{	cPerg1,;					//1
					'05',;					//2
					'Vend.Espec.2',;		//3
					'mv_ch5',;				//4
					'C',;					//5
					6,;						//6
					0,;						//7
					0,;						//8
					'G',;					//9	
					'mv_par05',;			//10
					'SA3'})					//11
	Aadd(aSX1Resp,{	cPerg1,;					//1
					'06',;					//2
					'Vend.Espec.3',;		//3
					'mv_ch6',;				//4
					'C',;					//5
					6,;						//6
					0,;						//7
					0,;						//8
					'G',;					//9	
					'mv_par06',;			//10
					'SA3'})					//11
					
	Aadd(aSX1Resp,{	cPerg1,;					//1
					'07',;					//2
					'Vend.Espec.4',;		//3
					'mv_ch7',;				//4
					'C',;					//5
					6,;						//6
					0,;						//7
					0,;						//8
					'G',;					//9	
					'mv_par07',;			//10
					'SA3'})					//11										
						
	// Grava Perguntas				
    //U_XPUTSX1(aSx1Cab,aSX1Resp,.T./*lForceAtuSx1*/)
	
	
	
	
Return

/*/{Protheus.doc} sfGrava
Função para gravação dos dados
@type function
@version 12.1.33
@author Marcelo Lauschner
@since 9/17/2014
/*/
Static Function sfGrava()
	
	Local	iX
	DbSelectArea("SA1")
	DbSetOrder(1)
	
	If oFolder1:nOption == 1	// Selecão de clientes
		For iX := 1 To Len(oGetCli:aCols)
			
			DbSelectArea("SA1")
			If DbSeek(xFilial("SA1")+oGetCli:aCols[iX,nPcCod]+oGetCli:aCols[iX,nPcLoja])
				RecLock("SA1",.F.)
				SA1->A1_SEMTMK	:= oGetCli:aCols[iX,nPcSemTmk]
				SA1->A1_DIAWEEK	:= oGetCli:aCols[iX,nPcDiaWeek]
				SA1->A1_TEMVIS	:= oGetCli:aCols[iX,nPcTemVis]
				SA1->A1_SEQVIST	:= oGetCli:aCols[iX,nPcSeqVist]
				SA1->A1_GERAT	:= oGetCli:aCols[iX,nPcGerat]
				SA1->A1_TABELA	:= oGetCli:aCols[iX,nPcTabela]
				SA1->A1_VEND	:= oGetCli:aCols[iX,nPcVend]
				SA1->A1_VEND2	:= oGetCli:aCols[iX,nPcVend2]
				SA1->A1_VEND3	:= oGetCli:aCols[iX,nPcVend3]
				SA1->A1_VEND4	:= oGetCli:aCols[iX,nPcVend4]
				SA1->A1_POTENC	:= oGetCli:aCols[iX,nPcPotenc]
				SA1->A1_POTENC2	:= oGetCli:aCols[iX,nPcPotenc2]
				MsUnlock()
			Endif
		Next
	ElseIf oFolder1:nOption == 2 // Roteiros por dia selecionado
		
		For iX := 1 To Len(oGetRot:aCols)
			
			DbSelectArea("SA1")
			If DbSeek(xFilial("SA1")+oGetRot:aCols[iX,nPrCod]+oGetRot:aCols[iX,nPrLoja])
				RecLock("SA1",.F.)
				SA1->A1_SEMTMK	:= oGetRot:aCols[iX,nPrSemTmk]
				SA1->A1_DIAWEEK	:= oGetRot:aCols[iX,nPrDiaWeek]
				SA1->A1_TEMVIS	:= oGetRot:aCols[iX,nPrTemVis]
				SA1->A1_SEQVIST	:= oGetRot:aCols[iX,nPrSeqVist]
				SA1->A1_VEND	:= oGetRot:acols[iX,nPrVend]
				SA1->A1_POTENC	:= oGetRot:aCols[iX,nPrPotenc]
				SA1->A1_POTENC2	:= oGetRot:aCols[iX,nPrPotenc2]
				MsUnlock()
			Endif
		Next
		
	Endif
	
	MsgInfo("Gravação de dados finalizada!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Informação!")
	
Return

/*/{Protheus.doc} sfViewMaps
Função para visualização do cliente no Google Maps
@type function
@version 12.1.33
@author Marcelo Lauschner
@since 9/17/2014
@param nInOpc, numeric, opção escolhida
/*/
Static Function sfViewMaps(nInOpc)
	
	Local sb
	local iX       := 0 as numeric
	Default nInOpc := 1
	
	sb 	:= "https://www.google.com.br/maps/dir/"
	DbSelectArea("SA1")
	DbSetOrder(1)
	
	For iX := 1 To Len(oGetRot:aCols)
		
		DbSelectArea("SA1")
		If DbSeek(xFilial("SA1")+oGetRot:aCols[iX,nPrCod]+oGetRot:aCols[iX,nPrLoja])
			If iX > 1
				sb += "/"
			Endif
			sb 	+=  StrTran(StrTran(Alltrim(SA1->A1_END),"/"," ")," ","+")
			sb	+=  ",+"
			sb 	+=  StrTran(StrTran(Alltrim(SA1->A1_BAIRRO),"/"," ")," ","+")
			sb	+=  ",+"
			sb 	+=  StrTran(StrTran(Alltrim(SA1->A1_MUN),"/"," ")," ","+")
			sb	+=  ",+"
			sb 	+=  StrTran(Alltrim(SA1->A1_EST)," ","+")
			sb	+=  ",+"
			sb 	+=  StrTran(Alltrim(SA1->A1_CEP)," ","+")
			
		Endif
	Next
	//Aviso(ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Link",sb,{"Ok"},3)
	
	
	// Se for a opção abrir no navegador
	If nInOpc == 2
		ShellExecute( "Open", sb, "", "C:\", 1 )
	Else
		cTGet2	:= sb
		oGetUrl:CtrlRefresh()
		//oTIBrowser:Navigate(sb)
	Endif
	
Return

/*/{Protheus.doc} sfExpExcel
Função de exportação dos dados para excel
@type function
@version 12.1.33
@author Marcelo Lauschner
@since 2/20/2012
/*/
Static Function sfExpExcel()
	
	Local	aDadExp	:= {}
	
	If Len(oGetCli:aCols) > 0
		Aadd(aDadExp,{"GETDADOS","Roteiro Vendedor",oGetCli:aHeader,oGetCli:aCols})
	Endif
	
	If Len(oGetRot:aCols) > 0
		Aadd(aDadExp,{"GETDADOS","Roteiro Dia "+ DTOC(oCalend2:dDiaAtu),oGetRot:aHeader,oGetRot:aCols})
	Endif
	
	If FindFunction("RemoteType") .And. RemoteType() == 1 .And. Len(aDadExp) > 0
		DlgToExcel(aDadExp)
	EndIf
	
Return

/*/{Protheus.doc} sfSearch
Pesquisa dados no aCols
@type function
@version 12.1.33
@author Marcelo Lauschner
@since 9/17/2014
/*/
Static Function sfSearch()
	
	Local	cTipoBox	:= "C"
	Local	cGetPesq	:= Space(100)
	Local	lContinua	:= .F.
	Local	nPosView	:= 0
	Local	iX
	
	DEFINE MSDIALOG oDlgS TITLE (ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Alterar Tomador do Serviço do Frete!") FROM 001,001 TO 170,400 PIXEL
	@ 010,018 Say "Selecione uma Opção de Pesquisa" Pixel of oDlgS
	@ 010,110 Combobox cTipoBox Items {"C=Código","N=Nome"} Pixel of oDlgS
	@ 022,018 MsGet cGetPesq Size 100,10 Pixel of oDlgS
	@ 035,018 BUTTON "Confirma" Size 40,10 Pixel of oDlgS Action (lContinua	:= .T.,oDlgS:End())
	@ 035,068 BUTTON "Cancela"  Size 40,10 Pixel of oDlgS Action (oDlgS:End())
	
	ACTIVATE MSDIALOG oDlgS CENTERED
	
	If !lContinua
		Return
	Endif
	cGetPesq := Alltrim(Upper(cGetPesq))
	
	If oFolder1:nOption == 1	// Selecão de clientes
		For iX := 1 To Len(oGetCli:aCols)
			If cTipoBox == "C"
				If cGetPesq $ oGetCli:aCols[iX,nPcCod] + "-" +oGetCli:aCols[iX,nPcLoja]
					nPosView	:= iX
					Exit
				Endif
			ElseIf cTipoBox == "N"
				If cGetPesq $ oGetCli:aCols[iX,nPcNome]
					nPosView	:= ix
					Exit
				Endif
			Endif
		Next
		If nPosView > 0
			oGetCli:Goto(nPosView)
			oGetCli:oBrowse:SetFocus()
		Endif
	ElseIf oFolder1:nOption == 2
		For iX := 1 To Len(oGetRot:aCols)
			If cTipoBox == "C"
				If cGetPesq $ oGetRot:aCols[iX,nPrCod] + "-" +oGetRot:aCols[iX,nPrLoja]
					nPosView	:= iX
					Exit
				Endif
			ElseIf cTipoBox == "N"
				If cGetPesq $ oGetRot:aCols[iX,nPrNome]
					nPosView	:= ix
					Exit
				Endif
			Endif
		Next
		If nPosView > 0
			oGetRot:Goto(nPosView)
			oGetRot:oBrowse:SetFocus()
		Endif
	Endif
Return



Static Function sfAgenda()


	Local aPergs    := {}
	Local aRet      := {}
	Local aRestPerg := sfRestPerg(.T./*lSalvaPerg*/,/*aPerguntas*/,9/*nTamSx1*/)
	local iX        := 0 as numeric
	
	Aadd(aPergs,{1,"Operador",Space(6)				,				,"ExistCpo('SU7')"	,"SU7"	,".T.",6,.T.})
	Aadd(aPergs,{1,"Emissão" ,oCalend2:dDiaAtu 		,"99/99/9999"	,'.T.'				,		,".T.",45,.T.})
					
	If !ParamBox(@aPergs,"Parâmetro Geração Agenda ",aRet)
		MsgAlert("Operação cancelada.","Alerta: "+ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		Return
	EndIf
	
	DbSelectArea("SU7")
	DbSetOrder(1)
	DbSeek(xFilial("SU7")+mv_par01)	
				
	DbselectArea("SU4")
	Dbsetorder(1)
				
	cSU4Lista	:=	GetSxeNum( "SU4" ,"U4_LISTA")
	ConfirmSX8()
				
	While DbSeek(xFilial() + cSU4Lista )
		cSU4Lista	:=	GetSxeNum( "SU4" ,"U4_LISTA")
		ConfirmSX8()
	EndDo
				
	DbselectArea("SU4")
	RecLock("SU4",.T.)
	SU4->U4_FILIAL	:= xFilial("SU4")
	SU4->U4_STATUS 	:= "1" 										//	Ativa
	SU4->U4_TIPO 	:= "3" 										//	Vendas
	SU4->U4_LISTA 	:= cSU4Lista								//	GetSxeNum("SU4","U4_LISTA") //	Codigo do atendimento
	SU4->U4_DESC 	:= "Roteiro dia: " + DTOC(oCalend2:dDiaAtu) + " Operador "+ SU7->U7_COD+ "-'" + SU7->U7_NOME
	SU4->U4_DATA 	:= MV_PAR02
	SU4->U4_HORA1 	:= "08:00:00"
	SU4->U4_FORMA 	:= "1" 										//	VOZ
	SU4->U4_TELE  	:= "2" 										//	TELEVENDAS
	SU4->U4_OPERAD 	:= mv_par01
	SU4->U4_TIPOTEL := "1" 										//	RESIDENCIAL
	SU4->U4_DTVISIT := oCalend2:dDiaAtu  
	SU4->U4_OBSVEN  := "Agenda gerada em " + DTOC(Date()) + " " + Time() + " por " + cUserName
				
	MsUnlock()
	cLista	:= SU4->U4_LISTA
	
	For iX := 1 To Len(oGetRot:aCols)
			
		DbSelectArea("SA1")
		If DbSeek(xFilial("SA1")+oGetRot:aCols[iX,nPrCod]+oGetRot:aCols[iX,nPrLoja])
			
			cNumSU6	:= StrZero(iX,6)
			
			cContato	:= U_BFTMKG01(SA1->A1_COD,SA1->A1_LOJA)
			
			DbSelectArea("SU6")
			RecLock("SU6", .T.)
			SU6->U6_FILIAL	:= xFilial("SU6")
			SU6->U6_LISTA	:= cLista   								//	Codigo do atendimento
			SU6->U6_CODIGO	:= cNumSU6									//	GetSxeNum("SU6","U6_CODIGO")
			SU6->U6_FILENT	:= xFilial( "SA1" )				 			//	xFilial("SA1")
			SU6->U6_ENTIDA	:= "SA1"									//	"SA1"
			SU6->U6_CODENT	:= SA1->A1_COD + SA1->A1_LOJA
			SU6->U6_ORIGEM	:= "3"  									//	Atendimento
			SU6->U6_CONTATO	:= cContato
			SU6->U6_DATA	:= oCalend2:dDiaAtu
			SU6->U6_HRINI 	:= "08:00"
			SU6->U6_HRFIM	:= "23:59"
			SU6->U6_STATUS	:= "1"   									//	Nao enviado
			
			MsUnlock()
		Endif
	Next
	sfRestPerg(/*lSalvaPerg*/,aRestPerg/*aPerguntas*/,/*nTamSx1*/)
	MsgInfo("Lista de operador Gerada!")
Return 
	



Static Function sfAgeAut()

	Local	aPergs 		:= {}
	Local	aRet 		:= {}
	Local	aRestPerg	:= sfRestPerg(.T./*lSalvaPerg*/,/*aPerguntas*/,9/*nTamSx1*/)
	
	Aadd(aPergs,{1,"Operador",Space(6)		,				,"ExistCpo('SU7')"	,"SU7"	,".T.",6,.T.})
	Aadd(aPergs,{1,"Vendedor",Space(6)		,				,"ExistCpo('SA3')"	,"SA3"	,".T.",6,.T.})
	Aadd(aPergs,{1,"Data De" ,Date() 		,"99/99/9999"	,'.T.'				,		,".T.",45,.T.})
	Aadd(aPergs,{1,"Data Até",Date() 		,"99/99/9999"	,'.T.'				,		,".T.",45,.T.})
						
	If !ParamBox(@aPergs,"Parâmetro Geração Agenda ",aRet)
		MsgAlert("Operação cancelada.","Alerta: "+ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		Return
	EndIf
	
	DbSelectArea("SU7")
	DbSetOrder(1)
	DbSeek(xFilial("SU7")+MV_PAR01)	
	
	Private dDataDe := MV_PAR03
	Private dDataAte := MV_PAR04
	
	While dDataDe <= dDataAte 
	
		cQry := "SELECT A1_COD, A1_LOJA"
		cQry += "  FROM " +RetSqlName("SA1") + " A1 "
		cQry += " WHERE D_E_L_E_T_ = ' ' "
		cQry += "   AND CASE "
		cQry += "         WHEN (" + RetSem(oCalend2:dDiaAtu) + " - CASE WHEN A1_SEMTMK = ' ' THEN '0' ELSE A1_SEMTMK END) % (A1_TEMVIS / 7)) = 0 THEN "
		cQry += "            CASE WHEN " + RetSem(oCalend2:dDiaAtu) + " % 4 = 0 THEN "
		cQry += "                4 "
		cQry += "              ELSE "
		cQry += "                " + RetSem(oCalend2:dDiaAtu) + " % 4 "
		cQry += "              END "
		cQry += "         ELSE "
		cQry += "          0 "
		cQry += "       END <> 0 "
		cQry += "   AND A1_VEND = '" + MV_PAR02 + "'"
		cQry += "   AND A1_MSBLQL <> '1' "
		cQry += "   AND TO_CHAR(TO_DATE('"+ DTOS(dDataDe) +"', 'YYYYMMDD'), 'D') = A1_DIAWEEK "
		cQry += "   AND A1_FILIAL = '" + xFilial("SA1") + "' "
		cQry += " ORDER BY A1_SEQVIST "
		
		TCQUERY cQry NEW ALIAS "QRYA"
		
		If QRYA->(!EOF())
			
			DbselectArea("SU4")
			Dbsetorder(1)
						
			cSU4Lista	:=	GetSxeNum( "SU4" ,"U4_LISTA")
			ConfirmSX8()
						
			While DbSeek(xFilial() + cSU4Lista )
				cSU4Lista	:=	GetSxeNum( "SU4" ,"U4_LISTA")
				ConfirmSX8()
			EndDo
						
			DbselectArea("SU4")
			RecLock("SU4",.T.)
			SU4->U4_FILIAL	:= xFilial("SU4")
			SU4->U4_STATUS 	:= "1" 										//	Ativa
			SU4->U4_TIPO 	:= "3" 										//	Vendas
			SU4->U4_LISTA 	:= cSU4Lista								//	GetSxeNum("SU4","U4_LISTA") //	Codigo do atendimento
			SU4->U4_DESC 	:= "Roteiro dia: " + DTOC(dDataDe) + " Operador "+ SU7->U7_COD + "-'" + SU7->U7_NOME
			SU4->U4_DATA 	:= dDataDe
			SU4->U4_HORA1 	:= "08:00"
			SU4->U4_FORMA 	:= "1" 										//	VOZ
			SU4->U4_TELE  	:= "2" 										//	TELEVENDAS
			SU4->U4_OPERAD 	:= MV_PAR01
			SU4->U4_TIPOTEL := "1" 										//	RESIDENCIAL
			SU4->U4_DTVISIT := dDataDe  
			SU4->U4_OBSVEN  := "Agenda gerada em " + DTOC(Date()) + " " + Time() + " por " + cUserName
			MsUnlock()
			
			cLista	:= SU4->U4_LISTA
			iX := 1

			While QRYA->(!EOF())
				
				cNumSU6	:= StrZero(iX,6)
				cContato	:= U_BFTMKG01(QRYA->A1_COD,QRYA->A1_LOJA)
				DbSelectArea("SU6")
				RecLock("SU6", .T.)
				SU6->U6_FILIAL	:= xFilial("SU6")
				SU6->U6_LISTA	:= cLista   								//	Codigo do atendimento
				SU6->U6_CODIGO	:= cNumSU6									//	GetSxeNum("SU6","U6_CODIGO")
				SU6->U6_FILENT	:= xFilial( "SA1" )				 			//	xFilial("SA1")
				SU6->U6_ENTIDA	:= "SA1"									//	"SA1"
				SU6->U6_CODENT	:= QRYA->A1_COD + QRYA->A1_LOJA
				SU6->U6_ORIGEM	:= "3"  									//	Atendimento
				SU6->U6_CONTATO	:= cContato
				SU6->U6_DATA	:= dDataDe
				SU6->U6_HRINI 	:= "08:00"
				SU6->U6_HRFIM	:= "23:59"
				SU6->U6_STATUS	:= "1"   									//	Nao enviado
				MsUnlock()
				
				iX := iX + 1
				QRYA->(dbSkip())	
			End		
		End
		
		dDataDe := dDataDe + 1
		QRYA->(dbCloseArea())
	End
	
	sfRestPerg(/*lSalvaPerg*/,aRestPerg/*aPerguntas*/,/*nTamSx1*/)
	MsgInfo("Lista de operador Gerada!")
Return 		

/*/{Protheus.doc} sfRestPerg
Função para restaurar as perguntas para controle da rotina
@type function
@version 12.1.33
@author Marcelo Lauschner
@since 4/22/2014
@param lSalvaPerg, logical, indica se deve ou não salvar as respostas das perguntas
@param aPerguntas, array, vetor contendo os parâmetros das perguntas
@param nTamSx1, numeric, tamanho da pergunta na SX1
@return array, aPerguntas
/*/
Static Function sfRestPerg(lSalvaPerg,aPerguntas,nTamSx1)
	
	Local ni
	DEFAULT lSalvaPerg	:=.F.
	Default nTamSX1		:= 40
	DEFAULT aPerguntas	:=Array(nTamSX1)
	
	For ni := 1 to Len(aPerguntas)
		If lSalvaPerg
			aPerguntas[ni] := &("mv_par"+StrZero(ni,2))
		Else
			&("mv_par"+StrZero(ni,2)) :=	aPerguntas[ni]
		EndIf
	Next ni
	
Return(aPerguntas)
