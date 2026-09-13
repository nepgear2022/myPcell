pcDefinePCell(
  list(ddGetObj("zsytest") "OctIND2" "layout")   ; 指定库和单元名
  (
    (metal   "METAL5")         ; 参数：金属层，默认 METAL5
    (Pw   10.0)                ; 参数：走线宽度 (Path Width)
    (Ps   5.0)                 ; 参数：匝间间距 (Path Spacing)
    (l   65.0)                 ;
    (turns   3)                ; 参数：匝数
    (sides   7)                ; 参数：多边形边数（8 表示八边形）
    (PathExtend  37.0)         ; 参数：外部引出线延伸长度
    (InnerCross t)             ; 参数：是否在中心添加十字连接
    (tap t)
    )
    
  let((cv step pi angel angel1 x x0 y y0 l1)
    cv = pcCellView            ; 获取当前 cellview
    pi = 4*atan(1)             ; 圆周率 π
    angel1 = 0.0               ; 初始角度
    angel = 2*pi/sides
    step  = (Pw + Ps) / sides  ; 每段径向增量，将螺距分配到每个边
    x0 = 0.0
    y0 = 0.0
    point= list()
    l1=l

       for(k 1 turns*sides+fix(sides/2)+1
       x = x0 + l1*cos(angel1)
       y = y0 + l1*sin(angel1)
       x= round(x*100.0)/100.0
       y= round(y*100.0)/100.0
       point= append1(point x:y)
       l1=l1+step
       angel1=angel1+angel
       )
    
    lastpoint =car(last(point))
    xlastpoint1 = car(lastpoint)
    xlastpoint2 = car(lastpoint)-PathExtend

    point= append1(point xlastpoint1:0)
    point= append1(point xlastpoint2:0)
    
    if(InnerCross == t 
    then
      point = append(list(0:0) point)   ; 添加原点
    Path1=rodCreateRect(                      ;原点接触孔
        ?cvId   cv
        ?layer "METAL5"
        ?width  Pw
        ?length Pw
        ?origin 0:-Pw/2
        ?subRectArray
            list(
                list(
                ?layer "CONT"
                ?width 2.0
                ?length 2.0
                ?gap "distribute"                    ; 均匀分布
                ?lowerLeftOffsetX 0.30
                ?lowerLeftOffsetY 0.30
                ?upperRightOffsetX -0.3
                ?upperRightOffsetY -0.3
                ?spaceX            0.5
                ?spaceY            0.5 )))
    Path2=rodCreateRect(                      ;外面接触孔
        ?cvId   cv
        ?layer "METAL5"
        ?width  Pw
        ?length Pw
        ?origin xlastpoint2:-Pw/2
        ?subRectArray
            list(
                list(
                ?layer "CONT"
                ?width 2.0
                ?length 2.0
                ?gap "distribute"                    ; 均匀分布
                ?lowerLeftOffsetX 0.30
                ?lowerLeftOffsetY 0.30
                ?upperRightOffsetX -0.3
                ?upperRightOffsetY -0.3
                ?spaceX            0.5
                ?spaceY            0.5 )))
    )

    dbCreatePath(
      cv
      metal
      point
      Pw)

    
     if( tap == t
     then
     maxX = apply('max, mapcar('car point))  
     minX= xlastpoint2
     maxY = apply('max, mapcar('cadr point)) 
     minY = apply('min, mapcar('cadr point)) 
     rodCreatePath(
      ?layer "METAL1"
      ?width 5
      ?pts list(0:minY-3*Pw
                minX-3*Pw:minY-3*Pw 
                minX-3*Pw:maxY+3*Pw 
                maxX+3*Pw:maxY+3*Pw 
                maxX+3*Pw:minY-3*Pw 
                0:minY-3*Pw)
      ?subRect  list(
                list(?layer "CONT"
                     ?width 3.0
                     ?length 3.0
                     ?gap "distribute"               ; 沿路径均匀分布
                     ?beginOffset 0.5               ; 路径起点偏移
                     ?endOffset 0.5                 ; 路径终点偏移
                     ?space 0.5     ))                 ; 孔间距
                 )
         )

        
    ) ;End of let
)

;-------------------CDF parameter----------
;let((libId cellId cdfId)
;       unless(cellId = ddGetObj("zsytest" "OctIND2")  ; 获取cell对象
;            error("Could not get cell %s." "OctIND2"))
;   cdfId = cdfGetBaseCellCDF(cellId)          ; 获取已有CDF
;   when(cdfId cdfDeleteCDF(cdfId))            ; 如果存在，先删除
;        cdfId = cdfCreateBaseCellCDF(cellId)       ; 创建新基础CDF
;    cdfCreateParam(cdfId
;    ?name "InnerCross"
;    ?prompt "Inner Cross"
;    ?type "boolean"
;    ?defValue   t
;    ?display "t"
;    ?editable "t"  )
;    
;    cdfCreateParam(cdfId
;    ?name "tap"
;    ?prompt "tap"
;    ?type "boolean"
;    ?defValue   t
;    ?display "t"
;    ?editable "t" )
;)

