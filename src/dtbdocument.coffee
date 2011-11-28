# This file contains the `LYT.DTBDocument` class, which forms the basis for other classes.
# It is not meant for direct instantiation.

# FIXME: Improve error-handling, and send requests through service (or something)

do ->
  # Meta-element name attribute values to look for
  # Name attribute values for nodes that may appear 0-1 times per file  
  # Names that may have variations (e.g. `ncc:format` is the deprecated in favor of `dc:format`) are defined a arrays.
  # C.f. [The DAISY 2.02 specification](http://www.daisy.org/z3986/specifications/daisy_202.html#h3metadef)
  METADATA_NAMES =
    singular:
      coverage:         "dc:coverage"
      date:             "dc:date"
      description:      "dc:description"
      format:          ["dc:format", "ncc:format"]
      identifier:      ["dc:identifier", "ncc:identifier"]
      publisher:        "dc:publisher"
      relation:         "dc:relation"
      rights:           "dc:rights"
      source:           "dc:source"
      subject:          "dc:subject"
      title:            "dc:title"
      type:             "dc:type"
      charset:          "ncc:charset"
      depth:            "ncc:depth"
      files:            "ncc:files"
      footnotes:        "ncc:footnotes"
      generator:        "ncc:generator"
      kByteSize:        "ncc:kByteSize"
      maxPageNormal:    "ncc:maxPageNormal"
      multimediaType:   "ncc:multimediaType"
      pageFront:       ["ncc:pageFront", "ncc:page-front"]
      pageNormal:      ["ncc:pageNormal", "ncc:page-normal"]
      pageSpecial:     ["ncc:pageSpecial", "ncc:page-special"]
      prodNotes:        "ncc:prodNotes"
      producer:         "ncc:producer"
      producedDate:     "ncc:producedDate"
      revision:         "ncc:revision"
      revisionDate:     "ncc:revisionDate"
      setInfo:         ["ncc:setInfo", "ncc:setinfo"]
      sidebars:         "ncc:sidebars"
      sourceDate:       "ncc:sourceDate"
      sourceEdition:    "ncc:sourceEdition"
      sourcePublisher:  "ncc:sourcePublisher"
      sourceRights:     "ncc:sourceRights"
      sourceTitle:      "ncc:sourceTitle"
      timeInThisSmil:  ["ncc:timeInThisSmil", "time-in-this-smil"]
      tocItems:        ["ncc:tocItems", "ncc:tocitems", "ncc:TOCitems"]
      totalElapsedTime:["ncc:totalElapsedTime", "total-elapsed-time"]
      totalTime:       ["ncc:totalTime", "ncc:totaltime"]
    
    # Name attribute values for nodes that may appear multiple times per file
    plural:
      contributor: "dc:contributor"
      creator:     "dc:creator"
      language:    "dc:language"
      narrator:    "ncc:narrator"
  
  # -------
  
  # This class serves as the parent of the `SMILDocument` and `TextContentDocument` classes.  
  # It is not meant for direct instantiation - instantiate the specific subclasses.
  class LYT.DTBDocument
    
    # The constructor takes 1-2 arguments (the 2nd argument is optional):  
    # - url: (string) the URL to retrieve
    # - callback: (function) called when the download is complete (used by subclasses)
    #
    # `LYT.DTBDocument` acts as a Deferred.
    constructor: (@url, callback = null) ->
      deferred = jQuery.Deferred()
      deferred.promise this
      
      @source = null
      dataType = if @url.match(/\.x?html?$/i)? then "html" else "xml"
      
      coerceToHTML = (responseText) =>
        log.message "DTB: Coercing #{@url} into HTML"
        html = jQuery "<html/>"
        document = responseText.match /<html[^>]*>([\s\S]+)<\/html>\s*$/i
        return null unless (document = document[1])?
        
        document = nerfImageURLs document
        
        html.html document
      
      nerfImageURLs = (html) ->
        html.replace ///
          (<img [^>]*?)        # image tag
          src\s*=\s*           # src attr (plus possible whitespace)
          (                    # branch...
            (("')([^"']+)\3)   # quoted src attr value
            |
            ([^\s]+)           # unquoted src attr value
          )///ig, "$1data-x-src=$2"
          
      
      
      loaded = (document, status, jqXHR) =>
        if dataType is "html" or jQuery(document).find("parsererror").length isnt 0
          @source = coerceToHTML jqXHR.responseText
        else
          @source = jQuery document
        resolve()
      
      failed = (jqXHR, status, error) =>
        if status is "parsererror"
          log.error "DTB: Parser error in XML response. Attempting recovering"
          @source = coerceToHTML jqXHR.responseText
          resolve()
          return
        log.errorGroup "DTB: Failed to get #{@url}", jqXHR, status, error
        deferred.reject status, error
      
      resolve = =>
        if @source?
          log.group "DTB: Got: #{@url}", document
          callback? deferred
          deferred.resolve this
        else
          deferred.reject -1, "FAILED_TO_LOAD"
      
      log.message "DTB: Getting: #{@url}"
      
      request = jQuery.ajax {
        url:      @url
        dataType: dataType
        async:    yes
        cache:    yes
        success:  loaded
        error:    failed
        headers:
          # For some strange reason, this avoids a hanging bug in Chrome,
          # even though Chrome refuses to set this particular header...
          connection: "close"
      }
      
      deferred
    
    
    # Parse and return the metadata as an array
    getMetadata: ->
      return {} unless @source?
      
      # Return cached metadata, if available
      return @_metadata if @_metadata?
      
      # Find the `meta` elements matching the given name-attribute values.
      # Multiple values are given as an array
      findNodes = (values) =>
        values = [values] unless values instanceof Array
        nodes  = []
        selectors = ("meta[name='#{value}']" for value in values).join(", ")
        @source.find(selectors).each ->
          node = jQuery this
          nodes.push {
            content: node.attr("content")
            scheme:  node.attr("scheme") or null
          }
        
        return null if nodes.length is 0
        return nodes
      
      xml = @source.find("head").first()
      @_metadata = {}
      
      for own name, values of METADATA_NAMES.singular
        found = findNodes values
        @_metadata[name] = found.shift() if found?
      
      for own name, values of METADATA_NAMES.plural
        found = findNodes values
        @_metadata[name] = found if found?
      
      @_metadata
    
  