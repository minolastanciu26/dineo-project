using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using DineoAPP.Data;
using DineoAPP.Models;

namespace DineoAPP.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ReservationsController : ControllerBase
    {
        private readonly DineoContext _context;

        public ReservationsController(DineoContext context)
        {
            _context = context;
        }

        // GET: api/reservations/all
        [HttpGet("all")]
        public async Task<IActionResult> GetAll()
        {
            var reservations = await _context.Reservations
                .Include(r => r.Restaurant)
                .Include(r => r.Table)
                .OrderByDescending(r => r.Date)
                .Select(r => new {
                    r.Id,
                    r.UserId,
                    r.RestaurantId,
                    RestaurantName = r.Restaurant != null ? r.Restaurant.Name : "—",
                    r.Date,
                    Time = r.Time.ToString(@"hh\:mm"),
                    r.GuestCount,
                    r.Status,
                    TableNumber = r.Table != null ? r.Table.TableNumber : 0
                })
                .ToListAsync();

            return Ok(reservations);
        }

        // GET: api/reservations/user/{userId}
        [HttpGet("user/{userId}")]
        public async Task<IActionResult> GetUserReservations(int userId)
        {
            var reservations = await _context.Reservations
                .Where(r => r.UserId == userId)
                .Include(r => r.Restaurant)
                .Include(r => r.Table)
                .OrderByDescending(r => r.Date)
                .ToListAsync();

            var reservationIds = reservations.Select(r => r.Id).ToList();
            var orders = await _context.Orders
                .Where(o => o.ReservationId != null && reservationIds.Contains(o.ReservationId.Value))
                .Select(o => new { o.ReservationId, o.Status })
                .ToListAsync();
            var orderStatusMap = orders.ToDictionary(o => o.ReservationId!.Value, o => o.Status);

            var result = reservations.Select(r => new
            {
                r.Id,
                r.UserId,
                r.RestaurantId,
                r.Restaurant,
                r.TableId,
                r.Table,
                r.Date,
                r.Time,
                r.Status,
                r.CreatedAt,
                r.GuestCount,
                OrderStatus = orderStatusMap.TryGetValue(r.Id, out var os) ? os : null,
            });

            return Ok(result);
        }

        // GET: api/reservations/tables/{restaurantId}
        [HttpGet("tables/{restaurantId}")]
        public async Task<IActionResult> GetTables(int restaurantId)
        {
            var tables = await _context.Tables
                .Where(t => t.RestaurantId == restaurantId)
                .ToListAsync();

            return Ok(tables);
        }

        // GET: api/reservations/available/{restaurantId}
        [HttpGet("available/{restaurantId}")]
        public async Task<IActionResult> GetAvailableTables(
            int restaurantId,
            [FromQuery] DateTime date,
            [FromQuery] string time)
        {
            var reservedTableIds = await _context.Reservations
                .Where(r => r.RestaurantId == restaurantId &&
                            r.Date.Date == date.Date &&
                            r.Time == TimeSpan.Parse(time) &&
                            r.Status != "Cancelled" &&
                            r.Status != "Rejected")
                .Select(r => r.TableId)
                .ToListAsync();

            var tables = await _context.Tables
                .Where(t => t.RestaurantId == restaurantId)
                .ToListAsync();

            var result = tables.Select(t => new
            {
                t.Id,
                t.TableNumber,
                t.Seats,
                t.PositionX,
                t.PositionY,
                t.Floor,
                IsAvailable = !reservedTableIds.Contains(t.Id)
            });

            return Ok(result);
        }

        // POST: api/reservations
        [HttpPost]
        public async Task<IActionResult> CreateReservation([FromBody] CreateReservationRequest request)
        {
            var table = await _context.Tables.FindAsync(request.TableId);
            if (table == null)
                return NotFound(new { message = "Table not found" });

            var exists = await _context.Reservations
                .AnyAsync(r => r.TableId == request.TableId &&
                               r.Date.Date == request.Date.Date &&
                               r.Time == request.Time &&
                               r.Status != "Cancelled" &&
                               r.Status != "Rejected");

            if (exists)
                return BadRequest(new { message = "Table already reserved for this time" });

            var reservation = new Reservation
            {
                UserId       = request.UserId,
                RestaurantId = request.RestaurantId,
                TableId      = request.TableId,
                Date         = request.Date,
                Time         = request.Time,
                GuestCount   = request.GuestCount,
                Status       = "Pending",
                CreatedAt    = DateTime.UtcNow
            };

            _context.Reservations.Add(reservation);
            await _context.SaveChangesAsync();

            var restaurant = await _context.Restaurants.FindAsync(request.RestaurantId);
            var restaurantName = restaurant?.Name ?? "restaurant";

            // Notificare Pending
            _context.Notifications.Add(new Notification
            {
                UserId    = request.UserId,
                Title     = "Reservation Pending ⏳",
                Message   = $"Your reservation at {restaurantName} for {request.Date:MMM dd} at {request.Time:hh\\:mm} is awaiting confirmation.",
                IsRead    = false,
                CreatedAt = DateTime.UtcNow
            });

            await _context.SaveChangesAsync();

            return Ok(new { message = "Reservation submitted! Awaiting confirmation.", reservationId = reservation.Id });
        }

        // PUT: api/reservations/{id}/approve
        [HttpPut("{id}/approve")]
        public async Task<IActionResult> Approve(int id)
        {
            var reservation = await _context.Reservations
                .Include(r => r.Restaurant)
                .FirstOrDefaultAsync(r => r.Id == id);

            if (reservation == null)
                return NotFound(new { message = "Reservation not found!" });

            reservation.Status = "Confirmed";
            await _context.SaveChangesAsync();

            var restaurantName = reservation.Restaurant?.Name ?? "restaurant";

            // Notificare Confirmed
            _context.Notifications.Add(new Notification
            {
                UserId    = reservation.UserId,
                Title     = "Reservation Confirmed! 🎉",
                Message   = $"Your table at {restaurantName} is confirmed for {reservation.Date:MMM dd} at {reservation.Time:hh\\:mm}.",
                IsRead    = false,
                CreatedAt = DateTime.UtcNow
            });

            await _context.SaveChangesAsync();

            return Ok(new { message = "Reservation approved!" });
        }

        // PUT: api/reservations/{id}/reject
        [HttpPut("{id}/reject")]
        public async Task<IActionResult> Reject(int id, [FromBody] RejectReservationRequest request)
        {
            var reservation = await _context.Reservations
                .Include(r => r.Restaurant)
                .FirstOrDefaultAsync(r => r.Id == id);

            if (reservation == null)
                return NotFound(new { message = "Reservation not found!" });

            reservation.Status = "Rejected";
            await _context.SaveChangesAsync();

            var restaurantName = reservation.Restaurant?.Name ?? "restaurant";

            // Notificare Rejected cu motiv
            _context.Notifications.Add(new Notification
            {
                UserId    = reservation.UserId,
                Title     = "Reservation Not Available 😔",
                Message   = $"Your reservation at {restaurantName} on {reservation.Date:MMM dd} could not be confirmed. Reason: {request.Reason}",
                IsRead    = false,
                CreatedAt = DateTime.UtcNow
            });

            await _context.SaveChangesAsync();

            return Ok(new { message = "Reservation rejected. User notified." });
        }

        // PUT: api/reservations/{id}/cancel
        [HttpPut("{id}/cancel")]
        public async Task<IActionResult> Cancel(int id)
        {
            var reservation = await _context.Reservations.FindAsync(id);

            if (reservation == null)
                return NotFound(new { message = "Reservation not found!" });

            reservation.Status = "Cancelled";
            await _context.SaveChangesAsync();

            return Ok(new { message = "Reservation cancelled successfully!" });
        }
    }

    public class CreateReservationRequest
    {
        public int UserId { get; set; }
        public int RestaurantId { get; set; }
        public int TableId { get; set; }
        public DateTime Date { get; set; }
        public TimeSpan Time { get; set; }
        public int GuestCount { get; set; }
    }

    public class RejectReservationRequest
    {
        public string Reason { get; set; } = string.Empty;
    }
}