import React, { useState, useEffect, useRef, useMemo } from 'react';
import { connect } from 'react-redux';
import styled from '@emotion/styled';
import tw from 'twin.macro';
import actioncable from 'actioncable';
import {
  ChartBarIcon,
  UsersIcon,
  ChatBubbleLeftRightIcon,
  ArrowTrendingUpIcon,
  ClockIcon
} from '@heroicons/react/24/outline';
import graphql from '@chaskiq/store/src/graphql/client';
import { VISITOR_ANALYTICS, LIVE_VISITORS } from '@chaskiq/store/src/graphql/queries';
import { ResponsiveLine } from '@nivo/line';
import { ResponsiveBar } from '@nivo/bar';

const DashboardContainer = styled.div`
  ${tw`h-full bg-gray-50 overflow-auto`}
`;

const StatsGrid = styled.div`
  ${tw`grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 p-6`}
`;

const StatCard = styled.div`
  ${tw`bg-white rounded-lg shadow-sm border border-gray-200 p-6`}
`;

const ChartContainer = styled.div`
  ${tw`bg-white rounded-lg shadow-sm border border-gray-200 p-6 mb-6`}
  height: 400px;
`;

interface RealtimeAnalyticsProps {
  app: any;
  accessToken: string;
  dispatch: any;
}

interface AnalyticsData {
  totalVisitors: number;
  activeVisitors: number;
  totalConversations: number;
  activeConversations: number;
  conversionRate: number;
  averageResponseTime: number;
  hourlyData: Array<{ hour: string; visitors: number; conversations: number }>;
  deviceData: Array<{ device: string; count: number }>;
}

const RealtimeAnalytics: React.FC<RealtimeAnalyticsProps> = ({
  app,
  accessToken,
  dispatch
}) => {
  const [analytics, setAnalytics] = useState<AnalyticsData>({
    totalVisitors: 0,
    activeVisitors: 0,
    totalConversations: 0,
    activeConversations: 0,
    conversionRate: 0,
    averageResponseTime: 0,
    hourlyData: [],
    deviceData: [],
  });
  const [isLoading, setIsLoading] = useState(true);
  const [lastUpdate, setLastUpdate] = useState<Date>(new Date());
  const cableRef = useRef<any>(null);
  const subscriptionRef = useRef<any>(null);

  // Fetch initial analytics data
  const fetchAnalytics = () => {
    if (!app?.key) return;

    graphql(
      VISITOR_ANALYTICS,
      {
        appKey: app.key,
        timeRange: '24h',
      },
      {
        success: (data) => {
          const analyticsData = data.visitorAnalytics;
          setAnalytics({
            totalVisitors: analyticsData.totalVisitors || 0,
            activeVisitors: analyticsData.activeVisitors || 0,
            totalConversations: analyticsData.totalConversations || 0,
            activeConversations: analyticsData.activeConversations || 0,
            conversionRate: analyticsData.conversionRate || 0,
            averageResponseTime: analyticsData.averageResponseTime || 0,
            hourlyData: analyticsData.hourlyPerformance?.map((h: any) => ({
              hour: h.hour,
              visitors: h.visitors || 0,
              conversations: h.conversations || 0,
            })) || [],
            deviceData: analyticsData.deviceBreakdown?.map((d: any) => ({
              device: d.device,
              count: d.count || 0,
            })) || [],
          });
          setIsLoading(false);
          setLastUpdate(new Date());
        },
        error: (err) => {
          console.error('Error fetching analytics:', err);
          setIsLoading(false);
        }
      }
    );
  };

  // Fetch live visitors count
  const fetchLiveVisitors = () => {
    if (!app?.key) return;

    graphql(
      LIVE_VISITORS,
      { appKey: app.key },
      {
        success: (data) => {
          setAnalytics((prev) => ({
            ...prev,
            activeVisitors: data.liveVisitors?.count || 0,
          }));
        },
        error: () => {}
      }
    );
  };

  // Initialize ActionCable subscription for real-time updates
  useEffect(() => {
    if (!app?.key || !accessToken) return;

    fetchAnalytics();
    fetchLiveVisitors();

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
          console.log('RealtimeAnalytics: Connected to ActionCable');
        },
        disconnected: () => {
          console.log('RealtimeAnalytics: Disconnected from ActionCable');
        },
        received: (data) => {
          // Update analytics in real-time based on events
          if (data.type === 'visitor:new' || data.type === 'visitor:update') {
            fetchLiveVisitors();
            // Increment total visitors if new
            if (data.type === 'visitor:new') {
              setAnalytics((prev) => ({
                ...prev,
                totalVisitors: prev.totalVisitors + 1,
              }));
            }
          }
          if (data.type === 'conversation_part') {
            setAnalytics((prev) => ({
              ...prev,
              activeConversations: prev.activeConversations + 1,
            }));
          }
        },
      }
    );

    // Refresh analytics every 30 seconds
    const interval = setInterval(() => {
      fetchAnalytics();
    }, 30000);

    return () => {
      if (subscriptionRef.current) {
        subscriptionRef.current.unsubscribe();
      }
      if (cableRef.current) {
        cableRef.current.disconnect();
      }
      clearInterval(interval);
    };
  }, [app?.key, accessToken]);

  // Prepare chart data
  const lineChartData = useMemo(() => {
    if (!analytics.hourlyData || analytics.hourlyData.length === 0) {
      return [{ id: 'visitors', data: [] }, { id: 'conversations', data: [] }];
    }

    return [
      {
        id: 'visitors',
        data: analytics.hourlyData.map((d) => ({
          x: d.hour,
          y: d.visitors,
        })),
      },
      {
        id: 'conversations',
        data: analytics.hourlyData.map((d) => ({
          x: d.hour,
          y: d.conversations,
        })),
      },
    ];
  }, [analytics.hourlyData]);

  const barChartData = useMemo(() => {
    if (!analytics.deviceData || analytics.deviceData.length === 0) {
      return [];
    }
    return analytics.deviceData.map((d) => ({
      device: d.device,
      count: d.count,
    }));
  }, [analytics.deviceData]);

  if (isLoading) {
    return (
      <DashboardContainer>
        <div className="p-12 text-center">
          <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
          <p className="mt-2 text-gray-500">Loading analytics...</p>
        </div>
      </DashboardContainer>
    );
  }

  return (
    <DashboardContainer>
      <div className="p-6">
        <div className="flex items-center justify-between mb-6">
          <h1 className="text-2xl font-bold text-gray-900">Real-time Analytics</h1>
          <div className="flex items-center space-x-2 text-sm text-gray-500">
            <ClockIcon className="h-4 w-4" />
            <span>Last updated: {lastUpdate.toLocaleTimeString()}</span>
          </div>
        </div>

        <StatsGrid>
          <StatCard>
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600">Total Visitors</p>
                <p className="text-3xl font-bold text-gray-900 mt-2">
                  {analytics.totalVisitors.toLocaleString()}
                </p>
              </div>
              <UsersIcon className="h-12 w-12 text-blue-500" />
            </div>
          </StatCard>

          <StatCard>
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600">Active Visitors</p>
                <p className="text-3xl font-bold text-green-600 mt-2">
                  {analytics.activeVisitors.toLocaleString()}
                </p>
              </div>
              <ArrowTrendingUpIcon className="h-12 w-12 text-green-500" />
            </div>
          </StatCard>

          <StatCard>
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600">Total Conversations</p>
                <p className="text-3xl font-bold text-gray-900 mt-2">
                  {analytics.totalConversations.toLocaleString()}
                </p>
              </div>
              <ChatBubbleLeftRightIcon className="h-12 w-12 text-purple-500" />
            </div>
          </StatCard>

          <StatCard>
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600">Conversion Rate</p>
                <p className="text-3xl font-bold text-blue-600 mt-2">
                  {analytics.conversionRate.toFixed(1)}%
                </p>
              </div>
              <ChartBarIcon className="h-12 w-12 text-blue-500" />
            </div>
          </StatCard>
        </StatsGrid>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mt-6">
          <ChartContainer>
            <h3 className="text-lg font-semibold text-gray-900 mb-4">Hourly Performance</h3>
            {lineChartData[0].data.length > 0 ? (
              <ResponsiveLine
                data={lineChartData}
                margin={{ top: 50, right: 50, bottom: 50, left: 60 }}
                xScale={{ type: 'point' }}
                yScale={{ type: 'linear', min: 'auto', max: 'auto' }}
                curve="monotoneX"
                axisTop={null}
                axisRight={null}
                axisBottom={{
                  tickSize: 5,
                  tickPadding: 5,
                  tickRotation: 0,
                }}
                axisLeft={{
                  tickSize: 5,
                  tickPadding: 5,
                  tickRotation: 0,
                }}
                pointSize={8}
                pointColor={{ theme: 'background' }}
                pointBorderWidth={2}
                pointBorderColor={{ from: 'serieColor' }}
                useMesh={true}
                legends={[
                  {
                    anchor: 'top-right',
                    direction: 'column',
                    justify: false,
                    translateX: 0,
                    translateY: -40,
                    itemsSpacing: 0,
                    itemDirection: 'left-to-right',
                    itemWidth: 80,
                    itemHeight: 20,
                    itemOpacity: 0.75,
                    symbolSize: 12,
                    symbolShape: 'circle',
                  },
                ]}
              />
            ) : (
              <div className="flex items-center justify-center h-full text-gray-500">
                No data available
              </div>
            )}
          </ChartContainer>

          <ChartContainer>
            <h3 className="text-lg font-semibold text-gray-900 mb-4">Device Breakdown</h3>
            {barChartData.length > 0 ? (
              <ResponsiveBar
                data={barChartData}
                keys={['count']}
                indexBy="device"
                margin={{ top: 50, right: 50, bottom: 50, left: 60 }}
                padding={0.3}
                valueScale={{ type: 'linear' }}
                indexScale={{ type: 'band', round: true }}
                colors={{ scheme: 'nivo' }}
                axisTop={null}
                axisRight={null}
                axisBottom={{
                  tickSize: 5,
                  tickPadding: 5,
                  tickRotation: 0,
                }}
                axisLeft={{
                  tickSize: 5,
                  tickPadding: 5,
                  tickRotation: 0,
                }}
                labelSkipWidth={12}
                labelSkipHeight={12}
                labelTextColor={{ from: 'color', modifiers: [['darker', 1.6]] }}
                animate={true}
                motionStiffness={90}
                motionDamping={15}
              />
            ) : (
              <div className="flex items-center justify-center h-full text-gray-500">
                No data available
              </div>
            )}
          </ChartContainer>
        </div>
      </div>
    </DashboardContainer>
  );
};

const mapStateToProps = (state: any) => ({
  app: state.app,
  accessToken: state.auth?.accessToken,
});

export default connect(mapStateToProps)(RealtimeAnalytics);

