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
  EnvelopeIcon,
  ClockIcon,
  UserGroupIcon,
  ChartBarIcon
} from '@heroicons/react/24/outline';
import graphql from '@chaskiq/store/src/graphql/client';
import { EMAIL_SEQUENCES, EMAIL_SEQUENCE } from '@chaskiq/store/src/graphql/queries';
import {
  CREATE_EMAIL_SEQUENCE,
  UPDATE_EMAIL_SEQUENCE,
  DELETE_EMAIL_SEQUENCE,
  TOGGLE_EMAIL_SEQUENCE,
  DUPLICATE_EMAIL_SEQUENCE
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

const SequenceContainer = styled.div`
  ${tw`h-full bg-gray-50 overflow-auto`}
`;

const SequenceGrid = styled.div`
  ${tw`grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 p-6`}
`;

const SequenceCard = styled.div<{ active?: boolean }>`
  ${tw`bg-white rounded-lg shadow-sm border border-gray-200 p-6 hover:shadow-md transition-shadow cursor-pointer`}
  ${props => props.active && tw`border-green-500 border-2`}
`;

const SequenceHeader = styled.div`
  ${tw`flex items-center justify-between mb-4`}
`;

const TriggerBadge = styled.span<{ event: string }>`
  ${tw`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium`}
  ${props => {
    switch (props.event) {
      case 'signup': return tw`bg-blue-100 text-blue-800`;
      case 'purchase': return tw`bg-green-100 text-green-800`;
      case 'abandon_cart': return tw`bg-red-100 text-red-800`;
      case 'welcome': return tw`bg-purple-100 text-purple-800`;
      case 'feedback': return tw`bg-yellow-100 text-yellow-800`;
      case 'support': return tw`bg-indigo-100 text-indigo-800`;
      default: return tw`bg-gray-100 text-gray-800`;
    }
  }}
`;

interface EmailSequenceManagerProps {
  app: any;
  dispatch: any;
  match: any;
  history: any;
}

const EmailSequenceManager: React.FC<EmailSequenceManagerProps> = ({
  app,
  dispatch,
  match,
  history
}) => {
  const [sequences, setSequences] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [openDialog, setOpenDialog] = useState<any>(null);
  const [openDeleteDialog, setOpenDeleteDialog] = useState<any>(null);
  const [selectedSequence, setSelectedSequence] = useState<any>(null);
  const [filter, setFilter] = useState<'all' | 'active' | 'inactive'>('all');
  const [triggerFilter, setTriggerFilter] = useState<string>('all');

  // Fetch sequences
  const fetchSequences = () => {
    if (!app?.key) return;

    setIsLoading(true);
    graphql(
      EMAIL_SEQUENCES,
      {
        appKey: app.key,
        status: filter === 'all' ? null : filter === 'active' ? 'active' : 'inactive',
        triggerEvent: triggerFilter === 'all' ? null : triggerFilter
      },
      {
        success: (data) => {
          setSequences(data.emailSequences || []);
          setIsLoading(false);
        },
        error: (err) => {
          console.error('Error fetching sequences:', err);
          dispatch(errorMessage('Failed to load email sequences'));
          setIsLoading(false);
        }
      }
    );
  };

  useEffect(() => {
    if (app?.key) {
      fetchSequences();
    }
  }, [app?.key, filter, triggerFilter]);

  // Create new sequence
  const handleCreate = () => {
    setOpenDialog({
      id: null,
      name: '',
      description: '',
      triggerEvent: 'signup',
      active: true,
      sequenceData: {}
    });
  };

  // Edit sequence
  const handleEdit = (sequence: any) => {
    setOpenDialog(sequence);
  };

  // Delete sequence
  const handleDelete = (sequence: any) => {
    setOpenDeleteDialog(sequence);
  };

  // Toggle active status
  const handleToggle = (sequence: any) => {
    if (!app?.key) return;

    graphql(
      TOGGLE_EMAIL_SEQUENCE,
      {
        appKey: app.key,
        id: sequence.id
      },
      {
        success: () => {
          dispatch(successMessage(`Sequence ${sequence.active ? 'deactivated' : 'activated'}`));
          fetchSequences();
        },
        error: () => {
          dispatch(errorMessage('Failed to toggle sequence'));
        }
      }
    );
  };

  // Duplicate sequence
  const handleDuplicate = (sequence: any) => {
    if (!app?.key) return;

    graphql(
      DUPLICATE_EMAIL_SEQUENCE,
      {
        appKey: app.key,
        id: sequence.id
      },
      {
        success: () => {
          dispatch(successMessage('Sequence duplicated'));
          fetchSequences();
        },
        error: () => {
          dispatch(errorMessage('Failed to duplicate sequence'));
        }
      }
    );
  };

  // Save sequence
  const handleSave = (formData: any) => {
    if (!app?.key) return;

    const sequenceData = {
      name: formData.name,
      description: formData.description || '',
      triggerEvent: formData.triggerEvent || 'signup',
      active: formData.active !== false,
      sequenceData: formData.sequenceData || {}
    };

    const mutation = openDialog?.id ? UPDATE_EMAIL_SEQUENCE : CREATE_EMAIL_SEQUENCE;
    const variables = openDialog?.id
      ? { appKey: app.key, id: openDialog.id, sequenceData }
      : { appKey: app.key, sequenceData };

    graphql(
      mutation,
      variables,
      {
        success: () => {
          dispatch(successMessage(`Sequence ${openDialog?.id ? 'updated' : 'created'}`));
          setOpenDialog(null);
          fetchSequences();
        },
        error: (err) => {
          console.error('Error saving sequence:', err);
          dispatch(errorMessage('Failed to save sequence'));
        }
      }
    );
  };

  // Confirm delete
  const handleConfirmDelete = () => {
    if (!app?.key || !openDeleteDialog) return;

    graphql(
      DELETE_EMAIL_SEQUENCE,
      {
        appKey: app.key,
        id: openDeleteDialog.id
      },
      {
        success: () => {
          dispatch(successMessage('Sequence deleted'));
          setOpenDeleteDialog(null);
          fetchSequences();
        },
        error: () => {
          dispatch(errorMessage('Failed to delete sequence'));
        }
      }
    );
  };

  const getTriggerEventLabel = (event: string) => {
    const labels: { [key: string]: string } = {
      signup: 'Sign Up',
      purchase: 'Purchase',
      abandon_cart: 'Abandon Cart',
      welcome: 'Welcome',
      feedback: 'Feedback',
      support: 'Support'
    };
    return labels[event] || event;
  };

  const filteredSequences = sequences.filter((sequence: any) => {
    if (filter === 'active' && !sequence.active) return false;
    if (filter === 'inactive' && sequence.active) return false;
    if (triggerFilter !== 'all' && sequence.triggerEvent !== triggerFilter) return false;
    return true;
  });

  return (
    <SequenceContainer>
      <Content>
        <ContentHeader
          title="Email Sequences"
          actions={
            <Button onClick={handleCreate} variant="contained" color="primary">
              <PlusIcon className="h-5 w-5 mr-2" />
              New Sequence
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
            <label className="block text-sm font-medium text-gray-700 mb-1">Trigger Event</label>
            <select
              value={triggerFilter}
              onChange={(e) => setTriggerFilter(e.target.value)}
              className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            >
              <option value="all">All Events</option>
              <option value="signup">Sign Up</option>
              <option value="purchase">Purchase</option>
              <option value="abandon_cart">Abandon Cart</option>
              <option value="welcome">Welcome</option>
              <option value="feedback">Feedback</option>
              <option value="support">Support</option>
            </select>
          </div>
        </div>

        {/* Sequences Grid */}
        {isLoading ? (
          <div className="p-12 text-center">
            <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
            <p className="mt-2 text-gray-500">Loading sequences...</p>
          </div>
        ) : filteredSequences.length === 0 ? (
          <EmptyView
            title="No email sequences found"
            subtitle="Create your first email sequence to automate your marketing campaigns"
            action={
              <Button onClick={handleCreate} variant="contained" color="primary">
                <PlusIcon className="h-5 w-5 mr-2" />
                Create Sequence
              </Button>
            }
          />
        ) : (
          <SequenceGrid>
            {filteredSequences.map((sequence: any) => (
              <SequenceCard
                key={sequence.id}
                active={sequence.active}
                onClick={() => {
                  setSelectedSequence(sequence);
                  history.push(`${match.url}/${sequence.id}`);
                }}
              >
                <SequenceHeader>
                  <div className="flex-1">
                    <h3 className="text-lg font-semibold text-gray-900">{sequence.name}</h3>
                    <div className="flex items-center space-x-2 mt-1">
                      {sequence.triggerEvent && (
                        <TriggerBadge event={sequence.triggerEvent}>
                          {getTriggerEventLabel(sequence.triggerEvent)}
                        </TriggerBadge>
                      )}
                      {sequence.active ? (
                        <Badge variant="success">Active</Badge>
                      ) : (
                        <Badge variant="gray">Inactive</Badge>
                      )}
                    </div>
                  </div>
                  <SwitchControl
                    checked={sequence.active}
                    onChange={() => handleToggle(sequence)}
                    onClick={(e: any) => e.stopPropagation()}
                  />
                </SequenceHeader>

                {sequence.description && (
                  <p className="text-sm text-gray-600 mb-4 line-clamp-2">
                    {sequence.description}
                  </p>
                )}

                <div className="mt-4 space-y-2">
                  <div className="flex items-center text-sm text-gray-600">
                    <EnvelopeIcon className="h-4 w-4 mr-2" />
                    {sequence.stepsCount || 0} steps
                  </div>
                  {sequence.activeExecutionsCount > 0 && (
                    <div className="flex items-center text-sm text-gray-600">
                      <UserGroupIcon className="h-4 w-4 mr-2" />
                      {sequence.activeExecutionsCount} active
                    </div>
                  )}
                </div>

                <div className="mt-4 pt-4 border-t border-gray-200 flex items-center justify-between">
                  <div className="flex items-center space-x-2">
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        handleEdit(sequence);
                      }}
                      className="p-2 text-gray-400 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                      title="Edit"
                    >
                      <PencilIcon className="h-4 w-4" />
                    </button>
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        handleDuplicate(sequence);
                      }}
                      className="p-2 text-gray-400 hover:text-green-600 hover:bg-green-50 rounded-lg transition-colors"
                      title="Duplicate"
                    >
                      <DocumentDuplicateIcon className="h-4 w-4" />
                    </button>
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        handleDelete(sequence);
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
                      setSelectedSequence(sequence);
                      // Navigate to analytics
                    }}
                    className="p-2 text-gray-400 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                    title="Analytics"
                  >
                    <ChartBarIcon className="h-4 w-4" />
                  </button>
                </div>
              </SequenceCard>
            ))}
          </SequenceGrid>
        )}

        {/* Create/Edit Dialog */}
        {openDialog && (
          <EmailSequenceDialog
            open={!!openDialog}
            sequence={openDialog}
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
            deleteHandler={handleConfirmDelete}
          >
            <p>This action cannot be undone. All sequence data and steps will be permanently deleted.</p>
          </DeleteDialog>
        )}
      </Content>
    </SequenceContainer>
  );
};

// Sequence Form Dialog Component
interface EmailSequenceDialogProps {
  open: boolean;
  sequence: any;
  onClose: () => void;
  onSave: (data: any) => void;
  app: any;
}

const EmailSequenceDialog: React.FC<EmailSequenceDialogProps> = ({
  open,
  sequence,
  onClose,
  onSave,
  app
}) => {
  const [formData, setFormData] = useState({
    name: sequence?.name || '',
    description: sequence?.description || '',
    triggerEvent: sequence?.triggerEvent || 'signup',
    active: sequence?.active !== false,
    sequenceData: sequence?.sequenceData || {}
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSave(formData);
  };

  return (
    <FormDialog
      open={open}
      handleClose={onClose}
      titleContent={sequence?.id ? 'Edit Email Sequence' : 'Create Email Sequence'}
      formComponent={
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Sequence Name
            </label>
            <input
              type="text"
              required
              value={formData.name}
              onChange={(e) => setFormData({ ...formData, name: e.target.value })}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
              placeholder="Welcome Email Sequence"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Description
            </label>
            <textarea
              rows={3}
              value={formData.description}
              onChange={(e) => setFormData({ ...formData, description: e.target.value })}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
              placeholder="Describe what this sequence does..."
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Trigger Event
            </label>
            <select
              value={formData.triggerEvent}
              onChange={(e) => setFormData({ ...formData, triggerEvent: e.target.value })}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            >
              <option value="signup">Sign Up</option>
              <option value="purchase">Purchase</option>
              <option value="abandon_cart">Abandon Cart</option>
              <option value="welcome">Welcome</option>
              <option value="feedback">Feedback</option>
              <option value="support">Support</option>
            </select>
          </div>

          <div className="flex items-center space-x-2">
            <SwitchControl
              checked={formData.active}
              onChange={(checked) => setFormData({ ...formData, active: checked })}
            />
            <label className="text-sm font-medium text-gray-700">Active</label>
          </div>

          <div className="flex justify-end space-x-3 pt-4">
            <Button onClick={onClose} variant="outlined">
              Cancel
            </Button>
            <Button type="submit" variant="contained" color="primary">
              {sequence?.id ? 'Update' : 'Create'}
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

export default connect(mapStateToProps)(withRouter(EmailSequenceManager));

