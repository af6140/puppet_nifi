module Ent
  module Nifi
    class Config
      def self.configure(url, cert_path, key_path)
        if @config.nil?
          @config = {}
          @config[:url] = url
          @config[:cert] = OpenSSL::X509::Certificate.new(File.read(cert_path))
          @config[:key] = OpenSSL::PKey::RSA.new(File.read(key_path))
        end
      end

      def self.config
        @config
      end
    end
  end
end