require 'rubygems'
require 'bundler'

Bundler.require

$LOAD_PATH.unshift 'lib'

require 'wrapper'

configure do
  set :public_folder, File.dirname(__FILE__) + '/public'
  mime_type :jnlp, 'application/x-java-jnlp-file'
  mime_type :ccla, 'application/vnd.concordconsortium.launcher'

  Wrapper.add_template(:install, open(File.dirname(__FILE__) + '/templates/install.jnlp').read)
  Wrapper.add_template(:jcl, open(File.dirname(__FILE__) + '/templates/jcl.jnlp').read)
end

def raw_post
  request.env["rack.input"].read
end

def useragent
  UserAgent.parse(request.user_agent)
end

get '/' do
  redirect '/index.html'
end

get '/:project/:version.jnlp' do
  content_type :jnlp
  last_modified(Time.now)
  ua = useragent
  if ua.platform == "Macintosh" && ua.os =~ /10\.(\d+)(\.\d+)?$/ && $1.to_i >= 9
    #redirect to the ccla file
    redirect request.fullpath.sub(/\.jnlp/, '.ccla')
  else
    Wrapper.wrap({
      :template => :install,
      :wrapped_jnlp => params[:jnlp],
      :href => request.url,
      :vendor => "ConcordConsortium",
      :project => params[:project],
      :version => params[:version],
      :old_versions => params[:old_versions],
      :default_jnlp => params[:default_jnlp],
      :max_heap => params[:max_heap]
    })
  end
end

get '/:project/:version.ccla' do
  content_type :ccla
  last_modified(Time.now)
  Wrapper.wrap({
    :template => :install,
    :wrapped_jnlp => params[:jnlp],
    :href => request.url,
    :vendor => "ConcordConsortium",
    :project => params[:project],
    :version => params[:version],
    :old_versions => params[:old_versions],
    :default_jnlp => params[:default_jnlp],
    :max_heap => params[:max_heap]
  })
end

get '/jcl/:project/:version.jnlp' do
  content_type :jnlp
  last_modified(Time.now)
  ua = useragent
  if ua.platform == "Macintosh" && ua.os =~ /10\.(\d+)(\.\d+)?$/ && $1.to_i >= 9
    #redirect to the ccla file
    redirect request.fullpath.sub(/\.jnlp/, '.ccla')
  else
    Wrapper.wrap({
      :template => :jcl,
      :wrapped_jnlp => params[:jnlp],
      :href => request.url,
      :vendor => "ConcordConsortium",
      :project => "General",
      :version => "1.0"
    })
  end
end

get '/jcl/:project/:version.ccla' do
  content_type :ccla
  last_modified(Time.now)
  Wrapper.wrap({
    :template => :jcl,
    :wrapped_jnlp => params[:jnlp],
    :href => request.url,
    :vendor => "ConcordConsortium",
    :project => "General",
    :version => "1.0"
  })
end

get '/unwrap' do
  content_type :jnlp
  last_modified(Time.now)
  Wrapper.unwrap(params[:jnlp], params)
end
