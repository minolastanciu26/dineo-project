using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using DineoAPP.Data;
using DineoAPP.Models;

namespace DineoAPP.Controllers
{
    /// <summary>
    /// Called by the Flutter app on launch (or periodically).
    /// Sends "Your table is ready!" notifications for confirmed reservations
    /// starting within the next 15 minutes.
    /// </summary>
    [Route("api/[controller]")]
    [ApiController]
    public class ReservationArrivalController : ControllerBase
    {
        private readonly DineoContext _context;

        public ReservationArrivalController(DineoContext context)
        {
            _context = context;
        }

        // POST api/reservationarrival/check
        // Body: { "userId": 5 }   — pass 0 to check ALL users (admin / background job)
        [HttpPost("check")]
        public async Task<IActionResult> CheckArrivals([FromBody] ArrivalCheckRequest req)
        {
            var now = DateTime.UtcNow;
            var windowEnd = now.AddMinutes(15);
            var today = now.Date;

            var query = _context.Reservations
                .Include(r => r.Restaurant)
                .Where(r =>
                    r.Status == "Confirmed" &&
                    r.Date.Date == today);

            if (req.UserId > 0)
                query = query.Where(r => r.UserId == req.UserId);

            var reservations = await query.ToListAsync();

            int notified = 0;

            foreach (var res in reservations)
            {
                // Build the DateTime of the reservation
                var resDateTime = res.Date.Date + res.Time;

                // Within the window: between now and now+15min
                if (resDateTime < now || resDateTime > windowEnd)
                    continue;

                // Don't send duplicate — check if already notified today
                var alreadySent = await _context.Notifications
                    .AnyAsync(n =>
                        n.UserId == res.UserId &&
                        n.Title == "🍽️ Your table is ready!" &&
                        n.CreatedAt.Date == today);

                if (alreadySent) continue;

                _context.Notifications.Add(new Notification
                {
                    UserId = res.UserId,
                    Title = "🍽️ Your table is ready!",
                    Message = $"ARRIVAL|{res.RestaurantId}|{res.Id}|Hungry? Your table at {res.Restaurant.Name} is waiting. Tap to see today's menu and start ordering!",
                    IsRead = false,
                    CreatedAt = DateTime.UtcNow
                });

                notified++;
            }

            if (notified > 0)
                await _context.SaveChangesAsync();

            return Ok(new { notified });
        }
    }

    public class ArrivalCheckRequest
    {
        public int UserId { get; set; }
    }
}