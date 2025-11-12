# frozen_string_literal: true

class FlowBuilder < ApplicationRecord
  belongs_to :app
  
  validates :name, presence: true
  validates :flow_type, inclusion: { 
    in: %w[welcome qualifying support feedback lead_generation abandoned_cart] 
  }
  
  scope :active, -> { where(active: true) }
  scope :by_type, ->(type) { where(flow_type: type) }
  scope :ordered, -> { order(:position) }
  
  before_validation :set_defaults
  
  # Tidio-like visual flow builder functionality
  def nodes
    flow_data['nodes'] || []
  end
  
  def connections
    flow_data['connections'] || []
  end
  
  def start_node
    nodes.find { |node| node['type'] == 'start' } || nodes.first
  end
  
  def execute_flow(visitor_session, conversation = nil, context = {})
    return unless active? && should_trigger_for?(visitor_session)
    
    current_node = start_node
    flow_context = context.merge(
      visitor_session: visitor_session,
      conversation: conversation,
      variables: {}
    )
    
    execute_node(current_node, flow_context)
  end
  
  def should_trigger_for?(visitor_session)
    return false unless triggers.present?
    
    triggers.all? do |trigger_type, conditions|
      case trigger_type
      when 'page_url'
        check_page_url_trigger(visitor_session, conditions)
      when 'time_on_page'
        check_time_trigger(visitor_session, conditions)
      when 'visitor_type'
        check_visitor_type_trigger(visitor_session, conditions)
      when 'custom_event'
        check_custom_event_trigger(visitor_session, conditions)
      else
        true
      end
    end
  end
  
  def duplicate!
    dup.tap do |new_flow|
      new_flow.name = "#{name} (Copy)"
      new_flow.active = false
      new_flow.flow_data = flow_data.deep_dup
      new_flow.triggers = triggers.deep_dup
      new_flow.save!
    end
  end
  
  def flow_stats
    {
      total_executions: 0, # TODO: Implement flow execution tracking
      successful_completions: 0,
      abandonment_rate: 0.0,
      average_completion_time: 0,
      most_common_exit_point: nil
    }
  end

  def calculate_abandonment_rate
    # TODO: Implement abandonment rate calculation
    0.0
  end

  def calculate_avg_completion_time
    # TODO: Implement average completion time calculation
    0
  end

  def find_most_common_exit_point
    # TODO: Implement exit point tracking
    nil
  end
  
  private
  
  def set_defaults
    self.flow_data ||= {
      'nodes' => [
        {
          'id' => SecureRandom.uuid,
          'type' => 'start',
          'position' => { 'x' => 100, 'y' => 100 },
          'data' => { 'label' => 'Flow Start' }
        }
      ],
      'connections' => []
    }
    self.triggers ||= {}
  end
  
  def execute_node(node, context)
    return unless node
    
    case node['type']
    when 'message'
      execute_message_node(node, context)
    when 'question'
      execute_question_node(node, context)
    when 'condition'
      execute_condition_node(node, context)
    when 'action'
      execute_action_node(node, context)
    when 'wait'
      execute_wait_node(node, context)
    when 'webhook'
      execute_webhook_node(node, context)
    when 'end'
      execute_end_node(node, context)
    end
  end
  
  def execute_message_node(node, context)
    message_data = node['data']
    conversation = context[:conversation]
    
    if conversation
      conversation.add_message(
        from: app.agent_bots.first,
        message: {
          html: message_data['content'],
          serialized_content: message_data['content']
        },
        message_source: 'flow_builder'
      )
    end
    
    # Continue to next node
    next_node = find_next_node(node)
    execute_node(next_node, context) if next_node
  end
  
  def execute_question_node(node, context)
    question_data = node['data']
    conversation = context[:conversation]
    
    if conversation
      # Send question with quick replies or input options
      message_content = {
        html: question_data['question'],
        serialized_content: question_data['question']
      }
      
      if question_data['options']&.any?
        message_content[:controls] = {
          type: 'data_retrieval',
          schema: question_data['options'].map { |option|
            { type: 'button', text: option['text'], value: option['value'] }
          }
        }
      end
      
      conversation.add_message(
        from: app.agent_bots.first,
        message: message_content,
        message_source: 'flow_builder'
      )
    end
    
    # Wait for user response (this would be handled asynchronously)
    # For now, just continue to next node
    next_node = find_next_node(node)
    execute_node(next_node, context) if next_node
  end
  
  def execute_condition_node(node, context)
    condition_data = node['data']
    visitor_session = context[:visitor_session]
    variables = context[:variables]
    
    result = evaluate_condition(condition_data, visitor_session, variables)
    
    # Find the appropriate next node based on condition result
    connection_type = result ? 'true' : 'false'
    next_node = find_next_node(node, connection_type)
    execute_node(next_node, context) if next_node
  end
  
  def execute_action_node(node, context)
    action_data = node['data']
    visitor_session = context[:visitor_session]
    
    case action_data['action_type']
    when 'set_variable'
      context[:variables][action_data['variable_name']] = action_data['variable_value']
    when 'tag_user'
      visitor_session.app_user.tag_list.add(action_data['tag'])
      visitor_session.app_user.save
    when 'send_email'
      # Queue email sending
      EmailSenderJob.perform_later(
        visitor_session.app_user,
        action_data['email_template']
      )
    when 'create_lead'
      visitor_session.app_user.update(lifecycle_stage: 'lead')
    end
    
    next_node = find_next_node(node)
    execute_node(next_node, context) if next_node
  end
  
  def execute_wait_node(node, context)
    wait_data = node['data']
    wait_seconds = wait_data['duration'] || 5
    
    # Schedule the next node execution
    FlowContinuationJob.perform_in(
      wait_seconds.seconds,
      id,
      find_next_node(node)&.dig('id'),
      context
    )
  end
  
  def execute_webhook_node(node, context)
    webhook_data = node['data']
    
    # Send webhook with context data
    WebhookSenderJob.perform_later(
      webhook_data['url'],
      webhook_data['payload'].merge(context.except(:visitor_session, :conversation))
    )
    
    next_node = find_next_node(node)
    execute_node(next_node, context) if next_node
  end
  
  def execute_end_node(node, context)
    # Flow completed successfully
    # Log completion, update stats, etc.
    Rails.logger.info "Flow #{name} completed for visitor #{context[:visitor_session].session_id}"
  end
  
  def find_next_node(current_node, connection_type = 'default')
    current_id = current_node['id']
    
    connection = connections.find do |conn|
      conn['source'] == current_id && 
      (conn['type'] == connection_type || connection_type == 'default')
    end
    
    return nil unless connection
    
    nodes.find { |node| node['id'] == connection['target'] }
  end
  
  def check_page_url_trigger(visitor_session, conditions)
    current_page = visitor_session.current_page
    return false unless current_page
    
    case conditions['operator']
    when 'contains'
      current_page.include?(conditions['value'])
    when 'equals'
      current_page == conditions['value']
    when 'starts_with'
      current_page.start_with?(conditions['value'])
    else
      true
    end
  end
  
  def check_time_trigger(visitor_session, conditions)
    min_time = conditions['min_seconds'] || 30
    visitor_session.duration_seconds >= min_time
  end
  
  def check_visitor_type_trigger(visitor_session, conditions)
    case conditions['type']
    when 'new'
      !visitor_session.is_returning
    when 'returning'
      visitor_session.is_returning
    else
      true
    end
  end
  
  def check_custom_event_trigger(visitor_session, conditions)
    # Custom events would be tracked separately
    # For now, return true
    true
  end
  
  def evaluate_condition(condition_data, visitor_session, variables)
    left_value = get_condition_value(condition_data['left'], visitor_session, variables)
    right_value = get_condition_value(condition_data['right'], visitor_session, variables)
    operator = condition_data['operator']
    
    case operator
    when 'equals'
      left_value == right_value
    when 'not_equals'
      left_value != right_value
    when 'greater_than'
      left_value.to_f > right_value.to_f
    when 'less_than'
      left_value.to_f < right_value.to_f
    when 'contains'
      left_value.to_s.include?(right_value.to_s)
    else
      false
    end
  end
  
  def get_condition_value(value_config, visitor_session, variables)
    case value_config['type']
    when 'literal'
      value_config['value']
    when 'variable'
      variables[value_config['name']]
    when 'visitor_property'
      visitor_session.app_user.send(value_config['property'])
    when 'session_property'
      visitor_session.send(value_config['property'])
    else
      value_config['value']
    end
  end
end