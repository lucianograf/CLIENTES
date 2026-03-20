#INCLUDE "URZUM.CH"

//+-----------------------------------------------------------------------------------//
//|Empresa...: aFill Tecnologia
//|Funcao....: U_SIGAFIN()
//|Autor.....: aFill Tecnologia - suporte@afill.com.br
//|Data......: 06 de Outubro de 2011, 19:00
//|Uso.......: SIGACOM
//|Versao....: Protheus - 10
//|Descricao.: PE para n�o permitir a baixa de titulos de previs�o do template
//|Observa��o:
//+-----------------------------------------------------------------------------------//
// teste 20/03/2026//
*-----------------------------------------*
User Function SIGAFIN()
	*-----------------------------------------*

	MVPROVIS := Iif( !"|PRP|PRC" $ MVPROVIS,MVPROVIS+"|PRP|PRC",MVPROVIS)

Return





