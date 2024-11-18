require 'sinatra'
require 'active_record'

ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: '/home/ec2-user/Assignment4/db/mydatabase.sqlite3')

class User < ActiveRecord::Base
end

enable(:sessions)

get('/') do
  redirect('/welcome')
end

get('/welcome') do
  # Login and sign-up options
  erb(:welcome)
end

get('/login') do
  # Enter username and password and authenticate
  @error = session.delete(:error)
  erb(:loginform)
end

get ('/signup') do
  # Enter details to add in db
  @error = session.delete(:error)
  erb(:signupform)
end

get ('/adduser') do
  # Get user input from the params
  username = params[:username]
  password = params[:password]

  if username.nil? || username.strip.empty? || password.nil? || password.strip.empty?
    session[:error] = 'Username and password are required.'
    redirect('/signup')
  end

  # Check if the username already exists
  if User.where('LOWER(username) = ?', username.downcase).exists?
    session[:error] = 'Username already exists. Please choose another one.'
    redirect('/signup')  # Redirect back to signup page with error
  end

  # Set default values for totalwin, totalloss, and totalprofit
  totalwin = 0
  totalloss = 0
  totalprofit = 0

  # Create a new user with default values
  User.create(
    username: username,
    password: password,
    totalwin: totalwin,
    totalloss: totalloss,
    totalprofit: totalprofit
  )

  # Redirect to the login page after user is created
  redirect('/login')
end

get('/authenticate') do
  name = params[:username] 
  pass = params[:password]

  if name.nil? || name.strip.empty? || pass.nil? || pass.strip.empty?
    session[:error] = 'Username and password are required.'
    redirect('/login')
  end
  
  @user = User.find_by(username: name)  # Use find_by to search by username

  if @user && @user.password == pass
    session[:username] = name  # Store username in session for later use
    session[:current_win] = 0
    session[:current_loss] = 0
    session[:current_profit] = 0
    session[:current_win_money] ||= 0
    session[:current_loss_money] ||= 0
    erb(:betting)
  else
    session[:error] = 'Login failed, please enter the correct username or password!'
    redirect('/login')
  end
end

get '/bet' do
  # Ensure session keys are initialized
  session[:current_win_count] ||= 0
  session[:current_loss_count] ||= 0
  session[:current_win_money] ||= 0
  session[:current_loss_money] ||= 0
  session[:current_profit] ||= 0

  # Fetch the user from the database
  @user = User.find_by(username: session[:username])
  unless @user
    redirect('/login')  # Redirect if the user is not logged in
  end

  # Validate input first
  bet_money = params[:bet_money].to_i
  bet_number = params[:bet_number].to_i

  if bet_money <= 0 || !(1..6).include?(bet_number)
    @error = "Invalid input. Bet money must be positive, and bet number must be between 1 and 6."
    return erb(:betting)
  end

  # Generate a random roll
  @roll = rand(1..6)

  # Determine bet outcome and update session variables
  if bet_number == @roll
    session[:current_win_count] += 1
    session[:current_win_money] += bet_money 
    session[:current_profit] += bet_money
    @result = "You won this bet!"
  else
    session[:current_loss_count] += 1
    session[:current_loss_money] += bet_money
    session[:current_profit] -= bet_money
    @result = "You lost this bet!"
  end

  # Update the user data in the database with the change from the current bet
  @user.totalwin += session[:current_win_money] - @user.totalwin
  @user.totalloss += session[:current_loss_money] - @user.totalloss
  @user.totalprofit += session[:current_profit] - @user.totalprofit
  @user.save

  # Render the betting page with the result
  erb(:betting)
end

get('/logout') do
  user = User.find_by(username: session[:username])

  if user
    user.totalwin += session[:current_win_money] - user.totalwin
    user.totalloss += session[:current_loss_money] - user.totalloss
    user.totalprofit += session[:current_profit] - user.totalprofit
    user.save
  end

  session.clear
  redirect('/login')
end

not_found do
  erb(:notfound)
end
