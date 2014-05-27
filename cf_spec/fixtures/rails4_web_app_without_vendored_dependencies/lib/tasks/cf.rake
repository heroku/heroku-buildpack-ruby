namespace :cf do
  desc "Only run on the first application instance. Migrates etc."
  task :on_first_instance do
    instance_index = JSON.parse(ENV["VCAP_APPLICATION"])["instance_index"] rescue nil
    exit(0) unless instance_index == 0
    Rake::Task['db:migrate'].invoke
  end
end
