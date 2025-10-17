# System Analytics - Quick Reference Guide

## 📊 Overview
This document provides a quick reference for implementing System Analytics in the PawSense super admin dashboard.

**Full Analysis:** See `SYSTEM_ANALYTICS_COMPREHENSIVE_ANALYSIS.md` for complete details.

---

## 🎯 Top Priority Metrics for MVP

### Dashboard Summary Cards (6 KPIs)
| Metric | Source | Calculation |
|--------|--------|-------------|
| **Total Users** | `users` collection | Count all documents |
| **Active Clinics** | `clinic_registrations` | Count where `status = 'approved'` |
| **Total Appointments (Period)** | `appointments` | Count where `createdAt` in date range |
| **System Revenue (Period)** | `appointments` | Sum `totalCost` where `status = 'completed'` |
| **AI Scans (Period)** | `assessment_results` | Count where `timestamp` in date range |
| **Average Rating** | `clinicRatings` | Average of all `rating` values |

---

## 📈 Core Charts & Visualizations

### 1. User Growth Trend (Line Chart)
- **X-axis:** Date (daily/weekly/monthly)
- **Y-axis:** New user registrations
- **Data:** Group `users` by `createdAt` date
- **Period:** Last 7/30/90 days

### 2. Clinic Status Distribution (Pie Chart)
- **Segments:** Pending, Approved, Rejected, Suspended
- **Data:** Count from `clinic_registrations` grouped by `status`
- **Colors:** Yellow (pending), Green (approved), Red (rejected), Gray (suspended)

### 3. Appointment Volume Trends (Bar Chart)
- **X-axis:** Date
- **Y-axis:** Appointment count
- **Data:** Group `appointments` by `createdAt` date
- **Breakdown:** Option to stack by status

### 4. Top 5 Clinics (Table)
- **Columns:** Clinic Name, Appointments, Revenue, Rating, Completion Rate
- **Sorting:** By any column
- **Data:** Aggregate from multiple collections

### 5. Disease Distribution (Bar Chart)
- **X-axis:** Disease name
- **Y-axis:** Occurrence count
- **Data:** Frequency analysis of `appointments.diagnosis` field
- **Limit:** Top 10 diseases

### 6. Revenue Analytics (Area Chart)
- **X-axis:** Date
- **Y-axis:** Revenue (₱)
- **Data:** Sum of `totalCost` grouped by completion date
- **Trend line:** Moving average

---

## 🔧 Required Firebase Queries

### Query 1: User Statistics
```dart
// Get all users grouped by role
final usersSnapshot = await FirebaseFirestore.instance
    .collection('users')
    .get();

// Client-side grouping by role
final stats = {
  'total': usersSnapshot.docs.length,
  'petOwners': usersSnapshot.docs.where((d) => d['role'] == 'petOwner').length,
  'clinicAdmins': usersSnapshot.docs.where((d) => d['role'] == 'clinicAdmin').length,
  'active': usersSnapshot.docs.where((d) => d['isActive'] == true).length,
};
```

### Query 2: Clinic Statistics
```dart
// Get clinic registration statuses
final clinicsSnapshot = await FirebaseFirestore.instance
    .collection('clinic_registrations')
    .get();

final stats = {
  'total': clinicsSnapshot.docs.length,
  'pending': clinicsSnapshot.docs.where((d) => d['status'] == 'pending').length,
  'approved': clinicsSnapshot.docs.where((d) => d['status'] == 'approved').length,
  'rejected': clinicsSnapshot.docs.where((d) => d['status'] == 'rejected').length,
  'suspended': clinicsSnapshot.docs.where((d) => d['status'] == 'suspended').length,
};
```

### Query 3: Appointments in Period
```dart
// Get appointments in date range
final startDate = DateTime.now().subtract(Duration(days: 30));
final endDate = DateTime.now();

final appointmentsSnapshot = await FirebaseFirestore.instance
    .collection('appointments')
    .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
    .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
    .get();

final stats = {
  'total': appointmentsSnapshot.docs.length,
  'completed': appointmentsSnapshot.docs.where((d) => d['status'] == 'completed').length,
  'pending': appointmentsSnapshot.docs.where((d) => d['status'] == 'pending').length,
  'cancelled': appointmentsSnapshot.docs.where((d) => d['status'] == 'cancelled').length,
};
```

### Query 4: Revenue Calculation
```dart
// Get completed appointments and sum revenue
final completedSnapshot = await FirebaseFirestore.instance
    .collection('appointments')
    .where('status', isEqualTo: 'completed')
    .where('completedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
    .where('completedAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
    .get();

double totalRevenue = 0.0;
for (final doc in completedSnapshot.docs) {
  final cost = (doc.data()['totalCost'] as num?)?.toDouble() ?? 0.0;
  totalRevenue += cost;
}
```

### Query 5: Average Rating
```dart
// Get all ratings and calculate average
final ratingsSnapshot = await FirebaseFirestore.instance
    .collection('clinicRatings')
    .get();

double totalRating = 0.0;
int count = 0;

for (final doc in ratingsSnapshot.docs) {
  final rating = (doc.data()['rating'] as num?)?.toDouble() ?? 0.0;
  totalRating += rating;
  count++;
}

final averageRating = count > 0 ? totalRating / count : 0.0;
```

### Query 6: AI Scans
```dart
// Get assessment results in period
final assessmentsSnapshot = await FirebaseFirestore.instance
    .collection('assessment_results')
    .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
    .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
    .get();

final stats = {
  'total': assessmentsSnapshot.docs.length,
  'withBooking': assessmentsSnapshot.docs
      .where((d) => d.data()['hasBookedAppointment'] == true).length,
};
```

---

## 📁 File Structure

### New Files to Create:

```
lib/
├── core/
│   ├── services/
│   │   └── super_admin/
│   │       └── super_admin_analytics_service.dart  ← NEW
│   │
│   └── widgets/
│       └── super_admin/
│           └── system_analytics/
│               ├── analytics_summary_cards.dart     ← NEW
│               ├── user_growth_chart.dart           ← NEW
│               ├── clinic_status_chart.dart         ← NEW
│               ├── appointment_volume_chart.dart    ← NEW
│               ├── top_clinics_table.dart           ← NEW
│               ├── disease_distribution_chart.dart  ← NEW
│               └── revenue_analytics_chart.dart     ← NEW
│
└── pages/
    └── web/
        └── superadmin/
            └── system_analytics_screen.dart         ← MODIFY
```

---

## 🚀 Implementation Checklist

### Phase 1: Core Service Layer
- [ ] Create `super_admin_analytics_service.dart`
- [ ] Implement `getUserStatistics()` method
- [ ] Implement `getClinicStatistics()` method
- [ ] Implement `getAppointmentStatistics()` method
- [ ] Implement `getRevenueStatistics()` method
- [ ] Implement `getAIUsageStatistics()` method
- [ ] Implement `getAverageRating()` method
- [ ] Add error handling and logging
- [ ] Add caching layer (15-30 min TTL)

### Phase 2: Summary Cards Widget
- [ ] Create `analytics_summary_cards.dart`
- [ ] Design card component with icon, value, label, trend
- [ ] Implement grid layout (3 cards per row)
- [ ] Add loading states
- [ ] Add error states
- [ ] Connect to service layer

### Phase 3: Charts Implementation
- [ ] Install chart package (fl_chart or charts_flutter)
- [ ] Create `user_growth_chart.dart` - Line chart
- [ ] Create `clinic_status_chart.dart` - Pie chart
- [ ] Create `appointment_volume_chart.dart` - Bar chart
- [ ] Create `disease_distribution_chart.dart` - Bar chart
- [ ] Create `revenue_analytics_chart.dart` - Area chart
- [ ] Add responsive sizing
- [ ] Add tooltips and legends

### Phase 4: Table Widget
- [ ] Create `top_clinics_table.dart`
- [ ] Implement sortable columns
- [ ] Add pagination (if needed)
- [ ] Style table with AppColors
- [ ] Add "View Details" action

### Phase 5: Screen Integration
- [ ] Update `system_analytics_screen.dart`
- [ ] Replace mock data with real data
- [ ] Add period selector (dropdown)
- [ ] Implement data refresh logic
- [ ] Add loading indicators
- [ ] Add empty states
- [ ] Add error handling

### Phase 6: Performance Optimization
- [ ] Add Firebase composite indexes
- [ ] Implement result caching
- [ ] Optimize query patterns
- [ ] Test with large datasets
- [ ] Monitor query performance
- [ ] Add pagination where needed

---

## 🎨 UI Layout Structure

```
┌─────────────────────────────────────────────────────────────┐
│  System Analytics                                           │
│  Comprehensive system performance and usage analytics       │
│                                                             │
│  [Period Selector: Last 30 Days ▼]  [Refresh] [Export]    │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  KPI SUMMARY CARDS (6 cards in 2 rows)                     │
│                                                             │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐                      │
│  │ 👥 1,250│ │ 🏥 45   │ │ 📅 890  │                      │
│  │ Users   │ │ Clinics │ │ Appts   │                      │
│  │ +12.5% ↑│ │ +3 ↑    │ │ +8.2% ↑ │                      │
│  └─────────┘ └─────────┘ └─────────┘                      │
│                                                             │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐                      │
│  │ ₱125K   │ │ 🤖 342  │ │ ⭐ 4.5  │                      │
│  │ Revenue │ │ AI Scans│ │ Rating  │                      │
│  │ +15.3% ↑│ │ +22% ↑  │ │ +0.2 ↑  │                      │
│  └─────────┘ └─────────┘ └─────────┘                      │
└─────────────────────────────────────────────────────────────┘

┌────────────────────────┬────────────────────────────────────┐
│ USER GROWTH TREND      │ CLINIC STATUS DISTRIBUTION        │
│                        │                                    │
│ [Line Chart]           │ [Pie Chart]                        │
│ - Daily registrations  │ - Approved: 40 (89%)              │
│ - Trend line           │ - Pending: 3 (7%)                 │
│ - Period comparison    │ - Rejected: 1 (2%)                │
│                        │ - Suspended: 1 (2%)               │
├────────────────────────┼────────────────────────────────────┤
│ APPOINTMENT VOLUME     │ TOP 5 PERFORMING CLINICS          │
│                        │                                    │
│ [Bar Chart]            │ [Table]                            │
│ - Daily/weekly bars    │ Clinic | Appts | Revenue | Rating│
│ - Status breakdown     │ ABC    | 150   | ₱45K    | 4.8   │
│ - Completion rate      │ XYZ    | 142   | ₱42K    | 4.7   │
└────────────────────────┴────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ REVENUE ANALYTICS                                           │
│                                                             │
│ [Area Chart with multiple metrics]                         │
│ - Total revenue over time                                  │
│ - Revenue by clinic (top 5)                                │
│ - Average transaction value                                │
│                                                             │
│ Quick Stats:                                               │
│ - Total System Revenue: ₱125,450                           │
│ - Monthly Average: ₱41,817                                 │
│ - Avg per Appointment: ₱756                                │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ DISEASE DISTRIBUTION & AI ANALYTICS                         │
│                                                             │
│ [Bar Chart - Top 10 Diseases]                              │
│ [Stats Cards - AI metrics]                                 │
└─────────────────────────────────────────────────────────────┘
```

---

## 💡 Key Design Decisions

### 1. **Real-Time vs Pre-Aggregated**
**Decision:** Start with real-time aggregation + caching
- **Rationale:** Simpler to implement, always accurate, sufficient for <100 clinics
- **Future:** Switch to pre-aggregated if performance degrades

### 2. **Client-Side vs Server-Side Aggregation**
**Decision:** Use client-side for complex calculations
- **Rationale:** Firestore has limited aggregation capabilities
- **Trade-off:** Higher data transfer, but more flexible
- **Optimization:** Cache results, limit document fetches

### 3. **Period Options**
**Decision:** Last 7/30/90 days, 1 year, custom range
- **Rationale:** Covers most common use cases
- **Implementation:** Custom range optional for Phase 2

### 4. **Chart Library**
**Recommendation:** Use `fl_chart` package
- **Rationale:** Highly customizable, good performance, active maintenance
- **Alternative:** `charts_flutter` (if fl_chart has issues)

### 5. **Caching Strategy**
**Decision:** 15-30 minute TTL for analytics data
- **Rationale:** Balance between freshness and performance
- **Implementation:** Use existing `DataCache` utility

---

## 🔐 Security Considerations

### Role Verification
```dart
// Verify super admin before loading analytics
final user = await AuthGuard.getCurrentUser();
if (user?.role != 'superAdmin') {
  // Redirect or show error
  return;
}
```

### Data Access Controls
- Only super admins can access system-wide analytics
- Clinic admins see only their clinic data (separate dashboard)
- Pet owners have no access to analytics

### Sensitive Data Handling
- Don't expose individual user PII in aggregates
- Anonymize clinic names in certain contexts
- Log analytics access for audit trail

---

## ⚠️ Common Pitfalls to Avoid

1. **Over-fetching Data**
   - ❌ Don't fetch all appointments to count them
   - ✅ Use `.limit()` and fetch only needed fields

2. **Missing Indexes**
   - ❌ Don't query without composite indexes
   - ✅ Create indexes for common query patterns

3. **Blocking UI**
   - ❌ Don't wait for all data before showing anything
   - ✅ Load critical metrics first, others progressively

4. **Cache Invalidation**
   - ❌ Don't cache forever
   - ✅ Set appropriate TTL and manual refresh option

5. **Error Handling**
   - ❌ Don't crash on missing data
   - ✅ Gracefully handle nulls, show N/A when appropriate

---

## 📊 Sample Data Models

### TimeSeriesData
```dart
class TimeSeriesData {
  final String date;  // 'YYYY-MM-DD'
  final double value;
  
  TimeSeriesData({required this.date, required this.value});
}
```

### ClinicPerformanceData
```dart
class ClinicPerformanceData {
  final String clinicId;
  final String clinicName;
  final int appointmentCount;
  final double revenue;
  final double averageRating;
  final double completionRate;
  
  ClinicPerformanceData({
    required this.clinicId,
    required this.clinicName,
    required this.appointmentCount,
    required this.revenue,
    required this.averageRating,
    required this.completionRate,
  });
}
```

### DiseaseData
```dart
class DiseaseData {
  final String name;
  final int count;
  final double percentage;
  
  DiseaseData({
    required this.name,
    required this.count,
    required this.percentage,
  });
}
```

---

## 🎯 Success Metrics

### Performance Targets
- Dashboard initial load: < 3 seconds
- Chart render time: < 500ms
- Period change: < 2 seconds
- Cache hit rate: > 80%

### Data Accuracy
- 100% accuracy for all metrics
- Real-time updates for critical metrics
- Historical data consistency

### User Experience
- Zero loading spinners (use skeletons)
- Smooth transitions between periods
- Clear empty states
- Helpful error messages

---

## 📞 Support & Resources

### Documentation
- Full Analysis: `SYSTEM_ANALYTICS_COMPREHENSIVE_ANALYSIS.md`
- Firebase Schema: `FIREBASE_COLLECTIONS_README.md`
- Admin Dashboard: `DYNAMIC_ADMIN_DASHBOARD.md`

### Code References
- Admin Dashboard Service: `lib/core/services/admin/dashboard_service.dart`
- User Management: `lib/pages/web/superadmin/user_management_screen.dart`
- Clinic Management: `lib/pages/web/superadmin/clinic_management_screen.dart`

### External Resources
- [Firestore Aggregation Queries](https://firebase.google.com/docs/firestore/query-data/aggregation-queries)
- [fl_chart Documentation](https://pub.dev/packages/fl_chart)
- [Firebase Performance Best Practices](https://firebase.google.com/docs/firestore/best-practices)

---

**Last Updated:** October 18, 2025  
**Status:** Ready for Development  
**Estimated Timeline:** 2-4 weeks for MVP
