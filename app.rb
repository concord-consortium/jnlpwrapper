require 'rubygems'
require 'bundler'

Bundler.require

$LOAD_PATH.unshift 'lib'

require 'wrapper'

configure do
  set :public_folder, File.dirname(__FILE__) + '/public'
  mime_type :jnlp, 'application/x-java-jnlp-file'

  Wrapper.add_template(:install, open(File.dirname(__FILE__) + '/templates/install.jnlp').read)
  Wrapper.add_template(:jcl, open(File.dirname(__FILE__) + '/templates/jcl.jnlp').read)
end

def raw_post
  request.env["rack.input"].read
end

get '/' do
  redirect '/index.html'
end

get '/:project/:version.jnlp' do
  content_type :jnlp
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
