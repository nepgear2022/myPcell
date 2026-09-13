pcDefinePCell(
  list(ddGetObj("zsytest") "MOMPcellver2" "layout")
  ; 参数列表
  (
    (fingerLength float 10.0)    ; 手指垂直方向高度
    (fingerWidth  float 1.5)     ; 手指水平方向宽度
    (fingerSpace  float 1.5)     
    (numFingers   int   10)      
    (busWidth     float 1.0)     ; 总线宽度（上下两条水平金属条的高度）
    (gap          float 0.29)     ; 手指与对面总线之间的间隙
  )
  let((cv totalWidth i x yA yB)
    cv = pcCellView              ; 获取当前 Pcell 的 cellView 对象

    totalWidth = (numFingers-1)*(fingerWidth+fingerSpace) + fingerWidth


    foreach(layernum list("5" "6")
      foreach(line list("busBotom" "TopBottom")
        if(line == "busBotom" then
            org = list(0 -busWidth)          ; 左下角位于 y = -busWidth(器件下方)
        else org = list(0 fingerLength)      ; 左下角位于 y = fingerLength（手指顶部）
        );End if 
        rodCreateRect(
              ?name   sprintf(nil "%s _M %s" line layernum   )
              ?cvId   cv
              ?layer  concat("METAL" layernum)
              ?width  totalWidth          ; 宽度 = 器件总宽度
              ?length busWidth            ; 高度 = 总线宽度
              ?origin org 
                )
      ); End foreach
    ); End foreach 生成M5、M6的顶部走线和底部走线

    ; ===== 循环生成每根手指 =====
    for(i 0 sub1(numFingers)  
      x = i*(fingerWidth+fingerSpace) ; 计算当前手指的 X 坐标
     
      if(evenp(i) then   ; 判断奇偶，决定手指属于哪一组，偶数连接底部
        yA = 0
        yB = fingerLength - gap    ; 手指顶端与顶部总线之间留 gap
      else
        ; 奇数索引 → B 组：连接顶部总线，底部留间隙
        yA = gap                   ; 手指底端与底部总线之间留 gap
        yB = fingerLength
      )

      foreach(layernum list("5" "6")
          rodCreateRect(
            ?name   sprintf(nil "finger_M%s_%d" layernum i)
            ?cvId   cv
            ?layer  sprintf(nil "METAL%s" layernum)
            ?width  fingerWidth
            ?length yB - yA            ; 手指高度（扣除间隙后）
            ?origin list(x yA)         ; 左下角坐标
          )
      )  ; 生成重合的M5、M6手指


      ; ----- VIA56 通孔阵列（连接 M5 和 M6）-----
      rodCreateRect(
        ?name      sprintf(nil "via_%d" i)
        ?cvId      cv
        ?layer     "VIA56"
        ?width     0.36             ; 通孔宽度
        ?length    0.36             ; 通孔长度
        ?origin    list(x + 0.57 yA + 0.57)  ; 左下角向内偏移 0.07（安全距离）
        ?elementsY floor((yB - yA - 1.14) / (0.34 + 0.34))
                    ; 垂直方向通孔数量 = 可用高度 / (通孔大小 + 通孔间距)
                    ; 0.14 = 上下各 0.07 的安全距离
        ?spaceY    0.34             ; 通孔在 Y 方向的间距
      )
    )
  )
)