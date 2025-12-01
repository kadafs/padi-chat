
require_relative "../chaskiq_boot.rb"

# Patch action_policy-graphql to remove default_value from field options before eager loading
# GraphQL 1.13.x doesn't accept default_value as a keyword argument for fields
module ActionPolicyGraphQLPatch
  def initialize(*args, **kwargs, &block)
    # Remove default_value from kwargs if present (it's not valid for fields in GraphQL 1.13.x)
    kwargs = kwargs.dup
    kwargs.delete(:default_value) if kwargs.key?(:default_value)
    super(*args, **kwargs, &block)
  end
end

# Apply patch immediately if class is already loaded
if defined?(ActionPolicy::GraphQL::AuthorizedField)
  unless ActionPolicy::GraphQL::AuthorizedField < ActionPolicyGraphQLPatch
    ActionPolicy::GraphQL::AuthorizedField.prepend(ActionPolicyGraphQLPatch)
  end
end

if defined?(Rails::Server) || defined?(Rails::Console) || Sidekiq.server?
  Rails.application.config.to_prepare do
    # Ensure patch is applied before eager loading (in case class wasn't loaded yet)
    if defined?(ActionPolicy::GraphQL::AuthorizedField)
      unless ActionPolicy::GraphQL::AuthorizedField < ActionPolicyGraphQLPatch
        ActionPolicy::GraphQL::AuthorizedField.prepend(ActionPolicyGraphQLPatch)
      end
    end
    
    # This will force Rails to load all models
    Rails.application.eager_load!
    ChaskiqBoot.plugin_autoloader
  end
end