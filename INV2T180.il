  procedure(crGetOverlapLayerBoxList(cv inst lpp1 lpp2)
    let((Shp1 Shp2 OverlapLayerout OverlapLayerBoxList)
         Shp1=setof(x inst~>master~>shapes x~>lpp==lpp1)
         Shp2=setof(x inst~>master~>shapes x~>lpp==lpp2)
         OverlapLayerOut=dbLayerAnd(cv lpp1 Shp1 Shp2)
         OverlapLayerBoxList=foreach(mapcar x OverlapLayerOut~>bBox dbTransformBBox(x inst~>transform))
         foreach(one OverlapLayerOut dbDeleteObject(one))
         OverlapLayerBoxList=sort(OverlapLayerBoxList lambda((A B) lessp(caadr(A) caadr(B))))
        );let
);proc

 procedure(crGetLayerBox(inst lpp)
   let((ShpBBox xformShpBBox llxList llyList urxList uryList minllx minlly maxurx maxury)
        ShpBBox=setof(x inst~>master~>shapes x~>lpp==lpp)
        xformShpBBox=foreach(mapcar x ShpBBox~>bBox dbTransformBBox(x inst~>transform))
        llxList=foreach(mapcar bBox xformShpBBox xCoord(lowerLeft(bBox)))
        llyList=foreach(mapcar bBox xformShpBBox yCoord(lowerLeft(bBox)))
        urxList=foreach(mapcar bBox xformShpBBox xCoord(upperRight(bBox)))
        uryList=foreach(mapcar bBox xformShpBBox yCoord(upperRight(bBox)))
        minllx=apply('min llxList)
        minlly=apply('min llyList)
        maxurx=apply('max urxList)
        maxury=apply('max uryList)
        list(list(minllx minlly) list(maxurx maxury))
      );let
);proc
 

      
 procedure(CreateINV2(libName cellName) 
          pcDefinePCell(list(ddGetObj(libName) cellName "layout")
                            (
                            (pw         "1.0u")
                            (pfw         "1.0u")
                            (pl          "0.5u")
                            (nw         "1.0u")
                            (nfw         "1.0u")
                            (nl          "0.5u")
                            (PNSpace     "3.0u")
                            (PathW    0.15)
                               )   
    let((cv tmp tmp1 NInstId PInstId M1Layer M1PinLayer M2Layer M2PinLayer POLayer PPLayer NPLayer ODLayer NWLayer COLayer tf mfgGrid COs COw COp V1w V1s V1p GateCORows GateCOColumns M1EncCO ODEncCO PPNPEncOD NWEnCO)
    cv=pcCellView 
    pw_var=cdfParseFloatString(pw)
    pfw_var=cdfParseFloatString(pfw)
    pl_var=cdfParseFloatString(pl)
    nw_var=cdfParseFloatString(nw)
    nfw_var=cdfParseFloatString(nfw)
    nl_var=pl_var;cdfParseFloatString(nl)
    PNSpace_var=cdfParseFloatString(PNSpace)
    NInstId=dbCreateParamInstByMasterName(cv "zsytest" "Nmos2" "layout" "" list(0 0) "R0" 1
                      list(
                             list("w"  "string" sprintf(str,"%g",nw_var))
                           ;  list("fw" "string" sprintf(str "%g" nfw_var))
                           list("l"  "string" sprintf(str "%g" pl_var)                             
                             list("TAP"  "string" "nil"))  ));Create NMOS


   tmp=atof(aelSuffixNotation(nw_var+PNSpace_var))
   PInstId=dbCreateParamInstByMasterName(cv "zsytest" "Pmos2" "layout" "" list(0 tmp) "R0" 1
                     list(
                            list("w"  "string" sprintf(str,"%g",pw_var))
                          ;  list("fw" "string" sprintf(str "%g" pfw_var)) 
                            list("l"  "string" sprintf(str,"%g",pl_var))  
                         
                         )
                                          );Create PMOS
  M1Layer=list("METAL1" "drawing")
  M1PinLayer=list("METAL1" "pin")
  M2Layer=list("METAL2" "drawing")
  M2PinLayer=list("METAL2" "pin")
  POLayer=list("POLY1" "drawing")
  PPLayer=list("PIMP" "drawing")
  NPLayer=list("NIMP" "drawing")
  ODLayer=list("DIFF" "drawing")
  NWLayer=list("NWELL" "drawing")
  COLayer=list("CONT" "drawing")
   ;Layer Def
  tf=techGetTechFile(cv)
  mfgGrid=techGetMfgGridResolution(tf)
  COw=techGetSpacingRule(tf "minWidth" "CONT")
  COs=techGetSpacingRule(tf "minSpacing" "CONT")
  COp=COw+COs
  V1w=techGetSpacingRule(tf "minWidth" "VIA12")
  V1s=techGetSpacingRule(tf "minSpacing" "VIA12")
  V1p=V1w+V1s
  GateCORows=2 
  GateCOColumns=2 
  M1EncCO=techGetSpacingRule(tf "minEnclosure" "METAL1" "CONT")
  M1EncV1=techGetSpacingRule(tf "minEnclosure" "METAL1" "VIA12")
  ODEncCO=techGetSpacingRule(tf "minEnclosure" "DIFF" "CONT")
  PPNPEncOD=techGetSpacingRule(tf "minEnclosure" "PIMP" "DIFF")
  NWEncOD=techGetSpacingRule(tf "minEnclosure" "NWELL" "DIFF")
 ;Param Def



  ; ==================== NMOS 栅极金属和接触孔 ====================
        xgate=car(centerBox(NInstId~>bBox))  
        oneinst_ODPOOverlapBox=crGetOverlapLayerBoxList(cv NInstId POLayer ODLayer)
        tmp=cdfParseFloatString(nw)*1e6*0.5        
        gateM1_y0=topEdge(car(oneinst_ODPOOverlapBox))+tmp                 
        gateM1_y1=gateM1_y0+(2*M1EncCO+COw*GateCORows+(COp-COw)*(GateCORows-1))
        gatePO_y0=topEdge(car(oneinst_ODPOOverlapBox))
        gatePO_y1=gateM1_y1
        tmp1=gateM1_y1
    ; 画 M1 矩形（覆盖栅极区域）
foreach(x oneinst_ODPOOverlapBox
       gateM1_x0=leftEdge(x)                                                                    
       gateM1_x1=rightEdge(x)                                                                   
       M1Obj=dbCreateRect(cv M1Layer list(gateM1_x0:gateM1_y0 gateM1_x1:gateM1_y1))            
       POObj=dbCreateRect(cv POLayer list(gateM1_x0:gatePO_y0 gateM1_x1:gatePO_y1))     
       gate_Length=gateM1_x1-gateM1_x0                                                          
       GatePOEncCO_H=(gate_Length-GateCOColumns*COw-(GateCOColumns-1)*(COp-COw))/2.0      
       GatePOEncCO_H=floor(GatePOEncCO_H/mfgGrid)*mfgGrid 
          fig1=dbCreateFigGroup(cv "fig1" t 0:0 "R0")
          dbAddFigToFigGroup(fig1 M1Obj)
          dbAddFigToFigGroup(fig1 POObj)    
  ; 嵌套循环生成 GateCORows × GateCOColumns 的 CONT 阵列                              
    for(i 0 GateCORows-1
        gateCO_y0=gateM1_y0+M1EncCO+i*COp
        for(j 0 GateCOColumns-1
           gateCO_x0=gateM1_x0+GatePOEncCO_H+j*COp
           COObj=dbCreateRect(cv COLayer list(gateCO_x0:gateCO_y0 gateCO_x0+COw:gateCO_y0+COw))
            dbAddFigToFigGroup(fig1 COObj)
           ;Drawing METAL1&&POLY1 of Gate
          );for   
       );for
        );foreach
        ;Create NMOS Gate Via

        tmp=cdfParseFloatString(pw)*1e6*0.5
        oneinst_ODPOOverlapBox=crGetOverlapLayerBoxList(cv PInstId POLayer ODLayer)
        gateM1_y1=bottomEdge(car(oneinst_ODPOOverlapBox))-tmp
        gateM1_y0=gateM1_y1-(2*M1EncCO+COw*GateCORows+(COp-COw)*(GateCORows-1))
                
        gatePO_y0=gateM1_y0
        gatePO_y1=bottomEdge(car(oneinst_ODPOOverlapBox))
  foreach(x oneinst_ODPOOverlapBox
       gateM1_x0=leftEdge(x)                                                                    
       gateM1_x1=rightEdge(x)                                                                   
       M1Obj=dbCreateRect(cv M1Layer list(gateM1_x0:gateM1_y0 gateM1_x1:gateM1_y1))            
       POObj=dbCreateRect(cv POLayer list(gateM1_x0:gatePO_y0 gateM1_x1:gatePO_y1))     
       gate_Length=gateM1_x1-gateM1_x0                                                          
       GatePOEncCO_H=(gate_Length-GateCOColumns*COw-(GateCOColumns-1)*(COp-COw))/2.0      
       GatePOEncCO_H=floor(GatePOEncCO_H/mfgGrid)*mfgGrid 
          fig=dbCreateFigGroup(cv "fig" t 0:0 "R0")
          dbAddFigToFigGroup(fig M1Obj)
          dbAddFigToFigGroup(fig POObj)    
                                     
    for(i 0 GateCORows-1
        gateCO_y0=gateM1_y0+M1EncCO+i*COp
        for(j 0 GateCOColumns-1
           gateCO_x0=gateM1_x0+GatePOEncCO_H+j*COp
           COObj=dbCreateRect(cv COLayer list(gateCO_x0:gateCO_y0 gateCO_x0+COw:gateCO_y0+COw))
            dbAddFigToFigGroup(fig COObj)
           ;Drawing METAL1&&POLY1 of Gate
          );for   
       );for
        );foreach
           ;Create PMOS Gate Via



   dbCreatePath(cv M1Layer list(xgate:tmp1 xgate:gateM1_y0) PathW)
   tmp=(gateM1_y0-tmp1)*0.5 
   fig=dbCreateRect(cv M1PinLayer 
           list(xgate-PathW*0.5:tmp+tmp1-PathW*0.5 xgate+PathW*0.5:tmp+tmp1+PathW*0.5))
   net=dbCreateNet(cv "A")
   dbCreateTerm(net "A" "input")
   dbCreateLabel(cv M1PinLayer xgate-PathW*0.5:tmp+tmp1 "A" "centerLeft" "R0" "roman" PathW)
   pin=dbCreatePin(net fig "A")
   pin~>accessDir=list("top" "bottom" "left" "right")
   ;Create  Input path and pin
   ;printf("81") 

   P_M1PPOverlapBox=crGetOverlapLayerBoxList(cv PInstId M1Layer PPLayer)
   P_M1PPOverlapBox=sort(P_M1PPOverlapBox lambda((A B) greaterp(cadar(A) cadar(B))))
   P_leftM1Box=nth(0 P_M1PPOverlapBox)
   P_rightM1Box=nth(1 P_M1PPOverlapBox)
      unless(caar(P_leftM1Box)<caar(P_rightM1Box)
        x=P_leftM1Box
        P_leftM1Box=P_rightM1Box
        P_rightM1Box=x
       ) 
       ;Make sure that leftBox is on left for some wrong cases
   P_gateM1Box_x0=(caar(P_leftM1Box)+caadr(P_rightM1Box))/2-(PathW/2)
   P_gateM1Box_x1=(caar(P_leftM1Box)+caadr(P_rightM1Box))/2+(PathW/2)
   P_gateM1Box_y0=cadadr(P_leftM1Box)+0.2
   P_gateM1Box_y1=cadadr(P_leftM1Box)+0.7
   ;printf("92") 
   P_gateM1Box=list(list(P_gateM1Box_x0 P_gateM1Box_y0) list(P_gateM1Box_x1 P_gateM1Box_y1))
  
   ;printf("98") 
   N_M1NPOverlapBox=crGetOverlapLayerBoxList(cv NInstId M1Layer NPLayer)
   N_M1NPOverlapBox=sort(N_M1NPOverlapBox lambda((A B) lessp(cadar(A) cadar(B))))
   N_leftM1Box=nth(0 N_M1NPOverlapBox)
   N_rightM1Box=nth(1 N_M1NPOverlapBox)
      unless(caar(N_leftM1Box)<caar(N_rightM1Box)
         x=N_leftM1Box
         N_leftM1Box=N_rightM1Box
         N_rightM1Box=x
       )

   N_gateM1Box_x0=(caar(N_leftM1Box)+caadr(N_rightM1Box))/2-(PathW/2)
   N_gateM1Box_x1=(caar(N_leftM1Box)+caadr(N_rightM1Box))/2+(PathW/2)
   N_gateM1Box_y0=cadadr(N_leftM1Box)+0.2
   N_gateM1Box_y1=cadadr(N_leftM1Box)+0.7
   N_gateM1Box=list(list(N_gateM1Box_x0 N_gateM1Box_y0) list(N_gateM1Box_x1 N_gateM1Box_y1)) 
 
  ;printf("113") 

P_x1=float(caar(P_rightM1Box))
P_y=cadadr(P_rightM1Box)
P_x2=max(caadr(P_gateM1Box) caadr(N_gateM1Box))+PathW+PathW/2.0


N_x2=P_x2
N_y=cadar(N_rightM1Box)
N_x1=caar(N_rightM1Box)


Mid=(caar(P_rightM1Box)+caadr(P_rightM1Box))/2.0
dbCreatePath(cv M2Layer list(Mid:N_y Mid:P_y) PathW)
fig=dbCreateRect(cv M2PinLayer 
    list(Mid-PathW*0.5:tmp+tmp1-PathW*0.5 Mid+PathW*0.5:tmp+tmp1+PathW*0.5)) 
net=dbCreateNet(cv "Y")
dbCreateTerm(net "Y" "output")
dbCreateLabel(cv M2PinLayer Mid:tmp+tmp1 "Y" "centerCenter" "R0" "roman" PathW)
pin=dbCreatePin(net fig "Y")
pin~>accessDir=list("top" "bottom" "left" "right")
;Create Output path & pin

tmp=cdfParseFloatString(nw)*1e6+0.02
dbCreatePath(cv M1Layer list(Mid:N_y Mid:N_y+tmp) PathW)
tmp=int((tmp+V1s-2*M1EncV1)/V1p)
dbCreateViaShapeArray(cv "VIA12" techGetTechFile(cv) Mid-V1w*0.5 N_y+M1EncV1 V1p V1p V1w V1w tmp 1)
 


tmp=cdfParseFloatString(pw)*1e6+0.02
dbCreatePath(cv M1Layer list(Mid:P_y Mid:P_y-tmp) PathW)
tmp1=int((tmp+V1s-2*M1EncV1)/V1p)
dbCreateViaShapeArray(cv "VIA12" techGetTechFile(cv) Mid-V1w*0.5 P_y-tmp+M1EncV1 V1p V1p V1w V1w tmp1 1)



PMosPPTop=cadadr(crGetLayerBox(PInstId PPLayer))
NMosNPBot=cadar(crGetLayerBox(NInstId NPLayer))

Ring_Width=2*ODEncCO+COw

Ring_x0=min(leftEdge(crGetLayerBox(PInstId PPLayer)) leftEdge(crGetLayerBox(NInstId NPLayer)))
Ring_x1=max(rightEdge(crGetLayerBox(PInstId PPLayer)) rightEdge(crGetLayerBox(NInstId NPLayer)))
NRing_y0=PMosPPTop+PPNPEncOD
NRing_y1=NRing_y0+Ring_Width
PRing_y1=NMosNPBot-PPNPEncOD
PRing_y0=PRing_y1-Ring_Width
       
  for(num 0 0
    foreach(layer list(M1Layer ODLayer)
        foreach(yPref '("PRing_y" "NRing_y")
            dbCreateRect(cv layer
                list(
                    evalstring(artMakeString(concat("Ring_x"  num))) + PPNPEncOD :
                    evalstring(artMakeString(concat(yPref    num)))
                    
                    evalstring(artMakeString(concat("Ring_x"  num+1))) - PPNPEncOD :
                    evalstring(artMakeString(concat(yPref    num+1)))
                )
                      )
              )
             )
      )
   
  ;Create DIFF/METAL1 layer of Ring

         fig=dbCreateRect(cv M1PinLayer list(Ring_x0+PPNPEncOD:NRing_y0 Ring_x0+PPNPEncOD+NRing_y1-NRing_y0:NRing_y1))
         net=dbCreateNet(cv "VDD")
         dbCreateTerm(net "VDD" "inputOutput")
         dbCreateLabel(cv M1PinLayer Ring_x0+PPNPEncOD:(NRing_y1+NRing_y0)/2.0 "VDD" "centerLeft" "R0" "roman" Ring_Width)
         pin=dbCreatePin(net fig "VDD")
         pin~>AccessDir=list("top" "bottom" "left" "right")

         fig=dbCreateRect(cv M1PinLayer list(Ring_x0+PPNPEncOD:PRing_y0 Ring_x0+PPNPEncOD+PRing_y1-PRing_y0:PRing_y1))
         net=dbCreateNet(cv "VSS")
         dbCreateTerm(net "VSS" "inputOutput")
         dbCreateLabel(cv M1PinLayer Ring_x0+PPNPEncOD:(PRing_y1+PRing_y0)/2.0 "VSS" "centerLeft" "R0" "roman" Ring_Width)
         pin=dbCreatePin(net fig "VSS")
         pin~>AccessDir=list("top" "bottom" "left" "right")  
         ;Create  VDD&&VSS Pin 

         VDD_x0=(leftEdge(P_leftM1Box)+rightEdge(P_leftM1Box))/2.0
        VDD_x0=floor(VDD_x0/mfgGrid)*mfgGrid
        VDD_y0=bottomEdge(P_leftM1Box)
        VDD_x1=VDD_x0
        VDD_y1=NRing_y1
        dbCreatePath(cv M1Layer list(VDD_x0:VDD_y0 VDD_x1:VDD_y1) PathW)
    
        VSS_x0=(leftEdge(N_leftM1Box)+rightEdge(N_leftM1Box))/2.0
        VSS_x0=floor(VSS_x0/mfgGrid)*mfgGrid
        VSS_y0=topEdge(N_leftM1Box)
        VSS_x1=VSS_x0
        VSS_y1=PRing_y0
        dbCreatePath(cv M1Layer list(VSS_x0:VSS_y0 VSS_x1:VSS_y1) PathW)
        ;Create SD to VDD&&VSS Path
       


  
      RingLength=Ring_x1-Ring_x0
      COColumns=int((RingLength+COs-2*ODEncCO)/COp)  
    foreach(x list(list(Ring_x0 NRing_y0) list(Ring_x0 PRing_y0))       
            RingCO_y0=cadr(x)+ODEncCO
            for(i 0 COColumns-1
                RingCO_x0=car(x)+PPNPEncOD+ODEncCO+i*COp
                dbCreateRect(cv COLayer
                list(RingCO_x0:RingCO_y0 RingCO_x0+COw:RingCO_y0+COw))                                
                );for            
         );foreach
    ;Create CONT of Ring

      NRing_y0=PMosPPTop
      NRing_y1=NRing_y0+Ring_Width+PPNPEncOD * 2
      PRing_y1=NMosNPBot
      PRing_y0=NMosNPBot-Ring_Width-PPNPEncOD * 2

      for(num 0 0  
          foreach(x list(list(PPLayer "PRing_y")  list(NPLayer "NRing_y"))
             layer=car(x)
             y=cadr(x)
             dbCreateRect(cv layer
                 list(
                evalstring(artMakeString(concat("Ring_x"  num))):
                evalstring(artMakeString(concat(y    num)))
                
                evalstring(artMakeString(concat("Ring_x"  num+1))):
                evalstring(artMakeString(concat(y    num+1)))
                      )
                   )
                 );foreach
          );for
         ;Create PIMP/(NIMP && NWELL) layer of Ring

         );let

  );pdDefine
);proc
