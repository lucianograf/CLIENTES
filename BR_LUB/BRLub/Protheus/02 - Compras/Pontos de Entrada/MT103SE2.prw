
/*/{Protheus.doc} MT103SE2
Ponto de entrada para adição de novos campos na aba duplicatas 
@type function
@version  
@author Marcelo Alberto Lauschner
@since 21/10/2021
@return variant, return_description
/*/
User Function MT103SE2

	//Local aHead     := PARAMIXB[1]
	//Local lVisual   := PARAMIXB[2]
	Local aRet      := {}

	if !IsInCallStack("A103DEVOL")


		Aadd(aRet,{Alltrim(GetSx3Cache("E2_HIST","X3_TITULO")),;	//X3_TITULO
		    GetSx3Cache("E2_HIST","X3_CAMPO"),;	                    //X3_CAMPO,;
			GetSx3Cache("E2_HIST","X3_PICTURE"),; 	                //X3_PICTURE,;
			GetSx3Cache("E2_HIST","X3_TAMANHO"),;	                //X3_TAMANHO,;
			GetSx3Cache("E2_HIST","X3_DECIMAL"),;	                //X3_DECIMAL,;
			GetSx3Cache("E2_HIST","X3_VALID"),;	                    //X3_VALID,;
			GetSx3Cache("E2_HIST","X3_USADO"),;	                    //X3_USADO,;
			GetSx3Cache("E2_HIST","X3_TIPO"),;		                //X3_TIPO,;
			GetSx3Cache("E2_HIST","X3_F3"),;		                //X3_F3,;
			GetSx3Cache("E2_HIST","X3_CONTEXT"),;	                //X3_CONTEXT,;
			GetSx3Cache("E2_HIST","X3_CBOX"),;		                //X3_CBOX,;
			GetSx3Cache("E2_HIST","X3_RELACAO"),;	                //X3_RELACAO,;
			".T."})

	Endif

Return aRet
