#include 'protheus.ch'
#include 'parmtype.ch'

User Function F090QFIL()

	Local cFiltro	:= PARAMIXB[1]  //recebe a cláusula WHERE atual da rotina

	//cFiltro := " E2_FILIAL = '01' AND E2_FORNECE BETWEEN '000001' AND '000002' AND E2_LOJA = '01' "
	//Aviso(ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" F090QFIL",cFiltro,{"Ok"},3)
	// E2_FILIAL = '  ' AND  E2_EMISSAO <= '20180120' AND  E2_PORTADO >= '   ' AND  E2_PORTADO <= 'ZZZ' AND  E2_VENCREA >= '20180120' AND  E2_VENCREA <= '20180123' AND  E2_NUMBOR = '      ' AND  E2_ORIGEM NOT IN ('SIGAEEC','SIGAEDC','SIGAECO','SIGAEFF','SIGAESS') AND  E2_TIPO NOT IN ('PR','PRE') AND  E2_TIPO NOT IN ('PR ','NDF','AB-','FB-','FC-','FU-','IR-','IN-','IS-','PI-','CF-','CS-','FE-','IV-') AND  E2_SALDO > 0 
	//MemoWrite('/log_sqls/f090qfil.sql',cFiltro)
	cFiltro := StrTran(cFiltro,"AND  E2_NUMBOR = '      '"," ")
	//Aviso(ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" F090QFIL",cFiltro,{"Ok"},3)
	
Return cFiltro 