#!/usr/bin/env ruby
# encoding: utf-8

require "mediawiki_api"
require "HTTParty"
require "csv"
require 'open-uri'
require './helper'

IMAGE_REGEX = /(\s*\|\s*image\s*=)\s/

def comment(title, author, url)
  "==Summary==
{{Non-free use rationale 2
|Description = The cover of [[#{title.strip}]] by #{author}.
|Source = #{url.strip}
|Author = #{author}
|Article = #{title.strip}
|Purpose = To serve as the primary means of visual identification at the top of the article dedicated to the work in question.
|Replaceability = n.a.
|Minimality = Will only be used on the article itself.
|Commercial = n.a.
}}

==Licensing==
{{Non-free book cover}}"
end

Helper.read_env_vars

client = MediawikiApi::Client.new "https://en.wikipedia.org/w/api.php"
client.log_in ENV["USERNAME"], ENV["PASSWORD"]

books = CSV.read("books.csv.txt").drop(1)

#TODO: figure out the file extension to use based on the URL

books.each do |title, url|
  puts "#{title}"
  text = client.get_wikitext(title).body
  extension = File.extname(url)

  #Make sure "| image = " only appears once
  image_count = text.scan(IMAGE_REGEX).size

  if image_count > 1
    puts "- ERROR: #{title} couldn't be processed. '| image =' appears more than once."
    next
  end

  if text.scan(/author\s*=\s*/).size == 0
    puts "- ERROR: #{title} couldn't be processed. No author is present on the page!"
    next
  end

  author = text.match(/author\s*=\s*(?<author>.*)/)[:author]

  open("book_covers/#{title}#{extension}", 'wb') do |file|
    file << open(url.strip).read
  end

  begin
    client.upload_image("#{title.gsub(":", " -")}#{extension}","book_covers/#{title}#{extension}", comment(title, author, url), false)
  rescue Exception => e
    puts "- ERROR: #{e}"
    next
  end


  if image_count == 0
    puts "- NOTE: image = did not appear in original text"
    text.gsub!(/(\{\{Infobox book)(\n\|\s*name\s*=.*)?/, "\\1\\2\n| image = #{title.gsub(":", " -")}#{extension}")
  else
    puts "- NOTE: Image inserted as normal"
    text.gsub!(IMAGE_REGEX, "\\1 #{title.gsub(":", " -")}#{extension}")
  end

  client.edit(title: title, text: text, summary: "Adding image")
end




