#Include 'Protheus.ch'

/*/{Protheus.doc} BFFATA37
(Cadastro de Motivos de Bloqueio por Alçadas)
@author MarceloLauschner
@since 09/09/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFFATA37()

Private cString := "SZS"

// Executa gravação do Log de Uso da rotina
U_BFCFGM01()

dbSelectArea("SZS")
dbSetOrder(1)

AxCadastro(cString,"Cadastro de motivos de Alçadas",".T."/*cVldExc*/,".T."/*cVldAlt*/)

Return

