import React, { useState, useEffect, useRef } from 'react';
import { connect } from 'react-redux';
import styled from '@emotion/styled';
import tw from 'twin.macro';
import {
  BellIcon,
  XMarkIcon,
  CheckIcon,
  ExclamationTriangleIcon,
  InformationCircleIcon,
  CheckCircleIcon
} from '@heroicons/react/24/outline';
import actioncable from 'actioncable';
import { createNotification, clearNotification } from '@chaskiq/store/src/actions/notifications';

const NotificationCenterContainer = styled.div`
  ${tw`relative`}
`;

const BellButton = styled.button`
  ${tw`relative p-2 text-gray-400 hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500 rounded-lg`}
`;

const Badge = styled.span`
  ${tw`absolute top-0 right-0 inline-flex items-center justify-center px-2 py-1 text-xs font-bold leading-none text-white transform translate-x-1/2 -translate-y-1/2 bg-red-600 rounded-full`}
`;

const Dropdown = styled.div<{ open: boolean }>`
  ${tw`absolute right-0 mt-2 w-80 bg-white rounded-lg shadow-lg ring-1 ring-black ring-opacity-5 z-50`}
  ${props => props.open ? tw`block` : tw`hidden`}
  max-height: 500px;
  overflow-y: auto;
`;

const NotificationItem = styled.div<{ unread?: boolean }>`
  ${tw`p-4 border-b border-gray-200 hover:bg-gray-50 cursor-pointer transition-colors`}
  ${props => props.unread && tw`bg-blue-50`}
`;

const NotificationHeader = styled.div`
  ${tw`flex items-center justify-between p-4 border-b border-gray-200`}
`;

interface Notification {
  id: string;
  type: 'info' | 'success' | 'warning' | 'error';
  title: string;
  message: string;
  timestamp: Date;
  read: boolean;
  action?: {
    type: string;
    path?: string;
    label?: string;
  };
}

interface NotificationCenterProps {
  app: any;
  accessToken: string;
  dispatch: any;
  notifications: any;
}

const NotificationCenter: React.FC<NotificationCenterProps> = ({
  app,
  accessToken,
  dispatch,
  notifications
}) => {
  const [isOpen, setIsOpen] = useState(false);
  const [notificationList, setNotificationList] = useState<Notification[]>([]);
  const [unreadCount, setUnreadCount] = useState(0);
  const cableRef = useRef<any>(null);
  const subscriptionRef = useRef<any>(null);

  // Initialize ActionCable subscription
  useEffect(() => {
    if (!app?.key || !accessToken) return;

    const chaskiq_cable_url = document.querySelector('meta[name="chaskiq-ws"]')?.getAttribute('content');
    if (!chaskiq_cable_url) return;

    const cable = actioncable.createConsumer(
      `${chaskiq_cable_url}?app=${app.key}&token=${accessToken}`
    );

    cableRef.current = cable;

    subscriptionRef.current = cable.subscriptions.create(
      {
        channel: 'EventsChannel',
        app: app.key,
      },
      {
        connected: () => {
          console.log('NotificationCenter: Connected to ActionCable');
        },
        disconnected: () => {
          console.log('NotificationCenter: Disconnected from ActionCable');
        },
        received: (data) => {
          if (data.type === 'notification') {
            handleNewNotification(data.data);
          }
        },
      }
    );

    return () => {
      if (subscriptionRef.current) {
        subscriptionRef.current.unsubscribe();
      }
      if (cableRef.current) {
        cableRef.current.disconnect();
      }
    };
  }, [app?.key, accessToken]);

  // Handle new notification from ActionCable
  const handleNewNotification = (data: any) => {
    const notification: Notification = {
      id: data.id || `notification-${Date.now()}-${Math.random()}`,
      type: data.type || 'info',
      title: data.subject || data.title || 'Notification',
      message: data.message || '',
      timestamp: new Date(),
      read: false,
      action: data.action || data.actions?.[0],
    };

    setNotificationList((prev) => [notification, ...prev]);
    setUnreadCount((prev) => prev + 1);

    // Show browser notification if permission granted
    if ('Notification' in window && Notification.permission === 'granted') {
      new Notification(notification.title, {
        body: notification.message,
        icon: '/favicon.ico',
      });
    }

    // Dispatch to existing notification system
    dispatch(createNotification({
      subject: notification.title,
      message: notification.message,
      timeout: 5000,
      actions: data.actions || [],
    }));
  };

  // Request browser notification permission
  useEffect(() => {
    if ('Notification' in window && Notification.permission === 'default') {
      Notification.requestPermission();
    }
  }, []);

  // Mark notification as read
  const markAsRead = (id: string) => {
    setNotificationList((prev) =>
      prev.map((n) => (n.id === id ? { ...n, read: true } : n))
    );
    setUnreadCount((prev) => Math.max(0, prev - 1));
  };

  // Mark all as read
  const markAllAsRead = () => {
    setNotificationList((prev) => prev.map((n) => ({ ...n, read: true })));
    setUnreadCount(0);
  };

  // Delete notification
  const deleteNotification = (id: string) => {
    setNotificationList((prev) => {
      const notification = prev.find((n) => n.id === id);
      if (notification && !notification.read) {
        setUnreadCount((prevCount) => Math.max(0, prevCount - 1));
      }
      return prev.filter((n) => n.id !== id);
    });
  };

  // Get icon for notification type
  const getIcon = (type: string) => {
    switch (type) {
      case 'success':
        return <CheckCircleIcon className="h-5 w-5 text-green-500" />;
      case 'warning':
        return <ExclamationTriangleIcon className="h-5 w-5 text-yellow-500" />;
      case 'error':
        return <ExclamationTriangleIcon className="h-5 w-5 text-red-500" />;
      default:
        return <InformationCircleIcon className="h-5 w-5 text-blue-500" />;
    }
  };

  // Format timestamp
  const formatTimestamp = (date: Date) => {
    const now = new Date();
    const diff = now.getTime() - date.getTime();
    const minutes = Math.floor(diff / 60000);
    const hours = Math.floor(minutes / 60);
    const days = Math.floor(hours / 24);

    if (minutes < 1) return 'Just now';
    if (minutes < 60) return `${minutes}m ago`;
    if (hours < 24) return `${hours}h ago`;
    if (days < 7) return `${days}d ago`;
    return date.toLocaleDateString();
  };

  return (
    <NotificationCenterContainer>
      <BellButton onClick={() => setIsOpen(!isOpen)}>
        <BellIcon className="h-6 w-6" />
        {unreadCount > 0 && <Badge>{unreadCount > 99 ? '99+' : unreadCount}</Badge>}
      </BellButton>

      <Dropdown open={isOpen}>
        <NotificationHeader>
          <h3 className="text-lg font-semibold text-gray-900">Notifications</h3>
          <div className="flex items-center space-x-2">
            {unreadCount > 0 && (
              <button
                onClick={markAllAsRead}
                className="text-sm text-blue-600 hover:text-blue-800"
              >
                Mark all read
              </button>
            )}
            <button
              onClick={() => setIsOpen(false)}
              className="text-gray-400 hover:text-gray-500"
            >
              <XMarkIcon className="h-5 w-5" />
            </button>
          </div>
        </NotificationHeader>

        <div>
          {notificationList.length === 0 ? (
            <div className="p-8 text-center text-gray-500">
              <BellIcon className="h-12 w-12 mx-auto mb-2 text-gray-300" />
              <p>No notifications</p>
            </div>
          ) : (
            notificationList.map((notification) => (
              <NotificationItem
                key={notification.id}
                unread={!notification.read}
                onClick={() => markAsRead(notification.id)}
              >
                <div className="flex items-start space-x-3">
                  <div className="flex-shrink-0 mt-0.5">
                    {getIcon(notification.type)}
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium text-gray-900">
                      {notification.title}
                    </p>
                    <p className="text-sm text-gray-500 mt-1">
                      {notification.message}
                    </p>
                    <div className="flex items-center justify-between mt-2">
                      <span className="text-xs text-gray-400">
                        {formatTimestamp(notification.timestamp)}
                      </span>
                      <div className="flex items-center space-x-2">
                        {!notification.read && (
                          <span className="h-2 w-2 bg-blue-600 rounded-full"></span>
                        )}
                        <button
                          onClick={(e) => {
                            e.stopPropagation();
                            deleteNotification(notification.id);
                          }}
                          className="text-gray-400 hover:text-red-500"
                        >
                          <XMarkIcon className="h-4 w-4" />
                        </button>
                      </div>
                    </div>
                  </div>
                </div>
              </NotificationItem>
            ))
          )}
        </div>
      </Dropdown>
    </NotificationCenterContainer>
  );
};

const mapStateToProps = (state: any) => ({
  app: state.app,
  accessToken: state.auth?.accessToken,
  notifications: state.notifications,
});

export default connect(mapStateToProps)(NotificationCenter);

