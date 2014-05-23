require 'sinatra'
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

  articles.reverse
end

def save_article(url, title, description)
  article = { url: url, title: title, description: description }
  redis = get_connection
  redis.rpush("slacker:articles", article.to_json)
end

# def read_in_art
#   articles = []
#   CSV.foreach('views/data.csv' , headers: true) do |row|
#     articles << row.to_hash
#   end
#   articles.reverse
# end

get '/' do
  @read = find_articles
  erb :index
end

get '/article_new' do
  @article = params["article"]
  erb :form_page
end

post '/article_new' do
  @article = params["title"]
  @url = params["article_url"]
  @description = params["description"]
  if @description.length <= 20
     erb :form_page
  else
    save_article(@url,@article,@description)
    # CSV.open("views/data.csv", "a") do |csv|
    #   if csv != ''
    #     csv.puts([@article,@url,@source,@description])
    #   end
  end
    redirect '/'
end
