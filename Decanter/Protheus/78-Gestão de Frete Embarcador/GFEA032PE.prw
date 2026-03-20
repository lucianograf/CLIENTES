#Include 'Protheus.ch'

User Function GFEA032()
Local aParam     := PARAMIXB
Local xRet       := .T.
Local oObj       := ''
Local cIdPonto   := ''
Local cIdModel   := ''
Local lIsGrid    := .F.
Local nLinha     := 0
Local nQtdLinhas := 0
Local cMsg       := ''
Local nX
Local nCnt
Local cClasse

	If aParam <> NIL
		oObj       := aParam[1]
		cIdPonto   := aParam[2]
		cIdModel   := aParam[3]

		lIsGrid    := "GRID" $ oObj:ClassName()
		
		cClasse := oObj:ClassName()
		
		If lIsGrid
			nQtdLinhas := oObj:GetQtdLine()
			nLinha     := oObj:nLine
		EndIf

		If cIdPonto ==  'MODELCOMMITTTS' 
				oModel := PARAMIXB[1]:GetModel()
				oModelGWL := oModel:GetModel('GFEA032_GWL')
				oModelGWD := oModel:GetModel('GFEA032_GWD')

				for nCnt := 1 to oModelGWL:Length()
					oModelGWL:GoLine(nCnt)
					if !oModelGWL:IsDeleted()
						cCodDocto := oModelGWL:GetValue("GWL_NRDC") 
						cSerie :=  oModelGWL:GetValue("GWL_SERDC") 
						cObserv := oModelGWD:GetValue("GWD_CDTIPO") + oModelGWD:GetValue("GWD_DSTIPO")

						BeginSql Alias "TRB"
							SELECT D2_PEDIDO
							FROM %table:SD2% SD2
							WHERE SD2.D_E_L_E_T_ = ''
							AND D2_FILIAL = %xFilial:SD2%
							AND D2_DOC = %Exp:cCodDocto%
							AND D2_SERIE = %Exp:cSerie%
							Group by D2_PEDIDO
						EndSql

						WHILE TRB->( !EOF() )

							if oObj:NOPERATION == 3 .OR. oObj:NOPERATION == 4 .OR. oObj:NOPERATION == 5
								cPedido :=  TRB->D2_PEDIDO
								cTipo := ''
								if oObj:NOPERATION == 3
									cTipo := 'IO'
								elseif oObj:NOPERATION == 4
									cTipo := 'AO'
								elseif oObj:NOPERATION == 5
									cTipo := 'EO'
								endif
								U_DCCFGM02(cTipo, cPedido, cObserv)
							endif
							TRB->( DBSKIP( ) )
						ENDDO
						TRB->( DBCLOSEAREA(  ) )
					endif
				next nCnt
			endif
		EndIf
Return xRet
