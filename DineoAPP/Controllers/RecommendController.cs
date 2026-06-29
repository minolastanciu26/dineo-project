using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using DineoAPP.Data;
using DineoAPP.Services;

namespace DineoAPP.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class RecommendController : ControllerBase
    {
        private readonly DineoContext _context;

        public RecommendController(DineoContext context)
        {
            _context = context;
        }

        [HttpPost]
        public async Task<IActionResult> GetRecommendation([FromBody] RecommendRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.Preference))
                return BadRequest(new { message = "Te rog descrie ce cauți." });

            var restaurants = await _context.Restaurants.ToListAsync();
            if (!restaurants.Any())
                return Ok(new { recommendation = "Nu există restaurante disponibile momentan." });

            var decors = await _context.FloorDecors.ToListAsync();
            var menuCategories = await _context.MenuCategories
                .Include(c => c.MenuItems)
                .ToListAsync();

            var tokens = DineoNlpEngine.Tokenize(request.Preference);
            var intent = DineoNlpEngine.ExtractIntent(tokens);

            var scored = restaurants
                .Select(r => (
                    Restaurant: r,
                    Score: DineoNlpEngine.ScoreRestaurant(
                        r,
                        decors.Where(d => d.RestaurantId == r.Id).ToList(),
                        menuCategories.Where(c => c.RestaurantId == r.Id).ToList(),
                        tokens,
                        intent)
                ))
                .OrderByDescending(x => x.Score)
                .ToList();

            // Take top 3 with a positive score; fall back to top 3 by rating if nothing matched
            var top3 = scored.Where(x => x.Score > 1.3).Take(3).ToList();
            bool noMatch = !top3.Any();
            if (noMatch)
                top3 = scored.Take(3).ToList();

            // Build per-restaurant menu term matches
            var results = top3.Select(x =>
            {
                var r = x.Restaurant;
                var terms = new List<string>();
                foreach (var cat in menuCategories.Where(c => c.RestaurantId == r.Id))
                {
                    var catNorm = cat.Name?.ToLower() ?? "";
                    if (tokens.Any(t => t.Length >= 3 && catNorm.Contains(t)))
                        terms.Add(cat.Name!);
                    foreach (var item in cat.MenuItems ?? new List<DineoAPP.Models.MenuItem>())
                    {
                        var itemNorm = (item.Name ?? "").ToLower();
                        if (tokens.Any(t => t.Length >= 3 && itemNorm.Contains(t)))
                            terms.Add(item.Name!);
                    }
                }

                return new
                {
                    id          = r.Id,
                    name        = r.Name,
                    rating      = r.Rating,
                    cuisineType = r.CuisineType,
                    imageUrl    = r.ImageUrl,
                    description = r.Description,
                    reasonText  = DineoNlpEngine.BuildRestaurantReason(r, intent, terms)
                };
            }).ToList();

            return Ok(new
            {
                intro   = DineoNlpEngine.BuildIntro(noMatch),
                results
            });
        }
    }

    public class RecommendRequest
    {
        public string Preference { get; set; } = string.Empty;
    }
}
