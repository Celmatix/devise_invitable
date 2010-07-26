require File.dirname(__FILE__) + '/acceptance_helper'

feature "Invitations:" do
  background do
    ActionMailer::Base.deliveries.clear
  end
  
  scenario "not authenticated user should not be able to send an invitation" do
    visit "http://www.example.com/users/invitation/new"
    
    current_url.should == "http://www.example.com/users/sign_in"
  end
  
  scenario "authenticated user should be able to send an invitation" do
    invite
    
    current_url.should == "http://www.example.com/"
    page.should have_content('An invitation email has been sent to user@test.com.')
    User.last.email.should == "user@test.com"
    User.last.invitation_token.should be_present
    ActionMailer::Base.deliveries.size.should == 2
  end
  
  scenario "authenticated user with invalid email should receive an error message" do
    user = create_user
    invite do
      fill_in 'Email', :with => user.email
    end
    
    current_url.should == "http://www.example.com/users/invitation"
    page.should have_css("input[type=text][value='#{user.email}']")
    page.should have_content("Email #{DEVISE_ORM == :mongoid ? 'is already' : 'has already been'} taken")
  end
  
  scenario "authenticated user should not be able to visit accept invitation page" do
    sign_in_as_user
    visit "http://www.example.com/users/invitation/accept"
    
    current_url.should == "http://www.example.com/"
  end
  
  scenario "not authenticated user with invalid invitation token should not be able to accept invitation" do
    user = create_user
    accept_invitation :invitation_token => 'invalid_token'
    
    current_url.should == "http://www.example.com/users/invitation"
    page.should have_css('#error_explanation')
    page.should have_content('Invitation token is invalid')
    user.should_not be_valid_password('987654321')
  end
  
  scenario "not authenticated user with valid invitation token but invalid password should not be able to accept invitation" do
    user = invite
    sign_out
    accept_invitation :invitation_token => user.invitation_token do
      fill_in 'Password confirmation', :with => 'other_password'
    end
    
    current_url.should == "http://www.example.com/users/invitation"
    page.should have_css('#error_explanation')
    page.should have_content("Password doesn't match confirmation")
    user.should_not be_valid_password('987654321')
  end
  
  scenario "not authenticated user with valid data should be able to accept invitation" do
    user = invite
    sign_out
    accept_invitation :invitation_token => user.invitation_token
    
    current_url.should == "http://www.example.com/"
    page.should have_content("Your password was set successfully. You are now signed in.")
    user.reload.should be_valid_password('987654321')
    User.last.email.should == "user@test.com"
    User.last.invitation_token.should be_nil
  end
  
  scenario "after entering invalid data user should still be able to accept invitation" do
    user = invite
    sign_out
    accept_invitation :invitation_token => user.invitation_token do
      fill_in 'Password confirmation', :with => 'other_password'
    end
    
    current_url.should == "http://www.example.com/users/invitation"
    page.should have_css('#error_explanation')
    page.should have_content("Password doesn't match confirmation")
    user.reload.should_not be_valid_password('987654321')
    
    accept_invitation :invitation_token => user.invitation_token
    
    current_url.should == "http://www.example.com/"
    page.should have_content("Your password was set successfully. You are now signed in.")
    user.reload.should be_valid_password('987654321')
  end
  
  scenario "sign in user automatically after setting it\'s password" do
    user = invite
    sign_out
    accept_invitation :invitation_token => user.invitation_token
    sign_out
    
    page.should have_content('Signed out successfully.')
  end
  
end