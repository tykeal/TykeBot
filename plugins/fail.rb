
plugin.add_command(
	:syntax      => 'fail',
	:description => 'Produces a whale',
	:regex       => /^fail$/,
	:is_public   => true,
  :html => true
) {
  html = 	Jabber::XHTML::HTML.new(
'
      <p style="font-family:Andale Mono">

       \"""/ 
        | |
▄██████████████▄▐█▄▄▄▄█▌
████████████████▌▀▀██▀▀
████▄████████████▄▄█▌
▄▄▄▄▄██████████████▀

      </p>
')
}


