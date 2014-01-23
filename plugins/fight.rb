require 'json'
require 'nokogiri'
require 'open-uri'
require "cgi"

command do
  description "fight two search terms against each other"

  # do our fight, we parse the entire line but we actually use the
  # raw message body
  action :required=>:fight, :html=>true do |fight|
    puts fight
    fighters = fight.split(/\s+vs\s+/)
    if fighters.length >= 2 then
      match = select_fighters(fighters)
      match_results = {}
      match['fighters'].each do |f|
        match_results[f] = search(f)
        sleep 1
      end
      report_match(match_results, match['side-lines'])
    else
      "Fights are between 2 (or more) objects using ' vs ' as a separator"
    end
  end
end

helper :select_fighters do |fighters|
  if fighters.length > 2 then
    f1 = fighters.choice
    side_lines = fighters.reject { |f| f == f1 }
    f2 = side_lines.choice
    side_lines = side_lines.reject { |f| f == f2 }
    { 'fighters' => [ f1, f2 ], 'side-lines' => side_lines }
  else
    { 'fighters' => fighters, 'side-lines' => [] }
  end
end

helper :search do |q|
  # Use a custom User-Agent otherwise google makes it harder to get the results counts
  doc = Nokogiri::HTML(open("https://www.google.com/search?q=#{CGI.escape(q)}", "User-Agent" => 'Mozilla/5.0 (X11; Linux x86_64; rv:8.0) Gecko/20100101 Firefox/8.0'))
  doc.xpath("//div[@id='resultStats']").text.match('[0-9,]+')[0]
end

helper :report_match do |results, side_lines|
  report = '<br /><b>Fight Results</b> (per Google)<br />'
  win_order = results.sort_by { |k,v| v.gsub(/[,]/, '').to_i }
  if win_order[0][1] == win_order[1][1] then
    # tied match
    report << "<b>%s</b> and <b>%s</b> tie at <b>%s</b>" % [win_order[0][0], win_order[1][0], win_order[0][1]]
  else
    report << "<b>%s</b> with <b>%s</b> wins against <b>%s</b> with <b>%s</b>" % [win_order[1][0], win_order[1][1], win_order[0][0], win_order[0][1]]
  end
  if !side_lines.empty? then
    report << '<br /><b>Sitting out this round</b><br />'
    side_lines.each do |f|
      report << "<b>%s</b>, " % f
    end
    # get rid of our trailing ', '
    report = report.chop.chop
  end
  report
end
