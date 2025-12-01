# frozen_string_literal: true

# Patch action_policy-graphql to remove default_value from field options
# GraphQL 1.13.x doesn't accept default_value as a keyword argument for fields
# (it's only valid for arguments, not fields)
module ActionPolicyGraphQLPatch
  def initialize(*args, **kwargs, &block)
    # Remove default_value from kwargs if present (it's not valid for fields in GraphQL 1.13.x)
    kwargs = kwargs.dup
    kwargs.delete(:default_value) if kwargs.key?(:default_value)
    super(*args, **kwargs, &block)
  end
end

# Patch immediately if class is already loaded, otherwise use to_prepare
if defined?(ActionPolicy::GraphQL::AuthorizedField)
  ActionPolicy::GraphQL::AuthorizedField.prepend(ActionPolicyGraphQLPatch)
else
  Rails.application.config.to_prepare do
    if defined?(ActionPolicy::GraphQL::AuthorizedField)
      ActionPolicy::GraphQL::AuthorizedField.prepend(ActionPolicyGraphQLPatch) unless ActionPolicy::GraphQL::AuthorizedField < ActionPolicyGraphQLPatch
    end
  end
end

