# Testing Guide: Real-time Features

This guide provides step-by-step instructions for testing all real-time features implemented in Phase 4.

## Prerequisites

1. **Backend Setup**
   - PostgreSQL database running
   - Rails server running (`rails s` or `bin/dev`)
   - ActionCable WebSocket server running
   - Redis running (for ActionCable)

2. **Frontend Setup**
   - Node.js dependencies installed (`yarn install` or `npm install`)
   - Frontend build running (`yarn build` or `npm run build`)
   - Development server running (if using webpack-dev-server)

3. **Browser Requirements**
   - Modern browser (Chrome, Firefox, Edge, Safari)
   - Browser console open (F12)
   - Network tab open to monitor WebSocket connections

4. **Test Accounts**
   - At least 2 agent accounts
   - Test visitor sessions (can use browser incognito mode)

## 1. Testing Real-time Notifications

### Setup
1. Log in as an agent
2. Open the sidebar - you should see the notification bell icon
3. Open browser console to monitor ActionCable connections

### Test 1: Notification Center UI
**Steps:**
1. Click the bell icon in the sidebar
2. **Expected:** Dropdown opens showing "No notifications" or existing notifications
3. Check that the bell icon is visible and clickable
4. **Expected:** Dropdown closes when clicking outside or the X button

### Test 2: Browser Notification Permission
**Steps:**
1. Click the bell icon
2. Check browser console for permission request
3. **Expected:** Browser asks for notification permission (if not already granted)
4. Grant permission
5. **Expected:** Future notifications will show browser notifications

### Test 3: Real-time Notification Reception
**Steps:**
1. Open two browser windows/tabs:
   - Window 1: Logged in as Agent A
   - Window 2: Logged in as Agent B (or use incognito)
2. In Window 2, trigger a notification event (e.g., send a message, assign conversation)
3. **Expected:** In Window 1:
   - Notification appears in the dropdown
   - Unread count badge updates
   - Browser notification appears (if permission granted)
   - Notification shows correct title, message, and timestamp

### Test 4: Mark as Read
**Steps:**
1. Receive a notification
2. Click on the notification in the dropdown
3. **Expected:** 
   - Notification is marked as read (blue background disappears)
   - Unread count decreases
   - Unread dot indicator disappears

### Test 5: Mark All as Read
**Steps:**
1. Have multiple unread notifications
2. Click "Mark all read" button in notification dropdown
3. **Expected:**
   - All notifications marked as read
   - Unread count becomes 0
   - Badge disappears from bell icon

### Test 6: Delete Notification
**Steps:**
1. Have at least one notification
2. Click the X button on a notification
3. **Expected:**
   - Notification is removed from the list
   - Unread count decreases if notification was unread

### Test 7: ActionCable Connection
**Steps:**
1. Open browser console
2. Look for: `NotificationCenter: Connected to ActionCable`
3. **Expected:** Connection message appears in console
4. Check Network tab → WS (WebSocket)
5. **Expected:** WebSocket connection to ActionCable is established

### Test 8: Notification Types
**Steps:**
1. Trigger different notification types:
   - Info notification
   - Success notification
   - Warning notification
   - Error notification
2. **Expected:** Each notification shows appropriate icon and color

## 2. Testing Presence Indicators

### Setup
1. Log in as Agent A
2. Open a page that shows presence (e.g., Conversations, Team page)
3. Open browser console

### Test 1: Presence Indicator Component
**Steps:**
1. Find a component using `PresenceIndicator`
2. **Expected:** 
   - Green dot for online users
   - Gray dot for offline users
   - Yellow dot for away users
   - Red dot for busy users

### Test 2: Agent Presence List
**Steps:**
1. Navigate to a page with `AgentPresenceList` component
2. **Expected:**
   - List shows all agents
   - Online agents appear first
   - Each agent shows:
     - Avatar or placeholder
     - Name and email
     - Presence indicator dot
     - Last seen time (for offline agents)

### Test 3: Real-time Presence Updates
**Steps:**
1. Open two browser windows:
   - Window 1: Logged in as Agent A
   - Window 2: Logged in as Agent B
2. In Window 1, observe Agent B's presence status
3. In Window 2, log out or close the tab
4. **Expected:** In Window 1:
   - Agent B's status changes to offline
   - Last seen timestamp updates
   - Agent B moves to offline section

### Test 4: Agent Comes Online
**Steps:**
1. Agent B is offline
2. Agent B logs in
3. **Expected:** In Window 1:
   - Agent B's status changes to online
   - Agent B moves to online section
   - Presence dot turns green

### Test 5: Presence Channel Connection
**Steps:**
1. Open browser console
2. Look for: `AgentPresenceList: Connected to ActionCable`
3. **Expected:** Connection message appears
4. Check Network tab → WS
5. **Expected:** WebSocket connection established

### Test 6: Presence Data Structure
**Steps:**
1. Open browser console
2. Monitor ActionCable messages
3. When presence update occurs, check the data structure
4. **Expected:** Data includes:
   - `id` or `email`
   - `name` or `displayName`
   - `state` (online/offline)
   - `lastSeen` timestamp

## 3. Testing Real-time Analytics Dashboard

### Setup
1. Log in as an agent with `reports` permission
2. Navigate to `/apps/:appKey/tidio/analytics`
3. Open browser console

### Test 1: Dashboard Loads
**Steps:**
1. Navigate to analytics page
2. **Expected:**
   - Page loads without errors
   - Stats cards display (Total Visitors, Active Visitors, etc.)
   - Charts render (or show "No data available")
   - "Last updated" timestamp shows

### Test 2: Initial Data Load
**Steps:**
1. Wait for page to fully load
2. **Expected:**
   - Stats show actual numbers (not 0 unless no data)
   - Charts display data if available
   - Loading spinner disappears

### Test 3: Real-time Visitor Updates
**Steps:**
1. Open analytics dashboard
2. In another browser/incognito window, visit the website as a visitor
3. **Expected:** In analytics dashboard:
   - Active Visitors count increases
   - Total Visitors count increases
   - Charts update (if hourly data is shown)
   - "Last updated" timestamp refreshes

### Test 4: Real-time Conversation Updates
**Steps:**
1. Open analytics dashboard
2. Start a new conversation (from visitor side)
3. **Expected:** In analytics dashboard:
   - Active Conversations count increases
   - Total Conversations count increases
   - Conversion rate recalculates

### Test 5: Auto-refresh
**Steps:**
1. Open analytics dashboard
2. Wait 30 seconds
3. **Expected:**
   - Data refreshes automatically
   - "Last updated" timestamp updates
   - Stats update if there are changes

### Test 6: ActionCable Integration
**Steps:**
1. Open browser console
2. Look for: `RealtimeAnalytics: Connected to ActionCable`
3. **Expected:** Connection message appears
4. Trigger a visitor event
5. **Expected:** Console shows received data

### Test 7: Chart Rendering
**Steps:**
1. Ensure there is data (visitors, conversations)
2. **Expected:**
   - Hourly Performance chart shows line graph
   - Device Breakdown chart shows bar graph
   - Charts are interactive (hover shows values)
   - Legends are visible

### Test 8: No Data State
**Steps:**
1. Use a new app with no data
2. Navigate to analytics
3. **Expected:**
   - Stats show 0
   - Charts show "No data available" message
   - No errors in console

## 4. Testing ActionCable Connections

### Test 1: Connection Establishment
**Steps:**
1. Open browser console
2. Log in to the application
3. **Expected:** Console shows:
   - `Connected to events`
   - `Connected to agent events`
   - Component-specific connection messages

### Test 2: WebSocket Connection
**Steps:**
1. Open Network tab → WS filter
2. **Expected:** See WebSocket connection(s) to ActionCable
3. Check connection status:
   - Status: 101 Switching Protocols (successful)
   - Messages tab shows ping/pong frames

### Test 3: Disconnection Handling
**Steps:**
1. Establish connection
2. Disconnect network (or stop Redis/ActionCable server)
3. **Expected:**
   - Console shows disconnection messages
   - Components handle disconnection gracefully
   - No errors or crashes

### Test 4: Reconnection
**Steps:**
1. Disconnect network
2. Reconnect network
3. **Expected:**
   - Connection automatically re-establishes
   - Components resume receiving updates
   - No duplicate subscriptions

### Test 5: Multiple Subscriptions
**Steps:**
1. Open multiple pages with real-time features
2. Check console and Network tab
3. **Expected:**
   - Each component has its own subscription
   - No subscription conflicts
   - All subscriptions work independently

## 5. Testing Performance Optimizations

### Test 1: Virtual Scrolling
**Steps:**
1. Navigate to a page with a large list (1000+ items)
2. Open browser DevTools → Performance
3. Record performance while scrolling
4. **Expected:**
   - Only visible items are rendered
   - Smooth scrolling (60fps)
   - Low memory usage
   - Check Elements tab - only ~20 DOM nodes for list items

### Test 2: Lazy Loading
**Steps:**
1. Navigate to a page using lazy loading
2. Open Network tab
3. Scroll to bottom of list
4. **Expected:**
   - Initial load only fetches first batch
   - More items load as you scroll
   - Network requests triggered on scroll
   - Loading indicator shows during fetch

### Test 3: Intersection Observer
**Steps:**
1. Use a page with lazy loading
2. Scroll slowly to bottom
3. **Expected:**
   - Load trigger happens before reaching bottom
   - Smooth loading experience
   - No jarring content jumps

## 6. Integration Testing

### Test 1: Multiple Real-time Features Together
**Steps:**
1. Open application with all features:
   - Notification center
   - Presence indicators
   - Real-time analytics
   - Visitor tracking
   - Tidio inbox
2. **Expected:**
   - All features work simultaneously
   - No conflicts between subscriptions
   - Performance remains good

### Test 2: Cross-tab Communication
**Steps:**
1. Open same app in multiple tabs
2. Trigger events in one tab
3. **Expected:** Other tabs receive updates via ActionCable

### Test 3: Browser Refresh
**Steps:**
1. Have real-time features active
2. Refresh browser
3. **Expected:**
   - All subscriptions re-establish
   - Data reloads correctly
   - No memory leaks

## 7. Error Handling Tests

### Test 1: Backend Unavailable
**Steps:**
1. Stop Rails server or ActionCable
2. Try to use real-time features
3. **Expected:**
   - Graceful error handling
   - User-friendly error messages
   - No application crashes

### Test 2: Network Interruption
**Steps:**
1. Use real-time features
2. Disconnect network mid-operation
3. **Expected:**
   - Features handle disconnection
   - Reconnection attempts
   - No data loss

### Test 3: Invalid Data
**Steps:**
1. Send malformed data via ActionCable (requires backend modification)
2. **Expected:**
   - Components handle invalid data gracefully
   - Errors logged to console
   - Application continues functioning

## 8. Browser Compatibility Tests

### Test in Multiple Browsers
**Steps:**
1. Test in Chrome
2. Test in Firefox
3. Test in Safari
4. Test in Edge
5. **Expected:** All features work in all browsers

## 9. Mobile Testing

### Test on Mobile Devices
**Steps:**
1. Open application on mobile browser
2. Test all real-time features
3. **Expected:**
   - Features work on mobile
   - Touch interactions work
   - Performance is acceptable
   - Notifications work (if supported)

## 10. Performance Benchmarks

### Measure Performance
**Steps:**
1. Open Chrome DevTools → Performance
2. Record session while using real-time features
3. Check metrics:
   - FPS (should be 60fps)
   - Memory usage (should be stable)
   - CPU usage (should be reasonable)
   - Network usage (WebSocket overhead)

## Troubleshooting

### Common Issues

1. **Notifications not appearing**
   - Check ActionCable connection in console
   - Verify backend is broadcasting events
   - Check notification permission in browser

2. **Presence not updating**
   - Verify PresenceChannel is broadcasting
   - Check agent online status in database
   - Check ActionCable subscription

3. **Analytics not updating**
   - Verify visitor events are being tracked
   - Check GraphQL queries are working
   - Verify ActionCable events are received

4. **WebSocket connection fails**
   - Check Redis is running
   - Verify ActionCable URL in meta tag
   - Check CORS settings
   - Verify access token is valid

5. **Performance issues**
   - Check for memory leaks (use Chrome DevTools Memory profiler)
   - Verify virtual scrolling is working
   - Check for unnecessary re-renders

## Test Checklist

Use this checklist to ensure all features are tested:

- [ ] Notification center UI works
- [ ] Browser notifications work
- [ ] Real-time notifications received
- [ ] Mark as read works
- [ ] Mark all as read works
- [ ] Delete notification works
- [ ] Presence indicators display correctly
- [ ] Real-time presence updates work
- [ ] Analytics dashboard loads
- [ ] Real-time analytics updates work
- [ ] Charts render correctly
- [ ] ActionCable connections establish
- [ ] WebSocket connections work
- [ ] Disconnection handling works
- [ ] Reconnection works
- [ ] Virtual scrolling works
- [ ] Lazy loading works
- [ ] Multiple features work together
- [ ] Error handling works
- [ ] Browser compatibility verified
- [ ] Mobile compatibility verified
- [ ] Performance is acceptable

## Backend Testing Requirements

To fully test real-time features, the backend needs to broadcast events. Here's what needs to be tested on the backend:

1. **Notification Broadcasting**
   - Test broadcasting notifications via ActionCable
   - Verify EventsChannel receives notifications
   - Test different notification types

2. **Presence Broadcasting**
   - Test broadcasting presence updates
   - Verify PresenceChannel works
   - Test agent online/offline status

3. **Visitor Event Broadcasting**
   - Test broadcasting visitor:new events
   - Test broadcasting visitor:update events
   - Test broadcasting visitor:offline events

4. **Conversation Event Broadcasting**
   - Test broadcasting conversation_part events
   - Test broadcasting conversations:update_state events
   - Test broadcasting conversations:typing events

## Next Steps After Testing

1. **Fix any bugs found**
2. **Optimize performance if needed**
3. **Add more test coverage**
4. **Document any issues**
5. **Create automated tests**

