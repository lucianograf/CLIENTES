#INCLUDE "rwmake.ch"

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³CADZM  º Autor ³ CHRISTIAN DANIEL COSTAº Data ³  27/07/10   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ TABELA DE DE PRODUTOS POR CLIENTE EM COMODATO              º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ BIG FORTA                                                  º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/

User Function CADZM


//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Declaracao de Variaveis                                             ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Private cString
Private cZMContr
Private cZMClie
Private cZMLoja         
cVldAlt := ".T." // Validacao para permitir a alteracao. Pode-se utilizar ExecBlock.
cVldExc := ".T." // Validacao para permitir a exclusao. Pode-se utilizar ExecBlock.
//aBotoes := {} //"VERMELHO",U_SBIMPSA1(),"Adicionar Produtos","Produtos"
// Executa gravação do Log de Uso da rotina
U_BFCFGM01()

Private cString := "SZM"

dbSelectArea("SZM")
dbSetOrder(1) 
//AADD(aBotoes,{"PRODUTO",{|| U_SB1XSZM(M->ZM_NUMCONT,M->ZM_CLIENTE,M->ZM_LOJA)},"Adicionar Produtos","Produtos"})
       
//AxCadastro(cString,"TAB CONTRATOS",cVldExc,cVldAlt, , ,{|| U_GravarSZO(M->ZM_NUMCONT)} , , , , ,aBotoes)
AxCadastro(cString,"TAB CONTRATOS",cVldExc,cVldAlt, , , ,{|| IIF(INCLUI .OR. ALTERA,U_SB1XSZM(M->ZM_NUMCONT,M->ZM_CLIENTE,M->ZM_LOJA),U_SB1XSZM(SZM->ZM_NUMCONT,SZM->ZM_CLIENTE,SZM->ZM_LOJA))} , , , ,)
//			1			2			 3		 4	   5 6 7			8											 9	 
Return 

