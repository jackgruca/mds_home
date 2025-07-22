# Custom VORP Big Board System - Product Requirements Document

## Project Overview
Create a comprehensive custom ranking and VORP-based big board system that allows users to create personalized rankings, generate VORP calculations, and integrate these into the consensus system with full mock draft integration.

## User Journey Flow
1. **Consensus Big Board** → View and customize platform weights
2. **Position Rankings** → Create custom rankings per position with drag-and-drop
3. **Saved Custom Rankings** → Manage all custom positional rankings
4. **Custom Big Board Creation** → Generate VORP-based big board from custom rankings
5. **Consensus Integration** → Include custom rankings in weighted consensus
6. **Mock Draft Integration** → Use any ranking system for draft simulation

## Phase 1: Enhanced Position Rankings Management

### 1.1 Custom Position Rankings Screen Enhancement
**Location**: Extend on the QB/RB/WR/TE final ranking screen in the 'Custom Rankings Builder'

**Features**:
- Add "Save Custom Rankings" button to each position screen
- Drag-and-drop reordering functionality (position level only)
- Manual rank input capability
- Real-time VORP and points calculation display
- User naming for custom ranking sets

**Technical Requirements**:
- Extend existing final ranking screens with drag-and-drop capability
- Add save functionality with user-defined names
- Integrate VORP preview calculations
- localStorage persistence for MVP

**Deliverables**:
- Enhanced final ranking screens with save functionality
- Drag-and-drop reordering component
- VORP preview in position screens
- Custom ranking naming system

### 1.2 Saved Custom Rankings Management Section
**Location**: New navigation section "My Rankings"

**Features**:
- Dashboard showing all saved position rankings
- Last modified dates and ranking counts
- Quick preview of top players per position
- Edit/Delete functionality for saved rankings
- "Create Custom Big Board" master button
- User-friendly naming and organization

**Technical Requirements**:
- New navigation route and screen
- CRUD operations for custom rankings
- localStorage data management
- Integration with existing navigation system

**Deliverables**:
- New "My Rankings" screen/section
- Rankings management dashboard
- CRUD operations for saved rankings

## Phase 2: Custom Big Board Generation

### 2.1 Custom Big Board Screen
**Location**: New screen accessible from "My Rankings"

**Features**:
- Aggregate view of all custom position rankings
- VORP calculations based on custom ranks
- Real-time point projections and VORP updates
- Save functionality for complete custom big board

**Technical Requirements**:
- Convert custom position ranks to projected points
- Calculate VORP using HistoricalPointsService
- Generate VORPBigBoard from custom rankings
- Integration with existing VORP calculation services

**Deliverables**:
- Custom Big Board screen
- Integration with VORP calculation services
- Real-time VORP calculations

## Phase 3: Consensus Integration & Weight Management

### 3.1 Enhanced Weight System
**Location**: Existing big board weight adjustment panel

**Features**:
- Add "My Custom Rankings" as new weight option
- Default equal weights for all platforms including custom
- Dynamic weight adjustment including custom rankings
- Auto-recalculation of consensus when custom rankings included

**Technical Requirements**:
- Extend CustomWeightConfig to include user rankings
- Modify consensus calculation to include custom data
- Update WeightAdjustmentPanel UI

**Deliverables**:
- Enhanced weight configuration system
- Updated consensus calculation logic
- UI updates for custom ranking weights

### 3.2 Consensus Big Board Enhancement
**Location**: Existing big board screen

**Features**:
- Auto-inclusion of custom rankings in consensus
- Visual indicator when custom rankings are active
- Seamless integration with existing VORP mode
- Export functionality including custom data

**Deliverables**:
- Enhanced consensus calculation
- UI indicators for custom ranking inclusion
- Updated export functionality

## Phase 4: Mock Draft Integration

### 4.1 Ranking System Selection
**Location**: Mock draft simulator

**Features**:
- Dropdown to select ranking system:
  - Consensus (platform-weighted)
  - Consensus + Custom (with custom rankings)
  - Custom VORP Only
  - Individual platforms (ESPN, PFF, etc.)
- Preview of selected ranking system
- Draft recommendations based on selected system

**Technical Requirements**:
- Integration with all ranking calculation systems
- Draft logic based on selected ranking methodology
- Real-time ranking system switching

**Deliverables**:
- Ranking system selector component
- Mock draft integration
- Recommendation engine updates

## Technical Architecture

### Data Models
```dart
class CustomPositionRanking {
  final String id;
  final String userId; // for future auth
  final String position;
  final String name;
  final List<CustomPlayerRank> playerRanks;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class CustomPlayerRank {
  final String playerId;
  final String playerName;
  final int customRank;
  final double projectedPoints;
  final double vorp;
}

class CustomBigBoard {
  final String id;
  final String name;
  final Map<String, CustomPositionRanking> positionRankings;
  final List<VORPBigBoardPlayer> aggregatedPlayers;
  final DateTime createdAt;
}
```

### Services
1. **CustomRankingService**
   - CRUD operations for custom rankings
   - localStorage persistence
   - Integration with VORP calculations

2. **Enhanced VORPService**
   - Support for custom ranking input
   - Hybrid calculation methods

### UI Components
1. **DragDropRankingList**
   - Reorderable player list
   - Real-time updates
   - Manual rank input

2. **CustomRankingsDashboard**
   - Management interface
   - Quick actions
   - Create big board functionality

3. **SaveRankingDialog**
   - Name input for custom rankings
   - Save confirmation

## Data Persistence (Phase 1 - Local Storage)
- Use browser localStorage for MVP
- JSON serialization of custom rankings
- Dummy save buttons with success feedback
- Migration path planned for user authentication

## Success Metrics
1. Users can create and save custom position rankings with names
2. Drag-and-drop reordering works smoothly on position screens
3. VORP calculations update in real-time
4. Custom rankings are properly saved and retrievable
5. Management dashboard provides clear overview

## Implementation Priority
1. **Phase 1**: Custom rankings creation and management ← **CURRENT PHASE**
2. **Phase 2**: Custom big board generation
3. **Phase 3**: Consensus integration
4. **Phase 4**: Mock draft integration

## Phase 1 Detailed Implementation Plan

### Step 1: Data Models and Services
- Create CustomPositionRanking and related models
- Implement CustomRankingService with localStorage
- Add CRUD operations

### Step 2: Enhanced Position Screens
- Add drag-and-drop functionality to existing ranking screens
- Implement save dialog with naming
- Add VORP preview calculations
- Integrate with CustomRankingService

### Step 3: My Rankings Dashboard
- Create new navigation section
- Build management dashboard
- Implement edit/delete functionality
- Add "Create Custom Big Board" button (placeholder for Phase 2)

### Step 4: Testing and Polish
- Test drag-and-drop across all position screens
- Validate localStorage persistence
- Ensure VORP calculations are accurate
- Polish UI/UX

## Technical Notes
- Leverage existing VORP calculation services
- Maintain compatibility with current weight customization
- Ensure smooth integration with existing navigation
- Plan for future authentication integration

---

**Status**: Ready for Phase 1 Implementation
**Timeline**: Phase 1 estimated at 3-4 development sessions
**Next**: Begin with data models and services implementation