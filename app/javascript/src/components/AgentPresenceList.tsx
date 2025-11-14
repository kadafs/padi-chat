import React, { useState, useEffect, useRef } from 'react';
import { connect } from 'react-redux';
import styled from '@emotion/styled';
import tw from 'twin.macro';
import actioncable from 'actioncable';
import { updateAppUserPresence } from '@chaskiq/store/src/actions/app_users';
import PresenceIndicator from './PresenceIndicator';
import { UserIcon } from '@heroicons/react/24/outline';

const PresenceListContainer = styled.div`
  ${tw`bg-white rounded-lg shadow-sm border border-gray-200 p-4`}
`;

const AgentItem = styled.div`
  ${tw`flex items-center justify-between p-3 hover:bg-gray-50 rounded-lg transition-colors`}
`;

interface Agent {
  id: string;
  name: string;
  email: string;
  avatar?: string;
  status: 'online' | 'offline' | 'away' | 'busy';
  lastSeen?: Date;
}

interface AgentPresenceListProps {
  app: any;
  accessToken: string;
  dispatch: any;
  agents?: any[];
}

const AgentPresenceList: React.FC<AgentPresenceListProps> = ({
  app,
  accessToken,
  dispatch,
  agents = [],
}) => {
  const [agentList, setAgentList] = useState<Agent[]>([]);
  const cableRef = useRef<any>(null);
  const subscriptionRef = useRef<any>(null);

  // Initialize with agents from props
  useEffect(() => {
    if (agents && agents.length > 0) {
      const initialAgents: Agent[] = agents.map((agent: any) => ({
        id: agent.id?.toString() || agent.email,
        name: agent.name || agent.displayName || agent.email,
        email: agent.email,
        avatar: agent.avatarUrl,
        status: agent.online ? 'online' : 'offline',
        lastSeen: agent.lastSeen ? new Date(agent.lastSeen) : undefined,
      }));
      setAgentList(initialAgents);
    }
  }, [agents]);

  // Initialize ActionCable subscription for presence updates
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
          console.log('AgentPresenceList: Connected to ActionCable');
        },
        disconnected: () => {
          console.log('AgentPresenceList: Disconnected from ActionCable');
        },
        received: (data) => {
          if (data.type === 'presence') {
            handlePresenceUpdate(data.data);
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

  // Handle presence updates from ActionCable
  const handlePresenceUpdate = (data: any) => {
    const agentId = data.id?.toString() || data.email;
    const status = data.state === 'online' ? 'online' : 'offline';

    setAgentList((prev) => {
      const existingIndex = prev.findIndex((a) => a.id === agentId);
      
      if (existingIndex >= 0) {
        // Update existing agent
        const updated = [...prev];
        updated[existingIndex] = {
          ...updated[existingIndex],
          status,
          lastSeen: data.lastSeen ? new Date(data.lastSeen) : updated[existingIndex].lastSeen,
        };
        return updated;
      } else {
        // Add new agent
        return [
          ...prev,
          {
            id: agentId,
            name: data.name || data.displayName || data.email,
            email: data.email,
            avatar: data.avatarUrl,
            status,
            lastSeen: data.lastSeen ? new Date(data.lastSeen) : new Date(),
          },
        ];
      }
    });

    // Dispatch to Redux store
    dispatch(updateAppUserPresence(data));
  };

  // Format last seen time
  const formatLastSeen = (date?: Date) => {
    if (!date) return '';
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

  const onlineAgents = agentList.filter((a) => a.status === 'online');
  const offlineAgents = agentList.filter((a) => a.status === 'offline');

  return (
    <PresenceListContainer>
      <div className="mb-4">
        <h3 className="text-lg font-semibold text-gray-900 mb-2">Team Presence</h3>
        <div className="flex items-center space-x-4 text-sm text-gray-600">
          <span>{onlineAgents.length} online</span>
          <span>{offlineAgents.length} offline</span>
        </div>
      </div>

      <div className="space-y-2">
        {agentList.length === 0 ? (
          <div className="text-center text-gray-500 py-8">
            <UserIcon className="h-12 w-12 mx-auto mb-2 text-gray-300" />
            <p>No agents found</p>
          </div>
        ) : (
          <>
            {/* Online agents first */}
            {onlineAgents.map((agent) => (
              <AgentItem key={agent.id}>
                <div className="flex items-center space-x-3 flex-1">
                  <div className="relative">
                    {agent.avatar ? (
                      <img
                        src={agent.avatar}
                        alt={agent.name}
                        className="h-10 w-10 rounded-full"
                      />
                    ) : (
                      <div className="h-10 w-10 rounded-full bg-gray-200 flex items-center justify-center">
                        <UserIcon className="h-6 w-6 text-gray-400" />
                      </div>
                    )}
                    <div className="absolute bottom-0 right-0">
                      <PresenceIndicator status={agent.status} size="sm" />
                    </div>
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium text-gray-900 truncate">
                      {agent.name}
                    </p>
                    <p className="text-xs text-gray-500 truncate">{agent.email}</p>
                  </div>
                </div>
              </AgentItem>
            ))}

            {/* Offline agents */}
            {offlineAgents.map((agent) => (
              <AgentItem key={agent.id}>
                <div className="flex items-center space-x-3 flex-1">
                  <div className="relative">
                    {agent.avatar ? (
                      <img
                        src={agent.avatar}
                        alt={agent.name}
                        className="h-10 w-10 rounded-full opacity-60"
                      />
                    ) : (
                      <div className="h-10 w-10 rounded-full bg-gray-200 flex items-center justify-center opacity-60">
                        <UserIcon className="h-6 w-6 text-gray-400" />
                      </div>
                    )}
                    <div className="absolute bottom-0 right-0">
                      <PresenceIndicator status={agent.status} size="sm" />
                    </div>
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium text-gray-500 truncate">
                      {agent.name}
                    </p>
                    <p className="text-xs text-gray-400 truncate">
                      {agent.lastSeen ? formatLastSeen(agent.lastSeen) : 'Offline'}
                    </p>
                  </div>
                </div>
              </AgentItem>
            ))}
          </>
        )}
      </div>
    </PresenceListContainer>
  );
};

const mapStateToProps = (state: any) => ({
  app: state.app,
  accessToken: state.auth?.accessToken,
  agents: state.agents?.collection || [],
});

export default connect(mapStateToProps)(AgentPresenceList);

