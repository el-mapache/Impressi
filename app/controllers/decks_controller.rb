class DecksController < ApplicationController
  layout 'deck', :except => :new
  # before_filter :authenticate_user!, :only => [:edit, :update]
  
  def new
    guest_deck_id = session[:guest_deck]
    if session[:guest_deck] && move_decks_from_guest_user
      target_deck = Deck.find(guest_deck_id)
      redirect_to edit_deck_path(target_deck)
    else
      deck = nil
      deck ||= Deck.find_by_id(guest_deck_id) 
      deck.destroy if deck
      @deck = current_or_guest_user.decks.build
    end
  end

  def create
    deck = current_or_guest_user.decks.create(:template_id => 1)
    redirect_to edit_deck_path(deck)
  end
  
  def edit
    @template_data = Template.dropdown_data
    @deck = Deck.find(params[:id])
    if @deck.user_id != current_or_guest_user.id
      redirect_to :root
      flash[:notice] = 'You are not authorized to edit that deck.'
    end
  end

  def update
    deck             = Deck.find(params[:id])
    deck.template_id = params[:deck][:template_id]
    deck.steps       = params[:deck][:steps].inject([]) { |array, step| array << step[1] }
      
    if user_signed_in?
      deck.user_id = current_user.id
    else
      session[:guest_deck] = deck.id
    end
        
    respond_to do |format|
      if deck.save
        format.js 
      else
        render :text => 'Failed Ajax call.'
      end
    end
  end

  def destroy
    deck_name = Deck.find(params[:id]).name
    Deck.find(params[:id]).destroy
    flash[:success] = "Deck #{deck_name} deleted"
    redirect_to user_path(current_user)
  end

  def show
    @deck = Deck.find(params[:id])
    
    respond_to do |format|
      format.html {
        if deck_belongs_to_guest_user?(@deck)
          session[:guest_deck] = @deck.id 
          redirect_to new_user_registration_path
        end }
      format.json { render :json => @deck }
    end
  end

  private

  def deck_belongs_to_guest_user?(deck)
    Deck.find_all_by_user_id(session[:guest_user_id]).include?(deck)
  end
end
