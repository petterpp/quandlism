QuandlismContext_.stage = () ->
  context     = @
  canvasId    = null
  canvasNode  = null
  lines       = []
  line        = null
  width       = Math.floor (context.w()-quandlism_yaxis_width-2)
  height      = Math.floor (context.h() * quandlism_stage.h)
  xScale      = d3.time.scale()
  yScale      = d3.scale.linear()
  ySecondScale = d3.scale.linear()
  xAxis       = d3.svg.axis().orient('bottom').scale xScale
  yAxis       = d3.svg.axis().orient('left').scale yScale
  ySecondAxis = d3.svg.axis().orient("right").scale ySecondScale
  extent      = []
  threshold   = 10
  dateStart   = null
  dateEnd     = null
  drawStart   = null
  drawEnd     = null
  indexStart  = null
  indexEnd    = null
  threshold   = 10
  canvas      = null
  ctx         = null
  
  
  stage = (selection) =>
        
    canvasId = "canvas-stage-#{++quandlism_id_ref}" if not canvasId?
    
    # Get lines and generate unique ID for the stage
    lines = selection.datum()
    line  = _.first lines
    selection.attr "style", "position: absolute; left: 0px; top: 0px;"
    
    # Build the yAxis
    # If no brush, dont calcualte stage height as percentage, use entire space
    yAxisDOM = selection.insert 'svg'
    yAxisDOM.attr 'class', 'y axis'
    yAxisDOM.attr 'id', "y-axis-#{canvasId}"
    yAxisDOM.attr 'width', quandlism_yaxis_width
    yAxisDOM.attr 'height', Math.floor (context.h() * quandlism_stage.h)
    yAxisDOM.attr "style", "position: absolute; left: 0px; top: 0px;"
    
    ySecondAxisDOM = selection.insert("svg")
    ySecondAxisDOM.attr "class", "y axis"
    ySecondAxisDOM.attr "id", "y-axis-" + canvasId
    ySecondAxisDOM.attr "width", quandlism_yaxis_width
    ySecondAxisDOM.attr "height", Math.floor(context.h() * quandlism_stage.h)
    ySecondAxisDOM.attr "style", "position: absolute; left: " + Math.floor(context.w()) + "px; top: 0px;"
    ySecondAxisDOM.selectAll("*").remove()  if context.utility().getExtent(lines, indexStart, indexEnd)[1][1] / context.utility().getExtent(lines, indexStart, indexEnd)[0][1] < 2

    # Create canvas element and get reference to drawing context
    canvas = selection.append 'canvas'
    canvas.attr 'width', width
    canvas.attr 'height', height
    canvas.attr 'class', 'canvas-stage'
    canvas.attr 'id', canvasId
    canvas.attr 'style', "position: absolute; left: #{quandlism_yaxis_width}px; top: 0px; border-left: 1px solid black; border-bottom: 1px solid black;"
    canvas.attr 'data-y_min', null
    canvas.attr 'data-y_max', null
  
    ctx = canvas.node().getContext '2d'
   
    # Build the xAxis
    xAxisDOM = selection.append 'svg'
    xAxisDOM.attr 'class', 'x axis'
    xAxisDOM.attr 'id', "x-axis-#{canvasId}"
    xAxisDOM.attr 'width',  Math.floor context.w()-quandlism_yaxis_width
    xAxisDOM.attr 'height', Math.floor context.h() * quandlism_xaxis.h
    xAxisDOM.attr 'style', "position: absolute; left: #{quandlism_yaxis_width}px; top: #{height}px"


    # Calculate the range and domain of the x and y scales
    setScales = () =>
      
      # Don't check user generated extents
      # If visible area of plot has equal extents, then try the entire plot
      # If those values are equal then put the line in the middle!
      unless context.yAxisMax() and context.yAxisMin()
        extent = context.utility().getExtent lines, indexStart, indexEnd
        extent = context.utility().getExtent lines, 0, line.length() unless extent[0][0] isnt extent[0][1]
        extent = [Math.floor(extent[0][0]/2), Math.floor(extent[0][0]*2)] unless extent[0][0] isnt extent[0][1]
      # Update the linear x and y scales with calculated extent
                 
      _yMin = context.yAxisMin()
      _yMax = context.yAxisMax()
      
      _yMin = null if _.isString(_yMin) and _.isEmpty(_yMin)
      _yMax = null if _.isString(_yMax) and _.isEmpty(_yMax)

      _yMin = _yMin ? extent[0][0] 
      _yMax = _yMax ? extent[0][1]
           
      # Set yvalues in context in the case of  calculated extent being used
      context.yAxisMin _yMin
      context.yAxisMax _yMax
      
      yScale.domain [_yMin, _yMax]
      yScale.range  [(height - context.padding()), context.padding()]

      yAxis.ticks Math.floor context.h()*quandlism_stage.h / 30
      yAxis.tickSize 5, 3, 0

      ySecondScale.domain [ extent[1][0], extent[1][1] ]
      ySecondScale.range [ height - context.padding(), context.padding() ]
      ySecondAxis.ticks Math.floor(context.h() * quandlism_stage.h / 30)
      ySecondAxis.tickSize 5, 3, 0

      # Build the yAxis tick formatting function
      unitsObj = context.utility().getUnitAndDivisor Math.round(extent[0][1])
      unitsSecondObj = context.utility().getUnitAndDivisor(Math.round(extent[1][1]))

      yAxis.tickFormat (d) =>
        n = (d/unitsObj['divisor']).toFixed 2
        n = n.replace(/0+$/, '')
        n = n.replace(/\.$/, '')
        "#{n}#{unitsObj['label']}"
        
      ySecondAxis.tickFormat (d) ->
        n = (d / unitsSecondObj["divisor"]).toFixed(2)
        n = n.replace(/0+$/, "")
        n = n.replace(/\.$/, "")
        "#{n}#{unitsSecondObj['label']}"
  
      xScale.domain [dateStart, dateEnd]
      xScale.range  [0, width]
      return
    
    # Draw axis
    drawAxis = () =>
      # Remove old yAxis and redraw
      yAxisDOM.selectAll('*').remove()
      yg = yAxisDOM.append 'g'
      yg.attr 'transform', "translate(#{quandlism_yaxis_width}, 0)"
      yg.call yAxis
      
      ySecondAxisDOM.selectAll("*").remove()
      canvas.attr "style", "position: absolute; left: " + quandlism_yaxis_width + "px; top: 0px; border-left: 1px solid black; border-bottom: 1px solid black;border-right: 1px solid black;"
      ygSecond = ySecondAxisDOM.append("g")
      ygSecond.attr "transform", "translate(1, 0)"
      ygSecond.call ySecondAxis
      if context.utility().getExtent(lines, indexStart, indexEnd)[1][1] / context.utility().getExtent(lines, indexStart, indexEnd)[0][1] < 2
        ySecondAxisDOM.selectAll("*").remove()
        canvas.attr "style", "position: absolute; left: " + quandlism_yaxis_width + "px; top: 0px; border-left: 1px solid black; border-bottom: 1px solid black;"

      xAxisDOM.selectAll('*').remove()
      xg = xAxisDOM.append 'g'
      xg.call xAxis
      
      # Remove axis path. We only want the numbers.
      xg.select('path').remove()
      yg.select('path').remove()
      
      return

    # Draw y and x grid lines
    drawGridLines = () =>
      for y in yScale.ticks Math.floor context.h()*quandlism_stage.h / 30
        ctx.beginPath()
        ctx.strokeStyle = '#EDEDED'
        ctx.lineWidth = 1
        ctx.moveTo 0, Math.floor yScale y
        ctx.lineTo width, Math.floor yScale y
        ctx.stroke()
        ctx.closePath()
        
      for x in xScale.ticks Math.floor (context.w()-quandlism_yaxis_width)/100
        ctx.beginPath()
        ctx.strokeStyle = '#EDEDED'
        ctx.lineWith = 1
        ctx.moveTo xScale(x), height
        ctx.lineTo xScale(x), 0
        ctx.stroke()
        ctx.closePath()
        
        
    # Draws the stage data
    #
    # lineId - The id of the line to be highlighted when drawing the lines (integer or null)
    draw = (lineId) =>
      lineId = lineId ? -1  
      # Refresh axis and gridlines
      drawAxis()
      ctx.clearRect 0, 0, width, height      
      drawGridLines()

      for line, j in lines   
        # calculate the line width to use (if we are on lineId)
        lineWidth = if j is lineId then 3 else 1.5
        if extent[1][1] / extent[0][1] > 2 and Math.abs(line.extent(indexStart, indexEnd)[1] - extent[1][1]) < Math.abs(line.extent(indexStart, indexEnd)[1] - extent[0][1])
          line.drawPathFromIndicies ctx, xScale, ySecondScale, indexStart, indexEnd, lineWidth
        else
          line.drawPathFromIndicies ctx, xScale, yScale, indexStart, indexEnd, lineWidth
        if ((indexEnd-indexStart) < threshold)
          line.drawPointAtIndex ctx, xScale, yScale, i, 2 for i in [indexStart..indexEnd]
          
        #line.drawPath ctx, xScale, yScale, dateStart, dateEnd, lineWidth
      return
      
    # Detects line hit
    # Analyzed color under the mouse cursor and try to match to a line
    #
    # m - The mouse position, in canvas space
    #
    # Returns false, or an object with keys x, color and line, if a match was found
    lineHit = (m) ->
      # Check for a direct match under cursor
      hex = context.utility().getPixelRGB m, ctx
      
      i = _.indexOf context.colorList(), hex
      return {x: m[0], color: hex, line: lines[i] } if i isnt -1

      # If no match, check the immediate area for fuzzy matching
      hitMatrix = []
      for j in [m[0]-3..m[0]+3]
        for k in [m[1]-3..m[1]+3]
          if j isnt m[0] or k isnt m[1]
            hitMatrix.push [j, k]
            
      for n in [0..(hitMatrix.length-1)]
        hex = context.utility().getPixelRGB hitMatrix[n], ctx
        i = _.indexOf context.colorList(), hex
        return {x: hitMatrix[n][0], color: hex, line: lines[i]} if i isnt -1
      false
      
    # Render the tooltip data, from a mouseover event on a line, and highlight the moused over point
    #
    # locq  - Mouse location
    # x     - The x index of the data point
    # line  - The line that was highlighted
    # hex   - The color
    # 
    # Returns null
    drawTooltip = (loc, hit, dataIndex) =>
      # Draw the line with the point highlighted
      line_ = hit.line
      date  = line_.dateAt(dataIndex)
      value = line_.valueAt(dataIndex)
      draw line_.id()
      if extent[1][1] / extent[0][1] > 2 and Math.abs(line_.extent(indexStart, indexEnd)[1] - extent[1][1]) < Math.abs(line_.extent(indexStart, indexEnd)[1] - extent[0][1])
        line_.drawPointAtIndex ctx, xScale, ySecondScale, dataIndex, 3
      else
        line_.drawPointAtIndex ctx, xScale, yScale, dataIndex, 3  

      # In toolip container?
      inTooltip = loc[1] <= 20 and loc[0] >= (width-250)
      w = if inTooltip then width-400 else width
      # Container
      ctx.beginPath()
      ctx.fillStyle = 'rgba(237, 237, 237, 0.80)'
      ctx.fillRect w-240, 0, 240, 15
      ctx.closePath()
      # Value
      ctx.fillStyle = '#000'
      ctx.textAlign = 'start'
      tooltipText = "#{context.utility().getMonthName date.getUTCMonth()}  #{date.getUTCDate()}, #{date.getFullYear()}: "
      tooltipText += "#{context.utility().formatNumberAsString value.toFixed 2}"
      ctx.fillText tooltipText, w-110, 10, 100
      # Line Name
      ctx.fillStyle = line_.color()
      ctx.textAlign = 'end'
      ctx.fillText "#{context.utility().truncate line_.name(), 20}", w-120, 10, 200

      return
      
      
    # Remove toolitp data and graph highlighting
    clearTooltip = () ->
      draw()
      return
      

    # Intial draw. If there is a brush in the context, it will dispatch the adjust event and force the 
    # stage to draw. If there isn't, force the stage to draw
    #
    unless context.dombrush()?
      dateStart = _.first lines[0].dates()
      dateEnd = _.last lines[0].dates()
      indexStart = 0
      indexEnd   = line.length()
      setScales()
      draw()

    # Callbacks / Event bindings
    # Listen for events dispatched from context, or listen for events in canvas
  
    # Respond to page resize
    # Resize, clear and re-draw
    context.on 'respond.stage', () ->
      ctx.clearRect 0, 0, width, height
      width = Math.floor (context.w()-quandlism_yaxis_width-1)
      height = Math.floor (context.h() * quandlism_stage.h)
      canvas.attr 'width', width
      canvas.attr 'height', height
      
      # Adjust y axis width
      yAxisDOM.attr 'width', quandlism_yaxis_width
      
      # Adjust x axis with and marign
      xAxisDOM.attr 'width',  Math.floor context.w() - quandlism_yaxis_width
      xAxisDOM.attr 'height', Math.floor context.utility().xAxisHeight()
      ySecondAxisDOM.attr "style", "position: absolute; left: " + Math.floor(context.w()) + "px; top: 0px;"
      setScales()
      draw()
      return
 
    # Respond to adjsut events from the brush
    context.on 'adjust.stage', (_dateStart, _indexStart, _dateEnd, _indexEnd) ->
      indexStart  = _indexStart
      indexEnd    = _indexEnd
      dateStart   = _dateStart
      dateEnd     = _dateEnd
      setScales()
      draw()
      return
      
    # Respond to toggle event by re-drawing
    context.on 'toggle.stage', () ->
      context.resetState() unless context.dombrush()
      setScales()
      draw()
      return
      
    # Respond to refresh event. Update line data and re-draw
    context.on 'refresh.stage', () ->
      lines = selection.datum()
      line  = _.first lines
      # Only draw if there is no brush to dispatch the adjust event
      draw() if not context.dombrush()      
      return
      
    d3.select("##{canvasId}").on 'mousemove', (e) ->
      loc = d3.mouse @
      hit = lineHit loc
      dataIndex =  hit.line.getClosestIndex(xScale.invert(hit.x)) if hit      
      if hit isnt false then drawTooltip loc, hit, dataIndex else clearTooltip()
      return
 
    return
    
    

    
  # Expose attributes via getters/setters
  stage.canvasId = (_) =>
    if not _? then return canvasId
    canvasId = _
    stage
    
  stage.xScale = (_) =>
    if not _? then return xScale
    xScale = _
    stage
    
  stage.yScale = (_) =>
    if not _? then return yScale
    yScale = _
    stage
    
  stage.threshold = (_) =>
    if not _? then return threshold
    threshold = _
    stage
    
  stage