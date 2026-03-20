#include "rwmake.ch"

/*/{Protheus.doc} DIS014
(long_description)
@author MarceloLauschner
@since 15/06/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function DIS014()
	
	Local	 lContinua	:= .F.
	Private cNumnf  	:= Space(TamSX3("F2_DOC")[1])
	Private cTransp 	:= Space(6)
	Private cSerie  	:= GetMv("GM_SERIENF")
	Private nVolumes 	:= 0
	
	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()
	
	@ 200,1 TO 380,395 DIALOG oLeTxt TITLE OemToAnsi("Informacoes da NF")
	@ 02,10 TO 070,190
	@ 10,018 Say "Serie da NF"
	@ 10,070 Get cSerie
	@ 20,018 Say "Numero da NF"
	@ 20,070 Get cNumnf Valid sfVldNf()
	@ 30,018 Say "Nova Transportadora"
	@ 30,070 Get cTransp F3 "SA4"
	@ 40,018 Say "Volumes"
	@ 40,070 Get nVolumes Size 30,10 Picture "@E 9,999" 

	@ 72,133 BMPBUTTON TYPE 01 ACTION (lContinua := .T.,oLeTxt:End())
	@ 72,163 BMPBUTTON TYPE 02 ACTION oLeTxt:End()
	
	Activate Dialog oLeTxt Centered
	
	If lContinua
		OkLeTxt()
	Endif
	
Return

Static Function sfVldNf()

	Local	lRet	:= .T.
	
	dbSelectArea("SF2")
	dbSetOrder(1)
	If DbSeek(xFilial("SF2")+cNumnf+cSerie,.F.)
		cTransp	:= SF2->F2_TRANSP
		nVolumes	:= SF2->F2_VOLUME1
	Else
		lRet	:= .F.
		MsgAlert("Não há nota fiscal com esta numeração!","Não há registro")
	Endif
	
Return lRet	


/*/{Protheus.doc} OkLeTxt
(long_description)
@author MarceloLauschner
@since 15/06/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function OkLeTxt()
	
	dbSelectArea("SF2")
	dbSetOrder(1)
	If DbSeek(xFilial("SF2")+cNumnf+cSerie,.F.)
		Reclock("SF2",.F.)
		SF2->F2_TRANSP 	:= cTransp
		SF2->F2_VOLUME1	:= nVolumes
		SF2->F2_ESPECI1	:= "DIVERSOS"
		MSUnLock()
		MsgAlert("Entrada de Dados Realizada com sucesso!!","Informacao","INFO")
	Else
		MsgAlert("Nota Fiscal Inexistente","Atencao!")
	Endif

Return
