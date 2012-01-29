require 'free-image'
require 'aalib'

helper :get_image do |url|
	image_data = http_get(url).body
	WIDTH = 160
	HEIGHT = 80
	memory = FreeImage::Memory.new(image_data)
	image = FreeImage::Bitmap.open(memory)
	image = image.rescale(WIDTH, HEIGHT)
	
	
	
	hardware = AAlib::HardwareParams.new
	render = AAlib::RenderParams.new
	
	hardware.width = WIDTH
	hardware.height = HEIGHT
	
	context = AAlib.init(AAlib.memory_driver, hardware)
	
	0.upto(WIDTH-1) do |x|
		0.upto(HEIGHT-1) do |y|
			rgb = image.pixel_color(x, HEIGHT-1-y).values
			r = rgb[2]
			g = (rgb[1] & 0xFF00) >> 8
			b = (rgb[0] & 0xFF0000) >> 16
			pixel = (r+g+b) / 3
			context.putpixel(x, y, pixel)
		end
	end
	
	context.render(render)
	context.flush
	ascii = context.text
	result = "<br/><p style='font-family: Courier New;'>"
	0.upto(HEIGHT/2-1) do |row|
		current_row = "#{ascii[row*WIDTH, WIDTH/2]}"
		current_row.gsub!('&', '&amp;')
		current_row.gsub!('<', '&lt;')
		current_row.gsub!('>', '&gt;')
		result << current_row
		result << "<br/>"
	end
	
	result << "</p>"
	result
end

command do
  description "Load an image from a url"
  
  action(:required=>:url,:html=>true) do |message,url|
    begin
      get_image(url)
    rescue
      error
      "!fail"
    end
  end
end

