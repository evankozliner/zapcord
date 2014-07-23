class SearchController < ApplicationController

  #TODO: WAY too much logic, move this stuff to a model
  def index
    logger = Logger.new('log/development.log')
    query = params[:query]
    #TODO: Switch this to bisection for speed
    #TODO: handle /search/entries//none
    if query.blank?
      query = "sky"
      Entry.reindex
      User.reindex
      #TODO: add a message instead
      @results = Entry.search query, page: params[:page], per_page: 10
    else
      @results = Entry.search query
      has_entry = false
      @results.to_a.each do |result|
        #Complete: this check needs to be stronger because someone can enter something like "jackas" and it will not
        #stop the method from querying RT for "jackas", which will in turn return "Jackass" and create the entry again
        if result.title.downcase.gsub(/\s+/, "") == query.downcase.gsub(/\s+/, "")
          has_entry = true
        end
      end
      #TODO: (in progress) finish this method
      unless has_entry
        entry = false
        uri = URI("http://api.rottentomatoes.com/api/public/v1.0/movies.json?apikey=" +
        ENV["ROTTEN_TOMATOES_KEY"] +
        "&q=" +
        query.to_s.gsub(" ", "+") +
        "&page_limit=20")
        resp = JSON.parse(Net::HTTP.get_response(uri).body)
        unless resp.blank?
          resp["movies"].each do |movie|
            #TODO: Add pictures!
            entry = Entry.create(title: movie["title"], description: movie["synopsis"])
          end
        end
      end
      #TODO: there's certainly a better way of doing this... (not DRY, we query twice)
      @results = Entry.search query, page: params[:page], per_page: 10
    end
  end
  def query
    query = params[:query]

    if params[:type] == "entries"
      @results = Entry.search query, limit: 10, page: params[:page], per_page: 10
    else
      @results = User.search query, limit: 10, page: params[:page], per_page: 10
    end

    if @results.blank? && @results.count > 0
      render nothing: true
    else
      # if has_entry then render json: @results else render json: @results.to_a.push(entry).to_json end
      render json: @results
    end
  end
end
