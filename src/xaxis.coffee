QuandlismContext_.xaxis = () ->
  context     = @
  width       = context.w() * quandlism_xaxis.w
  height      = context.h() * quandlism_xaxis.h
  scale       = d3.time.scale().range [0, width]
  axis_       = d3.svg.axis().scale(scale)
  extent      = []
  active      = false
  lines       = []
  id          = null
  parseDate   = null
  
  
  xaxis = (selection) =>
    
    id = selection.attr 'id';      
    lines = selection.datum();
    
    axis_.tickSize 5, 3, 0
    
    update = () ->
      xaxis.remove()
      g = selection.append 'svg'
      g.attr 'width', width
      g.attr 'height', height
      g.append 'g'
      g.attr 'transform', 'translate(0, 27)'
      g.call(axis_)
      
    changeScale = () =>
      extent = [lines[0].dateAt(0), lines[0].dateAt(lines[0].length()-1)]
      parseDate = context.utility().parseDate(lines[0].dateAt(0))
      scale.domain [parseDate(extent[0][0]), parseDate(extent[0][1])]
      axis_.tickFormat d3.time.format('%b %d, %Y')
      axis_.ticks Math.floor width / 150, 0, 0
      scale.range [0, width]
      
    changeScale()
    update()

    # Event listneres
    
    # Respond to resizing browser by re-calucaling width and re-drawing
    context.on "respond.xaxis-#{id}", () ->
      width = context.w() * quandlism_xaxis.w
      axis_.ticks Math.floor width/ 150, 0, 0
      scale.range [0, width]
      update()

    # Respond to refresh event. Get new lines and redraw
    context.on "refresh.xaxis-#{id}", () ->
      lines = selection.datum()
      changeScale()
      update()

    # If xaxis is set to active, respond to adjsut event from brush by
    # recalculating extents and scales and re-drawing
    if active
      context.on "adjust.xaxis-#{id}", (x1, x2) ->
        x2 = if x2 > lines[0].length()-1 then lines[0].length()-1 else x2
        x1 = if x1 < 0 then 0 else x1
        extent = [lines[0].dateAt(x1), lines[0].dateAt(x2)]
        scale.domain [parseDate(extent[0][0]), parseDate(extent[0][1])]
        update()

      
    return

  # Expose attributes with getters/etters
  xaxis.remove = () =>
    d3.select("##{id}").selectAll("svg").remove();
    
  xaxis.active = (_) =>
    if not _ then return active
    active = _
    xaxis
    
  d3.rebind(xaxis, axis_, 'orient', 'ticks', 'ticksSubdivide', 'tickSize', 'tickPadding', 'tickFormat');
 