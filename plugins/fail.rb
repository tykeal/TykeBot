plugin.add_command(
	:syntax      => 'fail',
	:description => 'Produces a whale',
	:regex       => /^fail$/,
	:is_public   => true,
  :html => true
) {
'
      <p style="font-family:Andale Mono,Menlo">

<br/>       \"""/ 
<br/>        | |
<br/>▄██████████████▄▐█▄▄▄▄█▌
<br/>████████████████▌▀▀██▀▀
<br/>████▄████████████▄▄█▌
<br/>▄▄▄▄▄██████████████▀
<br/>
      </p>
'
}


