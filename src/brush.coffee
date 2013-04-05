QuandlismContext_.brush = () ->
  context       = @
  height        = Math.floor context.h()*quandlism_brush.h
  width         = Math.floor context.w()-quandlism_yaxis_width
  dateStart = dateEnd = drawStart = drawEnd = line = null
  dragging = dragEnabled = stretching = touchPoint = null
  canvas = ctx = canvasId = brushId = null
  extent = lines = []
  xScale        = d3.time.scale()
  yScale        = d3.scale.linear()
  xAxis         = d3.svg.axis().orient('bottom').scale xScale  
  threshold     = 10
  handleWidth   = 10
  stretchLimit  = 6
  stertchhMin   = 100
  activeHandle  = 0
  buffer        = document.createElement('canvas')
  useCache      = false
  previous      = {}

  brush = (selection) =>
    canvasId = "canvas-brush-#{++quandlism_id_ref}" if not canvasId?

    # For convenience, use refernce to first line
    lines = selection.datum()
    line  = _.first lines
    
    # Extract the default start and end dates
    dateStart = _.first line.dates()
    dateEnd   = _.last  line.dates()
    
    # Apply CSS to selection
    selection.attr "style", "position: absolute; top: #{context.h()*(quandlism_stage.h+quandlism_xaxis.h)}px; left: #{quandlism_yaxis_width}px"
    # append canvas and get reference to element and drawing context
    canvas = selection.append('canvas')
    canvas.attr 'id', canvasId
    canvas.attr 'class', 'canvas-brush'
    canvas.attr "style", "position: absolute; left: 0px; top: 0px; border-bottom: 1px solid black;"
    ctx = canvas.node().getContext '2d'
    
    # xAxis
    xAxisDOM = selection.append 'svg'
    xAxisDOM.attr 'class', 'x axis'
    xAxisDOM.attr 'id', "x-axis-#{canvasId}"
    xAxisDOM.attr 'height', Math.floor context.h()*quandlism_xaxis.h
    xAxisDOM.attr 'width', Math.floor context.w()-quandlism_yaxis_width
    xAxisDOM.attr "style", "position: absolute; top: #{context.h()*quandlism_brush.h}px; left: 0px"
    
  
    

    # Determines if the there are enough points that in the dataset
    # to allow dragging. If not, set the start and width of the brush
    # to fill the entire canvas context
    #
    # Returns null
    checkDragState = () =>
      if (line.length()) <= stretchLimit
        dateStart = _.first line.dates()
        dateEnd   = _.last  line.dates()
        drawStart = xScale dateStart
        drawEnd   = xScale dateEnd
        dragEnabled = false
      else
        dragEnabled = true
    
    # Calculate the y and x scales. Sets the domain and ranges of the
    # scales and creates the x axis labelling functions
    # 
    # Returns null
    setScales = () =>
      yScale.domain context.utility().getBrushExtent lines, null, null 
      yScale.range [height-context.padding(), context.padding()]

      xScale.range [context.padding(), width-context.padding()]
      xScale.domain [_.first(line.dates()), _.last(line.dates())]
      
      return
    
    # Calculates variables needed for drawing the brush (start, width)
    # and re-calculates if the values are below the minimum allowed 
    #
    # Returns null
    setBrushValues = () =>
      # Set the date and x-value of the date, for the endpoints
      dateStart = line.dateAt Math.floor(context.startPoint()*line.length())
      dateEnd   = _.last line.dates()
      drawStart = xScale dateStart 
      drawEnd   = xScale dateEnd
      setPrevious 'dateStart', dateStart
      setPrevious 'dateEnd', dateEnd
      setPrevious 'drawStart', drawStart
      setPrevious 'drawEnd', drawEnd
      return
      
    # Update function drives the brush element. This is called on invertal
    # Clears the canvas and draws the lines and control
    #
    # Returns null
    update = () =>
      clearCanvas()
      if useCache then drawFromCache() else draw()
      drawBrush()
      return
      
    # Wipes the drawing context of the canvas
    # Clears the width and height of the preivously drawn area and sets
    # the height and width of the DOM element to the new height and width
    #
    # Returns null
    clearCanvas = () =>
      ctx.clearRect 0, 0, getPrevious('width'), getPrevious('height')
      canvas.attr('width', width).attr('height', height)
      return
      
    # Removes the current xaxis, if it exists, and draws the xaxis by calling
    # the xAxis function on the SVG selction
    #
    # Returns null
    drawAxis = () =>
      xAxisDOM.selectAll('*').remove()
      xg = xAxisDOM.append 'g'
      xg.call xAxis
      # Remove the drawn axis path. We only want the numbers
      xg.select('path').remove()
      return
       
    # Draws the path of each line of the dataset, and the points, if the dataset has few rows
    #
    # Returns null
    draw = () =>
      line.drawPath ctx, xScale, yScale, 1     for line, j in lines
      line.drawPoints ctx, xScale, yScale, _.first(line.dates(), _.last(line.dates()), 3)   if (line.length() <= threshold)
      saveCanvasData()
      return
      
    # Don't redraw the brush. Just use the saved image
    drawFromCache = () =>
      ctx.drawImage buffer.canvas, 0, 0
      return
      
    # Save the canvas state as an image for easy re-drawing
    saveCanvasData = () =>
      useCache = true      
      buffer.setAttribute 'width', width
      buffer.setAttribute 'height', height
      buffer = buffer.getContext('2d')
      buffer.drawImage document.getElementById(canvasId), 0, 0
      return
    
    # Uses the xStart, handleWidth and brushWidth variables to draw the 
    # the brush control on the canvas context 
    #
    # Returns null
    drawBrush = () =>
      ctx.strokeStyle = 'rgba(237, 237, 237, 0.80)'
      ctx.beginPath()
      ctx.fillStyle = 'rgba(237, 237, 237, 0.80)'
      ctx.fillRect drawStart, 0, (drawEnd-drawStart), height
      ctx.closePath()
    
      ctx.beginPath()
      ctx.fillStyle = '#D9D9D9'
      ctx.fillRect drawStart-handleWidth, 0, handleWidth, height
      ctx.closePath()
      
      ctx.beginPath()
      ctx.fillStyle = '#D9D9D9'
      ctx.fillRect drawEnd, 0, handleWidth, height
      ctx.closePath()
      return
        
    # Resets the buffer element and sets useCache to be false
    #
    removeCache = () =>
      buffer = document.createElement('canvas')
      useCache = false
      return
        
    # Send the new start and end dates that should be rendered on the sage
    # triggers the context.adjust event with those parameters
    #
    # calculateDates - Re-calcualte date end points before dispatching?
    # Returns null
    dispatchAdjust = (calculateDates) =>
      calculateDates = calculateDates ? false
      if calculateDates
        dateStart = xScale.invert drawStart
        dateEnd   = xScale.invert drawEnd
        # If dateStart > dateEnd, handles were inverted, so 
        # reverse order of dispatch
        if dateStart > dateEnd
          d = dateEnd
          dateEnd = dateStart
          dateStart = d
        
      # Before dispatching to stage, reset the y min and max 
      startVal = line.getClosestIndex(dateStart)
      endVal = line.getClosestIndex(dateEnd)
      context.adjust line.dateAt(startVal), startVal, line.dateAt(endVal), endVal
      return
      
    # Resets the state of the brush control
    # Sets dragging and stretching to to false and saves the xStart and brushWidth values
    #
    # Returns null
    saveState = () =>
      dragging = false
      stretching = false
      activeHandle = 0
      # If drawStart > drawEnd, handles were inverted,so flip values 
      if drawStart > drawEnd
          d = drawEnd
          drawEnd = drawStart
          drawStart = d
      dateStart = xScale.invert drawStart
      dateEnd   = xScale.invert drawEnd
      setPrevious 'drawStart', drawStart
      setPrevious 'dateStart', dateStart
      setPrevious 'drawEnd', drawEnd
      setPrevious 'dateEnd', dateEnd
      return
      
      
    # Determines if the mouse cursor location corresponds to the draggable portion of the brush control
    #
    # x - The x coordinate of the mouse cursor
    # 
    # Returns boolean
    isDraggingLocation = (x) =>
      x <= (drawEnd) and x >= drawStart

    # Determines if the mouse cursor location corresponds to the left handle of the brush control
    #
    # x - The x coordinate of the mouse cursor
    # 
    # Returns boolean      
    isLeftHandle = (x) =>
      x >= (drawStart-handleWidth) and x < (drawStart)

    # Determines if the mouse cursor location corresponds to the right handle of the brush control
    #
    # x - The x coordinate of the mouse cursor
    # 
    # Returns boolean      
    isRightHandle = (x) =>
      x > drawEnd and x <= (drawEnd + handleWidth)
    
      
    # Add classes to the brush
    # Removes any of the clases, defined in 'classes' variable before appending className
    setBrushClass = (className) =>
      document.getElementById("#{context.dombrush().substring(1)}").className = className
      return
      
    setPrevious = (key, value) =>
      previous[key] = value
      return
      
    getPrevious = (key) =>
      previous[key] ? null  
    
    # Save intial values of height and width
    setPrevious 'width', width
    setPrevious 'height', height
     
    #  
    # Intial drawing of brush
    #
    setScales()
    checkDragState()
    setBrushValues() if dragEnabled
    drawAxis()
    dispatchAdjust()
        
    # Set drawing interval
    setInterval update, 70
 

    # Event listners
  
    # Respond to resized browser by recalculating key points and redrawing
    context.on "respond.brush", () ->
      setPrevious 'height', height
      setPrevious 'width', width
      height = Math.floor context.h()*quandlism_brush.h
      width = Math.floor context.w()-quandlism_yaxis_width
      removeCache()
      setScales()
      drawStart = xScale dateStart
      drawEnd   = xScale dateEnd
      saveState()
      xAxisDOM.attr 'width', width
      drawAxis()
      return
      
    # Respond to refresh event
    context.on 'refresh.brush', () ->
      # Check for stage only
      return if _.has(context.options(), 'stage_only') and context.options().stage_only is true
      lines = selection.datum()
      line  = _.first lines
      removeCache()
      setScales()
      checkDragState()
      setBrushValues() if dragEnabled
      drawAxis()
      dispatchAdjust()
      return
      
      
    # Respond to toggle by re-setting extents to account for newly hidden or visible columns
    # And redrawing the brush backgorund
    context.on "toggle.brush", () ->
      context.resetState()
      removeCache()
      setScales()
      dispatchAdjust()
      return
      
    # Listen for mousedown event to track mouse clicks before dragging or stretching control
    canvas.on 'mousedown', (e) ->
      d3.event.preventDefault()
      m = d3.mouse @
      touchPoint = m[0]
      
      if isLeftHandle m[0]
        # If click on left handle
        stretching = true
        activeHandle = -1
      else if isRightHandle m[0]
        # If click on right handle
        stretching = true
        activeHandle = 1
      else if isDraggingLocation m[0]
        # if dragging
        dragging = true
        
      return
        
    # On mouseup save the new state of the control
    canvas.on 'mouseup', (e) ->
      context.resetState() # reset the state on explicit user event
      dispatchAdjust(true)
      saveState()
      return
      
    # Detect movement off of the canvas. Reset state
    canvas.on 'mouseout', (e) ->
      dispatchAdjust(true)
      setBrushClass ''
      saveState()  
      return
    
    # On double click expand brush
    canvas.on "dblclick", (e) ->
      d3.event.preventDefault()
      m = d3.mouse(this)
      touchPoint = m[0]
      if isDraggingLocation(m[0]) or isLeftHandle(m[0]) or isRightHandle(m[0])
        dateStart = _.first(line.dates())
        dateEnd = _.last(line.dates())
        drawStart = xScale(dateStart)
        drawEnd = xScale(dateEnd)
        context.toggle()
        return

    # Calculate various points for animating dragging and stretching
    canvas.on 'mousemove', (e) ->
      m = d3.mouse @
      if dragging or stretching
        dragDiff = m[0]-touchPoint
        if dragging and dragEnabled
          drawStart = getPrevious('drawStart') + dragDiff
          drawEnd   = getPrevious('drawEnd') + dragDiff
          
        else if stretching
          # Calculate new brushWidth and xStart values, ensuring the the brush does not have a width less than stretchMin
          throw "Error: Unknown stretching direction" if activeHandle not in [0, -1, 1]
          drawStart = getPrevious('drawStart') + dragDiff if activeHandle is -1
          drawEnd   = getPrevious('drawEnd') + dragDiff   if activeHandle is 1
          # If brush has been moved, remove any transformations on the stage of the graph (ie. y axis changes)
               
        # Fix drawStart and drawEnd to constrain to dimensions
        drawStart = if drawStart < 0 then 0 else drawStart
        drawEnd   = if drawEnd > width then width else drawEnd
        
      else if dragEnabled
        if isDraggingLocation m[0]
          setBrushClass 'move'
        else if isLeftHandle(m[0]) or isRightHandle(m[0])
          setBrushClass 'resize'
        else
          setBrushClass ''
      return

  # 
  # Getters and setters
  #  
  brush.canvasId = (_) =>
    if not _? then return canvasId
    canvasId = _
    brush
  
  brush.xScale = (_) =>
    if not _? then return xScale
    xScale = _
    brush
    
  brush.yScale = (_) =>
    if not _? then return yScale
    yScale = _
    brush
    
  brush.threshold = (_) =>
    if not _? then return threshold
    threshold = _
    brush
    
  brush.stretchLimit = (_) =>
    if not _? then return stretchLimit
    stretchLimit = _
    brush
    
  brush.handleWidth = (_) =>
    if not _? then return handleWidth
    handleWidth = _
    brush
    
  
  brush
      