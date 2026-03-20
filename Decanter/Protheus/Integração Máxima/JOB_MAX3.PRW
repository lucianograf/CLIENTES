/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³PROGRAMA  ³ JOB_PEDIDO  ³ AUTOR ³JONATHAN VIEIRA ALMEIDA DATA 14-08-2017±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÝÄÄÄÄÄÄÄÝÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÝÄÄÄÄÄÄÝÄÄÄÄÄÄÄÄÄÄ´±±
±±³DESCRICAO ³ IMPORTACAO DE DIGITACAO DE PEDIDOS VIA ARQUIVO TEXTO       ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±± ALTERAçãO:                                          DATA : 			   ±±
±± 																	       ±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³USO       ³ ESPECIFICO                                                 ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÝÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

#INCLUDE "RWMAKE.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "AP5MAIL.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "COLORS.CH"
#INCLUDE "FONT.CH"
//#INCLUDE "INKEY.CH"

USER FUNCTION JOB_MAX3()

PRIVATE VTIPOIMP := {}

//rotina verifica se esta em execução nao tenho certeza se faz isso.
//FWGetRunSchedule()
CONOUT("JOB_MAX3:VERIFICANDO JOB_MAX3...")

IF !IsInCallStack("U_XJOB1")
	U_XJOB3()
ELSE
	CONOUT("EST� SENDO USADA-JOB3")
Endif

RETURN

USER FUNCTION XJOB3()

CONOUT(TIME()+" JOB_MAX3:IMPORTANDO VIA API!")
U_ROTINA(,"4")
CONOUT(TIME()+" JOB_MAX3:IMPORTADO COM SUCESSO!")			

RETURN         

Static Function Scheddef()
Local aParam
Local aOrd     := {OemToAnsi(" Por Codigo         "),OemToAnsi(" Alfabetica         ")}
aParam := { "P",;                      //Tipo R para relatorio P para processo   
"ACA070",;// Pergunte do relatorio, caso nao use passar ParamDef            
"SA1",;  // Alias            
aOrd,;   //Array de ordens   
"Teste SchedDef"}    
Return aParam
