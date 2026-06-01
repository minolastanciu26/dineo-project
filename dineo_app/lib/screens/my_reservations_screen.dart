import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

class MyReservationsScreen extends StatefulWidget {
  const MyReservationsScreen({super.key});

  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _reservations = [];
  bool _isLoading = true;
  int _userId = 0;

  DateTime _currentMonth = DateTime.now();
  DateTime? _selectedDay;
  List<dynamic> _selectedDayReservations = [];

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('userId') ?? 0;

    try {
      final reservations = await _apiService.getUserReservations(_userId);
      if (mounted) {
        setState(() {
          _reservations = reservations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Set<int> _getReservationDays() {
    final Set<int> days = {};
    for (final r in _reservations) {
      final date = DateTime.parse(r['date']);
      if (date.month == _currentMonth.month && date.year == _currentMonth.year) {
        days.add(date.day);
      }
    }
    return days;
  }

  List<dynamic> _getReservationsForDay(DateTime day) {
    return _reservations.where((r) {
      final date = DateTime.parse(r['date']);
      return date.day == day.day &&
          date.month == day.month &&
          date.year == day.year;
    }).toList();
  }

  void _onDayTap(int day) {
    final selected = DateTime(_currentMonth.year, _currentMonth.month, day);
    final dayReservations = _getReservationsForDay(selected);
    setState(() {
      _selectedDay = selected;
      _selectedDayReservations = dayReservations;
    });
  }

  Future<void> _addToGoogleCalendar(dynamic reservation) async {
    final restaurant = reservation['restaurant'];
    final table = reservation['table'];
    final date = DateTime.parse(reservation['date']);
    final timeParts = (reservation['time'] as String).split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    final startTime = DateTime(date.year, date.month, date.day, hour, minute);
    final endTime = startTime.add(const Duration(hours: 1));

    String pad(int n) => n.toString().padLeft(2, '0');

    final start =
        "${startTime.year}${pad(startTime.month)}${pad(startTime.day)}T${pad(startTime.hour)}${pad(startTime.minute)}00";
    final end =
        "${endTime.year}${pad(endTime.month)}${pad(endTime.day)}T${pad(endTime.hour)}${pad(endTime.minute)}00";

    final title = Uri.encodeComponent(
        "Reservation at ${restaurant?['name'] ?? 'Restaurant'}");
    final details = Uri.encodeComponent(
        "Table ${table?['tableNumber'] ?? '-'} • ${table?['seats'] ?? '-'} seats");
    final location = Uri.encodeComponent(restaurant?['address'] ?? '');

    final url =
        "https://calendar.google.com/calendar/render?action=TEMPLATE&text=$title&dates=$start/$end&details=$details&location=$location";

    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open Google Calendar")),
        );
      }
    }
  }

  String _monthName(int month) {
    const months = [
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ];
    return months[month - 1];
  }

  String _shortMonthName(int month) {
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return months[month - 1];
  }

  String _formatTime(String timeStr) {
    final parts = timeStr.split(':');
    return "${parts[0]}:${parts[1]}";
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed': return const Color(0xFF4CAF50);
      case 'cancelled': return Colors.red;
      case 'pending': return Colors.orange;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                const SizedBox(width: 10),
                Image.asset('assets/images/logo.png', height: 30),
                const Spacer(),
            Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text(
            "My Calendar",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_selectedDay != null)
            GestureDetector(
              onTap: () => setState(() {
                _selectedDay = null;
                _selectedDayReservations = [];
              }),
              child: const Text(
                "See all",
                style: TextStyle(
                  color: Color(0xFFB71C1C),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    ],
  ),
),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFFB71C1C)),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadReservations,
                      color: const Color(0xFFB71C1C),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          children: [
                            _buildCalendar(),
                            const SizedBox(height: 10),

                            if (_selectedDay != null && _selectedDayReservations.isNotEmpty)
                              _buildReservationsList(_selectedDayReservations, showTitle: true)
                            else if (_selectedDay != null && _selectedDayReservations.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Text(
                                  "No reservations on ${_selectedDay!.day} ${_shortMonthName(_selectedDay!.month)}",
                                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                                ),
                              )
                            else if (_reservations.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(40),
                                child: Column(
                                  children: [
                                    Icon(Icons.calendar_today_outlined,
                                        color: Colors.grey, size: 60),
                                    SizedBox(height: 15),
                                    Text(
                                      "No reservations yet",
                                      style: TextStyle(color: Colors.grey, fontSize: 16),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      "Reserve a table at your favourite restaurant",
                                      style: TextStyle(color: Colors.grey, fontSize: 13),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                            else
                              _buildReservationsList(_reservations, showTitle: false),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    final reservationDays = _getReservationDays();
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final startingWeekday = firstDayOfMonth.weekday;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Month navigation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Color(0xFFB71C1C)),
                  onPressed: () => setState(() {
                    _currentMonth = DateTime(
                      _currentMonth.year,
                      _currentMonth.month - 1,
                    );
                    _selectedDay = null;
                    _selectedDayReservations = [];
                  }),
                ),
                Text(
                  "${_monthName(_currentMonth.month)} ${_currentMonth.year}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Color(0xFFB71C1C)),
                  onPressed: () => setState(() {
                    _currentMonth = DateTime(
                      _currentMonth.year,
                      _currentMonth.month + 1,
                    );
                    _selectedDay = null;
                    _selectedDayReservations = [];
                  }),
                ),
              ],
            ),
          ),

          // Day names
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                  .map((d) => SizedBox(
                        width: 36,
                        child: Center(
                          child: Text(
                            d,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Days grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
              ),
              itemCount: (startingWeekday - 1) + daysInMonth,
              itemBuilder: (context, index) {
                if (index < startingWeekday - 1) {
                  return const SizedBox();
                }

                final day = index - (startingWeekday - 1) + 1;
                final hasReservation = reservationDays.contains(day);
                final isSelected = _selectedDay?.day == day &&
                    _selectedDay?.month == _currentMonth.month &&
                    _selectedDay?.year == _currentMonth.year;
                final isToday = DateTime.now().day == day &&
                    DateTime.now().month == _currentMonth.month &&
                    DateTime.now().year == _currentMonth.year;

                return GestureDetector(
                  onTap: () => _onDayTap(day),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFB71C1C)
                          : hasReservation
                              ? const Color(0xFFB71C1C).withOpacity(0.15)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isToday && !isSelected
                          ? Border.all(color: const Color(0xFFB71C1C), width: 1)
                          : null,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          "$day",
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : isToday
                                    ? const Color(0xFFB71C1C)
                                    : Colors.white,
                            fontSize: 13,
                            fontWeight: hasReservation || isToday
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        if (hasReservation && !isSelected)
                          Positioned(
                            bottom: 3,
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: Color(0xFFB71C1C),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 15),
        ],
      ),
    );
  }

  Widget _buildReservationsList(List<dynamic> reservations, {required bool showTitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTitle) ...[
            const SizedBox(height: 10),
            Text(
              "Reservations on ${_selectedDay!.day} ${_shortMonthName(_selectedDay!.month)}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
          ] else ...[
            const SizedBox(height: 10),
            const Text(
              "All Reservations",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
          ],
          ...reservations.map((r) => _buildReservationCard(r)),
        ],
      ),
    );
  }

  Widget _buildReservationCard(dynamic r) {
    final restaurant = r['restaurant'];
    final table = r['table'];
    final status = r['status'] ?? 'Confirmed';

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: _statusColor(status).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    restaurant?['name'] ?? 'Restaurant',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: _statusColor(status),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                _buildDetailChip(
                  Icons.calendar_today,
                  "${DateTime.parse(r['date']).day} ${_shortMonthName(DateTime.parse(r['date']).month)} ${DateTime.parse(r['date']).year}",
                ),
                const SizedBox(width: 10),
                _buildDetailChip(Icons.access_time, _formatTime(r['time'])),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildDetailChip(Icons.table_restaurant,
                    "Table ${table?['tableNumber'] ?? '-'}"),
                const SizedBox(width: 10),
                _buildDetailChip(Icons.people, "${table?['seats'] ?? '-'} seats"),
              ],
            ),

            if (restaurant?['address'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.grey, size: 14),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      restaurant['address'],
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            if (status.toLowerCase() == 'confirmed') ...[
  const SizedBox(height: 12),
  SizedBox(
    width: double.infinity,
    child: OutlinedButton.icon(
      onPressed: () => _addToGoogleCalendar(r),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFFB71C1C)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
      icon: const Icon(Icons.calendar_month,
          color: Color(0xFFB71C1C), size: 16),
      label: const Text(
        "Add to Google Calendar",
        style: TextStyle(color: Color(0xFFB71C1C), fontSize: 13),
      ),
    ),
  ),
],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFB71C1C), size: 14),
          const SizedBox(width: 5),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}