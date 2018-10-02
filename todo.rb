require "sinatra"
require "sinatra/reloader" if development?
require "tilt/erubis"
require "sinatra/content_for"

configure do
  enable :sessions
  set :session_secret, "secret"
end

before do
  session[:lists] ||= []
  @lists = session[:lists]
end

get "/" do
  redirect "/lists"
end

get "/lists" do
  erb :lists
end

get "/lists/:which" do
  if params[:which] == "new"
    erb :new_list
  else
    @list = @lists[params[:which].to_i]
    erb :list
  end
end

post "/lists/:which" do
  @list = @lists[params[:which].to_i]
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :list_edit
  else
    @list[:name] = list_name
    session[:success] = "The list name has been edited."
    redirect "/lists/#{params[:which]}"
  end
end

get "/lists/:which/edit" do
  @list = @lists[params[:which].to_i]
  erb :list_edit
end

post "/lists/:which/destroy" do
  @lists.delete_at(params[:which].to_i)
  session[:success] = "The list was removed successfully."
  redirect "/lists"
end

post "/lists/:which/todos/:which_todo/destroy" do
  @list = @lists[params[:which].to_i]
  @list[:todos].delete_at(params[:which_todo].to_i)
  session[:success] = "The todo was removed successfully."
  redirect "/lists/#{params[:which]}"
end

post "/lists/:which/todos/:which_todo/complete" do
  @list = @lists[params[:which].to_i]
  todo = @list[:todos][params[:which_todo].to_i]
  todo[:completed] = params[:completed] == "true"
  redirect "/lists/#{params[:which]}"
end

post "/lists/:which/complete" do
  @list = @lists[params[:which].to_i]
  @list[:todos].each do |todo|
    todo[:completed] = true
  end
  redirect "/lists/#{params[:which]}"
end

post "/lists/:which/todos" do
  @todo = params[:todo].strip
  @list = @lists[params[:which].to_i]
  error = error_for_todo(@todo)
  if error
    session[:error] = error
    erb :list
  else
    @list[:todos] << {name: @todo, completed: false}
    session[:success] = "New todo was created"
    redirect "/lists/#{params[:which]}"
  end
end

def error_for_todo(name)
  if !name.size.between?(1,100)
    "Todo name must have between 1 and 100 characters."
  end
end

def error_for_list_name(name)
  if !name.size.between?(1,100)
    "The list name must have between 1 and 100 characters."
  elsif session[:lists].any? { |list| list[:name] == name  }
    "The list name must be unique."
  end
end

post  "/lists" do
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list
  else
    session[:lists] << {name: list_name, todos: []}
    session[:success] = "The list has been created."
    redirect "/lists"
  end
end

helpers do
  def all_completed?(list)
    list[:todos].all? { |todo| todo[:completed] } && list[:todos].size > 0
  end

  def remaining(list)
    list[:todos].select { |todo| !todo[:completed]}.size
  end

  def list_class(list)
    "complete" if all_completed?(list)
  end

  def sorted_list_indexes(list)
    list_of_indexes = list[:todos].map.with_index do |todo, index|
                                   [index, todo[:completed]]
                                  end
    list_of_indexes.sort_by! { |pair| pair[1] ? 1 : 0 }
    list_of_indexes.map! { |pair| pair[0] }
    list_of_indexes
  end

  def sorted_lists_indexes
    list_of_indexes = @lists.map.with_index do |list, index|
                                   [index, all_completed?(list)]
                                  end
    list_of_indexes.sort_by! { |pair| pair[1] ? 1 : 0 }
    list_of_indexes.map! { |pair| pair[0] }
    list_of_indexes
  end
end