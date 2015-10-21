module NeAPI
  class Logger
    attr_accessor :logger
    def initialize
      @logger ||= Logger.new(STDOUT)
    end
    def write subject, body
      @logger.debug sprintf("%s: %s", subject, body)
    end
  end
end
