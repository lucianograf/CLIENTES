
/*/{Protheus.doc} TMKVCA
(Ponto de entrada para alterar consulta de produtos no TMK)
	
@author MarceloLauschner
@since 06/01/2012
@version 1.0		

@return Sem retorno

@example
(examples)

@see (links_or_references)
/*/
User Function TMKVCA()
                                           
	Local		nPxProd		:= aScan(aHeader,{|x| Alltrim(x[2]) == "UB_PRODUTO"})
 
       
	If Type("aRotina") == "U"
		Private aRotina   := {{ ,"TMKA271", 0, 2}}
	Endif

	//MaComView(aCols[N][nPxProd])  
	MaViewSB2(aCols[N][nPxProd])

Return
