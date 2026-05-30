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

            return Ok(reservations);
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
                            r.Status != "Cancelled")
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
                       r.Status != "Cancelled");

    if (exists)
        return BadRequest(new { message = "Table already reserved for this time" });

    var reservation = new Reservation
    {
        UserId = request.UserId,
        RestaurantId = request.RestaurantId,
        TableId = request.TableId,
        Date = request.Date,
        Time = request.Time,
        GuestCount = request.GuestCount,
        Status = "Confirmed",
        CreatedAt = DateTime.UtcNow
    };

    _context.Reservations.Add(reservation);
    await _context.SaveChangesAsync();

    // Fetch restaurant name
    var restaurant = await _context.Restaurants.FindAsync(request.RestaurantId);
    var restaurantName = restaurant?.Name ?? "restaurant";

    // Notificare Reservation Confirmed
    _context.Notifications.Add(new Notification
    {
        UserId = request.UserId,
        Title = "Reservation Confirmed! 🎉",
        Message = $"Your table at {restaurantName} is confirmed for {request.Date:MMM dd} at {request.Time:hh\\:mm}.",
        IsRead = false,
        CreatedAt = DateTime.UtcNow
    });

    // Notificare Review Reminder — programata pentru dupa rezervare
    _context.Notifications.Add(new Notification
    {
        UserId = request.UserId,
        Title = "How was your experience? ⭐",
        Message = $"You visited {restaurantName}! Leave a review and help others discover it.",
        IsRead = false,
        CreatedAt = request.Date.Add(request.Time).AddHours(2)
    });

    await _context.SaveChangesAsync();

    return Ok(new { message = "Reservation confirmed!", reservationId = reservation.Id });
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
}