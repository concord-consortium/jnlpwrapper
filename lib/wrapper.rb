module Wrapper
  require 'open-uri'
  require 'cgi'
  require 'rexml/document'
  require 'stringio'
  require 'base64'
  require 'zlib'

  require 'app_config'
  CONFIG = AppConfig.config

  INSTALL_APP = "http://install.diy.concord.org"

  @@template_content = {}
  def self.add_template(type, content)
    @@template_content[type] = content
  end

  def self.get_template_copy(type)
    (@@template_content[type] || "").dup
  end

  def self.encode(str)
    out = StringIO.new
    gz = Zlib::GzipWriter.new(out)
    gz.write str
    gz.close
    Base64.encode64(out.string).gsub(/\n/, '')
  end

  def self.is_valid_jnlp(jnlp=nil)
    return false if jnlp.nil?
    return true unless CONFIG[:valid_domains]
    return true if jnlp =~ %r!^http(s)?://[^/]*(#{CONFIG[:valid_domains].join('|')})/!
    return false
  end

  def self.wrap(opts = {}) # wrapped_jnlp, href, vendor, project, version, old_versions, default_jnlp, max_heap
    raise "Missing required option :href" unless opts[:href]
    raise "Missing required option :vendor" unless opts[:vendor]
    raise "Missing required option :project" unless opts[:project]
    raise "Missing required option :version" unless opts[:version]
    raise "Missing required option :template" unless opts[:template]

    # Force moving from jnlp.concord.org to jars.dev.concord.org
    opts[:href] = opts[:href].sub("jnlp.concord.org","jars.dev.concord.org")
    opts[:wrapped_jnlp] = opts[:wrapped_jnlp].sub("jnlp.concord.org","jars.dev.concord.org") if is_valid_jnlp(opts[:wrapped_jnlp])
    opts[:default_jnlp] = opts[:default_jnlp].sub("jnlp.concord.org","jars.dev.concord.org") if is_valid_jnlp(opts[:default_jnlp])

    opts = {
      :max_heap => 512,
      :url_base => (opts[:href] || "").sub(/[^\/]+\/[^\/]+\.jnlp.*$/, ""),
      :not_found => "#{INSTALL_APP}/#{opts[:project]}/#{opts[:version]}"
    }.merge(opts)

    wrapped_content = get_template_copy(opts[:template])
    [:vendor, :project, :version, :href, :not_found, :max_heap].each do |sym|
      wrapped_content.gsub!("${#{sym.to_s}}", opts[sym].to_s) if opts[sym]
    end

    optional_props = ""
    optional_props += "<property name=\"jnlp.product_old_versions\" value=\"#{opts[:old_versions]}\" />\n" if opts[:old_versions]
    optional_props += "<property name=\"jnlp.default_jnlp\" value=\"#{opts[:default_jnlp]}\" />\n" if is_valid_jnlp(opts[:default_jnlp])
    if is_valid_jnlp(opts[:wrapped_jnlp])
      optional_props += "<property name=\"jnlp.wrapped_jnlp\" value=\"b64gz:#{encode(opts[:wrapped_jnlp])}\" />\n"
      if opts[:wrapped_jnlp] =~ /jars\.dev\.concord\.org/
        optional_props += "<property name=\"jnlp.jnlp2shell.static_www\" value=\"true\"/>"
        optional_props += "<property name=\"jnlp.jnlp2shell.mirror_host\" value=\"jars.dev.concord.org\"/>"
      end
    end

    wrapped_content.gsub!("${optional_props}", optional_props)

    return wrapped_content
  end
  
  def self.unwrap(jnlp, opts = {})
    # have to pass in href, title, description, vendor, homepage, jnlp_properties, argument
    jnlp = REXML::Document.new(open(jnlp).read).root
    jnlp.attributes["href"] = opts['href'] if opts['href']
    
    # modify the jnlp info
    jnlp_info = jnlp.elements['information']
    jnlp_info.elements['title'].text = opts['title'] if opts['title']
    jnlp_info.elements['description'].text = opts['description'] if opts['description']
    jnlp_info.elements['vendor'].text = opts['vendor'] if opts['vendor']
    jnlp_info.elements['homepage'].attributes['href'] = opts['homepage'] if opts['homepage']
    
    # add various properties
    resources = jnlp.elements['resources[not(@os)]']
    if opts['jnlp_properties']
      opts['jnlp_properties'].split("&").each do |prop_pair|
        arr = prop_pair.split("=")
        resources << (pr = REXML::Element.new("property"))
        pr.attributes["name"] = CGI.unescape(arr[0])
        pr.attributes["value"] = CGI.unescape(arr[1])
      end
    end
    
    app_desc = jnlp.elements["application-desc"]
    # modify the main class
    if app_desc.attributes["main-class"] =~ /net\.sf\.sail\.emf\.launch\.EMFLauncher3/
      app_desc.attributes["main-class"] = "net.sf.sail.emf.launch.EMFLauncher2"
    end
    
    # modify the argument
    app_desc.elements['argument'].text = opts['argument'] if opts['argument']
    
    return jnlp.to_s
  end
end
