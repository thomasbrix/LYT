do ->
  
  # Class to model an NCC document
  class LYT.NCCDocument extends LYT.TextContentDocument
    constructor: (url) ->
      super url, (deferred) =>
        @structure = parseStructure @source
        @sectionList = flattenStructure @structure
        
        # FIXME: This isn't pretty, and shouldn't be handled here!
        for section, index in @sectionList
          section.previousSection = @sectionList[index-1] if index > 0
          section.nextSection     = @sectionList[index+1] if index < @sectionList.length-1
    
    # Find a section by its ID. If no ID is given,
    # the first section will be returned
    findSection: (id = null) ->
      find = (id, sections) ->
        for section in sections
          return section if section.id is id
          if section.children?
            child = find id, section.children
            return child if child?
        return null
      
      return @structure[0] or null unless id
      find id, @structure
      
  # -------
  
  # ## Privileged
  
  # Internal helper function to parse the (flat) heading structure of an NCC document
  # into a nested collection of `NCCSection` objects
  parseStructure = (xml) ->
    # Collects consecutive heading of the given level or higher in the `collector`.  
    # I.e. given a level of 3, it will collect all `H3` elements until it hits an `H1`
    # element. Each higher level (i.e. `H4`) heading encountered along the way will be
    # collected recursively.  
    # Returns the number of headings collected.
    getConsecutive = (headings, level, collector) ->
      # Loop through the `headings` array
      for heading, index in headings
        # Return the current index if the heading isn't the given level
        return index if heading.tagName.toLowerCase() isnt "h#{level}"
        # Create a section object
        section = new LYT.Section heading
        # Collect all higher-level headings into that section's `children` array,
        # and increment the `index` accordingly
        index += getConsecutive headings.slice(index+1), level+1, section.children
        # Add the section to the collector array
        collector.push section
      
      # If the loop ran to the end of the `headings` array, return the array's length
      return headings.length
    
    # Create an array to hold the structured data
    structure = []
    # Find all headings as a plain array
    headings  = jQuery.makeArray xml.find(":header")
    return [] if headings.length is 0
    # Find the level of the first heading (should be level 1)
    level     = parseInt headings[0].tagName.slice(1), 10
    # Get all consecutive headings of that level
    getConsecutive headings, level, structure
    return structure
  
  
  flattenStructure = (structure) ->
    flat = []
    for section in structure
      flat.push section
      flat = flat.concat flattenStructure(section.children)
    flat
    
  

