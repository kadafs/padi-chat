import React, { useState, useEffect, useRef } from 'react';
import { connect } from 'react-redux';
import {
  ChatBubbleLeftRightIcon,
  UserIcon,
  ClockIcon,
  StarIcon,
  TagIcon,
  EllipsisHorizontalIcon,
  FunnelIcon,
  MagnifyingGlassIcon,
  PhoneIcon,
  VideoCameraIcon,
  PaperClipIcon,
  FaceSmileIcon,
  PaperAirplaneIcon,
  CheckCircleIcon,
  ExclamationTriangleIcon
} from '@heroicons/react/24/outline';
import { StarIcon as StarIconSolid } from '@heroicons/react/24/solid';
import styled from '@emotion/styled';
import tw from 'twin.macro';

// Tidio-inspired styled components
const InboxContainer = styled.div`
  ${tw`flex h-full bg-gray-50`}
`;

const Sidebar = styled.div`
  ${tw`w-80 bg-white border-r border-gray-200 flex flex-col`}
`;

const ConversationArea = styled.div`
  ${tw`flex-1 flex flex-col bg-white`}
`;

const SidebarHeader = styled.div`
  ${tw`p-4 border-b border-gray-200 bg-white`}
`;

const SearchBar = styled.div`
  ${tw`relative mb-4`}
  
  input {
    ${tw`w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent`}
  }
  
  .search-icon {
    ${tw`absolute left-3 top-2.5 h-5 w-5 text-gray-400`}
  }
`;

const FilterTabs = styled.div`
  ${tw`flex space-x-1 bg-gray-100 p-1 rounded-lg`}
`;

const FilterTab = styled.button<{ active?: boolean }>`
  ${tw`flex-1 py-2 px-3 text-sm font-medium rounded-md transition-colors`}
  ${props => props.active 
    ? tw`bg-white text-gray-900 shadow-sm` 
    : tw`text-gray-600 hover:text-gray-900`
  }
`;

const ConversationList = styled.div`
  ${tw`flex-1 overflow-y-auto`}
`;

const ConversationItem = styled.div<{ active?: boolean; unread?: boolean }>`
  ${tw`p-4 border-b border-gray-100 cursor-pointer hover:bg-gray-50 transition-colors relative`}
  ${props => props.active && tw`bg-blue-50 border-blue-200`}
  
  ${props => props.unread && `
    &::before {
      content: '';
      position: absolute;
      left: 0;
      top: 0;
      bottom: 0;
      width: 3px;
      background: #3b82f6;
    }
  `}
`;

const ConversationHeader = styled.div`
  ${tw`p-4 border-b border-gray-200 bg-white flex items-center justify-between`}
`;

const ConversationContent = styled.div`
  ${tw`flex-1 overflow-y-auto p-4 space-y-4`}
`;

const MessageInput = styled.div`
  ${tw`p-4 border-t border-gray-200 bg-white`}
`;

const MessageInputBox = styled.div`
  ${tw`border border-gray-300 rounded-lg p-3 min-h-[100px] focus-within:ring-2 focus-within:ring-blue-500 focus-within:border-transparent`}
`;

const MessageActions = styled.div`
  ${tw`flex items-center justify-between mt-3`}
`;

const ActionButton = styled.button`
  ${tw`p-2 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-lg transition-colors`}
`;

const SendButton = styled.button`
  ${tw`bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors flex items-center space-x-2`}
`;

const Message = styled.div<{ isAgent?: boolean }>`
  ${tw`flex space-x-3`}
  ${props => props.isAgent && tw`flex-row-reverse space-x-reverse`}
`;

const MessageBubble = styled.div<{ isAgent?: boolean }>`
  ${tw`max-w-xs lg:max-w-md px-4 py-2 rounded-lg`}
  ${props => props.isAgent 
    ? tw`bg-blue-600 text-white` 
    : tw`bg-gray-100 text-gray-900`
  }
`;

const Avatar = styled.div`
  ${tw`w-8 h-8 bg-gray-300 rounded-full flex items-center justify-center flex-shrink-0`}
`;

const UserInfo = styled.div`
  ${tw`bg-white p-4 border-l border-gray-200 w-80`}
`;

interface TidioInboxProps {
  app: any;
  conversations: any[];
  currentUser: any;
}

const TidioInbox: React.FC<TidioInboxProps> = ({ app, conversations, currentUser }) => {
  const [activeConversation, setActiveConversation] = useState<any>(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [activeFilter, setActiveFilter] = useState('all');
  const [messageText, setMessageText] = useState('');
  const [showUserInfo, setShowUserInfo] = useState(false);
  const [visitorSessions, setVisitorSessions] = useState([]);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  // Mock data for demonstration
  const [mockConversations] = useState([
    {
      id: 1,
      customer: {
        name: 'Sarah Johnson',
        email: 'sarah@example.com',
        avatar: null,
        isOnline: true,
        location: 'New York, US',
        device: 'desktop',
        timeOnSite: '5m 32s',
        pageViews: 3,
        visitCount: 1
      },
      lastMessage: {
        text: 'Hi, I need help with my order status',
        timestamp: new Date(Date.now() - 300000), // 5 minutes ago
        isFromCustomer: true
      },
      status: 'open',
      priority: 'normal',
      unreadCount: 1,
      tags: ['support', 'order-inquiry'],
      assignedAgent: currentUser,
      rating: null
    },
    {
      id: 2,
      customer: {
        name: 'Mike Chen',
        email: 'mike@example.com',
        avatar: null,
        isOnline: false,
        location: 'San Francisco, US',
        device: 'mobile',
        timeOnSite: '2m 15s',
        pageViews: 5,
        visitCount: 3
      },
      lastMessage: {
        text: 'Thanks for the help! That solved my issue.',
        timestamp: new Date(Date.now() - 3600000), // 1 hour ago
        isFromCustomer: true
      },
      status: 'resolved',
      priority: 'normal',
      unreadCount: 0,
      tags: ['support', 'resolved'],
      assignedAgent: currentUser,
      rating: 5
    }
  ]);

  const [mockMessages] = useState({
    1: [
      {
        id: 1,
        text: 'Hello! Welcome to our store. How can I help you today?',
        timestamp: new Date(Date.now() - 600000),
        isFromAgent: true,
        agent: currentUser
      },
      {
        id: 2,
        text: 'Hi, I need help with my order status',
        timestamp: new Date(Date.now() - 300000),
        isFromAgent: false
      },
      {
        id: 3,
        text: 'Of course! I\'d be happy to help you check your order status. Could you please provide me with your order number?',
        timestamp: new Date(Date.now() - 240000),
        isFromAgent: true,
        agent: currentUser
      }
    ]
  });

  useEffect(() => {
    scrollToBottom();
  }, [activeConversation]);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  const handleSendMessage = () => {
    if (!messageText.trim() || !activeConversation) return;
    
    // TODO: Implement actual message sending
    console.log('Sending message:', messageText);
    setMessageText('');
  };

  const formatRelativeTime = (date: Date) => {
    const now = new Date();
    const diff = now.getTime() - date.getTime();
    const minutes = Math.floor(diff / 60000);
    
    if (minutes < 1) return 'now';
    if (minutes < 60) return `${minutes}m ago`;
    if (minutes < 1440) return `${Math.floor(minutes / 60)}h ago`;
    return `${Math.floor(minutes / 1440)}d ago`;
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'open': return 'text-green-600';
      case 'pending': return 'text-yellow-600';
      case 'resolved': return 'text-gray-600';
      default: return 'text-gray-600';
    }
  };

  const getPriorityIcon = (priority: string) => {
    switch (priority) {
      case 'high':
        return <ExclamationTriangleIcon className="h-4 w-4 text-red-500" />;
      case 'medium':
        return <ClockIcon className="h-4 w-4 text-yellow-500" />;
      default:
        return null;
    }
  };

  const filteredConversations = mockConversations.filter(conv => {
    const matchesSearch = searchQuery === '' || 
      conv.customer.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      conv.customer.email.toLowerCase().includes(searchQuery.toLowerCase()) ||
      conv.lastMessage.text.toLowerCase().includes(searchQuery.toLowerCase());
    
    const matchesFilter = activeFilter === 'all' ||
      (activeFilter === 'unread' && conv.unreadCount > 0) ||
      (activeFilter === 'open' && conv.status === 'open') ||
      (activeFilter === 'resolved' && conv.status === 'resolved');
    
    return matchesSearch && matchesFilter;
  });

  return (
    <InboxContainer>
      {/* Sidebar with conversation list */}
      <Sidebar>
        <SidebarHeader>
          <h1 className="text-xl font-semibold text-gray-900 mb-4">Inbox</h1>
          
          <SearchBar>
            <MagnifyingGlassIcon className="search-icon" />
            <input
              type="text"
              placeholder="Search conversations..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
            />
          </SearchBar>
          
          <FilterTabs>
            <FilterTab 
              active={activeFilter === 'all'} 
              onClick={() => setActiveFilter('all')}
            >
              All
            </FilterTab>
            <FilterTab 
              active={activeFilter === 'unread'} 
              onClick={() => setActiveFilter('unread')}
            >
              Unread
            </FilterTab>
            <FilterTab 
              active={activeFilter === 'open'} 
              onClick={() => setActiveFilter('open')}
            >
              Open
            </FilterTab>
            <FilterTab 
              active={activeFilter === 'resolved'} 
              onClick={() => setActiveFilter('resolved')}
            >
              Resolved
            </FilterTab>
          </FilterTabs>
        </SidebarHeader>
        
        <ConversationList>
          {filteredConversations.map(conversation => (
            <ConversationItem
              key={conversation.id}
              active={activeConversation?.id === conversation.id}
              unread={conversation.unreadCount > 0}
              onClick={() => setActiveConversation(conversation)}
            >
              <div className="flex items-start space-x-3">
                <div className="relative">
                  <Avatar>
                    <UserIcon className="h-5 w-5 text-gray-500" />
                  </Avatar>
                  {conversation.customer.isOnline && (
                    <div className="absolute -bottom-1 -right-1 w-3 h-3 bg-green-500 border-2 border-white rounded-full" />
                  )}
                </div>
                
                <div className="flex-1 min-w-0">
                  <div className="flex items-center justify-between">
                    <p className="text-sm font-medium text-gray-900 truncate">
                      {conversation.customer.name}
                    </p>
                    <div className="flex items-center space-x-1">
                      {getPriorityIcon(conversation.priority)}
                      <span className="text-xs text-gray-500">
                        {formatRelativeTime(conversation.lastMessage.timestamp)}
                      </span>
                    </div>
                  </div>
                  
                  <p className="text-sm text-gray-600 truncate">
                    {conversation.lastMessage.text}
                  </p>
                  
                  <div className="flex items-center justify-between mt-1">
                    <div className="flex items-center space-x-2">
                      <span className={`text-xs font-medium ${getStatusColor(conversation.status)}`}>
                        {conversation.status}
                      </span>
                      {conversation.tags.map(tag => (
                        <span
                          key={tag}
                          className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-gray-100 text-gray-800"
                        >
                          {tag}
                        </span>
                      ))}
                    </div>
                    
                    {conversation.unreadCount > 0 && (
                      <span className="inline-flex items-center justify-center px-2 py-1 text-xs font-bold leading-none text-white bg-blue-600 rounded-full">
                        {conversation.unreadCount}
                      </span>
                    )}
                  </div>
                </div>
              </div>
            </ConversationItem>
          ))}
        </ConversationList>
      </Sidebar>

      {/* Main conversation area */}
      <ConversationArea>
        {activeConversation ? (
          <>
            <ConversationHeader>
              <div className="flex items-center space-x-3">
                <div className="relative">
                  <Avatar>
                    <UserIcon className="h-5 w-5 text-gray-500" />
                  </Avatar>
                  {activeConversation.customer.isOnline && (
                    <div className="absolute -bottom-1 -right-1 w-3 h-3 bg-green-500 border-2 border-white rounded-full" />
                  )}
                </div>
                
                <div>
                  <h2 className="text-lg font-semibold text-gray-900">
                    {activeConversation.customer.name}
                  </h2>
                  <div className="flex items-center space-x-4 text-sm text-gray-500">
                    <span>{activeConversation.customer.location}</span>
                    <span>•</span>
                    <span>{activeConversation.customer.device}</span>
                    <span>•</span>
                    <span>On site: {activeConversation.customer.timeOnSite}</span>
                  </div>
                </div>
              </div>
              
              <div className="flex items-center space-x-2">
                <ActionButton>
                  <PhoneIcon className="h-5 w-5" />
                </ActionButton>
                <ActionButton>
                  <VideoCameraIcon className="h-5 w-5" />
                </ActionButton>
                <ActionButton onClick={() => setShowUserInfo(!showUserInfo)}>
                  <UserIcon className="h-5 w-5" />
                </ActionButton>
                <ActionButton>
                  <EllipsisHorizontalIcon className="h-5 w-5" />
                </ActionButton>
              </div>
            </ConversationHeader>
            
            <ConversationContent>
              {mockMessages[activeConversation.id]?.map(message => (
                <Message key={message.id} isAgent={message.isFromAgent}>
                  <Avatar>
                    {message.isFromAgent ? (
                      <span className="text-xs font-medium text-white bg-blue-600 w-full h-full flex items-center justify-center rounded-full">
                        {currentUser.name?.[0] || 'A'}
                      </span>
                    ) : (
                      <UserIcon className="h-5 w-5 text-gray-500" />
                    )}
                  </Avatar>
                  
                  <div>
                    <MessageBubble isAgent={message.isFromAgent}>
                      <p className="text-sm">{message.text}</p>
                    </MessageBubble>
                    <p className="text-xs text-gray-500 mt-1">
                      {formatRelativeTime(message.timestamp)}
                    </p>
                  </div>
                </Message>
              ))}
              <div ref={messagesEndRef} />
            </ConversationContent>
            
            <MessageInput>
              <MessageInputBox>
                <textarea
                  className="w-full resize-none outline-none"
                  placeholder="Type your message..."
                  value={messageText}
                  onChange={(e) => setMessageText(e.target.value)}
                  onKeyPress={(e) => {
                    if (e.key === 'Enter' && !e.shiftKey) {
                      e.preventDefault();
                      handleSendMessage();
                    }
                  }}
                  rows={3}
                />
              </MessageInputBox>
              
              <MessageActions>
                <div className="flex items-center space-x-2">
                  <ActionButton>
                    <PaperClipIcon className="h-5 w-5" />
                  </ActionButton>
                  <ActionButton>
                    <FaceSmileIcon className="h-5 w-5" />
                  </ActionButton>
                </div>
                
                <SendButton onClick={handleSendMessage}>
                  <PaperAirplaneIcon className="h-5 w-5" />
                  <span>Send</span>
                </SendButton>
              </MessageActions>
            </MessageInput>
          </>
        ) : (
          <div className="flex-1 flex items-center justify-center">
            <div className="text-center">
              <ChatBubbleLeftRightIcon className="mx-auto h-12 w-12 text-gray-400" />
              <h3 className="mt-2 text-lg font-medium text-gray-900">No conversation selected</h3>
              <p className="mt-1 text-gray-500">Choose a conversation from the sidebar to start messaging.</p>
            </div>
          </div>
        )}
      </ConversationArea>

      {/* User info sidebar */}
      {showUserInfo && activeConversation && (
        <UserInfo>
          <div className="space-y-6">
            <div>
              <h3 className="text-lg font-medium text-gray-900 mb-4">Contact Details</h3>
              
              <div className="space-y-3">
                <div>
                  <label className="text-sm font-medium text-gray-700">Name</label>
                  <p className="text-sm text-gray-900">{activeConversation.customer.name}</p>
                </div>
                
                <div>
                  <label className="text-sm font-medium text-gray-700">Email</label>
                  <p className="text-sm text-gray-900">{activeConversation.customer.email}</p>
                </div>
                
                <div>
                  <label className="text-sm font-medium text-gray-700">Location</label>
                  <p className="text-sm text-gray-900">{activeConversation.customer.location}</p>
                </div>
                
                <div>
                  <label className="text-sm font-medium text-gray-700">Device</label>
                  <p className="text-sm text-gray-900">{activeConversation.customer.device}</p>
                </div>
              </div>
            </div>
            
            <div>
              <h4 className="text-sm font-medium text-gray-700 mb-2">Visit Information</h4>
              <div className="space-y-2 text-sm">
                <div className="flex justify-between">
                  <span className="text-gray-600">Time on site:</span>
                  <span className="text-gray-900">{activeConversation.customer.timeOnSite}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-600">Page views:</span>
                  <span className="text-gray-900">{activeConversation.customer.pageViews}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-600">Visit count:</span>
                  <span className="text-gray-900">{activeConversation.customer.visitCount}</span>
                </div>
              </div>
            </div>
            
            <div>
              <h4 className="text-sm font-medium text-gray-700 mb-2">Tags</h4>
              <div className="flex flex-wrap gap-2">
                {activeConversation.tags.map(tag => (
                  <span
                    key={tag}
                    className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800"
                  >
                    {tag}
                  </span>
                ))}
              </div>
            </div>
            
            {activeConversation.rating && (
              <div>
                <h4 className="text-sm font-medium text-gray-700 mb-2">Rating</h4>
                <div className="flex items-center space-x-1">
                  {[1, 2, 3, 4, 5].map(star => (
                    <StarIconSolid
                      key={star}
                      className={`h-5 w-5 ${
                        star <= activeConversation.rating 
                          ? 'text-yellow-400' 
                          : 'text-gray-300'
                      }`}
                    />
                  ))}
                </div>
              </div>
            )}
          </div>
        </UserInfo>
      )}
    </InboxContainer>
  );
};

const mapStateToProps = (state: any) => ({
  app: state.app,
  conversations: state.conversations,
  currentUser: state.currentUser
});

export default connect(mapStateToProps)(TidioInbox);