#include "Protheus.ch"

/*/{Protheus.doc} LEXPESA1
    PE para adição de campos customizados de clientes para integração da LexosHub
    @type function
    @version 1.0
    @author Daniel Scheeren - Gruppe
    @since 14/12/2023
    @return array, Array no formato padrão de Execauto com os campos a adicionar
/*/
User Function LEXPESA1()
    Local aCamposRet := {}
    Local jPedido    := PARAMIXB[1]
    Local aSA1Auto   := PARAMIXB[2]
    Local nPos       := 0

    If (nPos := AScan(aSA1Auto, {|aSA1| AllTrim(aSA1[1]) == "A1_BAIRRO" })) <> 0
        aAdd(aCamposRet, {"A1_BAIRROE"  ,  SubStr(aSA1Auto[nPos][2] , 1, TamSX3("A1_BAIRROE")[1]) 			,Nil})
        
    EndIf

    If (nPos := AScan(aSA1Auto, {|aSA1| AllTrim(aSA1[1]) == "A1_CEP" })) <> 0
        aAdd(aCamposRet, {"A1_CEPE"  ,aSA1Auto[nPos][2] 			,Nil})
    EndIf

    If (nPos := AScan(aSA1Auto, {|aSA1| AllTrim(aSA1[1]) == "A1_MUN" })) <> 0
        aAdd(aCamposRet, {"A1_MUNE"  ,aSA1Auto[nPos][2] 			,Nil})
    EndIf

   aAdd(aCamposRet, {"A1_NATUREZ" ,"1101      "        ,Nil})
   aAdd(aCamposRet, {"A1_SATIV1 " ,"999999"        ,Nil})
   aAdd(aCamposRet, {"A1_CONTRIB" ,"1"        ,Nil})

Return aCamposRet

