# frozen_string_literal: true

# Patch action_policy-graphql to remove default_value from field options
# GraphQL 1.13.x doesn't accept default_value as a keyword argument for fields
# (it's only valid for arguments, not fields)
module ActionPolicy
  module GraphQL
    class AuthorizedField < ::GraphQL::Schema::Field
      alias_method :original_initialize, :initialize

      def initialize(*args, **kwargs, &block)
        # Remove default_value from kwargs if present (it's not valid for fields in GraphQL 1.13.x)
        kwargs = kwargs.dup
        kwargs.delete(:default_value) if kwargs.key?(:default_value)
        
        original_initialize(*args, **kwargs, &block)
      end
    end
  end
end

