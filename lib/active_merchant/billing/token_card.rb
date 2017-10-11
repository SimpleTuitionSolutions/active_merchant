require 'time'
require 'date'
require "active_merchant/billing/model"

module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    # A +CreditCard+ object represents a physical credit card, and is capable of validating the various
    # data associated with these.
    #
    # At the moment, the following credit card types are supported:
    #
    # * Visa
    # * MasterCard
    # * Discover
    # * American Express
    # * Diner's Club
    # * JCB
    # * Switch
    # * Solo
    # * Dankort
    # * Maestro
    # * Forbrugsforeningen
    # * Laser
    #
    # For testing purposes, use the 'bogus' credit card brand. This skips the vast majority of
    # validations, allowing you to focus on your core concerns until you're ready to be more concerned
    # with the details of particular credit cards or your gateway.
    #
    # == Testing With CreditCard
    # Often when testing we don't care about the particulars of a given card brand. When using the 'test'
    # mode in your {Gateway}, there are six different valid card numbers: 1, 2, 3, 'success', 'fail',
    # and 'error'.
    #
    # For details, see {CreditCardMethods::ClassMethods#valid_number?}
    #
    # == Example Usage
    #   cc = CreditCard.new(
    #     :first_name         => 'Steve',
    #     :last_name          => 'Smith',
    #     :month              => '9',
    #     :year               => '2017',
    #     :brand              => 'visa',
    #     :number             => '4242424242424242',
    #     :verification_value => '424'
    #   )
    #
    #   cc.validate # => {}
    #   cc.display_number # => XXXX-XXXX-XXXX-4242
    #
    class TokenCard < Model
      include CreditCardMethods

      class << self
        # Inherited, but can be overridden w/o changing parent's value
        attr_accessor :require_name
      end

      self.require_name = true

      # Returns or sets the credit card token.
      #
      # @return [String]
      attr_reader :token

      def token=(value)
        @token = value
      end

      # Returns or sets the expiry month for the card.
      #
      # @return [Integer]
      attr_reader :month

      # Returns or sets the expiry year for the card.
      #
      # @return [Integer]
      attr_reader :year

      # Returns or sets the credit card brand.
      #
      # Valid card types are
      #
      # * +'visa'+
      # * +'master'+
      # * +'discover'+
      # * +'american_express'+
      # * +'diners_club'+
      # * +'jcb'+
      # * +'switch'+
      # * +'solo'+
      # * +'dankort'+
      # * +'maestro'+
      # * +'forbrugsforeningen'+
      # * +'laser'+
      #
      # Or, if you wish to test your implementation, +'bogus'+.
      #
      # @return (String) the credit card brand
      attr_reader :brand

      def brand=(value)
        @brand = (value.respond_to?(:downcase) ? value.downcase : value)
      end

      # Returns or sets the first name of the card holder.
      #
      # @return [String]
      attr_accessor :first_name

      # Returns or sets the last name of the card holder.
      #
      # @return [String]
      attr_accessor :last_name

      # Provides proxy access to an expiry date object
      #
      # @return [ExpiryDate]
      def expiry_date
        ExpiryDate.new(@month, @year)
      end

      # Returns whether the credit card has expired.
      #
      # @return +true+ if the card has expired, +false+ otherwise
      def expired?
        expiry_date.expired?
      end

      # Returns whether either the +first_name+ or the +last_name+ attributes has been set.
      def name?
        first_name? || last_name?
      end

      # Returns whether the +first_name+ attribute has been set.
      def first_name?
        first_name.present?
      end

      # Returns whether the +last_name+ attribute has been set.
      def last_name?
        last_name.present?
      end

      # Returns the full name of the card holder.
      #
      # @return [String] the full name of the card holder
      def name
        "#{first_name} #{last_name}".strip
      end

      def name=(full_name)
        names = full_name.split
        self.last_name  = names.pop
        self.first_name = names.join(" ")
      end

      %w(month year).each do |m|
        class_eval %(
          def #{m}=(v)
            @#{m} = case v
            when "", nil, 0
              nil
            else
              v.to_i
            end
          end
        )
      end

      # Validates the credit card details.
      #
      # Any validation errors are added to the {#errors} attribute.
      def validate
        errors = validate_essential_attributes

        errors_hash(
          errors +
          validate_card_brand
        )
      end

      def self.requires_name?
        require_name
      end

      private

      def validate_essential_attributes #:nodoc:
        errors = []

        if self.class.requires_name?
          errors << [:first_name, "cannot be empty"] if first_name.blank?
          errors << [:last_name,  "cannot be empty"] if last_name.blank?
        end

        if(empty?(month) || empty?(year))
          errors << [:month, "is required"] if empty?(month)
          errors << [:year,  "is required"] if empty?(year)
        else
          errors << [:month, "is not a valid month"] if !valid_month?(month)

          if expired?
            errors << [:year,  "expired"]
          else
            errors << [:year,  "is not a valid year"]  if !valid_expiry_year?(year)
          end
        end

        if empty?(token)
          errors << [:token, 'is required']
        end

        errors
      end

      def validate_card_brand #:nodoc:
        errors = []

        if empty?(brand)
          errors << [:brand, "is required"]
        else
          errors << [:brand, "is invalid"]  if !TokenCard.card_companies.keys.include?(brand)
        end

        errors
      end

      class ExpiryDate #:nodoc:
        attr_reader :month, :year
        def initialize(month, year)
          @month = month.to_i
          @year = year.to_i
        end

        def expired? #:nodoc:
          Time.now.utc > expiration
        end

        def expiration #:nodoc:
          begin
            Time.utc(year, month, month_days, 23, 59, 59)
          rescue ArgumentError
            Time.at(0).utc
          end
        end

        private
        def month_days
          mdays = [nil,31,28,31,30,31,30,31,31,30,31,30,31]
          mdays[2] = 29 if Date.leap?(year)
          mdays[month]
        end
      end
    end
  end
end
