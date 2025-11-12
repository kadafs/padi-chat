# frozen_string_literal: true

class FlowExecutionJob < ApplicationJob
  queue_as :default

  def perform(flow_id, visitor_session_id, context = {})
    flow = FlowBuilder.find(flow_id)
    visitor_session = VisitorSession.find(visitor_session_id)

    # Skip if flow or session no longer exists
    return unless flow && visitor_session
    return unless flow.active?

    # Find or create conversation for the flow
    conversation = find_or_create_conversation(visitor_session)

    # Execute the flow
    execute_flow(flow, visitor_session, conversation, context)
  end

  private

  def find_or_create_conversation(visitor_session)
    app = visitor_session.app
    
    # Look for existing open conversation
    conversation = app.conversations
                     .where(main_participant: visitor_session.app_user)
                     .opened
                     .last

    if conversation
      conversation
    else
      app.start_conversation(
        from: visitor_session.app_user,
        participant: visitor_session.app_user,
        subject: 'Automated Flow',
        message_source: 'flow_builder'
      )
    end
  end

  def execute_flow(flow, visitor_session, conversation, context)
    current_node = flow.start_node
    flow_context = context.merge(
      visitor_session: visitor_session,
      conversation: conversation,
      variables: {}
    )

    while current_node
      execute_node(current_node, flow_context)
      current_node = find_next_node(flow, current_node, flow_context)
    end
  end

  def execute_node(node, context)
    case node['type']
    when 'message'
      execute_message_node(node, context)
    when 'question'
      execute_question_node(node, context)
    when 'condition'
      execute_condition_node(node, context)
    when 'action'
      execute_action_node(node, context)
    when 'webhook'
      execute_webhook_node(node, context)
    when 'wait'
      execute_wait_node(node, context)
    end
  rescue StandardError => e
    Rails.logger.error "Error executing flow node: #{e.message}"
    # Could add error tracking here (e.g., Bugsnag, Sentry)
  end

  def execute_message_node(node, context)
    conversation = context[:conversation]
    message_data = node['data']

    return unless conversation && message_data['content'].present?

    conversation.add_message(
      from: conversation.app.agent_bots.first,
      message: {
        html: message_data['content'],
        serialized_content: message_data['content'],
        blocks: build_message_blocks(message_data)
      },
      message_source: 'flow_builder'
    )

    # Add typing delay for natural feel
    sleep(calculate_typing_delay(message_data['content']))
  end

  def execute_question_node(node, context)
    conversation = context[:conversation]
    question_data = node['data']

    return unless conversation && question_data['question'].present?

    # Send question with quick replies
    message_content = {
      html: question_data['question'],
      serialized_content: question_data['question']
    }

    if question_data['options']&.any?
      message_content[:controls] = {
        type: 'data_retrieval',
        schema: question_data['options'].map { |option|
          {
            type: 'button',
            text: option['text'],
            value: option['value']
          }
        }
      }
    end

    conversation.add_message(
      from: conversation.app.agent_bots.first,
      message: message_content,
      message_source: 'flow_builder'
    )

    # Store that we're waiting for a response
    context[:variables]['awaiting_response'] = true
    context[:variables]['question_node_id'] = node['id']
  end

  def execute_condition_node(node, context)
    condition_data = node['data']
    visitor_session = context[:visitor_session]
    variables = context[:variables]

    # Evaluate condition and store result
    result = evaluate_condition(condition_data, visitor_session, variables)
    context[:variables]['last_condition_result'] = result
  end

  def execute_action_node(node, context)
    action_data = node['data']
    visitor_session = context[:visitor_session]
    variables = context[:variables]

    case action_data['action_type']
    when 'set_variable'
      variables[action_data['variable_name']] = action_data['variable_value']
    
    when 'tag_user'
      visitor_session.app_user.tag_list.add(action_data['tag'])
      visitor_session.app_user.save
    
    when 'send_email'
      EmailSenderJob.perform_later(
        visitor_session.app_user,
        action_data['email_template'],
        variables
      )
    
    when 'create_lead'
      visitor_session.app_user.update(lifecycle_stage: 'lead')
    
    when 'assign_conversation'
      if context[:conversation] && action_data['agent_id']
        agent = Agent.find_by(id: action_data['agent_id'])
        context[:conversation].assign_user(agent) if agent
      end
    
    when 'update_contact'
      visitor_session.app_user.update(
        action_data['contact_attributes']
      )
    end
  end

  def execute_webhook_node(node, context)
    webhook_data = node['data']
    return unless webhook_data['url'].present?

    # Prepare webhook payload
    payload = webhook_data['payload'].merge(
      visitor_session_id: context[:visitor_session].id,
      conversation_id: context[:conversation]&.id,
      variables: context[:variables]
    )

    # Send webhook asynchronously
    WebhookSenderJob.perform_later(
      webhook_data['url'],
      payload,
      webhook_data['headers'] || {}
    )
  end

  def execute_wait_node(node, context)
    wait_data = node['data']
    wait_seconds = wait_data['duration'] || 5

    # Schedule the next node execution
    FlowContinuationJob.set(wait: wait_seconds.seconds)
                      .perform_later(
                        node['next_node_id'],
                        context[:visitor_session].id,
                        context
                      )
  end

  def find_next_node(flow, current_node, context)
    current_id = current_node['id']
    
    # Handle conditional branching
    if current_node['type'] == 'condition'
      result = context[:variables]['last_condition_result']
      connection_type = result ? 'true' : 'false'
    else
      connection_type = 'default'
    end

    # Find next connection
    connection = flow.connections.find do |conn|
      conn['source'] == current_id && 
      (conn['type'] == connection_type || connection_type == 'default')
    end

    return nil unless connection

    # Find the target node
    flow.nodes.find { |node| node['id'] == connection['target'] }
  end

  def build_message_blocks(message_data)
    blocks = []
    
    if message_data['content'].present?
      blocks << {
        type: 'text',
        data: { text: message_data['content'] }
      }
    end

    message_data['attachments']&.each do |attachment|
      blocks << {
        type: attachment['type'] || 'image',
        data: {
          url: attachment['url'],
          caption: attachment['caption']
        }
      }
    end

    blocks
  end

  def calculate_typing_delay(content)
    # Simulate natural typing speed (avg 40 words per minute)
    words = content.split.size
    delay = (words / 40.0) * 60
    [delay, 2].min # Cap at 2 seconds
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