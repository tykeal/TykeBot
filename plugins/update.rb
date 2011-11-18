#command(:rand, :description => 'Produce a random number from 0 to 10') { rand(10).to_s }

command(:update, :description => 'Make bot update to the latest revision', :is_public => false) {
  `#{config[:update_script]}`
}

init do
  config[:update_script] || = '~/deploy/tykebot/current/scripts/run_update.sh'
end
