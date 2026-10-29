procedure(crGetOverlapLayerBoxList(cv inst lpp1 lpp2)
    let((Shp1 Shp2 OverlapLayerOut OverlapLayerBoxList)
         Shp1=setof(x inst~>master~>shapes x~>lpp==lpp1)
         Shp2=setof(x inst~>master~>shapes x~>lpp==lpp2)
         OverlapLayerOut=dbLayerAnd(cv lpp1 Shp1 Shp2)
         OverlapLayerBoxList=foreach(mapcar x OverlapLayerOut~>bBox dbTransformBBox(x inst~>transform))
         foreach(one OverlapLayerOut dbDeleteObject(one))
         OverlapLayerBoxList=sort(OverlapLayerBoxList lambda((A B) lessp(caadr(A) caadr(B))))
        );let 按右边界 x 坐标从小到大排序
);proc

procedure(crSnapUpToGrid(value grid)
  if(grid && grid > 0.0 then
    ceiling((value - 1e-12) / grid) * grid
  else
    value
  )
)

procedure(crConnectDrainSorce(cv Inst1 Inst2)   ;
    let((a b x Soece Drain)
        Inst1=crGetOverlapLayerBoxList(cv Inst1 M1Layer ODLayer)
        Inst2=crGetOverlapLayerBoxList(cv Inst2 M1Layer ODLayer)
        a=caaar(Inst1)
        b=caaar(Inst2)
            unless(a
                error("crConnectDrainSorce error")
            )
        if(a>b then
            x=Inst1
            Inst1=Inst2
            Inst2=x
        )
        Drain=cadr(Inst1)
        Sorce=car(Inst2)
        dbCreateRect(cv M1Layer list(leftEdge(Drain):bottomEdge(Drain) rightEdge(Sorce):topEdge(Drain)))
        dbCreateRect(cv ODLayer list(leftEdge(Drain):bottomEdge(Drain)-0.04 rightEdge(Sorce):topEdge(Drain)+0.04))
    )
)


procedure(crCreatePMOSGateToMetal(cv PInst layer)
    let((PInstOverlap TopY LeftX RightX BottomY X_CO Y_CO tmp PMOSGateY)
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
                then tmp = COw +0.2 - (RightX-LeftX)   ;代表Ploy需要的宽度
                RightX = RightX +tmp/2
                LeftX = LeftX - tmp/2
                )
        BottomY=TopY-CORows*COw-(CORows-1)*COs-0.2-0.2
        BottomY=crSnapUpToGrid(BottomY mfgGrid)
        dbCreateRect(cv POLayer list(LeftX:BottomY RightX:TopY))
        dbCreateRect(cv M1Layer list(LeftX:BottomY RightX:TopY-0.2))
        
        X_CO=(LeftX+RightX)/2-COw/2
        
        for( i 0 CORows-1
            Y_CO=BottomY+POEncCO+i*(COw+COs)
            dbCreateRect(cv COLayer list(X_CO:Y_CO X_CO+COw:Y_CO+COw))       
        )
        PMOSGateY = BottomY
        
        cond(
            (layer == M1Layer
               nil
            )
            (layer == M2Layer
               dbCreateRect(cv M2Layer list(LeftX:BottomY RightX:TopY-0.2))
               dbCreateViaShapeArray(cv "VIA12" nil LeftX+0.1 BottomY+0.1 V12p V12p V12w V12w 1 1)
            )
            (layer == M3Layer
               dbCreateRect(cv M2Layer list(LeftX:BottomY RightX:TopY-0.2))
               dbCreateViaShapeArray(cv "VIA12" nil LeftX+0.1 BottomY+0.1 V12p V12p V12w V12w 1 1)
               dbCreateRect(cv M3Layer list(LeftX:BottomY RightX:TopY-0.2))
               dbCreateViaShapeArray(cv "VIA23" nil LeftX+0.1 BottomY+0.1 V23p V23p V23w V23w 1 1)
            )
        ); End of cond
    ); End of let
)



procedure(crCreateNMOSGateToMetal(cv NInst layer)
    let((NInstOverlap TopY LeftX RightX BottomY X_CO Y_CO tmp NMOSGateY) 
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
        TopY=BottomY+CORows*COw+(CORows-1)*COs+0.2+0.2
        TopY=crSnapUpToGrid(TopY mfgGrid)
        dbCreateRect(cv POLayer list(LeftX:BottomY RightX:TopY))
        dbCreateRect(cv M1Layer list(LeftX:BottomY+0.2 RightX:TopY))
        
        X_CO=(LeftX+RightX)/2-COw/2
        
        for( i 0 CORows-1
            Y_CO=TopY-POEncCO-i*(COw+COs)-COw
            dbCreateRect(cv COLayer list(X_CO:Y_CO X_CO+COw:Y_CO+COw))       
        )
        NMOSGateY = TopY
        cond(
            (layer == M1Layer
                nil)
            (layer == M2Layer
                dbCreateRect(cv M2Layer list(LeftX:BottomY+0.2 RightX:TopY))
                dbCreateViaShapeArray(cv "VIA12" nil LeftX+0.1  TopY-0.1-V12w  V12p V12p V12w V12w 1 1))
            (layer == M3Layer
                dbCreateRect(cv M2Layer list(LeftX:BottomY+0.2 RightX:TopY))
                dbCreateViaShapeArray(cv "VIA12" nil LeftX+0.1  TopY-0.1-V12w  V12p V12p V12w V12w 1 1)
                dbCreateRect(cv M3Layer list(LeftX:BottomY+0.2 RightX:TopY))
                dbCreateViaShapeArray(cv "VIA23" nil LeftX+0.1  TopY-0.1-V23w  V23p V23p V23w V23w 1 1))
        )
        
        
        
    )
)

procedure(crConnectPolyDirectly(NInst PInst layer)
    let((PInstOverlap NInstOverlap x1  y1 y2)
        PInstOverlap = crGetOverlapLayerBoxList(cv PInst POLayer ODLayer)
        NInstOverlap = crGetOverlapLayerBoxList(cv NInst POLayer ODLayer)
        PInstOverlap = car(PInstOverlap)
        NInstOverlap = car(NInstOverlap)
            unless(topEdge(NInstOverlap)
             error("crConnectPolyDirectly calculate error")
            )
        x1=(leftEdge(NInstOverlap)+rightEdge(NInstOverlap))/2
        y1=topEdge(NInstOverlap)+0.2
        y2=bottomEdge(PInstOverlap)-0.2
        dbCreatePath(cv layer list(x1:y1 x1:y2) pathW)
    )
)

procedure(crConnectDrainDirectly(NInst PInst)
    let((PInstOverlap NInstOverlap x1 x2 y1 y2)
        PInstOverlap = crGetOverlapLayerBoxList(cv PInst ODLayer M1Layer)
        NInstOverlap = crGetOverlapLayerBoxList(cv NInst ODLayer M1Layer)
        PInstOverlap = cadr(PInstOverlap)
        NInstOverlap = cadr(NInstOverlap)
            unless(topEdge(NInstOverlap)
             error("crConnectPolyDirectly calculate error")
            )
        x1=leftEdge(NInstOverlap)+SD_DRCspace/2
        if(x1> rightEdge(NInstOverlap) then
           x1=rightEdge(NInstOverlap)
        )
        y1=bottomEdge(NInstOverlap)
        x2=rightEdge(NInstOverlap)+SD_DRCspace/2
        y2=topEdge(PInstOverlap)
        dbCreateRect(cv M1Layer list(x1:y1 x2:y2))
    )
)


procedure(crConnectSourceToVDD(PInst)
     let((y1 y2 MidX PInstOverlap PbBox)
         PInstOverlap=crGetOverlapLayerBoxList(cv PInst M1Layer ODLayer)
         PbBox=car(PInstOverlap)
            unless(caar(PbBox)
             error("crConnectSourceToVDD calculate error")
            )
         MidX = (caar(PbBox) + caadr(PbBox))/2
         y1=cadar(PbBox)
         y2=VDDy1
         dbCreatePath(cv M1Layer list(MidX:y1 MidX:y2) pathW) ;连接VDD线
     )
)

procedure(crConnectSourceToVSS(NInst)
     let((y1 y2 MidX NInstOverlap NbBox)
         NInstOverlap=crGetOverlapLayerBoxList(cv NInst M1Layer ODLayer)
         NbBox= car(NInstOverlap)
             unless(caar(NbBox)
             error("crConnectSourceToVSS calculate error")
            )
         MidX = (caar(NbBox) + caadr(NbBox))/2
         y1=cadar(NbBox)
         y2=VSSy1
         dbCreatePath(cv M1Layer list(MidX:y1 MidX:y2) pathW) ;连接VSS线
     )
)

procedure(crConnectPloyToSignal(Inst signal_y net Layer)
    let(( x y1 y2 maxY minY)
        bBox= crGetOverlapLayerBoxList(cv Inst POLayer ODLayer)
        bBox= car(bBox)
             unless(leftEdge(bBox)
             error("crConnectPloyToSignal calculate error")
             )
        x=(leftEdge(bBox)+rightEdge(bBox))/2
        y1=bottomEdge(bBox)
        y2=topEdge(bBox)
        maxY=max(y1 y2 signal_y-V12w/2-0.1 signal_y+V12w/2+0.1)
        minY=min(y1 y2 signal_y-V12w/2-0.1 signal_y+V12w/2+0.1)         ;需满足M1 Enc V12
        dbCreatePath(cv Layer list(x:minY x:maxY) pathW)       ;需满足M1 Enc V12
        if( y1>signal_y                                                              ;如果是PMOS
          then progn(dbCreatePath(cv POLayer list(x:y1 x:y1-0.6) pl_var*1e6)
          ;   dbCreateRect(cv "CONT" list(x-0.11:y1-0.6+0.33 x+0.11:y1-0.6+0.11 ))   ;重复打孔了
                    )
          else progn(dbCreatePath(cv POLayer list(x:y2 x:y2+0.6) nl_var*1e6)       ;如果是nMOS
          ;   dbCreateRect(cv "CONT" list(x-0.11:y2+0.6-0.33 x+0.11:y2+0.6-0.11 ))   ;重复打孔了
                  )
          )
    )
)    ;连接signal线和ploy



procedure(LogicPcellCdf(libName cellName)
  let((cellId cdfId)
    unless(cellId = ddGetObj(libName cellName)
      error("Could not get cell %s." cellName)
    )
    when(cdfId = cdfGetBaseCellCDF(cellId)
      cdfDeleteCDF(cdfId)
    )
    cdfId = cdfCreateBaseCellCDF(cellId)
    cdfCreateParam(cdfId
      ?name    "pw"
      ?prompt  "PMOS Width"
      ?type    "string"
      ?defValue "2.0u"
      ?callback "CheckPNSpace()"
    )
    
    cdfCreateParam(cdfId
      ?name    "nw"
      ?prompt  "NMOS Width"
      ?type    "string"
      ?defValue "2.0u"
      ?callback "CheckPNSpace()"
    )
    
    cdfCreateParam(cdfId
      ?name    "l"
      ?prompt  "MOS Gate Length"
      ?type    "string"
      ?defValue "0.18u"
    )
    

    cdfCreateParam(cdfId
      ?name    "PNSpace"
      ?prompt  "PN Space"
      ?type    "string"
      ?defValue "6.0u"
      ?callback "CheckPNSpace()"
    )
    
    cdfCreateParam(cdfId
      ?name    "PNSpace"
      ?prompt  "PN Space"
      ?type    "string"
      ?defValue "3.0u"
      ?callback "CheckPNSpace()"
    )
    
    cdfCreateParam(cdfId
      ?name    "PathW"
      ?prompt  "PathWidth(um)"
      ?type    "float"
      ?defValue 0.27
      ?callback "CheckPathW()"
    )
    
    cdfSaveCDF(cdfId)
  )
)


procedure(CheckPNSpace()
    let((tf cv pwValue nwValue pwUm nwUm COw COs COp M1EncCO GateCORows gateContactHeight
       minPNSpaceUm pnSpaceValue pnSpaceUm newPNSpaceUm newPNSpaceString fieldId)
            unless(boundp('cdfgData) && cdfgData
               warn("PNSpace callback: cdfgData is not available.\n")
               return()
            )
            cv = nil
    when(isCallable('artGetCdfTargetCV)
      cv = artGetCdfTargetCV()
    )
    unless(cv
      cv = geGetEditCellView()
    )
    tf = if(cv then techGetTechFile(cv) else nil)
    pwValue = cdfParseFloatString(cdfgData~>pw~>value)
    nwValue = cdfParseFloatString(cdfgData~>nw~>value)
    PathW   = cdfParseFloatString(cdfgData~>PathW~>value)
    pnSpaceValue = cdfParseFloatString(cdfgData~>PNSpace~>value)
    unless(pwValue && nwValue && pnSpaceValue
      warn("PNSpace callback: invalid pw, nw, or PNSpace value.\n")
      return()
    )
    pwUm = pwValue * 1e6
    nwUm = nwValue * 1e6
    if(tf then
      COw = techGetSpacingRule(tf "minWidth" "CONT")
      COs = techGetSpacingRule(tf "minSpacing" "CONT")
      M1EncCO = techGetSpacingRule(tf "minEnclosure" "METAL1" "CONT")
      GateCORows = 2
      COp = COw + COs
      M3Space = techGetSpacingRule(tf "minSpacing" "METAL3")
      gateContactHeight = 2.0 * M1EncCO + COw * GateCORows + (COp - COw) * (GateCORows - 1)
      minPNSpaceUm =  nwUm + gateContactHeight * 2+M3Space + PathW*4.0
    else
      minPNSpaceUm =nwUm + 3.0
      warn("PNSpace callback: cannot get techFile. Use fallback min=%gu.\n" minPNSpaceUm)
    )
    
    pnSpaceUm = pnSpaceValue * 1e6
        newPNSpaceUm = max(pnSpaceUm minPNSpaceUm)
    when(abs(newPNSpaceUm - pnSpaceUm) > 1e-12
      newPNSpaceString = sprintf(nil "%gu" newPNSpaceUm)
      cdfgData~>PNSpace~>value = newPNSpaceString
      when(boundp('cdfgForm) && cdfgForm
        fieldId = get(cdfgForm 'PNSpace)
        when(fieldId
          fieldId~>value = newPNSpaceString
        )
      )
      warn("PNSpace=%g is smaller than dynamic min=%g. Reset to %s.\n"
           pnSpaceUm minPNSpaceUm newPNSpaceString)
    )
    printf("INFO: PNSpace final=%g min=%g\n" newPNSpaceUm minPNSpaceUm)

    )
)

procedure(CheckPathW()
  let((tf cv PathW minPathW newPathW fieldId)
            unless(boundp('cdfgData) && cdfgData
               warn("PNSpace callback: cdfgData is not available.\n")
               return()
            )
            cv = nil
    when(isCallable('artGetCdfTargetCV)
      cv = artGetCdfTargetCV()
    )
    unless(cv
      cv = geGetEditCellView()
    )
    tf = if(cv then techGetTechFile(cv) else nil)
    PathW = cdfParseFloatString(cdfgData~>PathW~>value)
    minPathW=PathW+V12w+2*M1EncV1
    newPathW=max(minPathW PathW)
    when(abs(newPathW-PathW)>1e-12
        cdfgData~>PathW~>value = newPathW
        when(boundp('cdfgForm) && cdfgForm
            fieldId = get(cdfgForm 'PathW)
            fieldId~>value = newPathW
        )
    warn("PathW=%g is smaller than dynamic min=%g. Reset to %s.\n"
           PathW minPathW newPathW)
    )
  )
)




pcDefinePCell(list(ddGetObj("zsytest") "DFF" "layout")
        (
        (l "0.18u")                               ; 沟道长度
        (pw "2.0u")                                ; 沟道宽度                  
        (nw "2.0u")                           
        (PNSpace "6.0u")                  ;PMOS NMOS间距
        (PathW float 0.27)
        )
    cv=pcCellView 
    pw_var=cdfParseFloatString(pw)
    nw_var=cdfParseFloatString(nw)
    pl_var=cdfParseFloatString(l)
    nl_var=cdfParseFloatString(l)
    PNSpace_var=cdfParseFloatString(PNSpace)
      ;PathW=0.15 ;互联线宽度
      ;pathW=V12w+2*M1EncV1
    tf=techGetTechFile(cv)
    POLayer    = list("POLY1"  "drawing")  ; 多晶硅层
    ODLayer    = list("DIFF"   "drawing")  ; 有源区（扩散层）
    COLayer=list("CONT" "drawing")
    M1EncCO     = techGetSpacingRule(tf "minEnclosure" "METAL1" "CONT")  ; M1 包覆 CONT
    M1EncV1=techGetSpacingRule(tf "minEnclosure" "METAL1" "VIA12")
    M2EncV2=techGetSpacingRule(tf "minEnclosure" "METAL2" "VIA23")
    M1PinLayer = list("METAL1" "pin")
    M2PinLayer = list("METAL2" "pin")
    M3PinLayer = list("METAL3" "pin")
    M1Layer    = list("METAL1" "drawing")
    M2Layer    = list("METAL2" "drawing")
    M3Layer    = list("METAL3" "drawing")
    V12w       = techGetSpacingRule(tf "minWidth" "VIA12")        ; VIA12 最小宽度
    V12s       = techGetSpacingRule(tf "minSpacing" "VIA12")      ; VIA12 最小间距
    V12p       = V12w+V12s                                        ; VIA12 节距
    V23w       = techGetSpacingRule(tf "minWidth" "VIA23")        ; VIA23 最小宽度
    V23s       = techGetSpacingRule(tf "minSpacing" "VIA23")      ; VIA23 最小间距
    V23p       = V23w+V23s
    PPNPEncOD  = techGetSpacingRule(tf "minEnclosure" "PIMP" "DIFF")
    POEncCO    = techGetSpacingRule(tf "minEnclosure" "POLY1" "CONT")
    COw=techGetSpacingRule(tf "minWidth" "CONT")
    COs=techGetSpacingRule(tf "minSpacing" "CONT")
    CORows = 2
    mfgGrid=techGetMfgGridResolution(tf)


    Instspace1=1.32   ;NIMP相连
    SD_DRCspace=0.54   ; 0.46为了满足M1.S<0.23，0.47为了满足CO.S<0.25,0.54为了满足Min. M2.S<0.28
    Instspace2=0.54+SD_DRCspace   ;SD公用，但要满足M1.S>0.23
    X_N1=0.0
    X_N2=X_N1+Instspace1+nl_var*1e6
    X_N3=X_N2+Instspace2+nl_var*1e6
    X_N4=X_N3+Instspace1+nl_var*1e6
    X_N5=X_N4+Instspace2+nl_var*1e6
    X_N6=X_N5+Instspace1+nl_var*1e6
    X_N7=X_N6+Instspace1+nl_var*1e6
    X_N8=X_N7+Instspace2+nl_var*1e6
    X_N9=X_N8+Instspace1+nl_var*1e6
    X_N10=X_N9+Instspace2+nl_var*1e6
    X_N11=X_N10+Instspace1+nl_var*1e6
    Xcoor=list(X_N1 X_N2 X_N3 X_N4 X_N5 X_N6 X_N7 X_N8 X_N9 X_N10 X_N11)
    YPInst=atof(aelSuffixNotation(nw_var+PNSpace_var))
    NInst_list = list()
    PInst_list = list()                                    ;计算所有MOS坐标
    
    for(i 1 11
    		InstName=sprintf(nil "NInst%d" i)
    		currentX = nth(i-1 Xcoor)
        InstName=dbCreateParamInstByMasterName(cv "tsmc18" "nmos2v" "layout" InstName list(currentX 0) "R0" 1
                                          list(    list("w"  "string" sprintf(str,"%g",nw_var))                 
                                                   list("l"  "string" sprintf(str,"%g",nl_var))
                                              )
                                          )
        NInst_list =append1(NInst_list InstName)
        InstName=sprintf(nil "PInst%d" i)
        InstName=dbCreateParamInstByMasterName(cv "tsmc18" "pmos2v" "layout" InstName list(currentX YPInst) "R0" 1
                                          list(  list("w"  "string" sprintf(str,"%g",pw_var))                 
                                                 list("l"  "string" sprintf(str,"%g",pl_var))
                                                 )
                                          )
        PInst_list =append1(PInst_list InstName)
    )
    
    crConnectDrainSorce(cv nth(1 NInst_list) nth(2 NInst_list))
    crConnectDrainSorce(cv nth(3 NInst_list) nth(4 NInst_list))
    crConnectDrainSorce(cv nth(6 NInst_list) nth(7 NInst_list))
    crConnectDrainSorce(cv nth(8 NInst_list) nth(9 NInst_list))
    crConnectDrainSorce(cv nth(1 PInst_list) nth(2 PInst_list))
    crConnectDrainSorce(cv nth(3 PInst_list) nth(4 PInst_list))
    crConnectDrainSorce(cv nth(6 PInst_list) nth(7 PInst_list))
    crConnectDrainSorce(cv nth(8 PInst_list) nth(9 PInst_list))
    
    VSSy1=bottomEdge(nth(0 NInst_list))-0.7
    VDDy1=topEdge(nth(0 PInst_list))+0.7
    InstLeftX=leftEdge(nth(0 NInst_list))
    InstRightX=rightEdge(nth(10 NInst_list))
    VSSpath = rodCreatePath(
           ?cvId cv
           ?layer "METAL1"
           ?pts list(InstLeftX:VSSy1  InstRightX:VSSy1)
           ?width 0.5
           ?pin t
           ?pinAccessDir list("top" "bottom" "left" "right")
           ?termName "TermVSS"
           ?subRect  list( list(
               ?layer M1PinLayer
               ?width 0.22
               ?length 0.22
               ?gap "distribute"           
               ?beginOffset -0.6
               ?endOffset -0.7
               ?space    0.66   )
                          list(
               ?layer "CONT"
               ?width 0.22
               ?length 0.22
               ?gap "distribute"           
               ?beginOffset -0.15
               ?endOffset -0.25
               ?space    0.66   )
           );End ofsubRectArray
    )  ;
    dbCreateLabel(cv M1PinLayer InstLeftX:VSSy1 "VSS" "centerLeft" "R0" "roman" 0.3 );  VSS Label
    VSSDiff = rodCreateRect(           
           ?cvId  cv
           ?layer "DIFF"
           ?fromObj VSSpath
           ?size 0
           )
    VSSRing = rodCreateRect(
           ?cvId  cv
           ?layer "PIMP"
           ?fromObj VSSpath
           ?size PPNPEncOD)     ;VSS保护环
    VDDpath = rodCreatePath(
           ?cvId cv
           ?layer "METAL1"
           ?pts list(InstLeftX:VDDy1  InstRightX:VDDy1)
           ?width 0.5
           ?pin t
           ?pinAccessDir list("top" "bottom" "left" "right")
           ?termName "TermVDD"
           ?subRect  list( list(
               ?layer M1PinLayer
               ?width 0.22
               ?length 0.22
               ?gap "distribute"           
               ?beginOffset -0.6
               ?endOffset -0.7
               ?space    0.66   )
                          list(
               ?layer "CONT"
               ?width 0.22
               ?length 0.22
               ?gap "distribute"           
               ?beginOffset -0.15
               ?endOffset -0.25
               ?space    0.66   )
           );
    )  ;
    dbCreateLabel(cv M1PinLayer InstLeftX:VDDy1 "VDD" "centerLeft" "R0" "roman" 0.3 );  VDD Label
    VDDRing = rodCreateRect(
           ?cvId  cv
           ?layer "NIMP"
           ?fromObj VDDpath
           ?size PPNPEncOD)     ;VDD保护环
    VDDDiff = rodCreateRect(
           ?cvId  cv
           ?layer "DIFF"
           ?fromObj VDDpath
           ?size 0)
    VDDNWELL = rodCreateRect(
           ?cvId  cv
           ?layer "NWELL"
           ?fromObj VDDRing
           ?size 0.3)     ;VDD的NWELL

    for(i 0 10 ; 因为列表有11个元素，索引是0到10
        NInst = nth(i NInst_list) ; 取第i个元素
        PInst = nth(i PInst_list) 
        if( (i == 2)  || (i == 7) || (i == 9)  then; 是第3、5、8、10个
            crCreateNMOSGateToMetal(cv NInst M3Layer)
            crCreatePMOSGateToMetal(cv PInst M3Layer)
        else
            crCreateNMOSGateToMetal(cv NInst M2Layer)
            crCreatePMOSGateToMetal(cv PInst M2Layer)
        );创建poly的孔
        if((i==0)||(i==1)||(i==3)||(i==5)||(i==6)||(i==8)||(i==10)  then  ; 是第1、2、4、6、7、9、11个
            crConnectPolyDirectly(NInst PInst M2Layer)  
            crConnectSourceToVDD(PInst)
            crConnectSourceToVSS(NInst)
        );两个的ploy直接用M2的连接线，并且这些MOS源极连电源or地
        if((i==0)||(i==1)||(i==2)||(i==5)||(i==6)||(i==7)||(i==10) then ; 是第1、2、3、6、7、8、11个
            crConnectDrainDirectly(NInst PInst)
        );链接PNMOS的Drain
    );
    
    y2=topEdge(nth(0 NInst_list))+PNSpace_var*1e6*2/8
    y3=topEdge(nth(0 NInst_list))+PNSpace_var*1e6*3/8
    y4=topEdge(nth(0 NInst_list))+PNSpace_var*1e6*4/8
    y5=topEdge(nth(0 NInst_list))+PNSpace_var*1e6*5/8
    
    NInstOverlap = crGetOverlapLayerBoxList(cv nth(0 NInst_list) POLayer ODLayer)
    NInstOverlap = car(NInstOverlap)
            unless(leftEdge(NInstOverlap)
                error("calc for x_clk error")
            )
    x_clk=(leftEdge(NInstOverlap)+rightEdge(NInstOverlap))/2
    netclk = dbCreateNet(cv "clk")

    clkpinfig=dbCreateRect(cv M2PinLayer list(x_clk-0.12:y3-0.12 x_clk+0.12:y3+0.12))
    dbCreateLabel(cv M2PinLayer x_clk:y3 "CLK" "centerCenter" "R0" "roman" 0.2 )
    clkpin=dbCreatePin(netclk clkpinfig "clk") 
    clkpin~>AccessDir=list("top" "bottom" "left" "right")
    dbCreateViaShapeArray(cv "VIA23" netclk x_clk-V23w/2 y5-V23w/2 V23p V23p V23w V23w 1 1) ;创建CLKpin和via
    dbCreateRect(cv M2Layer list(x_clk-V23w/2-0.06:y5-V23w/2-0.06 x_clk+V23w/2+0.06:y5+V23w/2+0.06))
    dbCreateRect(cv M3Layer list(x_clk-V23w/2-0.06:y5-V23w/2-0.06 x_clk+V23w/2+0.06:y5+V23w/2+0.06))
    
    NInstOverlap = crGetOverlapLayerBoxList(cv nth(0 NInst_list) M1Layer ODLayer)
    NInstOverlap = cadr(NInstOverlap)
            unless(leftEdge(NInstOverlap)
                error("calc for x_clki error")
            )
    x_clki=(leftEdge(NInstOverlap)+rightEdge(NInstOverlap))/2+SD_DRCspace/2
    netclki = dbCreateNet(cv "clki")
    dbCreateRect(cv M3Layer list(x_clki-V12w/2-0.06:y2-V12w/2-0.06 x_clki+V12w/2+0.06:y2+V12w/2+0.06))
    dbCreateRect(cv M2Layer list(x_clki-V12w/2-0.06:y2-V12w/2-0.19 x_clki+V12w/2+0.19:y2+V12w/2+0.13))  ;需满足M2.A<0.202
    dbCreateRect(cv M1Layer list(x_clki-V12w/2-0.06:y2-V12w/2-0.06 x_clki+V12w/2+0.06:y2+V12w/2+0.06))
    dbCreateViaShapeArray(cv "VIA12" netclki x_clki-V12w/2 y2-V12w/2 V12p V12p V12w V12w 1 1) ;创建CLKipin和via
    dbCreateViaShapeArray(cv "VIA23" netclki x_clki-V23w/2 y2-V23w/2 V23p V23p V23w V23w 1 1) ;创建CLKipin和via
    dbCreateLabel(cv M3Layer x_clki:y2 "CLKi" "centerCenter" "R0" "roman" 0.2 )
    x_end=rightEdge(nth(9 NInst_list)) ;最后用到clk信号线的是第10个mos
    yclk=y5
    yclki=y2
    dbCreatePath(cv M3Layer list(x_clk-0.14:yclk x_end:yclk) pathW)
    dbCreatePath(cv M3Layer list(x_clki-0.14:yclki x_end:yclki) pathW) ;clk(y5) clki(y2)信号线
    
    NInstOverlap = crGetOverlapLayerBoxList(cv nth(1 NInst_list) POLayer ODLayer)
    NInstOverlap = car(NInstOverlap)
            unless(leftEdge(NInstOverlap)
                error("calc for x_D error")
            )
    x_D=(leftEdge(NInstOverlap)+rightEdge(NInstOverlap))/2
    netD = dbCreateNet(cv "D")
    Dpinfig=dbCreateRect(cv M2PinLayer list(x_D-0.12:y3-0.12 x_D+0.12:y3+0.12))
    dbCreateLabel(cv M2PinLayer x_D:y3 "D" "centerCenter" "R0" "roman" 0.2 )
    Dpin=dbCreatePin(netD Dpinfig "D")
    Dpin~>AccessDir=list("top" "bottom" "left" "right") ;创建Dpin
    
    crConnectPloyToSignal(nth(2 PInst_list) yclk netclk M3Layer)
    crConnectPloyToSignal(nth(9 PInst_list) yclk netclk M3Layer)
    crConnectPloyToSignal(nth(2 NInst_list) yclki netclki M3Layer)
    crConnectPloyToSignal(nth(9 NInst_list) yclki netclki M3Layer) ;第3、10个PNMOS连接到clk、clki
    
    NInstOverlap = crGetOverlapLayerBoxList(cv nth(4 NInst_list) POLayer ODLayer)
    NInstOverlap = car(NInstOverlap)
            unless(leftEdge(NInstOverlap)
                error("calc for connectNMOS5 error")
            )
    MidX5=(leftEdge(NInstOverlap)+rightEdge(NInstOverlap))/2
    dbCreatePath(cv M2Layer list(MidX5:topEdge(nth(4 NInst_list))  MidX5:yclk-0.7  MidX5+0.1:yclk-0.7 MidX5+0.1:yclk+0.18 ) pathW)  ;因附近有M2线，故这条线需要拐弯
    dbCreateRect(cv M2Layer list(MidX5+0.1-V23w/2-0.06:yclk-V23w/2-0.06 MidX5+0.1+V23w/2+0.06:yclk+V23w/2+0.06) )   
    dbCreateViaShapeArray(cv "VIA23" nil MidX5+0.1-V23w/2 yclk-V23w/2 V23p V23p V23w V23w 1 1)  ;NMOS5链接CLK  ,MidX5+0.1为连接点横坐标
    tempy=bottomEdge(nth(4 PInst_list))
    dbCreatePath(cv M2Layer list(MidX5:tempy MidX5:tempy-0.4 MidX5+0.8:tempy-0.4 MidX5+0.8:yclki-0.12-0.06) pathW)
    dbCreateRect(cv M2Layer list(MidX5+0.8-V23w/2-0.06:yclki-V23w/2-0.06 MidX5+0.8+V23w/2+0.06:yclki+V23w/2+0.06) );MidX5+0.8是Via中心坐标，为一个整体
    dbCreateViaShapeArray(cv "VIA23" nil MidX5+0.8-V23w/2 yclki-V23w/2 V23p V23p V23w V23w 1 1)    ;PMOS5链接CLKi
    
    NInstOverlap = crGetOverlapLayerBoxList(cv nth(7 NInst_list) POLayer ODLayer)
    NInstOverlap = car(NInstOverlap)
            unless(leftEdge(NInstOverlap)
                error("calc for connectNMOS8 error")
            )
    MidX8=(leftEdge(NInstOverlap)+rightEdge(NInstOverlap))/2
    dbCreatePath(cv M2Layer list(MidX8:topEdge(nth(7 NInst_list)) MidX8:yclk+0.12+0.06) pathW)
    dbCreateRect(cv M2Layer list(MidX8-V23w/2-0.06:yclk-V23w/2-0.06 MidX8+V23w/2+0.06:yclk+V23w/2+0.06) )
    dbCreateViaShapeArray(cv "VIA23" nil MidX8-V23w/2 yclk-V23w/2 V23p V23p V23w V23w 1 1) ;NMOS8链接CLK
    tempy=bottomEdge(nth(7 PInst_list))
    dbCreatePath(cv M2Layer list(MidX8:tempy MidX8:tempy-0.4 MidX8+0.8:tempy-0.4 MidX8+0.8:yclki-0.12-0.06) pathW)
    dbCreateRect(cv M2Layer list(MidX8+0.8-V23w/2-0.06:yclki-V23w/2-0.06 MidX8+0.8+V23w/2+0.06:yclki+V23w/2+0.06) );MidX5+0.8是Via中心坐标，为一个整体
    dbCreateViaShapeArray(cv "VIA23" nil MidX8+0.8-V23w/2 yclki-V23w/2 V23p V23p V23w V23w 1 1)    ;PMOS8链接CLKi
    
    foreach(idx list(3 8)   ;connect PNMOS4/9 Drain
        let((nBox pBox x yN yP yJN yJP)
            nBox = crGetOverlapLayerBoxList(cv nth(idx NInst_list) ODLayer M1Layer)
            nBox = cadr(nBox)
            unless(leftEdge(nBox) 
                error("calc for connectNMOS%dDrain error" idx+1)
            )
            pBox = crGetOverlapLayerBoxList(cv nth(idx PInst_list) ODLayer M1Layer)
            pBox = cadr(pBox)
            unless(leftEdge(pBox) 
                error("calc for connectPMOS%dDrain error" idx+1))
            x   = (leftEdge(nBox)+rightEdge(nBox))/2+SD_DRCspace/2
            yN  = topEdge(nBox)          ; NMOS 侧 M1 短桩起点（向上）
            yP  = bottomEdge(pBox)       ; PMOS 侧 M1 短桩起点（向下）
            yJN = yN + 1.7               ; M2 与 NMOS 侧 M1 的搭接点
            yJP = yP - 1.7               ; M2 与 PMOS 侧 M1 的搭接点
            dbCreatePath(cv M1Layer list(x:yN x:yJN) pathW)
            dbCreatePath(cv M1Layer list(x:yP x:yJP) pathW)
            dbCreatePath(cv M2Layer list(x:yJN x:yJP) pathW)
            dbCreateRect(cv M1Layer list(x-V12w/2-0.06:yJN-V12w/2-0.06 x+V12w/2+0.06:yJN+V12w/2+0.06))
            dbCreateRect(cv M2Layer list(x-V12w/2-0.06:yJN-V12w/2-0.06 x+V12w/2+0.06:yJN+V12w/2+0.06))
            dbCreateRect(cv M1Layer list(x-V12w/2-0.06:yJP-V12w/2-0.06 x+V12w/2+0.06:yJP+V12w/2+0.06))
            dbCreateRect(cv M2Layer list(x-V12w/2-0.06:yJP-V12w/2-0.06 x+V12w/2+0.06:yJP+V12w/2+0.06))
            dbCreateViaShapeArray(cv "VIA12" nil x-V12w/2 yJN-V12w/2 V12p V12p V12w V12w 1 1)
            dbCreateViaShapeArray(cv "VIA12" nil x-V12w/2 yJP-V12w/2 V12p V12p V12w V12w 1 1)
        )
    )
    
    
    
    foreach(idx list(list(2 5) list(7 10))   ;MOS3 drain connect to MOS6 Poly, MOS8 drain connect to MOS11 Poly
        let((b1 b2 xD xG)
            
            b1 = crGetOverlapLayerBoxList(cv nth(car(idx) NInst_list) ODLayer M1Layer) ; --- drain 端：POLY∩M1 取第 2 个 box ---
            b1 = cadr(b1)
                unless(leftEdge(b1)
                    error("MOS3 drain connect to MOS6 PLOY error")
                )
            xD = (leftEdge(b1)+rightEdge(b1))/2 +SD_DRCspace/2  ;  例MOS3 drain横坐标
            b2 = crGetOverlapLayerBoxList(cv nth(cadr(idx) NInst_list) POLayer ODLayer) ; --- 栅极端：POLY∩DIFF 取第 1 个 box ---
            b2 = car(b2)  
            xG = (leftEdge(b2)+rightEdge(b2))/2   ;  例MOS6 Poly横坐标
            dbCreatePath(cv M1Layer list(xD-0.12:y4 xG+0.12:y4) pathW)
            dbCreateViaShapeArray(cv "VIA12" nil xG-V12w/2  y4-V12w/2  V12p V12p V12w V12w 1 1)
            dbCreateRect(cv M1Layer list(xG-V12w/2-0.06:y4-V12w/2-0.06 xG+V12w/2+0.06:y4+V12w/2+0.06))
        )
    )
    
    foreach(idx list(list(3 5) list(8 10))   ;mos4 poly connect to mos6 drain, mos9 poly connect to mos11 drain
      let((nBox1 nBox2 x1 x2)
        nBox1=crGetOverlapLayerBoxList(cv nth(car(idx) NInst_list) POLayer ODLayer) ;mos4poly
        nBox1=car(nBox1)
                unless(leftEdge(nBox1)
                    error("mos4 poly connect to mos6 drain PLOY error")
                )
        x1= (leftEdge(nBox1)+rightEdge(nBox1))/2
        nBox2=crGetOverlapLayerBoxList(cv nth(cadr(idx) NInst_list) M1Layer ODLayer) ;提取mos6drain
        nBox2=cadr(nBox2)
        x2= (leftEdge(nBox2)+rightEdge(nBox2))/2+SD_DRCspace/2                         ;mos6drain 横坐标
        dbCreatePath(cv M1Layer list(x1-V12w/2-M1EncV1:y3 x2+0.12:y3) pathW)
        dbCreateViaShapeArray(cv "VIA12" nil x1-V12w/2  y3-V12w/2  V12p V12p V12w V12w 1 1)
        dbCreateRect(cv M1Layer list(x1-V12w/2-0.06:y3-V12w/2-0.06 x1+V12w/2+0.06:y3+V12w/2+0.06))
      )
    )
    
    foreach(idx list(list(4 5) list(9 10))  ;mos5 drain connect to mos6 poly, mos10 drain connect to mos11 poly
      let((nBox1 pBox1 x1 yn yp nBox2 x2)
        nBox1=crGetOverlapLayerBoxList(cv nth(car(idx) NInst_list) ODLayer M1Layer)
        nBox1=cadr(nBox1)
                unless(leftEdge(nBox1)
                    error("mos5 drain connect to mos6 poly error")
                )
        x1=(leftEdge(nBox1)+rightEdge(nBox1))/2
        yn=topEdge(nBox1)
        pBox1=crGetOverlapLayerBoxList(cv nth(car(idx) PInst_list) ODLayer M1Layer)  ;drain
        pBox1=cadr(pBox1)
        yp=bottomEdge(pBox1)
        nBox2=crGetOverlapLayerBoxList(cv nth(cadr(idx) NInst_list) POLayer ODLayer)  ;ploy
        nBox2=car(nBox2)
        x2=(leftEdge(nBox2)+rightEdge(nBox2))/2
        dbCreatePath(cv M1Layer list(x1:yn-0.14 x1+SD_DRCspace/2:yn-0.14 x1+SD_DRCspace/2:yn+0.8 x2+0.22:yn+0.8) pathW )
        dbCreatePath(cv M1Layer list(x1:yp+0.14 x1+SD_DRCspace/2:yp+0.14 x1+SD_DRCspace/2:yp-0.8 x2+0.22:yp-0.8) pathW )
 ;       dbCreateViaShapeArray(cv "VIA12" nil x2-V12w/2  yn+0.8-V12w/2  V12p V12p V12w V12w 1 1) ;已经有孔，重复打孔了
 ;       dbCreateViaShapeArray(cv "VIA12" nil x2-V12w/2  yp-0.8-V12w/2  V12p V12p V12w V12w 1 1)
      )
    )
    
    NInstOverlap = crGetOverlapLayerBoxList(cv nth(5 NInst_list) M1Layer ODLayer)
    NInstOverlap = cadr(NInstOverlap)
                unless(leftEdge(NInstOverlap)
                    error("MOS6drain connect to mos7poly")
                )
    x1=(leftEdge(NInstOverlap)+rightEdge(NInstOverlap))/2+SD_DRCspace/2
    NInstOverlap = crGetOverlapLayerBoxList(cv nth(6 NInst_list) POLayer ODLayer)
    NInstOverlap = car(NInstOverlap)
    x2=(leftEdge(NInstOverlap)+rightEdge(NInstOverlap))/2
    dbCreatePath(cv M1Layer list(x1:y4 x2+V12w/2+M1EncV1:y4) pathW)
    dbCreateViaShapeArray(cv "VIA12" nil x2-V12w/2  y4-V12w/2  V12p V12p V12w V12w 1 1) ;MOS6drain connect to mos7poly
    dbCreateRect(cv M1Layer list(x2-V12w/2-0.06:y4-V12w/2-0.06 x2+V12w/2+0.06:y4+V12w/2+0.06))
    
    NInstOverlap = crGetOverlapLayerBoxList(cv nth(10 NInst_list) M1Layer ODLayer)
    NInstOverlap = cadr(NInstOverlap)
    x1=(leftEdge(NInstOverlap)+rightEdge(NInstOverlap))/2 +SD_DRCspace/2 
    netQ = dbCreateNet(cv "Q")
    Qpinfig=dbCreateRect(cv M1PinLayer list(x1-0.12:y3-0.12 x1+0.12:y3+0.12 ))
    Qpin=dbCreatePin(netQ Qpinfig "Q") 
    Qpin~>AccessDir=list("top" "bottom" "left" "right")
 ;   dbCreateViaShapeArray(cv "VIA12" netQ x1-V12w/2 y3-V12w/2 V12p V12p V12w V12w 1 1) ;创建CLKpin和via
    dbCreateLabel(cv M1PinLayer x1:y3 "Q" "centerCenter" "R0" "roman" 0.2 )

    LogicPcellCdf("zsytest" "DFF")

)

