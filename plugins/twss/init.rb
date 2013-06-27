require 'uri'
#https://github.com/bvandenbos/twss
#https://github.com/sausheong/naive-bayes  without the steemer 
twss = NaiveBayes.new(["she_said","she_didnt_say"])
started = false

on :join do |bot|
  timer(2) do 
    load_file("good.txt").each_line{|line|twss.train("she_said",line)}
    load_file("bad.txt").each_line{|line|twss.train("she_didnt_say",line)}
    started = true 
  end
end

on :firehose do |bot,message|
  if started && message.body != nil   
   if message.body.size>6 && !message.sender.bot?
    said=who_said_it(message.body)
    if(said=="she_said" && rand(10)==4)
      bot.send(:text=>"That's what she said!")
    end
   end
  end
end

helper :who_said_it do |body|
  twss.classify(body) 
end

