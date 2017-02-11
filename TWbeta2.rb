require 'sinatra'
require 'data_mapper'
set :sessions, true
DataMapper.setup(:default, "sqlite:///#{Dir.pwd}/twic.db")

class Status 
	include DataMapper::Resource
	property :status_id, Serial
	property :content, String
	property :Upvotes, Integer
	property :Downvotes, Integer
	property :user_id, Integer
	property :voterList, String
end
class User
	include DataMapper::Resource
	property :id,Serial
	property :email, String
	property :password, String
	property :friendList, String
end
DataMapper.finalize
Status.auto_upgrade!
User.auto_upgrade!
get '/' do
	user=nil
	if session[:seson_id]
		user = User.get(session[:seson_id])
		puts "LOGGED IN SESSION"
		puts user
	else
		puts " no logged in user "
		redirect '/signin'
	end
	if user
	status =Status.all(:user_id => user.id)
	puts status
	arr =user.friendList.split(" ")
	A=[]
	i=0
	arr.each do |x|
		if A.include?x.to_i
			print " present "	
		else
			A[i] = x.to_i
			i=i+1 
		end
	end
	friendsStatuses =[]
	i =0
	A.each do |x|
		friendsStatuses[i] = Status.all(:user_id => x)
		i=i+1
	end
	i =0
	friends =[]
	A.each do |x|
		friends[i] =  User.get(x).email
		i=i+1
	end
	erb :twit_pg, locals: {user: user, status: status, friendsStatuses: friendsStatuses, friends: friends} 
	else
	redirect '/signup'	
	end
	
end

get '/signin' do
	erb :signin
end
post '/signin' do
	puts params
	email =params[:email]
	pw = params[:password]
	user = User.all(:email => email).first
	if user
		if pw==user.password
			session[:seson_id]=user.id
			puts "SUCCESSFULLY SIGNED IN"
			redirect '/'
		else
			puts "Password is wrong!"
			redirect '/signin'
		end

	else
		puts "No such user exist pls signup!"
		redirect '/signup'
	end

end	
get '/signup' do
	erb :signup
end
post '/register' do


	puts params
	email = params[:email]
	password = params[:password]

	user = User.all(:email => email).first
	if user
		puts "this email already exists"
		redirect '/signup'
	else
		nwuser =User.new
		nwuser.email =email
		nwuser.password =password
		nwuser.friendList =""
		nwuser.save
		session[:seson_id]= nwuser.id
		puts " new user created with userid = #{nwuser.id}"
		redirect '/'
	end
end

post '/logout' do
	session[:seson_id] = nil
	redirect '/'
end

post '/add_status' do
	tsk = Status.new
	puts params
	tsk.content =params[:content]
	tsk.Upvotes =0
	tsk.Downvotes =0
	tsk.voterList =""
	tsk.user_id =session[:seson_id]
	tsk.save
	puts "task #{tsk.content} created "
	redirect '/'
end
post '/edit_status' do
	newcontent =params[:edited_content]
	id =params[:status_id]
	tsk =Status.get(id.to_i)
	if tsk.user_id == session[:seson_id]
		tsk.content = newcontent 
		tsk.save
	end
	redirect '/'

end
post '/find_friend' do
	friend =params[:findFriend]
	puts params
	user = User.all(:email => friend).first
	erb :FriendFound, locals: {user: user} 
end
post '/follow' do
	puts params
	friendId =params[:friendID].to_s
	puts friendId
	user = User.get(session[:seson_id])
	user.friendList="#{user.friendList}#{friendId} "
	puts user.friendList
	user.save
	redirect '/'

end
post '/delete_status' do
	id =params[:status_id]
	tsk =Status.get(id.to_i)
	if tsk.user_id == session[:seson_id]
		tsk.destroy
	end
	redirect '/'
end
post '/downvote' do
	id =params[:status_id]
	tsk =Status.get(id.to_i)
	arr =tsk.voterList.split(" ")
	A=[]
	i=0
	arr.each do |x|
		A[i] = x.to_i
		i=i+1 
	end
	
	if A.include?(session[:seson_id])
		redirect '/'
	else
		A[i]=(session[:seson_id])
		tsk.voterList="#{tsk.voterList}#{A[i]} "
		tsk.Downvotes = tsk.Downvotes+1
		tsk.save
	end
	redirect '/'
end
post '/upvote' do
	id =params[:status_id]
	tsk =Status.get(id.to_i)
	arr =tsk.voterList.split(" ")
	A=[]
	i=0
	arr.each do |x|
		A[i] = x.to_i
		i=i+1 
	end
	
	if A.include?(session[:seson_id])
		redirect '/'
	else
		A[i]=(session[:seson_id])
		tsk.voterList="#{tsk.voterList}#{A[i]} "
		tsk.Upvotes = tsk.Upvotes+1
		tsk.save
	end


	redirect '/'
end


