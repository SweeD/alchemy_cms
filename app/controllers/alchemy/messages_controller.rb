# == Sending Messages:
# To send Messages via contact forms you can create your form fields in the config.yml
# === Example:
# Make an Element with this options inside your @elements.yml file:
#
#   - name: contact
#     display_name: Kontaktformular
#     contents:
#     - name: mail_to
#       type: EssenceText
#     - name: subject
#       type: EssenceText
#     - name: mail_from
#       type: EssenceText
#     - name: success_page
#       type: EssenceText
#
# The fields mail_to, mail_from, subject and success_page are recommended.
# The MessagesController uses them to send your mails. So your customer has full controll of these values inside his contactform @element.
# 
# Then make a page layout for your contact page in the page_layouts.yml file:
# 
#   - name: contact
#     display_name: Kontakt
#     unique: true
#     cache: false
#     @elements: [pageheading, heading, contact, bild, absatz, file_download]
#     autogenerate: [contact]
#
# Disabling the page caching is stronlgy recommended!
#
# The editor view for your @element should have this layout:
# 
#   <%= render_essence_editor_by_name(@element, 'mail_from') %>
#   <%= render_essence_editor_by_name(@element, 'mail_to') %>
#   <%= render_essence_editor_by_name(@element, 'subject') %>
#   <p>
#     Folgeseite: <%= page_selector(@element, 'success_page') %>
#   </p>
# 
# Please have a look at the alchemy/config/config.yml file for further Message settings.

module Alchemy
	class MessagesController < Alchemy::BaseController

		before_filter :get_page, :except => :create

		helper 'alchemy/pages'

		def index#:nodoc:
			redirect_to show_page_path(:urlname => @page.urlname, :lang => multi_language? ? @page.language_code : nil)
		end

		def new#:nodoc:
			@message = Message.new
			render :template => 'alchemy/pages/show', :layout => layout_for_page
		end

		def create#:nodoc:
			@message = Message.new(params[:message].merge(:ip => request.remote_ip))
			@element = Element.find_by_id(@message.contact_form_id)
			@page = @element.page
			@root_page = @page.get_language_root
			if @message.valid?
				Messages.contact_form_mail(@message, mail_to, mail_from, subject).deliver
				redirect_to_success_page
			else
				render :template => 'alchemy/pages/show', :layout => layout_for_page
			end
		end

	private

		def mailer_config
			Alchemy::Config.get(:mailer)
		end

		def mail_to
			@element.ingredient("mail_to")
		rescue
			mailer_config[:mail_to]
		end

		def mail_from
			@element.ingredient("mail_from")
		rescue
			mailer_config[:mail_from]
		end

		def subject
			@element.ingredient("subject")
		rescue
			mailer_config[:subject]
		end

		def redirect_to_success_page
			if @element.ingredient("success_page")
				urlname = @element.ingredient("success_page")
			elsif mailer_config[:forward_to_page] && mailer_config[:mail_success_page]
				urlname = Page.find_by_urlname(mailer_config[:mail_success_page]).urlname
			else
				flash[:notice] = Alchemy::I18n.t('alchemy.contactform.messages.success')
				urlname = Page.language_root_for(session[:language_id]).urlname
			end
			redirect_to show_page_path(:urlname => urlname, :lang => multi_language? ? session[:language_code] : nil)
		end

		def get_page
			@page = Page.find_by_page_layout_and_language_id(mailer_config[:page_layout_name], session[:language_id])
			raise "Page for page_layout #{mailer_config[:page_layout_name]} not found" if @page.blank?
			@root_page = @page.get_language_root
		end

	end
end
