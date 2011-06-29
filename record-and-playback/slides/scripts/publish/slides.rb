require '../../core/lib/recordandplayback'
require 'rubygems'
require 'trollop'
require 'yaml'
require 'builder'

opts = Trollop::options do
  opt :meeting_id, "Meeting id to archive", :default => '58f4a6b3-cd07-444d-8564-59116cb53974', :type => String
end

meeting_id = opts[:meeting_id]
puts meeting_id
match = /(.*)-(.*)/.match meeting_id
meeting_id = match[1]
playback = match[2]

puts meeting_id
puts playback

if (playback == "slides")
	puts "publishing #{meeting_id}"
	logger = Logger.new("/var/log/bigbluebutton/slides-publish-#{meeting_id}.log", 'daily' )
	BigBlueButton.logger = logger

	# This script lives in scripts/archive/steps while properties.yaml lives in scripts/
	bbb_props = YAML::load(File.open('../../core/scripts/bigbluebutton.yml'))
	simple_props = YAML::load(File.open('slides.yml'))
	
	recording_dir = bbb_props['recording_dir']

	process_dir = "#{recording_dir}/process/#{meeting_id}/slides"
	publish_dir = simple_props['publish_dir'] + "/#{meeting_id}"
	playback_host = simple_props['playback_host']
	
	package_dir = "#{recording_dir}/publish/#{meeting_id}/slides"
	if not FileTest.directory?(package_dir)
		FileUtils.mkdir_p package_dir
		
		if not FileTest.directory?(publish_dir)
			FileUtils.mkdir_p publish_dir
		end
		
		audio_dir = "#{package_dir}/audio"
		FileUtils.mkdir_p audio_dir
		
		FileUtils.cp("#{process_dir}/audio.ogg", audio_dir)
		FileUtils.cp("#{process_dir}/events.xml", package_dir)
		FileUtils.cp_r("#{process_dir}/presentation", package_dir)

		# Create metadata.xml
		b = Builder::XmlMarkup.new(:indent => 2)		 
		metaxml = b.recording {
		  b.recordID(meeting_id)
		  b.state("available")
		  b.published(true)
		  b.start_time(Time.at((BigBlueButton::Events.first_event_timestamp("#{process_dir}/events.xml").to_f/1000.0)).utc)
		  b.end_time(Time.at((BigBlueButton::Events.last_event_timestamp("#{process_dir}/events.xml").to_f/1000.0)).utc)
		  b.playback {
		  	b.format("simple")
		  	b.link("http://#{playback_host}/playback/slides/playback.html?meetingId=#{meeting_id}")
	  	}
		  b.meta {
		  	BigBlueButton::Events.get_meeting_metadata("#{process_dir}/events.xml").each { |k,v| b.method_missing(k,v) }
	  	}			
		}
		
		puts "writing metadata to #{package_dir}/metadata.xml" 
		metadata_xml = File.new("#{package_dir}/metadata.xml","w")
		metadata_xml.write(metaxml)
		metadata_xml.close		
		
		# Now publish this recording		
		FileUtils.cp_r(package_dir, publish_dir)
			
		# Create index.html
		dir_list = Dir.entries(publish_dir) - ['.', '..']
		recordings = []
		dir_list.each do |d|
		  if File::directory?("#{publish_dir}/#{d}")
		    rec_time = File.ctime("#{publish_dir}/#{d}") 
		    play_link = "http://#{playback_host}/playback/slides/playback.html?meetingId=#{d}"
		    
		    metadata = BigBlueButton::Events.get_meeting_metadata("#{publish_dir}/#{d}/events.xml")
		    
                    recordings << {:rec_time => rec_time, :link => play_link, :title => metadata['title'].nil? ? metadata['meetingId'] : metadata['title']}
		  end
		end
		
		b = Builder::XmlMarkup.new(:indent => 2)		 
		html = b.html {
		  b.head {
		    b.title "Slides Playback Recordings"
		  }
		  b.body {
		    b.h1 "Slides Playback Recordings"
		      recordings.each do |r|
		        b.p { |y| 
		          y << r[:rec_time].to_s
		          b.a({:href => r[:link]}, r[:title])
		        }
		      end
		   }
		 }
		 
		index_html = File.new("#{publish_dir}/index.html","w")
		index_html.write(html)
		index_html.close
    File.chmod(0644, "#{publish_dir}/index.html")
	end
end
