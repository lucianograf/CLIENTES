#Include 'Totvs.ch'

/*/{Protheus.doc} decetq02
Impressão de etiquetas de Pallets 
@type function
@version 1
@author Marcelo Alberto Lauschner
@since 28/04/2021
/*/
User Function decetq02()

	Local    cPerg    := "ETIQC002"

	If Pergunte(cPerg,.T.)
		MsAguarde({||sfExec()},"Aguarde","Imprimindo Etiquetas.....")
	EndIf

Return

/*/{Protheus.doc} DECIMPR02
Executa impressão das etiquetass
@type function
@version 1
@author Marcelo Alberto Lauschner
@since 28/04/2021
@return return_type, return_description
/*/
Static Function sfExec()

	Local nVol  	:= 0
	Local nX 
	If mv_par01 == 1
		nVol := SF2->F2_VOLUME1
	Else
		nVol := mv_par02
		nIni := mv_par03
	EndIf

	If nVol =  0
		MSGALERT( "Nota fiscal sem volume ", "Mensagem" )
	Else
		For nX := 1 To nVol

			MSCBPRINTER("ZEBRA","LPT2",,,.f.,,,,,,.f.,)

			MSCBCHKSTATUS(.F.)
			MSCBBEGIN(1,6)

			SA1->(DbSeek(xFilial("SA1")+SF2->F2_CLIENTE+SF2->F2_LOJA))
			SA4->(DbSeek(xFilial("SA4")+SF2->F2_TRANSP))
			SD2->(DbSetOrder(3))
			SD2->(DbSeek(xFilial("SD2")+SF2->F2_DOC+SF2->F2_SERIE))

			MSCBSAY(080,15,"www.decanter.com.br", "R","0","050,050")

			// PEDIDO + FAIXA CONTENDO FILIAL - ESTADO ORIGEM - ESTADO DESTINO + DATA E HORA
			MSCBSAY(075,080,SD2->D2_PEDIDO, "N","0","030,050") // PEDIDO

			MSCBBOX(072,085,095,165,100,"B") // BOX PRETO
			MSCBSAY(074,090,AllTrim(SM0->M0_CODFIL)+" - "+SM0->M0_ESTCOB+" - "+SF2->F2_EST, "R","0","150,100",.t.)
			MSCBSAY(065,105,DToC(Date())+" - "+Time(), "R","0","050,050")

			// DADOS CLIENTE + TRANSPORTADORA
			MSCBSAY(031,30,Transform(SA1->A1_CEP,"@R 99999-999")+" - "+AllTrim(SA1->A1_MUN)+" - "+SA1->A1_EST, "R","0","080,050")
			MSCBSAY(040,30,AllTrim(SA1->A1_END)+" - "+AllTrim(SA1->A1_BAIRRO), "R","0","040,035")
			MSCBSAY(045,30,SA1->A1_NOME    , "R","0","040,035")
			MSCBSAY(050,30,SA1->A1_NREDUZ  , "R","0","060,050")
			MSCBSAY(055,30,SA4->A4_NOME    , "R","0","070,050")

			MSCBBOX(005,010,030,165,100,"B")
			MSCBSAY(005,015,STRZERO(VAL(SF2->F2_DOC),6), "R","0","200,200",.t.)

			If mv_par01 == 1
				MSCBSAY(015,110,Transform(nX,"@R 9999") + "/" + Transform(nVol,"@R 9999"), "R","0","100,170",.t.)
			Else
				MSCBSAY(015,110,Transform(nIni,"@R 9999") + "/" + Transform(mv_par04,"@R 9999"), "R","0","100,170",.t.)
				nIni := nIni + 1
			EndIf

			MSCBSAY(005,105,"Total CX: "+Transform(mv_par05,"@R 999"), "R","0","080,100",.t.)

			MSCBEND()
			MSCBCLOSEPRINTER()
			
		Next 
	EndIf

Return
