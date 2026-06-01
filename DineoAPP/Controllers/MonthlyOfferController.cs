using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using DineoAPP.Data;
using DineoAPP.Models;

namespace DineoAPP.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class MonthlyOfferController : ControllerBase
    {
        private readonly DineoContext _context;

        public MonthlyOfferController(DineoContext context)
        {
            _context = context;
        }

        // GET: api/monthlyoffer/current
        [HttpGet("current")]
        public async Task<IActionResult> GetCurrentOffer()
        {
            var now = DateTime.UtcNow;

            var offer = await _context.MonthlyOffers
                .Include(o => o.Restaurant)
                .FirstOrDefaultAsync(o =>
                    o.Month == now.Month &&
                    o.Year == now.Year &&
                    o.IsActive);

            if (offer == null)
                return NotFound(new { message = "No offer this month" });

            return Ok(new
            {
                offer.Id,
                offer.Month,
                offer.Year,
                offer.IsActive,
                RestaurantId = offer.RestaurantId,
                Restaurant = new
                {
                    offer.Restaurant.Id,
                    offer.Restaurant.Name,
                    offer.Restaurant.Description,
                    offer.Restaurant.CuisineType,
                    offer.Restaurant.Rating,
                    offer.Restaurant.Address,
                    offer.Restaurant.ImageUrl,
                    offer.Restaurant.PhoneNumber,
                }
            });
        }

        // GET: api/monthlyoffer/user/{userId}/status
        [HttpGet("user/{userId}/status")]
        public async Task<IActionResult> GetUserOfferStatus(int userId)
        {
            var now = DateTime.UtcNow;

            var offer = await _context.MonthlyOffers
                .FirstOrDefaultAsync(o =>
                    o.Month == now.Month &&
                    o.Year == now.Year &&
                    o.IsActive);

            if (offer == null)
                return NotFound(new { message = "No offer this month" });

            var userOffer = await _context.UserMonthlyOffers
                .FirstOrDefaultAsync(u =>
                    u.UserId == userId &&
                    u.MonthlyOfferId == offer.Id);

            return Ok(new
            {
                isUsed = userOffer?.IsUsed ?? false,
                usedAt = userOffer?.UsedAt
            });
        }

        // POST: api/monthlyoffer/use
        [HttpPost("use")]
        public async Task<IActionResult> UseOffer([FromBody] UseOfferRequest request)
        {
            var now = DateTime.UtcNow;

            var offer = await _context.MonthlyOffers
                .FirstOrDefaultAsync(o =>
                    o.Month == now.Month &&
                    o.Year == now.Year &&
                    o.IsActive);

            if (offer == null)
                return NotFound(new { message = "No offer this month" });

            var existing = await _context.UserMonthlyOffers
                .FirstOrDefaultAsync(u =>
                    u.UserId == request.UserId &&
                    u.MonthlyOfferId == offer.Id);

            if (existing != null && existing.IsUsed)
                return BadRequest(new { message = "Offer already used" });

            if (existing == null)
            {
                _context.UserMonthlyOffers.Add(new UserMonthlyOffer
                {
                    UserId = request.UserId,
                    MonthlyOfferId = offer.Id,
                    IsUsed = true,
                    UsedAt = DateTime.UtcNow
                });
            }
            else
            {
                existing.IsUsed = true;
                existing.UsedAt = DateTime.UtcNow;
            }

            await _context.SaveChangesAsync();
            return Ok(new { message = "Offer used successfully!" });
        }

        // POST: api/monthlyoffer/admin/create  ← înlocuiește oferta existentă
        [HttpPost("admin/create")]
        public async Task<IActionResult> CreateOffer([FromBody] CreateOfferRequest request)
        {
            // Dacă există deja o ofertă pentru luna respectivă, o dezactivăm
            var existing = await _context.MonthlyOffers
                .Where(o => o.Month == request.Month && o.Year == request.Year)
                .ToListAsync();

            foreach (var old in existing)
            {
                old.IsActive = false;
            }

            // Creăm oferta nouă
            var offer = new MonthlyOffer
            {
                RestaurantId = request.RestaurantId,
                Month        = request.Month,
                Year         = request.Year,
                IsActive     = true
            };

            _context.MonthlyOffers.Add(offer);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Offer updated!", offerId = offer.Id });
        }

        // DELETE: api/monthlyoffer/current
        [HttpDelete("current")]
        public async Task<IActionResult> RemoveCurrentOffer()
        {
            var now = DateTime.UtcNow;

            var offers = await _context.MonthlyOffers
                .Where(o => o.Month == now.Month && o.Year == now.Year && o.IsActive)
                .ToListAsync();

            foreach (var offer in offers)
                offer.IsActive = false;

            await _context.SaveChangesAsync();
            return Ok(new { message = "Offer removed!" });
        }
    }

    public class UseOfferRequest
    {
        public int UserId { get; set; }
    }

    public class CreateOfferRequest
    {
        public int RestaurantId { get; set; }
        public int Month { get; set; }
        public int Year { get; set; }
    }
}