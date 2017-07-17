module Ent
  module Nifi
    class ExceptionHandler
      def self.process(e)
        # by default, include exception message
        msg = e.to_s
        #msg += ', details: ' + retrieve_error_message(e.http_body) if e.respond_to? :http_body
        yield msg
      end
    end
  end
end
