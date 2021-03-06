#!/usr/bin/env ruby
# encoding: utf-8

require 'mediawiki_api'
require 'HTTParty'
require 'csv'
require 'open-uri'
require '../helper'
require 'fileutils'
require 'colorize'

# File format: <page_name>@!@<url_for_image>

IMAGE_REGEX = /(\s*\|\s*image\s*=)\s/

def comment(title, author, url)
  "==Summary==
{{Non-free use rationale book cover
| Article = #{title.strip}
| Title   = [[#{title.strip}]]
| Author  = #{author}
| Source  = #{url}
| Use     = Infobox
}}

==Licensing==
{{Non-free book cover|image has rationale=yes}}"
end
BOOK_PROJECT = "{{WikiProject Books|class=File}}"

Helper.read_env_vars(file = '../vars.csv')

client = MediawikiApi::Client.new 'https://en.wikipedia.org/w/api.php'
client.log_in ENV['USERNAME'], ENV['PASSWORD']

Dir.mkdir('book_covers') unless Dir.exist?('book_covers')

books = File.open('books.csv.txt').read


books.each_line do |book|
  title, url = book.split('@!@')
  puts title.to_s.colorize(:blue)

  text = client.get_wikitext(title).body
  extension = File.extname(url).strip

  # Make sure "| image = " only appears once
  image_count = text.scan(IMAGE_REGEX).size

  if image_count > 1
    Helper.print_message("- ERROR: #{title} couldn't be processed. '| image =' appears more than once.")
    next
  end

  filename = "#{title}#{extension}".gsub(':', '')
  author = ''
  if text.raw_text.scan(/author[s]*\s*=\s*/).any?
    author = text.raw_text.match(/author[s]*\s*=\s*(?<author>[^\|\n]*)/)[:author]
  end

  open("video_games/#{filename}", 'wb') do |file|
    file << open(url.strip).read
  end

  begin
    @response = client.upload_image(filename, "video_games/#{filename}", 'Adding image', false, comment(title, author, url))
  rescue Exception => e
    Helper.print_message("- ERROR: #{e}")
    next
  end

  unless @response.data["result"] == "Success"
    Helper.print_message("- ERROR: There are warnings: #{@response.data["warnings"]}")
    next
  end
  client.edit(title: "File talk:#{filename}", text: BOOK_PROJECT, summary: 'adding project')

  if image_count == 0
    puts '- NOTE: image = did not appear in original text'.colorize(:green)
    text.gsub!(/(\{\{Infobox book)(\n\|\s*name\s*=.*)?/i, "\\1\\2\n| image = #{filename}")
  else
    puts '- NOTE: Image inserted as normal'.colorize(:green)
    text.gsub!(IMAGE_REGEX, "\\1 #{filename}")
  end

  client.edit(title: title, text: text, summary: 'Adding image')

  talk_page = client.get_wikitext("Talk:#{title}").body

  talk_page.gsub!(/\|\s*cover\s*=\s*[^\}\|]*/, '')

  client.edit(title: "Talk:#{title}", text: talk_page, summary: 'has cover art')
  break
end

puts "Cleaning up and deleting all downloaded covers"
FileUtils.rm_rf('book_covers')
