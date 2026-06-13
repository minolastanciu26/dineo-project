using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using DineoAPP.Data;
using DineoAPP.Models;

namespace DineoAPP.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ReviewsController : ControllerBase
    {
        private readonly DineoContext _context;

        public ReviewsController(DineoContext context)
        {
            _context = context;
        }

        // GET: api/reviews/restaurant/{restaurantId}
        [HttpGet("restaurant/{restaurantId}")]
        public async Task<IActionResult> GetReviews(int restaurantId)
        {
            var reviews = await _context.Reviews
                .Where(r => r.RestaurantId == restaurantId)
                .Include(r => r.User)
                .OrderByDescending(r => r.CreatedAt)
                .Select(r => new
                {
                    r.Id,
                    r.UserId,
                    r.Rating,
                    r.Comment,
                    r.CreatedAt,
                    User = new
                    {
                        r.User.FirstName,
                        r.User.LastName,
                        r.User.ProfilePicture
                    }
                })
                .ToListAsync();

            return Ok(reviews);
        }

        // GET: api/reviews/restaurant/{restaurantId}/average
        [HttpGet("restaurant/{restaurantId}/average")]
        public async Task<IActionResult> GetAverageRating(int restaurantId)
        {
            var reviews = await _context.Reviews
                .Where(r => r.RestaurantId == restaurantId)
                .ToListAsync();

            if (!reviews.Any())
                return Ok(new { average = 0.0, count = 0 });

            var average = reviews.Average(r => r.Rating);
            return Ok(new { average = Math.Round(average, 1), count = reviews.Count });
        }

        // POST: api/reviews
[HttpPost]
public async Task<IActionResult> CreateReview([FromBody] CreateReviewRequest request)
{
    if (request.Rating < 1 || request.Rating > 5)
        return BadRequest(new { message = "Rating must be between 1 and 5" });

    var review = new Review
    {
        UserId = request.UserId,
        RestaurantId = request.RestaurantId,
        Rating = request.Rating,
        Comment = request.Comment,
        CreatedAt = DateTime.UtcNow
    };

    _context.Reviews.Add(review);
    await _context.SaveChangesAsync();

    // Update restaurant average rating
    var allReviews = await _context.Reviews
        .Where(r => r.RestaurantId == request.RestaurantId)
        .ToListAsync();

    var restaurant = await _context.Restaurants.FindAsync(request.RestaurantId);
    if (restaurant != null)
    {
        restaurant.Rating = Math.Round(allReviews.Average(r => r.Rating), 1);
        await _context.SaveChangesAsync();
    }

    return Ok(new { message = "Review added successfully!" });
}

        // DELETE: api/reviews/{id}
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteReview(int id, [FromQuery] int? userId)
        {
            Review? review;

            if (userId.HasValue)
            {
                // Regular user — can only delete their own reviews
                review = await _context.Reviews
                    .FirstOrDefaultAsync(r => r.Id == id && r.UserId == userId.Value);
            }
            else
            {
                // Admin — can delete any review
                review = await _context.Reviews.FindAsync(id);
            }

            if (review == null)
                return NotFound(new { message = "Review not found" });

            _context.Reviews.Remove(review);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Review deleted successfully!" });
        }
    }

    public class CreateReviewRequest
    {
        public int UserId { get; set; }
        public int RestaurantId { get; set; }
        public int Rating { get; set; }
        public string? Comment { get; set; }
    }
}