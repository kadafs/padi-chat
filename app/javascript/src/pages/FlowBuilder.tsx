import React, { useState, useCallback, useRef, useEffect } from 'react';
import ReactFlow, {
  Node,
  Edge,
  addEdge,
  Background,
  Controls,
  MiniMap,
  useNodesState,
  useEdgesState,
  Connection,
  NodeTypes,
  ReactFlowProvider,
  MarkerType,
  Position
} from 'reactflow';
import 'reactflow/dist/style.css';
import { connect } from 'react-redux';
import styled from '@emotion/styled';
import tw from 'twin.macro';
import graphql from '@chaskiq/store/src/graphql/client';
import { FLOWS, FLOW } from '@chaskiq/store/src/graphql/queries';
import { CREATE_FLOW, UPDATE_FLOW, DELETE_FLOW } from '@chaskiq/store/src/graphql/mutations';
import {
  PlusIcon,
  PlayIcon,
  PauseIcon,
  TrashIcon,
  DocumentDuplicateIcon,
  Cog6ToothIcon,
  ChatBubbleLeftIcon,
  QuestionMarkCircleIcon,
  BoltIcon,
  ClockIcon,
  LinkIcon,
  FlagIcon
} from '@heroicons/react/24/outline';

// Styled components
const FlowBuilderContainer = styled.div`
  ${tw`h-full flex flex-col bg-gray-50`}
`;

const Toolbar = styled.div`
  ${tw`bg-white border-b border-gray-200 px-6 py-4 flex items-center justify-between`}
`;

const FlowCanvas = styled.div`
  ${tw`flex-1 relative`}
`;

const NodePalette = styled.div`
  ${tw`absolute top-4 left-4 bg-white rounded-lg shadow-lg border border-gray-200 p-4 z-10 w-64`}
`;

const NodePaletteItem = styled.div`
  ${tw`flex items-center space-x-3 p-3 hover:bg-gray-50 rounded-lg cursor-pointer border border-transparent hover:border-gray-200 transition-all`}
`;

const SettingsPanel = styled.div<{ isOpen: boolean }>`
  ${tw`absolute top-0 right-0 h-full bg-white border-l border-gray-200 transition-transform duration-300 z-20`}
  width: 400px;
  transform: translateX(${props => props.isOpen ? '0' : '100%'});
`;

// Custom node components
const MessageNode: React.FC<any> = ({ data }) => (
  <div className="bg-blue-500 text-white p-4 rounded-lg min-w-[200px] border-2 border-blue-600">
    <div className="flex items-center space-x-2 mb-2">
      <ChatBubbleLeftIcon className="h-5 w-5" />
      <span className="font-medium">Message</span>
    </div>
    <p className="text-sm opacity-90">{data.content || 'Click to edit message...'}</p>
    <div className="mt-2 flex justify-end">
      <button 
        onClick={() => data.onEdit?.(data)}
        className="text-blue-100 hover:text-white text-sm"
      >
        Edit
      </button>
    </div>
  </div>
);

const QuestionNode: React.FC<any> = ({ data }) => (
  <div className="bg-purple-500 text-white p-4 rounded-lg min-w-[200px] border-2 border-purple-600">
    <div className="flex items-center space-x-2 mb-2">
      <QuestionMarkCircleIcon className="h-5 w-5" />
      <span className="font-medium">Question</span>
    </div>
    <p className="text-sm opacity-90">{data.question || 'Click to edit question...'}</p>
    {data.options && (
      <div className="mt-2 space-y-1">
        {data.options.map((option: any, idx: number) => (
          <div key={idx} className="text-xs bg-purple-400 px-2 py-1 rounded">
            {option.text}
          </div>
        ))}
      </div>
    )}
    <div className="mt-2 flex justify-end">
      <button 
        onClick={() => data.onEdit?.(data)}
        className="text-purple-100 hover:text-white text-sm"
      >
        Edit
      </button>
    </div>
  </div>
);

const ConditionNode: React.FC<any> = ({ data }) => (
  <div className="bg-yellow-500 text-white p-4 rounded-lg min-w-[200px] border-2 border-yellow-600">
    <div className="flex items-center space-x-2 mb-2">
      <BoltIcon className="h-5 w-5" />
      <span className="font-medium">Condition</span>
    </div>
    <p className="text-sm opacity-90">
      {data.condition ? `If ${data.condition.field} ${data.condition.operator} ${data.condition.value}` : 'Click to edit condition...'}
    </p>
    <div className="mt-2 flex justify-end">
      <button 
        onClick={() => data.onEdit?.(data)}
        className="text-yellow-100 hover:text-white text-sm"
      >
        Edit
      </button>
    </div>
  </div>
);

const ActionNode: React.FC<any> = ({ data }) => (
  <div className="bg-green-500 text-white p-4 rounded-lg min-w-[200px] border-2 border-green-600">
    <div className="flex items-center space-x-2 mb-2">
      <Cog6ToothIcon className="h-5 w-5" />
      <span className="font-medium">Action</span>
    </div>
    <p className="text-sm opacity-90">{data.action || 'Click to configure action...'}</p>
    <div className="mt-2 flex justify-end">
      <button 
        onClick={() => data.onEdit?.(data)}
        className="text-green-100 hover:text-white text-sm"
      >
        Edit
      </button>
    </div>
  </div>
);

const WaitNode: React.FC<any> = ({ data }) => (
  <div className="bg-orange-500 text-white p-4 rounded-lg min-w-[200px] border-2 border-orange-600">
    <div className="flex items-center space-x-2 mb-2">
      <ClockIcon className="h-5 w-5" />
      <span className="font-medium">Wait</span>
    </div>
    <p className="text-sm opacity-90">
      Wait {data.duration || '5'} seconds
    </p>
    <div className="mt-2 flex justify-end">
      <button 
        onClick={() => data.onEdit?.(data)}
        className="text-orange-100 hover:text-white text-sm"
      >
        Edit
      </button>
    </div>
  </div>
);

const WebhookNode: React.FC<any> = ({ data }) => (
  <div className="bg-indigo-500 text-white p-4 rounded-lg min-w-[200px] border-2 border-indigo-600">
    <div className="flex items-center space-x-2 mb-2">
      <LinkIcon className="h-5 w-5" />
      <span className="font-medium">Webhook</span>
    </div>
    <p className="text-sm opacity-90">{data.url || 'Click to configure webhook...'}</p>
    <div className="mt-2 flex justify-end">
      <button 
        onClick={() => data.onEdit?.(data)}
        className="text-indigo-100 hover:text-white text-sm"
      >
        Edit
      </button>
    </div>
  </div>
);

const EndNode: React.FC<any> = ({ data }) => (
  <div className="bg-red-500 text-white p-4 rounded-lg min-w-[200px] border-2 border-red-600">
    <div className="flex items-center space-x-2 mb-2">
      <FlagIcon className="h-5 w-5" />
      <span className="font-medium">End</span>
    </div>
    <p className="text-sm opacity-90">Flow ends here</p>
  </div>
);

const nodeTypes: NodeTypes = {
  messageNode: MessageNode,
  questionNode: QuestionNode,
  conditionNode: ConditionNode,
  actionNode: ActionNode,
  waitNode: WaitNode,
  webhookNode: WebhookNode,
  endNode: EndNode
};

interface FlowBuilderProps {
  app: any;
  flowData?: any;
  onSave?: (flowData: any) => void;
}

const FlowBuilder: React.FC<FlowBuilderProps> = ({ app, flowData: initialFlowData, onSave }) => {
  const [nodes, setNodes, onNodesChange] = useNodesState([]);
  const [edges, setEdges, onEdgesChange] = useEdgesState([]);
  const [selectedNode, setSelectedNode] = useState<Node | null>(null);
  const [showPalette, setShowPalette] = useState(true);
  const [showSettings, setShowSettings] = useState(false);
  const [isPlaying, setIsPlaying] = useState(false);
  const [flowName, setFlowName] = useState('New Flow');
  const [currentFlowId, setCurrentFlowId] = useState<string | null>(null);
  const [isSaving, setIsSaving] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const reactFlowWrapper = useRef<HTMLDivElement>(null);
  const [reactFlowInstance, setReactFlowInstance] = useState<any>(null);

  // Fetch flows list
  const fetchFlows = () => {
    if (!app?.key) return;
    
    setIsLoading(true);
    graphql(
      FLOWS,
      {
        appKey: app.key
      },
      {
        success: (data) => {
          const flows = data.flows || [];
          // If we have a flow ID in URL or props, load it
          // Otherwise, just show the list or create new
          setIsLoading(false);
        },
        error: (err) => {
          console.error('Error fetching flows:', err);
          setIsLoading(false);
        }
      }
    );
  };

  // Load a specific flow
  const loadFlow = (flowId: string) => {
    if (!app?.key || !flowId) return;
    
    setIsLoading(true);
    graphql(
      FLOW,
      {
        appKey: app.key,
        id: flowId
      },
      {
        success: (data) => {
          const flow = data.flow;
          if (flow) {
            setCurrentFlowId(flow.id);
            setFlowName(flow.name || 'New Flow');
            // Parse flow data - adjust based on actual structure
            const flowData = typeof flow.flowData === 'string' 
              ? JSON.parse(flow.flowData) 
              : flow.flowData || {};
            setNodes(flowData.nodes || flow.nodes || []);
            setEdges(flowData.edges || flow.edges || flow.connections || []);
          }
          setIsLoading(false);
        },
        error: (err) => {
          console.error('Error loading flow:', err);
          setIsLoading(false);
        }
      }
    );
  };

  // Initialize with existing flow data or create new
  useEffect(() => {
    if (initialFlowData) {
      setNodes(initialFlowData.nodes || []);
      setEdges(initialFlowData.edges || []);
      setFlowName(initialFlowData.name || 'New Flow');
      if (initialFlowData.id) {
        setCurrentFlowId(initialFlowData.id);
      }
    } else if (app?.key) {
      // Check if there's a flow ID in the URL or load from props
      // For now, create initial start node
      const startNode: Node = {
        id: 'start',
        type: 'input',
        position: { x: 250, y: 100 },
        data: { 
          label: 'Flow Start',
          content: 'When this flow is triggered...'
        },
        style: { 
          background: '#10b981', 
          color: 'white', 
          border: '2px solid #059669',
          borderRadius: '8px'
        }
      };
      setNodes([startNode]);
    }
  }, [initialFlowData, app?.key, setNodes, setEdges]);

  const onConnect = useCallback(
    (params: Connection) => {
      const edge = {
        ...params,
        markerEnd: {
          type: MarkerType.ArrowClosed,
          color: '#6b7280'
        },
        style: { stroke: '#6b7280' }
      };
      setEdges((eds) => addEdge(edge, eds));
    },
    [setEdges]
  );

  const onDragOver = useCallback((event: React.DragEvent) => {
    event.preventDefault();
    event.dataTransfer.dropEffect = 'move';
  }, []);

  const onDrop = useCallback(
    (event: React.DragEvent) => {
      event.preventDefault();

      const reactFlowBounds = reactFlowWrapper.current?.getBoundingClientRect();
      const type = event.dataTransfer.getData('application/reactflow');

      if (typeof type === 'undefined' || !type || !reactFlowBounds) {
        return;
      }

      const position = reactFlowInstance.project({
        x: event.clientX - reactFlowBounds.left,
        y: event.clientY - reactFlowBounds.top,
      });

      const newNode: Node = {
        id: `${type}_${Date.now()}`,
        type,
        position,
        data: { 
          label: type,
          onEdit: (nodeData: any) => {
            setSelectedNode(nodes.find(n => n.data === nodeData) || null);
            setShowSettings(true);
          }
        },
        sourcePosition: Position.Right,
        targetPosition: Position.Left
      };

      setNodes((nds) => nds.concat(newNode));
    },
    [reactFlowInstance, nodes, setNodes]
  );

  const onDragStart = (event: React.DragEvent, nodeType: string) => {
    event.dataTransfer.setData('application/reactflow', nodeType);
    event.dataTransfer.effectAllowed = 'move';
  };

  const handleSave = () => {
    if (!app?.key || isSaving) return;
    
    setIsSaving(true);
    const flowData = {
      name: flowName,
      description: '',
      active: true,
      flowData: {
        nodes,
        edges
      },
      triggers: {}
    };
    
    const mutation = currentFlowId ? UPDATE_FLOW : CREATE_FLOW;
    const variables = currentFlowId
      ? {
          appKey: app.key,
          id: currentFlowId,
          flowData: flowData
        }
      : {
          appKey: app.key,
          flowData: flowData
        };
    
    graphql(
      mutation,
      variables,
      {
        success: (data) => {
          const savedFlow = currentFlowId 
            ? data.updateFlow?.flow 
            : data.createFlow?.flow;
          
          if (savedFlow) {
            setCurrentFlowId(savedFlow.id);
            onSave?.(savedFlow);
            console.log('Flow saved:', savedFlow);
          }
          setIsSaving(false);
        },
        error: (err) => {
          console.error('Error saving flow:', err);
          setIsSaving(false);
        }
      }
    );
  };

  const handlePlay = () => {
    setIsPlaying(!isPlaying);
    // TODO: Implement flow testing/preview
    console.log('Testing flow...');
  };

  const handleNodeClick = (event: React.MouseEvent, node: Node) => {
    setSelectedNode(node);
    setShowSettings(true);
  };

  const deleteSelectedNode = () => {
    if (selectedNode) {
      setNodes((nds) => nds.filter(n => n.id !== selectedNode.id));
      setEdges((eds) => eds.filter(e => e.source !== selectedNode.id && e.target !== selectedNode.id));
      setSelectedNode(null);
      setShowSettings(false);
    }
  };

  const duplicateSelectedNode = () => {
    if (selectedNode) {
      const newNode: Node = {
        ...selectedNode,
        id: `${selectedNode.id}_copy_${Date.now()}`,
        position: {
          x: selectedNode.position.x + 50,
          y: selectedNode.position.y + 50
        }
      };
      setNodes((nds) => [...nds, newNode]);
    }
  };

  const nodeItems = [
    { type: 'messageNode', label: 'Message', icon: ChatBubbleLeftIcon, color: 'bg-blue-500' },
    { type: 'questionNode', label: 'Question', icon: QuestionMarkCircleIcon, color: 'bg-purple-500' },
    { type: 'conditionNode', label: 'Condition', icon: BoltIcon, color: 'bg-yellow-500' },
    { type: 'actionNode', label: 'Action', icon: Cog6ToothIcon, color: 'bg-green-500' },
    { type: 'waitNode', label: 'Wait', icon: ClockIcon, color: 'bg-orange-500' },
    { type: 'webhookNode', label: 'Webhook', icon: LinkIcon, color: 'bg-indigo-500' },
    { type: 'endNode', label: 'End', icon: FlagIcon, color: 'bg-red-500' }
  ];

  return (
    <ReactFlowProvider>
      <FlowBuilderContainer>
        <Toolbar>
          <div className="flex items-center space-x-4">
            <input
              type="text"
              value={flowName}
              onChange={(e) => setFlowName(e.target.value)}
              className="text-xl font-semibold bg-transparent border-none outline-none focus:bg-white focus:border focus:border-gray-300 focus:rounded px-2 py-1"
            />
            <span className="text-sm text-gray-500">
              {nodes.length} nodes • {edges.length} connections
              {isLoading && ' • Loading...'}
            </span>
          </div>
          
          <div className="flex items-center space-x-3">
            <button
              onClick={() => setShowPalette(!showPalette)}
              className="px-3 py-2 text-sm bg-gray-100 hover:bg-gray-200 rounded-lg transition-colors"
            >
              <PlusIcon className="h-4 w-4" />
            </button>
            
            <button
              onClick={handlePlay}
              className={`px-4 py-2 text-sm font-medium rounded-lg transition-colors ${
                isPlaying 
                  ? 'bg-red-600 text-white hover:bg-red-700' 
                  : 'bg-green-600 text-white hover:bg-green-700'
              }`}
            >
              {isPlaying ? (
                <>
                  <PauseIcon className="h-4 w-4 inline mr-1" />
                  Stop Test
                </>
              ) : (
                <>
                  <PlayIcon className="h-4 w-4 inline mr-1" />
                  Test Flow
                </>
              )}
            </button>
            
            <button
              onClick={handleSave}
              disabled={isSaving}
              className="px-4 py-2 text-sm font-medium bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isSaving ? 'Saving...' : 'Save Flow'}
            </button>
          </div>
        </Toolbar>
        
        <FlowCanvas ref={reactFlowWrapper}>
          <ReactFlow
            nodes={nodes}
            edges={edges}
            onNodesChange={onNodesChange}
            onEdgesChange={onEdgesChange}
            onConnect={onConnect}
            onInit={setReactFlowInstance}
            onDrop={onDrop}
            onDragOver={onDragOver}
            onNodeClick={handleNodeClick}
            nodeTypes={nodeTypes}
            fitView
            className="bg-gray-50"
          >
            <Background color="#e5e7eb" gap={20} />
            <Controls />
            <MiniMap 
              nodeColor={(node) => {
                switch (node.type) {
                  case 'messageNode': return '#3b82f6';
                  case 'questionNode': return '#8b5cf6';
                  case 'conditionNode': return '#eab308';
                  case 'actionNode': return '#10b981';
                  case 'waitNode': return '#f97316';
                  case 'webhookNode': return '#6366f1';
                  case 'endNode': return '#ef4444';
                  default: return '#6b7280';
                }
              }}
              maskColor="rgba(0, 0, 0, 0.1)"
              className="bg-white border border-gray-200 rounded-lg"
            />
          </ReactFlow>
          
          {showPalette && (
            <NodePalette>
              <h3 className="text-sm font-medium text-gray-900 mb-3">Add Node</h3>
              <div className="space-y-2">
                {nodeItems.map((item) => {
                  const Icon = item.icon;
                  return (
                    <NodePaletteItem
                      key={item.type}
                      onDragStart={(event) => onDragStart(event, item.type)}
                      draggable
                    >
                      <div className={`p-2 rounded-lg ${item.color} text-white`}>
                        <Icon className="h-5 w-5" />
                      </div>
                      <span className="text-sm font-medium text-gray-900">{item.label}</span>
                    </NodePaletteItem>
                  );
                })}
              </div>
            </NodePalette>
          )}
        </FlowCanvas>
        
        <SettingsPanel isOpen={showSettings}>
          <div className="h-full flex flex-col">
            <div className="p-6 border-b border-gray-200">
              <div className="flex items-center justify-between">
                <h3 className="text-lg font-medium text-gray-900">
                  {selectedNode ? 'Edit Node' : 'Node Settings'}
                </h3>
                <button
                  onClick={() => setShowSettings(false)}
                  className="text-gray-400 hover:text-gray-600"
                >
                  ×
                </button>
              </div>
            </div>
            
            <div className="flex-1 overflow-y-auto p-6">
              {selectedNode ? (
                <div className="space-y-6">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Node Type
                    </label>
                    <p className="text-sm text-gray-900 bg-gray-100 px-3 py-2 rounded">
                      {selectedNode.type}
                    </p>
                  </div>
                  
                  {selectedNode.type === 'messageNode' && (
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        Message Content
                      </label>
                      <textarea
                        className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                        rows={4}
                        placeholder="Enter your message..."
                        value={selectedNode.data.content || ''}
                        onChange={(e) => {
                          const updatedNode = {
                            ...selectedNode,
                            data: { ...selectedNode.data, content: e.target.value }
                          };
                          setSelectedNode(updatedNode);
                          setNodes(nds => nds.map(n => n.id === selectedNode.id ? updatedNode : n));
                        }}
                      />
                    </div>
                  )}
                  
                  {selectedNode.type === 'questionNode' && (
                    <div className="space-y-4">
                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-2">
                          Question Text
                        </label>
                        <textarea
                          className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                          rows={3}
                          placeholder="What would you like to ask?"
                          value={selectedNode.data.question || ''}
                          onChange={(e) => {
                            const updatedNode = {
                              ...selectedNode,
                              data: { ...selectedNode.data, question: e.target.value }
                            };
                            setSelectedNode(updatedNode);
                            setNodes(nds => nds.map(n => n.id === selectedNode.id ? updatedNode : n));
                          }}
                        />
                      </div>
                      
                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-2">
                          Answer Options
                        </label>
                        <div className="space-y-2">
                          {(selectedNode.data.options || []).map((option: any, idx: number) => (
                            <input
                              key={idx}
                              type="text"
                              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                              value={option.text}
                              onChange={(e) => {
                                const newOptions = [...(selectedNode.data.options || [])];
                                newOptions[idx] = { ...option, text: e.target.value };
                                const updatedNode = {
                                  ...selectedNode,
                                  data: { ...selectedNode.data, options: newOptions }
                                };
                                setSelectedNode(updatedNode);
                                setNodes(nds => nds.map(n => n.id === selectedNode.id ? updatedNode : n));
                              }}
                            />
                          ))}
                          <button
                            onClick={() => {
                              const newOptions = [...(selectedNode.data.options || []), { text: '', value: '' }];
                              const updatedNode = {
                                ...selectedNode,
                                data: { ...selectedNode.data, options: newOptions }
                              };
                              setSelectedNode(updatedNode);
                              setNodes(nds => nds.map(n => n.id === selectedNode.id ? updatedNode : n));
                            }}
                            className="w-full px-3 py-2 border-2 border-dashed border-gray-300 rounded-lg text-sm text-gray-500 hover:border-gray-400"
                          >
                            + Add Option
                          </button>
                        </div>
                      </div>
                    </div>
                  )}
                  
                  <div className="flex space-x-3 pt-4 border-t border-gray-200">
                    <button
                      onClick={duplicateSelectedNode}
                      className="flex-1 px-4 py-2 text-sm font-medium text-gray-700 bg-gray-100 border border-gray-300 rounded-lg hover:bg-gray-200"
                    >
                      <DocumentDuplicateIcon className="h-4 w-4 inline mr-1" />
                      Duplicate
                    </button>
                    <button
                      onClick={deleteSelectedNode}
                      className="flex-1 px-4 py-2 text-sm font-medium text-white bg-red-600 rounded-lg hover:bg-red-700"
                    >
                      <TrashIcon className="h-4 w-4 inline mr-1" />
                      Delete
                    </button>
                  </div>
                </div>
              ) : (
                <div className="text-center text-gray-500">
                  <Cog6ToothIcon className="mx-auto h-12 w-12 text-gray-400 mb-4" />
                  <p>Select a node to edit its properties</p>
                </div>
              )}
            </div>
          </div>
        </SettingsPanel>
      </FlowBuilderContainer>
    </ReactFlowProvider>
  );
};

const mapStateToProps = (state: any) => ({
  app: state.app
});

export default connect(mapStateToProps)(FlowBuilder);