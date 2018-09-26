#!/bin/env ruby
# encoding: utf-8

#===========================================#
# Every email needs at least these:         #
#   @app_root_url                           #
#   @subject                                #
#   @headline                               #
#   @welcome                                #
#   @body                                   #
#   @goodbye                                #
#===========================================#

class Emailer < ActionMailer::Base
  #include Resque::Mailer
  default :from => "Aywa Markets <noreply@aywalive.com>"

  # The email template names
  @@page_stack = "page_stack"
  @@generic = "generic"

  # Adds helper for limited use in controller
  def help
    Helper.instance
  end

  class Helper
    include Singleton
    include ActionView::Helpers::NumberHelper
    include ActionView::Helpers::DateHelper
  end
  
  def send_email(email)
    @app_root_url = "localhost:3000/"
    @subject = email["subject"].to_s
    @headline = t('emailer.new_msg.headline')
    @welcome = t('emailer.hello')
    @email_body = email["message"].to_s
    @goodbye = t('emailer.thanks')

    mail_it_with_bcc(email["recipient"].to_s, 'ninah.midiwo@gmail.com', @subject, @@page_stack)
  end

  def message_notification(message, partnerCC)
    @recipient = get_recipient(message)
    I18n.locale = @recipient.locale || 'en'
    @app_root_url = "http://#{Willstream::Config.server_name}/"
    @subject = t('emailer.new_msg.subject')
    @headline = t('emailer.new_msg.headline')
    @welcome = t('emailer.hello')
    @email_body = t('emailer.new_msg.body',
                    :sendername => get_sender(message).displayname,
                    :login_link => @app_root_url)
    @goodbye = t('emailer.see_you_soon')

    mail_it_with_bcc(@recipient.email, Willstream::Config.outgoing_email, @subject, @@page_stack)
#    I18n.locale = @recipient.respond_to?(@recipient.locale) ? @recipient.locale : 'fr'
  end

  def anonymous_message_confirmation(merchant_id, new_user)
    @app_root_url = "http://#{Willstream::Config.server_name}/"
    @subject = t('emailer.anonymous_message_confirmation.subject', :business_name => @business_name)
    @business_name = Merchant.find(merchant_id).business_name
    @business_url = @app_root_url + Merchant.find(merchant_id).username
    @headline = t('emailer.anonymous_message_confirmation.headline', :business_name => @business_name)
    @welcome = t('emailer.hello') + new_user.username
    @email_body = t('emailer.anonymous_message_confirmation.body',
                    :business_url => @business_url,
                    :business_name => @business_name,
                    :login_link => @app_root_url,
                    :username => new_user.username,
                    :password => new_user.password)
    @goodbye = t('emailer.anonymous_message_confirmation.goodbye', :business_name => @business_name)

    mail_it_with_bcc(new_user.email, Willstream::Config.outgoing_email, @subject, @@page_stack)
  end

  def activation_request_notification(activation_request)
    @app_root_url = "http://#{Willstream::Config.server_name}/"
    requested_merchant = Merchant.find(activation_request.merchant_id)
    requesting_user = User.find(activation_request.user_id)
    @subject = t('emailer.activation_request_notification.subject')
    @headline = t('emailer.activation_request_notification.headline', :business_name => requested_merchant.business_name)
    @welcome = t('emailer.activation_request_notification.welcome')
    @email_body = t('emailer.activation_request_notification.body',
                    :username => requesting_user.username,
                    :user_email => requesting_user.email,
                    :path_to_merchant => @app_root_url + requested_merchant.username,
                    :business_name => requested_merchant.business_name)
    @goodbye = t('emailer.thanks')
    mail_it_with_bcc(requested_merchant.partner.email ? requested_merchant.partner.email : "senegal@willstream.com", Willstream::Config.outgoing_email, @subject, @@page_stack)
  end

  #Notification to users upon payment
  def stream_new_notification(payment)
    # Calculate these first
    @app_root_url = "http://#{Willstream::Config.server_name}/"
    @payment = payment
    @streams = payment.streams
    @user = @streams[0].user
    I18n.locale = @user? @user.locale : 'fr'
    
    #setup payment summary & table
    @count = @streams.size
    @pay_amount = 0;
    @summary_table = t('emailer.stream_new.table_start').html_safe +
                      t('emailer.stream_new.header_row', :currency => Currency.find_by_code(@streams[0].currency.upcase).name).html_safe
    @payment_has_direct_style = false
    @payment_has_voucher_style = false
    for stream in @streams
      if stream.is_direct?
        @payment_has_direct_style = true
      else
        @payment_has_voucher_style = true
      end
      @pay_amount = @pay_amount + (stream.amount_cents)
      @summary_table = @summary_table +
                       (stream.is_direct? ?
                        t("emailer.stream_new.#{stream.stream_package.present? ? stream.stream_package.merchant.username : ''}.stream_row_direct",
                          :app_root_url => @app_root_url,
                          :stream_number => stream.code,
                          :purpose => stream.purpose,
                          :instructions => stream.sender_notes,
                          :amount => help.number_with_delimiter(stream.amount_cents / 100),
                          :default => t('emailer.stream_new.stream_row_direct',
                                        :app_root_url => @app_root_url,
                                        :stream_number => stream.code,
                                        :purpose => stream.purpose,
                                        :instructions => stream.sender_notes,
                                        :amount => help.number_with_delimiter(stream.amount_cents / 100))
                        ).html_safe :
                        t("emailer.stream_new.#{stream.stream_package.present? ? stream.stream_package.merchant.username : ''}.stream_row_voucher",
                          :app_root_url => @app_root_url,
                          :stream_number => stream.code,
                          :purpose => stream.purpose,
                          :instructions => stream.sender_notes,
                          :beneficiary => stream.beneficiary.phone_number,
                          :secret_code => stream.pin,
                          :amount => help.number_with_delimiter(stream.amount_cents / 100),
                          :default => t('emailer.stream_new.stream_row_voucher',
                                        :app_root_url => @app_root_url,
                                        :stream_number => stream.code,
                                        :purpose => stream.purpose,
                                        :instructions => stream.sender_notes,
                                        :beneficiary => stream.beneficiary.phone_number,
                                        :secret_code => stream.pin,
                                        :amount => help.number_with_delimiter(stream.amount_cents / 100))
                        ).html_safe) 
    end
    @summary_table = @summary_table.html_safe + 
                    t('emailer.stream_new.table_end').html_safe
    case @payment.reason
    when Payment::BENEFICIARY_REQUEST
      @subject = t('emailer.beneficiary_request.subject', 
                   :beneficiary_name => @streams[0].beneficiary.username,
                   :merchant_name => @streams[0].stream_package.merchant.business_name,
                   :merchant_city => @streams[0].stream_package.merchant.city_name)
      @headline = t('emailer.beneficiary_request.headline',
                    :beneficiary_name => @streams[0].beneficiary.username)
      @email_body = t('emailer.beneficiary_request.confirmation',
                      :beneficiary_name => @streams[0].beneficiary.username,
                      :merchant_name => @streams[0].stream_package.merchant.business_name,
                      :merchant_city => @streams[0].stream_package.merchant.city_name,
                      :to_amount => help.number_to_currency(@payment.amount_subtotal_in_to_currency.to_f / 100, 
                        :unit => Currency.find_by_code(@streams[0].currency).name).html_safe,
                      :payment_url => @app_root_url + "payments/" + @payment.id.to_s + "/edit").html_safe + 
                    t('emailer.stream_new.blank', :fill_variable => @summary_table).html_safe + 
                    (@payment_has_direct_style ? t('emailer.stream_new.table_legend_direct', :app_root_url => @app_root_url).html_safe : "") + 
                    (@payment_has_voucher_style ? t('emailer.stream_new.table_legend_voucher', :app_root_url => @app_root_url).html_safe : "") + 
                    t('emailer.stream_new.action_table', 
                      :app_root_url => @app_root_url, 
                      :invite_url => @user.get_promo_code).html_safe +
                    t('emailer.stream_new.contact').html_safe
      @welcome = t('emailer.hello') + (@user.first_name != nil ? @user.first_name : @user.username)
      @goodbye = t('emailer.beneficiary_request.goodbye')
    when Payment::DEFERRED
      @subject = t('emailer.deferred_payment.subject', 
                   :merchant_name => @streams[0].stream_package.merchant.business_name)
      @headline = t('emailer.deferred_payment.headline')
      @email_body = t('emailer.deferred_payment.confirmation',
                      :merchant_name => @streams[0].stream_package.merchant.business_name,
                      :merchant_city => @streams[0].stream_package.merchant.city_name,
                      :amount => help.number_to_currency((@payment.from_amount_cents/100.00).round(2).to_s, :unit => Money::Currency.table[@payment.from_currency["iso_code"].to_sym][:symbol]).html_safe,
                      :payment_url => @app_root_url + "payments/" + @payment.id.to_s + "/edit").html_safe + 
                    t('emailer.stream_new.blank', :fill_variable => @summary_table).html_safe + 
                    (@payment_has_direct_style ? t('emailer.stream_new.table_legend_direct', :app_root_url => @app_root_url).html_safe : "") + 
                    (@payment_has_voucher_style ? t('emailer.stream_new.table_legend_voucher', :app_root_url => @app_root_url).html_safe : "") + 
                    t('emailer.stream_new.action_table', 
                      :app_root_url => @app_root_url, 
                      :invite_url => @user.get_promo_code).html_safe +
                    t('emailer.stream_new.contact').html_safe
      @welcome = t('emailer.hello') + (@user.first_name != nil ? @user.first_name : @user.username)
      @goodbye = t('emailer.beneficiary_request.goodbye')
    else
      @subject = t('emailer.stream_new.subject', 
                    :purpose => @streams[0].purpose, 
                    :and_more => (@count > 1 ? t('emailer.stream_new.and_more') : ""))
      @headline = t('emailer.stream_new.headline')
      @email_body = ((@payment.amount_subtotal_in_to_currency != @payment.to_amount_subtotal_cents) ? 
                      (t('payment.show.confirmation_prepaid',
                        :amount => help.number_to_currency(((@payment.amount_subtotal_in_to_currency)/100.00).round(2).to_s, :unit => Currency.find_by_code(@payment.streams[0].currency.downcase).name),
                        :prepaid_charge => help.number_to_currency(((@payment.amount_subtotal_in_to_currency - @payment.to_amount_subtotal_cents)/100.00).round(2).to_s, :unit => Currency.find_by_code(@payment.streams[0].currency.downcase).name),
                        :prepaid_balance => help.number_to_currency(((@payment.user.get_stored_balance(@payment.streams[0].currency.downcase))/100.00).round(2).to_s, :unit => Currency.find_by_code(@payment.streams[0].currency.downcase).name)).html_safe) : "") +
                    ((@payment.to_amount_subtotal_cents > 0) ? 
                      (t('payment.show.confirmation_payment', 
                        :amount => help.number_to_currency(((@payment.from_amount_cents)/100.00).round(2).to_s, :unit => Money::Currency.table[@payment.from_currency["iso_code"].to_sym][:symbol]).html_safe).html_safe) : "") +
                    t('emailer.stream_new.details',
                      :confirmation_number => payment.pnr_id).html_safe + 
                    t('emailer.stream_new.blank', :fill_variable => @summary_table).html_safe + 
                    (@payment_has_direct_style ? t('emailer.stream_new.table_legend_direct', :app_root_url => @app_root_url).html_safe : "") + 
                    (@payment_has_voucher_style ? t('emailer.stream_new.table_legend_voucher', :app_root_url => @app_root_url).html_safe : "") + 
                    t('emailer.stream_new.action_table', 
                      :app_root_url => @app_root_url, 
                      :invite_url => @user.get_promo_code).html_safe +
                    t('emailer.stream_new.contact').html_safe
      @welcome = t('emailer.hello') + (@user.first_name != nil ? @user.first_name : @user.username)
      @goodbye = t('emailer.stream_new.goodbye')
    end

    @info = t('emailer.stream_new.info')

    mail_it_with_bcc(@user.email, Willstream::Config.outgoing_email, @subject, @@generic)
  end

  #Notification to merchant when a stream is purchased
  def stream_merchant_notification(stream, merchant)
    @stream = stream
    I18n.locale = merchant.locale.present? ? merchant.locale : 'fr'
    @app_root_url = "http://#{Willstream::Config.merchant_home}/"
    @subject = t('emailer.merchant_notif.subject', 
                 :package_name => (@stream.stream_package.i18n_title.present? ? @stream.stream_package.i18n_title : "Not Specified"),
                 :from_user => "@" + @stream.user.friendly_name,
                 :amount => help.number_to_currency((@stream.amount_cents / 100), :unit => Currency.find_by_code(@stream.currency.upcase).name)).html_safe
    @headline = t('emailer.merchant_notif.headline').html_safe
    @welcome = t('emailer.hello').html_safe
    @email_body = t('emailer.merchant_notif.body',
                    :from_user => "@" + @stream.user.friendly_name,
                    :package_name => (@stream.stream_package.i18n_title.present? ? @stream.stream_package.i18n_title : "Not Specified"),
                    :amount => help.number_to_currency((@stream.amount_cents / 100), :unit => Currency.find_by_code(@stream.currency.upcase).name),
                    :stream_number => @stream.code,
                    :instructions => @stream.sender_notes.present? ? @stream.sender_notes : "None Specified",
                    :profile_link => @app_root_url + merchant.username).html_safe
    @goodbye = t('emailer.merchant_notif.goodbye').html_safe

    if merchant.cell_number.present?
      begin
        SMS.send(SMS.i18n_dest(merchant.cell_number, merchant.country), t("emailer.merchant_notif.#{@stream.stream_package.present? ? @stream.stream_package.merchant.username : ''}.sms", 
                                                                        :from_user => @stream.user.friendly_name,
                                                                        :package_name => (@stream.stream_package.i18n_title.present? ? @stream.stream_package.i18n_title : "Not Specified"),
                                                                        :amount => help.number_to_currency((@stream.amount_cents / 100), :unit => Currency.find_by_code(@stream.currency.upcase).name),
                                                                        :default => t('emailer.merchant_notif.sms', 
                                                                                      :from_user => @stream.user.friendly_name,
                                                                                      :package_name => (@stream.stream_package.i18n_title.present? ? @stream.stream_package.i18n_title : "Not Specified"),
                                                                                      :amount => help.number_to_currency((@stream.amount_cents / 100), :unit => Currency.find_by_code(@stream.currency.upcase).name))))
        if @stream.sender_notes.present?
          SMS.send(SMS.i18n_dest(merchant.cell_number, merchant.country), t('emailer.merchant_notif.sms_instructions', 
                                          :from_user => @stream.user.friendly_name,
                                          :instructions => @stream.sender_notes))
        end
      rescue Exception => e
        Rails.logger.info('Exception in sending SMS stream notification to merchant.')
      end
    end
    
    mail_it_with_bcc(merchant.email, Willstream::Config.outgoing_email, @subject, @@page_stack)
  end

  #Notification to users when a stream is redeemed
  def transaction_notification(trans)
    @trans = trans
    I18n.locale = @trans.stream.user ? @trans.stream.user.locale : 'fr'
    @app_root_url = "http://#{Willstream::Config.user_home}/"
    @subject = t('emailer.stream_txn.subject',
                  :amount => help.number_to_currency(@trans.amount_cents.to_f/100, :unit => Currency.find_by_code(@trans.currency.upcase).name),
                  :business_name => @trans.merchant.business_name).html_safe
    @headline = t('emailer.stream_txn.headline').html_safe
    @welcome = t('emailer.hello').html_safe + (@trans.stream.user.first_name != nil ? @trans.stream.user.first_name : @trans.stream.user.username)
    @email_body = (@trans.stream.is_direct? ? 
                    t("emailer.stream_txn.#{@trans.merchant.username}.body_direct",
                      :stream_code => @trans.stream.code,
                      :txn_amount => help.number_to_currency(@trans.amount_cents.to_f/100, :unit => Currency.find_by_code(@trans.currency.upcase).name).to_s,
                      :business_name => @trans.merchant.business_name,
                      :business_url => @app_root_url + @trans.merchant.username,
                      :default => t('emailer.stream_txn.body_direct',
                                    :stream_code => @trans.stream.code,
                                    :txn_amount => help.number_to_currency(@trans.amount_cents.to_f/100, :unit => Currency.find_by_code(@trans.currency.upcase).name).to_s,
                                    :business_name => @trans.merchant.business_name,
                                    :business_url => @app_root_url + @trans.merchant.username)
                    ).html_safe :
                    t("emailer.stream_txn.#{@trans.merchant.username}.body_voucher",
                      :stream_code => @trans.stream.code,
                      :txn_amount => help.number_to_currency(@trans.amount_cents.to_f/100, :unit => Currency.find_by_code(@trans.currency.upcase).name).to_s,
                      :business_name => @trans.merchant.business_name,
                      :business_url => @app_root_url + @trans.merchant.username,
                      :beneficiary_number => @trans.stream.beneficiary.phone_number,
                      :business_name => @trans.merchant.business_name,
                      :balance => help.number_to_currency(@trans.stream.balance_cents/100, :unit => Currency.find_by_code(@trans.currency.upcase).name).to_s,
                      :default => t('emailer.stream_txn.body_voucher',
                                    :stream_code => @trans.stream.code,
                                    :txn_amount => help.number_to_currency(@trans.amount_cents.to_f/100, :unit => Currency.find_by_code(@trans.currency.upcase).name).to_s,
                                    :business_name => @trans.merchant.business_name,
                                    :business_url => @app_root_url + @trans.merchant.username,
                                    :beneficiary_number => @trans.stream.beneficiary.phone_number,
                                    :business_name => @trans.merchant.business_name,
                                    :balance => help.number_to_currency(@trans.stream.balance_cents/100, :unit => Currency.find_by_code(@trans.currency.upcase).name).to_s)
                    ).html_safe) + 
                  t('emailer.stream_txn.action_table',
                    :app_root_url => @app_root_url,
                    :business_name => @trans.merchant.business_name,
                    :business_url => @app_root_url + @trans.merchant.username,
                    :city_search_url => @app_root_url + "merchants?city=" + @trans.merchant.city_name,
                    :business_city => @trans.merchant.city_name,
                    :invite_url => @trans.stream.user.get_promo_code).html_safe
    @goodbye = t('emailer.stream_txn.goodbye')

    mail_it_with_bcc(@trans.stream.user.email, Willstream::Config.outgoing_email, @subject, @@generic)
    if @trans.stream.category == Category.find_by_category_desc("Transport")
      SMS.send(SMS.i18n_dest(@trans.stream.beneficiary.phone_number, Country.find(@trans.stream.payment.to_country)), 
             t("sms.stream_txn.#{@trans.merchant.username}.redeem", 
                :business_name => @trans.merchant.business_name,
                :amount => help.number_to_currency(@trans.amount_cents / 100, :unit => Currency.find_by_code(@trans.currency.upcase).name).to_s,
                :code => @trans.stream.code,
                :balance => help.number_to_currency(@trans.stream.balance, :unit => Currency.find_by_code(@trans.currency.upcase).name).to_s,
                :package_title => @trans.stream.stream_package.present? ? @trans.stream.stream_package.i18n_title : "",
                :default => t("sms.stream_txn.redeem",
                              :business_name => @trans.merchant.business_name,
                              :amount => help.number_to_currency(@trans.amount_cents / 100, :unit => Currency.find_by_code(@trans.currency.upcase).name).to_s,
                              :code => @trans.stream.code,
                              :balance => help.number_to_currency(@trans.stream.balance, :unit => Currency.find_by_code(@trans.currency.upcase).name,
                              :package_title => @trans.stream.stream_package.present? ? @trans.stream.stream_package.i18n_title : "").to_s)))
    end
  end
  
  def user_signup_notification(user)
    @user = user
    I18n.locale = @user ? @user.locale : 'en'
    @app_root_url = "http://#{Willstream::Config.user_home}/"
    @subject = t('emailer.new_user.transport_subject')
    @headline = t('emailer.new_user.headline')
    @welcome = t('emailer.hello') + (@user.first_name != nil ? @user.first_name : @user.username)
    @email_body = @user.activation_reason == (User::SELF_ENROL || User::INVITE) ?
                  t('emailer.new_user.transport_body', :app_root_url => @app_root_url, :username => @user.username) :
                  t('emailer.new_user.transport_body', :app_root_url => @app_root_url, :username => @user.username, :temp_password => @user.password)
    @goodbye = t('emailer.new_user.goodbye')

    mail_it_with_bcc(@user.email, Willstream::Config.outgoing_email, @subject, @@page_stack)
  end
  
  def new_merchant_activation(new_merchant, url)
    @merchant = new_merchant
    I18n.locale = @merchant.locale || 'fr'
    @app_root_url = "http://#{Willstream::Config.merchant_home}/"
    @subject = t('emailer.welcome_to_willstream')
    @headline = t('emailer.new_merchant.headline')
    @welcome = t('emailer.hello') + @merchant.business_name
    @email_body = t('emailer.new_merchant.body',
                    :country => @merchant.country.nameFR,
                    :accept_url => url,
                    :username => @merchant.username,
                    :password => @merchant.password,
                    :copy_link => t('emailer.copy_link', :url => url))
    @goodbye = t('emailer.thanks')

    mail_it_with_bcc(@merchant.email, Willstream::Config.outgoing_email, @subject, @@page_stack)
  end

  def new_referred_merchant(new_referred_merchant, user)
    I18n.locale = 'fr'
    @referred_merchant = new_referred_merchant
    I18n.locale = user ? user.locale : 'fr'
    @app_root_url = "http://#{Willstream::Config.merchant_home}/"
    @subject = t('emailer.new_referred_merchant.subject')
    @headline = t('emailer.new_referred_merchant.headline')
    @welcome = t('emailer.hello')
    if user != nil
      @referring_user_details = user.username +
      " (Id: " + user.id.to_s +
      ") (Signup Coupon: " + (user.signup_coupon_code ? user.signup_coupon_code : "None") + ")"
    else
      @referring_user = "Anonymous User"
    end
    @email_body = t('emailer.new_referred_merchant.body',
                    :merchant_name => @referred_merchant.merchant_name,
                    :merchant_address => @referred_merchant.merchant_address,
                    :merchant_contact => @referred_merchant.contact_info,
                    :referrer_name => @referred_merchant.referrer_name,
                    :referrer_email => @referred_merchant.referrer_email,
                    :referrer_phone => @referred_merchant.referrer_phone,
                    :referrer_notes => @referred_merchant.notes,
                    :referring_user => @referring_user_details,
                    :referred_at => @referred_merchant.created_at.strftime("%d.%m.%y %H:%M"))
    @goodbye = t('emailer.thanks')

    # TODO - Configure this to get the email address from somewhere
    mail_it_with_bcc('referamerchant@willstream.com', Willstream::Config.outgoing_email, @subject, @@page_stack)
  end

  def merchant_referral_complete(new_referred_merchant)
    I18n.locale = 'fr'
    @referred_merchant = new_referred_merchant
    I18n.locale = @referred_merchant.user ? @referred_merchant.user.locale : 'fr'
    @app_root_url = "http://#{Willstream::Config.user_home}/"
    @subject = t('emailer.merchant_referral_complete.subject', 
                  :referred_merchant_info => @referred_merchant.merchant_name)
    @headline = t('emailer.merchant_referral_complete.headline',
                   :merchant_name => @referred_merchant.merchant.business_name,
                   :merchant_city => @referred_merchant.merchant.city_name)
    @welcome = t('emailer.hello')
    @email_body = t('emailer.merchant_referral_complete.body',
                    :referred_merchant_info => @referred_merchant.merchant_name,
                    :referral_date => @referred_merchant.created_at.strftime("%d.%m.%y"),
                    :merchant_name => @referred_merchant.merchant.business_name,
                    :merchant_city => @referred_merchant.merchant.city_name,
                    :profile_url => @app_root_url + @referred_merchant.merchant.username,
                    :pay_url => @app_root_url + "payments/new?merchantId=" + @referred_merchant.merchant.id.to_s)
    @goodbye = t('emailer.thanks')

    # TODO - Configure this to get the email address from somewhere
    mail_it_with_bcc(@referred_merchant.referrer_email, Willstream::Config.outgoing_email, @subject, @@page_stack)
  end

  def merchant_referral_contacted(new_referred_merchant)
    I18n.locale = 'fr'
    @referred_merchant = new_referred_merchant
    I18n.locale = @referred_merchant.user ? @referred_merchant.user.locale : 'fr'
    @app_root_url = "http://#{Willstream::Config.user_home}/"
    @subject = t('emailer.merchant_referral_contacted.subject', 
                  :referred_merchant_info => @referred_merchant.merchant_name)
    @headline = t('emailer.merchant_referral_contacted.headline',
                   :merchant_name => @referred_merchant.merchant.business_name,
                   :merchant_city => @referred_merchant.merchant.city_name)
    @welcome = t('emailer.hello')
    @email_body = t('emailer.merchant_referral_contacted.body',
                    :referred_merchant_info => @referred_merchant.merchant_name,
                    :merchant_name => @referred_merchant.merchant.business_name,
                    :merchant_city => @referred_merchant.merchant.city_name,
                    :referral_date => @referred_merchant.created_at.strftime("%d.%m.%y"),
                    :willstream_home => @app_root_url)
    @goodbye = t('emailer.thanks')

    # TODO - Configure this to get the email address from somewhere
    mail_it_with_bcc(@referred_merchant.referrer_email, Willstream::Config.outgoing_email, @subject, @@page_stack)
  end

  def successful_referral(completed_referred_merchant, user)
    I18n.locale = 'fr'
    @referral = completed_referred_merchant
    I18n.locale = user ? user.locale : 'fr'
    @app_root_url = "http://#{Willstream::Config.user_home}/"
    @subject = t('emailer.successful_referral.subject')
    @headline = t('emailer.successful_referral.headline')
    @welcome = t('emailer.hello') + " " + @referral.referrer_name
    @email_body = t('emailer.successful_referral.body',
                    :merchant_name => @referral.merchant_name,
                    :referrer_contact_info => @referral.referrer_name + ", " + @referral.referrer_phone + ", " + @referral.referrer_email,
                    :referral_url => @app_root_url + "referred_merchants/new")
    @goodbye = t('emailer.thanks')

    # TODO - Configure this to get the email address from somewhere
    mail_it_with_bcc(@referral.referrer_email, Willstream::Config.outgoing_email, @subject, @@page_stack)
  end

  def successful_referral_and_signup(completed_referred_merchant, user)
    I18n.locale = 'fr'
    @referral = completed_referred_merchant
    I18n.locale = user ? user.locale : 'fr'
    @app_root_url = "http://#{Willstream::Config.user_home}/"
    @subject = t('emailer.successful_referral_and_signup.subject', :referred_merchant_name => @referral.merchant_name)
    @headline = t('emailer.successful_referral_and_signup.headline')
    @welcome = t('emailer.hello') + " " + @referral.referrer_name
    @email_body = t('emailer.successful_referral_and_signup.body',
                    :app_root_url => @app_root_url,
                    :referred_merchant_name => @referral.merchant_name,
                    :referrer_contact_info => @referral.referrer_name + ", " + @referral.referrer_phone + ", " + @referral.referrer_email,
                    :username => user.username,
                    :temp_password => user.temporary_password,
                    :referral_url => @app_root_url + "referred_merchants/new")
    @goodbye = t('emailer.successful_referral_and_signup.goodbye')

    # TODO - Configure this to get the email address from somewhere
    mail_it_with_bcc(user.email, Willstream::Config.outgoing_email, @subject, @@generic)
  end

  def successful_beneficiary_referral(beneficiary_name, completed_referred_merchant, user)
    I18n.locale = 'fr'
    @referral = completed_referred_merchant
    I18n.locale = user ? user.locale : 'fr'
    @app_root_url = "http://#{Willstream::Config.user_home}/"
    @subject = t('emailer.successful_beneficiary_referral.subject',
                 :beneficiary_name => beneficiary_name,
                 :referred_merchant_name => @referral.merchant_name,
                 :city_name => @referral.merchant_address)
    @headline = t('emailer.successful_beneficiary_referral.headline',
                  :beneficiary_name => beneficiary_name)
    @welcome = t('emailer.hello') + " " + (user.first_name.present? ? user.first_name : user.username)
    @email_body = t('emailer.successful_beneficiary_referral.body',
                    :beneficiary_name => beneficiary_name,
                    :referred_merchant_name => @referral.merchant_name,
                    :referral_url => @app_root_url + "/referred_merchants/new",
                    :referral_contact_info => @referral.merchant_name + ", " + @referral.merchant_address + ", " + @referral.contact_info)
    @goodbye = ""

    # TODO - Configure this to get the email address from somewhere
    mail_it_with_bcc(user.email, Willstream::Config.outgoing_email, @subject, @@page_stack)
  end

  def successful_beneficiary_referral_and_invite(beneficiary_name, completed_referred_merchant, user)
    I18n.locale = 'fr'
    @referral = completed_referred_merchant
    I18n.locale = user ? user.locale : 'fr'
    @app_root_url = "http://#{Willstream::Config.user_home}/"
    @subject = t('emailer.successful_beneficiary_referral_and_invite.subject',
                 :beneficiary_name => beneficiary_name,
                 :referred_merchant_name => @referral.merchant_name,
                 :city_name => @referral.merchant_address)
    @headline = t('emailer.successful_beneficiary_referral_and_invite.headline',
                  :beneficiary_name => beneficiary_name,
                  :referred_merchant_name => @referral.merchant_name,
                  :city_name => @referral.merchant_address)
    @welcome = t('emailer.hello') + " " + (user.first_name.present? ? user.first_name : user.username)
    @email_body = t('emailer.successful_beneficiary_referral_and_invite.body',
                    :beneficiary_name => beneficiary_name,
                    :referred_merchant_name => @referral.merchant_name,
                    :city_name => @referral.merchant_address,
                    :referral_url => @app_root_url + "referred_merchants/new",
                    :app_root_url => @app_root_url,
                    :username => user.username,
                    :temp_password => user.temporary_password,
                    :referral_contact_info => @referral.merchant_name + ", " + @referral.merchant_address + ", " + @referral.contact_info)
    @goodbye = t('emailer.successful_beneficiary_referral_and_invite.goodbye')

    # TODO - Configure this to get the email address from somewhere
    mail_it_with_bcc(user.email, Willstream::Config.outgoing_email, @subject, @@generic)
  end

  def successful_beneficiary_invite(beneficiary_name, user)
    I18n.locale = 'fr'
    I18n.locale = user ? user.locale : 'fr'
    @app_root_url = "http://#{Willstream::Config.user_home}/"
    @subject = t('emailer.successful_beneficiary_invite.subject',
                 :beneficiary_name => beneficiary_name)
    @headline = t('emailer.successful_beneficiary_invite.headline',
                  :beneficiary_name => beneficiary_name)
    @welcome = t('emailer.hello') + " " + (user.first_name.present? ? user.first_name : user.username)
    @email_body = t('emailer.successful_beneficiary_invite.body',
                    :beneficiary_name => beneficiary_name,
                    :referral_url => @app_root_url + "referred_merchants/new",
                    :app_root_url => @app_root_url,
                    :username => user.username,
                    :temp_password => user.temporary_password)
    @goodbye = t('emailer.successful_beneficiary_invite.goodbye')

    # TODO - Configure this to get the email address from somewhere
    mail_it_with_bcc(user.email, Willstream::Config.outgoing_email, @subject, @@generic)
  end

  def new_registered_merchant(new_registered_merchant)
    @registered_merchant = new_registered_merchant
    I18n.locale = @registered_merchant.locale || 'fr'
    @app_root_url = "http://#{Willstream::Config.merchant_home}/"
    @subject = t('emailer.new_registered_merchant.subject')
    @biz_or_club = @registered_merchant.is_club? ? "Club" : "Business"
    @headline = t('emailer.new_registered_merchant.headline', :biz_or_club => @biz_or_club)
    @welcome = t('emailer.hello')
    @email_body = t('emailer.new_registered_merchant.body',
                    :biz_or_club => @biz_or_club,
                    :registered_at => @registered_merchant.created_at.strftime("%d.%m.%y %H:%M"),
                    :business_name => @registered_merchant.business_name,
                    :address => @registered_merchant.address_1 != nil ? @registered_merchant.address_1 : "",
                    :contact_name => @registered_merchant.contact_name,
                    :cell_number => @registered_merchant.cell_number,
                    :email => @registered_merchant.email)
    @goodbye = t('emailer.thanks')

    # TODO - Configure this to get the email address from somewhere
    mail_it_with_bcc(new_registered_merchant.partner.email ? new_registered_merchant.partner.email : "senegal@willstream.com", Willstream::Config.outgoing_email, @subject, @@page_stack)
  end

  def new_club_invitation(club_connection, url)
    I18n.locale = club_connection.merchant.locale || 'fr'
    @club_connection = club_connection
    @app_root_url = "http://#{Willstream::Config.server_name}/"
    @from = @club_connection.merchant.business_name + " <" + @club_connection.merchant.email + ">"
    @subject = t('emailer.new_club_invitation.subject', :clubname => @club_connection.merchant.business_name)
    @headline = t('emailer.new_club_invitation.headline', :clubname => @club_connection.merchant.business_name)
    @welcome = t('emailer.hello') + @club_connection.connection_name
    @email_body = t('emailer.new_club_invitation.body',
                    :username => @club_connection.sender_username,
                    :clubname => @club_connection.merchant.business_name,
                    :accept_url => url,
                    :club_url => "http://#{Willstream::Config.user_home}/" + @club_connection.merchant.username,
                    :copy_link => t('emailer.copy_link', :url => url),
                    :message => @club_connection.notes)
    @goodbye = t('emailer.thanks')

    mail_it_with_bcc_from(@from, @club_connection.connection_email, Willstream::Config.outgoing_email, @subject, @@page_stack)
  end

  def new_club_welcome(merchant)
    I18n.locale = merchant.locale || 'fr'
    @merchant = merchant
    @app_root_url = "http://#{Willstream::Config.server_name}/"
    @subject = t('emailer.new_club_welcome.subject')
    @headline = t('emailer.new_club_welcome.headline')
    @welcome = t('emailer.new_club_welcome.subject')
    @email_body = t('emailer.new_club_welcome.body',
                    :username => @merchant.username,
                    :clubname => @merchant.business_name,
                    :contact_name => @merchant.contact_name)
    @goodbye = t('emailer.thanks')

    mail_it_with_bcc(@merchant.email, Willstream::Config.outgoing_email, @subject, @@generic)
  end

  def activation_thanks(activated_merchant, user)
    I18n.locale = user.locale || 'fr'
    @user = user
    @merchant = activated_merchant
    @app_root_url = "http://#{Willstream::Config.server_name}/"
    @subject = t('emailer.activation_thanks.subject')
    @headline = t('emailer.activation_thanks.headline')
    @welcome = t('emailer.activation_thanks.welcome', :username => @user.username)
    @email_body = t('emailer.activation_thanks.body',
                    :username => @user.username,
                    :merchant_name => @merchant.business_name)
    @goodbye = t('emailer.thanks')

    mail_it_with_bcc(@user.email, Willstream::Config.outgoing_email, @subject, @@page_stack)
  end

  def user_invite(invite)
    I18n.locale = invite.user.locale || 'fr'
    @app_root_url = "http://#{Willstream::Config.server_name}/"
    @subject = t('emailer.user_invite.subject', :user_name => invite.name)
    @headline = t('emailer.user_invite.headline')
    @welcome = t('emailer.user_invite.welcome')
    @email_body = t('emailer.user_invite.body',
                    :user_name => invite.name,
                    :invite_url => @app_root_url + "inv/" + invite.authentication_token)
    @goodbye = t('emailer.thanks')

    @from = invite.name + " <noreply@willstream.com>"

    mail_it_with_bcc_from(@from, invite.invite_email, Willstream::Config.outgoing_email, @subject, @@generic)
  end

  def topup_notification(user, from_amount, to_amount, current_balance)
    I18n.locale = user.locale || 'fr'
    @app_root_url = "http://#{Willstream::Config.server_name}/"
    @subject = t('emailer.topup_notification.subject', :amount => to_amount)
    @headline = t('emailer.topup_notification.headline')
    @welcome = t('emailer.topup_notification.welcome', :name => user.friendly_name)
    @email_body = t('emailer.topup_notification.body',
                    :from_amount => from_amount,
                    :to_amount => to_amount,
                    :current_balance => current_balance,
                    :home_url => @app_root_url)
    @goodbye = ""
    mail_it_with_bcc(user.email, Willstream::Config.outgoing_email, @subject, @@generic)
  end

  def user_referral_bonus_notification_sender(referring_user, referred_user, to_amount, current_balance)
    I18n.locale = referring_user.locale || 'fr'
    @app_root_url = "http://#{Willstream::Config.server_name}/"
    @subject = t('emailer.user_referral_bonus_notification_sender.subject', :amount => to_amount, :referred_name => referred_user.friendly_name)
    @headline = t('emailer.user_referral_bonus_notification_sender.headline', :amount => to_amount)
    @welcome = t('emailer.user_referral_bonus_notification_sender.welcome', :name => referring_user.friendly_name)
    @email_body = t('emailer.user_referral_bonus_notification_sender.body',
                    :referred_name => referred_user.friendly_name,
                    :amount => to_amount,
                    :current_balance => current_balance,
                    :home_url => @app_root_url)
    @goodbye = ""
    mail_it_with_bcc(referring_user.email, Willstream::Config.outgoing_email, @subject, @@generic)
  end

  def user_referral_bonus_notification_receiver(referring_user, referred_user, to_amount, current_balance)
    I18n.locale = referred_user.locale || 'fr'
    @app_root_url = "http://#{Willstream::Config.server_name}/"
    @subject = t('emailer.user_referral_bonus_notification_receiver.subject', :amount => to_amount)
    @headline = t('emailer.user_referral_bonus_notification_receiver.headline', :amount => to_amount)
    @welcome = t('emailer.user_referral_bonus_notification_receiver.welcome', :name => referred_user.friendly_name)
    @email_body = t('emailer.user_referral_bonus_notification_receiver.body',
                    :referring_name => referring_user.friendly_name,
                    :amount => to_amount,
                    :current_balance => current_balance,
                    :home_url => @app_root_url)
    @goodbye = ""
    mail_it_with_bcc(referred_user.email, Willstream::Config.outgoing_email, @subject, @@generic)
  end

  def general_bonus_notification(user, message, to_amount, current_balance)
    I18n.locale = user.locale || 'fr'
    @app_root_url = "http://#{Willstream::Config.server_name}/"
    @subject = t('emailer.general_bonus_notification.subject', :amount => to_amount)
    @headline = t('emailer.general_bonus_notification.headline', :amount => to_amount)
    @welcome = t('emailer.general_bonus_notification.welcome', :name => user.friendly_name)
    @email_body = t('emailer.general_bonus_notification.body',
                    :message => message.present? ? message + "<br><br>" : "",
                    :amount => to_amount,
                    :current_balance => current_balance,
                    :home_url => @app_root_url)
    @goodbye = ""
    mail_it_with_bcc(user.email, Willstream::Config.outgoing_email, @subject, @@generic)
  end

  def postpaid_budget_notification(postpaid_budget)
    I18n.locale = postpaid_budget.user.locale || 'fr'
    @app_root_url = "http://#{Willstream::Config.server_name}/"
    @subject = t('emailer.postpaid_budget_notification.subject', 
                  :amount => "#{postpaid_budget.amount} CFA",
                  :po_id => postpaid_budget.po_id.present? ? postpaid_budget.po_id : 'N/A',
                  :merchant => postpaid_budget.merchant.display_name)
    @headline = ""
    @welcome = t('emailer.general_bonus_notification.welcome', :name => postpaid_budget.user.friendly_name)
    @email_body = t('emailer.postpaid_budget_notification.body',
                    :home_url => @app_root_url,
                    :amount => "#{postpaid_budget.amount} CFA",
                    :po_id => postpaid_budget.po_id.present? ? postpaid_budget.po_id : 'N/A',
                    :merchant => postpaid_budget.merchant.display_name,
                    :invoice_date => l(postpaid_budget.fulfillment_date, format: :short),
                    :fulfillment_date => l(postpaid_budget.fulfillment_date, format: :short),
                    :invoice_number => "AW#{postpaid_budget.merchant_id.to_s.rjust(5,'0')}-#{postpaid_budget.id.to_s.rjust(12,'0')}",
                    :total_amount_due => "#{postpaid_budget.amount + postpaid_budget.total_service_fees} CFA",
                    :settlement_details => postpaid_budget.merchant.om_settlement_details.present? ? postpaid_budget.merchant.om_settlement_details.html_safe : "A Régler",
                    :approval_stamp_photo => "<img src='http://#{Willstream::Config.server_name}/assets/#{postpaid_budget.merchant.invoice_stamp.url(:medium)}'/>".html_safe,
                    :po_id => postpaid_budget.po_id.present? ? postpaid_budget.po_id : 'N/A',
                    :user => postpaid_budget.user.friendly_name
                   )
    @goodbye = ""
    headers['Return-Receipt-To'] = postpaid_budget.merchant.email
    mail_it_with_cc_bcc(postpaid_budget.user.email, postpaid_budget.merchant.email, Willstream::Config.outgoing_email, @subject, @@generic)
  end

  def postpaid_budget_expiry_notification(postpaid_budget)
    I18n.locale = postpaid_budget.user.locale || 'fr'
    @app_root_url = "http://#{Willstream::Config.server_name}/"
    @subject = t('emailer.postpaid_budget_expiry_notification.subject', 
                  :amount => "#{postpaid_budget.amount} CFA",
                  :po_id => postpaid_budget.po_id.present? ? postpaid_budget.po_id : 'N/A',
                  :merchant => postpaid_budget.merchant.display_name)
    @headline = ""
    @welcome = ""
    @email_body = t('emailer.postpaid_budget_expiry_notification.body',
                    :home_url => @app_root_url,
                    :invoice_date => l(postpaid_budget.invoice_date, format: :short),
                    :fulfillment_date => l(postpaid_budget.fulfillment_date, format: :short),
                    :invoice_number => "AW#{postpaid_budget.merchant_id.to_s.rjust(5,'0')}-PBU#{postpaid_budget.id.to_s.rjust(12,'0')}",
                    :amount => "#{postpaid_budget.amount} CFA",
                    :consumed_amount => "#{postpaid_budget.amount_consumed_to_date} CFA",
                    :total_tickets => postpaid_budget.total_ticket_events,
                    :sent_tickets => postpaid_budget.total_tickets_sent,
                    :validated_tickets => postpaid_budget.total_ticket_validations,
                    :cancelled_tickets => postpaid_budget.total_tickets_cancelled,
                    :per_ticket_fee => postpaid_budget.service_fee_per_ticket_event,
                    :service_fees => "#{postpaid_budget.total_service_fees} CFA",
                    :total_amount_due => "#{postpaid_budget.amount + postpaid_budget.total_service_fees} CFA",
                    :settlement_details => postpaid_budget.merchant.om_settlement_details.present? ? postpaid_budget.merchant.om_settlement_details.html_safe : "A Régler",
                    :approval_stamp_photo => "<img src='http://#{Willstream::Config.server_name}/assets/#{postpaid_budget.merchant.invoice_stamp.url(:medium)}'/>".html_safe,
                    :po_id => postpaid_budget.po_id.present? ? postpaid_budget.po_id : 'N/A',
                    :merchant => postpaid_budget.merchant.display_name,
                    :user => postpaid_budget.user.friendly_name)
    @goodbye = ""
    headers['Return-Receipt-To'] = postpaid_budget.merchant.email
    mail_it_with_cc_bcc(postpaid_budget.user.email, postpaid_budget.merchant.email, Willstream::Config.outgoing_email, @subject, @@generic)
  end

  def postpaid_fee_invoice_notification(invoice)
    I18n.locale = invoice.postpaid_agreement.user.locale || 'fr'
    @app_root_url = "http://#{Willstream::Config.server_name}/"
    @subject = t('emailer.postpaid_fee_invoice_notification.subject',
                  :merchant => invoice.postpaid_agreement.merchant.display_name,
                  :billing_period_start => I18n.l(invoice.billing_period_start, format: :short), 
                  :billing_period_end => I18n.l(invoice.billing_period_end, format: :short), 
                  :amount => "#{(invoice.total_flat_fee + invoice.total_percent_fee).round(2)} CFA")
    @headline = ""
    @welcome = ""
    @email_body = t('emailer.postpaid_fee_invoice_notification.body',
                    :home_url => @app_root_url,
                    :billing_period_start => I18n.l(invoice.billing_period_start, format: :short), 
                    :billing_period_end => I18n.l(invoice.billing_period_end, format: :short),
                    :invoice_number => "AW#{invoice.postpaid_agreement.merchant_id.to_s.rjust(5,'0')}-PFI#{invoice.id.to_s.rjust(12,'0')}",
                    :total_tickets => invoice.total_ticket_events,
                    :sent_tickets => invoice.total_tickets_sent,
                    :validated_tickets => invoice.total_ticket_validations,
                    :cancelled_tickets => invoice.total_tickets_cancelled,
                    :per_ticket_flat_fee => "#{invoice.flat_fee_rate} CFA",
                    :per_ticket_percent_fee => "#{invoice.percent_fee_rate}%",
                    :total_amount_sent => "#{invoice.total_amount_sent} CFA",
                    :total_amount_validated => "#{invoice.total_amount_validated} CFA",
                    :total_flat_fee => "#{invoice.total_flat_fee} CFA",
                    :total_percent_fee => "#{invoice.total_percent_fee} CFA",
                    :amount => "#{(invoice.total_flat_fee + invoice.total_percent_fee).round(2)} CFA",
                    :settlement_details => invoice.postpaid_agreement.merchant.om_settlement_details.present? ? invoice.postpaid_agreement.merchant.om_settlement_details.html_safe : "A Régler",
                    :approval_stamp_photo => "<img src='http://#{Willstream::Config.server_name}/assets/#{invoice.postpaid_agreement.merchant.invoice_stamp.url(:medium)}'/>".html_safe,
                    :merchant => invoice.postpaid_agreement.merchant.display_name,
                    :user => invoice.postpaid_agreement.user.friendly_name)
    @goodbye = ""
    headers['Return-Receipt-To'] = invoice.postpaid_agreement.merchant.email
    mail_it_with_cc_bcc(invoice.postpaid_agreement.user.email, invoice.postpaid_agreement.merchant.email, Willstream::Config.outgoing_email, @subject, @@generic)
  end

  private

  def mail_it(to, subject, template)
    mail(:to => to,
         :subject => subject,
         :template_path => "emailer",
         :template_name => template)
  end

  def mail_it_with_cc(to, cc, subject, template)
    mail(:to => to,
         :cc => cc,
         :subject => subject,
         :template_path => "emailer",
         :template_name => template)
  end

  def mail_it_with_cc_bcc(to, cc, bcc, subject, template)
    mail(:to => to,
         :cc => cc,
         :bcc => bcc,
         :subject => subject,
         :template_path => "emailer",
         :template_name => template)
  end

  def mail_it_with_bcc(to, bcc, subject, template)
    mail(:to => to,
         :bcc => bcc,
         :subject => subject,
         :template_path => "emailer",
         :template_name => template)
  end

  def mail_it_with_bcc_from(from, to, bcc, subject, template)
    mail(:to => to,
         :from => from,
         :bcc => bcc,
         :subject => subject,
         :template_path => "emailer",
         :template_name => template)
  end

  def mail_it_with_from(from, to, subject, template)
    mail(:from => from,
    :to => to,
    :subject => subject,
    :template_path => "emailer",
    :template_name => template)
  end

  def get_recipient(message)
    recipient_id = message.recipient_id
    tablename = Usertype.getUserControllerName(message.recipienttype_id)
    recipient = User.find_by_sql("select id, email, locale from #{tablename} where id=#{recipient_id}")
    if recipient && recipient.count > 0
      recipient = recipient[0]
    end
    # Default recipient locale to english if it's nil
    if recipient.locale == nil
      recipient.locale = 'en'
    end

    return recipient
  end

  def get_sender(message)
    sender_id = message.sender_id
    sendertype_id = message.sendertype_id
    tablename = Usertype.getUserControllerName(sendertype_id)
    displaynamefield = Usertype.getDisplaynameFieldName(sendertype_id)
    sender = User.find_by_sql("select id, #{displaynamefield} as displayname from #{tablename} where id=#{sender_id}")
    if sender && sender.count > 0
      sender = sender[0]
    end

    return sender
  end

end