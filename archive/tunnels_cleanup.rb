#!/usr/bin/env ruby
# encoding: utf-8

require 'mediawiki_api'
require 'HTTParty'
require 'csv'
require 'open-uri'
require './helper'
require 'fileutils'

OPEN_REGEX = /\|(\s*)open\s*=\s*/

QUERY_URL = "https://petscan.wmflabs.org/?language=en&project=wikipedia&depth=0&categories=Pages%20using%20infobox%20tunnel%20with%20deprecated%20parameters&combination=subset&negcats=&ns%5B0%5D=1&larger=&smaller=&minlinks=&maxlinks=&before=&after=&max_age=&show_redirects=both&edits%5Bbots%5D=both&edits%5Banons%5D=both&edits%5Bflagged%5D=both&templates_yes=&templates_any=&templates_no=&outlinks_yes=&outlinks_any=&outlinks_no=&links_to_all=&links_to_any=&links_to_no=&sparql=&manual_list=&manual_list_wiki=&pagepile=&wikidata_source_sites=&subpage_filter=either&common_wiki=auto&source_combination=&wikidata_item=no&wikidata_label_language=&wikidata_prop_item_use=&wpiu=any&sitelinks_yes=&sitelinks_any=&sitelinks_no=&min_sitelink_count=&max_sitelink_count=&format=json&output_compatability=catscan&sortby=title&sortorder=ascending&regexp_filter=&min_redlink_count=1&doit=Do%20it%21&interface_language=en&active_tab=tab_output"

Helper.read_env_vars

client = MediawikiApi::Client.new 'https://en.wikipedia.org/w/api.php'
client.log_in ENV['USERNAME'], ENV['PASSWORD']

json = JSON.load(open(QUERY_URL))
titles = json["*"].first["a"]["*"].map{ | page| page["title"].gsub("_"," ")}
puts titles.size

# For testing
# pages = File.open('tv.txt').read
# pages.each_line do |title|
titles.each do |title|
  title.strip!
  puts title
  text = client.get_wikitext(title).body

  count = text.scan(OPEN_REGEX).size

  if count > 1
    puts "- ERROR: 'open' param appears more than one time on the page."
    next
  end

  if count < 1
    puts "- ERROR: 'open' param not found."
    next
  end

  opened_count = text.scan(/\|\s*opened\s*=\s*/).size
  if opened_count > 0
    puts "- ERROR: 'opened' param already on page."
    next
  end


  text.gsub!(OPEN_REGEX, '|\1opened = ')

  client.edit(title: title, text: text, summary: 'Fixing infobox not to use [[:Category:Pages using infobox tunnel with deprecated parameters|deprecated parameters]]')
  puts "- SUCCESS"
  # sleep rand(2..10)
end

puts "DONE"
