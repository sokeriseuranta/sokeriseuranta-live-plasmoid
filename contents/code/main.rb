# <Copyright and license information goes here.>
require 'plasma_applet'
require 'net/http'
require 'json'

module SokeriseurantaLive
	class Main < PlasmaScripting::Applet
		slots 'updateData()'
	  
		def initialize parent
			super parent
		end

		def init
			@bgvalue = "--"
			@time = "--"
			
			self.has_configuration_interface = true
			#resize 125, 125
			self.aspect_ratio_mode = Plasma::Square
		
			
			# Do initial data update, then update periodically
			# every 5 minutes.
			updateData()
			@timer = Qt::Timer.new(self)
			connect(@timer, SIGNAL('timeout()'), self, SLOT('updateData()'))
			@timer.start(300000)
			
		end
		
		def updateData()
			# Fetch data from Sokeriseuranta Pebble API. 
			# Note: This API may not be stable or persistent.
			# Note: The API will return the lastest gluocse value
			# from a CGM device, *not* from fingerprick measurements.
			
			url = URI.parse('https://sokeriseuranta.fi/api/nightscout/pebble')			
			api_token = ""
			email = ""
			
			http = Net::HTTP.new(url.host, url.port)
			http.use_ssl = true
			
			req = Net::HTTP::Get.new(url.request_uri)		
			req.add_field("X-User-Email", email)
			req.add_field("X-Access-Token", api_token)
			res = http.request(req)
			
			# Return data is in the same format as Nightscout API
			# would return it. 
			# The Finnish decimal separator is comma, so replace the
			# dot. Also use Finnish time formatting.
			# The timestamp is the time of the latest available glucose
			# value. 
			json = JSON.parse(res.body)
			@bgvalue = json["bgs"][0]["sgv"].sub ".", ","
			timestamp = json["bgs"][0]["datetime"].to_s[0...-3].to_i
			@time = Time.at(timestamp).utc.strftime("%k.%M")
			
			update()
		end

		def paintInterface(painter, option, rect)
			# Small font font time and unit, large
			# and bold font for value
			
			painter.save
			font = Qt::Font.new
			font.setPixelSize 10
			painter.set_font font
			painter.pen = Qt::Color.new Qt::black
			painter.draw_text rect, Qt::AlignTop | Qt::AlignHCenter, @time
			painter.draw_text rect, Qt::AlignBottom | Qt::AlignHCenter, "mmol/l"
			font = Qt::Font.new
			font.setBold true
			font.setPixelSize 18
			painter.set_font font
			painter.draw_text rect, Qt::AlignVCenter | Qt::AlignHCenter, @bgvalue 
			painter.restore
		end
	end
end
