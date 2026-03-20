
/*/{Protheus.doc} FC010CON
(Ponto de entrada na rotina Posição do Cliente )
@author MarceloLauschner
@since 10/09/10
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function FC010CON()
	
	Local	aAreaSA1 := SA1->(GetArea())
	Local	nOpcao	 := 0
	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()
	
	If __cUserId $ GetMv("BF_USRSERA")
		
		nOpcao	:= Aviso("Alterar Dados","Escolha uma entidade a ser alterada!",{"Cliente","Referências","Conhecimento","Serasa"},2)
		
		If nOpcao == 1
			
			cCadastro := "Cadastro de Clientes - Alterar"
			
			DbSelectArea( "SA1" )
			DbSetOrder(1)
			INCLUI := .F.
			aRotAuto := nil
			
			A030Altera( "SA1", SA1->(Recno()), 4 )
		ElseIf nOpcao  == 2
			cCadastro	:= "Referências - Alterar
			DbSelectArea( "SA1" )
			DbSetOrder(1)
			Mata030Ref("SA1",SA1->(Recno()),4)
		ElseIf nOpcao == 3
			cCadastro := "Clientes - Banco de Conhecimento"
			DbSelectArea( "SA1" )
			DbSetOrder(1)
			MsDocumento( "SA1", SA1->(Recno()), 4 )
		ElseIf nOpcao == 4
			U_SERPEFIN(.T.,SA1->A1_COD,SA1->A1_COD,3)
		Endif
	Else
		nOpcao	:= Aviso("Alterar Dados","Escolha uma entidade a ser alterada!",{"Referências","Google","Conhecimento"},2)
		//	MsgAlert("Usuário sem permissão para executar esta rotina!","A T E N Ç Ã O!")
		If nOpcao == 1
			cCadastro	:= "Referências - Alterar
			DbSelectArea( "SA1" )
			DbSetOrder(1)
			Mata030Ref("SA1",SA1->(Recno()),4)
		ElseIf nOpcao == 2
			sb  := '"http://maps.google.com.br/maps?f=q&hl=pt-BR&geocode=&q='
			sb  +=     StrTran(Alltrim(SA1->A1_END)," ","+")
			sb	+=  ",+"
			sb  +=     StrTran(Alltrim(SA1->A1_CEP)," ","+")
			sb	+=  ",+"
			sb  +=     StrTran(Alltrim(SA1->A1_MUN)," ","+")
			sb	+=  ",+"
			sb  +=     StrTran(Alltrim(SA1->A1_EST)," ","+")
			sb  +=  "&ie=UTF8&g="
			sb  +=     StrTran(Alltrim(SA1->A1_MUN)," ","+")
			sb	+=  ",+"
			sb  +=     StrTran(Alltrim(SA1->A1_EST)," ","+")
			sb  += "&z=17&iwloc=addr"
			
			WaitRun( 'cmd.exe /c start iexplore.exe ' + sb + '"'  )
		ElseIf nOpcao == 3
			cCadastro := "Clientes - Banco de Conhecimento"
			DbSelectArea( "SA1" )
			DbSetOrder(1)
			MsDocumento( "SA1", SA1->(Recno()), 4 )
		Endif
	Endif
	
	RestArea(aAreaSA1)
	
Return
