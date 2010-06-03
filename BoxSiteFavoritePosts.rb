require 'rubygems'
require "selenium"
require "getoptlong"
require 'BoxSiteHelperModule.rb'
include BoxSiteHelperModule

# init
emailaddress = "foo@bar.com"
password = "password"

# process command line options
opts = GetoptLong.new(
    [ "--emailaddress", "-a", GetoptLong::OPTIONAL_ARGUMENT ],
    [ "--password", "-P", GetoptLong::OPTIONAL_ARGUMENT ]
)

unless ARGV.length > 0
  puts 'Usage: -a email address to login with
   -P passowrd
  e.g. ruby <scriptname> -a qa42@powered.com -P password'
  exit
end

begin
  opts.each { |opt, arg|
    case opt
    when "--emailaddress"
      emailaddress = arg
    when "--password"
      password = arg
    else
      puts 'Usage: -c list of clients
   -e environment
   -R Resume previous run
   -n Skip registration of new user before spidering registration
e.g. ruby start_watir_spider.rb -c sony, motorola -e QA, ClientQA '
      Process.exit!
    end
  }
end

# create instance of selenium client
selenium = Selenium::SeleniumDriver.new("localhost", 4444, "*chrome", "http://appcert01-rons.eng.powered.com:8075/", 10000);
selenium.start
selenium.set_context("test_box_site_favorite_topic")

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

# determine max page number
maxPageNumber = 0
topicHrefs = []
topicIds = []
selenium.open "/discussions/home"
selenium.get_xpath_count('//a').to_i.times do |i|
  if selenium.element?("document.links[#{i}]")
    href = selenium.get_attribute("document.links[#{i}]@href")
    if isPagerLink(href)
      if getPageNumber(href) > maxPageNumber
        maxPageNumber = getPageNumber(href)
      end
    end
  end
end
puts maxPageNumber

# now access each page and collect topics
for i in 1..maxPageNumber.to_i
  selenium.open "/discussions/?page=#{i}"
  selenium.get_xpath_count('//a').to_i.times do |i|
    if selenium.element?("document.links[#{i}]")
      href = selenium.get_attribute("document.links[#{i}]@href")
      if isTopicHref(href) && !topicIds.include?( getTopicId(href) )
        topicHrefs.push( href )
        topicIds.push( getTopicId(href) )
      end
    end
  end
end

# view each topic and favorit it
topicHrefs.each do |href|
  selenium.open(href)
  if selenium.element? "//div[@class=\"userFavoriteImage\"]" 
    selenium.click "//div[@class=\"userFavoriteImage\"]"
  end
end

selenium.stop
