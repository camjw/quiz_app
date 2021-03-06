require 'sinatra/base'
require 'sinatra/activerecord'
require_relative 'lib/game'
require_relative 'lib/player'
require_relative 'lib/question_getter'

# This class is the wrapper for the website.
class QuizApp < Sinatra::Base
  use Rack::Session::Pool
  set :database_file, 'config/database.yml'

  def initialize(getter: QuestionGetter.new, seed: nil)
    super
    @getter = getter
    @getter.give_random_seed(seed) if seed
  end

  get '/' do
    erb :index
  end

  post '/initialize_game' do
    name = params[:player_name]
    name = 'Stranger' if name == ''

    session[:game] = Game.new(Player.new(name), getter: @getter)
    redirect '/question'
  end

  get '/question' do
    @game = session[:game]
    questions_asked = @game.asked_questions.size

    @game.gain_life if (questions_asked % 5).zero? && (questions_asked > 0)

    redirect '/out_of_questions' if @game.all_questions_asked?

    @game.new_question
    @answers = @game.current_question.give_answers
    erb :question
  end

  post '/answer/:id' do
    @game = session[:game]
    @game.lose_life unless @game.play_game(params[:id].to_i)

    redirect '/question' unless @game.game_over?

    redirect '/game_over'
  end

  get '/game_over' do
    @game = session[:game]
    @game.add_to_leaderboard
    erb :game_over
  end

  get '/out_of_questions' do
    @game = session[:game]
    @game.add_to_leaderboard
    erb :out_of_questions
  end

  get '/leaderboard' do
    @game = session[:game]
    @top_scores = @game.fetch_top_scores
    erb :leaderboard
  end

  post '/leaderboard' do
    session[:game] = Game.new(Player.new('Stranger'), getter: @getter)
    redirect '/leaderboard'
  end
end
