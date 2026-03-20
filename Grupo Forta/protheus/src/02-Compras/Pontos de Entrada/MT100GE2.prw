#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} MT100GE2
//TODO Ponto de entrada para gravar dados na SE2 conforme edição do PE MT103SE2 
@author Marcelo Alberto Lauschner 
@since 22/01/2020
@version 1.0
@return Nil 
@type User Function
/*/
User Function MT100GE2()


	Local aTitAtual := PARAMIXB[1]
	Local nOpc 		:= PARAMIXB[2]
	Local aHeadSE2	:= PARAMIXB[3]
	Local aParcelas := ParamIXB[5]
	Local nX 		:= ParamIXB[4]
	
	Local nPxHist   := aScan(aHeadSE2,{|x| AllTrim(x[2])=="E2_HIST"})
	
	If nOpc == 1 .And. nPxHist > 0 //.. inclusao
		SE2->E2_HIST	:= aTitAtual[nPxHist] 
	Endif

Return Nil 