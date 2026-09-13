procedure(getOverlapLayerBoxList(cv inst lpp1 lpp2)
    let((shapes1 shapes2 overlapShapes overlapBoxes)
    shapes1 = setof(x inst~>master~>shapes x~>lpp==lpp1)
    shapes2 = setof(x inst~>master~>shapes x~>lpp==lpp2)
    overlapShapes = dbLayerAnd(cv lpp1 shapes1 shapes2)
    overlapBoxes = foreach(mapcar x overlapShapes~>bBox dbTransformBBox(x inst~>transform))
    foreach(y overlapShapes dbDeleteObject(y)) ;删去多余图形
    overlapBoxeslist = sort( overlapBoxes lambda((A B) lessp(cadr(car(A)) cadr(car(B))) )) ;根据y坐标排序
        )
)


pcDefinePCell(
   list(ddGetObj("zsytest") "NOR" "layout")  
      (
        (pl "0.18u")                                ; 沟道长度
        (pw "2.0u")                                ; 沟道宽度
        (nl "0.18u")                          
        (nw "2.0u")                           
        (PNspace "3.0u")                  ;PMOS NMOS间距
   )
nFig = 2
pFig = 2
   
cv = pcCellView
pl_meter = cdfParseFloatString(pl) 
pw_meter = cdfParseFloatString(pw) 
nl_meter = cdfParseFloatString(nl) 
nw_meter = cdfParseFloatString(nw) 
PNspace_meter = cdfParseFloatString(PNspace)
tf = techGetTechFile(cv)
POLayer    = list("POLY1"  "drawing")  ; 多晶硅层
ODLayer    = list("DIFF"   "drawing")  ; 有源区（扩散层）
M1EncCO     = techGetSpacingRule(tf "minEnclosure" "METAL1" "CONT")  ; M1 包覆 CONT
M1PinLayer = list("METAL1" "pin")
M2PinLayer = list("METAL2" "pin")
M1Layer    = list("METAL1" "drawing")
V12w         = techGetSpacingRule(tf "minWidth" "VIA12")        ; VIA12 最小宽度
V12s         = techGetSpacingRule(tf "minSpacing" "VIA12")      ; VIA12 最小间距
V12p         = V12w + V12s                                        ; VIA12 节距
PPNPEncOD   = techGetSpacingRule(tf "minEnclosure" "PIMP" "DIFF")
PathW=0.15 ;互联线宽度
   
   NInstId = dbCreateParamInstByMasterName(
    cv
    "zsytest" "NmosFig2" "layout" "" 
    (0:0) "R0" 1
    list(
    list("l" "string" sprintf(str "%g" nl_meter))
    list("w" "string" sprintf(str "%g" nw_meter))
    list("Fig" "int" nFig)
    )
    );绘制NMOS
    
    temp = atof(aelSuffixNotation((nw_meter+pw_meter)/2 + PNspace_meter))
    PInstId = dbCreateParamInstByMasterName(
        cv
        "zsytest" "PmosFig2" "layout" "" 
        (temp:0) "R180" 1
        list(
        list("l" "string" sprintf(str "%g" pl_meter))
        list("w" "string" sprintf(str "%g" pw_meter))
        list("Fig" "int" pFig)
    )
    );绘制PMOS
    
    NInstOverlap = getOverlapLayerBoxList(cv NInstId POLayer ODLayer)
    PInstOverlap = getOverlapLayerBoxList(cv PInstId POLayer ODLayer) ;计算栅极坐标
    temp1 = 0.4 ;金属与栅极间距
    Polyfinger1width = (PNspace_meter*1e6)/3-temp1 ;与ploy重叠的ploy长度
     

    
    
    foreach(PFinger  PInstOverlap
        LeftX = caar(PFinger)
        MidY = (cadar(PFinger)+cadadr(PFinger))/2
        x1 = LeftX-(PNspace_meter*1e6)/2 ;从Pmos栅极衍生出去的第一个poly的左边的坐标
        dbCreatePath(cv "POLY1"
            list(x1:MidY LeftX:MidY)
            nl_meter*1e6)
        rodCreateRect(
            ?cvId   cv
            ?layer "METAL1"
            ?width Polyfinger1width ;
            ?length pl_meter*1e6
            ?origin x1:MidY-pl_meter*1e6/2 
            ?subRectArray list( list(
                ?layer "CONT"
                ?width 0.10
                ?length 0.10
                ?gap "distribute"                    ; 均匀分布
                ?lowerLeftOffsetX 0.10
                ?lowerLeftOffsetY 0.0
                ?upperRightOffsetX -0.1
                ?upperRightOffsetY 0.0
                ?spaceX            0.2
                ?spaceY            0.1   ) )    ;End ofsubRectArray 
                ) 
    );End of rod  创建PMOS的Finger栅极的衍生ploy
    
    foreach(NFinger  NInstOverlap
        RightX = caadr(NFinger)
        MidY = (cadar(NFinger)+cadadr(NFinger))/2
        x2 = RightX+(PNspace_meter*1e6)/2-0.15 ;从Nmos栅极衍生出去的第一个poly的右边的坐标
        dbCreatePath(cv "POLY1"
            list(x2:MidY RightX:MidY)
            nl_meter*1e6)
        rodCreateRect(
            ?cvId   cv
            ?layer "METAL1"
            ?width Polyfinger1width ;
            ?length nl_meter*1e6
            ?origin x2-Polyfinger1width:MidY-nl_meter*1e6/2 
            ?subRectArray list( list(
                ?layer "CONT"
                ?width 0.10
                ?length 0.10
                ?gap "distribute"                    ; 均匀分布
                ?lowerLeftOffsetX 0.10
                ?lowerLeftOffsetY 0.0
                ?upperRightOffsetX -0.1
                ?upperRightOffsetY 0.0
                ?spaceX            0.2
                ?spaceY            0.1   ) )    ;End ofsubRectArray 
                ) 
        );End of rod  创建NMOS的Finger栅极的衍生ploy
    
    netIn1 = dbCreateNet(cv "netIn1")                   ; 创建网络 "A"
    netIn1term = dbCreateTerm(netIn1 "netIn1term" "input")               ; 创建端子，方向为 input
    netIn2 = dbCreateNet(cv "netIn2")                   ; 创建网络 "A"
    netIn2term = dbCreateTerm(netIn2 "netIn2term" "input")               ; 创建端子，方向为 input
    
    y1 = cadr(car(car(NInstOverlap)))
    y2 = cadr(cadr(car(NInstOverlap)))
    MidY1= (y1+y2)/2
    dbCreatePath(cv M1Layer 
            list(x2:MidY1 x1:MidY1) PathW=0.15 )
    PinInputFig= dbCreateRect(cv M1PinLayer 
               list(x2:MidY1-0.11 x1:MidY1+0.11 ))
    PinInput1 = dbCreatePin(netIn1 PinInputFig "netIn1")
    
    y1 = cadr(car(cadr(NInstOverlap)))
    y2 = cadr(cadr(cadr(NInstOverlap)))
    MidY2= (y1+y2)/2
    dbCreatePath(cv M1Layer 
            list(x2:MidY2 x1:MidY2) PathW=0.15 )
    PinInputFig2= dbCreateRect(cv M1PinLayer 
               list(x2:MidY2-0.11 x1:MidY2+0.1))
    PinInput2 = dbCreatePin(netIn2 PinInputFig2 "netIn2")
    
    NInstOverlap2=getOverlapLayerBoxList(cv NInstId M1Layer ODLayer)
    for(i 0 length(NInstOverlap2)-1
        if( i == 0 || i ==2 then
            Xcenter = car(centerBox(nth(i NInstOverlap2)))
            Ycenter = cadr(centerBox(nth(i NInstOverlap2)))
            VSSpath=dbCreatePath(cv "METAL1" 
               list(Xcenter+nw_meter/2*1e6:Ycenter  leftEdge(NInstId)-1.0:Ycenter  )        ;VSS连线
               nl_meter*1e6)
         )   ;   VSS连线
         if( i == 1 then
         Xcenter = car(centerBox(nth(i NInstOverlap2)))
         Ycenter = cadr(centerBox(nth(i NInstOverlap2)))
         M2pathn=dbCreatePath(cv "METAL2"
                list(Xcenter-nw_meter/2*1e6:Ycenter  rightEdge(NInstId)+PNspace_meter*1e6/2:Ycenter  ) 
                nl_meter*1e6)
                )   ;M输出连线
    );
    
    PInstOverlap2=getOverlapLayerBoxList(cv PInstId M1Layer ODLayer)
    for(i 0 length(PInstOverlap2)-1
        if( i == 0 then
            Xcenter = car(centerBox(nth(i PInstOverlap2)))
            Ycenter = cadr(centerBox(nth(i PInstOverlap2)))
            VDDpath=dbCreatePath(cv "METAL1" 
               list(Xcenter-pw_meter/2*1e6:Ycenter  rightEdge(PInstId)+1.0:Ycenter  )        ;VSS连线
               pl_meter*1e6)
        )   ;   VDD连线
        if( i == 2 then
            Xcenter = car(centerBox(nth(i PInstOverlap2)))
            Ycenter = cadr(centerBox(nth(i PInstOverlap2)))
            M2pathp=dbCreatePath(cv "METAL2"
                list(Xcenter+pw_meter/2*1e6:Ycenter  leftEdge(PInstId)-PNspace_meter*1e6/2-PathW:Ycenter  ) 
                pl_meter*1e6)
        )
    )
    
     x1=leftEdge(NInstId)-1.0
     y1=bottomEdge(NInstId)+0.1
     y2=topEdge(NInstId)-0.1
     VSSpath = rodCreatePath(
           ?cvId cv
           ?layer "METAL1"
           ?pts list(x1:y1  x1:y2)
           ?width 0.5
           ?pin t
           ?pinAccessDir list("top" "bottom" "left" "right")
           ?termName "TermVSS"
           ?subRect  list( list(
               ?layer M1PinLayer
               ?width 0.22
               ?length 0.22
               ?gap "distribute"           
               ?beginOffset -0.35
               ?endOffset -0.35
               ?space            0.3      ));End ofsubRectArray
           )  ;
       dbCreateLabel(cv M1PinLayer x1:(bottomEdge(NInstId)+topEdge(NInstId))/2.0 "VSS" "centerLeft" "R90" "roman" 0.3 );  VSS Label
       VSSRing = rodCreateRect(
           ?cvId  cv
           ?layer "PIMP"
           ?fromObj VSSpath
           ?size PPNPEncOD)     ;VSS保护环
        

     x2=rightEdge(PInstId)+1.0
     y1=bottomEdge(PInstId)+0.1
     y2=topEdge(PInstId)-0.1
     VDDpath = rodCreatePath(
           ?cvId cv
           ?layer "METAL1"
           ?pts list(x2:y1    x2:y2)
           ?width 0.5
           ?pin t
           ?pinAccessDir list("top" "bottom" "left" "right")
           ?termName "TermVDD"
           ?subRect  list( list(
               ?layer M1PinLayer
               ?width 0.22
               ?length 0.22
               ?gap "distribute"           
               ?beginOffset -0.35
               ?endOffset -0.35
               ?space     0.3      ));End ofsubRectArray
           )
      dbCreateLabel(cv M1PinLayer x2:(bottomEdge(PInstId)+topEdge(PInstId))/2.0 "VDD" "centerLeft" "R90" "roman" 0.3) ;  VDD Label
       VDDRing = rodCreateRect(
           ?cvId  cv
           ?layer "NIMP"
           ?fromObj VDDpath
           ?size PPNPEncOD
             )  ;VDD保护环
    
    x1=leftEdge(M2pathp)
    x2=rightEdge(M2pathn)
    y1=topEdge(M2pathp)
    y2=bottomEdge(M2pathn)
    M2outputPath= dbCreatePath( cv "METAL2" list((x1+x2)/2:y1 (x1+x2)/2:y2) PathW) ;M2金属连线 用于output
    
    netOut = dbCreateNet(cv "netOut")                   ; 创建网络 
    netOutterm = dbCreateTerm(netIn1 "netOutterm" "output")               ;
    PinOutputFig= dbCreateRect(cv M2PinLayer list(x1:y1  x1+0.11:y1-0.11))
    PinOutput = dbCreatePin(netOut PinOutputFig "netOut")
    
    
    
    
    
    
    
    );
    
    