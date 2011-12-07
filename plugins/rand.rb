command do
  description 'Respond with a random integer between 0 and max, with default max of 10.'
  action :optional=>:max do |msg,max|
    rand(bound(max,:min=>1,:max=>2**32,:default=>10)).to_s 
  end
end
