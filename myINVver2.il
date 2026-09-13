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
   list(ddGetObj("zsytest") "myINVver2" "layout")  
   (
        (pl "0.18u")                                ; 沟道长度
        (pw "2.0u")                                ; 沟道宽度
        (pFig 3)
        (nl "0.18u")                          
        (nw "2.0u")                           
        (nFig 3)
        (PNspace "3.0u")                  ;PMOS NMOS间距
   )
pl_meter = cdfParseFloatString(pl) 
pw_meter = cdfParseFloatString(pw) 
nl_meter = cdfParseFloatString(nl) 
nw_meter = cdfParseFloatString(nw) 
PNsapce_meter = cdfParseFloatString(PNspace)
cv = pcCellView
tf = techGetTechFile(cv)
POLayer    = list("POLY1"  "drawing")  ; 多晶硅层
ODLayer    = list("DIFF"   "drawing")  ; 有源区（扩散层）
M1EncCO     = techGetSpacingRule(tf "minEnclosure" "METAL1" "CONT")  ; M1 包覆 CONT
M1PinLayer = list("METAL1" "pin")
M2PinLayer = list("METAL2" "pin")
V12w         = techGetSpacingRule(tf "minWidth" "VIA12")        ; VIA12 最小宽度
V12s         = techGetSpacingRule(tf "minSpacing" "VIA12")      ; VIA12 最小间距
V12p         = V12w + V12s                                        ; VIA12 节距
PPNPEncOD   = techGetSpacingRule(tf "minEnclosure" "PIMP" "DIFF")
 
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

    temp = atof(aelSuffixNotation((nw_meter+pw_meter)/2 + PNsapce_meter))
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
    metal1width = (PNsapce_meter*1e6)/3-temp1 ;与ploy重叠的金属条长度
    
    foreach(a NInstOverlap
        MidY= (cadar(a)+cadadr(a))/2;栅极中心
        LeftX = caadr(a)      ;横坐标为栅极overlap的最左侧
        dbCreatePath(cv "POLY1"
            list(LeftX:MidY LeftX+(PNsapce_meter*1e6)/2:MidY)
            nl_meter*1e6)
        rodCreateRect(
            ?cvId   cv
            ?layer "METAL1"
            ?width metal1width ;
            ?length nl_meter*1e6
            ?origin LeftX+2*temp1:MidY-nl_meter*1e6/2 
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
                ?spaceY            0.1   ) )    ;End ofsubRectArray 今天写到这里
    ) ;End of rod
    );End foreach  ;绘制Nmos的栅极延伸
       
  
    
    foreach(b PInstOverlap
    MidY= (cadar(b)+cadadr(b))/2;栅极中心
    RightX = caar(b)
    dbCreatePath(cv "POLY1"
        list(RightX:MidY RightX-(PNsapce_meter*1e6)/2:MidY)
        pl_meter*1e6)
    rodCreateRect(
            ?cvId   cv
            ?layer "METAL1"
            ?width (PNsapce_meter*1e6)/3-temp1 ;
            ?length pl_meter*1e6
            ?origin RightX-(PNsapce_meter*1e6)/2:MidY-pl_meter*1e6/2 
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
                ?spaceY            0.1   ) )    ;End ofsubRectArray 今天写到这里
    ) ;End of rod        
    );End foreach  绘制pmos的栅极延伸
    
    xgate1=LeftX+2*temp1+2*metal1width/3 ;上述Nmos 栅极的rodCreateRect的x坐标加长度的2/3
    xgaye2=RightX-(PNsapce_meter*1e6)/2+metal1width/3
    ygate1=1e9
    ygate2=-1e9
    foreach(a NInstOverlap
        ygate1 = min(ygate1 cadar(a) cadadr(a))
        ygate2 = max(ygate2 cadar(a) cadadr(a)))  ;求重叠区域Y最小值、最大值用于M1金属的坐标
    foreach(a PInstOverlap
        ygate1 = min(ygate1 cadar(a) cadadr(a))
        ygate2 = max(ygate2 cadar(a) cadadr(a)))  ;求重叠区域Y最小值、最大值用于M1金属的坐标
    
    
    M1metalPath=InputMetal=dbCreateRect(
        cv
        "METAL1"
        list(xgate1:ygate1  xgaye2:ygate2)
        )   ;输入端金属连线
        
        
    pinFigA=dbCreateRect(cv M1PinLayer
            list(   car(centerBox(M1metalPath~>bBox))-0.11 : cadr(centerBox(M1metalPath~>bBox))-0.11
                    car(centerBox(M1metalPath~>bBox))+0.11 : cadr(centerBox(M1metalPath~>bBox))+0.11 ))
    netA = dbCreateNet(cv "A")
    dbCreateTerm(netA "A" "input")
    dbCreateLabel(cv M1PinLayer centerBox(M1metalPath~>bBox) "A" "centerLeft" "R0" "roman" 0.11 )
    pinA = dbCreatePin(netA pinFigA "A") ;创建引脚
    pinA~>accessDir = list("top" "bottom" "left" "right")  ; 设置可访问方向
    
    N_DLabels = setof(x NInstId~>master~>shapes  x~>objType == "label" && x~>theLabel == "D")
    P_DLabels = setof(x PInstId~>master~>shapes  x~>objType == "label" && x~>theLabel == "D")
    N_DLabels = foreach(mapcar x  N_DLabels~>bBox dbTransformBBox(x NInstId~>transform))
    P_DLabels = foreach(mapcar x  P_DLabels~>bBox dbTransformBBox(x PInstId~>transform))
    connect = xgate1-0.6                                          ;M2金属在x=xgate1-0.6 的位置连接
    P_Ymin = apply('min foreach(mapcar x P_DLabels cadar(x)))    ;寻找PMOS漏极y最小值
    P_Ymax = apply('max foreach(mapcar x P_DLabels cadadr(x)))
    N_Ymin = apply('min foreach(mapcar x N_DLabels cadar(x)))   ;寻找NMOS漏极y最小值
    N_Ymax = apply('max foreach(mapcar x N_DLabels cadadr(x)))
    M2y=apply('min list(bottomEdge(NInstId) bottomEdge(PInstId))) + 0.4 ;M2金属y坐标
    
    netY = dbCreateNet(cv "Y")
    dbCreateTerm(netY "Y" "output")
    foreach(a N_DLabels
        Xcenter = car(centerBox(a))
        Ycenter = cadr(centerBox(a))
        tmpNet=dbCreatePath(cv "METAL2" 
               list(Xcenter-nw_meter/2*1e6:Ycenter  connect+0.15:Ycenter  )
               0.3)
        dbCreateViaShapeArray(cv "VIA12" netY
            Xcenter-nw_meter*1e6/4 Ycenter-V12w/2 V12p V12p V12w V12w 1 2)
        ); End foreach 创建M2与Nmos互连金属
    
    foreach(a P_DLabels
        Xcenter = car(centerBox(a))
        Ycenter = cadr(centerBox(a))
        dbCreatePath(cv "METAL2" 
            list(connect-0.15:Ycenter  Xcenter+pw_meter/2*1e6:Ycenter  )
            0.3)
        dbCreateViaShapeArray(cv "VIA12" netY
            Xcenter-pw_meter*1e6/4 Ycenter-V12w/2 V12p V12p V12w V12w 1 2)
        ); End foreach 创建M2与Pmos互连金属
    
    N_SLabels = setof(x NInstId~>master~>shapes  x~>objType == "label" && x~>theLabel == "S")
    P_SLabels = setof(x PInstId~>master~>shapes  x~>objType == "label" && x~>theLabel == "S")
    N_SLabels = foreach(mapcar x  N_SLabels~>bBox dbTransformBBox(x NInstId~>transform))
    P_SLabels = foreach(mapcar x  P_SLabels~>bBox dbTransformBBox(x PInstId~>transform))
    
    foreach(a N_SLabels
        Xcenter = car(centerBox(a))
        Ycenter = cadr(centerBox(a))
        tmpNet=dbCreatePath(cv "METAL1" 
               list(Xcenter+nw_meter/2*1e6:Ycenter  leftEdge(NInstId)-1.5:Ycenter  )        ;源极和VSS连线
               nl_meter*1e6)
         );
         
     x1=leftEdge(NInstId)-1.5
     y1=bottomEdge(NInstId)+0.1
     y2=topEdge(NInstId)-0.1
    VSSpath = rodCreatePath(
           ?cvId cv
           ?layer "METAL1"
           ?pts list(x1:y1  x1:y2)
           ?width 0.5
           ?pin t
           ?pinAccessDir list("top" "bottom" "left" "right")
           ?termName "VSS"
           ?subRect  list( list(
               ?layer M1PinLayer
               ?width 0.22
               ?length 0.22
               ?gap "distribute"           
               ?beginOffset -0.35
               ?endOffset -0.35
               ?space            0.3      ));End ofsubRectArray
           )
       dbCreateLabel(cv M1PinLayer x1:(bottomEdge(NInstId)+topEdge(NInstId))/2.0 "VSS" "centerLeft" "R90" "roman" 0.3 );  VSS Label
       VSSRing = rodCreateRect(
           ?cvId  cv
           ?layer "PIMP"
           ?fromObj VSSpath
           ?size PPNPEncOD)     ;VSS保护环
           
           
       foreach(a P_SLabels
        Xcenter = car(centerBox(a))
        Ycenter = cadr(centerBox(a))
        dbCreatePath(cv "METAL1" 
            list( Xcenter-pw_meter/2*1e6:Ycenter  rightEdge(PInstId)+1.5:Ycenter  )  ;源极和VDD连线
            pl_meter*1e6)
       ); 
       
       x2=rightEdge(PInstId)+1.5
       y1=bottomEdge(PInstId)+0.1
       y2=topEdge(PInstId)-0.1
       VDDpath = rodCreatePath(
           ?cvId cv
           ?layer "METAL1"
           ?pts list(x2:y1    x2:y2)
           ?width 0.5
           ?pin t
           ?pinAccessDir list("top" "bottom" "left" "right")
           ?termName "VDD"
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
           
           
       netVDD = dbFindNetByName(cv "VDD")
       netVSS = dbFindNetByName(cv "VSS")
       dbCreateTerm(netVDD "VDD" "inputOutput")
       dbCreateTerm(netVSS "VSS" "inputOutput")
    
    
    
    
    
    
    
    M2metalpathlength=max(P_Ymax N_Ymax)-M2y   ;输出端M2金属长度
    M2metalpath=rodCreateRect(
            ?cvId   cv
            ?layer "METAL2"
            ?width 0.35
            ?length M2metalpathlength+0.2
            ?origin connect-0.35/2:M2y) ;输出端M2金属连线
    
    
    pinFigY=dbCreateRect(cv M2PinLayer
                        list(connect-0.11:M2y+0.1  connect+0.11:M2y+0.32)    )
    
    dbCreateLabel(cv M2PinLayer centerBox(pinFigY~>bBox) "Y" "centerLeft" "R0" "roman" 0.11 )
    pinY = dbCreatePin(netY pinFigY "Y") ;创建引脚
    pinY~>accessDir = list("top" "bottom" "left" "right")  ; 设置可访问方向

    
    
    ) ; End of PcDefinPcell
    


