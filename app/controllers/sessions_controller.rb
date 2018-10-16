require 'pry'
class SessionsController < ApplicationController
  def login_form
  end

  def login
    username = params[:username]
    if username and user = User.find_by(username: username)
      session[:user_id] = user.id
      flash[:status] = :success
      flash[:result_text] = "Successfully logged in as existing user #{user.username}"
    else
      user = User.new(username: username)
      if user.save
        session[:user_id] = user.id
        flash[:status] = :success
        flash[:result_text] = "Successfully created new user #{user.username} with ID #{user.id}"
      else
        flash.now[:status] = :failure
        flash.now[:result_text] = "Could not log in"
        flash.now[:messages] = user.errors.messages
        render "login_form", status: :bad_request
        return
      end
    end
    redirect_to root_path
  end

  def logout
    session[:user_id] = nil
    flash[:status] = :success
    flash[:result_text] = "Successfully logged out"
    redirect_to root_path
  end

  def create
    # Save the user's ID in the session
    auth_hash = request.env['omniauth.auth']
    user = User.find_by(uid: auth_hash[:uid], provider: 'github')
    # binding.pry
    if user
      # User was found in the database
      flash[:success] = "Logged in as returning user #{user.username}"
    else
      # User doesn't match anything in the DB, so create a new
      user = User.build_from_github(auth_hash)

      if user.save
        session[:user_id] = user.id 
        flash[:success] = "Logged in as new user #{user.username}"
      else
        # Couldn't save the user for some reason. If we
        # hit this it probably means there's a bug with the
        # way we've configured GitHub. Our strategy will
        # be to display error messages to make future
        # debugging easier.
        flash[:error] = "Could not create new user account: #{user.errors.messages}"
        redirect_to root_path
        return
      end
    end

    session[:user_id] = user.id
    redirect_to root_path
  end

  def destroy
    session[:user_id] = nil
    flash[:success] = "Successfully logged out!"

    redirect_to root_path
  end

end
