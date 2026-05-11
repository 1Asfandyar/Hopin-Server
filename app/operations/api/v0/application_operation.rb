require "dry/matcher/result_matcher"
require "dry/monads"
require "dry/monads/do"

module Api::V0
  module ApplicationOperation
    def self.included(base)
      base.include Dry::Monads[:result, :do]
      base.extend ClassMethods
    end

    module ClassMethods
      def call(params = {}, **context, &block)
        instance = new
        validation = instance.send(:validate_contract, params)
        result = validation.failure? ? validation : instance.call(validation.value!, **context)
        return result unless block

        Dry::Matcher::ResultMatcher.call(result, &block)
      end
    end

    private

    def validate_contract(params)
      return Success(params) unless self.class.const_defined?(:Contract)

      result = self.class::Contract.new.call(params)
      return Success(result.to_h) if result.success?

      Failure(errors: result.errors.to_h)
    end
  end
end
