
plugin.add_command(
	:syntax      => 'rand',
	:description => 'Produce a random number from 0 to 10',
	:regex       => /^rand$/,
	:is_public   => true
) { rand(10).to_s }

