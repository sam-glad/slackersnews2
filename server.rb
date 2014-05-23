require 'sinatra'
require 'csv'
require 'pry'
require 'redis'
require 'json'

def get_connection
  if ENV.has_key?("REDISCLOUD_URL")
    Redis.new(url: ENV["REDISCLOUD_URL"])
  else
    Redis.new
  end
end

def find_articles
  redis = get_connection
  serialized_articles = redis.lrange("slacker:articles", 0, -1)

  articles = []

  serialized_articles.each do |article|
    articles << JSON.parse(article, symbolize_names: true)
  end

  articles
end

def save_article(url, title, description)
  article = { url: url, title: title, description: description }

  redis = get_connection
  redis.rpush("slacker:articles", article.to_json)
end

def read_in_art
  articles = []
  CSV.foreach('views/data.csv' , headers: true) do |row|
    articles << row.to_hash
  end
  articles.reverse
end

get '/' do
  @read = read_in_art
  erb :index
end

get '/article_new' do
  @article = params["article"]
  erb :form_page
end

post '/article_new/apple' do
  @article = params["article"]
  @url = params["article_url"]
  @source = params["source"]
  @description = params["description"]
   if @description.length <= 20
     erb :form_page
  else
    CSV.open("views/data.csv", "a") do |csv|
      if csv != ''
        csv.puts([@article,@url,@source,@description])
      end
    end
    redirect '/'
  end
end

