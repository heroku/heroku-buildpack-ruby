begin

  STDOUT.sync = true

  def Rails.heroku_stdout_logger
    logger = Logger.new(STDOUT)
    logger.level = Logger.const_get(([ENV['LOG_LEVEL'].to_s.upcase, "INFO"] & %w[DEBUG INFO WARN ERROR FATAL UNKNOWN]).compact.first)
    logger
  end

  case Rails::VERSION::MAJOR
    when 3 then Rails.logger = Rails.application.config.logger = Rails.heroku_stdout_logger
    when 2 then
      # redefine Rails.logger
      def Rails.logger
        @@logger ||= Rails.heroku_stdout_logger
      end
      %w(
        ActiveSupport::Dependencies
        ActiveRecord::Base
        ActionController::Base
        ActionMailer::Base
        ActionView::Base
        ActiveResource::Base
      ).each do |klass_name|
        begin
          klass = Object
          klass_name.split("::").each { |part| klass = klass.const_get(part) }
          klass.logger = Rails.logger
        rescue
        end
      end
      Rails.cache.logger = Rails.logger rescue nil
  end

rescue Exception => ex

  puts "WARNING: Exception during rails_log_stdout init: #{ex.message}"

end
