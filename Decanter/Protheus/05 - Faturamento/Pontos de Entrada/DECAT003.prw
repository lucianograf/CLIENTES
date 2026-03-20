#include 'PROTHEUS.CH'
#include 'FWMVCDEF.CH'
#Include 'TBICONN.CH'
#Include 'COLORS.CH'
#Include "FWMBROWSE.CH"
#Include "RWMAKE.CH"

/*/{Protheus.doc} DECAT003
    Programa para avaliar as os pedidos com desconto e se houver desconto liberar ou bloquear pela campanha de vendas.
    @type  Function
    @author Giovane Wiedermann | Vamilly
    @since 09/11/2023
/*/

User Function DECAT003(cPedido as Character,cVend as Character, cProd as Character, nPerDesc as Numeric, nValDesc as Numeric,lSimu as Logical) 
    Local cAlias  := GetNextAlias() 
    Local aArea    := GetArea()
    Local aAreaSC5 := SC5->( GetArea() )
    Local aAreaSA3 := SA3->( GetArea() )
    Local aAreaSZ2 := SZ2->( GetArea() )
    Local aAreaSZ3 := SZ3->( GetArea() )
    Local aAreaSC6 := SC6->( GetArea() )
    Local cIDCamp   := ""
    Local cCanal    := ""
    //Local cLQry    := ""
    Local lRet      := .F.
    Local lAchou    := .F.
    Local lBlq      := .F.
    Local aCamp     := {}
    Local lHasCmp   as Logical 
    Local nX        as Numeric 
    Local cData     := DtoS(MsDate())
    
    

    Default lSimu   := .F.
    Default cPedido := ""


    DBSelectArea("SA3")
    SA3->( DBSetOrder(1) )
    IF SA3->( MSSeek(xFilial("SA3")+cVend) ) 
        cCanal := SA3->A3_XCANCLI
    EndIf
    //NDiF
    // Verificar se existe uma campanha para o produto 
   DBSelectArea("SZ2")
   SZ2->( DbSetOrder(3) )    
    If SZ2->( DBSeek(xFilial("SZ2")+cProd ))


        BeginSQL Alias cAlias 
        SELECT 
        	    Z1_ID       ID 
            ,   Z2_PERDESC  PERDESC 
            ,   Z2_VALDESC  VALDESC
            ,   Z2_PRODUTO PRODUTO
        FROM 
        	%Table:SZ1% SZ1 
            INNER JOIN %Table:SZ2% SZ2 ON 
        		Z2_FILIAL = Z1_FILIAL 
        	AND Z2_ID = Z1_ID 
            AND Z2_PRODUTO = %Exp:cProd%
        	AND SZ2.%notdel%
        WHERE   
            Z1_FILIAL = %Exp:xFilial("SZ1")%
        AND Z1_STATUS = '1' 
        AND Z1_DTINI <= %Exp:cData%
        AND Z1_DTFIM >= %Exp:cData%
        AND SZ1.%notdel%
        ORDER BY Z2_PERDESC DESC 
        EndSQL 

        //cLQry := GetLastQuery()[2]
        //MemoWrite("C:\temp\FAT.sql",cLQry)

        DbSelectArea("SZ3")
      
        DBSelectArea(cAlias)
        (cAlias)->( DbGoTop() )
        While !(cAlias)->( EoF() )

            SZ3->( DbSetOrder(1) )
            IF SZ3->(DBSeek( xFilial("SZ3") + (cAlias)->ID ))
                If SZ3->( DBSeek( xFilial("SZ3") + (cAlias)->ID + cVend )) // Pega caso a campanha seja pro vendedor do pedido 
                    aAdd(aCamp,{ (cAlias)->ID,;
                                 (cAlias)->PERDESC,;
                                 (cAlias)->VALDESC,;
                                 (cAlias)->PRODUTO}) 
                                lAchou := .T.
                EndIf
                SZ3->( DbSetOrder(2) )
                If SZ3->( DBSeek( xFilial("SZ3") + (cAlias)->ID + cCanal )) // Pega caso a campanha seja para o canal do vendedor
                    aAdd(aCamp,{ (cAlias)->ID,;
                                 (cAlias)->PERDESC,;
                                 (cAlias)->VALDESC,;
                                 (cAlias)->PRODUTO})
                                lAchou := .T.
                EndIf 
                // Verifica se achou o registro, caso não tenha encotrado pega o padrão.
                If !lAchou
                    aAdd(aCamp,{(cAlias)->ID,; // Pega caso caso seja uma campanha para todos os vendedores.
                                (cAlias)->PERDESC,;
                                (cAlias)->VALDESC,;
                                (cAlias)->PRODUTO})
                EndIf
            Else 
                aAdd(aCamp,{  (cAlias)->ID,; // Pega caso caso seja uma campanha para todos os vendedores.
                              (cAlias)->PERDESC,;
                              (cAlias)->VALDESC,;
                              (cAlias)->PRODUTO})
            EndIf
            lAchou := .F.
            (cAlias)->( DBSkip() )
        EndDo


        DBSelectArea("SZ4")

        If Len(aCamp)>0

            If lSimu 
                DBSelectArea("SC5")
                SC5->( DBSeek(xFilial("SC5")+ cPedido))
            EndIf


            For nX := 1 to Len(aCamp)
                   // Se o desconto do pedido > Campanha Bloqueia 
                
                IF nPerDesc > aCamp[nX][2] 

                    If lSimu 
                        lRet := .T.
                    Else 
                        IF !(SC5->C5_XBLQCMP)
                            RecLock("SC5",.F.) 
                                SC5->C5_BLQ := "1"
                                SC5->C5_LIBEROK := " "
                                SC5->C5_ZBLQCOM := "Pedido bloqueado devido ao desconto ser maior do que o estabelecido em campanha para o item: " + AllTrim(aCamp[nX][4])
                                SC5->C5_XBLQCMP := .T.
                            SC5->(MsUnlock())
                            lRet := .T.
                            
                        EndIf
                    EndIf 
                Else 
                
                    If lSimu 
                        lRet := .F.
                    Else 
                        IF !(SC5->C5_XBLQCMP)
                            RecLock("SC5",.F.) 
                                SC5->C5_BLQ := ''
                            SC5->(MsUnlock())
                        EndIF
                            lRet := .F.

                            RecLock("SZ4",.T.)
                                SZ4->Z4_FILIAL      := xFilial("SZ4")
                                SZ4->Z4_PEDIDO      := cPedido
                                SZ4->Z4_PRODUTO     := aCamp[nX][4]
                                SZ4->Z4_IDCMP       :=  aCamp[nX][1]
                                SZ4->Z4_VDESPD      :=  nValDesc
                                SZ4->Z4_DESPED      :=  nPerDesc
                                SZ4->Z4_VLCMP       := aCamp[nX][3]
                                SZ4->Z4_DESCMP      := aCamp[nX][2]
                                SZ4->Z4_USER        := __cUserID 
                                SZ4->Z4_DATA        := Date()
                            SZ4->( MsUnlock() )
                        
                    EndIf
                EndiF 

            Next 

        EndIf 
    EndiF 

RestArea(aArea)
RestArea(aAreaSC5)
RestArea(aAreaSC6)
RestArea(aAreaSA3)
RestArea(aAreaSZ2)
RestArea(aAreaSZ3)
Return lRet 

User Function Dec003BRW 
    Local aArea := GetArea()

	Default cTitulo := "Logs dos pedidos liberados por campanha"
	Default lPos := .F.

	Private oBrowse
	Private aRotina    := MenuDef()
	Private cTituloRot := cTitulo



	// Iniciamos a construção básica de um Browse.
	oBrowse := FWMBrowse():New()

	// Definimos a tabela que será exibida na Browse utilizando o método SetAlias
	oBrowse:SetAlias('SZ4')

	// Definimos o título que será exibido como método SetDescription
	oBrowse:SetDescription("Log de Pedidos liberados por Campanha")

	// Filtra o Browse com o filtro repassado no parâmetro


	oBrowse:Activate()
    
    RestArea(aArea)
Return Nil

Static Function MenuDef()

	Local aRot := {}

    // Adicionando opcões
	ADD OPTION aRot TITLE "Pesquisar" 	ACTION 'AxPesqui' 				    OPERATION 1 ACCESS 0 // "Pesquisar"
	ADD OPTION aRot TITLE "Visualizar"  ACTION 'VIEWDEF.DECAT003' 			OPERATION 2 ACCESS 0 // "Visualizar"

Return aRot

Static Function ModelDef()
	Local oModel
	Local oStr1:= FWFormStruct( 1, 'SZ4', /*bAvalCampo*/,/*lViewUsado*/ ) // Construção de uma estrutura de dados

	// Cria o objeto do Modelo de Dados
	oModel := MPFormModel():New('DEC03M', /*bPreValidacao*/, /*bPos*/,/*bCommit*/,/*bCancel*/)

    oModel:SetDescription("Log campanhas de vendas")

	// Adiciona ao modelo uma estrutura de formulário de edição por campo
	oModel:addFields('Campos',, oStr1, /*{|oModel| MVC001T(oModel)}*/,,)


    //Z4_FILIAL+Z4_PEDIDO+Z4_IDCMP+Z4_USER+Z4_DATA                                                                                                                    

	// Define a chave primaria utilizada pelo modelo
	oModel:SetPrimaryKey({'Z4_FILIAL', 'Z4_PEDIDO', 'Z4_IDCMP' })

	// Adiciona a descricao do Componente do Modelo de Dados
	oModel:GetModel('Campos'):SetDescription('Tabela')

Return oModel

Static Function ViewDef()
  	Local oView
	Local oStr1 := FWFormStruct(2, 'SZ4')
	Local oModel := ModelDef()

	// Cria o objeto de View
	oView := FWFormView():New()

	// Define qual o Modelo de dados será utilizado
	oView:SetModel(oModel)

	// Adiciona no nosso View um controle do tipo FormFields(antiga enchoice)
	oView:AddField('Formulario' , oStr1, 'Campos' )

	// Criar um "box" horizontal para receber algum elemento da view
	oView:CreateHorizontalBox('PAI', 100)

	// Relaciona o ID da View com o "box" para exibicao
	oView:SetOwnerView('Formulario', 'PAI')
	oView:EnableTitleView('Formulario' , cTituloRot )
	oView:SetViewProperty('Formulario' , 'SETCOLUMNSEPARATOR', {10})

	// Força o fechamento da janela na confirmação
	oView:SetCloseOnOk( {|| .T. } )

Return oView





