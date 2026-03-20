#Include 'Protheus.ch'

User Function BFFATA32()

	Local		lRet		:= .F.

	If ReadVar() == "M->PAB_ROTA"
		If Alltrim(M->PAB_ROTA) $ "23456#2356#236#2456#246#256#26#356#36#46#346#2346"
			lRet	:= .T.
		Else
			MsgAlert("Tipo de dados para dias de faturamento incorretos. Você deve informar somente de as opções dos dias de semana de '2' a '6'. Por exemplo '23456' ou '36'","A T E N Ç Ã O!! BFFATA32.PRW ")
		Endif
	Endif

Return lRet

/* 
2     a
23    a
234   a
2345  a
23456 A -
235
2356
236
24    b
245   b
2456  B -
246   C -
25    d 
256   D -
26    E -  
3     a
34    a 
345   a
3456  a
346   I -
35    f
356   F -
36    G -
4     a
45    a 
456   a
46    i
5     a
56    a
6     a

*/
