#include "totvs.ch"
//------------------------------------------------------------------
//Exemplo de configuração de TGrid em array com navegação por linha
//------------------------------------------------------------------
#define GRID_MOVEUP       0
#define GRID_MOVEDOWN     1
#define GRID_MOVEHOME     2
#define GRID_MOVEEND      3
#define GRID_MOVEPAGEUP   4
#define GRID_MOVEPAGEDOWN 5           
// BFCFGM20 ( Classe para encapsular acesso ao componente TGrid )
//------------------------------------------------------------------------------           
CLASS BFCFGM20    
    DATA oGrid  
    DATA oFrame 
    DATA oButtonsFrame  
    DATA oButtonHome    
    DATA oButtonPgUp    
    DATA oButtonUp  
    DATA oButtonDown    
    DATA oButtonPgDown  
    DATA oButtonEnd 
    DATA aData  
    DATA aHeadData
    DATA nLenData   
    DATA nRecNo 
    DATA nCursorPos     
    DATA nVisibleRows
    DATA nFreeze
      
    METHOD New(oDlg,aData,aHeadData) CONSTRUCTOR    
    METHOD onMove( o,nMvType,nCurPos,nOffSet,nVisRows ) 
    METHOD isBof()  
    METHOD isEof()  
    METHOD ShowData( nFirstRec, nCount )    
    METHOD ClearRows()  
    METHOD DoUpdate()       
    METHOD SelectRow(n)             
    METHOD GoHome()                         
    METHOD GoEnd()  
    METHOD GoPgUp()     
    METHOD GoPgDown()       
    METHOD GoUp(nOffSet)    
    METHOD GoDown(nOffSet)      
    METHOD SetCSS(cCSS)
    METHOD SetFreeze(nFreeze)
ENDCLASS

METHOD New(oDlg, aData,aHeadData) CLASS BFCFGM20   
    Local oFont
          
    ::oFrame:= tPanel():New(0,0,,oDlg,,,,,,200,200 )    
    ::oFrame:Align:= CONTROL_ALIGN_ALLCLIENT
    ::nRecNo:= 1    
    ::nCursorPos:= 0        
    ::nVisibleRows:= Len(aData)     //14 
    // Forçado para 1o ::GoEnd()
   	For iZ := 1 To Len(aData)
   		For iC := 1 To Len(aHeadData)
   			If Len(aHeadData[iC]) >= 4
	    		aData[iZ,iC] := Transform(aData[iZ,iC],aHeadData[iC,4])
	    	Endif
    	Next
    Next
    ::aData:= aData 
    ::aHeadData := aHeadData
    ::nLenData:= Len(aData)     
    ::oGrid:= tGrid():New( ::oFrame )   
    ::oGrid:Align:= CONTROL_ALIGN_ALLCLIENT
                                           
    //oFont := TFont():New('Tahoma',,-32,.T.)
    //::oGrid:SetFont(oFont)   
    //::oGrid:setRowHeight(50)                          
      
    ::oButtonsFrame:= tPanel():New(0,0,, ::oFrame,,,,,, 10,200,.F.,.T. )    
    ::oButtonsFrame:Align:= CONTROL_ALIGN_RIGHT     
    ::oButtonHome:= tBtnBmp():NewBar( "VCTOP.BMP",,,,, {||::GoHome()},,::oButtonsFrame )  
    ::oButtonHome:Align:= CONTROL_ALIGN_TOP 
    ::oButtonPgUp:= tBtnBmp():NewBar( "VCPGUP.BMP",,,,, {||::GoPgUp()},,::oButtonsFrame ) 
    ::oButtonPgUp:Align:= CONTROL_ALIGN_TOP 
    ::oButtonUp:= tBtnBmp():NewBar( "VCUP.BMP",,,,,{||::GoUp(1)},,::oButtonsFrame )
    ::oButtonUp:Align:= CONTROL_ALIGN_TOP 
    ::oButtonEnd:= tBtnBmp():NewBar( "VCBOTTOM.BMP",,,,, {||::GoEnd()},,::oButtonsFrame )
    ::oButtonEnd:Align:= CONTROL_ALIGN_BOTTOM
    ::oButtonPgDown:= tBtnBmp():NewBar( "VCPGDOWN.BMP",,,,, {||::GoPgDown()},,::oButtonsFrame )
    ::oButtonPgDown:Align:= CONTROL_ALIGN_BOTTOM
    ::oButtonDown:= tBtnBmp():NewBar( "VCDOWN.BMP",,,,, {||::GoDown(1)},,::oButtonsFrame )
    ::oButtonDown:Align:= CONTROL_ALIGN_BOTTOM 
                                
	For iZ := 1 To Len(aHeadData)
	    ::oGrid:addColumn( iZ, aHeadData[iZ,1], aHeadData[iZ,2],aHeadData[iZ,3])
    Next
    
    ::oGrid:bCursorMove:= {|o,nMvType,nCurPos,nOffSet,nVisRows| ::onMove(o,nMvType,nCurPos,nOffSet,nVisRows) }   
    ::ShowData(1)    
    ::SelectRow( ::nCursorPos )   
    // configura acionamento do duplo clique    
   // ::oGrid:bLDblClick:= {|| MsgStop("oi") } 
RETURN

METHOD isBof() CLASS BFCFGM20
RETURN  ( ::nRecno==1 )

METHOD isEof() CLASS BFCFGM20
RETURN ( ::nRecno==::nLenData )

METHOD GoHome() CLASS BFCFGM20
    if ::isBof()
        return
    endif
    ::nRecno = 1
    ::oGrid:ClearRows()
    ::ShowData( 1, ::nVisibleRows )    
    ::nCursorPos:= 0
    ::SelectRow( ::nCursorPos )
RETURN
METHOD GoEnd() CLASS BFCFGM20  
    if ::isEof()  
        return
    endif                                       
      
    ::nRecno:= ::nLenData
    ::oGrid:ClearRows()
    ::ShowData( ::nRecno , ::nVisibleRows) // - ::nVisibleRows + 1, ::nVisibleRows )  
    ::nCursorPos:= ::nVisibleRows-1
    ::SelectRow( ::nCursorPos )
RETURN
METHOD GoPgUp() CLASS BFCFGM20
    if ::isBof()
        return
    endif                                
      
    // força antes ir para a 1a linha da grid           
    if ::nCursorPos != 0    
        ::nRecno -= ::nCursorPos
        if ::nRecno <= 0 
            ::nRecno:=1
        endif
        ::nCursorPos:= 0  
        cb:= "{|o| {"
        For iq := 1 To Len(::aHeadData)
        	If iq > 1
        		cb += ","
        	Endif
        	cb += " Self:aData[Self:nRecno,"+Str(iq)+"]"
        Next
        cb += " } }"
        ::oGrid:setRowData( ::nCursorPos, &cb )

     //   ::oGrid:setRowData( ::nCursorPos, {|o| { ::aData[::nRecno,1], ::aData[::nRecno,2], ::aData[::nRecno,3], ::aData[::nRecno,4], ::aData[::nRecno,5], ::aData[::nRecno,6], ::aData[::nRecno,7] } } ) 
    Else
        ::nRecno -= ::nVisibleRows
        if ::nRecno <= 0 
            ::nRecno:=1
        endif
        ::oGrid:ClearRows()
        ::ShowData( ::nRecno, ::nVisibleRows )
        ::nCursorPos:= 0
    endif
    ::SelectRow( ::nCursorPos )
RETURN 
METHOD GoPgDown() CLASS BFCFGM20
    Local nLastVisRow
      
    if ::isEof()
        return
    endif                                         
      
    // força antes ir para a última linha da grid
    nLastVisRow:= ::nVisibleRows-1 
      
    if ::nCursorPos!=nLastVisRow    
      
        if ::nRecno+nLastVisRow > ::nLenData
            nLastVisRow:= ( ::nRecno+nLastVisRow ) - ::nLenData
            ::nRecno:= ::nLenData
        else
            ::nRecNo += nLastVisRow
        endif
          
        ::nCursorPos:= nLastVisRow
	    cb:= "{|o| {"
        For iq := 1 To Len(::aHeadData)
        	If iq > 1
        		cb += ","
        	Endif
        	cb += " Self:aData[Self:nRecno,"+Str(iq)+"]"
        Next
        cb += " } }"
        ::oGrid:setRowData( ::nCursorPos, &cb )

       // ::oGrid:setRowData( ::nCursorPos, {|o| { ::aData[::nRecno,1], ::aData[::nRecno,2], ::aData[::nRecno,3] , ::aData[::nRecno,4], ::aData[::nRecno,5], ::aData[::nRecno,6], ::aData[::nRecno,7]} } )
    else
        ::oGrid:ClearRows()
        ::nRecno += ::nVisibleRows
          
        if ::nRecno > ::nLenData
            ::nVisibleRows = ::nRecno-::nLenData
            ::nRecno:= ::nLenData
        endif 
          
        ::ShowData( ::nRecNo - ::nVisibleRows + 1, ::nVisibleRows )
        ::nCursorPos:= ::nVisibleRows-1
    endif   
      
    ::SelectRow( ::nCursorPos )
RETURN
      
METHOD GoUp(nOffSet) CLASS BFCFGM20
    Local lAdjustCursor:= .F.
    if ::isBof()
        RETURN
    endif
    if ::nCursorPos==0
        ::oGrid:scrollLine(-1)
        lAdjustCursor:= .T.
    else          
        ::nCursorPos -= nOffSet
    endif
    ::nRecno -= nOffSet    
      
    // atualiza linha corrente  
    cb:= "{|o| {"
    For iq := 1 To Len(::aHeadData)
      	If iq > 1
       		cb += ","
       	Endif
       	cb += " Self:aData[Self:nRecno,"+Str(iq)+"]"
	Next
	cb += " } }"
    ::oGrid:setRowData( ::nCursorPos, &cb )
  	//::oGrid:setRowData( ::nCursorPos, {|o| { ::aData[::nRecno,1], ::aData[::nRecno,2], ::aData[::nRecno,3], ::aData[::nRecno,4], ::aData[::nRecno,5], ::aData[::nRecno,6], ::aData[::nRecno,7] } } ) 
      
    if lAdjustCursor  
        ::nCursorPos:= 0
    endif
    ::SelectRow( ::nCursorPos )
RETURN
METHOD GoDown(nOffSet) CLASS BFCFGM20
    Local lAdjustCursor:= .F.    
    if ::isEof()
        RETURN
    endif      
      
    if ::nCursorPos==::nVisibleRows-1
        ::oGrid:scrollLine(1)
        lAdjustCursor:= .T.
    else
        ::nCursorPos += nOffSet
    endif                 
    ::nRecno += nOffSet
      
    // atualiza linha corrente  
    cb:= "{|o| {"
    For iq := 1 To Len(::aHeadData)
      	If iq > 1
       		cb += ","
       	Endif
       	cb += " Self:aData[Self:nRecno,"+Str(iq)+"]"
	Next
	cb += " } }"
	::oGrid:setRowData( ::nCursorPos, &cb )
 //   ::oGrid:setRowData( ::nCursorPos, {|o| { ::aData[::nRecno,1], ::aData[::nRecno,2], ::aData[::nRecno,3] , ::aData[::nRecno,4], ::aData[::nRecno,5], ::aData[::nRecno,6], ::aData[::nRecno,7]} } ) 
    if lAdjustCursor 
        ::nCursorPos:= ::nVisibleRows-1
    endif
    ::SelectRow( ::nCursorPos )       
RETURN
METHOD onMove( oGrid,nMvType,nCurPos,nOffSet,nVisRows ) CLASS BFCFGM20                          
    ::nCursorPos:= nCurPos
    ::nVisibleRows:= nVisRows
      
    if nMvType == GRID_MOVEUP  
        ::GoUp(nOffSet)
    elseif nMvType == GRID_MOVEDOWN       
        ::GoDown(nOffSet)
    elseif nMvType == GRID_MOVEHOME           
        ::GoHome()
    elseif nMvType == GRID_MOVEEND
        ::GoEnd()  
    elseif nMvType == GRID_MOVEPAGEUP
        ::GoPgUp()
    elseif nMvType == GRID_MOVEPAGEDOWN 
        ::GoPgDown()
    endif
RETURN             
METHOD ShowData( nFirstRec, nCount ) CLASS BFCFGM20
    local i, nRec, ci
    DEFAULT nCount:= ::nLenData
      
    for i=0 to nCount-1 
        nRec:= nFirstRec+i
        if nRec > ::nLenData
            RETURN
        endif
        ci:= Str( nRec )             
        
        cb:= "{|o| {"
        For iq := 1 To Len(::aHeadData)
        	If iq > 1
        		cb += ","
        	Endif
        	cb += "Self:aData["+ci+","+Str(iq)+"]"
        Next
        cb += " } }"
        ::oGrid:setRowData( i, &cb )
    next i
RETURN         

METHOD ClearRows() CLASS BFCFGM20
    ::oGrid:ClearRows()
    ::nRecNo:=1
RETURN
METHOD DoUpdate() CLASS BFCFGM20     
    
    For iZ := 1 To Len(::aData)
   		For iC := 1 To Len(::aHeadData)
   			If Len(::aHeadData[iC]) >= 4
	    		::aData[iZ,iC] := Transform(::aData[iZ,iC],::aHeadData[iC,4])
	    	Endif
    	Next
    Next
        
    ::nRecNo:=1
    ::Showdata(1)
    ::SelectRow(0)
RETURN
METHOD SelectRow(n) CLASS BFCFGM20
    ::oGrid:setSelectedRow(n)
RETURN           
METHOD SetCSS(cCSS) CLASS BFCFGM20
    ::oGrid:setCSS(cCSS)
RETURN      
  
METHOD SetFreeze(nFreeze) CLASS BFCFGM20
    ::nFreeze := nFreeze
    ::oGrid:nFreeze := nFreeze
RETURN