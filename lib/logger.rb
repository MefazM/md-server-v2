require 'logger'


module TheLogger
  class << self
    attr_accessor :output

    def error msg
      logger.error msg
    end

    def info msg
      logger.info msg
    end

    def warn msg
      logger.warn msg
    end

    private

    def logger
      @logger ||= Logger.new output || STDOUT
    end
  end
end
