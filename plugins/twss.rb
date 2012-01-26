require 'uri'
#https://github.com/bvandenbos/twss
#https://github.com/sausheong/naive-bayes  without the steemer 
#
on :firehose do |bot,message|
  if message.body != nil   
   if message.body.size>6 && bot.sender(message) != bot.name
    said=who_said_it(message.body)
    if(said=="she_said")
      bot.send(:text=>"Thats what she said!")
    end
   end
  end
end

helper :who_said_it do |body|
  TWSS_CLASSIFIER.classify(body) 
end

