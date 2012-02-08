command do
  description "echo a string"
  action :required=>:s do |s|
    s
  end
end
