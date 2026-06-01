import 'package:flutter/material.dart';
import '../models/restaurant.dart';
import '../services/api_service.dart';

class ReservationScreen extends StatefulWidget {
  final Restaurant restaurant;
  final int userId;

  const ReservationScreen({
    super.key,
    required this.restaurant,
    required this.userId,
  });

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  final ApiService _apiService = ApiService();

  int _currentStep = 0;

  DateTime _selectedDate = DateTime.now();
  String _selectedTime = "19:00";
  int _weekOffset = 0;

  List<dynamic> _tables = [];
  List<dynamic> _decors = [];
  int? _selectedTableId;
  int? _selectedTableNumber;
  int? _selectedTableSeats;
  bool _loadingTables = false;

  bool _confirming = false;
  bool _success = false;

  final List<String> _timeSlots = [
    "12:00", "12:30", "13:00", "13:30",
    "14:00", "19:00", "19:30", "20:00",
    "20:30", "21:00", "21:30",
  ];

  List<DateTime> _getWeekDates() {
    final now = DateTime.now();
    return List.generate(7, (i) => now.add(Duration(days: i + _weekOffset * 7)));
  }

  Future<void> _loadTables() async {
    setState(() => _loadingTables = true);
    try {
      final results = await Future.wait([
        _apiService.getAvailableTables(
          widget.restaurant.id,
          _selectedDate,
          _selectedTime,
        ),
        _apiService.getFloorDecors(widget.restaurant.id),
      ]);
      setState(() {
        _tables = results[0];
        _decors = results[1];
        _selectedTableId = null;
        _selectedTableNumber = null;
        _selectedTableSeats = null;
        _loadingTables = false;
      });
    } catch (e) {
      setState(() => _loadingTables = false);
    }
  }

  Future<void> _confirmReservation() async {
    if (_selectedTableId == null) return;
    setState(() => _confirming = true);

    final success = await _apiService.createReservation(
      userId: widget.userId,
      restaurantId: widget.restaurant.id,
      tableId: _selectedTableId!,
      date: _selectedDate,
      time: _selectedTime,
      guestCount: _selectedTableSeats ?? 2,
    );

    setState(() {
      _confirming = false;
      _success = success;
      if (success) _currentStep = 3;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: _success ? _buildSuccess() : _buildSteps(),
      ),
    );
  }

  Widget _buildSteps() {
    switch (_currentStep) {
      case 0: return _buildStep1();
      case 1: return _buildStep2();
      case 2: return _buildStep3();
      default: return _buildStep1();
    }
  }

  // ── STEP 1 ────────────────────────────────────────
  Widget _buildStep1() {
    final weekDates = _getWeekDates();
    final dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    final firstDay = weekDates.first;
    final lastDay = weekDates.last;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Reserve a table\nat ${widget.restaurant.name}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Select a date",
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    Row(
                      children: [
                        Text(
                          "${_monthName(firstDay.month)} ${firstDay.day} - ${lastDay.day}",
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        const SizedBox(width: 8),
                        if (_weekOffset > 0)
                          GestureDetector(
                            onTap: () => setState(() => _weekOffset--),
                            child: const Icon(Icons.chevron_left, color: Color(0xFFB71C1C), size: 20),
                          ),
                        GestureDetector(
                          onTap: () => setState(() => _weekOffset++),
                          child: const Icon(Icons.chevron_right, color: Color(0xFFB71C1C), size: 20),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                SizedBox(
                  height: 70,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: weekDates.length,
                    itemBuilder: (context, index) {
                      final date = weekDates[index];
                      final isSelected = date.day == _selectedDate.day &&
                          date.month == _selectedDate.month &&
                          date.year == _selectedDate.year;
                      final dayName = dayNames[date.weekday - 1];

                      return GestureDetector(
                        onTap: () => setState(() => _selectedDate = date),
                        child: Container(
                          width: 50,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFB71C1C) : const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "${date.day}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                dayName,
                                style: TextStyle(
                                  color: isSelected ? Colors.white70 : Colors.grey,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 25),

                const Text("Choose a time", style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _timeSlots.map((time) {
                    final isSelected = time == _selectedTime;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedTime = time),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFB71C1C) : const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          time,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        _buildNextButton(() async {
          await _loadTables();
          setState(() => _currentStep = 1);
        }),
      ],
    );
  }

  String _monthName(int month) {
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return months[month - 1];
  }

  // ── STEP 2 — TABLE LAYOUT cu decor ───────────────
  Widget _buildStep2() {
    return Column(
      children: [
        _buildHeader(),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Now it's time to\nchoose your table",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Legenda
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              _legendItem(const Color(0xFF3A3A3A), "Available"),
              const SizedBox(width: 16),
              _legendItem(const Color(0xFFB71C1C), "Selected"),
              const SizedBox(width: 16),
              _legendItem(const Color(0xFF2A2A2A), "Taken"),
            ],
          ),
        ),
        const SizedBox(height: 12),

        Expanded(
          child: _loadingTables
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFB71C1C)))
              : _tables.isEmpty
                  ? const Center(
                      child: Text("No tables available", style: TextStyle(color: Colors.grey)),
                    )
                  : _buildTableLayout(),
        ),

        _buildNextButton(_selectedTableId == null
            ? null
            : () => setState(() => _currentStep = 2)),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }

  Widget _buildTableLayout() {
    // Calculeaza dimensiunile canvas din pozitii mese + decor
    double maxX = 300;
    double maxY = 300;
    for (final t in _tables) {
      final x = (t['positionX'] as num?)?.toDouble() ?? 0;
      final y = (t['positionY'] as num?)?.toDouble() ?? 0;
      if (x > maxX) maxX = x;
      if (y > maxY) maxY = y;
    }
    for (final d in _decors) {
      final x = (d['x'] as num?)?.toDouble() ?? 0;
      final y = (d['y'] as num?)?.toDouble() ?? 0;
      final w = (d['width'] as num?)?.toDouble() ?? 80;
      final h = (d['height'] as num?)?.toDouble() ?? 40;
      if (x + w > maxX) maxX = x + w;
      if (y + h > maxY) maxY = y + h;
    }
    final canvasW = maxX + 80;
    final canvasH = maxY + 80;

    return InteractiveViewer(
      minScale: 0.4,
      maxScale: 2.5,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: Container(
            width: canvasW,
            height: canvasH,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2A2A2E)),
            ),
            child: Stack(
              children: [
                // Grid
                CustomPaint(
                  size: Size(canvasW, canvasH),
                  painter: _GridPainter(),
                ),

                // ── Decor elements ──────────────────
                ..._decors.map((d) {
                  final x = (d['x'] as num?)?.toDouble() ?? 0;
                  final y = (d['y'] as num?)?.toDouble() ?? 0;
                  final w = (d['width'] as num?)?.toDouble() ?? 80;
                  final h = (d['height'] as num?)?.toDouble() ?? 40;
                  final icon = d['icon'] as String? ?? '';
                  final label = d['label'] as String? ?? '';

                  return Positioned(
                    left: x,
                    top: y,
                    child: Container(
                      width: w,
                      height: h,
                      decoration: BoxDecoration(
                        color: const Color(0xFF242428),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF3A3A3E), width: 1.5),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(icon, style: const TextStyle(fontSize: 16)),
                          if (h > 35)
                            Text(
                              label,
                              style: const TextStyle(
                                color: Color(0xFF888888),
                                fontSize: 9,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),

                // ── Tables ─────────────────────────
                ..._tables.map((table) {
                  final x = (table['positionX'] as num?)?.toDouble() ?? 0;
                  final y = (table['positionY'] as num?)?.toDouble() ?? 0;
                  final isAvailable = table['isAvailable'] == true;
                  final isSelected = _selectedTableId == table['id'];
                  final seats = table['seats'] as int;
                  final number = table['tableNumber'] as int;

                  return Positioned(
                    left: x - 32,
                    top: y - 32,
                    child: GestureDetector(
                      onTap: isAvailable
                          ? () => setState(() {
                                _selectedTableId = table['id'];
                                _selectedTableNumber = number;
                                _selectedTableSeats = seats;
                              })
                          : null,
                      child: _buildTableNode(
                        number: number,
                        seats: seats,
                        isAvailable: isAvailable,
                        isSelected: isSelected,
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTableNode({
    required int number,
    required int seats,
    required bool isAvailable,
    required bool isSelected,
  }) {
    Color bg;
    if (isSelected) bg = const Color(0xFFB71C1C);
    else if (!isAvailable) bg = const Color(0xFF2A2A2A);
    else bg = const Color(0xFF3A3A3A);

    Color border;
    if (isSelected) border = const Color(0xFFE53935);
    else if (!isAvailable) border = const Color(0xFF222222);
    else border = const Color(0xFF555555);

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: 2),
        boxShadow: isSelected
            ? [BoxShadow(color: const Color(0xFFB71C1C).withOpacity(0.4), blurRadius: 12, spreadRadius: 2)]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "$number",
            style: TextStyle(
              color: isAvailable || isSelected ? Colors.white : Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "$seats seats",
            style: TextStyle(
              color: isAvailable || isSelected ? Colors.white70 : Colors.grey.shade700,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  // ── STEP 3 ────────────────────────────────────────
  Widget _buildStep3() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Confirm reservation?",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                _buildConfirmRow("Restaurant", widget.restaurant.name),
                _buildConfirmRow(
                  "Date",
                  "${_selectedDate.day} ${_monthName(_selectedDate.month)} ${_selectedDate.year}",
                ),
                _buildConfirmRow("Time", _selectedTime),
                _buildConfirmRow("Seats", "${_selectedTableSeats ?? '-'}"),
                _buildConfirmRow("Table no.", "${_selectedTableNumber ?? '-'}"),
                const SizedBox(height: 30),
                Center(
                  child: _buildTableWidget(
                    number: _selectedTableNumber ?? 0,
                    seats: _selectedTableSeats ?? 2,
                    isAvailable: true,
                    isSelected: true,
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _confirming ? null : _confirmReservation,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB71C1C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
              child: _confirming
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "CONFIRM RESERVATION",
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // ── SUCCESS ───────────────────────────────────────
  Widget _buildSuccess() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: Color(0xFF1A2A3A),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.hourglass_top_rounded, color: Color(0xFFFFB300), size: 60),
          ),
          const SizedBox(height: 25),
          const Text(
            "Request Sent!",
            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            "Your reservation is pending confirmation",
            style: TextStyle(color: Colors.grey, fontSize: 15),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "The restaurant will confirm or reject your reservation shortly. You will receive a notification.",
              style: TextStyle(color: Color(0xFFB71C1C), fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB71C1C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
            child: const Text(
              "Back to Restaurant",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  // ── TABLE WIDGET (Step 3 preview) ─────────────────
  Widget _buildTableWidget({
    required int number,
    required int seats,
    required bool isAvailable,
    required bool isSelected,
  }) {
    Color tableColor;
    if (isSelected) tableColor = const Color(0xFFB71C1C);
    else if (!isAvailable) tableColor = const Color(0xFF2A2A2A);
    else tableColor = const Color(0xFF3A3A3A);

    Color chairColor;
    if (isSelected) chairColor = const Color(0xFFB71C1C).withOpacity(0.7);
    else if (!isAvailable) chairColor = const Color(0xFF1A1A1A);
    else chairColor = const Color(0xFF4A4A4A);

    int topChairs = 0, bottomChairs = 0;
    if (seats == 2) { topChairs = 0; bottomChairs = 2; }
    else if (seats == 4) { topChairs = 2; bottomChairs = 2; }
    else if (seats == 6) { topChairs = 3; bottomChairs = 3; }
    else if (seats == 8) { topChairs = 4; bottomChairs = 4; }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (topChairs > 0)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(topChairs, (_) => Container(
              width: 12, height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(color: chairColor, borderRadius: BorderRadius.circular(3)),
            )),
          ),
        const SizedBox(height: 3),
        Container(
          width: 52, height: 28,
          decoration: BoxDecoration(color: tableColor, borderRadius: BorderRadius.circular(8)),
          child: Center(
            child: Text(
              "$number",
              style: TextStyle(
                color: isAvailable || isSelected ? Colors.white : Colors.grey,
                fontSize: 13, fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 3),
        if (bottomChairs > 0)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(bottomChairs, (_) => Container(
              width: 12, height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(color: chairColor, borderRadius: BorderRadius.circular(3)),
            )),
          ),
      ],
    );
  }

  // ── HELPERS ───────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              if (_currentStep > 0) {
                setState(() => _currentStep--);
              } else {
                Navigator.pop(context);
              }
            },
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.restaurant.name,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton(VoidCallback? onPressed) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: onPressed == null ? const Color(0xFF333333) : const Color(0xFFB71C1C),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          ),
          child: const Text(
            "NEXT",
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

// ── GRID PAINTER ──────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}
