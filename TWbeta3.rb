require 'sinatra'
require 'data_mapper'
set :sessions, true
DataMapper.setup(:default, "sqlite:///#{Dir.pwd}/twid.db")

class Status 
	include DataMapper::Resource
	property :status_id, Serial
	property :content, String
	property :upvotes, Integer
	property :downvotes, Integer
	property :user_id, Integer
end
class User
	include DataMapper::Resource
	property :id,Serial
	property :email, String
	property :password, String
	property :notification, Boolean
end
class FollowingList
	include DataMapper::Resource
	property :friend_key,Serial
	property :user_id, Integer
	property :following_user_id, Integer
end
class UpvoteList
	include DataMapper::Resource
	property :upvote_id,Serial
	property :user_id, Integer
	property :status_user_id, Integer
	property :status_id,Integer
end
class DownvoteList
	include DataMapper::Resource
	property :downvote_id,Serial
	property :user_id, Integer
	property :status_user_id, Integer
	property :status_id,Integer
end
class Comments
	include DataMapper::Resource
	property :comment_id,Serial
	property :user_id, Integer
	property :status_user_id, Integer
	property :status_id,Integer
	property :content, String
end
class Notifications
	include DataMapper::Resource
	property :notif_id,Serial
	property :user_id, Integer
	property :genby_user_id, Integer
	property :type,String
end
DataMapper.finalize
FollowingList.auto_upgrade!
UpvoteList.auto_upgrade!
DownvoteList.auto_upgrade!
Comments.auto_upgrade!
Notifications.auto_upgrade!
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
	following = FollowingList.all(:user_id => user.id)
	friendsStatuses =[]
	i =0
	following.each do |x|
		friendsStatuses[i] = Status.all(:user_id => x.following_user_id)
		i=i+1
	end
	i =0
	friends =[]
	following.each do |x|
		friends[i] =  User.get(x.following_user_id).email
		i=i+1
	end
	comments =Comments.all
	erb :twit_pg2, locals: {comments: comments, user: user, status: status, friendsStatuses: friendsStatuses, friends: friends} 
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
		nwuser.notification =false
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
	tsk.upvotes =0
	tsk.downvotes =0
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
post '/follow' do #edit needed
	puts params
	friendId =params[:friendID].to_s
	puts friendId
	user1 = User.get(session[:seson_id])
	user2 =User.get(friendId.to_i)
	friend =FollowingList.all(:user_id => user1.id)
	friend.each do |x|
		if x.following_user_id ==user2.id
			redirect '/'
		end
	end
	friend =FollowingList.new
	friend.user_id =user1.id
	friend.following_user_id =user2.id
	friend.save
	user1.save
	nwnotif =Notifications.new
	nwnotif.user_id = user2.id 
	nwnotif.genby_user_id =user1.id
	nwnotif.type ="#{user1.email} Started Following You"
	user2.notification =true
	user2.save
	nwnotif.save
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
	user1 = User.get(session[:seson_id]) #he clicks on vote
	id =params[:status_id]
	tsk =Status.get(id.to_i)
	user2 = User.get(tsk.user_id) #he gets notification
	#checking if this user has already voted
	upvote =DownvoteList.all
	upvote.each do |x|
		if(x.user_id == user1.id)
			if( x.status_user_id == user2.id )
				if x.status_id ==tsk.status_id
					return redirect '/'
				end
			end
		end
	end
	nwvote =DownvoteList.new
	nwvote.user_id =user1.id
	nwvote.status_id =tsk.status_id
	nwvote.status_user_id =user2.id
	user2.notification =true
	nwnotif =Notifications.new
	nwnotif.user_id =  user2.id
	nwnotif.genby_user_id =user1.id
	nwnotif.type ="#{user1.email} Downvoted on your status"
	tsk.downvotes =tsk.downvotes+1
	tsk.save
	nwnotif.save
	user2.save
	user1.save
	nwvote.save
	redirect '/'

end
post '/upvote' do
	user1 = User.get(session[:seson_id]) #he clicks on vote
	id =params[:status_id]
	tsk =Status.get(id.to_i)
	user2 = User.get(tsk.user_id) #he gets notification
	#checking if this user has already voted
	upvote=UpvoteList.all
	upvote.each do |x|
		if(x.user_id == user1.id)
			if( x.status_user_id == user2.id )
				if x.status_id ==tsk.status_id
					return redirect '/'
				end
			end
		end
	end
	nwvote =UpvoteList.new
	nwvote.user_id =user1.id
	nwvote.status_id =tsk.status_id
	nwvote.status_user_id =user2.id
	user2.notification =true
	nwnotif =Notifications.new
	nwnotif.user_id =  user2.id
	nwnotif.genby_user_id =user1.id
	nwnotif.type ="#{user1.email} Upvoted on your status"
	tsk.upvotes =tsk.upvotes+1
	tsk.save
	nwnotif.save
	user2.save
	user1.save
	nwvote.save
	redirect '/'
	
end

post '/comment' do
	content = params[:content]
	user1 = User.get(session[:seson_id]) #he clicks on comment
	id =params[:status_id]
	tsk =Status.get(id.to_i)
	user2 = User.get(tsk.user_id) #he gets notification
	nwcomnt =Comments.new
	nwcomnt.user_id =user1.id
	nwcomnt.status_id =tsk.status_id
	nwcomnt.status_user_id =user2.id
	nwcomnt.content =content
	user2.notification =true
	nwnotif =Notifications.new
	nwnotif.user_id =  user2.id
	nwnotif.genby_user_id =user1.id
	nwnotif.type ="#{user1.email} Commented on your status"
	tsk.save
	nwnotif.save
	user2.save
	user1.save
	nwcomnt.save
	redirect '/'
	
end

get '/notifs' do
	puts params
	user1 = User.get(session[:seson_id])
	user1.notification = false
	notifs = Notifications.all( :user_id => session[:seson_id])
	user1.save
	erb :notific, locals: {notifs: notifs}
	
end

get '/remove_notif' do
	notifId =params[:notif_id]
	notifi =Notifications.get(notifId.to_i)
	if notifi.user_id == session[:seson_id]
		notifi.destroy
	end
	redirect '/notifs'

end

post '/viewDetails' do
	statId =params[:status_id]
	upvotes =UpvoteList.all(:status_id => statId)
	upvoters =[]
	i=0
	upvotes.each do |x|
		upvoters[i] = User.get(x.user_id)
		i=i+1
	end
	downvotes =DownvoteList.all(:status_id => statId)
	downvoters =[]
	i=0
	downvotes.each do |x|
		downvoters[i] = User.get(x.user_id)
		i=i+1
	end
	erb :Votedetails, locals: {upvoters: upvoters, downvoters: downvoters}
	end
