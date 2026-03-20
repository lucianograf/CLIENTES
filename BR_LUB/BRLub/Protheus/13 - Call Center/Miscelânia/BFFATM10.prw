#include "protheus.ch"


/*/{Protheus.doc} BFFATM10
(Retorna o armazém da CC2 se houver distribuição pelo operador Logisitico )
	
@author MarceloLauschner
@since 31/05/2012
@version 1.0
		
@param lSUB, logico, Chamada via Callcenter ou não

@return cRetArm, Armazem valido

@example
(examples)

@see (links_or_references)
/*/
User Function BFFATM10(lSUB)
  
	Local	aAreaOld	:= GetArea()
	Local	nPxLocal	:= 0
	Local	nPxProduto	:= 0
	Local	cRetArm		:= "01"
	Local	cTipPed		:= Iif(Type("M->C5_TIPO") <> "U",M->C5_TIPO,"N")
	Local	cEmpFxc		:= Iif(Type("M->UA_XEMPFXC")<>"U",M->UA_XEMPFXC,Iif(Type("M->C5_XEMPFXC")<>"U",M->C5_XEMPFXC,"BF"))
	Local	cProduto		:= ""

	Default lSUB			:= .F.

// Gatilho conficu
	If !lSUB .And. cTipPed $ "N#B#D"
		nPxLocal	:= aScan(aHeader,{|x| Alltrim(x[2]) == "C6_LOCAL"})
		nPxProduto	:= aScan(aHeader,{|x| Alltrim(x[2]) == "C6_PRODUTO"})
	
		cRetArm		:= aCols[n,nPxLocal]
		cProduto 	:= aCols[n,nPxProduto]
	
		DbSelectArea("SA1")
		DbSetOrder(1)
		DbSeek(xFilial("SA1")+M->C5_CLIENTE+M->C5_LOJACLI)
	
		DbSelectArea("CC2")
		DbSetOrder(1) //CC2_FILIAL+CC2_EST+CC2_CODMUN
		DbSeek(xFilial("CC2")+SA1->A1_EST+SA1->A1_COD_MUN)
		If (cFilAnt $ "08") .And. !Empty(CC2->CC2_ARMPAD)
			cRetArm	:= CC2->CC2_ARMPAD
		Endif
		 
		DbSelectArea("SA3")
		DbSetOrder(1)
		DbSeek(xFilial("SA3")+M->C5_VEND1)
		cEmpFxc	:= SA3->A3_XSEGEMP+SA3->A3_XTPVEND
	Else
		nPxLocal	:= aScan(aHeader,{|x| Alltrim(x[2]) == "UB_LOCAL"})
		nPxProduto	:= aScan(aHeader,{|x| Alltrim(x[2]) == "UB_PRODUTO"})

		cRetArm	:= aCols[n,nPxLocal]
		cProduto 	:= aCols[n,nPxProduto]

		If Type("lProspect") <> "U" .And. !lProspect
			DbSelectArea("SA1")
			DbSetOrder(1)
			DbSeek(xFilial("SA1")+M->UA_CLIENTE+M->UA_LOJA)
			DbSelectArea("CC2")
			DbSetOrder(1) //CC2_FILIAL+CC2_EST+CC2_CODMUN
			DbSeek(xFilial("CC2")+SA1->A1_EST+SA1->A1_COD_MUN)
			If (cFilAnt $ "08") .And. !Empty(CC2->CC2_ARMPAD)
				cRetArm	:= CC2->CC2_ARMPAD
			Endif
		
		Else
			DbSelectArea("SUS")
			DbSetOrder(1)
			DbSeek(xFilial("SUS")+M->UA_CLIENTE+M->UA_LOJA)
			DbSelectArea("CC2")
			DbSetOrder(1) //CC2_FILIAL+CC2_EST+CC2_CODMUN
			DbSeek(xFilial("CC2")+SUS->US_EST+SUS->US_COD_MUN)
			If (cFilAnt $ "08") .And. !Empty(CC2->CC2_ARMPAD)
				cRetArm	:= CC2->CC2_ARMPAD
			Endif		
		Endif

	Endif

	RestArea(aAreaOld)

Return cRetArm
