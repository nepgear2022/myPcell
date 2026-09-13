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

procedure(crConnectToVDD(PbBox)
     let((y1 y2 MidX )
         MidX = (caar(PbBox) + caadr(PbBox))/2
         y1=cadar(PbBox)
         y2=VDDy1
         dbCreatePath(cv M1Layer list(MidX:y1 MidX:y2) 0.24) ;连接VDD线
     )
)

procedure(crConnectToVSS(NbBox)
     let((y1 y2 MidX )
         MidX = (caar(NbBox) + caadr(NbBox))/2
         y1=cadar(NbBox)
         y2=VSSy1
         dbCreatePath(cv M1Layer list(MidX:y1 MidX:y2) 0.24) ;连接VSS线
     )
)

procedure(crEnsureVia12(X signal_y net)
    let((viaLayer probeBox viaList hasVia via box viaX viaY)
    viaLayer = list("VIA12" "drawing")
    probeBox = list(
      X-V12w/2 : signal_y-V12w/2
      X+V12w/2 : signal_y+V12w/2
    )
    viaList = dbGetOverlaps(cv probeBox viaLayer)
    hasVia = nil
    foreach(via viaList
      box = via~>bBox
      viaX = (leftEdge(box) + rightEdge(box)) / 2
      viaY = (bottomEdge(box) + topEdge(box)) / 2

      when(
        abs(viaX - X) <= V12w &&
        abs(viaY - signal_y) <= V12w
        hasVia = t
      )
    )
     unless(hasVia
       dbCreateViaShapeArray(cv "VIA12" net X-V12w/2 signal_y-V12w/2 V12p V12p V12w V12w 1 1)
     )
    )
);连接signal线和ploy的时候打孔



procedure(crConnectPloyToSignal(bBox signal net)
    let((signal_y X y1 y2 maxY minY)
        signal_y=(topEdge(signal~>bBox)+bottomEdge(signal~>bBox))/2
        X=(leftEdge(bBox)+rightEdge(bBox))/2
        y1=bottomEdge(bBox)
        y2=topEdge(bBox)
        maxY=max(y1 y2 signal_y-V12w/2-0.1 signal_y+V12w/2+0.1)
        minY=min(y1 y2 signal_y-V12w/2-0.1 signal_y+V12w/2+0.1)         ;需满足M1 Enc V12
        dbCreatePath(cv M1Layer list(X:minY X:maxY) 0.28)       ;0.28为需满足M1 Enc V12
        crEnsureVia12(X signal_y net)
        if( y1>signal_y                                                              ;如果是PMOS
          then progn(dbCreatePath(cv POLayer list(X:y1 X:y1-0.6) pl_var*1e6)
             dbCreateRect(cv "CONT" list(X-0.11:y1-0.6+0.33 X+0.11:y1-0.6+0.11 ))
                    )
          else progn(dbCreatePath(cv POLayer list(X:y2 X:y2+0.6) nl_var*1e6)       ;如果是nMOS
             dbCreateRect(cv "CONT" list(X-0.11:y2+0.6-0.33 X+0.11:y2+0.6-0.11 ))
                  )
          )
        
        
    )
)    ;连接signal线和ploy

procedure(crConnectdrain(NInstbBox PInstbBox net)
    let((X1 X2 X3 X4 X5 Y1 Y2 Y3 Y4 Y5)
    X1=(leftEdge(PInstbBox)+rightEdge(PInstbBox))/2
    Y1=topEdge(PInstbBox)                                           ;PMOS顶端
    X2=X1
    Y2=bottomEdge(PInstbBox)-0.8                       ;PMOS底端
    X4=(leftEdge(NInstbBox)+rightEdge(NInstbBox))/2               
    Y4=topEdge(NInstbBox)+0.8                                       ;NMOS顶端
    X5=X4 
    Y5=bottomEdge(NInstbBox)                                        ;NMOS底端
    X3=X4
    Y3=Y2
    dbCreatePath(cv M1Layer list(X1:Y1 X2:Y2-V12w/2-0.1) 0.28)
    dbCreatePath(cv M1Layer list(X4:Y4+V12w/2+0.1 X5:Y5) 0.28)
    if( X2 == X3
        then dbCreatePath(cv M3Layer list(X3:Y3+V12w/2+0.1 X4:Y4-V12w/2-0.1) 0.28)
        else dbCreatePath(cv M3Layer list(X2+V12w/2+0.1:Y2 X3:Y3 X4:Y4-V12w/2-0.1) 0.28)
    
    )
    dbCreateViaShapeArray(cv "VIA12" net X2-V12w/2 Y2-V12w/2 V12p V12p V12w V12w 1 1)
    dbCreateViaShapeArray(cv "VIA12" net X4-V12w/2 Y4-V12w/2 V12p V12p V12w V12w 1 1)
    dbCreateViaShapeArray(cv "VIA23" net X2-V23w/2 Y2-V23w/2 V23p V23p V23w V23w 1 1)
    dbCreateViaShapeArray(cv "VIA23" net X4-V23w/2 Y4-V23w/2 V23p V23p V23w V23w 1 1)
    dbCreateRect(cv M2Layer list(X2-0.23:Y2-0.23 X2+0.23:Y2+0.23))
    dbCreateRect(cv M2Layer list(X4-0.23:Y4-0.235 X4+0.23:Y4+0.23))
    )
)



pcDefinePCell(list(ddGetObj("zsytest") "XOR" "layout")
        (
        (pl "0.48u")                               ; 沟道长度 0.48是为了满足M1与M1间距大于0.23
        (pw "1.0u")                                ; 沟道宽度
        (nl "0.48u")                          
        (nw "1.0u")                           
        (PNSpace "6.0u")                  ;PMOS NMOS间距
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
    M3PinLayer = list("METAL3" "pin")
    M1Layer    = list("METAL1" "drawing")
    M2Layer    = list("METAL2" "drawing")
    M3Layer    = list("METAL3" "drawing")
    V12w         = techGetSpacingRule(tf "minWidth" "VIA12")        ; VIA12 最小宽度
    V12s         = techGetSpacingRule(tf "minSpacing" "VIA12")      ; VIA12 最小间距
    V12p         = V12w + V12s                                        ; VIA12 节距
    V23w         = techGetSpacingRule(tf "minWidth" "VIA23")        ; VIA23 最小宽度
    V23s         = techGetSpacingRule(tf "minSpacing" "VIA23")      ; VIA23 最小间距
    V23p         = V23w + V23s 
    PPNPEncOD   = techGetSpacingRule(tf "minEnclosure" "PIMP" "DIFF")
    POEncCO     = techGetSpacingRule(tf "minEnclosure" "POLY1" "CONT")
    PathW=0.15 ;互联线宽度
    COw=techGetSpacingRule(tf "minWidth" "CONT")
    COs=techGetSpacingRule(tf "minSpacing" "CONT")
    CORows = 2
    mfgGrid=techGetMfgGridResolution(tf)

    
    PMOS_Y=atof(aelSuffixNotation(nw_var+PNSpace_var))
    MOS_X1=0.0
    MOS_X2=1.8
    MOS_X3=3.6
    MOS_X4=MOS_X3+0.72+(nl_var*1e6-0.18)   ;0.72+(nl_var*1e6-0.18) 的目的为让源极漏极重合
    MOS_X5=7.1                             ;避免N井间距小于0.44
    MOS_X6=MOS_X5+0.72+(nl_var*1e6-0.18) 
   
    NInstId1=dbCreateParamInstByMasterName(cv "tsmc18" "nmos2v" "layout" "" list(0 0) "R0" 1
                                          list(    list("w"  "string" sprintf(str,"%g",nw_var))                 
                                                   list("l"  "string" sprintf(str,"%g",nl_var))
                                              ))
    NInstId2=dbCreateParamInstByMasterName(cv "tsmc18" "nmos2v" "layout" "" list(MOS_X2 0) "R0" 1
                                          list(list("w" "string" sprintf(str,"%g",nw_var)) list("l" "string" sprintf(str,"%g",nl_var))))
    NInstId3=dbCreateParamInstByMasterName(cv "tsmc18" "nmos2v" "layout" "" list(MOS_X3 0) "R0" 1
                                          list(list("w" "string" sprintf(str,"%g",nw_var)) list("l" "string" sprintf(str,"%g",nl_var))))
    NInstId4=dbCreateParamInstByMasterName(cv "tsmc18" "nmos2v" "layout" "" list(MOS_X4 0) "R0" 1
                                          list(list("w" "string" sprintf(str,"%g",nw_var)) list("l" "string" sprintf(str,"%g",nl_var))))
    NInstId5=dbCreateParamInstByMasterName(cv "tsmc18" "nmos2v" "layout" "" list(MOS_X5 0) "R0" 1
                                          list(list("w" "string" sprintf(str,"%g",nw_var)) list("l" "string" sprintf(str,"%g",nl_var))))
    NInstId6=dbCreateParamInstByMasterName(cv "tsmc18" "nmos2v" "layout" "" list(MOS_X6 0) "R0" 1
                                          list(list("w" "string" sprintf(str,"%g",nw_var)) list("l" "string" sprintf(str,"%g",nl_var))))

    PInstId1=dbCreateParamInstByMasterName(cv "tsmc18" "pmos2v" "layout" "" list(MOS_X1 PMOS_Y) "R0" 1
                                          list(list("w" "string" sprintf(str,"%g",pw_var)) list("l" "string" sprintf(str,"%g",pl_var))))
    PInstId2=dbCreateParamInstByMasterName(cv "tsmc18" "pmos2v" "layout" "" list(MOS_X2 PMOS_Y) "R0" 1
                                          list(list("w" "string" sprintf(str,"%g",pw_var)) list("l" "string" sprintf(str,"%g",pl_var))))
    PInstId3=dbCreateParamInstByMasterName(cv "tsmc18" "pmos2v" "layout" "" list(MOS_X3 PMOS_Y) "R0" 1
                                          list(list("w" "string" sprintf(str,"%g",pw_var)) list("l" "string" sprintf(str,"%g",pl_var))))
    PInstId4=dbCreateParamInstByMasterName(cv "tsmc18" "pmos2v" "layout" "" list(MOS_X4 PMOS_Y) "R0" 1
                                          list(list("w" "string" sprintf(str,"%g",pw_var)) list("l" "string" sprintf(str,"%g",pl_var))))
    PInstId5=dbCreateParamInstByMasterName(cv "tsmc18" "pmos2v" "layout" "" list(MOS_X5 PMOS_Y) "R0" 1
                                          list(list("w" "string" sprintf(str,"%g",pw_var)) list("l" "string" sprintf(str,"%g",pl_var))))
    PInstId6=dbCreateParamInstByMasterName(cv "tsmc18" "pmos2v" "layout" "" list(MOS_X6 PMOS_Y) "R0" 1
                                          list(list("w" "string" sprintf(str,"%g",pw_var)) list("l" "string" sprintf(str,"%g",pl_var))))
                                          
    dbCreateRect(cv "NWELL" list(leftEdge(PInstId1)-0.1:bottomEdge(PInstId1) rightEdge(PInstId6):topEdge(PInstId6)))
    
    
    
    InstLeftX=leftEdge(NInstId1)
    InstRightX=rightEdge(NInstId6)
    Y_Bi=atof(aelSuffixNotation(nw_var+PNSpace_var/8*2))
    Y_B=atof(aelSuffixNotation(nw_var+PNSpace_var/8*3))
    Y_A=atof(aelSuffixNotation(nw_var+PNSpace_var/8*4))
    Y_Ai=atof(aelSuffixNotation(nw_var+PNSpace_var/8*5))
    SignalBi=dbCreatePath(cv M2Layer list(leftEdge(NInstId2):Y_Bi InstRightX:Y_Bi) 0.38)
    SignalB=dbCreatePath(cv M2Layer list(InstLeftX:Y_B InstRightX:Y_B) 0.38)
    SignalA=dbCreatePath(cv M2Layer list(InstLeftX:Y_A InstRightX:Y_A) 0.38)
    SignalAi=dbCreatePath(cv M2Layer list(InstLeftX:Y_Ai InstRightX:Y_Ai) 0.38)
    netA = dbCreateNet(cv "A")
    dbCreateTerm(netA "A" "input")
    netB = dbCreateNet(cv "B")
    dbCreateTerm(netB "B" "input")
    netAi = dbCreateNet(cv "Ai")
    dbCreateTerm(netA "A" "input")
    netBi = dbCreateNet(cv "Bi")
    dbCreateTerm(netB "B" "input")
    netAXORB = dbCreateNet(cv "AXORB")
    dbCreateTerm(netAXORB "AXORB" "output")
    
    
    
    VSSy1=bottomEdge(NInstId1)-0.7
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
               ?beginOffset -0.35
               ?endOffset -0.35
               ?space            0.3      ));End ofsubRectArray
           )  ;
     dbCreateLabel(cv M1PinLayer InstLeftX:VSSy1 "VSS" "centerLeft" "R0" "roman" 0.3 );  VSS Label
     VSSRing = rodCreateRect(
           ?cvId  cv
           ?layer "PIMP"
           ?fromObj VSSpath
           ?size PPNPEncOD)     ;VSS保护环
    
     VDDy1=topEdge(PInstId1)+0.7
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
               ?beginOffset -0.35
               ?endOffset -0.35
               ?space     0.3      ));End ofsubRectArray
           )  ;
     dbCreateLabel(cv M1PinLayer InstLeftX:VDDy1 "VDD" "centerLeft" "R0" "roman" 0.3 );  VDD Label
     VDDRing = rodCreateRect(
           ?cvId  cv
           ?layer "NIMP"
           ?fromObj VDDpath
           ?size PPNPEncOD)     ;VDD保护环
           
     PInstOverlap1=crGetOverlapLayerBoxList(cv PInstId1 M1Layer ODLayer)
     Overlap1=car(PInstOverlap1)
     PInstOverlap2=crGetOverlapLayerBoxList(cv PInstId2 M1Layer ODLayer)
     Overlap2=car(PInstOverlap2)
     PInstOverlap3=crGetOverlapLayerBoxList(cv PInstId3 M1Layer ODLayer)
     Overlap3=car(PInstOverlap3)
     PInstOverlap4=crGetOverlapLayerBoxList(cv PInstId4 M1Layer ODLayer)
     PInstOverlap5=crGetOverlapLayerBoxList(cv PInstId5 M1Layer ODLayer)
     PInstOverlap6=crGetOverlapLayerBoxList(cv PInstId6 M1Layer ODLayer)
     Overlap5=car(PInstOverlap5)
     crConnectToVDD(Overlap1)
     crConnectToVDD(Overlap2)
     crConnectToVDD(Overlap3)
     crConnectToVDD(Overlap5)
     
     NInstOverlap1=crGetOverlapLayerBoxList(cv NInstId1 M1Layer ODLayer)
     Overlap1=car(NInstOverlap1)
     NInstOverlap2=crGetOverlapLayerBoxList(cv NInstId2 M1Layer ODLayer)
     Overlap2=car(NInstOverlap2)
     NInstOverlap3=crGetOverlapLayerBoxList(cv NInstId3 M1Layer ODLayer)
     NInstOverlap4=crGetOverlapLayerBoxList(cv NInstId4 M1Layer ODLayer)
     Overlap4=cadr(NInstOverlap4)
     NInstOverlap5=crGetOverlapLayerBoxList(cv NInstId5 M1Layer ODLayer)
     NInstOverlap6=crGetOverlapLayerBoxList(cv NInstId6 M1Layer ODLayer)
     Overlap6=cadr(NInstOverlap6)
     crConnectToVSS(Overlap1)
     crConnectToVSS(Overlap2)
     crConnectToVSS(Overlap4)
     crConnectToVSS(Overlap6)   ;源极连接VSS,VDD部分
     
     net3 = dbCreateNet(cv "3")
     net4 = dbCreateNet(cv "4")
     P_Drain1=cadr(PInstOverlap1)
     P_Drain2=cadr(PInstOverlap2)
     P_Drain4=cadr(PInstOverlap4)
     P_Drain6=cadr(PInstOverlap6)
     N_Drain1=cadr(NInstOverlap1)
     N_Drain2=cadr(NInstOverlap2)
     N_Drain3=car(NInstOverlap3)
     N_Drain5=car(NInstOverlap5)
     crConnectdrain(N_Drain1 P_Drain1 netAi)
     crConnectdrain(N_Drain2 P_Drain2 netBi)
     crConnectdrain(N_Drain3 P_Drain4 net3)
     crConnectdrain(N_Drain5 P_Drain6 net4) ; PNMOS的M2连线
     
     PInstOverlap1=crGetOverlapLayerBoxList(cv PInstId1 POLayer ODLayer)
     PInstOverlap2=crGetOverlapLayerBoxList(cv PInstId2 POLayer ODLayer)
     PInstOverlap3=crGetOverlapLayerBoxList(cv PInstId3 POLayer ODLayer)
     PInstOverlap4=crGetOverlapLayerBoxList(cv PInstId4 POLayer ODLayer)
     ;PInstOverlap5例外
     PInstOverlap6=crGetOverlapLayerBoxList(cv PInstId6 POLayer ODLayer)
     NInstOverlap1=crGetOverlapLayerBoxList(cv NInstId1 POLayer ODLayer)
     NInstOverlap2=crGetOverlapLayerBoxList(cv NInstId2 POLayer ODLayer)
     NInstOverlap3=crGetOverlapLayerBoxList(cv NInstId3 POLayer ODLayer)
     NInstOverlap4=crGetOverlapLayerBoxList(cv NInstId4 POLayer ODLayer)
     NInstOverlap5=crGetOverlapLayerBoxList(cv NInstId5 POLayer ODLayer)
     NInstOverlap6=crGetOverlapLayerBoxList(cv NInstId6 POLayer ODLayer)
     when(length(PInstOverlap1) != 1
         error("PInstId1: 期望只得到 1 个 M1/DIFF overlap bBox，实际得到 %d 个。"
                                                     length(PInstOverlap1) )
     )
     
     crConnectPloyToSignal(car(PInstOverlap1) SignalA netA)
     crConnectPloyToSignal(car(PInstOverlap2) SignalB netB)
     crConnectPloyToSignal(car(PInstOverlap3) SignalA netA)
     crConnectPloyToSignal(car(PInstOverlap4) SignalAi netAi)
     crConnectPloyToSignal(car(PInstOverlap6) SignalBi  netBi)
     crConnectPloyToSignal(car(NInstOverlap1) SignalA netA)
     crConnectPloyToSignal(car(NInstOverlap2) SignalB netB)
     crConnectPloyToSignal(car(NInstOverlap3) SignalA netA)
     crConnectPloyToSignal(car(NInstOverlap4) SignalB  netB)
     crConnectPloyToSignal(car(NInstOverlap5) SignalAi netA)
     crConnectPloyToSignal(car(NInstOverlap6) SignalBi netBi)  ;连接poly和M1
     
     PInstOverlap5=crGetOverlapLayerBoxList(cv PInstId5 POLayer ODLayer) ;   
     X1 = (caaar(PInstOverlap5)+caadar(PInstOverlap5))/2
     Y1 = topEdge(car(PInstOverlap5))
     X2=X1
     Y2 = bottomEdge(car(PInstOverlap5))-0.6
     X3=X2-1.0
     Y3=Y2
     X4=X3
     Y4=Y_B
     dbCreatePath(cv M1Layer list(X1:Y1 X2:Y2 X3:Y3 X4:Y4-V12w/2-0.1) 0.28)
     dbCreateViaShapeArray(cv "VIA12" netB X4-V12w/2 Y4-V12w/2 V12p V12p V12w V12w 1 1)     ;PInstOverlap5例外,连接到B
     
     PInstOverlap4=crGetOverlapLayerBoxList(cv PInstId4 M1Layer ODLayer)
     Overlap4=car(PInstOverlap4)
     PInstOverlap6=crGetOverlapLayerBoxList(cv PInstId6 M1Layer ODLayer)
     Overlap6=car(PInstOverlap6)
     X1=(leftEdge(Overlap4)+rightEdge(Overlap4))/2
     Y1=topEdge(Overlap4)                                          ;PMOS4顶端
     X2=X1
     Y2=bottomEdge(Overlap4)-1.6
     X4=(leftEdge(Overlap6)+rightEdge(Overlap6))/2
     Y4=topEdge(Overlap6)                                          ;PMOS6顶端
     X3=X4
     Y3=Y2
     dbCreatePath(cv M1Layer list(X1:Y1 X2:Y2-V12w/2-0.1) 0.28) 
     dbCreatePath(cv M1Layer list(X3:Y3-V12w/2-0.1 X4:Y4) 0.28)
     dbCreatePath(cv M2Layer list(X2-V12w/2-0.1:Y2 X3+V12w/2+0.1:Y3) 0.28) 
     net5 = dbCreateNet(cv "5")
     dbCreateViaShapeArray(cv "VIA12" netB X2-V12w/2 Y2-V12w/2 V12p V12p V12w V12w 1 1)     
     dbCreateViaShapeArray(cv "VIA12" netB X3-V12w/2 Y3-V12w/2 V12p V12p V12w V12w 1 1)     ;PMOS4和6的连线
     
     
     PInstOverlap3=crGetOverlapLayerBoxList(cv PInstId3 M1Layer ODLayer)
     Overlap3=car(PInstOverlap3)
     X1=(leftEdge(Overlap3)+rightEdge(Overlap3))/2
     Y1=(Y_A+Y_B)/2
     X2=rightEdge(NInstId6)+1.0
     Y2=Y1
     X3=X2
     Y3=topEdge(NInstId6)-V12w/2-0.1
     dbCreatePath(cv M3Layer list(X1:Y1 X2:Y2 X3:Y3) 0.28)
     dbCreateViaShapeArray(cv "VIA23" netAXORB X3-V23w/2 Y3+0.1 V23p V23p V23w V23w 1 1)
     dbCreateRect(cv M2Layer list(X3-0.23:Y3 X3+0.23:Y3+0.46))

)