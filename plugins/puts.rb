command(:puts,
  :required=>:string,
	:description => 'Write something to $stdout',
  :is_public   =>  false
) do |sender, message|
	puts "#{sender} says '#{message}'"
	"'#{message}' written to $stdout"
end
