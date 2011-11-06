# Class to model an NCC file
# What does "NCC" stand for anyway? Besides being the first letters in the starship _Entreprise's_ hull number (NCC-1701), I mean. And why do I even know this? I'm not a Star Trek fan!

do =>
  class LYT.NCCFile
    # Create a new `NCCFile` instance from the URL of an NCC file
    constructor: (@url) ->
      @base = @url.replace /\/[^\/?=&]*$/, ''
      loadRemote = =>
        options = 
          url:      @url
          dataType: "xml"
          # FIXME: It really should be asynchronous...
          async:    true
          cache:    false
          success:  (xml, status, xhr) =>
            @xml = jQuery xml
            @structure = parseStructure @xml
            @metadata  = parseMetadata @xml
            @smilFiles = loadSMILFiles(@structure, @base)
            
        jQuery.ajax @url, options
      
      cacheLocally = =>
        LYT.cache.write "ncc", @url, @toJSON()
      
      loadLocal = =>
        data = LYT.cache.read "ncc", @url
        return false unless data and data.structure and data.metadata
        @structure = data.structure
        @metadata  = data.metadata
        @smilFiles = loadSMILFiles(@structure, @base)
        true
      
      # FIXME: Caching disabled  
      # if not loadLocal() then
      loadRemote()
      
    
    creators: ->
      return ["?"] unless @metadata.creator?
      creators = (creator.content for creator in @metadata.creator)
      if creators.length > 1
        creators.slice(0, -1).join(", ") + " & " + creators.pop()
      else
        creators[0]
    
    getTextById: (id) ->
      id = id.replace /^[^#]*/, ''
      @xml.find(id).first().text()
    
    # Convert the structure tree to an HTML nested list
    # FIXME: Doesn't create proper markup!
    toHTMLList: ->
      # Recursively builds nested ordered lists from an array of items
      mapper = (items) ->
        list = jQuery "<ol></ol>"
        for item in items
          element = jQuery "<li></li>"
          element.attr "id", item.id
          element.attr "data-href", item.href
          element.text item.text
          element.append mapper(item.children) if item.children?
          list.append element
        list
      
      # Create the wrapper unordered list
      element = jQuery "<ul></ul>"
      # FIXME: Use data-* attrs and use English names, plz
      element.attr "data-title", @metadata.title.content
      element.attr "data-creator", @creators()
      element.attr "data-totalTime", @metadata.totalTime.content
      element.attr "id", "NCCRootElement"
      element.attr "data-role", "listview"
      element.append mapper(@structure).html()
      element
    
    toJSON: ->
      return null unless @structure? and @metadata?
      structure: @structure
      metadata:  @metadata || false
    
  # ---------
  
  # ## Chaching 
  
  loadCache = (url) ->
    
  
  # ---------
  
  # ## Parsing functions
  
  # Parses `meta` nodes in the head-element
  parseMetadata = (xml) ->
    selectors = 
      # Name attribute values for nodes that appear 0-1 times per file  
      # TODO: Move these to config?
      singular: [
        "dc:coverage"
        "dc:date"
        "dc:description"
        ["dc:format", "ncc:format"]
        ["dc:identifier", "ncc:identifier"]
        "dc:publisher"
        "dc:relation"
        "dc:rights"
        "dc:source"
        "dc:subject"
        "dc:title"
        "dc:type"
        "ncc:charset"
        "ncc:depth"
        "ncc:files"
        "ncc:footnotes"
        "ncc:generator"
        "ncc:kByteSize"
        "ncc:maxPageNormal"
        "ncc:multimediaType"
        "ncc:pageFront", "ncc:page-front"
        "ncc:pageNormal", "ncc:page-normal"
        ["ncc:pageSpecial", "ncc:page-special"]
        "ncc:prodNotes"
        "ncc:producer"
        "ncc:producedDate"
        "ncc:revision"
        "ncc:revisionDate"
        ["ncc:setInfo", "ncc:setinfo"]
        "ncc:sidebars"
        "ncc:sourceDate"
        "ncc:sourceEdition"
        "ncc:sourcePublisher"
        "ncc:sourceRights"
        "ncc:sourceTitle"
        ["ncc:tocItems", "ncc:tocitems"]
        ["ncc:totalTime", "ncc:totaltime"]
      ]
      # Name attribute values for nodes that may appear multiple times per file
      plural: [
        "dc:contributor"
        "dc:creator"
        "dc:language"
        "ncc:narrator"
      ]
    
    # Finds nodes by the given name attribute value(s) _(multiple values given as an array)_
    findNodes = (selectors) ->
      selectors = [selectors] unless selectors instanceof Array
      name = selectors[0].replace /[^:]+:/, ''
      nodes = []
      while selectors.length > 0
        selector = "meta[name='#{selectors.shift()}']"
        xml.find(selector).each ->
          node = jQuery this
          obj = {}
          obj.content = node.attr("content")
          obj.scheme  = node.attr("scheme") if node.attr "scheme"
          nodes.push obj
      
      return null if nodes.length is 0
      { nodes: nodes, name: name }
    
    xml = xml.find("head").first()
    metadata = {}
    for selector in selectors.singular
      found = findNodes selector
      if found?
        metadata[found.name] = found.nodes.shift()
    
    for selector in selectors.plural
      found = findNodes selector
      if found?
        metadata[found.name] = jQuery.makeArray found.nodes
    
    metadata
  
  # Parses the structure of headings (and heading only) in the NCC file into a nested array (a tree)  
  # **Note:** This function absolutely relies on the NCC file being well-formed
  parseStructure = (xml) ->
    # Collects consecutive heading of the given level, and recursively collects each of their "children", and so on…
    getConsecutive = (headings, level, collector) ->
      for heading, index in headings
        return index if heading.tagName.toLowerCase() isnt "h#{level}"
        heading = jQuery heading
        link = heading.find("a").first()
        node = {
          text: link.text()
          href: link.attr "href"
          id:   heading.attr "id"
        }
        children = []
        index += getConsecutive headings.slice(index+1), level+1, children
        node.children = children if children.length > 0
        collector.push node
      
      headings.length
    
    headings  = jQuery.makeArray xml.find(":header")
    level     = parseInt headings[0].tagName.slice(1), 10
    structure = []
    
    getConsecutive headings, level, structure
    structure
  
  loadSMILFiles = (nodes, baseURI) ->
    console.log nodes
    urls = []
    getURLs = (nodes) ->
      for node in nodes
        urls.push "#{baseURI}/#{node.href.replace(/#.*$/, '')}"
        if node.children?
          getURLs node.children
    
    getURLs nodes
    
    (new LYT.SMILFile url for url in urls)
    

    