require 'rubygems'
require "selenium"
require "getoptlong"
require 'BoxSiteHelperModule.rb'
include BoxSiteHelperModule

# init
usage = "Usage: -p <prefix to use>
   -u base url
   -e ending indexputs 
   -a email address to login with
   -P password
  e.g. ruby #{$0} -p \"this is a test\" -e 10 -a qa42@powered.com -P password"
url = ''
prefix = 'qa'
topicid = 0
startnum = 0
endnum = 0
emailaddress = "foo@bar.com"
password = "password"
imageDir = File.expand_path("./images")
numOfMaterials = 4
numOfInstructions = 4
numOfInstructionImages = 3

# process command line options
opts = GetoptLong.new(
    [ "--url", "-u", GetoptLong::REQUIRED_ARGUMENT ],
    [ "--prefix", "-p", GetoptLong::REQUIRED_ARGUMENT ],
    [ "--endnum", "-e", GetoptLong::REQUIRED_ARGUMENT ],
    [ "--emailaddress", "-a", GetoptLong::REQUIRED_ARGUMENT ],
    [ "--password", "-P", GetoptLong::REQUIRED_ARGUMENT ]
)

unless ARGV.length > 0
  puts usage
  exit
end

begin
  opts.each { |opt, arg|
    case opt
    when "--url"
      url = arg
    when "--prefix"
      prefix = arg
    when "--endnum"
      endnum = arg.to_i
    when "--emailaddress"
      emailaddress = arg
    when "--password"
      password = arg
    else
      puts usage
      Process.exit!
    end
  }
end

# create instance of selenium client
selenium = Selenium::SeleniumDriver.new("localhost", 4444, "*chrome", url, 10000);
selenium.start
selenium.allow_native_xpath("false")      # don't use native xpath cuz FF is teh weak
selenium.set_context("test_box_site_create_topic")

# go home and logout if necessary.  Then login.
selenium.open "/"
if selenium.element? "link=Logout"
  selenium.click "link=Logout"
  selenium.wait_for_page_to_load "30"
end
loginFrontendUser(selenium, emailaddress, password)


#  get 4 random checkbox ids
selenium.open "/projects/new"
selenium.wait_for_page_to_load "30000"
selenium.click "link=Select up to 4 categories"
selenium.wait_for_element "catId_1080"
allCheckboxIds =  getAllCheckboxIds(selenium)

# get the list of image files
imageFilenames = getImageFilenames(imageDir, 'jpg')

# create projects main loop
time = Time.new
for index in 1..endnum
  puts "creating project #{index}..."
  selenium.open "/projects/new"
  selenium.wait_for_page_to_load "30000"
  selenium.wait_for_element "projectName"
  selenium.type "projectName", "project name: #{time.month}-#{time.day}-#{time.year} #{time.hour}:#{time.min}:#{time.sec} #{index} #{prefix} #{getString(5)}"
  selenium.type "projectDescription", "description: #{getString(50)}"
  # upload images and files, be sure to wait for the modal to open
  for i in 1..4
    selenium.click "//a[matches(@onclick,'openProjectImageDialog')]"
    selenium.wait_for_element "file1"
    selenium.type "file1", imageDir + '/' + imageFilenames[rand(imageFilenames.length)]
    selenium.click "uploadSubmitButton"
    # dunno why, but wait_for_element doesn't work here...
    until selenium.element? "//div[@id='addedImage#{i}']"
      sleep 1
    end
  end
  selenium.click "link=Select up to 4 categories"
  selenium.wait_for_element "catId_1080"
  getRandomArrayElements(allCheckboxIds,4).each do |id|
    selenium.click id
  end
  selenium.click "link=Select Categories"
  selenium.type "tagString", getCommaString(4)
  selenium.type "hours", rand(5)
  selenium.type "minutes", "15"
  selenium.select "skillLevel", "label=Learning"
  # materials
  for i in 1..numOfMaterials
    selenium.wait_for_element "material#{i}"
    selenium.type "material#{i}", "material #{i}: #{getString(10).slice(0,128)}"
    selenium.click "//a[@href='javascript:projectControl.addNewMaterial();']" unless i == numOfMaterials
  end
  # instructions
  for imageIndex in 1..numOfInstructionImages
    selenium.wait_for_element "//a[matches(text(),'Add Instruction Photo')]"
    sleep 2 # frack!
    selenium.click "//a[matches(text(),'Add Instruction Photo')]"
    selenium.wait_for_element "//input[@id='file1'][@class='File Modal_focusable']"
    selenium.wait_for_element "//a[matches(@onclick, 'cancelUploadDialog')]"
    selenium.type "file1", imageDir + '/' + imageFilenames[rand(imageFilenames.length)]
    selenium.click "uploadSubmitButton"
    # dunno why, but wait_for_element doesn't work here...
    until selenium.element? "//div[@id='addedImage#{imageIndex}'][@class='projectImageThumbnail']"
      sleep 1
    end
  end
  for i in 1..numOfInstructions
    selenium.wait_for_element "instructionTitle#{i}"
    selenium.type "instructionTitle#{i}", "instruction title: #{getString(5).slice(0,64)}"
    selenium.type "instruction#{i}", "instruction body: #{getString(100)}"
    selenium.click "//a[@href='javascript:projectControl.addNewInstruction();']" unless i == numOfInstructions
  end
  # save
  puts "saving project #{index}"
  selenium.click "link=Save and Publish"
  # wait up to 10 sec for save to complete
  for i in 1..10
    if selenium.element? "link=Unpublish"
      break
    elsif selenium.element? "//div[@class='error'][@id='Notifier']"
    #elsif selenium.text? "The following errors must be corrected before saving your project"
      puts "There was an error during save, break."
      break
    end 
    sleep 1 
  end
end
selenium.stop
