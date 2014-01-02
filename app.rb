require 'rubygems'
require 'sinatra'
require File.dirname(__FILE__) + '/lib/config'
require File.dirname(__FILE__) +'/lib/wrapper'

# set :static, true
set :public, File.dirname(__FILE__) + '/public'
set :install_template, File.dirname(__FILE__) + '/templates/install.jnlp'
set :jcl_template, File.dirname(__FILE__) + '/templates/jcl.jnlp'
mime :jnlp, 'application/x-java-jnlp-file'

Wrapper.add_template(:install, open(install_template).read)
Wrapper.add_template(:jcl, open(jcl_template).read)

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
