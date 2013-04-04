require 'open-uri'
require 'json'

class DBPedia
  attr_accessor :json, :article, :url,
                :comment, :summary, :homepage, :name,
                :geo_lat, :geo_long, :geo_full, :geo_geometry,
                :property, :ontology

  PRIMARY_TOPIC_IDENTIFIER = 'http://xmlns.com/foaf/0.1/primaryTopic'
  DEPICTION_IDENTIFIER     = 'http://xmlns.com/foaf/0.1/depiction'
  REDIRECT_IDENTIFIER      = 'http://dbpedia.org/ontology/wikiPageRedirects'
  RDF_LABEL_IDENTIFIER     = 'http://www.w3.org/2000/01/rdf-schema#label'
  RDF_COMMENT_IDENTIFIER   = 'http://www.w3.org/2000/01/rdf-schema#comment'
  OWL_SAMEAS_IDENTIFIER    = 'http://www.w3.org/2002/07/owl#sameAs'

  RDF_TYPE_IDENTIFIER      = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type'

  RESOURCE_NAME_IDENTIFIER = 'http://xmlns.com/foaf/0.1/name'

  SUBJECT_IDENTIFIER       = 'http://purl.org/dc/terms/subject' # Categories?

  HOMEPAGE_IDENTIFIER      = 'http://xmlns.com/foaf/0.1/homepage'

  GEO_LAT_IDENTIFIER       = 'http://www.w3.org/2003/01/geo/wgs84_pos#lat'
  GEO_LONG_IDENTIFIER      = 'http://www.w3.org/2003/01/geo/wgs84_pos#long'
  GEO_FULL_IDENTIFIER      = 'http://www.georss.org/georss/point'
  GEO_GEOMETRY             = 'http://www.w3.org/2003/01/geo/wgs84_pos#geometry'

  DERIVED_FROM_IDENTIFIER  = 'http://www.w3.org/ns/prov#wasDerivedFrom'

  PRIMARY_TOPIC_OF         = 'http://xmlns.com/foaf/0.1/isPrimaryTopicOf'

  DBPEDIA_PROPERTY_REGEX   = Regexp.compile "http://dbpedia.org/property/(.*)"
  DBPEDIA_ONTOLOGY_REGEX   = Regexp.compile "http://dbpedia.org/ontology/(.*)"

  def initialize(page, lang = 'en')
    @page = page

    @lang = lang

    @article = page
    @url  = "http://#{@lang}.wikipedia.org/wiki/#{@article}"

    @dbp_article_url = 'http://dbpedia.org/page/' + @page
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

  def handle_json
    ret = {}

    @json[topic].each do |key, value|
      case key
      when PRIMARY_TOPIC_IDENTIFIER
        puts "DBpedia primary topic"
        pp value;puts;puts
      when DEPICTION_IDENTIFIER
        puts "DBpedia depiction"
        pp value;puts;puts
      when REDIRECT_IDENTIFIER
        puts "DBpedia redirect"
        pp value;puts;puts
      when RDF_LABEL_IDENTIFIER
        value.each do |hash|
          type = hash['type']
          lang = hash['lang']

          ret[type] ||= {}
          ret[type][lang] = hash['value']
        end
        pp ret
      when RDF_COMMENT_IDENTIFIER
        value.each do |h|
          if h['type'] == 'literal' && h['lang'] == @lang
            @comment = h['value']
            break
          end
        end
        puts "DBpedia RDF comment:"
        pp comment;puts;puts
      when OWL_SAMEAS_IDENTIFIER
        puts "DBpedia OWL sameas"
        pp value;puts;puts
      when RDF_TYPE_IDENTIFIER
        puts "DBpedia RDF type"
        pp value;puts;puts
      when RESOURCE_NAME_IDENTIFIER
        @name = value[0][:value]
      when SUBJECT_IDENTIFIER
        puts "DBpedia subject"
        pp value;puts;puts
      when HOMEPAGE_IDENTIFIER
        # Homepage should only be one link...
        @homepage = value[0]['value']
      when GEO_LAT_IDENTIFIER
        @geo_lat = value[0]['value']
      when GEO_LONG_IDENTIFIER
        @geo_long = value[0]['value']
      when GEO_FULL_IDENTIFIER
        @geo_str = value[0]['value']
      when GEO_GEOMETRY
        puts "DBpedia geo (geometry)"
        pp value;puts;puts
      when DERIVED_FROM_IDENTIFIER
        puts "DBpedia derived from"
        pp value;puts;puts      
      when PRIMARY_TOPIC_OF
        puts "DBpedia topic of"
        pp value;puts;puts
      when DBPEDIA_PROPERTY_REGEX
        puts "DBpedia property: #{$1}"
        pp value;puts;puts
      when DBPEDIA_ONTOLOGY_REGEX
        puts "DBpedia ontology: #{$1}"
        pp value;puts;puts
      else
        puts;puts 'UNKNOWN:'
        pp key
        pp value
        puts;puts
      end
    end
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
handle_json
#pp @json[topic_uri]
#pp @json
return
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
