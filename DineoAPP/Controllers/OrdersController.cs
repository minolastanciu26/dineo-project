using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using DineoAPP.Data;
using DineoAPP.Models;

namespace DineoAPP.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class OrdersController : ControllerBase
    {
        private readonly DineoContext _context;

        public OrdersController(DineoContext context)
        {
            _context = context;
        }

        // ─────────────────────────────────────────────────────────────
        // GET api/orders/reservation/{reservationId}
        // Active order for a reservation (includes items + menu names)
        // ─────────────────────────────────────────────────────────────
        [HttpGet("reservation/{reservationId}")]
        public async Task<IActionResult> GetOrderByReservation(int reservationId)
        {
            var order = await _context.Orders
                .Where(o => o.ReservationId == reservationId)
                .OrderByDescending(o => o.CreatedAt)
                .FirstOrDefaultAsync();

            if (order == null)
                return NotFound(new { message = "No order for this reservation" });

            var items = await _context.OrderItems
                .Where(oi => oi.OrderId == order.Id)
                .Include(oi => oi.MenuItem)
                .Select(oi => new
                {
                    oi.Id,
                    oi.MenuItemId,
                    menuItemName = oi.MenuItem.Name,
                    menuItemImageUrl = oi.MenuItem.ImageUrl,
                    oi.Quantity,
                    oi.Price,
                    subtotal = oi.Quantity * oi.Price
                })
                .ToListAsync();

            // Fetch table number via reservation
            var reservation = await _context.Reservations
                .Include(r => r.Table)
                .FirstOrDefaultAsync(r => r.Id == reservationId);

            return Ok(new
            {
                order.Id,
                order.UserId,
                order.RestaurantId,
                order.ReservationId,
                order.Status,
                order.TotalPrice,
                order.CreatedAt,
                tableNumber = reservation?.Table?.TableNumber,
                items
            });
        }

        // ─────────────────────────────────────────────────────────────
        // GET api/orders/{orderId}
        // ─────────────────────────────────────────────────────────────
        [HttpGet("{orderId}")]
        public async Task<IActionResult> GetOrder(int orderId)
        {
            var order = await _context.Orders.FindAsync(orderId);
            if (order == null) return NotFound();

            var items = await _context.OrderItems
                .Where(oi => oi.OrderId == orderId)
                .Include(oi => oi.MenuItem)
                .Select(oi => new
                {
                    oi.Id,
                    oi.MenuItemId,
                    menuItemName = oi.MenuItem.Name,
                    menuItemImageUrl = oi.MenuItem.ImageUrl,
                    oi.Quantity,
                    oi.Price,
                    subtotal = oi.Quantity * oi.Price
                })
                .ToListAsync();

            return Ok(new
            {
                order.Id,
                order.UserId,
                order.RestaurantId,
                order.ReservationId,
                order.Status,
                order.TotalPrice,
                order.CreatedAt,
                items
            });
        }

        // ─────────────────────────────────────────────────────────────
        // GET api/orders/restaurant/{restaurantId}/active
        // All active orders for a restaurant (admin dashboard)
        // ─────────────────────────────────────────────────────────────
        [HttpGet("restaurant/{restaurantId}/active")]
        public async Task<IActionResult> GetActiveOrdersForRestaurant(int restaurantId)
        {
            var orders = await _context.Orders
                .Where(o => o.RestaurantId == restaurantId &&
                            o.Status != "Paid" && o.Status != "Cancelled")
                .OrderByDescending(o => o.CreatedAt)
                .ToListAsync();

            // Always return 200 with empty array when no orders
            if (!orders.Any()) return Ok(new List<object>());

            var result = new List<object>();

            foreach (var order in orders)
            {
                var items = await _context.OrderItems
                    .Where(oi => oi.OrderId == order.Id)
                    .Include(oi => oi.MenuItem)
                    .Select(oi => new
                    {
                        oi.Id,
                        oi.MenuItemId,
                        menuItemName = oi.MenuItem.Name,
                        oi.Quantity,
                        oi.Price,
                        subtotal = oi.Quantity * oi.Price
                    })
                    .ToListAsync();

                var reservation = await _context.Reservations
                    .Include(r => r.Table)
                    .FirstOrDefaultAsync(r => r.Id == order.ReservationId);

                result.Add(new
                {
                    order.Id,
                    order.UserId,
                    order.RestaurantId,
                    order.ReservationId,
                    order.Status,
                    order.TotalPrice,
                    order.CreatedAt,
                    tableNumber = reservation?.Table?.TableNumber,
                    items
                });
            }

            return Ok(result);
        }

        // ─────────────────────────────────────────────────────────────
        // GET api/orders/user/{userId}/active
        // Active order in progress for the current user (homepage card)
        // ─────────────────────────────────────────────────────────────
        [HttpGet("user/{userId}/active")]
        public async Task<IActionResult> GetActiveOrderForUser(int userId)
        {
            var order = await _context.Orders
                .Include(o => o.Restaurant)
                .Where(o => o.UserId == userId &&
                            o.Status != "Paid" && o.Status != "Cancelled")
                .OrderByDescending(o => o.CreatedAt)
                .FirstOrDefaultAsync();

            if (order == null)
                return NotFound(new { message = "No active order" });

            var items = await _context.OrderItems
                .Where(oi => oi.OrderId == order.Id)
                .Include(oi => oi.MenuItem)
                .Select(oi => new
                {
                    oi.Id,
                    oi.MenuItemId,
                    menuItemName = oi.MenuItem.Name,
                    oi.Quantity,
                    oi.Price
                })
                .ToListAsync();

            return Ok(new
            {
                order.Id,
                order.UserId,
                order.RestaurantId,
                restaurantName = order.Restaurant.Name,
                order.ReservationId,
                order.Status,
                order.TotalPrice,
                order.CreatedAt,
                items
            });
        }

        // ─────────────────────────────────────────────────────────────
        // POST api/orders
        // Create a new order linked to a reservation
        // ─────────────────────────────────────────────────────────────
        [HttpPost]
        public async Task<IActionResult> CreateOrder([FromBody] CreateOrderRequest req)
        {
            // Check if there's already a non-paid order for this reservation
            var existing = await _context.Orders
                .FirstOrDefaultAsync(o => o.ReservationId == req.ReservationId &&
                                          o.Status != "Paid" && o.Status != "Cancelled");
            if (existing != null)
                return Ok(new { existing.Id, message = "existing_order" });

            var order = new Order
            {
                UserId = req.UserId,
                RestaurantId = req.RestaurantId,
                ReservationId = req.ReservationId,
                TotalPrice = 0,
                Status = "Pending",
                CreatedAt = DateTime.UtcNow
            };

            _context.Orders.Add(order);
            await _context.SaveChangesAsync();

            return Ok(new { order.Id, message = "created" });
        }

        // ─────────────────────────────────────────────────────────────
        // POST api/orders/{orderId}/items
        // Add item to order
        // ─────────────────────────────────────────────────────────────
        [HttpPost("{orderId}/items")]
        public async Task<IActionResult> AddItem(int orderId, [FromBody] AddOrderItemRequest req)
        {
            var order = await _context.Orders.FindAsync(orderId);
            if (order == null) return NotFound(new { message = "Order not found" });

            var menuItem = await _context.MenuItems.FindAsync(req.MenuItemId);
            if (menuItem == null) return NotFound(new { message = "Menu item not found" });

            // If item already in cart → increment quantity
            var existing = await _context.OrderItems
                .FirstOrDefaultAsync(oi => oi.OrderId == orderId && oi.MenuItemId == req.MenuItemId);

            if (existing != null)
            {
                existing.Quantity += req.Quantity;
            }
            else
            {
                var item = new OrderItem
                {
                    OrderId = orderId,
                    MenuItemId = req.MenuItemId,
                    Quantity = req.Quantity,
                    Price = menuItem.Price
                };
                _context.OrderItems.Add(item);
            }

            // Recalculate total
            await _context.SaveChangesAsync();
            order.TotalPrice = await _context.OrderItems
                .Where(oi => oi.OrderId == orderId)
                .SumAsync(oi => oi.Quantity * oi.Price);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Item added" });
        }

        // ─────────────────────────────────────────────────────────────
        // PUT api/orders/{orderId}/items/{itemId}
        // Update quantity of an item
        // ─────────────────────────────────────────────────────────────
        [HttpPut("{orderId}/items/{itemId}")]
        public async Task<IActionResult> UpdateItem(int orderId, int itemId,
            [FromBody] UpdateOrderItemRequest req)
        {
            var item = await _context.OrderItems
                .FirstOrDefaultAsync(oi => oi.Id == itemId && oi.OrderId == orderId);
            if (item == null) return NotFound();

            if (req.Quantity <= 0)
            {
                _context.OrderItems.Remove(item);
            }
            else
            {
                item.Quantity = req.Quantity;
            }

            await _context.SaveChangesAsync();

            var order = await _context.Orders.FindAsync(orderId);
            if (order != null)
            {
                order.TotalPrice = await _context.OrderItems
                    .Where(oi => oi.OrderId == orderId)
                    .SumAsync(oi => oi.Quantity * oi.Price);
                await _context.SaveChangesAsync();
            }

            return Ok(new { message = "Updated" });
        }

        // ─────────────────────────────────────────────────────────────
        // DELETE api/orders/{orderId}/items/{itemId}
        // Remove item from order
        // ─────────────────────────────────────────────────────────────
        [HttpDelete("{orderId}/items/{itemId}")]
        public async Task<IActionResult> RemoveItem(int orderId, int itemId)
        {
            var item = await _context.OrderItems
                .FirstOrDefaultAsync(oi => oi.Id == itemId && oi.OrderId == orderId);
            if (item == null) return NotFound();

            _context.OrderItems.Remove(item);
            await _context.SaveChangesAsync();

            var order = await _context.Orders.FindAsync(orderId);
            if (order != null)
            {
                order.TotalPrice = await _context.OrderItems
                    .Where(oi => oi.OrderId == orderId)
                    .SumAsync(oi => oi.Quantity * oi.Price);
                await _context.SaveChangesAsync();
            }

            return Ok(new { message = "Removed" });
        }

        // ─────────────────────────────────────────────────────────────
        // PUT api/orders/{orderId}/status
        // Change order status
        // ─────────────────────────────────────────────────────────────
        [HttpPut("{orderId}/status")]
        public async Task<IActionResult> UpdateStatus(int orderId,
            [FromBody] UpdateOrderStatusRequest req)
        {
            var order = await _context.Orders
                .Include(o => o.Restaurant)
                .FirstOrDefaultAsync(o => o.Id == orderId);
            if (order == null) return NotFound();

            var oldStatus = order.Status;
            order.Status = req.Status;
            await _context.SaveChangesAsync();

            // ── Notify user on status changes ──────────────────────
            string? title = null;
            string? message = null;

            if (req.Status == "InProgress" && oldStatus == "Pending")
            {
                title = "👨‍🍳 Order accepted!";
                message = $"Your order at {order.Restaurant.Name} is now being prepared.";
            }
            else if (req.Status == "Ready")
            {
                title = "🍽️ Order ready!";
                message = $"Your order at {order.Restaurant.Name} is ready. Enjoy!";
            }
            else if (req.Status == "Paid")
            {
                title = "✅ Payment confirmed!";
                message = $"Thank you for dining at {order.Restaurant.Name}!";
            }

            if (title != null)
            {
                _context.Notifications.Add(new Notification
                {
                    UserId = order.UserId,
                    Title = title,
                    Message = message!,
                    IsRead = false,
                    CreatedAt = DateTime.UtcNow
                });
                await _context.SaveChangesAsync();
            }

            // ── After Paid → send review prompt ───────────────────
            if (req.Status == "Paid")
            {
                _context.Notifications.Add(new Notification
                {
                    UserId = order.UserId,
                    Title = "⭐ How was your meal?",
                    Message = $"Leave a review for {order.Restaurant.Name} and help others discover it!",
                    IsRead = false,
                    CreatedAt = DateTime.UtcNow.AddSeconds(5),
                    // Store restaurantId in message for deep-link (parsed on Flutter side)
                    // Format: "REVIEW_PROMPT|{restaurantId}|{message}"
                });

                // Overwrite with rich payload for deep link
                var reviewNotif = _context.Notifications.Local.Last();
                reviewNotif.Message = $"REVIEW_PROMPT|{order.RestaurantId}|Leave a review for {order.Restaurant.Name} and help others discover it!";
                await _context.SaveChangesAsync();
            }

            return Ok(new { message = "Status updated", order.Status });
        }

        // ─────────────────────────────────────────────────────────────
        // POST api/orders/{orderId}/request-bill
        // User requests the bill (notifies restaurant admin)
        // ─────────────────────────────────────────────────────────────
        [HttpPost("{orderId}/request-bill")]
        public async Task<IActionResult> RequestBill(int orderId,
            [FromBody] RequestBillRequest req)
        {
            var order = await _context.Orders
                .Include(o => o.Restaurant)
                .FirstOrDefaultAsync(o => o.Id == orderId);
            if (order == null) return NotFound();

            // Get table number
            var reservation = await _context.Reservations
                .Include(r => r.Table)
                .FirstOrDefaultAsync(r => r.Id == order.ReservationId);

            var tableNumber = reservation?.Table?.TableNumber.ToString() ?? "?";
            var paymentLabel = req.PaymentMethod == "cash" ? "cash payment 💵" : "card payment 💳";

            // Notify all admins of this restaurant
            var restaurantAdmins = await _context.Users
                .Where(u => u.Role == "RestaurantAdmin" && u.RestaurantId == order.RestaurantId)
                .ToListAsync();

            foreach (var admin in restaurantAdmins)
            {
                _context.Notifications.Add(new Notification
                {
                    UserId = admin.Id,
                    Title = $"💵 Table {tableNumber} requests the bill",
                    Message = $"Table {tableNumber} is requesting the bill — {paymentLabel}. Total: {order.TotalPrice:F2} RON",
                    IsRead = false,
                    CreatedAt = DateTime.UtcNow
                });
            }

            order.Status = "BillRequested";

            // Send review prompt to user after cash payment request
            // (delayed 10s so it appears after they get back to homepage)
            if (req.PaymentMethod == "cash")
            {
                _context.Notifications.Add(new Notification
                {
                    UserId = order.UserId,
                    Title = "⭐ How was your meal?",
                    Message = $"REVIEW_PROMPT|{order.RestaurantId}|Leave a review for {order.Restaurant.Name} and help others discover it!",
                    IsRead = false,
                    CreatedAt = DateTime.UtcNow.AddSeconds(10)
                });
            }

            await _context.SaveChangesAsync();

            return Ok(new { message = "Bill requested", tableNumber });
        }

        // ─────────────────────────────────────────────────────────────
        // POST api/orders/{orderId}/pay-card
        // Simulated card payment — immediately marks as Paid
        // ─────────────────────────────────────────────────────────────
        [HttpPost("{orderId}/pay-card")]
        public async Task<IActionResult> PayWithCard(int orderId)
        {
            var order = await _context.Orders
                .Include(o => o.Restaurant)
                .FirstOrDefaultAsync(o => o.Id == orderId);
            if (order == null) return NotFound();

            order.Status = "Paid";
            await _context.SaveChangesAsync();

            // Notify user
            _context.Notifications.Add(new Notification
            {
                UserId = order.UserId,
                Title = "✅ Payment successful!",
                Message = $"Your payment of {order.TotalPrice:F2} RON at {order.Restaurant.Name} was processed. 🎉",
                IsRead = false,
                CreatedAt = DateTime.UtcNow
            });

            // Review prompt
            _context.Notifications.Add(new Notification
            {
                UserId = order.UserId,
                Title = "⭐ How was your meal?",
                Message = $"REVIEW_PROMPT|{order.RestaurantId}|Leave a review for {order.Restaurant.Name} and help others discover it!",
                IsRead = false,
                CreatedAt = DateTime.UtcNow.AddSeconds(3)
            });

            await _context.SaveChangesAsync();
            return Ok(new { message = "Payment successful", orderId });
        }
    }

    // ── Request DTOs ────────────────────────────────────────────────

    public class CreateOrderRequest
    {
        public int UserId { get; set; }
        public int RestaurantId { get; set; }
        public int? ReservationId { get; set; }
    }

    public class AddOrderItemRequest
    {
        public int MenuItemId { get; set; }
        public int Quantity { get; set; } = 1;
    }

    public class UpdateOrderItemRequest
    {
        public int Quantity { get; set; }
    }

    public class UpdateOrderStatusRequest
    {
        public string Status { get; set; } = string.Empty;
    }

    public class RequestBillRequest
    {
        public string PaymentMethod { get; set; } = "cash"; // "cash" | "card"
    }
}