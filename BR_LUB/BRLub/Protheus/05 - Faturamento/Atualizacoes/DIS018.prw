#INCLUDE "rwmake.ch"
//--------------------------------+
// Favor Documentar alterações.   |
// Data - Analista - Descrição	  |
//--------------------------------+
//-------------------------------------------------------------------------------------------------
// 29/03/2010 - 
//
//-------------------------------------------------------------------------------------------------

User Function DIS018

	/*/
	ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
	±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
	±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
	±±ºPrograma ³DIS018 º Autor ³ Leonardo J Koerich Jr  º Data ³  22/05/03   º±±
	±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
	±±ºDescricao ³ Reimpressao  etiqueta para despacho                        º±±
	±±º          ³                                                            º±±
	±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
	±±ºUso       ³ Sigafat                                                    º±±
	±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
	±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
	ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
	/*/

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Declaracao de Variaveis                                             ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	Private cPerg  := "DIS018"

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Verifica as perguntas selecionadas                                      ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()

	ValidPerg()

	If Pergunte(cPerg,.T.)
		_Eti()
	Endif

Return

Static Function _Eti()

	dbSelectArea("SC5")
	dbSetOrder(1)
	If dbSeek(xFilial("SC5")+mv_par02)
		dbSelectArea("SA1")
		dbSetOrder(1)
		If dbSeek(xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI)
		
			For y := 1 To mv_par04
			
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Inicio de impressao                                                 ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			
				_cPorta := "LPT1:9600,n,8,1"
			
				MSCBPRINTER("ALLEGRO",_cPorta,Nil,) //Seta tipo de impressora
				MSCBCHKSTATUS(.F.)
				MSCBBEGIN(1,4) //Inicio da Imagem da Etiqueta
			
				MSCBSAY(07,29,"BF BIG FORTA COM REPR LTDA (47) 3041-2001","N","9","002,001") //Imprime Texto
				MSCBSAY(07,21,SA1->A1_NOME,"N","9","002,001") //Imprime Texto
				MSCBSAY(07,17,SA1->A1_MUN,"N","9","002,001") //Imprime Texto
				MSCBSAY(07,13,"Pedido: " + mv_par02 + " Nr.NF: " + mv_par03,"N","9","002,002") //Imprime Texto
				dbSelectArea("SB1")
				dbSetOrder(1)
				If dbSeek(xFilial("SB1")+mv_par01)
					MSCBSAY(07,09,AllTrim(mv_par01) + " - " + Substr(SB1->B1_DESC,1,30),"N","9","002,001") //Imprime Texto
					MSCBSAY(07,05,"Endereco: "+ SB1->B1_LOCAL + " - " + AllTrim(Transform(y,"@E 9999")) + "/" + AllTrim(Transform(mv_par04,"@E 9999")) + " Cx c/ " + AllTrim(Transform(SB1->b1_convb,"@E 9999")),"N","9","002,001") //Imprime Texto
				Else
					MSCBSAY(07,09,"VOLUMES DIVERSOS","N","9","002,001") //Imprime Texto
				Endif
			
				cResult := MSCBEND()
				MemoWrit('DIS010',cResult)
			
			Next
		Endif
	Endif

Return

	/*/
	ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
	±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
	±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
	±±ºFun‡„o    ³VALIDPERG º Autor ³ AP5 IDE            º Data ³  16/04/02   º±±
	±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
	±±ºDescri‡„o ³ Verifica a existencia das perguntas criando-as caso seja   º±±
	±±º          ³ necessario (caso nao existam).                             º±±
	±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
	±±ºUso       ³ Programa principal                                         º±±
	±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
	±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
	ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
	/*/

Static Function ValidPerg

	Local _sAlias := Alias()
	Local aRegs := {}
	Local i,j

	dbSelectArea("SX1")
	dbSetOrder(1)
	// cPerg :=  PADR(cPerg,Len(SX1->X1_GRUPO))
	cPerg :=  PADR(cPerg,Len("X1_GRUPO"))

	aAdd(aRegs,{cPerg,"01","Produto"      ,"","","mv_ch1","C",15,0,0,"G","","mv_par01","","","","","","","","","","","","","","","","","","","","","","","","","SB1"})
	aAdd(aRegs,{cPerg,"02","Pedido"       ,"","","mv_ch2","C",06,0,0,"G","","mv_par02","","","","","","","","","","","","","","","","","",""})
	aAdd(aRegs,{cPerg,"03","Nota Fiscal"  ,"","","mv_ch3","C",06,0,0,"G","","mv_par03","","","","","","","","","","","","","","","","","",""})
	aAdd(aRegs,{cPerg,"04","Nr. Etiquetas","","","mv_ch4","N",04,0,0,"G","","mv_par04","","","","","","","","","","","","","","","","","",""})

	For i:=1 to Len(aRegs)
		If !dbSeek(cPerg+aRegs[i,2])
			RecLock("SX1",.T.)
			For j:=1 to FCount()
				If j <= Len(aRegs[i])
					FieldPut(j,aRegs[i,j])
				Endif
			Next
			MsUnlock()
		Endif
	Next

	dbSelectArea(_sAlias)

Return
