require 'plugins/wolfram/wolfram.rb'
api=WolframApi.new
xml=open('plugins/wolfram/test/wolfram_response.xml'){|f|f.read}
puts WolframApi.new.parse(xml).inspect
