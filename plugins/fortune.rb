forcedevent = nil

def get_fortune
  `/usr/bin/fortune`
end

command(:fortune,
  :description => 'get a fortune'
) { get_fortune() }
