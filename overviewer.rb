require File.join(File.dirname(__FILE__), 'dbpedia.rb')
require File.join(File.dirname(__FILE__), 'duckduckgo.rb')
require 'pp'
require 'sinatra'

# YES THIS ENTIRE THING IS A HACK. I KNOW. STOP.

$related_main = ''
$related = ''

$pre = <<EOF
<!DOCTYPE html>
<html>
<head>
<title>%title%</title>
<style type="text/css">
* {
  -moz-box-sizing:border-box;
  -webkit-box-sizing:border-box;
  box-sizing:border-box;
}

#wrap, body {
  margin: 0;
  padding: 0;
}

#wrap > * {
  padding: 10px;
}

blockquote {
  position: relative;

  margin: 10px;

  padding: 0 2.5em;

  font-style: italic;
}

blockquote::before, blockquote::after {
  position: absolute;
  font-size: 2em;
  font-weight: bold;
}

blockquote::before {
  content: '\\201C';
  margin-left: -1em;
  margin-top: -0.2em;
}

blockquote::after {
  content: '\\201D';
  right: 0.5em;
}

figure {
  position: relative;
}

figcaption::before {
  content: "\\2014";
}

figcaption {
  padding: 0;
  margin: 0;
  margin-left: 60px;
  font-style: italic;
}

#footer {
  font-size: 0.8em;
  border-top: 1px solid black;
  margin-top: 100px;
  clear: both;
}

#main {
  float: left;
  width: 75%;
}

#related {
  float: left;
  width: 25%;
  border: none;
  border-left: 1px solid black;
}

#header {
  margin: 0px;
  border: none;
  border-bottom: 1px solid black;
}

#header h1 {
  margin: 0;
  padding: 0 10px;
}

#header, #related {
  background: #eee;
}

%related_main%

</style>
</head>
<body>
<div id="wrap">

<div id="header">
  <h1>%title%</h1>
</div>

<div id="main">

EOF

$post = <<EOF
</div>

<div id="related">
  <p>Related content:</>
  <p>
    <ul>
%related%
    </ul>
  </p>
</div>

<div id="footer">
This site uses services the following:
<ul>
  <li><a href="http://duckduckgo.com">duckduckgo</a>: <a href="http://duckduckgo.com/api.html">Zero-click Info API</a>.</li>
  <li><a href="http://bing.com">Bing&trade;</a>: <a href="https://datamarket.azure.com/dataset/5BA839F1-12CE-4CCE-BF57-A49D98D29A44">Bing&trade; Search API</a>.</li>
  <li><a href="http://dbpedia.com">DBpedia</a>: <a href="http://wiki.dbpedia.org/OnlineAccess#h28-11">Linked Data sources</a>.</li>
</ul>
</div>

</div>
</body>
</html>
EOF

def quote(text, source, url)
  $text += <<EOF
<figure>
  <blockquote>#{text}</blockquote>
  <figcaption><a href=\"#{url}\">#{source}</a></figcaption>
</figure>
EOF
end

def test(query)
  $text = ''
  $related_main = ''
  $related = ''
  ddg = DuckDuckGo.new(query)
  #pp ddg.json
  #pp ddg.abstract
  #pp ddg.related

  #abstract = ddg.abstract
  #related  = ddg.related

  $title = query.capitalize

  if ddg.related_topics.length > 0
    ddg.related_topics.each do |topic|
      icon = topic['Icon']
      result = topic['Result'].gsub('<a href="http://duckduckgo.com/', '<a href="/?q=')
      result.gsub!('_','+')

      $related += "<li><img src=\"#{icon['URL']}\" width=\"#{icon['Width']}\" height=\"#{icon['Height']}\"> #{result}</li>\n"
    end
  end

  if !ddg.definition && !ddg.abstract
    $related_main = '#related { background: white; float: none; width: 100%; border-left: none; }'
  end

  if ddg.definition
    quote(ddg.definition, ddg.definition_source, "")
  end

  if ddg.abstract
    quote(ddg.abstract, ddg.abstract_source, ddg.abstract_url)
  end

=begin
  if ddg.related_topics
    ddg.related_topics.each do |topic|
      pp topic
      _puts topic['Text']
    end
  end
=end
pp ddg.json
  # Wikipedia

  if ddg.wikipedia_article
    dbp = DBPedia.new(ddg.wikipedia_article)
    #dbp.test
  end
end

get '/' do
  ret = ''

  if params[:q]
    test params[:q]
    ret = $pre + $text + $post
  else
    $title = 'Overviewer'
    ret = $pre + '<form action="/" method="GET"><input type="text" id="q" name="q"><input type="submit" value="Search"></form>' + $post
  end

  ret.gsub!('%title%', $title)
  ret.gsub!('%related%', $related)
  ret.gsub!('%related_main%', $related_main)

  ret
end
