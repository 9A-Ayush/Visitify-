import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/amenity.dart';
import '../../services/auth_provider.dart';
import '../../theme/app_theme.dart';
import 'package:provider/provider.dart';

class AmenitiesScreen extends StatefulWidget {
  const AmenitiesScreen({Key? key}) : super(key: key);

  @override
  State<AmenitiesScreen> createState() => _AmenitiesScreenState();
}

class _AmenitiesScreenState extends State<AmenitiesScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  String _selectedAmenity = 'Swimming Pool';
  bool _isBooking = false;

  final List<String> _amenities = [
    'Swimming Pool',
    'Gym',
    'Club House',
    'Tennis Court',
    'Basketball Court',
    'Children\'s Play Area',
    'Party Hall',
    'Conference Room',
  ];

  final List<String> _timeSlots = [
    '06:00 - 08:00',
    '08:00 - 10:00',
    '10:00 - 12:00',
    '12:00 - 14:00',
    '14:00 - 16:00',
    '16:00 - 18:00',
    '18:00 - 20:00',
    '20:00 - 22:00',
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.appUser;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  boxShadow: AppTheme.softShadow,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Expanded(
                      child: Text(
                        'Amenity Booking',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48), // Balance the back button
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Amenity Selector
                      Container(
                        margin: const EdgeInsets.all(20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: AppTheme.cardRadius,
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.location_city, color: AppTheme.primary, size: 20),
                                const SizedBox(width: 8),
                                Text('Select Amenity', style: AppTheme.headingSmall),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 40,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _amenities.length,
                                itemBuilder: (context, index) {
                                  final amenity = _amenities[index];
                                  final isSelected = _selectedAmenity == amenity;
                                  return GestureDetector(
                                    onTap: () => setState(() => _selectedAmenity = amenity),
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 12),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        gradient: isSelected ? AppTheme.primaryGradient : null,
                                        color: isSelected ? null : AppTheme.background,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isSelected ? Colors.transparent : AppTheme.primary.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Text(
                                        amenity,
                                        style: AppTheme.bodyMedium.copyWith(
                                          color: isSelected ? Colors.white : AppTheme.textPrimary,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Calendar
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: AppTheme.cardRadius,
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.calendar_today, color: AppTheme.primary, size: 20),
                                const SizedBox(width: 8),
                                Text('Select Date', style: AppTheme.headingSmall),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TableCalendar<Amenity>(
                              firstDay: DateTime.now(),
                              lastDay: DateTime.now().add(const Duration(days: 30)),
                              focusedDay: _focusedDay,
                              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                              onDaySelected: (selectedDay, focusedDay) {
                                setState(() {
                                  _selectedDay = selectedDay;
                                  _focusedDay = focusedDay;
                                });
                              },
                              calendarStyle: CalendarStyle(
                                outsideDaysVisible: false,
                                selectedDecoration: BoxDecoration(
                                  color: AppTheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                todayDecoration: BoxDecoration(
                                  color: AppTheme.accent,
                                  shape: BoxShape.circle,
                                ),
                                weekendTextStyle: AppTheme.bodyMedium.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                                defaultTextStyle: AppTheme.bodyMedium,
                              ),
                              headerStyle: HeaderStyle(
                                formatButtonVisible: false,
                                titleCentered: true,
                                titleTextStyle: AppTheme.headingSmall,
                                leftChevronIcon: Icon(
                                  Icons.chevron_left,
                                  color: AppTheme.primary,
                                ),
                                rightChevronIcon: Icon(
                                  Icons.chevron_right,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Time Slots
                      Container(
                        margin: const EdgeInsets.all(20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: AppTheme.cardRadius,
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.access_time, color: AppTheme.primary, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Slots for ${_formatDate(_selectedDay)}',
                                  style: AppTheme.headingSmall,
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 400,
                              child: StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('amenities')
                                    .where('name', isEqualTo: _selectedAmenity)
                                    .where('date', isEqualTo: _formatDateForQuery(_selectedDay))
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  final bookedSlots = <String>{};
                                  if (snapshot.hasData) {
                                    for (var doc in snapshot.data!.docs) {
                                      final amenity = Amenity.fromMap(
                                          doc.data() as Map<String, dynamic>, doc.id);
                                      bookedSlots.add(amenity.slotTime);
                                    }
                                  }

                                  return GridView.builder(
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                      childAspectRatio: 2.5,
                                    ),
                                    itemCount: _timeSlots.length,
                                    itemBuilder: (context, index) {
                                      final slot = _timeSlots[index];
                                      final isBooked = bookedSlots.contains(slot);
                                      return _buildTimeSlotCard(slot, isBooked, user);
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSlotCard(String slot, bool isBooked, user) {
    return GestureDetector(
      onTap: (isBooked || _isBooking) ? null : () => _bookSlot(slot, user),
      child: Container(
        decoration: BoxDecoration(
          color: isBooked ? AppTheme.background : AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isBooked 
                ? AppTheme.textSecondary.withOpacity(0.3)
                : AppTheme.primary.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: isBooked ? null : AppTheme.cardShadow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              slot,
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: isBooked ? AppTheme.textSecondary : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isBooked 
                    ? AppTheme.error.withOpacity(0.1)
                    : AppTheme.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isBooked ? 'BOOKED' : 'AVAILABLE',
                style: AppTheme.caption.copyWith(
                  color: isBooked ? AppTheme.error : AppTheme.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateForQuery(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _bookSlot(String slot, user) async {
    setState(() => _isBooking = true);
    try {
      await FirebaseFirestore.instance.collection('amenities').add({
        'name': _selectedAmenity,
        'slot_time': slot,
        'booked_by': user?.uid,
        'flat_no': user?.flatNo,
        'date': _formatDateForQuery(_selectedDay),
        'created_at': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('$_selectedAmenity booked for $slot'),
            backgroundColor: AppTheme.success,
          ),
        );
    } catch (e) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Error booking amenity: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
    } finally {
      setState(() => _isBooking = false);
    }
  }
}
