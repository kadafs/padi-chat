import React, { useState, useEffect } from 'react';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';
import styled from '@emotion/styled';
import tw from 'twin.macro';
import {
  PlusIcon,
  PencilIcon,
  TrashIcon,
  PlayIcon,
  PauseIcon,
  DocumentDuplicateIcon,
  ChartBarIcon,
  ClockIcon,
  BoltIcon,
  UserGroupIcon,
  FunnelIcon
} from '@heroicons/react/24/outline';
import graphql from '@chaskiq/store/src/graphql/client';
import { PROACTIVE_MESSAGES, PROACTIVE_MESSAGE_ANALYTICS } from '@chaskiq/store/src/graphql/queries';
import {
  CREATE_PROACTIVE_CAMPAIGN,
  UPDATE_PROACTIVE_CAMPAIGN,
  TOGGLE_PROACTIVE_CAMPAIGN,
  DUPLICATE_PROACTIVE_CAMPAIGN,
  TEST_PROACTIVE_CAMPAIGN
} from '@chaskiq/store/src/graphql/mutations';
import Button from '@chaskiq/components/src/components/Button';
import ContentHeader from '@chaskiq/components/src/components/PageHeader';
import Content from '@chaskiq/components/src/components/Content';
import EmptyView from '@chaskiq/components/src/components/EmptyView';
import SwitchControl from '@chaskiq/components/src/components/Switch';
import FormDialog from '@chaskiq/components/src/components/FormDialog';
import DeleteDialog from '@chaskiq/components/src/components/DeleteDialog';
import Badge from '@chaskiq/components/src/components/Badge';
import { successMessage, errorMessage } from '@chaskiq/store/src/actions/status_messages';

const CampaignContainer = styled.div`
  ${tw`h-full bg-gray-50 overflow-auto`}
`;

const CampaignGrid = styled.div`
  ${tw`grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 p-6`}
`;

const CampaignCard = styled.div<{ active?: boolean }>`
  ${tw`bg-white rounded-lg shadow-sm border border-gray-200 p-6 hover:shadow-md transition-shadow cursor-pointer`}
  ${props => props.active && tw`border-green-500 border-2`}
`;

const CampaignHeader = styled.div`
  ${tw`flex items-center justify-between mb-4`}
`;

const TriggerBadge = styled.span<{ type: string }>`
  ${tw`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium`}
  ${props => {
    switch (props.type) {
      case 'time_based': return tw`bg-blue-100 text-blue-800`;
      case 'behavior_based': return tw`bg-purple-100 text-purple-800`;
      case 'exit_intent': return tw`bg-red-100 text-red-800`;
      case 'scroll_based': return tw`bg-yellow-100 text-yellow-800`;
      case 'page_based': return tw`bg-green-100 text-green-800`;
      default: return tw`bg-gray-100 text-gray-800`;
    }
  }}
`;

interface ProactiveMessageCampaignProps {
  app: any;
  dispatch: any;
  match: any;
  history: any;
}

const ProactiveMessageCampaign: React.FC<ProactiveMessageCampaignProps> = ({
  app,
  dispatch,
  match,
  history
}) => {
  const [campaigns, setCampaigns] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [openDialog, setOpenDialog] = useState<any>(null);
  const [openDeleteDialog, setOpenDeleteDialog] = useState<any>(null);
  const [selectedCampaign, setSelectedCampaign] = useState<any>(null);
  const [filter, setFilter] = useState<'all' | 'active' | 'inactive'>('all');
  const [triggerFilter, setTriggerFilter] = useState<string>('all');

  // Fetch campaigns
  const fetchCampaigns = () => {
    if (!app?.key) return;

    setIsLoading(true);
    graphql(
      PROACTIVE_MESSAGES,
      {
        appKey: app.key,
        status: filter === 'all' ? null : filter === 'active' ? 'active' : 'inactive',
        triggerType: triggerFilter === 'all' ? null : triggerFilter,
        searchTerm: null
      },
      {
        success: (data) => {
          const edges = data.proactiveMessages?.edges || [];
          const campaignsList = edges.map((edge: any) => edge.node);
          setCampaigns(campaignsList);
          setIsLoading(false);
        },
        error: (err) => {
          console.error('Error fetching campaigns:', err);
          dispatch(errorMessage('Failed to load campaigns'));
          setIsLoading(false);
        }
      }
    );
  };

  useEffect(() => {
    if (app?.key) {
      fetchCampaigns();
    }
  }, [app?.key, filter, triggerFilter]);

  // Create new campaign
  const handleCreate = () => {
    setOpenDialog({
      id: null,
      name: '',
      triggerType: 'time_based',
      delaySeconds: 30,
      messageContent: { text: '' },
      active: true,
      priority: 0,
      triggerConditions: {},
      targetingRules: {}
    });
  };

  // Edit campaign
  const handleEdit = (campaign: any) => {
    setOpenDialog(campaign);
  };

  // Delete campaign
  const handleDelete = (campaign: any) => {
    setOpenDeleteDialog(campaign);
  };

  // Toggle active status
  const handleToggle = (campaign: any) => {
    if (!app?.key) return;

    graphql(
      TOGGLE_PROACTIVE_CAMPAIGN,
      {
        appKey: app.key,
        id: campaign.id
      },
      {
        success: () => {
          dispatch(successMessage(`Campaign ${campaign.active ? 'deactivated' : 'activated'}`));
          fetchCampaigns();
        },
        error: () => {
          dispatch(errorMessage('Failed to toggle campaign'));
        }
      }
    );
  };

  // Duplicate campaign
  const handleDuplicate = (campaign: any) => {
    if (!app?.key) return;

    graphql(
      DUPLICATE_PROACTIVE_CAMPAIGN,
      {
        appKey: app.key,
        id: campaign.id
      },
      {
        success: () => {
          dispatch(successMessage('Campaign duplicated'));
          fetchCampaigns();
        },
        error: () => {
          dispatch(errorMessage('Failed to duplicate campaign'));
        }
      }
    );
  };

  // Test campaign
  const handleTest = (campaign: any) => {
    if (!app?.key) return;

    graphql(
      TEST_PROACTIVE_CAMPAIGN,
      {
        appKey: app.key,
        id: campaign.id
      },
      {
        success: () => {
          dispatch(successMessage('Test campaign sent'));
        },
        error: () => {
          dispatch(errorMessage('Failed to test campaign'));
        }
      }
    );
  };

  // Save campaign
  const handleSave = (formData: any) => {
    if (!app?.key) return;

    const campaignData = {
      name: formData.name,
      triggerType: formData.triggerType,
      delaySeconds: parseInt(formData.delaySeconds) || 30,
      messageContent: typeof formData.messageContent === 'string' 
        ? JSON.parse(formData.messageContent) 
        : formData.messageContent,
      active: formData.active !== false,
      priority: parseInt(formData.priority) || 0,
      triggerConditions: formData.triggerConditions || {},
      targetingRules: formData.targetingRules || {}
    };

    const mutation = openDialog?.id ? UPDATE_PROACTIVE_CAMPAIGN : CREATE_PROACTIVE_CAMPAIGN;
    const variables = openDialog?.id
      ? { appKey: app.key, id: openDialog.id, campaignData }
      : { appKey: app.key, campaignData };

    graphql(
      mutation,
      variables,
      {
        success: () => {
          dispatch(successMessage(`Campaign ${openDialog?.id ? 'updated' : 'created'}`));
          setOpenDialog(null);
          fetchCampaigns();
        },
        error: (err) => {
          console.error('Error saving campaign:', err);
          dispatch(errorMessage('Failed to save campaign'));
        }
      }
    );
  };

  const getTriggerTypeLabel = (type: string) => {
    const labels: { [key: string]: string } = {
      time_based: 'Time Based',
      behavior_based: 'Behavior Based',
      exit_intent: 'Exit Intent',
      scroll_based: 'Scroll Based',
      page_based: 'Page Based'
    };
    return labels[type] || type;
  };

  const filteredCampaigns = campaigns.filter((campaign: any) => {
    if (filter === 'active' && !campaign.active) return false;
    if (filter === 'inactive' && campaign.active) return false;
    if (triggerFilter !== 'all' && campaign.triggerType !== triggerFilter) return false;
    return true;
  });

  return (
    <CampaignContainer>
      <Content>
        <ContentHeader
          title="Proactive Chat Campaigns"
          actions={
            <Button onClick={handleCreate} variant="contained" color="primary">
              <PlusIcon className="h-5 w-5 mr-2" />
              New Campaign
            </Button>
          }
        />

        {/* Filters */}
        <div className="px-6 py-4 bg-white border-b border-gray-200 flex items-center space-x-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Status</label>
            <select
              value={filter}
              onChange={(e) => setFilter(e.target.value as any)}
              className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            >
              <option value="all">All</option>
              <option value="active">Active</option>
              <option value="inactive">Inactive</option>
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Trigger Type</label>
            <select
              value={triggerFilter}
              onChange={(e) => setTriggerFilter(e.target.value)}
              className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            >
              <option value="all">All Types</option>
              <option value="time_based">Time Based</option>
              <option value="behavior_based">Behavior Based</option>
              <option value="exit_intent">Exit Intent</option>
              <option value="scroll_based">Scroll Based</option>
              <option value="page_based">Page Based</option>
            </select>
          </div>
        </div>

        {/* Campaigns Grid */}
        {isLoading ? (
          <div className="p-12 text-center">
            <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
            <p className="mt-2 text-gray-500">Loading campaigns...</p>
          </div>
        ) : filteredCampaigns.length === 0 ? (
          <EmptyView
            title="No campaigns found"
            subtitle="Create your first proactive chat campaign to engage visitors"
            action={
              <Button onClick={handleCreate} variant="contained" color="primary">
                <PlusIcon className="h-5 w-5 mr-2" />
                Create Campaign
              </Button>
            }
          />
        ) : (
          <CampaignGrid>
            {filteredCampaigns.map((campaign: any) => (
              <CampaignCard
                key={campaign.id}
                active={campaign.active}
                onClick={() => {
                  setSelectedCampaign(campaign);
                  history.push(`${match.url}/${campaign.id}`);
                }}
              >
                <CampaignHeader>
                  <div className="flex-1">
                    <h3 className="text-lg font-semibold text-gray-900">{campaign.name}</h3>
                    <div className="flex items-center space-x-2 mt-1">
                      <TriggerBadge type={campaign.triggerType}>
                        {getTriggerTypeLabel(campaign.triggerType)}
                      </TriggerBadge>
                      {campaign.active ? (
                        <Badge variant="success">Active</Badge>
                      ) : (
                        <Badge variant="gray">Inactive</Badge>
                      )}
                    </div>
                  </div>
                  <SwitchControl
                    checked={campaign.active}
                    onChange={() => handleToggle(campaign)}
                    onClick={(e: any) => e.stopPropagation()}
                  />
                </CampaignHeader>

                <div className="mt-4 space-y-2">
                  <div className="flex items-center text-sm text-gray-600">
                    <ClockIcon className="h-4 w-4 mr-2" />
                    Delay: {campaign.delaySeconds || 30}s
                  </div>
                  {campaign.messageContent?.text && (
                    <p className="text-sm text-gray-600 truncate">
                      {campaign.messageContent.text}
                    </p>
                  )}
                </div>

                <div className="mt-4 pt-4 border-t border-gray-200 flex items-center justify-between">
                  <div className="flex items-center space-x-2">
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        handleEdit(campaign);
                      }}
                      className="p-2 text-gray-400 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                      title="Edit"
                    >
                      <PencilIcon className="h-4 w-4" />
                    </button>
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        handleDuplicate(campaign);
                      }}
                      className="p-2 text-gray-400 hover:text-green-600 hover:bg-green-50 rounded-lg transition-colors"
                      title="Duplicate"
                    >
                      <DocumentDuplicateIcon className="h-4 w-4" />
                    </button>
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        handleTest(campaign);
                      }}
                      className="p-2 text-gray-400 hover:text-purple-600 hover:bg-purple-50 rounded-lg transition-colors"
                      title="Test"
                    >
                      <PlayIcon className="h-4 w-4" />
                    </button>
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        handleDelete(campaign);
                      }}
                      className="p-2 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                      title="Delete"
                    >
                      <TrashIcon className="h-4 w-4" />
                    </button>
                  </div>
                  <button
                    onClick={(e) => {
                      e.stopPropagation();
                      setSelectedCampaign(campaign);
                      // Navigate to analytics
                    }}
                    className="p-2 text-gray-400 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                    title="Analytics"
                  >
                    <ChartBarIcon className="h-4 w-4" />
                  </button>
                </div>
              </CampaignCard>
            ))}
          </CampaignGrid>
        )}

        {/* Create/Edit Dialog */}
        {openDialog && (
          <ProactiveCampaignDialog
            open={!!openDialog}
            campaign={openDialog}
            onClose={() => setOpenDialog(null)}
            onSave={handleSave}
            app={app}
          />
        )}

        {/* Delete Dialog */}
        {openDeleteDialog && (
          <DeleteDialog
            open={!!openDeleteDialog}
            title={`Delete "${openDeleteDialog.name}"?`}
            closeHandler={() => setOpenDeleteDialog(null)}
            deleteHandler={() => {
              // TODO: Implement delete mutation
              setOpenDeleteDialog(null);
              fetchCampaigns();
            }}
          >
            <p>This action cannot be undone. All campaign data will be permanently deleted.</p>
          </DeleteDialog>
        )}
      </Content>
    </CampaignContainer>
  );
};

// Campaign Form Dialog Component
interface ProactiveCampaignDialogProps {
  open: boolean;
  campaign: any;
  onClose: () => void;
  onSave: (data: any) => void;
  app: any;
}

const ProactiveCampaignDialog: React.FC<ProactiveCampaignDialogProps> = ({
  open,
  campaign,
  onClose,
  onSave,
  app
}) => {
  const [formData, setFormData] = useState({
    name: campaign?.name || '',
    triggerType: campaign?.triggerType || 'time_based',
    delaySeconds: campaign?.delaySeconds || 30,
    messageContent: typeof campaign?.messageContent === 'object'
      ? JSON.stringify(campaign.messageContent, null, 2)
      : campaign?.messageContent || '{"text": ""}',
    active: campaign?.active !== false,
    priority: campaign?.priority || 0,
    triggerConditions: campaign?.triggerConditions || {},
    targetingRules: campaign?.targetingRules || {}
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSave(formData);
  };

  return (
    <FormDialog
      open={open}
      handleClose={onClose}
      titleContent={campaign?.id ? 'Edit Campaign' : 'Create Campaign'}
      formComponent={
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Campaign Name
            </label>
            <input
              type="text"
              required
              value={formData.name}
              onChange={(e) => setFormData({ ...formData, name: e.target.value })}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
              placeholder="Welcome Message"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Trigger Type
            </label>
            <select
              value={formData.triggerType}
              onChange={(e) => setFormData({ ...formData, triggerType: e.target.value })}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            >
              <option value="time_based">Time Based</option>
              <option value="behavior_based">Behavior Based</option>
              <option value="exit_intent">Exit Intent</option>
              <option value="scroll_based">Scroll Based</option>
              <option value="page_based">Page Based</option>
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Delay (seconds)
            </label>
            <input
              type="number"
              min="1"
              value={formData.delaySeconds}
              onChange={(e) => setFormData({ ...formData, delaySeconds: parseInt(e.target.value) || 30 })}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Message Content (JSON)
            </label>
            <textarea
              rows={6}
              value={formData.messageContent}
              onChange={(e) => setFormData({ ...formData, messageContent: e.target.value })}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 font-mono text-sm"
              placeholder='{"text": "Hello! How can I help you today?"}'
            />
          </div>

          <div className="flex items-center justify-between">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Priority
              </label>
              <input
                type="number"
                min="0"
                value={formData.priority}
                onChange={(e) => setFormData({ ...formData, priority: parseInt(e.target.value) || 0 })}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
              />
            </div>
            <div className="flex items-center space-x-2 mt-6">
              <SwitchControl
                checked={formData.active}
                onChange={(checked) => setFormData({ ...formData, active: checked })}
              />
              <label className="text-sm font-medium text-gray-700">Active</label>
            </div>
          </div>

          <div className="flex justify-end space-x-3 pt-4">
            <Button onClick={onClose} variant="outlined">
              Cancel
            </Button>
            <Button type="submit" variant="contained" color="primary">
              {campaign?.id ? 'Update' : 'Create'}
            </Button>
          </div>
        </form>
      }
    />
  );
};

const mapStateToProps = (state: any) => ({
  app: state.app
});

export default connect(mapStateToProps)(withRouter(ProactiveMessageCampaign));

