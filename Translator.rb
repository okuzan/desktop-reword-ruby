require 'net/http'
require 'rubygems'
require "uri"
require 'json'

class UnSupportedLanguage < RuntimeError

  def initialize(message = '')
    @msg = "not supported."
  end
end

def lc(text, to, from = 'en')

  begin

    uri = URI.parse("http://mymemory.translated.net/api/get")

    response = Net::HTTP.post_form(uri, {:q => text, :langpair => "#{from.to_s.downcase}|#{to.to_s.downcase}", :per_page => '50'})

    json_response_body = JSON.parse(response.body)

    if json_response_body['responseStatus'] == 200
      json_response_body['responseData']['translatedText']
    else
      puts json_response_body['responseDetails']
      raise StandardError, response['responseDetails']
    end
  rescue UnSupportedLanguage
    raise UnSupportedLanguage.new
  rescue => err_msg
    puts "#{err_msg}"
  end
end
