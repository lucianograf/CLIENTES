USER FUNCTION IMPORT_END()

PRIVATE CTAB1    := GETMV("XX_TAB1")
PRIVATE CTAB2    := GETMV("XX_TAB2")
PRIVATE ALINHA   := {}

DBSELECTAREA(CTAB1)
DBSELECTAREA(CTAB2)

cType := "Arquivo PRN " + "(*.CSV) |*.csv|" //Arquivos .txt

_cArquivo := cGetFile(cType, "Arquivo cabealho ", 0,, .T.,nor(GETF_LOCALHARD,GETF_NETWORKDRIVE))  //Seleciona o arquivo

IF EMPTY(_cArquivo)
	ALERT("Arquivo no encontrado")
	RETURN
ENDIF

//CABEALHO
FT_FUSE(_cArquivo)
FT_FGOTOP()

// Retorna o nmero de linhas do arquivo
NLAST := FT_FLASTREC()

PROCREGUA(NLAST) 

NINC := 0

FOR NX := 1 TO NLAST
	NINC++
	
	INCPROC("Selecionando Dados... " + ALLTRIM(STR(NINC)) + " de " + ALLTRIM(STR(NLAST)) + ".")

	_CLINHA   := FT_FREADLN()
    CNUMLINHA := CVALTOCHAR(NX)
	aLinha    := SPLIT_CAMP( _cLinha, ";") 

	GRAVA_CABEC()    

	FT_FSKIP()
NEXT NX

FT_FUSE() // FECHA O ARQUIVO


//ITEM
cType := "Arquivo PRN " + "(*.CSV) |*.csv|" //Arquivos .txt

_cArquivo := cGetFile(cType, "Arquivo Itens ", 0,, .T.,nor(GETF_LOCALHARD,GETF_NETWORKDRIVE))  //Seleciona o arquivo

IF EMPTY(_cArquivo)
	ALERT("Arquivo no encontrado")
	RETURN
ENDIF

FT_FUSE(_cArquivo)
FT_FGOTOP()

// Retorna o nmero de linhas do arquivo
NLAST := FT_FLASTREC()

PROCREGUA(NLAST) 

NINC := 0

FOR NX := 1 TO NLAST
	NINC++
	
	INCPROC("Selecionando Dados... " + ALLTRIM(STR(NINC)) + " de " + ALLTRIM(STR(NLAST)) + ".")

	_CLINHA   := FT_FREADLN()
    CNUMLINHA := CVALTOCHAR(NX)
	aLinha    := SPLIT_CAMP( _cLinha, ";") 

	GRAVA_ITEM()    

	FT_FSKIP()
NEXT NX

FT_FUSE() // FECHA O ARQUIVO

RETURN

STATIC FUNCTION GRAVA_CABEC

LOCAL CTAB1 := GETMV("XX_TAB1")

DBSELECTAREA(CTAB1)
(CTAB1)->(DBSETORDER(1))

RECLOCK(CTAB1,.T.)
//&(CTAB1+"->"+CTAB1+"_FILIAL") := XFILIAL("")

&(CTAB1+"->"+CTAB1+"_FILIAL" + " := '" + XFILIAL(CTAB1)+"'") 
&(CTAB1+"->"+CTAB1+"_FLAG"   + " := '" + ALINHA[1]+"'") 
&(CTAB1+"->"+CTAB1+"_TIPO"   + " := '" + ALINHA[2]+"'") 
&(CTAB1+"->"+CTAB1+"_DESC"   + " := '" + ALINHA[3]+"'") 
&(CTAB1+"->"+CTAB1+"_CODIGO" + " := '" + ALINHA[4]+"'") 
&(CTAB1+"->"+CTAB1+"_PATH"   + " := '" + ALINHA[5]+"'") 
//&(CTAB1+"->"+CTAB1+"_FRACIO" + " := '" + ALINHA[6]+"'") 
&(CTAB1+"->"+CTAB1+"_METODO" + " := '" + ALINHA[6]+"'") 
&(CTAB1+"->"+CTAB1+"_FUNCAO" + " := '" + ALINHA[7]+"'") 

(CTAB1)->(MSUNLOCK())

RETURN

STATIC FUNCTION GRAVA_ITEM

LOCAL CTAB2 := GETMV("XX_TAB2")

DBSELECTAREA(CTAB2)
(CTAB2)->(DBSETORDER(1))

RECLOCK(CTAB2,.T.)
&(CTAB2+"->"+CTAB2+"_FILIAL" + " := '" + XFILIAL(CTAB2)+"'")
&(CTAB2+"->"+CTAB2+"_CODIGO" + " := '" + ALINHA[1]+"'")  
&(CTAB2+"->"+CTAB2+"_ITEM"   + " := '" + ALINHA[2]+"'")  
&(CTAB2+"->"+CTAB2+"_CAMPO1" + " := '" + ALINHA[3]+"'")  
&(CTAB2+"->"+CTAB2+"_CAMPO2" + " := '" + ALINHA[4]+"'")  
&(CTAB2+"->"+CTAB2+"_TIPO1"  + " := '" + ALINHA[5]+"'")  
&(CTAB2+"->"+CTAB2+"_TIPO2"  + " := '" + ALINHA[6]+"'")   

(CTAB2)->(MSUNLOCK())

RETURN

STATIC FUNCTION SPLIT_CAMP( CSTR, CSEPARADOR)
LOCAL ARET      := {}
LOCAL NPOS      := 0
LOCAL SAIR      := .F.

//SEPARANDO A STRING EM CADA ';' ( PONTO-E-VIRGULA ) OU "+"
DO WHILE( !SAIR )
	NPOS := AT(CSEPARADOR, CSTR)
	IF NPOS > 0
		AADD(ARET, SUBSTR(CSTR, 1, NPOS - 1) )
		CSTR := SUBSTR(CSTR, NPOS + 1)
    ELSE
        SAIR = .T.
		AADD(ARET, ALLTRIM(CSTR) )
    ENDIF
ENDDO

RETURN ARET

USER FUNCTION EXPORT_END

LOCAL CTAB1 := GETMV("XX_TAB1")
LOCAL CTAB2 := GETMV("XX_TAB2")

DBSELECTAREA(CTAB1)
(CTAB1)->(DBSETORDER(1))
(CTAB1)->(DBGOTOP())

_carq := "cab_endpoint.csv"

_cpathtmp:="C:\temp\"//alltrim(gettemppath())

if file(_cpathtmp+_carq)
	ferase(_cpathtmp+_carq)
endif
_nhandle:=fcreate(_cpathtmp+_carq,0)

WHILE !(CTAB1)->(EOF())
	
	CFLAG      := &(CTAB1+"->"+CTAB1+"_FLAG")//ZM1->ZM1_FLAG 
	CTIPO      := &(CTAB1+"->"+CTAB1+"_TIPO")//ZM1_TIPO
	CENDPOINT  := &(CTAB1+"->"+CTAB1+"_DESC")//ZM1->ZM1_DESC
	CCODIGO    := &(CTAB1+"->"+CTAB1+"_CODIGO")//ZM1->ZM1_CODIGO
	CPATH      := &(CTAB1+"->"+CTAB1+"_PATH")//ZM1->ZM1_PATH
	//CPARTICIO  := &(CTAB1+"->"+CTAB1+"_FRACIO")//ZM1->ZM1_FRACIO
	CMETODO    := &(CTAB1+"->"+CTAB1+"_METODO")//ZM1->ZM1_FRACIO
	CFUNCAO    := &(CTAB1+"->"+CTAB1+"_FUNCAO")//ZM1->ZM1_FRACIO

	fwrite(_nhandle,CFLAG+";")	
	fwrite(_nhandle,CTIPO+";")	
	fwrite(_nhandle,CENDPOINT+";")	
	fwrite(_nhandle,CCODIGO+";")	
	fwrite(_nhandle,CPATH+";")	
//	fwrite(_nhandle,CPARTICIO+";")		
	fwrite(_nhandle,CMETODO+";")	
	fwrite(_nhandle,CFUNCAO+chr(13)+chr(10))	
	
	&(CTAB1+"->(DBSKIP())")
ENDDO

fclose(_nhandle)


DBSELECTAREA(CTAB2)
(CTAB2)->(DBSETORDER(1))
(CTAB2)->(DBGOTOP())

_carq := "item_endpoint.csv"

_cpathtmp:="C:\temp\"//alltrim(gettemppath())

if file(_cpathtmp+_carq)
	ferase(_cpathtmp+_carq)
endif
_nhandle:=fcreate(_cpathtmp+_carq,0)

WHILE !(CTAB2)->(EOF())

	CCODIGO    := &(CTAB2+"->"+CTAB2+"_CODIGO")//ZM1->ZM1_FRACIO	
	CITEM      := &(CTAB2+"->"+CTAB2+"_ITEM")//ZM1->ZM1_FLAG 
	CCAMPO1    := &(CTAB2+"->"+CTAB2+"_CAMPO1")//ZM1_TIPO
	CCAMPO2    := &(CTAB2+"->"+CTAB2+"_CAMPO2")//ZM1->ZM1_DESC
	CTIPO1     := &(CTAB2+"->"+CTAB2+"_TIPO1")//ZM1->ZM1_CODIGO
	CTIPO2     := &(CTAB2+"->"+CTAB2+"_TIPO2")//ZM1->ZM1_PATH

	fwrite(_nhandle,CCODIGO+";")	
	fwrite(_nhandle,CITEM+";")	
	fwrite(_nhandle,CCAMPO1+";")	
	fwrite(_nhandle,CCAMPO2+";")	
	fwrite(_nhandle,CTIPO1+";")	
	fwrite(_nhandle,CTIPO2+chr(13)+chr(10))	
	
	&(CTAB2+"->(DBSKIP())")
ENDDO

fclose(_nhandle)

RETURN