module Ent
  module Nifi
    class Config
      def self.configure(url, cert_path, key_path)
        if @config.nil?
          @config = {}
        end
        @config[:url] = url
        if cert_path
          @config[:cert] = OpenSSL::X509::Certificate.new(File.read(cert_path))
        end
        if(key_path)
          @config[:key] = OpenSSL::PKey::RSA.new(File.read(key_path))
        end
      end
      def self.config
        @config
      end
    end
  end
end