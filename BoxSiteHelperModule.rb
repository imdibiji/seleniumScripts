# some helper functions
require 'webster'

module BoxSiteHelperModule
  # some helper functions
  # get list of image files in a directory
  def getImageFilenames(directoryName, extension)
    #create and instance of Dir and then collect image filenames, return as array of strings
    images = []
    directory = Dir.new(directoryName)
    regExpression = Regexp.new('.+\.' + extension + '$')
    directory.each do |file|
      images.push(file) if file =~ regExpression
    end
    return images
  end

  # use some js to get all the checkbox ids
  def getAllCheckboxIds(seleniumObject)
    script = "var inputId  = new Array();"# Create array in java script.
    script += "var cnt = 0;" # Counter for check box ids.
    script += "var inputFields  = new Array();" # Create array in java script.
    script += "inputFields = window.document.getElementsByTagName('input');" # Collect input elements.
    script += "for(var i=0; i<inputFields.length; i++) {" # Loop through the collected elements.
    script += "if(inputFields[i].id !=null "
    script += "&& inputFields[i].id !='undefined' "
    script += "&& inputFields[i].getAttribute('type') == 'checkbox') {" # If input field is of type check box and input id is not null.
    script += "inputId[cnt]=inputFields[i].id ;" # Save check box id to inputId array.
    script += "cnt++;" # increment the counter.
    script += "}" # end of if.
    script += "}" # end of for.
    script += "inputId.toString();" # Convert array in to string.
    checkboxIds = seleniumObject.get_eval(script).split(",") # Split the string.
    return checkboxIds
  end

  def getString(numberOfWords)
    wordGenerator = Webster.new
    words = ''
    for i in 1..numberOfWords
      words += "#{wordGenerator.random_word} "
    end
    return words
  end

  def getCommaString(numberOfWords)
    wordGenerator = Webster.new
    words = ''
    for i in 1..numberOfWords
      words += "#{wordGenerator.random_word},"
    end
    return words.chop!
  end

  def getRandomArrayElements(theArray, numberOfElements)
    #returns random elements
    randomElements = []
    until randomElements.length == numberOfElements
      randomElement = theArray[rand(theArray.length)]
      randomElements.push(randomElement) unless randomElements.include?(randomElement) 
    end
    return randomElements
  end

  def isTopicHref(href)
    topicHrefPattern = Regexp.new('\/discussions\/\d+')
    if href =~ topicHrefPattern 
      return true
    else
      return false
    end
  end
  
  def isPagerLink(href)
    topicHrefPattern = Regexp.new('\/discussions\/.+&page=\d')
    if href =~ topicHrefPattern 
      return true
    else
      return false
    end
  end
  
  def getPageNumber(href)
    topicHrefPattern = Regexp.new('\/discussions\/.+&page=(\d+)')
    if href =~ topicHrefPattern 
      return $1.to_i
    else
      return false
    end
  end
  
  def getTopicId(href)
    topicHrefPattern = Regexp.new('\/discussions\/(\d+)')
    if href =~ topicHrefPattern 
      return $1.to_i
    else
      return false
    end
  end
  
end
