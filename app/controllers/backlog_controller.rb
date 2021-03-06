class BacklogController < ApplicationController
  before_action :authenticate_user!

  def index
    @group = "entries"
    if current_user.backlog.nil?
      Entry.clean_indices
      User.clean_indices
      Entry.reindex
      User.reindex
      Backlog.create(user_id: current_user.id)
      @entries = []
    else
      @entries = current_user.backlog.entries.reorder("associations.created_at DESC").page(params[:page]).per(5)
    end
  end

  def unbuilt
    # logger = Logger.new('log/development.log')
    # logger.debug("stuff")
    title = params["movie_info"][0]
    description = params["movie_info"][1]
    imdb = params["movie_info"][2]
    thumb = params["movie_info"][3]
    rt_id = params["movie_info"][4]
    if Entry.exists?(title: title, description: description)
      entry = Entry.where(title: title, description: description).take
    else
      entry = Entry.create(title: title,
        description: description,
        imdb_id: imdb,
        thumbnail_file_name: thumb,
        rotten_tomatoes_id: rt_id
        )
    end
    entry.update_photo
    render json: entry
  end

  #TODO: See if these methods actually do something... Might have been part of the earlier version
  # def add_entry
  #   current_user.backlog.add_entry!(params[:id], current_user.backlog.id)
  #   render nothing: true
  # end
  #
  # def delete_entry
  #   current_user.backlog.remove_entry!(params[:id])
  #   render nothing: true
  # end
end
