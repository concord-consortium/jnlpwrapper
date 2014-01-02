require 'rubygems'
require 'sinatra'
require File.dirname(__FILE__) + '/lib/config'
require File.dirname(__FILE__) +'/lib/wrapper'

# set :static, true
set :public, File.dirname(__FILE__) + '/public'
set :template, File.dirname(__FILE__) + '/templates/template.jnlp'
mime :jnlp, 'application/x-java-jnlp-file'

Wrapper.template_content = open(template).read

def raw_post
  request.env["rack.input"].read
end

get '/' do
  redirect '/index.html'
end

get '/:project/:version.jnlp' do
  content_type :jnlp
  last_modified(Time.now)
  Wrapper.wrap(params[:jnlp], request.url, "ConcordConsortium", params[:project], params[:version], params[:old_versions], params[:default_jnlp], params[:max_heap])
end

get '/unwrap' do
  content_type :jnlp
  last_modified(Time.now)
  Wrapper.unwrap(params[:jnlp], params)
end
