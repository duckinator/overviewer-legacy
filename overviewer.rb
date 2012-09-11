require File.join(File.dirname(__FILE__), 'dbpedia.rb')
require File.join(File.dirname(__FILE__), 'duckduckgo.rb')
require 'pp'
require 'sinatra'
require 'liquid'

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
      if topic.is_a?(Hash) && topic['Topics']
        handle_topics(query, topic['Topics'], type)
      end

      unless topic['Result']
        pp topic
        exit
      end

      icon = topic['Icon']
      result = topic['Result']

      result.gsub!('<a href="http://duckduckgo.com/c/', '<a href="/?type=category&amp;q=')
      result.gsub!('<a href="http://duckduckgo.com/', '<a href="/?q=')
      result.gsub!('_','+')

      # HACK.
      result_query = if result.include?('?q=')
        result.split('?q=')[1]
      elsif result.include?('&amp;q=')
        result.split('&amp;q=')[1]
      else
        ''
      end.split('"')[0]

      result_type = if result.include?('?type=')
        result.split('?type=')[1]
      elsif result.include?('&type')
        result.split('&type=')[1]
      else
        ''
      end.split('&')[0]

      if (CGI.escape(query).downcase == result_query.downcase) && (result_type == type)
        next
      end

      ret << [icon['URL'], result]
    end

    ret
  end

  def test(query, type = false)
    text = ''
    ddg = DuckDuckGo.new(query)

    is_category = (type == 'category')

    related = handle_topics(query, (ddg.json['RelatedTopics'] || []), type)

    if ddg.definition && !is_category
      text += quote(ddg.definition, ddg.definition_source, "")
    end

    if ddg.abstract && !is_category
      text += quote(ddg.abstract, ddg.abstract_source, ddg.abstract_url)
    end

=begin
    if ddg.related_topics
      ddg.related_topics.each do |topic|
        pp topic
        _puts topic['Text']
      end
    end
=end
    #pp ddg.json
    # Wikipedia

    if ddg.wikipedia_article
      dbp = DBPedia.new(ddg.wikipedia_article)
      #dbp.test
    end

    if is_category || (!ddg.definition && !ddg.abstract)
      type = 'category'
    end

    [text, related, type]
  end

  get '/' do
    text = ''

    query = params[:q]
    type  = params[:type] || ''

    if query
      text, related, type = test(query, type)
    end

    liquid :index, :locals => {
      :type    => type,
      :title   => query,
      :related => related,
      :text    => text,
    }
  end
end
