
/*/{Protheus.doc} Matucomp
Utilizado para alterações automáticas nos complementos dos documentos fiscais após a emissão das Notas Fiscais.

Eventos
Utilizado apos gravacao de todos os dados da NF de saida ou entrada digitadas no modulo fiscal, faturamento e compras.
@type function
@version  
@author Marcelo Alberto Lauschner / Diana Kistner 
@since 17/02/2021
@return return_type, return_description
/*/
User Function MATUCOMP() 

	Local lExiste   := .F.
    Local aArea     := GetArea()
    //aChave			Array of Record			Chave da Nota Fiscal (Entrada ou Saida,Serie,Doc,Cliente ou Fornecedor,Loja)

	dbSelectArea("CDD")
	CDD->(dbSetOrder(1))

	lExiste := CDD->(dbSeek(xFilial("CDD")+ParamIXB[1]+ParamIXB[2]+PADR(ParamIXB[3],TamSX3("CDD_DOC")[1])+ParamIXB[4]+ParamIXB[5]))

	If lExiste
		RecLock("CDD",.F.)
		If CDD->CDD_FILIAL == "0103"
		    CDD->CDD_IFCOMP :=  "000004"
		ElseIf CDD->CDD_FILIAL == "0105"
			CDD->CDD_IFCOMP :=  "000032"
		Endif
		MsUnlock()
	EndIf

	lExiste := .F.
	dbSelectArea("CDT")
	CDT->(dbSetOrder(1))
	lExiste := CDT->(dbSeek(xFilial("CDT")+ParamIXB[1]+ParamIXB[2]+PADR(ParamIXB[3],TamSX3("CDT_DOC")[1])+ParamIXB[4]+ParamIXB[5]))

	If lExiste
		RecLock("CDT",.F.)
		If CDT->CDT_FILIAL == "0103"
			CDT->CDT_IFCOMP := "000004"
		ElseIf CDT->CDT_FILIAL == "0105"
			CDT->CDT_IFCOMP := "000032"
		Endif 
		MsUnlock()
	Endif 
	
	RestArea(aArea)
Return
