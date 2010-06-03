class AdminController < ApplicationController
  
  before_filter :set_translation
  
  filter_access_to :index
  
  def index
    # Hello!
    @alchemy_version = configuration(:alchemy_version)
  end
  
  # Signup only works if no user is present in database.
  def signup
    if request.get?
      redirect_to admin_path if WaUser.count != 0
      flash[:explain] = _("Please Signup")
      @wa_user = WaUser.new
    else
      @wa_user = WaUser.new(params[:wa_user].merge({:role => 'admin'}))
      if @wa_user.save
        WaMailer.deliver_new_alchemy_user_mail(@wa_user, request)
        redirect_to :action => :index
      end
    end
  end
  
  def login
    if WaUser.count == 0
      redirect_to :action => 'signup'
    else
      if request.get?
        @wa_user_session = WaUserSession.new()
        flash.now[:info] = params[:message] || _("welcome_please_identify_notice")
        render :layout => 'login'
      else
        @wa_user_session = WaUserSession.new(params[:wa_user_session])
        if @wa_user_session.save
          if session[:redirect_url].blank?
            redirect_to :action => :index
          else
            redirect_to session[:redirect_url]
          end
        else
          render :layout => 'login'
        end
      end
    end
  end
  
  def logout
    message = params[:message] || _("logged_out")
    @wa_user_session = WaUserSession.find
    if @wa_user_session
      @wa_user_session.destroy
      current_user.unlock_pages if current_user
    end
    flash[:info] = message
    redirect_to root_url
  end
  
  def save_atom
    atom = WaAtom.find(params[:id]).atom
    wa_molecule = WaAtom.find(params[:id]).wa_molecule_id
    wa_page = WaMolecule.find(wa_molecule).wa_page_id
    if atom.update_attributes(params[:this_atom])
      flash[:notice] = _("element_saved")
    end
    redirect_to :controller => "wa_pages", :action => 'edit', :id => wa_page
  end
  
  def save_contentposition
    unless params[:wa_sitemap].nil?
      parent = WaPage.find(:first, :conditions => {:parent_id => nil})
      for pages in params[:wa_sitemap]["0"]
        for page in pages
          unless page["id"].nil? || page["id"] == "id"
            p = WaPage.find(page["id"])
            p.move_to_child_of parent
          end
        end
      end
    end
    unless params[:wa_sitemap_2].nil?
      parent = WaPage.find(params[:wa_sitemap_2]["id"]).parent_id
      for pages in params[:wa_sitemap_2]["0"]
        for page in pages
          unless page["id"].nil? || page["id"] == "id"
            p = WaPage.find(page["id"])
            p.move_to_child_of parent
          end
        end
      end
    end
    redirect_to :action => 'index'
  end
  
  def link_to_page
    @url_prefix = ""
    if configuration(:show_real_root)
      @wa_page_root = WaPage.root
    else
      @wa_page_root = WaPage.find_by_language_root_for(session[:language])
    end    
    @area_name = params[:area_name]
    @atom_id = params[:wa_atom_id]
    if params[:link_urls_for] == "newsletter"
      # TODO: links in newsletters has to go through statistic controller. therfore we have to put a string inside the wa_atom_rtfs and replace this string with recipient.id before sending the newsletter.
      #@url_prefix = "#{get_server}/recipients/reacts"
      @url_prefix = get_server
    end
    if multi_language?
      @url_prefix = "#{session[:language]}/"
    end
    render :layout => false
  end
  
  def infos
    @version = configuration(:alchemy_version)
    render :layout => false
  end
    
end