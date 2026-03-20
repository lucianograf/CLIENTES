#include 'totvs.ch'

// Função de gatilho para preencher o campo C6_CC/Decanter
User Function Gat_Vend()
   
   Local cVendedor  := M->C5_VEND1   // Aqui você pega o código do vendedor cadastrado
   Local cCentroCusto := ""

   // Verifica se o código do vendedor foi preenchido
   If !Empty(cVendedor)
      // Consulta a tabela de vendedores para obter o centro de custo
      DbSelectArea("SA3")
	  DbSetOrder(1)
	  DbSeek(xFilial("SA3")+cVendedor)
      cCentroCusto := alltrim(SA3->A3_ZCCUSTO)
   endif


Return cCentroCusto
