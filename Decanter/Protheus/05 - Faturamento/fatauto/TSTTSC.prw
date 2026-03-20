/*/{Protheus.doc} TSTTSC
(long_description)
@type user function
@author user
@since 18/02/2025
@version version
@param param_name, param_type, param_descr
@return return_var, return_type, return_description
@example
(examples)
@see (links_or_references)
/*/
User Function TSTTSC()

    Local lRet
    // StartJob(U_FATAUT3({"01","0101"}),"PRODUCAO",.T.)


    lRet := startjob("U_FATAUT3",getenvserver(),.T.,{"01","0101"})

Return nil
