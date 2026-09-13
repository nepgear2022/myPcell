pcDefinePCell(
   list(ddGetObj("zsytest") "NmosFig2" "layout")  
       (                                          
        (l "0.32u")                                ; 沟道长度
        (w "2.0u")                                ; 沟道宽度
        (Fig 3)
        (ConnVSS t)
       )
    let(((cv pcCellView))  
      l=evalstring(l)*1e6 
      w=evalstring(w)*1e6
    SDwidth=0.54
    ;------------ 1. 栅极 (POLY1) ------------
    Gate=rodCreateRect(
        ?cvId   cv
        ?layer "POLY1"
        ?width  a=w+2*0.22
        ?length l
        ?origin a/(-2):(Fig*l+(Fig-1)*SDwidth)/(-2)          ; 中心对称
        ?elementsY Fig
        ?spaceY SDwidth
            )

    ;------------ 2. 有源区 (DIFF) ------------
    DIFF=rodCreateRect(
        ?cvId   cv
        ?layer "DIFF"
        ?width  w
        ?length Fig*l+(Fig+1)*SDwidth
        ?origin w/(-2):(Fig*l+(Fig+1)*SDwidth)/(-2)         ; 偏移对齐
            )

    ;------------ 3. 源漏金属 + 接触孔阵列 ------------
   SDPath=rodCreateRect(
        ?cvId   cv
        ?layer "METAL1"
        ?width w
        ?length SDwidth
        ?origin w/(-2):((Fig+1)*SDwidth+Fig*l)/(-2)
        ?elementsY Fig+1
        ?spaceY l
        ?subRectArray  list( list(
                ?layer "CONT"
                ?width 0.22
                ?length 0.22
                ?gap "distribute"                    ; 均匀分布
                ?lowerLeftOffsetX 0.10
                ?lowerLeftOffsetY 0.10
                ?upperRightOffsetX -0.1
                ?upperRightOffsetY -0.1
                ?spaceX            0.3
                ?spaceY            0.3        ));End ofsubRectArray
        );End of SD path
    ; 4 NIMP
    NIMP=rodCreateRect(
            ?cvId  cv
            ?layer "NIMP"
            ?fromObj DIFF                            ; 基于DIFF扩展
            ?size 0.40
                     )
    ;5 finger标签、连接
let((i y y0 x0)
    y0 = ((Fig+1)*SDwidth + Fig*l)/(-2)
    for(i 0 Fig
       y = y0 + (SDwidth+l)*i
       if(evenp(i) then
           dbCreateLabel(cv "TEXT" 0:y+SDwidth/2 "S" "centerCenter" "R0" "roman" SDwidth/4)   ;S标签
           
       else 
           dbCreateLabel(cv "TEXT" 0:y+SDwidth/2 "D" "centerCenter" "R0" "roman" SDwidth/4) )  ;D标签
        
);end if
;    if(ConnVSS == t then
;    tf          = techGetTechFile(cv)                     ; 获取技术文件
;   PPNPEncOD   = techGetSpacingRule(tf "minEnclosure" "PIMP" "DIFF")     ; PIMP 包覆 DIFF
;       for(i 0 Fig
;           y = y0 + (SDwidth+l)*i
;         if(evenp(i) then
;            dbCreatePath(
;            cv
;            "METAL2"
;            list((w/(-2))-1:y+SDwidth/2 w/2:y+SDwidth/2)
;            0.3   ;略宽于接触孔
;            )
;         );End if
;
;       ) ;End for
;       VSSpath = rodCreatePath(
;           ?cvId cv
;           ?layer "METAL2"
;           ?pts list((w/(-2))-1.0:y0-0.5+SDwidth/2 w/(-2)-1.0:-(y0-0.5+SDwidth/2))
;           ?width 0.5
;           ?pin t
;           ?pinAccessDir list("top" "bottom" "left" "right")
;           ?termName "VSS"
;           ?subRect  list( list(
;               ?layer "CONT"
;               ?width 0.22
;               ?length 0.22
;               ?gap "distribute"           
;               ?beginOffset -0.35
;               ?endOffset -0.35
;               ?space            0.3      ));End ofsubRectArray
;           )
;       dbCreateLabel(cv "TEXT" (w/(-2))-1.0:y0-0.5+SDwidth/2 "VSS" "centerLeft" "R90" "roman" 0.3) ;  VSS Label
;       VSSRing = rodCreateRect(
;       ?cvId  cv
;       ?layer "PIMP"
;       ?fromObj VSSpath
;       ?size PPNPEncOD
;       )
;
;   ) ;End if S接VSS



);end let

);end line10 let
);end of all

;============================================================
; CDF 参数面板注册部分
;============================================================
   let((libId cellId cdfId)
        unless(cellId = ddGetObj("zsytest" "NmosFig")  ; 获取cell对象
              error("Could not get cell %s." "NmosFig")
                     )
            cdfId = cdfGetBaseCellCDF(cellId)          ; 获取已有CDF
            when(cdfId cdfDeleteCDF(cdfId))            ; 如果存在，先删除
            cdfId = cdfCreateBaseCellCDF(cellId)       ; 创建新基础CDF
            cdfCreateParam(cdfId
                ?name "l"
                ?prompt "Length(M)"
                ?units "lengthMetric"                  ; 单位类型：长度
                ?defValue "0.18u"
                ?type "string"                         ; 字符串类型
                ?display "t"
                ?editable "t"
                ?parseAsNumber "yes"                   ; 解析为数字
                ?parseAsCEL "yes"
                ?storeDefault "no"
                          )
            cdfCreateParam(cdfId
                ?name "w"
                ?prompt "Width(M)"
                ?units "lengthMetric"
                ?defValue "2.0u"
                ?type "string"
                ?display "t"
                ?editable "t"
                ?parseAsNumber "yes"
                ?parseAsCEL "yes"
                ?storeDefault "no"
                           )
            cdfCreateParam(cdfId
                ?name "ConnVSS"
                ?prompt "ConnVSS"
                ?defValue t
                ?type "boolean"                          ;
                ?display "t"
                ?editable "t"
                           )
            cdfSaveCDF(cdfId)                           ; 保存CDF
       )





