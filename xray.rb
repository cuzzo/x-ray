require "net/http"
require "nokogiri"
require "active_support/all"

USER_AGENT = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Ubuntu Chromium/66.0.3359.181 Chrome/66.0.3359.181 Safari/537.36"

def request(url)
  uri = URI(url)
  http = Net::HTTP.new(uri.host, uri.port)

  http.use_ssl = true if uri.port == 443

  request = Net::HTTP::Get.new(uri.request_uri)
  request.initialize_http_header({"User-Agent" => USER_AGENT})

  resp = http.request(request)
  if resp.code.to_i != 200
    raise "HTTP ERROR: #{url} -> #{resp.code}"
  end

  resp.body
end

# Get the css selector from an operation
def parse_selector(operation)
  operation
    .split(/[|@>]/)
    .first
    .strip
end

# Get the attribute selector from an operation
def parse_attribute(operation)
  operation
    .split("@")
    .last
    .match(/[\w_:-][\w\d\._:-]+/)[0]
end

def parse_pipe(pipe)
  type = pipe[0] == "|" ? :map : :select
  function = pipe[1..-1].strip
  [type, function]
end

# Selects an attribute from a set of elements.
def xattribute(els, operation)
  attribute_name = parse_attribute(operation)
  if attribute_name == "el"
    els
  elsif attribute_name == "html"
    els.map { |el| el.inner_html }
  else
    els.map { |el| el.attributes[attribute_name].value }
  end
end

# Execute a piped function on a given element value.
def xpipe(function, val)
  if val.respond_to?(function)
    val.send(function)
  else
    send(function, val)
  end
end

# Run a list of piped functions on a set of selected elements
def xchain(elements, operation)
  operation
    .scan(/[|>]\s*[\w_][\w\d_!?]+/)
    .reduce(elements) do |acc, pipe|
      type, function = parse_pipe(pipe)
      acc.send(type) { |val| xpipe(function, val) }
    end
end

def xstring(doc, operation)
  els = doc.css(parse_selector(operation))

  if operation.include?("@")
    els = xattribute(els, operation)
  else
    els = els.map { |el| el.text }
  end

  if operation.include?("|") || operation.include?(">")
    els = xchain(els, operation)
  end

  els
end

def xhash(doc, hash)
  hash.reduce({}) do |acc, (key, command)|
    operation = command.is_a?(Array) ? command.first : command
    val = xstring(doc, operation)
    val = val.first unless command.is_a?(Array)
    acc[key] = val
    acc
  end
end

# Execute a declarative xray command on a Nokogiri HTML Document.
def xcommand(doc, command)
  if command.is_a?(Hash)
    xhash(doc, command)
  elsif command.is_a?(String)
    xstring(doc, command)
  elsif command.is_a?(Array)
    xcommand(doc, command.first)
  else
    raise "Type <#{command.class}> not supported."
  end
end

def xray(url, scope, selector=nil)
  doc = Nokogiri::HTML(request(url))

  if selector
    doc = scope.is_a?(String) ?
      doc.css(scope).first :
      doc.css(scope.first)
    command = selector
  else
    command = scope
  end

  if doc.is_a?(Nokogiri::XML::NodeSet)
    doc.map { |el| xcommand(el, command) }
  else
    els = xcommand(doc, command)
    command.is_a?(String) ?
      els.first :
      els
  end
end
