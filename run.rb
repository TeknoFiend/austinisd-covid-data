require "open-uri"
require "json"
require 'nokogiri'

REFRESH_INTERVAL_HOURS = 8
MINUTES_PER_HOUR = 60
SECONDS_PER_MINUTE = 60

while(true) do
  puts "Downloading at #{Time.now}"
  puts '----------------------------------------'
  data = URI.parse("https://www.austinisd.org/covid-dashboard/ajax?_wrapper_format=drupal_ajax").read

  html = JSON.parse(data)[0]['data']

  $fragment = Nokogiri::HTML.fragment(html)

  if $fragment.search('thead').first.text.strip.gsub(/\s+/,',') != 'School,Total,New,Cases,Total,Cumulative,Cases,Total,New,Exposures,Total,Cumulative,Exposures'
    raise StandardError.new('Error: data format changed')
  end


  $fragment.text =~ /updated (\d+\/\d+\/\d+)/i
  date = $1

  updated_at = nil

  if( date )
    month,day,year = date.strip.split('/').map(&:strip).map(&:to_i)
    year = (year + 2000) if year < 100
    updated_at = Date.new(year,month,day)
  else
    $fragment.text =~ /updated (.*)/i
    updated_at = Date.parse($1)
    unless updated_at > Date.parse('2020-12-01')
      raise StandardError.new("Error: couldn't find update date")
    end
  end


  table = $fragment.search('tbody')
  rows = table.search('tr')

  data = rows.map do |row|
    col_data = row.search('td').map { |cell| cell.text.strip }.join(',')
  end

  csv = "School,Total New Cases,Total Cumulative Cases,Total New Exposures,Total Cumulative Exposures\n" + data.join("\n")

  filename = "data/#{updated_at.strftime('%Y-%m-%d')}.csv"
  File.open(filename, 'w') { |file| file.write(csv) }

  `git add #{filename}`
  `git commit #{filename} -m "Data for #{updated_at}"`
  `git push`

  puts "Updated #{filename}"
  puts '#################################################'
  sleep REFRESH_INTERVAL_HOURS * MINUTES_PER_HOUR * SECONDS_PER_MINUTE
end