require 'open-uri'
require 'json'

class DBPedia
  attr_accessor :json

  PRIMARY_TOPIC_IDENTIFIER = 'http://xmlns.com/foaf/0.1/primaryTopic'
  REDIRECT_IDENTIFIER      = 'http://dbpedia.org/ontology/wikiPageRedirects'
  RDF_LABEL_IDENTIFIER     = 'http://www.w3.org/2000/01/rdf-schema#label'

  RESOURCE_NAME_IDENTIFIER = 'http://xmlns.com/foaf/0.1/name'

  def initialize(page)
    @page = page

    @article = 'http://dbpedia.org/page/' + @page
    @data_prefix = 'http://dbpedia.org/data/' + page

    @json = fetch_json
  end

  def topic_raw
    return @topic_raw if @topic_raw

    key = nil

    @json.keys.each do |k|
      if primary_topic?(k)
        key = k
        break
      end
    end

    return nil unless key

    @topic_raw = @json[key][PRIMARY_TOPIC_IDENTIFIER][0]
  end

  def topic
    return @topic if @topic
    t = topic_raw

    raise "Cannot get URI of nonexistent topic!" if t.nil?
    
    return nil unless t['type'] == 'uri'

    @topic = t['value']
  end

  def labels
    ret = {}

    @json[topic].each do |key, value|
      if key == RDF_LABEL_IDENTIFIER
        value.each do |hash|
          type = hash['type']
          lang = hash['lang']

          ret[type] ||= {}
          ret[type][lang] = hash['value']
        end
      end
    end

    pp ret
    exit
  end

  def name
    @json[topic].each do |key, value|
      if key == RESOURCE_NAME_IDENTIFIER
        return value[0]['value']
      end
    end
  end

  def primary_topic?(key)
    __check_child_key(key, PRIMARY_TOPIC_IDENTIFIER)
  end

  def redirect?(key)
    __check_child_key(key, REDIRECT_IDENTIFIER)
  end

  def test

p name
p labels
#pp @json[topic_uri]
#pp @json
exit

@json.each do |url, resource|
  next if redirect?(url)

  puts
  pp url, resource
end

  end

  # Utility functions
  def fetch_json
    JSON.parse(open(@data_prefix + '.json').read)
  end

  def __check_child_key(key, value)
    @json[key].keys[0] == value
  end
end
