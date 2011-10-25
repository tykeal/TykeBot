
$bot.add_command(
	:syntax      => 'fail',
	:description => 'Produces a whale',
	:regex       => /^fail$/,
	:is_public   => true,
  :html => true
) {
'
 <body>

       \"""/ 
        | |
▄██████████████▄▐█▄▄▄▄█▌
████████████████▌▀▀██▀▀
████▄████████████▄▄█▌
▄▄▄▄▄██████████████▀

</body>
  <html xmlns="http://jabber.org/protocol/xhtml-im">
    <body xmlns="http://www.w3.org/1999/xhtml">
      <p style="font-family:Andale Mono">

       \"""/ 
        | |
▄██████████████▄▐█▄▄▄▄█▌
████████████████▌▀▀██▀▀
████▄████████████▄▄█▌
▄▄▄▄▄██████████████▀

      </p>
    </body>
  </html>

        
'
}


