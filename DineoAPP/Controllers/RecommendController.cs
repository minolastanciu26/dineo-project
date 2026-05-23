using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using DineoAPP.Data;
using System.Text;
using System.Text.Json;

namespace DineoAPP.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class RecommendController : ControllerBase
    {
        private readonly DineoContext _context;
        private readonly IConfiguration _configuration;
        private readonly HttpClient _httpClient;

        public RecommendController(DineoContext context, IConfiguration configuration)
        {
            _context = context;
            _configuration = configuration;
            _httpClient = new HttpClient();
        }

        [HttpPost]
        public async Task<IActionResult> GetRecommendation([FromBody] RecommendRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.Preference))
                return BadRequest(new { message = "Please describe what you're looking for." });

            // Fetch restaurants from DB
            // For now uses hardcoded list if DB is empty
            var restaurants = await _context.Restaurants.ToListAsync();

            string restaurantList;

            if (restaurants.Any())
            {
                restaurantList = string.Join("\n", restaurants.Select(r =>
                    $"- {r.Name} | Cuisine: {r.CuisineType} | Rating: {r.Rating} | Description: {r.Description}"));
            }
            else
            {
                // Fallback hardcoded restaurants for testing
                restaurantList = @"
- La Grande Bellezza | Cuisine: Italian | Rating: 4.8 | Description: Romantic Italian restaurant with amazing pasta and wine selection
- Caru' cu Bere | Cuisine: Romanian | Rating: 4.6 | Description: Historic brewery restaurant in the heart of Bucharest since 1879
- Vatra | Cuisine: Romanian | Rating: 4.5 | Description: Cozy hearth-inspired restaurant with traditional Romanian dishes
- Shift | Cuisine: International | Rating: 4.3 | Description: Vibrant fusion restaurant with creative cocktails and seasonal menu
- Lacrimi si Sfinti | Cuisine: Romanian Fusion | Rating: 4.7 | Description: Avant-garde Romanian fusion by chef Joseph Hadad";
            }

            // Build prompt for Gemini
            var prompt = $@"You are DINEO, a smart restaurant recommendation assistant in Bucharest, Romania.

A user is looking for: ""{request.Preference}""

Here are the available restaurants:
{restaurantList}

Based on the user's preference, recommend the TOP 2-3 best matching restaurants.
For each restaurant give:
- The restaurant name (bold with **)
- A short reason why it matches (1-2 sentences)
- The rating

Be warm, friendly and concise. Format the response nicely.
If nothing matches well, suggest the closest options and explain why.";

            // Call Gemini API
            var apiKey = _configuration["GeminiApiKey"];
            var geminiUrl = $"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key={apiKey}";

            var requestBody = new
            {
                contents = new[]
                {
                    new
                    {
                        parts = new[]
                        {
                            new { text = prompt }
                        }
                    }
                }
            };

            var json = JsonSerializer.Serialize(requestBody);
            var content = new StringContent(json, Encoding.UTF8, "application/json");

            try
            {
                var response = await _httpClient.PostAsync(geminiUrl, content);
                var responseBody = await response.Content.ReadAsStringAsync();

                if (!response.IsSuccessStatusCode)
                {
                    return StatusCode(500, new { message = "Gemini API error", details = responseBody });
                }

                // Parse Gemini response
                var geminiResponse = JsonSerializer.Deserialize<JsonElement>(responseBody);
                var text = geminiResponse
                    .GetProperty("candidates")[0]
                    .GetProperty("content")
                    .GetProperty("parts")[0]
                    .GetProperty("text")
                    .GetString();

                return Ok(new { recommendation = text });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Failed to get recommendation", error = ex.Message });
            }
        }
    }

    public class RecommendRequest
    {
        public string Preference { get; set; } = string.Empty;
    }
}