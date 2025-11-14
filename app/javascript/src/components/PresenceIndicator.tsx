import React from 'react';
import styled from '@emotion/styled';
import tw from 'twin.macro';

const PresenceDot = styled.span<{ status: 'online' | 'offline' | 'away' | 'busy' }>`
  ${tw`inline-block h-3 w-3 rounded-full border-2 border-white`}
  ${props => {
    switch (props.status) {
      case 'online':
        return tw`bg-green-500`;
      case 'away':
        return tw`bg-yellow-500`;
      case 'busy':
        return tw`bg-red-500`;
      default:
        return tw`bg-gray-400`;
    }
  }}
`;

interface PresenceIndicatorProps {
  status: 'online' | 'offline' | 'away' | 'busy';
  size?: 'sm' | 'md' | 'lg';
  showLabel?: boolean;
  className?: string;
}

const PresenceIndicator: React.FC<PresenceIndicatorProps> = ({
  status,
  size = 'md',
  showLabel = false,
  className = '',
}) => {
  const sizeClasses = {
    sm: 'h-2 w-2',
    md: 'h-3 w-3',
    lg: 'h-4 w-4',
  };

  const labelMap = {
    online: 'Online',
    offline: 'Offline',
    away: 'Away',
    busy: 'Busy',
  };

  return (
    <div className={`flex items-center space-x-1 ${className}`}>
      <PresenceDot
        status={status}
        className={sizeClasses[size]}
      />
      {showLabel && (
        <span className="text-xs text-gray-600">{labelMap[status]}</span>
      )}
    </div>
  );
};

export default PresenceIndicator;

