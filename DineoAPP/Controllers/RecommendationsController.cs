using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using DineoAPP.Data;

namespace DineoAPP.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class RecommendationsController : ControllerBase
    {
        private readonly DineoContext _context;

        public RecommendationsController(DineoContext context)
        {
            _context = context;
        }

        // GET: api/recommendations/{userId}
        [HttpGet("{userId}")]
        public async Task<IActionResult> GetRecommendations(int userId, [FromQuery] int take = 8)
        {
            var now = DateTime.UtcNow;
            var sevenDaysAgo = now.AddDays(-7);

            // ── 1. Toate restaurantele ────────────────────────────
            var allRestaurants = await _context.Restaurants.ToListAsync();
            if (!allRestaurants.Any())
                return Ok(new List<object>());

            // ── 2. Trending score (global, per restaurant) ───────
            var reservations7d = await _context.Reservations
                .Where(r => r.CreatedAt >= sevenDaysAgo)
                .GroupBy(r => r.RestaurantId)
                .Select(g => new { RestaurantId = g.Key, Count = g.Count() })
                .ToListAsync();

            var reviews7d = await _context.Reviews
                .Where(r => r.CreatedAt >= sevenDaysAgo)
                .GroupBy(r => r.RestaurantId)
                .Select(g => new { RestaurantId = g.Key, Count = g.Count(), AvgRating = g.Average(x => (double)x.Rating) })
                .ToListAsync();

            var orders7d = await _context.Orders
                .Where(o => o.CreatedAt >= sevenDaysAgo)
                .GroupBy(o => o.RestaurantId)
                .Select(g => new { RestaurantId = g.Key, Count = g.Count() })
                .ToListAsync();

            var resMap = reservations7d.ToDictionary(x => x.RestaurantId, x => x.Count);
            var revMap = reviews7d.ToDictionary(x => x.RestaurantId, x => x);
            var ordMap = orders7d.ToDictionary(x => x.RestaurantId, x => x.Count);

            // Min-max normalize helper
            double Normalize(double value, double min, double max)
                => max - min < 0.0001 ? 0 : (value - min) / (max - min);

            var resVals = allRestaurants.Select(r => (double)(resMap.GetValueOrDefault(r.Id, 0))).ToList();
            var ordVals = allRestaurants.Select(r => (double)(ordMap.GetValueOrDefault(r.Id, 0))).ToList();
            var revCountVals = allRestaurants.Select(r => (double)(revMap.ContainsKey(r.Id) ? revMap[r.Id].Count : 0)).ToList();
            var revRatingVals = allRestaurants.Select(r => revMap.ContainsKey(r.Id) ? revMap[r.Id].AvgRating : r.Rating).ToList();

            double resMin = resVals.DefaultIfEmpty(0).Min(), resMax = resVals.DefaultIfEmpty(0).Max();
            double ordMin = ordVals.DefaultIfEmpty(0).Min(), ordMax = ordVals.DefaultIfEmpty(0).Max();
            double revCMin = revCountVals.DefaultIfEmpty(0).Min(), revCMax = revCountVals.DefaultIfEmpty(0).Max();
            double revRMin = revRatingVals.DefaultIfEmpty(0).Min(), revRMax = revRatingVals.DefaultIfEmpty(0).Max();

            var trendingScores = new Dictionary<int, double>();
            foreach (var r in allRestaurants)
            {
                var resCount = (double)resMap.GetValueOrDefault(r.Id, 0);
                var ordCount = (double)ordMap.GetValueOrDefault(r.Id, 0);
                var revCount = (double)(revMap.ContainsKey(r.Id) ? revMap[r.Id].Count : 0);
                var revRating = revMap.ContainsKey(r.Id) ? revMap[r.Id].AvgRating : r.Rating;

                var nRes = Normalize(resCount, resMin, resMax);
                var nOrd = Normalize(ordCount, ordMin, ordMax);
                var nRevC = Normalize(revCount, revCMin, revCMax);
                var nRevR = Normalize(revRating, revRMin, revRMax);

                trendingScores[r.Id] = (nRes * 0.4) + (nRevR * 0.25) + (nRevC * 0.2) + (nOrd * 0.15);
            }

            // ── 3. User preference profile (per CuisineType) ──────
            var userReservations = await _context.Reservations
                .Where(r => r.UserId == userId && r.Status == "Confirmed")
                .Include(r => r.Restaurant)
                .ToListAsync();

            var userOrders = await _context.Orders
                .Where(o => o.UserId == userId)
                .Include(o => o.Restaurant)
                .ToListAsync();

            var userReviews = await _context.Reviews
                .Where(r => r.UserId == userId)
                .Include(r => r.Restaurant)
                .ToListAsync();

            var userFavourites = await _context.Favourites
                .Where(f => f.UserId == userId)
                .Include(f => f.Restaurant)
                .ToListAsync();

            var cuisinePrefs = new Dictionary<string, double>();
            var visitedRestaurantIds = new HashSet<int>();

            double DecayWeight(DateTime createdAt, double baseWeight)
            {
                var days = (now - createdAt).TotalDays;
                var recency = Math.Exp(-0.05 * Math.Max(days, 0));
                return baseWeight * recency;
            }

            void AddPref(string? cuisine, double weight)
            {
                if (string.IsNullOrWhiteSpace(cuisine)) return;
                cuisinePrefs[cuisine] = cuisinePrefs.GetValueOrDefault(cuisine, 0) + weight;
            }

            foreach (var r in userReservations)
            {
                AddPref(r.Restaurant.CuisineType, DecayWeight(r.CreatedAt, 3));
                visitedRestaurantIds.Add(r.RestaurantId);
            }

            foreach (var o in userOrders)
            {
                AddPref(o.Restaurant.CuisineType, DecayWeight(o.CreatedAt, 4));
                visitedRestaurantIds.Add(o.RestaurantId);
            }

            foreach (var rv in userReviews)
            {
                var weight = rv.Rating >= 4 ? 5 : (rv.Rating <= 2 ? -2 : 0);
                AddPref(rv.Restaurant.CuisineType, DecayWeight(rv.CreatedAt, weight));
                visitedRestaurantIds.Add(rv.RestaurantId);
            }

            foreach (var f in userFavourites)
            {
                AddPref(f.Restaurant.CuisineType, DecayWeight(f.CreatedAt, 2));
                visitedRestaurantIds.Add(f.RestaurantId);
            }

            // Normalize cuisine prefs to 0-1
            var maxPref = cuisinePrefs.Values.DefaultIfEmpty(0).Max();
            var minPref = cuisinePrefs.Values.DefaultIfEmpty(0).Min();
            double NormalizedPref(string? cuisine)
            {
                if (string.IsNullOrWhiteSpace(cuisine) || !cuisinePrefs.ContainsKey(cuisine))
                    return 0;
                return Normalize(cuisinePrefs[cuisine], minPref, maxPref);
            }

            bool isColdStart = !cuisinePrefs.Any();

            // ── 4. Match score per restaurant (skip visited) ──────
            var candidates = allRestaurants
                .Where(r => !visitedRestaurantIds.Contains(r.Id))
                .ToList();

            if (!candidates.Any())
                candidates = allRestaurants; // fallback: user visited everything

            var results = new List<dynamic>();

            foreach (var r in candidates)
            {
                double matchScore;
                if (isColdStart)
                {
                    // Cold start: rely on trending only, match = rating-based
                    matchScore = r.Rating / 5.0;
                }
                else
                {
                    var prefScore = NormalizedPref(r.CuisineType);
                    var ratingScore = r.Rating / 5.0;
                    // Proximity skipped (no user location available) -> 0
                    var proximityScore = 0.0;
                    matchScore = (prefScore * 0.5) + (ratingScore * 0.3) + (proximityScore * 0.2);
                }

                var trending = trendingScores.GetValueOrDefault(r.Id, 0);
                var finalScore = isColdStart
                    ? trending // cold start -> pure trending
                    : (matchScore * 0.7) + (trending * 0.3);

                results.Add(new
                {
                    r.Id,
                    r.Name,
                    r.Description,
                    r.CuisineType,
                    r.Rating,
                    Score = Math.Round(finalScore, 4),
                    MatchScore = Math.Round(matchScore, 4),
                    TrendingScore = Math.Round(trending, 4)
                });
            }

            var top = results
                .OrderByDescending(x => x.Score)
                .Take(take)
                .ToList();

            return Ok(top);
        }
    }
}