#!/usr/bin/env ruby

class Log
    # Open its singleton class
    class << self

        ISSUE_NUMBER ||= ENV.fetch('ISSUE_NUMBER', -1)
        DATE_FORMAT = '%Y-%m-%d %H:%M:%S'

        attr_writer :logger

        def logger=(logger)
            @logger = logger
            @logger.formatter = proc do |severity, datetime, _, msg|
                date_format = datetime.strftime(DATE_FORMAT)
                "[#{date_format}][#{severity}][#{ISSUE_NUMBER}]#{msg}\n"
            end
        end

        %w[debug info warn error fatal unknown].each do |name|
            define_method name do |component, message|
                @logger.send(name, "[#{component}]: #{message}") if @logger
            end
        end
    end
end
