#Include 'Protheus.ch'


/*/{Protheus.doc} BFCFGA02
(Exibe tela com listagem de usuários e retorna o e-mail dos usuários selecionados)
@author MarceloLauschner
@since 15/06/2015
@version 1.0
@param cUserList, character, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFCFGA02(cUserList)
	
	Local 	nC1			:= 0
	Local 	nC2			:= 0
	Local 	nPos       	:= 0
	Local 	aCmdBar 	:= {}
	Local 	aAllUsers	:= {}
	Local 	aUserList1	:= {}
	Local 	aUserList2	:= {}
	Local 	oDlgUsr
	Local 	oText
	Local 	oFont
	Local 	bLine
	Local	cPassw
	
	default cUserList := Space( 255 )
	
	aAllUsers	:= FWSFAllUsers()
	aUserList1	:= WFTokenChar( cUserList, ";" )
	aUserList2	:= AClone( aUserList1 )
	
	aBrowser	:= {}
	
	For nC1 := 1 to len( aAllUsers )
		cPassw 			:= PswMD5GetPass( aAllUsers[ nC1,2 ] )        
		cBloqueado    	:= FWSFUser( aAllUsers[ nC1,2 ] ,"DATAUSER","USR_MSBLQL",.F.)
		
		//Ignora inativos
		if ! ( cBloqueado == '1' ) .And. ! Empty( cPassw ) .And. ( __cUserID <> aAllUsers[ nC1,2 ] ) //ID do Usuï¿½rio.
			lSelected := AScan( aUserList1, { |x| Upper( AllTrim( x ) ) == Upper( AllTrim( aAllUsers[ nC1, 5 ] ) ) } ) > 0   //Email
			AAdd( aBrowser, { lSelected, aAllUsers[ nC1, 3 ], aAllUsers[ nC1,4 ], aAllUsers[ nC1, 5 ]} )
		endif 
	End
	
	If ( Len( aBrowser ) > 0 )
		aBrowser := ASort( aBrowser,,,{ |x,y| ( x[ 3] + x[ 4 ] ) < ( y[ 3 ] + y[ 4 ] ) } )
	Else
		AAdd( aBrowser, { .f., "", "", "" } )
	End
	
	DEFINE DIALOG oDlgUsr TITLE "Selecionar Destinatarios" FROM 0,0 To 19,64 //"Selecionar Destinatarios"
	DEFINE FONT oFont NAME "Arial" SIZE 0, -12 BOLD
	
	@ 17, 5 LISTBOX oBrowser ;
		FIELDS	"" ;
		HEADER	"",;
		"",;
		"Usuario",;
		"Nome",;
		"Endereco eletronico";
		ON DBLCLICK SelectUser( aUserList1 ) ;
		SIZE 242, 110 OF oDlgUsr PIXEL
	
	bLine := { || { ;
		if( aBrowser[ oBrowser:nAt,1 ], LoadBitmap( GetResource(), "WFCHK" ), LoadBitmap( GetResource(), "WFUNCHK" ) ),;
		LoadBitmap( GetResource(), "BMPUSER" ),;
		aBrowser[ oBrowser:nAt,2 ],;
		aBrowser[ oBrowser:nAt,3 ],;
		aBrowser[ oBrowser:nAt,4 ]} }
	
	oBrowser:SetArray( aBrowser )
	oBrowser:bLine := bLine
	
	AAdd( aCmdBar, { "LBTIK", {|| SelectAll( aUserList1, .t. ) }, "Marcar Todos" } ) //"Marcar Todos"
	AAdd( aCmdBar, { "LBNO", {|| SelectAll(  aUserList1, .f. ) }, "Desmarcar Todos" } ) //"Desmarcar Todos"
	
	ACTIVATE MSDIALOG oDlgUsr CENTERED ON INIT ( EnchoiceBar( oDlgUsr, { || oDlgUsr:End() }, { || aUserList1 := aUserList2, oDlgUsr:End() },, aCmdBar ) )
	oChkBtn := nil
	oUnChkBtn := nil
	
Return Padr(WFUnTokenChar( aUserList1, ";" ),255)


Static Function SelectAll( aUserList, lSelect )
	
	Local nC
	Local cUserName
	
	for nC := 1 to Len( aBrowser )
		cUserName := AllTrim( aBrowser[ nC,4 ] )
		
		if ( nPos := AScan( aUserList, { |x| Upper( AllTrim( x ) ) == Upper( cUserName ) } ) ) == 0 .and. lSelect
			AAdd( aUserList, cUserName )
			aBrowser[ nC,1 ] := .t.
		elseif ( nPos > 0 ) .and. !( lSelect )
			ADel( aUserList, nPos )
			ASize( aUserList, Len( aUserList ) -1 )
			aBrowser[ nC,1 ] := .f.
		end
		
	next
	
	oBrowser:Refresh()
return

/*/{Protheus.doc} SelectUser
Seleciona usuários da ListBox
@type function
@version 
@author Marcelo Alberto Lauschner
@since 21/03/2020
@param aUserList, array, param_description
@return return_type, return_description
/*/
Static Function SelectUser( aUserList ) 
	Local nPos
	Local cUserName := AllTrim( aBrowser[ oBrowser:nAt,4 ] )
	
	if ( nPos := AScan( aUserList, { |x| Upper( AllTrim( x ) ) == Upper( cUserName ) } ) ) == 0
		AAdd( aUserList, cUserName )
		aBrowser[ oBrowser:nAt, 1 ] := .t.
	else
		ADel( aUserList, nPos )
		ASize( aUserList, Len( aUserList ) -1 )
		aBrowser[ oBrowser:nAt, 1 ] := .f.
	end
	
	oBrowser:Refresh()
	
return
