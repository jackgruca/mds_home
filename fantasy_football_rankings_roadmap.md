# Fantasy Football Draft Rankings System - Phased Implementation Plan

## Project Overview
Transform the rankings section into a comprehensive Fantasy Football expert-making platform where users can easily see position rankings, compare expert opinions, create custom rankings, and integrate with the mock draft simulator.

## Core User Flow Vision
1. **Browse Position Rankings** → See expert rankings across all positions
2. **Compare Expert Opinions** → View multiple expert rankings side-by-side
3. **Create Custom Rankings** → Adjust weights for various attributes
4. **Generate Personal Big Board** → Combine expert + custom rankings
5. **Save & Share** → Export rankings and share with community
6. **Mock Draft Integration** → Use rankings in draft simulator

---

## Phase 1: Foundation - Multi-Position Rankings Infrastructure
**Timeline: Week 1-2**
**Deliverable: Working ranking screens for all Fantasy positions**

### 1.1 Create Position-Specific Ranking Screens
- **WR Rankings Screen** (`lib/screens/rankings/wr_rankings_screen.dart`)
- **RB Rankings Screen** (`lib/screens/rankings/rb_rankings_screen.dart`)
- **TE Rankings Screen** (`lib/screens/rankings/te_rankings_screen.dart`)
- **K Rankings Screen** (`lib/screens/rankings/k_rankings_screen.dart`)
- **DEF Rankings Screen** (`lib/screens/rankings/def_rankings_screen.dart`)

Each screen should replicate the QB rankings structure with:
- Season/tier filtering
- Query builder functionality
- Sortable data table
- Tier-based color coding
- Team logo integration

### 1.2 Update Navigation Structure
- Add new position routes to `lib/main.dart`
- Update `lib/widgets/common/top_nav_bar.dart` with position-specific navigation
- Create rankings dropdown menu in navigation

### 1.3 Implement Tier Calculation Services
Create `lib/services/rankings/tier_calculation_service.dart` with methods for:
- **WR Tier Calculation** (based on target share, EPA, yards, TDs)
- **RB Tier Calculation** (based on rush share, yards, TDs, receiving)
- **TE Tier Calculation** (based on target share, red zone usage, blocking)
- **Team Tier Calculations** (pass offense, run offense, QB tiers)

### 1.4 Data Models
Create position-specific models in `lib/models/rankings/`:
- `wr_ranking.dart`
- `rb_ranking.dart`
- `te_ranking.dart`
- `team_tier.dart`

**Acceptance Criteria:**
- [ ] All 5 position ranking screens functional
- [ ] Tier calculations working and displaying correctly
- [ ] Navigation between positions seamless
- [ ] Data filtering and sorting operational

---

## Phase 2: Next Year Projections Integration
**Timeline: Week 3**
**Deliverable: 2025 projections displayed in ranking screens**

### 2.1 Projection Data Integration
Based on your R script `rec_point_preds.R`, implement:
- **Target Share Projections** (`NY_tgtShare`)
- **Run Share Projections** (`NY_runShare`)
- **Red Zone Opportunity Projections** (`NY_rzOpportunities`)
- **Team Tier Projections** (`NY_passOffenseTier`, `NY_qbTier`, etc.)

### 2.2 Projection Display
Add projection columns to each ranking screen:
- Current season stats vs. projected next year stats
- Projection confidence indicators
- Year-over-year comparison views

### 2.3 Projection Service
Create `lib/services/projections/fantasy_projections_service.dart`:
- Load projection data from CSV/Firebase
- Calculate projected fantasy points
- Handle projection updates

**Acceptance Criteria:**
- [ ] 2025 projections visible in all ranking screens
- [ ] Projection vs. current season comparison working
- [ ] Projection confidence displayed appropriately

---

## Phase 3: Custom Rankings Engine
**Timeline: Week 4-5**
**Deliverable: "Create Your Own Rankings" functionality**

### 3.1 Custom Rankings UI Components
Create `lib/widgets/rankings/custom_rankings/`:
- `custom_ranking_builder.dart` - Main ranking builder widget
- `attribute_weight_slider.dart` - Weight adjustment sliders
- `ranking_preview.dart` - Live preview of custom rankings
- `ranking_save_dialog.dart` - Save/name custom rankings

### 3.2 Attribute Weight System
Implement weighted ranking calculation with these attributes:

**For WRs:**
- Target Share (20%)
- Receiving Yards (20%)
- Receiving TDs (15%)
- Red Zone Targets (10%)
- Team Pass Offense Tier (10%)
- QB Tier (10%)
- Player Experience Tier (5%)
- EPA per Target (10%)

**For RBs:**
- Rush Share (25%)
- Rushing Yards (20%)
- Rushing TDs (15%)
- Receiving Yards (15%)
- Team Run Offense Tier (10%)
- Red Zone Carries (10%)
- Player Experience Tier (5%)

**For TEs:**
- Target Share (25%)
- Receiving Yards (20%)
- Receiving TDs (15%)
- Red Zone Targets (15%)
- Team Pass Offense Tier (10%)
- QB Tier (10%)
- Player Experience Tier (5%)

### 3.3 Custom Rankings Service
Create `lib/services/rankings/custom_rankings_service.dart`:
- Calculate weighted scores
- Save/load custom ranking configurations
- Generate custom ranking results

### 3.4 Integration with Existing Rankings
Add "Create Your Own Rankings" button to each position screen that opens custom ranking builder.

**Acceptance Criteria:**
- [ ] Custom ranking builder functional for all positions
- [ ] Weight sliders update rankings in real-time
- [ ] Custom rankings can be saved and loaded
- [ ] Custom rankings integrate with existing position screens

---

## Phase 4: Expert Rankings Integration
**Timeline: Week 6**
**Deliverable: Multi-expert ranking comparison**

### 4.1 Expert Rankings Data Structure
Create `lib/models/rankings/expert_ranking.dart`:
- Expert name/source
- Position rankings
- Ranking methodology
- Last updated timestamp

### 4.2 Expert Comparison UI
Create `lib/widgets/rankings/expert_comparison/`:
- `expert_selector.dart` - Choose which experts to compare
- `expert_comparison_table.dart` - Side-by-side expert rankings
- `consensus_calculator.dart` - Calculate consensus rankings

### 4.3 Expert Rankings Service
Create `lib/services/rankings/expert_rankings_service.dart`:
- Load expert rankings from various sources
- Calculate consensus rankings
- Handle expert ranking updates

### 4.4 Integration Points
Add expert comparison tabs to each position ranking screen.

**Acceptance Criteria:**
- [ ] Expert rankings displayed alongside site rankings
- [ ] Consensus rankings calculated correctly
- [ ] Expert comparison table functional
- [ ] Users can select which experts to include

---

## Phase 5: Personal Big Board & Consensus
**Timeline: Week 7**
**Deliverable: Combined ranking system with personal big board**

### 5.1 Big Board Generator
Create `lib/screens/rankings/personal_big_board_screen.dart`:
- Combine custom rankings with selected expert rankings
- Cross-position player comparison
- Drag-and-drop ranking adjustment
- Tier-based grouping

### 5.2 Consensus Algorithm
Implement in `lib/services/rankings/consensus_service.dart`:
- Weight user custom rankings (e.g., 40%)
- Weight selected expert rankings (e.g., 60%)
- Handle position scarcity adjustments
- Calculate Value Over Replacement (VOR)

### 5.3 VOR Calculation
Add VOR transparency features:
- Show how VOR affects rankings
- Allow users to adjust VOR baselines
- Display VOR-adjusted vs. raw point projections

**Acceptance Criteria:**
- [ ] Personal big board combines custom + expert rankings
- [ ] Consensus algorithm working correctly
- [ ] VOR calculations transparent and adjustable
- [ ] Cross-position comparisons functional

---

## Phase 6: Save, Share & Export
**Timeline: Week 8**
**Deliverable: Full ranking persistence and sharing**

### 6.1 Ranking Persistence
Create `lib/services/rankings/ranking_persistence_service.dart`:
- Save custom ranking configurations
- Save personal big boards
- Version control for ranking changes
- Export to various formats (CSV, PDF, image)

### 6.2 Sharing Features
Create `lib/widgets/rankings/sharing/`:
- `ranking_share_dialog.dart` - Share rankings with others
- `ranking_export_options.dart` - Export format selection
- `ranking_link_generator.dart` - Generate shareable links

### 6.3 Community Features
Add basic community features:
- Public ranking galleries
- Ranking performance tracking
- Community voting on rankings

**Acceptance Criteria:**
- [ ] Rankings can be saved and loaded
- [ ] Export functionality working (CSV, PDF, image)
- [ ] Shareable links generated correctly
- [ ] Community ranking features functional

---

## Phase 7: Mock Draft Integration
**Timeline: Week 9**
**Deliverable: Rankings integrated with draft simulator**

### 7.1 Draft Integration Service
Create `lib/services/draft/ranking_draft_integration_service.dart`:
- Load personal big board into draft simulator
- Update draft board based on selections
- Handle ADP vs. personal ranking differences
- Provide draft recommendations

### 7.2 Draft Board Enhancements
Update `lib/ff_draft/widgets/ff_draft_board.dart`:
- Display personal rankings alongside ADP
- Show tier breaks in draft board
- Highlight value picks based on personal rankings
- Add ranking-based draft recommendations

### 7.3 Draft Strategy Integration
Enhance draft strategy with ranking data:
- Position run predictions based on rankings
- Value-based drafting recommendations
- Tier-based draft timing suggestions

**Acceptance Criteria:**
- [ ] Personal rankings load into draft simulator
- [ ] Draft board shows personal vs. ADP rankings
- [ ] Value picks highlighted correctly
- [ ] Draft recommendations based on personal rankings

---

## Phase 8: Advanced Features & Polish
**Timeline: Week 10-11**
**Deliverable: Production-ready ranking system**

### 8.1 Advanced Analytics
Add advanced ranking features:
- Ranking accuracy tracking
- Historical ranking performance
- Injury risk integration
- Strength of schedule adjustments

### 8.2 Mobile Optimization
Ensure all ranking screens work perfectly on mobile:
- Responsive design for all screens
- Touch-friendly controls
- Optimized data tables for mobile

### 8.3 Performance Optimization
- Lazy loading for large datasets
- Caching for frequently accessed rankings
- Optimized database queries
- Progressive loading for ranking calculations

### 8.4 User Experience Polish
- Loading states for all ranking operations
- Error handling and user feedback
- Tooltips and help text
- Onboarding flow for new users

**Acceptance Criteria:**
- [ ] All features working smoothly on mobile
- [ ] Performance optimized for large datasets
- [ ] Error handling comprehensive
- [ ] User experience polished and intuitive

---

## Implementation Notes

### Data Sources
- Use existing R script outputs for projections
- Integrate with Firebase for user data persistence
- Leverage existing nflverse data structure
- Maintain consistency with current QB rankings approach

### Code Structure
- Follow existing patterns from QB rankings screen
- Reuse existing UI components where possible
- Maintain consistent styling and theming
- Use existing services architecture

### Testing Strategy
- Unit tests for ranking calculations
- Integration tests for data flow
- User acceptance testing for each phase
- Performance testing for large datasets

### Deployment Strategy
- Deploy each phase incrementally
- Feature flags for gradual rollout
- User feedback collection at each phase
- Performance monitoring throughout

This phased approach ensures steady progress while maintaining a working application at each stage. Each phase builds upon the previous one and can be tested and validated independently. 