procedure(crGetOverlapLayerBoxList(cv inst lpp1 lpp2)
    let((Shp1 Shp2 OverlapLayerOut OverlapLayerBoxList)
         Shp1=setof(x inst~>master~>shapes x~>lpp==lpp1)
         Shp2=setof(x inst~>master~>shapes x~>lpp==lpp2)
         OverlapLayerOut=dbLayerAnd(cv lpp1 Shp1 Shp2)
         OverlapLayerBoxList=foreach(mapcar x OverlapLayerOut~>bBox dbTransformBBox(x inst~>transform))
         foreach(one OverlapLayerOut dbDeleteObject(one))
         OverlapLayerBoxList=sort(OverlapLayerBoxList lambda((A B) lessp(caadr(A) caadr(B))))
        );let
);proc

procedure(crSnapUpToGrid(value grid)
  if(grid && grid > 0.0 then
    ceiling((value - 1e-12) / grid) * grid
  else
    value
  )
)

procedure(crCreatePMOSGate(cv PInst)
    let((PInstOverlap TopY LeftX RightX BottomY X_CO Y_CO tmp)
        PInstOverlap = crGetOverlapLayerBoxList(cv PInst POLayer ODLayer)
          unless(PInstOverlap
          error("PMOS 未找到 POLY1 与 DIFF 的重叠区域。请检查器件层名及 crGetOverlapLayerBoxList。")
               )  
        PInstOverlap=car(PInstOverlap)
          unless(bottomEdge(PInstOverlap)
          error("PInstOverlap bBox calculate error")
               ) 

        TopY=bottomEdge(PInstOverlap)-0.1
        LeftX= leftEdge(PInstOverlap)
        RightX = rightEdge(PInstOverlap)
            if(RightX-LeftX< COw +0.2                 ;poly和CO需要0.1 的间距
                then tmp = COw +0.2 - (RightX-LeftX)
                RightX = RightX +tmp/2
                LeftX = LeftX - tmp/2
                )
        BottomY=TopY-CORows*COw-(CORows-1)*COs-PNSpace_var*1e6/6
        BottomY=crSnapUpToGrid(BottomY mfgGrid)
        dbCreateRect(cv POLayer list(LeftX:BottomY RightX:TopY))
        dbCreateRect(cv M1Layer list(LeftX:BottomY RightX:TopY-0.2))
        
        X_CO=(LeftX+RightX)/2-COw/2
        
        for( i 0 CORows-1
            Y_CO=BottomY+POEncCO+i*(COw+COs)
            dbCreateRect(cv COLayer list(X_CO:Y_CO X_CO+COw:Y_CO+COw))       
        )
        PMOSGateY = BottomY
    )
    ; println("47")
)

procedure(crCreateNMOSGate(cv NInst)
    let((NInstOverlap TopY LeftX RightX BottomY X_CO Y_CO tmpMidX)
        NInstOverlap = crGetOverlapLayerBoxList(cv NInst POLayer ODLayer)
            unless(NInstOverlap
                  error("NMOS 未找到 POLY1 与 DIFF 的重叠区域。请检查器件层名及 crGetOverlapLayerBoxList。")
                   )  
        NInstOverlap=car(NInstOverlap)
            unless(leftEdge(NInstOverlap)
                  error("NInstOverlap bBox calculate error")
                   ) 
                   
        LeftX = leftEdge(NInstOverlap)
        RightX = rightEdge(NInstOverlap)
            if(RightX-LeftX< COw+0.2                ;poly和CO需要0.1 的间距
                then tmp = COw+0.2-(RightX-LeftX)
                RightX = RightX+tmp/2
                LeftX = LeftX-tmp/2
                )
        BottomY=topEdge(NInstOverlap)+0.1
        TopY=BottomY+CORows*COw+(CORows-1)*COs+PNSpace_var*1e6/6
        TopY=crSnapUpToGrid(TopY mfgGrid)
        dbCreateRect(cv POLayer list(LeftX:BottomY RightX:TopY))
        dbCreateRect(cv M1Layer list(LeftX:BottomY+0.2 RightX:TopY))
        
        X_CO=(LeftX+RightX)/2-COw/2
        
        for( i 0 CORows-1
            Y_CO=TopY-POEncCO-i*(COw+COs)-COw
            dbCreateRect(cv COLayer list(X_CO:Y_CO X_CO+COw:Y_CO+COw))       
        )
        NMOSGateY = TopY
        MidX = ( LeftX+RightX )/2
      ;  println("61")
    )
)






pcDefinePCell(list(ddGetObj("zsytest") "nand2_2v" "layout")
        (
        (pl "0.3u")                               ; 沟道长度
        (pw "1.0u")                                ; 沟道宽度
        (nl "0.3u")                          
        (nw "1.0u")                           
        (PNSpace "3.0u")                  ;PMOS NMOS间距
        )
    cv=pcCellView 
    pw_var=cdfParseFloatString(pw)
    nw_var=cdfParseFloatString(nw)
    pl_var=cdfParseFloatString(pl)
    nl_var=cdfParseFloatString(nl)
    PNSpace_var=cdfParseFloatString(PNSpace)
    tf=techGetTechFile(cv)
    POLayer    = list("POLY1"  "drawing")  ; 多晶硅层
    ODLayer    = list("DIFF"   "drawing")  ; 有源区（扩散层）
    COLayer=list("CONT" "drawing")
    M1EncCO     = techGetSpacingRule(tf "minEnclosure" "METAL1" "CONT")  ; M1 包覆 CONT
    M1EncV1=techGetSpacingRule(tf "minEnclosure" "METAL1" "VIA12")
    M1PinLayer = list("METAL1" "pin")
    M2PinLayer = list("METAL2" "pin")
    M1Layer    = list("METAL1" "drawing")
    M2Layer    = list("METAL2" "drawing")
    V12w         = techGetSpacingRule(tf "minWidth" "VIA12")        ; VIA12 最小宽度
    V12s         = techGetSpacingRule(tf "minSpacing" "VIA12")      ; VIA12 最小间距
    V12p         = V12w + V12s                                        ; VIA12 节距
    PPNPEncOD   = techGetSpacingRule(tf "minEnclosure" "PIMP" "DIFF")
    POEncCO     = techGetSpacingRule(tf "minEnclosure" "POLY1" "CONT")
    PathW=0.15 ;互联线宽度
    COw=techGetSpacingRule(tf "minWidth" "CONT")
    COs=techGetSpacingRule(tf "minSpacing" "CONT")
    CORows = 2
    mfgGrid=techGetMfgGridResolution(tf)
    
    NInstId1=dbCreateParamInstByMasterName(cv "tsmc18" "nmos2v" "layout" "" list(0 0) "R0" 1
                                          list(    list("w"  "string" sprintf(str,"%g",nw_var))                 
                                                   list("l"  "string" sprintf(str,"%g",nl_var))
                                              )
                                          )
    tmpX=0.72+(nl_var*1e6-0.18)
    NInstId2=dbCreateParamInstByMasterName(cv "tsmc18" "nmos2v" "layout" "" list(tmpX 0) "R0" 1
                                          list(    list("w"  "string" sprintf(str,"%g",nw_var))                 
                                                   list("l"  "string" sprintf(str,"%g",nl_var))
                                              )
                                          )
    tmpY=atof(aelSuffixNotation(nw_var+PNSpace_var))
    PInstId1=dbCreateParamInstByMasterName(cv "tsmc18" "pmos2v" "layout" "" list(0 tmpY) "R0" 1
                                          list(  list("w"  "string" sprintf(str,"%g",pw_var))                 
                                                 list("l"  "string" sprintf(str,"%g",pl_var))
                                                 )
                                          )

    PInstId2=dbCreateParamInstByMasterName(cv "tsmc18" "pmos2v" "layout" "" list(tmpX tmpY) "R0" 1
                                          list(  list("w"  "string" sprintf(str,"%g",pw_var))                 
                                                 list("l"  "string" sprintf(str,"%g",pl_var))
                                              )
                                          )
    pairs=list(list(PInstId1 NInstId1) list(PInstId2 NInstId2))
    netIn1 = dbCreateNet(cv "netIn1")                   ; 创建网络 "A"
    netIn1term = dbCreateTerm(netIn1 "netIn1term" "input")               ; 创建端子，方向为 input
    netIn2 = dbCreateNet(cv "netIn2")                   ; 创建网络 "A"
    netIn2term = dbCreateTerm(netIn2 "netIn2term" "input")               ; 创建端子，方向为 input
    i = 1
    foreach(x pairs
        crCreatePMOSGate(cv car(x))
        crCreateNMOSGate(cv cadr(x))
        path=dbCreatePath(cv M1Layer list(MidX:NMOSGateY MidX:PMOSGateY) nl_var*1e6)  ; M1 input线宽直接被定为nl_var
        MidY=(NMOSGateY+PMOSGateY)/2
        netName = sprintf(nil "netIn%d" i)
        pinName = netName
        netId = dbFindNetByName(cv netName)
        PinInputFig=dbCreateRect(cv M1PinLayer list(MidX-0.12:MidY-0.12 MidX+0.12:MidY+0.12))
        PinInput=dbCreatePin(netId PinInputFig pinName)
        i=i+1
    )                  ;创建输入端互连线
    
   ;  println("162")
     x1=leftEdge(NInstId1)
     x2=rightEdge(NInstId2)
     VSSy1=bottomEdge(NInstId1)-0.7
     VSSpath = rodCreatePath(
           ?cvId cv
           ?layer "METAL1"
           ?pts list(x1:VSSy1  x2:VSSy1)
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
     dbCreateLabel(cv M1PinLayer x1:VSSy1 "VSS" "centerLeft" "R0" "roman" 0.3 );  VSS Label
     VSSRing = rodCreateRect(
           ?cvId  cv
           ?layer "PIMP"
           ?fromObj VSSpath
           ?size PPNPEncOD)     ;VSS保护环
    
     x1=leftEdge(PInstId1)
     x2=rightEdge(PInstId2)
     VDDy1=topEdge(PInstId1)+0.7
     VDDpath = rodCreatePath(
           ?cvId cv
           ?layer "METAL1"
           ?pts list(x1:VDDy1  x2:VDDy1)
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
           )  ;
     dbCreateLabel(cv M1PinLayer x1:VDDy1 "VDD" "centerLeft" "R0" "roman" 0.3 );  VDD Label
     VDDRing = rodCreateRect(
           ?cvId  cv
           ?layer "NIMP"
           ?fromObj VDDpath
           ?size PPNPEncOD)     ;VDD保护环
   ;  println("216")
     
     
     PInstOverlap1=crGetOverlapLayerBoxList(cv PInstId1 M1Layer ODLayer)
     Overlap1=car(PInstOverlap1)
     MidX = (caar(Overlap1) + caadr(Overlap1))/2
     y1=cadar(Overlap1)
     y2=VDDy1
     dbCreatePath(cv M1Layer list(MidX:y1 MidX:y2) 0.24)  ;连接VDD线
     
     
     Overlap2=cadr(PInstOverlap1)
     netOut = dbCreateNet(cv "netOut")
     dbCreateTerm(netOut "netOutTerm" "output")
     ;viaX=leftEdge(Overlap2)+M1EncV1
     viaX = (caar(Overlap2) + caadr(Overlap2))/2-V12w/2
     viaY= bottomEdge(Overlap2)+M1EncV1
     dbCreateViaShapeArray(cv "VIA12" netOut
            viaX viaY V12p V12p V12w V12w 2 1) ;创建PMOS的M2孔
     dbCreatePath(cv M1Layer list(viaX+V12w/2:viaY-0.01 viaX+V12w/2:viaY+CORows*V12w+(CORows-1)*V12s+0.1 ) V12w+0.12) ; 多建个路径包裹M2孔,DRC要求M1包裹V12大于0.06
     
     PInstOverlap2=crGetOverlapLayerBoxList(cv PInstId2 M1Layer ODLayer)
     Overlap2=cadr(PInstOverlap2)
     MidX = (caar(Overlap2) + caadr(Overlap2))/2
     y1=cadar(Overlap2)
     y2=VDDy1
     dbCreatePath(cv M1Layer list(MidX:y1 MidX:y2) 0.24) ;连接VDD线

     Overlap1=car(PInstOverlap2)
     M2_x1=(caar(Overlap1) + caadr(Overlap1))/2
     M2_y1=cadadr(Overlap1)
     M2_x2=M2_x1
     M2_y2=atof(aelSuffixNotation(nw_var+PNSpace_var/2))-0.5;      计算M2path路径
     ;println("224")
     NInstOverlap1=crGetOverlapLayerBoxList(cv NInstId1 M1Layer ODLayer)
     Overlap1=car(NInstOverlap1)
     MidX = (caar(Overlap1) + caadr(Overlap1))/2
     M2_x3 = MidX
     M2_y3 = M2_y2
     M2_x4 = M2_x3
     M2_y4 = bottomEdge(Overlap1)
     ;viaX=leftEdge(Overlap1)+M1EncV1
     viaX=(caar(Overlap1) + caadr(Overlap1))/2-V12w/2
     viaY=bottomEdge(Overlap1)+M1EncV1
     dbCreateViaShapeArray(cv "VIA12" netOut
            viaX viaY V12p V12p V12w V12w 2 1) ;创建NMOS的M2孔
     dbCreatePath(cv M1Layer list(viaX+V12w/2:viaY-0.01 viaX+V12w/2:viaY+CORows*V12w+(CORows-1)*V12s+0.1 ) V12w+0.12) ; 多建个路径包裹M2孔,DRC要求M1包裹V12大于0.06
     
     NInstOverlap2=crGetOverlapLayerBoxList(cv NInstId2 M1Layer ODLayer)
     Overlap2=cadr(NInstOverlap2)
     MidX = (caar(Overlap2) + caadr(Overlap2))/2
     y2 = cadadr(Overlap2)
     y1 = VSSy1
     dbCreatePath(cv M1Layer list(MidX:y1 MidX:y2) 0.24) ;连接VSS线
     
     M2Path=dbCreatePath(cv M2Layer list(M2_x1:M2_y1 M2_x2:M2_y2 M2_x3:M2_y3 M2_x4:M2_y4) 0.38)  ;M2线宽写为0.38
     pinOutputFig=dbCreateRect(cv M2PinLayer list(M2_x2-0.11:M2_y2-0.11 M2_x2+0.11:M2_y2+0.11) )
     PinOutput = dbCreatePin(netOut pinOutputFig "netOut")

)