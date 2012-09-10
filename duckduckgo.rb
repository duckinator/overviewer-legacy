require 'open-uri'
require 'json'
require 'cgi'

class DuckDuckGo
  attr_accessor :json

  def initialize(query)
    @query = query

    @json = fetch_json(query)

    #pp @json
  end

  def method_missing(meth, *args, &block)
    key = meth.to_s.gsub('_', '')

    possible_keys = @json.keys.grep(Regexp.compile("^#{key}$", 'i'))
    key = possible_keys[0]

    if @json.keys.include?(key)
      ret = @json[key]
      ret = nil if ret.empty?
      ret
    else
      super # Default method_missing handler.
    end
  end

  def wikipedia_article
    return false unless abstract_source == 'Wikipedia'

    url = abstract_url

    url.gsub(/https.*\/wiki\//, '')
  end

  def fetch_raw(query)
    open("http://duckduckgo.com/?q=#{CGI.escape(query)}&format=json").read
  end

  def fetch_json(query)
    JSON.parse(fetch_raw(query))
  end
end
