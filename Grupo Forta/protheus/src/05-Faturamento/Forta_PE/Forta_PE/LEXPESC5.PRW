#include "Protheus.ch"

/*/{Protheus.doc} LEXPESC5
    PE para adição de campos customizados no cabeçalho de pedidos para integração da LexosHub
    @type function
    @version 1.0
    @author Daniel Scheeren - Gruppe
    @since 17/12/2023
    @return array, Array no formato padrão de Execauto com os campos a adicionar
/*/
User Function LEXPESC5()
	Local aCamposRet := {}
    Local jPedido    := PARAMIXB[1]

   aAdd(aCamposRet, {"C5_TABELA " ,"601"        ,Nil})
   aAdd(aCamposRet, {"C5_TIPOCLI" ,"F"        ,Nil})
   aAdd(aCamposRet, {"C5_BANCO  " ,"000"        ,Nil})
   aAdd(aCamposRet, {"C5_VEND1  " ,"000001"        ,Nil})

Return aCamposRet

