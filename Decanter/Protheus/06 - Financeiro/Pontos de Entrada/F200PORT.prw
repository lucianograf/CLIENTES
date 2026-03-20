# include "protheus.ch"

/*/{Protheus.doc} F200PORT
(Ponto de entrada que com retorno T/F se a baixa será pelo portador do Titulo ou pelo parametro)
@author MarceloLauschner
@since 20/08/2010 
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function F200PORT()

Return .F. //!MsgYesNo("Considerar Banco/Agência/Conta informados nos paramêtros? " + chr(13)+chr(13) +"Se a opção for 'Não' os títulos serão baixados o Banco/Agência/Conta que estiver transferido cada título!","A T E N Ç Ã O!!")
