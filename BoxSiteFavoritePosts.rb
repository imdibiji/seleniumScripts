require 'rubygems'
require "selenium"
require "getoptlong"
require 'BoxSiteHelperModule.rb'
include BoxSiteHelperModule

# init
usage = "Usage: -a email address to login with
   -u base url
   -P password
  e.g. ruby #{$0} -a qa42@powered.com -P password"
url = ''
emailaddress = "foo@bar.com"
password = "boguspassword"

# process command line options
opts = GetoptLong.new(
    [ "--url", "-u", GetoptLong::REQUIRED_ARGUMENT ],
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
selenium.set_context("test_box_site_favorite_topic")

# go home and logout if necessary.  Then login.
selenium.open "/"
if selenium.element? "link=Logout"
  selenium.click "link=Logout"
  selenium.wait_for_page_to_load "30"
end
loginFrontendUser(selenium, emailaddress, password)

# determine the max page number for the discussions tab
maxPageNumber = 1 #there's always one page
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
puts "maxPageNumber = #{maxPageNumber}"

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

# view each topic and favorite it
topicHrefs.each do |href|
  selenium.open(href)
  if selenium.element? "//div[@class=\"userFavoriteImage \"]" 
    selenium.click "//div[@class=\"userFavoriteImage \"]"
  else
    puts "ack! could not favorite #{href}"
  end
end

selenium.stop
