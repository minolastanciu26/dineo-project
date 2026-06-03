import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';

class OrderProgressCard extends StatelessWidget {
  final VoidCallback? onAddMore;

  const OrderProgressCard({super.key, this.onAddMore});

  static const Map<String, _StatusInfo> _statusMap = {
    'Pending':      _StatusInfo('Waiting for restaurant...', Color(0xFFFF9800), 0.2),
    'InProgress':   _StatusInfo('In preparation 👨‍🍳',        Color(0xFFFF9800), 0.6),
    'BillRequested':_StatusInfo('Bill on the way 🧾',         Color(0xFF4CAF50), 0.85),
    'Ready':        _StatusInfo('Ready to pick up! 🍽️',      Color(0xFF4CAF50), 1.0),
    'Paid':         _StatusInfo('Paid ✅',                    Color(0xFF4CAF50), 1.0),
  };

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        if (cart.orderId == null || cart.restaurantName == null) {
          return const SizedBox.shrink();
        }

        final statusKey = cart.orderStatus ?? 'Pending';
        final info = _statusMap[statusKey] ??
            const _StatusInfo('Processing...', Color(0xFFFF9800), 0.3);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: const Color(0xFFB71C1C).withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFB71C1C).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.receipt_long,
                    color: Color(0xFFB71C1C), size: 18),
              ),
              const SizedBox(width: 10),

              // Info column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Order in Progress',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                              color: info.color, shape: BoxShape.circle),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cart.restaurantName!,
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    // Compact progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: info.progress,
                        backgroundColor: const Color(0xFF2A2A2A),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(info.color),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      info.label,
                      style: TextStyle(
                          color: info.color,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Right side: total + add more
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${cart.total.toStringAsFixed(0)} RON',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  if (onAddMore != null &&
                      !['BillRequested','Paid','Completed'].contains(cart.orderStatus)) ...[
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: onAddMore,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB71C1C),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '+ Add more',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatusInfo {
  final String label;
  final Color color;
  final double progress;
  const _StatusInfo(this.label, this.color, this.progress);
}