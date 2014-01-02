module Wrapper
  require 'open-uri'
  require 'cgi'
  require 'rexml/document'
  
  @@template_content = ""
  def self.template_content=(content)
    @@template_content = content
  end
  
  def self.wrap(wrapped_jnlp, href, vendor, project, version, old_versions, default_jnlp, max_heap)
  	max_heap = "128" unless max_heap
    url_base = href.sub(/[^\/]+\/[^\/]+\.jnlp.*$/, "")
    not_found = "#{INSTALL_APP}/#{project}/#{version}"

    #wrapped_jnlp = "#{url_base}unwrap?"
    #wrapped_jnlp << "title=#{project}%20#{version}"
    #wrapped_jnlp << "&amp;description=#{project}%20#{version}%20Launcher"
    #wrapped_jnlp << "&amp;vendor=#{vendor}"
    #wrapped_jnlp << "&amp;homepage=#{project}.concord.org"
    #wrapped_jnlp << "&amp;href=#{url_base}unwrap"
    #wrapped_jnlp << "&amp;jnlp=#{jnlp}"
    
    wrapped_content = @@template_content.gsub("${vendor}", vendor)
    wrapped_content.gsub!("${project}", project)
    wrapped_content.gsub!("${version}", version)
    wrapped_content.gsub!("${href}", href)
    wrapped_content.gsub!("${not_found}", not_found)
    wrapped_content.gsub!("${max_heap}", max_heap)

    optional_props = ""
    if old_versions
      optional_props += "<property name=\"product_old_versions\" value=\"#{old_versions}\" />\n"
    end

    if wrapped_jnlp
      optional_props += "<property name=\"wrapped_jnlp\" value=\"#{wrapped_jnlp}\" />\n"
    end    

    if default_jnlp
      optional_props += "<property name=\"default_jnlp\" value=\"#{default_jnlp}\" />\n"
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