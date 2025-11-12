# frozen_string_literal: true

class FlowContinuationJob < ApplicationJob
  queue_as :default

  def perform(next_node_id, visitor_session_id, context)
    visitor_session = VisitorSession.find(visitor_session_id)
    return unless visitor_session

    # Find the flow that's executing
    flow = FlowBuilder.joins(:visitor_sessions)
                      .where(visitor_sessions: { id: visitor_session_id })
                      .where(active: true)
                      .first

    return unless flow

    # Find the next node
    next_node = flow.nodes.find { |node| node['id'] == next_node_id }
    return unless next_node

    # Find or create conversation
    conversation = find_or_create_conversation(visitor_session)

    # Execute the next node
    flow_context = context.merge(
      visitor_session: visitor_session,
      conversation: conversation,
      variables: context[:variables] || {}
    )

    flow.execute_node(next_node, flow_context)
  end

  private

  def find_or_create_conversation(visitor_session)
    app = visitor_session.app
    
    conversation = app.conversations
                     .where(main_participant: visitor_session.app_user)
                     .opened
                     .last

    conversation || app.start_conversation(
      from: visitor_session.app_user,
      participant: visitor_session.app_user,
      subject: 'Automated Flow',
      message_source: 'flow_builder'
    )
  end
end


