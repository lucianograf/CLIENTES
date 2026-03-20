#include "rwmake.ch"
#include "protheus.ch"
#INCLUDE "TOPCONN.CH"
#INCLUDE "COLORS.CH"
#INCLUDE "TBICONN.CH"



//---------------------------------------------------------------------------------------
// Analista   : Júnior Conte - 25/07/18
// Nome função: RLLOG05
// Parametros :
// Objetivo   : Interface consulta analitica de operações de armazenagem por produto.
// 			
// Retorno    :
// Alterações :
//---------------------------------------------------------------------------------------


USER FUNCTION RLLOG05()
	processa({|| sfconpro()})
return(.t.)

static function sfconpro()

	Local oLbxA
	private aParam    := {}
	private aButtons := {}
	private oFonte1 := TFont():New( "Arial",10,14,,.t. )

//Z23->(MSGoto(cRecno))

	cQuery := " SELECT * "
	cQuery += " FROM "
	cQuery += retsqlname("Z24") + " Z24 "
	cQuery += " WHERE "
	cQuery += " Z24.Z24_FILIAL = '" + Z23->Z23_FILIAL 		+ "' AND "
	cQuery += " Z24.Z24_CLIENT = '" + Z23->Z23_CLIENT 		+ "' AND "
	cQuery += " Z24.Z24_LOJA   = '" + Z23->Z23_LOJA   		+ "' AND "
	cQuery += " Z24.Z24_DATA   = '" + DTOS(Z23->Z23_DATA)   + "' AND "
	cQuery += " Z24.D_E_L_E_T_ = ' ' AND Z24.Z24_STATUS = '0' "

	cQuery := ChangeQuery(cQuery)
	TCQUERY cQuery NEW ALIAS "Work"

	aDiverg := {}

	DbSelectArea("Work")
	dbGoTop()
//nTotCr := 0
	while !eof()



		//nTotCr += Work->Z24_VALOR

		aadd(aParam,{ Work->Z24_FILIAL,  Work->Z24_PRODUT, Work->Z24_DESPRO, 	 Work->Z24_DOC, Work->Z24_SERVIC,   TRANSFORM( Work->Z24_VALOR, "@r 999,999,999.9999" ) ,  TRANSFORM( Work->Z24_QTDARM, "@r 999,999,999.9999" ),  TRANSFORM( Work->Z24_PERCUB, "@r 999,999,999.9999" ) })

		DbSelectArea("Work")
		dbskip()
	enddo


	if len(aParam) == 0
		DbSelectArea("Work")
		DbCloseArea("Work")
		return(.t.)
	endif


	DbSelectArea("SA1")
	dbseek(xfilial()+Z23->Z23_CLIENT+Z23->Z23_LOJA)


	asort(aParam,,,{|x,y| x[4]<y[4]})



	@ 000,000 TO 500,925 DIALOG oDlg TITLE "Lista de produtos Armazenados no dia " + DTOC(Z23->Z23_DATA) + " Para o Cliente: " + SA1->A1_NOME

//@ 160,005 SAY OemToAnsi("Total a Receber: ")
//oObj1:=TSay():New( 160,050, { || transform(nTotCr,"@E 999,999,999.99") }  , oDlg ,, oFonte1,.f.,.f.,.f.,.t.,CLR_HBLUE )


	@ 000,000 ListBox oLbxA Var cItBx Fields Header 'Filial','Codigo Produto','Descrição Produto','Nota', 'Servico', 'Valor','Qtd Arm', 'Cubagem' Size 462,150;
		On  DBLClick (Alert("Teste")) OF oLbxA PIXEL
	oLbxA:SetArray(aParam)
	oLbxA:bLine := { || {aParam[oLbxA:nAt,1],aParam[oLbxA:nAt,2],aParam[oLbxA:nAt,3],aParam[oLbxA:nAt,4], aParam[oLbxA:nAt,5], aParam[oLbxA:nAt,6], aParam[oLbxA:nAt,7], aParam[oLbxA:nAt,8]}}

//@ 232,360 BMPBUTTON TYPE 1 ACTION Processa({|| sefin07b(.T.)})

//@ 155,410 BUTTON "Marca/Desmarca" SIZE 50, 10 OF oDlg PIXEL Action (sefin07f(oLbxA:nAt,nTotCr),oLbxA:Refresh())  //     Font oDlg:oFont // "Novo"
	@ 232,398 BMPBUTTON TYPE 2 ACTION Close(oDlg)
//@ 232,436 BMPBUTTON TYPE 6 ACTION sefin07e()
	ACTIVATE DIALOG oDlg


	DbSelectArea("Work")
	DbCloseArea("Work")


return(.t.)




