#INCLUDE "rwmake.ch"

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณMT100LOK  บ Autor ณ TOTVS     บ Data ณ  02/06/12   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDescricao ณ VALIDACAO NA LINHA DE DIGITACAO DOS ITENS DA NF DE ENTRADA บฑฑ
ฑฑบ          ณ PARA BLOQUEAR CONTAS DE DESPESA SEM O CENTRO DE CUSTO      บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ TRANSJOI                                                   บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
/*/

User Function MT100LOK

Private lRet	:= .T.

cContaC := ""
cCC     := ""
cGrupo  := ""
cManut  := ""
cProduto:= ""
_KM     := 0
cEstoq  := ""
cAbast  := ""
 
cContaC := GDFIELDGET("D1_CONTA")
cCC     := GDFIELDGET("D1_CC")
cRateio := GDFIELDGET("D1_RATEIO")                            
cItemC  := gdfieldget("D1_ITEMCTA")
cClvl   := gdfieldget("D1_CLVL")
cProduto:= gdfieldget("D1_COD")
cTES    := gdfieldget("D1_TES")
cTipoNf := gdfieldget("D1_TIPO")

cNatNFE	:= Alltrim(MaFisRet(,"NF_NATUREZA"))

if EMPTY(cContaC) .and. cRATEIO=="2" .AND. cTipoNf <> "D"
	lRet := .f.
	MsgStop('A Conta Contแbil deve ser preenchida.')
EndIf

If ctipo == "N".AND.cRATEIO =="2" .AND. cTipoNf <> "D"
	IF lRet  //Verifica se as amarracoes entre C'onta Contabil  e Centro de Custo sao permitidas conforme cadastro de Amarracoes do CTB
		lRet := CtbAmarra(cContaC,cCC,cItemC,cClvl,.T.)                        
	EndIf	  
//	if funname() == "MNTA650"
	IF lRet //Verifica se a conta aceita CC ou se o CC eh obrigatorio para a Conta Contabil conforme cadastro de plano de Contas.
		lRet := CtbObrig(cContaC,cCC,cItemC,cClvl,.T.)
	Endif

EndIf                  

//If Alltrim(cEmpAnt) <> "01" //Senใo for 01-Transjoi, nใo valida
//	Return lRet
//Endif

//cTpManut:= gdfieldget("D1_TPMANU")                     
//_KmRod  := gdfieldget("D1_KMRODAD")
//_Dtabas := gdfieldget("D1_DTABAS") 

//cGrupo:= POSICIONE("SB1",1,xFilial("SB1")+cProduto,"B1_GRUPO")
//cManut:= POSICIONE("SBM",1,xFilial("SBM")+cGrupo,"BM_MANUT")
//_KM   := POSICIONE("DA3",1,xFilial("DA3")+cClvl,"DA3_KMRODAD")
//cAbast  := POSICIONE("SB1",1,xFilial("SB1")+cProduto,"B1_ABASTEC")

//cEstoq  := POSICIONE("SF4",1,xFilial("SF4")+cTes,"F4_ESTOQUE")   

/*If cEstoq == "N"
	if EMPTY(cTpManut) .and. cManut == "1" 
		lRet := .f.
		MsgStop('Informe se o tipo do servi็o / produto ้ Corretivo ou Preventivo.')
	EndIf
endif

		
IF !EMPTY(cCLvl)  
	if _KmRod == 0
		lRet := .f.
		MsgStop('O valor do KM Rodado deve ser informado.')
	endif                          

	if _KmRod > 0 .and. empty(_Dtabas).and. cAbast == "1"
		lRet := .f.
		MsgStop('Deve ser informada a data de abastecimento.')
	endif
	if _KmRod < _KM 
		lRet := .T.
		MsgStop('O valor do KM Rodado deve ser maior que o informado no cadastro do Veํculo.')
	EndIf
endif    
*/
//MATA103|
If ALLTRIM(FUNNAME())$"MATA116"

	
		If SED->ED_CALCIRF = "S" .And. Alltrim(cDirf) = "2"
			ApMsgStop(Substr(cUsuario,7,7)+CHR(10)+CHR(13)+"A Natureza "+cNatNFE+" informada efetua cแlculo de IRRF, por้m nใo foi informado para gerar a Dirf (Gera Dirf) na aba Impostos do rodap้ da NF de Entrada."+CHR(13)+"Por favor, verifique a Natureza informada ou altere para Sim na gera็ใo da Dirf e informe o C๓d. de Reten็ใo."+CHR(13)+" ","Aten็ใo - "+Procname()+" - "+Funname())
		   //	cCodRet	:= SA2->A2_CODRET
			Return (.F.)
		Endif
		If SED->ED_CALCIRF = "S" .And. Alltrim(cDirf) = "1" .And. Alltrim(cCodRet) = ""
			ApMsgStop(Substr(cUsuario,7,7)+CHR(10)+CHR(13)+"A Natureza "+cNatNFE+" informada efetua cแlculo de IRRF e foi informado para gerar a Dirf (Gera Dirf) na aba Impostos do rodap้ da NF de Entrada. Por้m nใo foi informado um C๓d. de Reten็ใo."+CHR(13)+"Por favor, informe um C๓d. de Reten็ใo correto."+CHR(13)+" ","Aten็ใo - "+Procname()+" - "+Funname())
		//	cCodRet	:= SA2->A2_CODRET
			Return (.F.)
		Endif                              

		
		//If SED->ED_CALCIRF = "S" .And. cCodRet <> SA2->A2_CODRET
		//	ApMsgStop(Substr(cUsuario,7,7)+CHR(10)+CHR(13)+"O C๓d. de Reten็ใo "+cCodRet+" informado na aba Impostos no lan็amento da NFE ้ diferente do c๓d. "+Alltrim(SA2->A2_CODRET)+" cadastrado para o fornecedor "+Alltrim(SA2->A2_COD)+"/"+Alltrim(SA2->A2_LOJA)+"-"+Alltrim(SA2->A2_NOME)+"."+CHR(13)+"Como a Natureza informada Calcula IRRF ้ necessแrio que o C๓d. de Reten็ใo seja o mesmo do cadastro do Fornecedor."+CHR(13)+"Por favor, informe um C๓d. de Reten็ใo igual ao C๓d. de Reten็ใo cadastrado no Fornecedor ou verifique o cadastro do mesmo."+CHR(13)+"Obs.: O campo Cd. Retencao serแ atualizado agora com o c๓digo do Cadastro de Fornecedor.","Aten็ใo - "+Procname()+" - "+Funname())
		//	cCodRet	:= SA2->A2_CODRET
		//	Return (.F.)
		//Endif
		                               
Endif
Return(lRet)

//Return lRet
