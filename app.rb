require 'sinatra/base'
require_relative 'lib/game'
require_relative 'lib/player'
require_relative 'lib/question_getter'

# This class is the wrapper for the website.
class QuizApp < Sinatra::Base
  use Rack::Session::Pool

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
    redirect '/out_of_questions' if @game.all_questions_asked?

    @game.new_question
    @answers = @game.current_question.give_answers
    erb :question
  end

  post '/answer_0' do
    @game = session[:game]
    @game.lose_life unless @game.play_game(0)

    redirect '/question' unless @game.game_over?

    redirect '/game_over'
  end

  post '/answer_1' do
    @game = session[:game]
    @game.lose_life unless @game.play_game(1)

    redirect '/question' unless @game.game_over?

    redirect '/game_over'
  end

  post '/answer_2' do
    @game = session[:game]
    @game.lose_life unless @game.play_game(2)

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
    @top_scores = @game.get_top_scores
    erb :leaderboard
  end
end
