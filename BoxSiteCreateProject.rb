require 'rubygems'
require "selenium"
require "getoptlong"
require 'webster'

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

# init
prefix = 'qa'
topicid = 0
startnum = 0
endnum = 0
emailaddress = "foo@bar.com"
password = "password"
imageDir = '/home/davegoodine/Pictures'

# process command line options
opts = GetoptLong.new(
    [ "--prefix", "-p", GetoptLong::REQUIRED_ARGUMENT ],
    [ "--endnum", "-e", GetoptLong::REQUIRED_ARGUMENT ],
    [ "--emailaddress", "-a", GetoptLong::REQUIRED_ARGUMENT ],
    [ "--password", "-P", GetoptLong::REQUIRED_ARGUMENT ]
)

unless ARGV.length > 0
  puts 'Usage: -p <prefix to use>
   -e ending index
   -a email address to login with
   -P passowrd
  e.g. ruby $0 -p "this is a test" -e 10 -a qa42@powered.com -P password'
  exit
end

begin
  opts.each { |opt, arg|
    case opt
    when "--prefix"
      prefix = arg
    when "--endnum"
      endnum = arg.to_i
    when "--emailaddress"
      emailaddress = arg
    when "--password"
      password = arg
    else
      puts 'Usage: -p "prefix text"
   -e endnum
   -a email address
   -P password
  e.g. ruby $0 -p "this is a test" -e 10 -a qa42@powered.com -P password'
      Process.exit!
    end
  }
end

# create instance of selenium client
selenium = Selenium::SeleniumDriver.new("localhost", 4444, "*chrome", "http://appcert01-rons.eng.powered.com:8075/", 10000);
selenium.start
selenium.allow_native_xpath("false")      # don't use native xpath cuz FF is teh weak
selenium.set_context("test_box_site_create_topic")

# go home and logout if necessary.  Then login.
selenium.open "/"
if selenium.element? "link=Logout"
  selenium.click "link=Logout"
  selenium.wait_for_page_to_load "30"
end
selenium.open "/login"
selenium.wait_for_page_to_load "30000"
if (selenium.element? "emailAddress") && (selenium.element? "LoginSubmit")
  selenium.click "emailAddress"
  selenium.type "emailAddress", emailaddress
  selenium.type "password", password
  selenium.click "LoginSubmit"
  selenium.wait_for_page_to_load "30000"
else
  puts "could not login!"
end

#  get 4 random checkbox ids
selenium.open "/projects/new"
selenium.wait_for_page_to_load "30000"
selenium.click "link=Select up to 4 categories"
selenium.wait_for_element "catId_1080"
allCheckboxIds =  getAllCheckboxIds(selenium)

# get the list of image files
imageFilenames = getImageFilenames(imageDir, 'jpg')

# create projects main loop
for index in 1..endnum
  puts "creating project #{index}..."
  selenium.open "/projects/new"
  selenium.wait_for_page_to_load "30000"
  selenium.wait_for_element "projectName"
  selenium.type "projectName", "project name: #{index} #{prefix} #{getString(5)}"
  selenium.type "projectDescription", "description: #{getString(50)}"
  # upload images and files, be sure to wait for the modal to open
  for i in 1..4
    selenium.click "//a[matches(@onclick,'openProjectImageDialog')]"
    selenium.wait_for_element "file1"
    #until selenium.element? "file1"
    #  sleep 1
    #end
    selenium.type "file1", imageDir + '/' + imageFilenames[rand(imageFilenames.length)]
    selenium.click "uploadSubmitButton"
    #until selenium.element? "//span[@title='Delete']"
    #selenium.wait_for_element "//div[@id='addedImage#{i}']"
    until selenium.element? "//div[@id='addedImage#{i}']"
      sleep 1
    end
  end
  selenium.click "link=Select up to 4 categories"
  selenium.wait_for_element "catId_1080"
  getRandomArrayElements(allCheckboxIds,4).each do |id|
    selenium.click id
  end
  selenium.click "//a[@id='Modal_close']/span"
  selenium.type "tagString", getCommaString(4)
  selenium.type "hours", rand(5)
  selenium.type "minutes", "15"
  selenium.select "skillLevel", "label=Learning"
  selenium.type "material1", "material: #{getString(10).slice(0,128)}"
  selenium.type "instructionTitle1", "instruction title: #{getString(5).slice(0,64)}"
  selenium.type "instruction1", "instruction body: #{getString(100)}"
  puts "saving project #{index}"
  selenium.click "link=Save and Publish"
  selenium.wait_for_page_to_load "30000"
  for i in 1..10
    if selenium.element? "link=Unpublish"
      break
    elsif selenium.text? "The following errors must be corrected before saving your project"
      puts "got a bad word, break"
      break
    end 
    sleep 1 
  end
end
selenium.stop
