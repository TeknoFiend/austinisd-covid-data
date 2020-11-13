require "open-uri"
require "json"
require 'nokogiri'

data = URI.parse("https://www.austinisd.org/covid-dashboard/ajax?_wrapper_format=drupal_ajax").read

html = JSON.parse(data)[0]['data']

$fragment = Nokogiri::HTML.fragment(html)

if $fragment.search('thead').first.text.strip.gsub(/\s+/,',') != 'School,Total,New,Cases,Total,Cumulative,Cases,Total,New,Exposures,Total,Cumulative,Exposures'
  raise StandardError.new('Error: data format changed')
end

$fragment.text =~ /updated (\d+\/\d+\/\d+)/i
unless( date = $1 )
  raise StandardError.new("Error: couldn't find update date")
end

updated_at = Date.parse($1)

table = $fragment.search('tbody')
rows = table.search('tr')

data = rows.map do |row|
  col_data = row.search('td').map { |cell| cell.text.strip }.join(',')
end

csv = "School,Total New Cases,Total Cumulative Cases,Total New Exposures,Total Cumulative Exposures\n" + data.join("\n")

filename = "#{updated_at.strftime('%Y-%m-%d')}.csv"
File.open(filename, 'w') { |file| file.write(csv) }