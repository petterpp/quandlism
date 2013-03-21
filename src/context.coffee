   
quandlism.context = () ->
  context       = new QuandlismContext()
  w             = null
  h             = null
  dom           = null
  domstage      = null
  dombrush      = null
  domlegend     = null
  domtooltip    = null
  yAxisMin      = null
  yAxisMax      = null
  padding       = 10 
  startPoint    = 0.70
  event         = d3.dispatch('respond', 'adjust', 'toggle', 'refresh')
  colorList     = ['#e88033', '#4eb15d', '#c45199', '#6698cb', '#6c904c', '#e9563b', '#9b506f', '#d2c761', '#4166b0', '#44b1ae']
  lines         = []
  processes     = ["BUILD", "MERGE"]  
  callbacks     = {}
  options       = {}


  context.addCallback = (event, fn) ->
    return unless event? and _.isFunction(fn)
    callbacks["#{event}"] = []  unless callbacks["#{event}"]?
    callbacks["#{event}"].push fn
    return
    
  context.runCallbacks = (event) ->    
    return unless callbacks["#{event}"]? and callbacks["#{event}"].length
    callback() for callback in callbacks["#{event}"]
    return
    
    
  # Attach Data
  # Conveneince method for attaching lines datum for each declared DOM element
  context.data = (attributes, process = "build") =>    
    throw "Unknown process #{process}" unless process? and process.toUpperCase() in processes
    context.extractArguments attributes
    context.executeOptions options
    lines = context.utility()["#{process.toLowerCase()}Lines"](attributes, lines ? null)
    lines = context.utility().processLines(attributes, lines)     
    context.bindToElements()
    context.runCallbacks process
    context
    
  context.bindToElements = () =>
    d3.select(domstage).datum lines if domstage
    d3.select(dombrush).datum lines if dombrush
    d3.select(domlegend).datum lines if domlegend
    context
    
  # Extract optional quandlism parameters and execute assignment and calculation
  context.extractArguments = (attributes) =>
    for attr, value of attributes
      switch attr
        when "y_axis_min" then context.yAxisMin(value)
        when "y_axis_max" then context.yAxisMax(value)
    return

  # render
  # Conveneince method for calling method for each declared DOM element
  context.render = () =>
    context.build()
    d3.select(domstage).call context.stage() if domstage
    d3.select(dombrush).call context.brush() if dombrush
    d3.select(domlegend).call context.legend() if domlegend 
    context.respond()
    context
  
  
  # Convenience method for calling functions needed to update and redraw quandlism
  context.update = (options = {}) =>
    context.build()
    context.respond()
    context.refresh()
    context.runCallbacks 'update'
    context
  
  # use jQuery to get height and width of context container  
  context.build = () =>
    w = $(dom).width() - 50
    h = $(dom).height()
    context
  
  # Build the stage and brush elements using the container
  context.chart = (container, brush_) =>
    throw 'Invalid container' unless container.length
    brush = brush_ ? true
    # Add ID to container if not present
    container.children().remove()
    container.attr('id', "quandlism-#{++quandlism_id_ref}") if not container.attr('id')?
    dom = "##{container.attr('id')}"
    stageId = "quandlism-stage-#{++quandlism_id_ref}"
    container.append "<div class='stage' id='#{stageId}'></div>"
    domstage = "##{stageId}"
    if brush
      brushId = "quandlism-brush-#{++quandlism_id_ref}"
      container.append "<div class='brush' id='#{brushId}'></div>"
      dombrush = "##{brushId}"
    context  

  # Builds the legend elements with the given container
  context.withLegend = (container) =>
    throw 'Invalid container' if not container.length
    container.attr('id', "quandlism-legend-#{++quandlism_id_ref}") if not container.attr('id')
    domlegend = "##{container.attr('id')}"
    context

  # If the number of lines exceeds the size of colorList, increase the number of stored hex codes
  # by applying functions to the existing codes until there are lines.length number of unique codes
  context.addColorsIfNecessary = (lines_) =>
    colorsNeeded = lines_.length-colorList.length
    return if colorsNeeded < 0
    brightness = 0.1
    i = 0
    while i < colorsNeeded
      rgb = d3.rgb(colorList[i]).brighter brightness
      colorList.push rgb.toString()
      i++
    return   
    
  # Execute executable options!
  context.executeOptions = (options) ->
    for opt, value of options
      switch opt 
        when "reset" 
          if value is true
            context.resetState()
    context
  
    
  # Reset any transformations on the data
  context.resetState = ->
    yAxisMin = yAxisMax = null
    return
    
  # Expose attributes via getters and settesr
  context.lines = (_) =>
    if not _ then return lines
    lines = _
    context
    
  context.colorList = (_) =>
    if not _? then return colorList
    colorList = _
    context
  
  context.startPoint = (_) =>
    if not _? then return startPoint
    startPoint = _
    context
    
    
  context.options = (_) =>
    if not _? then return options
    options = _
    context
    
  context.w = (_) =>
    if not _? then return w
    w = _
    context
    
  context.h = (_) =>
    if not _? then return h
    h = _
    context
    
  context.yAxisMin = (_) =>
    if not _? then return yAxisMin
    yAxisMin = _
    context
    
  context.yAxisMax = (_) =>
    if not _? then return yAxisMax
    yAxisMax = _
    context
    
  context.dom = (_) =>
    if not _? then return dom
    dom = _
    context
    
  context.domstage = (_) =>
    if not _? then return domstage
    domstage = _
    context
    
  context.dombrush = (_) =>
    if not _? then return dombrush
    dombrush = _
    context
    
  context.domlegend = (_) =>
    if not _? then return domlegend
    domlegend = _
    context
    
  context.padding = (_) =>
    if not _? then return padding
    padding = _
    context
    
  context.callbacks = (_) =>
    if not _? then return callbacks
    callbacks = _
    context
    
  # Event listner and dispatchers
  
 
  # Respond to page resize no more than once every 500ms
  context.respond = _.throttle () => event.respond.call context, 500
  
  # Respond to adjust event
  context.adjust = (d1, i1, d2, i2) =>
    event.adjust.call context, d1, i1, d2, i2
    context.runCallbacks 'adjust'
    
  # Responds to toggle event
  context.toggle = () =>
    event.toggle.call context
    context.runCallbacks 'toggle'
    
  # Responds to refresh event.
  context.refresh = () =>
    event.refresh.call context, options
    context.runCallbacks 'refresh'
    return
    
  context.on = (type, listener) =>
    if not listener? then return event.on type
    event.on type, listener
    context
    
 
  # Listen for page resize
  d3.select(window).on 'resize', () =>
    d3.event.preventDefault()
    if dom
      w0 = $(dom).width() - 50
      h0 = $(dom).height()
      if w isnt w0 or h isnt h0
        w = w0
        h = h0
        context.respond()
    return
  
  
  context
  
  
class QuandlismContext

QuandlismContext_ = QuandlismContext.prototype = quandlism.context.prototype