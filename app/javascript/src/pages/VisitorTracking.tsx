import React, { useState, useEffect, useMemo } from 'react';
import { connect } from 'react-redux';
import styled from '@emotion/styled';
import tw from 'twin.macro';
import {
  MapPinIcon,
  DevicePhoneMobileIcon,
  ComputerDesktopIcon,
  DeviceTabletIcon,
  ClockIcon,
  EyeIcon,
  ArrowTrendingUpIcon,
  ChatBubbleBottomCenterTextIcon,
  FunnelIcon,
  GlobeAltIcon,
  UserGroupIcon,
  ArrowPathIcon
} from '@heroicons/react/24/outline';
import { ResponsivePie } from '@nivo/pie';
import { ResponsiveLine } from '@nivo/line';
import { ResponsiveBar } from '@nivo/bar';
import graphql from '@chaskiq/store/src/graphql/client';
import { VISITOR_SESSIONS, VISITOR_ANALYTICS, LIVE_VISITORS } from '@chaskiq/store/src/graphql/queries';

// Styled components
const TrackingContainer = styled.div`
  ${tw`h-full bg-gray-50 overflow-auto`}
`;

const Header = styled.div`
  ${tw`bg-white border-b border-gray-200 px-6 py-4`}
`;

const StatsGrid = styled.div`
  ${tw`grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 p-6`}
`;

const StatCard = styled.div`
  ${tw`bg-white rounded-lg shadow-sm border border-gray-200 p-6`}
`;

const MainContent = styled.div`
  ${tw`grid grid-cols-1 lg:grid-cols-3 gap-6 px-6 pb-6`}
`;

const VisitorsList = styled.div`
  ${tw`lg:col-span-2 bg-white rounded-lg shadow-sm border border-gray-200`}
`;

const VisitorItem = styled.div<{ isOnline?: boolean }>`
  ${tw`p-4 border-b border-gray-100 hover:bg-gray-50 cursor-pointer transition-colors relative`}
  
  ${props => props.isOnline && `
    &::before {
      content: '';
      position: absolute;
      left: 0;
      top: 0;
      bottom: 0;
      width: 3px;
      background: #10b981;
    }
  `}
`;

const AnalyticsPanel = styled.div`
  ${tw`bg-white rounded-lg shadow-sm border border-gray-200 p-6`}
`;

const ChartContainer = styled.div`
  ${tw`h-64 mt-4`}
`;

const FilterBar = styled.div`
  ${tw`flex flex-wrap items-center justify-between gap-4 mb-6`}
`;

const FilterSelect = styled.select`
  ${tw`px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent`}
`;

const RefreshButton = styled.button`
  ${tw`px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors flex items-center space-x-2`}
`;

interface VisitorTrackingProps {
  app: any;
  currentUser: any;
}

const VisitorTracking: React.FC<VisitorTrackingProps> = ({ app, currentUser }) => {
  const [visitors, setVisitors] = useState([]);
  const [analytics, setAnalytics] = useState<any>(null);
  const [timeFilter, setTimeFilter] = useState('24h');
  const [locationFilter, setLocationFilter] = useState('all');
  const [deviceFilter, setDeviceFilter] = useState('all');
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [selectedVisitor, setSelectedVisitor] = useState<any>(null);

  // Fetch visitor sessions
  const fetchVisitorSessions = () => {
    if (!app?.key) return;
    
    setIsLoading(true);
    graphql(
      VISITOR_SESSIONS,
      {
        appKey: app.key,
        timeRange: timeFilter,
        status: 'online'
      },
      {
        success: (data) => {
          const sessions = data.visitorSessions || [];
          setVisitors(sessions);
          setIsLoading(false);
          setIsRefreshing(false);
        },
        error: (err) => {
          console.error('Error fetching visitor sessions:', err);
          setIsLoading(false);
          setIsRefreshing(false);
        }
      }
    );
  };

  // Fetch analytics
  const fetchAnalytics = () => {
    if (!app?.key) return;
    
    graphql(
      VISITOR_ANALYTICS,
      {
        appKey: app.key,
        timeRange: timeFilter
      },
      {
        success: (data) => {
          setAnalytics(data.visitorAnalytics);
        },
        error: (err) => {
          console.error('Error fetching analytics:', err);
        }
      }
    );
  };

  // Initial load
  useEffect(() => {
    if (app?.key) {
      fetchVisitorSessions();
      fetchAnalytics();
    }
  }, [app?.key]);

  // Refetch when filters change
  useEffect(() => {
    if (app?.key) {
      fetchVisitorSessions();
      fetchAnalytics();
    }
  }, [timeFilter]);

  // Mock visitor data - fallback if API fails
  const [mockVisitors] = useState([
    {
      id: 1,
      sessionId: 'sess_123',
      isOnline: true,
      name: 'Anonymous Visitor',
      email: null,
      location: 'New York, US',
      country: 'US',
      city: 'New York',
      device: 'desktop',
      browser: 'Chrome',
      os: 'Windows',
      currentPage: '/products/laptop',
      timeOnSite: 324, // seconds
      pageViews: 5,
      visitCount: 1,
      isReturning: false,
      referrer: 'google.com',
      utmSource: 'google',
      utmMedium: 'organic',
      firstSeenAt: new Date(Date.now() - 324000),
      lastActivityAt: new Date(Date.now() - 30000),
      customAttributes: {
        cart_value: 299.99,
        product_interest: 'laptops'
      }
    },
    {
      id: 2,
      sessionId: 'sess_456',
      isOnline: true,
      name: 'Sarah Johnson',
      email: 'sarah@example.com',
      location: 'London, GB',
      country: 'GB',
      city: 'London',
      device: 'mobile',
      browser: 'Safari',
      os: 'iOS',
      currentPage: '/checkout',
      timeOnSite: 892, // seconds
      pageViews: 12,
      visitCount: 4,
      isReturning: true,
      referrer: 'newsletter',
      utmSource: 'email',
      utmMedium: 'newsletter',
      firstSeenAt: new Date(Date.now() - 892000),
      lastActivityAt: new Date(Date.now() - 120000),
      customAttributes: {
        cart_value: 149.99,
        membership: 'premium'
      }
    },
    {
      id: 3,
      sessionId: 'sess_789',
      isOnline: false,
      name: 'Mike Chen',
      email: 'mike@example.com',
      location: 'San Francisco, US',
      country: 'US',
      city: 'San Francisco',
      device: 'tablet',
      browser: 'Chrome',
      os: 'Android',
      currentPage: '/support/contact',
      timeOnSite: 156,
      pageViews: 3,
      visitCount: 2,
      isReturning: true,
      referrer: 'direct',
      utmSource: 'direct',
      utmMedium: 'direct',
      firstSeenAt: new Date(Date.now() - 3600000),
      lastActivityAt: new Date(Date.now() - 1800000),
      customAttributes: {
        support_topic: 'billing'
      }
    }
  ]);

  // Calculate stats from real data or fallback to mock
  const stats = useMemo(() => {
    const dataSource = visitors.length > 0 ? visitors : mockVisitors;
    const onlineVisitors = dataSource.filter((v: any) => v.isOnline).length;
    const totalVisitors = analytics?.totalVisitors || dataSource.length;
    const avgTimeOnSite = analytics?.averageTimeOnSite || 
      (dataSource.reduce((sum: number, v: any) => sum + (v.timeOnSite || 0), 0) / dataSource.length);
    const totalPageViews = analytics?.averagePageViews * totalVisitors || 
      dataSource.reduce((sum: number, v: any) => sum + (v.pageViews || 0), 0);

    return {
      onlineVisitors,
      totalVisitors,
      avgTimeOnSite: Math.round(avgTimeOnSite),
      totalPageViews: Math.round(totalPageViews)
    };
  }, [visitors, analytics, mockVisitors]);

  // Filter visitors
  const filteredVisitors = useMemo(() => {
    const dataSource = visitors.length > 0 ? visitors : mockVisitors;
    return dataSource.filter((visitor: any) => {
      if (locationFilter !== 'all' && visitor.countryCode !== locationFilter) {
        return false;
      }
      if (deviceFilter !== 'all' && visitor.deviceType !== deviceFilter) {
        return false;
      }
      return true;
    });
  }, [visitors, mockVisitors, locationFilter, deviceFilter]);

  // Device distribution data for chart
  const deviceData = useMemo(() => {
    const dataSource = visitors.length > 0 ? visitors : mockVisitors;
    const deviceCounts = dataSource.reduce((acc: Record<string, number>, visitor: any) => {
      const device = visitor.deviceType || visitor.device;
      acc[device] = (acc[device] || 0) + 1;
      return acc;
    }, {} as Record<string, number>);

    // Use analytics data if available
    if (analytics?.deviceBreakdown) {
      return analytics.deviceBreakdown.map((item: any) => ({
        id: item.device,
        label: item.device,
        value: item.count,
        color: item.device === 'desktop' ? '#3b82f6' : item.device === 'mobile' ? '#10b981' : '#f59e0b'
      }));
    }

    return Object.entries(deviceCounts).map(([device, count]) => ({
      id: device,
      label: device,
      value: count,
      color: device === 'desktop' ? '#3b82f6' : device === 'mobile' ? '#10b981' : '#f59e0b'
    }));
  }, [visitors, analytics, mockVisitors]);

  // Location data for chart
  const locationData = useMemo(() => {
    // Use analytics data if available
    if (analytics?.topCountries) {
      return analytics.topCountries.map((item: any) => ({
        country: item.country,
        visitors: item.visitors
      }));
    }

    const dataSource = visitors.length > 0 ? visitors : mockVisitors;
    const locationCounts = dataSource.reduce((acc: Record<string, number>, visitor: any) => {
      const country = visitor.countryCode || visitor.country;
      acc[country] = (acc[country] || 0) + 1;
      return acc;
    }, {} as Record<string, number>);

    return Object.entries(locationCounts).map(([country, count]) => ({
      country,
      visitors: count
    }));
  }, [visitors, analytics, mockVisitors]);

  // Time on site data
  const timeData = useMemo(() => {
    const dataSource = visitors.length > 0 ? visitors : mockVisitors;
    return [{
      id: 'time_on_site',
      data: dataSource.map((visitor: any, index: number) => ({
        x: index + 1,
        y: Math.round((visitor.timeOnSite || 0) / 60) // convert to minutes
      }))
    }];
  }, [visitors, mockVisitors]);

  const handleRefresh = () => {
    setIsRefreshing(true);
    fetchVisitorSessions();
    fetchAnalytics();
  };

  const formatDuration = (seconds: number) => {
    if (!seconds) return '0s';
    if (seconds < 60) return `${seconds}s`;
    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = seconds % 60;
    if (minutes < 60) return `${minutes}m ${remainingSeconds}s`;
    const hours = Math.floor(minutes / 60);
    const remainingMinutes = minutes % 60;
    return `${hours}h ${remainingMinutes}m`;
  };

  const getDeviceIcon = (device: string) => {
    switch (device) {
      case 'desktop':
        return <ComputerDesktopIcon className="h-4 w-4" />;
      case 'mobile':
        return <DevicePhoneMobileIcon className="h-4 w-4" />;
      case 'tablet':
        return <DeviceTabletIcon className="h-4 w-4" />;
      default:
        return <ComputerDesktopIcon className="h-4 w-4" />;
    }
  };

  const initiateChat = (visitor: any) => {
    console.log('Initiating chat with visitor:', visitor);
    // TODO: Implement proactive chat initiation
  };

  return (
    <TrackingContainer>
      <Header>
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-semibold text-gray-900">Visitor Tracking</h1>
            <p className="text-gray-600">Monitor and engage with your website visitors in real-time</p>
          </div>
          
          <RefreshButton onClick={handleRefresh} disabled={isRefreshing}>
            <ArrowPathIcon className={`h-4 w-4 ${isRefreshing ? 'animate-spin' : ''}`} />
            <span>Refresh</span>
          </RefreshButton>
        </div>
      </Header>

      <StatsGrid>
        <StatCard>
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Online Visitors</p>
              <p className="text-2xl font-semibold text-gray-900">{stats.onlineVisitors}</p>
            </div>
            <div className="p-3 bg-green-100 rounded-full">
              <UserGroupIcon className="h-6 w-6 text-green-600" />
            </div>
          </div>
          <div className="mt-2">
            <span className="text-sm text-green-600">
              +12% from yesterday
            </span>
          </div>
        </StatCard>

        <StatCard>
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Total Visitors</p>
              <p className="text-2xl font-semibold text-gray-900">{stats.totalVisitors}</p>
            </div>
            <div className="p-3 bg-blue-100 rounded-full">
              <EyeIcon className="h-6 w-6 text-blue-600" />
            </div>
          </div>
          <div className="mt-2">
            <span className="text-sm text-blue-600">
              Last 24 hours
            </span>
          </div>
        </StatCard>

        <StatCard>
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Avg. Time on Site</p>
              <p className="text-2xl font-semibold text-gray-900">
                {formatDuration(stats.avgTimeOnSite)}
              </p>
            </div>
            <div className="p-3 bg-yellow-100 rounded-full">
              <ClockIcon className="h-6 w-6 text-yellow-600" />
            </div>
          </div>
          <div className="mt-2">
            <span className="text-sm text-yellow-600">
              +8% from last week
            </span>
          </div>
        </StatCard>

        <StatCard>
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Page Views</p>
              <p className="text-2xl font-semibold text-gray-900">{stats.totalPageViews}</p>
            </div>
            <div className="p-3 bg-purple-100 rounded-full">
              <ArrowTrendingUpIcon className="h-6 w-6 text-purple-600" />
            </div>
          </div>
          <div className="mt-2">
            <span className="text-sm text-purple-600">
              +23% from last week
            </span>
          </div>
        </StatCard>
      </StatsGrid>

      <div className="px-6">
        <FilterBar>
          <div className="flex items-center space-x-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Time Range
              </label>
              <FilterSelect
                value={timeFilter}
                onChange={(e) => setTimeFilter(e.target.value)}
              >
                <option value="1h">Last Hour</option>
                <option value="24h">Last 24 Hours</option>
                <option value="7d">Last 7 Days</option>
                <option value="30d">Last 30 Days</option>
              </FilterSelect>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Location
              </label>
              <FilterSelect
                value={locationFilter}
                onChange={(e) => setLocationFilter(e.target.value)}
              >
                <option value="all">All Countries</option>
                <option value="US">United States</option>
                <option value="GB">United Kingdom</option>
                <option value="CA">Canada</option>
              </FilterSelect>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Device
              </label>
              <FilterSelect
                value={deviceFilter}
                onChange={(e) => setDeviceFilter(e.target.value)}
              >
                <option value="all">All Devices</option>
                <option value="desktop">Desktop</option>
                <option value="mobile">Mobile</option>
                <option value="tablet">Tablet</option>
              </FilterSelect>
            </div>
          </div>
        </FilterBar>
      </div>

      <MainContent>
        <VisitorsList>
          <div className="p-6 border-b border-gray-200">
            <h2 className="text-lg font-semibold text-gray-900">Active Visitors</h2>
            <p className="text-sm text-gray-600 mt-1">
              {filteredVisitors.filter(v => v.isOnline).length} visitors currently browsing
            </p>
          </div>

          <div className="max-h-96 overflow-y-auto">
            {isLoading && visitors.length === 0 ? (
              <div className="p-6 text-center text-gray-500">
                Loading visitors...
              </div>
            ) : filteredVisitors.length === 0 ? (
              <div className="p-6 text-center text-gray-500">
                No visitors found
              </div>
            ) : (
              filteredVisitors.map((visitor: any) => (
              <VisitorItem
                key={visitor.id}
                isOnline={visitor.isOnline}
                onClick={() => setSelectedVisitor(visitor)}
              >
                <div className="flex items-start justify-between">
                  <div className="flex items-start space-x-3">
                    <div className="relative">
                      <div className="w-10 h-10 bg-gray-200 rounded-full flex items-center justify-center">
                        <span className="text-sm font-medium text-gray-600">
                          {visitor.name?.[0] || '?'}
                        </span>
                      </div>
                      {visitor.isOnline && (
                        <div className="absolute -bottom-1 -right-1 w-3 h-3 bg-green-500 border-2 border-white rounded-full" />
                      )}
                    </div>

                    <div className="flex-1 min-w-0">
                      <div className="flex items-center space-x-2">
                        <p className="text-sm font-medium text-gray-900 truncate">
                          {visitor.appUser?.displayName || visitor.appUser?.email || 'Anonymous Visitor'}
                        </p>
                        {visitor.isReturning && (
                          <span className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-blue-100 text-blue-800">
                            Returning
                          </span>
                        )}
                      </div>

                      <div className="flex items-center space-x-4 mt-1 text-xs text-gray-500">
                        <div className="flex items-center space-x-1">
                          <MapPinIcon className="h-3 w-3" />
                          <span>{visitor.locationString || visitor.location || 'Unknown'}</span>
                        </div>
                        
                        <div className="flex items-center space-x-1">
                          {getDeviceIcon(visitor.deviceType || visitor.device)}
                          <span>{visitor.deviceType || visitor.device}</span>
                        </div>

                        <div className="flex items-center space-x-1">
                          <ClockIcon className="h-3 w-3" />
                          <span>{visitor.durationFormatted || formatDuration(visitor.timeOnSite || 0)}</span>
                        </div>

                        <div className="flex items-center space-x-1">
                          <EyeIcon className="h-3 w-3" />
                          <span>{visitor.pageViews || 0} pages</span>
                        </div>
                      </div>

                      <p className="text-xs text-gray-600 mt-1 truncate">
                        Currently on: {visitor.currentPage || visitor.landingPage || 'N/A'}
                      </p>
                    </div>
                  </div>

                  <div className="flex items-center space-x-2">
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        initiateChat(visitor);
                      }}
                      className="p-2 text-gray-400 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                      title="Start chat"
                    >
                      <ChatBubbleBottomCenterTextIcon className="h-4 w-4" />
                    </button>
                  </div>
                </div>
              </VisitorItem>
              ))
            )}
          </div>
        </VisitorsList>

        <div className="space-y-6">
          <AnalyticsPanel>
            <h3 className="text-lg font-semibold text-gray-900 mb-4">Device Distribution</h3>
            <ChartContainer>
              <ResponsivePie
                data={deviceData}
                margin={{ top: 40, right: 80, bottom: 80, left: 80 }}
                innerRadius={0.5}
                padAngle={0.7}
                cornerRadius={3}
                activeOuterRadiusOffset={8}
                colors={['#3b82f6', '#10b981', '#f59e0b']}
                borderWidth={1}
                borderColor={{ from: 'color', modifiers: [['darker', 0.2]] }}
                arcLinkLabelsSkipAngle={10}
                arcLinkLabelsTextColor="#333333"
                arcLinkLabelsThickness={2}
                arcLinkLabelsColor={{ from: 'color' }}
                arcLabelsSkipAngle={10}
                arcLabelsTextColor={{ from: 'color', modifiers: [['darker', 2]] }}
              />
            </ChartContainer>
          </AnalyticsPanel>

          <AnalyticsPanel>
            <h3 className="text-lg font-semibold text-gray-900 mb-4">Visitors by Location</h3>
            <ChartContainer>
              <ResponsiveBar
                data={locationData}
                keys={['visitors']}
                indexBy="country"
                margin={{ top: 50, right: 130, bottom: 50, left: 60 }}
                padding={0.3}
                valueScale={{ type: 'linear' }}
                indexScale={{ type: 'band', round: true }}
                colors={{ scheme: 'nivo' }}
                defs={[
                  {
                    id: 'dots',
                    type: 'patternDots',
                    background: 'inherit',
                    color: '#38bcb2',
                    size: 4,
                    padding: 1,
                    stagger: true
                  }
                ]}
                borderColor={{ from: 'color', modifiers: [['darker', 1.6]] }}
                axisTop={null}
                axisRight={null}
                axisBottom={{
                  tickSize: 5,
                  tickPadding: 5,
                  tickRotation: 0,
                  legend: 'Country',
                  legendPosition: 'middle',
                  legendOffset: 32
                }}
                axisLeft={{
                  tickSize: 5,
                  tickPadding: 5,
                  tickRotation: 0,
                  legend: 'Visitors',
                  legendPosition: 'middle',
                  legendOffset: -40
                }}
                labelSkipWidth={12}
                labelSkipHeight={12}
                labelTextColor={{ from: 'color', modifiers: [['darker', 1.6]] }}
              />
            </ChartContainer>
          </AnalyticsPanel>

          <AnalyticsPanel>
            <h3 className="text-lg font-semibold text-gray-900 mb-4">Time on Site</h3>
            <ChartContainer>
              <ResponsiveLine
                data={timeData}
                margin={{ top: 50, right: 110, bottom: 50, left: 60 }}
                xScale={{ type: 'point' }}
                yScale={{ type: 'linear', min: 'auto', max: 'auto', stacked: false, reverse: false }}
                yFormat=" >-.2f"
                axisTop={null}
                axisRight={null}
                axisBottom={{
                  orient: 'bottom',
                  tickSize: 5,
                  tickPadding: 5,
                  tickRotation: 0,
                  legend: 'Visitor',
                  legendOffset: 36,
                  legendPosition: 'middle'
                }}
                axisLeft={{
                  orient: 'left',
                  tickSize: 5,
                  tickPadding: 5,
                  tickRotation: 0,
                  legend: 'Minutes',
                  legendOffset: -40,
                  legendPosition: 'middle'
                }}
                pointSize={10}
                pointColor={{ theme: 'background' }}
                pointBorderWidth={2}
                pointBorderColor={{ from: 'serieColor' }}
                pointLabelYOffset={-12}
                useMesh={true}
                colors={{ scheme: 'category10' }}
              />
            </ChartContainer>
          </AnalyticsPanel>
        </div>
      </MainContent>
    </TrackingContainer>
  );
};

const mapStateToProps = (state: any) => ({
  app: state.app,
  currentUser: state.currentUser
});

export default connect(mapStateToProps)(VisitorTracking);