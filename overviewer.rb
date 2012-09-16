require File.join(File.dirname(__FILE__), 'dbpedia.rb')
require File.join(File.dirname(__FILE__), 'duckduckgo.rb')
require 'pp'
require 'sinatra'
require 'liquid'
require 'uri'
require 'cgi'

class Overviewer < Sinatra::Application
  def quote(text, source, url)
    <<-EOF
<figure>
  <blockquote>#{text}</blockquote>
  <figcaption><a href=\"#{url}\">#{source}</a></figcaption>
</figure>
    EOF
  end

  def handle_topics(query, topics, type)
    ret = []

    topics.each do |topic|
      if topic.is_a?(Hash) && topic.include?('Topics')
        # This returns something of the format:
        # {"Topics"=>
        #   [{"Result"=>
        #      ...},
        #    <snip>
        #    {"Result"=>
        #      ...}],
        #  "Name"=>"Category"}
        #
        # This should probably use 'Name', but it doesn't for now.
        ret += handle_topics(query, topic['Topics'], type)
        next
      end

      icon = topic['Icon']
      result = topic['Result']

      result.gsub!('<a href="http://duckduckgo.com/c/', '<a href="/?type=category&amp;q=')
      result.gsub!('<a href="http://duckduckgo.com/', '<a href="/?q=')
      result.gsub!('_','+')

      result_query = result.split('<a href="')[-1].split('">')[0]
      query_hash = CGI::parse(URI.parse(result_query).query)
      result_type = (query_hash['type'] || ['']).last

      if (CGI.escape(query).downcase == result_query.downcase) && (result_type == type)
        next
      end

      ret << [icon['URL'], result]
    end

    ret
  end

  def ddg(query, type = nil)
    summary = ''
    ddg = DuckDuckGo.new(query)

    is_category = (type == 'category')

    related = handle_topics(query, (ddg.json['RelatedTopics'] || []), type)
    article = ddg.wikipedia_article

    if ddg.definition && !is_category
      summary += quote(ddg.definition, ddg.definition_source, "")
    end

    if ddg.abstract && !is_category
      summary += quote(ddg.abstract, ddg.abstract_source, ddg.abstract_url)
    end

=begin
    if ddg.related_topics
      ddg.related_topics.each do |topic|
        pp topic
        _puts topic['Text']
      end
    end
=end

    if is_category || (!ddg.definition && !ddg.abstract)
      type = 'category'
    end

    article = nil unless ddg.uses_wikipedia? && !summary.empty?

    [summary, related, type, article]
  end

  def dbpedia(article, type = nil)
    DBPedia.new(article)
  end

  get '/' do
    summary = ''
    article = nil

    query = params[:q]
    type  = params[:type] || ''

    if query
      summary, related, type, article = ddg(query, type)
    end

    hash = {
      :type    => type,
      :title   => query,
      :name    => query,
      :query   => query,
      :related => related,
    }

    if query && !summary.empty?
      hash[:wikipedia] = article

      if hash[:wikipedia]
        dbp = dbpedia(article, type)

    puts;puts
    pp dbp.test
    puts;puts

        hash[:title] = hash[:name] = dbp.name if dbp.name.is_a?(String)

        hash[:wp_url] = dbp.url
        hash[:summary] = dbp.summary || dbp.comment
        hash[:summary_source_url]  = dbp.url
        hash[:summary_source_name] = 'Wikipedia'

        hash[:homepage] = dbp.homepage

        hash[:geo_lat]  = dbp.geo_lat
        hash[:geo_long] = dbp.geo_long
        hash[:geo_full] = dbp.geo_full

        if hash[:geo_lat] && hash[:geo_long]
          hash[:map_url] = "https://maps.google.com/maps?q=#{CGI.escape(query)}&sll=#{hash[:geo_lat]},#{hash[:geo_long]}"
          hash[:map_site_name] = 'Google Maps'
        end

        # hash[:links] is an or'd (||) list of URLs,
        # so it's truthy if there's a URL to show.
        hash[:links] = hash[:homepage] || hash[:map_url]
      else
        # Not using this since we can't guarantee it's properly attributed.
        hash[:noresults] = true
        #hash[:raw_summary] = summary
      end
    end

    hash[:type] = 'category' if hash[:summary].nil? || hash[:summary].empty?

    liquid :index, :locals => hash
  end
end
