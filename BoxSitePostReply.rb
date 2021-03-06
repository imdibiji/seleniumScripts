require 'rubygems'
require "selenium"
require "getoptlong"
require 'BoxSiteHelperModule.rb'
include BoxSiteHelperModule

# init
url = ''
prefix = 'qa'
topicid = 0
startnum = 0
endnum = 0
emailaddress = "foo@bar.com"
password = "password"
usage = "Usage: -p <prefix to use>
   -t topic id
   -s starting index
   -e ending index
   -a email address to login with
   -P password
  e.g. ruby #{$0} -p \"this is a test\" -s 1 -e 10 -a qa42@powered.com -P password"

# process command line options
opts = GetoptLong.new(
    [ "--url", "-u", GetoptLong::REQUIRED_ARGUMENT ],
    [ "--prefix", "-p", GetoptLong::REQUIRED_ARGUMENT ],
    [ "--topicid", "-t", GetoptLong::REQUIRED_ARGUMENT ],
    [ "--startnum", "-s", GetoptLong::REQUIRED_ARGUMENT ],
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
    when "--topicid"
      topicid = arg
    when "--startnum"
      startnum = arg.to_i
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
# don't use native xpath cuz FF is teh weak
selenium.start
selenium.allow_native_xpath("false")
selenium.set_context("test_box_site_post_reply")

# go home and logout if necessary.  Then login.
selenium.open "/"
if selenium.element? "link=Logout"
  selenium.click "link=Logout"
  selenium.wait_for_page_to_load "30"
end
loginFrontendUser(selenium, emailaddress, password)

#check for successful login
unless (selenium.element? "Logout")
  puts "login unsuccessful!"
  Process.exit!
end

# select a topic and post some replies
for index in startnum..endnum
  selenium.open "/discussions/home"
  selenium.wait_for_page_to_load "30000"
  if selenium.element? "xpath=//a[matches(@href,'#{topicid}')]"
    selenium.click "xpath=//a[matches(@href,'#{topicid}')]"
    selenium.wait_for_page_to_load "30000"
  else
    puts "couldn't find topic link"
    Process.exit!
  end
  if selenium.element? "link=Post a Reply"
    selenium.click "link=Post a Reply"
  else
    sleep 5
    selenium.click "link=Post a Reply"
  end

  selenium.wait_for_page_to_load "300"
#  selenium.type "editorArea", "#{Time.now}: #{prefix} : #{index}\nThis is the body.  this is the body.  this is the body.  this is the body.  this is the body.  this is the body.  this is the body.  this is the body.  this is the body.  this is the body.  this is the body.  this is the body.  this is the body.  this is the body.  this is the body.  this is the body.  this is the body.  this is the body.  this is the body."
  selenium.type "editorArea", "#{Time.now}: #{prefix} : #{index}\n #{getString(30)}"
  puts "posting reply index: #{index}"
  selenium.click "link=Post"
  selenium.wait_for_page_to_load "30000"
end
selenium.stop
