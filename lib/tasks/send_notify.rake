task :send_notify => :environment do
  CollectDataService.new.perform
end
