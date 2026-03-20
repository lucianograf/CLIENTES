#Include 'Protheus.ch'

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³RSERPEFIN ºAutor  ³Eduardo Donato     º Data ³  Mai/2007   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Relatorio gerado com os Titulos que Apresentaram Erros na   º±±
±±º          ³Inclusao / Correcao ao Serasa.                              º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Versa8.11 - Parmalat                                       º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

User Function RSerPefin()                     

Local lOk    := .F.
Private cArqPefin   := ""
Private aDadosSE1	:= {}

// Executa gravação do Log de Uso da rotina
U_BFCFGM01()

FormBatch("Protheus10", {	"Rotina para Importar Arquivos de Retorno do Serasa-Pefin"			}, ;
													{{1, .T., {|| If(stVldArq(), (lOk := .T., FechaBatch()), Nil)}}, ;
													 {2, .T., {|| lOk := .F., FechaBatch()}}													})
	
	If lOk
		SE1->( dbSetOrder(1) )
		Processa( {|lEnd| U_SerPefLeArq(cArqPefin,{|cFile, cLinha, nLinha| GeraVetor(cFile, cLinha, nLinha) })},"Processando...", "Arquivo de Retorno Serasa-Pefin ..." )
		Processa( {|lEnd| U_GeraRlt(aDadosSE1) },"Processando...", "Arquivo de Retorno Serasa-Pefin ..." )
	EndIf
	
Return(.T.)
	
/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Funcao    ³  GeraVetor ³ Autor ³ Paulo V. Beraldo    ³ Data ³ Mai/2007 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Trata a linha do arquivo importado                         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ Versao811 - Parmalat                                       ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function GeraVetor(cFile, cLinha, nLinha)
Private lOk				:=.F.
Private aDados  	:= {}
Private cCodReg, cCodOper, cFilDig,	dOcoren, dTerCont, cCodNat,	cCodEmb
Private cTipPes, cTipDc1, cDocum1, cMotBxa, cTipdc2, cDocum2, cUfRg, 	cBranco
Private cTipCOb, cDocCOb, cSpaco, cUfRg1, 	cNomDev
Private dDtNasc, cNomPai, cNomMae, cEnder, cBairro, cMunici, 	cUf
Private cCep, nValor, cNumCtr, cNossNum, cCplEndDv, nDddDev, nTelDev
Private dDtAssDev, nVlrTotDev, cBranco1, cCodErros, cSequencia


If Empty(cLinha)
	Return(.T.)
Endif

aDados  :={	{1,		{|cQuebra|	cCodReg    := cQuebra}}, ;  // 1  001
{1, 	{|cQuebra|	cCodOper	 := cQuebra}}, ;			 // 2  002
{6,		{|cQuebra|	cFilDig		 := cQuebra}}, ;            // 3  003
{8,		{|cQuebra|	dOcoren		 := cQuebra}}, ;            // 4  009
{8,		{|cQuebra|	dTerCont	 := cQuebra}}, ;            // 5  017
{3,		{|cQuebra|  cCodNat		 := cQuebra}}, ;            // 6  025
{4,		{|cQuebra|	cCodEmb		 := cQuebra}}, ;            // 7  028
{1,		{|cQuebra| 	cTipPes		 := cQuebra}}, ;            // 8  032
{1,		{|cQuebra|	cTipDc1		 := cQuebra}}, ;            // 9  033
{15,	{|cQuebra|	cDocum1		 := cQuebra}}, ;            // 10 034
{2,		{|cQuebra|	cMotBxa		 := cQuebra}}, ;            // 11 049
{1,		{|cQuebra|	cTipdc2		 := cQuebra}}, ;            // 12 051
{15,	{|cQuebra|	cDocum2    := cQuebra}}, ;              // 13 052
{2,		{|cQuebra|	cUfRg			 := cQuebra}}, ;        // 14 067
{1,		{|cQuebra|	cBranco		 := cQuebra}}, ;            // 15 069
{1,		{|cQuebra|	cTipCOb		 := cQuebra}}, ;            // 16 070
{15,	{|cQuebra|	cDocCOb		 := cQuebra}}, ;            // 17 071
{2,		{|cQuebra|	cSpaco		 := cQuebra}}, ;            // 18 086
{1,		{|cQuebra|	cTipDc2		 := cQuebra}}, ;            // 19 088
{15,	{|cQuebra|	cDocum2		 := cQuebra}}, ;            // 20 089
{2,		{|cQuebra|	cUfRg			 := cQuebra}}, ;        // 21 104
{70,	{|cQuebra|	cNomDev 	 := cQuebra}}, ;            // 22 106
{8,		{|cQuebra|	dDtNasc		 := cQuebra}}, ;            // 23 176
{70,	{|cQuebra|	cNomPai		 := cQuebra}}, ;            // 24 184
{70,	{|cQuebra|	cNomMae    := cQuebra}}, ;              // 25 254
{45,	{|cQuebra|	cEnder		 := cQuebra}}, ;            // 26 324
{20,	{|cQuebra|	cBairro		 := cQuebra}}, ;            // 27 369
{25,	{|cQuebra|	cMunici		 := cQuebra}}, ;            // 28 389
{2,		{|cQuebra|	cUf				 := cQuebra}}, ;        // 29 414
{8,		{|cQuebra|	cCep			 := cQuebra}}, ;        // 30 416
{15,	{|cQuebra|	nValor		 := cQuebra}}, ;            // 31 424
{16,	{|cQuebra|	cNumCtr		 := cQuebra}}, ;            // 32 439
{9,		{|cQuebra|	cNossNum	 := cQuebra}}, ;            // 33 455
{25,	{|cQuebra|	cCplEndDv  := cQuebra}}, ;              // 34 464
{4,		{|cQuebra|	nDddDev		 := cQuebra}}, ;            // 35
{9,		{|cQuebra|	nTelDev		 := cQuebra}}, ;            // 36
{8,		{|cQuebra|	dDtAssDev  := cQuebra}}, ;              // 37
{15,	{|cQuebra|	nVlrTotDev := cQuebra}}, ;              // 38
{9,		{|cQuebra|	cBranco1	 := cQuebra}}, ;            // 39
{60,	{|cQuebra|	cCodErros  := cQuebra}}, ;              // 40
{7,		{|cQuebra|	cSequencia := cQuebra}}  }              // 41
// 1           2         3         4          5          6         7        8         9        10        11           12     13         14       15         16        17       18        19        20          21         22         23        24       25        26       27         28        29       30          31        32        33        34        35        36        37       38        39        40        41         42       43         44       45         46        47        48     
//123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 
//0082656463201111070047304120002008Silvana Jarocz                                                        SERASA-CONVEM04000027R       49000976                                                                                                                                                                                                                                                                                                                                                                                                                                                                    0000001

//1E0001702011100720111007NF 48  J100068269200010399                                                       ADRIANO LOPES ME                                                      00000000                                                                                                                                            RUA  MELVIN JONES, 465                       COMERCIARIO         CRICIUMA                 SC888022300000000000000002  029880   AFT 000000000                         000000000000000000000000000000000000                                                                     0000002

//1E0001702011101220111013NF 48  J100480025100010199                                                       MARIA HELENA JORGE ME                                                 00000000                                                                                                                                            RODOVIA VEREADOR ONILDO LEMOS,00819          SANTINHO            FLORIANOPOLIS            SC880587000000000000000002  030115    NF 000000000                         000000000000000000000000000000000000                                                                     0000003

//9                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                0000004

aEval( aDados, {|z| cQuebra := Left( cLinha, z[1]), cLinha := Substr( cLinha, z[1] + 1 ), Eval(z[2], cQuebra ) } )

Aadd( aDadosSE1,{	cCodReg,cCodOper,cFilDig,dOcoren,dTerCont,cCodNat,cCodEmb,cTipPes,;
cTipDc1,cDocum1,cMotBxa,cTipdc2,cDocum2,cUfRg,cBranco,cTipCOb,cDocCOb,;
cSpaco,cTipDc2,cDocum2,cUfRg,cNomDev,dDtNasc,cNomPai,cNomMae,cEnder,cBairro,;
cMunici,cUf,cCep,nValor,cNumCtr,cNossNum,cCplEndDv,nDddDev,nTelDev,dDtAssDev,;
nVlrTotDev,cBranco1,cCodErros,cSequencia })
Return



/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Funcao    ³ValidArq1   ³ Autor ³ Paulo V. Beraldo    ³ Data ³ Mai/2007 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Valida o arquivo selecionado                               ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ Versao8.11 - Parmalat                                      ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function stVldArq()

cArqPefin := cGetFile( "Todos os Arquivos (*.*) | *.*", "Selecione o Arquivo de Retorno do Serasa",,"C:\PEFIN_SERASA\Retornos\",.T., )

If Len(Directory(cArqPefin)) == 0
	Help(" ",1,"NOFLEIMPOR",,cFile,05,01)
	Return(.F.)
Endif

Return(.T.)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³SerPefLeArq³ Autor ³ Paulo V. Beraldo     ³ Data ³Mai/2007  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³Le um arquivo TXT executando bloco de codigo para cada linha³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ cFile  nome do arquivo                                     ³±±
±±³          ³ bBlock bloco de codigo para cada linha                     ³±±
±±³          ³ Bloco de codigo chamado com tres parametros:               ³±±
±±³          ³ Nome do Arquivo, Conteudo da Linha, Numero da Linha        ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ Versao8.11 - Parmalat							                        ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
User Function SerPefLeArq(cFile, bBlock)
Local nBuf	   := 16 * 1024  // 16K
Local nHdl	   := fOpen(cFile, 0)
Local nTam	   := fSeek(nHdl, 0, 2)
Local nLin	   := 0
Local nLido    := 0
Local cBuffer  := ""
Local lLeuTudo := .F.
Local cLinha   := ""

If nHdl <= 0
	MsgAlert("Não possível abrir o arquivo '"+cFile+"' ")
	Return(.F.)
Endif

fSeek(nHdl, 0)
While nLido < nTam
	If Len(cBuffer) < nBuf .And. ! lLeuTudo
		cBuffer  += fReadStr(nHdl, nBuf)
		lLeuTudo := fSeek(nHdl, 0, 1) = nTam
	Endif
	nPos    := At(Chr(13) + Chr(10), cBuffer)	
	nPosE   := nPos
	// Corrigi Bug do arquivo de Retorno forçando tamanho da linha
	If nPos	<= 600 
		nPos	:= 602
	Endif
	nPos    := If(nPos == 0 .And. lLeuTudo, Len(cBuffer) + 1, nPos)
	cLinha  := Substr(cBuffer, 1, nPos - 1)
	nLin    ++                               
//	Alert("nPos"+Str(nPos)+"| cLinha|"+cLinha+"| nLin "+Str(nLin))
	Eval(bBlock,cFile, cLinha, nLin)
	nLido   += Len(cLinha) + Iif(nPosE > 0, 2,0) // Assumo Chr(13)+Chr(10) no final da linha
	cBuffer := Substr(cBuffer, nPos +Iif(nPosE > 0 , 2 , 0) )
Enddo

fClose(nHdl)

Return(.T.)

